CREATE TABLE [dbo].[Mon_DB_Usage] (
    [id]          INT           IDENTITY (1, 1) NOT NULL,
    [instance_id] INT           NULL,
    [dbid]        INT           NULL,
    [last_read]   SMALLDATETIME NULL,
    [datum]       SMALLDATETIME CONSTRAINT [DF_mon_DB_Usage_datum] DEFAULT (getdate()) NULL
);

