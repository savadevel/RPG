use RPG_BD
go


CREATE TABLE RPG_BD.rpg_develop.spr_acc_barring (
       tacc                 varchar(30) NOT NULL,
       is_del               bit NOT NULL DEFAULT 0,
       acc_nmb              char(6) NOT NULL,
       note                 varchar(512) NULL,
       acc_nme              varchar(255) NOT NULL,
       sid                  int NOT NULL DEFAULT (rpg_develop.fn_rpg_get_sid()),
       rowver               int NOT NULL DEFAULT (rpg_develop.fn_rpg_curr_rowver('Spravochniks')),
       cln_nmb              varchar(20) NOT NULL,
       cln_nme              varchar(255) NOT NULL,
       CHECK (rpg_develop.fn_rpg_param_rowver('Spravochniks', rowver, 'is_fix') = 0)
)
go

CREATE UNIQUE CLUSTERED INDEX XPKspr_acc_barring ON RPG_BD.rpg_develop.spr_acc_barring
(
       tacc                           ASC,
       rowver                         ASC
)
go

CREATE INDEX XIF1spr_acc_barring ON RPG_BD.rpg_develop.spr_acc_barring
(
       sid                            ASC
)
go

CREATE INDEX XIF2spr_acc_barring ON RPG_BD.rpg_develop.spr_acc_barring
(
       rowver                         ASC
)
go




