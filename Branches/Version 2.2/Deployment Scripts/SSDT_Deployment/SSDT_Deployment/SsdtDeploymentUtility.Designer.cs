namespace SsdtDeployment
{
    partial class SsdtDeploymentUtility
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
            this.components = new System.ComponentModel.Container();
            this.txtDacPacFilePath = new System.Windows.Forms.TextBox();
            this.txtPublishFilePath = new System.Windows.Forms.TextBox();
            this.lblDacpacFile = new System.Windows.Forms.Label();
            this.lblProfileFile = new System.Windows.Forms.Label();
            this.btnDeploy = new System.Windows.Forms.Button();
            this.processOutput = new System.Windows.Forms.RichTextBox();
            this.cmArgumentsUsed = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.copyCommandLineArgumentsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.pbDeploy = new System.Windows.Forms.ProgressBar();
            this.btnReset = new System.Windows.Forms.Button();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.tsTargetDb = new System.Windows.Forms.ToolStripStatusLabel();
            this.tsTargetDbValue = new System.Windows.Forms.ToolStripStatusLabel();
            this.tsTargetConnStr = new System.Windows.Forms.ToolStripStatusLabel();
            this.tsTargetConnStrValue = new System.Windows.Forms.ToolStripStatusLabel();
            this.tabControl = new System.Windows.Forms.TabControl();
            this.tabPreDeployment = new System.Windows.Forms.TabPage();
            this.btnDriftReport = new System.Windows.Forms.Button();
            this.reportOutput = new System.Windows.Forms.RichTextBox();
            this.btnReport = new System.Windows.Forms.Button();
            this.pbReport = new System.Windows.Forms.ProgressBar();
            this.tabDeployment = new System.Windows.Forms.TabPage();
            this.btnScript = new System.Windows.Forms.Button();
            this.cmArgumentsUsed.SuspendLayout();
            this.statusStrip1.SuspendLayout();
            this.tabControl.SuspendLayout();
            this.tabPreDeployment.SuspendLayout();
            this.tabDeployment.SuspendLayout();
            this.SuspendLayout();
            // 
            // txtDacPacFilePath
            // 
            this.txtDacPacFilePath.AllowDrop = true;
            this.txtDacPacFilePath.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtDacPacFilePath.BackColor = System.Drawing.Color.White;
            this.txtDacPacFilePath.Location = new System.Drawing.Point(13, 40);
            this.txtDacPacFilePath.MaxLength = 260;
            this.txtDacPacFilePath.Multiline = true;
            this.txtDacPacFilePath.Name = "txtDacPacFilePath";
            this.txtDacPacFilePath.ReadOnly = true;
            this.txtDacPacFilePath.Size = new System.Drawing.Size(997, 65);
            this.txtDacPacFilePath.TabIndex = 0;
            this.txtDacPacFilePath.TextChanged += new System.EventHandler(this.TextInputChanged);
            // 
            // txtPublishFilePath
            // 
            this.txtPublishFilePath.AllowDrop = true;
            this.txtPublishFilePath.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtPublishFilePath.BackColor = System.Drawing.Color.White;
            this.txtPublishFilePath.Location = new System.Drawing.Point(13, 124);
            this.txtPublishFilePath.MaxLength = 260;
            this.txtPublishFilePath.Multiline = true;
            this.txtPublishFilePath.Name = "txtPublishFilePath";
            this.txtPublishFilePath.ReadOnly = true;
            this.txtPublishFilePath.Size = new System.Drawing.Size(997, 63);
            this.txtPublishFilePath.TabIndex = 1;
            this.txtPublishFilePath.TextChanged += new System.EventHandler(this.TextInputChanged);
            // 
            // lblDacpacFile
            // 
            this.lblDacpacFile.AutoSize = true;
            this.lblDacpacFile.Location = new System.Drawing.Point(13, 21);
            this.lblDacpacFile.Name = "lblDacpacFile";
            this.lblDacpacFile.Size = new System.Drawing.Size(204, 13);
            this.lblDacpacFile.TabIndex = 2;
            this.lblDacpacFile.Text = "Main Project\'s DACPAC File (drag-n-drop):";
            // 
            // lblProfileFile
            // 
            this.lblProfileFile.AutoSize = true;
            this.lblProfileFile.Location = new System.Drawing.Point(13, 108);
            this.lblProfileFile.Name = "lblProfileFile";
            this.lblProfileFile.Size = new System.Drawing.Size(121, 13);
            this.lblProfileFile.TabIndex = 3;
            this.lblProfileFile.Text = "Profile File (drag-n-drop):";
            // 
            // btnDeploy
            // 
            this.btnDeploy.Location = new System.Drawing.Point(6, 10);
            this.btnDeploy.Name = "btnDeploy";
            this.btnDeploy.Size = new System.Drawing.Size(75, 23);
            this.btnDeploy.TabIndex = 4;
            this.btnDeploy.Text = "Deploy";
            this.btnDeploy.UseVisualStyleBackColor = true;
            this.btnDeploy.Click += new System.EventHandler(this.BtnDeployClick);
            // 
            // processOutput
            // 
            this.processOutput.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.processOutput.BackColor = System.Drawing.Color.White;
            this.processOutput.ContextMenuStrip = this.cmArgumentsUsed;
            this.processOutput.Location = new System.Drawing.Point(3, 39);
            this.processOutput.Name = "processOutput";
            this.processOutput.ReadOnly = true;
            this.processOutput.Size = new System.Drawing.Size(980, 192);
            this.processOutput.TabIndex = 5;
            this.processOutput.Text = "";
            // 
            // cmArgumentsUsed
            // 
            this.cmArgumentsUsed.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.copyCommandLineArgumentsToolStripMenuItem});
            this.cmArgumentsUsed.Name = "cmArgumentsUsed";
            this.cmArgumentsUsed.Size = new System.Drawing.Size(228, 26);
            // 
            // copyCommandLineArgumentsToolStripMenuItem
            // 
            this.copyCommandLineArgumentsToolStripMenuItem.Name = "copyCommandLineArgumentsToolStripMenuItem";
            this.copyCommandLineArgumentsToolStripMenuItem.Size = new System.Drawing.Size(227, 22);
            this.copyCommandLineArgumentsToolStripMenuItem.Text = "Copy Command-Line Arguments";
            this.copyCommandLineArgumentsToolStripMenuItem.Click += new System.EventHandler(this.CopyCommandLineArgumentsToolStripMenuItemClick);
            // 
            // pbDeploy
            // 
            this.pbDeploy.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pbDeploy.Location = new System.Drawing.Point(172, 10);
            this.pbDeploy.Name = "pbDeploy";
            this.pbDeploy.Size = new System.Drawing.Size(811, 23);
            this.pbDeploy.Style = System.Windows.Forms.ProgressBarStyle.Marquee;
            this.pbDeploy.TabIndex = 6;
            this.pbDeploy.Visible = false;
            // 
            // btnReset
            // 
            this.btnReset.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnReset.Location = new System.Drawing.Point(935, 11);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(75, 23);
            this.btnReset.TabIndex = 7;
            this.btnReset.Text = "Reset";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.BtnResetClick);
            // 
            // statusStrip1
            // 
            this.statusStrip1.GripStyle = System.Windows.Forms.ToolStripGripStyle.Visible;
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.tsTargetDb,
            this.tsTargetDbValue,
            this.tsTargetConnStr,
            this.tsTargetConnStrValue});
            this.statusStrip1.Location = new System.Drawing.Point(0, 467);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(1022, 22);
            this.statusStrip1.TabIndex = 11;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // tsTargetDb
            // 
            this.tsTargetDb.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Left;
            this.tsTargetDb.ForeColor = System.Drawing.Color.Crimson;
            this.tsTargetDb.Name = "tsTargetDb";
            this.tsTargetDb.Size = new System.Drawing.Size(96, 17);
            this.tsTargetDb.Text = "Target Database:";
            // 
            // tsTargetDbValue
            // 
            this.tsTargetDbValue.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Right;
            this.tsTargetDbValue.Name = "tsTargetDbValue";
            this.tsTargetDbValue.Size = new System.Drawing.Size(35, 17);
            this.tsTargetDbValue.Text = "NULL";
            // 
            // tsTargetConnStr
            // 
            this.tsTargetConnStr.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Left;
            this.tsTargetConnStr.ForeColor = System.Drawing.Color.Crimson;
            this.tsTargetConnStr.Name = "tsTargetConnStr";
            this.tsTargetConnStr.Size = new System.Drawing.Size(135, 17);
            this.tsTargetConnStr.Text = "Target Connection String:";
            // 
            // tsTargetConnStrValue
            // 
            this.tsTargetConnStrValue.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Right;
            this.tsTargetConnStrValue.Name = "tsTargetConnStrValue";
            this.tsTargetConnStrValue.Size = new System.Drawing.Size(35, 17);
            this.tsTargetConnStrValue.Text = "NULL";
            // 
            // tabControl
            // 
            this.tabControl.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tabControl.Controls.Add(this.tabPreDeployment);
            this.tabControl.Controls.Add(this.tabDeployment);
            this.tabControl.Location = new System.Drawing.Point(12, 204);
            this.tabControl.Name = "tabControl";
            this.tabControl.SelectedIndex = 0;
            this.tabControl.Size = new System.Drawing.Size(997, 260);
            this.tabControl.TabIndex = 13;
            // 
            // tabPreDeployment
            // 
            this.tabPreDeployment.Controls.Add(this.btnDriftReport);
            this.tabPreDeployment.Controls.Add(this.reportOutput);
            this.tabPreDeployment.Controls.Add(this.btnReport);
            this.tabPreDeployment.Controls.Add(this.pbReport);
            this.tabPreDeployment.Location = new System.Drawing.Point(4, 22);
            this.tabPreDeployment.Name = "tabPreDeployment";
            this.tabPreDeployment.Padding = new System.Windows.Forms.Padding(3);
            this.tabPreDeployment.Size = new System.Drawing.Size(989, 234);
            this.tabPreDeployment.TabIndex = 0;
            this.tabPreDeployment.Text = "Pre-Deployment";
            this.tabPreDeployment.UseVisualStyleBackColor = true;
            // 
            // btnDriftReport
            // 
            this.btnDriftReport.Location = new System.Drawing.Point(145, 10);
            this.btnDriftReport.Name = "btnDriftReport";
            this.btnDriftReport.Size = new System.Drawing.Size(133, 23);
            this.btnDriftReport.TabIndex = 10;
            this.btnDriftReport.Text = "Drift Report";
            this.btnDriftReport.UseVisualStyleBackColor = true;
            this.btnDriftReport.Click += new System.EventHandler(this.BtnDriftReportClick);
            // 
            // reportOutput
            // 
            this.reportOutput.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.reportOutput.BackColor = System.Drawing.Color.White;
            this.reportOutput.ContextMenuStrip = this.cmArgumentsUsed;
            this.reportOutput.Location = new System.Drawing.Point(3, 39);
            this.reportOutput.Name = "reportOutput";
            this.reportOutput.ReadOnly = true;
            this.reportOutput.Size = new System.Drawing.Size(983, 192);
            this.reportOutput.TabIndex = 8;
            this.reportOutput.Text = "";
            // 
            // btnReport
            // 
            this.btnReport.Location = new System.Drawing.Point(6, 10);
            this.btnReport.Name = "btnReport";
            this.btnReport.Size = new System.Drawing.Size(133, 23);
            this.btnReport.TabIndex = 7;
            this.btnReport.Text = "Pre-Deployment Report";
            this.btnReport.UseVisualStyleBackColor = true;
            this.btnReport.Click += new System.EventHandler(this.BtnReportClick);
            // 
            // pbReport
            // 
            this.pbReport.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pbReport.Location = new System.Drawing.Point(290, 10);
            this.pbReport.Name = "pbReport";
            this.pbReport.Size = new System.Drawing.Size(693, 23);
            this.pbReport.Style = System.Windows.Forms.ProgressBarStyle.Marquee;
            this.pbReport.TabIndex = 9;
            this.pbReport.Visible = false;
            // 
            // tabDeployment
            // 
            this.tabDeployment.Controls.Add(this.btnScript);
            this.tabDeployment.Controls.Add(this.processOutput);
            this.tabDeployment.Controls.Add(this.btnDeploy);
            this.tabDeployment.Controls.Add(this.pbDeploy);
            this.tabDeployment.Location = new System.Drawing.Point(4, 22);
            this.tabDeployment.Name = "tabDeployment";
            this.tabDeployment.Padding = new System.Windows.Forms.Padding(3);
            this.tabDeployment.Size = new System.Drawing.Size(989, 234);
            this.tabDeployment.TabIndex = 1;
            this.tabDeployment.Text = "Deployment";
            this.tabDeployment.UseVisualStyleBackColor = true;
            // 
            // btnScript
            // 
            this.btnScript.Location = new System.Drawing.Point(91, 10);
            this.btnScript.Name = "btnScript";
            this.btnScript.Size = new System.Drawing.Size(75, 23);
            this.btnScript.TabIndex = 7;
            this.btnScript.Text = "VS Script";
            this.btnScript.UseVisualStyleBackColor = true;
            this.btnScript.Click += new System.EventHandler(this.BtnScriptClick);
            // 
            // SsdtDeploymentUtility
            // 
            this.AllowDrop = true;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1022, 489);
            this.Controls.Add(this.tabControl);
            this.Controls.Add(this.statusStrip1);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.lblProfileFile);
            this.Controls.Add(this.lblDacpacFile);
            this.Controls.Add(this.txtPublishFilePath);
            this.Controls.Add(this.txtDacPacFilePath);
            this.MinimumSize = new System.Drawing.Size(1030, 516);
            this.Name = "SsdtDeploymentUtility";
            this.Text = "SSDT Deployment Utility";
            this.cmArgumentsUsed.ResumeLayout(false);
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.tabControl.ResumeLayout(false);
            this.tabPreDeployment.ResumeLayout(false);
            this.tabDeployment.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox txtDacPacFilePath;
        private System.Windows.Forms.TextBox txtPublishFilePath;
        private System.Windows.Forms.Label lblDacpacFile;
        private System.Windows.Forms.Label lblProfileFile;
        private System.Windows.Forms.Button btnDeploy;
        private System.Windows.Forms.RichTextBox processOutput;
        private System.Windows.Forms.ProgressBar pbDeploy;
        private System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel tsTargetDb;
        private System.Windows.Forms.ToolStripStatusLabel tsTargetDbValue;
        private System.Windows.Forms.ToolStripStatusLabel tsTargetConnStr;
        private System.Windows.Forms.ToolStripStatusLabel tsTargetConnStrValue;
        private System.Windows.Forms.TabControl tabControl;
        private System.Windows.Forms.TabPage tabDeployment;
        private System.Windows.Forms.TabPage tabPreDeployment;
        private System.Windows.Forms.Button btnDriftReport;
        private System.Windows.Forms.RichTextBox reportOutput;
        private System.Windows.Forms.Button btnReport;
        private System.Windows.Forms.ProgressBar pbReport;
        private System.Windows.Forms.ContextMenuStrip cmArgumentsUsed;
        private System.Windows.Forms.ToolStripMenuItem copyCommandLineArgumentsToolStripMenuItem;
        private System.Windows.Forms.Button btnScript;
    }
}

