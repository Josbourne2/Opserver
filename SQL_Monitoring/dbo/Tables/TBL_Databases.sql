CREATE TABLE [dbo].[TBL_Databases] (
    [id]           INT           IDENTITY (1, 1) NOT NULL,
    [Instance_id]  INT           NOT NULL,
    [dbid]         INT           NOT NULL,
    [db]           VARCHAR (300) NULL,
    [date_created] SMALLDATETIME NULL,
    [date_deleted] SMALLDATETIME NULL,
    [Date_checked] SMALLDATETIME NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

