using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using SFD;
using SFD.CollisionGroups;
using SFD.Colors;
using SFD.Effects;
using SFD.ErrorHandling;
using SFD.GUI;
using SFD.Loading;
using SFD.Logging;
using SFD.Materials;
using SFD.Objects;
using SFD.States;
using SFD.Tiles;
using SFD.UserProgression;
using SFDCT.Assets;
using SFDCT.Configuration;
using SFDCT.Helper;
using Keys = Microsoft.Xna.Framework.Input.Keys;

namespace SFDCT.Bootstrap;

[HarmonyPatch]
internal static class CoreHandler
{
    internal static bool SkipToEditor = false;
    internal static LogToFile ConsoleOutputLog;

    internal const SFDConfigSaveMode SAVE_MODERATOR_COMMANDS = (SFDConfigSaveMode)10;

    internal static void HotReloadAssets()
    {
        GameSFD game = GameSFD.Handle;
        if (game.CurrentState == State.Loading) return;

        Logger.LogInfo("Reloading assets...");
        ConsoleOutput.ShowMessage(ConsoleOutputType.Warning, "Reloading assets...");

        // Program
        ExConfig.Load();

        // SFD

        // - Static
        PlayerHUD.m_deadText = "";
        PlayerHUD.m_deadTextSize = Vector2.Zero;
        PlayerHUD.m_weaponSlotTexture = null;
        PlayerHUD.m_weaponSlotHighlightTexture = null;
        PlayerHUD.m_throwingModeIcon = null;
        PlayerHUD.m_skullIcon = null;
        PlayerHUD.m_textLife = "";
        PlayerHUD.m_textEnergy = "";
        PlayerHUD.m_bouncingAmmoIcon = null;
	    PlayerHUD.m_fireAmmoIcon = null;
        TileDatabase.m_categorizedTiles.Clear();
        TileDatabase.m_tiles.Clear();
        TileDatabase.m_tileKeyTranslations.Clear();
        TileDatabase.DefaultTileStructure = new TileStructure();
        TileDatabase.m_emptyTile = null;
        Cloud.m_texture = null;
        FireNodeFlamethrowerStart.m_texture = null;
        FireNodeFlamethrowerStart.m_origin = Vector2.Zero;
        FireNodeSpawner.m_texture = null;
        FireNodeSpawner.m_textureOrigin = Vector2.Zero;
        FireNodeTrailAir.m_texture = null;
        FireNodeTrailAir.m_origin = Vector2.Zero;
        FireNodeTrailGround.m_texture = null;
        FireNodeTrailGround.m_origin = Vector2.Zero;
        MuzzleFlashDynamic.m_muzzleSprites.Clear();
        Spark.m_sparkTexture = null;
        SFDLogo.m_isInitialized = false;
        MapThumbnailHandler.NoImage = null;
        MapThumbnailHandler.LastNoImageLoadException = null;
        ObjectMolotovThrown.TrailSpawner.m_texture = null;
        ObjectSpawnUnknown.m_spawnIndex = null;
        ObjectStreetsweeperCrate.m_textureParachute = null;
        ObjectSupplyCrate.m_textureParachute = null;
        ObjectSupplyCrate.m_textureCategories = null;
        Player.m_textureCrosshair = null;
        EffectAnimations.animations.Clear();
        MaterialDatabase.m_materials.Clear();
        CollisionGroupDatabase.m_collisionGroups.Clear();
        ColorDatabase.m_colors.Clear();
        ColorPaletteDatabase.m_palettes.Clear();

        // before Loading
        Textures.Initialize();

        BackgroundGrid.Load();
        BackgroundImage.Load();

        LanguageHelper.PreInit();

        ((StateLoading)game.GetState(State.Loading)).m_isLoaded = false;
        game.ChangeState(State.Loading, false);
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(SFDConfig), nameof(SFDConfig.SaveConfig))]
    private static void SaveSFDExtraSettings(SFDConfigSaveMode mode)
    {
        // This patch is a Prefix so the original code handles the saving
        // and checking of the configuration file

        lock (SFDConfig.m_saveConfigLock)
        {
            if (mode == SAVE_MODERATOR_COMMANDS || mode == SFDConfigSaveMode.All)
            {
                SFDConfig.ConfigHandler.UpdateValue("MODERATOR_COMMANDS", string.Join(" ", CoreConstants.MODDERATOR_COMMANDS));
            }

            if (mode == SFDConfigSaveMode.Settings || mode == SFDConfigSaveMode.All)
            {
                SFDConfig.ConfigHandler.UpdateValue("PRIMARY_COLOR", COLORS.MENU_BLUE.ToHex());
                SFDConfig.ConfigHandler.UpdateValue("CLIENT_REQUEST_SERVER_MOVEMENT", CoreConstants.CLIENT_REQUEST_SERVER_MOVEMENT);
            }
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.StateKeyDownEvent))]
    private static void CheckAssetReloadKeyPress(Keys key)
    {
        if (SFD.Input.Keyboard.IsCtrlDown() && key == Keys.F7) HotReloadAssets();
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(StateMainMenu), nameof(StateMainMenu.Load))]
    private static void CheckSkipToEditor(StateMainMenu __instance)
    {
        if (SkipToEditor)
        {
            SkipToEditor = false;

            SFDLogo.InstaFinalize();

            Logger.LogInfo("Starting Map Editor...");
            __instance.m_mainMenuPanel.actionMapEditor(null);
        }
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Challenges), nameof(Challenges.PostSetup))]
    private static void UnlockLockedItems()
    {
        // This is executed after Challenge.Load but before Challenge.PostSetup,
        // so challenge items are not locked yet. Only some items used in the official
        // campaigns and challenges that are locked with no real reason

        Items.m_allItems.Where(item => item.Locked).Do(item => item.Locked = false);
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.LoadContent))]
    private static void LoadSubContentFolders()
    {
        // Some content is loaded before the first loading state,
        // primarily BackgroundGrid and BackgroundImage. This means
        // the patches for those try to get content files while the
        // sub content folders havent loaded yet.

        SubContent.Load();
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(StateLoading), nameof(StateLoading.Load))]
    private static bool ExtraLoading(StateLoading __instance)
    {
        if (__instance.m_isLoaded) return true;

        // This to reload sub content folders after using a hot reload, since
        // they are loaded before this

        SubContent.Load();

        return true;
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(GlobalErrorHandler), nameof(GlobalErrorHandler.ShowError))]
    private static bool OverrideErrorDialog(Exception exception, string error, bool supressSend)
    {
        // This is to prevent players from sending error reports to Mythologic,
        // show them in our console instead, because they might be caused by us and
        // not vanilla code
        ThreadCultureHandler.SetThreadCultureInfo();

        GameSFD gameSFD = GameSFD.Handle;

        int startIndex = 0;
        string errorCaption = $"Superfighters Deluxe {VersionInfo.VERSION}" + (supressSend ? " - Error" : " - Unhandled Error");
        string errorMessage = GlobalErrorHandler.CreateErrorMessage(exception, error, out startIndex);

        Logger.LogError("################");
        Logger.LogError("[SFD Program Error]");
        Logger.LogError($"\t{exception}");
        Logger.LogError("");
        Logger.LogError($"Version:");
        Logger.LogError($"\t{VersionInfo.VERSION}");
        Logger.LogError($"Arch:");
        Logger.LogError($"\t{Environment.GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")}");
        Logger.LogError($"ArchWOW:");
        Logger.LogError($"\t{Environment.GetEnvironmentVariable("PROCESSOR_ARCHITEW6432")}");
        Logger.LogError("[GameSFD]");
        if (gameSFD != null)
        {
            Logger.LogError($"\tCurrentState: {gameSFD.CurrentState}");

            gameSFD.ExitFullscreen();
            gameSFD.ErrorShown();

            try
            {
                gameSFD.Exit();
            }
            catch { }
        }
        else
        {
            Logger.LogError("\tHandle is null");
        }

        Logger.LogError("[Error Source]");
        Logger.LogError($"\t{GlobalErrorHandler.ParseErrorSource(errorMessage)}");
        Logger.LogError("[Console Output]:");
        lock (ConsoleOutput.m_lock)
        {
            for (int num = ConsoleOutput.m_textsIndex - 1; num >= ConsoleOutput.m_textsIndex - 20; num--)
            {
                int num2 = ((num < 0) ? (num + 20) : num);
                if (!string.IsNullOrEmpty(ConsoleOutput.m_texts[num2].Message))
                {
                    Logger.LogError($"\t{ConsoleOutput.m_texts[num2].Message}");
                }
            }
        }
        Logger.LogError("################");

        try
        {
            Reports.Create("sfd_ex_crash", errorCaption + "\r\n \r\n" + errorMessage.Insert(startIndex, ConsoleOutput.GetLatestMessages() + "\r\n"));
        }
        catch { }

        Logger.LogError("Make sure your SFD installation version is not different from the target version.");
        Logger.LogError("Press any key to continue: ", false);
        Console.ReadKey();
        Console.WriteLine();

        GlobalErrorHandler.RequestExitApplicationAfterError?.Invoke();

        return false;
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(ConsoleOutput), nameof(ConsoleOutput.ShowMessage))]
    private static void LogConsoleMessageToConsoleLogs()
    {
        if (ConsoleOutputLog == null) return;

        int lastIndex = ((ConsoleOutput.m_textsIndex - 1) % ConsoleOutput.MAX_MESSAGES + ConsoleOutput.MAX_MESSAGES) % ConsoleOutput.MAX_MESSAGES;
        ConsoleOutput.ConsoleText text = ConsoleOutput.m_texts[lastIndex];
        ConsoleOutputLog.AddOutput($"{text.Time};{text.MessageType};{text.Message}");
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameSFD), MethodType.Constructor)]
    private static void Initialize(GameSFD __instance)
    {
        __instance.Window.Title = Globals.WindowTitle;

        if (ExConfig.Get<bool>(ExSettingKey.LogConsoleOutput))
        {
            Logger.LogDebug($"Creating console output logs");

            ConsoleOutputLog = new();
            string errorMessage = ConsoleOutputLog.Init(ExConfig.Get<string>(ExSettingKey.LogConsoleOutputFolder));

            if (!string.IsNullOrWhiteSpace(errorMessage))
            {
                Logger.LogDebug($"Failed to initialize console output logs: {errorMessage}");

                ConsoleOutputLog.Dispose();
                ConsoleOutputLog = null;
            }
        }
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.OnExiting))]
    private static void Dispose(GameSFD __instance)
    {
        ExConfig.Save();

        ConsoleOutputLog?.Dispose();
        ConsoleOutputLog = null;
    }
}
