use RPG_BD

go
    if object_id('rpg_develop.pr_spr_accsumm_by_period') is not null
    begin
        drop proc rpg_develop.pr_spr_accsumm_by_period
    end
go
