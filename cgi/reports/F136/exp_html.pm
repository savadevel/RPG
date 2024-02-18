#!/usr/bin/perl
#************************************************************************
#
# References  :
#
#          $Revision: 
#          $Date:     
#          $Author:   
#          $Mail:     
#
#***********************************************************************
#
# Name        :  
# Platforms   :  unix, windows      
# Contents    :                  
# Description :  
#                

package F136::RpgExportToHtml;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use DateTime;
use DateTime::Set;
use DateTime::Span;
use F136::export;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251"); 

    $VERSION = 0.01;
    @ISA     = qw(F136::RpgExport);
    $PACKAGE = __PACKAGE__;
}

#*******************************************************************************
#
sub DESTROY
#
#*******************************************************************************
{
    my ($self) = @_;
    
    foreach my $parent ( @ISA )
    {
        # вызываем деструкторы базовых классов
        next if $self->{$parent}{DESTROY}++;
        my $destructor = $parent->can("DESTROY");
        $self->$destructor() if $destructor;
    }
}

#*******************************************************************************
#
sub new
#
#*******************************************************************************
{
    ref($_[0]) && die "Error, class F136::RpgExportToHtml can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({@_}, $class);
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }

    # запрет на повторную инициализацию    
    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++);      
    return $self;       
}

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    return shift;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    
    $set->{LOG}->out(RpgLog::LOG_I, "user want 'Report by form 0409136' in HTML format");          
   
    if (TRUE != $self->load_data())
    {
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }
    
    my %types = (date => {}, time => {});

    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};

    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to HTML format");
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251',
                              -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));

    # Значения были загруженны в родительском классе RpgExport    
    my $rowver   = $self->{SRC_DATA}->get_obj_data('GET_ROWVER');
    my $executor = $self->{SRC_DATA}->get_obj_data('GET_USER');    
    my $ldate    = RpgTypeDate::Str2DateTime($rowver->ldate(), 'ISO8601')->add(days => 1);
    my $rdate    = RpgTypeDate::Str2DateTime($rowver->rdate(), 'ISO8601')->add(days => 1);
    my @dates    = DateTime::Set->from_recurrence
        (
            recurrence => sub
            {
                return $_[0] if $_[0]->is_infinite;
                return $_[0]->truncate(to => 'day')->add(days => 1)
            },
            span => DateTime::Span->from_datetimes(start => $ldate, end => $rdate)
        )->as_list;
        
    # печать тела (шаблона)
    $self->{TT}->process
    (
        'f136_form.html',
        {
            errors     => $self->errstr,
            alerts     => $self->alerts,
            dformat    => $types{date}{format},
            tformat    => $types{time}{format},
            date2str   => sub {my $val = shift; (ref($val) ? RpgTypeDate::DateTime2Str($val, $types{(shift)}{name}) : RpgTypeDate::Format($val, 'ISO8601', $types{(shift)}{name}));},
          
            ## ссылка на самого себя, предоставляет расширенные параметры
            get_data  => $self,                             
             
            ## параметры Банка
            bank      =>
            {
                OKATO       => $set->{SETT}->get('F136_SETTING', 'BANK_OKATO'),
                OKPO        => $set->{SETT}->get('F136_SETTING', 'BANK_OKPO'),
                main_num    => $set->{SETT}->get('F136_SETTING', 'BANK_MAIN_NUM'),
                registr_num => $set->{SETT}->get('F136_SETTING', 'BANK_REGISTR_NUM'),
                BIK         => $set->{SETT}->get('F136_SETTING', 'BANK_BIK'),
                
                name           => $set->{SETT}->get('F136_SETTING', 'BANK_NAME'),
                address        => $set->{SETT}->get('F136_SETTING', 'BANK_ADDRESS'),
                sub_president  => $set->{SETT}->get('F136_SETTING', 'BANK_SUB_PRESIDENT'),
                sub_accountant => $set->{SETT}->get('F136_SETTING', 'BANK_SUB_ACCOUNTANT')           
            },
            
            executor    =>
            {
               phone    => $executor->phone,
               name     => $executor->name   
            },
             
             ## атрибуты таблицы
            table     =>
            {
                period_left  => RpgTypeDate::DateTime2Str($ldate, $types{date}{name}),
                period_right => RpgTypeDate::DateTime2Str($rdate, $types{date}{name}),
                date         => strftime('"%d" %B %Y года', localtime)
            },
             
            ## все даты из диапазона за который создаётся отчет
            dates     => \@dates,
             
            ## число дней за которое формируется отчет
            num_days  => ($#dates + 1)
    });
    
    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;        
    }

    $set->{LOG}->out(RpgLog::LOG_I, "'Report by form 0409136' was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error make 'Report by form 0409136' in HTML format");              
    return FALSE;
}

#*******************************************************************************
#
sub get_body
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl, $headers, $fields) = (shift, shift, shift, shift, shift);
    
    return unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}));
    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе     
    my ($vars) = $self->{$PACKAGE};    
    my ($body) = $self->{SRC_DATA}->get_data('GET_BODY');
    my ($fpos) = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{FPOS};
    my ($lpos) = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{LPOS};        
    my ($ret, $max_cols) = ('', 0);
    my (@table);
    
    # цикл по строкам таблицы, делаем фактически транспонирование
    while ($fpos <= $lpos)
    {        
        my @row;
        
        # зоголовок строки
        push(@row,  map {$$body[$fpos]->{$_}} @{$headers});
        
        # значения строки
        do
        {        
            push(@row,  map {$$body[$fpos]->{$_}} @{$fields});                    
        }
        while (++$fpos <= $lpos && $$body[$fpos - 1]->{sub_row} == $$body[$fpos]->{sub_row} && $$body[$fpos - 1]->{note} eq $$body[$fpos]->{note});
                
        # формируем матрицу, значений         
        push(@table, \@row);
        $max_cols = $#row if($#row > $max_cols);
    }
    
    # собираем таблицу
    foreach my $row (@table)
    {
        # собираем строку        
        $ret .= "<tr>";
        $ret .= "<td>";
        $ret .= join('</td><td>', map {defined($$row[$_]) ? $$row[$_] : ''} (0..($#{$row} - ($#{$row} == $max_cols ? 0 : $#{$fields} + 1))));
        $ret .= "</td>";
        
        # выравнивание числа колонок таблицы
        unless ($#{$row} == $max_cols)
        {
            for (my $i = $#{$row} - $#{$fields}; $i <= $#{$row}; $i++)
            {               
                unless (defined($$row[$i]))
                {
                    $ret .= "<td colspan=";
                    $ret .= ($max_cols - $#{$row} + 1 + ($i == ($#{$row} - $#{$fields}) ? 1 : 0 ));
                    $ret .= '></td>';
                    last;
                }
                $ret .= "<td>$$row[$i]</td>";
            }
        }
        
        $ret .= "</tr>";        
        $ret .= "\n";           
    }

    return $ret; 
}

#*******************************************************************************
#
sub get_num_row
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl) = (shift, shift, shift);    

    return 0 unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}));
    return $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT};
}

#*******************************************************************************
#
#  Метод возвращает список уникальных значений поля
#
sub get_uniq_values
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl, $field) = (shift, shift, shift, shift);
    my ($ret)                             = [];

    return $ret unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl})    and
                       $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT} > 0);

    my ($body)   = $self->{SRC_DATA}->get_data('GET_BODY');
    
    # поле должно существовать
    return $ret unless(exists($$body[0]->{$field}));
    
    my ($fpos)   = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{FPOS};
    my ($lpos)   = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{LPOS};           
    my (%uniq)   = ();
    
    # пессимистичное выделение памяти
    #keys(%uniq)  = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT};    
    
    for (my $row = $fpos; $row <= $lpos; $row++)
    {
        unless (exists($uniq{$$body[$row]->{$field}}))
        {
            $$ret[$#{$ret} + 1] = $$body[$row]->{$field};
        }
        
        $uniq{$$body[$row]->{$field}}++;              
    }    

    return $ret;
}


#*******************************************************************************
#
#  Метод возвращает список - списков, согласно переданному полю из которого берется 
#  ключь, значения (для списка) берутся из указанных полей (типа TRANSFORM)
#
sub get_by_key
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl, $key, $fields) = (shift, shift, shift, shift, shift);
    my ($ret)                                   = [[]]; # массив уже содержит одну пустую строку

    return $ret unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl})    and
                       $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT} > 0);

    my ($body) = $self->{SRC_DATA}->get_data('GET_BODY');
    
    # поле ключа должно существовать
    return $ret unless(exists($$body[0]->{$key}));
    
    my ($fpos) = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{FPOS};
    my ($lpos) = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{LPOS};           
    my (%uniq) = ();
    
    for (my $row = $fpos; $row <= $lpos; $row++)
    {
        unless (exists($uniq{$$body[$row]->{$key}}))
        {
            # найден новый ключ, сохраняем позицию
            $uniq{$$body[$row]->{$key}}           = {};
            $uniq{$$body[$row]->{$key}}->{INSERT} = 0;                       # позиция вставки с которой следует начать (последняя строка)
            $uniq{$$body[$row]->{$key}}->{POS}    = $#{$$ret[$#{$ret}]} + 1; # позиция вставки ... (позиция в строке)
        }   
        
        # определяем необходимость в новой строке
        if ($uniq{$$body[$row]->{$key}}->{INSERT} > $#{$ret})
        {            
            # заводим новую строку
            $$ret[$#{$ret} + 1] = [];               
        }
        
        my $ins = $uniq{$$body[$row]->{$key}}->{INSERT};
        my $pos = $uniq{$$body[$row]->{$key}}->{POS};
        my $ref = $$ret[$ins]; # сохраняем ссылку на строку в которую вставляем, новые ячейки
        
        # увеличиваем номер строки для последующей вставки в него
        $uniq{$$body[$row]->{$key}}->{INSERT}++;
        
        # декларируем хеш - ячейки столбца
        $$ref[$pos] = {};
                
        for (my $col = 0; $col <= $#{$fields}; $col++)
        {
            $$ref[$pos]->{$$fields[$col]} =
                (defined($$body[$row]->{$$fields[$col]}) ? $$body[$row]->{$$fields[$col]} : '');
        }        
    }    

    return $ret;
}

#*******************************************************************************
#
sub get_columns
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl, $fields) = (shift, shift, shift, shift);
    my ($ret)                             = [];

    return $ret unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}) and
                       $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT} > 0);

    my ($body)   = $self->{SRC_DATA}->get_data('GET_BODY');
    my ($fpos)   = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{FPOS};
    my ($lpos)   = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{LPOS};    
    
    # резервируем память
    $#{$ret}     = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{COUNT} - 1;
        
    for (my $row = $fpos; $row <= $lpos; $row++)
    {
        for (my $col = 0; $col <= $#{$fields}; $col++)
        {
            $$ret[$row - $fpos]->{$$fields[$col]} =
                (defined($$body[$row]->{$$fields[$col]}) ? $$body[$row]->{$$fields[$col]} : '');
        }                
    }    
        
    return $ret; 
}

1;
