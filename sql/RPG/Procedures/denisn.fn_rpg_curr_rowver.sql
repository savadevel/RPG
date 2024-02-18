use RPG_BD

go
    if object_id('rpg_develop.fn_rpg_curr_rowver') is not null
    begin
        drop function rpg_develop.fn_rpg_curr_rowver
    end
go

/***************************************************************************************/
-- функция возвращает текущую версию
/***************************************************************************************/
create function rpg_develop.fn_rpg_curr_rowver
    (
        @strReport varchar(64) -- имя отчета
    )
    returns int
as
begin    
    return (select max(rowver) from rpg_develop.rpg_rep_rowver where report = @strReport and is_curr = 1)
end
go

