CREATE TABLE [dbo].[Mon_Excluded_Db_Backups] (
    [dbname]      VARCHAR (128) NOT NULL,
    [server]      VARCHAR (50)  NOT NULL,
    [instance_id] INT           NOT NULL,
    [domein]      VARCHAR (50)  NOT NULL,
    [dbauser]     VARCHAR (20)  NOT NULL,
    [datum]       SMALLDATETIME NOT NULL
);

