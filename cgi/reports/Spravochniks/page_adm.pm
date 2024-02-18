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

package Spravochniks::RpgPageAdmin;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use const;
use utils;
use types;
use page_default;
use src_data;

use Spravochniks::adm_exp;
use Spravochniks::adm_imp;
use Spravochniks::adm_rowver;


use constant DICTIONARIES =>
{
    GET_ROWVER     =>
    {
        src     => 'SQL_GET_ROWVER',
        params  => []
    },    
    GET_THE_ROWVER     =>
    {
        src     => 'SQL_GET_THE_ROWVER',
        params  => [{field => 'rowver'}]
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
    rowver =>
    {
        type => 'int' 
    }
};

use constant CHILDRENS =>
{
    IMPORT => 
    {
        CALENDAR  => sub {new Spravochniks::RpgAdmImport(@_);},
        DEPARTS   => sub {new Spravochniks::RpgAdmImport(@_);},
        CLR_CODES => sub {new Spravochniks::RpgAdmImport(@_);},
        CLR_RATE  => sub {new Spravochniks::RpgAdmImport(@_);}
    },
    EXPORT => 
    {
        CALENDAR  => sub {new Spravochniks::RpgAdmExport(@_);},
        DEPARTS   => sub {new Spravochniks::RpgAdmExport(@_);},
        CLR_CODES => sub {new Spravochniks::RpgAdmExport(@_);},
        CLR_RATE  => sub {new Spravochniks::RpgAdmExport(@_);}
    },
    EDIT =>
    {
        ROWVER => sub {new Spravochniks::RpgAdmRowVersion(@_);}
    },
    CREATE =>
    {
        ROWVER => sub {new Spravochniks::RpgAdmRowVersion(@_);}
    },
    DELETE =>
    {
        ROWVER => sub {new Spravochniks::RpgAdmRowVersion(@_);}
    }
};

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}

sub DESTROY
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
        my $exe  = $args{PARAM}{CGI}->param('exe');
        my $page = $args{PARAM}{CGI}->param('page');
        #my $to   = (defined($args{PARAM}{CGI}->param('lstOutTo')) ? $args{PARAM}{CGI}->param('lstOutTo') : 'HTML');
        
        if (    defined($exe) 
            and defined($page)
            and exists(CHILDRENS->{(uc($exe))}{uc($page)}))
        {
            return CHILDRENS->{(uc($exe))}{uc($page)}(@_);
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
    my $self = shift;    
    my $set  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе    
    
    $self->{TARGET} = undef;
    $self->{EXE}    = undef;
            
    my $exe  = $set->{CGI}->param('exe');
    my $page = $set->{CGI}->param('page');
    
    if (    defined($exe) 
        and defined($page)
        and defined(CHILDRENS->{(uc($exe))}{uc($page)}))
    {
        $self->{TARGET} = $page;
        $self->{EXE}    = $exe;
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
    my $maker = new RpgSQLMake;
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for console of administration 'Spravochniks'");    
    
    # загружаем словари
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

    # имя формата представления даты
    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};

    my $rowver  = $data->get_obj_data('GET_THE_ROWVER');
    my $checkin = ((grep {defined($_) && $_ == 0} map{$_->{is_fix}} @{$data->get_data('GET_ROWVER')}) ? FALSE : TRUE);
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251',
                              -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));
        
    # печать тела (шаблона)
    $self->{TT}->process('spr_admin.html',
        { 
            # версия к которой привязан текущий набор данных
            version      => 
            {
                rowver => $set->{SESSION}->rowver(),
                is_fix => $set->{SESSION}->is_fix(),
                access => $set->{SESSION}->access()
            },
            curver     => $set->{SESSION}->rowver(),
            checkin    => $checkin,
            errors     => $self->errstr,
            alerts     => $self->alerts,
            dformat    => $types{date}{format},
            tformat    => $types{time}{format},
            date2str   => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
            # словари
            dictionaries => {map{$_ => $data->get_data($_)} keys(%{DICTIONARIES()})}                                             
        });                

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for console of administration");
    return TRUE;

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for console of administration");
    return FALSE;
}

1;
