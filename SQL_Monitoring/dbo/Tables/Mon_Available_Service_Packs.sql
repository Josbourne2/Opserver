CREATE TABLE [dbo].[Mon_Available_Service_Packs] (
    [id]              INT           IDENTITY (1, 1) NOT NULL,
    [versie]          NVARCHAR (50) NOT NULL,
    [sp]              NVARCHAR (50) NOT NULL,
    [naam]            VARCHAR (255) NULL,
    [build]           NCHAR (40)    NOT NULL,
    [release_datum]   DATE          NULL,
    [opmerkingen]     VARCHAR (255) NULL,
    [prerequisite_id] INT           NULL,
    [type]            CHAR (2)      NULL,
    [Major_Version]   AS            (CONVERT([int],left([build],charindex('.',[build])-(1)),(0))) PERSISTED,
    [Minor_Version]   AS            (CONVERT([int],substring([build],charindex('.',[build])+(1),(charindex('.',[build],charindex('.',[build])+(1))-charindex('.',[build]))-(1)),(0))) PERSISTED,
    [Build_Number]    AS            (CONVERT([int],substring([build],charindex('.',[build],charindex('.',[build],charindex('.',[build])+(1)))+(1),(4)),(0))) PERSISTED,
    CONSTRAINT [PK_Mon_Available_Service_Packs] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_Mon_Available_Service_Packs_Mon_Available_Service_Packs] FOREIGN KEY ([prerequisite_id]) REFERENCES [dbo].[Mon_Available_Service_Packs] ([id])
);

