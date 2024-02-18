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

package RpgExportToExcel;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);
use UNIVERSAL qw(isa can);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use English;
use strict;
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Big;
use warnings;
use utils;

use constant MAX_ROWS  => 65000; # мах число строк на листе
use constant FIRST_ROW => 0;      # номер первой строки на листе
use constant FIRST_COL => 0;      # номер первой колонки на листе
use constant COLORS    =>          # цветовые схемы
{
    header => {
                  name   => 40,
                  color => '#B2B2B2'
              },
    corr   => {
                  name   => 41,
                  color => '#B3FFB3'
              },
    orig   => {
                  name   => 42,
                  color => '#F8F8F8'
              }, 
    status_ok => {
                  name   => 43,
                  color => '#F8F8F8'
              },
    status_err => {
                  name   => 44,
                  color => '#E37982'
              } 
};

use constant TYPE2FORMAT  =>    # формат представленния данных
{
    date => 
        {
            width => 12,
            ext  =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter', 
                num_format => 'dd/mm/yy'                
            }            
        },
    time => 
        {
            width => 15,
            ext  =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter', 
                num_format => 'dd/mm/yy hh:mm:ss'                
            }            
        },
    str => 
        {
            width  => 40,
            ext    =>
            { 
                align      => 'left', 
                border     => 1, 
                valign     => 'vcenter',
                text_wrap  => 1
            }            
        },
    chr => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter'                
            }            
        },
    byte => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter'                
            }            
        },
    bool => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter'                
            }            
        },
    txt => 
        {
            width => 100,
            ext   =>
            { 
                align      => 'left', 
                border     => 1, 
                valign     => 'vcenter',
                text_wrap  => 1,
                size       => 8
            }            
        },
    acc => 
        {
            width => 21,
            ext   =>
            { 
                align      => 'center', 
                border     => 1, 
                valign     => 'vcenter'
            }            
        },
    flt => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'right', 
                border     => 1, 
                valign     => 'vcenter'
            }            
        },
    int => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'right', 
                border     => 1, 
                valign     => 'vcenter'
            }            
        },
    mny => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'right', 
                border     => 1, 
                valign     => 'vcenter'                
            }            
        },
    unk => 
        {
            width => 12,
            ext   =>
            { 
                align      => 'left', 
                border     => 1, 
                valign     => 'vcenter'                
            }            
        }
};

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw ();
}

#*******************************************************************************
#
sub DESTROY
#
#*******************************************************************************
{
}

#*******************************************************************************
#
# 
sub new
#
#   SETT    = указатель на объект, источник денамических параметров RpgSett    
#   SESSION = указатель на объект, доступ к параметрам сессии
#       
#*******************************************************************************
{
    my ($class)  = shift;
    my ($self)   = (ref($class) ? $class : bless({@_}, $class));

    # запрет на повторную инициализацию    
    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++);      
    return $self;           
};

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    my ($self) = shift;    

    $self->{$PACKAGE}{ERROR} = ''; # сообщение о ошибке
    
    return $self;
}

#*******************************************************************************
#
#  Метод возвращает последнюю ошибку в модуле
#
sub errstr
#
#*******************************************************************************
{
    return $_[0]->{$PACKAGE}{ERROR};
}

#*******************************************************************************
# 
#  Вызов функции экспорта-представлениия данных в Excel формате, данные направляются 
#  в STDOUT
#
sub export
#  
#  хеш, в следующем фомате:#  
#       TITLE    - имя-описание отчета
#       TABLES   = ссылка на хеш, содержит параметры и данные для вывода в Excel
#       {
#           TABLE_01 = ссылка на хеш, содержит параметры и данные выводимой таблицы
#           {
#               TITLE - имя-описание таблицы
#               DATA  - ссылка на массив хешей, содержит данные для отображения в таблице TABLE_01
#               SKEEP - если определенно то пропустить печать таблицы, решается шаблоном 
#               ORDER - порядок вывода таблиц, не поддерживается, решается шаблоном 
#               FIELDS = ссылка на хеш, содержит описание полей таблицы
#               {
#                   FIELD_01 = ссылка на хеш, содержит описание поля таблицы
#                   {
#                       type    - тип данных поля
#                       desc    - описание поля
#                       order   - если определенно, то следовать заданному порядку вывода
#                       schema  - если определенно, то исползовать эту схему при конвертации
#                       hide    - если определенно то поле выводится но не отображается
#                       button  - если определенно, то элементы поля должны быть представленны ввиде кнопки
#                       key     - если определенно, то поле входит в уникальный идентификатор строки таблицы
#                       change  - если определенно, то разрешено изменять значение поля
#                       trigger = если определенно, то выполнить дополнительные действия в зависимости от значения
#                       {
#                           value_01 = ссылка на хеш, содержит описание триггера поля
#                           {
#                               value     - если определенно, заменить значением
#                               attribute - если определенно, установить свойство у тега
#                               type      - если определенно, новый тип
#                               style = опции форматирования поля
#                               {
#                                   name   - имя стиля
#                               }
#                           }
#                       },
#                       style = опции форматирования поля
#                       {
#                           name   - имя стиля
#                       }
#                   }
#               }
#           }        
#       }
#  
#*******************************************************************************
{
    my ($self) = shift;
    my (%args) = (@_);
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    $self->{$PACKAGE}{TABLES}     = $args{TABLES};
    $self->{$PACKAGE}{ERROR}      = '';    
    $self->{$PACKAGE}{WORKBOOK}   = Spreadsheet::WriteExcel::Big->new(\*STDOUT);
    $self->{$PACKAGE}{WORKSHEETS} = {};
    $self->{$PACKAGE}{FORMATS}    = {};
    
    binmode STDOUT;

    my ($workbook)   = $self->{$PACKAGE}{WORKBOOK};
    my ($formats)    = $self->{$PACKAGE}{FORMATS};
    my ($worksheets) = $self->{$PACKAGE}{WORKSHEETS};
    my ($tables)     = 
        [            
            # то что сортируемо
            (sort {$args{TABLES}->{$a}{ORDER} <=> $args{TABLES}->{$b}{ORDER}} grep {defined($args{TABLES}->{$_}{ORDER})} keys(%{$args{TABLES}})),
            # все остальное не содержит поля ORDER
            (grep {!defined($args{TABLES}->{$_}{ORDER})} keys(%{$args{TABLES}}))
        ]; 

    # создаём форматы представления данных в workbook
    $self->_make_formats() || goto _WAS_ERROR;

    # создаём все в worksheets
    $self->_make_worksheets($tables) || goto _WAS_ERROR;

    # цикл по таблицам. каждая таблица в своём worksheet
    foreach my $table (@{$tables})
    {           
        foreach my $sheet (@{$worksheets->{$table}{sheets}})
        {
           $self->_make_body($table, $sheet, $worksheets->{$table}{fields}) || goto _WAS_ERROR;
        }
    }

    return TRUE;        
    
_WAS_ERROR:    
    return FALSE;    
}

#*******************************************************************************
#
# Закрытый метод, создайт форматы представления данных в workbook
#
sub _make_formats
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    $self->{$PACKAGE}{FORMATS}  = {};

    my ($workbook) = $self->{$PACKAGE}{WORKBOOK};
    my ($formats)  = $self->{$PACKAGE}{FORMATS};

    # создаём шаблоны представления типов данных
    # для заголовка таблиц формат один
    $formats->{header} = $workbook->add_format(align => 'center', border => 2, valign => 'vcenter', text_wrap => 1, bold => 1);   

    # создаем цветовые схемы для всех типов данных
    foreach my $class (keys(%{COLORS()}))
    {
        $workbook->set_custom_color(COLORS->{$class}{name}, COLORS->{$class}{color}) ;
        
        if ($class eq 'header')
        {
            # для заголовка только одна цветовая схема (без конкретизации типа)
            $formats->{header}->set_bg_color(COLORS->{$class}{name});                
            next;
        }

        $formats->{$class} = {};
        
        foreach my $type (keys(%{TYPE2FORMAT()}))
        {
            # WriteExcel вычисляет имя метода по передоваемым ключам в хеше!
            $formats->{$class}{$type} = $workbook->add_format(bg_color => COLORS->{$class}{name}, %{TYPE2FORMAT->{$type}{ext}});
        }
    }

    return TRUE;
}

#*******************************************************************************
#
# Закрытый метод, создайт все worksheets и заголовки таблиц
#
sub _make_worksheets
#
#*******************************************************************************
{
    my ($self, $tables) = (shift, shift);
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    my ($workbook)   = $self->{$PACKAGE}{WORKBOOK};
    my ($worksheets) = $self->{$PACKAGE}{WORKSHEETS};

    # цикл формирования worksheet для каждого набора
    # учитываем ограничение Excel на количество строк
    foreach my $table (@{$tables})
    {
        my ($fields) = $vars->{TABLES}{$table}{FIELDS};
        my ($body)   = $vars->{TABLES}{$table}{DATA};
        
        $worksheets->{$table}         = {};
        $worksheets->{$table}{name}   = $table;
        $worksheets->{$table}{rows}   = $#{$body} + 1;
        $worksheets->{$table}{sheets} = [];
        $worksheets->{$table}{fields} =
            [
                # то что сортируемо
                (sort {$fields->{$a}{order} <=> $fields->{$b}{order}} grep {defined($fields->{$_}{order}) && !defined($fields->{$_}{hide})} keys(%{$fields})), 
                # все остальное не содержит поля order
                (grep {!defined($fields->{$_}{order}) && !defined($fields->{$_}{hide})} keys(%{$fields}))
            ]; 

        # если нет полей то пропускае создание worksheet(s)
        next if ($#{$worksheets->{$table}{fields}} < 0);

        # нарезаем набор данных по MAX_ROWS строк
        for (my $i = 0; 1; $i += MAX_ROWS)
        {
            # The worksheet name must be a valid Excel worksheet name, 
            # i.e. it cannot contain any of the following characters, C<: * ? / \> and it must be less than 32 characters. 
            # In addition, you cannot use the same, case insensitive, C<$sheetname> for more than one worksheet.
            my ($name)  = sprintf("Report (%s) - %02d", $table, int($i/MAX_ROWS));
            my (%sheet);

            push @{$worksheets->{$table}{sheets}}, \%sheet;

            $sheet{hndl} = $workbook->add_worksheet($name);

            # даже если таблица не содержит данных заголовок должен быть
            last if (($i + MAX_ROWS) >= $worksheets->{$table}{rows});
        }

        # создаём заголовки таблиц для всех worksheets принадлежащих $table
        $self->_make_headers($worksheets->{$table});
    }

    return TRUE;
}

#*******************************************************************************
#
# Закрытый метод, формирует заголовоки таблицы
#
sub _make_headers
#
#*******************************************************************************
{
    my ($self, $table) = (shift, shift);    

    my ($vars)  = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    my @names   = map {$vars->{TABLES}{$table->{name}}{FIELDS}{$_}{desc}} @{$table->{fields}};
    my $headers = Win2Utf8Ex([@names]);
    my @width   = map 
                    {
                        if (exists(TYPE2FORMAT->{$vars->{TABLES}{$table->{name}}{FIELDS}{$_}{type}}))
                        {
                            TYPE2FORMAT->{$vars->{TABLES}{$table->{name}}{FIELDS}{$_}{type}}{width};
                        }
                        else
                        {   
                            TYPE2FORMAT->{unk}{width};
                        }                        
                    }  
                    @{$table->{fields}};

    # создаем заголовки на всех worksheets на которых будет выведен текущий набор данных
    for(my $i = 0; $i <= $#{$table->{sheets}}; $i++)
    {
        my $sheet = $table->{sheets}->[$i];

        # задаём ширину колонки в зависимости от типа
        for (my $j = 0; $j <= $#width; $j++)
        {
            $sheet->{hndl}->set_column($j, $j, $width[$j]); 
        }

        # уминьшаем число строк на число сток входящих в заголовок
        my ($col, $max_rows) = (FIRST_COL, (MAX_ROWS - (FIRST_ROW + 1))); 

        # прописываем описание
        $sheet->{hndl}->write_unicode(FIRST_ROW, $col++, $_, $vars->{FORMATS}{header}) foreach (@{$headers});

        # вычисляем диапазон данных и область на worksheet для их представления
        $sheet->{frow} = FIRST_ROW + 1; # вывод данных после заголовка
        $sheet->{fcol} = FIRST_COL;

        $sheet->{fpos} = $i * $max_rows;

        $sheet->{lrow} = $sheet->{frow} + ((($table->{rows} - $sheet->{fpos}) < $max_rows) ? ($table->{rows} - $sheet->{fpos} ) : ($max_rows));  
        $sheet->{lcol} = FIRST_COL + $#{$table->{fields}} + 1;                                              
    }
    
    return TRUE;
}

#*******************************************************************************
#
# Закрытый метод, формирует тело таблицы
#
sub _make_body
#
#*******************************************************************************
{
    my ($self, $table, $sheet, $order) = (shift, shift, shift, shift); 
    my ($vars)     = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    my ($formats)  = $vars->{FORMATS};
    my ($pos)      = $sheet->{fpos};
    my ($fields)   = $vars->{TABLES}{$table}{FIELDS};
    my ($body)     = $vars->{TABLES}{$table}{DATA};
    my ($triggers) = # формиуем хеш-триггер вида: {field}{value}{format}
        {
            map 
                {
                    my $field = $_;
                    map {$field => {$_ => $fields->{$field}{trigger}{$_}{style}{name}}}
                        grep {defined($fields->{$field}{trigger}{$_}{style}{name})} 
                            keys(%{$fields->{$field}{trigger}})
                }
                grep {defined($fields->{$_}{trigger})}
                    @{$order}
        };

    # цикл печати данных на worksheet
    for (my $row = $sheet->{frow}; $row < $sheet->{lrow}; $row++, $pos++)
    {   
        my $format = 'orig';

        # определяем форматирование по значению полей с установленном форматированием
        # в trigger, поиск формата до первого найденного, остальные не учитываем
        foreach my $field (keys(%{$triggers}))
        {
            next unless (defined($triggers->{$field}{$$body[$pos]->{$field}}));
            $format = $triggers->{$field}{$$body[$pos]->{$field}};
        }

        # печатаем строку
        for(my $col = $sheet->{fcol}; $col < $sheet->{lcol}; $col++)
        {                   
            my $field = $$order[$col - $sheet->{fcol}];
            my $val   = $$body[$pos]->{$field};            
            my $type  = $fields->{$field}{type};

            $val  = $fields->{$field}{value}
                if (exists($fields->{$field}{value}));

            if (defined($fields->{$field}{trigger}) && defined(defined($fields->{$field}{trigger}{$val})))
            {
                $type = $fields->{$field}{trigger}{$val}{type}    
                    if (defined($fields->{$field}{trigger}{$val}{type}));

                $val  = $fields->{$field}{trigger}{$val}{value}   
                    if (defined($fields->{$field}{trigger}{$val}{value}));
            }
            
            $type = 'unk' unless (exists($formats->{$format}{$type}));
            
            unless (defined($val))
            {
                $val = undef;
            }
            elsif (can($val, 'convert'))
            {
                $val = $val->convert('EXCEL');
            }
            elsif ($val eq '')
            {
                $val = undef;
            }
            elsif (!ref($val))
            {                
                $val = RpgTypes::String2String(\$val, $type, $fields->{$field}{schema} || 'SQL', 'EXCEL');
            }            
            else
            {
                die "Error, type of val: '$val'";
            }
            
            # цикл по параметрам столбцов        
            unless (defined($val))
            {
                $sheet->{hndl}->write_blank($row, $col, $formats->{$format}{$type});
            }
            elsif ('str' eq $type || 'txt' eq $type || 'chr' eq $type)
            {                    
                $sheet->{hndl}->write_unicode($row, $col, Win2Utf8Ex(\$val), $formats->{$format}{$type});
            }
            elsif ('flt' eq $type || 'int' eq $type || 'mny' eq $type)
            {            
                $sheet->{hndl}->write_number($row, $col, $val, $formats->{$format}{$type});
            }        
            elsif ('acc' eq $type)
            {            
                $sheet->{hndl}->write_string($row, $col, $val, $formats->{$format}{$type});
            }        
            elsif ('date' eq $type || 'time' eq $type)
            {
                # предпалагается дата в формате ISO8601
                $sheet->{hndl}->write_date_time($row, $col, $val, $formats->{$format}{$type});
            }                
            else
            {
                $sheet->{hndl}->write($row, $col, $val, $formats->{$format}{$type});
            }
        }
    }
    
    return TRUE;
}

1;

