--Create service account if not exists
DECLARE @sql NVARCHAR(4000)

--Set selected service account
SELECT @sql =	N'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''$(ServiceAccount)'')
				BEGIN
					CREATE LOGIN [$(ServiceAccount)] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];
				END
				IF NOT EXISTS (	SELECT  r.name
								FROM    master.sys.server_role_members rm
										JOIN master.sys.server_principals r ON r.principal_id = rm.role_principal_id
										JOIN master.sys.server_principals l ON l.principal_id = rm.member_principal_id
								WHERE   l.[name] = ''$(ServiceAccount)''
									AND r.name = ''sysadmin'')
				BEGIN
					EXEC sys.sp_addsrvrolemember @loginame = ''$(ServiceAccount)'', @rolename = ''sysadmin'';
				END
				'
EXEC sp_executesql @statement = @sql;