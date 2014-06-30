IF ('$(Environment)' = 'Unknown') 
	RAISERROR ('Please set Environment variable before deploying this script. Procedure: Find this string '':setvar Environment "Unknown"'' and replace it with '':setvar Environment "actual environment"''. Acceptable inputs for actual environment include DEV, SIT, QA, or PROD.', 20, 1) WITH LOG

IF ('$(Environment)' != 'DEV') AND ('$(Environment)' != 'SIT') AND ('$(Environment)' != 'QA') AND ('$(Environment)' != 'PROD')
	RAISERROR ('Environment variable is not set to an acceptable input. Acceptable inputs for the Environment variable include DEV, SIT, QA, or PROD only.', 20, 1) WITH LOG
