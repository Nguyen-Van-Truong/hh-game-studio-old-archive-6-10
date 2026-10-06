using SFDCT.Helper;
using System.IO.Compression;
using System.Reflection;

namespace SFDCT;

internal static class Update
{
    private const string GitHubRepositoryVersionFileURL = "https://raw.githubusercontent.com/Liokindy/SFDCT/master/version";
    private const string GitHubRepositoryReleaseArchiveFileURL = "https://github.com/Liokindy/SFDCT/releases/download/VERSION/SFDCT.zip";
    private static HttpClient Client;

    private static void RenameFileToOld(string name)
    {
        string newName = name + ".old";

        File.Move(name, newName);
    }

    internal static void CleanOldFiles()
    {
        foreach (string path in Directory.GetFiles(Program.GameDirectory, "*.old", SearchOption.AllDirectories))
        {
            File.Delete(path);
        }
    }

    internal static bool CheckUpdate()
    {
        Logger.LogInfo("Checking for updates...");

        Version repositoryVersion;
        Version currentVersion = new(Globals.Version.TrimStart('v', '.'));
        string repositoryVersionString;

        Client = new();

        var task = Client.GetStringAsync(GitHubRepositoryVersionFileURL);

        try
        {
            Logger.LogDebug("Fetching version...");
            task.Wait();

            repositoryVersionString = task.Result;
            repositoryVersion = new(repositoryVersionString.TrimStart('v', '.'));
        }
        catch (Exception ex)
        {
            Logger.LogDebug("Exception trying to fetch version");
            Logger.LogDebug(ex.Message);
            return false;
        }

        switch (currentVersion.CompareTo(repositoryVersion))
        {
            case >= 0:
                Logger.LogInfo($"No new updates available");

                Client.Dispose();

                return false;
            case < 0:
                Logger.LogWarn($"New update available: {repositoryVersionString}");

                if (TryDownloadUpdate(repositoryVersionString))
                {
                    Client.Dispose();
                    return true;
                }

                Client.Dispose();
                return false;
        }
    }

    private static bool TryDownloadUpdate(string version)
    {
        Logger.LogWarn($"- Files inside '{Globals.Paths.Content}' will be deleted.");
        Logger.LogWarn("Download Update? ([Y]es/[N]o): ", false);

        bool choice = (Console.ReadLine() ?? string.Empty).Equals("Y", StringComparison.OrdinalIgnoreCase);
        if (!choice)
        {
            Logger.LogInfo("Update cancelled.");
            return false;
        }

        var archive = Path.Combine(Program.GameDirectory, "update.zip");
        var url = GitHubRepositoryReleaseArchiveFileURL.Replace("VERSION", version);

        Logger.LogDebug($"Update archive URL: {url}");
        Logger.LogDebug($"Update archive path: {archive}");

        Logger.LogInfo("Downloading update...");
        var task = Client.GetByteArrayAsync(url);
        try
        {
            task.Wait();

            using (var stream = File.Create(archive))
            {
                stream.Write(task.Result);
                stream.Dispose();
            }
        }
        catch (Exception ex)
        {
            Logger.LogError("Exception downloading update:");
            Logger.LogError(ex.Message);
            return false;
        }

        Logger.LogInfo("Removing old files...");

        var assemblyName = Path.GetFileNameWithoutExtension(Assembly.GetExecutingAssembly().Location);
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"{assemblyName}.deps.json"));
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"{assemblyName}.dll"));
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"{assemblyName}.exe"));
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"{assemblyName}.pdb"));
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"{assemblyName}.runtimeconfig.json"));

        RenameFileToOld(Path.Combine(Program.GameDirectory, $"0Harmony.dll"));
        RenameFileToOld(Path.Combine(Program.GameDirectory, $"Core.dll"));

        Directory.Delete(Globals.Paths.Content, true);

        Logger.LogInfo("Extracting update...");
        using (ZipArchive zip = ZipFile.OpenRead(archive))
        {
            zip.ExtractToDirectory(Program.GameDirectory, true);
        }

        File.Delete(archive);

        Logger.LogInfo("Update complete. Restart.");
        return true;
    }
}
