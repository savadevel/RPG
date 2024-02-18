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

package Spravochniks::RpgAdmImport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use const;
use types;
use sql_make;

use Spravochniks::adm_imp_html;
use Spravochniks::adm_exp;

use constant CGI_DESC =>  # содержит поля запроса, по ним делаем его валидацию
{
    CALENDAR => 
    { # параметры запроса на редактирование календаря
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            cmdUpd  => 
            {
                type   => 'str',
                array  => TRUE          
            },
            lstRowver =>
            {
                type => 'int'
            }
        },                    
        CHECKS => # проверки
        {
            pack => # cmdUpd=date:30.01.2006;workdate:30.01.2006;recalc:0;note:рабочий день;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            date =>
                            {
                                type => 'date' 
                            },
                            workdate =>
                            {
                                type => 'date' 
                            },
                            recalc =>
                            {
                                type => 'int' 
                            },
                            note =>
                            {
                                type => 'str' 
                            }                                                        
                        },
                        checks =>
                        {
                            compare =>
                            [
                                {cmp => 'ge', fields => ['date', 'workdate'], value => 0, oper => '-'} 
                            ]
                        }
                    }
                }
            ]
        }                
    },
    DEPARTS => 
    { # параметры запроса на редактирование подразделений Банка
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdIns  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdDel  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },            
            lstRowver =>
            {
                type => 'int'
            }
        },                    
        CHECKS => # проверки
        {
            pack => # cmdUpd=dep:9999;name:Москв;type:0;address:;okato:;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            dep =>
                            {
                                type => 'str' 
                            },
                            name =>
                            {
                                type => 'str' 
                            },
                            type =>
                            {
                                type => 'int' 
                            },
                            address =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            okato =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'dep', exp => '^\d{4}$'}
                            ]
                        }
                    }
                },
                { # cmdIns=dep:2345;name:tytuy;type:0;address:;okato:;
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            dep =>
                            {
                                type => 'str' 
                            },
                            name =>
                            {
                                type => 'str' 
                            },
                            type =>
                            {
                                type => 'int' 
                            },
                            address =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            okato =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'dep', exp => '^\d{4}$'}
                            ]
                        }
                    }
                },
                { # cmdDel=dep:2345;name:tytuy;type:0;address:;okato:;
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            dep =>
                            {
                                type => 'str' 
                            },
                            name =>
                            {
                                type => 'str' 
                            },
                            type =>
                            {
                                type => 'int' 
                            },
                            address =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            okato =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'dep', exp => '^\d{4}$'}
                            ]
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdIns', 'cmdDel', 'cmdUpd'], min => 1, max => undef}
            ]                        
        }                
    },
    CLR_CODES => 
    { # параметры запроса на выгрузку клиринговых кодов 
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdIns  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdDel  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            lstRowver =>
            {
                type => 'int'
            }
        },                    
        CHECKS => # проверки
        {
            pack => 
            [
                {   # cmdUpd=code:C16;als:;cbase:100000;note:12;
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            als  =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            note =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'},
                                {field => 'als',  exp => '^\w{3}|\w{0}$'},
                            ],
                            range =>
                            [
                                {field => 'cbase', min => 1, max => undef}
                            ]                            
                        }
                    }
                },
                { # cmdIns=code:R23;als:A33;cbase:1;note:;
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            als  =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            note =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'},
                                {field => 'als',  exp => '^\w{3}|\w{0}$'},
                            ],
                            range =>
                            [
                                {field => 'cbase', min => 1, max => undef}
                            ]                             
                        }
                    }
                },
                { # cmdDel=code:R23;als:A33;cbase:1;note:;
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            als  =>
                            {
                                type     => 'str',
                                optional => TRUE
                            },
                            note =>
                            {
                                type     => 'str',
                                optional => TRUE
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'},
                                {field => 'als',  exp => '^\w{3}|\w{0}$'},
                            ],
                            range =>
                            [
                                {field => 'cbase', min => 1, max => undef}
                            ]                             
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdIns', 'cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]
        }                
    },
    CLR_RATE => 
    { # параметры запроса на выгрузку курсов клиринговых кодов 
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdIns  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },
            cmdDel  => 
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE
            },            
            lstRowver =>
            {
                type => 'int'
            }
        },                    
        CHECKS => # проверки
        {
            pack => # cmdUpd=code:C57;date:28.05.1999;rate:3.89;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            date =>
                            {
                                type => 'date'
                            },
                            base =>
                            {
                                type => 'int' 
                            },
                            rate =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'}
                            ],
                            range =>
                            [
                                {field => 'rate', min => 0.0001, max => undef}
                            ]
                        }
                    }
                },
                { # cmdIns=code:C57;date:28.05.1999;rate:3.89;
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            date =>
                            {
                                type => 'date'
                            },
                            base =>
                            {
                                type => 'int' 
                            },
                            rate =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'}
                            ],
                            range =>
                            [
                                {field => 'rate', min => 0.0001, max => undef}
                            ]
                        }
                    }
                },
                { # cmdDel=code:C57;date:28.05.1999;rate:3.89;
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            code =>
                            {
                                type => 'str' 
                            },
                            date =>
                            {
                                type => 'date'
                            },
                            base =>
                            {
                                type => 'int' 
                            },
                            rate =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [                                
                                {field => 'code', exp => '^\w{3}$'}
                            ],
                            range =>
                            [
                                {field => 'rate', min => 0.0001, max => undef}
                            ]
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdIns', 'cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]
        }                
    }
};

use constant SUPPORT_SOURCES => # ассоциации модулей с параметрами запроса
{
    CALENDAR  => sub {new Spravochniks::RpgAdmImportFromHtml(@_);},
    DEPARTS   => sub {new Spravochniks::RpgAdmImportFromHtml(@_);},
    CLR_CODES => sub {new Spravochniks::RpgAdmImportFromHtml(@_);},
    CLR_RATE  => sub {new Spravochniks::RpgAdmImportFromHtml(@_);}
};    

BEGIN 
{    
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw (Spravochniks::RpgPageAdmin);
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
#       ENV_TT2 : переменные окружения для Template toolkit
#       LOG     : указатель на объект-логер, VbtLog
#       CGI     : ссылка на CGI модуль
#       MODULE  : определяет источник в SETT
#*******************************************************************************
{
    my ($class) = shift;
    
    unless (ref($class))
    {        
        # сюда попадаем только если объект создаётся на прямую, т.е. класса ещё не существует
        # в блоке делается переопределение объекта (передача управления дочерним классам)
        my %args = (@_);
        my $page = $args{PARAM}{CGI}->param('page');
        
        if (defined($page) and
            defined(SUPPORT_SOURCES->{uc($page)}))
        {
            return SUPPORT_SOURCES->{uc($page)}(@_);
        }       
        
        # задан не известный источник
        $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query load data from unknow source '%s'", $page);         
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
};

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($set)  = $self->{PARAM}; # общие параметры, значение self->{PARAM}, установленно в базовом классе    
    
    $set->{LOG}->out(RpgLog::LOG_I, "do import from '%s'", (defined($set->{CGI}->param('page')) ? $set->{CGI}->param('page') : '???'));
    
    return $self;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my ($self) = shift;        
    return $self->SUPER::do();    
}

#*******************************************************************************
#
# Печать HTML отчета о процедуре импорта
#
sub get_report
#
#*******************************************************************************
{
    my $self = shift;        
    my $set  = $self->{PARAM};      # общие параметры    
    my $vars = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета    
    my %args = (@_);        

    $set->{CGI}->param(-name => 'exe', -value => 'EXPORT'); 

    my $report = new Spravochniks::RpgAdmExport(%{$self});
    
    return $report->do();
}

1;
