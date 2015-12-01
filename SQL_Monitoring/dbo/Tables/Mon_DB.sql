CREATE TABLE [dbo].[Mon_DB] (
    [server]         VARCHAR (200)  NOT NULL,
    [dbname]         VARCHAR (200)  NOT NULL,
    [dbid]           SMALLINT       NOT NULL,
    [mode]           SMALLINT       NOT NULL,
    [status]         INT            NOT NULL,
    [status2]        INT            NULL,
    [crdate]         SMALLDATETIME  NOT NULL,
    [category]       INT            NULL,
    [cmptlevel]      INT            NOT NULL,
    [filename]       VARCHAR (2000) NOT NULL,
    [version]        INT            NULL,
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [datum]          SMALLDATETIME  CONSTRAINT [DF_Mon_DB_datum] DEFAULT (getdate()) NOT NULL,
    [deldate]        SMALLDATETIME  NULL,
    [instance_id]    INT            NULL,
    [creator]        VARCHAR (200)  NULL,
    [Applicatie]     NVARCHAR (255) NULL,
    [Contact]        NVARCHAR (255) NULL,
    [eigenaar]       VARCHAR (255)  NULL,
    [contactpersoon] VARCHAR (255)  NULL,
    [dienst]         VARCHAR (255)  NULL,
    CONSTRAINT [PK_Mon_DB] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_deldate_dbid_incl]
    ON [dbo].[Mon_DB]([deldate] ASC, [dbid] ASC)
    INCLUDE([dbname], [instance_id]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Server_dbname]
    ON [dbo].[Mon_DB]([server] ASC, [dbname] ASC) WHERE ([deldate] IS NULL);

