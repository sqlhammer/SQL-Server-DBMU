/*
PROCEDURE:		[IndexMaint].[usp_IndexMaintOptionAssociation]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to associate or disassociate an existing index maintenance option to an existing umbrella configuration.
PARAMETERS:		@OptionID INT --The disk cleanup option to be associated.
				@ConfigID INT --The configuration to be paired with.
				@IsEnabled BIT --Whether the feature level configuration should be set to enabled when created.
				@Remove BIT --Default set to 0 (false) which means that we are adding an association. 1 would indicate
					that we are detaching this option from the configuration.

*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [IndexMaint].[usp_IndexMaintOptionAssociation]
	@debug BIT = 0,
	@OptionID INT,
	@ConfigID INT,
	@IsEnabled BIT,
	@Remove BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
    
	BEGIN TRANSACTION
		
		--Logging
		DECLARE @LogEntry VARCHAR(8000)
		--Checks for the presence of this association.
		IF NOT EXISTS	(
							SELECT [IndexMaintConfigID] 
							FROM [IndexMaint].[Configs] 
							WHERE [OptionID] = @OptionID 
								AND [ConfigID] = @ConfigID
						)
		BEGIN
			IF @Remove = 0
			BEGIN  
				IF @debug = 1
				BEGIN
					PRINT 'Requested association did not exist, moving on.'
				END
            
				--Creates new association where there wasn't one already.  
				INSERT INTO [IndexMaint].[Configs]
						([OptionID]
						,[ConfigID]
						,[IsEnabled])
					VALUES
						(@OptionID
						,@ConfigID
						,@IsEnabled)

				SELECT @LogEntry = 'Index Maintenance OptionID ' + CAST(@OptionID AS VARCHAR(10)) + ' is now associated with Configuration ID ' + CAST(@ConfigID AS VARCHAR(10)) + ' and is ' + CASE CAST(@IsEnabled AS CHAR(1)) WHEN '1' THEN 'enabled.' ELSE 'disabled.' END
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

				IF @debug = 1
				BEGIN
					PRINT 'INSERT complete for your new association.'
				END
			END
			ELSE
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Specified association was did not exist. No operations will be conducted.'
				END
			END
		END
		ELSE
		BEGIN
			IF @Remove = 1
			BEGIN 
				IF @debug = 1
				BEGIN
					PRINT 'Specified association exists and will be dropped.'
				END

				--If the @Remove bit is set to true then remove the association.      
				DELETE FROM [IndexMaint].[Configs] WHERE [OptionID] = @OptionID AND [ConfigID] = @ConfigID

				SELECT @LogEntry = 'Index Maintenance OptionID ' + CAST(@OptionID AS VARCHAR(10)) + ' has been disassociated with Configuration ID ' + CAST(@ConfigID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

				IF @debug = 1
				BEGIN
					PRINT 'DELETE complete for specified association.'
				END
			END
			ELSE
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Requested association did already exists. No operations will be conducted.'
				END
			END       
		END      
        
	COMMIT

	SET NOCOUNT OFF