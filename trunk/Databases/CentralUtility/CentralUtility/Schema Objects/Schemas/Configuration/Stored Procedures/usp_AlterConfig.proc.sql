/*
PROCEDURE:		[Configuration].[usp_AlterConfig]
AUTHOR:			Derik Hammer
CREATION DATE:	5/1/2012
DESCRIPTION:	This procedure is used to alter an existing umbrella configuration.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Config ID to be altered.
				@Name VARCHAR(255) = NULL --New name for the configuration.
				@Desc VARCHAR(8000) = NULL --New description for the configuration.
				@IsEnabled BIT = NULL --Toggle enabled setting.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Configuration].[usp_AlterConfig]
	@debug BIT = 0,
	@ID INT,
	@Name VARCHAR(255) = NULL,
	@Desc VARCHAR(8000) = NULL,
	@IsEnabled BIT = NULL
AS
	SET NOCOUNT ON

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION

		--Declare variables
		DECLARE @UpdateStatement VARCHAR(MAX)
		DECLARE @ErrorMsg VARCHAR(255)
		--Logging
		DECLARE @LogEntry VARCHAR(8000)      

		IF @debug = 1
		BEGIN
			PRINT '**Requested Changes For Existing Config**'
			PRINT 'Config ID: ' + ISNULL(CAST(@ID AS VARCHAR),'NULL')
			PRINT 'Name: ' + ISNULL(@Name,'No Change')
			PRINT 'Description: ' + ISNULL(@Desc,'No Change')
			PRINT 'Enabled: ' + CASE @IsEnabled WHEN 0 THEN 'False' WHEN 1 THEN 'True' WHEN NULL THEN 'No Change' END
			PRINT ''
		END  

		--Checks for the presence of this configuration.
		IF EXISTS	(
							SELECT ConfigID
							FROM Configuration.Configs
							WHERE ConfigID = @ID
						)
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'Config ID, ' + CAST(@ID AS VARCHAR) + ', is valid.'
			END
			
			--Create UPDATE command
			SET @UpdateStatement = 'UPDATE [Configuration].[Configs] SET '

			--Append change variables
			IF @Name IS NOT NULL
			BEGIN
				--Check for a non-unique name
				IF NOT EXISTS	(
							SELECT ConfigID
							FROM Configuration.Configs
							WHERE ConfigName = @Name
						)
				BEGIN
					IF @debug = 1
					BEGIN
						PRINT 'New config name, ''' + @Name + ''', is unique and valid.'  
					END
                    
					SET @UpdateStatement = @UpdateStatement + '[ConfigName] = ''' + @Name + ''','
				END
				ELSE
				BEGIN
					IF @debug = 1
					BEGIN
						PRINT 'New config name, ''' + @Name + ''', is not unique and is therefore invalid.'

						SET @ErrorMsg = 'Input parameter @Name set to value ''' + @Name + ''' is already in use. Config cannot be updated with this value.'
						RAISERROR (@ErrorMsg,16,1)
						ROLLBACK
						RETURN                      
					END
				END
			END
			IF @Desc IS NOT NULL
			BEGIN
				IF RIGHT(@UpdateStatement,1) <> ','
					SET @UpdateStatement = @UpdateStatement + '[ConfigDesc] = ''' + @Desc + ''','
				ELSE
					SET @UpdateStatement = @UpdateStatement + ' [ConfigDesc] = ''' + @Desc + ''','
			END
			IF @IsEnabled IS NOT NULL
			BEGIN
				IF RIGHT(@UpdateStatement,1) <> ','
					SET @UpdateStatement = @UpdateStatement + '[IsEnabled] = ''' + CAST(@IsEnabled AS CHAR(1)) + ''','
				ELSE
					SET @UpdateStatement = @UpdateStatement + ' [IsEnabled] = ''' + CAST(@IsEnabled AS CHAR(1)) + ''','
			END
            
			--Remove trailing comma
			SET @UpdateStatement = LEFT(@UpdateStatement,LEN(@UpdateStatement) - 1)

			--Append config ID dependency
			SET @UpdateStatement = @UpdateStatement + ' WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR)

			IF @debug = 1
			BEGIN
				PRINT '@UpdateStatement = '
				PRINT @UpdateStatement
				PRINT ''
				PRINT 'EXEC ( @UpdateStatement )'
				PRINT ''
				PRINT '**************************************************************************'
				PRINT 'NOTE: Your UPDATE command was not executed due to debugging being enabled.'
				PRINT '**************************************************************************'
			END
			ELSE
			BEGIN
				--Alters the selected config
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @UpdateStatement, @LogMode = 'LIMITED'
				EXEC ( @UpdateStatement )
			END
		END
		ELSE
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'Config ID, ' + CAST(@ID AS VARCHAR) + ', does not exist.'
			END
  
			RAISERROR('Config ID does not exist.',16,1)
		END      
	
	COMMIT     

	SET NOCOUNT OFF