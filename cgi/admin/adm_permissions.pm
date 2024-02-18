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

package admin::RpgAdminPermissions;

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
use cgi_check;

use constant DICTIONARIES =>
{
    GET_USERS  =>    # список пользователей, зарегистрированных в журнале сервера данных
    {
        src    => 'SQL_GET_USERS',
        params => []
    },
    GET_GROUPS  =>  # список ресурсов, зарегистрированных в журнале сервера данных
    {
        src    => 'SQL_GET_GROUPS',
        params => []
    },
    GET_PERMISSIONS  =>  # список ресурсов, зарегистрированных в журнале сервера данных
    {
        src    => 'SQL_GET_PERMISSIONS',
        params => []
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
};

use constant CGI_DESC =>  # содержит поля запроса, по ним делаем его валидацию
{
    PERMISSIONS =>
    {
        CREATE =>
        {
            FIELDS =>
            {
                lstUsers  => # ID пользователя
                {
                    type     => 'int' # тип данных
                },
                lstAllowGroups =>  # ID групп
                {
                    type     => 'str',
                    optional => TRUE,
                    array    => TRUE
                }
            },
            CHECKS => # проверки
            {
            }                
        },
        DELETE =>
        {
            FIELDS =>
            {
                lstUsers  => # ID пользователя
                {
                    type     => 'int' # тип данных
                },
                lstDenyGroups =>  # ID групп
                {
                    type     => 'str',
                    optional => TRUE,
                    array    => TRUE
                }
            },
            CHECKS => # проверки
            {
            }                
        }
    }
};

use constant TABLES_DESC =>
{
    PERMISSIONS =>
    {
        TABLE =>
        {
            name => 'TBL_PERMISSIONS'
        },
        FIELDS =>
        {
            uid =>
            {
                type    => 'int',
                key     => TRUE
            },
            grp =>
            {
                type    => 'str',
                key     => TRUE
            }            
        }
    }
};

use constant COMMANDS_DESC => #  описание действий
{
    PERMISSIONS =>
    {
        DELETE =>
        {        
            type    => 'DELETE',
            where   => 
            { # условие на удаление
                uid     => 'lstUsers',
                grp     => 'lstDenyGroups'
            }            
        },
        CREATE =>
        {        
            type    => 'INSERT',
            set     => 
            { # соответствия между полями в CGI запросе и полями таблицы
                uid     => 'lstUsers',
                grp     => 'lstAllowGroups'
            }                    
        }
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
    ref($_[0]) && die "Error, class admin::RpgAdminPermissions can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({@_}, $class);
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }
    
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
            
    my $page = $set->{CGI}->param('page');
    
    if (defined($page)
        and defined(CGI_DESC()->{(uc($page))}))
    {
        $self->{TARGET} = uc($page);        
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

    if (defined($self->{TARGET}))
    {
        $set->{LOG}->out(RpgLog::LOG_I, "start apply change: TARGET = '%s'",
                                        $self->{TARGET});
        
        my $dbh = $set->{DB};
        
        eval 
        {
            $dbh->begin_work;
            $self->_applay_change_permissions($self->{TARGET}, 'DELETE');
            $self->_applay_change_permissions($self->{TARGET}, 'CREATE');
            $dbh->commit;   # commit the changes if we get this far
        };
        
        if ($@)        
        {
            my $msg = $@;
            
            eval {$dbh->rollback};            
            
            $msg .= $@ if ($@ ne '');        
            
            $set->{LOG}->out(RpgLog::LOG_E, "couldn't submit change, becose: %s", $msg);
            $self->_add_alert($self->{TARGET}, 'Ошибка во входном потоке, детали см. журнал');
        }
        else
        {
            $set->{LOG}->out(RpgLog::LOG_I, "changes applied");
        }        
    }
    
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make console management permissions");

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
    $self->{TT}->process('adm_permissions.html', 
        { 
            user         =>
            {
                uid    => $set->{SESSION}->uid,
                access => $set->{SESSION}->access,
                login  => $set->{SESSION}->login,
                domain => $set->{SESSION}->domain
            },
            show_user     =>
            {
                uid    => ($set->{CGI}->param('lstUsers') ?  $set->{CGI}->param('lstUsers')  : $set->{SESSION}->uid)
            },            
            errors     => $self->errstr,
            alerts     => $self->alerts,
            dformat    => $types{date}{format},
            tformat    => $types{time}{format},
            date2str   => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
            # словари
            dictionaries => {map{$_ => $data->get_data($_)} keys(%{DICTIONARIES()})}
        }) 
        || warn $self->{TT}->error();                

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
      
    $set->{LOG}->out(RpgLog::LOG_I, "console management permissions made and sent");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make form management permissions");
    return FALSE;
}

#*******************************************************************************
#
sub _applay_change_permissions
#
#*******************************************************************************
{
    my ($self, $target, $exe) = (shift, shift, shift);
    my $set   = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $vars  = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $maker = new RpgSQLMake;
    my $ret   = FALSE;
    
    my $cgi_check = new RpgCGICheck(PARAM => $set);        
    my $cgi_desc  = CGI_DESC->{$target}{$exe};
    
    # проверка CGI запроса
    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        die sprintf('invalid CGI query, becose: "%s"', $cgi_check->errstr);
    }
    elsif ($cgi_check->loaded_fields <= 1)
    {
        $ret = TRUE;
        goto _WAS_ERROR;        
    }
    
    my $cmd_desc = COMMANDS_DESC->{$target}{$exe};
    my $tbl_desc = TABLES_DESC->{$target};
    my $table    = $set->{SETT}->get($set->{SESSION}->report(), $tbl_desc->{TABLE}{name});
    my @sql;
    
    if ('INSERT' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, "set for UID = %d allow groups '%s'",
                                        $set->{CGI}->param('lstUsers'),
                                        join (',', $set->{CGI}->param('lstAllowGroups')));
        
        # вставка за несколько итераций, для каждого включения в группу
        my (@listval, $tsql);
        $tsql = $maker->insert
            (
                TABLE     => $table,
                FIELDS    => $tbl_desc->{FIELDS},
                FIELDVALS => $cmd_desc->{set},                    
                LISTVALS  => \@listval
                #CGI       => $set->{CGI},
                #REQUEST   => $cgi_desc->{FIELDS}
            );
        
        # по количесву элементов определяем количество операций
        # вставка которое должно быть (декартово произведение)
        my @rows  =
            map
            {
                my $field = $_;
                
                [
                    map
                    {
                        RpgTypes::String2String($_, $tbl_desc->{FIELDS}{$field}{type}, 'MAIN', 'SQL')
                    }
                    $set->{CGI}->param($cmd_desc->{set}{$field})
                ]
            } @listval;
        my $count = 1; # минимальное число записей
        
        # вычисляем количество строк
        $count *= $#{$_} + 1
            foreach (@rows);
        
        # цикл формирования инструкций вставки для всех строк из декартового
        # произведения
        foreach my $i (1..$count)
        {
            my @values;
            
            foreach my $row (@rows)
            {
                push @values, $$row[$i % ($#{$row} + 1)];
            }
            
            push @sql, sprintf($tsql, @values);
        }
    }
    elsif ('DELETE' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, "set for UID = %d deny groups '%s'",
                                        $set->{CGI}->param('lstUsers'),
                                        join (',', $set->{CGI}->param('lstDenyGroups')));        
        push @sql, $maker->delete
            (
                TABLE     => $table,
                FIELDS    => $tbl_desc->{FIELDS},
                WHERE     => $cmd_desc->{where},
                CGI       => $set->{CGI},
                REQUEST   => $cgi_desc->{FIELDS}
            );
    }
    else
    {
        die sprintf("unknown type, sql instruction: '%s'", $cmd_desc->{type});
    }

    foreach (@sql)
    {
        $set->{LOG}->out(RpgLog::LOG_D, "doing change table '%s', sql: %s", $target, $_);        
        $set->{DB}->do($_);
    }
    
_WAS_ERROR:    
    return $ret;
}

1;
