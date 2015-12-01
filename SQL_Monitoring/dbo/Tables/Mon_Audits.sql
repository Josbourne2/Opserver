CREATE TABLE [dbo].[Mon_Audits] (
    [server_instance_name]   SQL_VARIANT     NOT NULL,
    [event_time]             DATETIME2 (7)   NOT NULL,
    [succeeded]              BIT             NOT NULL,
    [session_id]             SMALLINT        NOT NULL,
    [server_principal_name]  NVARCHAR (128)  NULL,
    [database_name]          NVARCHAR (128)  NULL,
    [schema_name]            NVARCHAR (128)  NULL,
    [object_name]            NVARCHAR (128)  NULL,
    [statement]              NVARCHAR (4000) NULL,
    [action_id]              VARCHAR (4)     NULL,
    [class_type]             VARCHAR (2)     NULL,
    [class_type_desc]        NVARCHAR (35)   NULL,
    [class_desc]             NVARCHAR (35)   NULL,
    [containing_group_name]  NVARCHAR (128)  NULL,
    [name]                   NVARCHAR (128)  NULL,
    [additional_information] NVARCHAR (4000) NULL,
    [file_name]              NVARCHAR (260)  NOT NULL,
    [Id]                     BIGINT          IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_Mon_Audits]
    ON [dbo].[Mon_Audits]([Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NUQ_Mon_Audits]
    ON [dbo].[Mon_Audits]([event_time] ASC, [server_instance_name] ASC, [session_id] ASC)
    INCLUDE([succeeded], [server_principal_name], [database_name], [schema_name], [object_name], [statement], [action_id], [class_type], [class_type_desc], [class_desc], [containing_group_name], [name], [additional_information], [file_name], [Id]);

