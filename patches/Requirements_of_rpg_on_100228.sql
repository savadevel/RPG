/*
    Описание:
    Скрипт обновляет БД Задачи "Расчет фонда обязательных резервов, подлежащих депонированию в ЦБР" для
    Скрипт учитывает Требования в части:
    - Контроль загрузки данных. Этот контроль должен давать четкую информацию о незагруженных данных филиалов, т.е. должно выводиться сообщение в виде таблицы с перечнем филиалов, не предоставивших отчет либо предоставивших отчет в некорректном формате, с сообщением <данные не загружены>.
    - Контроль данных филиалов с данными Оборотно-сальдовой ведомости, формируемой на ежедневной основе. В целях корректного отражения данных необходимо предусмотреть в ПО контроль расшифровок филиалов с данными Оборотно-сальдовой ведомости, формируемой на ежедневной основе.
    
    Разработчик:
    savadevel@gmail.com
    
    Инструкция по установке обновления:
    1. Общие положения
        1.1. Перед установкой данного Обновления должны быть установленны все ранее разработанные обновления 
        1.2. Текущая версия должна быть задана и подписана
    
    2. Порядок установки
        1.1. Запустить Query Analyzer
        1.2. Подсоединитесь к серверу S_RPG с SQL учетной записью rpg_develop, БД RPG_BD
        1.3. Откройте данный скрипт (Requirements_of_RPG_on_100228.sql)
        1.4. Нажмите F5
        1.5. Скрипт должен быть исполнен без ошибок. Если при исполнении скрипта были сообщения об ошибке, предупреждения и т.д., то необходимо
             скопировать их текстовой файл и направить файл Разработчику.
*/

use Develop;
go

CREATE TABLE rpg_develop.f136_dic_checkings (
       sid                  int NOT NULL DEFAULT (rpg_develop.fn_rpg_get_sid()),
       rowver               int NOT NULL,
       id_checking          int NOT NULL,
       name                 varchar(512) NOT NULL,
       priority             int NOT NULL,
       environment          binary(2) NOT NULL,
       options              int NOT NULL,
       run                  varchar(2048) NOT NULL,
       note                 varchar(512) NOT NULL,
       is_del               bit NOT NULL DEFAULT 0
)
go

CREATE UNIQUE CLUSTERED INDEX XPKf136_dic_checkings ON rpg_develop.f136_dic_checkings
(
       rowver                         ASC,
       id_checking                    ASC
)
go

CREATE INDEX XIF1f136_dic_checkings ON rpg_develop.f136_dic_checkings
(
       sid                            ASC
)
go

CREATE INDEX XIF2f136_dic_checkings ON rpg_develop.f136_dic_checkings
(
       rowver                         ASC
)
go

CREATE VIEW rpg_develop.vw_f136_dic_checkings_curr_ver AS
select t.rowver, nullif(t.is_fix,null) is_fix, obj.id_checking,obj.name,obj.priority,obj.environment,obj.options,obj.run,obj.note,nullif(obj.sid,null) as sid
from
        rpg_develop.rpg_rowver   ver
    join
        rpg_develop.f136_dic_checkings  obj
    on
        obj.rowver = ver.rowver
    join
    (
        select ver.rowver, ver.is_fix, max(ver_obj.lkey) as lkey, obj.id_checking
        from 
                rpg_develop.vw_rpg_rowver ver    
            cross join
                    rpg_develop.rpg_rowver   ver_obj
                join
                    rpg_develop.f136_dic_checkings  obj
                on
                    ver_obj.rowver = obj.rowver
        where    
                ver_obj.lkey <= ver.lkey and ver_obj.rkey >= ver.rkey  and ver.is_curr = 1
        group by ver.rowver, ver.is_curr, ver.is_fix, obj.id_checking
    ) t
    on
        t.lkey = ver.lkey and t.id_checking = obj.id_checking 
where
    obj.is_del = 0
go


CREATE VIEW rpg_develop.vw_f136_dic_checkings_all_ver AS
select t.rowver, nullif(t.is_curr, null) is_curr, nullif(t.is_fix,null) is_fix, obj.id_checking,obj.name,obj.priority,obj.environment,obj.options,obj.run,obj.note
from
        rpg_develop.rpg_rowver   ver
    join
        rpg_develop.f136_dic_checkings  obj
    on
        obj.rowver = ver.rowver
    join
    (
        select ver.is_curr, ver.rowver, ver.is_fix, max(ver_obj.lkey) as lkey, obj.id_checking
        from 
                rpg_develop.vw_rpg_rowver ver    
            cross join
                    rpg_develop.rpg_rowver   ver_obj
                join
                    rpg_develop.f136_dic_checkings  obj
                on
                    ver_obj.rowver = obj.rowver
        where    
                ver_obj.lkey <= ver.lkey and ver_obj.rkey >= ver.rkey
        group by ver.rowver, ver.is_curr, ver.is_fix, obj.id_checking
    ) t
    on
        t.lkey = ver.lkey and t.id_checking = obj.id_checking 
where
    obj.is_del = 0
go

create trigger rpg_develop.tD_vw_f136_dic_checkings_curr_ver on  rpg_develop.vw_f136_dic_checkings_curr_ver
  instead of delete
  as
begin
    declare  
            @errno   int,
            @errmsg  varchar(255)


    -- запрет на удаление записей имеющих подписанную версию
    if exists
        (
            select 1
            from deleted
            where is_fix = 1
        )
    begin
        set @errno  = 16
        set @errmsg = 'Error, cannot deleted rowver which is check in into rpg_develop.f136_dic_checkings'
        goto error        
    end    
    
    -- обновление поля is_del, логическое удаление
    update rpg_develop.f136_dic_checkings set
        is_del = 1,
        sid = rpg_develop.fn_rpg_get_sid()
    from 
            deleted d
        join
            rpg_develop.f136_dic_checkings c
        on
            d.rowver = c.rowver and  d.id_checking = c.id_checking 

    -- переносим записи из представления в таблицу (физ. размещение)
    insert into rpg_develop.f136_dic_checkings 
        (rowver, id_checking, name, priority, environment, options, run, note, is_del)
    select 
        d.rowver, d.id_checking, d.name, d.priority, d.environment, d.options, d.run, d.note, 1
    from 
            rpg_develop.f136_dic_checkings c
        right join
            deleted d
        on
            d.rowver = c.rowver and d.id_checking = c.id_checking 
    where c.rowver is null
    
quit:
    return

error:
    raiserror(@errmsg, @errno, 1)
    rollback transaction
end
go


