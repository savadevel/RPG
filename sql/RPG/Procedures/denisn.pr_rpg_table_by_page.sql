use RPG_BD

go
    if object_id('rpg_develop.pr_rpg_table_by_page') is not null
    begin
        drop proc rpg_develop.pr_rpg_table_by_page
    end
go

/***************************************************************************************/
-- процедура возвращает запрос по странично
/***************************************************************************************/
create proc rpg_develop.pr_rpg_table_by_page
    @sSQL      nvarchar(4000), -- запрос
    @iRowId    int = null, -- начать с, если значение не указанно то с первой
    @iRowCount int = null  -- всего записей, если значение то все записи с позиции @iRowid
as
begin   
    declare @sMsg   varchar(256) -- в переменную собираем сообщения для лога 
    declare @iRows  int

    if @sSQL is null
    begin
        set @sMsg = 'error, invalid input value, can''t be NULL'
        goto error
    end
            
    if (@iRowId is null and @iRowCount is null)
    begin
        -- вывод всех строк запроса
        exec sp_executesql @sSQL
        return
    end
    
    declare @iHandle int    

    exec sp_cursoropen  @iHandle OUT, @sSQL, 1, 1, @iRows OUT
    
    if (@iRowCount is null)
    begin 
        -- вывод начиная с указанной позиции
        exec sp_cursorfetch @iHandle, 16, @iRowId, @iRows
    end
    else if (@iRowId is null)
    begin 
        -- вывод с первой позиции указанное число записей
        exec sp_cursorfetch @iHandle, 16, 1, @iRowCount
    end
    else
    begin
        -- вывод начиная с позиции @iRowId, @iRowCount записей
        exec sp_cursorfetch @iHandle, 16, @iRowId, @iRowCount
    end   

finish:    
    exec sp_cursorclose @iHandle
    select @iRows as rows 
    return

error:
    raiserror(@sMsg, 16, 1)
    select -1 rows 
    return
end
go 
