use RPG_BD

go
    if object_id('rpg_develop.pr_rpg_to_log') is not null
    begin
        drop proc rpg_develop.pr_rpg_to_log
    end
go

/***************************************************************************************/
-- процедура добавляет записи в журнал событий
/***************************************************************************************/
create proc rpg_develop.pr_rpg_to_log
    @so   varchar(64),               -- имя объекта сформировавшего сообщение
    @sl   varchar(32),               -- тип сообщения   
    @sm   varchar(7000) = ''         -- сообщение
as
begin   
    insert into rpg_develop.rpg_log(log, val) values
        (@sl, '[' + @so + ']: ' + @sm)    
    return 0
end
go 


