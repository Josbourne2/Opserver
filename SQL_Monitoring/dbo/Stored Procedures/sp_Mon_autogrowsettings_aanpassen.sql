

CREATE PROC [dbo].[sp_Mon_autogrowsettings_aanpassen]


AS
BEGIN

IF EXISTS (SELECT name FROM sys.tables WHERE name = 'Temp_Autogrow_settings')
	BEGIN
	   DROP TABLE Temp_Autogrow_settings
	END


CREATE TABLE Temp_Autogrow_settings (
  [Controle Datum] smalldatetime
, [server] varchar(200)
, [Database Name] sysname
, [File Name] sysname
, [Physical Name] NVARCHAR(260)
, [File Type] VARCHAR(4)
, [Total Size in Mb] INT
, [Available Space in Mb] INT
, [Growth Units] VARCHAR(15)
, [Max File Size in Mb] INT
, growth_target INT
, cmd  nvarchar(4000))   


insert into Temp_Autogrow_settings
	select df.date,
		mi.server,
		rtrim(db.dbname)
		,rtrim(df.name) as filenaam,
		 df.filename,
		 replace(usage,' only','') as filetype,
		 size_kb/1024 as size_MB, 
		 null as available_space
		,growth
		, CASE [maxsize_kb]   
					WHEN -1 THEN NULL   
					WHEN 268435456 THEN NULL   
					ELSE [maxsize_kb]/1024   
					END   as maxsize_MB
		,null as target
		,null as cmd
	from dbo.Mon_DB_Files df
	inner join mon_instance mi on mi.id=df.instance_id
	inner join mon_db db on db.instance_id = df.instance_id and db.dbid = df.dbid
	where df.controle_datum > (getdate() -2)
	AND df.date > (getdate() -2)
	AND mi.Controle =1
	and db.deldate is  null
	order by mi.server,db.dbname
   
Update Temp_Autogrow_settings
set growth_target = case   
	when [Total Size in Mb] < 20 then 10
	when [Total Size in Mb] between 20 and 200 then 50 
	when [Total Size in Mb] between 200 and 500 then 100 
	when [Total Size in Mb] > 500 then 300 
	end    

update 	Temp_Autogrow_settings
set
	cmd = 'ALTER DATABASE [' + [Database Name] + '] MODIFY FILE (NAME = N''' + [File Name] +  ''', FILEGROWTH = '+ cast(growth_target as varchar(10)) +'MB)' 
from Temp_Autogrow_settings where 
right([Growth Units],1) ='%' 
or (right([Growth Units],2)='Mb' and cast(replace([Growth Units],'Mb','') as int) <growth_target)
or (right([Growth Units],2)='Mb' and cast(replace([Growth Units],'Mb','') as int) >growth_target*1.5)
or (right([Growth Units],2)='kb' and cast(replace([Growth Units],'kb','') as int) <growth_target*1024)
or (right([Growth Units],2)='kb' and cast(replace([Growth Units],'kb','') as int) >growth_target*1024*1.5)

update 	Temp_Autogrow_settings
set
	cmd = null
from Temp_Autogrow_settings 
where [database name]  in ('model') 
and cmd is not null
and [Growth Units] = '51200 KB'


Update Temp_Autogrow_settings 
set [growth_target]=50
where 1=1
and [database name]  in ('model')

update 	Temp_Autogrow_settings
set
	cmd = 'ALTER DATABASE [' + [Database Name] + '] MODIFY FILE (NAME = N''' + [File Name] +  ''', FILEGROWTH = '+ cast(growth_target as varchar(10)) +'MB)' 
from Temp_Autogrow_settings 
where [database name]  in ('model') 
and cmd is not null

update 	Temp_Autogrow_settings
set
	cmd='sqlcmd -S ' + server + ' -E -Q "' + cmd +'"'
	where cmd is not null 

END


