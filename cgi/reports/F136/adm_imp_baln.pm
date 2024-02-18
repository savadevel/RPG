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

package F136::RpgAdmImportBalance;

use UNIVERSAL qw(isa);
use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use DBI;
use Digest::CRC;
use Fcntl qw (LOCK_SH LOCK_UN O_RDONLY);
use IO qw(Handle File);
use utils;
use types;
use sql_make;
use cgi_check;

use constant FILE_OF_CODES_FILIALS =>
{
    template =>
    {
        regexp => 'rf(\d{4})(\d{2}).mdb',
        fields => [ qw(department month) ]
    }
};  

use constant DICTIONARIES =>    # коды и № подразделений по которым определяем файлы для загрузки
{    
    GET_CODES   =>
    {
        src    => 'SQL_GET_THE_NUMBER_OF_CODES',
        params => 
        [
            {field => 'lstCodes'},
            {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
        ]  
    },
    GET_FILIALS =>
    {
        src    => 'SQL_GET_THE_FILIALS',  
        params => 
        [
            {field => 'lstDep'},
            {field => 'lstDep',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
        ]  
    },
    GET_THE_ROWVER    =>
    {
        src     => 'SQL_GET_THE_ROWVER',
        params  => [{field => 'lstRowver'}]
    }            
};

use constant TO_TABLE_DESC =>   # описание таблиц для сохранения остатков по кодам и статистики
{
    TABLES  =>
    {
        CODES   =>
        {name => 'TBL_TMP_CODES_OF_FILIALS'},
        STAT    =>
        {name => 'TBL_TMP_STAT_BY_SRC_OF_CODES'}
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
                src     => 'file'
            },
            fpath =>
            {
                type    => 'str',
                length  => 512,
                src     => 'path'
            },
            dep =>
            {
                type    => 'chr',
                length  => 4,
                src     => 'id'
            },
            num =>
            {
                type    => 'int',
                src     => 'num'
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
            perform =>
            {
                type    => 'int',
                src     => 'time'
            },
            fsize   =>
            {
                type    => 'long',
                src     =>  'file_size'
            }
        }
    }
};

use constant FROM_TABLE_DESC => # описание таблицы кодов подразделения в файле
{
    TABLE =>
    {
        name    => 'SQL_GET_CODES_OF_FILIALS',
        params  => 
        [
            {field => 'lstDep'},
            {field => 'lstDep',     options => {array => TRUE, wrap => '', spliter => ','}},
            {field => 'lstCodes'},
            {field => 'lstCodes',   options => {array => TRUE, wrap => '', spliter => ','}},
            {field => 'edtDateLeft'},
            {field => 'edtDateRight'}
        ]
    },
    FIELDS =>
    {
        date =>
        {
            key     => 1,           
            type    => 'date'
        },
        dep =>
        {
            key   => 1,           
            type  => 'str'
        },
        acc =>
        {
            key   => 1,           
            type  => 'acc'
        },
        code =>
        {
            key   => 1,           
            type  => 'acc'
        },
        bal_r =>
        {
            type  => 'mny'
        },
        bal_v =>
        {
            type  => 'mny'
        }
    }
};

use constant EXPORT_DESC =>     # описание процедур загрузки в основную таблицу остатков
{
    DAD_BALANCE =>
    {
        order => 0,
        title  => 'остатки по счетам ГО',
        SQL   => 
        {
            procedure =>
            {
                src     => 'IMPORT_DAD_BALANCE',
                params  => 
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'lstDep',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}
                ]  
            }
        },
        FIELDS =>
        {
            oper    => 
            {
                type    =>  'str',
                desc    =>  'Операция',
                order   =>  1
            }, 
            src    => 
            {
                type    =>  'str',
                desc    =>  'Источник',
                order   =>  2
            }, 
            dep => 
            {
                type    =>  'str',
                desc    =>  'Подразделение',
                order   =>  3
            }, 
            code   => 
            {
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            }, 
            acc   => 
            {
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  5
            }, 
            ldate  => 
            {
                type    =>  'date',
                desc    =>  'Первый остаток',
                order   =>  6
            }, 
            rdate  => 
            {
                type    =>  'date',
                desc    =>  'Последний остаток',
                order   =>  7
            }, 
            num    => 
            {
                type    =>  'int',
                desc    =>  'Число дней',
                order   =>  8
            },
            rowver => 
            {
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   9
            }         
        }
    },
    FIL_BALANCE =>
    {
        order => 1,
        title  => 'остатки по счетам филиалов',
        SQL   => 
        {
            procedure =>
            {
                src   => 'IMPORT_FIL_BALANCE',
                params  => 
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'lstDep',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}
                ]  
            }
        },
        FIELDS =>
        {
            oper    => 
            {
                type    =>  'str',
                desc    =>  'Операция',
                order   =>  1
            }, 
            src    => 
            {
                type    =>  'str',
                desc    =>  'Источник',
                order   =>  2
            }, 
            dep => 
            {
                type    =>  'str',
                desc    =>  'Подразделение',
                order   =>  3
            }, 
            code   => 
            {
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            }, 
            acc   => 
            {
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  5
            }, 
            ldate  => 
            {
                type    =>  'date',
                desc    =>  'Первый остаток',
                order   =>  6
            }, 
            rdate  => 
            {
                type    =>  'date',
                desc    =>  'Последний остаток',
                order   =>  7
            }, 
            num    => 
            {
                type    =>  'int',
                desc    =>  'Число дней',
                order   =>  8
            },
            rowver => 
            {
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   9
            }         
        }
    },
    DAD_CODES =>
    {
        order  => 2,
        title   => 'остатки по кодам ГО',
        SQL    => 
        {
            procedure =>
            {
                src   => 'IMPORT_DAD_CODES',
                params  => 
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'lstDep',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}
                ]  
            }
        },
        FIELDS =>
        {
            oper    => 
            {
                type    =>  'str',
                desc    =>  'Операция',
                order   =>  1
            }, 
            src    => 
            {
                type    =>  'str',
                desc    =>  'Источник',
                order   =>  2
            }, 
            dep => 
            {
                type    =>  'str',
                desc    =>  'Подразделение',
                order   =>  3
            }, 
            code   => 
            {
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            }, 
            acc   => 
            {
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  5
            }, 
            ldate  => 
            {
                type    =>  'date',
                desc    =>  'Первый остаток',
                order   =>  6
            }, 
            rdate  => 
            {
                type    =>  'date',
                desc    =>  'Последний остаток',
                order   =>  7
            }, 
            num    => 
            {
                type    =>  'int',
                desc    =>  'Число дней',
                order   =>  8
            },
            rowver => 
            {
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   9
            }         
        }
    },
    FIL_CODES =>
    {
        order => 3,
        title  => 'остатки по кодам филиалов',
        SQL   => 
        {
            procedure =>
            {
                src   => 'IMPORT_FIL_CODES',
                params  => 
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'lstDep',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'unk', wrap => "'", spliter => ' '}}
                ]  
            }
        },
        FIELDS =>
        {
            oper    => 
            {
                type    =>  'str',
                desc    =>  'Операция',
                order   =>  1
            }, 
            src    => 
            {
                type    =>  'str',
                desc    =>  'Источник',
                order   =>  2
            }, 
            dep => 
            {
                type    =>  'str',
                desc    =>  'Подразделение',
                order   =>  3
            }, 
            code   => 
            {
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            }, 
            acc   => 
            {
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  5
            }, 
            ldate  => 
            {
                type    =>  'date',
                desc    =>  'Первый остаток',
                order   =>  6
            }, 
            rdate  => 
            {
                type    =>  'date',
                desc    =>  'Последний остаток',
                order   =>  7
            }, 
            num    => 
            {
                type    =>  'int',
                desc    =>  'Число дней',
                order   =>  8
            },
            rowver => 
            {
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   9
            }         
        }
    }
};

use constant REPORT_DESC =>     # описание полей статистики
{
    STAT_SHORT =>
    {
        title  => 'Общая статистика',
        FIELDS => # описание полей статистики
        {
            name    => 
            {
                type    =>  'str',
                desc    =>  'Описание',
                order   =>  1
            },     
            status    => 
            {
                type    =>  'str',
                desc    =>  'Статус',
                order   =>  2
            },             
            del    => 
            {
                type    =>  'int',
                desc    =>  'Удалено записей',
                order   =>  3
            },     
            ins    => 
            {
                type    =>  'int',
                desc    =>  'Добавлено записей',
                order   =>  4
            },     
            summ    => 
            {
                type    =>  'int',
                desc    =>  'Всего записей',
                order   =>  5
            },
            time    => 
            {
                type    =>  'int',
                desc    =>  'Время',
                order   =>  6
            }
        }        
    },
    LOAD_FILIALS =>
    {
        title   => 'Загрузка остатков по кодам из файлов филиалов',
        FIELDS =>
        {
            status => 
            {
                type    =>  'str',
                desc    =>  'Статус',
                order   =>  1
            },    
            id  => 
            {
                type    =>  'acc',
                desc    =>  'ID',
                order   =>  2
            },         
            dep => 
            {
                type    =>  'str',
                desc    =>  'Подразделение',
                order   =>  3
            },
            num => 
            {
                type    =>  'int',
                desc    =>  'Число записей',
                order   =>  4
            },
            file => 
            {
                type    =>  'str',
                desc    =>  'Файл',
                order   =>  5
            },      
            path => 
            {
                type    =>  'txt',
                desc    =>  'Путь',
                order   =>  6
            },       
            time => 
            {
                type    =>  'int',
                desc    =>  'Затрачено, сек.',
                order   =>  7
            }                 
        }
    }
};

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

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
    
    foreach my $parent (@ISA)
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
    ref($_[0]) && die "Error, class F136::RpgAdmImportBalance can't use in inheritance\n";        
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
    my ($self) = shift;
    my ($set)  = $self->{PARAM}; 
    my ($vars) = $self->{$PACKAGE};
    
    # управление данными    
    $vars->{DATA}   = new RpgSrcData;
    $vars->{STAT}   = {};
    $vars->{TABLES} = {};
    
    $vars->{DATA}->add(TO => 'STAT_SHORT');   # статистика общая, формируется на стороне сервера приложений
    $vars->{DATA}->add(TO => 'LOAD_FILIALS'); # статистика загрузки остатков по кодам из файлов филиалов
    
    # инициализируем значениями по умолчанию статистику
    foreach my $from (keys(%{EXPORT_DESC()}))
    {        
        my $row = {name => EXPORT_DESC->{$from}{title}, del => 0, ins  => 0, upd  => 0, status => 'ошибка', time => 0};
        $vars->{STAT}->{$from} = $vars->{DATA}->row_insert($row, 'STAT_SHORT');
        
        $vars->{TABLES}{$from}{TITLE}  = EXPORT_DESC->{$from}{title};
        $vars->{TABLES}{$from}{FIELDS} = EXPORT_DESC->{$from}{FIELDS};
        $vars->{TABLES}{$from}{DATA}   = undef;
        $vars->{TABLES}{$from}{ORDER}  = undef;        
    }
    
    foreach my $tbl (keys(%{REPORT_DESC()}))
    {
        $vars->{TABLES}{$tbl} = {};
        $vars->{TABLES}{$tbl}{TITLE}  = REPORT_DESC->{$tbl}{title};
        $vars->{TABLES}{$tbl}{FIELDS} = REPORT_DESC->{$tbl}{FIELDS};
        $vars->{TABLES}{$tbl}{DATA}   = $vars->{DATA}->get_data($tbl);
        $vars->{TABLES}{$tbl}{ORDER}  = undef;
    }       
    
    return $self;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my $self = shift;    
    my $set  = $self->{PARAM};       
    my $vars = $self->{$PACKAGE};
    my $stat = $vars->{STAT};    
    my $ret  = FALSE;    
        
    $set->{LOG}->out(RpgLog::LOG_I, "start import balance data");
    
    unless (defined($self->{TARGET}) &&  defined(F136::RpgAdmImportCorr::CGI_DESC()->{$self->{TARGET}}))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "invalid CGI query");
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
        goto _WAS_ERROR;
    }
    
    my $cgi_check = new RpgCGICheck(PARAM => $set);        
    my $cgi_desc  = F136::RpgAdmImportCorr::CGI_DESC()->{$self->{TARGET}};
    
    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, 'invalid CGI query, becose: "%s"', $cgi_check->errstr);
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
        goto _WAS_ERROR;
    }        
    # текущая и версия переданных данных должны совпадать    
    elsif($set->{CGI}->param('lstRowver') != $set->{SESSION}->rowver())
    {        
        $stat->{$_}{status} = 'ошибка, несовпадение версий' foreach (keys(%{$stat}));
        $set->{LOG}->out(RpgLog::LOG_W, "rowver isn't same (ext != int): %d != %d", $set->{CGI}->param('lstRowver'), $set->{SESSION}->rowver());
        goto _PRINT_REPORT;
    }
    elsif($set->{SESSION}->access() != 2)
    {
        $stat->{$_}{status} = 'ошибка, текущая версия подписана' foreach (keys(%{$stat}));
        $set->{LOG}->out(RpgLog::LOG_W, "access denied %d", $set->{SESSION}->access());
        goto _PRINT_REPORT;
    }
    elsif(!$self->_store_codes_of_filials())
    {
        goto _PRINT_REPORT;
    }
    
    my $maker = new RpgSQLMake();    

    foreach my $from (keys(%{EXPORT_DESC()}))
    {
        my $query = $maker->procedure
            (
                DESC    =>
                {
                    src    => $set->{SETT}->get($set->{SESSION}->report(), EXPORT_DESC->{$from}{SQL}{procedure}{src}),
                    params => EXPORT_DESC->{$from}{SQL}{procedure}{params}
                },
                CGI     => $set->{CGI},
                REQUEST => F136::RpgAdmImportCorr::CGI_DESC()->{$self->{TARGET}}{FIELDS}
            );   

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (import), sql: '%s'", $from, $query);
        $stat->{$from}{time} = time;
        
        unless
            (
                $vars->{DATA}->add
                        (
                            FROM  => $set->{DB}, 
                            TO    => $from,
                            SRC   => $query
                        )
            )
        {
            # возникли ошибки на стороне сервера данных
            $stat->{$from}{status} = 'ошибка, не могу загрузить остатки';            
            $set->{LOG}->out(RpgLog::LOG_E, "Error, can't load src = $from, becose: %s", $vars->{DATA}->errstr());
        }
        else
        {
            # ок, запрос отработал
            my $counts = $vars->{DATA}->get_obj_data($from, 1);            

            $set->{LOG}->out(RpgLog::LOG_I, "balance from %s was loading, with code %d, inserted records %d,  deleted records %d",
                             $from, $counts->err(), $counts->ins(), $counts->del());
            
            $stat->{$from}{status} = $counts->err() == 0 ? 'исполнено': 'ошибка, не могу загрузить остатки';
            $stat->{$from}{ins}    = $counts->ins();
            $stat->{$from}{del}    = $counts->del();
            $stat->{$from}{summ}   = $counts->summ();
        }                

        $stat->{$from}{time}         = time - $stat->{$from}{time};
        $vars->{TABLES}{$from}{DATA} = $vars->{DATA}->get_data($from);
    }

    $ret = TRUE;
   
_PRINT_REPORT:
    $ret = $self->get_report
    (
        STATUS   => $ret,
        TITLE    => 'Протоколы загрузки',
        TEMPLATE => 'f136_admin_baln_imp.html',
        TABLES   => $vars->{TABLES}
    );
    
_WAS_ERROR:
    return $ret;
}

#*******************************************************************************
#
sub _store_codes_of_filials
#
#*******************************************************************************
{
    my $self = shift;    
    my $set  = $self->{PARAM};       
    my $vars = $self->{$PACKAGE};
    my $stat = $vars->{STAT};    
    my $ret  = FALSE;    

    my $maker = new RpgSQLMake();
    my $data  = new RpgSrcData;
    
    # загрузка словарей, на основе этой информации определяем какие филиалы и по 
    # каким кодам грузить
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
                REQUEST => F136::RpgAdmImportCorr::CGI_DESC()->{$self->{TARGET}}{FIELDS}
            );
        
        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (dictionary), sql: '%s'", $dic, $query);
                                                
        unless ($data->add(FROM  => $set->{DB}, TO => $dic, SRC => $query))
        {
            $stat->{$_}{status} = 'ошибка, не могу загрузить справочную информацию' foreach (keys(%{$stat}));
            $set->{LOG}->out(RpgLog::LOG_E, "Error, can't load dictionary, becose: %s", $data->errstr);
            goto _WAS_ERROR;
        }
    }

    my $rowver = $data->get_obj_data('GET_THE_ROWVER');
    my $rdate  = new RpgTypeDate(rval => $rowver->ldate, schema => 'SQL');
    
    $rdate->set_part(day => 1);
    $rdate->add(months => 1);
    
    my $files  = $self->_load_list_of_files($rdate);
    
    unless(keys(%{$files}))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "directory '%s' is empty",
                         $set->{SETT}->get($set->{SESSION}->report(), 'PATH_TO_CODES_FILIALS'));
        goto _EXIT;        
    }
    
    my $filials = $data->get_data('GET_FILIALS');
    my $codes   = $data->get_data('GET_CODES');
    
    if ($#{$filials} < 0 || $#{$codes} < 0)
    {
        $set->{LOG}->out(RpgLog::LOG_W, "no need load codes by filials, becose user query filials=%d and codes=%d", $#{$filials} + 1, $#{$codes} + 1);
        goto _EXIT;
    }    
    
    $set->{LOG}->out(RpgLog::LOG_D, "load codes by filials, filials=%d and codes=%d", $#{$filials} + 1, $#{$codes} + 1);
    
    my $listvals_tbl_codes   = [];
    my $create_tbl_codes = $maker->create
        (
            TABLE  => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{CODES}{name}),
            FIELDS => TO_TABLE_DESC->{FIELDS}{CODES}
        );
    my $select_tbl_codes = $maker->procedure
        (
            DESC    =>
            {
                src    => $set->{SETT}->get($set->{SESSION}->report(), FROM_TABLE_DESC->{TABLE}{name}),
                params => FROM_TABLE_DESC->{TABLE}{params}
            },
            CGI     => $set->{CGI},
            REQUEST => F136::RpgAdmImportCorr::CGI_DESC()->{$self->{TARGET}}{FIELDS}
        ); 
    my $insert_tbl_codes = $maker->insert
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{CODES}{name}),
            FIELDS    => TO_TABLE_DESC->{FIELDS}{CODES},
            FIELDVALS => FROM_TABLE_DESC->{FIELDS},
            LISTVALS  => $listvals_tbl_codes
        );   
    
    my $listvals_tbl_stat   = [];
    my $create_tbl_stat = $maker->create
        (
            TABLE  => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{STAT}{name}),
            FIELDS => TO_TABLE_DESC->{FIELDS}{STAT}
        );
    my $insert_tbl_stat = $maker->insert
        (
            TABLE     => $set->{SETT}->get($set->{SESSION}->report(), TO_TABLE_DESC->{TABLES}{STAT}{name}),
            FIELDS    => TO_TABLE_DESC->{FIELDS}{STAT},
            FIELDVALS => TO_TABLE_DESC->{FIELDS}{STAT},
            LISTVALS  => $listvals_tbl_stat
        );
        
    eval
    {        
        # создаем временную таблицу, в которую будем загружать остатки                
        $set->{LOG}->out(RpgLog::LOG_D, "try create temporary table for store codes, sql: %s", $create_tbl_codes);
        $set->{DB}->do($create_tbl_codes);    
        $set->{LOG}->out(RpgLog::LOG_D, "try create temporary table for store stat by load codes, sql: %s", $create_tbl_stat);
        $set->{DB}->do($create_tbl_stat);    
        
        # цикл по подразделениям для загрузки остатков
        foreach my $dep (@{$filials})
        {
            unless (defined($files->{$dep->{id}}))
            {
                $set->{LOG}->out(RpgLog::LOG_W, "for department ID '%d' file with codes not found",
                                $dep->{id});
                next;
            }
            
            my ($desc) = 
                {
                    file                => $files->{$dep->{id}}{file},
                    path                => $files->{$dep->{id}}{folder},
                    id                  => $dep->{id},
                    dep                 => $dep->{name},
                    num                 => 0,
                    time                => time,
                    status              => undef,
                    crc                 => undef,
                    load                => new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => time)) ,
                    file_date_create    => undef,
                    file_date_access    => undef,
                    file_date_modify    => undef,
                    file_size           => undef,
                    last_error          => 0                    
                };
            
            eval
            {
                my $path  = sprintf("%s%s", $files->{$dep->{id}}{folder}, $files->{$dep->{id}}{file});
                my $hFile = new IO::File($path, O_RDONLY);
                
                unless($hFile)
                {
                    my $err = $!;
                    $desc->{status}     = 'ошибка доступа к файлу';
                    $desc->{last_error} = 1;
                    die (sprintf("couldn't open file %s, becose: %s", $path, $err));
                }
                
                flock($hFile, LOCK_SH);
            
                # расчет статистики по файлу    
                {
                    my $ctx     = new Digest::CRC(type => 'crc32');
                    my @stat    = stat($path);
                    
                    seek($hFile, 0, 0);
                    $ctx->addfile($hFile);
                    seek($hFile, 0, 0);
                        
                    $desc->{crc}                =   $ctx->digest;
                    $desc->{file_date_create}   =   (scalar(@stat) >= 10 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[10])) : new RpgTypeDate());
                    $desc->{file_date_modify}   =   (scalar(@stat) >= 9 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[9])) : new RpgTypeDate());
                    $desc->{file_date_access}   =   (scalar(@stat) >= 8 ? new RpgTypeDate(type=>'time', rval => new Seconds2DateTime(seconds => $stat[8])) : new RpgTypeDate());
                    $desc->{file_size}          =   (scalar(@stat) >= 7 ? $stat[7] : 0);
                }
                
                # загрузка кодов
                eval
                {
                    my ($unc, $dsn, $dbh);

                    $unc = $files->{$dep->{id}}{path};
                    $dsn = "DRIVER={Microsoft Access Driver (*.mdb)};DBQ=$unc"; 
                                
                    $set->{LOG}->out(RpgLog::LOG_D, "try connect to DSN: %s", $dsn);
    
                    # создаем подключение и загружаем остаки
                    eval
                    {                    
                        $dbh = DBI->connect("dbi:ODBC:$dsn", 'admin','',
                            {
                                RaiseError => $set->{SETT}->get(undef, 'DBI_PRINT_ERROR'),
                                #AutoCommit => $set{SETT}->get(undef, 'DBI_AUTO_COMMIT'),
                                PrintError => $set->{SETT}->get(undef, 'DBI_RAISE_ERROR')
                            }) or die $DBI::errstr;
                        
                        $set->{LOG}->out(RpgLog::LOG_D, "try load codes for filial %s, sql: %s", $dep->{id}, $select_tbl_codes);
                        
                        $data->add(FROM => $dbh, TO => 'GET_BALANCE', SRC => $select_tbl_codes) || die $data->errstr();
                    };
    
                    if ($@) 
                    {
                        my $err = $@;
                        $desc->{status}     = 'ошибка доступа к данным';
                        $desc->{last_error} = 2;
                        eval
                        {
                            $dbh->disconnect if ($dbh);
                        };                        
                        die(sprintf("couldn't load codes from filial %s, becose: %s", $dep->{id}, $err));
                    }
                    
                    eval
                    {                
                        $set->{DB}->begin_work;
                        foreach my $row (@{$data->get_data('GET_BALANCE')})
                        {
                            my $query =
                                sprintf
                                (
                                    $insert_tbl_codes,
                                    map {RpgTypes::String2String($row->{$_}, FROM_TABLE_DESC->{FIELDS}->{$_}{type}, 'SQL', 'SQL')} @{$listvals_tbl_codes}
                                );
                            $set->{DB}->do($query);
                        }
                        $set->{DB}->commit;
                    };
                    
                    if ($@) 
                    {     
                        my $err = $@;                
                        eval {$set->{DB}->rollback};                
                        $err .= $@ if ($@ ne '');
                        $desc->{status}     = 'ошибка во время выгрузки остатков';
                        $desc->{last_error} = 3;
                        die(sprintf("couldn't add code from filial %s, becose: %s", $dep->{id}, $err));
                    }        
                };
                
                if ($@)
                {
                    $desc->{status}     = 'системная ошибка' unless(defined($desc->{status}));
                    $desc->{last_error} = 4 if(0 == $desc->{last_error});
                    $set->{LOG}->out(RpgLog::LOG_E, $@);
                }
                else
                {
                    $desc->{status}     = 'исполнено';
                    $desc->{num}        = $#{$data->get_data('GET_BALANCE')} + 1;
                    $desc->{last_error} = 0;
                    $set->{LOG}->out(RpgLog::LOG_D, "loaded rows %d for filial %s", $desc->{num}, $dep->{id});                    
                }
                
                flock($hFile, LOCK_UN);                    
            };

          
            $desc->{time} = time - $desc->{time};
            
            $vars->{DATA}->row_insert($desc, 'LOAD_FILIALS');
            
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
                            
                            RpgTypes::String2String($desc->{$src}, $type, 'SQL', 'SQL');                             
                        } @{$listvals_tbl_stat}
                    );
                $set->{DB}->do($query);
            };
        }               
    };
    
    if ($@) 
    {        
        $set->{LOG}->out(RpgLog::LOG_E, "couldn't load codes by filials, becose: %s", $@);
        $stat->{$_}{status} = 'ошибка, не могу загрузить остатки по кодам филиалов' foreach (keys(%{$stat}));
        goto _WAS_ERROR;
    }        

_EXIT:    
    $ret = TRUE;
   
_WAS_ERROR:           
    return $ret;
}

#*******************************************************************************
#
#   Возвращает дату на которую филиалы присылают расшифровку по кодам
#
sub _rdate
#
#*******************************************************************************
{
    my $self  = shift;
    my $rdate = shift->clone;

    $rdate->set_part(day => 1);
    $rdate->add(months => 1);
    
    return ($rdate);
}


#*******************************************************************************
#
#   Метод загружает список файлов согласно шаблону из директории и возвращает
#   ссылку на хеш подразделение => {path => 'путь', time => время, file => 'имя', folder => 'директория'}
#
sub _load_list_of_files
#
#*******************************************************************************
{
    my $self  = shift;
    my $rdate = shift;
    my $set   = $self->{PARAM};       
    my $vars  = $self->{$PACKAGE};
    my $ret   = {};
    
    # открываем дирикторию и загружаем список файлов согласно шаблону    
    my $folder   = $set->{SETT}->get($set->{SESSION}->report(), 'PATH_TO_CODES_FILIALS');    
    my $template = FILE_OF_CODES_FILIALS->{template}->{regexp};
    my $fields   = FILE_OF_CODES_FILIALS->{template}->{fields};
    my $month    = $rdate->month;
    my $dir      = undef;
    
    unless (opendir($dir, $folder))
    {
        $set->{LOG}->out(RpgLog::LOG_W, "couldn't open directory '%s', becose: %s",
                         $folder, $!);
        goto _WAS_ERROR;
    }
    
    foreach my $file (readdir($dir))
    {
        # цикл по файлам в директории
        my %data;
        
        @data{@{$fields}} = ($file =~ /^$template$/i);         
        next unless (defined($data{department}));
        
        my $path = "$folder/$file";
        my $time = [stat($path)]->[9];
        
        $ret->{$data{department}} = {time => -1, folder => $folder}
            unless(defined($ret->{$data{department}}));
        
        #if ($time > $ret->{$data{department}}{time})
        if ($month == $data{month})
        {
            $ret->{$data{department}}{file} = $file;
            $ret->{$data{department}}{path} = $path;
            $ret->{$data{department}}{time} = $time;
        }  
    }    
    
_WAS_ERROR:
    return $ret;    
}

1;
