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
package RpgTypes;

use UNIVERSAL qw(isa);
use locale;
use POSIX qw(setlocale LC_CTYPE);
use CGI;

use vars qw($VERSION $PACKAGE @ISA @EXPORT);
use English;
use strict;
use warnings;
use Exporter;
use Time::Local;
use DateTime;
use DateTime::Format::Strptime;
use Scalar::Util qw(refaddr);
use utils;

# схемы преобразования и проверки из
# данных представленных строкой во внутренее 
# представление
use constant DEFAULT_STRING2RAWDATA =>
{
    MAIN =>
    {
        unk     => {base => 'str', template => '^(.*)$'},
        int     => {base => 'num', template => '^([+-]?\d+)$'},
        long    => {base => 'num', template => '^([+-]?\d+)$'},
        uint    => {base => 'num', template => '^(\d+)$'},
        flt     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        dbl     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        bool    => {base => 'num', template => '^([Yy1\+T])$'}, # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        chr     => {base => 'str', template => '^(.*)$'},
        byte    => {base => 'str', template => '^(.)$'},
        str     => {base => 'str', template => '^(.*)$'},
        txt     => {base => 'str', template => '^(.*)$'},
        acc     => {base => 'str', template => '^(.*)$'},
        sql     => {base => 'str', template => '^(.*)$'},
        xml     => {base => 'str', template => '^(.*)$'},
        pwd     => {base => 'str', template => '^(.*)$'},
        pathd   => {base => 'str', template => '^(.*)$'},
        pathf   => {base => 'str', template => '^(.*)$'},        
        ip      => {base => 'str', template => '^((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))$'},
        date    => {base => 'str', template => 'USER01'},
        time    => {base => 'str', template => 'USER02'}
    },        
    SQL =>
    {
        unk     => {base => 'str', template => '^(.*)$'},
        int     => {base => 'num', template => '^([+-]?\d+)$'},
        long    => {base => 'num', template => '^([+-]?\d+)$'},
        uint    => {base => 'num', template => '^(\d+)$'},
        flt     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        dbl     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        bool    => {base => 'num', template => '^(1)$'},  # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        chr     => {base => 'str', template => '^(.*)$'},
        byte    => {base => 'str', template => '^(.)$'},
        str     => {base => 'str', template => '^(.*)$'},
        txt     => {base => 'str', template => '^(.*)$'},
        acc     => {base => 'str', template => '^(.*)$'},
        sql     => {base => 'str', template => '^(.*)$'},
        xml     => {base => 'str', template => '^(.*)$'},
        pwd     => {base => 'str', template => '^(.*)$'},
        pathd   => {base => 'str', template => '^(.*)$'},
        pathf   => {base => 'str', template => '^(.*)$'},        
        ip      => {base => 'str', template => '^((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))$'},
        date    => {base => 'str', template => 'ISO8601'},
        time    => {base => 'str', template => 'ISO8601'} 
    },
    LOG =>
    {
        unk     => {base => 'str', template => '^(.*)$'},
        int     => {base => 'num', template => '^([+-]?\d+)$'},
        long    => {base => 'num', template => '^([+-]?\d+)$'},
        uint    => {base => 'num', template => '^(\d+)$'},
        flt     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        dbl     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {base => 'num', template => '^([+-]?\d*\.?\d*)$'}, # возможны комбинации 0.0, .0, ., 0., 0
        bool    => {base => 'num', template => '^(1)$'},  # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        chr     => {base => 'str', template => '^(.*)$'},
        byte    => {base => 'str', template => '^(.)$'},
        str     => {base => 'str', template => '^(.*)$'},
        txt     => {base => 'str', template => '^(.*)$'},
        acc     => {base => 'str', template => '^(.*)$'},
        sql     => {base => 'str', template => '^(.*)$'},
        xml     => {base => 'str', template => '^(.*)$'},
        pwd     => {base => 'str', template => '^(.*)$'},
        pathd   => {base => 'str', template => '^(.*)$'},
        pathf   => {base => 'str', template => '^(.*)$'},        
        ip      => {base => 'str', template => '^((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))\.((?:(?:[0-1]?[0-9]?[0-9])|(?:[2]?[0-5]?[0-5])))$'},
        date    => {base => 'str', template => 'USER04'},
        time    => {base => 'str', template => 'USER04'} 
    }    
};

# схемы преобразования из внутреннего представления
# в строку
use constant DEFAULT_RAWDATA2STRING =>
{
    MAIN =>
    {
        unk     => {template => '%s',     if_undef =>undef},
        int     => {template => '%d',     if_undef =>undef},
        long    => {template => '%s',     if_undef =>undef},
        uint    => {template => '%u',     if_undef =>undef},
        flt     => {template => '%f',     if_undef =>undef}, 
        dbl     => {template => '%.04f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {template => '%.02f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        chr     => {template => '%s',     if_undef =>undef},
        byte    => {template => '%s',     if_undef =>undef},
        str     => {template => '%s',     if_undef =>undef},
        txt     => {template => '%s',     if_undef =>undef},
        acc     => {template => '%s',     if_undef =>undef},
        sql     => {template => '%s',     if_undef =>undef},
        xml     => {template => '%s',     if_undef =>undef},
        pwd     => {template => '%s',     if_undef =>undef},
        pathd   => {template => '%s',     if_undef =>undef},
        pathf   => {template => '%s',     if_undef =>undef},
        bool    => {template => '%s',     if_undef =>undef}, # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        ip      => {template => '%03d.%03d.%03d.%03d',  if_undef =>undef},
        date    => {template => 'USER01',               if_undef =>undef},
        time    => {template => 'USER02',               if_undef =>undef}
    },        
    HTML =>
    {
        unk     => {template => '%s',     if_undef =>undef},
        int     => {template => '%d',     if_undef =>undef},
        long    => {template => '%s',     if_undef =>undef},
        uint    => {template => '%u',     if_undef =>undef},
        flt     => {template => '%f',     if_undef =>undef}, 
        dbl     => {template => '%.04f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {template => '%.02f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        byte    => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        chr     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;'], ['\n', '<br>']]},
        str     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;'], ['\n', '<br>']]},
        txt     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;'], ['\n', '<br>']]},
        acc     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        sql     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        xml     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        pwd     => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        pathd   => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        pathf   => {template => '%s',     if_undef =>undef, replace=>[['&', '&amp;'], ['"', '&quot;'], ['<', '&lt;'], ['>', '&gt;']]},
        bool    => {template => '%s',     if_undef =>undef}, # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        ip      => {template => '%03d.%03d.%03d.%03d',  if_undef =>undef},
        date    => {template => 'USER01',               if_undef =>undef},
        time    => {template => 'USER02',               if_undef =>undef}
    },        
    EXCEL =>
    {
        unk     => {template => '%s',     if_undef =>undef},
        int     => {template => '%d',     if_undef =>undef},
        long    => {template => '%s',     if_undef =>undef},
        uint    => {template => '%u',     if_undef =>undef},
        flt     => {template => '%f',     if_undef =>undef}, 
        dbl     => {template => '%.04f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {template => '%.04f',  if_undef =>undef}, # возможны комбинации 0.0, .0, ., 0., 0
        byte    => {template => '%s',     if_undef =>undef},
        chr     => {template => '%s',     if_undef =>undef},
        str     => {template => '%s',     if_undef =>undef},
        txt     => {template => '%s',     if_undef =>undef},
        acc     => {template => '%s',     if_undef =>undef},
        sql     => {template => '%s',     if_undef =>undef},
        xml     => {template => '%s',     if_undef =>undef},
        pwd     => {template => '%s',     if_undef =>undef},
        pathd   => {template => '%s',     if_undef =>undef},
        pathf   => {template => '%s',     if_undef =>undef},
        bool    => {template => '%s',     if_undef =>undef}, # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        ip      => {template => '%03d.%03d.%03d.%03d',  if_undef =>undef},
        date    => {template => 'ISO8601',              if_undef =>undef},
        time    => {template => 'ISO8601',              if_undef =>undef}
    },        
    SQL =>
    {
        unk     => {template => '%s',        if_undef => 'null', replace=>[['^$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        int     => {template => '%d',        if_undef => 'null'},
        long    => {template => '%s',        if_undef => 'null'},
        uint    => {template => '%u',        if_undef => 'null'},
        flt     => {template => '%f',        if_undef => 'null'}, 
        dbl     => {template => '%.04f',     if_undef => 'null'}, # возможны комбинации 0.0, .0, ., 0., 0
        mny     => {template => '%.02f',     if_undef => 'null'}, # возможны комбинации 0.0, .0, ., 0., 0
        byte    => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        chr     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        str     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        txt     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        acc     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        sql     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        xml     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        pwd     => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        pathd   => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        pathf   => {template => '\'%s\'',    if_undef => 'null', replace=>[['^\'\'$', 'null'], ['(?!^\'|\'$)\'', '\'\'']]},
        bool    => {template => '%1d',       if_undef => 'null'}, # указывается только истинное значение, при проверке считаем, что совпало то истинна, иначе ложь
        ip      => {template => '\'%03d.%03d.%03d.%03d\'',  if_undef => 'null'}, # ввиде списка
        date    => {template => 'ISO',                      if_undef => 'null', replace=>[['(?:\A(?!null\Z))|(?:(?<!\Anull\Z)\Z)', '\'']]},
        time    => {template => 'ISO8601',                  if_undef => 'null', replace=>[['(?:\A(?!null\Z))|(?:(?<!\Anull\Z)\Z)', '\'']]}
    }
};

BEGIN 
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    $PACKAGE = __PACKAGE__;
    @ISA     = qw ();
}

my $USER_STRING2RAWDATA  = {};
my $USER_RAWDATA2STRING  = {};

#*******************************************************************************
#  Базовый класс для представления данных, во внутреннем формате
#*******************************************************************************
{
    package RpgType;    

    use vars qw($PACKAGE);
    use constant CHILDRENS =>
    {
        date    => sub {new RpgTypeDate(@_)},
        time    => sub {new RpgTypeDate(@_)},
        ip      => sub {new RpgTypeIP(@_)},
        bool    => sub {new RpgTypeBool(@_)},
        pathf   => sub {new RpgTypeFile(@_)}        
    };
    
    use overload
    (
        'fallback' => undef,
        '-'        => '_subtract',
        '+'        => '_add',    
        '<=>'      => '_cmp_num',
        'cmp'      => '_cmp_str',
        '""'       => '_stringify',        
        '0+'       => '_numify'      
    );
    
    $PACKAGE = __PACKAGE__;
    
    sub _subtract
    {
        my ($self, $add, $invers) = (shift, shift, shift);
        my ($left, $right)        = (undef, undef);
        
        return unless($self->is_set);
        
        $self->{base} eq 'num' || die "Error, operation '-' isn't support for base type '$self->{base}'\n";                   
        
        if (UNIVERSAL::isa($add, __PACKAGE__))
        {
            $add->{base} eq $self->{base} || die "Error, operation '-' isn't support for different types '$add->{base} != $self->{base}'\n";           
            
            $left  = $self->value;
            $right = $add->value;
        }
        elsif (!CORE::ref($add)) 
        {
            $left  = $self->value;
            $right = $add;
        }   
        else
        {
            die "Error, operation '-' is not support for type '$self->{type}' and value '$add'\n";
        }
        
        return ($invers ? $right - $left : $left - $right);
    }

    sub _add
    {
        my ($self, $add, $invers) = (shift, shift, shift);
        my ($left, $right)        = (undef, undef);
        
        return unless($self->is_set);
        
        if (UNIVERSAL::isa($add, __PACKAGE__))
        {
            $add->{base} eq $self->{base} || die "Error, operation '+' isn't support for different types '$add->{base} != $self->{base}'\n";           
            
            $left  = $self->value;
            $right = $add->value;
        }
        elsif (!CORE::ref($add)) 
        {
            $left  = $self->value;
            $right = $add;
        }   
        else
        {
            die "Error, operation '+' is not support for type '$self->{type}' and value '$add'\n";
        }
        
        return ($left + $right) if ($self->{base} eq 'num');
        return ($invers ? $right . $left : $left . $right);
    }

    sub _cmp_num
    {        
        my $self = shift;
        
        return $self->_cmp_str(@_) if($self->{base} eq 'str');
        return unless($self->is_set);
        
        my ($add, $invers) = (shift, shift);
        
        if (UNIVERSAL::isa($add, __PACKAGE__))
        {            
            return ($invers ? $add->value <=> $self->value : $self->value <=> $add->value);
        }
        elsif (!CORE::ref($add)) 
        {
            return ($invers ? $add <=> $self->value : $self->value <=> $add);
        }   

        die "Error, operation '<=>' is not support for type '$self->{type}' and value '$add'\n";
    }

    sub _cmp_str
    {
        my $self = shift;
        
        return $self->_cmp_num(@_) if($self->{base} eq 'num');
        return unless($self->is_set);
        
        my ($add, $invers) = (shift, shift);
        
        if (UNIVERSAL::isa($add, __PACKAGE__))
        {            
            return ($invers ? $add->value cmp $self->value : $self->value cmp $add->value);
        }
        elsif (!CORE::ref($add)) 
        {
            return ($invers ? $add cmp $self->value : $self->value cmp $add);
        }   

        die "Error, operation 'cmp' is not support for type '$self->{type}' and value '$add'\n";
    }

    sub _stringify
    {
        my $self = shift;
        return unless ($self->is_set);
        return $self->value;
    }

    sub _numify
    {
        my $self = shift;        
        return unless ($self->is_set);
        return ($self->{base} eq 'str' ? length($self->value) : $self->value);
    }
   
    # конструктор
    #       rval   - значение - ссылка
    #       type   - тип, если не задан то str
    #       schema - схема, если не задана то 'MAIN'
    #       
    sub new
    {
        my $class = shift;
        my %args  = (type => 'str', schema => 'MAIN', @_);

        # по базовому типу определяем дочерний класс
        if (!ref($class) && defined(CHILDRENS->{$args{type}}))
        {
            return CHILDRENS->{$args{type}}(@_);
        }

        my $self = bless {}, $class;
        
        return $self->_init(@_);
    }
    
    sub _init
    {
        my $self = shift;
        my %args = (type => 'str', schema => 'MAIN', @_);
               
        return $self if ($self->{$PACKAGE}{INIT}++);
        
        # определяем базовый тип
        my $convert = RpgTypes::GetString2Rawdata($args{schema}, $args{type});
        
        # по умолчанию базовый тип строковый
        $self->{base}   = defined($convert->{option}) ? $convert->{option}{base} : 'str';
        $self->{schema} = $args{schema};
        $self->{type}   = $args{type};
        
        return $self->set($args{rval}, $args{schema});
    }

    sub value
    {
        return shift->convert;
    }

    sub raw
    {
        return shift->{value};
    }
    
    sub schema
    {
        return shift->{schema};
    }    

    sub type
    {
        return shift->{type};
    }

    sub src
    {
        return shift->{src};
    }
    
    sub clone
    {
        return bless {%{ $_[0] }}, ref $_[0];
    }
    
    sub set
    {
        my ($self, $rval) = (shift, shift);
        my $schema        = shift || $self->schema;
        
        if (defined($rval))
        {
            ($self->{value}, $self->{schema}, $self->{src}) =
                $self->_parser(CORE::ref($rval) ? $rval : \$rval, $schema, $self->type);
        }
        else
        {
            $self->{value}  = undef;
            $self->{src}    = undef;
            $self->{schema} = $schema;
        }
        
        return $self;
    }
    
    sub _parser
    {
        my ($self, $rval, $schema, $type) = (shift, shift, shift, shift);
        my ($convert) = RpgTypes::GetString2Rawdata($schema, $type);

        defined($convert->{option}) ||
            die("Error, type '$type' isn't support for schema '$schema'");        

        return (undef, $schema, undef)
            unless (defined(${$rval}));
            
        my @ret = (${$rval} =~ /$convert->{option}{template}/s);

        $#ret >= 0 ||
            die("Error, invalid value '${$rval}' for template '$convert->{option}{template}', not found value"); 
        
        return ($#ret == 0? shift(@ret) : [@ret], $schema, ${$rval});
    }
    
    sub is_set
    {
        return defined(shift->{value});
    }
    
    sub convert
    {
        my $self    = shift;
        my $schema  = shift || $self->{schema};        
        my $convert = RpgTypes::GetRawdata2String($schema, $self->{type});
        
        defined($convert->{option}) || die "Error, type '$self->{type}' isn't support for schema '$schema'";
        
        my $ret = ($self->is_set ? sprintf($convert->{option}{template},
                                           'ARRAY' eq ref($self->{value}) ? @{$self->{value}} : $self->{value}) : $convert->{option}{if_undef});
        
        return $ret unless (defined($convert->{option}{replace}));        
        
        foreach my $replace (@{$convert->{option}{replace}})
        {
            $ret =~ s/$$replace[0]/$$replace[1]/g;            
        }
        
        return $ret;
    }
    
    1;
};

#*******************************************************************************
#  Класс для представления даты
#*******************************************************************************
{
    package RpgTypeDate;    

    use vars qw($PACKAGE @ISA $AUTOLOAD);

    @ISA     = qw(RpgType);
    $PACKAGE = __PACKAGE__;

    sub AUTOLOAD
    {
        my $self  = shift;
        my $param = $AUTOLOAD;
        my $raw   = $self->raw;
        
        $param =~ s/.*:://;
        
        defined($raw)     || die("Raw data isn't set in RpgTypeDate");        
        $raw->can($param) || die("Undefined call $AUTOLOAD");
        
        my $ret = $raw->$param(@_);
        
        return $ret
            unless (Scalar::Util::refaddr($ret));
        return $self
            if (Scalar::Util::refaddr($raw) == Scalar::Util::refaddr($ret));
        return new RpgTypeDate(rval => $ret, type => $self->type)
            if (UNIVERSAL::isa($ret, 'DateTime'));
        return $ret;        
    }
    
    BEGIN
    { 
        # внутренее представление датты ввиде массива
        my %FIELDS =
        (
            c_year      =>  0,
            c_mon       =>  1,
            c_day       =>  2,
            c_hour      =>  3,
            c_min       =>  4,
            c_sec       =>  5,
            c_msec      =>  6,
            c_epoch     =>  7
        );
        
        # создаем пространство имен - индексов
        eval " sub $_ () { $FIELDS{$_} }" foreach keys %FIELDS;
    }
    
    {
        # класс используется для формирования объект RpgTypeDate (DateTime)
        # из количества секунд с начала эпохи
        package Seconds2DateTime;
        
        use DateTime::TimeZone;

        # конструктор, на входе могут быть указаны следующие не обязательные
        # поля:
        #   seconds     - количество секунд с начала Новой Эры
        #   first_days  - время начала эпохи в днях с начала эры, по умолчанию
        #                 задается 719163 - 01/01/1970
        #   time_zone   - часовой пояс, по умолчанию Europe/Moscow
        sub new
        {
            my $class = shift;
            bless ({@_}, $class);
        }
        
        sub utc_rd_values
        {
            return ((defined($_[0]->{seconds}) ?
                            $_[0]->{seconds} / (24 * 60 * 60) : 0) + (defined($_[0]->{first_days}) ? $_[0]->{first_days} : 719163),
                    defined($_[0]->{seconds}) ?
                            $_[0]->{seconds} % (24 * 60 * 60) : 0, 0);
        }
        
        sub time_zone
        {
            return (new DateTime::TimeZone(name => ($_[0]->{time_zone} || 'Europe/Moscow')));
        }
        
        sub seconds
        {
            return shift->{seconds};
        }
        
        1;
    }    
    
    # преобразование даты представленной ввиде массива в хеш
    use constant ARR2HASH =>
    {
        year      =>  c_year ,
        month     =>  c_mon  ,
        day       =>  c_day  ,
        hour      =>  c_hour ,
        minute    =>  c_min  ,
        second    =>  c_sec
    };               
    
    # известные форматы
    use constant FORMATS =>
    {
        # dd mon yyyy hh:mm:ss:mmm(24h)
        EUROPE   =>
        {
            format => '%d %m %Y %H:%M:%S:%3N',  
            in     => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2})\s+(\d{2})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2}):(\d{3})\s*$/mo];
                $#{$ret} == 6 || die "Error, format 'EUROPE' of date $_[0]\n";
                new DateTime
                    (
                        year        => $$ret[2],
                        month       => $$ret[1],
                        day         => $$ret[0],
                        hour        => $$ret[3],
                        minute      => $$ret[4],
                        second      => $$ret[5],
                        nanosecond  => $$ret[6] * 1000000,
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'                        
                    );
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%02d %02d %04d %02d:%02d:%02d:%03d',
                        $dt->day, $dt->month, $dt->year, $dt->hour, $dt->minute, $dt->second, $dt->millisecond);                        
            }
        },
        # yyyy-mm-ddThh:mm:ss:mmm(no spaces)
        ISO8601  =>
        {
            format => '%Y-%m-%dT%H:%M:%S:%3N', 
            in     => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:(?:\:|\.)(\d{3}))?\s*$/mo];
                $#{$ret} == 6 || $#{$ret} == 5 || die "Error, format 'ISO8601' of date $_[0]\n";

                new DateTime
                    (
                        year        => $$ret[c_year],
                        month       => $$ret[c_mon],
                        day         => $$ret[c_day],
                        hour        => $$ret[c_hour],
                        minute      => $$ret[c_min],
                        second      => $$ret[c_sec],
                        nanosecond  => ($$ret[c_msec] || 0)  * 1000000,
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%04d-%02d-%02dT%02d:%02d:%02d.%03d',
                        $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second, $dt->millisecond);                        
            }
        },
        # yyyymmdd || yymmdd
        ISO  =>
        {
            format => '%Y%m%d',
            in  => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2}|\d{4})(\d{2})(\d{2})\s*$/mo];
                $#{$ret} == 2 || die "Error, format 'ISO' of date $_[0]\n";
                
                new DateTime
                    (
                        year        => $$ret[c_year] < 100 ? $$ret[c_year] + 2000 : $$ret[c_year],
                        month       => $$ret[c_mon],
                        day         => $$ret[c_day],
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                                
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%04d%02d%02d', $dt->year, $dt->month, $dt->day);
            }
        },
        # dd.mm.yyyy
        USER01  =>
        {
            format => '%d.%m.%Y',
            in  => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2})\.(\d{2})\.(\d{4})\s*$/mo];
                $#{$ret} == 2 || die "Error, format 'USER01' of date $_[0]\n";
                new DateTime
                    (
                        year        => $$ret[2],
                        month       => $$ret[1],
                        day         => $$ret[0],
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                                                
            },
            out => sub
            {                        
                my $dt = shift;                                    
                sprintf('%02d.%02d.%04d', $dt->day, $dt->month, $dt->year);
            }
        },
        # dd.mm.yyyy hh:mm:ss:mmm
        USER02  =>
        {
            format => '%d.%m.%Y %H:%M:%S:%3N',
            in  => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2}):(\d{3})\s*$/mo];
                $#{$ret} == 6 || die "Error, format 'USER02' of date $_[0]\n";
                new DateTime
                    (
                        year        => $$ret[2],
                        month       => $$ret[1],
                        day         => $$ret[0],
                        hour        => $$ret[3],
                        minute      => $$ret[4],
                        second      => $$ret[5],
                        nanosecond  => $$ret[6] * 1000000,
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%02d.%02d.%04d %02d:%02d:%02d:%03d',
                        $dt->day, $dt->month, $dt->year, $dt->hour, $dt->minute, $dt->second, $dt->millisecond);
            }
        },                                
        # hh:mm:ss dd.mm.yy 
        USER03  =>
        {
            format => '%H:%M:%S %d.%m.%y',
            in  => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2}):(\d{2}):(\d{2})\s+(\d{2})\.(\d{2})\.(\d{2})\s*$/mo];
                $#{$ret} == 6 || die "Error, format 'USER03' of date $_[0]\n";
                new DateTime
                    (
                        year        => ($$ret[5] <= 50 ? $$ret[5] + 2000 : 1900),
                        month       => $$ret[4],
                        day         => $$ret[3],
                        hour        => $$ret[0],
                        minute      => $$ret[1],
                        second      => $$ret[2],
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%02d:%02d:%02d %02d.%02d.%02d',
                        $dt->hour, $dt->minute, $dt->second, $dt->day, $dt->month, ($dt->year >= 2000 ? $dt->year - 2000 : $dt->year - 1900));
            }
        },
        # yyyymmddhhmmss || yymmddhhmmss
        USER04  =>
        {
            format => '%Y%m%d%H%M%S', 
            in     => sub
            {
                my $ret = [$_[0] =~ /^\s*(\d{2}|\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\s*$/mo];
                $#{$ret} == 5 || die "Error, format 'USER04' of date $_[0]\n";

                new DateTime
                    (
                        year        => $$ret[c_year] < 100 ? $$ret[c_year] + 2000 : $$ret[c_year],
                        month       => $$ret[c_mon],
                        day         => $$ret[c_day],
                        hour        => $$ret[c_hour],
                        minute      => $$ret[c_min],
                        second      => $$ret[c_sec],
                        #time_zone   => 'UTC'
                        locale      => 'ru_RU',
                        time_zone   => 'Europe/Moscow'
                    );                
            },
            out => sub
            {
                my $dt = shift;                                    
                sprintf('%04d%02d%02d%02d%02d%02d',
                        $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);                        
            }
        }        
    };
            
    
    use overload
    (
        '-'      => '_subtract',
        '+'      => '_add',    
        '<=>'    => '_cmp_str',
        'cmp'    => '_cmp_str',
        '""'     => '_stringify',        
        '0+'     => '_numify',
        fallback => undef # генерация ошибки
    );          

    #***************************************************************************
    #
    #   Перегрузка оператора '-', возвращает количество секунд с нэ.
    #   закрытый метод 
    #
    sub _subtract
    #
    #   $left   -   ссылка на объект RpgTypeDate
    #   $right  -   ссылка на объект RpgTypeDate, ссылка на объект RpgType,
    #               целое число секунд с нэ., массив (год, месяц ...), хеш
    #               (year, month, day, hour, minute, second, time_zone), ссылка
    #               на объект DateTime или ссылка на объект DateTime::Duration    
    #   $invers -   очередность членов в выражение
    #
    #***************************************************************************    
    {
        my ($left, $right, $invers) = (shift, shift, shift);

        return unless ($left->is_set);

        if (UNIVERSAL::isa($right, 'DateTime::Duration'))
        {
            !$invers || die "error, left operand can't be DateTime::Duration";
            return (($left->raw - $right)->utc_rd_as_seconds);
        }
        
        $right = RpgTypeDate::Some2UtcRataDie($right);
        
        return ($invers ? $right - $left->value : $left->value - $right);
    }

    #***************************************************************************
    #
    #   Перегрузка оператора '+', возвращает количество секунд с нэ.
    #   закрытый метод 
    #
    sub _add
    #
    #   $left   -   ссылка на объект RpgTypeDate
    #   $right  -   ссылка на объект RpgTypeDate, ссылка на объект RpgType,
    #               целое число секунд с нэ., массив (год, месяц ...), хеш
    #               (year, month, day, hour, minute, second, time_zone), ссылка
    #               на объект DateTime или ссылка на объект DateTime::Duration    
    #   $invers -   очередность членов в выражение
    #
    #***************************************************************************    
    {
        my ($left, $right) = (shift, shift);
        
        return unless ($left->is_set);
        
        if (UNIVERSAL::isa($right, 'DateTime::Duration'))
        {
            return (($left->raw + $right)->utc_rd_as_seconds);
        }

        return ($left->value + RpgTypeDate::Some2UtcRataDie($right));
    }

    #***************************************************************************
    #
    #   Перегрузка операторов сравнения (<=>)
    #
    sub _cmp_str
    #
    #   $left   -   ссылка на объект RpgTypeDate
    #   $right  -   ссылка на объект RpgTypeDate, ссылка на объект RpgType,
    #               целое число секунд с нэ., массив (год, месяц ...), хеш
    #               (year, month, day, hour, minute, second, time_zone) или
    #               ссылка на объект DateTime
    #   $invers -   очередность членов в выражение
    #
    #***************************************************************************        
    {
        my ($left, $right, $invers) = (shift, shift, shift);
        
        return unless ($left->is_set);
        
        $right = RpgTypeDate::Some2UtcRataDie($right);
        
        return ($invers ? $right <=> $left->value : $left->value <=> $right);
    }

    #***************************************************************************
    #
    #   Метод срабатывает когда объект участвует в строковом преобразовании
    #
    sub _stringify
    #
    #***************************************************************************            
    {
        my $self = shift;
        return unless ($self->is_set);
        return $self->convert;
    }

    #***************************************************************************
    #
    #   Метод срабатывает когда объект участвует в числовом преобразовании
    #
    sub _numify
    #
    #***************************************************************************                
    {
        my $self = shift;
        return unless ($self->is_set);
        return $self->value;
    }    
    
    sub DESTROY
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

    sub new
    {
        my $class = shift;        
        my %args  = (type => 'date', schema => 'MAIN', @_);        
        
        # если формат задан то формируем объект на его основе
        return new RpgTypeDate(rval   => Str2DateTime((ref($args{rval}) ? ${$args{rval}} : $args{rval}), $args{format}),
                               schema => $args{schema})
            if (defined($args{format}) && defined($args{rval}));
        
        my $self  = bless({}, $class);        
        
        foreach my $parent (@ISA)
        {
            # вызываем конструкторы базовых классов
            next
                if ($self->{$parent}{CREATE}++); # запрет на повторный вызов
            
            my $init = $parent->can('_init');
            
            $self->$init(%args)
                if $init; 
        }
        
        return $self;
    }

    sub clone
    {
        my $self = shift;
        my $new  = bless {%{ $self }}, ref $self;
        
        $new->{value} = $new->{value}->clone if ($new->is_set);
        
        return $new;
    }    
    
    #***************************************************************************
    #
    sub _parser
    #
    #   $rval   -   ссылка на объект RpgTypeDate, ссылка на объект RpgType,
    #               целое число секунд с начала эпохи, массив (год, месяц ...), 
    #               хеш (year, month, day, hour, minute, second, time_zone) или
    #               ссылка на объект DateTime
    #   $schema -   имя схемы
    #
    #***************************************************************************
    {
        my ($self, $rval, $schema, $type) = (shift, shift, shift, shift);
        my $ret    = undef;        
        my $src    = undef;
                
        if (!CORE::ref($rval) || 'SCALAR' eq CORE::ref($rval)) # строка - дата
        {
            my ($convert) = RpgTypes::GetString2Rawdata($schema, $type);
            
            defined($convert->{option}) || die("Error, type '$type' isn't support for schema '$schema'");
            
            $src = ref($rval) ? ${$rval} : $rval;
            $ret = Str2DateTime($src, shift || $convert->{option}{template});
        }
        elsif (UNIVERSAL::isa($rval, 'RpgTypeDate'))
        {
            $ret    = $rval->clone;
            $src    = $rval->src;
            $schema = $rval->schema;
            $type   = $rval->type;
        }
        elsif (UNIVERSAL::isa($rval, 'RpgType'))
        {
            $src = $rval->value;
            $ret = Str2DateTime($src, shift || 'ISO8601');            
        }
        elsif (UNIVERSAL::isa($rval, 'DateTime'))
        {
            $ret = $rval->clone;
        }
        elsif (UNIVERSAL::isa($rval, 'Seconds2DateTime'))
        {
            $ret = DateTime->from_object(object => $rval, locale => 'ru_RU');
        }
        elsif ('ARRAY' eq ref($rval))
        {
            $ret = new DateTime(map{$_ => $$rval{ARR2HASH->{$_}}} grep {defined $$rval{ARR2HASH->{$_}}} keys(%{ARR2HASH()}), locale => 'ru_RU', time_zone => 'Europe/Moscow');
        }
        elsif ('HASH' eq ref($rval))
        {
            $ret = new DateTime(time_zone => 'Europe/Moscow', locale => 'ru_RU', %{$rval});
        }
        
        defined ($ret) || die "Error, unknown type of object, value is: $rval";
        
        return (wantarray ? ($ret, $schema, $src) : $ret);
    }
    
    #***************************************************************************
    #
    #   Возвращает количество секунд с начала Новой Эры (00.00.0000)   
    #
    sub value
    #
    #***************************************************************************    
    {
        my $self = shift;
        return ($self->is_set ? $self->{value}->utc_rd_as_seconds : undef);
    }

    #***************************************************************************
    #
    #   Преобразует ссылку на объект RpgTypeDate, ссылку на объект RpgType, целое
    #   число секунд с начала Новой Эры, массив (год, месяц ...), хеш (year,
    #   month, day, hour, minute, second, time_zone) или ссылку на объект DateTime
    #   в число секунд в UTC с начала Новой Эры
    #
    sub Some2UtcRataDie
    #
    #   $some   - значение для перевода
    #   $schema - имя схемы, по умолчанию ISO8601
    #
    #***************************************************************************
    {
        my $some = shift;
        my $sec  = undef;
                
        if (!CORE::ref($some) || 'SCALAR' eq CORE::ref($some)) # 
        {
            # скалярное значение
            $sec = ref($some) ? ${$some} : $some;
            ($sec =~ /^\d+$/) || die "can't convert value $sec to UTC Rata Die seconds";
        }
        elsif (UNIVERSAL::isa($some, 'RpgTypeDate'))
        {
            $sec = $some->value;
        }
        elsif (UNIVERSAL::isa($some, 'RpgType'))
        {            
            $sec = Str2DateTime($some, shift || 'ISO8601')->utc_rd_as_seconds;            
        }
        elsif (UNIVERSAL::isa($some, 'DateTime'))
        {
            $sec = $some->utc_rd_as_seconds;
        }
        elsif (UNIVERSAL::isa($some, 'Seconds2DateTime'))
        {
            $sec = $some->seconds;
        }
        elsif ('ARRAY' eq ref($some))
        {
            $sec = (new DateTime(map{$_ => $$some{ARR2HASH->{$_}}} grep {defined $$some{ARR2HASH->{$_}}} keys(%{ARR2HASH()}), locale => 'ru_RU', time_zone   => 'Europe/Moscow'))->utc_rd_as_seconds;
        }
        elsif ('HASH' eq ref($some))
        {
            $sec = (new DateTime(time_zone => 'Europe/Moscow', locale => 'ru_RU', %{$some}))->utc_rd_as_seconds;
        }
        
        defined ($sec) || die "Error, unknown type of object, value is: $some";
        
        return $sec;
    }
    
    #***************************************************************************
    #
    #   Изменение даты, $dt->set(year => 1977);
    #   см. DateTime::set 
    sub set_part
    #
    #***************************************************************************    
    {
        return (shift->{value}->set(@_));
    }    

    #***************************************************************************
    #
    #   Преобразование даты к строковому представлению
    #
    sub convert
    #
    #   $schema -   схема, согласно которой делается преобразование в строку
    #
    #***************************************************************************                
    {
        my $self    = shift;
        my $schema  = shift || $self->{schema};
        my $convert = RpgTypes::GetRawdata2String($schema, $self->{type});
        
        defined($convert->{option}) || die("Error, type '$self->{type}' isn't support for schema '$schema'");
        
        my $ret = ($self->is_set ? DateTime2Str($self->raw, $convert->{option}{template}) : $convert->{option}{if_undef});
        
        return $ret unless (defined($convert->{option}{replace}));        
        
        foreach my $replace (@{$convert->{option}{replace}})
        {
            $ret =~ s/$$replace[0]/$$replace[1]/g;
        }
        
        return $ret;
    }
    
    sub format
    {
        return DateTime2Str(shift->raw, shift);
    }    
    
    sub GetStartEpoch
    {
        return [0, 1, 1, 0, 0, 0, 0];
    }
      
    #*******************************************************************************
    #
    #  Функция преобразует строку в дату, согласно переданому шаблону
    #  возвращает объект DateTime
    #
    sub Str2DateTime
    #
    #  $strDate - строка - дата
    #  $strFrmt - шаблон
    #
    #*******************************************************************************
    {
        my $strDate = shift;
        my $strFrmt = shift || 'ISO8601';
        
        # допустимо неопределееное значение, в этом случае устанавливается пустой массив
        return undef unless(defined($strDate) && '' ne $strDate);

        # если формат известный            
        if (defined(FORMATS->{$strFrmt}))
        {
            return FORMATS->{$strFrmt}{in}($strDate);
        }
        
        my $parser = new DateTime::Format::Strptime
            (
                pattern   => $strFrmt,
                #time_zone   => 'UTC',
                locale    => 'ru_RU',
                time_zone => 'Europe/Moscow'
            );
        
        my $ret = $parser->parse_datetime($strDate);
        
        defined($ret) ||
            die sprintf('Error, parser DateTime return: %s', $parser->errmsg);
        
        return $ret;
    }  ## Str2DateTime
    
    #*******************************************************************************
    #
    #  Функция преобразует строку в дату, согласно переданому шаблону,
    #  возвращает строку
    #
    sub DateTime2Str
    #
    #  $date    - дата
    #  $strFrmt - шаблон
    #
    #*******************************************************************************
    {
        my $date    = shift;
        my $strFrmt = shift || 'ISO8601';

        # допустимо неопределееное значение
        return undef unless(defined($date));
        
        # если формат известный            
        if (defined(FORMATS->{$strFrmt}))
        {            
            return FORMATS->{$strFrmt}{out}($date);
        }
        
        return $date->strftime($strFrmt);
    }  ## DateTime2Str

    sub Format
    {
        return DateTime2Str(Str2DateTime(shift, shift), shift);
    }
    
    sub GetCurrDate
    {
        return new RpgTypeDate(rval => DateTime->now(locale => 'ru_RU', time_zone => 'Europe/Moscow'));
    }

    1;    
};

#*******************************************************************************
#  Класс для представления IP
#*******************************************************************************
{
    package RpgTypeIP;    

    use vars qw($PACKAGE @ISA);

    @ISA     = qw(RpgType);
    $PACKAGE = __PACKAGE__;

    sub DESTROY
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

    sub new
    {
        my $class = shift;
        my $self  = bless({}, $class);
        my %args  = (type => 'ip', schema => 'MAIN', @_);        
        
        foreach my $parent (@ISA)
        {
            # вызываем конструкторы базовых классов
            next
                if ($self->{$parent}{CREATE}++); # запрет на повторный вызов
            
            my $init = $parent->can('_init');
            
            $self->$init(%args)
                if $init; 
        }
        
        return $self;
    }
    
    sub value
    {
        my $self = shift;
        return unless ($self->is_set);
        return sprintf('%03d.%03d.%03d.%03d', @{$self->raw});
    }    
    
    1;    
};

#*******************************************************************************
#  Класс для представления bool
#*******************************************************************************
{
    package RpgTypeBool;    

    use vars qw($PACKAGE @ISA);

    @ISA     = qw(RpgType);
    $PACKAGE = __PACKAGE__;

    sub DESTROY
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

    sub new
    {
        my $class = shift;
        my $self  = bless({}, $class);
        my %args  = (type => 'bool', schema => 'MAIN', @_);        
        
        foreach my $parent (@ISA)
        {
            # вызываем конструкторы базовых классов
            next
                if ($self->{$parent}{CREATE}++); # запрет на повторный вызов
            
            my $init = $parent->can('_init');
            
            $self->$init(%args)
                if $init; 
        }
        
        return $self;
    }
    
    sub set
    {
        my ($self, $rval) = (shift, shift);
        my $schema        = shift || $self->schema;
        
        ($self->{value}, $self->{schema}, $self->{src}) =
            $self->_parser(CORE::ref($rval) ? $rval : \$rval, $schema, $self->type);
        
        return $self;
    }    

    sub _parser
    {
        my ($self, $rval, $schema, $type) = (shift, shift, shift, shift);
        my ($convert) = RpgTypes::GetString2Rawdata($schema, $type);

        defined($convert->{option}) ||
            die("Error, type '$type' isn't support for schema '$schema'");        
        
        if (defined(${$rval}) && ${$rval} =~ /$convert->{option}{template}/)
        {
            return (utils::TRUE, $schema, ${$rval});
        }
        
        return (utils::FALSE, $schema, ${$rval});
    }   
    
    1;    
};

#*******************************************************************************
#  Класс для пути к файлу
#*******************************************************************************
{
    package RpgTypeFile;    

    use vars qw($PACKAGE @ISA);

    @ISA     = qw(RpgType);
    $PACKAGE = __PACKAGE__;

    sub DESTROY
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

    sub new
    {
        my $class = shift;
        my $self  = bless({}, $class);
        my %args  = (type => 'pathf', schema => 'MAIN', @_);        
        
        foreach my $parent (@ISA)
        {
            # вызываем конструкторы базовых классов
            next
                if ($self->{$parent}{CREATE}++); # запрет на повторный вызов
            
            my $init = $parent->can('_init');
            
            $self->$init(%args)
                if $init; 
        }
        
        return $self;
    }
    
    1;    
};

#*******************************************************************************
# 
#  Метод загружает шаблоны для проверки значений и их преобразования во 
#  внутренее представление
#
sub LoadString2Rawdata
#
#  указатель на массив хешей (формат ниже)
#
#   [{type, schema, style}, ..., {}]
#
#   type   - имя типа
#   schema - источник (CGI, SQL, FILE, ...)
#   style  - шаблон формата
#
#*******************************************************************************
{
    return _load_user_rules_convert($USER_STRING2RAWDATA, shift);
}

#*******************************************************************************
# 
#  Метод загружает шаблоны для преобразования из внутренего представления в 
#  строку
#
sub LoadRawdata2String
#
#  указатель на массив хешей (формат ниже)
#
#   [{type, schema, style}, ..., {}]
#
#   type   - имя типа
#   schema - источник (CGI, SQL, FILE, ...)
#   style  - шаблон формата
#
#*******************************************************************************
{
    return _load_user_rules_convert($USER_RAWDATA2STRING, shift);
}

sub GetString2Rawdata
{
    my ($schema, $type) = (shift, shift);

    defined($schema) || die "Error, schema not set";
    defined($type)   || die "Error, type not set";

    return {is_default => FALSE,  option => $USER_STRING2RAWDATA->{$schema}{$type}}  
        if (defined($USER_STRING2RAWDATA->{$schema}{$type})); 
        
    return {is_default => TRUE, option => DEFAULT_STRING2RAWDATA->{$schema}{$type}};    
}

sub GetRawdata2String
{
    my ($schema, $type) = (shift, shift);

    defined($schema) || die "Error, schema not set";
    defined($type)   || die "Error, type not set";
    
    return {is_default => FALSE,  option => $USER_RAWDATA2STRING->{$schema}{$type}}  
        if (defined($USER_RAWDATA2STRING->{$schema}{$type})); 
        
    defined($schema) || die "Error, schema not set";
    defined($type)   || die "Error, type not set";
        
    return {is_default => TRUE, option => DEFAULT_RAWDATA2STRING->{$schema}{$type}};    
}

sub String2String
{
    my ($rval, $type, $i_schema, $o_schema) = (shift, shift, shift, shift);
    my $ret = new RpgType(rval => $rval, type => $type, schema => $i_schema);
    return $ret->convert($o_schema);
}

1;

