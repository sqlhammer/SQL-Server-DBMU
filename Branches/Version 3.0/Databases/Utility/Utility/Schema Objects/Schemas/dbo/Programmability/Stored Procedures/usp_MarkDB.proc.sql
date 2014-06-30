/*
PROCEDURE:		dbo.usp_MarkDB
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure will begin a marked transaction and do an insert into the MarkedTransactions table so it
				will be saved in the transaction log for future reference during synchronized backup file restores.
PARAMETERS:		@Marker VARCHAR(255) --This is the name of the marker for the transaction log. It is passed from the usp_MarkAll
				@DBName NVARCHAR(500) --This is the database name that is being marked for insertion into the MarkTransactions table.
					This is a legacy parameter and in future revisions this parameter can be removed and either replaced with the 
					DB_NAME(DB_ID()) function or remove	the column name from the table since the table is in each database.

*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [dbo].[usp_MarkDB]
	@Marker VARCHAR(255),
	@DBName NVARCHAR(500)
AS

	BEGIN TRANSACTION @Marker WITH MARK 'Marked Transaction for TFS restore sync'
	
		INSERT INTO [dbo].[MarkedTransactions] (Marker_Name, DatabaseName) VALUES (@Marker, @DBName);
		
	COMMIT TRANSACTION @Marker
