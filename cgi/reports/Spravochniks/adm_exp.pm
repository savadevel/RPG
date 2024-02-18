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

package Spravochniks::RpgAdmExport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use const;
use types;
use src_data;
use cgi_check;
use sql_make;

use Spravochniks::page_adm;
use Spravochniks::adm_exp_html;
use Spravochniks::adm_exp_excel;

use constant CGI_DESC => # содержит поля запроса, по ним делаем его валидацию
{
    CALENDAR =>
    { # параметры выгрузки календаря
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type     => 'date',       
                request  => TRUE         
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type     => 'date',
                request  => TRUE
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            rowver =>
            {
                type     => 'int'
            },
            lstOutTo => 
            {
                type    => 'str',
                request => TRUE                            
            },
            page => 
            {
                type    => 'str',
                request => TRUE                            
            },
            exe => 
            {
                type    => 'str',
                request => TRUE                            
            }                
        },                    
        CHECKS => # проверки
        {
            compare =>
            [
                {cmp => 'le', fields => ['edtDateRight', 'edtDateLeft'], value => 7776000, oper => '-'},
                {cmp => 'ge', fields => ['edtDateRight', 'edtDateLeft'], value => 0,       oper => '-'} 
            ],
            pack =>
            [
                {
                    field => 'strOrder',
                    desc  =>
                    {
                        spliter   => PACK_ORDER_SPLITER,
                        extractor => PACK_ORDER_EXTRACT
                    }
                }
            ]
        }
    },    
    DEPARTS =>
    {
        FIELDS => 
        {
            chkTypeOfDep => # тип подразделения ГО или Филиал
            {
                type     => 'int',
                request  => TRUE,
                array    => TRUE
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            lstOutTo => 
            {
                type    => 'str',
                request => TRUE                            
            },
            rowver =>
            {
                type     => 'int'
            },
            page => 
            {
                type    => 'str',
                request => TRUE                            
            },
            exe => 
            {
                type    => 'str',
                request => TRUE                            
            }                                                                  
        },                    
        CHECKS => # проверки
        {
            pack =>
            [
                {
                    field => 'strOrder',
                    desc  =>
                    {
                        spliter   => PACK_ORDER_SPLITER,
                        extractor => PACK_ORDER_EXTRACT
                    }
                }
            ]
        }
    },
    CLR_CODES =>
    {    
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            lstOutTo => 
            {
                type    => 'str',
                request => TRUE                            
            },
            rowver =>
            {
                type     => 'int'
            },
            page => 
            {
                type    => 'str',
                request => TRUE                            
            },
            exe => 
            {
                type    => 'str',
                request => TRUE                            
            }                        
        },                    
        CHECKS => # проверки
        {
            pack =>
            [
                {
                    field => 'strOrder',
                    desc  =>
                    {
                        spliter   => PACK_ORDER_SPLITER,
                        extractor => PACK_ORDER_EXTRACT
                    }
                }
            ]
        }    
    },                    
    CLR_RATE =>
    {
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            lstOutTo => 
            {
                type    => 'str',
                request => TRUE                            
            },
            rowver =>
            {
                type     => 'int'
            },
            page => 
            {
                type    => 'str',
                request => TRUE                            
            },
            exe => 
            {
                type    => 'str',
                request => TRUE                            
            }               
        },                    
        CHECK => # проверки
        {
            pack =>
            [
                {
                    field => 'strOrder',
                    desc  =>
                    {
                        spliter   => PACK_ORDER_SPLITER,
                        extractor => PACK_ORDER_EXTRACT
                    }
                }
            ]
        }    
    }   
};

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    CALENDAR =>
    { # параметры выгрузки календаря
        title          => 'Справочник выходных - праздничных дней',
        html_template  => 'spr_admin_edit_calendar.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
        },
        SQL       => 
        {
            select  =>
            [
                {field => 'date'},
                {field => 'workdate'},
                {field => 'recalc'},
                {field => 'note'},
                {field => 'type'},
                {field => 'rowver'}
            ],
            from    => 
            {
                src   => 'SQL_GET_CALENDAR_RAW',   # имя источника
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'rowver'}
                ]
            },            
            order   =>
            [
                {field => 'date', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            date   => 
            {
                key       =>  1,
                type      =>  'date',
                desc      =>  'Текущий день',
                order     =>  1,
                button    =>  TRUE, # признак того, что поле кнопка-статус
                style     => {name=>'orig'},
                attribute => 'onclick=\'ShowDialog(this.parentNode);\''
            },
            workdate   => 
            { 
                type    =>  'date',
                desc    =>  'Рабочий день',
                order   =>  2,
                change  =>  TRUE
            },                            
            recalc   => 
            { 
                type    =>  'chr',
                desc    =>  'Пересчет',
                order   =>  3,
                change  =>  TRUE
            },                            
            note => 
            {
                type    =>  'str',
                desc    =>  'Описание',
                order   =>  4,
                change  =>  TRUE
            },
            rowver => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  5
            }
        }
    },
    DEPARTS  =>
    { # параметры выгрузки подразделений Банка
        title           => 'Справочник подразделений Банка',
        html_template   => 'spr_admin_edit_departs.html', # файл шаблона страницы
        DICTIONARIES    => # список дополнительных словарей
        {
            GET_DEPARTS_TYPES =>
            {
                src    => 'SQL_GET_DEPARTS_TYPES',
                params => []  
            }                    
        },
        SQL       => 
        {
            select  =>
            [
                {field => 'dep'},
                {field => 'name'},
                {field => 'type'},
                {field => 'address'},
                {field => 'okato'},
                {field => 'rowver'}
            ],
            from    =>
            {
                src    => 'SQL_GET_DEPARTS',   # имя источника
                params =>
                [
                    {field => 'rowver'},
                    {field => 'chkTypeOfDep', options => {array=>TRUE,spliter=>',',wrap=>'',type=>'int'}}
                ]
            },
            order   =>
            [
                {field => 'type', direction => 'asc'},
                {field => 'name', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            dep   => 
            {
                button    => TRUE, # признак того, что поле кнопка-статус
                type      => 'acc',
                desc      => 'Номер',
                key       => TRUE,
                style     => {name=>'orig'},
                attribute => 'onclick=\'ShowDialog(this.parentNode);\'',
                order     => 1
            },                                                      
            name   => 
            { 
                type    =>  'str',
                desc    =>  'Наименование подразделения',
                order   =>  2,
                uniq    =>  TRUE, 
                change  =>  TRUE
            },                            
            type   => 
            { 
                type    =>  'int',
                desc    =>  'Тип',
                order   =>  3,
                change  =>  TRUE
            },                            
            address => 
            {
                type    =>  'str',
                desc    =>  'Адрес',
                order   =>  4,
                change  =>  TRUE
            },
            okato => 
            {
                type    =>  'str',
                desc    =>  'Код территории по ОКАТО',
                order   =>  5,
                change  =>  TRUE
            },
            rowver => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  6
            }
        }
    },
    CLR_CODES =>
    { # параметры выгрузки клиринговых кодов
        title           => 'Справочник клиринговых кодов',
        html_template   => 'spr_admin_edit_clr_codes.html', # файл шаблона страницы
        DICTIONARIES    => # список дополнительных словарей
        {
            GET_CUR_CODES =>
            {
                src    => 'SQL_GET_CUR_CODES',
                params => [{field => 'rowver'}]  
            }                    
        },
        SQL       => 
        {
            select =>
            [
                {field => 'code'},
                {field => 'als'},
                {field => 'note'},
                {field => 'rowver'}
            ], 
            from =>
            {
                src    => 'SQL_GET_CLR_CODES',   # имя источника
                params => [{field => 'rowver'}]
            },
            order  =>
            [
                {field => 'code', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            code    => 
            { 
                button    => TRUE, # признак того, что поле кнопка-статус
                type      => 'acc',
                desc      => 'Клиринговый код',
                key       => TRUE,
                style     => {name=>'orig'},
                attribute => 'onclick=\'ShowDialog(this.parentNode);\'',
                order     => 1
            },                            
            als    => 
            { 
                type    =>  'acc',
                desc    =>  '№ валюты',
                order   =>  2,
                change  =>  TRUE
            },                            
            note    => 
            { 
                type    =>  'str',
                desc    =>  'Описание',
                order   =>  4,
                change  =>  TRUE
            },                            
            rowver  => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  5
            }
        }
    },
    CLR_RATE =>
    { # параметры выгрузки курсов клиринговых операций
        title    => 'Справочник курсов клиринговых операций',
        html_template  => 'spr_admin_edit_clr_rate.html', # файл шаблона страницы
        DICTIONARIES => # список дополнительных словарей
        {
            GET_CLR_CODES =>
            {
                src    => 'SQL_GET_CLR_CODES',   # имя источника
                params => [{field => 'rowver'}]
            }                    
        },
        SQL       => 
        {
            select  =>
            [
                {field => 'code'},
                {field => 'date'},
                {field => 'base'},
                {field => 'rate'},
                {field => 'note'},
                {field => 'rowver'}
            ],
            from    =>
            {
                src    => 'SQL_GET_CLR_RATE',   # имя источника
                params => [{field => 'rowver'}]
            },
            order   =>
            [
                {field => 'date', direction => 'asc'},
                {field => 'code', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            code    => 
            { 
                button    => TRUE, # признак того, что поле кнопка-статус
                type      => 'acc',
                desc      => 'Клиринговый код',
                key       => TRUE,
                style     => {name=>'orig'},
                attribute => 'onclick=\'ShowDialog(this.parentNode);\'',
                order     => 1
            },                            
            date    => 
            { 
                type    =>  'date',
                desc    =>  'Дата курса',
                order   =>  2,
                key     =>  TRUE
            },                            
            base     => 
            {
                type    =>  'int',
                desc    =>  'База курса',
                order   =>  3,
                change  =>  TRUE
            },                                                      
            rate     => 
            {
                type    =>  'mny',
                desc    =>  'Курс',
                order   =>  4,
                change  =>  TRUE
            },
            note    => 
            { 
                type    =>  'str',
                desc    =>  'Описание',
                order   =>  5
            },                            
            rowver  => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  6
            }
        }
    }
};

use constant SUPPORT_FORMATS =>
{
    html    => sub {new Spravochniks::RpgAdmExportToHtml(@_);},
    excel   => sub {new Spravochniks::RpgAdmExportToExcel(@_);}
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
        my %args = (@_);
        my $to   = $args{PARAM}{CGI}->param('lstOutTo');

        if (defined($to) && defined(SUPPORT_FORMATS->{$to}))
        {
            return SUPPORT_FORMATS->{$to}(@_);
        }

        # задан не известный формат
        $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query unknow format '%s' for export data", $to);         
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
    
    $self->{SRC_DATA}    = new RpgSrcData; # единый источник данных
    $self->{FIELDS_MAIN} = undef;
    $self->{FIELDS_OPT}  = undef;

    $set->{LOG}->out(RpgLog::LOG_I, "user query export in '%s' data '%s'", 
            (defined($set->{CGI}->param('lstOutTo')) ? $set->{CGI}->param('lstOutTo') : '???'),
            (defined($set->{CGI}->param('page')) ? $set->{CGI}->param('page') : '???'));
        
    return FALSE unless(defined($self->{TARGET}));

    my ($all_fields) = EXPORT_DESC->{$self->{TARGET}}{FIELDS};
    
    # берем только обязательные поля
    $self->{FIELDS_MAIN} = [sort {$all_fields->{$a}{order} <=> $all_fields->{$b}{order}} grep {!exists($all_fields->{$_}{skip})} keys(%{$all_fields})]; 
    # берем только опциональные поля
    $self->{FIELDS_OPT}  = [sort {$all_fields->{$a}{order} <=> $all_fields->{$b}{order}} grep {exists($all_fields->{$_}) && exists($all_fields->{$_}{skip}) && !exists($all_fields->{$_}{key})} $self->{PARAM}{CGI}->param('chkShowFields')]; 
    
    return $self;
}

#*******************************************************************************
#
#  Загружает данные корекций, возвращает TRUE при успехе
#
sub load_data
#
#*******************************************************************************
{
    my $self = shift;    
    my $set  = $self->{PARAM};       # общие параметры
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    

    unless (defined($self->{TARGET}) &&  defined(CGI_DESC->{$self->{TARGET}}))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "invalid CGI query");
        goto _WAS_ERROR;
    }
    
    my $cgi_check = new RpgCGICheck(PARAM => $set);        
    my $cgi_desc  = CGI_DESC->{$self->{TARGET}};
    
    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, 'invalid CGI query, becose: "%s"', $cgi_check->errstr);
        goto _WAS_ERROR;
    }
    
    $set->{LOG}->out(RpgLog::LOG_I, "loading data for export");
    
    my $exp_data = EXPORT_DESC->{$self->{TARGET}};
    my $fields   = $exp_data->{FIELDS};    
    my $sql      = $exp_data->{SQL};
    
    # строим SQL запрос:
    my $select   = [@{$sql->{select}}, map{{field => $_}} @{$self->{FIELDS_OPT}}];
    #   фильтрация
    my $where    = defined($sql->{where}) ? $sql->{where} : undef;
    my $group    = defined($sql->{group}) ? [@{$sql->{group}}, map{{field => $_}} @{$self->{FIELDS_OPT}}] : undef;
    #   сортировка
    my $order    = defined($sql->{order}) ? $sql->{order} : undef;
    
    if (defined($set->{CGI}->param('strOrder')))
    {
        # в запросе указанна сортировка, сбрасываем поумолчанию        
        my $spliter   = PACK_ORDER_SPLITER;
        my $extractor = PACK_ORDER_EXTRACT;        
        
        $order        = [];
        
        foreach (split($spliter, $set->{CGI}->param('strOrder')))        
        {
            my ($field, $value) = ($_ =~ /$extractor/);            
            
            next unless (defined($field) && defined($fields->{$field}));
            
            push(@{$order}, {field => $field, direction => $value});
        }
    }
    
    my $maker = new RpgSQLMake();
    my $query = $maker->select
        (
            SELECT  => $select,
            FROM    =>
            {
                src    => $set->{SETT}->get($set->{SESSION}->report(), $sql->{from}{src}),
                params => $sql->{from}{params}
            },
            WHERE   => $where,
            GROUP   => $group,
            ORDER   => $order,
            FIELDS  => $fields,
            CGI     => $set->{CGI},
            REQUEST => $cgi_desc->{FIELDS}
        );    
            
    $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (body table), sql: '%s'", $self->{TARGET}, $query);        
    
    # загружаем табличные данные
    unless ($self->{SRC_DATA}->add(FROM  => $set->{DB}, 
                                   TO    => 'GET_BODY',
                                   SRC   => $query))
    {
        $set->{LOG}->out(RpgLog::LOG_E, "Error, coldn't load data for export, becose: %s", $self->{SRC_DATA}->errstr());
        goto _WAS_ERROR;        
    }

    foreach my $dic (keys(%{$exp_data->{DICTIONARIES}}))
    {
        $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), $exp_data->{DICTIONARIES}{$dic}{src}),
                    params => $exp_data->{DICTIONARIES}{$dic}{params}
                },
                CGI     => $set->{CGI},
                REQUEST => CGI_DESC->{$self->{TARGET}}{FIELDS}
            );    

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (dictionary), sql: '%s'", $dic, $query);

        unless ($self->{SRC_DATA}->add(FROM  => $set->{DB}, 
                                       TO    => $dic,
                                       SRC   => $query,
                                       PARAM => undef))
        {
            $set->{LOG}->out(RpgLog::LOG_E, "Error, coldn't load dictionary, becose: %s", $self->{SRC_DATA}->errstr());
            goto _WAS_ERROR;
        }
    }
    
    $set->{LOG}->out(RpgLog::LOG_I, "data was loading");
    return TRUE;    
    
_WAS_ERROR:    
    $set->{LOG}->out(RpgLog::LOG_I, "error load of data");
    return FALSE;
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

1;
