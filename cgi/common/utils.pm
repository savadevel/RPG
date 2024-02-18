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

package utils;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION);
use Encode qw();
use English;
use strict;
use warnings;
use CGI;
use const;

require Exporter;

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw (Exporter);
    @EXPORT  = qw (CreateGUID min max TRUE FALSE Win2Utf8Ex Win2Utf8 utf_to);
}

#*******************************************************************************
#
#   Функция перекодирует входные данные в указанную кодировку. Если передана
#   ссылка то модифицируются данные и возвращается ссылка, если же передано
#   значение то модифицируется копия и она возвращается
#
sub utf_to
#
#   to   - кодировка см. модуль encode
#   data - данные для перекодирования это могут быть
#       ссылка на скаляр, массив, хеш
#       массив
#       скаляр
#
#*******************************************************************************
{
    my $to   = shift;
    
    if ($#_ > 0)
    {
        return (map {encode_to($to, $_)} @_);
    }
    
    my $data = shift;

    unless (ref($data))
    {
        return (Encode::is_utf8($data) ? Encode::encode($to, $data): $data);
    }
    elsif ('SCALAR' eq ref($data))
    {
        $$data = Encode::encode($to, $$data) if (Encode::is_utf8($$data));
        return ($data);
    }
    elsif ('ARRAY' eq ref($data))
    {
        utf_to($to, ref($_) ? $_ : \$_) foreach(@{$data});
    }
    elsif ('HASH' eq ref($data))
    {
        utf_to($to, ref($data->{$_}) ? $data->{$_} : \$data->{$_}) foreach(keys(%{$data}));
    }
    else
    {
        die sprintf("Error, unknown type '%s' of data '%s'", ref($data), $data);
    }
}

#*******************************************************************************
#
sub min
#
#*******************************************************************************
{
    return ($_[0] < $_[1] ? $_[0] : $_[1]);
}

#*******************************************************************************
#
sub max
#
#*******************************************************************************
{
    return ($_[0] < $_[1] ? $_[1] : $_[0]);
}

#*******************************************************************************
#
sub Win2Utf8
#
#*******************************************************************************
{
    my($ref) = shift;    
    my $ret = '';
    my $dlt = 0;

    foreach (split(//, $$ref))
    {
        $_ = ord;    
        
        if    ($_ >= 0xC0 and $_ <= 0xDF) # А - Ю
        {
            $dlt = (0x410 - 0xC0);
        }
        elsif ($_ >= 0xE0 and $_ <= 0xFF) # а - ю
        {
            $dlt = (0x430 - 0xE0);
        }
        elsif ($_ == 0xA8) # Ё
        {
            $dlt = 0x401 - 0xA8;
        }
        elsif ($_ == 0xB8) # ё
        {
            $dlt = 0x451 - 0xB8;
        }
        elsif ($_ == 0xB9)
        {
            $dlt = 0x2116 - 0xB9;
        }
        
        $ret .= sprintf('%04x', ($_ + $dlt));
        $dlt  = 0;
    }
    
    return $ret;
}

#*******************************************************************************
#
#  Создание GUID
#
sub CreateGUID
#
#*******************************************************************************
{
    srand(time ^ $$);
    return sprintf("%04X%04X-%04X-%04X-%04X-%04X%04X%04X", rand(0xFFFF), 
                                                             rand(0xFFFF),
                                                             rand(0xFFFF),
                                                             rand(0xFFFF),
                                                             rand(0xFFFF),
                                                             rand(0xFFFF),
                                                             rand(0xFFFF),
                                                             rand(0xFFFF));
}

#*******************************************************************************
#
sub Win2Utf8Ex
#
#*******************************************************************************
{
    if    (ref($_[0]) eq 'ARRAY')
    {
        foreach my $ref (@{$_[0]})
        {
            $ref = Win2Utf8Ex(\$ref);
        }
        
        return $_[0];
    }
    elsif (ref($_[0]) eq 'SCALAR')
    {
        return pack("H*", Win2Utf8($_[0]));
    }
    elsif ('' eq ref($_[0]))
    {
        return pack("H*", Win2Utf8(\$_[0]));
    }    
}

1;
