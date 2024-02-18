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

package Spravochniks::RpgAdmImportFromHtml;
use UNIVERSAL qw(isa can);
use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use cgi_check;

use Spravochniks::adm_imp;

# содержит описание таблиц для импорта - экспорта
use constant TABLES_DESC =>
{
    CALENDAR =>
    {
        TABLE =>
        {
            name => 'TBL_CALENDAR'
        },
        FIELDS    => # поля таблицы в БД
        {
            date   => 
            {
                key   => 1,      # признак поля как ключевого
                type  => 'date'   # тип поля
            },
            workdate   => 
            { 
                type  => 'date'
            },                            
            recalc   => 
            { 
                type  => 'int'
            },                            
            note => 
            {
                type  => 'str',
            },
            rowver => 
            {
                type  => 'int',
                key   => 1
            }                
        }                 
    },
    DEPARTS =>
    {
        TABLE =>
        {
            name => 'TBL_DEPARTS'
        },
        FIELDS    => # поля таблицы в БД
        {
            dep   => 
            {
                type    =>  'acc',
                key     =>  TRUE
            },                                                      
            name   => 
            { 
                type    =>  'str'
            },                            
            type   => 
            { 
                type    =>  'int'
            },                            
            address => 
            {
                type    =>  'str'
            },
            okato => 
            {
                type    =>  'str'
            },
            rowver => 
            {
                type    =>  'int',
                key     => TRUE,
            }
        }                 
    },
    CLR_CODES =>
    {
        TABLE =>
        {
            name => 'TBL_CLR_CODES'
        },
        FIELDS =>
        {
            code   => 
            {
                type    =>  'str',
                key     =>  TRUE
            },                                                      
            als   => 
            { 
                type    =>  'str'
            },                            
            note => 
            {
                type    =>  'str'
            },
            rowver => 
            {
                type    =>  'int',
                key     =>  TRUE
            }
        }
    },
    CLR_RATE  =>
    {
        TABLE =>
        {
            name => 'TBL_CLR_RATE'
        },
        FIELDS =>
        {
            code   => 
            {
                type    =>  'str',
                key     =>  TRUE
            },                                                      
            date   => 
            { 
                type    =>  'date',
                key     =>  TRUE
            },                            
            base   => 
            { 
                type    =>  'int'
            },                            
            rate   => 
            { 
                type    =>  'mny'
            },                            
            rowver => 
            {
                type    =>  'int',
                key     =>  TRUE
            }
        }
    }    
};

# содержит описание действий
use constant COMMANDS_DESC => 
{
    CALENDAR =>  # параметры изменения атрибутов клиента
    {
        OPTIONS =>
        {
            # параметры изменения атрибутов клиента
            title => 'редактирование календаря'
        },
        SQL     => # шаблон SQL на изменение записей в БД
        {
            insert  =>
            { # для Inserte (привязка полей)
                date     => 'date',              
                workdate => 'workdate',          
                recalc   => 'recalc',            
                note     => 'note',
                rowver   => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                workdate => 'workdate',          
                recalc   => 'recalc',            
                note     => 'note'
            },                    
            where      =>
            {
                date   => 'date',
                rowver => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    },
    DEPARTS =>
    {
        OPTIONS =>
        {
            # параметры изменения атрибутов клиента
            title => 'редактирование списка подразделений Банка'
        },
        SQL     => # шаблон SQL на изменение записей в БД
        {
            insert  =>
            { # для Inserte (привязка полей)
                dep     => 'dep',              
                name    => 'name',          
                type    => 'type',          
                address => 'address',
                okato   => 'okato',
                rowver  => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                name    => 'name',          
                type    => 'type',          
                address => 'address',
                okato   => 'okato',
            },                    
            where      =>
            {
                dep     => 'dep',
                rowver  => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    },
    CLR_CODES =>
    {
        OPTIONS =>
        {
            title => 'редактирование клиринговых кодов'
        },
        SQL =>
        {
            insert  =>
            { # для Inserte (привязка полей)
                code    => 'code',                              
                als     => 'als',           
                note    => 'note',
                rowver  => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                als     => 'als',           
                note    => 'note'
            },                    
            where      =>
            {
                code    => 'code',
                rowver  => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    },
    CLR_RATE =>
    {
        OPTIONS =>
        {
            title => 'редактирование курсов по клиринговым операциям'
        },
        SQL =>
        {
            insert  =>
            { # для Inserte (привязка полей)
                code    => 'code',
                base    => 'base',             
                date    => 'date',          
                rate    => 'rate',          
                rowver  => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                rate    => 'rate',
                base    => 'base'          
            },                    
            where      =>
            {
                code    => 'code',
                date    => 'date',
                rowver  => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    }
};

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(Spravochniks::RpgAdmImport);
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
    ref($_[0]) && die "Error, class Spravochniks::RpgAdmImportFromHtml can't use in inheritance\n";        
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
    my ($self)   = shift;
    my ($fields) = TABLES_DESC->{$self->{TARGET}}{FIELDS};    
    my ($vars)   = $self->{$PACKAGE};
        
    $vars->{KEYS} = [grep {exists($fields->{$_}{key})} keys(%{$fields})];    
    $vars->{DATA} = new RpgSrcData;
    $vars->{DATA}->add(TO => 'STAT_FULL');   # сюда будем сохранять данные из CGI, а затем перенесем их в БД
    
    return $self;
}    

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my $self  = shift;    
    my $set   = $self->{PARAM};  
    my $vars  = $self->{$PACKAGE};                 # содержит ссылку на хеш текущего пакета    
    my $ret   = FALSE;
    
    unless (defined($self->{TARGET}) &&  defined(Spravochniks::RpgAdmImport::CGI_DESC()->{$self->{TARGET}}))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "invalid CGI query");
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
        goto _WAS_ERROR;
    }
    
    my $cgi_check = new RpgCGICheck(PARAM => $set);        
    my $cgi_desc  = Spravochniks::RpgAdmImport::CGI_DESC()->{$self->{TARGET}};
    
    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        $self->_add_alert($self->{TARGET}, 'Ошибка, неверный формат входных параметров');
        $set->{LOG}->out(RpgLog::LOG_E, 'invalid CGI query, becose: "%s"', $cgi_check->errstr);
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
        goto _WAS_ERROR;
    }
    
    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};    
        
    $set->{LOG}->out(RpgLog::LOG_I, "start import data from HTML");

    # текущая и версия переданных данных должны совпадать   
    unless($set->{CGI}->param('lstRowver') == $set->{SESSION}->rowver())
    {
        $self->_add_alert($self->{TARGET}, 'Ошибка, не совпадение версий');
        $set->{LOG}->out(RpgLog::LOG_W, "rowver isn't same (ext != int): %d != %d", $set->{CGI}->param('lstRowver'), $set->{SESSION}->rowver());
        goto _WAS_ERROR;
    }
    elsif($set->{SESSION}->access() != 2)
    {
        $self->_add_alert($self->{TARGET}, 'Ошибка, текущая версия подписана');
        $set->{LOG}->out(RpgLog::LOG_W, "access denied %d", $set->{SESSION}->access());
        goto _WAS_ERROR;
    }
   
    goto _WAS_ERROR   
        unless(

                    TRUE == $self->_parse_add('cmdDel', $cgi_check->last_pack) 
                and 
                    TRUE == $self->_parse_add('cmdIns', $cgi_check->last_pack) 
                and 
                    TRUE == $self->_parse_add('cmdUpd', $cgi_check->last_pack) 
                and 
                    TRUE == $self->submit()
                );

    $ret = TRUE;
    
_WAS_ERROR:               

    return $self->get_report(
                                STATUS => $ret,
                                TITLE  => 'Протокол внесения изменений: ' . ($imp_desc->{OPTIONS}{title})
                            );
}

#*******************************************************************************
#
sub _parse_add
#
#*******************************************************************************
{
    my ($self, $from, $request) = (shift, shift, shift);
    
    my $ret  = FALSE;    
    my $vars = $self->{$PACKAGE};               # содержит ссылку на хеш текущего пакета        
    my $set  = $self->{PARAM};                  # общие параметры

    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};  # описание полей таблицы БД      
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};     # параметры импорта
    
    foreach my $pack (@{$request->{$from}})
    {
        my $row = {};
        
        # загружаем значения полей из insert
        foreach my $field (keys(%{$imp_desc->{SQL}{insert}}))
        {
            if (defined($pack->{$imp_desc->{SQL}{insert}{$field}}))
            {
                # берем только первое значение поля
                $row->{$field} = $pack->{$imp_desc->{SQL}{insert}{$field}}->[0];
                next;
            }
            
            $row->{$field} = $set->{CGI}->param($imp_desc->{SQL}{insert}{$field});
        }

        # все ключи должны быть определены
        foreach my $field (grep{$tbl_desc->{FIELDS}{$_}{key}} keys (%{$tbl_desc->{FIELDS}}))
        {
            next if(exists($row->{$field}));
            $set->{LOG}->out(RpgLog::LOG_E, "key '%s' not found in HTTP query POST", $field);
            $self->_add_alert($self->{TARGET}, 'Ошибка, во входном потоке');
            goto _WAS_ERROR;        
        }        
        
        $row->{cmd} = $from;
        
        # добавляем строку в хранилище
        $vars->{DATA}->row_insert($row, 'STAT_FULL');            
    }

    $ret = TRUE;

_WAS_ERROR:
    return $ret;        
}

#*******************************************************************************
#
#  Метод создает транзакцию, в которой сначало удаляются записи для комманд
#  cmdDel, затем добавляются в БД из cmdIns и после обновляем из cmdUpd
#
sub submit
#
#*******************************************************************************
{
    my ($self) = shift;     
    my ($set)  = $self->{PARAM};                                 # общие параметры 
    my ($vars) = $self->{$PACKAGE};                              # содержит ссылку на хеш текущего пакета     
    my ($ret)  = FALSE; 
    my ($dbh)  = $set->{DB}; 
    
    eval 
    {
        $dbh->begin_work;
        $self->_delete_rows($dbh) || die ' ';
        $self->_insert_rows($dbh) || die ' ';
        $self->_update_rows($dbh) || die ' ';
        $dbh->commit;   # commit the changes if we get this far
    };
    
    if ($@) 
    {        
        my $msg = $@;
        
        eval { $dbh->rollback };
        
        $msg .= $@ if ($@ ne '');

        $set->{LOG}->out(RpgLog::LOG_E, "couldn't submit correction, becose: %s", $msg);
        $self->_add_alert($self->{TARGET}, 'Ошибка во входном потоке, обратитесь к администратору системы');
        goto _WAS_ERROR;
    }    
    
    $ret = TRUE;
    
_WAS_ERROR:    
    return $ret;
}

#*******************************************************************************
#
#  Метод добавляет записи в БД
#
sub _insert_rows
#
#*******************************************************************************
{
    my ($self)   = shift;    
    my ($dbh)    = shift;    
    my ($set)    = $self->{PARAM};                                 # общие параметры    
    my ($vars)   = $self->{$PACKAGE};                              # содержит ссылку на хеш текущего пакета    
    my ($ret)    = FALSE;
   
    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};  # описание полей таблицы БД      
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};     # параметры импорта
   
    # строим запрос вида: 'insert into %s (%s) values (%s)'
    my ($listvals) = [];
    my ($maker)    = new RpgSQLMake();
    my ($template) = $maker->insert
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), 
                                           $tbl_desc->{TABLE}{name}),
            FIELDVALS => $imp_desc->{SQL}{insert},
            FIELDS    => $tbl_desc->{FIELDS},
            LISTVALS  => $listvals
        );
    # цикл по добавляемым записям
    foreach my $row (@{$vars->{DATA}->get_data('STAT_FULL')})
    {
        next unless($row->{cmd} eq 'cmdIns');

        my $query = sprintf($template, 
                            map 
                            {
                                can($row->{$_}, 'convert') ?
                                    $row->{$_}->convert('SQL') :
                                    RpgTypes::String2String($row->{$_}, $tbl_desc->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                            } @{$listvals});
        
        $set->{LOG}->out(RpgLog::LOG_D, "try execute insert, sql: %s", $query);          
        $dbh->do($query);        
    }    
    
    $ret = TRUE;
    
_WAS_ERROR:    
    return $ret;    
}

#*******************************************************************************
#
#  Метод удаляет записи в БД
#
sub _delete_rows
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($dbh)  = shift;    
    my ($set)  = $self->{PARAM};                                 # общие параметры    
    my ($vars) = $self->{$PACKAGE};                              # содержит ссылку на хеш текущего пакета    
    my ($ret)  = FALSE;
   
    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};  # описание полей таблицы БД      
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};     # параметры импорта
    
    # строим запрос вида: 'delete from %s where %s'    
    my ($listvals) = [];
    my ($maker)    = new RpgSQLMake();    
    my ($template) = $maker->delete
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), 
                                           $tbl_desc->{TABLE}{name}),
            WHERE     => $imp_desc->{SQL}{where},
            FIELDS    => $tbl_desc->{FIELDS},
            LISTVALS  => $listvals
        );    
                                      
    foreach my $row (@{$vars->{DATA}->get_data('STAT_FULL')})
    {
        next unless($row->{cmd} eq 'cmdDel');

        my $query = sprintf($template, 
                            map 
                            {
                                can($row->{$_}, 'convert') ?
                                    $row->{$_}->convert('SQL') :
                                    RpgTypes::String2String($row->{$_}, $tbl_desc->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                            } @{$listvals});
        
        $set->{LOG}->out(RpgLog::LOG_D, "try execute delete, sql: %s", $query);
        $dbh->do($query);
    }

    $ret = TRUE;
    
_WAS_ERROR:    
    return $ret;    
}

#*******************************************************************************
#
#  Метод обновляет записи в БД
#
sub _update_rows
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($dbh)  = shift;    
    my ($set)  = $self->{PARAM};                            # общие параметры    
    my ($vars) = $self->{$PACKAGE};                         # содержит ссылку на хеш текущего пакета    
    my ($ret)  = FALSE;
   
    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};  # описание полей таблицы БД      
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};     # параметры импорта
    
    # строим запрос вида: 'update table_name set field = %s where %s'    
    my ($listValsForUpdate, $listValsForInsert, $listValsForSelect) = ([], [], []);
    my ($maker)    = new RpgSQLMake();    
    my ($update)   = $maker->update
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), 
                                           $tbl_desc->{TABLE}{name}),
            FIELDVALS => $imp_desc->{SQL}{update},
            WHERE     => $imp_desc->{SQL}{where},
            FIELDS    => $tbl_desc->{FIELDS},
            LISTVALS  => $listValsForUpdate
        );    
    my ($select)   = 
        'select 1 ' .
        $maker->from
            (
                FROM =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), $tbl_desc->{TABLE}{name}),
                    param  => [],
                    single => 1
                }
            ) . ' ' .
        $maker->where
            (
                WHERE     => $imp_desc->{SQL}{where},
                FIELDS    => $tbl_desc->{FIELDS},
                LISTVALS  => $listValsForSelect
            );                                                                 
    my ($insert)    = $maker->insert
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), 
                                           $tbl_desc->{TABLE}{name}),
            FIELDVALS => $imp_desc->{SQL}{insert},
            FIELDS    => $tbl_desc->{FIELDS},
            LISTVALS  => $listValsForInsert
        );
        
    foreach my $row (@{$vars->{DATA}->get_data('STAT_FULL')})
    {
        next unless($row->{cmd} eq 'cmdUpd');
        
        my $query = sprintf($update, 
                            map 
                            {
                                can($row->{$_}, 'convert') ?
                                    $row->{$_}->convert('SQL') :
                                    RpgTypes::String2String($row->{$_}, $tbl_desc->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                            } @{$listValsForUpdate});
        
        $set->{LOG}->out(RpgLog::LOG_D, "try execute update, sql: %s", $query);
                
        my $status = $dbh->do($query);
        
        if ($status <= 0 && exists($imp_desc->{SQL}{check_update}))
        {   
            # операция обновления вернула признак, количества обновленных записей меньше 1
            # проверяем причину, делаем выборку и проверяем что такая запись существует
            $query = sprintf
                (
                    $select, 
                    map 
                    {
                        can($row->{$_}, 'convert') ?
                            $row->{$_}->convert('SQL') :
                            RpgTypes::String2String($row->{$_}, $tbl_desc->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                    } @{$listValsForSelect});
            
            $set->{LOG}->out(RpgLog::LOG_D, "need, check update row (becose last update return %d), try select, sql: %s", $status, $query);
            
            my $sth    = $dbh->prepare($query); $sth->execute();
            my $exists = defined($sth->fetchrow_arrayref);
            
            $sth->finish();
            
            unless ($exists)
            {
                # такой записи не существует в БД, добавляем запись в БД
                $query = sprintf
                    (
                        $insert, 
                        map 
                        {
                            can($row->{$_}, 'convert') ?
                                $row->{$_}->convert('SQL') :
                                RpgTypes::String2String($row->{$_}, $tbl_desc->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                        } @{$listValsForInsert});
                $set->{LOG}->out(RpgLog::LOG_D, "row was not find, try insert, sql: %s", $query);
                $dbh->do($query);
            }
        }
    }

    $ret = TRUE;
    
_WAS_ERROR:    
    return $ret;    
}

1;
