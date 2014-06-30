using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Xml.Linq;
using SsdtDeployment.Properties;
using SsdtDeployment.Set;

namespace SsdtDeployment.Process
{
    public class External
    {
        private string _reportOutputFile = string.Empty;
        private string _driftReportOutputFile = string.Empty;
        private string _reportFolder = string.Empty;
        private string _scriptOutputFile = string.Empty;
        private string _args = string.Empty;

        public event ProgressHandler Progress;
        public delegate void ProgressHandler(object sender, ProcessEventArgs e);
        public enum PackageAction
        {
            Report,
            Publish,
            DriftReport,
            Script,
        }      
        
        public External()
        {
            CreateWorkingFolders();
        }

        public void ExecuteProcess(DeploymentSet dacPacInfo, PackageAction action)
        {
            switch (action)
            {
                case PackageAction.Report:
                    _reportOutputFile = Path.Combine(CreateSessionFolder(_reportFolder, "Reports"), Settings.Default.PrePublishReportFilename);
                    _args = string.Format("/SourceFile:\"{0}\" /Profile:\"{1}\" /Action:DeployReport /OutputPath:\"{2}\"", dacPacInfo.DacPacFilePath, dacPacInfo.PublishProfileFilePath, _reportOutputFile);
                    break;

                case PackageAction.DriftReport:
                    _driftReportOutputFile = Path.Combine(CreateSessionFolder(_reportFolder, "Reports"), Settings.Default.DriftReportFilename);
                    //_args = string.Format("/TargetServerName:\"{0}\" /TargetDatabaseName:\"{1}\" /Action:DriftReport /OutputPath:\"{2}\"", "V-DEV-WEB-008\\DATA", "SSDTProject", _driftReportOutputFile);
                    _args = string.Format("/TargetConnectionString:\"{0}\" /Action:DriftReport /OutputPath:\"{1}\"", dacPacInfo.TargetConnectionString, _driftReportOutputFile);
                    break;

                case PackageAction.Publish:
                    _args = string.Format("/SourceFile:\"{0}\" /Profile:\"{1}\" /Action:Publish", dacPacInfo.DacPacFilePath, dacPacInfo.PublishProfileFilePath);
                    break;

                case PackageAction.Script:
                    _scriptOutputFile = Path.Combine(CreateSessionFolder(_reportFolder, "Reports"), Settings.Default.ScriptFilename);
                    _args = string.Format("/SourceFile:\"{0}\" /Profile:\"{1}\" /OutputPath:\"{2}\" /Action:Script", dacPacInfo.DacPacFilePath, dacPacInfo.PublishProfileFilePath, _scriptOutputFile);
                    break;
                default:
                    _args = string.Empty;
                    break;
            }
            
            using (var proc = new System.Diagnostics.Process())
            {
                proc.StartInfo.FileName = Settings.Default.SqlPackageExeLocation;
                proc.StartInfo.Arguments = _args;
                proc.StartInfo.UseShellExecute = false;
                proc.EnableRaisingEvents = true;
                proc.StartInfo.WindowStyle = ProcessWindowStyle.Normal;
                proc.StartInfo.CreateNoWindow = true;
                proc.StartInfo.RedirectStandardInput = true;
                proc.StartInfo.RedirectStandardOutput = true;
                proc.StartInfo.RedirectStandardError = true;
                proc.EnableRaisingEvents = true;
                proc.OutputDataReceived += ProcOutputDataReceived;
                proc.ErrorDataReceived += ProcOutputDataReceived;
                proc.Start();
                proc.BeginOutputReadLine();
                proc.BeginErrorReadLine();
                proc.WaitForExit();
            }

            Logging.Logger.Log.Info(string.Format("Command Line Arguments:{0}{1}{0}", Environment.NewLine, _args));

            Reporting(action);
        }
       
        private void Reporting(PackageAction action)
        {
            if (action == PackageAction.Report)
            {
                if (!File.Exists(_reportOutputFile)) return;

                // Deserialize the Xml to the screen if a report file exists...
                Progress(this, new ProcessEventArgs(XDocument.Load(_reportOutputFile).ToString(), _args));
            }

            if (action == PackageAction.DriftReport)
            {
                if (!File.Exists(_driftReportOutputFile)) return;

                // Deserialize the Xml to the screen if a report file exists...
                Progress(this, new ProcessEventArgs(XDocument.Load(_driftReportOutputFile).ToString(), _args));
            }
        }

        private void ProcOutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            Progress(this, new ProcessEventArgs(e.Data, _args));
        }

        private void CreateWorkingFolders()
        {
            var localAppFolder = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appName = Application.ProductName;

            var appDataFolder = Path.Combine(localAppFolder, appName);
            Directory.CreateDirectory(appDataFolder);

            var dataFolder = Path.Combine(appDataFolder, Settings.Default.DataFileFolderName);
            Directory.CreateDirectory(dataFolder);

            _reportFolder = dataFolder;
        }

        public static string CreateSessionFolder(string baseOutputFolder, string subdirName)
        {
            var customFolderName = Path.Combine(baseOutputFolder, subdirName);
            var dateStamp = string.Format("{0}_{1}_{2}",
                DateTime.Now.ToShortDateString().Replace("/", "-"),
                DateTime.Now.ToString("HH-mm-ss"),
                DateTime.Now.Millisecond);

            var sessionFolderName = Path.Combine(customFolderName, dateStamp);
            var bFolderSuccess = CreateFolder(sessionFolderName);
            var sessionFolderPath = bFolderSuccess ? sessionFolderName : null;
            return sessionFolderPath;
        }

        private static bool CreateFolder(string folderPath)
        {
            bool bSuccess;
            try
            {
                if (!Directory.Exists(folderPath))
                {
                    Directory.CreateDirectory(folderPath);
                    bSuccess = true;
                }
                else
                {
                    bSuccess = true;
                }
            }
            catch
            {
                bSuccess = false;
            }
            return bSuccess;
        }
    }
}
