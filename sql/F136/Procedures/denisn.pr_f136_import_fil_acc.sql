use RPG_BD

go                 
    if object_id('rpg_develop.pr_f136_import_fil_acc') is not null
    begin
        drop proc rpg_develop.pr_f136_import_fil_acc
    end
go

 