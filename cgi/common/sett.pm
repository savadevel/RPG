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

package RpgSett;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION);
use English;
use strict;
use warnings;
use log;
use utils;
use types;

use DBI;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw();
}

#*******************************************************************************
#
#   Конструктор источника параметров
#
sub new
#
#   параметры инициализации, см. метод reload
#
#*******************************************************************************
{
    my $name = shift;  
    my $self = {   
                   SETT   => undef,  # идентификатор файла параметров
                   PARAM  => {},     # именнованные наборы параметров
                   COMMON => {}      # неименнованный набор параметров
               };
    ref($name) && die "Error, class RpgSett can't use in inheritance\n";
    $self = bless($self); # запрет наследования
    
    $self->reload(@_);
    
    return $self;
}

#*******************************************************************************
#
# Метод, перегружает параметры из файла и БД
#
sub reload
#    
#    LOAD_TO      - имя набора параметров, если не задано то общий ресурс
#    DB           - ссылка на соединение с БД
#    SQL_GET_SETT - инструкция для выгрузки параметров из БД
#    PATH         - путь к файлу с параметрами
#    CHECK        - проверочный хеш, описание см. приват метод _check
#    определяются как именнованные параметры
#
#*******************************************************************************
{
    my ($self)    = shift;
    $self->{SETT} = {@_};
    
    $self->_load_from_file() if (defined($self->{SETT}{PATH}));
    $self->_load_from_db()   if (defined($self->{SETT}{DB}) and defined($self->{SETT}{SQL_GET_SETT}));
    $self->{SETT} = undef;
}

#*******************************************************************************
#
sub get
#
#*******************************************************************************
{
    my ($self)                   = shift;
    my ($where, $name, $default) = (shift, shift, shift);

    if (defined($where) && exists($self->{PARAM}{$where}{$name}))
    {
        return $self->{PARAM}{$where}{$name}->convert;
    }
    elsif (exists($self->{COMMON}{$name}))
    {
        return $self->{COMMON}{$name}->convert;
    }

    return $default;
}

#*******************************************************************************
#
sub set
#
#*******************************************************************************
{
    my ($self)                        = shift;
    my ($where, $name, $value, $type) = (shift, shift, shift, shift);
    
    return FALSE if (defined($where) && !exists($self->{PARAM}{$where}));    
    
    my ($src) = (defined($where) ? $self->{PARAM}{$where} : $self->{COMMON});
        
    $src->{$name} = new RpgType(value=>\$value, type=>$type);
        
    return TRUE;    
}

#*******************************************************************************
#
sub print
#
#*******************************************************************************
{
    my ($self, $log, $from, $level) = (shift, shift, shift, shift);
    my ($src)               = (defined($from) && exists($self->{PARAM}{$from}) ? $self->{PARAM}{$from} : $self->{COMMON});
    my ($str)               = "";
    
    foreach(keys(%{$src}))
    {
        my $val = $src->{$_}->convert;
        $str .= " <$_> = ";                
        $val  = '***' if ($src->{$_}->type eq 'pwd');        
        $str .= $val  if (defined($val));        
    }    
    
    $str =~ s/'/"/go;
    $str =~ s/%/%%/go;    
    $log->out($level || RpgLog::LOG_D, $str);    

    $self->print($log, undef) if ($src != $self->{COMMON});
}
    
#*******************************************************************************
#
# Закрытый метод загружает параметры из файла
#
sub _load_from_file
#
#*******************************************************************************
{
    my ($self)  = (shift);
    my ($params, $stream);

    $params  = defined($self->{SETT}{LOAD_TO}) ? \$self->{PARAM}{$self->{SETT}{LOAD_TO}} : \$self->{COMMON};
    $$params = {};
        
    if (defined($self->{SETT}{CHECK}))
    {
        # загружаем все значения по умолчанию        
        foreach my $from ('IMPORTANT', 'SOME')
        {
            next unless(defined($self->{SETT}{CHECK}{$from}));
            
            foreach my $param (keys(%{$self->{SETT}{CHECK}{$from}}))
            {
                $$params->{$param} = new RpgType(rval=>\$self->{SETT}{CHECK}{$from}{$param}{value}, type=>$self->{SETT}{CHECK}{$from}{$param}{type}); 
            }
        }
    }
        
    if (open ($stream, "< $self->{SETT}{PATH}"))
    {
        while (<$stream>)
        {
            chomp;
            s/#.*//;
            s/^\s*<\s*//;
            s/\s+$//;
            next unless (length);
            my ($var, $value) = (split (/\s*=\s*/, $_, 2), "", "");        
            $var =~ s/\s*>\s*$//;            
            next unless (exists($$params->{$var}));            
            # сохраняем параметр из файла, перезаписываем
            $$params->{$var}->set($value eq '' ? undef : $value); 
        }
                
        close($stream);   
             
        $self->_check();
    }
    else
    {
        die "Error, can't load setting from file: $self->{SETT}{PATH}, becose: $!\n";
    }
}

#*******************************************************************************
#
sub _load_from_db
#
#*******************************************************************************
{
    my $self = shift;
    my $params;

    $params  = defined($self->{SETT}{LOAD_TO}) ? \$self->{PARAM}{$self->{SETT}{LOAD_TO}} : \$self->{COMMON};
    $$params = {};

    eval
    {
        my ($sth) = $self->{SETT}{DB}->prepare($self->{SETT}{SQL_GET_SETT});
        
        if ($sth->execute)
        {
            foreach my $row (@{$sth->fetchall_arrayref({})})
            {
                $$params->{$row->{setting}} = new RpgType(rval=>\$row->{val}, type=>$row->{type});                 
            }
            
            $self->_check();        
        }    
    
        $sth->finish();
    };
    
    die "Erorr, can't load setting from DB slq: $self->{SETT}{SQL_GET_SETT}, becose $@\n" if ($@);
}

#*******************************************************************************
#
#  Метод проверяет элемент хеша на соответствие шаблонам (эталонам)
#  IMPORTANT_PARAM и SOME_PARAM
#
sub _check
#
#  IMPORTANT - ссылка на массив содержит параметры без определённого значения которых
#              не возможна работа приложения
#  SOME      - ссылка на хеш содержит параметры без определённого значения которых
#              возможна работа приложения, но требуется некоторое значение default
# 
#*******************************************************************************
{
    my ($self)  = (shift);
    my ($check) = (exists($self->{SETT}{LOAD_TO}) ? $self->{PARAM}{$self->{SETT}{LOAD_TO}} : $self->{COMMON});
    
    if (defined($self->{SETT}{CHECK}{IMPORTANT}))
    {
        foreach (keys(%{$self->{SETT}{CHECK}{IMPORTANT}}))
        {
            defined($check->{$_}) || die "Error, missed or bad important parameter <$_>\n";
        }
    }        

    if (defined($self->{SETT}{CHECK}{SOME}))
    {
        foreach (keys(%{$self->{SETT}{CHECK}{SOME}}))
        {
            next if (defined($check->{$_}));
            $check->{$_} = new RpgType(rval=>\$self->{SETT}{CHECK}{SOME}{$_}{value}, type=>$self->{SETT}{CHECK}{SOME}{$_}{type});                  
        }                
    }
    
    return;
} 

1;
