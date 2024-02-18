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

package RpgPageTree;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use src_data;
use sql_make;
use page_default;

use constant DICTIONARIES =>
{
    GET_TREE  =>   # список отчетов в соответствии с правами пользователя
    {
        src    => 'SQL_GET_TREE_REPORT',
        params => [{field => 'uid'}]
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
    uid =>
    {
        type => 'int'
    }
};

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}

#*******************************************************************************
#
#  Конструктор RpgPageTree
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
sub do
#
#*******************************************************************************
{
    my $self  = shift;            # все параметры
    my $set   = $self->{PARAM};   # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $data  = new RpgSrcData;
    my $maker = new RpgSQLMake;
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make tree reports");
    
    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        my $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{MODULE}, DICTIONARIES->{$dic}{src}),
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

    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251');

    # значение $self->{TT}, установленно в базовом классе       
    $self->{TT}->process('tree.html',
                        {
                            path    => $set->{CGI}->script_name,
                            tree    => [@{$data->get_data('GET_TREE')}],
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
    
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make tree reports");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make tree reports");
    return FALSE;
}

1;
