
-- =============================================
-- Author:		Jos Menhart
-- Create date: 2013-07-17
-- Description:	Verwijdert disk info van disks die niet meer actueel zijn voor een instance.
-- =============================================
CREATE PROCEDURE [dbo].[sp_remove_disk_info] 
	-- Add the parameters for the stored procedure here
	@node varchar(255), 
	@instance varchar(50) = NULL,
	@drive_letter char(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	DECLARE @instance_id INT;

	SELECT @instance_id = id
	FROM dbo.Mon_Instance
	WHERE node  = @node
		AND ISNULL(Instance,'') = ISNULL(@instance, '');

	SELECT * FROM dbo.Mon_Server_Freediskspace
	WHERE Instance_id = @instance_id
		AND DriveLetter = @drive_letter

	DELETE FROM dbo.Mon_Server_Freediskspace
	WHERE Instance_id = @instance_id
		AND DriveLetter = @drive_letter
	
END


