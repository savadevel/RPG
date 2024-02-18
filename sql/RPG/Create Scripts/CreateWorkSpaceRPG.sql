use RPG_BD
go

go                 
    if object_id('rpg_develop.fn_rpg_get_sid') is not null
    begin
        drop function rpg_develop.fn_rpg_get_sid
    end
go

/***************************************************************************************/
-- функция id текущей сессии, если не определен то null
/***************************************************************************************/
create function rpg_develop.fn_rpg_get_sid() returns int
as
begin    
    return 
    (    
--        isnull(
            (
                select max(rpg.sid) 
                from 
                        master..sysprocesses sys 
                    join 
                        rpg_develop.rpg_sessions rpg 
                    on 
                        sys.login_time = rpg.sdate and sys.spid = rpg.spid and sys.spid = @@SPID
            )
--, 0)
    )
end
go




go
    if object_id('rpg_develop.fn_rpg_curr_rowver') is not null
    begin
        drop function rpg_develop.fn_rpg_curr_rowver
    end
go

/***************************************************************************************/
-- функция возвращает текущую версию
/***************************************************************************************/
create function rpg_develop.fn_rpg_curr_rowver
    (
        @strReport varchar(32) -- имя версии
    )
    returns int
as
begin    
    return (select curver 
            from  rpg_develop.rpg_dic_rowver d
            where report = @strReport)
end
go


go
    if object_id('rpg_develop.fn_rpg_sys_identity') is not null
    begin
        drop function rpg_develop.fn_rpg_sys_identity
    end
go

/***************************************************************************************/
-- функция формирования уникальных значений для столбца ID
/***************************************************************************************/
create function rpg_develop.fn_rpg_sys_identity
    (
        @tid int -- id таблицы
    )
    returns int
as
begin    
    return isnull((select min(id) from rpg_develop.rpg_sys_identity (XLOCK) where tid = @tid) + 1, 0)
end
go


go
    if object_id('rpg_develop.fn_rpg_param_rowver') is not null
    begin
        drop function rpg_develop.fn_rpg_param_rowver
    end
go

/***************************************************************************************/
-- функция возвращает параметры версии, значения @strParam
--  is_fix  - если версия не зафиксированна то 1 или 0 в противном случае
--  is_base - если версия базовая то 1 или 0 в противном случае
--  is_curr - если версия текущая то 1 или 0 в противном случае
-- если версия не существует то возвращается -1
/***************************************************************************************/
create function rpg_develop.fn_rpg_param_rowver
    (
        @strReport varchar(32), -- имя версии
        @iRowVer   int,         -- номер версии
        @strParam  varchar(8)      -- параметр
    )
    returns int
as
begin    
    return isnull(
    (
        select 
                case @strParam
                    when 'is_fix' then is_fix
                    when 'is_base' then is_base
                    when 'is_curr' then is_curr
                    else -2
                 end
        from  rpg_develop.vw_rpg_rowver
        where report = @strReport and rowver = @iRowVer
    ), -1)
end
go



CREATE TABLE RPG_BD.rpg_develop.rpg_dic_groups (
       grp                  varchar(32) NOT NULL,
       type                 binary(1) NOT NULL,
       note                 varchar(256) NOT NULL
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_groups ON RPG_BD.rpg_develop.rpg_dic_groups
(
       grp                            ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_log (
       log                  varchar(3) NOT NULL,
       level                int NOT NULL,
       note                 varchar(512) NULL
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_log ON RPG_BD.rpg_develop.rpg_dic_log
(
       log                            ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_permissions (
       permission           tinyint NOT NULL,
       note                 varchar(512) NULL
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_permissions ON RPG_BD.rpg_develop.rpg_dic_permissions
(
       permission                     ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_reports (
       report               varchar(32) NOT NULL,
       preport              varchar(32) NULL,
       level                int NULL,
       lkey                 int NULL,
       rkey                 int NULL,
       name                 varchar(256) NOT NULL,
       lib                  varchar(32) NOT NULL,
       path                 varchar(512) NOT NULL,
       note                 varchar(512) NULL
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_reports ON RPG_BD.rpg_develop.rpg_dic_reports
(
       report                         ASC
)
go

CREATE INDEX XIF1rpg_dic_reports ON RPG_BD.rpg_develop.rpg_dic_reports
(
       preport                        ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_rowver (
       note                 varchar(512) NULL,
       curver               int NOT NULL,
       report               varchar(32) NOT NULL,
       outver               int NULL,
       basver               int NOT NULL DEFAULT (rpg_develop.fn_rpg_sys_identity(object_id('rpg_develop.rpg_rowver'))),
       sid                  int NOT NULL DEFAULT (rpg_develop.fn_rpg_get_sid())
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       report                         ASC
)
go

CREATE UNIQUE INDEX XAK1rpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       basver                         ASC
)
go

CREATE INDEX XIF1rpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       curver                         ASC
)
go

CREATE INDEX XIF2rpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       outver                         ASC
)
go

CREATE INDEX XIF4rpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       basver                         ASC
)
go

CREATE INDEX XIF5rpg_dic_rowver ON RPG_BD.rpg_develop.rpg_dic_rowver
(
       sid                            ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_types (
       type                 varchar(16) NOT NULL,
       note                 varchar(512) NULL
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_types ON RPG_BD.rpg_develop.rpg_dic_types
(
       type                           ASC
)
go


CREATE TABLE RPG_BD.rpg_develop.rpg_dic_users (
       uid                  int NOT NULL DEFAULT (rpg_develop.fn_rpg_sys_identity(object_id('rpg_develop.rpg_dic_users'))),
       name                 varchar(128) NOT NULL,
       fname                varchar(32) NULL,
       login                varchar(32) NOT NULL,
       mname                varchar(32) NULL,
       note                 varchar(512) NULL,
       lname                varchar(32) NULL,
       position             varchar(256) NULL,
       department           varchar(256) NULL,
       phone                varchar(32) NULL,
       domain               varchar(32) NOT NULL,
       fax                  varchar(32) NULL,
       pass                 varchar(128) NULL,
       is_del               bit NOT NULL DEFAULT 0
)
go

CREATE UNIQUE CLUSTERED INDEX XPKrpg_dic_users ON RPG_BD.rpg_develop.rpg_dic_users
(
       uid                            ASC
)
go

CREATE UNIQUE INDEX XAK1rpg_dic_users ON RPG_BD.rpg_develop.rpg_dic_users
(
       domain                         ASC,
       login                          ASC,
       pass                           ASC
)
go

