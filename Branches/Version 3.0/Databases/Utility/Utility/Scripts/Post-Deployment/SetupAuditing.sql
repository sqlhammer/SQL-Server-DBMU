/*		Populate initial audit option record.		*/
IF NOT EXISTS (SELECT OptionID FROM [Audit].[Options])
	INSERT INTO [Audit].[Options] ( [PurgeValue], [PurgeTypeID] ) VALUES (NULL, NULL);
/****************************************************/

/***************** Setup Server DDL Auditing **************************/

IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
	EXEC [Utility].[Audit].[usp_SetupServerDDLAudit]

/**********************************************************************/
