use RPG_BD

go
truncate table RPG_BD.rpg_develop.rpg_log
go
truncate table RPG_BD.rpg_develop.rpg_settings
go
truncate table RPG_BD.rpg_develop.rpg_permissions
go
alter table RPG_BD.rpg_develop.rpg_dic_rowver DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_rowver
alter table RPG_BD.rpg_develop.rpg_dic_rowver ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_rowver DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_rowver
alter table RPG_BD.rpg_develop.rpg_rowver ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_sessions DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_sessions
alter table RPG_BD.rpg_develop.rpg_sessions ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_permissions DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_permissions 
alter table RPG_BD.rpg_develop.rpg_dic_permissions ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_groups_users DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_groups_users 
alter table RPG_BD.rpg_develop.rpg_groups_users ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_groups DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_groups 
alter table RPG_BD.rpg_develop.rpg_dic_groups ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_log DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_log
alter table RPG_BD.rpg_develop.rpg_dic_log ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_reports DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_reports
alter table RPG_BD.rpg_develop.rpg_dic_reports ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_users_ip DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_users_ip
alter table RPG_BD.rpg_develop.rpg_dic_users_ip ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_users DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_users
alter table RPG_BD.rpg_develop.rpg_dic_users ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_dic_types DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_dic_types
alter table RPG_BD.rpg_develop.rpg_dic_types ENABLE trigger all
go
alter table RPG_BD.rpg_develop.rpg_sys_identity DISABLE trigger all
delete from RPG_BD.rpg_develop.rpg_sys_identity
alter table RPG_BD.rpg_develop.rpg_sys_identity ENABLE trigger all
go

/***************************************************************************************/
print 'грузим данные в словари'
/***************************************************************************************/
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('a', 1, 'аудит действий пользователя') 
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('e', 2, 'сообщения об ошибках') 
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('w', 3, 'предупреждающие сообщения') 
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('i', 4, 'информационные сообщения') 
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('d', 5, 'отладочный сообщения') 
insert into RPG_BD.rpg_develop.rpg_dic_log (log, level, note) values ('f', 6, 'flood') 

go

insert into RPG_BD.rpg_develop.rpg_dic_permissions (permission, note) values (0,  'доступ запрещен')
insert into RPG_BD.rpg_develop.rpg_dic_permissions (permission, note) values (1,  'доступ разрешен на чтение')
insert into RPG_BD.rpg_develop.rpg_dic_permissions (permission, note) values (2,  'доступ разрешен на изменение')

go
print 'приложения системы'
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('root',                   null,   'Unknown',                   '', '', 'Неизвестное приложение') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('RPG',                    'root', 'Отчетность',                'RpgAboutUser',     'about_user',   'Главная страница') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('RPG_users',              'RPG',  'Управление пользователями', 'admin::RpgAdminUsers',       'admin::adm_users',       'Консоль регистрации пользователей') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('RPG_permissions',        'RPG',  'Управление правами',        'admin::RpgAdminPermissions', 'admin::adm_permissions', 'Управление правами пользователей') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('RPG_audit',              'RPG',  'Журналы',                   'admin::RpgAdminLog',         'admin::adm_log',         'Выгрузка журналов сервера приложений и сервера данных') 

go

print 'пользователи'
insert into RPG_BD.rpg_develop.rpg_dic_users (uid, name, domain, login, note) values (0, 'Unknown Name',  'RPG', 'guest',  'пользователь не зарегистрирован в системе')

insert into RPG_BD.rpg_develop.rpg_dic_users (uid, name, domain, login, note) values (1, 'Developer', 'RPG', 'rpg_develop',   'разработчик') 

go

print 'машины с которых разрешен доступ'
insert into RPG_BD.rpg_develop.rpg_dic_users_ip (ip, uid, fip, sip, mip, lip) values (0,0, 0,   0,   0,   0) 
insert into RPG_BD.rpg_develop.rpg_dic_users_ip (uid, fip, sip, mip, lip)     values (1, 255, 255, 255, 255)
insert into RPG_BD.rpg_develop.rpg_dic_users_ip (uid, fip, sip, mip, lip)     values (2,   0,   0,   0,   0)
insert into RPG_BD.rpg_develop.rpg_dic_users_ip (uid, fip, sip, mip, lip)     values (3,   0,   0,   0,   0) 
insert into RPG_BD.rpg_develop.rpg_dic_users_ip (uid, fip, sip, mip, lip)     values (4, 255, 255, 255, 255) 
go

print 'задаем группы'
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('admin_sys',            1,  'Администратор системы') 
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('admin_permissions',    3,  'Администратор пользователей') 
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('auditor',              1,  'Аудитор') 

go
print 'включаем пользователей в группы'
insert into RPG_BD.rpg_develop.rpg_groups_users (grp, uid) values ('admin_permissions',  1) 
go

print 'задаем права для групп'
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('admin_sys', 2, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('admin_sys', 1, 'RPG_audit') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('admin_sys', 2, 'RPG_users') 

insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('admin_permissions', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('admin_permissions', 2, 'RPG_permissions') 

insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('auditor', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('auditor', 2, 'RPG_audit') 
go

insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('str',    'строковый тип') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('sql',    'sql инструкция') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('acc',    '№ счета') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('xml',    'xml поток') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('bool',   'булево значение') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('int',    'целое число') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('long',   'длинное целое число') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('flt',    'вещественное число') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('dbl',    'вещественное число') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('mny',    'денежная величина') 
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('pwd',    'пароль')
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('ip',     'ip машины')
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('date',   'дата')
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('time',   'дата + время')
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('pthd',   'путь к директории')
insert into RPG_BD.rpg_develop.rpg_dic_types (type, note) values ('pthf',   'путь к файлу')
go
print 'создание сессии'
exec rpg_develop.pr_rpg_create_sid 'root', 0, 0, 0, 0, 0, 'RPG', 'rpg_develop'

go
print 'управление версиями'
insert into RPG_BD.rpg_develop.rpg_rowver (rowver,  prowver, label) values (0, null, 'vRoot')
insert into RPG_BD.rpg_develop.rpg_rowver (rowver,  prowver, label) values (1, 0,    'RPG. Базовая версия.') 
insert into RPG_BD.rpg_develop.rpg_dic_rowver (report, basver, curver, outver) values ('RPG',          1, 1, 1)

go
print 'Загрузка параметров работы: общие'
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'FORMAT_OF_DATE',      'str', 'USER01',                            'Формат представления даты') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'FORMAT_OF_TIME',      'str', 'USER02',                            'Формат представления времени') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'PRC_LOG',             'str', 'RPG_BD.rpg_develop.pr_rpg_to_log',      'Процедура регистрации событий') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'PRC_CREATE_SID',      'str', 'RPG_BD.rpg_develop.pr_rpg_create_sid',  'Процедура создания сессии') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'PRC_CLOSE_SID',       'str', 'RPG_BD.rpg_develop.pr_rpg_close_sid',   'Процедура закрытия сессии') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'LEN_MSG',             'int', '7000',                              'Длина сообщения записываемого в БД') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'LOG_TO_DB',           'bool', 'Y',                                 'Флаг ведения журнала') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'DEBUG_LEVEL',         'int',  '5',                                 'Уровень отладочной инф.: 1 => "a", 2 => "e", 3 => "w", 4 => "i", 5 => "d", 6= "f"') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'NUMBER_ROWS_ON_PAGE',   'int',  '1000', 'Число строк на странице') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_TABLE_BY_PAGE', 'str',  'exec rpg_develop.pr_rpg_table_by_page %s, %s, %s', 'Инструкция постраничной выборки') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_TREE_REPORT', 'str', 
    '
        select 
            DISTINCT 
            lkey,
            p.report, 
            preport, 
            name, 
            [level], 
            lib, 
            path, 
            case (rkey - lkey) 
                when 1 then ''leaf'' 
                else case 
                        when preport = ''root'' then ''root''
                        else ''folder'' 
                    end 
            end as who 
        from 
                RPG_BD.rpg_develop.rpg_permissions p
            join
                RPG_BD.rpg_develop.vw_rpg_groups_users g
            on 
                p.grp=g.grp
            join
                rpg_develop.rpg_dic_reports r
            on
                r.report = p.report            
        where uid = %d and permission > 0
        order by lkey
    ', 'Инструкция для извлечения дерева отчетов, используется в CGI') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_CHILD_REPORTS', 'str', 
    '
        select 
            uid, 
            case permission when 1 then ''+'' when 2 then ''+'' else ''-'' end as reading,
            case permission when 2 then ''+'' else ''-'' end as writing,
            name,
            note
        from
                (
                    select uid, report, max(permission) permission
                    from
                            RPG_BD.rpg_develop.rpg_permissions p
                        join
                            RPG_BD.rpg_develop.vw_rpg_groups_users g
                        on 
                            p.grp=g.grp
                    where permission > 0
                    group by uid, report
                ) t
            join
                RPG_BD.rpg_develop.rpg_dic_reports r
            on
                t.report = r.report
        where
            exists
            (
                select 1
                from 
                        RPG_BD.rpg_develop.rpg_dic_reports bas
                    cross join
                        RPG_BD.rpg_develop.rpg_dic_reports rpg
                where  
                    rpg.lkey >= bas.lkey and rpg.rkey <= bas.rkey      
                    and bas.report = %s and rpg.report = r.report
            )                    
            and
            uid = %s
        order by lkey
    ', 'Инструкция возращает список дочерних отчетов по UID пользователя') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_REPORTS', 'str', 
    '
        select *
        from   RPG_BD.rpg_develop.rpg_dic_reports
        where report <> ''root''    
        order by lkey
    ', 'Инструкция возращает список отчетов') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_THE_REPORT', 'str', 
    '
        select report, preport, name, level, lib, path, note
        from  RPG_BD.rpg_develop.rpg_dic_reports
        where report = %s
    ', 'Инструкция возращает информацию по указанному отчету') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_USER',        'str', 'select * from rpg_develop.vw_rpg_dic_users where uid = %d', 'Инструкция возращает информацию о пользователе по его ID') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_USERS',       'str', 'select * from rpg_develop.vw_rpg_dic_users order by name, domain, login', 'Инструкция возращает информацию о пользователях') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_ALL_USERS',   'str', 'select * from rpg_develop.rpg_dic_users where uid <> 0 order by name, domain, login', 'Инструкция возращает информацию о всех пользователях, включая удаленных') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_IP',          'str', 'select * from rpg_develop.vw_rpg_dic_users_ip order by number', 'Инструкция возращает список IP пользователей') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'TBL_USERS',           'str', 'rpg_develop.vw_rpg_dic_users',    'Таблица пользователей') 
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'TBL_IP',              'str', 'rpg_develop.vw_rpg_dic_users_ip', 'Таблица IP пользователей') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_IP_BY_UID',   'str', 
    '   
        select *
        from rpg_develop.vw_rpg_dic_users_ip
        where uid = %s
        order by number
    ', 'Инструкция возращает список IP пользователя') 

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_LOG',   'str', 
    '   
        select 
            s.sid,
            l.log,
            convert(varchar, l.date, 126) as date,
            l.val,
            u.uid,
            u.name,
            isnull(u.fname, '''') + '' '' + isnull(u.mname, '''') + '' '' + isnull(u.lname, '''') as fio,
            u.phone,
            u.fax,
            u.department,    
            r.name + '', '''''' + r.note + '''''''' as report,    
            s.domain + ''\'' + s.login as login,
            s.host + '':'' + cast(s.port as varchar) as host,
            case s.permission when 0 then ''-'' when 1 then ''r'' when 2 then ''w'' else ''?'' end as permission,
            convert(varchar, s.sdate, 126) as sdate,
            convert(varchar, s.edate, 126) as edate
        from 
                rpg_develop.rpg_log l
            join
                rpg_develop.rpg_sessions s
            on
                l.sid = s.sid
            join
                rpg_develop.rpg_dic_reports r
            on
                s.report = r.report
            join
                rpg_develop.rpg_dic_users u
            on
                s.uid = u.uid
        where 
            date >= %s and date <= dateadd(day, 1, %s)
            and
            (%s is null or l.log in (%s))
            and
            (%s is null or u.uid in (%s))
            and
            (%s is null or r.report in (%s))        
    ', 'Инструкция выгрузки информации из лога сервера данных') 
    
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_GROUPS',       'str', 
    '
        select grp, cast(type as int) type, note
        from RPG_BD.rpg_develop.rpg_dic_groups 
        order by note
    ', 'Инструкция возращает список групп')

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'SQL_GET_PERMISSIONS',       'str', 
    '
        select grp, uid
        from RPG_BD.rpg_develop.vw_rpg_groups_users        
    ', 'Инструкция возращает список групп и входящих в них пользователей')

insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('RPG',  'TBL_PERMISSIONS',       'str', 'RPG_BD.rpg_develop.vw_rpg_groups_users', 'Таблица групп и входящих в них пользователей')    
go

-- подписываем текущую версию RPG
update rpg_develop.rpg_dic_rowver set
    outver = null
where report = 'RPG'
go

-- закрытие сессии
exec rpg_develop.pr_rpg_close_sid 

go

select 'ok'

