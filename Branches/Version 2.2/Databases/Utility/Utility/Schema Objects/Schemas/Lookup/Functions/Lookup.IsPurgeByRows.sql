/*
FUNCTION:		[Lookup].[IsPurgeByRows]
AUTHOR:			Derik Hammer
CREATION DATE:	11/28/2013
DESCRIPTION:	This function returns a BIT scalar value indicating whether the given PurgeTypeID is the necessary
				value to purge by rows.
PARAMETERS:		@PurgeTypeID INT -- The PurgeTypeID to be validated.

*/
/*
CHANGE HISTORY:



*/
CREATE FUNCTION [Lookup].[IsPurgeByRows]
(
	@PurgeTypeID INT
)
RETURNS BIT
AS
BEGIN
	DECLARE @IsPurgeByFiles BIT = 0;
	
	SELECT @IsPurgeByFiles = CASE PurgeTypeDesc
								WHEN 'PURGE BY NUMBER OF ROWS' THEN CAST(1 AS BIT)
								ELSE CAST(0 AS BIT)
							END
	FROM [Lookup].[PurgeTypes]
	WHERE PurgeTypeID = @PurgeTypeID;

	RETURN @IsPurgeByFiles;
END
