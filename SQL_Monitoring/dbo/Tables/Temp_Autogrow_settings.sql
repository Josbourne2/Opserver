CREATE TABLE [dbo].[Temp_Autogrow_settings] (
    [Controle Datum]        SMALLDATETIME   NULL,
    [server]                VARCHAR (200)   NULL,
    [Database Name]         [sysname]       NOT NULL,
    [File Name]             [sysname]       NOT NULL,
    [Physical Name]         NVARCHAR (260)  NULL,
    [File Type]             VARCHAR (4)     NULL,
    [Total Size in Mb]      INT             NULL,
    [Available Space in Mb] INT             NULL,
    [Growth Units]          VARCHAR (15)    NULL,
    [Max File Size in Mb]   INT             NULL,
    [growth_target]         INT             NULL,
    [cmd]                   NVARCHAR (4000) NULL
);

