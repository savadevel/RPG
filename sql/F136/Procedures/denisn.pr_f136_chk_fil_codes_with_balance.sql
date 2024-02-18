use Develop

go                 
    if object_id('rpg_develop.pr_f136_chk_fil_codes_with_balance') is not null
    begin
        drop proc rpg_develop.pr_f136_chk_fil_codes_with_balance
    end
go

