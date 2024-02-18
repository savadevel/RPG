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

package admin::RpgAdminLog;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use page_default;
use src_data;
use sql_make;
use admin::adm_log_exp;

use constant DICTIONARIES =>
{
    GET_USERS_SRV_DATA    =>    # список всех пользователей, включая удаленных
    {
        src    => 'SQL_GET_ALL_USERS',
        params => [],
        device => 'DB'
    },
    GET_REPORTS_SRV_DATA    =>  # список ресурсов, включая удаленные
    {
        src    => 'SQL_GET_REPORTS',
        params => [],
        device => 'DB'
    },
    GET_USERS_SRV_APPS    =>    # список пользователей, зарегистрированных в журнале сервера приложений
    {
        src    => 'PATH_LOG',
        params => [{field => 'user'}],        
        device => 'LOG'
    },
    GET_REPORTS_SRV_APPS    =>  # список ресурсов, зарегистрированных в журнале сервера приложений
    {
        src    => 'PATH_LOG',
        params => [{field => 'report'}],        
        device => 'LOG'
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
};

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}


use constant CHILDRENS =>
{
    EXPORT => 
    {
        SRV_APPS => sub {new admin::RpgAdminLogExport(@_);},
        SRV_DATA => sub {new admin::RpgAdminLogExport(@_);}
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
        my $exe  = $args{PARAM}{CGI}->param('exe');
        my $page = $args{PARAM}{CGI}->param('page');
        #my $to   = (defined($args{PARAM}{CGI}->param('lstOutTo')) ? $args{PARAM}{CGI}->param('lstOutTo') : 'HTML');
        
        if (    defined($exe) 
            and defined($page)
            and defined(CHILDRENS->{(uc($exe))}{uc($page)}))
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
    my ($self) = shift;    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе    

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
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make query request logs");

    goto _WAS_ERROR unless($self->_get_dictionary_from_db($data));
    #goto _WAS_ERROR unless($self->_get_dictionary_from_log($data));
    
    # имя формата представления даты
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
    $self->{TT}->process('adm_log.html',
        {
            errors     => $self->errstr,
            alerts     => $self->alerts,
            dformat    => $types{date}{format},
            tformat    => $types{time}{format},
            date2str   => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
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
        
    $set->{LOG}->out(RpgLog::LOG_I, "end start prepare data for make query request logs");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error start prepare data for make query request logs");
    return FALSE;
}

#*******************************************************************************
#
#
sub _get_dictionary_from_log
#
#
#*******************************************************************************
{
    my $self   = shift;    
    my $store  = shift;
    my $set    = $self->{PARAM}; # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my %trees;                   
    my $parser_log =                 # процедура для callback, в нее передается хеш текущей строки из которой будут взяты поля
        sub
        {
            my ($num, $row)  = (shift, shift);    
            
            foreach my $tree (keys(%trees))
            {
                # цикл по словарям, которые представляются ввиде деревьев, количество узлов определяется числом полей
                my $data   = $trees{$tree}->{DATA};
                my $fields = $#{$trees{$tree}->{FIELDS}};
                
                for (my $field = 0; $field <= $fields; $field++)
                {
                    # если поле не существует то заменяем на '' для сохранения иерархии
                    my $val = defined($row->{$trees{$tree}->{FIELDS}->[$field]}) ? $row->{$trees{$tree}->{FIELDS}->[$field]} : '';
                    
                    # создаем - обновляем узел
                    if ($field == $fields)
                    {
                        # если последнее поле пропускаем создание узла   
                        $data->{$val} = undef;
                        next;
                    }
                    
                    $data->{$val} = {} unless (defined($data->{$val})); # создаем узел
                    $data = $data->{$val}; # переходим к следующему узлу
                }    
            }
        };
    my $tree2store; 
    $tree2store =
        sub
        {
            my ($fields, $to, $data, $col, $row) = (shift, shift, shift, shift, shift || {});
           
            foreach my $key (sort keys(%{$data}))
            {
                $row->{($fields->[$col])} = $key;
                
                if (defined($data->{$key}))
                {
                    # узел
                    $tree2store->($fields, $to, $data->{$key}, $col + 1, $row);
                }
                else
                {
                    # лепесток, добавляем в хранилище                    
                    $store->row_insert({(%{$row})}, $to);
                }
            }                   
        };
        
    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        # словари сервера приложений
        next if ('LOG' ne DICTIONARIES->{$dic}{device});
        
        $trees{$dic} = {FIELDS => [], DATA => {}};
        
        foreach (@{DICTIONARIES->{$dic}{params}})
        {
            # создаем список полей словаря
            push(@{$trees{$dic}->{FIELDS}}, $_->{field});
        }        
    }   
        
    $set->{LOG}->load($parser_log);
    
    # переносим данные в хранилище
    foreach my $tree (keys(%trees))
    {
        $store->add(TO => $tree);        
        # цикл по словарям, которые представлены ввиде деревьев, количество узлов определяется числом полей
        $tree2store->($trees{$tree}->{FIELDS}, $tree, $trees{$tree}->{DATA}, 0);        
    }    
    
    return TRUE;
}

#*******************************************************************************
#
#
sub _get_dictionary_from_db
#
#
#*******************************************************************************
{
    my $self  = shift;
    my $data  = shift;    
    my $set   = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $maker = new RpgSQLMake();

    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        # последовательно загружаем словари сервера данных
        next if ('DB' ne DICTIONARIES->{$dic}{device});

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

    return TRUE;

_WAS_ERROR:
    return FALSE;    
}

1;
