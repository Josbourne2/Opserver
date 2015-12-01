CREATE TABLE [dbo].[Mon_Audits_Ignore_List] (
    [server_instance_name]  SQL_VARIANT    NOT NULL,
    [server_principal_name] NVARCHAR (128) NULL,
    [database_name]         NVARCHAR (128) NULL
);

