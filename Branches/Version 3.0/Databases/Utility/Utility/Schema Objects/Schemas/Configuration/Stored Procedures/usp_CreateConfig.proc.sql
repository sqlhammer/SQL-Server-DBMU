/*
PROCEDURE:		[Configuration].[usp_CreateConfig]
AUTHOR:			Derik Hammer
CREATION DATE:	4/28/2012
DESCRIPTION:	This procedure is used to create a new umbrella configuration without any associated feature options.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@Name VARCHAR(255) --Name of the configuration.
				@Desc VARCHAR(8000) --Description of the configuration. Default set to NULL.
				@IsEnabled BIT --Whether the umbrella configuration should be set to enabled when created.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 09/06/2013 --	Set return value to provide user with the new option id.

*/
CREATE PROCEDURE [Configuration].[usp_CreateConfig]
	@debug BIT = 0,
	@Name VARCHAR(255),
	@Desc VARCHAR(8000) = NULL,
	@IsEnabled BIT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON  

	BEGIN TRANSACTION
  
		DECLARE @ReturnValue INT = 0
		--Logging
		DECLARE @LogEntry VARCHAR(8000)

		IF @debug = 1
		BEGIN
			PRINT '**Requested Settings for new Config**'
			PRINT 'Name: ' + @Name
			PRINT 'Description: ' + @Desc
			PRINT 'Enabled: ' + CASE @IsEnabled WHEN 0 THEN 'False' WHEN 1 THEN 'True' END
			PRINT ''
		END  

		--Checks for the presence of this configuration.
		IF NOT EXISTS	(
							SELECT ConfigID
							FROM Configuration.Configs
							WHERE ConfigName = @Name
						)
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'Configuration named, ''' + @Name + ''', is new and valid.'
			END
            
			--Creates new configuration where there wasn't one already.  
			INSERT INTO Configuration.Configs (ConfigName,ConfigDesc,IsEnabled)
				VALUES (@Name,@Desc,@IsEnabled)

			SELECT @LogEntry = 'Created new Configuration: Name = ' + @Name + ', Description = ' + ISNULL(@Desc,'NULL') + ', ' + CASE CAST(@IsEnabled AS CHAR(1)) WHEN '1' THEN 'set to Enabled.' ELSE 'set as Disabled.' END
			EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

			IF @debug = 1
			BEGIN
				PRINT 'Insert of configuration complete and successful.'
			END       
		END  
		ELSE
		BEGIN
			IF @debug = 1
			BEGIN          
				PRINT 'Configuration named, ''' + @Name + ''', already exists.'
			END
		END

	COMMIT
	SELECT TOP 1  @ReturnValue = ConfigID
	FROM Configuration.Configs
	WHERE ConfigName = @Name     
  
	SET NOCOUNT OFF    
	RETURN ISNULL(@ReturnValue,0)
