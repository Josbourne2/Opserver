
-- =============================================
-- Author:		Avd Berg	
-- Create date: 11-10-10
-- Description:	Deze functie geeft als resultaat de instance_id van een aangegevn SQL servernaam.
--				Als de aangegeven servernaam niet gevonden kan worden, wordt als resultaat de waarde -1 gegeven.
-- =============================================
CREATE FUNCTION [dbo].[InstID] 
(
	-- Add the parameters for the function here
	@server varchar(50)
)
RETURNS integer 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @instance_id  as int

	-- Add the T-SQL statements to compute the return value here
	if exists (SELECT id from [dbo].mon_instance where node = '' + @server + '')
		BEGIN
		SELECT @instance_id= id from [dbo].mon_instance where node = '' + @server + ''
		END
	else
	BEGIN
		set @instance_id = -1
	END
	-- Return the result of the function
	RETURN @instance_id

END


