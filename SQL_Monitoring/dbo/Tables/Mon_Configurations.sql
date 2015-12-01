CREATE TABLE [dbo].[Mon_Configurations] (
    [id]               INT            IDENTITY (1, 1) NOT NULL,
    [instance_id]      INT            NULL,
    [configuration_id] INT            NOT NULL,
    [name]             NVARCHAR (35)  NOT NULL,
    [value]            SQL_VARIANT    NULL,
    [minimum]          SQL_VARIANT    NULL,
    [maximum]          SQL_VARIANT    NULL,
    [value_in_use]     SQL_VARIANT    NULL,
    [description]      NVARCHAR (255) NOT NULL,
    [is_dynamic]       BIT            NOT NULL,
    [is_advanced]      BIT            NOT NULL,
    [checkdate]        SMALLDATETIME  DEFAULT (getdate()) NULL,
    [push_config]      BIT            DEFAULT ((0)) NULL
);

