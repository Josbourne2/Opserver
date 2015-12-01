CREATE TABLE [dbo].[Mon_Backups] (
    [type]           CHAR (1)       NOT NULL,
    [duur]           INT            NULL,
    [backup_size]    NUMERIC (20)   NULL,
    [backup_datum]   SMALLDATETIME  NOT NULL,
    [database_name]  VARCHAR (128)  NULL,
    [datum]          SMALLDATETIME  CONSTRAINT [DF_Mon_Backups_datum2] DEFAULT (getdate()) NOT NULL,
    [id]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [server]         VARCHAR (50)   NULL,
    [backup_file]    VARCHAR (1000) NULL,
    [instance_id]    INT            NOT NULL,
    [backup_size_MB] AS             (([backup_size]*(8))/(1024.00)),
    [dbid]           INT            NOT NULL,
    [db_type]        AS             (case when [database_name]='msdb' OR ([database_name]='model' OR [database_name]='master' OR [database_name]='distribution') then 's' else 'u' end)
);


GO
CREATE CLUSTERED INDEX [CI_BD_InstID_dbid]
    ON [dbo].[Mon_Backups]([backup_datum] ASC, [instance_id] ASC, [dbid] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_backup_datum]
    ON [dbo].[Mon_Backups]([type] ASC, [db_type] ASC, [backup_datum] ASC, [database_name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_datum_type_incl]
    ON [dbo].[Mon_Backups]([datum] ASC, [type] ASC)
    INCLUDE([db_type]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_id]
    ON [dbo].[Mon_Backups]([id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_iid_dbid_dbtype,type_incl]
    ON [dbo].[Mon_Backups]([instance_id] ASC, [dbid] ASC, [db_type] ASC, [type] ASC)
    INCLUDE([backup_datum], [datum]);


GO
CREATE NONCLUSTERED INDEX [IX_type_ed_aggr]
    ON [dbo].[Mon_Backups]([db_type] ASC, [type] ASC, [instance_id] ASC, [dbid] ASC, [backup_datum] ASC)
    INCLUDE([id]);

