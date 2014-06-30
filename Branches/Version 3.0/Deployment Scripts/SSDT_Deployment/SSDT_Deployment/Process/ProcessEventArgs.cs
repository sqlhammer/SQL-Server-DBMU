using System;

namespace SsdtDeployment.Process
{
    public class ProcessEventArgs : EventArgs
    {
        public string ProcessOutputLine { get; set; }
        public string CommandLineArguments { get; set; }

        public ProcessEventArgs(string outputLine, string commandLineArgs)
        {
            ProcessOutputLine = outputLine;
            CommandLineArguments = commandLineArgs;
        }
    }
}
