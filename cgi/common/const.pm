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
package const;
use strict;
use warnings;

use vars qw(@EXPORT @ISA $VERSION);
use Exporter;

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw (Exporter);
    @EXPORT  = qw (TRUE FALSE INFINITY NEG_INFINITY NAN PACK_ORDER_SPLITER PACK_ORDER_EXTRACT PACK_PARAM_SPLITER PACK_PARAM_EXTRACT);
}

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PACK_ORDER_SPLITER => '&';
use constant PACK_ORDER_EXTRACT => '^\[(\w+)\]\s+(asc|desc)$';
use constant PACK_PARAM_SPLITER => ';';
use constant PACK_PARAM_EXTRACT => '^(\w+):(.*)$';

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);
use constant NAN          => INFINITY - INFINITY;

1;

