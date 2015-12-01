CREATE TABLE [dbo].[Mon_FileSizes] (
    [id]          INT            IDENTITY (1, 1) NOT NULL,
    [server]      VARCHAR (150)  NULL,
    [Versie]      VARCHAR (50)   NULL,
    [dbnaam]      VARCHAR (250)  NULL,
    [filetype]    VARCHAR (10)   NULL,
    [size]        BIGINT         NULL,
    [size_MB]     AS             (([size]*(8))/(1024.00)),
    [date]        SMALLDATETIME  NULL,
    [Opm]         VARCHAR (4000) NULL,
    [Instance_id] INT            NULL,
    [dbid]        INT            NULL,
    CONSTRAINT [PK_Mon_FileSizes] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Instid_DBid]
    ON [dbo].[Mon_FileSizes]([Instance_id] ASC, [dbid] ASC)
    INCLUDE([filetype], [date]);


GO
CREATE NONCLUSTERED INDEX [IX_server_dbnaam]
    ON [dbo].[Mon_FileSizes]([server] ASC, [dbnaam] ASC)
    INCLUDE([filetype], [date]);

