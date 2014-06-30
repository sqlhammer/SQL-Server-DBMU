/*
PROCEDURE:		dbo.usp_MarkAll
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure will execute the usp_MarkDB procedure on all database on the server that have the procedure applied
				to them. Then it will purge old records in their MarkedTransactions tables. The purpose of this is to set a marker
				in all database transaction logs that can be referenced in the future when doing database restores. Applications
				such as Biztalk and TFS require this due to the inter-database dependencies of data and the fact that it is impossible
				to synchronize multiple database backups.
PARAMETERS:		@Marker VARCHAR(255) --This is the name of the marker for the transaction log. It is passed to the usp_MarkDB procedures.
				@purgedate DATETIME2 --This parameter is a date for the MarkedTransactions table to be purged by. The only purpose of this
					is to prevent the MarkedTransaction table from growing unchecked.

*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [dbo].[usp_MarkAll]
	@MarkName NVARCHAR(128), 
	@purgedate DATETIME2 /*DECLARE @date DATETIME2; SET @date=getdate()-30*/
AS
	
	BEGIN TRANSACTION @MarkName WITH MARK 'Marked Transaction for TFS restore sync'
	
		DECLARE @sql AS VARCHAR(8000)
		SET @sql = 'USE [?]; IF EXISTS (SELECT name FROM [sys].[procedures] WHERE name = ''usp_MarkDB'')
									 EXEC [dbo].[usp_MarkDB] @Marker=' + @MarkName + ', @DBName=''?'';
		IF EXISTS (SELECT NAME FROM [sys].[objects] WHERE name = ''MarkedTransactions'')
									DELETE FROM [dbo].[MarkedTransactions] WHERE COMMIT_TIME < ''' + CAST(@purgedate AS VARCHAR(15)) + ''''
		
		EXEC [sys].[sp_MSforeachdb] @sql
		
	COMMIT TRANSACTION @MarkName