
CREATE PROCEDURE [dbo].[sp_mon_delete_instance] @node VARCHAR(255), @instance VARCHAR(255)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN


-- =============================================
-- Author:		Jos Menhart
-- Create date: 20130708
-- Last Modified:	20150601 by Anja
-- Description:	Stop bewaken host
-- =============================================
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--DECLARE @ServerID INT;

	--SELECT @ServerID = id
	--FROM dbo.Mon_Server
	--WHERE server = @node


	UPDATE dbo.Mon_Instance
	SET te_bewaken = 0, 
		controle = 0, 
		opmerkingen = COALESCE(opmerkingen,'') + 'Uit monitoring verwijderd op ' + CAST(sysdatetime() as varchar) + ' door ' + SUSER_SNAME(),
		end_date = SYSDATETIME()
	WHERE node = @node
			AND ISNULL(instance,'') = ISNULL(@instance,'')
END

