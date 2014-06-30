using System;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using SsdtDeployment.Process;
using SsdtDeployment.Profile;
using SsdtDeployment.Properties;
using SsdtDeployment.Set;

namespace SsdtDeployment
{
    public partial class SsdtDeploymentUtility : Form
    {
        private BackgroundWorker _deployWorker = new BackgroundWorker();
        private BackgroundWorker _reportWorker = new BackgroundWorker();

        public SsdtDeploymentUtility()
        {
            InitializeComponent();
            txtDacPacFilePath.AllowDrop = true;
            txtDacPacFilePath.DragEnter += InputDragEnter;
            txtDacPacFilePath.DragDrop += TxtDacPacFilePathDragDrop;
            txtPublishFilePath.AllowDrop = true;
            txtPublishFilePath.DragEnter += InputDragEnter;
            txtPublishFilePath.DragDrop += TxtPublishFilePathDragDrop;
            _deployWorker.DoWork += DeployWorker;
            _deployWorker.ProgressChanged += DeployWorkerProgressChanged;
            _deployWorker.RunWorkerCompleted += DeployWorkerRunWorkerCompleted;
            _deployWorker.WorkerReportsProgress = true;
            _deployWorker.WorkerSupportsCancellation = true;
            _reportWorker.DoWork += ReportWorker;
            _reportWorker.ProgressChanged += ReportWorkerProgressChanged;
            _reportWorker.RunWorkerCompleted += ReportWorkerRunWorkerCompleted;
            _reportWorker.WorkerReportsProgress = true;
            _reportWorker.WorkerSupportsCancellation = true;
        }

        #region Ui Events and Helpers
        private void InputDragEnter(object sender, DragEventArgs e)
        {
            // Clear the field...
            ClearOutput();

            if (e.Data.GetDataPresent(DataFormats.FileDrop)) e.Effect = DragDropEffects.Copy;
        }
        
        private void TextInputChanged(object sender, EventArgs e)
        {
            ClearOutput();
        }

        private void ClearOutput()
        {
            reportOutput.Clear();
            processOutput.Clear();
        }

        private void TxtDacPacFilePathDragDrop(object sender, DragEventArgs e)
        {           
            // Only get the first file, not interested in multi-selected files...
            var file = (e.Data.GetData(DataFormats.FileDrop) as string[]).FirstOrDefault();
            if (file != null && file.EndsWith(".dacpac", StringComparison.CurrentCultureIgnoreCase))
            {
                txtDacPacFilePath.Text = GetDragDropValue(file);
            }
        }

        private void TxtPublishFilePathDragDrop(object sender, DragEventArgs e)
        {
            // Only get the first file, not interested in multi-selected files...
            var file = (e.Data.GetData(DataFormats.FileDrop) as string[]).FirstOrDefault();
            if (file != null && file.EndsWith(".publish.xml", StringComparison.CurrentCultureIgnoreCase))
            {
                txtPublishFilePath.Text = GetDragDropValue(file);
                ParseAndDisplayProfileInfo(txtPublishFilePath.Text);
            }
        }

        private static string GetDragDropValue(string file)
        {
            // If the drag-n-drop data is null, walk away...
            if (file == null) return string.Empty;

            // If the drag-n-drop data is not a fully qualified path to a file, walk away...
            if (!File.Exists(file)) return string.Empty;

            return file;
        }

        private void BtnResetClick(object sender, EventArgs e)
        {
            txtDacPacFilePath.Clear();
            txtPublishFilePath.Clear();
            processOutput.Clear();
            reportOutput.Clear();
            tsTargetConnStrValue.Text = Resources.SsdtDeploymentUtility_BtnResetClick_NULL;
            tsTargetDbValue.Text = Resources.SsdtDeploymentUtility_BtnResetClick_NULL;
        }

        private PublishProfile ParseAndDisplayProfileInfo(string pathToProfileFile)
        {
            var pub = new PublishProfile(pathToProfileFile);
            tsTargetDbValue.Text = pub.TargetDatabaseName;
            tsTargetConnStrValue.Text = pub.TargetConnectionString;

            return pub;
        }

        private void CopyCommandLineArgumentsToolStripMenuItemClick(object sender, EventArgs e)
        {
            var menuItem = sender as ToolStripDropDownItem;
            if (menuItem == null) return;

            var cm = menuItem.Owner as ContextMenuStrip;
            if (cm == null) return;

            var control = cm.SourceControl;
            if (control == null) return;

            var args = control.Tag as string;
            Clipboard.SetText(!string.IsNullOrWhiteSpace(args) ? args : "Nothing");
        }

        #endregion

        #region Deployment Events
        private void BtnDeployClick(object sender, EventArgs e)
        {           
            processOutput.Text = string.Empty;
            var deploymentSet = new DeploymentSet
                                {
                                    DacPacFilePath = txtDacPacFilePath.Text,
                                    PublishProfileFilePath = txtPublishFilePath.Text,
                                    TypeOfReport = DeploymentSet.ReportType.Nothing,
                                };

            if (!string.IsNullOrWhiteSpace(deploymentSet.DacPacFilePath) && !string.IsNullOrWhiteSpace(deploymentSet.PublishProfileFilePath))
            {
                btnDeploy.Enabled = false;
                _deployWorker.RunWorkerAsync(deploymentSet);
            }
        }

        private void BtnScriptClick(object sender, EventArgs e)
        {
            processOutput.Text = string.Empty;
            var deploymentSet = new DeploymentSet
            {
                DacPacFilePath = txtDacPacFilePath.Text,
                PublishProfileFilePath = txtPublishFilePath.Text,
                TypeOfReport = DeploymentSet.ReportType.Script,
            };

            if (!string.IsNullOrWhiteSpace(deploymentSet.DacPacFilePath) && !string.IsNullOrWhiteSpace(deploymentSet.PublishProfileFilePath))
            {
                btnDeploy.Enabled = false;
                btnScript.Enabled = false;
                _deployWorker.RunWorkerAsync(deploymentSet);
            }
        }

        private void DeployWorkerRunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            pbDeploy.Visible = false;
            btnDeploy.Enabled = true;
            btnScript.Enabled = true;
        }
        
        private void DeployWorkerProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            pbDeploy.Visible = true;
            if (!(e.UserState is ProcessEventArgs)) return;
            var events = e.UserState as ProcessEventArgs;
            processOutput.Text += (events.ProcessOutputLine + Environment.NewLine);
            processOutput.Tag = events.CommandLineArguments;
        }

        private void DeployWorker(object sender, DoWorkEventArgs e)
        {
            if (!(e.Argument is DeploymentSet)) return;
            
            var dacPacSet = e.Argument as DeploymentSet;
            var deployProcess = new External();
            deployProcess.Progress += DeploymentProcessProgress;

            var action = External.PackageAction.Script;
            switch (dacPacSet.TypeOfReport)
            {
                case DeploymentSet.ReportType.Nothing:
                    action = External.PackageAction.Publish;
                    break;
                case DeploymentSet.ReportType.Script:
                    action = External.PackageAction.Script;
                    break;
                default:
                    action = External.PackageAction.Script;
                    break;
            }
            deployProcess.ExecuteProcess(dacPacSet, action);
        }

        void DeploymentProcessProgress(object sender, ProcessEventArgs e)
        {
            _deployWorker.ReportProgress(0, e);
        }
        #endregion

        #region Report Events
        private void BtnReportClick(object sender, EventArgs e)
        {
            reportOutput.Text = string.Empty;
            var deploymentSet = new DeploymentSet
            {
                DacPacFilePath = txtDacPacFilePath.Text,
                PublishProfileFilePath = txtPublishFilePath.Text,
                TypeOfReport = DeploymentSet.ReportType.PublishReport,
            };

            if (string.IsNullOrWhiteSpace(deploymentSet.DacPacFilePath) ||
                string.IsNullOrWhiteSpace(deploymentSet.PublishProfileFilePath)) return;
            btnReport.Enabled = false;
            btnDriftReport.Enabled = false;
            _reportWorker.RunWorkerAsync(deploymentSet);
        }

        private void BtnDriftReportClick(object sender, EventArgs e)
        {
            reportOutput.Text = string.Empty;
            var pubInfo = ParseAndDisplayProfileInfo(txtPublishFilePath.Text);
            var deploymentSet = new DeploymentSet
            {
                DacPacFilePath = txtDacPacFilePath.Text,
                PublishProfileFilePath = txtPublishFilePath.Text,
                TargetConnectionString = pubInfo.TargetConnectionString,
                TargetDatabaseName = pubInfo.TargetDatabaseName,
                TypeOfReport = DeploymentSet.ReportType.DriftReport,
            };

            if (string.IsNullOrWhiteSpace(deploymentSet.DacPacFilePath) ||
                string.IsNullOrWhiteSpace(deploymentSet.PublishProfileFilePath)) return;
            btnReport.Enabled = false;
            btnDriftReport.Enabled = false;
            _reportWorker.RunWorkerAsync(deploymentSet);
        }

        private void ReportWorkerRunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            pbReport.Visible = false;
            btnReport.Enabled = true;
            btnDriftReport.Enabled = true;
        }

        private void ReportWorkerProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            pbReport.Visible = true;
            if (!(e.UserState is ProcessEventArgs)) return;
            var events = e.UserState as ProcessEventArgs;
            reportOutput.Text += (events.ProcessOutputLine + Environment.NewLine);
            reportOutput.Tag = events.CommandLineArguments;
        }

        private void ReportWorker(object sender, DoWorkEventArgs e)
        {
            if (!(e.Argument is DeploymentSet)) return;

            var dacPacSet = e.Argument as DeploymentSet;
            var reportProcess = new External();
            reportProcess.Progress += ReportProcessProgress;

            var action = External.PackageAction.Report;
            switch(dacPacSet.TypeOfReport)
            {
                case DeploymentSet.ReportType.Nothing:
                    action = External.PackageAction.Publish;
                    break;
                case DeploymentSet.ReportType.PublishReport:
                    action = External.PackageAction.Report;
                    break;
                case DeploymentSet.ReportType.DriftReport:
                    action = External.PackageAction.DriftReport;
                    break;
            }

            reportProcess.ExecuteProcess(dacPacSet, action);
        }

        void ReportProcessProgress(object sender, ProcessEventArgs e)
        {
            _reportWorker.ReportProgress(0, e);
        }
        #endregion
    }
}
