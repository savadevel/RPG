use RPG_BD

go
truncate table RPG_BD.rpg_develop.f136_raw_balance
go
truncate table RPG_BD.rpg_develop.f136_settings
go
alter table RPG_BD.rpg_develop.f136_view_form_in_html DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_view_form_in_html
alter table RPG_BD.rpg_develop.f136_view_form_in_html ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_view_form_in_kliko DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_view_form_in_kliko
alter table RPG_BD.rpg_develop.f136_view_form_in_kliko ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_form_calc_balance DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_form_calc_balance 
alter table RPG_BD.rpg_develop.f136_form_calc_balance ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_form_calc_aggregates DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_form_calc_aggregates
alter table RPG_BD.rpg_develop.f136_form_calc_aggregates ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_form_sub_rows DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_form_sub_rows
alter table RPG_BD.rpg_develop.f136_form_sub_rows ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_form_rows DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_form_rows
alter table RPG_BD.rpg_develop.f136_form_rows ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_use_account DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_use_account
alter table RPG_BD.rpg_develop.f136_use_account ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_codes DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_codes
alter table RPG_BD.rpg_develop.f136_codes ENABLE trigger all
go
alter table RPG_BD.rpg_develop.f136_rowver DISABLE trigger all
delete from RPG_BD.rpg_develop.f136_rowver
alter table RPG_BD.rpg_develop.f136_rowver ENABLE trigger all
go

-- создание сессии
exec rpg_develop.pr_rpg_create_sid 'root', 0, 0, 0, 0, 0, 'RPG', 'rpg_develop'
go

-- приложения системы
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('F136',                   'RPG',  'Форма 136',    'RpgAboutUser',     'about_user',   'Форма 136. ''Об обязательных резервах кредитных организаций''') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('F136_app',               'F136', 'Генератор', 'F136::RpgPageApp',   'F136::page_app', 'Генератор приложений для формы 136') 
insert into RPG_BD.rpg_develop.rpg_dic_reports (report, preport, name, lib, path, note) values ('F136_adm',               'F136', 'Управление',    'F136::RpgPageAdmin', 'F136::page_adm', 'Управление генератором формы 136') 
                                                                                              
go

-- добавление групп пользователей задачи
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('f136_admin',   0,  'Администратор формы 136') 
insert into RPG_BD.rpg_develop.rpg_dic_groups (grp, type, note) values ('f136_user',    0,  'Пользователь формы 136') 
go

-- задаем права для групп
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_user', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_user', 1, 'F136') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_user', 1, 'F136_app')

insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_admin', 1, 'RPG') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_admin', 2, 'F136') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_admin', 2, 'F136_app') 
insert into RPG_BD.rpg_develop.rpg_permissions (grp, permission, report) values ('f136_admin', 2, 'F136_adm') 
go

-- управление версиями
insert into RPG_BD.rpg_develop.rpg_rowver (rowver,  prowver, label) values (2, 0,    'Форма 136. Базовая версия.')
insert into RPG_BD.rpg_develop.rpg_dic_rowver (report, basver, curver, outver) values ('F136', 2, 2, 2) 
go

print 'Загрузка параметров работы: форма 136'
insert into RPG_BD.rpg_develop.vw_rpg_settings (report, setting, type, val, note) values ('F136', 'MAX_NESTING',         'int', '20', 'Мах уровень вложенности, или число итераций за которое должно быть найденно решение') 

go

-- подписываем текущую версию справочников
update rpg_develop.vw_f136_rowver set
    is_fix = 1
where is_fix = 0
go

-- закрытие сессии
exec rpg_develop.pr_rpg_close_sid 

go

select 'ok'
