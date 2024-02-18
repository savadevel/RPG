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

package RpgPageDefault;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw($VERSION $PACKAGE @ERRORS);
use Template;
use English;
use strict;
use CGI qw (escapeHTML);

use FindBin qw($Bin);
use lib "$Bin/../common";
use utils;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
}

#*******************************************************************************
#
#   Метод возвращает последнюю глобальную ошибку или все ошибки модуля,
#   ошибка берется либо из модуля если он существует, либо из глобальной переменной
#
sub errstr
#
#*******************************************************************************
{
    my $self = shift;
    
    if (ref($self))
    {
        join ('; ', @{$self->{'ERRORS'}});
    }
    else
    {
        @ERRORS == 0 ? '' : $ERRORS[$#ERRORS];
    }    
}

#*******************************************************************************
#
#   Метод добавляет сообщение об ошибке в журнал
#
sub _add_error
#
#   format - формат сообщения
#   data   - данные соответствующие формату сообщения (все остальные)
#
#*******************************************************************************
{
    my $self   = shift;
    my $format = shift;
    my $ref    = ref($self) ? $self->{'ERRORS'} : \@ERRORS;
        
    push (@{$ref}, ($#_ >= 0 ? sprintf($format, @_) : $format));
    return;
}

#*******************************************************************************
#
#   Сброс всех сообщений об ошибках
#
sub _clear_errors
#
#*******************************************************************************
{
    my $self = shift;
    my $ref  = ref($self) ? $self->{'ERRORS'} : \@ERRORS;
    
    $#{$ref} = -1;    
    return;
}

#*******************************************************************************
#
#   Метод возвращает накопленный хеш сообщений пользователю, в фомате
#   {key1 => ['msg1', 'msg2', ...], ...}
#
sub alerts
#
#   key - ключь сообщения(если задан то возвращаются сообщения только этого ключа) 
#
#*******************************************************************************
{
    my ($self, $key) = (shift, shift);    
    return (defined($key) ? ($self->{ALERTS}{$key} || []) : $self->{ALERTS});
}


#*******************************************************************************
#
#   Метод добавляет сообщение пользователю в хеш сообщений
#
sub _add_alert
#
#   key    - ключь сообщения
#   format - формат сообщения
#   data   - данные соответствующие формату сообщения (все остальные)
#
#*******************************************************************************
{
    my ($self, $key, $format) = (shift, shift, shift);
    
    $self->{ALERTS}{$key} = []
        unless (ref($self->{ALERTS}{$key}));
    
    $self->{ALERTS}{$key}->[$#{$self->{ALERTS}{$key}} + 1] =
        ($#_ >= 0 ? sprintf($format, @_) : $format);
    return;         
}

#*******************************************************************************
#
#  Конструктор RpgPageDefault
#
sub new
#
#  PARAM - хеш содержит следующие элементы
#       SETT    : указатель на объект, источник денамических параметров RpgSett    
#       ENV_TT2 : переменные окружения для Template toolkit
#       LOG     : указатель на объект-логер, VbtLog
#       CGI     : ссылка на CGI модуль
#       MODULE  : определяет источник в SETT
#  ALERTS
#
#*******************************************************************************
{
    my ($class)  = shift;
    my ($self)   = (ref($class) ? $class : bless({@_}, $class));

    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++); # запрет на повторную инициализацию    
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
    my ($set)  = $self->{PARAM};
    
    #$self->{PARAM}   = $args{PARAM}; # параметры работы используются всеми потомками
    # содержит предупреждения которые должны быть выведены шаблоны пользователю 
    $self->{ALERTS}  = ref($self->{ALERTS}) ? {%{$self->{ALERTS}}} : {};  
    # содержит описание ошибок
    $self->{ERRORS}  = ref($self->{ERRORS}) ? {@{$self->{ERRORS}}} : [];  
    # ссылка на модуль Template toolkit, один на всех    
    $self->{TT}      = (ref($self->{TT}) ? 
                            $self->{TT} :
                            Template->new({
                                        INCLUDE_PATH => $set->{SETT}->get($set->{MODULE}, 'TT2_INCLUDE_PATH'),
                                        PRE_PROCESS  => $set->{SETT}->get($set->{MODULE}, 'TT2_PRE_PROCESS'),
                                        POST_PROCESS => $set->{SETT}->get($set->{MODULE}, 'TT2_POST_PROCESS'),                                                                        INTERPOLATE  => $set->{SETT}->get($set->{MODULE}, 'TT2_INTERPOLATE'),
                                        TAG_STYLE    => $set->{SETT}->get($set->{MODULE}, 'TT2_TAG_STYLE'),
                                        DEBUG        => $set->{SETT}->get($set->{MODULE}, 'TT2_DEBUG')                                    
                                    })) || warn "$Template::ERROR";

    $set->{CGI}->param(-name => 'sid',    -value => $set->{SESSION}->sid());
    $set->{CGI}->param(-name => 'uid',    -value => $set->{SESSION}->uid());
    $set->{CGI}->param(-name => 'rowver', -value => $set->{SESSION}->rowver());
    $set->{CGI}->param(-name => 'access', -value => $set->{SESSION}->access());
    
    return $self;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make default page");

    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251');
    
    $self->{TT}->process('default.html', 
                        {
                            errors => $self->errstr,
                            alerts => $self->alerts,
                        }) || warn $self->{TT}->error();

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make default page");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make default page");
    return FALSE;
}

1;
