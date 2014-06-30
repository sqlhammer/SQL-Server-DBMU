/*
PROCEDURE:		[Audit].[usp_DisableServerDDLTrigger]
AUTHOR:			Derik Hammer
CREATION DATE:	10/1/2012
DESCRIPTION:	This procedure will disable the Server level DDL auditing feature.
PARAMETERS:		

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/24/2012 --	This procedure will now ensure the 'Utility - Audit - RESTORE DATABASE' job is
									disabled. In addition validation has been added in case the job or the trigger
									doesn't exist.

*/
CREATE PROCEDURE [Audit].[usp_DisableServerDDLTrigger]
AS
	--Disabled the 'Utility - Audit - RESTORE DATABASE' job
	IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE [Name] = 'Utility - Audit - RESTORE DATABASE')
	BEGIN
		UPDATE MSDB.dbo.sysjobs
			SET Enabled = 0
			WHERE [Name] = 'Utility - Audit - RESTORE DATABASE'

		EXEC Logging.usp_InsertLogEntry @Feature = 'Audit',	@TextEntry = 'Disabled SQL Agent Job - ''Utility - Audit - RESTORE DATABASE''', @LogMode = 'LIMITED'
	END

	--Disable the DDL auditing
	IF EXISTS (SELECT name FROM MASTER.sys.server_triggers WHERE [Name] = 'ServerAuditTrigger')
	BEGIN
		;DISABLE TRIGGER ServerAuditTrigger ON ALL SERVER;

		EXEC Logging.usp_InsertLogEntry @Feature = 'Audit',	@TextEntry = 'DISABLE TRIGGER ServerAuditTrigger ON ALL SERVER', @LogMode = 'LIMITED'
	END
    