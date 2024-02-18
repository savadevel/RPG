use RPG_BD
go

truncate table RPG_BD.rpg_develop.spr_ogress
go
truncate table RPG_BD.rpg_develop.spr_acc_barring
go
truncate table RPG_BD.rpg_develop.spr_calendar
go
truncate table RPG_BD.rpg_develop.spr_departments
go

-- создание сессии
exec rpg_develop.pr_rpg_create_sid 'root', 0, 0, 0, 0, 0, 'RPG', 'rpg_develop'

go

-- приложения системы
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('Spravochniks',           'RPG',          'Справочники',         'RpgAboutUser', 'about_user', 'Выгрузка справочной информации') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('SprAccBalance',          'Spravochniks', 'Остатки на счетах',   'Spravochniks::RpgPageApp',   'Spravochniks::page_app', 'Генератор формы') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('SprCalendar',            'Spravochniks', 'Календарь',           'Spravochniks::RpgPageApp',   'Spravochniks::page_app', 'Генератор формы') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('SprRateOfExchange',      'Spravochniks', 'Курсы валют',         'Spravochniks::RpgPageApp',   'Spravochniks::page_app', 'Генератор формы') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('SprDepartments',         'Spravochniks', 'Подразделения Банка', 'Spravochniks::RpgPageApp',   'Spravochniks::page_app', 'Генератор формы') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('Spr_adm',                'Spravochniks', 'Управление',          'Spravochniks::RpgPageAdmin', 'Spravochniks::page_adm', 'Управление справочниками')

insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('spr_admin',    0,  'Администратор справочников') 
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('spr_user',     0,  'Пользователь справочников')
go

-- задаем права для групп
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'Spravochniks') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'SprAccBalance') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'SprCalendar') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'SprDepartments') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'SprRateOfExchange') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_admin', 2, 'Spr_adm') 

insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'Spravochniks') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'SprAccBalance') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'SprCalendar') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'SprDepartments') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('spr_user', 1, 'SprRateOfExchange')
go

-- управление версиями
insert into RPG_BD.rpg_develop.rpg_rowver (rowver,  prowver, label) values (3, 0,    'Справочники. Базовая версия.')
insert into RPG_BD.rpg_develop.rpg_dic_rowver (report, basver, curver, outver) values ('Spravochniks', 3, 3, 3) 
go

-- подписываем текущую версию справочников
update rpg_develop.vw_rpg_rowver set
    is_fix = 1
where report = 'Spravochniks'
go

-- закрытие сессии
exec rpg_develop.pr_rpg_close_sid 

go

select 'ok'
