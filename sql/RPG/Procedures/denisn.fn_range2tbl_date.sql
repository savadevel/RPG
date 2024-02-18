use RPG_BD

go
    if object_id('rpg_develop.fn_range2tbl_date') is not null
    begin
        drop function rpg_develop.fn_range2tbl_date
    end
go

/***************************************************************************************/
-- функция формирует список дат, из указанного диапазона
-- таблицу вида (id, val)
/***************************************************************************************/
create function rpg_develop.fn_range2tbl_date (@datLeft datetime, @datRight datetime)
    returns @tbl table (id  int identity(1, 1) not null, 
                        val datetime not null) 
as
begin    
    declare @sMsg  varchar(256) -- в переменную собираем сообщения для лога    

    if @datLeft is null or @datRight is null
    begin
        set @sMsg = 'error, invalid input value, can''t be NULL'
        goto error_range2tbl_date
    end
    -- левая граница не может быть больше правой
    else if @datLeft > @datRight 
    begin
        set @sMsg = 'error, [' + convert(varchar, @datLeft, 126) + ' > ' + convert(varchar, @datRight, 126) + ']'
        goto error_range2tbl_date
    end

    declare @datCurr as datetime -- текущая метка времени
    set     @datCurr  = @datLeft

    while @datCurr <= @datRight -- создаём массив дат
    begin            
        insert into @tbl (val) values (@datCurr)
        set @datCurr = dateadd(day, 1, @datCurr)
    end

    return

error_range2tbl_date:
--    raiserror(@sMsg, 16, 1)
    return
end
go
