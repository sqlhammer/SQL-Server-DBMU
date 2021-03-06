﻿/*
PROCEDURE:		[Trace].[usp_EnableConfig]
AUTHOR:			Derik Hammer
CREATION DATE:	10/16/2013
DESCRIPTION:	This procedure is used to enable Trace feature level configurations.
				If you do not pass in a ConfigID or ConfigName then all feature level configurations
				for the selected OptionID will be enabled.
PARAMETERS:		@OptionID INT --The option that you'd like to enable. First half of the key.
				@ConfigID INT = NULL --This parameter used to select the configuration to enable. The second half
					of the key, if passed in. Default is NULL because @ConfigName or no selection is allowed.
				@ConfigName VARCHAR(250) = NULL --This parameter used to select the configuration to enable. 
					The second half	of the key, if passed in. Default is NULL because @ConfigID or no selection 
					is allowed.
*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Trace].[usp_EnableConfig]
	@OptionID int,
	@ConfigName varchar(250) = NULL,
	@ConfigID int = NULL
AS
	SET NOCOUNT ON

	--Validate input
	-- - Must have the optionID
	IF NOT EXISTS (SELECT OptionID FROM [Trace].[Configs] WHERE OptionID = @OptionID)
	BEGIN
		RAISERROR('Option ID not found.',16,1);
		RETURN 1;
	END
	-- - If configname and configid are passed in then they must match
	IF @ConfigName IS NOT NULL
		AND @ConfigID IS NOT NULL
		AND NOT EXISTS (SELECT ConfigID FROM [Configuration].[Configs] WHERE ConfigID = @ConfigID AND ConfigName = @ConfigName)
	BEGIN
		RAISERROR('Combination of Config ID and Config name does not match. Recommendation: Input only one of the two parameters.',16,1);
		RETURN 1;
	END
	-- - verify configid
	IF NOT EXISTS (SELECT ConfigID FROM [Trace].[Configs] WHERE ConfigID = @ConfigID)
		AND @ConfigID IS NOT NULL
	BEGIN
		RAISERROR('Configuraiton ID not found.',16,1);
		RETURN 1;
	END
	-- - verify configname exists and is a configuration that is used for this feature
	IF NOT EXISTS (SELECT ConfigName FROM [Configuration].[Configs] configs
					INNER JOIN [Trace].[Configs] bakConfigs ON bakConfigs.ConfigID = configs.ConfigID
					WHERE ConfigName = @ConfigName)
		AND @ConfigName IS NOT NULL
	BEGIN
		RAISERROR('Configuration name not found in relation to an option of this feature.',16,1);
		RETURN 1;
	END

	--Enable configs
	IF @ConfigID IS NOT NULL
	BEGIN
		--Enable the configuration
		UPDATE [Trace].[Configs]
		SET IsEnabled = 1
		WHERE ConfigID = @ConfigID
			AND OptionID = @OptionID

		--Success
		RETURN 0;
	END
	IF @ConfigName IS NOT NULL
	BEGIN
		--Enable the configuration
		UPDATE [Trace].[Configs]
		SET IsEnabled = 1
		WHERE ConfigID IN (SELECT ConfigID FROM Configuration.Configs WHERE ConfigName = @ConfigName)
			AND OptionID = @OptionID

		--Success
		RETURN 0;
	END
	IF @ConfigID IS NULL AND @ConfigName IS NULL
	BEGIN
		--Enable the configuration
		UPDATE [Trace].[Configs]
		SET IsEnabled = 1
		WHERE OptionID = @OptionID

		--Success
		RETURN 0;
	END

RETURN 0 -- Return success
