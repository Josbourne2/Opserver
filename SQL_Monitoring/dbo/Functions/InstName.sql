
-- =============================================
-- Author:		Avd Berg	
-- Create date: 11-10-10
-- Description:	Deze functie geeft als resultaat de instance_naam van een aangegevn SQL instanceid.
--				Als de aangegeven instanceid niet gevonden kan worden, wordt als resultaat de waarde n.a. gegeven.
-- =============================================
CREATE FUNCTION [dbo].[InstName] 
(
	-- Add the parameters for the function here
	@instance_id int
)
RETURNS varchar(50) 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @server  as varchar(50)

	-- Add the T-SQL statements to compute the return value here
	if exists (SELECT node from [dbo].mon_instance where id = @instance_id)
	
	
	--case when instance is null then node else node + '\' + instance
		BEGIN
		SELECT @server = case when instance is null then node else node + '\' + instance end from [dbo].mon_instance where id = @instance_id
		END
	else
	BEGIN
		set @server = 'n.a.'
	END
	-- Return the result of the function
	RETURN @server

END


