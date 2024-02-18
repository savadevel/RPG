use RPG_BD
go


CREATE TABLE RPG_BD.rpg_develop.f136_codes (
       code                 char(6) NOT NULL,
       rowver               int NOT NULL DEFAULT (rpg_develop.fn_rpg_curr_rowver('F136')),
       is_del               bit NOT NULL DEFAULT 0,
       note                 varchar(512) NULL,
       sid                  int NOT NULL DEFAULT (rpg_develop.fn_rpg_get_sid()),
       CHECK (rpg_develop.fn_rpg_param_rowver('F136', rowver, 'is_fix') = 0)
)
go
