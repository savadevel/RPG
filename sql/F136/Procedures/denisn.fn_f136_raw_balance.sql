use RPG_BD

go                 
    if object_id('rpg_develop.fn_f136_raw_balance') is not null
    begin
        drop function rpg_develop.fn_f136_raw_balance
    end
go
