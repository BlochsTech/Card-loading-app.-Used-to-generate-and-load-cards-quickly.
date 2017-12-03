using System;
using System.Diagnostics;
using CardLoader2000.CardLoadingLibrary.Objects;

namespace CardLoader2000.CardLoadingLibrary
{
    public class CommandHelper
    {
        internal static CommandOutput Execute(string command, string workingDirectory, int timeoutMS = 10000, int limitSeconds = 30, bool redirectInput = false)
        {
            ProcessStartInfo processInfo = new ProcessStartInfo("cmd.exe", "/s /c \"" + command+"\"")
            {
                WorkingDirectory = workingDirectory,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardError = true,
                RedirectStandardOutput = true,
                RedirectStandardInput = redirectInput
            };

            Process process = Process.Start(processInfo);

            TimeSpan T = new TimeSpan(), limit = new TimeSpan(0, 0, limitSeconds);
            DateTime start = DateTime.Now;
            string output = "";

            if (process == null)
                return new CommandOutput
                {
                    error = "Command process could not be created.",
                    exitCode = 1,
                    output = "Command process could not be created."
                };

            process.WaitForExit(timeoutMS); //Timeout 10 sec.

            if (DateTime.Now - start >= TimeSpan.FromMilliseconds(timeoutMS))
            {
                start = DateTime.Now;
                string oStream = "", nOutStream = "";
                while (T < limit)
                {
                    if (!oStream.Equals(nOutStream))
                    {
                        start = DateTime.Now;
                    }
                    T = DateTime.Now - start;
                    oStream = nOutStream;
                    nOutStream = process.StandardOutput.ReadToEnd();
                    output += nOutStream;
                }
            }

            CommandOutput co = new CommandOutput
            {
                output = String.IsNullOrEmpty(output) ? process.StandardOutput.ReadToEnd() : output,
                error = process.StandardError.ReadToEnd(),
                exitCode = process.ExitCode
            };

            return co;
        }
    }
}
