namespace SsdtDeployment.Set
{
    public class DeploymentSet
    {
        public string DacPacFilePath { get; set; }
        public string PublishProfileFilePath { get; set; }
        public string TargetConnectionString { get; set; }
        public string TargetDatabaseName { get; set; }
        public ReportType TypeOfReport { get; set; }

        public enum ReportType
        {
            Nothing,
            PublishReport,
            DriftReport,
            Script,
        }
    }
}
