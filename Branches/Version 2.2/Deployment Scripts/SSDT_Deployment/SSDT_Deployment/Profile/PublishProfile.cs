using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace SsdtDeployment.Profile
{
    public class PublishProfile
    {
        private readonly XNamespace _proj = "http://schemas.microsoft.com/developer/msbuild/2003";

        public string TargetDatabaseName { get; set; }
        public string TargetConnectionString { get; set; }

        public PublishProfile(string pathToProfileFile)
        {
            if (!File.Exists(pathToProfileFile)) return;

            var profileDoc = XDocument.Load(pathToProfileFile);
            if (profileDoc.Root == null) return;

            var firstTargetDb = profileDoc.Root.Elements(_proj + "PropertyGroup").Elements(_proj + "TargetDatabaseName").FirstOrDefault();
            if (firstTargetDb != null) TargetDatabaseName = firstTargetDb.Value;

            var firstConnStr = profileDoc.Root.Elements(_proj + "PropertyGroup").Elements(_proj + "TargetConnectionString").FirstOrDefault();
            if (firstConnStr != null && !string.IsNullOrWhiteSpace(TargetDatabaseName))
            {
                TargetConnectionString = string.Format("{0};Initial Catalog={1}", firstConnStr.Value, TargetDatabaseName);
            }
        }
    }
}
