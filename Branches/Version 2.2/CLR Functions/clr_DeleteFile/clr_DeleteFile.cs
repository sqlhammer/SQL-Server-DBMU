using System;
using System.IO;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections;
using System.Diagnostics;
using Microsoft.SqlServer.Server;

public class UserDefinedFunctions
{

    [Microsoft.SqlServer.Server.SqlFunction]
    public static int DeleteFile(string path)
    {
        string FileExtention;

        FileExtention = path.Substring((path.Length - 3), 3);
        FileExtention = FileExtention.ToUpper();

        if ((FileExtention != "TRC") && (FileExtention != "BAK") && (FileExtention != "TRN") 
            && (FileExtention != "ADF") && (FileExtention != "CER") && (FileExtention != "KEY"))
            return 1;

        if (!File.Exists(path))
            return 2;

        File.Delete(path);

        if (File.Exists(path))
            return 3;

        return 0;
    }

}