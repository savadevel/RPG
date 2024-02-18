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

package RpgAboutUser;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use utils;
use page_default;
use src_data;
use sql_make;

use constant DICTIONARIES =>
{
    GET_USER    =>
    {
        src    => 'SQL_GET_USER',
        params => [{field => 'uid'}]

    },
    GET_REPORTS =>
    {
        src    => 'SQL_GET_CHILD_REPORTS',
        params => [{field => 'report'}, {field => 'uid'}]

    },
    GET_REPORT =>
    {
        src    => 'SQL_GET_THE_REPORT',
        params => [{field => 'report'}]

    },
    GET_IP      =>
    {
        src    => 'SQL_GET_IP_BY_UID',
        params => [{field => 'uid'}]
    }
};

use constant FIELDS_OF_DICTIONARIES =>
{
    uid =>
    {
        type => 'int'
    },
    report =>
    {
        type => 'str'
    }
};

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
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
    ref($_[0]) && die "Error, class RpgAboutUser can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({@_}, $class);
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }

 
    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++); # запрет на повторную инициализацию    
    return $self;    
}

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($set)  = $self->{PARAM}; # общие параметры, значение self->{PARAM}, установленно в базовом классе    

    # загрузка параметров источника-словарь
    foreach my $param (keys(%{FIELDS_OF_DICTIONARIES()}))
    {
        $set->{CGI}->param(-name => $param, -value => $set->{SESSION}->$param);
    }
    
    return $self;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my $self  = shift;    
    my $set   = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $vars  = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $data  = new RpgSrcData;
    my $maker = new RpgSQLMake();
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make query about current user");

    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        my $query = $maker->procedure
                                  (
                                        DESC    => {
                                                      src    => $set->{SETT}->get($set->{SESSION}->report(), DICTIONARIES->{$dic}{src}),
                                                      params => DICTIONARIES->{$dic}{params}
                                                   },
                                        CGI     => $set->{CGI},
                                        REQUEST => FIELDS_OF_DICTIONARIES
                                  );    

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (dictionary), sql: '%s'", $dic, $query);

        unless ($data->add(FROM  => $set->{DB}, 
                           TO    => $dic,
                           SRC   => $query,
                           PARAM => undef))
        {
            $set->{LOG}->out(RpgLog::LOG_E, "Error, coldn't load dictionary, becose: %s", $data->errstr());
            $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
            goto _WAS_ERROR;
        }
    }
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251');
    
    # печать тела (шаблона)
    $self->{TT}->process('about_user.html', {
                                                errors     => $self->errstr,
                                                alerts     => $self->alerts,
                                                # словари
                                                dictionary => {map{$_ => $data->get_data($_)} keys(%{DICTIONARIES()})}
                                            }) 
        || warn $self->{TT}->error();                

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make query about current user");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make query about current user");
    return FALSE;
}

1;
