/*
CLASS:		    Utility.FileManipulation
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
    public class FileManipulation
    {
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

        public static IEnumerable GetFileList(string targetDirectory, string searchPattern)
        {
            //enable the use of % as a wild card since it's a SQL standard character
            searchPattern = searchPattern.Replace("%", "*");

            try
            {
                ArrayList FilePropertiesCollection = new ArrayList();
                DirectoryInfo dirInfo = new DirectoryInfo(targetDirectory);
                FileInfo[] files = dirInfo.GetFiles(searchPattern);
                foreach (FileInfo fileInfo in files)
                {
                    //I'm adding to the colection the properties (FileProperties) 
                    //of each file I've found  
                    FilePropertiesCollection.Add(new FileProperties(fileInfo.Name,
                    fileInfo.Length, fileInfo.CreationTime));
                }
                return FilePropertiesCollection;
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
