#!/usr/bin/perl -w
$| = 1;
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

use strict;
use warnings;
use locale;
use POSIX qw(strftime setlocale LC_CTYPE);
use DBI;
use CGI;
use English;

use FindBin qw($Bin);

BEGIN
{
    if ($Bin =~ m/^(.+)$/)
    {
        $Bin = $1;        
    }
    else
    {
        die "Bad directory $Bin\n";
    }    
}

use lib "$Bin";
use lib "$Bin/common";       
use lib "$Bin/lib";    
use lib "$Bin/reports";

use log;
use utils;                    # 
use auth;                     # модуль идентификации
use sett;                     # источник параметров
use page_frameset;            # модуль задает общее оформление, устанавливает фреймы 
use page_tree;                # модуль динамически формирует дерево отчетов в соответствии с правами
use page_default;             # модуль формирует страницу, для пользователя запросившего не существующий отчет

use constant DEF =>
{
    GET_APP_NAME          => $PROGRAM_NAME,         #'RPG',
    GET_OPTIONS           => "$Bin/opt/sett.in",    # путь к обязательным параметрам работы
    GET_NAME_FRAME_LEFT   => '_tree',               # путь к странице с деревом отчетов
    GET_NAME_FRAME_RIGHT  => '_report',             # путь к странице с отчетом
    GET_TITLE             => 'Отчётность ver. 0.2'  # имя по умолчанию выводимое в заголовке броузера
};

# список обязательных параметров которые должны быть заданы в файле опций
use constant IMPORTANT_PARAM =>
{   
    BD_CONNECT_STR   => {value=> undef, type => 'str'},
    BD_USER          => {value=> undef, type => 'str'},
    BD_PASS          => {value=> undef, type => 'pwd'},
    SQL_GET_SETT     => {value=> undef, type => 'str'},
    TT2_INCLUDE_PATH => {value=> undef, type => 'str'},
    PRC_CREATE_SID   => {value=> undef, type => 'str'},
    PRC_CLOSE_SID    => {value=> undef, type => 'str'}
};

# список необязательных параметров (с заданными параметрами по умолчанию) загружаемых из файла опций
use constant SOME_PARAM =>
{
    DBI_PRINT_ERROR  => {value=> 'y',        type => 'bool'},
    DBI_AUTO_COMMIT  => {value=> 'n',        type => 'bool'},
    DBI_RAISE_ERROR  => {value=> 'y',        type => 'bool'},
    LOG_TO_DB        => {value=> 'y',        type => 'bool'},
    PATH_LOG         => {value=> undef,      type => 'str'},
    DEBUG_LEVEL      => {value=> 1,          type => 'int'},
    TT2_INTERPOLATE  => {value=> 0,          type => 'int'},
    TT2_POST_PROCESS => {value=> undef,      type => 'str'},
    TT2_PRE_PROCESS  => {value=> undef,      type => 'str'},
    TT2_TAG_STYLE    => {value=> 'template', type => 'str'},
    TT2_DEBUG        => {value=> undef,      type => 'str'}
};

# инициализация переменных среды
$ENV{ORACLE_BASE} = qw(/home/app/oradb)                 unless (defined($ENV{ORACLE_BASE}));
$ENV{ORACLE_HOME} = qw(/home/app/oradb/product/9.2.0)   unless (defined($ENV{ORACLE_HOME}));
$ENV{TNS_ADMIN}   = qw(/home/isa/rpg/)                  unless (defined($ENV{TNS_ADMIN}));
$ENV{ORACLE_SID}  = qw(DEV)                             unless (defined($ENV{ORACLE_SID}));
$ENV{NLS_LANG}    = qw(AMERICAN_AMERICA.CL8MSWIN1251)   unless (defined($ENV{NLS_LANG}));
$ENV{REMOTE_ADDR} = qw(000.000.000.000)                 unless (defined($ENV{REMOTE_ADDR}));
$ENV{REMOTE_PORT} = qw(0)                               unless (defined($ENV{REMOTE_PORT}));
$ENV{REMOTE_USER} = qw(guest)                           unless (defined($ENV{REMOTE_USER}));

# параметры работы
my(%set)   = (
                 SETT      => undef,               
                 CGI       => new CGI,              # переменная для работы по HTTP 
                 LOG       => undef,                # журналирование работы
                 SESSION   => undef,                # параметры сессии
                 APP       => DEF->{GET_APP_NAME},  # имя приложения
                 DB        => undef,                # соединение с БД                 
                 FILE_INI  => DEF->{GET_OPTIONS},   # файл с параметрами 
                 MODULE    => 'RPG',
                 ADDRESS   => "$ENV{REMOTE_ADDR}:$ENV{REMOTE_PORT}",
                 USER      => $ENV{REMOTE_USER}
             );       

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    use CGI::Carp qw(fatalsToBrowser set_message warningsToBrowser);
    
    # перехват ошибок, в коде
    sub Error2Log 
    {
        if (defined($set{LOG}))
        {
            # запись ошибки в журнал
            $set{LOG}->out(RpgLog::LOG_E, $_[0]);
        }
        if (defined($set{DB}) && defined($set{SESSION}))
        {
            $set{SESSION}->close();
        }

        print "<p>Извините, но запрошенная страница в данный момент не доступна, попробуйте позже или обратитесь в службу поддержки.</p>\n";
    }

    # устанавливаем свой перехватчик ошибок
    set_message(\&Error2Log);
};

###########################################################################
{   
    # определяем запрошенный отчет, передается через URL    
    my $page   = (defined($set{CGI}->url_param('page'))? lc($set{CGI}->url_param('page')) : '');
    my $report = (($page eq DEF->{GET_NAME_FRAME_RIGHT} and defined($set{CGI}->url_param('report'))) ? $set{CGI}->url_param('report') : '');
     
    # загружаем параметры работы    
    $set{SETT} = new RpgSett(PATH    => $set{FILE_INI},
                             CHECK   => {
                                            IMPORTANT => (IMPORTANT_PARAM),
                                            SOME      => (SOME_PARAM)
                                        }
                            );
    # создаем логер
    $set{LOG} = new RpgLog(PATH        => $set{SETT}->get(undef, 'PATH_LOG'),
                           DEBUG_LEVEL => $set{SETT}->get(undef, 'DEBUG_LEVEL'),
                           APP         => $set{MODULE},
                           ADDRESS     => $set{ADDRESS},
                           LOG_TO_DB   => $set{SETT}->get(undef, 'LOG_TO_DB'),
                           USER        => $set{USER});

    # создаём подключение к БД
    $set{DB} = DBI->connect($set{SETT}->get(undef, 'BD_CONNECT_STR'),
                            $set{SETT}->get(undef, 'BD_USER'),
                            $set{SETT}->get(undef, 'BD_PASS'),
                            {
                                RaiseError => $set{SETT}->get(undef, 'DBI_PRINT_ERROR'),
                                AutoCommit => $set{SETT}->get(undef, 'DBI_AUTO_COMMIT'),
                                PrintError => $set{SETT}->get(undef, 'DBI_RAISE_ERROR')
                            }
                            ) || die "Database connection not made: $DBI::errstr";

    $set{SESSION} = new RpgAuth
                            (
                                REPORT         => $report || 'RPG',
                                DB             => $set{DB},
                                PRC_CREATE_SID => $set{SETT}->get($set{MODULE}, 'PRC_CREATE_SID'),
                                PRC_CLOSE_SID  => $set{SETT}->get($set{MODULE}, 'PRC_CLOSE_SID')
                            );

    $set{SETT}->reload(LOAD_TO      => $set{SESSION}->report(),
                       SQL_GET_SETT => sprintf($set{SETT}->get(undef, 'SQL_GET_SETT'), $set{SESSION}->report()),
                       DB           => $set{DB});  
                       
    # добавляем ведение журнала в БД
    $set{LOG}->set(SID         => $set{SESSION}->sid(), 
                   UID         => $set{SESSION}->uid(), 
                   DB          => $set{DB}, 
                   REPORT      => $set{SESSION}->report(), 
                   PRC_LOG     => $set{SETT}->get($set{SESSION}->report(), 'PRC_LOG'),
                   LEN_MSG     => $set{SETT}->get($set{SESSION}->report(), 'LEN_MSG'),
                   LOG_TO_DB   => ('n' eq lc ($set{SETT}->get($set{SESSION}->report(), 'LOG_TO_DB'))? undef : 'Y'),
                   DEBUG_LEVEL => $set{SETT}->get($set{SESSION}->report(), 'DEBUG_LEVEL'),
                   PERMISSION   => $set{SESSION}->access()
                  );    
    
    $set{LOG}->out(RpgLog::LOG_A, "Begin session");        
    $set{LOG}->out_env(RpgLog::LOG_D);    
    
    # печать параметров переданных методом POST  в теле сообщения
    $set{LOG}->out(RpgLog::LOG_D, "param: %s",     join("; ", map((defined($_) ? $_ : '') . "=". join(",", map(defined($_) ? $_ : '', @{[$set{CGI}->param($_)]})), $set{CGI}->param())));
    # печать параметров переданных методом POST или GET в строке запроса
    $set{LOG}->out(RpgLog::LOG_D, "url_param: %s", join("; ", map((defined($_) ? $_ : '') . "=". join(",", map(defined($_) ? $_ : '', @{[$set{CGI}->url_param($_)]})), $set{CGI}->url_param())));
    # печать cookie
    $set{LOG}->out(RpgLog::LOG_D, "cookie: %s",    join("; ", map((defined($_) ? $_ : '') . "=". join(",", map(defined($_) ? $_ : '', @{[$set{CGI}->cookie($_)]})), $set{CGI}->cookie())));
    
    # печать загруженных опций
    $set{SETT}->print($set{LOG}, $set{SESSION}->report(), RpgLog::LOG_F);
    
    my $obj = undef;

    # Запрос отчета
    if ($set{SESSION}->access() < 1)
    {
        # нет доступа
        $set{LOG}->out(RpgLog::LOG_A, "Access denied", $set{SESSION}->uid());
        $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:new RpgPageDefault()");          
        $obj = new RpgPageDefault(PARAM => \%set);
    }
    elsif ($page eq '')
    {            
        # При пустом запросе формируем frameset
        $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:new RpgFrameset()");  
        $obj = new RpgPageFrameset(PARAM    => \%set,
                                   FRAMESET =>
                                   {
                                       left  => {path =>$set{CGI}->script_name, name => DEF->{GET_NAME_FRAME_LEFT}},
                                       right => {path =>$set{CGI}->script_name, name => DEF->{GET_NAME_FRAME_RIGHT}}
                                   });
    }
    elsif ($page eq DEF->{GET_NAME_FRAME_LEFT})
    {
        # Формируем дерево
        $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:new RpgTree()");          
        $obj = new RpgPageTree(PARAM => \%set,
                               FRAMESET =>
                               {
                                   left  => {path =>$set{CGI}->script_name, name => DEF->{GET_NAME_FRAME_LEFT}},
                                   right => {path =>$set{CGI}->script_name, name => DEF->{GET_NAME_FRAME_RIGHT}}
                               });
    }
    elsif ($page eq DEF->{GET_NAME_FRAME_RIGHT})
    {
        $obj = LoadObj(\%set);
        
        unless (defined($obj))
        {
            # не удалось создать объект отчета
            $set{LOG}->out(RpgLog::LOG_E, "Error, can't load report: UID = %d, report = '%s', lib = %s, path = %s", 
                           $set{SESSION}->uid(), $set{SESSION}->report(), $set{SESSION}->lib(), $set{SESSION}->path());
            $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:new RpgPageDefault()");          
            $obj = new RpgPageDefault(PARAM => \%set);
        }
    }
    else
    {
        $set{LOG}->out(RpgLog::LOG_E, "Error, invalid value of path_info = %s, url_param = %s", 
                       $set{CGI}->path_info, $set{CGI}->url_param("page"));
        $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:new RpgPageDefault()");          
        $obj = new RpgPageDefault(PARAM => \%set);
    }

    $set{LOG}->out(RpgLog::LOG_F, "call $set{APP}:do()");  
    $obj->do();        
    $set{LOG}->out(RpgLog::LOG_A, "End session");  

    # создаем отметку в БД о завершении сессии
    $set{SESSION}->close();
    $set{DB}->disconnect;
}        

exit(0);

#*******************************************************************************
#
sub LoadObj
#
#*******************************************************************************
{
    my ($set)   = shift;
    my ($ret)   = undef;        
    my ($path)  = $set->{SESSION}->path();
    my ($modul) = $set->{SESSION}->lib();
         
    $ret = eval("use $path; new $modul(PARAM => \$set);");    

    $set->{LOG}->out(RpgLog::LOG_E, "Error in LoadObj after eval: %s", $@) 
        if(defined($@) and '' ne $@);    
    
    return $ret;
}
