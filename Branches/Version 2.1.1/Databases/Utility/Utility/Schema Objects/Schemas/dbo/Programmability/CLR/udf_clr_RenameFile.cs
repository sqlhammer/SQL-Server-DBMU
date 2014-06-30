/*
FUNCTION:		[dbo].[udf_clr_RenameFile]
AUTHOR:			Derik Hammer
CREATION DATE:	4/3/2013
DESCRIPTION:	This function was rewritten and moved into this database project after upgrading to VS2010 SSDT.
                The previous function worked the same but was in its own external CLR project.
PARAMETERS:		string OriginalFilePath = The full file path of the file to be renamed.
                string NewFileName = The new name of the file.

*/
/*
CHANGE HISTORY:



*/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using Utility;
using System.IO;
using System.Collections;
using System.Diagnostics;
using System.Collections.Generic;
using System.Text;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlInt32 udf_clr_RenameFile(string OriginalFilePath, string NewFileName)
    {
        return FileManipulation.RenameFile(OriginalFilePath, NewFileName);
    }
}
