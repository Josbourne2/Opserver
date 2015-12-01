
CREATE PROCEDURE [dbo].[run_script_on_remote_server_using_osql]
   @node		NVARCHAR(50)	  
   ,@SQLversie  varchar(5) = null
   , @command    VARCHAR(4000) = NULL
   ,@filenaam   VARCHAR(4000) = NULL
   
AS
BEGIN
   --======================================================================================================
   -- 20100204 A vd Berg
   -- De sp sp_run_script_on_remote_server_using_osql genereert de code voor een batch-bestand om een uitrol te doen over
   -- alle bij de monitor geregistreerde, en niet verwijderde, instances.
   -- De parameters @command en @filenaam zijn wederzijds uitsluitend. Indien beide gevuld wordt @command genomen
   -- Indien beide leeg wordt een foutmelding gegeven.
   --
   -- De parameter @node moet worden aangegeven, maar mag de waarde NULL krijgen. In dat geval worden alle nodes geselecteerd.
   -- @SQLversie krijgt als default de waarde NULL mee om te zorgen dat een eventuele node-selectie goed werkt.
   --
   -- Selecteer de output van de sp en voer die uit in een cmd-scherm
   --
   --    
   -- Tijdens de uitvoer van het batch-bestand:
   -- * Meldingen en voortgang worden geschreven in de standaard Windows temp-folder in het bestand MonSQLLog.txt
   --   Indien de temp-folder niet bestaat wordt "C:\" gebruikt
   -- * Het log-bestand wordt geopend met Notepad zodra de batch is afgelopen.
   -- * In de titel van de DOS-box wordt de naam van de instance getoond
   --
   -- Parameters
   --     @Node		: de node waarvoor het script gemaakt wordt, verpicht in te vullen. Als geen node-selectie gewenst is kan de waarde null worden ingegeven
   --     @SQLversie: de sql-versie uit de tabel, als string weergegeven. Mogelijke waardes: 7, 2000, 2005 en 2008
   --     @command  : Uit te voeren commando (SQL-statement)
   --     @filenaam : Uit te voeren file. Indien gewenst inclusief padnaam.
   --
   -- Voorbeelden	: EXECUTE [sp_run_script_on_remote_server_using_osql] 'borpis05',  @filenaam = 'c:\temp\SQLQuery3.sql'
   --				  EXECUTE [sp_run_script_on_remote_server_using_osql] null,  @filenaam = 'c:\temp\SQLQuery3.sql' --alle gecontroleerde instanties
   --				  EXECUTE [sp_run_script_on_remote_server_using_osql] 'help' --de helptekst
   --


   --======================================================================================================
   SET NOCOUNT ON
   
   DECLARE @instance VARCHAR(300)
          ,@script   VARCHAR(4000)
		  ,@TSQL	 varchar(4000)
   
IF upper(@node) = 'help'
goto eindedoorhelp

   IF (@command IS NULL) AND (@filenaam IS NULL) and upper(@node) <> 'help'
   BEGIN
		print 'Voer het volgende commando uit voor hulp bij gebruik van deze procedure:
			EXECUTE [sp_run_script_on_remote_server_using_osql] ''help'''
      RAISERROR ('Procedure sp_run_script_on_remote_server_using_osql verwacht parameter @command of @filenaam', 17, 1)
   END
   ELSE
   BEGIN
      CREATE TABLE #tmpscript
      (
          nr    INT            IDENTITY
         ,cmd   VARCHAR(4000)
      )

      -- Standaard header voor batch file
      INSERT #tmpscript (cmd) VALUES('@ECHO OFF')
      INSERT #tmpscript (cmd) VALUES('')
      INSERT #tmpscript (cmd) VALUES('REM Controleer op bestaan temp-setting')
      INSERT #tmpscript (cmd) VALUES('IF NOT EXIST %TEMP% SET %TEMP%="C:"')
      INSERT #tmpscript (cmd) VALUES('')
      INSERT #tmpscript (cmd) VALUES('REM Maak var met naam logbestand')
      INSERT #tmpscript (cmd) VALUES('SET _LOG_=%TEMP%\MonSQLLog.txt')
      INSERT #tmpscript (cmd) VALUES('')
      INSERT #tmpscript (cmd) VALUES('ECHO Start batch > %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('DATE /T >> %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('TIME /T >> %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('')
set @TSQL = 'DECLARE inst_csr CURSOR
      FOR
select node + ISNULL(''\'' +Instance,'''' ) from dbo.Mon_Instance where controle =1 and te_bewaken = 1 '
if	@SQLversie is null set @TSQL = @TSQL 
if	@SQLversie = '2000' set @TSQL = @TSQL +' and (versie = ''2000'') '
if	@SQLversie like '7%' set @TSQL = @TSQL +'and  (versie like ''7%'') '
if	@SQLversie = '2008' set @TSQL =  @TSQL +'and (versie = ''2008'') '
if	@SQLversie = '2005' set @TSQL =  @TSQL +'and (versie = ''2005'') '
--if  @node is not null set @TSQL = @TSQL + ' and node = ''' + @node + ''''
 
set @TSQL = @TSQL + ' order by node'


      -- Definieer cursor voor ophalen alle te monitoren instances
	
      exec (@TSQL)

      OPEN inst_csr
      
      FETCH NEXT FROM inst_csr INTO @instance

      WHILE @@FETCH_STATUS = 0
      BEGIN
         INSERT #tmpscript (cmd) VALUES('TITLE ' + @instance)
         INSERT #tmpscript (cmd) VALUES('ECHO ' + @instance + ' >> %_LOG_%')
         
         IF @command IS NOT NULL
         BEGIN
            -- Commando: gebruik OSQL met -Q-optie
            -- Geen database opgenomen
            SET @script = 'CALL OSQL -S"' + @instance + '" -Udba_ictro -P Qu-9$racR -Q"' + @command + '" >> %_LOG_%'
         END
         ELSE
         BEGIN
            --Filenaam: gebruik -i-optie
            --Default database is master
            SET @script = 'CALL OSQL -S"' + @instance + '" -Udba_ictro -P Qu-9$racR -d"master" -i"' + @filenaam + '" -n >> %_LOG_%'
         END

         INSERT #tmpscript (cmd) VALUES(@script)
	  
         FETCH inst_csr
         INTO @instance
      END
      
      CLOSE inst_csr
      DEALLOCATE inst_csr
   
      -- Standaard einde voor batch file
      INSERT #tmpscript (cmd) VALUES('')
      INSERT #tmpscript (cmd) VALUES('TITLE Batch beeindigd')
      INSERT #tmpscript (cmd) VALUES('DATE /T >> %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('TIME /T >> %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('ECHO Einde batch >> %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('')
      INSERT #tmpscript (cmd) VALUES('REM Toon logbestand')
      INSERT #tmpscript (cmd) VALUES('CALL notepad %_LOG_%')
      INSERT #tmpscript (cmd) VALUES('')
      
      -- Geef totale script terug als resultset
	  if exists (select * from #tmpscript where cmd like 'CALL OSQL%')
		BEGIN
		  SELECT cmd
		  FROM #tmpscript
		  ORDER BY nr
		END
	  if not exists (select * from #tmpscript where cmd like 'CALL OSQL%')
		BEGIN
		  print 'De selectie met de opgegeven parameters levert geen resultaten op.
Voer het volgende commando uit voor hulp bij gebruik van deze procedure:
			EXECUTE [sp_run_script_on_remote_server_using_osql] ''help'''
		END

      DROP TABLE #tmpscript
   END
goto einde

eindedoorhelp:
print '
HELP:
    De sp sp_run_script_on remote_server_using_osql genereert de code voor een batch-bestand om een uitrol te doen over
    alle bij de monitor geregistreerde, en niet verwijderde, instances.
    De parameters @command en @filenaam zijn wederzijds uitsluitend. Indien beide gevuld wordt @command genomen
    Indien beide leeg wordt een foutmelding gegeven.
   
    De parameter @node moet worden aangegeven, maar mag de waarde NULL krijgen. In dat geval worden alle nodes geselecteerd.
    @SQLversie krijgt als default de waarde NULL mee om te zorgen dat een eventuele node-selectie goed werkt.
   
    Selecteer de output van de sp en voer die uit in een cmd-scherm
   
       
    Tijdens de uitvoer van het batch-bestand:
    * Meldingen en voortgang worden geschreven in de standaard Windows temp-folder in het bestand MonSQLLog.txt
      Indien de temp-folder niet bestaat wordt "C:\" gebruikt
    * Het log-bestand wordt geopend met Notepad zodra de batch is afgelopen.
    * In de titel van de DOS-box wordt de naam van de instance getoond
   
    Parameters
        @Node		: de node waarvoor het script gemaakt wordt, verpicht in te vullen. Als geen node-selectie gewenst is kan de waarde null worden ingegeven
        @SQLversie: de sql-versie uit de tabel, als string weergegeven. Mogelijke waardes: 7, 2000, 2005 en 2008
        @command  : Uit te voeren commando (SQL-statement)
        @filenaam : Uit te voeren file. Indien gewenst inclusief padnaam.
   
    Voorbeelden	: EXECUTE [sp_run_script_on_remote_server_using_osql] ''borpis05'',  @filenaam = ''c:\temp\SQLQuery3.sql''
   				  EXECUTE [sp_run_script_on_remote_server_using_osql] null,  @filenaam = ''c:\temp\SQLQuery3.sql'' --alle gecontroleerde instanties
   				  EXECUTE [sp_run_script_on_remote_server_using_osql] ''help'' --de helptekst
   

'

einde:

END


