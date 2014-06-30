/*
PROCEDURE:		[Logging].[usp_InsertLogEntry]
AUTHOR:			Derik Hammer
CREATION DATE:	10/8/2012
DESCRIPTION:	This procedure will INSERT a record into the [Logging].[Entries] table.
PARAMETERS:		@Feature VARCHAR(128) --Feature name to associate the log entry.
				@TextEntry VARCHAR(8000) --Log entry

*/
/*
CHANGE HISTORY:

	

*/
CREATE PROCEDURE [Logging].[usp_InsertLogEntry]
	@Feature VARCHAR(128),
	@TextEntry VARCHAR(8000),
	@LogMode VARCHAR(50)
AS
	SET NOCOUNT ON

	DECLARE @FeatureID INT
	DECLARE @msg VARCHAR(128)

	--Check for enabled logging option
	IF EXISTS (	SELECT opts.OptionID
				FROM [Logging].[Options] opts
				INNER JOIN [Logging].[Features] LogFeats ON LogFeats.OptionID = opts.OptionID
				INNER JOIN [Lookup].[Features] Feats ON Feats.FeatureID = LogFeats.FeatureID
				INNER JOIN [Logging].[Configs] LogConfigs ON LogConfigs.OptionID = opts.OptionID
				INNER JOIN [Configuration].[Configs] Configs ON Configs.ConfigID = LogConfigs.ConfigID
				WHERE UPPER(Feats.FeatureName) = UPPER(@Feature)
					AND Configs.IsEnabled = 1
					AND LogConfigs.IsEnabled = 1 )
	BEGIN
		IF (UPPER(@LogMode) = 'LIMITED')
			OR ((UPPER(@LogMode) = 'VERBOSE') AND ('VERBOSE' = (SELECT TOP 1 UPPER(LogMode.LoggingModeDesc)
														FROM [Logging].[Options] opts
														INNER JOIN [Lookup].[LoggingModes] LogMode ON LogMode.LoggingModeID = opts.LoggingModeID
														INNER JOIN [Logging].[Features] LogFeats ON LogFeats.OptionID = opts.OptionID
														INNER JOIN [Lookup].[Features] Feats ON Feats.FeatureID = LogFeats.FeatureID
														INNER JOIN [Logging].[Configs] LogConfigs ON LogConfigs.OptionID = opts.OptionID
														INNER JOIN [Configuration].[Configs] Configs ON Configs.ConfigID = LogConfigs.ConfigID
														WHERE UPPER(Feats.FeatureName) = UPPER(@Feature)
															AND Configs.IsEnabled = 1
															AND LogConfigs.IsEnabled = 1)))
		BEGIN 
			--Identify FeatureID
			-- - NOTE:	@FeatureID will never be NULL because we are in this IF block
			-- -		only because we satisfied the WHERE Feats.FeatureName = @Feature
			-- -		clause from above. There is no warning if the [Lookup].[Features]
			-- -		table has invalid data but there is also no interruption of commands.
			SELECT @FeatureID = FeatureID
			FROM [Lookup].[Features]
			WHERE UPPER(FeatureName) = UPPER(@Feature)

			--Log entry
			INSERT INTO [Logging].[Entries] ( LoginName, FeatureID, TextEntry )
				VALUES ( ORIGINAL_LOGIN(), @FeatureID, @TextEntry )     
		END
		
	END --End IF - Check for enabled logging option 

	SET NOCOUNT OFF    
