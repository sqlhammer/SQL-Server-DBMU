/*
PROCEDURE:		[Logging].[usp_PurgeLogEntries]
AUTHOR:			Derik Hammer
CREATION DATE:	10/11/2012
DESCRIPTION:	This procedure will purge records from the Logging.Entries table based on pre-determined settings on a per feature basis.
PARAMETERS:		

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Logging].[usp_PurgeLogEntries]
AS
	SET NOCOUNT ON

	DECLARE @FeatID INT
	DECLARE @OptID INT
	DECLARE @PurgeTypeDesc VARCHAR(50)
	DECLARE @PurgeValue INT
	DECLARE @RowDiff BIGINT
	DECLARE @DynamicSQL NVARCHAR(4000)
	DECLARE @DateMarker DATETIME2(3)
	DECLARE @FeatureName VARCHAR(50)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	DECLARE Feature_Cursor CURSOR FAST_FORWARD LOCAL READ_ONLY FOR
	SELECT Feats.FeatureID, Feats.OptionID, pType.PurgeTypeDesc, opts.PurgeValue
	FROM Logging.Features Feats
	INNER JOIN Logging.Options opts ON opts.OptionID = Feats.OptionID
	INNER JOIN [Lookup].[PurgeTypes] pType ON pType.PurgeTypeID = opts.PurgeTypeID
	INNER JOIN Logging.Configs LogConfig ON LogConfig.OptionID = Feats.OptionID
	INNER JOIN Configuration.Configs Config ON Config.ConfigID = LogConfig.ConfigID
	WHERE Config.IsEnabled = 1
		AND LogConfig.IsEnabled = 1

	OPEN Feature_Cursor
	FETCH NEXT FROM Feature_Cursor INTO @FeatID, @OptID, @PurgeTypeDesc, @PurgeValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @PurgeTypeDesc = 'PURGE BY NUMBER OF ROWS'
		BEGIN
			SELECT @RowDiff = (COUNT(EntryID) - @PurgeValue) 
			FROM Logging.Entries
			WHERE FeatureID = @FeatID

			IF @RowDiff > 0
			BEGIN
				SET @DynamicSQL = 'DELETE FROM Logging.Entries
									WHERE EntryID IN	(SELECT TOP ' + CAST(@RowDiff AS VARCHAR(10)) + ' EntryID
														FROM Logging.Entries
														WHERE FeatureID = ' + CAST(@FeatID AS VARCHAR(10)) + '
														ORDER BY InsertDate ASC)'

				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @DynamicSQL, @LogMode = 'VERBOSE'
				
				EXEC (@DynamicSQL)

				SELECT @FeatureName = FeatureName FROM Lookup.Features WHERE FeatureID = @FeatID
				SET @LogEntry = 'Purged oldest ' + CAST(@RowDiff AS VARCHAR(10)) + ' records from [Logging].[Entries] table for the feature ' + @FeatureName + '.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
			END
		END
		
		IF @PurgeTypeDesc = 'PURGE BY DAYS'
		BEGIN
			IF @PurgeValue > 0
			BEGIN
				SET @PurgeValue = 0 - @PurgeValue
			END
        
			IF EXISTS (SELECT EntryID FROM [Logging].[Entries] WHERE [InsertDate] < @DateMarker AND FeatureID = @FeatID)
			BEGIN
				SELECT @DateMarker = DATEADD(dd,@PurgeValue,GETDATE())

				SET @LogEntry = 'DELETE FROM [Logging].[Entries] WHERE [InsertDate] < ''' + CAST(@DateMarker AS VARCHAR(25)) + ''' AND FeatureID = @FeatID'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @DynamicSQL, @LogMode = 'VERBOSE'
			
				DELETE FROM [Logging].[Entries]
				WHERE [InsertDate] < @DateMarker
					 AND FeatureID = @FeatID

				SET @LogEntry = 'Purged records older than ' + CAST(@DateMarker AS VARCHAR(25)) + ' from [Logging].[Entries] table for the feature ' + @FeatureName + '.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
			END
		END
		
		FETCH NEXT FROM Feature_Cursor INTO @FeatID, @OptID, @PurgeTypeDesc, @PurgeValue
	END  
	
	SET NOCOUNT OFF    
