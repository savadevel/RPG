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

package F136::RpgAdmRowVersion;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use sql_make;
    
use constant CGI_DESC =>  # содержит поля запроса, по ним делаем его валидацию
{
    EDIT => 
    { # параметры запроса на изменение атрибутов версии
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            lstRowver  => # ID версии
            {
                type     => 'int'
            },
            edtVerDateLeft => # левая граница (дата) отчетного переиода
            {
                type     => 'date',
                optional => TRUE   
            },
            edtVerDateRight => # правая граница (дата) отчетного переиода
            {
                type     => 'date',
                optional => TRUE
            },
            chkIsCurr => # признак того что версия текущая
            {
                type     => 'int',
                optional => TRUE
            },
            chkIsFix => # признак того что версия подписана
            {
                type     => 'int',
                optional => TRUE
            },
            chkIsUseOutSum => # Использовать исходящий остаток
            {
                type     => 'int',
                optional => TRUE
            },
            edtNote => # Описание версии
            {
                type     => 'str',
                optional => TRUE
            }
        },                    
        CHECKS => # проверки
        {
            compare =>
            [
                {cmp => 'le', fields => ['edtVerDateRight', 'edtVerDateLeft'], value => 3024000, oper => '-'},
                {cmp => 'ge', fields => ['edtVerDateRight', 'edtVerDateLeft'], value => 259200,  oper => '-'} 
            ]
        }                
    },
    DELETE => 
    { # параметры запроса на удаление версии
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            lstRowver  => # ID версии
            {
                type     => 'int' # тип данных
            }
        },                    
        CHECKS => # проверки
        {
        }                
    },
    CREATE => 
    { # параметры запроса на создание версии
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            lstParentRowver  => # ID родительской версии
            {
                type     => 'int'
            },
            edtVerDateLeft => # левая граница (дата) отчетного переиода
            {
                type     => 'date'
            },
            edtVerDateRight => # правая граница (дата) отчетного переиода
            {
                type     => 'date'      
            },
            edtLabel  => # имя версии
            {
                type     => 'str'         
            },
            edtNote =># Описание версии
            {
                type     => 'str',
                optional => TRUE
            },
            chkIsUseOutSum =>
            {
                type     => 'bool',
                optional => TRUE
            }
        },                    
        CHECKS => # проверки
        {
            compare =>
            [
                {cmp => 'le', fields => ['edtVerDateRight', 'edtVerDateLeft'], value => 3024000, oper => '-'},
                {cmp => 'ge', fields => ['edtVerDateRight', 'edtVerDateLeft'], value => 259200,  oper => '-'} 
            ]
        }                
    }
};

use constant TABLE_DESC =>
{
    TABLE =>
    {
        name => 'TBL_ROWVER'
    },
    FIELDS =>
    {
        rowver => 
        {                                
            key    =>   TRUE,         # признак поля как ключевого
            type   =>   'int'         # тип поля
        },
        prowver => 
        {                                
            type   =>   'int'   
        },
        label => 
        {                                
            type   =>   'str'   
        },
        note => 
        {                                
            type   =>   'txt'   
        },
        ldate => 
        {                                
            type   =>   'date'   
        },
        rdate => 
        {                                
            type   =>   'date'   
        },
        transfer => 
        {                                
            type   =>   'bool'   
        },
        is_curr => 
        {                                
            type   =>   'int'   
        },
        is_fix => 
        {                                
            type   =>   'int'   
        }
    }        
};

use constant COMMANDS_DESC => #  описание действий
{
    EDIT =>
    {        
        type => 'UPDATE',
        set  => 
        { # соответствия между полями в CGI запросе и полями таблицы
#                label    => 'edtLabel',
            note     => 'edtNote',
            ldate    => 'edtVerDateLeft',
            rdate    => 'edtVerDateRight',
            transfer => 'chkIsUseOutSum',
            is_curr  => 'chkIsCurr',
            is_fix   => 'chkIsFix'
        },                    
        where    => 
        { # условие на обновление
            rowver  => 'lstRowver'
        }            
    },
    DELETE =>
    {        
        type  => 'DELETE',
        where => 
        { # условие на удаление
            rowver  => 'lstRowver'
        }            
    },
    CREATE =>
    {        
        type => 'INSERT',
        set  => 
        { # соответствия между полями в CGI запросе и полями таблицы
            label    => 'edtLabel',
            note     => 'edtNote',
            ldate    => 'edtVerDateLeft',
            rdate    => 'edtVerDateRight',
#               transfer => 'chkIsUseOutSum',
            prowver  => 'lstParentRowver'
        }                    
    }
};   

BEGIN 
{    
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw (F136::RpgPageAdmin);
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
    ref($_[0]) && die "Error, class F136::RpgAdmRowVersion can't use in inheritance\n";        
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
};

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
    my $set  = $self->{PARAM};       # общие параметры
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    $set->{LOG}->out(RpgLog::LOG_I, "need applay changes of a version");

    unless (defined($self->{EXE}) &&  defined(CGI_DESC->{$self->{EXE}}))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "invalid CGI query");
        goto _WAS_ERROR;
    }
    
    my $cgi_check = new RpgCGICheck(PARAM => $set);        
    my $cgi_desc  = CGI_DESC->{$self->{EXE}};
    
    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, 'invalid CGI query, becose: "%s"', $cgi_check->errstr);
        goto _WAS_ERROR;
    }

    my $maker = new RpgSQLMake();
    my $table = $set->{SETT}->get($set->{SESSION}->report(), TABLE_DESC->{TABLE}{name});
    my $sql   = '';
    
    if ('UPDATE' eq COMMANDS_DESC->{$self->{EXE}}->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, "update version [%s]", join(",", map($_, $set->{CGI}->param('lstRowver'))));
        $sql = $maker->update
        (
            TABLE     => $table,
            FIELDS    => TABLE_DESC->{FIELDS},
            FIELDVALS => COMMANDS_DESC->{$self->{EXE}}{set},
            WHERE     => COMMANDS_DESC->{$self->{EXE}}{where},
            CGI       => $set->{CGI},
            REQUEST   => CGI_DESC->{$self->{EXE}}{FIELDS}
        );
    }
    elsif ('INSERT' eq COMMANDS_DESC->{$self->{EXE}}->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, "insert version [%s]", join(",", map($_, $set->{CGI}->param('edtLabel'))));
        $sql = $maker->insert
                (
                    TABLE     => $table,
                    FIELDS    => TABLE_DESC->{FIELDS},
                    FIELDVALS => COMMANDS_DESC->{$self->{EXE}}{set},
                    CGI       => $set->{CGI},
                    REQUEST   => CGI_DESC->{$self->{EXE}}{FIELDS}
                );
    }
    elsif ('DELETE' eq COMMANDS_DESC->{$self->{EXE}}->{type})
    {
        $set->{LOG}->out(RpgLog::LOG_I, "delete version [%s]", join(",", map($_, $set->{CGI}->param('lstRowver'))));
        $sql = $maker->delete
                (
                    TABLE     => $table,
                    FIELDS    => TABLE_DESC->{FIELDS},
                    WHERE     => COMMANDS_DESC->{$self->{EXE}}{where},
                    CGI       => $set->{CGI},
                    REQUEST   => CGI_DESC->{$self->{EXE}}{FIELDS}
                );
    }
    else
    {
        die "Error, unknown type, sql instruction: COMMANDS_DESC->{$self->{EXE}}->{type}\n";
    }

    $set->{LOG}->out(RpgLog::LOG_D, "doing change table of version, sql: %s", $sql);        

    eval
    {
        $set->{DB}->do($sql);    
    };

    if ($@) 
    {                
        $set->{LOG}->out(RpgLog::LOG_E, "couldn't submit changes, becose: %s", $@);
        goto _WAS_ERROR;
    }    

    $set->{LOG}->out(RpgLog::LOG_I, "changes applied");    

_WAS_ERROR:
    # формирует страницу с Redirect на административную консоль, что бы не вазится с пересозданием текущей сессии        
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251',
                              -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));
    print "<html><meta http-equiv='refresh' content=0></html>";
    return TRUE;
}

1;
