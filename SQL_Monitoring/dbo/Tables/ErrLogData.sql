CREATE TABLE [dbo].[ErrLogData] (
    [LogID]         INT             IDENTITY (1, 1) NOT NULL,
    [LogDate]       DATETIME        NULL,
    [ProcessInfo]   NVARCHAR (50)   NULL,
    [LogText]       NVARCHAR (4000) NULL,
    [SQLServerName] NVARCHAR (150)  NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);

