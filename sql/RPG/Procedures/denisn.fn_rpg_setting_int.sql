use RPG_BD

go                 
    if object_id('rpg_develop.fn_rpg_setting_int') is not null
    begin
        drop function rpg_develop.fn_rpg_setting_int
    end
go

/***************************************************************************************/
-- функция по имени параметра возвращает значение из таблицы REP_SETTINGS
-- целое число
/***************************************************************************************/
create function rpg_develop.fn_rpg_setting_int
    (
        @sSett nvarchar(64), -- имя параметра
        @sRep  nvarchar(32), -- имя отчета    
        @iVer  int
    )
    returns int
as
begin    
    return 
    (    
        select case count(*) when 1 then cast(max(val) as int) else null end
        from rpg_develop.vw_rpg_settings
        where 
                type    = 'int' 
            and 
                report  = @sRep
            and 
                setting = @sSett
            and 
                (
                        @iVer is not null and @iVer = rowver
                    or
                        @iVer is null and is_curr = @iVer
                )
        group by report, setting
    )
end
go

