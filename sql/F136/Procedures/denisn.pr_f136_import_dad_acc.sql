use RPG_BD

go                 
    if object_id('rpg_develop.pr_f136_import_dad_acc') is not null
    begin
        drop proc rpg_develop.pr_f136_import_dad_acc
    end
go

