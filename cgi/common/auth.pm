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

package RpgAuth;

use vars qw(@ISA @EXPORT $VERSION %PARAM_SESSION $AUTOLOAD);

use English;
use strict;
use DBI;

use utils;

require Exporter;

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw (Exporter);
    @EXPORT  = qw ();    
    
    for my $param (qw(sid uid report preport version access lib path is_fix rowver))
    {
        $PARAM_SESSION{$param} ++;
    }
}

sub AUTOLOAD
{
    my $self  = shift;
    my $param = $AUTOLOAD;
    
    $param =~ s/.*:://;
    
    return exists($self->{SESSION}{(lc($param))}) ? $self->{SESSION}{(lc($param))} : undef
        if (exists($PARAM_SESSION{(lc($param))}));
    
    die("Undefined call $AUTOLOAD");
}

#*******************************************************************************
#
#   Конструктор идентификации пользователя
#
sub new
#
#   REPORT         - имя запрошенного отчета
#   DB             - подключение к БД
#   PRC_CREATE_SID - sql процедура создания сессии
#   PRC_CLOSE_SID  - sql процедура закрытия сессии
#
#*******************************************************************************
{   
    ref($_[0]) && die "Error, class RpgLog can't use in inheritance\n";     
    my $self = bless({}, shift);
    
    $self->{SETT}    = {@_};  # параметры работы
    $self->{SESSION} = undef; # параметры сессии

    goto _WAS_ERROR
        unless (defined($ENV{REMOTE_USER}) && ($ENV{REMOTE_USER} =~ /^([\w-]+)\\([\w-]+)$/o || $ENV{REMOTE_USER} =~ /^()([\w-]+)$/o));

    $self->{SETT}{DOMAIN} = $1 || '';
    $self->{SETT}{LOGIN}  = $2 || '';
    
    goto _WAS_ERROR
        unless (defined($ENV{REMOTE_ADDR}) && $ENV{REMOTE_ADDR} =~ /^(\d{1,3}?)\.(\d{1,3}?)\.(\d{1,3}?)\.(\d{1,3}?)$/o);
        
    $self->{SETT}{IP}   = [$1, $2, $3, $4];        
    $self->{SETT}{PORT} = $ENV{REMOTE_PORT} || 0;
    
    $self->_start();
        
    return $self;
    
_WAS_ERROR:
    die 'Error, can\'t identify the user';        
}

sub domain
{
    return shift->{SETT}{DOMAIN};
}

sub login
{
    return shift->{SETT}{LOGIN};
}

sub ip
{
    return sprintf('%03d.%03d.%03d.%03d', @{shift->{SETT}{IP}});
}

sub port
{
    return shift->{SETT}{PORT};
}

#*******************************************************************************
#
DESTROY
#
#*******************************************************************************
{
    #$_[0]->close() if (defined($_[0]->{SETT}{DB}));    
}

#*******************************************************************************
#
# Создание сессии, если при создании возникнут ошибки то вызываем die
#
sub _start
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($sql)  = sprintf('exec %s \'%s\', %d, %d, %d, %d, %d, \'%s\', \'%s\'', 
                        $self->{SETT}{PRC_CREATE_SID}, $self->{SETT}{REPORT}, @{$self->{SETT}{IP}}, $self->{SETT}{PORT}, $self->{SETT}{DOMAIN}, $self->{SETT}{LOGIN});
   
    eval
    {        
        my ($sth)= $self->{SETT}{DB}->prepare($sql);
                
        $sth->execute;
        $self->{SESSION} = $sth->fetchall_arrayref({})->[0];
        $sth->finish();        
    };
    
    if ($@) 
    {
        die "Error, can't create session, becose: \n$@";
    }        
}

#*******************************************************************************
#
# Закрытие сессии
#
sub close
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($sql)  = $self->{SETT}{PRC_CLOSE_SID};

    eval
    {        
        $self->{SETT}{DB}->do($sql);
    };
    
    return ($@? FALSE : TRUE);
}

1;
