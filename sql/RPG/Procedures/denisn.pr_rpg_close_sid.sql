use RPG_BD

go
    if object_id('rpg_develop.pr_rpg_close_sid') is not null
    begin
        drop proc rpg_develop.pr_rpg_close_sid
    end
go

/***************************************************************************************/
-- процедура закрывает текущую сессию
/***************************************************************************************/
create proc rpg_develop.pr_rpg_close_sid
as
begin   
    update RPG_BD.rpg_develop.rpg_sessions set
        edate = getdate()
    where sid = rpg_develop.fn_rpg_get_sid()    
    return 0
end
go 


