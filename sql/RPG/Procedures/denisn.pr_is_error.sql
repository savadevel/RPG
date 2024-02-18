use RPG_BD

go
    if object_id('rpg_develop.pr_is_error') is not null    
    begin
        drop proc rpg_develop.pr_is_error
    end
go

/***************************************************************************************/
-- процедура проверяет значение @iErr и возвращает её значение
-- приэтом через @sMsg возвращается сообщение об ошибке
/***************************************************************************************/
create proc rpg_develop.pr_is_error
            @iErr  int,                -- значение из @@ERROR
            @sApp  varchar(32) = '',   -- наименование приложение где произошла ошибка
            @sMsg  varchar(512) output -- сообющение создается при отличном о нуля значении @iErr
                               
as
begin
    set @sMsg = null
    
    if @iErr = 0
    begin
        return 0
    end
    
    set @sMsg = 'error,'+ @sApp + 'see table sysmessages for error=' + cast(@iErr as varchar)
    return -1
end
go
