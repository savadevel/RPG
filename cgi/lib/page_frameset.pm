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

package RpgPageFrameset;

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use POSIX;
use warnings;
use utils;
use page_default;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}

#*******************************************************************************
#
#  Конструктор RpgPageFrameset
#
sub new
#
#  PARAM - хеш содержит следующие элементы
#       SETT    : указатель на объект, источник денамических параметров RpgSett    
#       LOG     : указатель на объект-логер, VbtLog
#       CGI     : ссылка на CGI модуль
#       MODULE  : определяет источник в SETT
#  FRAMESET - хеш содержит параметры фреймов
#       left  {path, name} : параметры левого фрейма
#       right {path, name} : параметры правого фрейма
#*******************************************************************************
{
    my ($class) = shift;
    ref($class) && die "Error, class RpgPageFrameset can't use in inheritance\n";
    my ($self)  = bless({@_}); # наследование от этого класса запрещенно
           
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
sub do
#
#*******************************************************************************
{
    my $self = shift;           # все параметры
    my $set  = $self->{PARAM};  # общие параметры, значение self->{PARAM}, установленно в базовом классе
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make frameset of window");
    
    # значение self->{PARAM}, установленно в базовом классе
    print $self->{PARAM}->{CGI}->header(-TYPE    => 'text/html', 
                                        -CHARSET => 'windows-1251');
    
    # значение $self->{TT}, установленно в базовом классе
    $self->{TT}->process('frameset.html',                        
                        {
                            errors  => $self->errstr,
                            alerts  => $self->alerts,                         
                            %{$self->{FRAMESET}}
                        }) || warn $self->{TT}->error();
    
    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
    
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make frameset of window");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make frameset of window");
    return FALSE;
}

1;
