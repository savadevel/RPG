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

package RpgSQLMake;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw($VERSION $PACKAGE @ISA);
use Template;
use English;
use strict;
use warnings;
use CGI;
use utils;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw();
}

#*******************************************************************************
#  Класс конверитрования внутреннего типа в тип данных SQL
#*******************************************************************************
{
    package RpgSQLTypes;
    
    use vars qw($AUTOLOAD);
    
    sub AUTOLOAD
    {
        my $self  = shift;
        my $param = $AUTOLOAD;        

        return 'varchar';
    }
    
    DESTROY { }
       
    sub new {return bless({}, shift);}    

    sub date {return 'datetime';}   
    sub time {return 'datetime';}   
    sub int  {return 'int';     }
    sub long {return 'bigint';  }
    sub bool {return 'bit';     }         
    sub flt  {return 'float';   }       
    sub mny  {return 'money';   }   
    sub str  {return 'varchar'; }
    sub ip   {return 'varchar'; }
    sub txt  {return 'varchar'; }                                     
    sub acc  {return 'char';    }                 
    sub chr  {return 'char';    }
    sub byte {return 'char';    }

    1;
}

#*******************************************************************************
#
#  Конструктор RpgSQLMake
#
sub new
#
#
#*******************************************************************************
{
    ref($_[0]) && die "Error, class F136::RpgSQLMake can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = (ref($class) ? $class : bless({@_}, $class));
           
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
DESTROY
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
# Создание SQL запроса (SELECT)
# 
sub select
#
#    SELECT  - массив содержит поля которые должны быть взяты из источника (FROM)
#            [
#                {
#                    field => 'name01'           - имя поля из FROM
#                    func  => 'sum'              - функция обрамляющая поле
#                    hide  => TRUE               - признак скрытия поля в предложении SELECT
#                    as_is => TRUE               - признак подстановки поля как есть, без []
#                    alias => 'alias01'          - as alias01
#                }  
#            ]
#    FROM    - источник записей (таблица, запрос, функция и т.д.), см. описание метода from
#              подставляется в SQL инструкциб FROM как вложенный запрос
#    WHERE   - указания по формированию предложения WHERE
#    ORDER   - сортировка полей источника
#           [
#               {
#                    field       => 'name01'
#                    direction   => 'asc' | 'desc'
#               }
#           ]
#    GROUP   - группировка полей источника
#           [
#               {
#                    field  => 'name01'
#               }
#           ]
#    FIELDS  - описание полей источника записей
#    CGI     - ссылка на CGI объект, источник значений для предложения WHERE
#    REQUEST - описание полей запроса CGI
#
#*******************************************************************************
{
    my $self = shift;
    my %args = (@_);
    my $ret  = undef;
    
    my @select;
    
    foreach my $field (@{$args{SELECT}})
    {
        next if (defined($field->{hide}));
        push (@select, $field->{field});
        
        $select[$#select] = "[$select[$#select]]"
            if (!defined($field->{as_is}));

        $select[$#select] = "$field->{func}($select[$#select])"
            if (defined($field->{func}));

        $select[$#select] = "$select[$#select] as $field->{alias}"
            if (defined($field->{alias}));
    }
    
    $ret  = "select " . (join(",", @select)) . " \n";            
    $ret .= $self->from(@_);    
    $ret .= $self->where(@_);
    $ret .= "group by " . (join(",", map {"[$_->{field}]"} @{$args{GROUP}})) . " \n"
        if (defined($args{GROUP}) && $#{$args{GROUP}} >= 0);
    $ret .= "order by " . (join(",", map{"[$_->{field}] " . ($_->{direction} || '')} @{$args{ORDER}})) . " \n"
        if (defined($args{ORDER}) && $#{$args{ORDER}} >= 0);
        
    return $ret;
}   

#*******************************************************************************
# 
# Создание параметризованного вызова процедуры
#
sub procedure
#
#
#    DESC     - указания по формированию вызова процедуры, ссылка на хеш вида
#               {
#                  src    => 'TEMPLATE',           - шаблон источника
#                  params => [
#                               {
#                                   field   => param01,
#                                   options => 
#                                   {
#                                       array   => TRUE,  - если ключ определен то параметор должен быть представлен ввиде списка
#                                       spliter => ',',   - символ разделитель (по умолчанию пустышка)
#                                       wrap    => "'",   - символ обрамляющий элемениы списка
#                                       type    => 'int'  - тип данных имеет более высокий приоритет чем значение из REQUEST
#                                       schema  => '',    - формат данных
#                                   }
#                               },        
#                               ...
#                           ]
#               }
#    CGI      - ссылка на CGI объект, источник значений для предложения WHERE           
#    REQUEST  - описание полей запроса CGI
#
#
#*******************************************************************************
{
    my ($self) = shift;
    my (%args) = (@_);        
    return $self->_from(FROM    => $args{DESC}, 
                        CGI     => $args{CGI}, 
                        REQUEST => $args{REQUEST});
}

#*******************************************************************************
# 
# Создание SQL инструкции FROM
#
sub from
#
#    FROM     - имя таблицы
#    или
#    FROM     - указания по формированию предложения FROM, строка или ссылка на хеш вида
#               {
#                  single => 1,                    - признак что таблица единственная, таблица будет без () t 
#                  alias  => 'name'                - псевдо имя таблицы
#                  src    => 'TEMPLATE',           - шаблон источника
#                  params => [
#                               {
#                                   field   => param01,
#                                   options => 
#                                   {
#                                       array   => TRUE,  - если ключ определен то параметор должен быть представлен ввиде списка
#                                       spliter => ',',   - символ разделитель (по умолчанию пустышка)
#                                       wrap    => "'",   - символ обрамляющий элемениы списка
#                                       type    => 'int'  - тип данных имеет более высокий приоритет чем значение из REQUEST
#                                       schema  => '',    - формат данных
#                                   }
#                               },        
#                               ...
#                           ]
#               }
#    CGI      - ссылка на CGI объект, источник значений для предложения WHERE           
#    REQUEST  - описание полей запроса CGI
#
#*******************************************************************************
{
    my $self = shift;
    my %args = (@_);
    my $ret;

    unless (defined($args{FROM}))
    {
        $ret = '';
    }
    elsif (!ref($args{FROM}))
    {
        $ret = $args{FROM};
    }
    elsif ('HASH' eq ref($args{FROM}))
    {
        $ret = $self->_from(@_);

        if (defined($ret))
        {
            my $alias = (defined($args{FROM}->{alias}) ? $args{FROM}->{alias} : 't');
            $ret      = (exists($args{FROM}->{single}) ? "from $ret $alias \n" : "from ($ret) $alias \n");
        }                                                                                            
    }
    else
    {
        die sprintf("Error, invalid type value of key FROM, in hash: ", ref($args{FROM}));
    }

    return $ret;
}

#*******************************************************************************
#
sub _from
#
#*******************************************************************************
{
    my ($self)   = shift;
    my (%args)   = (@_);
   
    return unless (defined($args{FROM}));            # значение не определенно, значит пустой источник
    return $args{FROM} unless (ref($args{FROM}));    # это не темплет (т.е. не ссылка), а имя источника

    my @params;
    
    # цикл по параметрам шаблона
    foreach (@{$args{FROM}->{params}})    
    {        
        # определяем тип парметра (значение из запроса имеет более низкий приоритет)
        my $name    = $_->{field};
        my $param   = $_->{options}    || {};
        my $type    = $param->{type}   || $args{REQUEST}->{$name}{type};
        my $schema  = $param->{schema} || $args{REQUEST}->{$name}{schema} || 'MAIN';
        my @values  = ($args{CGI}->param($name));
        
        unless ($#values >= 0)
        {   
            # если значение не определенно то 'null'        
            push @params, 'null';
            next;
        }        
        elsif(!defined($param->{array}))
        {
            # если значение не список
            push @params, RpgTypes::String2String(\$values[0], $type, $schema, 'SQL');
            next;
        }
        
        my $spliter = (defined($param->{spliter}) ? $param->{spliter} : ''); 
        my $wrap    = (defined($param->{wrap})    ? $param->{wrap} : '');

        # собираем список и добавляем в массив значений
        push @params, ($wrap . join($spliter, map{RpgTypes::String2String(\$_, $type, $schema, 'SQL')} @values) . $wrap);
    }
    
    return (sprintf($args{FROM}->{src}, @params));
}

#*******************************************************************************
# 
# Создание SQL инструкции WHERE
#
sub where
#
#    WHERE    - указания по формированию предложения WHERE
#    FIELDS   - описание полей источника записей
#    CGI      - ссылка на CGI объект, источник значений для предложения WHERE
#    REQUEST  - описание полей запроса CGI
#    LISTVALS - ссылка на массив (опционально), будут добавленны поля в порядке 
#               использования
#
#    [{f1 => v1}, {f2 => v2}]
#       where f1 = v1 or f2 = v2
#
#    (f1 => v1, f2 => v2)
#       where f1 = v1 and f2 = v2
#
#    (f1 => v1, f2 => [v1, v2, ...])
#       where f1 = v1 and (f2 = v1 or f2 = v2 or f2 = v3 ...)
#
#    (f1 => v1, f2 => {'in' => [v1, v2, ...]})
#       where f1 = v1 and f2 in (v1, v2, ...)
#
#    (f1 => v1, f2 => {'in' => [v1, v2, ...], '=' => v3})
#       where f1 = v1 and f2 in (v1, v2, ...) and f2 = v3
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($ret)  = $self->_where(@_);
    return (defined($ret) ? "where $ret \n" : "");

}

#*******************************************************************************
#
sub _where
#
#*******************************************************************************
{
    my ($self)   = shift;
    my (%args)   = (@_);        
    my ($cmp)    = ((exists($args{OPER}) and exists($args{OPER})) ? $args{OPER} : '=');
    my ($src)    = (defined($args{CGI}) and defined($args{REQUEST}));
    my (@ret, $join);
    
    # если WHERE не определенно возвращаем пустышку
    return undef unless(exists($args{WHERE}) and defined($args{WHERE}));
    
    if ('ARRAY' eq ref($args{WHERE}))
    {
        $join = ((exists($args{JOIN})) ? $args{JOIN} : ' or ');
        
        # значение массив, т.е. конструкция вида [{f1 => v1}, {f2 => v2}] 
        # операции объединяются всоответствии со значением JOIN
        push @ret, grep {defined}
                    map
                    {    
                        if ('HASH' eq ref($_))
                        {
                            # конструкция вида [{f1 => v1}, ..
                            $self->_where(@_, WHERE => {%{$_}});
                        }
                        elsif ('CODE' eq ref($_))
                        {                            
                            $_->(@_);
                        }
                        else
                        {
                            die "Error, incorrect format, expectation value HASH or ARRAY, but '" . ref($_) . "'\n" ;
                        }                        
                    }
                    (@{$args{WHERE}});        
    }
    elsif ('HASH' eq ref($args{WHERE}))
    {    
        $join = ((exists($args{JOIN})) ? $args{JOIN} : ' and ');
        
        # цикл по ключам хеша, формируем пары и сохраняем их в массив ret
        foreach my $field (sort keys(%{$args{WHERE}}))
        {
            my $val  = $args{WHERE}->{$field};
            my $name = $field;      
                    
            if (!defined($val))
            {   # если значение не определено для поля то предполагаем сравнение с NULL
                push @ret, '[' . $name . '] is null';      
                push @{$args{LISTVALS}}, undef if (exists($args{LISTVALS}));
                next;
            }        
            elsif (!ref($val))
            {
                # скаляр, т.е. конструкция вида f1 => v1
                # если в запросе параметру соответствует несколько значений, то соединяются значения по 
                # OR
                my ($mean) = $self->_where(@_, WHERE => {($field) => [$val]});                
                push @ret, $mean if (defined($mean));            
            }
            elsif ('ARRAY' eq ref($val))
            {
                # массив, т.е. конструкция вида f2 => [v1, v2, ...]
                # значения объединяем по OR
                my @mean;
                
                @mean = grep {defined}
                        map
                            {   
                                my $param = $_;
                                
                                push @{$args{LISTVALS}}, $name 
                                    if (exists($args{LISTVALS}));
                                
                                (
                                    $src ?
                                        map 
                                        {
                                            if (defined($_))
                                            {
                                                RpgTypes::String2String(\$_, $args{REQUEST}->{$param}{type}, $args{REQUEST}->{$param}{schema} || 'MAIN', 'SQL');
                                            }
                                            else
                                            {
                                                undef;
                                            }
                                        } $args{CGI}->param($param) :
                                        '%s'
                                );
                            }
                            @{$val};
                
                next if ($#mean < 0);
                
                if ('in' eq $cmp)
                {
                    push @ret, "[$name] in ("  . join(',', @mean) . ')';
                }
                else
                {
                    push @ret, "[$name] $cmp " . join(" or [$name] $cmp ", @mean);                
                    $ret[$#ret] = "($ret[$#ret])" if ($#mean > 0);
                }                       
            }
            elsif ('HASH' eq ref($val))
            {
                # хешь, т.е. конструкция вида f2 => {'in' => [v1, v2, ...], 'eq' => v3}
                my @mean;
                @mean = grep {defined}
                        map
                        {  
                            $self->_where(@_,
                                          OPER  => $_, 
                                          WHERE => {($field) => ($val->{$_})});
                        }
                        keys(%{$val});
                push @ret, join(' and ', @mean) if ($#mean >= 0);
            }
        }   
    }
    
    return ($#ret >= 0 ? join ($join, @ret) : undef);
}   

#*******************************************************************************
# 
# Создание SQL на обновление
#
sub update
#
#    TABLE     - имя таблицы
#    WHERE     -
#    FIELDS    - список полей SQL таблицы, с описанием типа
#    FIELDVALS - список полей-значений, в формате
#                {field1_sql => field1_cgi, field2_sql => field2_cgi, ...} - тогда должныбыть указаны CGI и REQUEST
#              или
#                {field1_sql => field1_sql, field2_sql => field2_sql, ...}
#
#    CGI       - объект CGI
#    REQUEST   - описание полей CGI запроса
#
#*******************************************************************************
{
    my ($self)   = shift;
    my (%args)   = (@_);
    my ($ret)    = undef;
    my ($src)    = (defined($args{CGI}) and defined($args{REQUEST}));
   
    $ret  = "update $args{TABLE} set \n";
    $ret .= (join(', ',  grep {defined}
                        map 
                        {
                            my ($fcgi) = $args{FIELDVALS}->{$_};
                            my ($fsql) = $_;                                                        
                            
                            push @{$args{LISTVALS}}, $_ if (exists($args{LISTVALS}));
                            
                            if ($src && defined($args{CGI}->param($fcgi)))
                            {
                                "[$fsql]=" . (RpgTypes::String2String($args{CGI}->param($fcgi), $args{REQUEST}->{$fcgi}{type}, $args{REQUEST}->{$fcgi}{schema} || 'MAIN', 'SQL'));
                            }
                            elsif(!$src)
                            {
                                "[$fsql]=\%s";
                            }
                            else
                            {
                                undef;
                            }
                        } keys(%{$args{FIELDVALS}}))) . "\n";
    #$ret .= $self->from(FROM    => $args{TABLE}, 
    #                    CGI     => $args{CGI}, 
    #                    REQUEST => $args{REQUEST});
    $ret .= $self->where(@_);
    
    return $ret;
}   

#*******************************************************************************
# 
# Создание SQL на удаление
#
sub delete
#
#    TABLE     - имя таблицы
#    WHERE
#    FIELDS    - список полей SQL таблицы, с описанием типа
#
#    CGI       - объект CGI
#    REQUEST   - описание полей CGI запроса
#
#*******************************************************************************
{
    my ($self) = shift;
    my (%args) = (@_);
    my ($ret)  = undef;    
    
    $ret  = "delete \n";
    $ret .= $self->from(FROM    => $args{TABLE}, 
                        CGI     => $args{CGI}, 
                        REQUEST => $args{REQUEST});
    $ret .= "\n";
    $ret .= $self->where(@_);

    return $ret;
}   

#*******************************************************************************
# 
# Создание SQL на добавление
#
sub insert
#
#    TABLE     - имя таблицы
#    FIELDVALS - список полей-значений, в формате
#                {field1_sql => field1_cgi, field2_sql => field2_cgi, ...} - тогда должныбыть указаны CGI и REQUEST
#              или
#                {field1_sql => field1_sql, field2_sql => field2_sql, ...}
#    FIELDS    - список полей SQL таблицы, с описанием типа
#    CGI       - объект CGI
#    REQUEST   - описание полей CGI запроса
#
#*******************************************************************************
{
    my ($self)   = shift;
    my (%args)   = (@_);
    my ($ret)    = undef;
    my ($src)    = (defined($args{CGI}) and defined($args{REQUEST}));
    
    $ret  = "insert into $args{TABLE} ";
    $ret .= "( " . (join(', ', grep {defined}
                        map 
                        {
                            if ($src and !defined($args{CGI}->param($args{FIELDVALS}->{$_})))
                            {
                                undef;
                            }
                            else
                            {
                                "[". ($_) . "]";
                            }                        
                        } 
                        keys(%{$args{FIELDVALS}}))) . ") ";    
    $ret .= "values ";
    $ret .= "( " . (join(', ',  grep {defined}
                        map 
                        {
                                my ($fcgi) = $args{FIELDVALS}->{$_};
                                my ($fsql) = $_;

                                push @{$args{LISTVALS}}, $_ if (exists($args{LISTVALS}));

                                if ($src && defined($args{CGI}->param($fcgi)))
                                {
                                    my $val = $args{CGI}->param($fcgi);
                                    RpgTypes::String2String($val, $args{REQUEST}->{$fcgi}{type}, $args{REQUEST}->{$fcgi}{schema} || 'MAIN', 'SQL');
                                }
                                elsif(!$src)
                                {
                                    '%s';
                                }
                                else
                                {
                                    undef;
                                }
                        } keys(%{$args{FIELDVALS}}))) . ") ";    
    
    return $ret;
}   

#*******************************************************************************
# 
# SQL на создание таблицы
#
sub create
#
#    TABLE   - имя таблицы
#    FIELDS  - список полей SQL таблицы, с описанием типа
#
#*******************************************************************************
{
    my $self   = shift;
    my %args   = (@_);
    my $ret    = undef;
    my $types  = new RpgSQLTypes;
    my @fields =
        map 
        {
            my $length = (defined($args{FIELDS}->{$_}{length}) ? $args{FIELDS}->{$_}{length} : undef);
            my $type   = $args{FIELDS}->{$_}{type}; $type = $types->$type();

            (defined($length) ? "$_ $type($length)" : "$_ $type");
        }
        keys(%{$args{FIELDS}});
    my @keys   = grep {exists($args{FIELDS}->{$_}{key})} keys(%{$args{FIELDS}});

    $ret  = "create table $args{TABLE} ";
    $ret .= "(";
    $ret .= join(', ', @fields);
    $ret .= ($#keys >= 0 ? ', primary key (' . (join(', ', @keys)) . ')' : '');
    $ret .= ") ";

    return $ret;
}

#*******************************************************************************
#
#   Формирует инструкцию для по страничного вывода данных
#
sub paging
#
#   METHOD      - метод-процедура формирования страничного представления данных
#   SELECT      - инструкция SQL на выборку
#   FIRST_ROW   - номер первой записи
#   ROWS        - количество записей
#
#*******************************************************************************
{
    my $self   = shift;
    my %args   = (@_);
    my $select = RpgTypes::String2String($args{SELECT}, 'str', 'MAIN', 'SQL');
    
    # чистка инструкции
    $select =~ s/(?:\n\r)|(?:\n)|(?:\s{2,})/ /mgo;
    $select =~ s/(^\s+)|(\s+$)//mgo;    
    
    return (sprintf($args{METHOD},
                    $select,
                    RpgTypes::String2String($args{FIRST_ROW}, 'int', 'MAIN', 'SQL'),
                    RpgTypes::String2String($args{ROWS},  'int', 'MAIN', 'SQL')
            ));
}

1;
