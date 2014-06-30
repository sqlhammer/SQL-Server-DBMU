/*
FUNCTION:		dbo.udf_ReadJobSchedule
AUTHOR:			Derik Hammer
CREATION DATE:	9/13/2012
DESCRIPTION:	This function returns a single row table that contains an easy to read translation of the
				detailed SQL Agent (int) schedule format.
PARAMETERS:		@f_Type INT - dbo.sysschedules freq_type equivalent. How frequently a job runs for this schedule.
				@f_Interval INT - dbo.sysschedules freq_Interval equivalent. Days that the job is executed. 
					Depends on the value of freq_type. A setting of 0 indicates that freq_interval is unused.
				@f_SubDay_Type INT - dbo.sysschedules freq_SubDay_Type equivalent.  Units for the freq_subday_interval.
				@f_SubDay_Interval INT - dbo.sysschedules freq_SubDay_Interval equivalent. Number of freq_subday_type 
					periods to occur between each execution of the job.
				@f_relative_interval INT - dbo.sysschedules freq_relative_interval equivalent. Which day of the month 
					when freq_interval occurs in each month, if freq_interval is 32 (monthly relative).
				@f_Recurrence_Factor INT - dbo.sysschedules freq_Recurrence_Factor equivalent. Number of weeks or 
					months between the scheduled execution of a job. freq_recurrence_factor is used only if freq_type 
					is 8, 16, or 32. If this column contains 0, freq_recurrence_factor is unused.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 01/15/2013 --	Corrected bug where periodicities below daily weren't showing up correctly and accounted
									for changes relevant to the Monthly periodicity in the udf_TranslateJobSchedule function.

** Derik Hammer ** 02/19/2013 --	Added a length check on @MultiDayString to avoid an invalid length error on the RIGHT()
									function when @f_Interval = 0.

*/
CREATE FUNCTION [dbo].[udf_ReadJobSchedule]
(
	@f_Type INT
	, @f_Interval INT
	, @f_SubDay_Type INT
	, @f_SubDay_Interval INT
	, @f_relative_interval INT
	, @f_Recurrence_Factor INT
)
RETURNS VARCHAR(250)
AS
BEGIN

	--Declare variables
	DECLARE @EasyReadSchedule VARCHAR(250)
	DECLARE @MultiDayString VARCHAR(1000) = ''
	DECLARE @Decrementing_f_Interval INT = @f_Interval

	WHILE @Decrementing_f_Interval > 0
	BEGIN
		SELECT @MultiDayString = @MultiDayString + ',' + 
			CASE 
				WHEN @Decrementing_f_Interval >= 64 THEN 'Saturday'
				WHEN @Decrementing_f_Interval >= 32 THEN 'Friday'
				WHEN @Decrementing_f_Interval >= 16 THEN 'Thursday'
				WHEN @Decrementing_f_Interval >= 8 THEN 'Wednesday'
				WHEN @Decrementing_f_Interval >= 4 THEN 'Tuesday'
				WHEN @Decrementing_f_Interval >= 2 THEN 'Monday'
				WHEN @Decrementing_f_Interval >= 1 THEN 'Sunday'
			END
		
		SELECT @Decrementing_f_Interval = 
			CASE      
				WHEN @Decrementing_f_Interval >= 64 THEN @Decrementing_f_Interval - 64
				WHEN @Decrementing_f_Interval >= 32 THEN @Decrementing_f_Interval - 32
				WHEN @Decrementing_f_Interval >= 16 THEN @Decrementing_f_Interval - 16
				WHEN @Decrementing_f_Interval >= 8 THEN @Decrementing_f_Interval - 8
				WHEN @Decrementing_f_Interval >= 4 THEN @Decrementing_f_Interval - 4
				WHEN @Decrementing_f_Interval >= 2 THEN @Decrementing_f_Interval - 2
				WHEN @Decrementing_f_Interval >= 1 THEN @Decrementing_f_Interval - 1
			END
	END 
	--Remove leading ','       
	IF LEN(@MultiDayString) > 0   
		SELECT @MultiDayString = RIGHT(@MultiDayString,LEN(@MultiDayString)-1) 

	SELECT @EasyReadSchedule =	CASE 
									  WHEN @f_Type = 1 THEN 'On demand'
									  WHEN @f_Type = 4 AND @f_Interval = 1 AND @f_SubDay_Type = 1 AND @f_SubDay_Interval = 0 THEN 'Daily'
									  WHEN @f_Type = 4 AND @f_Interval > 1 THEN 'Every ' + CONVERT(VARCHAR(10),@f_Interval) + ' days'
									  WHEN @f_Type = 8  THEN 'Weekly on ' +	@MultiDayString
									  WHEN @f_Type = 16 THEN 'Monthly on day ' + CONVERT(VARCHAR(10),@f_Interval)
									  WHEN @f_Type = 32 THEN 'Monthly on the ' +	CASE @f_relative_interval 
																						WHEN 1 THEN 'first'
																						WHEN 2 THEN 'second'
																						WHEN 4 THEN 'third'
																						WHEN 8 THEN 'fourth'
																						WHEN 16 THEN 'last'
																					END
																				+	CASE @f_Interval
																						WHEN 1 THEN ' Sunday'
																						WHEN 2 THEN ' Monday'
																						WHEN 3 THEN ' Tuesday'
																						WHEN 4 THEN ' Wednesday'
																						WHEN 5 THEN ' Thursday'
																						WHEN 6 THEN ' Friday'
																						WHEN 7 THEN ' Saturday'
																						WHEN 8 THEN ' day'
																						WHEN 9 THEN ' weekday'
																						WHEN 10 THEN ' weekend day'
																					END
									  WHEN @f_Type = 64 THEN 'When SQL Agent service starts'
									  WHEN @f_Type = 128 THEN 'When computer is idle'
									  WHEN @f_Type = 4 AND @f_Interval = 0 AND @f_SubDay_Type > 1 THEN 'Every ' + 
																											CONVERT(VARCHAR(10),@f_SubDay_Interval) +	CASE @f_SubDay_Type 
																																							WHEN 2 THEN ' second(s)'
																																							WHEN 4 THEN ' minute(s)'
																																							WHEN 8 THEN ' hour(s)'
																																						END                                                                                                                          
						END

    --Return the string
	RETURN @EasyReadSchedule
END
