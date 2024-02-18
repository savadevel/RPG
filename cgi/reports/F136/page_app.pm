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

package F136::RpgPageApp;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use page_default;
use src_data;
use sql_make;

use F136::export;

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}

use constant DICTIONARIES =>
{
    GET_DEPARTS     =>
    {
        src    => 'SQL_GET_DEPART_BY_PERMISSION',
        params  => [{field => 'access'}]
    },    
    GET_APPS        =>
    {
        src    => 'SQL_GET_APPS_BY_PERMISSION',
        params  => [{field => 'access'}]
    },        
    GET_ROWVER      =>
    {
        src     => 'SQL_GET_ROWVER_BY_PERMISSION',
        params  => [{field => 'access'}]
    }    
};

use constant FIELDS_OF_DICTIONARIES => 
{
    access =>
    {
        type => 'int' 
    }
};

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
    my ($class) = shift;

    unless (ref($class))
    {
        # сюда попадаем только если объект создаётся на прямую, т.е. класса ещё не существует
        # в блоке делается переопределение объекта (передача управления дочерним классам)
        my %args = (@_);

        if (defined($args{PARAM}{CGI}->param('lstOutTo')))
        {
            return new F136::RpgExport(@_);
        }        

        # не было найденно подходящего дочернего класса
        # придется делать самим        
    }
    
    # был вызов либо дочерним классом, т.е. класс такой существует
    # или дочернего нет
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
    my ($self) = shift;    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе    
    
    $set->{SETT}->reload(LOAD_TO      => 'F136_SETTING',
                         SQL_GET_SETT => $set->{SETT}->get($set->{SESSION}->report(), 'SQL_GET_F136_SETTINGS'),
                         DB           => $set->{DB});  
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
    my $maker = new RpgSQLMake;
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make query 'Report by form 0409136'");
    
    # загружаем список отчетов в соответствии с правами пользователя
    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        my $query = $maker->procedure
            (
                DESC    =>
                {
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
    
    my %types = (date => {}, time => {});

    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251');
    
    # печать тела (шаблона)
    $self->{TT}->process('f136_main.html',
        {                                              
            errors       => $self->errstr,
            alerts       => $self->alerts,
            dformat      => $types{date}{format},
            tformat      => $types{time}{format},
            date2str     => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
            # словари
            dictionaries => {map{$_ => $data->get_data($_)} keys(%{DICTIONARIES()})}                                             
        });
    
    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make query 'Report by form 0409136'");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make query 'Report by form 0409136'");
    return FALSE;
}

1;
