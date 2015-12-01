


CREATE PROCEDURE [dbo].[sp_mon_add_instance] @node VARCHAR(255), @instance VARCHAR(255), @eigenaar VARCHAR(255),
	@contactpersoon VARCHAR(255), @applicatie VARCHAR(255), @dienst VARCHAR(255)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN

-- =============================================
-- Author:		Jos Menhart
-- Create date: 20130708
-- Last Modified:	20150601 by Anja
-- Description:	Voeg een nieuwe server of instance toe aan de monitoring database
-- =============================================

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ServerID INT;
	SET @node = UPPER(@node);
	--======================
	-- mon_server tabel bestaat niet meer
	--======================

	IF NOT EXISTS (SELECT * FROM dbo.Mon_Instance WHERE node = @node AND instance = @instance)
	BEGIN
		Insert into Mon_instance(node, instance,te_bewaken,  creation_date, eigenaar, contactpersoon,applicatie,dienst,[created_by]) 
		values 
		(@node,@instance,1, SYSDATETIME(), @eigenaar, @contactpersoon,@applicatie,@dienst, SUSER_SNAME())
	END
	ELSE
	BEGIN
		UPDATE dbo.Mon_Instance
		SET te_bewaken = 1, 
			controle = 0, 
			eigenaar = @eigenaar, 
			contactpersoon = @contactpersoon,
			applicatie = @applicatie,
			dienst = @dienst,				
			updated_date = SYSDATETIME(),
			updated_by = SUSER_SNAME()
		WHERE node = @node
			AND instance = @instance
	END

END



