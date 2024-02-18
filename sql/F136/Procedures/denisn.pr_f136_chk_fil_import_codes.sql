use Develop

go                 
    if object_id('rpg_develop.pr_f136_chk_fil_import_codes') is not null
    begin
        drop proc rpg_develop.pr_f136_chk_fil_import_codes
    end
go

