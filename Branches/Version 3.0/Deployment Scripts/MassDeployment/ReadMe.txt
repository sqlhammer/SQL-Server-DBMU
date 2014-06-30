Title:		MassDeployment.ps1

Author:		Mikhail Wall

Purpose:	To allow database deployment via .dacpac to multiple server instances through 
		SQLPACKAGE.EXE.

Required:	The following directories/files must be present in the specified locations.

		1. Root script [directory] - default is 'MassDeployment'.

			(1).	MassDeployment.ps1 [file] - The PowerShell script to be invoked.

			(2).	*.publish.xml [file(s)] - default is Mass-Deploy.publish.xml.
				Multiple files can be present.  The script will use the file specified 
				in the input parameters.

			(3).	DATABASE_NAME.dacpac [file(s)] - default is Utility.dacpac.M
				ultiple files can be present.  The script will use the file specified in 
				the input parameters.

			(4).	SsdtDeploymentTool [directory] - application directory.

				i.	Redistribute [directory] - application sub-directory that 
					contains 'SqlPackage.exe' and associated sub-directories and 
					files.

			(5)	Environment specific directories [directory] - contains files necessary
				to deploy to the associated environment.

				i.	*.txt [file] - default is ConnectionStrings.txt.  This is
					a new-line delimited list of server instances to deploy
					to.  MUST BE POPULATED PRIOR TO SCRIPT EXECUTION.  The path to 
					the desired environment must be passed at execution.

		* NOTE: The paths to all above objects have default parameter values in the script, with
			the execption of the connection string text file(s).  If the above structure/naming
			conventions are maintained no additional parameters are required for full deployment
			(see MassDeployment.ps1 parameter declarations for further clarification).
			Modification to name/location of any of the above, will require that assocated full
			path to passed in to the script.
			