use RPG_BD

go
    if object_id('rpg_develop.fn_spr_rate_exchange') is not null
    begin
        drop function rpg_develop.fn_spr_rate_exchange
    end
go


/***************************************************************************************/
-- функция возвращает курс за период
/***************************************************************************************/
create function rpg_develop.fn_spr_rate_exchange 
    (
       @datLeft   datetime, -- левая граница диапазона
       @datRight  datetime,  -- правая граница диапазона, загрузки остатка по балансу
       @rowver    int
    )
    returns @tbl table
    (
        id   int, 
        date datetime, 
        rowver int not null,
        rte  money not null, 
        rbs  int not null, 
        rgn  varchar(16),
        primary key (rgn, date)
    ) 
as
begin    
    declare @sMsg  varchar(256) -- в переменную собираем сообщения для лога    

    if @datLeft is null or @datRight is null
    begin
        set @sMsg = 'error, invalid input value, can''t be NULL'
        goto error
    end
    -- левая граница не может быть больше правой
    else if @datLeft > @datRight 
    begin
        set @sMsg = 'error, [' + convert(varchar, @datLeft, 126) + ' > ' + convert(varchar, @datRight, 126) + ']'
        goto error
    end
    
    set @rowver = isnull(@rowver, (select curver from rpg_develop.rpg_dic_rowver where report = 'Spravochniks')) 

    -- таблица дат        
    declare @tabDate table (date datetime primary key) 
    
    -- заполняем календарь
    insert into @tabDate (date) 
    select date from rpg_develop.fn_spr_calendar(@datLeft, @datRight, @rowver)
    
    -- добавляем курсы из опердня
    insert into @tbl (id, rowver, [date], rte, rbs, rgn)
    select cur.id, @rowver, days.[date], rte, rbs, rgn  
    from 
                CPY_RPG_A..rate     r   (nolock)
            join 
                CPY_RPG_A..currency cur (nolock)
            on cur.id = r.cid and cur.grp = 0 and r.rid = 0
        cross join
            @tabDate days
    where 
        r.rdt = (
                    select max(rdt) 
                    from CPY_RPG_A..rate (nolock)
                    where cid = r.cid AND rid = 0 and rdt <= days.date
                )
    
    -- добавляем клиринг 
    insert into @tbl (id, rowver, date, rte, rbs, rgn)
    select 
        null AS id, 
        @rowver,
        days.date, 
        r.rate as rte, 
        r.base as rbs, 
        r.code as rgn
    from 
        (
                rpg_develop.vw_spr_clearing_codes c
            join
                rpg_develop.vw_spr_clearing_rate  r
            on
                c.code = r.code and c.rowver = r.rowver
        )
        cross join
            @tabDate days
    where
            c.als is null
        and
            c.rowver = @rowver
        and 
            r.date = (
                        select max(date)
                        from rpg_develop.vw_spr_clearing_rate
                        where date <= days.date and code = r.code and rowver = r.rowver
                     )
    
    -- учитываем альтернативные имена кодов валюты
    insert into @tbl (id, rowver, date, rte, rbs, rgn)
    select
        null, a.rowver, date, rte, rbs, a.code
    from
        @tbl t join rpg_develop.vw_spr_clearing_codes a
        on t.rgn = a.als and t.rowver = a.rowver
    where
        a.als is not null
    
finish:                    
error:
    return
end    

