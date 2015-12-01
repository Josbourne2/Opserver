

CREATE PROCEDURE [dbo].[usp_Verzamel_dbFileprops_linked_server]
	(@srv nvarchar(50)=null)
AS
BEGIN
	/*
Van servers die niet met powershell benaderd kunnen worden 
kunnen met dit script de instance-parameters worden verzameld en ingelezen.
Vanwege problemen met MSDTC (execute AT niet mogelijk) wordt de data eerst lokaal op iedere instantie verzameld en daarna centraal ingelezen.

Er zijn een aantal databaseservers die expliciet uitgesloten worden (zie verder); deze geven connectieproblemen.
*/

 set nocount on
 
--DECLARE @srv nvarchar(50)
DECLARE @srvs nvarchar(50)
DECLARE @ins varchar(100)
DECLARE @iid int
DECLARE @sname varchar(100)
DECLARE @inst TABLE(id int identity(1,1), iid int,name varchar(100),sname varchar(100),ins varchar(100))
DECLARE @id int=1,@idmax int
DECLARE @qry varchar(max),@qry2 varchar(max)
DECLARE @error nvarchar(2000)

DECLARE @maxid int,@sql nvarchar(400)
,@date varchar(100), @dbname varchar(150), @dbid int
DECLARE @did int ,@dmaxid int,@mirror int,@dbstatus varchar(20)


set @date = GETDATE()
--if exists (select 1 from tempdb.sys.objects where name like '#temp1%') drop table #temp1
Create table #temp1(db varchar(200),dbid int,Fname varchar(100),[FileId] [bigint] NULL,
	[PhysicalName] [varchar](1500) NULL,
	[FileType] [tinyint] NULL,
	[Filesize_MB] decimal(16,2) NULL,
	[Growth] [int] NULL,
	[GrowthPerc] [bit] NULL,
	[MaxSize] [bigint] NULL,
	Filegroup varchar(200) null,Usage_MB decimal(16,2) null, Free_MB decimal(16,2) null
	)
	
	--if exists (select 1 from tempdb.sys.objects where name like '#temp2%') drop table #temp2
Create table #temp2(date smalldatetime,
	server varchar(50),instance varchar(50),
	iid int,db varchar(200),dbid int,Fname varchar(100),[FileId] [bigint] NULL,
	[PhysicalName] [varchar](1500) NULL,
	[FileType] [tinyint] NULL,
	[Filesize_MB] decimal(16,2) NULL,
	[Growth] [int] NULL,
	[GrowthPerc] [bit] NULL,
	[MaxSize] [bigint] NULL,
	Filegroup varchar(200) null,Usage_MB decimal(16,2) null, Free_MB decimal(16,2) null
	)

if @srv is null 
	BEGIN
	insert into @inst
		select id,server,node as Servername,instance from dbo.mon_Instance
		where 1=1
		--and isnull(IsWMIEnabled,0)=0
		and isnull(node,'xx') not in ('xx')

		and ISNULL(controle,1) =1
		and LEN(node) >1
	END
If @srv is not null
	BEGIN
	insert into @inst
		select id,server,node as Servername,instance from dbo.mon_Instance
		where 1=1
		and server = @srv
		and ISNULL(controle,1) =1
	END


--select * from @inst
Select  @idmax =COUNT(*) from @inst
WHILE @id <= @idmax
BEGIN
BEGIN TRY
	Select  @iid=iid,@srv = name, @ins=ins, @sname = sname from @inst
	where Id =@id
	set @id =@id+1

	SET @srvs = REPLACE(@srv,'-','')
	SET @srvs = REPLACE(@srvs,'\','')
	SET @srvs = REPLACE(@srvs,'.','')

	print @srv +'  ' +  @srvs
IF EXISTS (select name from sys.servers where name = @srvs)
	BEGIN
	EXEC master.dbo.sp_dropserver @server=@srvs, @droplogins='droplogins'
	END

	EXEC master.dbo.sp_addlinkedserver @server = @srv, @srvproduct=N'SQL Server'
	set @srvs=@srv
	EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @srvs, @locallogin = NULL , @useself = N'True'
	exec sp_serveroption @server=@srvs, @optname='rpc', @optvalue='true'  
	exec sp_serveroption @server=@srvs, @optname='rpc out', @optvalue='true'  
	--Read more: http://sqlsolace.blogspot.com/2009/09/server-dev-02-is-not-configured-for-rpc.html#ixzz2o0yzLBWx


select @date = convert(varchar(100),GETDATE(),120)

set @qry = 	'select db, dbid, Fname, FileId, PhysicalName, FileType, Filesize_MB, Growth, GrowthPerc, MaxSize, Filegroup, Usage_MB, Free_MB from sql_mon.dbo.dbfiles'


set @qry2= 'select * from openquery(['+ @srv +'],'''+@qry +''')'
insert into #temp1
EXEC ( @qry2)
	
insert into #temp2
select @date,@sname,@ins,@iid,* from #temp1
truncate table #temp1
	
	Set @qry =''
	Set @qry2 =''	
	EXEC master.dbo.sp_dropserver @server=@srvs, @droplogins='droplogins'
	

END TRY
BEGIN CATCH
set @error = @@error
Print 'error opgetreden: errornr ' + cast(error_number() as varchar(20)) + '; '+ error_message()
--update Instances 
--set Remarks =  'Dbfile-script: Error ' + cast(error_number() as varchar(20)) + '; '+ error_message(),
--CheckDate= @date
--where id = @iid
	Set @qry =''
	Set @qry2 =''	
	EXEC master.dbo.sp_dropserver @server=@srvs, @droplogins='droplogins'

END CATCH
END --END INSTANCE
select * from #temp2

INSERT INTO [DatabaseFileData]
           ([date]
           ,[server]
           ,[instance]
           ,[instance_id]   
           ,[DB]
           ,[DBID]
           ,[Fname]
           ,[FileId]
           ,[PhysicalName]
           ,[FileType]
           ,[Filesize_MB]
           ,[Growth]
           ,[GrowthPerc]
           ,[MaxSize]
           ,[Filegroup]
           ,[Usage_MB]
           ,[Free_MB])
     select [date]
           ,[server]
           ,[instance]
           ,iid   
           ,[DB]
           ,[DBID]
           ,[Fname]
           ,[FileId]
           ,[PhysicalName]
           ,[FileType]
           ,[Filesize_MB]
           ,[Growth]
           ,[GrowthPerc]
           ,[MaxSize]
           ,[Filegroup]
           ,[Usage_MB]
           ,[Free_MB] from #temp2

		   
---+==========================================
-- Oude data verwijderen, per week een record bewaren voor evt trendanalyse

 delete  
  FROM [DatabaseFileData]
  where (datepart(weekday,[date]))  <7 and date <GETDATE()-60

END




