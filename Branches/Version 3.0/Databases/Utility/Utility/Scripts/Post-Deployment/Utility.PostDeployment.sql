/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
BEGIN
	DECLARE @vPostDeploymentStartTime DATETIME = GETDATE(); 
	PRINT 
	'
	 +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 |B|E|G|I|N| |P|O|S|T|D|E|P|L|O|Y|M|E|N|T| |S|C|R|I|P|T| |@| 
	 +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	' 
	+ CONVERT(VARCHAR(30),GETDATE(),120);

	--File system
	:r .\FileAndFileGroupSetup.SQL

	--Data
	:r .\PopulateLookupData.sql
	:r .\PopulateInformationDetails.SQL

	--SQL Agent objects and jobs
	:r .\CreateSQLAgentOperatorAndCategory.sql
	:r .\Jobs\JOB-Utility-BackupJobSpawningController.sql
	:r .\Jobs\JOB-Utility-CycleAllTraceTables.sql
	:r .\Jobs\JOB-Utility-DiskCleanupFilePurge.sql
	:r .\Jobs\JOB-Utility-PopulateCurrentTraceTables.sql
	:r .\Jobs\JOB-Utility-PurgeTableEntires.sql
	:r .\Jobs\JOB-Utility-PurgeTableEntires.sql
	:r .\Jobs\JOB-Utility-ValidateFeatureConfigurations.SQL

	--Server configurations
	:r .\CorrectDatabaseOwner.sql
	:r .\SetupAuditing.sql

	PRINT '
	 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+  
	 |P|O|S|T|D|E|P|L|O|Y|M|E|N|T| |D|U|R|A|T|I|O|N| |=|  
	 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+ 
	 '
	+ CONVERT(VARCHAR(5),DATEDIFF(ss,@vPostDeploymentStartTime,GETDATE())) + ' seconds'; 
	PRINT '
	 +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 |E|N|D| |P|O|S|T|D|E|P|L|O|Y|M|E|N|T| |S|C|R|I|P|T| |@| 
	 +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 '
	 + CONVERT(VARCHAR(30),GETDATE(),120);
END
GO
