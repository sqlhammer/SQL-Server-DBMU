/*
PROCEDURE:		[Audit].[usp_PurgeDDLEntries]
AUTHOR:			Derik Hammer
CREATION DATE:	12/02/2013
DESCRIPTION:	This procedure will purge records from the Audit.ServerDDL table based on pre-determined settings on a per feature basis.
PARAMETERS:		

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Audit].[usp_PurgeDDLEntries]
AS
	SET NOCOUNT ON

	DECLARE @PurgeTypeDesc VARCHAR(50)
	DECLARE @PurgeValue BIGINT
	DECLARE @RowDiff BIGINT
	DECLARE @DynamicSQL VARCHAR(8000)
	DECLARE @DateMarker DATETIME2(3)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	SELECT @PurgeTypeDesc = pType.PurgeTypeDesc, @PurgeValue = opts.PurgeValue
	FROM Audit.Options opts
	INNER JOIN [Lookup].[PurgeTypes] pType ON pType.PurgeTypeID = opts.PurgeTypeID
		
	IF @PurgeTypeDesc = 'PURGE BY NUMBER OF ROWS'
	BEGIN
		SELECT @RowDiff = (COUNT([ServerDDLID]) - @PurgeValue) 
		FROM Audit.ServerDDL

		IF @RowDiff > 0
		BEGIN
			SET @DynamicSQL = 'DELETE FROM Audit.ServerDDL
								WHERE [ServerDDLID] IN	(SELECT TOP ' + CAST(@RowDiff AS VARCHAR(10)) + ' ServerDDLID
														FROM Audit.ServerDDL
														ORDER BY [AuditDate] ASC)'

			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @DynamicSQL, @LogMode = 'VERBOSE'
				
			EXEC (@DynamicSQL)

			SET @LogEntry = 'Purged oldest ' + CAST(@RowDiff AS VARCHAR(10)) + ' records from [Audit].[ServerDDL] table.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		END
	END
		
	IF @PurgeTypeDesc = 'PURGE BY DAYS'
	BEGIN
		IF @PurgeValue > 0
		BEGIN
			SET @PurgeValue = 0 - @PurgeValue
		END
        
		SELECT @DateMarker = DATEADD(dd,@PurgeValue,GETDATE())

		IF EXISTS (SELECT [ServerDDLID] FROM [Audit].[ServerDDL] WHERE [AuditDate] < @DateMarker)
		BEGIN
			SET @LogEntry = 'DELETE FROM [Audit].[ServerDDL] WHERE [AuditDate] < ''' + CAST(@DateMarker AS VARCHAR(25)) + ''''
			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			
			DELETE FROM [Audit].[ServerDDL]
			WHERE [AuditDate] < @DateMarker

			SET @LogEntry = 'Purged records older than ' + CAST(@DateMarker AS VARCHAR(25)) + ' from [Audit].[ServerDDL] table.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		END
	END
		
	
	SET NOCOUNT OFF    
