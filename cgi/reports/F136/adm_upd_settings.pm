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

package F136::RpgAdmUpdateSettings;

use UNIVERSAL qw(isa can);
use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use Exporter;
use English;
use strict;
use warnings;
use utils;
use sql_make;

use constant TABLE_DESC =>
{
    TABLE =>
    {
        name  => 'TBL_F136_SETTINGS'
    },
    FIELDS =>
    {
        setting => 
        {                                
            key  => TRUE,         # признак поля как ключевого
            name => 'setting',    # физическое имя поля
            type => 'str'         # тип поля
        },
        val => 
        {                            
            name => 'val',
            type => 'str'   
        },
        type => 
        {                            
            name => 'type',
            type => 'str'   
        }
    }
};

use constant COMMAND_DESC =>
{
    OPTIONS =>
    {
    },
    SQL =>
    {
        update  => 
        { # соответствия между полями
            val      => 'val'
        },                    
        where    => 
        { # условие на обновление
            setting  => 'setting'
        }                
    }    
};

use constant DICTIONARY =>
{
    src     => 'SQL_GET_F136_SETTINGS',
    params  => [] 
};

BEGIN 
{    
    $VERSION = 0.01;
    @ISA     = qw(F136::RpgAdmImportCorr);
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
#  PARAM - хеш содержит следующие элементы
#       SETT    : указатель на объект, источник денамических параметров RpgSett    
#       LOG     : указатель на объект-логер, VbtLog
#       CGI     : ссылка на CGI модуль
#       SESSION : параметры текущей сессии
#*******************************************************************************
{
    ref($_[0]) && die "Error, class F136::RpgAdmUpdateSettings can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({@_}, $class);
           
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
    my ($self) = shift;        
    my ($set)  = $self->{PARAM};       # общие параметры
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    $set->{LOG}->out(RpgLog::LOG_I, "start update parameters 'Report by form 0409136'"); 

    # текущая и версия переданных данных должны совпадать   
    unless($set->{CGI}->param('rowver') == $set->{SESSION}->rowver())
    {
        $self->_add_alert('PARAM', 'ошибка, не совпадение версий');
        $set->{LOG}->out(RpgLog::LOG_W, "rowver isn't same (ext != int): %d != %d", $set->{CGI}->param('rowver'), $set->{SESSION}->rowver());
        goto _WAS_ERROR;
    }
    elsif($set->{SESSION}->access() != 2)
    {
        $self->_add_alert('PARAM', 'ошибка, текущая версия подписана');
        $set->{LOG}->out(RpgLog::LOG_W, "access denied %d", $set->{SESSION}->access());
        goto _WAS_ERROR;
    }

    $self->_check() && $self->_submit();    
    $set->{LOG}->out(RpgLog::LOG_I, "parameters was updating");         
_WAS_ERROR:    

    return $self->SUPER::do();    
}

#*******************************************************************************
#
sub _check
#
#*******************************************************************************
{
    my ($self) = shift;        
    my ($set)  = $self->{PARAM};       # общие параметры
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    $vars->{DATA}      = new RpgSrcData;
    $vars->{DO_UPDATE} = [];
    
    # загружаем текущие параметры, по ним будем искать в запросе параметры для обновления
    # и делать проверку форматов
    unless ($vars->{DATA}->add(FROM  => $set->{DB}, 
                               TO    => 'GET_SETTINGS',
                               SRC   => $set->{SETT}->get($set->{SESSION}->report(), DICTIONARY->{src}),
                               PARAM => DICTIONARY->{params}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, "couldn't loading parameters from DB for checking input parameters, becose: %s", $vars->{DATA}->errstr());
        goto _WAS_ERROR;    
    }
    
    my ($listvals) = [];
    my ($maker)    = new RpgSQLMake();
    my ($template) = $maker->update
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), TABLE_DESC->{TABLE}{name}),
            FIELDS    => TABLE_DESC->{FIELDS},
            FIELDVALS => COMMAND_DESC->{SQL}{update},
            WHERE     => COMMAND_DESC->{SQL}{where},
            LISTVALS  => $listvals
        );

    # ищим и проверяем параметры формы
    foreach my $row (@{$vars->{DATA}->get_data('GET_SETTINGS')})
    {
        my $val = $set->{CGI}->param($row->{setting});
        
        next unless (defined($val));
        
        eval
        {
            $val = new RpgType(rval => \$val, type => $row->{type});
        };
        
        if ($@)
        {
            $set->{LOG}->out(RpgLog::LOG_W, "invalid value '%s' parameter '%s', becose: %s", $set->{CGI}->param($row->{setting}), $row->{type}, $@);
            goto _WAS_ERROR;
        }

        my $param = {setting => $row->{setting}, val => $val};
        my $query = sprintf($template, 
                            map 
                            {
                                can($param->{$_}, 'convert') ?
                                    $param->{$_}->convert('SQL') :
                                    RpgTypes::String2String($param->{$_}, TABLE_DESC->{FIELDS}{$_}{type}, 'MAIN', 'SQL');
                            } @{$listvals});

        push @{$vars->{DO_UPDATE}}, $query;
    } 
    
    return TRUE;
    
_WAS_ERROR:        
    return FALSE;
}

#*******************************************************************************
#
sub _submit
#
#*******************************************************************************
{
    my ($self) = shift;        
    my ($set)  = $self->{PARAM};       # общие параметры
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    my ($dbh)  = $set->{DB}; 
    my $query  = undef;

    eval 
    {
        $dbh->begin_work;        
        foreach $query (@{$vars->{DO_UPDATE}})
        {
            $set->{LOG}->out(RpgLog::LOG_D, "try execute update, sql: %s", $query);          
            $dbh->do($query);
        }        
        $dbh->commit;   # commit the changes if we get this far
    };
    
    if ($@) 
    {           
        my $msg = $@;
        
        eval {$dbh->rollback};
        
        $msg .= $@ if ($@ ne '');

        $set->{LOG}->out(RpgLog::LOG_E, "couldn't update parameters, becose: %s", $@);
        $set->{LOG}->out(RpgLog::LOG_D, "couldn't execution instruction: %s", $query);        
        goto _WAS_ERROR;
    }    
    
    return TRUE;
    
_WAS_ERROR:        
    return FALSE;
}

1;
