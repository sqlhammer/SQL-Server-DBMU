namespace Database_Maintenance_Console
{
    partial class frmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle6 = new System.Windows.Forms.DataGridViewCellStyle();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmMain));
            this.tabControl = new System.Windows.Forms.TabControl();
            this.tabPageCentral = new System.Windows.Forms.TabPage();
            this.tabPageBackups = new System.Windows.Forms.TabPage();
            this.gbBackupPlans = new System.Windows.Forms.GroupBox();
            this.dgvBackupPlans = new System.Windows.Forms.DataGridView();
            this.gbOptionEditor = new System.Windows.Forms.GroupBox();
            this.btnDropOption = new System.Windows.Forms.Button();
            this.btnNewOption = new System.Windows.Forms.Button();
            this.btnApplyBakOpt = new System.Windows.Forms.Button();
            this.btnResetBakOpt = new System.Windows.Forms.Button();
            this.gbConfigurations = new System.Windows.Forms.GroupBox();
            this.dgvConfigs = new System.Windows.Forms.DataGridView();
            this.gbSettings = new System.Windows.Forms.GroupBox();
            this.scBackupSettings = new System.Windows.Forms.SplitContainer();
            this.nudMaxTransferSize = new System.Windows.Forms.NumericUpDown();
            this.nudBufferCount = new System.Windows.Forms.NumericUpDown();
            this.nudFileCount = new System.Windows.Forms.NumericUpDown();
            this.txtBackupDirectory = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.chbMAXTRANSSIZE = new System.Windows.Forms.CheckBox();
            this.chbBufferCount = new System.Windows.Forms.CheckBox();
            this.chbFileCount = new System.Windows.Forms.CheckBox();
            this.chbCompress = new System.Windows.Forms.CheckBox();
            this.chbVerify = new System.Windows.Forms.CheckBox();
            this.cbBackupType = new System.Windows.Forms.ComboBox();
            this.gbBackupFrequency = new System.Windows.Forms.GroupBox();
            this.lblBackupMonths2 = new System.Windows.Forms.Label();
            this.nudBackupMonths2 = new System.Windows.Forms.NumericUpDown();
            this.lblBackupofevery2 = new System.Windows.Forms.Label();
            this.comboBox1 = new System.Windows.Forms.ComboBox();
            this.cbBackupMonth = new System.Windows.Forms.ComboBox();
            this.lblBackupMonths = new System.Windows.Forms.Label();
            this.nudBackupMonths = new System.Windows.Forms.NumericUpDown();
            this.lblBackupofevery = new System.Windows.Forms.Label();
            this.rbBackupThe = new System.Windows.Forms.RadioButton();
            this.rbBackupDay = new System.Windows.Forms.RadioButton();
            this.chlstBackupDaysofWeek = new System.Windows.Forms.CheckedListBox();
            this.lblBackupWeeksOn = new System.Windows.Forms.Label();
            this.lblBackupDays = new System.Windows.Forms.Label();
            this.numericUpDown2 = new System.Windows.Forms.NumericUpDown();
            this.lblBackupRecurs = new System.Windows.Forms.Label();
            this.cbBackupInterval = new System.Windows.Forms.ComboBox();
            this.numericUpDown1 = new System.Windows.Forms.NumericUpDown();
            this.lblBackupInterval = new System.Windows.Forms.Label();
            this.dtpBackupStartTime = new System.Windows.Forms.DateTimePicker();
            this.lblBackupStartTime = new System.Windows.Forms.Label();
            this.cbBackupOccurs = new System.Windows.Forms.ComboBox();
            this.lblBackupOccurs = new System.Windows.Forms.Label();
            this.pnlArrow3 = new System.Windows.Forms.Panel();
            this.pnlArrow2 = new System.Windows.Forms.Panel();
            this.pnlArrow1 = new System.Windows.Forms.Panel();
            this.gbDatabases = new System.Windows.Forms.GroupBox();
            this.dgvDatabases = new System.Windows.Forms.DataGridView();
            this.gbOptions = new System.Windows.Forms.GroupBox();
            this.dgvOptions = new System.Windows.Forms.DataGridView();
            this.tabPageDiskCleanup = new System.Windows.Forms.TabPage();
            this.tabPageIndexMaint = new System.Windows.Forms.TabPage();
            this.tabPageAudit = new System.Windows.Forms.TabPage();
            this.tabPageLogging = new System.Windows.Forms.TabPage();
            this.tabPageConfiguration = new System.Windows.Forms.TabPage();
            this.lstServerNames = new System.Windows.Forms.ListBox();
            this.gbServers = new System.Windows.Forms.GroupBox();
            this.btnRemoveServer = new System.Windows.Forms.Button();
            this.btnAddServers = new System.Windows.Forms.Button();
            this.mnuMain = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.connectionManagerToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.refreshF5ToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.refreshCurrentTabF5ToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.refreshServerListToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.refreshAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.statusStrip = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel = new System.Windows.Forms.ToolStripStatusLabel();
            this.autoHideServerList = new System.Windows.Forms.SplitContainer();
            this.tabControl.SuspendLayout();
            this.tabPageBackups.SuspendLayout();
            this.gbBackupPlans.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvBackupPlans)).BeginInit();
            this.gbOptionEditor.SuspendLayout();
            this.gbConfigurations.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvConfigs)).BeginInit();
            this.gbSettings.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.scBackupSettings)).BeginInit();
            this.scBackupSettings.Panel1.SuspendLayout();
            this.scBackupSettings.Panel2.SuspendLayout();
            this.scBackupSettings.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxTransferSize)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudBufferCount)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudFileCount)).BeginInit();
            this.gbBackupFrequency.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.nudBackupMonths2)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudBackupMonths)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).BeginInit();
            this.gbDatabases.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvDatabases)).BeginInit();
            this.gbOptions.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvOptions)).BeginInit();
            this.gbServers.SuspendLayout();
            this.mnuMain.SuspendLayout();
            this.statusStrip.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.autoHideServerList)).BeginInit();
            this.autoHideServerList.Panel2.SuspendLayout();
            this.autoHideServerList.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControl
            // 
            this.tabControl.Controls.Add(this.tabPageCentral);
            this.tabControl.Controls.Add(this.tabPageBackups);
            this.tabControl.Controls.Add(this.tabPageDiskCleanup);
            this.tabControl.Controls.Add(this.tabPageIndexMaint);
            this.tabControl.Controls.Add(this.tabPageAudit);
            this.tabControl.Controls.Add(this.tabPageLogging);
            this.tabControl.Controls.Add(this.tabPageConfiguration);
            this.tabControl.Font = new System.Drawing.Font("Arial Rounded MT Bold", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tabControl.Location = new System.Drawing.Point(11, 43);
            this.tabControl.Name = "tabControl";
            this.tabControl.SelectedIndex = 0;
            this.tabControl.Size = new System.Drawing.Size(1002, 714);
            this.tabControl.TabIndex = 0;
            // 
            // tabPageCentral
            // 
            this.tabPageCentral.Font = new System.Drawing.Font("MS Outlook", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(2)));
            this.tabPageCentral.Location = new System.Drawing.Point(4, 26);
            this.tabPageCentral.Name = "tabPageCentral";
            this.tabPageCentral.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageCentral.Size = new System.Drawing.Size(994, 684);
            this.tabPageCentral.TabIndex = 0;
            this.tabPageCentral.Text = "Central Overview";
            this.tabPageCentral.UseVisualStyleBackColor = true;
            // 
            // tabPageBackups
            // 
            this.tabPageBackups.Controls.Add(this.gbBackupPlans);
            this.tabPageBackups.Controls.Add(this.gbOptionEditor);
            this.tabPageBackups.Font = new System.Drawing.Font("Arial", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tabPageBackups.Location = new System.Drawing.Point(4, 26);
            this.tabPageBackups.Name = "tabPageBackups";
            this.tabPageBackups.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageBackups.Size = new System.Drawing.Size(994, 684);
            this.tabPageBackups.TabIndex = 1;
            this.tabPageBackups.Text = "Backups";
            this.tabPageBackups.UseVisualStyleBackColor = true;
            this.tabPageBackups.Enter += new System.EventHandler(this.tabPageBackups_Enter);
            // 
            // gbBackupPlans
            // 
            this.gbBackupPlans.Controls.Add(this.dgvBackupPlans);
            this.gbBackupPlans.Location = new System.Drawing.Point(6, 6);
            this.gbBackupPlans.Name = "gbBackupPlans";
            this.gbBackupPlans.Size = new System.Drawing.Size(979, 228);
            this.gbBackupPlans.TabIndex = 2;
            this.gbBackupPlans.TabStop = false;
            this.gbBackupPlans.Text = "Backup Plans";
            // 
            // dgvBackupPlans
            // 
            this.dgvBackupPlans.AllowUserToAddRows = false;
            this.dgvBackupPlans.AllowUserToDeleteRows = false;
            this.dgvBackupPlans.AllowUserToOrderColumns = true;
            dataGridViewCellStyle6.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(224)))), ((int)(((byte)(224)))), ((int)(((byte)(224)))));
            this.dgvBackupPlans.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle6;
            this.dgvBackupPlans.BackgroundColor = System.Drawing.Color.White;
            this.dgvBackupPlans.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvBackupPlans.Location = new System.Drawing.Point(6, 24);
            this.dgvBackupPlans.Name = "dgvBackupPlans";
            this.dgvBackupPlans.ReadOnly = true;
            this.dgvBackupPlans.Size = new System.Drawing.Size(967, 198);
            this.dgvBackupPlans.TabIndex = 0;
            // 
            // gbOptionEditor
            // 
            this.gbOptionEditor.Controls.Add(this.btnDropOption);
            this.gbOptionEditor.Controls.Add(this.btnNewOption);
            this.gbOptionEditor.Controls.Add(this.btnApplyBakOpt);
            this.gbOptionEditor.Controls.Add(this.btnResetBakOpt);
            this.gbOptionEditor.Controls.Add(this.gbConfigurations);
            this.gbOptionEditor.Controls.Add(this.gbSettings);
            this.gbOptionEditor.Controls.Add(this.pnlArrow3);
            this.gbOptionEditor.Controls.Add(this.pnlArrow2);
            this.gbOptionEditor.Controls.Add(this.pnlArrow1);
            this.gbOptionEditor.Controls.Add(this.gbDatabases);
            this.gbOptionEditor.Controls.Add(this.gbOptions);
            this.gbOptionEditor.Location = new System.Drawing.Point(7, 240);
            this.gbOptionEditor.Name = "gbOptionEditor";
            this.gbOptionEditor.Size = new System.Drawing.Size(979, 438);
            this.gbOptionEditor.TabIndex = 1;
            this.gbOptionEditor.TabStop = false;
            this.gbOptionEditor.Text = "Option Editor";
            // 
            // btnDropOption
            // 
            this.btnDropOption.Location = new System.Drawing.Point(703, 404);
            this.btnDropOption.Name = "btnDropOption";
            this.btnDropOption.Size = new System.Drawing.Size(75, 25);
            this.btnDropOption.TabIndex = 16;
            this.btnDropOption.Text = "Drop";
            this.btnDropOption.UseVisualStyleBackColor = true;
            // 
            // btnNewOption
            // 
            this.btnNewOption.Location = new System.Drawing.Point(622, 403);
            this.btnNewOption.Name = "btnNewOption";
            this.btnNewOption.Size = new System.Drawing.Size(75, 25);
            this.btnNewOption.TabIndex = 15;
            this.btnNewOption.Text = "New";
            this.btnNewOption.UseVisualStyleBackColor = true;
            // 
            // btnApplyBakOpt
            // 
            this.btnApplyBakOpt.Location = new System.Drawing.Point(897, 404);
            this.btnApplyBakOpt.Name = "btnApplyBakOpt";
            this.btnApplyBakOpt.Size = new System.Drawing.Size(75, 25);
            this.btnApplyBakOpt.TabIndex = 14;
            this.btnApplyBakOpt.Text = "Apply";
            this.btnApplyBakOpt.UseVisualStyleBackColor = true;
            this.btnApplyBakOpt.Click += new System.EventHandler(this.btnApplyBakOpt_Click);
            // 
            // btnResetBakOpt
            // 
            this.btnResetBakOpt.Location = new System.Drawing.Point(816, 404);
            this.btnResetBakOpt.Name = "btnResetBakOpt";
            this.btnResetBakOpt.Size = new System.Drawing.Size(75, 25);
            this.btnResetBakOpt.TabIndex = 13;
            this.btnResetBakOpt.Text = "Reset";
            this.btnResetBakOpt.UseVisualStyleBackColor = true;
            this.btnResetBakOpt.Click += new System.EventHandler(this.btnReset_Click);
            // 
            // gbConfigurations
            // 
            this.gbConfigurations.Controls.Add(this.dgvConfigs);
            this.gbConfigurations.Location = new System.Drawing.Point(6, 34);
            this.gbConfigurations.Name = "gbConfigurations";
            this.gbConfigurations.Size = new System.Drawing.Size(131, 398);
            this.gbConfigurations.TabIndex = 12;
            this.gbConfigurations.TabStop = false;
            this.gbConfigurations.Text = "Configs";
            // 
            // dgvConfigs
            // 
            this.dgvConfigs.AllowUserToAddRows = false;
            this.dgvConfigs.AllowUserToDeleteRows = false;
            this.dgvConfigs.AllowUserToOrderColumns = true;
            this.dgvConfigs.BackgroundColor = System.Drawing.Color.White;
            this.dgvConfigs.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvConfigs.ColumnHeadersVisible = false;
            this.dgvConfigs.Location = new System.Drawing.Point(6, 29);
            this.dgvConfigs.MultiSelect = false;
            this.dgvConfigs.Name = "dgvConfigs";
            this.dgvConfigs.ReadOnly = true;
            this.dgvConfigs.RowHeadersVisible = false;
            this.dgvConfigs.Size = new System.Drawing.Size(119, 361);
            this.dgvConfigs.TabIndex = 3;
            this.dgvConfigs.CellClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvConfigs_CellClick);
            this.dgvConfigs.CellContentClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvConfigs_CellContentClick);
            this.dgvConfigs.CellContentDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvConfigs_CellContentDoubleClick);
            this.dgvConfigs.CellDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvConfigs_CellDoubleClick);
            // 
            // gbSettings
            // 
            this.gbSettings.Controls.Add(this.scBackupSettings);
            this.gbSettings.Location = new System.Drawing.Point(622, 34);
            this.gbSettings.Name = "gbSettings";
            this.gbSettings.Size = new System.Drawing.Size(350, 364);
            this.gbSettings.TabIndex = 9;
            this.gbSettings.TabStop = false;
            this.gbSettings.Text = "Settings";
            // 
            // scBackupSettings
            // 
            this.scBackupSettings.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.scBackupSettings.Dock = System.Windows.Forms.DockStyle.Fill;
            this.scBackupSettings.Font = new System.Drawing.Font("Arial", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.scBackupSettings.Location = new System.Drawing.Point(3, 17);
            this.scBackupSettings.Name = "scBackupSettings";
            // 
            // scBackupSettings.Panel1
            // 
            this.scBackupSettings.Panel1.Controls.Add(this.nudMaxTransferSize);
            this.scBackupSettings.Panel1.Controls.Add(this.nudBufferCount);
            this.scBackupSettings.Panel1.Controls.Add(this.nudFileCount);
            this.scBackupSettings.Panel1.Controls.Add(this.txtBackupDirectory);
            this.scBackupSettings.Panel1.Controls.Add(this.label1);
            this.scBackupSettings.Panel1.Controls.Add(this.chbMAXTRANSSIZE);
            this.scBackupSettings.Panel1.Controls.Add(this.chbBufferCount);
            this.scBackupSettings.Panel1.Controls.Add(this.chbFileCount);
            this.scBackupSettings.Panel1.Controls.Add(this.chbCompress);
            this.scBackupSettings.Panel1.Controls.Add(this.chbVerify);
            this.scBackupSettings.Panel1.Controls.Add(this.cbBackupType);
            this.scBackupSettings.Panel1.Font = new System.Drawing.Font("Arial", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            // 
            // scBackupSettings.Panel2
            // 
            this.scBackupSettings.Panel2.Controls.Add(this.gbBackupFrequency);
            this.scBackupSettings.Panel2.Controls.Add(this.cbBackupInterval);
            this.scBackupSettings.Panel2.Controls.Add(this.numericUpDown1);
            this.scBackupSettings.Panel2.Controls.Add(this.lblBackupInterval);
            this.scBackupSettings.Panel2.Controls.Add(this.dtpBackupStartTime);
            this.scBackupSettings.Panel2.Controls.Add(this.lblBackupStartTime);
            this.scBackupSettings.Panel2.Controls.Add(this.cbBackupOccurs);
            this.scBackupSettings.Panel2.Controls.Add(this.lblBackupOccurs);
            this.scBackupSettings.Size = new System.Drawing.Size(344, 344);
            this.scBackupSettings.SplitterDistance = 185;
            this.scBackupSettings.TabIndex = 0;
            // 
            // nudMaxTransferSize
            // 
            this.nudMaxTransferSize.Enabled = false;
            this.nudMaxTransferSize.Location = new System.Drawing.Point(105, 194);
            this.nudMaxTransferSize.Maximum = new decimal(new int[] {
            4194304,
            0,
            0,
            0});
            this.nudMaxTransferSize.Name = "nudMaxTransferSize";
            this.nudMaxTransferSize.Size = new System.Drawing.Size(72, 20);
            this.nudMaxTransferSize.TabIndex = 15;
            this.nudMaxTransferSize.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.nudMaxTransferSize.Value = new decimal(new int[] {
            1048576,
            0,
            0,
            0});
            // 
            // nudBufferCount
            // 
            this.nudBufferCount.Enabled = false;
            this.nudBufferCount.Location = new System.Drawing.Point(137, 157);
            this.nudBufferCount.Name = "nudBufferCount";
            this.nudBufferCount.Size = new System.Drawing.Size(40, 20);
            this.nudBufferCount.TabIndex = 14;
            this.nudBufferCount.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.nudBufferCount.Value = new decimal(new int[] {
            64,
            0,
            0,
            0});
            // 
            // nudFileCount
            // 
            this.nudFileCount.Enabled = false;
            this.nudFileCount.Location = new System.Drawing.Point(137, 123);
            this.nudFileCount.Name = "nudFileCount";
            this.nudFileCount.Size = new System.Drawing.Size(40, 20);
            this.nudFileCount.TabIndex = 13;
            this.nudFileCount.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.nudFileCount.Value = new decimal(new int[] {
            2,
            0,
            0,
            0});
            // 
            // txtBackupDirectory
            // 
            this.txtBackupDirectory.Location = new System.Drawing.Point(10, 249);
            this.txtBackupDirectory.Name = "txtBackupDirectory";
            this.txtBackupDirectory.Size = new System.Drawing.Size(167, 20);
            this.txtBackupDirectory.TabIndex = 12;
            this.txtBackupDirectory.WordWrap = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(7, 231);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(93, 14);
            this.label1.TabIndex = 11;
            this.label1.Text = "Backup Directory:";
            // 
            // chbMAXTRANSSIZE
            // 
            this.chbMAXTRANSSIZE.AutoSize = true;
            this.chbMAXTRANSSIZE.Location = new System.Drawing.Point(7, 188);
            this.chbMAXTRANSSIZE.Name = "chbMAXTRANSSIZE";
            this.chbMAXTRANSSIZE.Size = new System.Drawing.Size(92, 32);
            this.chbMAXTRANSSIZE.TabIndex = 10;
            this.chbMAXTRANSSIZE.Text = "Custom Max\r\nTransfer Size\r\n";
            this.chbMAXTRANSSIZE.UseVisualStyleBackColor = true;
            this.chbMAXTRANSSIZE.CheckedChanged += new System.EventHandler(this.chbMAXTRANSSIZE_CheckedChanged);
            // 
            // chbBufferCount
            // 
            this.chbBufferCount.AutoSize = true;
            this.chbBufferCount.Location = new System.Drawing.Point(7, 159);
            this.chbBufferCount.Name = "chbBufferCount";
            this.chbBufferCount.Size = new System.Drawing.Size(127, 18);
            this.chbBufferCount.TabIndex = 8;
            this.chbBufferCount.Text = "Custom Buffer Count";
            this.chbBufferCount.UseVisualStyleBackColor = true;
            this.chbBufferCount.CheckedChanged += new System.EventHandler(this.chbBufferCount_CheckedChanged);
            // 
            // chbFileCount
            // 
            this.chbFileCount.AutoSize = true;
            this.chbFileCount.Location = new System.Drawing.Point(7, 125);
            this.chbFileCount.Name = "chbFileCount";
            this.chbFileCount.Size = new System.Drawing.Size(112, 18);
            this.chbFileCount.TabIndex = 6;
            this.chbFileCount.Text = "Custom File Count";
            this.chbFileCount.UseVisualStyleBackColor = true;
            this.chbFileCount.CheckedChanged += new System.EventHandler(this.chbFileCount_CheckedChanged);
            // 
            // chbCompress
            // 
            this.chbCompress.AutoSize = true;
            this.chbCompress.Checked = true;
            this.chbCompress.CheckState = System.Windows.Forms.CheckState.Checked;
            this.chbCompress.Location = new System.Drawing.Point(7, 95);
            this.chbCompress.Name = "chbCompress";
            this.chbCompress.Size = new System.Drawing.Size(75, 18);
            this.chbCompress.TabIndex = 3;
            this.chbCompress.Text = "Compress";
            this.chbCompress.UseVisualStyleBackColor = true;
            // 
            // chbVerify
            // 
            this.chbVerify.AutoSize = true;
            this.chbVerify.Location = new System.Drawing.Point(7, 65);
            this.chbVerify.Name = "chbVerify";
            this.chbVerify.Size = new System.Drawing.Size(55, 18);
            this.chbVerify.TabIndex = 2;
            this.chbVerify.Text = "Verify";
            this.chbVerify.UseVisualStyleBackColor = true;
            // 
            // cbBackupType
            // 
            this.cbBackupType.FormattingEnabled = true;
            this.cbBackupType.Location = new System.Drawing.Point(3, 32);
            this.cbBackupType.Name = "cbBackupType";
            this.cbBackupType.Size = new System.Drawing.Size(174, 22);
            this.cbBackupType.TabIndex = 0;
            this.cbBackupType.Text = "<Backup Type>";
            // 
            // gbBackupFrequency
            // 
            this.gbBackupFrequency.Controls.Add(this.lblBackupMonths2);
            this.gbBackupFrequency.Controls.Add(this.nudBackupMonths2);
            this.gbBackupFrequency.Controls.Add(this.lblBackupofevery2);
            this.gbBackupFrequency.Controls.Add(this.comboBox1);
            this.gbBackupFrequency.Controls.Add(this.cbBackupMonth);
            this.gbBackupFrequency.Controls.Add(this.lblBackupMonths);
            this.gbBackupFrequency.Controls.Add(this.nudBackupMonths);
            this.gbBackupFrequency.Controls.Add(this.lblBackupofevery);
            this.gbBackupFrequency.Controls.Add(this.rbBackupThe);
            this.gbBackupFrequency.Controls.Add(this.rbBackupDay);
            this.gbBackupFrequency.Controls.Add(this.chlstBackupDaysofWeek);
            this.gbBackupFrequency.Controls.Add(this.lblBackupWeeksOn);
            this.gbBackupFrequency.Controls.Add(this.lblBackupDays);
            this.gbBackupFrequency.Controls.Add(this.numericUpDown2);
            this.gbBackupFrequency.Controls.Add(this.lblBackupRecurs);
            this.gbBackupFrequency.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.gbBackupFrequency.Location = new System.Drawing.Point(6, 37);
            this.gbBackupFrequency.Name = "gbBackupFrequency";
            this.gbBackupFrequency.Size = new System.Drawing.Size(138, 232);
            this.gbBackupFrequency.TabIndex = 7;
            this.gbBackupFrequency.TabStop = false;
            // 
            // lblBackupMonths2
            // 
            this.lblBackupMonths2.AutoSize = true;
            this.lblBackupMonths2.Location = new System.Drawing.Point(106, 168);
            this.lblBackupMonths2.Name = "lblBackupMonths2";
            this.lblBackupMonths2.Size = new System.Drawing.Size(50, 14);
            this.lblBackupMonths2.TabIndex = 14;
            this.lblBackupMonths2.Text = "month(s)";
            this.lblBackupMonths2.Visible = false;
            // 
            // nudBackupMonths2
            // 
            this.nudBackupMonths2.Location = new System.Drawing.Point(64, 167);
            this.nudBackupMonths2.Name = "nudBackupMonths2";
            this.nudBackupMonths2.Size = new System.Drawing.Size(35, 20);
            this.nudBackupMonths2.TabIndex = 13;
            this.nudBackupMonths2.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.nudBackupMonths2.Visible = false;
            // 
            // lblBackupofevery2
            // 
            this.lblBackupofevery2.AutoSize = true;
            this.lblBackupofevery2.Location = new System.Drawing.Point(10, 169);
            this.lblBackupofevery2.Name = "lblBackupofevery2";
            this.lblBackupofevery2.Size = new System.Drawing.Size(48, 14);
            this.lblBackupofevery2.TabIndex = 12;
            this.lblBackupofevery2.Text = "of every";
            this.lblBackupofevery2.Visible = false;
            // 
            // comboBox1
            // 
            this.comboBox1.FormattingEnabled = true;
            this.comboBox1.Items.AddRange(new object[] {
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "day",
            "week day",
            "weekend day"});
            this.comboBox1.Location = new System.Drawing.Point(11, 141);
            this.comboBox1.Name = "comboBox1";
            this.comboBox1.Size = new System.Drawing.Size(121, 22);
            this.comboBox1.TabIndex = 11;
            this.comboBox1.Text = "<blank>";
            this.comboBox1.Visible = false;
            // 
            // cbBackupMonth
            // 
            this.cbBackupMonth.FormattingEnabled = true;
            this.cbBackupMonth.Items.AddRange(new object[] {
            "first",
            "second",
            "third",
            "fourth",
            "last"});
            this.cbBackupMonth.Location = new System.Drawing.Point(11, 115);
            this.cbBackupMonth.Name = "cbBackupMonth";
            this.cbBackupMonth.Size = new System.Drawing.Size(121, 22);
            this.cbBackupMonth.TabIndex = 10;
            this.cbBackupMonth.Text = "<blank>";
            this.cbBackupMonth.Visible = false;
            // 
            // lblBackupMonths
            // 
            this.lblBackupMonths.AutoSize = true;
            this.lblBackupMonths.Location = new System.Drawing.Point(57, 65);
            this.lblBackupMonths.Name = "lblBackupMonths";
            this.lblBackupMonths.Size = new System.Drawing.Size(50, 14);
            this.lblBackupMonths.TabIndex = 9;
            this.lblBackupMonths.Text = "month(s)";
            this.lblBackupMonths.Visible = false;
            // 
            // nudBackupMonths
            // 
            this.nudBackupMonths.Location = new System.Drawing.Point(10, 65);
            this.nudBackupMonths.Name = "nudBackupMonths";
            this.nudBackupMonths.Size = new System.Drawing.Size(35, 20);
            this.nudBackupMonths.TabIndex = 8;
            this.nudBackupMonths.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.nudBackupMonths.Visible = false;
            // 
            // lblBackupofevery
            // 
            this.lblBackupofevery.AutoSize = true;
            this.lblBackupofevery.Location = new System.Drawing.Point(54, 40);
            this.lblBackupofevery.Name = "lblBackupofevery";
            this.lblBackupofevery.Size = new System.Drawing.Size(48, 14);
            this.lblBackupofevery.TabIndex = 7;
            this.lblBackupofevery.Text = "of every";
            this.lblBackupofevery.Visible = false;
            // 
            // rbBackupThe
            // 
            this.rbBackupThe.AutoSize = true;
            this.rbBackupThe.Location = new System.Drawing.Point(11, 91);
            this.rbBackupThe.Name = "rbBackupThe";
            this.rbBackupThe.Size = new System.Drawing.Size(43, 18);
            this.rbBackupThe.TabIndex = 6;
            this.rbBackupThe.TabStop = true;
            this.rbBackupThe.Text = "The";
            this.rbBackupThe.UseVisualStyleBackColor = true;
            this.rbBackupThe.Visible = false;
            // 
            // rbBackupDay
            // 
            this.rbBackupDay.AutoSize = true;
            this.rbBackupDay.Location = new System.Drawing.Point(10, 20);
            this.rbBackupDay.Name = "rbBackupDay";
            this.rbBackupDay.Size = new System.Drawing.Size(44, 18);
            this.rbBackupDay.TabIndex = 5;
            this.rbBackupDay.TabStop = true;
            this.rbBackupDay.Text = "Day";
            this.rbBackupDay.UseVisualStyleBackColor = true;
            this.rbBackupDay.Visible = false;
            // 
            // chlstBackupDaysofWeek
            // 
            this.chlstBackupDaysofWeek.FormattingEnabled = true;
            this.chlstBackupDaysofWeek.Items.AddRange(new object[] {
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday"});
            this.chlstBackupDaysofWeek.Location = new System.Drawing.Point(10, 65);
            this.chlstBackupDaysofWeek.Name = "chlstBackupDaysofWeek";
            this.chlstBackupDaysofWeek.Size = new System.Drawing.Size(120, 109);
            this.chlstBackupDaysofWeek.TabIndex = 4;
            this.chlstBackupDaysofWeek.Visible = false;
            // 
            // lblBackupWeeksOn
            // 
            this.lblBackupWeeksOn.AutoSize = true;
            this.lblBackupWeeksOn.Location = new System.Drawing.Point(54, 40);
            this.lblBackupWeeksOn.Name = "lblBackupWeeksOn";
            this.lblBackupWeeksOn.Size = new System.Drawing.Size(63, 14);
            this.lblBackupWeeksOn.TabIndex = 3;
            this.lblBackupWeeksOn.Text = "week(s) on";
            this.lblBackupWeeksOn.Visible = false;
            // 
            // lblBackupDays
            // 
            this.lblBackupDays.AutoSize = true;
            this.lblBackupDays.Location = new System.Drawing.Point(51, 40);
            this.lblBackupDays.Name = "lblBackupDays";
            this.lblBackupDays.Size = new System.Drawing.Size(40, 14);
            this.lblBackupDays.TabIndex = 2;
            this.lblBackupDays.Text = "Day(s)";
            this.lblBackupDays.Visible = false;
            // 
            // numericUpDown2
            // 
            this.numericUpDown2.Location = new System.Drawing.Point(10, 38);
            this.numericUpDown2.Maximum = new decimal(new int[] {
            30,
            0,
            0,
            0});
            this.numericUpDown2.Name = "numericUpDown2";
            this.numericUpDown2.Size = new System.Drawing.Size(35, 20);
            this.numericUpDown2.TabIndex = 1;
            this.numericUpDown2.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericUpDown2.Visible = false;
            // 
            // lblBackupRecurs
            // 
            this.lblBackupRecurs.AutoSize = true;
            this.lblBackupRecurs.Location = new System.Drawing.Point(7, 20);
            this.lblBackupRecurs.Name = "lblBackupRecurs";
            this.lblBackupRecurs.Size = new System.Drawing.Size(76, 14);
            this.lblBackupRecurs.TabIndex = 0;
            this.lblBackupRecurs.Text = "Recurs every:";
            this.lblBackupRecurs.Visible = false;
            // 
            // cbBackupInterval
            // 
            this.cbBackupInterval.FormattingEnabled = true;
            this.cbBackupInterval.Items.AddRange(new object[] {
            "hour(s)",
            "minute(s)"});
            this.cbBackupInterval.Location = new System.Drawing.Point(97, 281);
            this.cbBackupInterval.Name = "cbBackupInterval";
            this.cbBackupInterval.Size = new System.Drawing.Size(91, 22);
            this.cbBackupInterval.TabIndex = 6;
            this.cbBackupInterval.Text = "<Periodicity>";
            // 
            // numericUpDown1
            // 
            this.numericUpDown1.Location = new System.Drawing.Point(52, 282);
            this.numericUpDown1.Name = "numericUpDown1";
            this.numericUpDown1.Size = new System.Drawing.Size(39, 20);
            this.numericUpDown1.TabIndex = 5;
            this.numericUpDown1.Value = new decimal(new int[] {
            15,
            0,
            0,
            0});
            // 
            // lblBackupInterval
            // 
            this.lblBackupInterval.AutoSize = true;
            this.lblBackupInterval.Location = new System.Drawing.Point(6, 284);
            this.lblBackupInterval.Name = "lblBackupInterval";
            this.lblBackupInterval.Size = new System.Drawing.Size(45, 14);
            this.lblBackupInterval.TabIndex = 4;
            this.lblBackupInterval.Text = "Interval:";
            // 
            // dtpBackupStartTime
            // 
            this.dtpBackupStartTime.CustomFormat = "HH:mm:ss";
            this.dtpBackupStartTime.Format = System.Windows.Forms.DateTimePickerFormat.Custom;
            this.dtpBackupStartTime.Location = new System.Drawing.Point(68, 310);
            this.dtpBackupStartTime.Name = "dtpBackupStartTime";
            this.dtpBackupStartTime.ShowUpDown = true;
            this.dtpBackupStartTime.Size = new System.Drawing.Size(76, 20);
            this.dtpBackupStartTime.TabIndex = 3;
            this.dtpBackupStartTime.Value = new System.DateTime(2013, 2, 15, 0, 0, 0, 0);
            // 
            // lblBackupStartTime
            // 
            this.lblBackupStartTime.AutoSize = true;
            this.lblBackupStartTime.Location = new System.Drawing.Point(6, 315);
            this.lblBackupStartTime.Name = "lblBackupStartTime";
            this.lblBackupStartTime.Size = new System.Drawing.Size(58, 14);
            this.lblBackupStartTime.TabIndex = 2;
            this.lblBackupStartTime.Text = "Start Time:";
            // 
            // cbBackupOccurs
            // 
            this.cbBackupOccurs.FormattingEnabled = true;
            this.cbBackupOccurs.Items.AddRange(new object[] {
            "Daily",
            "Weekly",
            "Monthly"});
            this.cbBackupOccurs.Location = new System.Drawing.Point(52, 9);
            this.cbBackupOccurs.Name = "cbBackupOccurs";
            this.cbBackupOccurs.Size = new System.Drawing.Size(92, 22);
            this.cbBackupOccurs.TabIndex = 1;
            this.cbBackupOccurs.Text = "<Occurance>";
            // 
            // lblBackupOccurs
            // 
            this.lblBackupOccurs.AutoSize = true;
            this.lblBackupOccurs.Location = new System.Drawing.Point(3, 12);
            this.lblBackupOccurs.Name = "lblBackupOccurs";
            this.lblBackupOccurs.Size = new System.Drawing.Size(46, 14);
            this.lblBackupOccurs.TabIndex = 0;
            this.lblBackupOccurs.Text = "Occurs:";
            // 
            // pnlArrow3
            // 
            this.pnlArrow3.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("pnlArrow3.BackgroundImage")));
            this.pnlArrow3.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Stretch;
            this.pnlArrow3.Location = new System.Drawing.Point(576, 234);
            this.pnlArrow3.Name = "pnlArrow3";
            this.pnlArrow3.Size = new System.Drawing.Size(40, 30);
            this.pnlArrow3.TabIndex = 8;
            // 
            // pnlArrow2
            // 
            this.pnlArrow2.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("pnlArrow2.BackgroundImage")));
            this.pnlArrow2.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Stretch;
            this.pnlArrow2.Location = new System.Drawing.Point(308, 234);
            this.pnlArrow2.Name = "pnlArrow2";
            this.pnlArrow2.Size = new System.Drawing.Size(40, 30);
            this.pnlArrow2.TabIndex = 7;
            // 
            // pnlArrow1
            // 
            this.pnlArrow1.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("pnlArrow1.BackgroundImage")));
            this.pnlArrow1.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Stretch;
            this.pnlArrow1.Location = new System.Drawing.Point(143, 221);
            this.pnlArrow1.Name = "pnlArrow1";
            this.pnlArrow1.Size = new System.Drawing.Size(40, 54);
            this.pnlArrow1.TabIndex = 6;
            // 
            // gbDatabases
            // 
            this.gbDatabases.Controls.Add(this.dgvDatabases);
            this.gbDatabases.Location = new System.Drawing.Point(354, 34);
            this.gbDatabases.Name = "gbDatabases";
            this.gbDatabases.Size = new System.Drawing.Size(216, 398);
            this.gbDatabases.TabIndex = 10;
            this.gbDatabases.TabStop = false;
            this.gbDatabases.Text = "Databases";
            // 
            // dgvDatabases
            // 
            this.dgvDatabases.AllowUserToAddRows = false;
            this.dgvDatabases.AllowUserToDeleteRows = false;
            this.dgvDatabases.AllowUserToOrderColumns = true;
            this.dgvDatabases.BackgroundColor = System.Drawing.Color.White;
            this.dgvDatabases.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvDatabases.ColumnHeadersVisible = false;
            this.dgvDatabases.Location = new System.Drawing.Point(7, 29);
            this.dgvDatabases.Name = "dgvDatabases";
            this.dgvDatabases.ReadOnly = true;
            this.dgvDatabases.RowHeadersVisible = false;
            this.dgvDatabases.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.CellSelect;
            this.dgvDatabases.Size = new System.Drawing.Size(203, 361);
            this.dgvDatabases.TabIndex = 0;
            // 
            // gbOptions
            // 
            this.gbOptions.Controls.Add(this.dgvOptions);
            this.gbOptions.Location = new System.Drawing.Point(189, 34);
            this.gbOptions.Name = "gbOptions";
            this.gbOptions.Size = new System.Drawing.Size(113, 398);
            this.gbOptions.TabIndex = 11;
            this.gbOptions.TabStop = false;
            this.gbOptions.Text = "Options";
            // 
            // dgvOptions
            // 
            this.dgvOptions.AllowUserToAddRows = false;
            this.dgvOptions.AllowUserToDeleteRows = false;
            this.dgvOptions.AllowUserToOrderColumns = true;
            this.dgvOptions.BackgroundColor = System.Drawing.Color.White;
            this.dgvOptions.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvOptions.ColumnHeadersVisible = false;
            this.dgvOptions.Location = new System.Drawing.Point(7, 29);
            this.dgvOptions.Name = "dgvOptions";
            this.dgvOptions.ReadOnly = true;
            this.dgvOptions.RowHeadersVisible = false;
            this.dgvOptions.Size = new System.Drawing.Size(100, 361);
            this.dgvOptions.TabIndex = 0;
            this.dgvOptions.CellClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvOptions_CellClick);
            this.dgvOptions.CellContentClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvOptions_CellContentClick);
            this.dgvOptions.CellContentDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvOptions_CellContentDoubleClick);
            this.dgvOptions.CellDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvOptions_CellDoubleClick);
            this.dgvOptions.Click += new System.EventHandler(this.dgvOptions_Click);
            // 
            // tabPageDiskCleanup
            // 
            this.tabPageDiskCleanup.Location = new System.Drawing.Point(4, 26);
            this.tabPageDiskCleanup.Name = "tabPageDiskCleanup";
            this.tabPageDiskCleanup.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageDiskCleanup.Size = new System.Drawing.Size(994, 684);
            this.tabPageDiskCleanup.TabIndex = 2;
            this.tabPageDiskCleanup.Text = "Disk Clean-up";
            this.tabPageDiskCleanup.UseVisualStyleBackColor = true;
            // 
            // tabPageIndexMaint
            // 
            this.tabPageIndexMaint.Location = new System.Drawing.Point(4, 26);
            this.tabPageIndexMaint.Name = "tabPageIndexMaint";
            this.tabPageIndexMaint.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageIndexMaint.Size = new System.Drawing.Size(994, 684);
            this.tabPageIndexMaint.TabIndex = 3;
            this.tabPageIndexMaint.Text = "Index Maintenance";
            this.tabPageIndexMaint.UseVisualStyleBackColor = true;
            // 
            // tabPageAudit
            // 
            this.tabPageAudit.Location = new System.Drawing.Point(4, 26);
            this.tabPageAudit.Name = "tabPageAudit";
            this.tabPageAudit.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageAudit.Size = new System.Drawing.Size(994, 684);
            this.tabPageAudit.TabIndex = 4;
            this.tabPageAudit.Text = "DDL Auditing";
            this.tabPageAudit.UseVisualStyleBackColor = true;
            // 
            // tabPageLogging
            // 
            this.tabPageLogging.Location = new System.Drawing.Point(4, 26);
            this.tabPageLogging.Name = "tabPageLogging";
            this.tabPageLogging.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageLogging.Size = new System.Drawing.Size(994, 684);
            this.tabPageLogging.TabIndex = 5;
            this.tabPageLogging.Text = "Logging";
            this.tabPageLogging.UseVisualStyleBackColor = true;
            // 
            // tabPageConfiguration
            // 
            this.tabPageConfiguration.Location = new System.Drawing.Point(4, 26);
            this.tabPageConfiguration.Name = "tabPageConfiguration";
            this.tabPageConfiguration.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageConfiguration.Size = new System.Drawing.Size(994, 684);
            this.tabPageConfiguration.TabIndex = 6;
            this.tabPageConfiguration.Text = "Configuration";
            this.tabPageConfiguration.UseVisualStyleBackColor = true;
            // 
            // lstServerNames
            // 
            this.lstServerNames.Font = new System.Drawing.Font("Arial Rounded MT Bold", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lstServerNames.FormattingEnabled = true;
            this.lstServerNames.HorizontalScrollbar = true;
            this.lstServerNames.ItemHeight = 14;
            this.lstServerNames.Location = new System.Drawing.Point(9, 26);
            this.lstServerNames.Name = "lstServerNames";
            this.lstServerNames.Size = new System.Drawing.Size(278, 648);
            this.lstServerNames.TabIndex = 1;
            this.lstServerNames.SelectedIndexChanged += new System.EventHandler(this.lstServerNames_SelectedIndexChanged);
            // 
            // gbServers
            // 
            this.gbServers.Controls.Add(this.btnRemoveServer);
            this.gbServers.Controls.Add(this.btnAddServers);
            this.gbServers.Controls.Add(this.lstServerNames);
            this.gbServers.Location = new System.Drawing.Point(3, 4);
            this.gbServers.Name = "gbServers";
            this.gbServers.Size = new System.Drawing.Size(294, 715);
            this.gbServers.TabIndex = 2;
            this.gbServers.TabStop = false;
            this.gbServers.Text = "Server List";
            // 
            // btnRemoveServer
            // 
            this.btnRemoveServer.Location = new System.Drawing.Point(161, 680);
            this.btnRemoveServer.Name = "btnRemoveServer";
            this.btnRemoveServer.Size = new System.Drawing.Size(125, 25);
            this.btnRemoveServer.TabIndex = 3;
            this.btnRemoveServer.Text = "Remove";
            this.btnRemoveServer.UseVisualStyleBackColor = true;
            this.btnRemoveServer.Click += new System.EventHandler(this.btnRemoveServer_Click);
            // 
            // btnAddServers
            // 
            this.btnAddServers.Location = new System.Drawing.Point(10, 680);
            this.btnAddServers.Name = "btnAddServers";
            this.btnAddServers.Size = new System.Drawing.Size(125, 25);
            this.btnAddServers.TabIndex = 2;
            this.btnAddServers.Text = "Add";
            this.btnAddServers.UseVisualStyleBackColor = true;
            this.btnAddServers.Click += new System.EventHandler(this.btnAddServers_Click);
            // 
            // mnuMain
            // 
            this.mnuMain.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem,
            this.refreshF5ToolStripMenuItem});
            this.mnuMain.Location = new System.Drawing.Point(0, 0);
            this.mnuMain.Name = "mnuMain";
            this.mnuMain.Size = new System.Drawing.Size(1384, 24);
            this.mnuMain.TabIndex = 3;
            this.mnuMain.Text = "mnuMain";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.connectionManagerToolStripMenuItem,
            this.exitToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem.Text = "&File";
            // 
            // connectionManagerToolStripMenuItem
            // 
            this.connectionManagerToolStripMenuItem.Name = "connectionManagerToolStripMenuItem";
            this.connectionManagerToolStripMenuItem.Size = new System.Drawing.Size(186, 22);
            this.connectionManagerToolStripMenuItem.Text = "&Connection Manager";
            this.connectionManagerToolStripMenuItem.Click += new System.EventHandler(this.connectionManagerToolStripMenuItem_Click);
            // 
            // exitToolStripMenuItem
            // 
            this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
            this.exitToolStripMenuItem.Size = new System.Drawing.Size(186, 22);
            this.exitToolStripMenuItem.Text = "E&xit";
            this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
            // 
            // refreshF5ToolStripMenuItem
            // 
            this.refreshF5ToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.refreshCurrentTabF5ToolStripMenuItem,
            this.refreshServerListToolStripMenuItem,
            this.refreshAllToolStripMenuItem});
            this.refreshF5ToolStripMenuItem.Name = "refreshF5ToolStripMenuItem";
            this.refreshF5ToolStripMenuItem.Size = new System.Drawing.Size(58, 20);
            this.refreshF5ToolStripMenuItem.Text = "&Refresh";
            // 
            // refreshCurrentTabF5ToolStripMenuItem
            // 
            this.refreshCurrentTabF5ToolStripMenuItem.Name = "refreshCurrentTabF5ToolStripMenuItem";
            this.refreshCurrentTabF5ToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F5;
            this.refreshCurrentTabF5ToolStripMenuItem.Size = new System.Drawing.Size(206, 22);
            this.refreshCurrentTabF5ToolStripMenuItem.Text = "Refresh - &Current Tab";
            this.refreshCurrentTabF5ToolStripMenuItem.Click += new System.EventHandler(this.refreshCurrentTabF5ToolStripMenuItem_Click);
            // 
            // refreshServerListToolStripMenuItem
            // 
            this.refreshServerListToolStripMenuItem.Name = "refreshServerListToolStripMenuItem";
            this.refreshServerListToolStripMenuItem.Size = new System.Drawing.Size(206, 22);
            this.refreshServerListToolStripMenuItem.Text = "Refresh - &Server List";
            this.refreshServerListToolStripMenuItem.Click += new System.EventHandler(this.refreshServerListToolStripMenuItem_Click);
            // 
            // refreshAllToolStripMenuItem
            // 
            this.refreshAllToolStripMenuItem.Name = "refreshAllToolStripMenuItem";
            this.refreshAllToolStripMenuItem.Size = new System.Drawing.Size(206, 22);
            this.refreshAllToolStripMenuItem.Text = "Refresh - &All";
            this.refreshAllToolStripMenuItem.Click += new System.EventHandler(this.refreshAllToolStripMenuItem_Click);
            // 
            // statusStrip
            // 
            this.statusStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel});
            this.statusStrip.Location = new System.Drawing.Point(0, 765);
            this.statusStrip.Name = "statusStrip";
            this.statusStrip.Size = new System.Drawing.Size(1384, 22);
            this.statusStrip.TabIndex = 4;
            this.statusStrip.Text = "statusStrip1";
            // 
            // toolStripStatusLabel
            // 
            this.toolStripStatusLabel.Name = "toolStripStatusLabel";
            this.toolStripStatusLabel.Size = new System.Drawing.Size(39, 17);
            this.toolStripStatusLabel.Text = "Ready";
            // 
            // autoHideServerList
            // 
            this.autoHideServerList.Location = new System.Drawing.Point(1019, 43);
            this.autoHideServerList.Name = "autoHideServerList";
            // 
            // autoHideServerList.Panel1
            // 
            this.autoHideServerList.Panel1.MouseEnter += new System.EventHandler(this.autoHideServerList_Panel1_MouseEnter);
            // 
            // autoHideServerList.Panel2
            // 
            this.autoHideServerList.Panel2.Controls.Add(this.gbServers);
            this.autoHideServerList.Panel2.MouseEnter += new System.EventHandler(this.autoHideServerList_Panel2_MouseEnter);
            this.autoHideServerList.Size = new System.Drawing.Size(353, 732);
            this.autoHideServerList.SplitterDistance = 40;
            this.autoHideServerList.TabIndex = 5;
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(9F, 17F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.BackColor = System.Drawing.SystemColors.Control;
            this.ClientSize = new System.Drawing.Size(1384, 787);
            this.Controls.Add(this.autoHideServerList);
            this.Controls.Add(this.statusStrip);
            this.Controls.Add(this.tabControl);
            this.Controls.Add(this.mnuMain);
            this.Font = new System.Drawing.Font("Arial Rounded MT Bold", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MainMenuStrip = this.mnuMain;
            this.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.MinimumSize = new System.Drawing.Size(1400, 825);
            this.Name = "frmMain";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Database Maintenance Console";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.frmMain_FormClosed);
            this.Load += new System.EventHandler(this.frmMain_Load);
            this.Resize += new System.EventHandler(this.frmMain_Resize);
            this.tabControl.ResumeLayout(false);
            this.tabPageBackups.ResumeLayout(false);
            this.gbBackupPlans.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvBackupPlans)).EndInit();
            this.gbOptionEditor.ResumeLayout(false);
            this.gbConfigurations.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvConfigs)).EndInit();
            this.gbSettings.ResumeLayout(false);
            this.scBackupSettings.Panel1.ResumeLayout(false);
            this.scBackupSettings.Panel1.PerformLayout();
            this.scBackupSettings.Panel2.ResumeLayout(false);
            this.scBackupSettings.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.scBackupSettings)).EndInit();
            this.scBackupSettings.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxTransferSize)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudBufferCount)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudFileCount)).EndInit();
            this.gbBackupFrequency.ResumeLayout(false);
            this.gbBackupFrequency.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.nudBackupMonths2)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudBackupMonths)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).EndInit();
            this.gbDatabases.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvDatabases)).EndInit();
            this.gbOptions.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvOptions)).EndInit();
            this.gbServers.ResumeLayout(false);
            this.mnuMain.ResumeLayout(false);
            this.mnuMain.PerformLayout();
            this.statusStrip.ResumeLayout(false);
            this.statusStrip.PerformLayout();
            this.autoHideServerList.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.autoHideServerList)).EndInit();
            this.autoHideServerList.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TabControl tabControl;
        private System.Windows.Forms.TabPage tabPageCentral;
        private System.Windows.Forms.TabPage tabPageBackups;
        private System.Windows.Forms.ListBox lstServerNames;
        private System.Windows.Forms.TabPage tabPageDiskCleanup;
        private System.Windows.Forms.TabPage tabPageIndexMaint;
        private System.Windows.Forms.TabPage tabPageAudit;
        private System.Windows.Forms.TabPage tabPageLogging;
        private System.Windows.Forms.TabPage tabPageConfiguration;
        private System.Windows.Forms.GroupBox gbServers;
        private System.Windows.Forms.MenuStrip mnuMain;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem refreshF5ToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem refreshCurrentTabF5ToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem refreshServerListToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem refreshAllToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem connectionManagerToolStripMenuItem;
        private System.Windows.Forms.Button btnAddServers;
        private System.Windows.Forms.StatusStrip statusStrip;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel;
        private System.Windows.Forms.Button btnRemoveServer;
        private System.Windows.Forms.GroupBox gbBackupPlans;
        private System.Windows.Forms.GroupBox gbOptionEditor;
        private System.Windows.Forms.DataGridView dgvBackupPlans;
        private System.Windows.Forms.GroupBox gbSettings;
        private System.Windows.Forms.Panel pnlArrow3;
        private System.Windows.Forms.Panel pnlArrow2;
        private System.Windows.Forms.Panel pnlArrow1;
        private System.Windows.Forms.GroupBox gbConfigurations;
        private System.Windows.Forms.GroupBox gbDatabases;
        private System.Windows.Forms.GroupBox gbOptions;
        private System.Windows.Forms.Button btnApplyBakOpt;
        private System.Windows.Forms.Button btnResetBakOpt;
        private System.Windows.Forms.DataGridView dgvConfigs;
        private System.Windows.Forms.DataGridView dgvOptions;
        private System.Windows.Forms.DataGridView dgvDatabases;
        private System.Windows.Forms.Button btnNewOption;
        private System.Windows.Forms.Button btnDropOption;
        private System.Windows.Forms.SplitContainer scBackupSettings;
        private System.Windows.Forms.CheckBox chbCompress;
        private System.Windows.Forms.CheckBox chbVerify;
        private System.Windows.Forms.ComboBox cbBackupType;
        private System.Windows.Forms.TextBox txtBackupDirectory;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckBox chbMAXTRANSSIZE;
        private System.Windows.Forms.CheckBox chbBufferCount;
        private System.Windows.Forms.CheckBox chbFileCount;
        private System.Windows.Forms.NumericUpDown nudMaxTransferSize;
        private System.Windows.Forms.NumericUpDown nudBufferCount;
        private System.Windows.Forms.NumericUpDown nudFileCount;
        private System.Windows.Forms.DateTimePicker dtpBackupStartTime;
        private System.Windows.Forms.Label lblBackupStartTime;
        private System.Windows.Forms.ComboBox cbBackupOccurs;
        private System.Windows.Forms.Label lblBackupOccurs;
        private System.Windows.Forms.ComboBox cbBackupInterval;
        private System.Windows.Forms.NumericUpDown numericUpDown1;
        private System.Windows.Forms.Label lblBackupInterval;
        private System.Windows.Forms.GroupBox gbBackupFrequency;
        private System.Windows.Forms.CheckedListBox chlstBackupDaysofWeek;
        private System.Windows.Forms.Label lblBackupWeeksOn;
        private System.Windows.Forms.Label lblBackupDays;
        private System.Windows.Forms.NumericUpDown numericUpDown2;
        private System.Windows.Forms.Label lblBackupRecurs;
        private System.Windows.Forms.Label lblBackupMonths2;
        private System.Windows.Forms.NumericUpDown nudBackupMonths2;
        private System.Windows.Forms.Label lblBackupofevery2;
        private System.Windows.Forms.ComboBox comboBox1;
        private System.Windows.Forms.ComboBox cbBackupMonth;
        private System.Windows.Forms.Label lblBackupMonths;
        private System.Windows.Forms.NumericUpDown nudBackupMonths;
        private System.Windows.Forms.Label lblBackupofevery;
        private System.Windows.Forms.RadioButton rbBackupThe;
        private System.Windows.Forms.RadioButton rbBackupDay;
        private System.Windows.Forms.SplitContainer autoHideServerList;
    }
}

