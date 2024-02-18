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

package admin::RpgAdminLogExport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use Data::Sorting qw(:arrays);
use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use const;
use cgi_check;
use page_default;
use admin::adm_log;
use admin::adm_log_exp_excel;
use admin::adm_log_exp_html;

use constant CGI_DESC => # содержит поля запроса, по ним делаем его валидацию
{
    SRV_APPS => # параметры выгрузки журнала сервера приложений
    { 
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
            lstUsers => # Пользователи
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstReports => # Ресурсы
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },            
            chkType      => # тип сообщения
            {
                type     => 'chr',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            chkSession  => # инф. о сессии:
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            chkUser    =>
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstOutTo    => # Экспортировать в
            {
                type     => 'str',                
                request  => TRUE                            
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
                {cmp => 'le', fields => ['edtDateRight', 'edtDateLeft'], value => 432000, oper => '-'},
                {cmp => 'ge', fields => ['edtDateRight', 'edtDateLeft'], value => 0,      oper => '-'} 
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
        }
    },
    SRV_DATA => # параметры выгрузки журнала сервера данных
    { 
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
            lstUsers => # Пользователи
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstReports => # Ресурсы
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },            
            chkType      => # тип сообщения
            {
                type     => 'chr',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            chkSession  => # инф. о сессии:
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE
            },
            chkUser    =>
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstOutTo    => # Экспортировать в
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE                            
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
                {cmp => 'le', fields => ['edtDateRight', 'edtDateLeft'], value => 432000, oper => '-'},
                {cmp => 'ge', fields => ['edtDateRight', 'edtDateLeft'], value => 0,      oper => '-'} 
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
        }
    }    
};

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных
{   
    SRV_APPS => # параметры выгрузки журнала сервера приложений
    {
        # параметры выгрузки остатков по счетам
        title         => 'Журнал сервера приложений',
        html_template => 'show_table_data.html',
        data_from     => 0, # номер источника, содержащего данные
        device        => 'LOG',  
        PAGING        => # постраничный вывод
        {
            data_from => 1, # номер источника, содержащего количество строк
            rows      => 'NUMBER_ROWS_ON_PAGE',
            page      => 'numPage',   
            method    => 'SQL_GET_TABLE_BY_PAGE' 
        },        
        FILTERS       => 
        [        
            {field => 'log',    value => 'chkType'},
            {field => 'uid',    value => 'lstUsers'},
            {field => 'report', value => 'lstReports'}
        ],
        FIELDS    => 
        {            
            sid  => 
            {
                order => 1,
                type  => 'int',
                desc  => 'SID',
                skip  =>  TRUE
            },
            date => 
            {
                order  => 2,
                type   => 'time',
                desc   => 'Дата',
                schema => 'LOG'
            },
            login => 
            {
                order => 3,
                type  => 'str',
                desc  => 'Логин'
            },
            log => 
            {
                order => 4,
                type  => 'chr',
                desc  => 'Тип сообщения'
            },
            host => 
            {
                order => 5,
                type  => 'str',
                desc  => 'IP машины',
                skip  =>  TRUE
            },
            report => 
            {
                order => 5,
                type  => 'str',
                desc  => 'Ресурс'
            },
            permission => 
            {
                order => 6,
                type  => 'chr',
                desc  => 'Уровень доступа',
                skip  =>  TRUE
            },
            uid    =>
            {
                type    =>  'int',
                desc    =>  'UID',
                skip    =>  TRUE,
                order   =>  7
            },
            val    =>
            {
                type    =>  'txt',
                desc    =>  'Сообщение',
                skip    =>  TRUE,
                order   =>  8,
                style   =>
                {
                    width => 1200
                }
            }
        }
    },
    SRV_DATA => # параметры выгрузки журнала сервера данных
    {
        # параметры выгрузки остатков по счетам
        title         => 'Журнал сервера данных',
        html_template => 'show_table_data.html',
        data_from     => 1, # номер источника, содержащего данные
        device        => 'DB',  
        PAGING        => # постраничный вывод
        {
            data_from => 2, # номер источника, содержащего количество строк
            rows      => 'NUMBER_ROWS_ON_PAGE',
            page      => 'numPage',   
            method    => 'SQL_GET_TABLE_BY_PAGE' 
        },        
        SQL       => 
        {
            select =>
            [
                {field => 'log'},
                {field => 'date'},
                {field => 'val'},
                {field => 'uid'},
                {field => 'name'},
                {field => 'fio'},
                {field => 'phone'},
                {field => 'fax'},
                {field => 'department'},
                {field => 'report'},
                {field => 'login'},
                {field => 'host'},
                {field => 'permission'},
                {field => 'sdate'},
                {field => 'edate'}
            ],  
            from   => 
            {
                src    => 'SQL_GET_LOG',   # имя источника
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'chkType'},
                    {field => 'chkType', options => {array => TRUE, spliter => ',', wrap => ''}},
                    {field => 'lstUsers'},
                    {field => 'lstUsers', options => {array => TRUE, spliter => ',', wrap => ''}},
                    {field => 'lstReports'},
                    {field => 'lstReports', options => {array => TRUE, spliter => ',', wrap => ''}},
                ]
            },            
            order     =>
            [
                {field => 'date', direction => 'desc'}
            ]
        },
        FIELDS    => 
        {
            sid    =>
            {
                type    =>  'int',
                desc    =>  'SID',
                skip    =>  TRUE,
                order   =>  1
            },
            date    =>
            {
                type    =>  'time',
                desc    =>  'Дата',                
                order   =>  2
            },
            login    =>
            {
                type    =>  'str',
                desc    =>  'Логин',
                order   =>  3            
            },
            name    =>
            {
                type    =>  'str',
                desc    =>  'Пользователь',
                skip    =>  TRUE,
                order   =>  4
            },
            log     =>
            {
                type    =>  'chr',
                desc    =>  'Тип сообщения',
                order   =>  5
            },
            report    =>
            {
                type    =>  'txt',
                desc    =>  'Ресурс',
                order   =>  6
            },
            sdate    =>
            {
                type    =>  'time',
                desc    =>  'Время начала сессии',
                skip    =>  TRUE,
                order   =>  7
            },
            edate    =>
            {
                type    =>  'time',
                desc    =>  'Время окончания сессии',
                skip    =>  TRUE,
                order   =>  8
            },
            host    =>
            {
                type    =>  'str',
                desc    =>  'IP машины',
                skip    =>  TRUE,
                order   =>  9            
            },
            permission    =>
            {
                type    =>  'chr',
                desc    =>  'Уровень доступа',
                skip    =>  TRUE,
                order   =>  10
            },
            fio    =>
            {
                type    =>  'str',
                desc    =>  'ФИО',
                skip    =>  TRUE,
                order   =>  11            
            },            
            department    =>
            {
                type    =>  'txt',
                desc    =>  'Отдел',
                skip    =>  TRUE,
                order   =>  12
            },
            phone    =>
            {
                type    =>  'str',
                desc    =>  'Телефон',
                skip    =>  TRUE,
                order   =>  13
            },
            fax    =>
            {
                type    =>  'str',
                desc    =>  'Факс',
                skip    =>  TRUE,
                order   =>  14
            },
            uid    =>
            {
                type    =>  'int',
                desc    =>  'UID',
                skip    =>  TRUE,
                order   =>  15            
            },
            val    =>
            {
                type    =>  'txt',
                desc    =>  'Сообщение',
                skip    =>  TRUE,
                order   =>  16,
                style   =>
                {
                    width => 1200
                }
            }
        }
    }    
};

use constant SUPPORT_FORMATS => # модули экспорта
{
    html  => sub {new admin::RpgAdminLogExportToHtml(@_);},
    excel => sub {new admin::RpgAdminLogExportToExcel(@_);}
};

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(admin::RpgAdminLog);
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
    $self->{FIELDS_MAIN} = [];
    $self->{FIELDS_OPT}  = [];
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

    my $fields = EXPORT_DESC->{$self->{TARGET}}{FIELDS};

    # берем только обязательные поля
    push (@{$self->{FIELDS_MAIN}}, sort {$fields->{$a}{order} <=> $fields->{$b}{order}} grep {!exists($fields->{$_}{skip})} keys(%{$fields})); 
    # берем только опциональные поля, инф. о пользователе
    push (@{$self->{FIELDS_OPT}},  sort {$fields->{$a}{order} <=> $fields->{$b}{order}} grep {exists($fields->{$_}) && exists($fields->{$_}{skip}) && !exists($fields->{$_}{key})} $self->{PARAM}{CGI}->param('chkUser')); 
    # берем только опциональные поля, инф. о сессии
    push (@{$self->{FIELDS_OPT}},  sort {$fields->{$a}{order} <=> $fields->{$b}{order}} grep {exists($fields->{$_}) && exists($fields->{$_}{skip}) && !exists($fields->{$_}{key})} $self->{PARAM}{CGI}->param('chkSession')); 
    
    return $self;
}

#*******************************************************************************
#
#  Загружает данные, возвращает TRUE при успехе
#
sub load_data
#
#*******************************************************************************
{    
    my ($self, $paging) = (shift, shift);    
    my $set  = $self->{PARAM};       # общие параметры
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $ret  = FALSE;
    
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
    
    if ('DB' eq EXPORT_DESC->{$self->{TARGET}}{device})
    {
        $ret = $self->_load_from_db($paging);
    }
    elsif ('LOG' eq EXPORT_DESC->{$self->{TARGET}}{device})
    {
        $ret = $self->_load_from_log($paging);
    }
    else
    {
        die sprintf("Error, unknow type of device: %s", EXPORT_DESC->{$self->{TARGET}}{device});
    }
    
    return $ret;    
    
_WAS_ERROR:    
    $set->{LOG}->out(RpgLog::LOG_I, "error load of data");
    return FALSE;
}

sub _allocate_row
{
    my ($self, $row) = (shift, shift);
    
    
}

#*******************************************************************************
#
sub _load_from_log
#
#*******************************************************************************
{
    my ($self, $paging) = (shift, shift || FALSE);    
    my $set         = $self->{PARAM};       # общие параметры
    my $vars        = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $cgi_desc    = CGI_DESC->{$self->{TARGET}};
    my $exp_desc    = EXPORT_DESC->{$self->{TARGET}};
    my $fields      = $exp_desc->{FIELDS};
    my $ldate       = new RpgTypeDate(rval   => $set->{CGI}->param('edtDateLeft'),
                                      schema => $cgi_desc->{edtDateLeft}{schema}  || 'MAIN');
    my $rdate       = new RpgTypeDate(rval   => $set->{CGI}->param('edtDateRight'),
                                      schema => $cgi_desc->{edtDateRight}{schema} || 'MAIN');
    my $count       = 0;
    my %filters;
    my @storage;       # все дни из диапазона
    my $parser_log  =  # процедура для callback, в нее передается хеш текущей строки из которой будут взяты поля
        sub
        {
            my ($num, $row) = (shift, shift);

            foreach my $field (keys(%filters))
            {
                next if (exists($filters{$field}->{$row->{$field}}));
                return;
            }            

            $count ++;
            
            push @storage, $row;            
        };
        
    # формируем фильтры
    foreach my $filter (@{$exp_desc->{FILTERS}})
    {
        my @values = ($set->{CGI}->param($filter->{value}));
        next unless(@values);        
        @{$filters{$filter->{field}}}{@values} = ();
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "start load log for range [%s - %s]", $ldate, $rdate);
    
    # цикл по дням для выгрузки лога
    foreach (my $i = $ldate->clone; $i <= $rdate; $i->add(days => 1))
    {        
        $set->{LOG}->load($parser_log, $i->format('ISO'));
    }

    if (defined($set->{CGI}->param('strOrder')))
    {
        # в запросе указанна сортировка, сбрасываем поумолчанию        
        my $spliter   = PACK_ORDER_SPLITER;
        my $extractor = PACK_ORDER_EXTRACT;        
        my @order;
        
        foreach (split($spliter, $set->{CGI}->param('strOrder')))        
        {
            my ($field, $value) = ($_ =~ /$extractor/);            
            
            next unless (defined($field) && defined($fields->{$field}));
            
            push(@order, {sortkey => $field, order => ($value eq 'asc' ? 'ascending' : 'descending')});
        }
        
        @storage = sorted_array(@storage, @order);        
    }
    else
    {    
        # в логе самая последняя запись должна показываться самой первой
        @storage = reverse(@storage);
    }
    
    if ($paging == TRUE && defined($exp_desc->{PAGING})) # проверка необходимости постраничного вывода
    {
        my $rows = $set->{SETT}->get($set->{SESSION}->report(), $exp_desc->{PAGING}{rows});
        my $frow = (($set->{CGI}->param($exp_desc->{PAGING}{page}) || 1) - 1) * $rows;
    
        # организуем постраничный вывод записей
        @storage = splice(@storage, $frow, $rows);
    }

    # создаем хранилище
    $self->{SRC_DATA}->add(TO => 'GET_BODY');        
    $self->{SRC_DATA}->rows_insert(\@storage, 'GET_BODY', $exp_desc->{data_from});
    $self->{SRC_DATA}->rows_insert([{rows => $count}], 'GET_BODY', $exp_desc->{PAGING}{data_from});
    
    $set->{LOG}->out(RpgLog::LOG_I, "was loading from log %d rows", $count);
    
    return TRUE;
    
_WAS_ERROR:
    return FALSE;
}

#*******************************************************************************
#
sub _load_from_db
#
#*******************************************************************************
{
    my ($self, $paging) = (shift, shift || FALSE);    
    my $set      = $self->{PARAM};       # общие параметры
    my $vars     = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $cgi_desc = CGI_DESC->{$self->{TARGET}};
    my $exp_desc = EXPORT_DESC->{$self->{TARGET}};
    my $fields   = $exp_desc->{FIELDS};    
    my $sql      = $exp_desc->{SQL};
    
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
        
    if ($paging == TRUE && defined($exp_desc->{PAGING})) # проверка необходимости постраничного вывода
    {
        my $page = $set->{CGI}->param($exp_desc->{PAGING}{page}) || 1;
        my $rows = $set->{SETT}->get($set->{SESSION}->report(), $exp_desc->{PAGING}{rows});
        
        $query = $maker->paging
            (
                SELECT    => $query,
                METHOD    => $set->{SETT}->get($set->{SESSION}->report(), $exp_desc->{PAGING}{method}),
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

    foreach my $dic (keys(%{$exp_desc->{DICTIONARIES}}))
    {
        $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), $exp_desc->{DICTIONARIES}{$dic}{src}),
                    params => $exp_desc->{GET_DICTIONARY}{$dic}{params}
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
    return FALSE;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my ($self) = shift;
    
    $self->SUPER::do();    
    return 1;
}

1;
