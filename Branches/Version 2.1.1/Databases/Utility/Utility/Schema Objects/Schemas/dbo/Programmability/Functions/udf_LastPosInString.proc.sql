/*
FUNCTION:		dbo.udf_clr_DeleteFile
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This function will find a position in a string based on a pattern.
PARAMETERS:		@pattern varchar(10) --Search pattern to use as a split 
				@string varchar(1000) --String to search in.
				@last bit --Default is 1 which will pull the last position in the string. Setting
					it to 0 would indicate the first position in the string.
*/
/*
CHANGE HISTORY:


*/
CREATE FUNCTION udf_PosInString 
(
	 @pattern varchar(10),
	 @string varchar(1000),
	 @last bit = 1
)
RETURNS int
AS
BEGIN
	declare @start int, @position int

	--a filter to start after a comma to account for backup files with spaces
	set @position = charindex(',', @string)
	set @start = @position

	IF @last = 1
	BEGIN
	set @position = charindex(@pattern, @string, @start+1)
	set @start = @position
	while @start <> 0
		begin
		   set @start = charindex(@pattern, @string, @start+1)
		   If @start <> 0
			set @position = @start
		END
	END
	ELSE
	BEGIN
		set @position = charindex(@pattern, @string, @start+1)
	END
	RETURN @position
END

GO