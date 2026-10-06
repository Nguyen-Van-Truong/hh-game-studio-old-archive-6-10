using HarmonyLib;
using Microsoft.Xna.Framework;
using SDR.Networking;
using SFD;
using SFD.Code.MenuControls;
using SFD.Effects;
using SFD.GameKeyboard;
using SFD.MenuControls;
using SFD.States;
using SFDCT.Configuration;
using SFDCT.Helper;
using SFDCT.Sync;
using System.Reflection.Emit;

namespace SFDCT.UI;

[HarmonyPatch]
internal static class UIHandler
{
    //internal static bool IsServerInfoInvalid(GameServerInfo gameServer)
    //{
    //    if (gameServer == null) return true;

    //    bool invalidMaxPlayers = gameServer.MaxAvailableSlots == 0 || gameServer.MaxAvailableSlots > 16;

    //    int totalPlayerCount = gameServer.Players + gameServer.Bots;
    //    bool invalidPlayerCount = totalPlayerCount > gameServer.MaxAvailableSlots;

    //    bool invalidNameLength = gameServer.GameName == null || gameServer.GameName.Length < 3 || gameServer.GameName.Length > 24;

    //    return invalidMaxPlayers || invalidPlayerCount || invalidNameLength;
    //}

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.DrawInner))]
    private static IEnumerable<CodeInstruction> OverrideVersionLabel(IEnumerable<CodeInstruction> instructions)
    {
        foreach (var instruction in instructions)
        {
            if (instruction.opcode == OpCodes.Ldstr && instruction.operand?.Equals(VersionInfo.VERSION) == true)
            {
                instruction.operand = $"{VersionInfo.VERSION} - {Globals.Version}";
            }
        }

        return instructions;
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(FilmGrain), nameof(FilmGrain.Draw))]
    private static bool CheckFilmGrainHide()
    {
        if (ExConfig.Get<bool>(ExSettingKey.HideFilmgrain)) return false;
        return true;
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(MainMenuPanel), MethodType.Constructor)]
    private static void MainMenuExSettingsButton(MainMenuPanel __instance)
    {
        if (CoreConstants.IsGame)
        {
            var menu = __instance.menu;
            var sfdctSettings = new MainMenuItem(Globals.Identity.ToUpperInvariant(), new ControlEvents.ChooseEvent((object obj) => { __instance.OpenSubPanel(new Panels.ExSettingsPanel()); }));

            sfdctSettings.Initialize(menu);

            __instance.Height += 1;
            menu.Height += 1;
            menu.Items.Insert(menu.Items.Count - 2, sfdctSettings);
            __instance.UpdatePosition();
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameMenuPanel), MethodType.Constructor)]
    private static void GameMenuInsertExtraElements(GameMenuPanel __instance)
    {
        var menu = (Menu)__instance.members[0];
        var sfdctSettings = new MainMenuItem(Globals.Identity.ToUpperInvariant(), new ControlEvents.ChooseEvent((object obj) => { __instance.OpenSubPanel(new Panels.ExSettingsPanel()); }));

        sfdctSettings.Initialize(menu);

        menu.Height += 1;
        menu.Items.Insert(menu.Items.Count - 1, sfdctSettings);

        // the DS doesnt load profiles, so its possible to accidentally
        // erase existing profiles when it "saves" them
        // 
        // (as of now the DS is not implemented, might need to use 'GameSFD.Handle.CurrentStateIsServerClient' later?)
        if (GameSFD.Handle.CurrentState == State.Game || GameSFD.Handle.CurrentState == State.GameOffline)
        {
            var playerSlots = new MainMenuPlayerSlot[8];

            for (int i = 0; i < 8; i++)
            {
                var playerSlot = new MainMenuPlayerSlot(Vector2.Zero, __instance, i, i >= 2);
                playerSlot.SetProfile(Profile.GetPlayerProfile(i));
                playerSlots[i] = playerSlot;
                __instance.members.Add(playerSlot);
            }

            menu.NeighborUpId = 5;
            menu.NeighborDownId = 1;

            // set the correct neighbor ids
            // 0 is the menu, 1-8 are the player slots
            playerSlots[0].NeighborUpId = 0;
            playerSlots[0].NeighborDownId = 2;
            playerSlots[1].NeighborUpId = 1;
            playerSlots[1].NeighborDownId = 3;
            playerSlots[2].NeighborUpId = 2;
            playerSlots[2].NeighborDownId = 4;
            playerSlots[3].NeighborUpId = 3;
            playerSlots[3].NeighborDownId = 8;

            playerSlots[7].NeighborUpId = 4;
            playerSlots[7].NeighborDownId = 7;
            playerSlots[6].NeighborUpId = 8;
            playerSlots[6].NeighborDownId = 6;
            playerSlots[5].NeighborUpId = 7;
            playerSlots[5].NeighborDownId = 5;
            playerSlots[4].NeighborUpId = 6;
            playerSlots[4].NeighborDownId = 0;
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameMenuPanel), nameof(GameMenuPanel.Update))]
    private static void GameMenuUpdatePlayerSlot(GameMenuPanel __instance, float elapsed)
    {
        foreach (var member in __instance.members)
        {
            if (member is not MainMenuPlayerSlot playerSlot) continue;

            playerSlot.Update(elapsed);
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameMenuPanel), nameof(GameMenuPanel.UpdatePosition))]
    private static void GameMenuUpdatePositionPlayerSlot(GameMenuPanel __instance)
    {
        // the scoreboard can get in the way of the 8 local player slots,
        // or they run off screen due to their vanilla alignment.

        // vanilla aligns them to the side at the bottom of the screen.
        // this way they're aligned vertically at the top and bottom of
        // the left menu, from top to bottom:
        // p8, p7, p6, p5, menu, p1, p2, p3, p4

        int i = 0;
        foreach (var member in __instance.members)
        {
            if (member is not MainMenuPlayerSlot playerSlot) continue;

            int x = -__instance.Area.X + 8;
            int y = -__instance.Area.Y;

            if (i < 4)
            {
                y = -__instance.Area.Y + Resolution.SCREEN_HEIGHT - Resolution.GAME_SCREEN_OFFSET_Y * 2 - 100 - (member.Height + 8) * (3 - i);
            }
            else
            {
                y = -__instance.Area.Y + Resolution.GAME_SCREEN_OFFSET_Y * 2 + 182 - (member.Height + 8) * (i - 4);
            }

            playerSlot.LocalPosition = new(x, y);
            i++;
        }
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(MainMenuPlayerSlot), nameof(MainMenuPlayerSlot.ProfilePanel_SelectProfile))]
    private static bool PlayerSlotSelectProfileFix(MainMenuPlayerSlot __instance, Profile selectedProfile, int profileSlot)
    {
        // this method crashes the game if ParentPanel is not a MainMenuPanel,
        // because it instantly casts it.

        // TODO: the profile is not replicated correctly to other players,
        // so it isnt updated in their scoreboards

        if (__instance.ParentPanel is MainMenuPanel) return true;
        if (selectedProfile == null) return true;

        CoreConstants.PLAYER_PROFILE[__instance.PlayerIndex] = profileSlot;
        __instance.SetProfile(selectedProfile);

        if (GameSFD.Handle.CurrentState == State.GameOffline)
        {
            var gameInfo = StateGameOffline.GameInfo;
            var gameUser = gameInfo.GetGameUserByUserIdentifier(gameInfo.GetLocalGameUserIdentifier(__instance.PlayerIndex));

            gameUser.Profile = selectedProfile;
            gameUser.Profile.Updated = true;
        }
        else if (GameSFD.Handle.CurrentState == State.Game && GameSFD.Handle.Client != null)
        {
            var profileChangeData = new ExNetMessage.ProfileChangeRequest.Data()
            {
                PlayerIndex = (byte)__instance.PlayerIndex,
                Profile = selectedProfile,
            };

            MessageHandler.Send(GameSFD.Handle.Client, ExMessageType.ProfileChangeRequest, profileChangeData);
        }

        return false;
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(FilmGrain), nameof(FilmGrain.Draw))]
    private static bool HideFilmGrain()
    {
        return !ExConfig.Get<bool>(ExSettingKey.HideFilmgrain);
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(KeyBindPanel), MethodType.Constructor)]
    private static void InsertRemainingLocalPlayerKeys(KeyBindPanel __instance)
    {
        // Add all the elements of player 5-8 keybinds, and then
        // shift the new keybind elements back (before the misc keys).
        // This way uses the original code and saves a lot of hassle.

        // TODO: make this a setting for people who dont want clutter?

        // FIXME: the input type of player 5 keeps resetting to Controller even
        // if it was set to Keyboard

        var originalElementCount = __instance.menu.Items.Count;
        var currentKeyBinds = new KeyBindPanel.PlayerKeyBindItems[8];
        for (int i = 0; i < 8; i++)
        {
            if (i < __instance.playerKeyBindings.Length)
            {
                currentKeyBinds[i] = __instance.playerKeyBindings[i];
            }
            else
            {
                var keyBind = new KeyBindPanel.PlayerKeyBindItems(i + 1);

                keyBind.SetupControls(__instance.menu, __instance, true);
                currentKeyBinds[i] = keyBind;
            }
        }

        __instance.playerKeyBindings = currentKeyBinds;

        var currentElementCount = __instance.menu.Items.Count;
        var miscElementCount = 1 + __instance.miscKeys.Length + 3; // Separator + Misc Keys + Empty Separator + OK + CANCEL

        var newKeyBindElements = __instance.menu.Items.GetRange(originalElementCount, currentElementCount - originalElementCount);
        __instance.menu.Items.RemoveRange(originalElementCount, currentElementCount - originalElementCount);
        __instance.menu.Items.InsertRange(originalElementCount - miscElementCount, newKeyBindElements);

        __instance.UpdateGamePadTexts();
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(KeyBindPanel), nameof(KeyBindPanel.keyBindPanel_OK))]
    private static void SetupRemainingLocalPlayerKeys()
    {
        for (int i = 5; i < VirtualKeyboard.BindedKeys.Length; i++)
        {
            VirtualKeyboard.BindedKeys[i].Setup();
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(JoinGamePanel), MethodType.Constructor, [typeof(GameServerInfo)])]
    private static void JoinGamePanelInsertExtraOptions(JoinGamePanel __instance)
    {
        //var connectAsSpectatorButton = new MenuItemButton(LanguageHelper.GetText("sfdct.button.connectspectator").ToUpperInvariant(), _ =>
        //{
        //    ClientHandler.NextConnectionAsSpectator = true;
        //    __instance.StartConnect();

        //    // dont keep ClientHandler.NextConnectionAsSpectator set to true if the panel gets closed,
        //    // or wasnt opened because of certain checks in JoinGamePanel.StartConnect

        //    if (__instance.SubPanel == null || __instance.SubPanel is not ConnectingPanel)
        //    {
        //        ClientHandler.NextConnectionAsSpectator = false;
        //        return;
        //    }

        //    var subPanelCancelButton = (MenuItemButton)((Menu)__instance.SubPanel.members[0]).Items.Last();
        //    subPanelCancelButton.ChooseEvent = (ControlEvents.ChooseEvent)Delegate.Combine(subPanelCancelButton.ChooseEvent, new ControlEvents.ChooseEvent((object _) =>
        //    {
        //        ClientHandler.NextConnectionAsSpectator = false;
        //    }));
        //}, "micon_ok");

        var requestServerMovementToggle = new MenuItemDropdown(LanguageHelper.GetText("sfdct.button.requestservermovement").ToUpperInvariant(), [LanguageHelper.GetText("general.on"), LanguageHelper.GetText("general.off")]);
        requestServerMovementToggle.SetStartValue(CoreConstants.CLIENT_REQUEST_SERVER_MOVEMENT ? 0 : 1);
        requestServerMovementToggle.DropdownItemVisibleCount = 2;

        Hooker.Add(requestServerMovementToggle, "ValueChangedEvent", new MenuItemValueChangedEvent(_ =>
        {
            bool value = requestServerMovementToggle.ValueId == 0;

            if (CoreConstants.CLIENT_REQUEST_SERVER_MOVEMENT != value)
            {
                CoreConstants.CLIENT_REQUEST_SERVER_MOVEMENT = value;
                SFDConfig.SaveConfig(SFDConfigSaveMode.Settings);
            }
        }));

        __instance.Height += Menu.ITEM_HEIGHT * 2;
        __instance.m_menu.Height += 1;
        __instance.m_menu.Add(requestServerMovementToggle, __instance.m_menu.ItemCount - 2);
        // __instance.m_menu.Add(connectAsSpectatorButton, __instance.m_menu.ItemCount - 2);
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameBrowserMenuItem), nameof(GameBrowserMenuItem.Game), MethodType.Setter)]
    private static void GameBrowserMenuItem_Setter_Game_Postfix_CustomServerColors(GameBrowserMenuItem __instance)
    {
        if (__instance.labels == null) return;
        if (__instance.m_game == null) return;

        //bool isInvalid = false;
        bool isSFR = false;
        bool isEmpty = false;
        bool isFull = false;

        //if (IsServerInfoInvalid(__instance.m_game))
        //{
        //    isInvalid = true;
        //}
        //else
        //{
        if (__instance.m_game.Version.StartsWith("v.2"))
        {
            isSFR = true;
        }

        if (__instance.m_game.Players <= 0)
        {
            isEmpty = true;
        }
        else if (__instance.m_game.Players >= __instance.m_game.MaxAvailableSlots)
        {
            isFull = true;
        }
        //}

        foreach (var label in __instance.labels)
        {
            if (isSFR)
            {
                label.Color = Globals.SFRServerColor;
            }

            //if (isInvalid)
            //{
            //    label.Color *= 0.25f;
            //    continue;
            //}

            if (isEmpty)
            {
                label.Color *= 0.5f;
                continue;
            }

            if (isFull)
            {
                label.Color *= 0.7f;
                continue;
            }
        }
    }

    //[HarmonyPostfix]
    //[HarmonyPatch(typeof(GameBrowserPanel), nameof(GameBrowserPanel.IncludeGameInFilter))]
    //private static void GameBrowserPanel_IncludeGameInFilter_Postfix_SecurityChecks(ref bool __result, GameServerInfo gameServer)
    //{
    //    if (!__result) return;

    //    __result = !IsServerInfoInvalid(gameServer);
    //}
}
