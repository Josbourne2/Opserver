﻿CREATE TABLE [dbo].[Mon_Logins] (
    [status]         SMALLINT      NULL,
    [createdate]     SMALLDATETIME NULL,
    [updatedate]     SMALLDATETIME NULL,
    [accdate]        SMALLDATETIME NULL,
    [name]           [sysname]     NULL,
    [dbname]         [sysname]     NULL,
    [language]       [sysname]     NULL,
    [denylogin]      INT           NULL,
    [hasaccess]      INT           NULL,
    [isntname]       INT           NULL,
    [isntgroup]      INT           NULL,
    [isntuser]       INT           NULL,
    [sysadmin]       INT           NULL,
    [securityadmin]  INT           NULL,
    [serveradmin]    INT           NULL,
    [setupadmin]     INT           NULL,
    [processadmin]   INT           NULL,
    [diskadmin]      INT           NULL,
    [dbcreator]      INT           NULL,
    [bulkadmin]      INT           NULL,
    [loginname]      [sysname]     NULL,
    [controle_datum] SMALLDATETIME CONSTRAINT [DF_Mon_Logins_controle_datum] DEFAULT (getdate()) NULL,
    [server]         VARCHAR (250) NULL,
    [instance_id]    INT           NULL,
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [deletedate]     SMALLDATETIME NULL,
    [ExpirationSet]  TINYINT       NULL,
    CONSTRAINT [PK_Mon_Logins] PRIMARY KEY CLUSTERED ([id] ASC)
);

