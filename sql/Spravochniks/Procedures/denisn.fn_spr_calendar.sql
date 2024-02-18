use RPG_BD

go
    if object_id('rpg_develop.fn_spr_calendar') is not null
    begin
        drop function rpg_develop.fn_spr_calendar
    end
go


/***************************************************************************************/
-- функция возвращает календарь 
/***************************************************************************************/
create function rpg_develop.fn_spr_calendar 
    (
        @datLeft   datetime, -- левая граница диапазона
        @datRight  datetime, -- правая граница диапазона, загрузки остатка по балансу
        @rowver    int
    )

    returns @tbl table
    (
        rowver   int,
        date     datetime, 
        workdate datetime, 
        recalc   int not null, 
        type     int not null, -- тип дня (0 - рабочий, 1 - выходной)  
        note     varchar(64),
        primary key (date)
    ) 
as
begin    
    declare @sMsg  varchar(256) -- в переменную собираем сообщения для лога    

    set @rowver = isnull(@rowver, (select curver from rpg_develop.rpg_dic_rowver where report = 'Spravochniks')) 

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
    else if (not exists(select 1 from rpg_develop.vw_rpg_rowver where report = 'Spravochniks' and rowver = @rowver))
    begin
        set @sMsg = 'error, invalid rowver number: ' + cast(@rowver as varchar)
        goto error        
    end
    
    declare @datCurr as datetime    -- текущая метка времени
    declare @datWork as datetime    -- последний рабочий день
    declare @iRecalc as int         -- флаг пересчета
    declare @iType   as int         -- тип
    declare @strDesc as varchar(64) -- описание
    
    set     @datCurr = @datLeft
    set     @datWork = null
    
    -- цикл по всем датам диапазона
    while @datCurr <= @datRight 
    begin            
        if 0 = ((datepart(weekday, @datCurr)  + (@@DATEFIRST - 1)) % 7) and 1 = day(@datCurr)
        begin
            -- воскресение 1-ое число, требуется пересчет металлов
            set @iRecalc = 1
            set @iType   = 1
            set @strDesc = 'воскресение 1-ое число'
        end
        else if 6 = ((datepart(weekday, @datCurr)  + (@@DATEFIRST - 1)) % 7) or 0 = ((datepart(weekday, @datCurr)  + (@@DATEFIRST - 1)) % 7)
        begin
        -- суббота или воскресение, курс устанавливается в пятницу, баланса в выходные нет
            set @iRecalc = 1
            set @iType   = 1
            set @strDesc = 'выходной день'
        end
        else if (1 = (select case when (cast(replace(str(day(@datCurr), 2), ' ', '0') as varchar) + cast(replace(str(month(@datCurr), 2), ' ', '0') as varchar)) in ('0101','0201','0301','0401','0501','0701','2302','0803','0105','0905','1206','0411') then 1 else 0 end))
        begin
            -- праздничный день
            set @iRecalc = 0
            set @iType   = 1
            set @strDesc = 'праздничный день'
        end
        else
        begin
            -- рабочий день
            set @datWork = @datCurr
            set @iRecalc = 0
            set @iType   = 0
            set @strDesc = 'рабочий день'
        end

        while @datWork is null 
        begin    
            -- первый день выходной ищим первый рабочий день        
            set @datWork = dateadd(day, -1, @datCurr)                         
            set @datWork = (select max (workdate) from rpg_develop.fn_spr_calendar(@datWork, @datLeft, @rowver))
        end
    
        insert into @tbl (rowver, date, workdate, recalc, type, note)
        values (@rowver, @datCurr, @datWork, @iRecalc, @iType, @strDesc)
    
        set @datCurr = dateadd(day, 1, @datCurr)    
    end

    update @tbl
    set workdate = dic.workdate,
        recalc   = dic.recalc,
        note     = dic.note,
        type     = case when dic.date = dic.workdate then 0 else 1 end    
    from 
            rpg_develop.vw_spr_calendar dic 
        join 
            @tbl tmp 
        on 
            dic.date = tmp.date
    where
            dic.rowver = @rowver

finish:
error:
    return
end    
go