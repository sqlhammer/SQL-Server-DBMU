/*
CLASS:		    Utility.FileProperties
AUTHOR:			Derik Hammer
CREATION DATE:	4/3/2013
DESCRIPTION:	This class was rewritten and moved into this database project after upgrading to VS2010 SSDT.
                The previous class worked the same but was in its own external CLR project.
*/
/*
CHANGE HISTORY:



*/
using System;
using System.IO;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections;
using System.Diagnostics;
using Microsoft.SqlServer.Server;
using System.Collections.Generic;
using System.Text;

namespace Utility
{
    public class FileProperties
    {
        public SqlString FileName;
        public SqlInt64 FileSize;
        public SqlDateTime CreationTime;
        public FileProperties(SqlString fileName, SqlInt64 fileSize, SqlDateTime creationTime)
        {
            FileName = fileName;
            FileSize = fileSize;
            CreationTime = creationTime;
        }
    }   
}
