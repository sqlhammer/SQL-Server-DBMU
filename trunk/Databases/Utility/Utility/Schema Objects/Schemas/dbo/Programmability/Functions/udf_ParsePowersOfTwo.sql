/*
FUNCTION:		[dbo].[udf_ParsePowersOfTwo]
AUTHOR:			Derik Hammer
CREATION DATE:	12/02/2013
DESCRIPTION:	This function is used to parse out all of the powers of 2 from a given INT.
PARAMETERS:		@PowerOfTwo INT --Inputted aggregate of powers of 2.
*/
/*
CHANGE HISTORY:



*/
CREATE FUNCTION [dbo].[udf_ParsePowersOfTwo]
(
	@PowerOfTwo INT
)
RETURNS @returntable TABLE
(
	value INT
)
AS
BEGIN
	--Implemented for performance; indicates the maximum value that can be submitted to this function
	DECLARE @MaxExponent TINYINT = 7 --Example: POWER(2,7) = 128

	--Variables
	DECLARE @Decrementing_f_Interval INT = @PowerOfTwo;
	DECLARE @CurrentIteration TINYINT = @MaxExponent + 1 --Implemented to prevent infinite loops on invalid inputs
	DECLARE @CurrentExponent TINYINT;
	
	--While there are still viable powers of 2 in the aggregate.
	WHILE @Decrementing_f_Interval > 0
	BEGIN
		--Base value of 2 cause the math to be incorrect so we manually set the exponent to 1 and exit the loop.
		IF @Decrementing_f_Interval = 2
		BEGIN
			SELECT @CurrentExponent = 1, @Decrementing_f_Interval = 0;
		END
		--For all cases greater than 2
		ELSE
		BEGIN
			--Identify if the current aggregate is its own highest power of 2.
			-- - Decrement the iteration condition and set the current exponent for derived return value.
			;WITH 
			TallyTable AS (
				SELECT N FROM dbo.tally WHERE N <= @MaxExponent AND N > 1
			),
			Roots AS (
				SELECT POWER(CAST(@Decrementing_f_Interval AS float),1/CAST(N AS float)) AS [root], N FROM TallyTable
			)
			SELECT TOP 1 @Decrementing_f_Interval = @Decrementing_f_Interval - POWER(2,N)
				, @CurrentExponent = N
			FROM Roots
			WHERE [root] = CAST([root] AS INT)
			ORDER BY N DESC;

			--Identify the highest power of 2 within the current aggregate.
			-- - Decrement the iteration condition and set the current exponent for derived return value.
			;WITH 
			TallyTable AS (
				SELECT N FROM dbo.tally WHERE N <= @MaxExponent AND N > 1
			),
			Roots AS (
				SELECT POWER(CAST(@Decrementing_f_Interval AS float),1/CAST(N AS float)) AS [root], N FROM TallyTable
			)
			SELECT TOP 1 @Decrementing_f_Interval = @Decrementing_f_Interval - POWER(2,N)
				, @CurrentExponent = N
			FROM Roots
			WHERE [root] > 2
			ORDER BY [root] ASC;
		END

		--Populate return table
		INSERT INTO @returntable ( [value] ) VALUES ( POWER(2,@CurrentExponent) );

		--Decrement infinite loop prevention
		SELECT @CurrentIteration = @CurrentIteration - 1;

		--If infinite loop is detected
		-- - invalidate all results and exit
		IF @CurrentIteration < 0
		BEGIN
			DELETE FROM @returntable;
			RETURN
		END
	END -- END WHILE

	--Return result set table
	-- - This is an indication of success
	RETURN 
END
