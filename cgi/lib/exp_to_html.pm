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

package RpgExportToHtml;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);
use UNIVERSAL qw(isa can);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use Template;
use English;
use strict;
use warnings;
use CGI;
use utils;
use types;

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
#   TT      = указатель на объект, TemplateToolkit
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
    
    $self->{$PACKAGE}{ERROR} = '';  # сообщение о ошибке
    
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
#  Вызов функции экспорта-представлениия данных в HTML формате, данные направляются 
#  в STDOUT
#
sub export
#  
#  хеш, в следующем фомате:#  
#       TITLE    - имя-описание отчета
#       TEMPLATE - шаблон в формате TT2
#       PARAM    = ссылка на хеш, содержит параметры которые будут переданны шаблону
#       TABLES   = ссылка на хеш, содержит параметры и данные для вывода в TT2
#       {
#           TABLE_01 = ссылка на хеш (имя ссылки, он же ключь хеша доступ к данным из TT2 через этот ключ), 
#                     содержит параметры и данные выводимой таблицы
#           {
#               TITLE - имя-описание таблицы
#               DATA  - ссылка на массив хешей, содержит данные для отображения в таблице TABLE_01
#               SKEEP - если определенно то пропустить печать таблицы, решается шаблоном 
#               ORDER - порядок вывода таблиц, не поддерживается, решается шаблоном 
#               FIELDS = ссылка на хеш, содержит описание полей таблицы
#               {
#                   FIELD_01 = ссылка на хеш, содержит описание поля таблицы
#                   {
#                       type      - тип данных поля
#                       desc      - описание поля
#                       order     - если определенно, то следовать заданному порядку вывода
#                       hide      - если определенно, то поле выводится но не отображается
#                       button    - если определенно, то элементы поля должны быть представленны ввиде кнопки
#                       key       - если определенно, то поле входит в уникальный идентификатор строки таблицы
#                       uniq      - если определенно, то значения поля уникальны
#                       change    - если определенно, то разрешено изменять значение поля
#                       to_row    - если определенно, то задать значение свойства тега, имя свойства берётся из to_row, а значение текущее без учета триггера
#                       format    - если определенно, установить формат
#                       schema    - если определенно, то исползовать эту схему при конвертации
#                       attribute - если определенно, установить свойство у тега
#                       value     - если определенно, заменить значением
#                       trigger = если определенно, то выполнить дополнительные действия в зависимости от значения
#                       {
#                           value_01 = ссылка на хеш, содержит описание триггера поля
#                           {
#                               value     - если определенно, заменить значением, более высокий приоритет
#                               type      - если определенно, новый тип
#                               attribute - если определенно, установить свойство у тега, более высокий приоритет
#                               style = опции форматирования поля
#                               {
#                                   name   - имя стиля
#                               }
#                           }
#                       },
#                       style = опции форматирования поля
#                       {
#                           name   - имя стиля
#                           width  - ширина поля
#                           align  - выравнивание
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

    $self->{$PACKAGE}{ERROR}  = '';
    $self->{$PACKAGE}{TABLES} = $args{TABLES};
        
    # печать тела шаблона
    unless  ($self->{TT}->process
                (
                    $args{TEMPLATE},
                    {                             
                        title    => $args{TITLE},
                        executor => $self,
                        tables   => $args{TABLES},
                        %{$args{PARAM} || {}}
                    }
                )
            )
    {
        $self->{$PACKAGE}{ERROR} .= $self->{TT}->error();
        return FALSE;    
    }

    return TRUE;        
    
}

#*******************************************************************************
#
# 
#
sub get_title
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    my ($vars) = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета    
    
    return $vars->{TABLES}{$from}{TITLE};
}

#*******************************************************************************
#
# 
#
sub get_rows
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    my $vars = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета
    
    return ($vars->{TABLES}{$from}{DATA} || []);
}

#*******************************************************************************
#
# 
#
sub get_table
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    my $vars = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета
    
    return $vars->{TABLES}{$from}{DATA};
}

#*******************************************************************************
#
# 
#
sub get_fields
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);    
    my ($vars) = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета    
    
    exists($vars->{TABLES}{$from}{FIELDS}) || die "Error, can't find fields set for '$from'";
    
    # содержит ссылку на хеш описания полей печатаемой таблицы   
    my ($fields) = $vars->{TABLES}{$from}{FIELDS};
    my ($order)  = 
        [
            # то что сортируемо
            (sort {$fields->{$a}{order} <=> $fields->{$b}{order}} grep {defined($fields->{$_}{order})} keys(%{$fields})), 
            # все остальное не содержит поля order
            (grep {!defined($fields->{$_}{order})} keys(%{$fields}))
        ]; 
    my ($ret)    = [];        
    
    # цикл определения параметров полей
    foreach my $field (@{$order})
    {
        $$ret[$#{$ret} + 1] = {};
        $$ret[$#{$ret}]->{name}   = $field;
        $$ret[$#{$ret}]->{type}   = $fields->{$field}{type};
        $$ret[$#{$ret}]->{desc}   = $fields->{$field}{desc};
        $$ret[$#{$ret}]->{hide}   = exists($fields->{$field}{hide}) ? $fields->{$field}{hide}   : 0;
        # если доступ только на просмотр, то редактирование полей не допустимо (change = 0)
        $$ret[$#{$ret}]->{change} = (2 == $self->{SESSION}->access() && exists($fields->{$field}{change})) ? $fields->{$field}{change} : 0;
        $$ret[$#{$ret}]->{key}    = exists($fields->{$field}{key})    ? $fields->{$field}{key}    : 0;
        $$ret[$#{$ret}]->{button} = exists($fields->{$field}{button}) ? $fields->{$field}{button} : 0;
        $$ret[$#{$ret}]->{uniq}   = exists($fields->{$field}{uniq})   ? $fields->{$field}{uniq}   : 0;
        $$ret[$#{$ret}]->{style}  = exists($fields->{$field}{style})  ? $fields->{$field}{style}  : {};
    }

    return $ret;       
}

#*******************************************************************************
#
# 
#
sub get_body
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    
    my ($ret)  = '';              
    my ($vars) = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета    

    exists($vars->{TABLES}{$from}{FIELDS}) || die "Error, can't find fields set for '$from'";
    exists($vars->{TABLES}{$from}{DATA})   || die "Error, can't find data set for '$from'";

    return $ret unless($#{$vars->{TABLES}{$from}{DATA}} >= 0);  # пустой запрос    
    
    # содержит ссылку на хеш описания полей печатаемой таблицы 
    my ($fields) = $vars->{TABLES}{$from}{FIELDS};
    my ($order)  = 
        [
            # то что сортируемо
            (sort {$fields->{$a}{order} <=> $fields->{$b}{order}} 
                grep {defined($fields->{$_}{order})}                 
                    keys(%{$fields})), 
            # все остальное не содержит поля order
            (grep {!defined($fields->{$_}{order})} keys(%{$fields}))
        ]; 
    # содержит ссылку на хеш данных печатаемой таблицы 
    my ($data) = $vars->{TABLES}{$from}{DATA};     
   
    foreach my $row (@{$data})    
    {
        my ($tr, $to_row) = ('', '');
        
        foreach my $field (@{$order})
        {                        
            my $val   = $row->{$field};
            my $type  = $fields->{$field}{type};
            my ($class, $attribute);

            $to_row .= " $fields->{$field}{to_row}='$val'"
                if (defined($fields->{$field}{to_row}));

            $class     = $fields->{$field}{style}{name}
                if (defined($fields->{$field}{style}{name}));

            $attribute = $fields->{$field}{attribute}
                if (defined($fields->{$field}{attribute}));

            $val        = $fields->{$field}{value}
                if (exists($fields->{$field}{value}));

            if (defined($fields->{$field}{trigger}) && defined($fields->{$field}{trigger}{$val}))
            {
                $type      = $fields->{$field}{trigger}{$val}{type}    
                    if (defined($fields->{$field}{trigger}{$val}{type}));

                $class     = $fields->{$field}{trigger}{$val}{style}{name}
                    if (defined($fields->{$field}{trigger}{$val}{style}{name}));

                $attribute = $fields->{$field}{trigger}{$val}{attribute}
                    if (defined($fields->{$field}{trigger}{$val}{attribute}));

                $val       = $fields->{$field}{trigger}{$val}{value}   
                    if (defined($fields->{$field}{trigger}{$val}{value}));
            }

            $tr .= '<td' . (defined($class) ? " class='$class'" : '') . (defined($attribute)? " $attribute" : '') . '>';
            
            unless (defined($val))
            {
                $val = '';
            }
            elsif (can($val, 'convert'))
            {
                $val = $val->convert('HTML');
            }
            elsif ($val eq '')
            {
            }
            elsif (!ref($val))
            {
                $val = RpgTypes::String2String(\$val, $type, $fields->{$field}{schema} || 'SQL', 'HTML');
            }
            else
            {                
                die "Error, type of val: '$val'";
            }
            
            $tr .= "$val</td>";                
        }        
        $ret .= "<tr$to_row>$tr</tr>";
    }
    
    return $ret;
}

1;
