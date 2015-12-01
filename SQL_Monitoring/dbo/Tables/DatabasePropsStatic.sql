CREATE TABLE [dbo].[DatabasePropsStatic] (
    [Id]                          INT           IDENTITY (1, 1) NOT NULL,
    [Date]                        SMALLDATETIME NULL,
    [SERVER]                      VARCHAR (50)  NULL,
    [Instance]                    VARCHAR (50)  NULL,
    [Instance_id]                 INT           NULL,
    [Db]                          VARCHAR (300) NULL,
    [DbId]                        INT           NULL,
    [AutoClose]                   BIT           NULL,
    [AutoShrink]                  BIT           NULL,
    [Owner]                       VARCHAR (100) NULL,
    [Status]                      VARCHAR (100) NULL,
    [CompatibilityLevel]          VARCHAR (30)  NULL,
    [AutoCreateStatisticsEnabled] BIT           NULL,
    [AutoUpdateStatisticsEnabled] BIT           NULL,
    [Collation]                   VARCHAR (100) NULL,
    [RecoveryModel]               VARCHAR (20)  NULL,
    [IsMirroringEnabled]          BIT           NULL,
    [rank]                        BIGINT        NULL,
    [PageVerifyOption]            VARCHAR (50)  NULL,
    [createdate]                  SMALLDATETIME NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

