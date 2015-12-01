/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
/* Insert base data into Software table. Specific software settings can be managed using the Mon_Software_Configurations table. */
SET IDENTITY_INSERT dbo.Mon_Software ON;
GO
MERGE INTO dbo.Mon_Software AS TRG
USING ( 
        SELECT 1, 'Default'
		UNION
		SELECT 2, 'Microsoft Dynamics CRM'
		UNION
		SELECT 3, 'Biztalk (only messagebox db server)'
		UNION
		SELECT 4, 'Sharepoint') AS SRC (Id, Name)
ON TRG.Id = SRC.Id
WHEN NOT MATCHED THEN INSERT (Id, Name) VALUES (Id, Name);
GO
SET IDENTITY_INSERT dbo.Mon_Software OFF;
GO

SET IDENTITY_INSERT dbo.Mon_Software_Configurations ON;
MERGE INTO dbo.Mon_Software_Configurations AS TRG
USING (SELECT 1, N'optimize for ad hoc workloads', CAST(N'1' AS nvarchar(1)), 1
		UNION SELECT
			 2, N'optimize for ad hoc workloads', CAST(N'1' AS nvarchar(1)), 2
UNION SELECT
			 3, N'optimize for ad hoc workloads', CAST(N'1' AS nvarchar(1)), 3
UNION SELECT
			 4, N'optimize for ad hoc workloads', CAST(N'1' AS nvarchar(1)), 4
UNION SELECT
			 5, N'max degree of parallelism', CAST(N'1' AS nvarchar(1)), 2
UNION SELECT
			 6, N'max degree of parallelism', CAST(N'1' AS nvarchar(1)), 3
UNION SELECT
			 7, N'max degree of parallelism', CAST(N'1' AS nvarchar(1)), 4

        ) AS SRC (Id, Name, value,mon_software_id)
ON TRG.Id = SRC.Id
WHEN NOT MATCHED THEN INSERT (Id, Name, value,mon_software_id) VALUES (Id, Name, value,mon_software_id);
SET IDENTITY_INSERT dbo.Mon_Software_Configurations OFF;
GO
INSERT INTO OpManager.SecuritySettings (provider) VALUES ('alladmin');
GO

/* Comment out for production */
INSERT INTO OpManager.Mon_Clusters VALUES('TestCluster1');
INSERT INTO OpManager.Mon_Clusters VALUES('TestCluster2');
INSERT INTO OpManager.Mon_Nodes VALUES('TestClusterNode1',1);
INSERT INTO OpManager.Mon_Nodes VALUES('TestClusterNode2',1);
INSERT INTO OpManager.Mon_Nodes VALUES('TestClusterNode3',1);
INSERT INTO OpManager.Mon_Nodes VALUES('TestClusterNode3',2);
INSERT INTO OpManager.Mon_Nodes VALUES('TestClusterNode3',2);
EXECUTE  [dbo].[sp_mon_add_instance_to_cluster] 
   @node = 'TestClusterNode1'
  ,@instance = 'TestClusterInstance1'
  ,@eigenaar = ''
  ,@contactpersoon = ''
  ,@applicatie = ''
  ,@dienst = ''
  ,@cluster_name = 'TestCluster1' 
GO
USE [SQL_Monitoring]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[sp_mon_add_instance]
		@node = N'TestNode100',
		@instance = N'TestInstance100',
		@eigenaar = N'sdfds',
		@contactpersoon = N'sdfd',
		@applicatie = N'sdf',
		@dienst = N'sdf'

SELECT	'Return Value' = @return_value

GO