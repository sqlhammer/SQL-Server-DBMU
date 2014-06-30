-- =============================================
-- This is to be manually added to the build script
-- so to rename the previous database before deploying
-- a new one. Then there will be a post deploy script
-- to pull over the previous version's settings.
-- =============================================

USE [$(DatabaseName)]
GO
DECLARE @NewDBName SYSNAME
DECLARE @NewFileName sysname, @OriginalFilePath NVARCHAR(260), @RenameReturnCode TINYINT, @msg NVARCHAR(4000),
	@AllFilesRenamedSuccessfully BIT = 1

--Set New DB Name
SET @NewDBName = '$(DatabaseName)_auto_bk_' + REPLACE(CONVERT(VARCHAR(10),GETDATE(),120),'-','')

--Store database file locations for renaming
IF OBJECT_ID('tempdb..##DatabaseFileRename') IS NOT NULL
	DROP TABLE ##DatabaseFileRename

SELECT (REPLACE(name,'$(DatabaseName)', @NewDBName) + '.' + RIGHT(physical_name,3)) AS [NewLogicalName]
	, physical_name 
INTO ##DatabaseFileRename 
FROM sys.database_files

--Rename Database
IF EXISTS (SELECT database_id FROM sys.databases WHERE NAME = '$(DatabaseName)')
BEGIN
	ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	EXEC sys.sp_renamedb @dbname = '$(DatabaseName)', @newname = @NewDBName
	EXEC ('ALTER DATABASE [' + @NewDBName + '] SET MULTI_USER')
END

--Detach database and set it offline to get around a bug where detach isn't possible.
EXEC ( 'ALTER DATABASE [' + @NewDBName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE
		EXEC sys.sp_detach_db @dbname = ''' + @NewDBName + '''')

--Rename files
DECLARE Renaming_Cursor CURSOR FORWARD_ONLY STATIC LOCAL READ_ONLY FOR
SELECT [NewLogicalName], physical_name FROM ##DatabaseFileRename

OPEN Renaming_Cursor
FETCH NEXT FROM Renaming_Cursor INTO @NewFileName, @OriginalFilePath

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @RenameReturnCode = NULL --clear return code
	EXEC @RenameReturnCode = [dbo].[udf_clr_RenameFile] @NewFileName=@NewFileName, @OriginalFilePath=@OriginalFilePath

	-- 1 = New file failed to create and old file was not deleted (net result of nothing).
	IF @RenameReturnCode = 1
	BEGIN
		SET @AllFilesRenamedSuccessfully = 0  
		SET @msg = 'New file (' + @NewFileName + ') failed to create and old file (' + @OriginalFilePath + ') was not deleted (net result of nothing).'
		RAISERROR(@msg, 16, 1)
	END  
	-- 2 = New file was created but old file failed to delete.
	IF @RenameReturnCode = 1
	BEGIN
		SET @AllFilesRenamedSuccessfully = 0
		SET @msg = 'New file (' + @NewFileName + ') was created but old file (' + @OriginalFilePath + ') failed to delete.'
		RAISERROR(@msg, 16, 1)
	END 
	-- NULL result
	IF @RenameReturnCode IS NULL
	BEGIN
		SET @AllFilesRenamedSuccessfully = 0
		SET @msg = 'Return code from clr_RenameFile was NULL indicating an unknown result. Validate that the file renaming was successful.
		Database Attachment process skipped due to this result.
		**New file name: ' + @NewFileName + ' -- Original file path: ' + @OriginalFilePath + '**'
		RAISERROR(@msg, 16, 1)
	END 

	FETCH NEXT FROM Renaming_Cursor INTO @NewFileName, @OriginalFilePath
END

CLOSE Renaming_Cursor
DEALLOCATE Renaming_Cursor

--Re-attach database
-- --Don't attempt an attach without all of the files.
IF @AllFilesRenamedSuccessfully = 1
BEGIN
	DECLARE @sql NVARCHAR(4000), @RootFilePath NVARCHAR(260), @RightToken INT
	SET @sql = 	'CREATE DATABASE ' + @NewDBName + ' ON '

	DECLARE Attach_Cursor CURSOR FORWARD_ONLY STATIC LOCAL READ_ONLY FOR
	SELECT [NewLogicalName], physical_name FROM ##DatabaseFileRename

	OPEN Attach_Cursor
	FETCH NEXT FROM Attach_Cursor INTO @NewFileName, @OriginalFilePath

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @RightToken = dbo.udf_PosInString('\',@OriginalFilePath,1)
		SET @RootFilePath = LEFT(@OriginalFilePath,@RightToken)

		SET @sql = @sql + '(FILENAME = ''' + @RootFilePath + @NewFileName + '''), '

		FETCH NEXT FROM Attach_Cursor INTO @NewFileName, @OriginalFilePath
	END

	--Remove trailing ', '
	SET @sql = LEFT(@sql,LEN(@sql)-2)

	SET @sql = @sql + ' FOR ATTACH;'

	--PRINT @sql
	EXEC (@sql)

END

--Turn database back online
EXEC ( 'ALTER DATABASE [' + @NewDBName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE' )

--Renaming garbage collection
IF OBJECT_ID('tempdb..##DatabaseFileRename') IS NOT NULL
	DROP TABLE ##DatabaseFileRename
