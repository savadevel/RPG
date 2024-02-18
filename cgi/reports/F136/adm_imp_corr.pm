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

package F136::RpgAdmImportCorr;

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
use sql_make;

use F136::adm_imp_corr_html;
use F136::adm_imp_baln;          
use F136::adm_upd_settings;
use F136::page_adm; 

use exp_to_html;
use exp_to_excel;

use constant CGI_DESC =>  # содержит поля запроса, по ним делаем его валидацию
{
    CORR_CLN => # корректировка атрибутов клиентов
    { # параметры запроса на изменение атрибутов клиента
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            cmdDel  =>
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE          
            },
            cmdUpd  => 
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
            pack => # cmdUpd=cln_id:71012;cln_cls:2002;cln_res:1;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            cln_id =>
                            {
                                type => 'int' 
                            },
                            cln_cls =>
                            {
                                type => 'int' 
                            },
                            cln_res =>
                            {
                                type => 'bool' 
                            }                            
                        }
                    }
                },
                {
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            cln_id =>
                            {
                                type => 'int' 
                            },
                            cln_cls =>
                            {
                                type => 'int' 
                            },
                            cln_res =>
                            {
                                type => 'bool' 
                            }                            
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]            
        }                
    },
    CORR_SUM => # корректировка остатков на счетах клиентов
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
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
            cmdUpd  => 
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
            pack => # cmdIns=sum_aid:1339406;sum_bdt:29.04.2005;sum_acc:47407;sum_code:111111;sum_slc:8194325.00;
            [
                {
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
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
    CORR_ACC => 
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
            {
                type        => 'str',        # тип данных
                array       => TRUE,
                optional    => TRUE          # если определенно то объект опциональный
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
                {   # cmdUpd=acc_id:137296;acc_msk:52;acc_std:30.04.2005;acc_mtd:09.01.2007;
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            acc_id =>
                            {
                                type => 'int' 
                            },
                            acc_msk =>
                            {
                                type => 'long' 
                            },
                            acc_std =>
                            {
                                type => 'date' 
                            },
                            acc_mtd =>
                            {
                                type => 'date' 
                            }                                                        
                        },
                        checks =>
                        {
                            compare =>
                            [
                                {cmp => 'ge', fields => ['acc_mtd', 'acc_std'], value => 0, oper => '-'} 
                            ],
                            match =>
                            [
                                {field => 'acc_msk',   exp => '^\d*$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {   # cmdDel=acc_id:137296;acc_msk:52;acc_std:30.04.2005;acc_mtd:09.01.2007;
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            acc_id =>
                            {
                                type => 'int' 
                            },
                            acc_msk =>
                            {
                                type => 'long' 
                            },
                            acc_std =>
                            {
                                type => 'date' 
                            },
                            acc_mtd =>
                            {
                                type => 'date' 
                            }                                                        
                        },
                        checks =>
                        {
                            compare =>
                            [
                                {cmp => 'ge', fields => ['acc_mtd', 'acc_std'], value => 0, oper => '-'} 
                            ],
                            match =>
                            [
                                {field => 'acc_msk',   exp => '^\d*$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                }            
            ],
            count =>
            [
                {fields => ['cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]                     
        }                                 
    },
    ONLY_CORR_CLN => # корректировка атрибутов клиентов
    { # параметры запроса на изменение атрибутов клиента
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            cmdDel  =>
            {
                type        => 'str',
                array       => TRUE,
                optional    => TRUE          
            },
            cmdUpd  => 
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
            pack => # cmdUpd=cln_id:71012;cln_cls:2002;cln_res:1;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            cln_id =>
                            {
                                type => 'int' 
                            },
                            cln_cls =>
                            {
                                type => 'int' 
                            },
                            cln_res =>
                            {
                                type => 'bool' 
                            }                            
                        }
                    }
                },
                {
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            cln_id =>
                            {
                                type => 'int' 
                            },
                            cln_cls =>
                            {
                                type => 'int' 
                            },
                            cln_res =>
                            {
                                type => 'bool' 
                            }                            
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]            
        }                
    },
    ONLY_CORR_SUM => # корректировка остатков на счетах клиентов
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
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
            cmdUpd  => 
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
            pack => # cmdIns=sum_aid:1339406;sum_bdt:29.04.2005;sum_acc:47407;sum_code:111111;sum_slc:8194325.00;
            [
                {
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
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
    ONLY_CORR_ACC => 
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
            {
                type        => 'str',        # тип данных
                array       => TRUE,
                optional    => TRUE          # если определенно то объект опциональный
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
                {   # cmdUpd=acc_id:137296;acc_msk:52;acc_std:30.04.2005;acc_mtd:09.01.2007;
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            acc_id =>
                            {
                                type => 'int' 
                            },
                            acc_msk =>
                            {
                                type => 'long' 
                            },
                            acc_std =>
                            {
                                type => 'date' 
                            },
                            acc_mtd =>
                            {
                                type => 'date' 
                            }                                                        
                        },
                        checks =>
                        {
                            compare =>
                            [
                                {cmp => 'ge', fields => ['acc_mtd', 'acc_std'], value => 0, oper => '-'} 
                            ],
                            match =>
                            [
                                {field => 'acc_msk',   exp => '^\d*$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {   # cmdDel=acc_id:137296;acc_msk:52;acc_std:30.04.2005;acc_mtd:09.01.2007;
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            acc_id =>
                            {
                                type => 'int' 
                            },
                            acc_msk =>
                            {
                                type => 'long' 
                            },
                            acc_std =>
                            {
                                type => 'date' 
                            },
                            acc_mtd =>
                            {
                                type => 'date' 
                            }                                                        
                        },
                        checks =>
                        {
                            compare =>
                            [
                                {cmp => 'ge', fields => ['acc_mtd', 'acc_std'], value => 0, oper => '-'} 
                            ],
                            match =>
                            [
                                {field => 'acc_msk',   exp => '^\d*$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                }            
            ],
            count =>
            [
                {fields => ['cmdUpd', 'cmdDel'], min => 1, max => undef}
            ]                     
        }                                 
    },
    CORR_BAL => 
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            cmdUpd  => # список атрибутов балансового счета для изменения
            {
                type        => 'str',        # тип данных
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
            pack => # cmdUpd=date:01.01.2006;dep:16;code:000000;acc:20206;bal_r:1.00;bal_v:200;
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
                            code =>
                            {
                                type => 'acc'
                            },
                            dep  =>
                            {
                                type => 'str' 
                            },
                            acc =>
                            {
                                type => 'acc' 
                            },
                            bal_r =>
                            {
                                type => 'mny' 
                            },
                            bal_v =>
                            {
                                type => 'mny' 
                            }
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'acc',  exp => '^\d{5}$'},
                                {field => 'code', exp => '^\d{6}$'},
                                {field => 'dep',  exp => '^\d{4}$'},
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdDel',
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
                            dep  =>
                            {
                                type => 'int' 
                            },
                            acc =>
                            {
                                type => 'acc' 
                            },
                            code =>
                            {
                                type => 'acc'
                            },
                            bal_r =>
                            {
                                type => 'mny' 
                            },
                            bal_v =>
                            {
                                type => 'mny' 
                            }
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'acc', exp => '^\d{5}$'},
                                {field => 'dep', exp => '^\d{4}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                }
            ]
        }                                 
    },    
    CORR_COD => 
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {                   
            cmdIns  => 
            {
                type        => 'str',        # тип данных
                array       => TRUE,
                optional    => TRUE          # если определенно то объект опциональный
            },
            cmdUpd  => 
            {
                type        => 'str',        # тип данных
                array       => TRUE,
                optional    => TRUE          # если определенно то объект опциональный
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
            pack => # cmdIns=sum_aid:1339406;sum_bdt:29.04.2005;sum_acc:47407;sum_code:111111;sum_slc:8194325.00;
            [
                {
                    field => 'cmdIns',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdDel',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                },
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter   => PACK_PARAM_SPLITER,
                        extractor => PACK_PARAM_EXTRACT,
                        fields =>
                        {
                            sum_aid =>
                            {
                                type => 'int' 
                            },
                            sum_bdt =>
                            {
                                type => 'date' 
                            },
                            sum_acc =>
                            {
                                type => 'acc' 
                            },
                            sum_code =>
                            {
                                type => 'acc' 
                            },
                            sum_slc =>
                            {
                                type => 'mny' 
                            }                                                        
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'sum_acc',   exp => '^\d{5}$'},
                                {field => 'sum_code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'sum_acc', min => 10201, max => 99999}
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
    SUMM_BAL => # импорт из остатков по считам из хранилища
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            edtDateLeft => # левая граница (дата) выгрузки
            {
                type     => 'date'        # тип данных
            },
            edtDateRight => # правая граница (дата) выгрузки
            {
                type     => 'date'
            },
            lstDep =>
            {
                type     => 'str',
                array    => TRUE,
                optional => TRUE             
            },
            lstAcc =>
            {
                type     => 'acc',
                array    => TRUE,
                optional => TRUE 
            },
            lstCodes =>
            {
                type     => 'acc',
                array    => TRUE,
                optional => TRUE 
            },
            sid =>
            {
                type => 'int'
            },
            lstRowver =>
            {
                type => 'int'
            }
        },                    
        CHECKS => # проверки
        {
            compare =>
            [
                {cmp => 'le', fields => ['edtDateRight', 'edtDateLeft'], value => 3024000, oper => '-'},
                {cmp => 'ge', fields => ['edtDateRight', 'edtDateLeft'], value => 0,       oper => '-'} 
            ],
            match =>
            [
                {field => 'lstAcc', exp => '^\d{5}$'},
                {field => 'lstCls', exp => '^\d{4}$'},
                {field => 'lstDep', exp => '^\d{4}$'}
            ],
            range =>
            [
                {field => 'lstAcc', min => 10201,  max => 99999},
                {field => 'lstDep', min => '0000', max => '9999'}
            ]
        }
    },
    SETTINGS =>
    {
        FIELDS => 
        {
        },
        CHECKS =>
        {
        }
    },
    SETT_PERMISSIONS_ACC => # редактирование прав на доступ к счетам
    {
        FIELDS => # список параметров которые могут быть в CGI запросе
        {
            cmdUpd  => 
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
            pack => # cmdUpd=code:000000;acc:31803;cando:10;
            [
                {
                    field => 'cmdUpd',
                    desc  =>
                    {
                        spliter     => PACK_PARAM_SPLITER,
                        extractor   => PACK_PARAM_EXTRACT,
                        fields      =>
                        {
                            code =>
                            {
                                type => 'int' 
                            },
                            acc  =>
                            {
                                type => 'int' 
                            },
                            cando =>
                            {
                                type => 'int' 
                            }                            
                        },
                        checks =>
                        {
                            match =>
                            [
                                {field => 'acc',   exp => '^\d{5}$'},
                                {field => 'code', exp => '^\d{6}$'}
                            ],
                            range =>
                            [
                                {field => 'acc', min => 10201, max => 99999}
                            ]                         
                        }
                    }
                }                
            ],
            count =>
            [
                {fields => ['cmdUpd'], min => 1, max => undef}
            ]                     
        }                                 
    }
};
    
use constant SUPPORT_SOURCES => # ассоциации модулей с параметрами запроса
{
    CORR_CLN => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    CORR_SUM => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    CORR_ACC => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    ONLY_CORR_CLN => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    ONLY_CORR_SUM => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    ONLY_CORR_ACC => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    CORR_BAL => sub {new F136::RpgAdmImportCorrFromHtml(@_);},
    CORR_COD => sub {new F136::RpgAdmImportCorrFromHtml(@_);},    
    
    SETT_PERMISSIONS_ACC => sub {new F136::RpgAdmImportCorrFromHtml(@_);},

    SUMM_BAL => sub {new F136::RpgAdmImportBalance(@_);},
                               
    SETTINGS => sub {new F136::RpgAdmUpdateSettings(@_);}
};    

BEGIN 
{    
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw (F136::RpgPageAdmin Exporter);
    @EXPORT  = qw (CGI_DESC);    
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
    my $self   = shift;
    
    return unless (defined(CGI_DESC->{$self->{TARGET}}));
    
    my $set    = $self->{PARAM};      # общие параметры    
    my $vars   = $self->{$PACKAGE};   # содержит ссылку на хеш текущего пакета    
    my %args   = (@_);        
    my $exp    = undef;
    my $format = lc(defined($set->{CGI}->param('lstOutTo')) ? $set->{CGI}->param('lstOutTo') : '');

    $set->{LOG}->out(RpgLog::LOG_I, "make report by process import, format's %s", $format);

    if ('excel' eq $format)
    {
        $exp = new RpgExportToExcel(%{$set});
        
        # печать заголовка ответа
        print $set->{CGI}->header(-TYPE       => 'application/vnd.ms-excel', 
                                  -ATTACHMENT => sprintf('f136_report_%d_%d_%s.xls', $set->{SESSION}->uid(), $set->{SESSION}->sid(), strftime('%Y%m%d%H%M%S', localtime)),
                                  -cookie     => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));        
    }
    else
    {
        $args{PARAM} = (defined($args{PARAM}) ? $args{PARAM} : {});

        # формируем request        
        my $param_cgi = CGI_DESC->{$self->{TARGET}};            
        my $fields    = F136::RpgAdmExportCorr::CGI_DESC()->{$self->{TARGET}}{FIELDS};   

        $args{PARAM}{request} = 
            {
                map {$_ => [$set->{CGI}->param($_)]} 
                    grep {defined($fields->{$_}{request})} $set->{CGI}->param()
            };
        $args{PARAM}{errors} = $self->errstr;
        $args{PARAM}{alerts} = $self->alerts;

        $exp = new RpgExportToHtml(%{$set}, TT => $self->{TT});

        # печать заголовка ответа
        print $set->{CGI}->header(-TYPE    => 'text/html', 
                                  -CHARSET => 'windows-1251',
                                  -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));        
    }
    
    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to %s format", $format);
    
    # печать тела (шаблона)
    if (FALSE == $exp->export(%args))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, exporter returns: %s", $exp->errstr());
        goto _WAS_ERROR;
    }

    $set->{LOG}->out(RpgLog::LOG_I, "report was sending");
    return TRUE;

_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error make report");      
    return FALSE;    
}

#*******************************************************************************
#
# Экспорт отчета
#
sub repeat_export
#
#*******************************************************************************
{
    my ($self)  = shift;    
    my ($set)   = $self->{PARAM};  
    
    $set->{CGI}->param(-name => 'exe', -value => 'EXPORT'); 
    my $report = new F136::RpgPageAdmin(%{$self});

    return $report->do();
}


1;
