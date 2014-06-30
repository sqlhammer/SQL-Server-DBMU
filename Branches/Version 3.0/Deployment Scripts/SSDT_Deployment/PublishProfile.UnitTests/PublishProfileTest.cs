using System.IO;
using SsdtDeployment.Profile;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;

namespace PublishProfile_UnitTests
{
    [TestClass()]
    public class PublishProfileTest
    {
        public TestContext TestContext { get; set; }

        [TestMethod()]
        [DeploymentItem("TestData")]
        public void PublishProfile_FeedFile_VerifyParsedData()
        {
            const string expectedDbName = "DatabaseName";
            const string expectedConnStr = @"Data Source=SqlServer\Instance;Integrated Security=True;Pooling=False;Initial Catalog=DatabaseName";

            var pathToProfileFile = Path.Combine(TestContext.DeploymentDirectory, "PublishProfile.publish.xml");
            var target = new PublishProfile(pathToProfileFile);

            var dbName = target.TargetDatabaseName;
            var connStr = target.TargetConnectionString;

            Assert.AreEqual(expectedDbName, dbName);
            Assert.AreEqual(expectedConnStr, connStr);
        }
    }
}
