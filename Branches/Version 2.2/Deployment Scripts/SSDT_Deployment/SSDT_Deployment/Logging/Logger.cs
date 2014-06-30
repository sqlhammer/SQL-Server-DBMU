
using System.Diagnostics;
using System.IO;
using log4net;
using log4net.Appender;

namespace SsdtDeployment.Logging
{
    /// <summary>
    /// The Logger class handles the management of the log4net logging functionality and management of the LogDict Dictionary housing logs for each class
    /// </summary>
    public class Logger
    {
        /// <summary>
        /// Create a dictionary to house the logs, one for each class
        /// </summary>
        private static readonly System.Collections.Generic.Dictionary<string, ILog> LogDict = new System.Collections.Generic.Dictionary<string, ILog>();

        /// <summary>
        /// Used to reference the local class
        /// </summary>
        private static readonly string ClassFullName = typeof(Logger).FullName;

        /// <summary>
        /// Handle the creation of the logger
        /// </summary>
        static Logger()
        {
            // configure log4net from the web.config
            log4net.Config.XmlConfigurator.Configure();

            // add the current class to the logdict
            LogDict.Add(ClassFullName, LogManager.GetLogger(typeof(Logger)));

            // add the pid property that will contain the process id for the output
            GlobalContext.Properties["pid"] = System.Diagnostics.Process.GetCurrentProcess().Id;

            // comment the creation of the new logdict entry
            LogDict[ClassFullName].Debug("Creating repository for " + ClassFullName);
        }

        /// <summary>
        /// Static property to access the logger for the requestion class
        /// </summary>
        public static ILog Log
        {
            get
            {
                // get a reference to the class calling the logger
                var callingClass = new StackTrace().GetFrame(1).GetMethod().DeclaringType;

                // check to see if the class already has a reference in the LogDict
                if (!LogDict.ContainsKey(callingClass.FullName))
                {
                    // if there was not logger already created, create a new one for the class
                    var log = LogManager.GetLogger(callingClass);

                    // lock the logger to ensure a safe threading update
                    lock (LogDict)
                    {
                        // ensure the LogDict entry wasn't added before the lock was established
                        if (!LogDict.ContainsKey(callingClass.FullName))
                        {
                            // add the new log to the LogDict
                            LogDict.Add(callingClass.FullName, log);

                            // comment the creation of the new LogDict entry
                            log.Debug("Creating repository for " + callingClass.FullName);
                        }
                    }
                }

                // return the Logger for the requesting class
                return LogDict[callingClass.FullName];
            }
        }
    }
}
