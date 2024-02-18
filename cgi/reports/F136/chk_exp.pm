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

package F136::RpgChkExport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use Digest::CRC;
use Fcntl qw (LOCK_SH LOCK_UN O_RDONLY);
use IO qw(Handle File);
use utils;
use const;
use types;
use src_data;
use cgi_check;
use sql_make;

use F136::page_chk;
use F136::chk_exp_html;
use F136::chk_exp_excel;
use F136::adm_imp_baln; 

# список параметров которые могут быть в CGI запросе
# содержит поля запроса, по ним делаем его валидацию
use constant CGI_DESC => 
{
    1 =>
    { # параметры выгрузки отчета по контролю
        FIELDS =>
        {
            p_sFilials  => 
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE  
            },
            p_sCodes    =>
            {
                type     => 'acc',
                optional => TRUE,
                array    => TRUE  
            },            
            p_sOutTo    =>
            {
                type     => 'str'
            },
            p_iLevel    =>
            {
                type     => 'int'
            },            
            page => 
            {
                type    => 'int'                           
            },
            exe => 
            {
                type    => 'str'                           
            },
            rowver =>
            {
                type     => 'int'
            }            
        },                    
        CHECKS => # проверки
        {
            match =>
            [
                {field => 'p_sFilials', exp => '^\d{4}$'},
                {field => 'p_sCodes', exp => '^\d{6}$'},
            ],
            exactly =>
            [
                {field => 'page',values => [1]},
                {field => 'p_iLevel',   values => [1, 2, 3]},
                {field => 'p_sOutTo',   values => ['html', 'excel']},
            ]
        }
    },
    2 =>
    { # параметры выгрузки отчета по контролю
        FIELDS =>
        {
            p_sFilials  => 
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE  
            },
            p_iLevel    =>
            {
                type     => 'int'
            },
            p_sOutTo    =>
            {
                type     => 'str'
            },
            page => 
            {
                type    => 'int'                           
            },
            exe => 
            {
                type    => 'str'                           
            },
            rowver =>
            {
                type     => 'int'
            }                
        },                    
        CHECKS => # проверки
        {
            match =>
            [
                {field => 'p_sFilials', exp => '^\d{4}$'}
            ],
            exactly =>
            [
                {field => 'page',values => [2]},
                {field => 'p_iLevel',   values => [1, 2, 3]},
                {field => 'p_sOutTo',   values => ['html', 'excel']},
            ]
        }
    },
    3 =>
    { # параметры выгрузки отчета по контролю
        FIELDS =>
        {
            p_sFilials  => 
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE  
            },
            p_sCodes    =>
            {
                type     => 'acc',
                optional => TRUE,
                array    => TRUE  
            },            
            p_iLevel    =>
            {
                type     => 'int'
            },
            p_sOutTo    =>
            {
                type     => 'str'
            },
            page => 
            {
                type    => 'int'                           
            },
            exe => 
            {
                type    => 'str'                           
            },
            rowver =>
            {
                type     => 'int'
            }                
        },                    
        CHECKS => # проверки
        {
            match =>
            [
                {field => 'p_sFilials', exp => '^\d{4}$'},
                {field => 'p_sCodes', exp => '^\d{6}$'},
            ],
            exactly =>
            [
                {field => 'page',values => [3]},
                {field => 'p_iLevel',   values => [1, 2, 3]},
                {field => 'p_sOutTo',   values => ['html', 'excel']},
            ]
        }
    }
};

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    1 =>
    { # параметры выгрузки отчетов по контролю
        title    => 'Отчет по контролю',
        html_template  => 'f136_chk_show_tables_data.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
            GET_THE_ROWVER    =>
            {
                src     => 'SQL_GET_THE_ROWVER',
                params  => [{field => 'rowver'}]
            },
            GET_ROWVER      =>
            {
                src     => 'SQL_GET_ROWVER',
                params  => []
            },
            GET_LIST_OF_SOURCES =>
            {
                src     => undef,
                params  => []
            }            
        },
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            procedure =>
            {
                src   => 'SQL_GET_REPORT_BY_CHECKING',
                params  => 
                [
                    {field => 'page'},      # @iChecking
                    {field => 'p_sFilials',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}, # @sDeps
                    {field => 'p_sCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}, # @sCodes
                    {field => '_null_'},    # @sAccs
                    {field => 'rowver'},    # @iRowVer
                    {field => 'p_iLevel'}     # @iLevel
                ]  
            }
        },
        FIELDS    => # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического                 
        {
            cname   =>
            {
                type    =>  'str',
                length  =>  '512',
                desc    =>  'Имя проверки',
                order   =>  1
            },
            status  =>
            {
                desc    =>  'Статус',
                order   =>  2,
                type    =>  'int',
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'Ok',
                        type    => 'str',
                        style   => {name=>'status_ok'}
                    },
                    1 =>
                    {
                        value   => 'Ошибка',
                        type    => 'str',
                        style   => {name=>'status_err'}
                    }
                }                             
            },
            note    =>
            {
                type    =>  'str',
                length  =>  '512',
                desc    =>  'Описание',
                order   =>  3
            },
            rowver  =>
            {
                order   =>  4,
                type    => 'int',
                desc    => 'Версия'
            }
        }                    
    },
    2 =>
    { # параметры выгрузки отчетов по контролю
        title    => 'Отчет по контролю',
        html_template  => 'f136_chk_show_tables_data.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
            GET_THE_ROWVER    =>
            {
                src     => 'SQL_GET_THE_ROWVER',
                params  => [{field => 'rowver'}]
            },
            GET_ROWVER      =>
            {
                src     => 'SQL_GET_ROWVER',
                params  => []
            },
            GET_LIST_OF_SOURCES =>
            {
                src     => undef,
                params  => []
            }
        },
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            procedure =>
            {
                src   => 'SQL_GET_REPORT_BY_CHECKING',
                params  => 
                [
                    {field => 'page'},
                    {field => 'p_sFilials',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => '_null_'},
                    {field => '_null_'},
                    {field => 'rowver'},
                    {field => 'p_iLevel'}
                ]  
            }
        },
        FIELDS    => # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического                 
        {   
            dep     =>
            {
                type    =>  "chr",
                length  =>  "4",
                desc    =>  "№ филиала",
                order   =>  1
            },
            name    =>
            {
                type    =>  "str",
                length  =>  "64",
                desc    =>  "Филиал",
                order   =>  2
            },
            fname    =>
            {
                type    =>  "str",
                length  =>  "128",
                desc    =>  "Файл",
                order   =>  3
            },

            status  =>
            {
                desc    =>  'Статус',
                order   =>  6,
                type    =>  'int',
                trigger =>
                {
                    0 =>
                    {
                        value   => 'Ok',
                        type    => 'chr',
                        style   => {name=>'status_ok'}
                    },
                    1 =>
                    {
                        value   => 'Данные не загружены',
                        type    => 'chr',
                        style   => {name=>'status_err'}
                    }
                },
                style   =>
                {
                    width   => 150
                }                             
            },             
            ldate    =>
            {
                type    =>  'time',
                desc    =>  'Дата и время загрузки',
                order   =>  4
            },
            stat   =>
            {
                type    =>  'chr',
                desc    =>  'Загружено кодов',
                order   =>  5
            },           
            is_updating   =>
            {
                type    => 'chr',
                order   => 6,
                desc    => 'Файл обновлен'                                 
            },           
            is_existing   =>
            {
                type    => 'chr',
                order   => 7,
                desc    => 'Файл доступен'                            
            },           
            is_loading   =>
            {
                type    => 'chr',
                order   => 7,
                desc    => 'Файл доступен',
                hide    => 1                                           
            },
            is_error_load   =>
            {
                type    => 'chr',
                order   => 7,
                desc    => 'Ошибки загрузки'                             
            },
            rowver  =>
            {
                order   =>  13,
                type    => 'int',
                desc    => 'Версия'
            }                  
        }                    
    },
    3 =>
    { # параметры выгрузки отчетов по контролю
        title    => 'Отчет по контролю',
        html_template  => 'f136_chk_show_tables_data.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
            GET_THE_ROWVER    =>
            {
                src     => 'SQL_GET_THE_ROWVER',
                params  => [{field => 'rowver'}]
            },
            GET_ROWVER      =>
            {
                src     => 'SQL_GET_ROWVER',
                params  => []
            }            
        },
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            procedure =>
            {
                src   => 'SQL_GET_REPORT_BY_CHECKING',
                params  => 
                [
                    {field => 'page'},
                    {field => 'p_sFilials',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'p_sCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => '_null_'},
                    {field => 'rowver'},
                    {field => 'p_iLevel'}
                ]  
            }
        },
        FIELDS    => # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического                 
        {
            dep     =>
            {
                type    =>  "chr",
                length  =>  "4",
                desc    =>  "№ филиала",
                order   =>  1
            },
            name    =>
            {
                type    =>  "str",
                length  =>  "64",
                desc    =>  "Филиал",
                order   =>  2
            },
            date    =>
            {
                type    =>  "date",
                desc    =>  "Дата",
                order   =>  3
            },
            code    =>
            {
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4,
                style   =>
                {
                    width   => 100
                }
            },
            acc    =>
            {
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  5,
                style   =>
                {
                    width   => 100
                }   
            },
            status  =>
            {
                desc    =>  'Статус',
                order   =>  6,
                type    =>  'int',
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'Ok',
                        type    => 'str',
                        style   => {name=>'status_ok'}
                    },
                    1 =>
                    {
                        value   => 'Ошибка',
                        type    => 'str',
                        style   => {name=>'status_err'}
                    }
                }                             
            },            
            bal_r   =>
            {
                type    => 'mny',
                order   => 7,
                desc    =>  'Руб. остаток по балансу',
                style   =>
                {
                    width   => 130
                }
                
            },
            chk_bal_r   =>
            {
                type    => 'mny',
                order   => 8,
                desc    =>  'Руб. остаток по коду',
                style   =>
                {
                    width   => 130
                }
            },
            delta_r   =>
            {
                type    => 'mny',
                order   => 9,
                desc    =>  'Расхождение по руб.',
                style   =>
                {
                    width   => 130
                }
            },
            bal_v   =>
            {
                type    => 'mny',
                order   => 10,
                desc    =>  'Вал. остаток по балансу',
                style   =>
                {
                    width   => 130
                }
                
            },
            chk_bal_v   =>
            {
                type    => 'mny',
                order   => 11,
                desc    =>  'Вал. остаток по коду',
                style   =>
                {
                    width   => 130
                }
            },
            delta_v   =>
            {
                type    => 'mny',
                order   => 12,
                desc    =>  'Расхождение по вал.',
                style   =>
                {
                    width   => 130
                }
            },
            rowver  =>
            {
                order   =>  13,
                type    => 'int',
                desc    => 'Версия'
            }          
        }                    
    }
};

use constant TO_TABLE_DESC =>   # описание таблиц для сохранения остатков по кодам и статистики
{
    TABLES  =>
    {
        CODES   =>
        {name => 'TBL_TMP_CODES_OF_FILIALS_FOR_CHECK'},
        STAT    =>
        {name => 'TBL_TMP_STAT_BY_SRC_OF_CODES_FOR_CHECK'}
    },    
    FIELDS =>
    {
        CODES =>
        {
            date =>
            {
                key     => 1,
                type    => 'date'
            },
            dep =>
            {
                key    => 1,           
                type   => 'chr',
                length => 4
            },
            acc =>
            {
                key    => 1,           
                type   => 'acc',
                length => 5
    
            },
            code =>
            {
                key    => 1,           
                type   => 'acc',
                length => 6
    
            },
            bal_r =>
            {
                type  => 'mny'
            },
            bal_v =>
            {
                type  => 'mny'
            }
        },
        STAT =>
        {
            crc =>
            {
                type    => 'long',
                src     => 'crc'
            },
            fname =>
            {
                type    => 'str',
                length  => 512,
                src     => 'fname'
            },
            fpath =>
            {
                type    => 'str',
                length  => 512,
                src     => 'fpath'
            },
            dep =>
            {
                type    => 'chr',
                length  => 4,
                src     => 'department'
            },
            ldate   =>
            {
                type    => 'time',
                src     => 'load'    
            },
            adate   =>
            {
                type    => 'time',
                src     => 'file_date_access'    
            },
            mdate   =>
            {
                type    => 'time',
                src     => 'file_date_modify'    
            },
            cdate   =>
            {
                type    => 'time',
                src     => 'file_date_create'    
            },
            status   =>
            {
                type    => 'int',
                src     => 'last_error'    
            },
            note   =>
            {
                type    => 'str',
                length  => 1024,
                src     => 'status'
            },
            fsize   =>
            {
                type    => 'long',
                src     =>  'file_size'
            },
            rmonth  =>
            {
                type    => 'int',
                src     => 'month'
            }           
        }
    }
};

use constant SUPPORT_FORMATS =>
{
    html    => sub {new F136::RpgChkExportToHtml(@_);},
    excel   => sub {new F136::RpgChkExportToExcel(@_);}
};

BEGIN 
{    
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw (F136::RpgPageChk);
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
#*******************************************************************************
{
    my ($class) = shift;
    
    unless (ref($class))
    {
        my %args = (@_);
        my $to   = $args{PARAM}{CGI}->param('p_sOutTo');

        if (defined($to) && defined(SUPPORT_FORMATS->{$to}))
        {
            return SUPPORT_FORMATS->{$to}(@_);
        }
        elsif (defined($to))
        {
            $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query unknow format '%s' for export", $to);
        }        

        # задан не известный формат
        $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query unknow format '%s' for export data", $to);         
    }
    
    # был вызов либо дочерним классом, т.е. класс такой существует
    # или дочернего нет
    my ($self)  = (ref($class) ? $class : bless({}, $class));
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }

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
            (defined($set->{CGI}->param('p_sOutTo')) ? $set->{CGI}->param('p_sOutTo') : '???'),
            (defined($set->{CGI}->param('page')) ? $set->{CGI}->param('page') : '???'));
        
    return FALSE unless(defined($self->{TARGET}));
            
    return $self;
}

#*******************************************************************************
#
#  Загружает данные по контролю, возвращает TRUE при успехе
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
    my $maker = new RpgSQLMake();

    foreach my $dic (keys(%{$exp_data->{DICTIONARIES}}))
    {
        if ($dic eq 'GET_LIST_OF_SOURCES')
        {
            $self->_load_list_of_files_to_db();
            next;
        }
        
        my $query = $maker->procedure
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
    
    my $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), $sql->{procedure}{src}),
                    params => $sql->{procedure}{params}
                },
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

#*******************************************************************************
#
#   Метод загружает список файлов из директории со статистикой в БД
#
sub _load_list_of_files_to_db
#
#*******************************************************************************
{
    my $self  = shift;
    my $rdate = shift;
    my $set   = $self->{PARAM};       
    my $vars  = $self->{$PACKAGE};
    
    # открываем дирикторию и загружаем список файлов согласно шаблону    
    my $folder   = $set->{SETT}->get($set->{SESSION}->report(), 'PATH_TO_CODES_FILIALS');    
    my $template = F136::RpgAdmImportBalance::FILE_OF_CODES_FILIALS->{template}->{regexp};
    my $fields   = F136::RpgAdmImportBalance::FILE_OF_CODES_FILIALS->{template}->{fields};
    my $dir      = undef;

    my $maker               = new RpgSQLMake();
    my $listvals_tbl_stat   = [];
    my $create_tbl_stat     = $maker->create
        (
            TABLE  => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{STAT}{name}),
            FIELDS => TO_TABLE_DESC->{FIELDS}{STAT}
        );
    my $insert_tbl_stat     = $maker->insert
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{STAT}{name}),
            FIELDS    => TO_TABLE_DESC->{FIELDS}{STAT},
            FIELDVALS => TO_TABLE_DESC->{FIELDS}{STAT},
            LISTVALS  => $listvals_tbl_stat
        );
        
    eval
    {        
        # создаем временную таблицу, в которую будем загружать остатки                
        $set->{LOG}->out(RpgLog::LOG_D, "try create temporary table for store stat by load codes, sql: %s", $create_tbl_stat);
        $set->{DB}->do($create_tbl_stat);    

        unless (opendir($dir, $folder))
        {
            die (sprintf("couldn't open directory '%s', becose: %s"), $folder, $!);        
        }
        
        foreach my $file (readdir($dir))
        {
            next if (-d $file);
            
            # цикл по файлам в директории
            my %desc =
                (
                    department          => undef,
                    month               => undef,
                    file                => undef,
                    path                => undef,
                    status              => undef,
                    last_error          => 0,
                    crc                 => 0,
                    file_date_create    => undef,
                    file_date_modify    => undef,
                    file_date_access    => undef,
                    file_size           => undef,
                    load                => new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => time)) 
                );
            
            @desc{@{$fields}} = ($file =~ /^$template$/i);         
            
            $desc{fpath} = $folder;
            $desc{fname} = $file;
            
            my $path  = sprintf("%s%s", $folder, $file);
            my $hFile = new IO::File($path, O_RDONLY);
            
            unless($hFile)
            {
                my $err = $!;
                $desc{status}     = 'ошибка доступа к файлу';
                $desc{last_error} = 1;
            }
            else
            {
                flock($hFile, LOCK_SH);
                
                eval
                {
                    my $ctx     = new Digest::CRC(type => 'crc32');
                    my @stat    = stat($path);
                    
                    seek($hFile, 0, 0);
                    $ctx->addfile($hFile);
                    seek($hFile, 0, 0);
                        
                    $desc{crc}                =   $ctx->digest;
                    $desc{file_date_create}   =   (scalar(@stat) >= 10 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[10])) : new RpgTypeDate());
                    $desc{file_date_modify}   =   (scalar(@stat) >= 9 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[9])) : new RpgTypeDate());
                    $desc{file_date_access}   =   (scalar(@stat) >= 8 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[8])) : new RpgTypeDate());
                    $desc{file_size}          =   (scalar(@stat) >= 7 ? $stat[7] : 0);
                };
                
                flock($hFile, LOCK_UN);  
            }
            
            eval
            {
                my $query =
                    sprintf
                    (
                        $insert_tbl_stat,
                        map
                        {
                            my $field   = $_;
                            my $type    = TO_TABLE_DESC->{FIELDS}{STAT}{$field}{type};
                            my $src     = TO_TABLE_DESC->{FIELDS}{STAT}{$field}{src};
                            
                            RpgTypes::String2String($desc{$src}, $type, 'SQL', 'SQL');                             
                        } @{$listvals_tbl_stat}
                    );
                $set->{DB}->do($query);
            };            
        }  
    };       

    if ($@) 
    {
        $set->{LOG}->out(RpgLog::LOG_E, $@);
    }      
    
_WAS_ERROR:
    return;    
}

1;
