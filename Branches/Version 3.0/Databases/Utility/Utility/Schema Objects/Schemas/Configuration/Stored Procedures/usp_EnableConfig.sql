/*
PROCEDURE:		[Configuration].[usp_EnableConfig]
AUTHOR:			Derik Hammer
CREATION DATE:	10/16/2013
DESCRIPTION:	This procedure is used to enable configurations.
PARAMETERS:		@ConfigID INT = 0 --This parameter used to select the configuration to enable.
					Default is 0 which equals all configurations.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Configuration].[usp_EnableConfig]
	@ConfigID int = 0 --0 = all configs
AS
	SET NOCOUNT ON

	--Validate input
	IF EXISTS (SELECT ConfigID FROM Configuration.Configs WHERE ConfigID = @ConfigID) OR @ConfigID = 0
	BEGIN
		--Enable the configuration
		UPDATE Configuration.Configs
		SET IsEnabled = 1
		WHERE ConfigID = @ConfigID
			OR @ConfigID = 0 --Enable all configs if 0;
	END
	ELSE
	BEGIN
		--Throw error due to configuation not found.
		RAISERROR('Configuration ID not found.',16,1)
		RETURN 1 --Failed due to invalid input
	END

RETURN 0 -- Return success
