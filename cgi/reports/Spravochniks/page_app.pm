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

package Spravochniks::RpgPageApp;

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

use Spravochniks::export;

use constant FORMS_MAKE_QUERY =>
{
    SprAccBalance => # справочник остатков на счетах
    {
        HTML_TEMPLATE  => 'AccBalance_main.html', # шаблон первой страницы (формирование запроса)   
        DICTIONARIES   =>                         # список дополнительных словарей
        {
            GET_ACCOUNT => 
            {
                src    => 'SQL_GET_ACCOUNT',      
                params => []  
            }   
        }
    },
    SprCalendar => # календарный справочник
    {
        HTML_TEMPLATE  => 'Calendar_main.html',    
        DICTIONARIES =>
        {
            GET_ROWVER =>
            {
                src    => 'SQL_GET_ROWVER_BY_PERMISSION',
                params  => [{field => 'access'}]
            }                
        }
    },
    SprRateOfExchange => # справочник курсов валют
    {
        HTML_TEMPLATE  => 'RateOfExchange_main.html',    
        DICTIONARIES =>
        {
            GET_CUR =>
            {
                src     => 'SQL_GET_CUR',
                params  => []
            },
            GET_ROWVER =>
            {
                src    => 'SQL_GET_ROWVER_BY_PERMISSION',
                params => [{field => 'access'}]
            }        
        }
    },
    SprDepartments => # справочник подразделений Банка
    {
        HTML_TEMPLATE  => 'Departments_main.html',    
        DICTIONARIES   =>
        {
            GET_ROWVER =>
            {
                src    => 'SQL_GET_ROWVER_BY_PERMISSION',
                params => [{field => 'access'}]
            }        
        }
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
    access =>
    {
        type => 'int' 
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
    my ($class) = shift;
    
    unless (ref($class))
    {
        my %args = (@_);   
        # сюда попадаем только если объект создаётся на прямую, т.е. класса ещё не существует
        # в блоке делается переопределение объекта (передача управления дочерним классам)       

        if (defined($args{PARAM}{CGI}->param('lstOutTo')))
        {
            return new Spravochniks::RpgExport(@_);
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
    return shift;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my $self = shift;    
    my $set  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $ret  = TRUE;
    my $data = new RpgSrcData;

    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make query report '%s'", $set->{SESSION}->report()); 
    
    unless (exists(FORMS_MAKE_QUERY->{$set->{SESSION}->report()}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, "can't locate report in Spravochniks::%s", $set->{SESSION}->report());
        $self->SUPER::do();
        goto _WAS_ERROR;
    }
    
    my ($maker) = new RpgSQLMake();
    my ($spr)   = FORMS_MAKE_QUERY->{$set->{SESSION}->report()};
    
    # загружаем словари    
    foreach my $dic (keys(%{$spr->{DICTIONARIES}}))
    {
        my $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), $spr->{DICTIONARIES}{$dic}{src}),
                    params => $spr->{DICTIONARIES}{$dic}{params}
                },
                CGI     => $set->{CGI},
                REQUEST => FIELDS_OF_DICTIONARIES
            );    

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (dictionary), sql: %s", $dic, $query);

        unless ($data->add(FROM  => $set->{DB}, 
                           TO    => $dic,
                           SRC   => $query))
        {
            $set->{LOG}->out(RpgLog::LOG_E, "error load dictionary, becose: %s", $data->errstr());
            goto _WAS_ERROR;
        }
    }
    
    my %types = (date => {}, time => {});

    # имя формата представления даты
    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};

    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251');
    
    # печать тела (шаблона)
    $self->{TT}->process($spr->{HTML_TEMPLATE}, 
        {
            errors       => $self->errstr,
            alerts       => $self->alerts,
            dformat      => $types{date}{format},
            tformat      => $types{time}{format},
            date2str     => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
            dates        =>
            {
                previous => RpgTypeDate::GetCurrDate->subtract(days => 1)->format($types{date}{name})
            },
            # словари
            dictionaries => {map{$_ => $data->get_data($_)} keys(%{$spr->{DICTIONARIES}})}
        });

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for make query");
    return TRUE;
    
_WAS_ERROR:      
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make query");
    return FALSE;
}

1;
