using dnlib.DotNet;
using HarmonyLib;
using SFDCT.Bootstrap;
using SFDCT.Configuration;
using SFDCT.Helper;
using System.Diagnostics;
using System.Text;

namespace SFDCT;

internal static class Program
{
    internal static readonly Harmony Harmony = new("https://github.com/Liokindy/SFDCT");
    internal static string GameDirectory = Directory.GetCurrentDirectory();
    internal static bool Debug = false;

    static void Main(string[] args)
    {
        bool checkUpdate = true;
        bool checkSFDVersion = true;
        uint programChoiceTime = 3000;
        bool checkProgramChoice = true;

        for (int i = 0; i < args.Length; i++)
        {
            string arg = args[i];

            if (arg.Equals("--help", StringComparison.OrdinalIgnoreCase))
            {
                Logger.LogInfo("--help");
                Logger.LogInfo("--verbose");
                Logger.LogInfo("--version");
                Logger.LogInfo("--skip-update-check");
                Logger.LogInfo("--skip-choice");
                Logger.LogInfo("--set-game-directory");
                Logger.LogInfo("--set-choice-timeout");
                Logger.LogInfo("--ignore-sfd-version");
                return;
            }
            else if (arg.Equals("--verbose", StringComparison.OrdinalIgnoreCase))
            {
                Debug = true;
            }
            else if (arg.Equals("--version", StringComparison.OrdinalIgnoreCase))
            {
                WriteVersion();
                return;
            }
            else if (arg.Equals("--set-choice-timeout", StringComparison.OrdinalIgnoreCase))
            {
                i++;
                programChoiceTime = uint.Parse(args[i]);
            }
            else if (arg.Equals("--ignore-sfd-version", StringComparison.OrdinalIgnoreCase))
            {
                checkSFDVersion = false;
            }
            else if (arg.Equals("--skip-update-check", StringComparison.OrdinalIgnoreCase))
            {
                checkUpdate = false;
            }
            else if (arg.Equals("--skip-choice", StringComparison.OrdinalIgnoreCase))
            {
                checkProgramChoice = false;
            }
            else if (arg.Equals("--set-game-directory", StringComparison.OrdinalIgnoreCase) && args.Length > i + 1)
            {
                i++;
                GameDirectory = args[i];
            }
        }

#if DEBUG
        Debug = true;
#endif

        // TODO: there's probably a better fix for this
        // 
        // both Steam and debugging in VS launch our executable at
        // "Superfighters Deluxe", but if it gets ran manually then
        // Directory.GetCurrentDirectory() points at our actual folder,
        // causing a lot of issues
        if (GameDirectory.EndsWith("Superfighters Deluxe") && File.Exists(Path.Combine(GameDirectory, "Superfighters Deluxe.exe")) && File.Exists(Path.Combine(GameDirectory, "Superfighters Deluxe Language Tool.exe")))
        {
            GameDirectory = Path.Combine(GameDirectory, Globals.Identity);
        }

        if (checkProgramChoice)
        {
            Logger.LogWarn($"1. {Globals.Identity} (default); 2. SFD (vanilla); E. Map Editor (starts after main-menu);");
            Logger.LogWarn("Start option:", false);

            var k = new ConsoleKeyInfo();
            for (int wait = 0; wait < programChoiceTime; wait += 100)
            {
                if (Console.KeyAvailable)
                {
                    k = Console.ReadKey();
                    break;
                }

                Thread.Sleep(100);
            }

            Console.WriteLine();

            switch (k.Key)
            {
                case ConsoleKey.D2:
                case ConsoleKey.NumPad2:
                    StartSFD(args);
                    return;
                case ConsoleKey.E:
                    CoreHandler.SkipToEditor = true;
                    break;
            }
        }

        Update.CleanOldFiles();
        if (checkUpdate && Update.CheckUpdate()) return;

        WriteVersion();
        if (checkSFDVersion && !CheckSFDVersion())
        {
            Logger.LogError("Something went wrong trying to check your SFD installation's version, or the current mod version is incompatible with it.");
            Logger.LogError("(You can ignore this warning by adding '--ignore-sfd-version' to launch options, however this may cause the mod or SFD to crash)");
            return;
        }

        Logger.LogDebug($"Harmony.Id: {Harmony.Id}");
        Logger.LogDebug($"GameDirectory: {GameDirectory}");

        Logger.LogInfo("Checking core directories...");
        try
        {
            Directory.CreateDirectory(Globals.Paths.Content);
            Directory.CreateDirectory(Globals.Paths.Data);
            Directory.CreateDirectory(Globals.Paths.Commands);
            Directory.CreateDirectory(Globals.Paths.Language);
        }
        catch (Exception ex)
        {
            Logger.LogError("Exception trying to crate core directories, make sure the mod has permissions over them.");
            Logger.LogDebug(ex);
            return;
        }

        CopySFDDependencies();

        ExConfig.Load();

        var patchStopWatch = new Stopwatch();
        Logger.LogInfo("Patching");
        patchStopWatch.Start();
        Harmony.PatchAll();
        patchStopWatch.Stop();

        Logger.LogInfo($"Starting ({patchStopWatch.ElapsedMilliseconds}ms)");

        Greet();
        SFD.Program.Main(args);

        return;
    }

    static void StartSFD(string[] args)
    {
        Logger.LogInfo("Starting SFD");
        Process.Start(Path.Combine(Globals.Paths.SFD, "Superfighters Deluxe.exe"), string.Join(" ", args));
        return;
    }

    private static void WriteVersion()
    {
        Logger.LogInfo($"{Globals.Identity} - {Globals.Version}. SFD {SFD.VersionInfo.VERSION}");
    }

    private static void Greet()
    {
        // do not decypher!!!
        var greets = new string[]
        {
            "aGkuIGhlbGxvLiBncmVldGluZ3Mu",
            "d2VsY29tZSBhYm9hcmQsIGNhcHRhaW4uIGFsbCBzeXN0ZW1zIG9ubGluZQ==",
            "ZGlkIHlvdSBrbm93IHRoZSBsZW5ndGggb2YgbGFzZXJzIGlzIGVxdWFsIHRvIHRoZSBkaXN0YW5jZSB0b3dhcmRzIGVkZ2Ugb2YgdGhlIHNjcmVlbiwgcGx1cyAxNj8=",
            "ZGlkIHlvdSBrbm93IGxhc2VycyB3b2JibGUgcmFuZG9tbHkgZWFjaCBmcmFtZSBieSAwLjExNDUgZGVncmVlcz8=",
            "ZGlkIHlvdSBrbm93IHRoZXJlIGFyZSBhIGxvdCBvZiB1bnVzZWQgY29sb3JzIGluIHRoZSBnYW1lPyBtb3N0IGFyZSB2YXJpYXRpb25zIG9mIHVzZWQgY29sb3Jz",
            "ZGlkIHlvdSBrbm93IGZpc3RzIGFuZCBmZWV0IGFyZSB0ZWNobmljYWxseSBkaXN0aW5jdCAnd2VhcG9ucycgaW4gdGhlIGNvZGU/",
            "ZGlkIHlvdSBrbm93IHRoZXJlIGFyZSByZW1uYW50cyBvZiBhIHZvdGUta2lja2luZyBzeXN0ZW0gaW4gdGhlIGNvZGU/",
            "ZGlkIHlvdSBrbm93IGFuaW1hdGlvbnMgc3VwcG9ydCBoYXZpbmcgMyBkaXN0aW5jdCAnY29sbGlzaW9ucyc/IHRoZXlyZSBuZXZlciB1c2Vk",
            "ZGlkIHlvdSBrbm93IHRoZSBnYW1lIHVzZXMgYm90aCAnbGF6ZXInIGFuZCAnbGFzZXInIGluIHRoZSBjb2RlIGFuZCBhc3NldHM/",
            "ZGlkIHlvdSBrbm93IHRoZSAndXNlci5zZmRkJyBmaWxlIGlzIG5vdCBlbmNyeXB0ZWQgaW4gYW55IHdheT8uLi4gaXRzIGp1c3Qgc2NyYW1ibGVkIGJlZm9yZSBiZWluZyBzYXZlZA==",
            "ZGlkIHlvdSBrbm93IG5lb24gdGlsZXMgYWN0dWFsbHkgcHVsc2Ugc2xpZ2h0bHk/",
            "ZGlkIHlvdSBrbm93IHRoZSBoYW5kIG9uIGdhdWdlIHRpbGVzIGFsd2F5cyBvc2NpbGxhdGVzIGV2ZXJ5IDQgZnJhbWVzPyBvciB3ZWxsLCBldmVyeSA1MCBtaWxsaXNlY29uZHM=",
            "ZGlkIHlvdSBrbm93IHBsYXllciBib2RpZXMgYXJlIGp1c3Qgc2xpZGluZyBjaXJjbGVzIG1hZGUgb3V0IG9mICdGTEVTSCc/",
            "ZGlkIHlvdSBrbm93IHRoZSBiYXNlIGRhbWFnZSBvZiB0aGUgc2F3YmxhZGUgdGlsZSBpcyBhY3R1YWxseSA4NT8gaXQgZ2V0cyBjaG9wcGVkIHRvIDE1JQ==",
            "ZGlkIHlvdSBrbm93IHRoZSBtb3N0IGNvbW1vbiBidWxsZXQgc3BlZWQgaXMgMTIwMCB1bml0cz8uLi4gdGhlIGF2ZXJhZ2UgaXMgMTI2MyB1bml0cy4gYSBsb3QgdXNlIDEyMDA=",
            "ZGlkIHlvdSBrbm93IHRoZXJlIGlzIGNvZGUgZm9yIG1hbnkgb2JqZWN0cyB0aGF0IGNhbm5vdCBiZSBzcGF3bmVkPw==",
            "ZGlkIHlvdSBrbm93IHRoZSBvYmplY3QgIzIxNDc0ODM2NDYgaXMgcmVzcG9uc2libGUgZm9yIHJlcHJlc2VudGluZyB0aGUgd29ybGQ/",
            "ZGlkIHlvdSBrbm93IHBsYXllciBzdGF0aXN0aWNzIGFyZSBwYXJ0aWFsbHkgcmVzcG9uc2libGUgZm9yIGhhbmRsaW5nIGJvdHMgQUk/",
            "ZGlkIHlvdSBrbm93IHRoZSBjYW1lcmEgaXMgc2xpZ2h0bHkgYmlnZ2VyIGFuZCBudWRnZWQgdG8gdGhlIHJpZ2h0IHdoaWxlIGluIHRoZSBtYWluIG1lbnU/",
            "ZGlkIHlvdSBrbm93IHRoZSBmYXIgYmFja2dyb3VuZCBibGltcCB0aWxlIGhhcyByZW1uYW50IGNvZGUgdG8gYm9iIHVwIGFuZCBkb3duIHNsb3dseT8=",
            "ZGlkIHlvdSBrbm93IHRoZSB0aW1lIG9uIGNsb2NrIHRpbGVzIGlzIHN5bmNlZCB0byB5b3VyIGN1cnJlbnQgdGltZQ==",
            "ZGlkIHlvdSBrbm93IGVhY2ggZmlyZSBiaXQgaGFzIGEgcmFkaXVzIG9mIDUgcGl4ZWxzPw==",
            "ZGlkIHlvdSBrbm93IHRoZSBmaWxtZ3JhaW4gdGV4dHVyZSBuZWVkcyB0byBiZSBhdGxlYXN0IDE5MiBwaXhlbHMgd2lkZSBhbmQgdGFsbD8=",
        };

        var choosenGreet = "dGhhbmtzIGZvciBwbGF5aW5n";
        var random = new Random();
        if (random.NextDouble() < 0.25) choosenGreet = greets[random.Next(greets.Length)];

        Logger.LogInfo(Encoding.UTF8.GetString(Convert.FromBase64String(choosenGreet)));
    }

    private static bool CheckSFDVersion()
    {
        Logger.LogInfo($"Checking SFD version...");

        try
        {
            var path = Path.Combine(Globals.Paths.SFD, "SFD.Core.dll");

            var _SFD = AssemblyDef.Load(path);
            var _VersionInfo = _SFD.Find("SFD.VersionInfo", true);
            var _VERSION = _VersionInfo.FindField("VERSION");
            var version = (string)_VERSION.Constant.Value;

            // compare both versions literally
            Logger.LogDebug(version);
            return version == SFD.VersionInfo.VERSION;
        }
        catch (Exception ex)
        {
            Logger.LogDebug("Exception:");
            Logger.LogDebug(ex);
        }

        return false;
    }

    private static void CopySFDDependencies()
    {
        // IMPORTANT TODO:
        // There has to be a better way to solve this at a project-level,
        // instead of copying and using every single assembly SFD uses.

        string[] dependencyArray = [
            "steam_api64.dll",
            "steam_api64.lib",
            "steam_appid.txt",
            "Box2D.XNA.dll",
            "Facepunch.Steamworks.Win64.dll",
            "SFD.Core.dll",
            "SFD.GameScriptInterface.dll",
            "SFD.Input.dll",
            "SFD.MP.dll",
            "SFD.PlayNAudioTest.dll",
            "SFD.ScriptEngine.dll",
            "SFD.WindowsFormsControlLibrary.dll",
            "SteamLayer.dll",
            "DiscordRPC.xml",
            "SDL3.dll",
            "FAudio.dll",
            "FNA.dll",
            "FNA.dll.config",
            "FNA3D.dll",
        ];

        Logger.LogInfo($"Getting SFD dependencies...");

        foreach (var name in dependencyArray)
        {
            var sfdPath = Path.Combine(Globals.Paths.SFD, name);
            var path = Path.Combine(GameDirectory, name);

            if (File.Exists(path))
            {
                var currentModifyDate = File.GetLastWriteTime(path);
                var sfdModifyDate = File.GetLastWriteTime(sfdPath);

                if (sfdModifyDate <= currentModifyDate)
                {
                    Logger.LogDebug($"Ignoring: '{name}'...");
                    continue;
                }

                File.Delete(path);
            }

            Logger.LogInfo($"Copying: '{name}'...");
            File.Copy(sfdPath, path);
        }
    }
}
