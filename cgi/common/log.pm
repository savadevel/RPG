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

package RpgLog;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA @EXPORT $VERSION);
use Fcntl ':flock'; # import LOCK_* constants
use English;
use strict;

use Exporter;
use DBI;

use utils;

use constant LOG_F => 6;
use constant LOG_D => 5;
use constant LOG_I => 4;
use constant LOG_W => 3;
use constant LOG_E => 2;
use constant LOG_A => 1;

use constant MAX_LEN_MSG => 5000; # 

use constant LVL2STR => 
{
    1 => 'a',
    2 => 'e',    
    3 => 'w',
    4 => 'i',
    5 => 'd',
    6 => 'f'
};

use constant PERMISSION2STR => 
{
    0 => '-',
    1 => 'r',    
    2 => 'w',
};

use constant FIELDS =>
{
    log => 
    {
        order => 1,
        type  => 'chr',
        desc  => 'Тип сообщения'
    },
    sid  => 
    {
        order => 2,
        type  => 'int',
        desc  => 'SID'
    },
    uid    =>
    {
        order => 3,
        type  => 'int',
        desc  => 'UID'        
    },
    login => 
    {
        order => 4,
        type  => 'str',
        desc  => 'Логин'
    },
    host => 
    {
        order => 5,
        type  => 'str',
        desc  => 'IP машины'
    },
    report => 
    {
        order => 6,
        type  => 'str',
        desc  => 'Ресурс'
    },
    permission => 
    {
        order => 7,
        type  => 'chr',
        desc  => 'Уровень доступа'
    },
    date => 
    {
        order  => 8,
        type   => 'time',
        format => '%Y%M%D%HH%MM%SS',
        desc   => 'Дата'
    },
    val => 
    {
        order  => 9,
        type   => 'txt',
        desc   => 'Сообщение'
    }
};

BEGIN
{
    setlocale(&POSIX::LC_CTYPE, "Russian_Russia.1251");

    $VERSION = 0.01;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(LOG_D LOG_W LOG_I LOG_E);    
}

#*******************************************************************************
#
#   Конструктор логера
#
sub new
#
#   параметры инициализации, см. метод set
#
#*******************************************************************************
{
    ref($_[0]) && die "Error, class F136::RpgAdmExportCorrToExcel can't use in inheritance\n";        
    my ($class) = shift;
    my ($self)  = bless({}, $class);

    $self->{SETT} =
        { 
            DEBUG_LEVEL => LOG_E,  # уровень отладочной инф.
            APP         => undef,  # имя приложения
            ADDRESS     => undef,  # машина пользователя
            REPORT      => undef,  # имя отчета
            UID         => undef,  # идентификатор пользователя
            SID         => CreateGUID(), # идентификатор сессии                                      
            LEN_MSG     => MAX_LEN_MSG, # длина сообщения в журнале
            LOG_TO_DB   => 'Y',    # если значение отлично от undef вывод направляется в БД
            PRC_LOG     => undef,  # процедура ведения журнала в БД
            DB          => undef,  # если задан то пытается вывести данные через DBI
            PATH        => undef,  # путь к журналу
            USER        => 'guest',# имя пользователя
            PERMISSION  => 0       # уровень доступа
        };
    $self->{HNDL}  = undef;  # идентификатор журнала в системе
    $self->{GUID}  = $self->{SETT}{SID};
    $self->set(@_);
    
    return $self;
}

#*******************************************************************************
#
# Динамическое изменение параметров работы логера
#
sub set
#
#    DEBUG_LEVEL - уровень отладочной инф.
#    APP         - имя приложения
#    ADDRESS     - машина пользователя
#    UID         - идентификатор пользователя
#    SID         - идентификатор сессии    
#    REPORT      - имя отчета                                  
#    DB          - если задан то пытается вывести данные через DBI
#    PATH        - путь к журналу
#    PRC_LOG     - процедура ведения журнала в БД
#    LOG_TO_DB   - если значение отлично от undef вывод направляется в БД
#    LEN_MSG     -
#    USER        - имя пользователя
#    PERMISSION  - уровень доступа
#    определяются как именнованные параметры
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($sid)  = $self->{SETT}{SID};
    
    $self->{SETT}             = {%{$self->{SETT}}, @_};    
    
    $self->{SETT}{SID}        = defined($self->{SETT}{SID}) ? $self->{SETT}{SID} : '';
    $self->{SETT}{USER}       = $self->{SETT}{USER}       || '';
    $self->{SETT}{UID}        = $self->{SETT}{UID}        || '';
    $self->{SETT}{PERMISSION} = $self->{SETT}{PERMISSION} || 0;
    $self->{SETT}{REPORT}     = $self->{SETT}{REPORT}     || '';
    $self->{SETT}{LEN_MSG}    = $self->{SETT}{LEN_MSG}    || MAX_LEN_MSG;

    unless (exists(PERMISSION2STR->{$self->{SETT}{PERMISSION}}))
    {
        $self->{SETT}{PERMISSION} = 0;
        warn("Warning, invalid value of permission: $self->{SETT}{PERMISSION}\n");        
        return FALSE;    
    }
    
    return TRUE;
}

#*******************************************************************************
#
DESTROY
#
#*******************************************************************************
{
    my $self = shift;
    close($self->{SETT}{HNDL}) if (defined($self->{SETT}{HNDL}));    
}

#*******************************************************************************
#
sub out
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($lvl)  = shift;
    
    $lvl = 6 unless (exists(LVL2STR->{$lvl}));
    
    if (int($lvl) > int($self->{SETT}{DEBUG_LEVEL}))
    {
        # установленный уровень отладочной инф. меньше чем у текущего сообщения        
        return FALSE; 
    }

    my ($template) = shift;
    my ($msg)      = ($#_ >= 0 ? sprintf($template, @_) : $template);    

    if (int($self->{SETT}{DEBUG_LEVEL}) >= 6)
    {
        my @caller = caller(1);

        if ($#caller >= 3)
        {
            $msg = "{$caller[0]:$caller[1]:$caller[2]:$caller[3]} $msg";
        }
        else
        {
            $msg = "{?:?:?:?} $msg";            
        }        
    }
    elsif (int($self->{SETT}{DEBUG_LEVEL}) >= 5)
    {
        my @caller = caller(1);

        if ($#caller >= 3)
        {
            $msg = "{$caller[3]:$caller[2]} $msg";
        }
        else
        {
            $msg = "{?:?} $msg";            
        }        
    }

    # чистка выводимой строки
    $msg =~ s/\n|\r/ /mgo;
    $msg =~ s/(^\s+)|(\s+$)//mgo;    
    $msg =~ s/\s{2,}/ /mgo;
    $self->_out2file($lvl, \$msg);
    $msg =~ s/'/"/go; # Строки оформляются символом (') так что заменяем на (")
    $self->_out2db($lvl, \$msg);
    
    return TRUE;
}
    
#*******************************************************************************
#
sub _out2file
#
#*******************************************************************************
{
    my ($self, $lvl, $msg) = (shift, shift, shift);
    
    $self->{HNDL} = undef;
    
    unless (defined($self->{SETT}{PATH}))
    {
        return;
    }    
    unless(open($self->{HNDL}, ">>$self->{SETT}{PATH}/rpg_" . strftime("%Y%m%d", localtime) . ".log"))
    {
        $self->{HNDL} = undef;
        warn(sprintf("Can't open file %s: $! \n", $self->{SETT}{PATH}));
        return;
    }
    
    $self->_lock();
    my $txt = sprintf
        (
            "[%s][%s][%s][%s][%s][%s][%s][%s] %s\n",
            LVL2STR->{$lvl},
            $self->{SETT}{SID},
            $self->{SETT}{UID},
            $self->{SETT}{USER}, 
            $self->{SETT}{ADDRESS},
            $self->{SETT}{REPORT},
            PERMISSION2STR->{$self->{SETT}{PERMISSION}},                                    
            strftime("%y%m%d%H%M%S", localtime), 
            $$msg
        );
    syswrite($self->{HNDL}, $txt, length($txt));    
    $self->_unlock();
    
    close($self->{HNDL});
}

#*******************************************************************************
#
sub _out2db
#
#*******************************************************************************
{
    my ($self, $lvl, $msg) = (shift, shift, shift);
    
    unless (    defined($self->{SETT}{DB}) 
            and 
                defined($self->{SETT}{PRC_LOG}) 
            and 
                defined($self->{SETT}{LOG_TO_DB}))
    {
        return;
    }        

    foreach (0..(length($$msg)/MAX_LEN_MSG))
    {
        # формат вызова: denisn.pr_rpg_to_log 'APP', 'LVL', 'MSG'
        my ($sql) = sprintf('exec %s \'%s\', \'%s\', \'%s\'', 
                            $self->{SETT}{PRC_LOG},                                                        
                            $self->{SETT}{APP}, 
                            LVL2STR->{$lvl},
                            substr($$msg, $_ * MAX_LEN_MSG, MAX_LEN_MSG));
                            
        $self->{SETT}{DB}->do($sql);
    }
}

#*******************************************************************************
#
sub out_env
#
#*******************************************************************************
{
    my ($self) = shift;
    my ($env)  = join("; ", map {"$_ = $ENV{$_}"} sort(keys(%ENV)));    
    $env =~ s/\n//g;
    $env =~ s/"/'/g;
    $env =~ s/%/%%/g;
    $self->out(shift || LOG_D, $env);
}

#*******************************************************************************
#
sub out_ref
#
#*******************************************************************************
{
    my $str  =  '';
    my $self = shift;
    my $lvl  = shift;
    my $val  = shift;
    
    if    (ref($val) eq 'ARRAY')
    {
        $str = join(";", @{$val});
    }
    elsif (ref($val) eq 'SCALAR')
    {
        $str = $$val;
    }
    elsif (ref($val) eq 'HASH')
    {
        $str = join(";", map {
                                if (defined($val->{$_}))
                                {
                                    "$_ = $val->{$_}";                                    
                                }
                                else
                                {
                                    "$_ =";
                                }
                             } keys(%{$val}));
    }
    else
    {   
        $str = $val;
    }
    
    $str =~ s/"/'/go;
    $str =~ s/%/%%/go;

    $self->out($lvl, $str);
}

#*******************************************************************************
#
sub _lock 
#
#*******************************************************************************
{
    flock($_[0]->{HNDL}, LOCK_EX);
    # and, in case someone appended
    # while we were waiting...
    seek($_[0]->{HNDL}, 0, 2);
}

#*******************************************************************************
#
sub _unlock
#
#*******************************************************************************
{
    flock($_[0]->{HNDL}, LOCK_UN);
}


#*******************************************************************************
#
#  Метод чтения лога, построчно
#
sub load
#
#  call  - ссылка на процедуру которая будет вызвана после прочтения корректной 
#          строки, формат вызова (номер строки, строка ввиде ссылки на хеш)
#  date  - метка времени в формате ГГММДД
#  first - позиция начала чтения
#  last  - позиция окончания чтения
#
#*******************************************************************************
{
    my $self  = shift;
    my $call  = shift;
    my $date  = shift || strftime("%y%m%d", localtime);
    my $first = shift;
    my $last  = shift;
    
    return unless(defined($call) and 'CODE' eq ref($call));
    
    $self->{HNDL} = undef;
 
    unless(open($self->{HNDL}, "<$self->{SETT}{PATH}/rpg_$date.log"))
    {
        $self->{HNDL} = undef;
        $self->out(LOG_E, "Can't load file '%s', becose: %s", $self->{SETT}{PATH}, $!);
        return;
    }
    
    $self->_lock();
    
    local *HNDL = $self->{HNDL};
    
    # переносим указатель в начало файла
    seek(HNDL, 0, 0);
    
    my @fields = sort {FIELDS->{$a}{order} <=> FIELDS->{$b}{order}} keys(%{FIELDS()});
        
    # читаем файл по строкам
    for (my $row = 0; <HNDL>; $row++)
    {        
        next if (defined($first) && $first > $row);

        my @tmp = ($_ =~ /^\[(\w)\]\[(\d+)\]\[(\d+)\]\[([\w\\]+)\]\[([\w:\.]+)\]\[(\w+)\]\[(\w)\]\[(\d+)\]\s+(.*)$/io);        
        next unless (@tmp > 0);
        my %var;
        @var{@fields} = @tmp;
        $call->($row, \%var);
    }

    $self->_unlock();
    
    close($self->{HNDL});    
}

1;
