


CREATE PROCEDURE [dbo].[sp_mon_check_connectivity] @NODE VARCHAR(255) = 'ALL'

AS
BEGIN
	
/* Proberen connectie te maken via linked sql servers
**

*/
--=========================================================================
-- 
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

--=========================================================================
SET XACT_ABORT OFF
SET NOCOUNT ON
SET XACT_ABORT ON
print 'XACT ABORT is ON'
-- declare variabelen
--Declare @Datum nvarchar(20)
Declare @inst nvarchar(64)
Declare @TSQL1 nvarchar(4000)
Declare @TSQL2 nvarchar(4000)
Declare @TSQL3 nvarchar(4000)
Declare @TSQL4 nvarchar(4000)
Declare @TSQL5 nvarchar(4000)
Declare @TSQL6 nvarchar(4000)
Declare @TSQL7 nvarchar(4000)
Declare @TSQL8 nvarchar(4000)
Declare @TSQL9 nvarchar(4000)
Declare @sqlqry nvarchar(4000)
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@ver nvarchar(50),@id int
declare @cnt int,@error int
Declare @Linked_server varchar(500)
DECLARE @reden_onbereikbaar varchar(255) = ''



--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 
--gebruik van een temp-tabel werkt hier niet icm een linked server, helaas
--IF OBJECT_ID('tempdb..#mp_start') IS NOT NULL 
--		BEGIN
--		drop table #mp_start
--		END

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor



-- declareer arraytabel en vul met mon_instance
select getdate() as 'start'
select count(*) as 'aantal' from mon_instance--logcontrole.dbo.c_sqlnodes



declare node_cursor Cursor For
	select node, instance,versie,id 
	from mon_instance 
	where ( isnull(te_bewaken,1) = 1 AND @NODE = 'ALL' )
	OR node like '%'+@NODE +'%'
   order by domein, instance,node
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@id
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if @inst = '' or @inst is null set @srvr1 = @srvr
		if @inst <> '' 
		begin
			set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		end

		
		set @error=0
		if @ver like '7.%' or @ver like '6.%'
			BEGIN
				exec dbo.sp_mon_CreateLinkedServer @srvr1,@error,@version =7
			END
		else
			BEGIN
				exec dbo.sp_mon_CreateLinkedServer @srvr1,@error, @error_message = @reden_onbereikbaar OUTPUT
				
			END
		if @error >0  goto error

		if exists (select srvid from master..sysservers where srvname = @srvr1 and @reden_onbereikbaar = '')
			BEGIN

				update dbo.mon_instance set dd_laatst_beschikbaar = getdate()  where id = @id;		
				update dbo.mon_instance set controle = '1', controledatum = getdate(),reden_onbereikbaar = '' where id = @id;		
--Linked server weer verwijderen
				EXEC sp_dropserver @srvr1 ,'droplogins'
END
		ELSE
			BEGIN
				-- probleem met connectie; reden komt in veld reden_onbereikbaar
						update dbo.mon_instance set dd_laatst_beschikbaar = case when controle ='0' then dd_laatst_beschikbaar when controle = '1' then  controledatum end  where id = @id;		
						update dbo.mon_instance set controle = '0', controledatum = getdate(), reden_onbereikbaar = @reden_onbereikbaar where id = @id
				EXEC sp_dropserver @srvr1 ,'droplogins'
			END



	
	goto ok
error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
	end

ok:
	set @srvr1 =''
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@id

select @TSQL1 = ''
select @TSQL2 = ''
select @TSQL3 = ''
select @TSQL4 = ''
select @TSQL5 = ''
select @TSQL7 = ''
select @TSQL8 = ''
select @TSQL9 = ''
select getdate() as 'Einde'

END
Close node_cursor
Deallocate node_cursor

SET NOCOUNT OFF
SET XACT_ABORT OFF

END



