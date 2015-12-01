CREATE PROCEDURE [dbo].[sp_mon_add_cluster]
	@name varchar(255)
AS
	IF NOT EXISTS(SELECT * FROM [dbo].[Mon_Clusters] WHERE [Name] = @name)
	BEGIN
		INSERT INTO [dbo].[Mon_Clusters] VALUES (@name);
	END
	
RETURN 0
