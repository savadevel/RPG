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

package Spravochniks::RpgExport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use Exporter;
use English;
use strict;
use warnings;
use utils;
use const;
use types;
use src_data;
use cgi_check;
use sql_make;
use page_default;

use Spravochniks::page_app;
use Spravochniks::exp_excel;
use Spravochniks::exp_html;

use constant CGI_DESC => # содержит поля запроса, по ним делаем его валидацию
{
    SHOW_SUM => # остатки на счетах
    {     
        FIELDS => 
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
            lstAcc      => # список б. счетов второго порядка
            {
                type     => 'acc',
                request  => TRUE
            },        
            numPage    =>  # номер страницы
            {
                type     => 'int',
                request  => TRUE,
                optional => TRUE 
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                optional => TRUE,  # если не определенно, то при выгрузке   не будет учитываться
                array    => TRUE,
                request  => TRUE
            },
            page =>
            {
                type     => 'str',
                request  => TRUE
            },
            exe =>
            {
                type     => 'str',
                request  => TRUE
            },
            lstOutTo =>
            {
                type => 'str',
                request  => TRUE
            }            
        },                    
        CHECKS => # проверки
        {
            compare =>
            [
                {cmp => 'le', fields => ['edtDateRight', 'edtDateLeft'], value => 3024000, oper => '-'},
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
            ],
            match =>
            [
                {field => 'lstAcc', exp => '^\d{5}$'}
            ],
            range =>
            [
                {field => 'lstAcc',  min => 10201, max => 99999},
                {field => 'numPage', min => 1,     max => undef}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['cln_nmb', 'cln_res', 'cln_cls', 'cln_desc']}
            ]         
        }    
    },
    SHOW_DAT => # календарь
    {     
        FIELDS => 
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
            lstRowver => # номер выгружаемой версии справочников
            {
                type     => 'int',
                request  => TRUE
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
    SHOW_CUR => # курсы валют
    {
        FIELDS => 
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
            numPage    =>  # номер страницы
            {
                type     => 'int',
                request  => TRUE,
                optional => TRUE 
            },            
            lstCur      => # список RGN курсов валют
            {
                type     => 'str',
                request  => TRUE,
                array    => TRUE
            },
            lstRowver => # номер выгружаемой версии справочников
            {
                type     => 'int',
                request  => TRUE
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
            ],
            range =>
            [
                {field => 'numPage', min => 1,     max => undef}
            ],            
            match =>
            [
                {field => 'lstCur', exp => '^\w{3}$'}
            ]            
        }    
    },
    SHOW_DEP => # подразделения Банка
    {
        FIELDS => 
        {
            chkTypeOfDep => # тип подразделения ГО или Филиал
            {
                type     => 'int',
                array    => TRUE,
                request  => TRUE
            },
            lstRowver => # номер выгружаемой версии справочников
            {
                type     => 'int',
                request  => TRUE
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
    }
};

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    SHOW_SUM => # остатки на счетах
    {
        # параметры выгрузки остатков по счетам
        title         => 'Справочник остатков по балансовым счетам',
        html_template => 'show_table_data.html',
        data_from     => 1, # номер источника, содержащего данные
        PAGING        => # постраничный вывод
        {
            data_from => 2, # номер источника, содержащего количество строк
            rows      => 'NUMBER_ROWS_ON_PAGE',
            page      => 'numPage',   
            method    => 'SQL_GET_TABLE_BY_PAGE' 
        },        
        SQL       => 
        {
            select    =>
            [
                {field => 'acc_acc'},                
                {field => 'acc_nmb'},
                {field => 'sum_slb'},
                {field => 'sum_bdt'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},                
                {field => 'cln_nmb'},
                {field => 'cln_res'},
                {field => 'cln_cls'},
                {field => 'cln_desc'}
            ],                     
            from =>
            {
                src    => 'SQL_GET_ACCSUMM',   # имя источника
                params =>
                [
                    {field => 'lstAcc'}, 
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}
                ]
            },
            order =>
            [
                {field => 'acc_nmb',    direction => 'asc'},
                {field => 'sum_bdt',    direction => 'asc'}
            ]            
        },
        FIELDS    => 
        {
            acc_acc   => 
            {
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  1
            },                                                      
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Лицевой счет',
                order   =>  2
            },                            
            sum_slb   => 
            { 
                type    =>  'mny',
                desc    =>  'Остаток за период',
                order   =>  3
            },                            
            acc_msk => 
            {
                type    =>  'int',
                desc    =>  'Маска Счета',
                order   =>  4
            },
            acc_lck => 
            {
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  5
            },
            cln_nmb  => 
            {
                type    =>  'acc',
                desc    =>  'Код клиента',
                order   =>  6,
                skip    =>  TRUE
            },                                 
            cln_res  => 
            {
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  7,
                skip    =>  TRUE
            }, 
            cln_cls  => 
            {
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  8,
                skip    =>  TRUE
            },                            
            sum_bdt   => 
            { 
                type    =>  'date',
                skip    =>  TRUE,
                desc    =>  'Дата проводки',
                order   =>  9
            },
            acc_desc => 
            {
                type    =>  'str',
                desc    =>  'Описание Счета',
                order   =>  10
            },                
            cln_desc => 
            {
                type    =>  'str',
                desc    =>  'Описание Клиента',
                order   =>  11,
                skip    =>  TRUE
            }            
        }
    },
    SHOW_DAT => # календарь
    {
        # параметры выгрузки календаря
        title           => 'Справочник выходных - праздничных дней',
        html_template   => 'show_table_data.html', 
        SQL             => 
        {
            select =>
            [
                {field => 'date'},
                {field => 'workdate'},
                {field => 'recalc'},
                {field => 'note'},
                {field => 'type'},
                {field => 'rowver'}
            ],  
            from   => 
            {
                src    => 'SQL_GET_CALENDAR',   # имя источника
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'lstRowver'}
                ]
            },            
            order     =>
            [
                {field => 'date', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            date   => 
            {
                key     =>  1,
                type    =>  'date',
                desc    =>  'Текущий день',
                order   =>  1 
            },                                                      
            workdate   => 
            { 
                type    =>  'date',
                desc    =>  'Рабочий день',
                order   =>  2
            },                            
            recalc   => 
            { 
                type    =>  'chr',
                desc    =>  'Пересчет',
                order   =>  3                     
            },                            
            note => 
            {
                type    =>  'str',
                desc    =>  'Описание',
                order   =>  4
            },
            type => 
            {
                type    =>  'int',
                desc    =>  'Тип',
                order   =>  4,
                hide    =>  1
            },
            rowver => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  5
            }                
        }
    },
    SHOW_CUR => # курсы валют
    { 
        # параметры выгрузки курсов валют
        title   => 'Справочник курсов валют',
        html_template => 'show_table_data.html',
        data_from     => 1, # номер источника, содержащего данные
        PAGING        => # постраничный вывод
        {
            data_from => 2, # номер источника, содержащего количество строк
            rows      => 'NUMBER_ROWS_ON_PAGE',
            page      => 'numPage',   
            method    => 'SQL_GET_TABLE_BY_PAGE' 
        },                
        SQL       =>
        {
            select   =>
            [
                {field => 'cur_id'},
                {field => 'cur_rgn'},
                {field => 'cur_snm'},
                {field => 'cur_date'},
                {field => 'cur_rate'},
                {field => 'cur_desc'},
                {field => 'rowver'}
            ], 
            from     =>
            {
                src    => 'SQL_GET_RATE_OF_EXCHANGE', # имя источника хранится во внешнем источнике
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'lstRowver'},
                    {field => 'lstCur', options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstRowver'}
                ]
            },
            order    =>
            [
                {field => 'cur_rgn',  direction => 'asc'},
                {field => 'cur_date', direction => 'asc'}
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            cur_id    =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Код',       # описание поля                                                 
                order   =>  1
            },
            cur_rgn      => 
            {
                key     =>  1,           
                type    =>  'acc',       
                desc    =>  '№ гос. регистрации',
                order   =>  2
            },                        
            cur_snm      => 
            {
                type    =>  'str',       
                desc    =>  'Валюта',
                order   =>  3
            },        
            cur_date     => 
            { 
                type    =>  'date',
                desc    =>  'На Дату',
                order   =>  4
            },
            cur_rate => 
            {
                type    =>  'flt',
                desc    =>  'Курс',
                order   =>  5
            },
            cur_desc => 
            {
                type    =>  'str',
                desc    =>  'Описание Валюты',
                order   =>  6
            },
            rowver => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  7
            }  
        }                    
    },
    SHOW_DEP => # подразделения Банка
    {
        # параметры выгрузки списока подразделений Банка
        title   => 'Справочник подразделений Банка',
        html_template => 'show_table_data.html',
        SQL       => 
        {
            select    =>
            [
                {field => 'dep'},
                {field => 'name'},
                {field => 'type'},
                {field => 'address'},
                {field => 'okato'},
                {field => 'rowver'}
            ], 
            from =>
            {
                src    => 'SQL_GET_DEPARTS',   # имя источника
                params =>
                [
                    {field => 'lstRowver'},
                    {field => 'chkTypeOfDep', options => {array => TRUE, spliter => ',', wrap => '', type => 'int'}}
                ]
            },
            order =>            
            [
                {field => 'type', direction => 'asc'},
                {field => 'name', direction => 'asc'}
            ]
        },
        FIELDS    => 
        {
            name   => 
            { 
                type    =>  'str',
                desc    =>  'Наименование подразделения',
                order   =>  1
            },                            
            dep   => 
            {
                type    =>  'acc',
                desc    =>  'Номер',
                order   =>  2
            },                                                      
            type   => 
            { 
                type    =>  'int',
                desc    =>  'Тип',
                order   =>  3,
                # задает действие взависимости от значения
                trigger     =>  
                {
                    0 =>
                    {
                        value   => 'ГО',
                        type    => 'str'
                    },
                    1 =>
                    {
                        value   => 'филиал',
                        type    => 'str'
                    }
                }
            },                            
            address => 
            {
                type    =>  'str',
                desc    =>  'Адрес',
                order   =>  4
            },
            okato => 
            {
                type    =>  'str',
                desc    =>  'Код территории по ОКАТО',
                order   =>  5
            },
            rowver => 
            {
                type    =>  'int',
                desc    =>  'Версия',
                order   =>  6
            }
        }
    }
};

use constant SUPPORT_FORMATS => # модули экспорта
{
    html  => sub {new Spravochniks::RpgExportToHtml(@_);},
    excel => sub {new Spravochniks::RpgExportToExcel(@_);}
};

BEGIN 
{    
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw (Spravochniks::RpgPageApp);
}

#*******************************************************************************
#
sub DESTROY
#
#*******************************************************************************
{
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
        my $to   = lc($args{PARAM}{CGI}->param('lstOutTo'));
        my $page = $args{PARAM}{CGI}->param('page');
        
        if (defined($to) and defined(SUPPORT_FORMATS->{$to}))
        {
            return SUPPORT_FORMATS->{$to}(@_);
        }       
        elsif (defined($to))
        {
            $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query unknow format '%s' for export", $to);
        }
        
        # не было найденно подходящего дочернего класса
        # придется делать самим :0(     
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
    $self->{TARGET}      = undef;

    $set->{LOG}->out(RpgLog::LOG_I, "user query export in '%s' data '%s'", 
            (defined($set->{CGI}->param('lstOutTo')) ? $set->{CGI}->param('lstOutTo') : '???'),
            (defined($set->{CGI}->param('page')) ? $set->{CGI}->param('page') : '???'));
            
    my $page = $set->{CGI}->param('page');
    
    if (    defined($page) 
        and defined(CGI_DESC->{$page}))
    {
        $self->{TARGET} = $page;
    }
    else
    {
        return FALSE;
    }

    my ($all_fields)  = EXPORT_DESC->{$self->{TARGET}}{FIELDS};

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
    my ($self, $paging) = (shift, shift);    
    my $set  = $self->{PARAM};       # общие параметры
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    
    unless (defined($self->{TARGET}))
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
        
    if ($paging == TRUE && defined($exp_data->{PAGING})) # проверка необходимости постраничного вывода
    {
        my $page = $set->{CGI}->param($exp_data->{PAGING}{page}) || 1;
        my $rows = $set->{SETT}->get($set->{SESSION}->report(), $exp_data->{PAGING}{rows});
        
        $query = $maker->paging
            (
                SELECT    => $query,
                METHOD    => $set->{SETT}->get($set->{SESSION}->report(), $exp_data->{PAGING}{method}),
                FIRST_ROW => ($page - 1) * $rows + 1,
                ROWS      => $rows
            );
    }

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
                    params => $exp_data->{GET_DICTIONARY}{$dic}{params}
                },
                CGI     => $set->{CGI},
                REQUEST => CGI_DESC->{$self->{TARGET}}{PARAM}
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

sub do
{
    my ($self) = shift;
    
    $self->SUPER::do();    
    return 1;
}

1;
