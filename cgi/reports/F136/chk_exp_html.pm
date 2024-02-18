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

package F136::RpgChkExportToHtml;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use F136::chk_exp;
use exp_to_html;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(F136::RpgChkExport);
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
    ref($_[0]) && die "Error, class F136::RpgChkExportToHtml can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({@_}, $class);
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }

    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++);      
    return $self;       
}


#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    return shift;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my ($vars) = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета    
    
    $set->{LOG}->out(RpgLog::LOG_I, "user want see data in HTML");
    
    if (TRUE != $self->load_data())
    {
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }
    
    my %types   = (date => {}, time => {});
    my $data    = $self->{SRC_DATA};
    my $rowver  = $data->get_obj_data('GET_THE_ROWVER');
    my $checkin = ((grep {defined($_) && $_ == 0} map{$_->{is_fix}} @{$data->get_data('GET_ROWVER')}) ? FALSE : TRUE);

    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251',
                              -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));
    
    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to HTML format");

    my $param = F136::RpgChkExport::EXPORT_DESC()->{$self->{TARGET}};    
    my $exp   = new RpgExportToHtml(%{$set}, TT => $self->{TT});
    
    # печать тела (шаблона)
    if (FALSE == $exp->export
        (
            TITLE    => $param->{title},
            TEMPLATE => $param->{html_template},
            PARAM    => 
            {
                errors       => $self->errstr,
                alerts       => $self->alerts,
                bin_oper     => sub {($_[0] & $_[2]);},            
                dformat      => $types{date}{format},
                tformat      => $types{time}{format},
                date2str     => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
                
                # атрибуты таблицы
                table        => {
                                    description  => (exists($param->{title}) ? $param->{title} : undef),
                                    period_left  => $set->{CGI}->param('edtDateLeft'),
                                    period_right => $set->{CGI}->param('edtDateRight'),
                                    count        => ($#{$self->{SRC_DATA}->get_data('GET_BODY')} + 1)                                               
                                },                     
                # сохраняем параметры вызова
                request      => $self->_make_request(),            
                # версия к которой привязан текущий набор данных
                version      => 
                            {
                                rowver  => $set->{SESSION}->rowver(),
                                is_fix  => $set->{SESSION}->is_fix(),
                                access  => $set->{SESSION}->access(),
                                lperiod => $rowver->ldate(),
                                rperiod => $rowver->rdate(),
                                label   => $rowver->label()
                            },                                        
                # словари
                dictionary   => {map{$_ => $data->get_data($_)} keys(%{$param->{DICTIONARIES}})}
            },
            TABLES   =>
            {
                REPORT => 
                {
                    TITLE  => $param->{title},
                    DATA   => $data->get_data('GET_BODY', 1),
                    FIELDS =>
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
                        }
                    }
                },
                REPORT_EXT =>
                {
                    TITLE  => $param->{title},
                    DATA   => $data->get_data('GET_BODY', 0),
                    FIELDS => $param->{FIELDS}
                }
            }
        ))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, exporter returns: %s", $exp->errstr());
        goto _WAS_ERROR;
    }
    
    $set->{LOG}->out(RpgLog::LOG_I, "check data in HTML format was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare check data in HTML format");              
    return FALSE;
}

#*******************************************************************************
#
# Собирает строку srtRequest, используется для повтора последнего запроса
#
sub _make_request
#
#*******************************************************************************
{
    my ($self)    = shift;
    my ($set)     = $self->{PARAM};
    my ($fields)  = F136::RpgChkExport::CGI_DESC()->{$self->{TARGET}}{FIELDS};
    my ($ret)     =
            {
                map {$_ => [$set->{CGI}->param($_)]} 
                    grep {defined($fields->{$_}) && defined($fields->{$_}{request})} $set->{CGI}->param()
            };       
   
    return  $ret;
}


1;
