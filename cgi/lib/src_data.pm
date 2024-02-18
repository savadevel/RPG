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

package RpgSrcData;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw($VERSION $PACKAGE @ISA @EXPORT);
use Template;
use English;
use Exporter;
use strict;
use warnings;
use CGI;
use utils;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(CreateGroup);
}

#*******************************************************************************
#  Класс для навигации по элементам массива строк хешей
#  структура вида возвращаемого fetchall_arrayref({})
#*******************************************************************************
{
    package RpgSrcDataRow;
    
    use vars qw($AUTOLOAD);
    
    sub AUTOLOAD
    {
        my $self  = shift;
        my $param = $AUTOLOAD;
        my $row   = $self->{DATA}->[$self->{ROW}];
        
        $param =~ s/.*:://;
        $param = lc($param);
        
        return $row->{(lc($param))}
            if (exists($row->{(lc($param))}));        
        die("Undefined call $AUTOLOAD");
    }
    
    DESTROY
    {
    }
       
    sub new
    {
        my ($class)   = shift;
        my ($self)    = (ref($class) ? $class : bless({}, $class));        
        $self->{DATA} = shift;
        $self->{ROW}  = ($#{$self->{DATA}} == -1 ? -1 : 0);
        return $self;
    }
    
    # изменение номера строки
    sub set_num
    {
        my $self  = shift;
        my $pos   = shift || 0;
        
        $pos >= 0 || die "Error, invalid value of pos=$pos";        
        ($self->{ROW}, $pos) = ($pos, $self->{ROW});
        
        return $pos;
    }
    
    # добавить строку
    sub add_row
    {
        my $self = shift;
        my $row  = shift || {};
        my $pos  = ($#_ >= 0 ? shift : $self->{ROW} + 1);
        
        $pos >= 0 || die "Error, invalid value of pos=$pos";                
        ($self->{DATA}->[$pos], $row) = ($row, $self->{DATA}->[$pos]);
        $self->{ROW} = $#{$self->{DATA}};
        
        return $row;
    }    

    # возвращает ссылку на строку
    sub get_row
    {
        my $self = shift;
        my $pos  = ($#_ >= 0 ? shift : $self->{ROW});
        
        $pos >= 0 || die "Error, invalid value of pos=$pos";                
        
        return $self->{DATA}->[$pos];
    }    

    # установить значение поля
    sub set_value
    {
        my $self = shift;
        my $key  = shift;
        my $val  = shift;
        my $pos  = ($#_ >= 0 ? shift : $self->{ROW});
        
        $pos >= 0 || die "Error, invalid value of pos=$pos";        
        exists($self->{DATA}->[$pos]->{$key}) || die "Error, not found key = $key in RpgSrcDataRow";        
        ($self->{DATA}->[$pos]->{$key}, $val) = ($val, $self->{DATA}->[$pos]->{$key});        
        
        return $val;
    }    

    1;
};

#*******************************************************************************
#
#  Конструктор RpgSrcData
#
sub new
#
#
#*******************************************************************************
{
    my ($class)  = shift;
    my ($self)   = (ref($class) ? $class : bless({}, $class));

    # запрет на повторную инициализацию    
    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++);      
    return $self;       
}

#*******************************************************************************
#
DESTROY
#
#*******************************************************************************
{
}

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
#  Метод загружает в хеш данные из внешнего источника, при успехе возвращает число 
#  наборов или undef в противном случае
#
sub add
#
#  FROM  - ссылка на DBI объект используемый как источник данных (если значение 
#          не определенно то создается пустое хранилище)
#  TO    - имя ключа, по которому будет обращение в дальнейшем к этому источнику
#  SRС   - инструкция применяемая к источнику данных для получения последних
#  PARAM - ссылка на список параметров используемых при формировании инструкции 
#
#*******************************************************************************
{
    my ($self) = shift;
    my (%args) = (PARAM => [], @_);
    
    # уничтожаем предыдущее значение
    delete($self->{DATA}{$args{TO}}) if (defined($self->{DATA}{$args{TO}}));
    
    $self->{DATA}{$args{TO}}{SRC} = undef;
    $self->{DATA}{$args{TO}}{SRC} = [];

    $self->{$PACKAGE}{ERROR}      = '';
    
    unless (defined($args{FROM}))
    {
        # нет источника
        $self->{DATA}{$args{TO}}{SRC}->[0] = [];
        $self->{$PACKAGE}{ERROR}           = "Error, source's not set for '$args{TO}'";
    }
    else
    {
        # источник данных БД
        my ($sth)  = undef; 
        my ($exe)  = '';    
    
        $exe = sprintf($args{SRC}, @{('ARRAY' eq ref($args{PARAM}) ? $args{PARAM} : [])});
            
        unless (defined($exe)                              and 
                ''   ne $exe                               and
                defined($sth = $args{FROM}->prepare($exe)) and  
                defined($sth->execute))
        {
            delete($self->{DATA}{$args{TO}}) if (defined($self->{DATA}{$args{TO}}));
            $self->{$PACKAGE}{ERROR} = "Error, can't execute instruction sql: '$exe', for '$args{TO}', becose: " . $args{FROM}->errstr;
        }
        else
        {   
            eval
            {
                do
                {               
                    my $dat = $sth->fetchall_arrayref({});
                    $self->{DATA}{$args{TO}}{SRC}->[$#{$self->{DATA}{$args{TO}}{SRC}} + 1] = $dat
                        if (defined($dat));
                } 
                while ($sth->{odbc_more_results});
            };

            if ($@) 
            {
                $self->{$PACKAGE}{ERROR} = "Error, can't retrive data from sql: '$exe', for '$args{TO}', becose: " . $sth->errstr;
            }        
        }
        
        $sth->finish() if (defined($sth));
    }
    
    return ($#{$self->{DATA}{$args{TO}}{SRC}} + 1);        
}   

#*******************************************************************************
#
#  Метод возвращает последнюю ошибку в модуле
#
sub errstr
#
#*******************************************************************************
{
    return shift->{$PACKAGE}{ERROR};
}

#*******************************************************************************
#
# Метод возвращает ссылку на данные, если соответствующего источника не существует
# возвращается undef
#
sub get_data
#
# идентификатор источника
# номер набора (по умолчанию 0)
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    my ($num)         = ($#_ >= 0 ? shift : 0);
    
    return ((defined($self->{DATA}{$from}{SRC}) && ($#{$self->{DATA}{$from}{SRC}} >= $num)) ? $self->{DATA}{$from}{SRC}->[$num] : undef);
}

#*******************************************************************************
#
# Метод возвращает ссылку на объект данные, если соответствующего источника не существует
# возвращается undef
#
sub get_obj_data
#
# идентификатор источника
# номер набора (по умолчанию 0)
#
#*******************************************************************************
{
    my ($self, $from) = (shift, shift);
    my ($num)         = ($#_ >= 0 ? shift : 0);
    
    return ((defined($self->{DATA}{$from}{SRC}) && ($#{$self->{DATA}{$from}{SRC}} >= $num))
             ? new RpgSrcDataRow($self->{DATA}{$from}{SRC}->[$num]) : undef);
}

#*******************************************************************************
#
#  Метод добавляет записи в указанное хранилище
#
sub row_insert
#
# добавляемая строка
# идентификатор источника
# номер набора (по умолчанию 0)
#
#*******************************************************************************
{
    my ($self, $row, $to, $num) = (shift, shift, shift, shift || 0);
    
    unless (defined($self->{DATA}{$to}{SRC}))
    {
        $self->{$PACKAGE}{ERROR} = "Error, source $to isn't exists";
        return undef;
    }
    
    $self->{DATA}{$to}{SRC}->[$num] = []
        unless (defined($self->{DATA}{$to}{SRC}->[$num]));
    
    my $rows = @{$self->{DATA}{$to}{SRC}->[$num]};
        
    $self->{DATA}{$to}{SRC}->[$num]->[$rows] = $row;
    $self->{DATA}{$to}{SRC}->[$num]->[$rows];
}

#*******************************************************************************
#
#   Метод добавляет группу в источник
#
sub rows_insert
#
#   добавляемая группа
#   идентификатор источника
#   номер набора (по умолчанию в конец)
#
#*******************************************************************************
{
    my ($self, $rows, $to, $num) = (shift, shift, shift, shift);
    
    unless (defined($self->{DATA}{$to}{SRC}))
    {
        $self->{$PACKAGE}{ERROR} = "Error, source $to isn't exists";
        return undef;
    }
    
    $num = $#{$self->{DATA}{$to}{SRC}}
        unless (defined($num));
    
    $self->{DATA}{$to}{SRC}->[$num] = $rows;
}

#*******************************************************************************
#
# Создание группировки по заданным полям
# возвращает при успехе ссылку на хеш в противном случае undef
# 
sub CreateGroup
#
# TABLE  - ссылка на источник данных
# FIELDS - поля по которым следует сделать группировку 
#          ВНИМАНИЕ (в TABLE должна быть сортировка согласно FIELDS, чтобы не 
#          было пропусков)
# 
#*******************************************************************************
{
    my (%args) = (@_);
    
    return unless(defined($args{TABLE}) and defined($args{FIELDS}));
    
    my $body = $args{TABLE};
    my $ret  = {};
        
    # цикл по строкам таблицы
    for (my $row = 0; $row <= $#{$body}; $row++)
    {
        # сохраняем ссылку на корень
        my $ref = $ret;
        
        # цикл по значениям строки, создаем дерево
        foreach my $field (@{$args{FIELDS}})
        {
            my $key = (defined($$body[$row]->{$field}) ? $$body[$row]->{$field} : '');
            # создаем новый узел если такого не существует
            $ref->{$key} = {} unless(exists($ref->{$key}) and defined($ref->{$key}));
            # сохраняем ссылку на узел
            $ref = $ref->{$key};
        }
        
        # подсчитываем число элементов в группе
        unless ($ref->{COUNT}++)
        {
            # первое значение в группе 
            $ref->{FPOS} = $row;         
        }
        
        # проверка на разрыв
        !defined($ref->{LPOS}) || $ref->{LPOS} + 1 == $row || die "error, found gap, more 1: LPOS=$ref->{LPOS}, row=$row ";
        
        $ref->{LPOS} = $row;
    }
    
    return $ret;
}

1;
