using HarmonyLib;
using SFD;
using SFDCT.Configuration;
using SFDCT.Helper;

namespace SFDCT.Bootstrap;

[HarmonyPatch]
internal static class LanguageHandler
{
    internal static string DefaultLanguageName { get { return $"{Globals.Identity}_default"; } }

    internal static string[] GetExLanguages()
    {
        return LanguageFileTranslator.m_languageFileMappings.Keys
                .Where(lang => lang.StartsWith(Globals.Identity, StringComparison.OrdinalIgnoreCase))
                .ToArray();
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(LanguageFileTranslator), nameof(LanguageFileTranslator.ListLanguageNames))]
    private static void RemoveExLanguages(ref List<string> __result)
    {
        for (int i = __result.Count - 1; i >= 0; i--)
        {
            string language = __result[i];

            if (language.StartsWith(Globals.Identity, StringComparison.OrdinalIgnoreCase))
            {
                __result.RemoveAt(i);
            }
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(LanguageHelper), nameof(LanguageHelper.Load))]
    private static void LoadExLanguageFile()
    {
        string filePath = Path.Combine(Globals.Paths.Language, ExConfig.Get<string>(ExSettingKey.Language)) + ".xml";

        if (!File.Exists(filePath))
        {
            if (LanguageFileTranslator.m_languageFileMappings.ContainsKey(ExConfig.Get<string>(ExSettingKey.Language)))
            {
                filePath = LanguageFileTranslator.GetLanguageFileFromName(ExConfig.Get<string>(ExSettingKey.Language));
            }
        }

        if (!File.Exists(filePath))
        {
            Logger.LogError($"Failed to find language file: '{filePath}'");
            Logger.LogError("Using default language...");

            filePath = Path.Combine(Globals.Paths.Language, DefaultLanguageName + ".xml");
            ExConfig.Set(ExSettingKey.Language, DefaultLanguageName);
        }

        filePath = Path.GetFullPath(filePath);

        if (!File.Exists(filePath))
        {
            Logger.LogError("Failed to find default language file");
            return;
        }

        LanguageHelper.ReadFile(filePath, LanguageHelper.m_texts, LanguageHelper.m_textHashes);
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(LanguageFileTranslator), nameof(LanguageFileTranslator.Load))]
    private static void LoadExLanguagesFolder()
    {
        string folderPath = Path.GetFullPath(Globals.Paths.Language);

        LanguageFileTranslator.LoadFolder(folderPath);
    }
}
