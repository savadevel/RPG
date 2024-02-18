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

package F136::RpgAdmImportCorrFromHtml;

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

use F136::adm_imp_corr;

# содержит описание таблиц для импорта - экспорта
use constant TABLES_DESC =>
{
    CORR_CLN =>
    {
        TABLE =>
        {
            name    => 'TBL_CORR_CLIENTS'
        },
        FIELDS    => # поля таблицы в БД
        {
            id => 
            {
                key    =>   1,            # признак поля как ключевого
                type   =>   'int',        # тип поля
                desc   =>   'ID клиента', # описание (подпись у колонки в HTML таблице)
                order  =>   2             # позиция колонки в HTML таблице (если значение не определенно то колонка не будет представленна в HTML)
            },
            res => 
            {
                type   =>   'int',
                desc   =>   'Резидент',
                order  =>   3
            },
            cls => 
            {
                type   =>   'int',
                desc   =>   'Класс',
                order  =>   4
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   5
            },                                            
            cmd =>
            {
                type    =>   'str',       
                desc    =>   'Команда',   
                order   =>   1,
                trigger =>
                {
                    cmdIns => {value => 'добавление'},
                    cmdDel => {value => 'удаление'},
                    cmdUpd => {value => 'обновление'},
                }
            }                                      
        }                 
    },
    CORR_ACC =>
    {
        TABLE       => 
        {
            name    => 'TBL_CORR_ACCOUNT'
        },
        FIELDS    => 
        {
            id => 
            {
                key    =>   1,         
                type   =>   'int',     
                desc   =>   'ID счета',
                order  =>   2             
            },
            msk => 
            {
                type   =>   'long',
                desc   =>   'Маска счета',
                order  =>   3
            },
            std => 
            {                
                type   =>   'date',
                desc   =>   'Нач. сделки',
                order  =>   4
            },
            mtd => 
            {
                type   =>   'date',
                desc   =>   'Оконч. сделки',
                order  =>   5
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   6
            },                                            
            cmd =>
            {
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>  {
                                cmdIns => {value => 'добавление'},
                                cmdDel => {value => 'удаление'},
                                cmdUpd => {value => 'обновление'},
                            }             
            }                                            
        }     
    },
    CORR_SUM =>
    {
        TABLE =>
        {
            name => 'TBL_CORR_ACCSUMM'
        },
        FIELDS =>
        {
            aid => 
            {
                key    =>   1,           # признак поля как ключевого
                type   =>   'int',       # тип поля
                desc   =>   'ID счета',  # описание поля
                order  =>   2            # порядковый номер поля 
            },
            bdt => 
            {
                key    =>   1,           
                type   =>   'date',
                desc   =>   'На дату',
                order  =>   3
            },
            acc => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Счет 2-го порядка',
                order  =>   4
            },
            code => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Код',
                order  =>   5
            },                                                        
            slc => 
            {
                type   =>   'mny',
                desc   =>   'Остаток на счете',
                order  =>   6
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   7
            },                                                                        
            cmd =>
            {
                           
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>  {
                                cmdIns => {value => 'добавление'},
                                cmdDel => {value => 'удаление'},
                                cmdUpd => {value => 'обновление'},
                            } 
            }                                                                        
        }                 
    },
    ONLY_CORR_CLN =>
    {
        TABLE =>
        {
            name    => 'TBL_CORR_CLIENTS'
        },
        FIELDS    => # поля таблицы в БД
        {
            id => 
            {
                key    =>   1,            # признак поля как ключевого
                type   =>   'int',        # тип поля
                desc   =>   'ID клиента', # описание (подпись у колонки в HTML таблице)
                order  =>   2             # позиция колонки в HTML таблице (если значение не определенно то колонка не будет представленна в HTML)
            },
            res => 
            {
                type   =>   'int',
                desc   =>   'Резидент',
                order  =>   3
            },
            cls => 
            {
                type   =>   'int',
                desc   =>   'Класс',
                order  =>   4
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   5
            },                                            
            cmd =>
            {
                type    =>   'str',       
                desc    =>   'Команда',   
                order   =>   1,
                trigger =>
                {
                    cmdIns => {value => 'добавление'},
                    cmdDel => {value => 'удаление'},
                    cmdUpd => {value => 'обновление'},
                }
            }                                      
        }                 
    },
    ONLY_CORR_ACC =>
    {
        TABLE       => 
        {
            name    => 'TBL_CORR_ACCOUNT'
        },
        FIELDS    => 
        {
            id => 
            {
                key    =>   1,         
                type   =>   'int',     
                desc   =>   'ID счета',
                order  =>   2             
            },
            msk => 
            {
                type   =>   'long',
                desc   =>   'Маска счета',
                order  =>   3
            },
            std => 
            {                
                type   =>   'date',
                desc   =>   'Нач. сделки',
                order  =>   4
            },
            mtd => 
            {
                type   =>   'date',
                desc   =>   'Оконч. сделки',
                order  =>   5
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   6
            },                                            
            cmd =>
            {
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>  {
                                cmdIns => {value => 'добавление'},
                                cmdDel => {value => 'удаление'},
                                cmdUpd => {value => 'обновление'},
                            }             
            }                                            
        }     
    },
    ONLY_CORR_SUM =>
    {
        TABLE =>
        {
            name => 'TBL_CORR_ACCSUMM'
        },
        FIELDS =>
        {
            aid => 
            {
                key    =>   1,           # признак поля как ключевого
                type   =>   'int',       # тип поля
                desc   =>   'ID счета',  # описание поля
                order  =>   2            # порядковый номер поля 
            },
            bdt => 
            {
                key    =>   1,           
                type   =>   'date',
                desc   =>   'На дату',
                order  =>   3
            },
            acc => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Счет 2-го порядка',
                order  =>   4
            },
            code => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Код',
                order  =>   5
            },                                                        
            slc => 
            {
                type   =>   'mny',
                desc   =>   'Остаток на счете',
                order  =>   6
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   7
            },                                                                        
            cmd =>
            {
                           
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>  {
                                cmdIns => {value => 'добавление'},
                                cmdDel => {value => 'удаление'},
                                cmdUpd => {value => 'обновление'},
                            } 
            }                                                                        
        }                 
    },
    CORR_BAL =>
    {
        TABLE =>
        {
            name => 'TBL_CORR_BALANCE'
        },
        FIELDS =>
        {
            dep => 
            {
                key    =>   1,           # признак поля как ключевого
                type   =>   'str',       # тип поля
                desc   =>   'ID подразд.',     # описание поля
                order  =>   2            # порядковый номер поля 
            },
            date => 
            {
                key    =>   1,           
                type   =>   'date',
                desc   =>   'На Дату',
                order  =>   3
            },
            acc => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Счет 2-го порядка',
                order  =>   4
            },
            code => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Код',
                order  =>   5
            },                                                        
            bal_r => 
            {
                type   =>   'mny',
                desc   =>   'Рублевый остаток',
                order  =>   6
            },
            bal_v => 
            {
                type   =>   'mny',
                desc   =>   'Рублевый остаток',
                order  =>   7
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   8
            },    
            cmd =>
            {
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>
                {
                    cmdIns => {value => 'добавление'},
                    cmdDel => {value => 'удаление'},
                    cmdUpd => {value => 'обновление'},
                } 
            }                                                                        
        }
    },
    CORR_COD =>
    {
        TABLE =>
        {
            name => 'TBL_CORR_ACCSUMM'
        },
        FIELDS =>
        {
            aid => 
            {
                key    =>   1,           # признак поля как ключевого
                type   =>   'int',       # тип поля
                desc   =>   'ID счета',  # описание поля
                order  =>   2            # порядковый номер поля 
            },
            bdt => 
            {
                key    =>   1,           
                type   =>   'date',
                desc   =>   'На дату',
                order  =>   3
            },
            acc => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Счет 2-го порядка',
                order  =>   4
            },
            code => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Код',
                order  =>   5
            },                                                        
            slc => 
            {
                type   =>   'mny',
                desc   =>   'Остаток на счете',
                order  =>   6
            },
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   7
            },                                                                                                    
            cmd=>
            {
                           
                type   =>   'str',       
                desc   =>   'Команда',   
                order  =>   1,
                trigger =>
                {
                    cmdIns => {value => 'добавление'},
                    cmdDel => {value => 'удаление'},
                    cmdUpd => {value => 'обновление'},
                } 
            }                                            
        }
    },
    SETT_PERMISSIONS_ACC =>
    {
        TABLE =>
        {
            name => 'TBL_F136_USE_ACCOUNT'
        },
        FIELDS   => 
        {
            cando => 
            {
                type   =>   'int',       # тип поля
                desc   =>   'Маска разрешений',  # описание поля
                order  =>   1            # порядковый номер поля 
            },
            acc => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Счет 2-го порядка',
                order  =>   2
            },
            code => 
            {
                key    =>   1,           
                type   =>   'acc',
                desc   =>   'Код',
                order  =>   3
            },                                                        
            rowver => 
            {
                key    =>   1,           
                type   =>   'int',
                desc   =>   'Версия',
                order  =>   7
            }                                            
        }                      
    }
};

# содержит описание действий
use constant COMMANDS_DESC => 
{
    CORR_CLN =>  # параметры изменения атрибутов клиента
    {
        OPTIONS =>
        {
            # параметры изменения атрибутов клиента
            title       => 'атрибуты клинтов',
            # признак необходимости вывода отчета по последней процедуре внесения изменений
            show_report => 1
        },
        SQL     => # шаблон SQL на изменение записей в БД
        {
            insert  =>
            { # для Inserte (привязка полей)
                id     => 'cln_id',                
                res    => 'cln_res',           
                cls    => 'cln_cls',           
                rowver => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                res    => 'cln_res',           
                cls    => 'cln_cls'
            },                    
            where      =>
            {
                id     => 'id',
                rowver => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    },
    CORR_ACC =>  # параметры изменения атрибутов счета
    {
        OPTIONS =>
        {
            title       => 'атрибуты счета',
            show_report => 1 
        },
        SQL =>
        {
            insert    =>
            {
                id      => 'acc_id',     
                msk     => 'acc_msk',
                mtd     => 'acc_mtd',
                std     => 'acc_std',
                rowver  => 'lstRowver'
            },                    
            update    =>
            {
                msk     => 'acc_msk',
                mtd     => 'acc_mtd',
                std     => 'acc_std'
            },                    
            where     =>
            {
                id      => 'acc_id',
                rowver  => 'lstRowver'
            },
            check_update => 1
        }
    },
    CORR_SUM =>
    {
        OPTIONS =>
        {
            title       => 'остатки по счетам',
            show_report => 1
        },
        SQL       => 
        {
            insert    =>
            {
                aid    => 'sum_aid', 
                bdt    => 'sum_bdt', 
                slc    => 'sum_slc', 
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },                    
            update    =>
            {
                slc    => 'sum_slc' 
            },                    
            where     =>
            {                               # условие на удаление
                aid    => 'sum_aid',
                bdt    => 'sum_bdt',
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },
            check_update => 1
        }    
    },
    ONLY_CORR_CLN =>  # параметры изменения атрибутов клиента
    {
        OPTIONS =>
        {
            # параметры изменения атрибутов клиента
            title       => 'атрибуты клинтов',
            # признак необходимости вывода отчета по последней процедуре внесения изменений
            show_report => 1
        },
        SQL     => # шаблон SQL на изменение записей в БД
        {
            insert  =>
            { # для Inserte (привязка полей)
                id     => 'cln_id',                
                res    => 'cln_res',           
                cls    => 'cln_cls',           
                rowver => 'lstRowver'
            },                    
            update  =>
            { # для Update (привязка полей)
                res    => 'cln_res',           
                cls    => 'cln_cls'
            },                    
            where      =>
            {
                id     => 'id',
                rowver => 'lstRowver'
            },
            # проверка существования записи при обновлении,
            # если такой нет то будет inserte 
            check_update => 1
        }
    },
    ONLY_CORR_ACC =>  # параметры изменения атрибутов счета
    {
        OPTIONS =>
        {
            title       => 'атрибуты счета',
            show_report => 1 
        },
        SQL =>
        {
            insert    =>
            {
                id      => 'acc_id',     
                msk     => 'acc_msk',
                mtd     => 'acc_mtd',
                std     => 'acc_std',
                rowver  => 'lstRowver'
            },                    
            update    =>
            {
                msk     => 'acc_msk',
                mtd     => 'acc_mtd',
                std     => 'acc_std'
            },                    
            where     =>
            {
                id      => 'acc_id',
                rowver  => 'lstRowver'
            },
            check_update => 1
        }
    },
    ONLY_CORR_SUM =>
    {
        OPTIONS =>
        {
            title       => 'остатки по счетам',
            show_report => 1
        },
        SQL       => 
        {
            insert    =>
            {
                aid    => 'sum_aid', 
                bdt    => 'sum_bdt', 
                slc    => 'sum_slc', 
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },                    
            update    =>
            {
                slc    => 'sum_slc' 
            },                    
            where     =>
            {                               # условие на удаление
                aid    => 'sum_aid',
                bdt    => 'sum_bdt',
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },
            check_update => 1
        }    
    },
    CORR_BAL =>  # параметры изменения остатка на балансовых счетах              
    {   
        OPTIONS =>
        {
            title       => 'остатки по балансовым счетам',
            show_report => 1
        },
        SQL       => 
        {
            insert =>
            {
                date   => 'date',              
                acc    => 'acc',               
                code   => 'code',              
                dep    => 'dep',
                rowver => 'lstRowver',
                bal_r  => 'bal_r',
                bal_v  => 'bal_v'
            },
            update =>
            {
                bal_r  => 'bal_r',
                bal_v  => 'bal_v'
            },
            where =>
            {
                date   => 'date', 
                acc    => 'acc',  
                code   => 'code', 
                dep    => 'dep',
                rowver => 'lstRowver'
            },
            check_update => 1
        }    
    },
    CORR_COD => # параметры изменения остатка на счетах                 
    {
        OPTIONS =>
        {
            title       => 'остатки по счетам',
            show_report => 1
        },
        SQL       => 
        {
            insert    =>
            {
                aid    => 'sum_aid', 
                bdt    => 'sum_bdt', 
                slc    => 'sum_slc', 
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },                    
            update    =>
            {
                slc    => 'sum_slc' 
            },                    
            where     =>
            {                               # условие на удаление
                aid    => 'sum_aid',
                bdt    => 'sum_bdt',
                acc    => 'sum_acc',
                code   => 'sum_code',
                rowver => 'lstRowver'
            },
            check_update => 1
        }
    },
    SETT_PERMISSIONS_ACC =>
    {
        OPTIONS =>
        {
            title       => 'список кодов и счетов',
            show_report => 1
        },
        SQL       => 
        {
            insert    =>
            {
                cando  => 'cando',
                acc    => 'acc',
                code   => 'code',
                rowver => 'lstRowver'
            },                    
            update    =>
            {
                cando  => 'cando'
            },                    
            where     =>
            {
                acc    => 'acc',
                code   => 'code',
                rowver => 'lstRowver'
            },
            check_update => 1
        }    
    }        
};

use constant REPORT_DESC =>
{
    FIELDS => # описание полей статистики
    {
        name  =>
        {
            type    =>  'str',
            desc    =>  'Параметр',
            order   =>  1
        },
        value =>
        {
            type    =>  'str',
            desc    =>  'Значение',
            order   =>  2
        } 
    },
    OPTIONS =>
    {
        title       => 'Общая статистика',
        show_report => 1,
        set         =>
        [
            {field => 'status', desc => 'Статус'},
            {field => 'del',    desc => 'Удалено записей'},
            {field => 'ins',    desc => 'Добавлено записей'},
            {field => 'upd',    desc => 'Обновлено записей'},
            {field => 'summ',   desc => 'Всего записей'},
            {field => 'time',   desc => 'Время, сек.'}, 
        ]
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
    ref($_[0]) && die "Error, class F136::RpgAdmImportCorrFromHtml can't use in inheritance\n";        
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
    my ($vars) = $self->{$PACKAGE};

    # статистика по удаленным, добавленным записям   
    $vars->{STAT}   =
        {
            summ    => 0,
            del     => 0,
            ins     => 0,
            upd     => 0,
            status  => 'ошибка',
            time    => (time)
        };
    # хранилища данных
    $vars->{DATA}   =  new RpgSrcData;    
    $vars->{DATA}->add(TO => 'STAT_FULL');  # данный, расшифровка общей статистики
    $vars->{DATA}->add(TO => 'STAT_SHORT'); # данный, статистика общая                
    
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
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $ret  = FALSE;
    
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
    
    my $tbl_desc = TABLES_DESC->{$self->{TARGET}};
    my $imp_desc = COMMANDS_DESC->{$self->{TARGET}};    
    
    $set->{LOG}->out(RpgLog::LOG_I, "start import correction data from HTML");

    # текущая и версия переданных данных должны совпадать   
    unless($set->{CGI}->param('lstRowver') == $set->{SESSION}->rowver())
    {
        $vars->{STAT}{status} = 'ошибка, не совпадение версий';
        $set->{LOG}->out(RpgLog::LOG_W, "rowver isn't same (ext != int): %d != %d", $set->{CGI}->param('lstRowver'), $set->{SESSION}->rowver());
        goto _PRINT_REPORT;
    }
    elsif($set->{SESSION}->access() != 2)
    {
        $vars->{STAT}{status} = 'ошибка, текущая версия подписана';        
        $set->{LOG}->out(RpgLog::LOG_W, "access denied %d", $set->{SESSION}->access());
        goto _PRINT_REPORT;
    }
    
    goto _PRINT_REPORT
        unless
            (
                    TRUE == $self->_parse_add('cmdDel', $cgi_check->last_pack) 
                and 
                    TRUE == $self->_parse_add('cmdIns', $cgi_check->last_pack) 
                and 
                    TRUE == $self->_parse_add('cmdUpd', $cgi_check->last_pack) 
                and 
                    TRUE == $self->submit()
            );

    $vars->{STAT}{status} = 'исполнено';
    $ret = TRUE;
    
_PRINT_REPORT:

    $vars->{STAT}{time}   = (time - $vars->{STAT}{time});
    $vars->{STAT}{summ}   = $vars->{STAT}{del} + $vars->{STAT}{ins} + $vars->{STAT}{upd};        

    if (defined($imp_desc->{OPTIONS}{show_report}))
    {
        my ($stat) = $vars->{DATA}->get_obj_data('STAT_SHORT');
        
        # переносим статистику в хранилище
        foreach my $field (@{REPORT_DESC->{OPTIONS}{set}})
        {
            $stat->add_row({name => $field->{desc}, value => $vars->{STAT}{$field->{field}}});
        }
            
        # печать отчета
        $ret = $self->get_report
            (
                STATUS   => $ret,
                TITLE    => 'Протокол сохранения коррекций: ' . ($imp_desc->{OPTIONS}{title}),
                TEMPLATE => 'f136_admin_corr_imp.html',
                TABLES   =>
                {
                    STAT_SHORT =>
                    {
                        TITLE   =>  REPORT_DESC->{OPTIONS}{title},
                        DATA    =>  $vars->{DATA}->get_data('STAT_SHORT'),
                        FIELDS  =>  REPORT_DESC->{FIELDS}
                    },
                    STAT_FULL  =>
                    {
                        TITLE   =>  $imp_desc->{OPTIONS}{title},
                        DATA    =>  $vars->{DATA}->get_data('STAT_FULL'),
                        FIELDS  =>  $tbl_desc->{FIELDS}
                    }
                }
            );        
    }
    else
    {
        # отчет печатать не надо, повторяем последний экспорт
        $ret = $self->repeat_export();
    }
    
_WAS_ERROR:    
    return $ret;
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
            $vars->{STAT}{status} = 'Ошибка, во входном потоке';
            $self->_add_alert($self->{TARGET}, $vars->{STAT}{status});
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
        
        eval {$dbh->rollback};
        
        $msg .= $@ if ($@ ne '');

        $set->{LOG}->out(RpgLog::LOG_E, "couldn't submit correction, becose: %s", $msg);
        $vars->{STAT}{status} = 'Ошибка во входном потоке, обратитесь к администратору системы';
        $self->_add_alert($self->{TARGET}, $vars->{STAT}{status});
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
    my $self   = shift;    
    my $dbh    = shift;    
    my $set    = $self->{PARAM};    # общие параметры    
    my $vars   = $self->{$PACKAGE}; # содержит ссылку на хеш текущего пакета    
    my $ret    = FALSE;

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
        $vars->{STAT}{ins}++;
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
        $vars->{STAT}{del}++;
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
        
        $vars->{STAT}{upd}++;
    }

    $ret = TRUE;
    
_WAS_ERROR:    
    return $ret;    
}


1;
