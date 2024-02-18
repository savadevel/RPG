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

package admin::RpgAdminLogExportToExcel;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use admin::adm_log_exp;
use exp_to_excel;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(admin::RpgAdminLogExport);
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
    ref($_[0]) && die "Error, class admin::RpgAdminLogExportToExcel can't use in inheritance\n";        
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

    $set->{LOG}->out(RpgLog::LOG_I, "user want see data in Excel"); 
    
    if (TRUE != $self->load_data(FALSE))
    {
        $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу        
        goto _WAS_ERROR;        
    }
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE       => 'application/vnd.ms-excel', 
                              -ATTACHMENT => sprintf('spr_report_%d_%d_%s.xls', $set->{SESSION}->uid(), $set->{SESSION}->sid(), strftime('%Y%m%d%H%M%S', localtime)),
                              -cookie     => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));

    $set->{LOG}->out(RpgLog::LOG_D, "prepare data for out to Excel format");

    my $param = admin::RpgAdminLogExport::EXPORT_DESC()->{$self->{TARGET}};    
    my $exp   = new RpgExportToExcel(%{$set});
    
    # печать тела (шаблона)
    if (FALSE == $exp->export
        (
            TITLE  => $param->{title},
            TABLES =>
            {
                GET_DATA => 
                {
                    TITLE  => $param->{title},
                    DATA   => $self->{SRC_DATA}->get_data('GET_BODY'),
                    FIELDS => {map{$_ => $param->{FIELDS}->{$_}} (@{$self->{FIELDS_MAIN}}, @{$self->{FIELDS_OPT}})}
                }
            }
        ))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, exporter returns: %s", $exp->errstr());
        goto _WAS_ERROR;
    }
      
    $set->{LOG}->out(RpgLog::LOG_I, "data in Excel format was sending");
    return TRUE;
    
_WAS_ERROR:
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data in Excel format");              
    return FALSE;
}

1;
