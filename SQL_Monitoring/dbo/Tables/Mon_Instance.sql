CREATE TABLE [dbo].[Mon_Instance] (
    [id]                             INT            IDENTITY (1, 1) NOT NULL,
    [Node]                           NVARCHAR (50)  NULL,
    [Instance]                       NVARCHAR (50)  NULL,
    [Controle]                       NVARCHAR (1)   NULL,
    [versie]                         NVARCHAR (50)  NULL,
    [Lokatie]                        NVARCHAR (50)  NULL,
    [domein]                         VARCHAR (16)   NULL,
    [build]                          NCHAR (40)     NULL,
    [editie]                         NVARCHAR (50)  NULL,
    [w_build]                        NVARCHAR (50)  NULL,
    [w_sp]                           NVARCHAR (50)  NULL,
    [controledatum]                  SMALLDATETIME  NULL,
    [te_bewaken]                     VARCHAR (1)    CONSTRAINT [DF_Mon_Instance_te_bewaken] DEFAULT ((1)) NULL,
    [opmerkingen]                    VARCHAR (4000) NULL,
    [reden_onbereikbaar]             VARCHAR (4000) NULL,
    [IsClustered]                    BIT            NULL,
    [DNS_Suffix]                     VARCHAR (100)  NULL,
    [Serviceaccount]                 VARCHAR (200)  NULL,
    [Data_dir]                       VARCHAR (600)  NULL,
    [Log_dir]                        VARCHAR (600)  NULL,
    [Backup_dir]                     VARCHAR (600)  NULL,
    [dd_laatst_beschikbaar]          SMALLDATETIME  NULL,
    [eigenaar]                       VARCHAR (255)  NOT NULL,
    [server]                         AS             (case when [Instance] IS NULL then [Node] else ([Node]+'\')+[Instance] end),
    [ResourceLastUpdateDateTime]     DATETIME2 (0)  NULL,
    [ResourceVersion]                VARCHAR (20)   NULL,
    [max_server_memory_value]        INT            NULL,
    [max_server_memory_value_in_use] INT            NULL,
    [creation_date]                  DATETIME2 (0)  DEFAULT (sysdatetime()) NULL,
    [end_date]                       DATETIME2 (0)  NULL,
    [contactpersoon]                 VARCHAR (255)  NOT NULL,
    [applicatie]                     VARCHAR (255)  NOT NULL,
    [dienst]                         VARCHAR (255)  NOT NULL,
    [created_by]                     VARCHAR (255)  NULL,
    [updated_by]                     VARCHAR (255)  NULL,
    [updated_date]                   DATETIME2 (0)  NULL,
    [is_uitgefaseerd]                BIT            DEFAULT ((0)) NOT NULL,
    [heeft_SQL_engine]               BIT            DEFAULT ((1)) NOT NULL,
    [SSAS]                           BIT            DEFAULT ((0)) NOT NULL,
    [SSIS]                           BIT            DEFAULT ((0)) NOT NULL,
    [SSRS]                           BIT            DEFAULT ((0)) NOT NULL,
    [Major_Version]                  AS             (case when isnumeric(left([build],charindex('.',[build])-(1)))=(1) then CONVERT([int],left([build],charindex('.',[build])-(1)),(0))  end) PERSISTED,
    [Minor_Version]                  AS             (case when isnumeric(left([build],charindex('.',[build])-(1)))=(1) then CONVERT([int],substring([build],charindex('.',[build])+(1),(charindex('.',[build],charindex('.',[build])+(1))-charindex('.',[build]))-(1)),(0))  end) PERSISTED,
    [Build_Number]                   AS             (case when isnumeric(left([build],charindex('.',[build])-(1)))=(1) then CONVERT([int],substring([build],charindex('.',[build],charindex('.',[build],charindex('.',[build])+(1)))+(1),(4)),(0))  end) PERSISTED,
    [automatische_updates]           BIT            DEFAULT ((1)) NULL,
    [SQL_Audit]                      BIT            DEFAULT ((0)) NULL,
    [maxdop_enabled]                 BIT            DEFAULT ((1)) NOT NULL,
    [mon_cluster_id] INT NULL, 
    CONSTRAINT [PK_Mon_Instance] PRIMARY KEY CLUSTERED ([id] ASC), 
    CONSTRAINT [FK_Mon_Instance_To_Mon_Clusters] FOREIGN KEY ([mon_cluster_id]) REFERENCES [OpManager].[Mon_Clusters]([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Controle]
    ON [dbo].[Mon_Instance]([Controle] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Node_instance]
    ON [dbo].[Mon_Instance]([Node] ASC, [Instance] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Te_Bewaken]
    ON [dbo].[Mon_Instance]([te_bewaken] ASC);

