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

package RpgCGICheck;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw($VERSION $PACKAGE @ISA);
use English;
use strict;
use CGI qw (escapeHTML);
use Exporter;
use warnings;
use utils;
use types;

use constant SUPPORT_CHECKS =>
{
    match   => '_match'   , 
    count   => '_count'   , 
    range   => '_range'   , 
    exactly => '_exactly' , 
    compare => '_compare' ,
    size    => '_size'    , 
    pack    => '_pack'    
};

use constant SUPPORT_DIFF_OPER =>
{
    le => sub {$_[0] <= $_[1]},
    ge => sub {$_[0] >= $_[1]},
    eq => sub {$_[0] == $_[1]},
    ne => sub {$_[0] != $_[1]},
    lt => sub {$_[0] < $_[1]},
    gt => sub {$_[0] > $_[1]}
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
#
#  PARAM - хеш содержит следующие элементы
#       SETT    = указатель на объект, источник денамических параметров RpgSett    
#       SESSION = указатель на объект, доступ к параметрам сессии
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
#  Метод проверяет CGI запрос, на соответствие установленым значениям
#  TRUE - при успехи и FALSE - при ошибках
#
sub checking
#
#  CGI    => ссылка на объект CGI, если не задано берется из PARAM
#  FIELDS => описание полей запроса
#  CHECKS => список проверок 
#
#       ,где
#
#       FIELDS = 
#       {
#           field_01 - поле в CGI запросе
#           {
#               type     - тип данных
#               arary    - если определенно, то предполагается список
#               optional - если определенно, то поле может отсутствовать во входном потоке, все проверки пропускаются
#               schema   - если определенно, то формат типа берется этот (например для даты), иначе системный
#           },
#           ...
#       }
#             
#       CHECKS =
#       {
#           match - проверка формата значений 
#           [
#               {field => field_01, exp => '^regexp1$'},    
#               {field => field_02, exp => '^regexp2$'}  
#            ...
#           ],
#           count   - число элементов в списке (списках) значений
#           [   
#               {fields => [field_01, field_02, ...],  min => 1, max => 1},       - один элемент
#               {fields => [field_02],                 min => 1, max => undef},   - число значений от одного и более
#            ...
#           ],
#           range   - диапазон значений
#           [   
#               {field => field_01,  min => 1,     max => 1000},   - от 1 до 1000
#               {field => field_02,  min => 1,     max => undef},  - от 1 и более
#               {field => field_02,  min => undef, max => 1},      - до 1
#            ...
#           ],
#           exactly - проверка на конкретные значения
#           [   
#               {field => field_01,  values => [2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007]},
#            ...
#           ],
#           compare    - проверка разности
#           [
#               {cmp => 'eq', fields => [field_01, field_02, ...], value => 1, oper => '+'}, - меньше или равно
#               {cmp => 'ne', fields => [field_01, field_02, ...], value => 1, oper => '-'}, - больше или равно
#            ...    
#           ],
#           pack   - проверка запакованного значения, формат строки: имя sub_spliter значение spliter имя sub_spliter значение spliter
#           [
#               {
#                   field => field_01,
#                   desc  => 
#                   {
#                       spliter    - символ разделитель 
#                       extractor  - regexp возвращающий пару (имя-параметр)
#                       fields =>  - список имен, если не задан то нет проверки типов полей
#                       {
#                           см. описание поле FIELDS в методе checking
#                           ...
#                       },
#                       сhecks =>  - список имен, если не задан то нет проверки 
#                       {
#                           см. описание поле CHECKS в методе checking
#                           ...
#                       },
#                       ...
#                   },                   
#               },
#               ...
#           ],
#       }
#*******************************************************************************
{
    my ($self) = shift;
    my (%args) = (@_);
    my ($ret)  = FALSE;
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    my ($fields, $checks, $cgi) = ($args{FIELDS} || {}, $args{CHECKS} || {}, $args{CGI} || $set->{CGI});
    
    $vars->{REQUEST} = {}; # здесь будут сохранятся значения из CGI
    $vars->{PACK}    = {}; # здесь будут сохранятся распакованные значения
    $vars->{ERROR}   = ''; # сообщение об ошибке

    unless ($self->_load_fields($cgi, $fields))
    {
        goto _WAS_ERROR;
    }

    foreach my $check (keys(%{$checks}))
    {
        unless (exists(SUPPORT_CHECKS->{$check}))
        {
            warn("Warning, checking '$check' isn't support\n");
            next;
        }
        
        my $method = SUPPORT_CHECKS->{$check};

        goto _WAS_ERROR unless($self->$method($cgi, $fields, $checks->{$check}));
    }
    
    $ret = TRUE;

_WAS_ERROR:
    return $ret;        
}

#*******************************************************************************
#
# Возвращащает количество загруженных параметров
#
sub loaded_fields
#
#*******************************************************************************
{
    my $self = shift;
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    
    return (ref($vars->{REQUEST}) ? scalar(keys(%{$vars->{REQUEST}})) : 0);
}

#*******************************************************************************
#
# Возвращащает ссылку на поля-значения во внутреннем представлении из последнего
# запроса
#
sub last_request
#
#*******************************************************************************
{
    my $self = shift;
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    
    return (ref($vars->{REQUEST}) ? $vars->{REQUEST} : {});
}

#*******************************************************************************
#
# Возвращащает ссылку на поля-значения во внутреннем представлении из последнего
# запроса-пакета
#
sub last_pack
#
#*******************************************************************************
{
    my $self = shift;
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    
    return (ref($vars->{PACK}) ? $vars->{PACK} : {});
}

#*******************************************************************************
#
# Загрузка параметров из запроса
#
sub _load_fields
#
#*******************************************************************************
{
    my ($self)         = shift;
    my ($cgi, $fields) = (shift, shift);
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    my ($ret)  = FALSE;
    
    # цикл по допустимым параметрам в запросе
    foreach my $field (keys(%{$fields}))
    {        
        my $param = [ref($cgi) eq 'HASH' ? @{$cgi->{$field}} : $cgi->param($field)];
        my $count = $#{$param};

        if ($count >= 0)
        {   
            $vars->{REQUEST}{$field} = [];
        }
        elsif (exists($fields->{$field}{optional}))
        {
            next;
        }
        else
        {
            # параметр не опциональный и он небыл определен в запросе
            $vars->{ERROR} .= "\nError, couldn't find param '$field' in CGI request";
            goto _WAS_ERROR;
        }
        
        # скалярное поле может иметь только одно значение
        unless (exists($fields->{$field}{array}) ||  $count == 0)
        {               
            $vars->{ERROR} .= "\nError, param '$field' isn't scalar";
            goto _WAS_ERROR;
        }                
        
        # проверяем соответствие значения типу
        for (my $i = 0; $i <= $count; $i++)
        {
            eval
            {
                $vars->{REQUEST}{$field}->[$i] = 
                    new RpgType(rval => \$$param[$i], type => $fields->{$field}{type}, schema => $fields->{$field}{schema} || 'MAIN');                
            };

            if ($@)
            {
                $vars->{ERROR} .= "\nError, format (type='$fields->{$field}{type}') of value is bad ('$field'='$$param[$i]')\n";
                goto _WAS_ERROR;
            }
        }        
    }

    $ret = TRUE;

_WAS_ERROR:    
    return $ret;
}

#   match - проверка формата значений 
#           [
#               {field => field_01, exp => '^regexp1$'},    
#               {field => field_02, exp => '^regexp2$'}  
#            ...
#           ],
sub _match
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        next unless (defined($vars->{REQUEST}{$check->{field}}));
        
        foreach my $value (map {$_->src} @{$vars->{REQUEST}{$check->{field}}})
        {
            unless ($value =~ /$check->{exp}/i)
            {
                $vars->{ERROR} .= "\nError, found invalid value of field '$check->{field}'='$value', when check match for '$check->{exp}'";
                goto _WAS_ERROR;
            }        
        }
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}

#   count   - число элементов в списке значений
#           [   
#               {fields => [field_01, field_02, ...],  min => 1, max => 1},       - один элемент
#               {fields => [field_02],                 min => 1, max => undef},   - число значений от одного и более
#            ...
#           ],
sub _count   
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        my $count = 0;
        
        foreach my $field (@{$check->{fields}})
        {
            next unless (defined($vars->{REQUEST}{$field}));
            
            $count += $#{$vars->{REQUEST}{$field}} + 1
        }
        
        unless ((!defined($check->{min}) || $check->{min} <= $count) && 
                (!defined($check->{max}) || $check->{max} >= $count))
        {
            $vars->{ERROR} .= "\nError, count of values for field(s) is $count, need between '". (defined($check->{min}) ? $check->{min} : 'undef') . "', '" . (defined($check->{min}) ? $check->{min} : 'undef') . "'";
            goto _WAS_ERROR;
        }        
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}

#   size   - сверка размерностей полей
#           [   
#               [field_01, field_02, ...] - список полей размерности которых должны совпадать
#            ...
#           ],
sub _size   
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        my $size = undef;
        
        foreach my $field (@{$check})
        {
            next unless (defined($vars->{REQUEST}{$field}));
            
            $size = $#{$vars->{REQUEST}{$field}} unless (defined($size));
            
            next if ($size == $#{$vars->{REQUEST}{$field}});
            
            # несовпадение размерностей

            $vars->{ERROR} .= sprintf("\nError, size of field '$field' is %d, need: %d", $#{$vars->{REQUEST}{$field}} + 1, $size + 1);
            goto _WAS_ERROR;            
        }        
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}
 
#   range   - диапазон значений
#           [   
#               {field => field_01,  min => 1,     max => 1000},   - от 1 до 1000
#               {field => field_02,  min => 1,     max => undef},  - от 1 и более
#               {field => field_02,  min => undef, max => 1},      - до 1
#            ...
#           ],
sub _range
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        next unless (defined($vars->{REQUEST}{$check->{field}}));
        
        foreach my $value (@{$vars->{REQUEST}{$check->{field}}})
        {
            unless ((!defined($check->{min}) || $check->{min} <= $value) && 
                    (!defined($check->{max}) || $check->{max} >= $value))
            {
                $vars->{ERROR} .= "\nError, range of value for field '$check->{field}' is $value, need between '". (defined($check->{min}) ? $check->{min} : 'undef') . "', '" . (defined($check->{max}) ? $check->{max} : 'undef') . "'";
                goto _WAS_ERROR;
            }        
        }
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}

#   exactly - проверка на конкретные значения
#           [   
#               {field => field_01,  values => [2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007]},
#            ...
#           ],
sub _exactly
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        next unless (defined($vars->{REQUEST}{$check->{field}}));

        my %tmp;
        @tmp{@{$check->{values}}} = ();
        
        foreach my $value (map {$_->value} @{$vars->{REQUEST}{$check->{field}}})
        {
            unless (exists($tmp{$value}))
            {
                $vars->{ERROR} .= "\nError, value for field '$check->{field}' is '$value' and it not exactly";
                goto _WAS_ERROR;
            }        
        }
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}


#   compare    - проверка разности
#           [
#               {cmp => 'eq', fields => [field_01, field_02, ...], value => 1, oper => '+'}, - меньше или равно
#               {cmp => 'ne', fields => [field_01, field_02, ...], value => 1, oper => '-'}, - больше или равно
#            ...    
#           ],
sub _compare
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my ($ret)  = FALSE;
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    foreach my $check (@{$checks})
    {
        my $sum = undef;
        
        foreach my $field (@{$check->{fields}})
        {
            next unless (defined($vars->{REQUEST}{$field}));
            
            foreach (@{$vars->{REQUEST}{$field}})
            {
                unless (defined($sum))
                {
                    $sum = $_ + 0;
                }                        
                elsif ($check->{oper} eq '+')
                {
                    $sum += $_;
                }
                elsif ($check->{oper} eq '-')
                {
                    $sum -= $_;
                }
                else
                {
                    $vars->{ERROR} .= "\nError, operation '$check->{oper}' isn't support, for method diff in RpgCGICheck";
                    goto _WAS_ERROR;                
                }
            }
        }
        
        next unless (defined($sum));
        
        if (defined(SUPPORT_DIFF_OPER->{$check->{cmp}}))
        {
            next if(SUPPORT_DIFF_OPER->{$check->{cmp}}($sum, $check->{value}));
            $vars->{ERROR} .= "\nError, $sum $check->{cmp} $check->{value} isn't true compare";
            goto _WAS_ERROR;                            
        }
        
        $vars->{ERROR} .= "\nError, operation $check->{cmp} isn't support";
        goto _WAS_ERROR;                            
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
} 

# pack - проверка запакованного значения, формат строки: имя sub_spliter значение spliter имя sub_spliter значение spliter
#           [
#               {
#                   field => field_01,
#                   desc  => 
#                   {
#                       spliter    - символ разделитель 
#                       extractor  - regexp возвращающий пару (имя-параметр)
#                       fields =>  - список имен, если не задан то нет проверки типов полей
#                       {
#                           см. описание поле FIELDS в методе checking
#                           ...
#                       },
#                       сhecks =>  - список имен, если не задан то нет проверки 
#                       {
#                           см. описание поле CHECKS в методе checking
#                           ...
#                       },
#                       ...
#                   },                   
#               },
#               ...
#           ],
sub _pack 
{
    my ($self, $cgi, $fields, $checks) = (shift, shift, shift, shift);
    my $ret     = FALSE;
    my $vars    = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $checker = new RpgCGICheck();
    
    foreach my $check (@{$checks})
    {
        next unless (defined($vars->{REQUEST}{$check->{field}}));
        
        foreach my $value (map {$_->value} @{$vars->{REQUEST}{$check->{field}}})
        {
            my %param     = ();
            my $extractor = $check->{desc}{extractor};
            
            foreach (split($check->{desc}{spliter}, $value))
            {
                my ($field, $meaning) = ($_ =~ /$extractor/s);

                unless (defined($field))
                {
                    $vars->{ERROR} .= "\nError, invalid format of pack field '$check->{field}' : '$value', for spliter='$check->{desc}{spliter}' and extractor='$extractor'";
                    goto _WAS_ERROR;                            
                }
                
                $param{$field} = []
                    unless (defined($param{$field}));
                
                push (@{$param{$field}}, $meaning);
            }
            
            if ($checker->checking(CGI => \%param, FIELDS => $check->{desc}{fields}, CHECKS => $check->{desc}{checks}))
            {
                $vars->{PACK}{$check->{field}} = [] unless (defined($vars->{PACK}{$check->{field}}));
                push (@{$vars->{PACK}{$check->{field}}}, $checker->last_request);
                next;
            }           

            $vars->{ERROR} .= "\nError, invalid format of pack: '$value', for spliter='$check->{desc}{spliter}' and extractor='$extractor'";
            $vars->{ERROR} .= $checker->errstr;
            goto _WAS_ERROR;                               
        }        
    }    
    
    $ret = TRUE;

_WAS_ERROR:        
    return $ret;
}


1;
