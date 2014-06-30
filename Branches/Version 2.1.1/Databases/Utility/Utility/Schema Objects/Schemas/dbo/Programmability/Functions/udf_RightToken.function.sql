/*
FUNCTION:		dbo.udf_RightToken
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This function will find the right token in a string based on a passed in delimiter.
PARAMETERS:		@String varchar(1000) --String to search.
				@Delimiter varchar(10) --Delimiter to use when finding the right token.

*/
/*
CHANGE HISTORY:


*/
CREATE FUNCTION udf_RightToken 
(
	@String varchar(8000)
	, @Delimiter varchar(10)
)
RETURNS varchar(8000)
AS
BEGIN
	declare @LastSpace int
	declare @TokenLength int
	declare @Token varchar(100)
	select @LastSpace = dbo.udf_PosInString(@Delimiter, @String, 1)	
	set @TokenLength = LEN(@String)-@LastSpace
	Select @Token = RIGHT(@String, @TokenLength)

	RETURN @Token
END

GO