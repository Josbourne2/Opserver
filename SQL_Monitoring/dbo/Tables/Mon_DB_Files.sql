CREATE TABLE [dbo].[Mon_DB_Files] (
    [instance_id]    INT           NULL,
    [dbid]           INT           NULL,
    [name]           VARCHAR (150) NULL,
    [fileid]         INT           NULL,
    [filename]       VARCHAR (500) NULL,
    [filegroup]      VARCHAR (50)  NULL,
    [size_kb]        BIGINT        NULL,
    [maxsize_kb]     BIGINT        NULL,
    [growth]         VARCHAR (30)  NULL,
    [usage]          VARCHAR (50)  NULL,
    [date]           SMALLDATETIME NULL,
    [controle_datum] SMALLDATETIME NULL
);

