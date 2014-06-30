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
	DECLARE @vPreDeploymentStartTime DATETIME = GETDATE(); 
	PRINT 
	'
	 +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 |B|E|G|I|N| |P|R|E|-|D|E|P|L|O|Y|M|E|N|T| |S|C|R|I|P|T| |@| 
	 +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	' 
	+ CONVERT(VARCHAR(30),GETDATE(),120);

	--Validation
	:r .\\CheckEnvironment.sql

	--Security
	:r .\\CreateServiceAccount.SQL
	:r .\\CreateCredentialAndProxy.SQL

	--Configuration
	:r .\\SystemConfigurations.sql

	PRINT '
	 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+  
	 |P|R|E|-|D|E|P|L|O|Y|M|E|N|T| |D|U|R|A|T|I|O|N| |=|  
	 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+ 
	 '
	+ CONVERT(VARCHAR(5),DATEDIFF(ss,@vPreDeploymentStartTime,GETDATE())) + ' seconds'; 
	PRINT '
	 +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 |E|N|D| |P|R|E|-|D|E|P|L|O|Y|M|E|N|T| |S|C|R|I|P|T| |@| 
	 +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+ 
	 '
	 + CONVERT(VARCHAR(30),GETDATE(),120);
END
GO
