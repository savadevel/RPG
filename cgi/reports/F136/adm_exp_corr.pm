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

package F136::RpgAdmExportCorr;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use const;
use types;
use src_data;
use cgi_check;
use sql_make;

use F136::page_adm;
use F136::adm_exp_corr_html;
use F136::adm_exp_corr_excel;

# список параметров которые могут быть в CGI запросе
# содержит поля запроса, по ним делаем его валидацию
use constant CGI_DESC => 
{
    CORR_CLN =>
    { # параметры выгрузки атрибутов клиента
        FIELDS =>
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type     => 'date',        # тип данных
                request  => TRUE          # если значение определенно, то поле будет добавленно в тег request
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type     => 'date',
                request  => TRUE
            },
            lstAcc      => # список б. счетов второго порябка
            {
                type     => 'acc',
                array    => TRUE,
                request  => TRUE
            },
            lstCls      => # список классов клиентов Банка
            {
                type     => 'int',
                array    => TRUE,
                optional => TRUE,
                request  => TRUE
            },
            chkRes      => # список признаков резидентности
            {
                type     => 'int',
                array    => TRUE,
                optional => TRUE,
                request  => TRUE
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
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc', exp => '^\d{5}$'},
                {field => 'lstCls', exp => '^\d{4}$'},
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['acc_nmb', 'acc_lck', 'acc_msk', 'acc_desc']},
                {field => 'chkRes',         values => [0, 1]},
                {field => 'lstCls',         values => [2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 3001]},
            ]
        }
    },    
    CORR_ACC =>
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
            lstAcc      => # список б. счетов второго порябка
            {
                type     => 'acc',
                array    => TRUE,   
                request  => TRUE
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
                array    => TRUE,   
                optional => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc', min => 10201, max => 99999}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['cln_res', 'cln_desc', 'cln_cls', 'acc_code']}
            ]
        }
    },
    CORR_SUM =>
    {    
        FIELDS => 
        {
            edtDateLeft => 
            {
                type     => 'date',        
                request  => TRUE
            },
            edtDateRight => 
            {
                type     => 'date',
                request  => TRUE
            },
            lstAcc      => 
            {
                type     => 'acc',
                array    => TRUE,
                request  => TRUE
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
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc', min => 10201, max => 99999}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['cln_res', 'cln_desc', 'cln_cls', 'acc_msk', 'acc_lck', 'acc_desc']}
            ]
        }    
    },                    
    CORR_COD =>
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
            lstAcc      => # список б. счетов второго порябка
            {
                type     => 'acc',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstCodes      => # список кодов 136 формы
            {
                type     => 'acc',
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
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc',   exp => '^\d{5}$'},
                {field => 'lstCodes', exp => '^\d{6}$'}
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['cln_res', 'cln_desc', 'cln_cls', 'acc_msk', 'acc_lck', 'acc_desc', 'sum_bdt', 'sum_acc']}
            ],
            count =>
            [
                {fields => ['lstAcc', 'lstCodes'], min => 1, max => undef}
            ]
        }    
    },    
    SHOW_COD =>
    {
        FIELDS => 
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type    => 'date',        
                request => TRUE    
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type    => 'date',
                request => TRUE 
            },
            lstCodes      => # список кодов 136 формы
            {
                type     => 'acc',
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
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstCodes', exp => '^\d{6}$'}
            ]
        }    
    },
    ONLY_CORR_CLN => 
    { # параметры на выгрузку коррекций по клиентам
        FIELDS => 
        {
            strOrder    => 
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
            ]        }
    },
    ONLY_CORR_ACC => 
    { # параметры на выгрузку коррекций по счетам
        FIELDS => 
        {
            strOrder    => 
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE  
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    ONLY_CORR_SUM => 
    { # параметры на выгрузку коррекций по остаткам
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request  => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SHOW_BAL =>
    {  # выгрузка для просмотра загруженных счетов и кодов      
        FIELDS => 
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type    => 'date',        
                request => TRUE     
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type    => 'date',
                request => TRUE  
            },
            lstDep       => # список подразделений
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE  
            },
            lstAcc       => # список кодов 136 формы
            {
                type     => 'acc',
                array    => TRUE,
                request  => TRUE  
            },
            lstCodes      => # список кодов 136 формы
            {
                type     => 'acc',
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
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                array    => TRUE,
                optional => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
            },
            rowver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc',   exp => '^\d{5}$'},
                {field => 'lstCodes', exp => '^\d{6}$'},
                {field => 'lstDep',   exp => '^\d{4}$'}
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['acc', 'code', 'dep']}
            ]
        }
    },
    CORR_BAL =>
    {  # выгрузка для просмотра загруженных счетов и кодов      
        FIELDS => 
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type    => 'date',        
                request => TRUE     
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type    => 'date',
                request => TRUE  
            },
            lstDep       => # список подразделений
            {
                type     => 'str',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE  
            },
            lstAcc       => # список кодов 136 формы
            {
                type     => 'acc',
                array    => TRUE,
                request  => TRUE  
            },
            lstCodes      => # список кодов 136 формы
            {
                type     => 'acc',
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
            chkShowNull    => # выгрузка нулевых остатков
            {
                type     => 'int',
                optional => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
            },
            rowver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc',   exp => '^\d{5}$'},
                {field => 'lstCodes', exp => '^\d{6}$'},
                {field => 'lstDep',   exp => '^\d{4}$'}
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ]
        }
    },                
    SHOW_SUM =>
    {  # выгрузка для просмотра остатков на лицевых счетах
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
            lstAcc       => # список кодов 136 формы
            {
                type     => 'acc',
                array    => TRUE,
                request  => TRUE   
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                spliter  => '&',
                optional => TRUE,                
                request  => TRUE   
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstAcc',   exp => '^\d{5}$'},
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ]         
        }    
    },
    SHOW_CUR =>
    {  # выгрузка для просмотра счетов по коду валюты
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
            lstCur       => # список кодов 136 формы
            {
                type     => 'int',
                array    => TRUE,
                request  => TRUE   
            },
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                spliter  => '&',
                optional => TRUE,                
                request  => TRUE   
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
            },
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                array    => TRUE,
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
                {field => 'lstCur',   exp => '^\d+$'},
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['cln_res', 'cln_desc', 'cln_cls', 'acc_msk', 'acc_lck', 'acc_desc']}
            ]            
        }    
    },    
    SETT_USE_ACC =>     
    { # параметры на выгрузку коррекций по остаткам
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SETT_HTML =>     
    { # параметры на выгрузки параметров представления в HTML
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SETT_KLIKO =>     
    { # параметры на выгрузки параметров представления в Kliko
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SETT_RESERVE =>     
    { # параметры на выгрузки параметров представления в ПО Reserve
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SETT_FORMULAS =>     
    { # параметры на выгрузки формул расчета 136 формы
        FIELDS => 
        {
            strOrder    => # строка указывает порядок сортировки полей
            {
                type     => 'str',
                optional => TRUE,
                request => TRUE 
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
    SETT_PERMISSIONS_ACC =>
    { # параметры выгрузки разрешений
        FIELDS => 
        {
            lstAcc      => # список б. счетов второго порябка
            {
                type     => 'acc',
                optional => TRUE,
                array    => TRUE,
                request  => TRUE
            },
            lstCodes      => # список кодов 136 формы
            {
                type     => 'acc',
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
            sprver =>
            {
                type     => 'int',
                optional => TRUE
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
        CHECKS => 
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
            ],
            match =>
            [
                {field => 'lstAcc',   exp => '^\d{5}$'},
                {field => 'lstCodes', exp => '^\d{6}$'}
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201, max => 99999}
            ]
        }
    },
    CHECK_47426N_EQUAL_47426 =>
    {  # сумма остатков по кодам 222222 по балансовому счету 47426, 474261, 474263 должна соответствовать остатку по 
       # балансовому счету 47426 на соответствующую дату
       FIELDS => 
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type    => 'date',        
                request => TRUE     
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type    => 'date',
                request => TRUE  
            },
            lstDep       => # список подразделений
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
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                array    => TRUE,
                optional => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
            },
            rowver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstDep',   exp => '^\d{4}$'}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['dep']}
            ]
        }
    },
    CHECK_47426_BY_32802 =>
    {  # выгрузка результатов сверки остаков счета 47426 c 32802
        FIELDS => 
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type    => 'date',        
                request => TRUE     
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type    => 'date',
                request => TRUE  
            },
            lstDep       => # список подразделений
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
            chkShowFields    => # поля которые дополнительно должны быть экспортированны
            {
                type     => 'str',
                array    => TRUE,
                optional => TRUE,
                request  => TRUE
            },
            sprver =>
            {
                type     => 'int',
                optional => TRUE
            },
            rowver =>
            {
                type     => 'int',
                optional => TRUE
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
                {field => 'lstDep',   exp => '^\d{4}$'}
            ],
            exactly =>
            [
                {field => 'chkShowFields',  values => ['dep']}
            ]
        }
    }
};

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    CORR_CLN =>
    { # параметры выгрузки атрибутов клиента
        title    => 'Редактирование атрибутов клиентов',
        html_template  => 'f136_admin_corr_cln.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
            GET_CLIENT_CLS =>
            {
                src     => 'SQL_GET_CURR_CLIENT_CLS',                                                       
                params  => []  
            },
            GET_CLIENT_RES =>
            {
                src    => 'SQL_GET_CURR_CLIENT_RES',                                                                               
                params => []  
            }
        },
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            select    =>
            [
                {field => 'cln_id'},
                {field => 'cln_src'},
                {field => 'cln_cls'},
                {field => 'cln_res'},
                {field => 'cln_desc'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src     => 'SQL_GET_CLIENTS',                                               
                params  =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'sprver'},
                    {field => 'lstAcc', options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
                ]  
            },
            where     =>
            {
                cln_cls => {in => 'lstCls'},
                cln_res => {in => 'chkRes'}                                            
            },
            group    =>
            [
                {field => 'cln_id'},
                {field => 'cln_src'},
                {field => 'cln_cls'},
                {field => 'cln_res'},
                {field => 'cln_desc'},
                {field => 'rowver'}        
            ],
            order    =>
            [                
                {field => 'cln_cls',  direction => 'asc'},
                {field => 'cln_res',  direction => 'asc'},
                {field => 'cln_desc', direction => 'asc'},
                {field => 'cln_src',  direction => 'asc'}
            ]
        },
        FIELDS    => # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического                 
        {   
            cln_id  =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1            # позиция поля при экспорте 
            },
            cln_src    => 
            {
                type    =>  'int',
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },
            cln_cls  => 
            {
                change  =>  1,           
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  3
            },
            cln_res  => 
            {
                change  =>  1,           
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  4
            },
            acc_msk  => 
            {
                skip    =>  1,
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  5
            },
            acc_lck  => 
            {
                skip    =>  1,
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  6
            },
            acc_nmb  => 
            {
                skip    =>  1,
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  7
            },
            cln_desc  => 
            {
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  8
            },
            acc_desc => 
            {
                skip    =>  1,           
                type    => 'txt',
                desc    => 'Описание счета',
                order   =>  9                                
            },
            rowver    => 
            {
                type    =>  'int',       
                desc    =>  'Версия',
                order   =>  10
            }
        }                    
    },
    CORR_SUM =>
    { # параметры выгрузки остатков на лицевых счетах
        title    => 'Редактирование остатков на счетах',
        html_template  => 'f136_admin_corr_sum.html', 
        DICTIONARIES   => 
        {
            GET_CODE => 
            {
                src    => 'SQL_GET_CURR_ACC',
                params => []  
            }
        },
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            select    =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'sum_src'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from =>
            {
                src    => 'SQL_GET_ACCSUMM',                                            
                params =>
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'sprver'},
                    {field => 'lstAcc',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstCodes', options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstAcc'},
                    {field => 'lstCodes', options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstCodes'},
                    {field => 'lstAcc',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}                                                   
                ]  
            },
            group =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'sum_src'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            order =>
            [
                {field => 'acc_nmb',    direction => 'asc'},
                {field => 'sum_code',   direction => 'asc'},
                {field => 'sum_ldate',  direction => 'asc'}
            ]
        },                 
        FIELDS    => 
        {   
            sum_aid =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            sum_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },        
            sum_bdt   => 
            { 
                key     =>  1,           
                type    =>  'date',
                desc    =>  'Дата проводки',
                order   =>  3
            },
            sum_acc   => 
            { 
                key     =>  1,           
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  4
            },                                                                                        
            sum_code   => 
            { 
                key     =>  1,           
                change  =>  1,
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  5
            },
            sum_ldate  =>
            { 
                type    =>  'date',
                desc    =>  'Левая граница',
                order   =>  6
            },                                        
            sum_rdate  =>
            { 
                type    =>  'date',
                desc    =>  'Правая граница',
                order   =>  7
            },                                        
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  8
            },
            sum_slc   => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Остаток',
                order   =>  9
            },                                  
            acc_msk => 
            {
                skip    =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  10
            },
            acc_lck => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  11
            },
            cln_res  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  12
            }, 
            cln_cls  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  13
            },
            acc_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  14
            },      
            cln_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  15
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  16
            }
        }                    
    },
    SHOW_CUR =>
    { # параметры выгрузки счетов по кодам валют
        title    => 'Просмотр счетов по кодам валют',
        html_template  => 'show_table_data.html', 
        DICTIONARIES   => 
        {},
        SQL       => # шаблон SQL на выборку записей                    
        {                        
            select    =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src     => 'SQL_GET_ACC_BY_CUR', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'sprver'},
                    {field => 'lstCur', options => {array => TRUE, wrap => "", spliter => ','}}
                ]
            },
            group =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            order =>
            [
                {field => 'sum_ldate',  direction => 'asc'},
                {field => 'sum_code',   direction => 'asc'},
                {field => 'acc_nmb',    direction => 'asc'}
            ]
        },       
        FIELDS    => 
        {   
            sum_aid =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            sum_bdt   => 
            { 
                key     =>  1,           
                type    =>  'date',
                desc    =>  'Дата проводки',
                order   =>  2
            },
            sum_acc   => 
            { 
                key     =>  1,           
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  3
            },                                                                                        
            sum_code   => 
            { 
                key     =>  1,           
                change  =>  1,
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            },
            sum_ldate  =>
            { 
                type    =>  'date',
                desc    =>  'Левая граница',
                order   =>  5
            },                                        
            sum_rdate  =>
            { 
                type    =>  'date',
                desc    =>  'Правая граница',
                order   =>  6
            }, 
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  8
            },
            sum_slc   => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Остаток',
                order   =>  9
            },                                  
            acc_msk => 
            {
                skip    =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  10
            },
            acc_lck => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  11
            },
            cln_res  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  12
            }, 
            cln_cls  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  13
            },
            acc_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  14
            },
            cln_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  15
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  16
            }            
        }
    },
    CORR_ACC =>
    { # параметры выгрузки атрибутов счетов
        title    => 'Редактирование атрибутов счетов',
        html_template  => 'f136_admin_corr_acc.html', 
        DICTIONARIES   => 
        {
            GET_ACCOUNT_MSK =>
            {
                src    => 'SQL_GET_CURR_ACCOUNT_MSK',
                params => []  
            }                    
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'acc_id'},
                {field => 'acc_src'},
                {field => 'acc_nmb'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_std'},
                {field => 'acc_mtd'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from =>
            {
                src    => 'SQL_GET_ACCOUNT',          
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'sprver'},
                    {field => 'lstAcc', options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
                ]  
            },
            group =>
            [
                {field => 'acc_id'},
                {field => 'acc_src'},
                {field => 'acc_nmb'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_std'},
                {field => 'acc_mtd'},
                {field => 'acc_desc'},
                {field => 'rowver'} 
            ],
            order =>
            [
                {field => 'acc_nmb',    direction => 'asc'}
            ]            
        }, 
        FIELDS    => 
        {   
            acc_id =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                                                                 
                order   =>  1
            },
            acc_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1,           # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                            value   => 'корр.',
                            type    => 'str',
                            style => {name=>'corr'},
                            attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                }
            },        
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  3
            },
            acc_code  =>  
            { 
                skip    =>  1,
                type    =>  'acc',
                desc    =>  'Назначенный код',
                order   =>  4
            },                                        
            acc_msk   => 
            {
                change  =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  5
            },
            acc_lck => 
            {
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  6
            },
            acc_std => 
            {
                change  =>  1,   
                type    =>  'date',
                desc    =>  'Дата начала сделки',
                order   =>  7
            },
            acc_mtd => 
            {
                change  =>  1,   
                type    =>  'date',
                desc    =>  'Дата окончания сделки',
                order   =>  8
            },
            cln_res  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  10
            }, 
            cln_cls  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  11
            },
            acc_desc => 
            {
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  12
            },                  
            cln_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  13
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  14
            }
        }                 
    },
    CORR_COD =>
    { # параметры выгрузки лицевых счетов по коду
        title     => 'Список лицевых счетов участвующих в расчете кода (кодов)',
        html_template   => 'f136_admin_corr_cod.html', 
        DICTIONARIES    => 
        {
            GET_CODE => 
            {
                src     => 'SQL_GET_CURR_ACC',
                params  => []  
            }
        },
        SQL     => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_date'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'sum_src'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],            
            from  =>
            {
                src    => 'SQL_GET_CODESUMM',                                             
                params =>
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'}, 
                    {field => 'sprver'}, 
                    {field => 'lstAcc',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstAcc'},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstCodes'},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
                ]
            },
            group =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_date'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'sum_src'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            order =>
            [
                {field => 'sum_date',   direction => 'asc'},
                {field => 'sum_code',   direction => 'asc'},
                {field => 'acc_nmb',    direction => 'asc'}
            ]
        },                 
        FIELDS    => 
        {   
            sum_aid =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            sum_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },
            sum_bdt   => 
            { 
                key     =>  1,           
                #skip    =>  1,
                hide    => 1,
                type    =>  'date',
                desc    =>  'Дата проводки',
                order   =>  3
            },
            sum_acc   => 
            { 
                key     =>  1,           
                hide    => 1,
                #skip    =>  1,
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  4
            },                                                                                        
            sum_code   => 
            { 
                key     =>  1,           
                change  =>  1,
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  5
            },
            sum_date  =>
            { 
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  6
            },                                        
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  7
            },
            sum_slc   => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Остаток',
                order   =>  8
            },                                  
            acc_msk => 
            {
                skip    =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  9
            },
            acc_lck => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  10
            },
            cln_res  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  11
            }, 
            cln_cls  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  12
            },
            acc_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  13
            },      
            cln_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  14
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  15
            }
        }
    },
    CORR_BAL =>
    {
        title    => 'Редактирование остатков по счетам и кодам используемым при расчете 136 формы',
        html_template  => 'f136_admin_corr_bal.html',
        DICTIONARIES   => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'date'},
                {field => 'acc'},
                {field => 'code'},
                {field => 'name'},
                {field => 'dep'},
                {field => 'bal_src'},
                {field => 'bal_r'},
                {field => 'bal_v'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src     => 'SQL_CORR_BALANCE', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},
                    {field => 'sprver'},
                    {field => 'sprver'},
                    {field => 'lstAcc'},
                    {field => 'lstCodes'},
                    {field => 'lstCodes'},
                    {field => 'lstDep'},
                    {field => 'lstDep'},
                    {field => 'chkShowNull'}
                ]
            },
            order =>
            [
                {field => 'date',   direction => 'asc'},
                {field => 'acc',    direction => 'asc'},
                {field => 'code',   direction => 'asc'},
                {field => 'name',   direction => 'asc'},
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            bal_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  1,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },                                        
            date     => 
            { 
                key     =>  1,
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  2
            },
            dep  => 
            {
                key     =>  1,           
                hide    =>  1,
                type    =>  'str',       
                desc    =>  'ID подразделения',
                order   =>  3
            },
            name  => 
            {
                type    =>  'str',       
                desc    =>  'Подразделение',
                order   =>  3
            },
            code    =>
            {
                key     =>  1,           # признак поля как ключевого
                type    =>  'acc',       # тип поля
                desc    =>  'Код',       # описание поля                                                 
                order   =>  4
            },
            acc      => 
            {
                key     =>  1,           
                type    =>  'acc',       
                desc    =>  'Счет',
                order   =>  5
            },                                             
            bal_r => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Рублевый остаток',
                order   =>  6
            },
            bal_v => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Валютный остаток',
                order   =>  7
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  8
            }
        }
    },                                
    ONLY_CORR_CLN =>
    { # параметры выгрузки атрибутов клиента
        title    => 'Коррекции атрибутов клиентов',
        html_template  => 'f136_admin_corr_cln.html', # файл шаблона страницы
        DICTIONARIES   => # список дополнительных словарей
        {
            GET_CLIENT_CLS =>
            {
                src    => 'SQL_GET_CURR_CLIENT_CLS',          
                params => []  
            },
            GET_CLIENT_RES =>
            {
                src    => 'SQL_GET_CURR_CLIENT_RES',                                                                               
                params => []  
            }
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'cln_id'},
                {field => 'cln_src'},
                {field => 'cln_cls'},
                {field => 'cln_res'},
                {field => 'cln_desc'},
                {field => 'rowver'}
            ], 
            from     =>
            {
                src    => 'SQL_GET_CORR_CLIENTS',                                                 
                params => []  
            },
            where     =>
            {
                cln_cls => {in => 'lstCls'},
                cln_res => {in => 'chkRes'}                                            
            },
            order =>
            [
                {field => 'cln_src',    direction => 'asc'},
                {field => 'cln_cls',    direction => 'asc'},
                {field => 'cln_res',    direction => 'asc'},
                {field => 'cln_desc',   direction => 'asc'}
            ]
        },   
        FIELDS    => # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического                 
        {   
            cln_id   =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1            # позиция поля при экспорте 
            },
            cln_src    => 
            {
                type    =>  'int',
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },
            cln_cls  => 
            {
                change  =>  1,           
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  3
            },
            cln_res  => 
            {
                change  =>  1,           
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  4
            },
            cln_desc  => 
            {
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  5
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  6
            }
        }                    
    },
    ONLY_CORR_SUM =>
    { # параметры выгрузки остатков на лицевых счетах
        title    => 'Коррекции остатков на счетах',
        html_template  => 'f136_admin_corr_sum.html',                     
        DICTIONARIES   => 
        {
            GET_CODE => 
            {
                src    => 'SQL_GET_CURR_ACC',
                params => []  
            }
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'sum_src'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src    => 'SQL_GET_CORR_ACCSUMM',
                params => []  
            },
            order =>
            [
                {field => 'sum_code',   direction => 'asc'},
                {field => 'acc_nmb',    direction => 'asc'}
            ]
        },                 
        FIELDS    => 
        {   
            sum_aid =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            sum_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                } 
            },        
            sum_bdt   => 
            { 
                key     =>  1,           
                type    =>  'date',
                desc    =>  'Дата проводки',
                order   =>  3
            },
            sum_acc   => 
            { 
                key     =>  1,           
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  4
            },                                                                                        
            sum_code   => 
            { 
                key     =>  1,           
                change  =>  1,
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  5
            },
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  6
            },
            sum_slc   => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Остаток',
                order   =>  7
            },
            acc_desc => 
            {
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  8
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  9
            } 
        }
    },
    ONLY_CORR_ACC =>
    { # параметры выгрузки атрибутов счетов
        title    => 'Коррекции атрибутов счетов',
        html_template  => 'f136_admin_corr_acc.html', 
        DICTIONARIES => 
        {
            GET_ACCOUNT_MSK =>
            {
                src     => 'SQL_GET_CURR_ACCOUNT_MSK',
                params  => []  
            }                    
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'acc_id'},
                {field => 'acc_src'},
                {field => 'acc_nmb'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_std'},
                {field => 'acc_mtd'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src    => 'SQL_GET_CORR_ACCOUNT',
                params => []  
            },            
            order =>
            [
                {field => 'acc_nmb',    direction => 'asc'}, 
            ]
        }, 
        FIELDS   => 
        {   
            acc_id =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            acc_src      => 
            {
                type    =>  'int',       
                desc    =>  'Источник',
                button  =>  1, # признак того, что поле кнопка-статус
                order   =>  2,
                to_row  =>  'src', # установить свойство строки при выводе в HTML
                # задает действие взависимости от значения
                trigger     =>
                {
                    0 =>
                    {
                        value   => 'ориг.',
                        type    => 'str',
                        style => {name=>'orig'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    },
                    1 =>
                    {
                        value   => 'корр.',
                        type    => 'str',
                        style => {name=>'corr'},
                        attribute => 'onclick=\'ShowDialog(this.parentNode);\''
                    }
                }                                                 
            },        
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  3
            },
            acc_code  =>  
            { 
                skip    =>  1,
                type    =>  'acc',
                desc    =>  'Назначенный код',
                order   =>  4
            },                                        
            acc_msk   => 
            {
                change  =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  5
            },
            acc_lck => 
            {
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  6
            },
            acc_std => 
            {
                change  =>  1,   
                type    =>  'date',
                desc    =>  'Дата начала сделки',
                order   =>  7
            },
            acc_mtd => 
            {
                change  =>  1,   
                type    =>  'date',
                desc    =>  'Дата окончания сделки',
                order   =>  8
            },
            acc_desc => 
            {
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  9
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  10
            }                                  
        }                 
    },
    SHOW_COD =>
    {
        title    => 'Просмотор расчета кодов',
        html_template  => 'show_table_data.html',
        DICTIONARIES   => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'date'},
                {field => 'acc'},
                {field => 'code'},
                {field => 'bal_r'},
                {field => 'bal_v'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src    => 'SQL_GET_CALC_CODES', 
                params =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'lstCodes', options => {array => TRUE, wrap => "'", type => 'int', spliter => ' '}}
                ]
            },
            group =>
            [
                {field => 'date'},
                {field => 'acc'},
                {field => 'code'},
                {field => 'bal_r'},
                {field => 'bal_v'},
                {field => 'rowver'}
            ],
            order =>
            [
                {field => 'code',   direction => 'asc'}, 
                {field => 'date',   direction => 'asc'},
                {field => 'acc',    direction => 'asc'}                
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            code    =>
            {
                type    =>  'acc',       # тип поля
                desc    =>  'Код',       # описание поля                                                 
                order   =>  1
            },
            acc      => 
            {
                type    =>  'acc',       
                desc    =>  'Счет',
                order   =>  2
            },        
            date     => 
            { 
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  3
            },
            bal_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток',
                order   =>  4
            },
            bal_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток',
                order   =>  5
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  6
            }
        }                       
    },
    SHOW_BAL =>
    {
        title    => 'Просмотр остатков по счетам и кодам используемым при расчете 136 формы',
        html_template  => 'show_table_data.html',
        DICTIONARIES   => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'date'},
                {field => 'bal_r',  func => 'sum', alias => 'bal_r'},
                {field => 'bal_v',  func => 'sum', alias => 'bal_v'}
            ],
            from     =>
            {
                src    => 'SQL_SHOW_BALANCE', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},
                    {field => 'rowver'},
                    {field => 'sprver'},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstCodes'},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},                                                    
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => '', spliter => ','}}
                ]
            },
            group =>
            [
                {field => 'rowver'},
                {field => 'date'},
            ],
            order =>
            [
                {field => 'date',   direction => 'asc'}, 
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            date     => 
            { 
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  1
            },
            bal_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток',
                order   =>  2
            },
            bal_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток',
                order   =>  3
            },
            code    =>
            {
                skip    =>  1,           # если значение отлично от нуля то поле будет участвовать в запросе, если ноль то опционально
                type    =>  'acc',       # тип поля
                desc    =>  'Код',       # описание поля                                                 
                order   =>  4
            },
            acc      => 
            {
                skip    =>  1,
                type    =>  'acc',       
                desc    =>  'Счет',
                order   =>  5
            }, 
            dep       => 
            {
                skip    =>  1,
                type    =>  'str',       
                desc    =>  'Подразделение',
                order   =>  6
            },
            rowver    => 
            {
                type    =>  'int',       
                desc    =>  'Версия',
                order   =>  7
            }
        }                       
    },
    SHOW_SUM =>
    {
        title    => 'Просмотр остатков на лицевых счетах',
        html_template  => 'show_table_data.html',
        DICTIONARIES => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            from     =>
            {
                src     => 'SQL_SHOW_ACCSUM', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'edtDateLeft'},
                    {field => 'edtDateRight'},
                    {field => 'sprver'},
                    {field => 'lstAcc', options => {array => TRUE, wrap => "", spliter => ','}}
                ]
            },
            group =>
            [
                {field => 'sum_bdt'},
                {field => 'sum_ldate'},
                {field => 'sum_rdate'},
                {field => 'sum_code'},
                {field => 'sum_aid'},
                {field => 'sum_acc'},
                {field => 'acc_nmb'},
                {field => 'sum_slc'},
                {field => 'acc_msk'},
                {field => 'acc_lck'},
                {field => 'acc_desc'},
                {field => 'rowver'}
            ],
            order =>
            [
                {field => 'sum_ldate',  direction => 'asc'},
                {field => 'sum_code',   direction => 'asc'},
                {field => 'acc_nmb',    direction => 'asc'}
            ]
        },       
        FIELDS    => 
        {   
            sum_aid =>
            {
                hide    =>  1,           # признак того, что поле не отображается
                key     =>  1,           # признак поля как ключевого
                type    =>  'int',       # тип поля
                desc    =>  'ID',        # описание поля                                                 
                order   =>  1
            },
            sum_bdt   => 
            { 
                key     =>  1,           
                type    =>  'date',
                desc    =>  'Дата проводки',
                order   =>  2
            },
            sum_acc   => 
            { 
                key     =>  1,           
                type    =>  'acc',
                desc    =>  'Счет 2-го порядка',
                order   =>  3
            },                                                                                        
            sum_code   => 
            { 
                key     =>  1,           
                change  =>  1,
                type    =>  'acc',
                desc    =>  'Код',
                order   =>  4
            },
            sum_ldate  =>
            { 
                type    =>  'date',
                desc    =>  'Левая граница',
                order   =>  5
            },                                        
            sum_rdate  =>
            { 
                type    =>  'date',
                desc    =>  'Правая граница',
                order   =>  6
            }, 
            acc_nmb   => 
            { 
                type    =>  'acc',
                desc    =>  'Счет',
                order   =>  8
            },
            sum_slc   => 
            {
                change  =>  1,
                type    =>  'mny',
                desc    =>  'Остаток',
                order   =>  9
            },                                  
            acc_msk => 
            {
                skip    =>  1,   
                type    =>  'long',
                desc    =>  'Маска счета',
                order   =>  10
            },
            acc_lck => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Состояние',
                order   =>  11
            },
            cln_res  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Резидент',
                order   =>  12
            }, 
            cln_cls  => 
            {
                skip    =>  1,   
                type    =>  'int',
                desc    =>  'Класс',
                order   =>  13
            },
            acc_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание счета',
                order   =>  14
            },
            cln_desc => 
            {
                skip    =>  1,   
                type    =>  'txt',
                desc    =>  'Описание клиента',
                order   =>  15
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  16
            }            
        }     
    },
    SETT_USE_ACC =>
    { # параметры выгрузки счетов участвующих в расчете страхового взноса
        title    => 'Счета, участвующие в расчете страхового взноса',
        html_template  => 'show_table_data.html', 
        DICTIONARIES   => {},
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'acc'},
                {field => 'note'},
                {field => 'edt_cln'},
                {field => 'edt_acc'},
                {field => 'edt_sum'},
                {field => 'see_sum'},
                {field => 'code'}
            ],
            from     =>
            {
                src    => 'SQL_GET_SETT_USE_ACC',
                params =>
                [
                    {field => 'lstCodes'},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstAcc'},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
                ]  
            },
            order =>
            [
                {field => 'acc',    direction => 'asc'},
                {field => 'code',   direction => 'asc'}
            ]
        }, 
        FIELDS    => 
        {   
            acc =>
            {
                type    =>  'acc',      
                desc    =>  'Счет',                   
                order   =>  1
            },
            code =>
            {
                type    =>  'acc',      
                desc    =>  'Код',   
                order   =>  2
            },                                                           
            edt_cln =>
            {
                type    =>  'chr',      
                desc    =>  'Изм. Атр. клиентов',   
                order   =>  3
            },
            edt_acc =>
            {
                type    =>  'chr',      
                desc    =>  'Изм. Атр. счетов',   
                order   =>  4
            },
            edt_sum =>
            {
                type    =>  'chr',      
                desc    =>  'Изм. ост. по счету',   
                order   =>  5
            },
            see_sum =>
            {
                type    =>  'chr',      
                desc    =>  'Прос. ост. по счету',   
                order   =>  6
            },
            note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание',   
                order   =>  7
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  8
            }
        }                 
    },                
    SETT_KLIKO => 
    { # параметры выгрузки параметров представления в Kliko
        title    => 'Параметры представления в формате ПО "Kliko"',
        html_template  => 'show_table_data.html', 
        DICTIONARIES   => {},
        SQL       => # шаблон SQL на выборку записей                    
        {
                                                                     # список полей таблицы в БД, заданой в table{src}   
            select    =>
            [
                {field => 'rowver'},
                {field => 'app_name'},
                {field => 'position'},
                {field => 'note'},
                {field => 'oper'},
                {field => 'sub_row'},
                {field => 'type'},
                {field => 'show_num'},
                {field => 'show_note'},
                {field => 'show_rub'},
                {field => 'show_cur'}
            ], 
            from     =>
            {
                src    => 'SQL_GET_SETT_KLIKO',
                params  => []  
            },
            order =>
            [
                {field => 'position',   direction => 'asc'} 
            ]
        }, 
        FIELDS    => 
        {   
            app_name =>
            {
                type    =>  'str',      
                desc    =>  'Приложение',   
                order   =>  1
            },
            position =>
            {
                type    =>  'int',      
                desc    =>  'Позиция',   
                order   =>  2
            },
            note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание',   
                order   =>  3
            },                                            
            oper =>
            {
                type    =>  'str',      
                desc    =>  'Операция',   
                order   =>  4
            },
            sub_row =>
            {
                type    =>  'int',      
                desc    =>  'Номер формулы',   
                order   =>  5
            },
            type =>
            {
                type    =>  'str',      
                desc    =>  'Тип строки',   
                order   =>  6
            },
            show_num =>
            {
                type    =>  'chr',      
                desc    =>  'Номер строки',   
                order   =>  7
            },
            show_note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание строки',   
                order   =>  8
            },
            show_rub =>
            {
                type    =>  'chr',      
                desc    =>  'Руб. остаток',   
                order   =>  9
            },
            show_cur =>
            {
                type    =>  'chr',      
                desc    =>  'Вал. остаток',   
                order   =>  10
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  11
            }
        }                 
    },                
    SETT_HTML => 
    { # параметры выгрузки параметров представления в HTML
        title    => 'Параметры представления формы в HTML формате',
        html_template  => 'show_table_data.html', 
        DICTIONARIES   => 
        {
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'app_name'},
                {field => 'position'},
                {field => 'note'},
                {field => 'oper'},
                {field => 'sub_row'},
                {field => 'type'},
                {field => 'show_num'},
                {field => 'show_note'},
                {field => 'show_rub'},
                {field => 'show_cur'}
            ], 
            from     =>
            {
                src    => 'SQL_GET_SETT_HTML',    
                params => []  
            },
            order =>
            [
                {field => 'position',   direction => 'asc'} 
            ]
        }, 
        FIELDS    => 
        {   
            app_name =>
            {
                type    =>  'str',      
                desc    =>  'Приложение',   
                order   =>  2
            },
            position =>
            {
                type    =>  'int',      
                desc    =>  'Позиция',   
                order   =>  3
            },
            note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание',   
                order   =>  4
            },                                            
            oper =>
            {
                type    =>  'str',      
                desc    =>  'Операция',   
                order   =>  5
            },
            sub_row =>
            {
                type    =>  'int',      
                desc    =>  'Номер формулы',   
                order   =>  6
            },
            type =>
            {
                type    =>  'str',      
                desc    =>  'Тип строки',   
                order   =>  7
            },
            show_num =>
            {
                type    =>  'chr',      
                desc    =>  'Номер строки',   
                order   =>  8
            },
            show_note =>
            {
                type    =>  'chr',      
                desc    =>  'Описание строки',   
                order   =>  9
            },
            show_rub =>
            {
                type    =>  'chr',      
                desc    =>  'Руб. остаток',   
                order   =>  10
            },
            show_cur =>
            {
                type    =>  'chr',      
                desc    =>  'Вал. остаток',   
                order   =>  11
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  12
            }
        }                 
    },
    SETT_RESERVE => 
    { # параметры выгрузки параметров представления в ПО Reserve
        title    => 'Параметры представления в формате ПО "Резерв"',
        html_template  => 'show_table_data.html', 
        DICTIONARIES => 
        {
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'app_name'},
                {field => 'position'},
                {field => 'note'},
                {field => 'oper'},
                {field => 'sub_row'},
                {field => 'type'},
                {field => 'show_num'},
                {field => 'show_note'},
                {field => 'show_rub'},
                {field => 'show_cur'}
            ],
            from     =>
            {
                src    => 'SQL_GET_SETT_HTML',
                params => []  
            },
            order =>
            [
                {field => 'position',   direction => 'asc'}  
            ]
        }, 
        FIELDS    => 
        {   
            app_name =>
            {
                type    =>  'str',      
                desc    =>  'Приложение',   
                order   =>  2
            },
            position =>
            {
                type    =>  'int',      
                desc    =>  'Позиция',   
                order   =>  3
            },
            note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание',   
                order   =>  4
            },                                            
            oper =>
            {
                type    =>  'str',      
                desc    =>  'Операция',   
                order   =>  5
            },
            sub_row =>
            {
                type    =>  'int',      
                desc    =>  'Номер формулы',   
                order   =>  6
            },
            type =>
            {
                type    =>  'str',      
                desc    =>  'Тип строки',   
                order   =>  7
            },
            show_num =>
            {
                type    =>  'chr',      
                desc    =>  'Номер строки',   
                order   =>  8
            },
            show_note =>
            {
                type    =>  'chr',      
                desc    =>  'Руб. остаток',   
                order   =>  10
            },
            show_cur =>
            {
                type    =>  'chr',      
                desc    =>  'Вал. остаток',   
                order   =>  11
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  12
            }                 
        }                 
    },
    SETT_FORMULAS => 
    { # параметры выгрузки параметров формул расчета
        title    => 'Формулы расчета',
        html_template  => 'show_table_data.html', 
        DICTIONARIES   => 
        {
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'app'},
                {field => 'num'},
                {field => 'sub_row'},
                {field => 'chk_sub_row'},
                {field => 'chk_oper'},
                {field => 'coeff_r'},
                {field => 'coeff_v'},
                {field => 'type'},
                {field => 'code'},
                {field => 'acc'},
                {field => 'bal_oper'},
                {field => 'bal_note'},
                {field => 'agg_app_name'},
                {field => 'agg_num'},
                {field => 'agg_oper'},
                {field => 'agg_note'},
                {field => 'bal_r'},
                {field => 'bal_v'},
                {field => 'ddate'},
                {field => 'set_bal_r'},
                {field => 'set_bal_v'},
                {field => 'position'},
                {field => 'format'},
                {field => 'rowver'}
            ],
            from  =>
            {
                src    => 'SQL_GET_SETT_FORMULAS', 
                params  => []  
            },
            order =>
            [
                {field => 'app',   direction => 'asc'}, 
                {field => 'num',   direction => 'asc'}, 
                {field => 'position',   direction => 'asc'}, 
                {field => 'acc',   direction => 'asc'}, 
                {field => 'code',   direction => 'asc'}        
            ]            
        }, 
        FIELDS    => 
        {   
            app =>
            {
                type    =>  'int',      
                desc    =>  'Номер приложения',   
                order   =>  1
            },
            num =>
            {
                type    =>  'str',      
                desc    =>  'Номер строки',   
                order   =>  2
            },
            sub_row =>
            {
                type    =>  'int',      
                desc    =>  'Номер формулы',   
                order   =>  3
            },
            chk_sub_row =>
            {
                type    =>  'int',      
                desc    =>  'Связанная формула',   
                order   =>  4
            },               
            chk_oper =>
            {
                type    =>  'str',      
                desc    =>  'Связанная операция',   
                order   =>  5
            },               
            coeff_r =>
            {
                type    =>  'str',      
                desc    =>  'Рублевый коэффициент',   
                order   =>  6
            },              
            coeff_v =>
            {
                type    =>  'str',      
                desc    =>  'Валютный коэффициент',   
                order   =>  7
            },
            type =>
            {
                type    =>  'str',      
                desc    =>  'Тип строки',   
                order   =>  8
            },
            code =>
            {
                type    =>  'acc',      
                desc    =>  'Код',   
                order   =>  9
            },
            acc =>
            {
                type    =>  'acc',      
                desc    =>  'Счет 2-го порядка',   
                order   =>  10
            },
            bal_oper =>
            {
                type    =>  'acc',      
                desc    =>  'Операция над остатком',   
                order   =>  11
            },
            bal_note =>
            {
                type    =>  'str',      
                desc    =>  'Описание операции над остатком',   
                order   =>  12
            },
            agg_app_name =>
            {
                type    =>  'acc',      
                desc    =>  'Приложение агрегата',   
                order   =>  13
            },
            agg_num =>
            {
                type    =>  'acc',      
                desc    =>  'Номер строки агрегата',   
                order   =>  14
            },
            agg_oper =>
            {
                type    =>  'acc',      
                desc    =>  'Операция над агрегатом',   
                order   =>  15
            },       
            agg_note =>
            {
                type    =>  'str',      
                desc    =>  'Описание операции над агрегатом',   
                order   =>  16
            },
            bal_r =>
            {
                type    =>  'chr',      
                desc    =>  'Рублёвое значение',   
                order   =>  17
            },
            bal_v =>
            {
                type    =>  'chr',      
                desc    =>  'Валютное значение',   
                order   =>  18
            },
            ddate =>
            {
                type    =>  'int',      
                desc    =>  'Дельта к дате',   
                order   =>  19
            },               
            set_bal_r =>
            {
                type    =>  'mny',      
                desc    =>  'Фиксированное рублевое значение',   
                order   =>  20
            },               
            set_bal_v =>
            {
                type    =>  'mny',      
                desc    =>  'Фиксированное валютное значение',   
                order   =>  21
            },               
            format =>
            {
                type    =>  'int',      
                desc    =>  'Формат',   
                order   =>  22
            },                
            position =>
            {
                type    =>  'int',      
                desc    =>  'Позиция',   
                hide    =>  1,
                order   =>  23
            },                
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  24
            }
        }                 
    },
    SETT_PERMISSIONS_ACC =>
    { # параметры выгрузки разрешений
        title    => 'Список кодов и счетов',
        html_template  => 'f136_admin_edit_permis_acc.html', 
        DICTIONARIES   => 
        {
            GET_SETTINGS =>
            {
                src    => 'SQL_GET_F136_SETTINGS',
                params => []  
            }                    
        },
        SQL       => # шаблон SQL на выборку записей                    
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'acc'},
                {field => 'note'},
                {field => 'code'},
                {field => 'cando'}
            ], 
            from     =>
            {
                src    => 'SQL_GET_SETT_USE_ACC',     # имя источника (хранится во внешнем источнике)
                params =>
                [
                    {field => 'lstCodes'},
                    {field => 'lstCodes',   options => {array => TRUE, type => 'str', wrap => '', spliter => ','}},
                    {field => 'lstAcc'},
                    {field => 'lstAcc',     options => {array => TRUE, type => 'str', wrap => '', spliter => ','}}
                ]  
            },
            order =>
            [
                {field => 'acc',    direction => 'asc'},
                {field => 'code',   direction => 'asc'}
            ]
        }, 
        FIELDS    => 
        {   
            code =>
            {
                type      =>  'acc',      
                desc      =>  'Код',   
                button    =>  1, # признак того, что поле кнопка-статус
                key       =>  1,
                order     =>  1,                
                style     =>  {name=>'orig'},
                attribute => 'onclick=\'ShowDialog(this.parentNode);\''
            },                                                           
            acc =>
            {
                type    =>  'acc',      
                desc    =>  'Счет 2-го порядка',   
                key     =>  1,
                order   =>  2
            },
            cando =>
            {
                type    =>  'int',      
                desc    =>  'Маска разрешений',   
                order   =>  3,
                change  =>  1
            },
            note =>
            {
                type    =>  'txt',      
                desc    =>  'Описание',   
                order   =>  4
            },
            rowver =>
            {
                type    =>  'int',       # тип поля
                desc    =>  'Версия',    # описание поля                                                 
                order   =>  5
            }
        }                 
    },
    CHECK_47426_BY_32802 =>
    {
        title    => 'Просмотр результатов сверки счета 47426 по 32802',
        html_template  => 'show_table_data.html',
        DICTIONARIES   => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'date'},
                {field => 'delta_r',  func => 'sum', alias => 'delta_r'},
                {field => 'delta_v',  func => 'sum', alias => 'delta_v'},
                {field => 'b32802_r',  func => 'sum', alias => 'b32802_r'},
                {field => 'b47426_r',  func => 'sum', alias => 'b47426_r'},
                {field => 'b32802_v',  func => 'sum', alias => 'b32802_v'},
                {field => 'b47426_v',  func => 'sum', alias => 'b47426_v'}
            ],
            from     =>
            {
                src    => 'SQL_CHECK_47426_BY_32802', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'rowver'},
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}},

                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}},

                    {field => 'rowver'},
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}}
                ]
            },
            group =>
            [
                {field => 'rowver'},
                {field => 'date'}
            ],
            order =>
            [
                {field => 'date',   direction => 'asc'}
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            date     => 
            { 
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  1
            },
            dep       => 
            {
                skip    =>  1,
                type    =>  'str',       
                desc    =>  'Подразделение',
                order   =>  2,
                style   => {align=>'center'}
            },
            delta_r => 
            {
                type    =>  'mny',
                desc    =>  'Делта рублевого остатка',
                order   =>  3,
                style   => {width=>'150'}
            },
            delta_v => 
            {
                type    =>  'mny',
                desc    =>  'Делта валютного остатка',
                order   =>  4,
                style   => {width=>'150'}
            },

            b32802_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по 32802',
                order   =>  5,
                style   => {width=>'150'}
            },
            b47426_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по 47426',
                order   =>  6,
                style   => {width=>'150'}
            },
            b32802_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по 32802',
                order   =>  7,
                style   => {width=>'150'}
            },
            b47426_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по 47426',
                order   =>  8 ,
                style   => {width=>'150'}
            },
            rowver    => 
            {
                type    =>  'int',       
                desc    =>  'Версия',
                order   =>  9
            }
        }                       
    },
    CHECK_47426N_EQUAL_47426 =>
    {
        title    => 'Просмотр результатов сверки суммы остатков по коду 222222 счета 47426, 474261 и 474263 остатку по балансовому счету 47426',
        html_template  => 'show_table_data.html',
        DICTIONARIES   => {},
        SQL       =>
        {
            select    =>
            [
                {field => 'rowver'},
                {field => 'date'},
                {field => 'delta_r',  func => 'sum', alias => 'delta_r'},
                {field => 'delta_v',  func => 'sum', alias => 'delta_v'},
                
                {field => 'b474261_r',  func => 'sum', alias => 'b474261_r'},
                {field => 'b474261_v',  func => 'sum', alias => 'b474261_v'},

                {field => 'b474263_r',  func => 'sum', alias => 'b474263_r'},
                {field => 'b474263_v',  func => 'sum', alias => 'b474263_v'},

                {field => 'b222222_r',  func => 'sum', alias => 'b222222_r'},
                {field => 'b222222_v',  func => 'sum', alias => 'b222222_v'},

                {field => 'b47426_r',  func => 'sum', alias => 'b47426_r'},
                {field => 'b47426_v',  func => 'sum', alias => 'b47426_v'}
            ],
            from     =>
            {
                src    => 'SQL_CHECK_47426N_EQUAL_47426', # имя источника хранится во внешнем источнике
                params  =>
                [
                    {field => 'rowver'},
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}},

                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}},

                    {field => 'rowver'},
                    {field => 'edtDateLeft'}, 
                    {field => 'edtDateRight'},                    
                    {field => 'sprver'},
                    {field => 'lstDep'},
                    {field => 'lstDep',     options => {array => TRUE, wrap => "'", type => 'unk', spliter => ' '}}
                ]
            },
            group =>
            [
                {field => 'rowver'},
                {field => 'date'}
            ],
            order =>
            [
                {field => 'date',   direction => 'asc'}
            ]
        },                    
        FIELDS    =>                            # все поля источника коррекций, ключ хеша это имя поля используемое в CGI, может отличаится от физического
        {   
            date     => 
            { 
                type    =>  'date',
                desc    =>  'Дата',
                order   =>  1
            },
            dep       => 
            {
                skip    =>  1,
                type    =>  'str',       
                desc    =>  'Подразделение',
                order   =>  2,
                style   => {align=>'center'}
            },
            delta_r => 
            {
                type    =>  'mny',
                desc    =>  'Делта рублевого остатка',
                order   =>  3,
                style   => {width=>'150'}
            },
            delta_v => 
            {
                type    =>  'mny',
                desc    =>  'Делта валютного остатка',
                order   =>  4,
                style   => {width=>'150'}
            },

            b222222_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по коду 222222',
                order   =>  5,
                style   => {width=>'170'}
            },
            b222222_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по коду 222222',
                order   =>  6,
                style   => {width=>'170'}
            },

            b474261_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по коду 474261',
                order   =>  7,
                style   => {width=>'170'}
            },
            b474261_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по коду 474261',
                order   =>  8,
                style   => {width=>'170'}
            },

            b474263_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по коду 474263',
                order   =>  9,
                style   => {width=>'170'}
            },
            b474263_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по коду 474263',
                order   =>  10,
                style   => {width=>'170'}
            },


            b47426_r => 
            {
                type    =>  'mny',
                desc    =>  'Рублевый остаток по счету 47426',
                order   =>  11,
                style   => {width=>'170'}
            },
            b47426_v => 
            {
                type    =>  'mny',
                desc    =>  'Валютный остаток по счету 47426',
                order   =>  12,
                style   => {width=>'170'}
            },
            rowver    => 
            {
                type    =>  'int',       
                desc    =>  'Версия',
                order   =>  13
            }
        }                       
    }

};

use constant SUPPORT_FORMATS =>
{
    html    => sub {new F136::RpgAdmExportCorrToHtml(@_);},
    excel   => sub {new F136::RpgAdmExportCorrToExcel(@_);}
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
