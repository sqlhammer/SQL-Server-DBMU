using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Data.SqlClient;
using Microsoft.VisualBasic;

namespace Database_Maintenance_Console
{
    public partial class frmMain : Form
    {
        public frmMain()
        {
            InitializeComponent();
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            //Close the program
            Application.Exit();
        }

        private void connectionManagerToolStripMenuItem_Click(object sender, EventArgs e)
        {
            //Load connection manager form.
            Form frmConnectionManager = new frmConnectionManager();
            frmConnectionManager.Show();
        }

        private void frmMain_FormClosed(object sender, FormClosedEventArgs e)
        {
            int cnt = 0;

            //Count the number of frmMains open
            foreach (Form OpenForm in Application.OpenForms)
            {
                if (OpenForm.Name == "frmMain")
                    cnt++;
            }

            //Exit the application if there are no more frmMains open
            if (cnt == 0)
                Application.Exit();
        }

        private void frmMain_Load(object sender, EventArgs e)
        {
            //Initial load of the  Utility server list
            RefreshUtilityServerList();
           
        }

        private void refreshServerListToolStripMenuItem_Click(object sender, EventArgs e)
        {
            RefreshUtilityServerList();
        }

        private void refreshAllToolStripMenuItem_Click(object sender, EventArgs e)
        {
            RefreshAll();
        }

        public void RefreshUtilityServerList()
        {
            string SelectedUtilityServer = "";

            //Check to see if the lstServerNames is loaded and has a selected item
            if (lstServerNames.SelectedItem != null)
            {
                SelectedUtilityServer = lstServerNames.SelectedItem.ToString();
            }
            
            //reload server list
            LoadTabData.LoadUtilityServerList(LoadTabData.CurrentCentralUtilityServer);
            lstServerNames.ClearSelected();
            lstServerNames.Items.Clear();
            if (LoadTabData.ServerList != null)
            {
                lstServerNames.Items.AddRange(LoadTabData.ServerList);
            }

            //Re-select the selected item from before the refresh
            if ((lstServerNames.Items.Contains(SelectedUtilityServer)) && (SelectedUtilityServer != string.Empty))
            {
                int index = lstServerNames.FindStringExact(SelectedUtilityServer);
                if (index != -1)
                {
                    lstServerNames.SetSelected(index, true);
                }
            }

            Application.DoEvents();
        }

        public void RefreshAll()
        {
            //Refresh the Utility database server list
            RefreshUtilityServerList();

            //Refresh Backup Tab
            RefreshBackupsTab();
        }

        private void btnAddServers_Click(object sender, EventArgs e)
        {
            AddNewUtilityServer();
        }

        private void AddNewUtilityServer()
        {
            string input = Interaction.InputBox("Enter the name of the server that you wish to add.", "Add Utility Server", "<Enter Server Name Here>");
            DialogResult result = new DialogResult();
            bool IsValid = false;

            do
            {
                if ((input == null) || (input == string.Empty))
                {
                    result = DialogResult.Cancel;
                }
                else
                {
                    toolStripStatusLabel.Text = "Performing connection test on \'" + input + "\'...";
                    Application.DoEvents();
                    IsValid = SQLQueryHandler.IsValidSQLConnection(input, LoadTabData.UtilityDatabaseName);
                    toolStripStatusLabel.Text = "Ready";
                    Application.DoEvents();

                    if (IsValid)
                    {
                        string SQLCommand = "IF NOT EXISTS (SELECT ConnectionName FROM Configuration.DataSources WHERE ConnectionName = \'" + input +
                            "\') BEGIN INSERT INTO Configuration.DataSources (ConnectionName, ConnectionString) VALUES (\'" + input +
                            "\',\'Data Source=" + input + ";Initial Catalog=" + LoadTabData.UtilityDatabaseName + ";Provider=SQLNCLI10.1;Integrated " +
                            "Security=SSPI;Application Name=Utility;Auto Translate=False;\') END";

                        SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentCentralUtilityServer, LoadTabData.CentalUtilityDatabaseName, SQLCommand, false);
                    }
                    else
                    {
                        result = MessageBox.Show("Connection test failed for \'" + input + "\'. Record was not inserted.", "Connection Test", MessageBoxButtons.RetryCancel, MessageBoxIcon.Error);
                    }
                }
            }
            while ((result == DialogResult.Retry) && (!IsValid));

            toolStripStatusLabel.Text = "Ready";
            Application.DoEvents();

            RefreshUtilityServerList();
        }

        private void btnRemoveServer_Click(object sender, EventArgs e)
        {
            RemoveUtilityServer();
        }

        private void RemoveUtilityServer()
        {
            if ((LoadTabData.CurrentUtilityServer != null) && (LoadTabData.CurrentUtilityServer != ""))
            {
                string SQLCommand = "DELETE FROM Configuration.DataSources WHERE ConnectionName = \'" + LoadTabData.CurrentUtilityServer + "\'";

                SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentCentralUtilityServer, LoadTabData.CentalUtilityDatabaseName, SQLCommand, false);
            }

            RefreshUtilityServerList();
        }
        
        private void RefreshBackupsTab()
        {
            //Verify there is a Utility database server selected. (Select index 0 if not)
            CheckForServerListSelection();

            //////////////////////////
            //  Backup Plans View   //
            //////////////////////////

            RefreshBackupPlansView();

            //////////////////////////
            //    Option Editor     //
            //////////////////////////

            ResetOptionEditor();

            //////////////////////////
            //    Settings Group    //
            //////////////////////////

            //Tell the UI to process the changes
            Application.DoEvents();
        }

        private void RefreshBackupPlansView()
        {
            //Set vars
            DataTable vwGetBackupPlans = new DataTable("vwGetBackupPlans");
            int SelectedIndex = this.lstServerNames.SelectedIndex;
            LoadTabData.CurrentUtilityServer = this.lstServerNames.Items[SelectedIndex].ToString();

            //Load datatable
            vwGetBackupPlans = LoadTabData.LoadBackupPlans(LoadTabData.CurrentUtilityServer);

            //Load the data grid view
            this.dgvBackupPlans.DataSource = vwGetBackupPlans;

            //Resize the columns
            this.dgvBackupPlans.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCells);
        }

        private void refreshCurrentTabF5ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            RefreshCurrentTab();
        }

        private void tabPageBackups_Enter(object sender, EventArgs e)
        {
            ResizeCurrentTab();
            RefreshCurrentTab();
        }

        private void ResizeCurrentTab()
        {
            switch (this.tabControl.SelectedTab.Text)
            {
                case "Central Overview":
                    break;
                case "Backups":
                    ResizeBackupTab();
                    break;
                case "Disk Clean-up":
                    break;
                case "Index Maintenance":
                    break;
                case "DDL Auditing":
                    break;
                case "Logging":
                    break;
                case "Configuration":
                    break;
            }
        }

        private void RefreshCurrentTab()
        {
            switch (this.tabControl.SelectedTab.Text)
            {
                case "Central Overview":
                    break;
                case "Backups":
                    ResizeBackupTab();
                    RefreshBackupsTab();
                    break;
                case "Disk Clean-up":
                    break;
                case "Index Maintenance":
                    break;
                case "DDL Auditing":
                    break;
                case "Logging":
                    break;
                case "Configuration":
                    break;
            }
        }

        private void CheckForServerListSelection()
        {
            int index = lstServerNames.SelectedIndex;

            if (index == -1)
            {
                lstServerNames.SetSelected(0, true);
            }
        }

        private void frmMain_Resize(object sender, EventArgs e)
        {
            ////////////////////////////
            //Resize Server List Group//
            ////////////////////////////

            //Set fixed widths
            gbServers.Width = 360;
            lstServerNames.Width = 342;
            //snap server group to right edge of auto hide box
            gbServers.Left = this.autoHideServerList.Panel2.Width - lstServerNames.Width - 40;
            //Resize group box
            gbServers.Height = this.Height - 110;
            //Move buttons
            btnAddServers.Top = gbServers.Height - btnAddServers.Height - 10;
            btnRemoveServer.Top = gbServers.Height - btnRemoveServer.Height - 10;
            //Resize server list
            lstServerNames.Height = gbServers.Height - btnAddServers.Height - 40;

            /*
            //Set fixed widths
            gbServers.Width = 360;
            lstServerNames.Width = 342;
            //snap server group to right edge of form
            gbServers.Left = this.Width - lstServerNames.Width - 40;
            //Resize group box
            gbServers.Height = this.Height - 110;
            //Move buttons
            btnAddServers.Top = gbServers.Height - btnAddServers.Height - 10;
            btnRemoveServer.Top = gbServers.Height - btnRemoveServer.Height - 10;
            //Resize server list
            lstServerNames.Height = gbServers.Height - btnAddServers.Height - 40;
            */

            Application.DoEvents();

            ////////////////////////////
            //   Resize Tab Control   //
            ////////////////////////////

            //Resize height
            tabControl.Height = this.Height - 110;
            //Resize the width with a minimum limit
            tabControl.Width = gbServers.Left - 20;

            ////////////////////////////
            //      Resize Tabs       //
            ////////////////////////////

            ResizeCurrentTab();
        }

        private void ResizeBackupTab()
        {
            ////////////////////////////////
            //  Resize Backup Plans View  //
            ////////////////////////////////

            //Backup plans groupbox
            gbBackupPlans.Height = (tabPageBackups.Height / 3) - 20;
            gbBackupPlans.Width = tabPageBackups.Width - 20;

            //Data grid view
            dgvBackupPlans.Height = gbBackupPlans.Height - 30;
            dgvBackupPlans.Width = gbBackupPlans.Width - 20;

            ////////////////////////////
            //  Resize Option Editor  //
            ////////////////////////////

            //Option Editor group box
            gbOptionEditor.Width = tabPageBackups.Width - 20;
            gbOptionEditor.Height = (tabPageBackups.Height / 3 * 2) - 20;
            gbOptionEditor.Top = gbBackupPlans.Height + 10;

            //Configurations group
            gbConfigurations.Top = 30;
            gbConfigurations.Width = (gbOptionEditor.Width / 10);
            gbConfigurations.Height = gbOptionEditor.Height - gbConfigurations.Top - 10;
            dgvConfigs.Top = 20;
            dgvConfigs.Width = gbConfigurations.Width - 10;
            dgvConfigs.Height = gbConfigurations.Height - 20;

            //Arrow 1
            pnlArrow1.Left = gbConfigurations.Right + 5;
            pnlArrow1.Top = gbConfigurations.Top + (gbConfigurations.Height / 2) - (pnlArrow1.Height / 2);

            //Options group
            gbOptions.Left = pnlArrow1.Right + 5;
            gbOptions.Top = 30;
            gbOptions.Width = (gbOptionEditor.Width / 20);
            gbOptions.Height = gbOptionEditor.Height - gbOptions.Top - 10;
            dgvOptions.Top = 20;
            dgvOptions.Width = gbOptions.Width - 10;
            dgvOptions.Height = gbOptions.Height - 20;

            //Arrow 2
            pnlArrow2.Left = gbOptions.Right + 5;
            pnlArrow2.Top = gbOptions.Top + (gbOptions.Height / 2) - (pnlArrow2.Height / 2);

            //Database group
            gbDatabases.Left = pnlArrow2.Right + 5;
            gbDatabases.Top = 30;
            gbDatabases.Width = (gbOptionEditor.Width / 5);
            gbDatabases.Height = gbOptionEditor.Height - gbDatabases.Top - 10;
            dgvDatabases.Top = 20;
            dgvDatabases.Width = gbDatabases.Width - 10;
            dgvDatabases.Height = gbDatabases.Height - 20;

            //Arrow 3
            pnlArrow3.Left = gbDatabases.Right + 5;
            pnlArrow3.Top = gbDatabases.Top + (gbDatabases.Height / 2) - (pnlArrow3.Height / 2);

            ////////////////////////////
            //  Resize Settings Group //
            ////////////////////////////

            //Settings group
            gbSettings.Left = pnlArrow3.Right + 5;
            gbSettings.Top = 30;
            gbSettings.Width = gbOptionEditor.Width - gbSettings.Left - 10;
            gbSettings.Height = gbOptionEditor.Height - gbSettings.Top - 40;

            //Buttons Left
            btnNewOption.Left = gbSettings.Left;
            btnNewOption.Top = gbSettings.Bottom + 5;
            btnDropOption.Left = btnNewOption.Right + 5;
            btnDropOption.Top = gbSettings.Bottom + 5;

            //Buttons Right
            btnApplyBakOpt.Left = gbSettings.Right - btnApplyBakOpt.Width;
            btnApplyBakOpt.Top = gbSettings.Bottom + 5;
            btnResetBakOpt.Left = btnApplyBakOpt.Left - btnResetBakOpt.Width - 10;
            btnResetBakOpt.Top = gbSettings.Bottom + 5;
        }

        private void lstServerNames_SelectedIndexChanged(object sender, EventArgs e)
        {
            //Check to see if the lstServerNames is loaded and has a selected item
            if (lstServerNames.SelectedItem != null)
            {
                LoadTabData.CurrentUtilityServer = this.lstServerNames.SelectedItem.ToString();
            }
        }

        /// <summary>
        /// Manipulate the Option Editor
        /// </summary>

        private void btnReset_Click(object sender, EventArgs e)
        {
            ResetOptionEditor();
        }

        private void ResetOptionEditor()
        {
            UpdateBackupConfigsGrid("null");
            UpdateBackupOptionsGrid("null");
            UpdateBackupDatabaseGrid("null");
        }

        private void UpdateBackupConfigsGrid(string OptionID)
        {
            DataTable ConfigNames = new DataTable("ConfigNames");
            DataTable ConfigsToSelect = new DataTable("ConfigsToSelect");

            //Build SQL Command
            string SQLCommand = "SELECT [ConfigName] FROM [Configuration].[Configs] ORDER BY [ConfigName];";

            ConfigNames = SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentUtilityServer, LoadTabData.UtilityDatabaseName, SQLCommand, true);
            this.dgvConfigs.DataSource = ConfigNames;

            //Resize and reset selection
            DataGridViewColumn column = dgvConfigs.Columns[0];
            column.MinimumWidth = dgvConfigs.Width - 4;
            this.dgvConfigs.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCellsExceptHeader);
            this.dgvConfigs.ClearSelection();

            //Select the appropriate Configs if necessary
            if (OptionID.ToLower() != "null")
            {
                //Load filtered list
                SQLCommand = "SELECT DISTINCT [ConfigName] FROM [Backup].[vwGetBackupPlan] WHERE [OptionID] = " + OptionID + " AND [ConfigName] <> \'None\'";
                ConfigsToSelect = SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentUtilityServer, LoadTabData.UtilityDatabaseName, SQLCommand, true);

                //Loop through results to select each
                for (int index = 0; index < dgvConfigs.RowCount; index++)
                {
                    foreach(DataRow row in ConfigsToSelect.Rows)
                    {
                        foreach(DataColumn DataTableColumn in ConfigsToSelect.Columns)
                        {
                            if (dgvConfigs.Rows[index].Cells[0].Value.ToString() == row[DataTableColumn].ToString())
                            {
                                dgvConfigs.Rows[index].Selected = true;
                            }
                        }
                    }
                }
            }
        }

        private void UpdateBackupOptionsGrid(string ConfigName)
        {
            DataTable OptionIDs = new DataTable("OptionIDs");
            DataTable OptionToSelect = new DataTable("ConfigsToSelect");

            //Build SQL Command
            string SQLCommand = "SELECT opts.[OptionID] FROM [Backup].[Options] opts LEFT JOIN [Backup].[Configs] bakC ON bakC.OptionID = opts.OptionID " +
                "LEFT JOIN [Configuration].[Configs] CC ON CC.ConfigID = bakC.ConfigID";
            if (ConfigName.ToLower() != "null")
            {
                SQLCommand = SQLCommand + " WHERE CC.[ConfigName] = \'" + ConfigName + "\'";
            }
            SQLCommand = SQLCommand + " ORDER BY opts.[OptionID];";

            OptionIDs = SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentUtilityServer, LoadTabData.UtilityDatabaseName, SQLCommand, true);
            this.dgvOptions.DataSource = OptionIDs;

            //Resize and reset selection
            DataGridViewColumn column = dgvOptions.Columns[0];
            column.MinimumWidth = dgvOptions.Width - 4;
            this.dgvOptions.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCellsExceptHeader);
            this.dgvOptions.ClearSelection();
        }

        private void UpdateBackupDatabaseGrid(string OptionID)
        {
            DataTable DatabaseNames = new DataTable("DatabaseNames");
            DataTable DatabasesToSelect = new DataTable("DatabasesToSelect");

            //Build SQL Command
            string SQLCommand = "SELECT [DatabaseName] FROM [Configuration].[RegisteredDatabases] ORDER BY [DatabaseName];";

            DatabaseNames = SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentUtilityServer, LoadTabData.UtilityDatabaseName, SQLCommand, true);
            this.dgvDatabases.DataSource = DatabaseNames;

            //Resize and reset selection
            DataGridViewColumn column = dgvDatabases.Columns[0];
            column.MinimumWidth = dgvDatabases.Width - 4;
            this.dgvDatabases.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCellsExceptHeader);
            this.dgvDatabases.ClearSelection();

            //Select the appropriate Configs if necessary
            if (OptionID.ToLower() != "null")
            {
                //Load filtered list
                SQLCommand = "SELECT DISTINCT [DatabaseName] FROM [Backup].[vwGetBackupPlan] WHERE [OptionID] = " + OptionID + " AND [DatabaseName] <> \'None\'";
                DatabasesToSelect = SQLQueryHandler.ExecuteSQLCommand(LoadTabData.CurrentUtilityServer, LoadTabData.UtilityDatabaseName, SQLCommand, true);

                //Loop through results to select each
                for (int index = 0; index < dgvDatabases.RowCount; index++)
                {
                    foreach (DataRow row in DatabasesToSelect.Rows)
                    {
                        foreach (DataColumn DataTableColumn in DatabasesToSelect.Columns)
                        {
                            if (dgvDatabases.Rows[index].Cells[0].Value.ToString() == row[DataTableColumn].ToString())
                            {
                                dgvDatabases[0, index].Selected = true;
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Backup Configs data grid view click events
        /// </summary>

        private void dgvConfigs_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupOptionsGrid(dgvConfigs.SelectedCells[0].FormattedValue.ToString());
            dgvDatabases.ClearSelection();
        }

        private void dgvConfigs_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupOptionsGrid(dgvConfigs.SelectedCells[0].FormattedValue.ToString());
            dgvDatabases.ClearSelection();
        }

        private void dgvConfigs_CellContentDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupOptionsGrid(dgvConfigs.SelectedCells[0].FormattedValue.ToString());
            dgvDatabases.ClearSelection();
        }

        private void dgvConfigs_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupOptionsGrid(dgvConfigs.SelectedCells[0].FormattedValue.ToString());
            dgvDatabases.ClearSelection();
        }

        /// <summary>
        /// Backup Options data grid view click events
        /// </summary>

        private void dgvOptions_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupConfigsGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
            UpdateBackupDatabaseGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
        }

        private void dgvOptions_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupConfigsGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
            UpdateBackupDatabaseGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
        }

        private void dgvOptions_CellContentDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupConfigsGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
            UpdateBackupDatabaseGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
        }

        private void dgvOptions_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            UpdateBackupConfigsGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
            UpdateBackupDatabaseGrid(dgvOptions.SelectedCells[0].FormattedValue.ToString());
        }

        private void dgvOptions_Click(object sender, EventArgs e)
        {
            bool IsSelected = false;
            foreach (DataGridViewCell cell in dgvOptions.SelectedCells)
            {
                IsSelected = true;
            }

            if (!IsSelected)
            {
                UpdateBackupOptionsGrid("null");
                dgvDatabases.ClearSelection();
                dgvConfigs.ClearSelection();
            }
        }

        private void btnApplyBakOpt_Click(object sender, EventArgs e)
        {

            //Refresh the backup plans
            RefreshBackupPlansView();
        }

        private void chbMAXTRANSSIZE_CheckedChanged(object sender, EventArgs e)
        {
            if (chbMAXTRANSSIZE.Checked)
            {
                nudMaxTransferSize.Enabled = true;
            }
            else
            {
                nudMaxTransferSize.Enabled = false;
            }
        }

        private void chbBufferCount_CheckedChanged(object sender, EventArgs e)
        {
            if (chbBufferCount.Checked)
            {
                nudBufferCount.Enabled = true;
            }
            else
            {
                nudBufferCount.Enabled = false;
            }
        }

        private void chbFileCount_CheckedChanged(object sender, EventArgs e)
        {
            if (chbFileCount.Checked)
            {
                nudFileCount.Enabled = true;
            }
            else
            {
                nudFileCount.Enabled = false;
            }
        }

        private void autoHideServerList_Panel2_MouseEnter(object sender, EventArgs e)
        {
            autoHideServerList.SplitterDistance = 50;
        }

        private void autoHideServerList_Panel1_MouseEnter(object sender, EventArgs e)
        {
            autoHideServerList.SplitterDistance = 315;
        }

    }
}
