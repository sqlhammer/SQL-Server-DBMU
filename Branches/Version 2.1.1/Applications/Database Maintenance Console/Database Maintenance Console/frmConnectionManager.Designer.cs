namespace Database_Maintenance_Console
{
    partial class frmConnectionManager
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmConnectionManager));
            this.mnuConnectionManager = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveAsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.gbCentralUtilityServer = new System.Windows.Forms.GroupBox();
            this.btnTestConnection = new System.Windows.Forms.Button();
            this.btnAddCentralServer = new System.Windows.Forms.Button();
            this.btnConnect = new System.Windows.Forms.Button();
            this.txtCentralUtilityServer = new System.Windows.Forms.TextBox();
            this.gbStoredCentralServers = new System.Windows.Forms.GroupBox();
            this.btnRemoveCentralServer = new System.Windows.Forms.Button();
            this.lstCentralServers = new System.Windows.Forms.ListBox();
            this.pnlLibertyTax = new System.Windows.Forms.Panel();
            this.statusStrip = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel = new System.Windows.Forms.ToolStripStatusLabel();
            this.mnuConnectionManager.SuspendLayout();
            this.gbCentralUtilityServer.SuspendLayout();
            this.gbStoredCentralServers.SuspendLayout();
            this.statusStrip.SuspendLayout();
            this.SuspendLayout();
            // 
            // mnuConnectionManager
            // 
            this.mnuConnectionManager.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem});
            this.mnuConnectionManager.Location = new System.Drawing.Point(0, 0);
            this.mnuConnectionManager.Name = "mnuConnectionManager";
            this.mnuConnectionManager.Padding = new System.Windows.Forms.Padding(8, 2, 0, 2);
            this.mnuConnectionManager.Size = new System.Drawing.Size(670, 24);
            this.mnuConnectionManager.TabIndex = 0;
            this.mnuConnectionManager.Text = "mnuConnectionManager";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.saveToolStripMenuItem,
            this.saveAsToolStripMenuItem,
            this.exitToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem.Text = "File";
            // 
            // saveToolStripMenuItem
            // 
            this.saveToolStripMenuItem.Name = "saveToolStripMenuItem";
            this.saveToolStripMenuItem.Size = new System.Drawing.Size(123, 22);
            this.saveToolStripMenuItem.Text = "Save";
            // 
            // saveAsToolStripMenuItem
            // 
            this.saveAsToolStripMenuItem.Name = "saveAsToolStripMenuItem";
            this.saveAsToolStripMenuItem.Size = new System.Drawing.Size(123, 22);
            this.saveAsToolStripMenuItem.Text = "Save As...";
            // 
            // exitToolStripMenuItem
            // 
            this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
            this.exitToolStripMenuItem.Size = new System.Drawing.Size(123, 22);
            this.exitToolStripMenuItem.Text = "Exit";
            this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
            // 
            // gbCentralUtilityServer
            // 
            this.gbCentralUtilityServer.Controls.Add(this.btnTestConnection);
            this.gbCentralUtilityServer.Controls.Add(this.btnAddCentralServer);
            this.gbCentralUtilityServer.Controls.Add(this.btnConnect);
            this.gbCentralUtilityServer.Controls.Add(this.txtCentralUtilityServer);
            this.gbCentralUtilityServer.Location = new System.Drawing.Point(13, 27);
            this.gbCentralUtilityServer.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.gbCentralUtilityServer.Name = "gbCentralUtilityServer";
            this.gbCentralUtilityServer.Padding = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.gbCentralUtilityServer.Size = new System.Drawing.Size(382, 90);
            this.gbCentralUtilityServer.TabIndex = 1;
            this.gbCentralUtilityServer.TabStop = false;
            this.gbCentralUtilityServer.Text = "Central Utility Server";
            // 
            // btnTestConnection
            // 
            this.btnTestConnection.Location = new System.Drawing.Point(98, 52);
            this.btnTestConnection.Name = "btnTestConnection";
            this.btnTestConnection.Size = new System.Drawing.Size(130, 25);
            this.btnTestConnection.TabIndex = 3;
            this.btnTestConnection.Text = "Test Connection";
            this.btnTestConnection.UseVisualStyleBackColor = true;
            this.btnTestConnection.Click += new System.EventHandler(this.btnTestConnection_Click);
            // 
            // btnAddCentralServer
            // 
            this.btnAddCentralServer.Location = new System.Drawing.Point(233, 52);
            this.btnAddCentralServer.Name = "btnAddCentralServer";
            this.btnAddCentralServer.Size = new System.Drawing.Size(140, 25);
            this.btnAddCentralServer.TabIndex = 2;
            this.btnAddCentralServer.Text = "Add to Stored List";
            this.btnAddCentralServer.UseVisualStyleBackColor = true;
            this.btnAddCentralServer.Click += new System.EventHandler(this.btnAddCentralServer_Click);
            // 
            // btnConnect
            // 
            this.btnConnect.Location = new System.Drawing.Point(7, 52);
            this.btnConnect.Name = "btnConnect";
            this.btnConnect.Size = new System.Drawing.Size(85, 25);
            this.btnConnect.TabIndex = 1;
            this.btnConnect.Text = "Connect";
            this.btnConnect.UseVisualStyleBackColor = true;
            this.btnConnect.Click += new System.EventHandler(this.btnConnect_Click);
            // 
            // txtCentralUtilityServer
            // 
            this.txtCentralUtilityServer.Location = new System.Drawing.Point(7, 22);
            this.txtCentralUtilityServer.Name = "txtCentralUtilityServer";
            this.txtCentralUtilityServer.Size = new System.Drawing.Size(366, 23);
            this.txtCentralUtilityServer.TabIndex = 0;
            // 
            // gbStoredCentralServers
            // 
            this.gbStoredCentralServers.Controls.Add(this.btnRemoveCentralServer);
            this.gbStoredCentralServers.Controls.Add(this.lstCentralServers);
            this.gbStoredCentralServers.Location = new System.Drawing.Point(402, 27);
            this.gbStoredCentralServers.Name = "gbStoredCentralServers";
            this.gbStoredCentralServers.Size = new System.Drawing.Size(256, 347);
            this.gbStoredCentralServers.TabIndex = 2;
            this.gbStoredCentralServers.TabStop = false;
            this.gbStoredCentralServers.Text = "Stored Central Utility Servers";
            // 
            // btnRemoveCentralServer
            // 
            this.btnRemoveCentralServer.Location = new System.Drawing.Point(9, 316);
            this.btnRemoveCentralServer.Name = "btnRemoveCentralServer";
            this.btnRemoveCentralServer.Size = new System.Drawing.Size(236, 25);
            this.btnRemoveCentralServer.TabIndex = 1;
            this.btnRemoveCentralServer.Text = "Remove Selection";
            this.btnRemoveCentralServer.UseVisualStyleBackColor = true;
            this.btnRemoveCentralServer.Click += new System.EventHandler(this.btnRemoveCentralServer_Click);
            // 
            // lstCentralServers
            // 
            this.lstCentralServers.FormattingEnabled = true;
            this.lstCentralServers.ItemHeight = 15;
            this.lstCentralServers.Location = new System.Drawing.Point(9, 22);
            this.lstCentralServers.Name = "lstCentralServers";
            this.lstCentralServers.Size = new System.Drawing.Size(236, 289);
            this.lstCentralServers.TabIndex = 0;
            this.lstCentralServers.SelectedIndexChanged += new System.EventHandler(this.lstCentralServers_SelectedIndexChanged);
            this.lstCentralServers.DoubleClick += new System.EventHandler(this.lstCentralServers_DoubleClick);
            // 
            // pnlLibertyTax
            // 
            this.pnlLibertyTax.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("pnlLibertyTax.BackgroundImage")));
            this.pnlLibertyTax.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Center;
            this.pnlLibertyTax.Location = new System.Drawing.Point(13, 125);
            this.pnlLibertyTax.Name = "pnlLibertyTax";
            this.pnlLibertyTax.Size = new System.Drawing.Size(382, 243);
            this.pnlLibertyTax.TabIndex = 3;
            // 
            // statusStrip
            // 
            this.statusStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel});
            this.statusStrip.Location = new System.Drawing.Point(0, 376);
            this.statusStrip.Name = "statusStrip";
            this.statusStrip.Size = new System.Drawing.Size(670, 22);
            this.statusStrip.TabIndex = 4;
            this.statusStrip.Text = "statusStrip1";
            // 
            // toolStripStatusLabel
            // 
            this.toolStripStatusLabel.Name = "toolStripStatusLabel";
            this.toolStripStatusLabel.Size = new System.Drawing.Size(0, 17);
            // 
            // frmConnectionManager
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(670, 398);
            this.Controls.Add(this.statusStrip);
            this.Controls.Add(this.pnlLibertyTax);
            this.Controls.Add(this.gbStoredCentralServers);
            this.Controls.Add(this.gbCentralUtilityServer);
            this.Controls.Add(this.mnuConnectionManager);
            this.Font = new System.Drawing.Font("Arial Rounded MT Bold", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MainMenuStrip = this.mnuConnectionManager;
            this.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.Name = "frmConnectionManager";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Connection Manager";
            this.Load += new System.EventHandler(this.frmConnectionManager_Load);
            this.mnuConnectionManager.ResumeLayout(false);
            this.mnuConnectionManager.PerformLayout();
            this.gbCentralUtilityServer.ResumeLayout(false);
            this.gbCentralUtilityServer.PerformLayout();
            this.gbStoredCentralServers.ResumeLayout(false);
            this.statusStrip.ResumeLayout(false);
            this.statusStrip.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.MenuStrip mnuConnectionManager;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveAsToolStripMenuItem;
        private System.Windows.Forms.GroupBox gbCentralUtilityServer;
        private System.Windows.Forms.Button btnAddCentralServer;
        private System.Windows.Forms.Button btnConnect;
        private System.Windows.Forms.TextBox txtCentralUtilityServer;
        private System.Windows.Forms.GroupBox gbStoredCentralServers;
        private System.Windows.Forms.ListBox lstCentralServers;
        private System.Windows.Forms.Button btnTestConnection;
        private System.Windows.Forms.Button btnRemoveCentralServer;
        private System.Windows.Forms.Panel pnlLibertyTax;
        private System.Windows.Forms.StatusStrip statusStrip;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel;
    }
}