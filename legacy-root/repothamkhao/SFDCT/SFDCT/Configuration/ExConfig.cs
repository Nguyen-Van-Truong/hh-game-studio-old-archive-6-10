using SFD;
using SFDCT.Bootstrap;
using SFDCT.Helper;

namespace SFDCT.Configuration;

internal static class ExConfig
{
    private static readonly Dictionary<ExSettingKey, object> Settings = [];

    internal static void Save()
    {
        var handler = new ExIniHandler();

        Save(handler);

        handler.Dispose();
    }

    internal static void Save(ExIniHandler handler)
    {
        Logger.LogDebug("Saving configuration...");

        SetSettingsToFile(handler);
        handler.SaveFile(Globals.Paths.ConfigurationIni);
    }

    internal static void Load()
    {
        Logger.LogDebug("Loading configuration...");

        SetSettingsToDefaults();
        var handler = new ExIniHandler();

        if (!File.Exists(Globals.Paths.ConfigurationIni))
        {
            Logger.LogDebug($"Creating configuration file...");
            using (FileStream fileStream = File.Create(Globals.Paths.ConfigurationIni))
            {
                fileStream.Close();
            }

            Thread.Sleep(100);
        }
        else
        {
            Logger.LogDebug($"Reading configuration file...");
            handler.ReadFile(Globals.Paths.ConfigurationIni);

            Set(ExSettingKey.SoundPanningEnabled, handler.ReadValueBool(GetKey(ExSettingKey.SoundPanningEnabled), true));
            Set(ExSettingKey.SoundPanningStrength, handler.ReadValueIntCapped(GetKey(ExSettingKey.SoundPanningStrength), 70, 0, 100) * 0.01f);
            Set(ExSettingKey.SoundPanningForceScreenSpace, handler.ReadValueBool(GetKey(ExSettingKey.SoundPanningForceScreenSpace), false));
            Set(ExSettingKey.SoundPanningInworldThreshold, handler.ReadValueIntCapped(GetKey(ExSettingKey.SoundPanningInworldThreshold), 60, 0, 1000));
            Set(ExSettingKey.SoundPanningInworldDistance, handler.ReadValueIntCapped(GetKey(ExSettingKey.SoundPanningInworldDistance), 400, 0, 1000));
            Set(ExSettingKey.LowHealthSaturationFactor, handler.ReadValueIntCapped(GetKey(ExSettingKey.LowHealthSaturationFactor), 70, 0, 100) * 0.01f);
            Set(ExSettingKey.LowHealthThreshold, handler.ReadValueIntCapped(GetKey(ExSettingKey.LowHealthThreshold), 25, 0, 100) * 0.01f);
            Set(ExSettingKey.LowHealthHurtLevel1Threshold, handler.ReadValueIntCapped(GetKey(ExSettingKey.LowHealthHurtLevel1Threshold), 25, 0, 100) * 0.01f);
            Set(ExSettingKey.LowHealthHurtLevel2Threshold, handler.ReadValueIntCapped(GetKey(ExSettingKey.LowHealthHurtLevel2Threshold), 12, 0, 100) * 0.01f);
            Set(ExSettingKey.HideFilmgrain, handler.ReadValueBool(GetKey(ExSettingKey.HideFilmgrain), false));
            Set(ExSettingKey.Language, handler.ReadValueString(GetKey(ExSettingKey.Language), LanguageHandler.DefaultLanguageName));
            //Set(ExSettingKey.SpectatorsMaximum, handler.ReadValueIntCapped(GetKey(ExSettingKey.SpectatorsMaximum), 4, 0, 4));
            //Set(ExSettingKey.SpectatorsOnlyModerators, handler.ReadValueBool(GetKey(ExSettingKey.SpectatorsOnlyModerators), true));
            //Set(ExSettingKey.VoteKickEnabled, handler.ReadValueBool(GetKey(ExSettingKey.VoteKickEnabled), false));
            //Set(ExSettingKey.VoteKickFailCooldown, handler.ReadValueIntCapped(GetKey(ExSettingKey.VoteKickFailCooldown), 150, 15, 300));
            //Set(ExSettingKey.VoteKickSuccessCooldown, handler.ReadValueIntCapped(GetKey(ExSettingKey.VoteKickSuccessCooldown), 60, 15, 300));
            Set(ExSettingKey.SubContent, handler.ReadValueBool(GetKey(ExSettingKey.SubContent), true));
            Set(ExSettingKey.SubContentDisabledFolders, handler.ReadValueString(GetKey(ExSettingKey.SubContentDisabledFolders), string.Empty));
            Set(ExSettingKey.SubContentEnabledFolders, handler.ReadValueString(GetKey(ExSettingKey.SubContentEnabledFolders), string.Empty));
            Set(ExSettingKey.ChatWidth, handler.ReadValueIntCapped(GetKey(ExSettingKey.ChatWidth), 428, 428 / 2, 428 * 4));
            Set(ExSettingKey.ChatHeight, handler.ReadValueIntCapped(GetKey(ExSettingKey.ChatHeight), 10 * (int)GameChat.MESSAGE_HEIGHT, 10 * (int)GameChat.MESSAGE_HEIGHT / 2, 10 * (int)GameChat.MESSAGE_HEIGHT * 4));
            Set(ExSettingKey.ChatExtraHeight, handler.ReadValueIntCapped(GetKey(ExSettingKey.ChatExtraHeight), 0, 0, 10 * (int)GameChat.MESSAGE_HEIGHT * 2));
            Set(ExSettingKey.LogConsoleOutput, handler.ReadValueBool(GetKey(ExSettingKey.LogConsoleOutput), false));
            Set(ExSettingKey.LogConsoleOutputFolder, handler.ReadValueString(GetKey(ExSettingKey.LogConsoleOutputFolder), ""));
        }

        SetSettingsToFile(handler);
        Save(handler);

        handler.Dispose();
    }

    private static void SetSettingsToDefaults()
    {
        Set(ExSettingKey.SoundPanningEnabled, true);
        Set(ExSettingKey.SoundPanningStrength, 0.70f);
        Set(ExSettingKey.SoundPanningForceScreenSpace, false);
        Set(ExSettingKey.SoundPanningInworldThreshold, 60);
        Set(ExSettingKey.SoundPanningInworldDistance, 400);
        Set(ExSettingKey.LowHealthSaturationFactor, 0.70f);
        Set(ExSettingKey.LowHealthThreshold, 0.25f);
        Set(ExSettingKey.LowHealthHurtLevel1Threshold, 0.25f);
        Set(ExSettingKey.LowHealthHurtLevel2Threshold, 0.12f);
        Set(ExSettingKey.HideFilmgrain, false);
        Set(ExSettingKey.Language, LanguageHandler.DefaultLanguageName);
        //Set(ExSettingKey.SpectatorsMaximum, 4);
        //Set(ExSettingKey.SpectatorsOnlyModerators, true);
        //Set(ExSettingKey.VoteKickEnabled, false);
        //Set(ExSettingKey.VoteKickFailCooldown, 150);
        //Set(ExSettingKey.VoteKickSuccessCooldown, 60);
        Set(ExSettingKey.SubContent, true);
        Set(ExSettingKey.SubContentDisabledFolders, string.Empty);
        Set(ExSettingKey.SubContentEnabledFolders, string.Empty);
        Set(ExSettingKey.ChatWidth, 428);
        Set(ExSettingKey.ChatHeight, 10 * (int)GameChat.MESSAGE_HEIGHT);
        Set(ExSettingKey.ChatExtraHeight, 0);
        Set(ExSettingKey.LogConsoleOutput, false);
        Set(ExSettingKey.LogConsoleOutputFolder, "");
    }

    private static void SetSettingsToFile(ExIniHandler handler)
    {
        handler.Clear();
        handler.ReadLine(GetKey(ExSettingKey.SoundPanningEnabled), Get<bool>(ExSettingKey.SoundPanningEnabled));
        handler.ReadLine(GetKey(ExSettingKey.SoundPanningStrength), (int)(Get<float>(ExSettingKey.SoundPanningStrength) * 100));
        handler.ReadLine(GetKey(ExSettingKey.SoundPanningForceScreenSpace), Get<bool>(ExSettingKey.SoundPanningForceScreenSpace));
        handler.ReadLine(GetKey(ExSettingKey.SoundPanningInworldThreshold), Get<int>(ExSettingKey.SoundPanningInworldThreshold));
        handler.ReadLine(GetKey(ExSettingKey.SoundPanningInworldDistance), Get<int>(ExSettingKey.SoundPanningInworldDistance));
        handler.ReadLine(GetKey(ExSettingKey.LowHealthSaturationFactor), (int)(Get<float>(ExSettingKey.LowHealthSaturationFactor) * 100));
        handler.ReadLine(GetKey(ExSettingKey.LowHealthThreshold), (int)(Get<float>(ExSettingKey.LowHealthThreshold) * 100));
        handler.ReadLine(GetKey(ExSettingKey.LowHealthHurtLevel1Threshold), (int)(Get<float>(ExSettingKey.LowHealthHurtLevel1Threshold) * 100));
        handler.ReadLine(GetKey(ExSettingKey.LowHealthHurtLevel2Threshold), (int)(Get<float>(ExSettingKey.LowHealthHurtLevel2Threshold) * 100));
        handler.ReadLine(GetKey(ExSettingKey.HideFilmgrain), Get<bool>(ExSettingKey.HideFilmgrain));
        handler.ReadLine(GetKey(ExSettingKey.Language), Get<string>(ExSettingKey.Language));
        //handler.ReadLine(GetKey(ExSettingKey.SpectatorsMaximum), Get<int>(ExSettingKey.SpectatorsMaximum));
        //handler.ReadLine(GetKey(ExSettingKey.SpectatorsOnlyModerators), Get<bool>(ExSettingKey.SpectatorsOnlyModerators));
        //handler.ReadLine(GetKey(ExSettingKey.VoteKickEnabled), Get<bool>(ExSettingKey.VoteKickEnabled));
        //handler.ReadLine(GetKey(ExSettingKey.VoteKickFailCooldown), Get<int>(ExSettingKey.VoteKickFailCooldown));
        //handler.ReadLine(GetKey(ExSettingKey.VoteKickSuccessCooldown), Get<int>(ExSettingKey.VoteKickSuccessCooldown));
        handler.ReadLine(GetKey(ExSettingKey.SubContent), Get<bool>(ExSettingKey.SubContent));
        handler.ReadLine(GetKey(ExSettingKey.SubContentDisabledFolders), Get<string>(ExSettingKey.SubContentDisabledFolders));
        handler.ReadLine(GetKey(ExSettingKey.SubContentEnabledFolders), Get<string>(ExSettingKey.SubContentEnabledFolders));
        handler.ReadLine(GetKey(ExSettingKey.ChatWidth), Get<int>(ExSettingKey.ChatWidth));
        handler.ReadLine(GetKey(ExSettingKey.ChatHeight), Get<int>(ExSettingKey.ChatHeight));
        handler.ReadLine(GetKey(ExSettingKey.ChatExtraHeight), Get<int>(ExSettingKey.ChatExtraHeight));
        handler.ReadLine(GetKey(ExSettingKey.LogConsoleOutput), Get<bool>(ExSettingKey.LogConsoleOutput));
        handler.ReadLine(GetKey(ExSettingKey.LogConsoleOutputFolder), Get<string>(ExSettingKey.LogConsoleOutputFolder));
    }

    internal static string GetKey(ExSettingKey setting)
    {
        switch (setting)
        {
            default: return "UNKNOWN_" + (int)setting;
            case ExSettingKey.SoundPanningEnabled: return "SOUNDPANNING_ENABLED";
            case ExSettingKey.SoundPanningStrength: return "SOUNDPANNING_STRENGTH";
            case ExSettingKey.SoundPanningForceScreenSpace: return "SOUNDPANNING_FORCE_SCREEN_SPACE";
            case ExSettingKey.SoundPanningInworldThreshold: return "SOUNDPANNING_INWORLD_THRESHOLD";
            case ExSettingKey.SoundPanningInworldDistance: return "SOUNDPANNING_INWORLD_DISTANCE";
            case ExSettingKey.LowHealthSaturationFactor: return "LOW_HEALTH_SATURATION_FACTOR";
            case ExSettingKey.LowHealthThreshold: return "LOW_HEALTH_THRESHOLD";
            case ExSettingKey.LowHealthHurtLevel1Threshold: return "LOW_HEALTH_HURTLEVEL1_THRESHOLD";
            case ExSettingKey.LowHealthHurtLevel2Threshold: return "LOW_HEALTH_HURTLEVEL2_THRESHOLD";
            case ExSettingKey.HideFilmgrain: return "HIDE_FILMGRAIN";
            case ExSettingKey.Language: return "LANGUAGE_FILE_NAME";
            //case ExSettingKey.SpectatorsMaximum: return "SPECTATORS_MAXIMUM";
            //case ExSettingKey.SpectatorsOnlyModerators: return "SPECTATORS_ONLY_MODERATORS";
            //case ExSettingKey.VoteKickEnabled: return "VOTEKICK_ENABLED";
            //case ExSettingKey.VoteKickSuccessCooldown: return "VOTEKICK_SUCCESS_COOLDOWN";
            //case ExSettingKey.VoteKickFailCooldown: return "VOTEKICK_FAIL_COOLDOWN";
            case ExSettingKey.SubContent: return "SUBCONTENT";
            case ExSettingKey.SubContentDisabledFolders: return "SUBCONTENT_DISABLED_FOLDERS";
            case ExSettingKey.SubContentEnabledFolders: return "SUBCONTENT_ENABLED_FOLDERS";
            case ExSettingKey.ChatWidth: return "CHAT_WIDTH";
            case ExSettingKey.ChatHeight: return "CHAT_HEIGHT";
            case ExSettingKey.ChatExtraHeight: return "CHAT_EXTRA_HEIGHT";
            case ExSettingKey.LogConsoleOutput: return "LOG_CONSOLE";
            case ExSettingKey.LogConsoleOutputFolder: return "LOG_CONSOLE_FOLDER";
        }
    }

    internal static T Get<T>(ExSettingKey key)
    {
        if (Settings.ContainsKey(key) && typeof(T) == Settings[key].GetType())
        {
            return (T)Settings[key];
        }

        return default;
    }

    internal static void Set<T>(ExSettingKey key, T value)
    {
        if (!Settings.ContainsKey(key))
        {
            Settings.Add(key, value);
        }
        else
        {
            Settings[key] = value;
        }
    }
}
