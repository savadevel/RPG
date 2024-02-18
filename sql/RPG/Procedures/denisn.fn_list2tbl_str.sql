use RPG_BD

go
    if object_id('rpg_develop.fn_list2tbl_str') is not null
    begin
        drop function rpg_develop.fn_list2tbl_str
    end
go

/***************************************************************************************/
-- функция преобразует список целых, разделенных пробелами в
-- таблицу вида (id, val)
/***************************************************************************************/
create function rpg_develop.fn_list2tbl_str (@list nvarchar(4000))
    returns @tbl table (id  int identity(1, 1) not null, 
                        val varchar(256) not null) 
as
begin    
    declare @pos      int,
            @textpos  int,
            @chunklen smallint,
            @str      nvarchar(4000),
            @tmpstr   nvarchar(4000),
            @leftover nvarchar(4000)

    set @textpos  = 1
    set @leftover = ''
    
    while @textpos <= datalength(@list) / 2
    begin
        set @chunklen = 4000 - datalength(@leftover) / 2
        set @tmpstr   = ltrim(@leftover + substring(@list, @textpos, @chunklen))
        set @textpos  = @textpos + @chunklen

        set @pos = charindex(' ', @tmpstr)
        while @pos > 0
        begin
            set @str    = substring(@tmpstr, 1, @pos - 1)
            insert @tbl (val) values(convert(varchar(256), @str))
            set @tmpstr = ltrim(substring(@tmpstr, @pos + 1, len(@tmpstr)))
            set @pos    = charindex(' ', @tmpstr)
        end
        set @leftover = @tmpstr
    end

    if ltrim(rtrim(@leftover)) <> ''
        insert @tbl (val) values(convert(varchar(256), @leftover))
    return
end
go
