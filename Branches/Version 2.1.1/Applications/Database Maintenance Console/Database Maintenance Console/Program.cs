using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using System.IO;
using System.Data.SqlClient;
using System.Data;

namespace Database_Maintenance_Console
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new frmConnectionManager());
        }
    }

    public static class SQLQueryHandler
    {
        public static DataTable ExecuteSQLCommand(string SQLServerName, string DatabaseName, string SQLCommand, bool IsQuery)
        {
            //Build string to pass to the connection test module.
            string connectionString = "database=" + DatabaseName + ";server=" + SQLServerName + ";Persist Security Info=True;integrated security=SSPI";
            SqlDataReader SQLReader = null;
            DataTable table = new DataTable();

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();

                    if (IsQuery)
                    {
                        using (SqlDataAdapter DataAdaptor = new SqlDataAdapter(SQLCommand, connection))
                        {
                            DataAdaptor.Fill(table);
                        }
                    }
                    else
                    {
                        SqlCommand Command = new SqlCommand(SQLCommand, connection);
                        Command.ExecuteNonQuery();
                    }
                }
                catch (SqlException e)
                {
                    MessageBox.Show(e.ToString());
                }
                finally
                {
                    // Close data reader object and database connection
                    if (SQLReader != null)
                        SQLReader.Close();

                    if (connection.State == ConnectionState.Open)
                        connection.Close();
                }
            }

            return table;
        }

        public static bool IsValidSQLConnection(string SQLServerName, string DatabaseName)
        {
            //Build string to pass to the connection test module.
            string connectionString = "database=" + DatabaseName + ";server=" + SQLServerName + ";Persist Security Info=True;integrated security=SSPI";

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();
                }
                catch
                {
                    return false;
                }
                finally
                {
                    if (connection.State == ConnectionState.Open)
                    {
                        connection.Close();
                    }
                }
            }

            return true;
        }
    }

    public static class LoadTabData
    {
        public static string CentalUtilityDatabaseName = "CentralUtility";
        public static string CurrentCentralUtilityServer = "";
        public static string CurrentUtilityServer = "";
        public static string UtilityDatabaseName = "Utility";
        public static string[] ServerList = null;
        
        public static void LoadConsoleForm()
        {
            //Turn on console display
            Form frmMain = new frmMain();
            frmMain.Show();
        }

        public static DataTable LoadBackupPlans(string UtilityServerName)
        {
            DataTable table = new DataTable();

            string cmd = "SELECT [ConfigName],[OptionID],[DatabaseName],[Enabled],[BackupType],[Periodicity],[StartTime],[Verify],[UseCHECKSUM],[UseCompression],[FileCount]" +
                ",[BufferCount],[MaxTransferSize],[BackupDirectory] FROM [Backup].[vwGetBackupPlan] ORDER BY [DatabaseName], [BackupType], [Enabled];";

            string connectionString = "database=" + UtilityDatabaseName + ";server=" + UtilityServerName + ";Persist Security Info=True;integrated security=SSPI";

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();

                    using (SqlDataAdapter DataAdaptor = new SqlDataAdapter(cmd, connection))
                    {
                        DataAdaptor.Fill(table);
                    }
                }
                catch (SqlException e)
                {
                    MessageBox.Show(e.ToString());
                }
                finally
                {
                    if (connection.State == ConnectionState.Open)
                        connection.Close();
                }
            }

            return table;
        }

        public static void LoadUtilityServerList(string CentralUtilityServerName)
        {
            string cmd = "SELECT ConnectionName FROM Configuration.DataSources ORDER BY ConnectionName;";
            SqlDataReader SQLReader = null;
            LoadTabData.ServerList = new string[1];

            string connectionString = "database=" + CentalUtilityDatabaseName + ";server=" + CentralUtilityServerName + ";Persist Security Info=True;integrated security=SSPI";
            
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();

                    //Build Command
                    SqlCommand Command = new SqlCommand(cmd, connection);

                    SQLReader = Command.ExecuteReader();

                    if (SQLReader.Read())
                    {
                        LoadTabData.ServerList[0] = SQLReader["ConnectionName"].ToString();

                        while (SQLReader.Read())
                        {
                            string[] tempArray = new string[LoadTabData.ServerList.GetUpperBound(0) + 2];

                            if (LoadTabData.ServerList != null)
                            {
                                Array.Copy(LoadTabData.ServerList, tempArray, LoadTabData.ServerList.Length);
                            }

                            LoadTabData.ServerList = tempArray;

                            LoadTabData.ServerList[ServerList.GetUpperBound(0)] = SQLReader["ConnectionName"].ToString();
                        }
                    }
                }
                catch (SqlException e)
                {
                    MessageBox.Show(e.ToString());
                }
                finally
                {
                    // Close data reader object and database connection
                    if (SQLReader != null)
                        SQLReader.Close();

                    if (connection.State == ConnectionState.Open)
                        connection.Close();
                }
            }
        }
    }
}
