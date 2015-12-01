



CREATE PROCEDURE [dbo].[sp_mon_add_instance_CI] @node VARCHAR(255), @contactpersoon VARCHAR(255), @dienst VARCHAR(255)
	-- Add the parameters for the stored procedure here
AS
BEGIN


	EXECUTE [dbo].[sp_mon_add_instance] 
	   @node = @node
	  ,@instance = 'INST1'
	  ,@eigenaar = 'SUPPORT-MSSQL'
	  ,@contactpersoon = @contactpersoon
	  ,@applicatie = 'Onbekend'
	  ,@dienst = @dienst;

END

