CREATE TABLE [dbo].[Mon_Software_Configurations]
(
	[Id] INT NOT NULL IDENTITY(1,1),
    [name]             NVARCHAR (35)  NOT NULL,
    [value]            SQL_VARIANT    NULL, 
    [mon_software_id] INT NOT NULL, 
    CONSTRAINT [FK_Mon_Software_Configurations_To_Mon_Software] FOREIGN KEY ([mon_software_id]) REFERENCES [Mon_Software]([Id]), 
    CONSTRAINT [PK_Mon_Software_Configurations] PRIMARY KEY ([Id])
)
