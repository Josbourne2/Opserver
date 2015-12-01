CREATE TABLE [dbo].[DatabasePropsDynamic] (
    [Id]                         INT             IDENTITY (1, 1) NOT NULL,
    [date]                       SMALLDATETIME   NULL,
    [instance_id]                INT             NULL,
    [dbid]                       INT             NULL,
    [Size]                       DECIMAL (20, 2) NULL,
    [SpaceAvailable]             VARCHAR (300)   NULL,
    [DataSpaceUsage]             VARCHAR (300)   NULL,
    [IndexSpaceUsage]            VARCHAR (300)   NULL,
    [LastBackupDate]             SMALLDATETIME   NULL,
    [LastDifferentialBackupDate] SMALLDATETIME   NULL,
    [LastLogBackupDate]          SMALLDATETIME   NULL,
    [LogReuseWaitStatus]         VARCHAR (30)    NULL,
    [MirroringRoleSequence]      TINYINT         NULL,
    [rank]                       INT             NULL,
    [Status]                     VARCHAR (100)   NULL,
    [MirroringRole]              VARCHAR (30)    NULL,
    [db]                         VARCHAR (300)   NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

