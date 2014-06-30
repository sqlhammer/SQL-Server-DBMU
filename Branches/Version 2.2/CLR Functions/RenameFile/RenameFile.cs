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
    public static int RenameFile(string OriginalFilePath, string NewFileName)
    {
        // Return code definitions:
        // -- 0 = Success.
        // -- 1 = New file failed to create and old file was not deleted (net result of nothing).
        // -- 2 = New file was created but old file failed to delete.

        //Declares
        string NewFilePath;

        //Set build full path for new file
        NewFilePath = Path.GetPathRoot(OriginalFilePath) + NewFileName;

        //Copy the original file with a new location and/or name
        File.Copy(OriginalFilePath, NewFilePath);

        if (File.Exists(NewFilePath))
        {
            if (File.Exists(OriginalFilePath))
            {
                //If the copyed file exists and the original still exists then delete the original
                File.Delete(OriginalFilePath);

                if (File.Exists(OriginalFilePath))
                {
                    //If the original still exists
                    return 2;
                }
            }
        }
        else
        {
            //If the new file was not created
            return 1;
        }
        
        //If everything is good
        return 0;
    }

}
