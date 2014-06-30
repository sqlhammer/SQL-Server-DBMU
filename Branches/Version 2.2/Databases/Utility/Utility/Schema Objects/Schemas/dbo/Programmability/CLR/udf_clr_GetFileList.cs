/*
FUNCTION:		[dbo].[udf_clr_GetFileList]
AUTHOR:			Derik Hammer
CREATION DATE:	4/3/2013
DESCRIPTION:	This function was rewritten and moved into this database project after upgrading to VS2010 SSDT.
                The previous function worked the same but was in its own external CLR project.
PARAMETERS:		string targetDirectory = The directory path to search for files in (non-recursive).
                string searchPattern = The search pattern to filter by. * and % are acceptable wild cards.

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
    [Microsoft.SqlServer.Server.SqlFunction(
            FillRowMethodName = "FindFiles",
            TableDefinition = "FileName nvarchar(500), FileSize_Bytes bigint, CreationTime datetime")]
    public static IEnumerable udf_clr_GetFileList(string targetDirectory, string searchPattern)
    {
        return FileManipulation.GetFileList(targetDirectory, searchPattern);
    }

    public static void FindFiles(object objFileProperties, out SqlString fileName, out SqlInt64 fileSize, out SqlDateTime creationTime)
    {
        //I'm using here the FileProperties class defined above
        FileProperties fileProperties = (FileProperties)objFileProperties;
        fileName = fileProperties.FileName;
        fileSize = fileProperties.FileSize;
        creationTime = fileProperties.CreationTime;
    }
}
