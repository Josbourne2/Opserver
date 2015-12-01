CREATE TABLE [OpManager].[Mon_Nodes]
(
	[Id] INT NOT NULL IDENTITY(1,1), 
    [name] VARCHAR(255) NOT NULL, 
    [mon_cluster_id] INT NULL, 
    CONSTRAINT [PK_Mon_Nodes] PRIMARY KEY ([Id]), 
    CONSTRAINT [FK_Mon_Nodes_To_Mon_Clusters] FOREIGN KEY ([mon_cluster_id]) REFERENCES [OpManager].[Mon_Clusters]([Id]) 
	
)
