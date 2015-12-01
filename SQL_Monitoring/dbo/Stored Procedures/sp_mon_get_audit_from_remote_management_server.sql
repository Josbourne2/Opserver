










CREATE PROCEDURE [dbo].[sp_mon_get_audit_from_remote_management_server] @ServerName VARCHAR(255), @InstanceName VARCHAR(255)

AS
BEGIN

	EXEC sp_configure 'show advanced options',1;
	RECONFIGURE;
	EXEC sp_configure 'Ad Hoc Distributed Queries',1;
	RECONFIGURE;
	
	SET XACT_ABORT OFF
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @error INT = 0;
	DECLARE @ERROR_MESSAGE VARCHAR(255);	
	DECLARE @SQL NVARCHAR(MAX);
	
	CREATE TABLE #TEMP_AUDITS(
	[server_instance_name] [sql_variant] NULL,
	[event_time] DATETIME2(7) NULL,
	[succeeded] [bit] NOT NULL,
	[session_id] [smallint] NOT NULL,
	[server_principal_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[schema_name] [nvarchar](128) NULL,
	[object_name] [nvarchar](128) NULL,
	[statement] [nvarchar](4000) NULL,
	[action_id] [varchar](4) NULL,
	[class_type] [varchar](2) NULL,
	[class_type_desc] [nvarchar](35) NULL,
	[class_desc] [nvarchar](35) NULL,
	[containing_group_name] [nvarchar](128) NULL,
	[name] [nvarchar](128) NULL,
	[additional_information] [nvarchar](4000) NULL,
	[file_name] nvarchar(260) not null,
	[Id] bigint not null
	)


	
	SET @SQL = 	'
	SELECT a.*
	FROM OPENROWSET(''SQLNCLI'', ''Server='+@ServerName+';Trusted_Connection=yes;'',
			''SELECT [server_instance_name]
      ,[event_time]
      ,[succeeded]
      ,[session_id]
      ,[server_principal_name]
      ,[database_name]
      ,[schema_name]
      ,[object_name]
      ,[statement]
      ,[action_id]
      ,[class_type]
      ,[class_type_desc]
      ,[class_desc]
      ,[containing_group_name]
      ,[name]
      ,[additional_information]
      ,[file_name]
      ,[Id]
	FROM [dbo].[Mon_Audits];'
	print @sql;


	INSERT INTO #TEMP_AUDITS
	EXEC (@SQL);

	MERGE INTO dbo.Mon_Audits AS TARGET
	USING (SELECT [server_instance_name]
      ,[event_time]
      ,[succeeded]
      ,[session_id]
      ,[server_principal_name]
      ,[database_name]
      ,[schema_name]
      ,[object_name]
      ,[statement]
      ,[action_id]
      ,[class_type]
      ,[class_type_desc]
      ,[class_desc]
      ,[containing_group_name]
      ,[name]
      ,[additional_information]
      ,[file_name]
  FROM #TEMP_AUDITS MA
  WHERE NOT EXISTS (SELECT *
					FROM [dbo].[Mon_Audits_Ignore_List] IL
					WHERE	IL.server_instance_name = MA.server_instance_name
						AND	IL.server_principal_name = MA.server_principal_name
						AND IL.database_name = MA.database_name )
		AND [statement] not like N'RESTORE VERIFYONLY%'
	AND [statement] not like N'RESTORE LABELONLY%'
	AND [statement] not like N'ALTER INDEX%'
	AND [statement] not like N'CREATE INDEX%'	
) AS SOURCE
		ON  SOURCE.event_time = TARGET.event_time 
		AND SOURCE.server_instance_name = TARGET.server_instance_name
		AND SOURCE.session_id = TARGET.session_id
	WHEN NOT MATCHED THEN 
		INSERT ([server_instance_name]
           ,[event_time]
           ,[succeeded]
           ,[session_id]
           ,[server_principal_name]
           ,[database_name]
           ,[schema_name]
           ,[object_name]
           ,[statement]
           ,[action_id]
           ,[class_type]
           ,[class_type_desc]
           ,[class_desc]
           ,[containing_group_name]
           ,[name]
           ,[additional_information]
		   ,[file_name])
		VALUES (SOURCE.[server_instance_name]
			   ,SOURCE.[event_time]
			   ,SOURCE.[succeeded]
			   ,SOURCE.[session_id]
			   ,SOURCE.[server_principal_name]
			   ,SOURCE.[database_name]
			   ,SOURCE.[schema_name]
			   ,SOURCE.[object_name]
			   ,SOURCE.[statement]
			   ,SOURCE.[action_id]
			   ,SOURCE.[class_type]
			   ,SOURCE.[class_type_desc]
			   ,SOURCE.[class_desc]
			   ,SOURCE.[containing_group_name]
			   ,SOURCE.[name]
			   ,SOURCE.[additional_information]
			   ,SOURCE.[file_name]);


	select [file_name], ROW_NUMBER() OVER (ORDER BY [file_name] DESC) AS RN
	FROM (
		SELECT DISTINCT [file_name]
		FROM #TEMP_AUDITS
		
		)DT
	ORDER BY RIGHT([file_name],28) ASC;


	DROP TABLE #TEMP_AUDITS;

	EXEC sp_configure 'Ad Hoc Distributed Queries',0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options',0;
	RECONFIGURE;
	
END
















