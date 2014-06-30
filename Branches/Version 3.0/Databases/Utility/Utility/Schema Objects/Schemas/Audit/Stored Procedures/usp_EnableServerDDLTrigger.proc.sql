/*
PROCEDURE:		[Audit].[usp_EnableServerDDLTrigger]
AUTHOR:			Derik Hammer
CREATION DATE:	10/1/2012
DESCRIPTION:	This procedure will enable the Server level DDL auditing feature.
PARAMETERS:		

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/24/2012 --	This procedure will now ensure the 'Utility - Audit - RESTORE DATABASE' job is
									enabled. In addition if any audit components are missing they will be created
									during the enabling process.

*/
CREATE PROCEDURE [Audit].[usp_EnableServerDDLTrigger]
AS
	--Enable the 'Utility - Audit - RESTORE DATABASE' job
	IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE [Name] = 'Utility - Audit - RESTORE DATABASE')
	BEGIN
		UPDATE MSDB.dbo.sysjobs
			SET Enabled = 1
			WHERE [Name] = 'Utility - Audit - RESTORE DATABASE'

		EXEC Logging.usp_InsertLogEntry @Feature = 'Audit',	@TextEntry = 'Enabled SQL Agent Job - ''Utility - Audit - RESTORE DATABASE''', @LogMode = 'LIMITED'
	END
	ELSE
	BEGIN
		--Create the job if it doesn't exist by validating the entire audit setup  
		EXEC [Audit].[usp_SetupServerDDLAudit]
	END
	  
	--Enable the DDL auditing
	IF EXISTS (SELECT name FROM MASTER.sys.server_triggers WHERE [Name] = 'ServerAuditTrigger')
	BEGIN
		;ENABLE TRIGGER ServerAuditTrigger ON ALL SERVER;
    
		EXEC Logging.usp_InsertLogEntry @Feature = 'Audit',	@TextEntry = 'ENABLE TRIGGER ServerAuditTrigger ON ALL SERVER', @LogMode = 'LIMITED'
	END
	ELSE
	BEGIN
		--Create the job if it doesn't exist by validating the entire audit setup  
		EXEC [Audit].[usp_SetupServerDDLAudit]
	END
    