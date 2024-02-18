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

package F136::RpgExportToReserve;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use utils;
use types;
use DateTime;
use DateTime::Set;
use DateTime::Span;
use F136::export;

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
    ref($_[0]) && die "Error, class F136::RpgExportToReserve can't use in inheritance\n";    
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
    
    $set->{LOG}->out(RpgLog::LOG_I, "user want 'Report by form 0409136' in RESERVE format");          
    $set->{LOG}->out(RpgLog::LOG_D, "doing F136::RpgExportToReserve::do()");
    
    if (TRUE != $self->load_data())
    {        
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }
   
    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to RESERVE format");

    my $rowver   = $self->{SRC_DATA}->get_obj_data('GET_ROWVER');
    my $arc      = Archive::Zip->new(); # пересылаем файлы пакетом, для этого используем архиватор
    my $data     = '';
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
    
    $self->{TT}->process
        (
            'reserve.tt2',
            {
                ## ссылка на самого себя, предоставляет расширенные параметры
                get_data  => $self,

                ## параметры отчета
                report    => 
                {
                    # дата представления расчета (должна попадать в период представления расчета, определенного ТУ Банка России для кредитной организации);
                    date_first => $ldate,
                    # отчетная дата (последняя дата [конец] отчетного периода);
                    date_last  => $rdate, 
                    date_curr  => $rdate,
                    date_report=> $rdate->clone->add(days => 3),
                    number     => 1,                   # номер посылки (от 1 до 9)  
                                                       # коэффициент усреднения по кредитной организации в формате #.#### пример: 0.015 (0 – если усреднения нет);
                    k_mean_rub => $set->{SETT}->get('F136_SETTING', 'K_MEAN_R'),
                    
                    ## все даты из диапазона за который создаётся отчет
                    dates      => \@dates,
                        
                    ## количество дней в отчетном периоде – количество столбцов дат в приложениях;
                    days       => $#dates + 1                    
                },
                 
                ## параметры Банка
                bank      =>
                {
                    # регистрационный номер КО
                    registr_num => $set->{SETT}->get('F136_SETTING', 'BANK_REGISTR_NUM')
                }
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
    
    $data =~ s/(?!\r)\n/\r\n/g;
       
    # Имя файла – orNNNNYn.ddd, 
    # где Y и ddd – отчетная дата , 
    # Y - номер года, 
    # ddd – номер дня в году (от 1 до 365/366), 
    # n – порядковый номер посылки, 
    # NNNN – регистрационный номер кредитной организации.     
    $set->{LOG}->out(RpgLog::LOG_D, "doing compression report");

    my $file_name = sprintf("or%04d%1d%1d.%03d", 
                            $set->{SETT}->get('F136_SETTING', 'BANK_REGISTR_NUM'),
                            $ldate->year,
                            1,
                            $ldate->day_of_year);
    my $file      = $arc->addString($data, $file_name);

    $file->desiredCompressionMethod(COMPRESSION_DEFLATED);
    $file->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE       => 'application/zip', 
                              -ATTACHMENT => sprintf('f136_reserve_%d_%d_%s.zip', $set->{SESSION}->uid(), $set->{SESSION}->sid(), strftime('%Y%m%d%H%M%S', localtime)),
                              -cookie     => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef)
                             );
    # выводим пакет
    $arc->writeToFileHandle(\*STDOUT);    
        
    $set->{LOG}->out(RpgLog::LOG_I, "'Report by form 0409136' was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error make 'Report by form 0409136' in RESERVE format");              
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
    my ($ret)      = '';
    my ($id_row)   = $$body[$fpos]->{sub_row};    
    my ($num_curr) = ''; # последний номер строки
    my (%dic_numbers, %dic_headers);  # словари 

    @dic_numbers{@{$numbers}} = (); # создаем словарь номеров строк таблицы подлежащих выводу
    @dic_headers{@{$headers}} = (); # создаем словарь полей заголовков строк
                    
    # цикл по строкам таблицы, делаем фактически транспонирование
    while ($fpos <= $lpos)
    {        
        my (@row); # значение полей строки (сначало накапливаем в массиве) 
        
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
        my $col            = ($#{$headers} >= 0 ? 1 : 0);
        my $cell_not_empty = 0; # количество не пустых записей
        
        do
        {        
            for (my $j = 0; $j <= $#{$fields}; $j++)
            {
                $row[$col++] = $$body[$fpos]->{$$fields[$j]};
                $cell_not_empty ++ if (defined($$body[$fpos]->{$$fields[$j]}));
            }   
        }
        while (++$fpos <= $lpos && $$body[$fpos - 1]->{sub_row} == $$body[$fpos]->{sub_row} && $$body[$fpos - 1]->{note} eq $$body[$fpos]->{note});
                        
        # создаем заголовок строки
        if ($#{$headers} >= 0)
        {   
            # заголовок формируем по значениям предыдущей строки
            $row[0] = join(';', map {defined($$body[$fpos - 1]->{$_}) ? $$body[$fpos - 1]->{$_} : ''} @{$headers});
        }
        
        if ($cell_not_empty == 0)
        {
            # строка без остатков на счетах
            $ret .= $row[0];
        }
        elsif ($cell_not_empty == 1)
        {
            # собираем строку с хронологическими данными
            $ret .= join(';', grep {defined($_)} @row);
        }
        else
        {        
            # собираем строку
            $ret .= join(';', map{(defined($_)) ? $_ : 'X'} @row);
        }
        
        # новый ID строки - новая строка
        $ret .= "\n";        
    }
        
    return $ret; 
}


1;
