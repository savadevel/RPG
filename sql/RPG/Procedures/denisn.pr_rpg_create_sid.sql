use RPG_BD

go
    if object_id('rpg_develop.pr_rpg_create_sid') is not null
    begin
        drop proc rpg_develop.pr_rpg_create_sid
    end
go

/***************************************************************************************/
-- процедура создаёт sid текущей сессии, возвращает таблицу с полями
--    SID     - ID сессии 
--    UID     - ID пользователя
--    REPORT  - имя отчета для доступа
--    PREPORT - имя отчета родителя для доступа
--    LIB     - perl модуль
--    ROWVER  - текущая версия
--    IS_FIX  - статус версии
--    PATH    - путь к perl модулю
--    ACCESS  - доступ 0 - запрет, 1 - чтение, 2 - внесение изменений
--    DOMAIN  - домен
--    LOGIN   - логин
/***************************************************************************************/
create proc rpg_develop.pr_rpg_create_sid
    @report varchar(32),  -- имя отчета    
    @fip    tinyint,          -- IP пользователя (1-ый байт) слева на право
    @sip    tinyint,          -- IP пользователя (2-ый байт)
    @mip    tinyint,          -- IP пользователя (3-ый байт)
    @lip    tinyint,          -- IP пользователя (4-ый байт)
    @port   int,              -- порт на пользовательской машине
    @domain varchar(32),      -- домен
    @login  varchar(32)       -- логин
as
begin   
    declare @spid    int,
            @sdate   datetime,
            @app     varchar(128),
            @ip      int,
            @sid     int,
            @host    varchar(15),
            @uid     int,
            @is_fix  bit,
            @rowver  int,
            @access  tinyint,
            @version varchar(32),
            @sMsg    varchar(256)
    
    set @domain = upper(@domain)
        
    -- строковое представление IP
    set @host = isnull(replace(str(@fip, 3), ' ', '0') + '.' + replace(str(@sip, 3), ' ', '0') + '.' + replace(str(@mip, 3), ' ', '0') + '.' + replace(str(@lip, 3), ' ', '0'), '???.???.???.???')
    
    -- чтение параметров из системы            
    select @spid = spid, @sdate = login_time, @app = program_name from master.dbo.sysprocesses where spid = @@SPID
    
    -- определяем разрешенный ip пользователя и его uid
    select @ip = isnull(max(ip), 0), @uid = isnull(max(users.uid), 0) 
    from 
            RPG_BD.rpg_develop.vw_rpg_dic_users_ip ip
        join
            RPG_BD.rpg_develop.vw_rpg_dic_users users
        on
            ip.uid = users.uid            
    where 
            upper(users.domain) = @domain
        and     
            users.login  = @login
        and
        (
            @host like ip.number
            or
            -- если для пользователя задан IP 255.255.255.255 то разрешен вход с любой машины
            ip.number like '255.255.255.255'
        )
        and 
        not exists
        (
            -- если для пользователя задан IP 0.0.0.0 то запрещен вход
            select 1
            from RPG_BD.rpg_develop.vw_rpg_dic_users_ip
            where uid = users.uid and number like '000.000.000.000'
        )
    
    -- определяем отчет
    select @report = max(report) from RPG_BD.rpg_develop.rpg_dic_reports where report = @report and report <> 'root'
    
    -- определяем права пользователя на отчет
    select @access = isnull(max(permission), 0)
    from 
            RPG_BD.rpg_develop.vw_rpg_groups_users g
        join
            RPG_BD.rpg_develop.rpg_permissions p
        on
            g.grp = p.grp and g.uid = @uid and p.report = @report

    -- определяем версию к которой привязан отчет;
    -- может быть только одна привязка, за исключением RPG, к которому
    -- привязаны все версии отчетов (учитываем это)
    if 1 >= (select count(*) 
        from  rpg_develop.rpg_dic_reports r join rpg_develop.rpg_dic_reports c on r.lkey <= c.lkey and r.rkey >= c.rkey join rpg_develop.rpg_dic_rowver v on v.report = r.report  
        where ('RPG' = isnull(@report,'RPG') or 'RPG' <> r.report) and c.report = isnull(@report,'RPG'))
    begin
        -- Определяем параметры версии
        select @version = v.report, @rowver = v.curver, @is_fix = case when v.curver = v.outver then 0 else 1 end
        from  rpg_develop.rpg_dic_reports r join rpg_develop.rpg_dic_reports c on r.lkey <= c.lkey and r.rkey >= c.rkey join rpg_develop.rpg_dic_rowver v on v.report = r.report  
        where ('RPG' = isnull(@report,'RPG') or 'RPG' <> r.report) and c.report = isnull(@report,'RPG')            

        -- понижаем права (на изменение) для отчета который подписанный
        if @is_fix = 1 and @access > 1
        begin
            set @access = @access - 1
        end
    end
    else
    begin
        -- если имеется более одной связанной версии то это есть ошибка при создании версии
        set @sMsg = 'Error, bad count rowver from  rpg_develop.rpg_dic_rowver'
        goto error
    end            

    -- создание сессии
    insert into RPG_BD.rpg_develop.rpg_sessions (report, uid, sdate, spid, app, host, port, ip, permission, domain, login)
    values (isnull(@report,'RPG'), @uid, @sdate, @spid, @app, @host, @port, @ip, @access, @domain, @login) 

    -- определяем ID текущей сессии
    set @sid = rpg_develop.fn_rpg_get_sid()
    
    -- делаем запись в журнале
    exec rpg_develop.pr_rpg_to_log 'pr_rpg_create_sid', 'i', 'create session'
    
    select @sid as sid, @uid as uid, report, preport, lib, path, @version as version, @access as access, @is_fix as is_fix, @rowver as rowver, @domain as domain, @login as login
    from RPG_BD.rpg_develop.rpg_dic_reports
    where report = isnull(@report,'RPG') 
    return 0

error:
    raiserror(@sMsg, 16, 1)
    return  -1 
end
go 


