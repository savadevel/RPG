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

package admin::RpgAdminUsers;

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
    GET_IP    =>  # список ресурсов, зарегистрированных в журнале сервера данных
    {
        src    => 'SQL_GET_IP',
        params => []
    }
};

use constant FIELDS_OF_DICTIONARIES => 
{
};

use constant CGI_DESC =>  # содержит поля запроса, по ним делаем его валидацию
{
    USERS =>
    {
        EDIT => 
        { # параметры запроса на изменение атрибутов версии
            FIELDS => # список параметров которые могут быть в CGI запросе
            {                   
                lstUsers  => # ID пользователя
                {
                    type     => 'int'
                },
                edtName => # ФИО
                {
                    type     => 'str'  
                },
                edtFname => # Фамилия
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtMname => # Имя    
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtLname => # Отчество
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtDepartment => # Подразделение
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtPosition => # Должность
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtPhone => # Телефон
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtFax => # Факс
                {
                    type     => 'str',
                    optional => TRUE
                },
                edtNote => # Описание
                {
                    type     => 'str',
                    optional => TRUE
                }
            },                    
            CHECKS => # проверки
            {
                match =>
                [
                    {field => 'edtName', exp => '^.+$'}
                ]
            }                
        },
        DELETE => 
        { # параметры запроса на удаление пользователя
            FIELDS => # список параметров которые могут быть в CGI запросе
            {                   
                lstUsers  => # ID пользователя
                {
                    type    => 'int' # тип данных
                }
            },                    
            CHECKS => # проверки
            {
            }                
        },
        CREATE => 
        { # параметры запроса на создание пользователя
            FIELDS => # список параметров которые могут быть в CGI запросе
            {
                edtLogin =>
                {
                    type => 'str'
                },
                edtDomain =>
                {
                    type => 'str'
                },
                edtName =>
                {
                    type => 'str'
                }
            },                    
            CHECKS => # проверки
            {
            }                
        }
    },
    IP =>
    {
        CREATE =>
        {
            FIELDS =>
            {
                lstUsers  => # ID пользователя
                {
                    type     => 'int' # тип данных                    
                },
                lstIpIns =>
                {
                    type     => 'ip',
                    optional => TRUE,
                    array    => TRUE
                }
            },
            CHECKS => # проверки
            {
                match =>
                [
                    {field => 'lstIpIns', exp => '^(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))$'},
                ]
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
                lstIpDel =>
                {
                    type     => 'ip',
                    optional => TRUE,
                    array    => TRUE
                }
            },
            CHECKS => # проверки
            {
                match =>
                [
                    {field => 'lstIpDel', exp => '^(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))\.(?:(?:[0-1][0-9][0-9])|(?:[2][0-5][0-5]))$'},
                ]
            }                
        }
    }
};

use constant TABLES_DESC =>
{
    USERS =>
    {
        TABLE =>
        {
            name => 'TBL_USERS'
        },
        FIELDS =>
        {
            uid =>
            {
                type    => 'int',
                key     => TRUE
            },
            name =>
            {
                type    => 'str'
            },
            fname =>
            {
                type    => 'str'
            },
            mname =>
            {
                type    => 'str'
            },
            lname =>
            {
                type    => 'str'
            },
            position =>
            {
                type    => 'str'
            },
            department =>
            {
                type    => 'str'
            },
            phone =>
            {
                type    => 'str'
            },
            fax =>
            {
                type    => 'str'
            },
            domain =>
            {
                type    => 'str'
            },
            login =>
            {
                type    => 'str'
            },
            note =>
            {
                type    => 'str'
            }            
        }
    },
    IP =>
    {
        TABLE =>
        {
            name => 'TBL_IP'
        },
        FIELDS =>
        {
            uid => 
            {
                type    => 'int'
            },
            number => 
            {                                
                type    => 'ip'
            },
            ip => 
            {                                
                type    => 'int'
            }            
        }
    }    
};

use constant COMMANDS_DESC => #  описание действий
{
    USERS =>
    {
        EDIT =>
        {        
            type => 'UPDATE',
            set  => 
            { # соответствия между полями в CGI запросе и полями таблицы
                name        => 'edtName',
                fname       => 'edtFname',
                mname       => 'edtMname',
                lname       => 'edtLname',
                position    => 'edtPosition',
                department  => 'edtDepartment',
                phone       => 'edtPhone',
                fax         => 'edtFax',                
                note        => 'edtNote'
            },                    
            where    => 
            { # условие на обновление
                uid  => 'lstUsers'
            }            
        },
        DELETE =>
        {        
            type    => 'DELETE',
            where   => 
            { # условие на удаление
                uid => 'lstUsers'
            }            
        },
        CREATE =>
        {        
            type => 'INSERT',
            set  => 
            { # соответствия между полями в CGI запросе и полями таблицы
                login    => 'edtLogin',
                domain   => 'edtDomain',
                name     => 'edtName'
            }                    
        }
    },
    IP =>
    {
        DELETE =>
        {        
            type    => 'DELETE',
            where   => 
            { # условие на удаление
                uid     => 'lstUsers',
                number  => 'lstIpDel'
            }            
        },
        CREATE =>
        {        
            type    => 'INSERT',
            set     => 
            { # соответствия между полями в CGI запросе и полями таблицы
                uid     => 'lstUsers',
                number  => 'lstIpIns'
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
    ref($_[0]) && die "Error, class admin::RpgAdminUsers can't use in inheritance\n";        
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
    $self->{EXE}    = undef;
            
    my $exe  = $set->{CGI}->param('exe');
    my $page = $set->{CGI}->param('page');
    
    if (    defined($exe) 
        and defined($page)
        and defined(CGI_DESC()->{(uc($page))}{(uc($exe))}))
    {
        $self->{TARGET} = uc($page);
        $self->{EXE}    = uc($exe);
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
        $set->{LOG}->out(RpgLog::LOG_I, "start apply change: TARGET = '%s', EXE = '%s'",
                                        $self->{TARGET}, $self->{EXE});
        
        my $dbh = $set->{DB};
        
        eval 
        {
            $dbh->begin_work;
            $self->_applay_change_user($self->{TARGET}, $self->{EXE});
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
        
    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for make console management users");
    
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
    $self->{TT}->process('adm_users.html',
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
                login  => ($set->{CGI}->param('edtLogin') ?  $set->{CGI}->param('edtLogin')  : $set->{SESSION}->login),
                domain => ($set->{CGI}->param('edtLogin') ?  $set->{CGI}->param('edtDomain') : $set->{SESSION}->domain),
            },
            errors       => $self->errstr,
            alerts       => $self->alerts,
            dformat      => $types{date}{format},
            tformat      => $types{time}{format},
            date2str     => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
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

    $set->{LOG}->out(RpgLog::LOG_I, "console management users made and sent");
    return TRUE;    

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for make console management users");
    return FALSE;
}

#*******************************************************************************
#
sub _applay_change_user
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
    
    my $cmd_desc = COMMANDS_DESC->{$target}{$exe};
    my $tbl_desc = TABLES_DESC->{$target};
    my $table    = $set->{SETT}->get($set->{SESSION}->report(), $tbl_desc->{TABLE}{name});
    my $sql      = '';
    
    # определяем тип изменений
    if ('UPDATE' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, 'update parameters of user with uid [%d]',
                                        $set->{CGI}->param('lstUsers'));
        $sql = $maker->update
        (
            TABLE     => $table,
            FIELDS    => $tbl_desc->{FIELDS},
            FIELDVALS => $cmd_desc->{set},
            WHERE     => $cmd_desc->{where},
            CGI       => $set->{CGI},
            REQUEST   => $cgi_desc->{FIELDS}
        );        
        
        # учитываем изменения в таблице IP для текущего пользователя
        $self->_applay_change_ip('IP', 'DELETE');
        $self->_applay_change_ip('IP', 'CREATE');
    }
    elsif ('INSERT' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, 'add user: domain="%s", login="%s", name="%s" ',
                                        $set->{CGI}->param('edtDomain'),
                                        $set->{CGI}->param('edtLogin'),
                                        $set->{CGI}->param('edtName'));
        
        $sql = $maker->insert
                (
                    TABLE     => $table,
                    FIELDS    => $tbl_desc->{FIELDS},
                    FIELDVALS => $cmd_desc->{set},
                    CGI       => $set->{CGI},
                    REQUEST   => $cgi_desc->{FIELDS}
                );
    }
    elsif ('DELETE' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, 'delete user with uid [%d]',
                                        $set->{CGI}->param('lstUsers'));
        $sql = $maker->delete
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

    $set->{LOG}->out(RpgLog::LOG_D, "doing change table '%s', sql: %s", $target, $sql);        
    $set->{DB}->do($sql);
    
_WAS_ERROR:    
    return $ret;
}

#*******************************************************************************
#
sub _applay_change_ip
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
    my $sql      = '';
    
    if ('INSERT' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, 'add IP(s) for user with uid [%d]',
                                        $set->{CGI}->param('lstUsers'));
        
        $sql = $maker->insert
                (
                    TABLE     => $table,
                    FIELDS    => $tbl_desc->{FIELDS},
                    FIELDVALS => $cmd_desc->{set},
                    CGI       => $set->{CGI},
                    REQUEST   => $cgi_desc->{FIELDS}
                );
    }
    elsif ('DELETE' eq $cmd_desc->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, 'delete IP(s) for user with uid [%d]',
                                        $set->{CGI}->param('lstUsers'));
        $sql = $maker->delete
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

    $set->{LOG}->out(RpgLog::LOG_D, "doing change table '%s', sql: %s", $target, $sql);        
    $set->{DB}->do($sql);
    
_WAS_ERROR:    
    return $ret;
}

1;
