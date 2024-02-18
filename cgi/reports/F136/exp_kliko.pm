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

package F136::RpgExportToKliko;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use Encode;
use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use warnings;
use utils;

use F136::export;

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    1 => # номер приложения
        {
            TEMPLATE  => 'F_P1.tt2', # шаблон файла КЛИКО
            FILE      => 'F_P1.txt', # имя создаваемого файла
            ALL_COLS  => 3,  # всего колонок, значение должно быть >= FILL_COLS, разница будет заполнена пустышками
            FILL_COLS => 3,
            MAKER     => sub {shift->_make_appn(@_)}
        },
    2 =>
        {
            TEMPLATE  => 'F_P2.tt2',
            FILE      => 'F_P2.txt',
            ALL_COLS  => 66, # 31 + 31 + 1 заголовок строки + 1 конец строки + 2 предыдущий отчетный период
            FILL_COLS => 65, 
            MAKER     => sub {shift->_make_appn(@_)}
        },
    3 =>
        {
            TEMPLATE  => 'F_P3.tt2',
            FILE      => 'F_P3.txt',
            ALL_COLS  => 65, # 31 + 31 + 1 заголовок строки + 2 предыдущий отчетный период
            FILL_COLS => 65,
            MAKER     => sub {shift->_make_appn(@_)}
            
        },
    4 =>
        {
            TEMPLATE  => 'F_P4.tt2',
            FILE      => 'F_P4.txt',
            ALL_COLS  => 66, # 31 + 31 + 1 заголовок строки + 1 коэф. + 2 предыдущий отчетный период
            FILL_COLS => 66,
            MAKER     => sub {shift->_make_app4(@_)}
        },
    5 =>
        {
            TEMPLATE  => 'F_P5.tt2',
            FILE      => 'F_P5.txt',
            ALL_COLS  => 33, # 31 + 1 заголовок строки + 1 предыдущий отчетный период
            FILL_COLS => 33,
            MAKER     => sub {shift->_make_app6(@_)}
        },
    6 =>
        {
            TEMPLATE  => 'F_P6.tt2',
            FILE      => 'F_P6.txt',
            ALL_COLS  => 65,
            FILL_COLS => 65,
            MAKER     => sub {shift->_make_appn(@_)}
        }
};

BEGIN 
{
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
    ref($_[0]) && die "Error, class F136::RpgExportToKliko can't use in inheritance\n";    
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
    
    $set->{LOG}->out(RpgLog::LOG_I, "user want 'Report by form 0409136' in KLIKO format");          
    $set->{LOG}->out(RpgLog::LOG_D, "doing F136::RpgExportToKliko::do()");
    
    if (TRUE != $self->load_data())
    {        
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }

    my $arc  = Archive::Zip->new(); # пересылаем файлы пакетом, для этого используем архиватор    

    foreach my $app ($set->{CGI}->param('chkApp'))
    {
        next unless (exists(EXPORT_DESC->{$app}));
        
        my $data = '';

        $set->{LOG}->out(RpgLog::LOG_D, "prepare application %s for out to KLIKO format", $app);
        
        $self->{TT}->process(
                                EXPORT_DESC->{$app}{TEMPLATE},
                                {
                                    ## ссылка на самого себя, предоставляет расширенные параметры
                                    get_data   => $self
                                },
                                \$data
                            );
        
        if (defined($self->{TT}->error()))
        {
            # если при выводе шаблона были ошибки, то пишим их в лог
            $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
            $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
            goto _WAS_ERROR;        
        }        
                
        $set->{LOG}->out(RpgLog::LOG_D, "doing compression application %s", $app);
        my $file = $arc->addString($data, EXPORT_DESC->{$app}{FILE});
    
        $file->desiredCompressionMethod(COMPRESSION_DEFLATED);
        $file->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);
    }
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE       => 'application/zip', 
                              -ATTACHMENT => sprintf('f136_reserve_%d_%d_%s.zip', $set->{SESSION}->uid(), $set->{SESSION}->sid(), strftime('%Y%m%d%H%M%S', localtime)),
                              -cookie     => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));
    # выводим пакет
    $arc->writeToFileHandle(\*STDOUT);    
        
    $set->{LOG}->out(RpgLog::LOG_I, "'Report by form 0409136' was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error make 'Report by form 0409136' in KLIKO format");              
    return FALSE;
}

#*******************************************************************************
#
sub get_body
#
#   $self    - ссылка на сам объект
#   $id_app  - номер приложения
#   $id_tbl  - номер таблицы приложения
#   $numbers - номера строк таблицы, который нужно вывести (если не указано то вывести все)
#   $headers - заголовки строк (выводятся один раз)
#   $fields  - поля которые нужно вывести (транспонировав представление)
#
#*******************************************************************************
{
    my ($self, $id_app, $id_tbl, $numbers, $headers, $fields) = (shift, shift, shift, shift, shift, shift);
    
    return unless(exists($self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}));
        
    my ($body)     = $self->{SRC_DATA}->get_data('GET_BODY');
    my ($fpos)     = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{FPOS};
    my ($lpos)     = $self->{GROUPS}{GET_BODY}{$id_app}{$id_tbl}{LPOS};    
    my ($ret)      = "\r\n";
    my ($num_curr) = ''; # последний номер строки
    my ($id_row)   = $$body[$fpos]->{sub_row};
    my (%dic_numbers, %dic_headers);  # словари 
                    
    @dic_numbers{@{$numbers}} = (); # создаем словарь номеров строк таблицы подлежащих выводу
    @dic_headers{@{$headers}} = (); # создаем словарь полей заголовков строк
    
    # цикл по строкам таблицы, делаем фактически транспонирование
    while ($fpos <= $lpos)
    {        
        my (@row); # значение полей строки (сначало накапливаем в массиве) 
        
        # выделяем память под строку
        #$#row     = EXPORT_DESC->{$id_app}{ALL_COLS} - 1;        
        $num_curr = $$body[$fpos]->{num} if (defined($$body[$fpos]->{num}));
        
        if ($#{$numbers} >= 0 && !exists($dic_numbers{$num_curr}))        
        {
            # выводим только указанные строки
            $fpos++;
            next;
        }
        # ок, собираем очередную строку:

        # транспанируем, результат сохраняем в массив, приэтом учитывается наличие 
        # (отсутствие заголовка)      
        # цикл формирование строки (начало - конец строки определяем по её ID)        
        my $col  = ($#{$headers} >= 0 ? 1 : 0);
        my $type = undef;
        my $show = undef;
        
        do
        {        
            for (my $j = 0; $j <= $#{$fields}; $j++)
            {
                $row[$col++] = $$body[$fpos]->{$$fields[$j]};
                $type        = $$body[$fpos]->{type};
                $show        = $$body[$fpos]->{show};
            }   
        }
        while (++$fpos <= $lpos && $$body[$fpos - 1]->{sub_row} == $$body[$fpos]->{sub_row} && $$body[$fpos - 1]->{note} eq $$body[$fpos]->{note});
                        
        # создаем заголовок строки
        if ($#{$headers} >= 0)
        {   
            # заголовок формируем по значениям предыдущей строки
            $row[0] = join('', map {defined($$body[$fpos - 1]->{$_}) ? $$body[$fpos - 1]->{$_} : ''} @{$headers});
        }
        
        # собираем строку
        $ret .= EXPORT_DESC->{$id_app}{MAKER}->($self, $id_app, \@row, $type, $show);        
        
        # новый ID строки - новая строка
        $ret .= "\r\n";        
    }
        
    return encode('cp866', decode('cp1251', $ret)); 
}

sub _make_app4
{
    my $self = shift;
    my $app  = shift;
    my $rows = shift;
    my $type = shift;
    my $show = shift;
    my $desc = EXPORT_DESC->{$app};
    my $ret  = '';
    
    # определяет тип значения строки
    #   0 - нет источника, строка не требует вычисления (строка типа заголовок группы)
    #   1 - остаток на счете или код
    #   2 - итого
    #   3 - хронологические данные (рассчитывается за период)
    #   4 - резервы (рассчитывается за период)
    #   5 - остаток по счету (коду) на дату относительно левой граници диапазона (указывается дельта)
    #   6 - остаток по счету (коду) на дату относительно правой граници диапазона (указывается дельта)
    #   7 - проставить значение в остаток на счете  на каждый день отчетного периода
    #   8 - проставить значение в остаток на счете на дату относительно левой граници диапазона (указывается дельта)
    #   9 - проставить значение в остаток на счете на дату относительно правой граници диапазона (указывается дельта
    #   10 - корректировочный коэф.
    if ($type == 10)
    {
        $ret = join (',', map{defined($rows->[$_]) ? "\"$rows->[$_]\"" : '""'} (0 .. EXPORT_DESC->{$app}{ALL_COLS} - 1));
    }
    elsif ($type == 0 || $type == 3 || $type == 4)
    {
        # строка - пустышка
        $ret = join (',', map{$_ == 1 ? '""' : (defined($rows->[$_])) ? "\"$rows->[$_]\"" : '""'} (0 .. EXPORT_DESC->{$app}{ALL_COLS} - 1));
    }
    else
    {
        my @tmp;
        my $fill = EXPORT_DESC->{$app}{FILL_COLS} - 2;
        my $all  = EXPORT_DESC->{$app}{ALL_COLS} - 2;
        
        $#tmp   = $all;       # выделяем память
        $tmp[0] = $rows->[0]; # заголовок строки
        $tmp[1] = undef;      # колонка для корр. коэф.
        
        # с первой отчётной даты по последнюю минус один день - два столбца тк рубли и валюта                
        # значения из последней даты переносим в предпоследнии поля, а промежуток заполняется нулями
        for (my $i = 1; $i <= $fill; $i++)
        {            
            if ($fill == $i || $fill - 1 == $i)
            {
                $tmp[$i+1] = $rows->[$#{$rows} - ($fill - $i)];                
            }
            elsif ($#{$rows} - 2 >= $i)
            {
                $tmp[$i+1] = $rows->[$i];
            }
            else
            {
                $tmp[$i+1] = defined($rows->[$#{$rows} - $i%2]) ? 0 : undef;
            }
        }
        
        $ret = join (',', map{defined($_) ? "\"$_\"" : '""'} @tmp);
    }
    
    $ret;
}

sub _make_appn
{
    my $self = shift;
    my $app  = shift;
    my $rows = shift;
    my $type = shift;
    my $desc = EXPORT_DESC->{$app};
    my $ret  = '';
    
    # определяет тип значения строки
    #   0 - нет источника, строка не требует вычисления (строка типа заголовок группы)
    #   1 - остаток на счете или код
    #   2 - итого
    #   3 - хронологические данные (рассчитывается за период)
    #   4 - резервы (рассчитывается за период)
    #   5 - остаток по счету (коду) на дату относительно левой граници диапазона (указывается дельта)
    #   6 - остаток по счету (коду) на дату относительно правой граници диапазона (указывается дельта)
    #   7 - проставить значение в остаток на счете  на каждый день отчетного периода
    #   8 - проставить значение в остаток на счете на дату относительно левой граници диапазона (указывается дельта)
    #   9 - проставить значение в остаток на счете на дату относительно правой граници диапазона (указывается дельта
    if ($type == 0 || $type == 3 || $type == 4)
    {
        # строка - пустышка
        $ret = join (',', map{(defined($rows->[$_])) ? "\"$rows->[$_]\"" : '""'} (0 .. EXPORT_DESC->{$app}{ALL_COLS} - 1));
    }
    else
    {
        my @tmp;
        my $fill = EXPORT_DESC->{$app}{FILL_COLS} - 1;
        my $all  = EXPORT_DESC->{$app}{ALL_COLS} - 1;
        
        $#tmp   = $all;       # выделяем память
        $tmp[0] = $rows->[0]; # заголовок строки
        
        # с первой отчётной даты по последнюю минус один день - два столбца тк рубли и валюта                
        # значения из последней даты переносим в предпоследнии поля, а промежуток заполняется нулями
        for (my $i = 1; $i <= $fill; $i++)
        {
            if ($fill == $i || $fill - 1 == $i)
            {
                $tmp[$i] = $rows->[$#{$rows} - ($fill - $i)];                
            }
            elsif ($#{$rows} - 2 >= $i)
            {
                $tmp[$i] = $rows->[$i];
            }
            else
            {
                $tmp[$i] = defined($rows->[$#{$rows} - $i%2]) ? 0 : undef;
            }
        }
        
        $ret = join (',', map{defined($_) ? "\"$_\"" : '""'} @tmp);
    }
    
    $ret;
}

sub _make_app6
{
    my $self = shift;
    my $app  = shift;
    my $rows = shift;
    my $type = shift;
    my $desc = EXPORT_DESC->{$app};
    my $ret  = '';
    
    # определяет тип значения строки
    #   0 - нет источника, строка не требует вычисления (строка типа заголовок группы)
    #   1 - остаток на счете или код
    #   2 - итого
    #   3 - хронологические данные (рассчитывается за период)
    #   4 - резервы (рассчитывается за период)
    #   5 - остаток по счету (коду) на дату относительно левой граници диапазона (указывается дельта)
    #   6 - остаток по счету (коду) на дату относительно правой граници диапазона (указывается дельта)
    #   7 - проставить значение в остаток на счете  на каждый день отчетного периода
    #   8 - проставить значение в остаток на счете на дату относительно левой граници диапазона (указывается дельта)
    #   9 - проставить значение в остаток на счете на дату относительно правой граници диапазона (указывается дельта
    if ($type == 0 || $type == 3 || $type == 4)
    {
        # строка - пустышка
        $ret = join (',', map{(defined($rows->[$_])) ? "\"$rows->[$_]\"" : '""'} (0 .. EXPORT_DESC->{$app}{ALL_COLS} - 1));
    }
    else
    {
        my @tmp;
        my $fill = EXPORT_DESC->{$app}{FILL_COLS} - 1;
        my $all  = EXPORT_DESC->{$app}{ALL_COLS} - 1;
        
        $#tmp   = $all;       # выделяем память
        $tmp[0] = $rows->[0]; # заголовок строки
        
        # с первой отчётной даты по последнюю минус один день - два столбца тк рубли и валюта                
        # значения из последней даты переносим в предпоследнии поля, а промежуток заполняется нулями
        for (my $i = 1; $i <= $fill; $i++)
        {
            if ($fill == $i)
            {
                $tmp[$i] = $rows->[$#{$rows}];                
            }
            elsif ($#{$rows} - 1 >= $i)
            {
                $tmp[$i] = $rows->[$i];
            }
            else
            {
                $tmp[$i] = defined($rows->[$#{$rows}]) ? 0 : undef;
            }
        }
        
        $ret = join (',', map{defined($_) ? "\"$_\"" : '""'} @tmp);
    }
    
    $ret;
}
1;
