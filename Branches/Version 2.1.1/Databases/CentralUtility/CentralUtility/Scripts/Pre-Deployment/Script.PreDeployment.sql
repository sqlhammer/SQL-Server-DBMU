/*
Begin - CentralUtility - Pre-Deployment Script
*/

GO 
IF ('$(Environment)' = 'Unknown') 
	RAISERROR ('Please set Environment variable before deploying this script. Procedure: Find this string '':setvar Environment "Unknown"'' and replace it with '':setvar Environment "actual environment"''. Acceptable inputs for actual environment include DEV, SIT, QA, or PROD.', 20, 1) WITH LOG
GO 
IF ('$(Environment)' != 'DEV') AND ('$(Environment)' != 'SIT') AND ('$(Environment)' != 'QA') AND ('$(Environment)' != 'PROD')
	RAISERROR ('Environment variable is not set to an acceptable input. Acceptable inputs for the Environment variable include DEV, SIT, QA, or PROD only.', 20, 1) WITH LOG
GO

--Create service account if not exists
DECLARE @ServiceAccount SYSNAME
DECLARE @sql NVARCHAR(4000)

SELECT @ServiceAccount =	CASE '$(Environment)'
								WHEN 'DEV' THEN 'LIBERTY\DevUtility'
								WHEN 'SIT' THEN 'LIBERTY\SITUtility'
								WHEN 'QA' THEN 'LIBERTY\QAUtility'
								WHEN 'PROD' THEN 'LIBERTY\Utility'
							END

SELECT @sql =	N'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''' + @ServiceAccount + ''')
				BEGIN
					CREATE LOGIN [' + @ServiceAccount + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];
				END
				IF NOT EXISTS (	SELECT  r.name
								FROM    master.sys.server_role_members rm
										JOIN master.sys.server_principals r ON r.principal_id = rm.role_principal_id
										JOIN master.sys.server_principals l ON l.principal_id = rm.member_principal_id
								WHERE   l.[name] = ''' + @ServiceAccount + '''
									AND r.name = ''sysadmin'')
				BEGIN
					EXEC sys.sp_addsrvrolemember @loginame = ''' + @ServiceAccount + ''', @rolename = ''sysadmin'';
				END
				'
EXEC sp_executesql @statement = @sql;
GO

/*
End - CentralUtility - Pre-Deployment Script
*/