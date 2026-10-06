namespace SFDCT;

internal static class Globals
{
    internal const string Identity = "SFDCT";
    internal const string Version = "v.3.0.0";
    internal static string WindowTitle { get { return $"Superfighters Deluxe {SFD.VersionInfo.VERSION} ({Version})"; } }
    internal static string VersionLabel { get { return $"{SFD.VersionInfo.VERSION} - {Version}"; } }
    internal static Microsoft.Xna.Framework.Color SFRServerColor { get { return new Microsoft.Xna.Framework.Color(222, 66, 165); } }

    internal static class Paths
    {
        internal static string SFD { get { return Directory.GetParent(Program.GameDirectory).FullName; } }
        internal static string Content { get { return Path.Combine(Program.GameDirectory, "Content"); } }
        internal static string SubContent { get { return Path.Combine(Program.GameDirectory, "SubContent"); } }
        internal static string Data { get { return Path.Combine(Content, "Data"); } }
        internal static string ConfigurationIni { get { return Path.Combine(Data, "config.ini"); } }
        internal static string Language { get { return Path.Combine(Data, "Misc", "Language"); } }
        internal static string Commands { get { return Path.Combine(Data, "Misc", "Commands"); } }
    }
}
