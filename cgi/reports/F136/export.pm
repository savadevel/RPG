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

package F136::RpgExport;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw($VERSION $PACKAGE @ISA);
use English;
use strict;
use warnings;
use utils;
use src_data;
use cgi_check;
use sql_make;

use F136::page_app;
use F136::exp_excel;
use F136::exp_kliko;
use F136::exp_reserve;
use F136::exp_html;

use constant CGI_DESC => # содержит поля запроса, по ним делаем его валидацию
{
    FIELDS => # список параметров которые могут быть в CGI запросе
    {
        lstRowver => # версия отчетной формы
        {
            type  => 'int'            
        },
        lstDep      => # список подразделений Банка
        {
            type  => 'str',
            array => TRUE            
        },
        chkApp      => # список приложений 136 которые требуется рассчитать
        {
            type  => 'int',
            array => TRUE
        },
        lstOutTo   => # формат генерации 136 формы
        {
            type  => 'str'
        },
        uid =>
        {
            type  => 'int'
        }                    
    },                    
    CHECKS => # проверки
    {
        match =>
        [
            {field => 'lstDep',   exp => '^\d{4}$'}
        ]
    }
};    

use constant EXPORT_DESC => # содержит описание процедур выгрузки данных из БД
{   
    # параметры расчета 136 формы
    GET_BODY  => # сама форма
    {
        src    => 'SQL_GET_F136_FORM',   # имя источника
        params =>
                [
                    {field => 'lstRowver'}, 
                    {field => 'lstDep', options => {array => TRUE, spliter => ' ', wrap => "'", type => 'unk'}}, 
                    {field => 'chkApp', options => {array => TRUE, spliter => ' ', wrap => "'"}},
                    {field => 'lstOutTo'}
                ]
    },
    GET_USER  => # имя делавшего расчет
    {
        src    => 'SQL_GET_USER',   # имя источника
        params => [{field => 'uid'}]
    },
    GET_ROWVER => # параметры версии
    {
        src    => 'SQL_GET_THE_ROWVER',
        params => [{field => 'lstRowver'}]                    
    }                
};

use constant SUPPORT_FORMATS =>
{
    kliko   => sub {new F136::RpgExportToKliko(@_);},
    html    => sub {new F136::RpgExportToHtml(@_);},
#    excel   => sub {new F136::RpgExportToExcel(@_);},
    reserve => sub {new F136::RpgExportToReserve(@_);}
};

BEGIN 
{
    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw(F136::RpgPageApp);
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
        $args{PARAM}->{LOG}->out(RpgLog::LOG_W, "user query unknow format '%s' for export 'Report by form 0409136'", $to);
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
}

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($set)  = $self->{PARAM};        # общие параметры, значение self->{PARAM}, установленно в базовом классе        

    $self->{SRC_DATA} = new RpgSrcData; # единый источник данных
    
    # эти параметры требуются при формировании 136 формы, но не передаются в CGI запросе
    $set->{CGI}->param(-name => 'uid', -value => $set->{SESSION}->uid());
    
    return $self;
}

#*******************************************************************************
#
#  Загружает данные для генерации 136 формы, возвращает TRUE при успехе
#
sub load_data
#
#*******************************************************************************
{
    my $self = shift;    
    my $set  = $self->{PARAM};       # общие параметры
    my $vars = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    my $cgi_check = new RpgCGICheck(PARAM => $set);
    my $cgi_desc  = CGI_DESC();

    unless ($cgi_check->checking(FIELDS => $cgi_desc->{FIELDS},
                                 CHECKS => $cgi_desc->{CHECKS}))
    {
        $set->{LOG}->out(RpgLog::LOG_E, 'invalid CGI query, becose: "%s"', $cgi_check->errstr);
        goto _WAS_ERROR;
    }
    
    $set->{LOG}->out
        (
            RpgLog::LOG_I, 
            "user query 'Report by form 0409136' with param: rowver=[%s], departments=[%s], applications=[%s]", 
            join(",", map($_, @{[$set->{CGI}->param('lstRowver')]})),
            join(",", map($_, @{[$set->{CGI}->param('lstDep')]})),
            join(",", map($_, @{[$set->{CGI}->param('chkApp')]}))
        );
    
    $set->{LOG}->out(RpgLog::LOG_I, "prepare data 'Report by form 0409136' for export");

    my $maker = new RpgSQLMake();
    
    foreach my $src (keys(%{EXPORT_DESC()}))
    {
        # строим SQL запрос:                
        my ($query) = $maker->procedure
            (
                DESC    =>
                    {
                        src    => $set->{SETT}->get($set->{SESSION}->report(), EXPORT_DESC->{$src}{src}),
                        params => EXPORT_DESC->{$src}{params}
                    },
                CGI     => $set->{CGI},
                REQUEST => $cgi_desc->{FIELDS}
            );    

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (data for show 'Report by form 0409136'), sql: '%s'", $src, $query);        
        
        # загружаем табличные данные
        unless ($self->{SRC_DATA}->add(FROM => $set->{DB}, TO => $src, SRC => $query))
        {
            # ошибки при расчете-загрузки формы
            $set->{LOG}->out(RpgLog::LOG_E, "can't load data 'Report by form 0409136', becose: %s", $self->{SRC_DATA}->errstr());
            goto _WAS_ERROR;
        }
        
        $set->{LOG}->out(RpgLog::LOG_D, "data loaded");
    }

    # создаем группировки для данных форм    
    $self->{GROUPS}{GET_BODY} = RpgSrcData::CreateGroup(TABLE  => $self->{SRC_DATA}->get_data('GET_BODY'), 
                                                        FIELDS => ['id_app', 'id_tbl']);        
    
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data 'Report by form 0409136' for export");
    return TRUE;    

_WAS_ERROR:    
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data 'Report by form 0409136' for export");
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
