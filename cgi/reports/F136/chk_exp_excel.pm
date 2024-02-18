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

package F136::RpgChkExportToExcel;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;

use FindBin qw($Bin);
use utils;

use F136::chk_exp;
use exp_to_excel;

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
    ref($_[0]) && die "Error, class F136::RpgChkExportToExcel can't use in inheritance\n";        
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
    
    $set->{LOG}->out(RpgLog::LOG_I, "user want see check data in Excel");
        
    if (TRUE != $self->load_data())
    {
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE       => 'application/vnd.ms-excel', 
                              -ATTACHMENT => sprintf('f136_report_%d_%d_%s.xls', $set->{SESSION}->uid(), $set->{SESSION}->sid(), strftime('%Y%m%d%H%M%S', localtime)),
                              -cookie     => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));

    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to Excel format");

    my $data    = $self->{SRC_DATA};
    my $param   = F136::RpgChkExport::EXPORT_DESC()->{$self->{TARGET}};    
    my $exp     = new RpgExportToExcel(%{$set});
    
    # печать тела (шаблона)
    if (FALSE == $exp->export
        (
            TITLE  => $param->{title},
            TABLES =>
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
      
    $set->{LOG}->out(RpgLog::LOG_I, "check data in Excel format was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare check data in Excel format");              
    return FALSE;
}

1;