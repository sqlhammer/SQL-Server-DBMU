using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Data.SqlClient;

namespace Database_Maintenance_Console
{
    public partial class frmConnectionManager : Form
    {
        public frmConnectionManager()
        {
            InitializeComponent();
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void btnAddCentralServer_Click(object sender, EventArgs e)
        {
            //Append a new Central Utility Server to the StoredConnections.config file
            StoreNewCentralUtilityServer();
        }

        private void RefreshCentralUtilityServerList()
        {
            //Clear list in preparation for refreshed data
            lstCentralServers.Items.Clear();
            
            //create streamreader
            StreamReader sr = new StreamReader("StoredConnections.config");

            //Add each line in the StoredConnections.config file into the list
            while (sr.Peek() > -1)
            {
                lstCentralServers.Items.Add(sr.ReadLine());
            }

            //Close file
            sr.Close();
        }

        private void StoreNewCentralUtilityServer()
        {
            //Check to see if server already exists
            bool ServerExists = false;

            if (lstCentralServers.Items.Contains(this.txtCentralUtilityServer.Text))
            {
                ServerExists = true;
            }
            
            if (!ServerExists)
            {
                //Create filestream and StreamWriter objects
                FileStream fs = File.Open("StoredConnections.config", FileMode.Append, FileAccess.Write);
                StreamWriter sw = new StreamWriter(fs);

                //Append new Central Utility Server
                sw.WriteLine(this.txtCentralUtilityServer.Text);

                //Close files
                sw.Close();
                fs.Close();

                //Refresh the server list
                RefreshCentralUtilityServerList();
            }
        }

        private void frmConnectionManager_Load(object sender, EventArgs e)
        {
            //Refresh the server list
            RefreshCentralUtilityServerList();

            //Reset status bar
            this.toolStripStatusLabel.Text = "Ready";
        }

        private void RemoveStoredCentralUtilityServer()
        {
            //create streamreader
            StreamReader sr = new StreamReader("StoredConnections.config");
            string[] tempFileContents = new string[1];

            tempFileContents[0] = sr.ReadLine();

            //Add each line in the StoredConnections.config file into the list
            while (sr.Peek() > -1)
            {
                //perform a redim preserve
                string[] tempArray = new string[tempFileContents.GetUpperBound(0)+2];

                if (tempFileContents != null)
                {
                    Array.Copy(tempFileContents, tempArray, tempFileContents.Length);
                }

                tempFileContents = tempArray;

                //add the next server into the tempFileContents
                tempFileContents[tempFileContents.GetUpperBound(0)] = sr.ReadLine();
            }

            //Close file
            sr.Close();

            /////////////////////////////////////////////

            //Create filestream and StreamWriter objects by truncating any existing file
            FileStream fs = File.Open("StoredConnections.config", FileMode.Create, FileAccess.Write);
            StreamWriter sw = new StreamWriter(fs);
            int cnt = 0;

            while (cnt <= tempFileContents.GetUpperBound(0))
            {
                if (tempFileContents.GetValue(cnt).ToString() != lstCentralServers.SelectedItem.ToString())
                {
                    //Append new Central Utility Server
                    sw.WriteLine(tempFileContents.GetValue(cnt));
                }

                cnt++;
            }

            //Close files
            sw.Close();
            fs.Close();

            //Refresh the server list
            RefreshCentralUtilityServerList();
        }

        private void btnRemoveCentralServer_Click(object sender, EventArgs e)
        {
            RemoveStoredCentralUtilityServer();
        }

        private void TestSQLConnection(string SQLServerName)
        {
            //Build string to pass to the connection test module.
            string connectionString = "database=CentralUtility;server=" + SQLServerName + ";Persist Security Info=True;integrated security=SSPI";
            
            //Manipulate the status bar results depending upon status and results.
            this.toolStripStatusLabel.Text = "Connection Test In Progress...";

            Application.DoEvents();

            if (IsSQLServerConnected(connectionString))
            {
                this.toolStripStatusLabel.Text = "Connection Test Successful";
            }
            else
            {
                this.toolStripStatusLabel.Text = "Connection Test Failed";
            }
        }

        private static bool IsSQLServerConnected(string connectionString)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();
                    return true;
                }
                catch (SqlException)
                {
                    return false;
                }
                finally
                {
                    //Close the connection just incase it is still open.
                    connection.Close();
                }
            }
        }

        private void btnTestConnection_Click(object sender, EventArgs e)
        {
            TestSQLConnection(this.txtCentralUtilityServer.Text);
        }

        private void lstCentralServers_SelectedIndexChanged(object sender, EventArgs e)
        {
            try
            {
                this.txtCentralUtilityServer.Text = this.lstCentralServers.SelectedItem.ToString();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void lstCentralServers_DoubleClick(object sender, EventArgs e)
        {
            btnConnect.PerformClick();
        }

        private void btnConnect_Click(object sender, EventArgs e)
        {
            this.toolStripStatusLabel.Text = "Loading Database Maintenance Utility Console...";
            Application.DoEvents();

            //Set public variable to keep track of currently selected CentralUtility server
            LoadTabData.CurrentCentralUtilityServer = this.txtCentralUtilityServer.Text;

            //Load the new main console form
            LoadTabData.LoadConsoleForm();

            //Close the old main console form if open
            int cnt = 0;
            foreach (Form OpenForm in Application.OpenForms)
            {
                if (OpenForm.Name == "frmMain")
                    cnt++;
            }
            if (cnt > 1)
            {
                CloseOpenForm(typeof(frmMain));
            }

            //Hide the connection manager
            this.Hide();
        }

        public static Form IsFormAlreadyOpen(Type FormType)
        {
            foreach (Form OpenForm in Application.OpenForms)
            {
                if (OpenForm.GetType() == FormType)
                    return OpenForm;
            }

            return null;
        }

        public static void CloseOpenForm(Type FormType)
        {
            foreach (Form OpenForm in Application.OpenForms)
            {
                if (OpenForm.GetType() == FormType)
                {
                    OpenForm.Close();
                    break;
                }
            }
        }
    }
}

