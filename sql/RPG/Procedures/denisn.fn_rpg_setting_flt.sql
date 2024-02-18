use RPG_BD

go                 
    if object_id('rpg_develop.fn_rpg_setting_flt') is not null
    begin
        drop function rpg_develop.fn_rpg_setting_flt
    end
go

/***************************************************************************************/
-- функция по имени параметра возвращает значение из таблицы REP_SETTINGS
-- вещественное число
/***************************************************************************************/
create function rpg_develop.fn_rpg_setting_flt
    (
        @sSett nvarchar(64), -- имя параметра
        @sRep  nvarchar(32), -- имя отчета    
        @iVer  int
    )
    returns float
as
begin    
    return 
    (    
        select case count(*) when 1 then cast(max(val) as real) else null end
        from rpg_develop.vw_rpg_settings
        where 
                type    = 'flt' 
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

