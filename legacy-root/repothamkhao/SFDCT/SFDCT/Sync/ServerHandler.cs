using HarmonyLib;
using Networking.LidgrenAdapter;
using SDR.Networking;
using SFD;
using SFDCT.Game;

namespace SFDCT.Sync;

[HarmonyPatch]
internal static class ServerHandler
{
    internal const float SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_TRUE = -1f;
    internal const float SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_FALSE = -2f;

    internal static bool OnlineMouseState = false;
    internal static List<OnlineMouse> OnlineMouseList = [];

    internal static void SyncMouseState(Server server)
    {
        var data = new ExNetMessage.MouseServerStateUpdate.Data()
        {
            State = OnlineMouseState,
        };

        MessageHandler.Send(server, ExMessageType.MouseStateChangeSignal, data);
    }

    internal static void HandleExDataMessage(Server server, NetMessage.MessageData messageData, NetIncomingMessage incomingMessage, NetConnection connection)
    {
        GameConnectionTag incomingTag = connection.GameConnectionTag();

        var messageType = (ExMessageType)incomingMessage.ReadByte();
        switch (messageType)
        {
            default:
                ConsoleOutput.ShowMessage(ConsoleOutputType.Error, $"Server: ExMessageType '{messageType}' not implemented!");
                break;
            case ExMessageType.MouseClientUpdate:
                if (incomingTag == null) break;
                if (!incomingTag.IsModerator) break;

                var mouseUpdateData = ExNetMessage.MouseClientUpdate.Read(incomingMessage);

                var onlineMouse = OnlineMouseList.Where(o => o.GameConnectionTag() == incomingTag).FirstOrDefault();
                if (onlineMouse == null)
                {
                    onlineMouse = new OnlineMouse(incomingTag);
                    OnlineMouseList.Add(onlineMouse);
                }

                onlineMouse.NetUpdate = NetTime.Now;
                onlineMouse.SetData(mouseUpdateData);
                break;
            case ExMessageType.ProfileChangeRequest:
                if (incomingTag == null) break;

                var profileChangeData = ExNetMessage.ProfileChangeRequest.Read(incomingMessage);

                if (profileChangeData.PlayerIndex >= incomingTag.GameUsers.Length) break;
                if (profileChangeData.Profile == null) break;

                var gameUser = incomingTag.GameUsers[profileChangeData.PlayerIndex];
                if (gameUser == null) break;

                gameUser.Profile = profileChangeData.Profile;
                gameUser.Profile.Updated = true;

                server.SyncGameUserInfo(gameUser);

                if (gameUser.GameSlot != null)
                {
                    server.SyncGameSlotInfo(gameUser.GameSlot);
                }

                break;
        }
    }

    internal static void UpdateWorld(Server server, GameWorld world, float chunkMs, float totalMs, bool isLast, bool isFirst)
    {
        var currentState = world.m_game.CurrentState;
        if (currentState is State.Game && OnlineMouseState && isLast)
        {
            for (int i = OnlineMouseList.Count - 1; i >= 0; i--)
            {
                var onlineMouse = OnlineMouseList[i];
                if (onlineMouse.IsInactive)
                {
                    onlineMouse.Dispose();
                    OnlineMouseList.RemoveAt(i);
                    continue;
                }

                onlineMouse.Update(world);
            }
        }
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Server), nameof(Server.updateForcedServerMovement))]
    private static void PreServerMovementOverride(Server __instance, float time, ref Dictionary<GameConnectionTag, bool> __state)
    {
        if (__instance.m_updateForcedServerMovementTime - time > 0f) return;

        // this way we can check and keep the forced server movement states without
        // having to completely re-implement the original method. just before the method
        // and restore the forced ones after the method

        __state = [];

        lock (Server.ServerUpdateLockObject)
        {
            foreach (var connection in __instance.m_server.GetNetConnections(true))
            {
                var tag = connection.GameConnectionTag();

                if (tag == null) continue;

                if (tag.ForcedServerMovementToggleTime == SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_FALSE)
                {
                    __state.Add(tag, false);
                }
                else if (tag.ForcedServerMovementToggleTime == SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_TRUE)
                {
                    __state.Add(tag, false);
                }
            }
        }
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(Server), nameof(Server.updateForcedServerMovement))]
    private static void PostServerMovementOverride(ref Dictionary<GameConnectionTag, bool> __state)
    {
        if (__state == null) return;

        foreach (var kvp in __state)
        {
            kvp.Key.ForcedServerMovementToggleTime = kvp.Value ? SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_TRUE : SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_FALSE;
            kvp.Key.ForceServerMovement = kvp.Value;
        }
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Server), nameof(Server.HandleDataMessage))]
    private static bool CheckExMessage(Server __instance, NetMessage.MessageData messageData, NetIncomingMessage msg, NetConnection netConnection)
    {
        if (messageData.MessageType != ExNetMessage.EX_MESSAGE_MESSAGE_TYPE) return true;

        HandleExDataMessage(__instance, messageData, msg, netConnection);
        return false;
    }

    //internal static bool HandleConnectRequest(Server server, NetConnection connection, ref NetMessage.Connection.ConnectRequest.Data connectData)
    //{
    //    if (connectData.AsSpectators && connectData.ConnectingUserCount > 1)
    //    {
    //        connection.Disconnect(Constants.NET.SERVER_BYE_MESSAGE);
    //        return true;
    //    }

    //    return false;
    //}

    //[HarmonyTranspiler]
    //[HarmonyPatch(typeof(Server), nameof(Server.DoReadRun))]
    //private static IEnumerable<CodeInstruction> Server_DoReadRun_Transpiler_SpectatorFix(ILGenerator il, IEnumerable<CodeInstruction> instructions)
    //{
    //    var code = new List<CodeInstruction>(instructions);

    //    // SFD accepts spectators that aren't the host, however 'JoinedAsSpectator'
    //    // is only set for the host if 'IsServer' is true, if 'IsGame' is true
    //    // then SFD hard codes 'JoinedAsSpectator' as false even though the
    //    // connection data may have 'AsSpectator' as true, and it will be accepted
    //    var gameUserLocalIndex = 37;
    //    var connectDataLocalIndex = 19;
    //    var senderConnectionLocalIndex = 18;

    //    var isGameInstruction = code[773];
    //    var isServerInstruction = code[779];
    //    var isLocalHostInstruction = code[455];
    //    var whileLoopEndInstruction = code[1686];
    //    var afterLobbyHelpTextInstruction = code[872 + 1];
    //    var afterReadAccountDataTrueInstruction = code[611 + 1];
    //    var afterNotNegotiatedConnectionInstruction = code[613 + 1];

    //    var asSpectatorInstructions = new List<CodeInstruction>
    //    {
    //        new(OpCodes.Ldloc_S, gameUserLocalIndex),
    //        new(OpCodes.Ldloc_S, connectDataLocalIndex), // connectData
    //        new(OpCodes.Ldfld, AccessTools.Field(typeof(NetMessage.Connection.ConnectRequest.Data), nameof(NetMessage.Connection.ConnectRequest.Data.AsSpectators))),
    //        new(OpCodes.Callvirt, AccessTools.PropertySetter(typeof(GameUser), nameof(GameUser.JoinedAsSpectator)))
    //    };

    //    // Replace 'false'
    //    var isGameIndex = code.IndexOf(isGameInstruction);
    //    code.RemoveRange(isGameIndex, 3);
    //    code.InsertRange(isGameIndex, asSpectatorInstructions);

    //    // Replace 'flag2 &&'
    //    var isServerIndex = code.IndexOf(isServerInstruction);
    //    code.RemoveRange(isServerIndex, 8);
    //    code.InsertRange(isServerIndex, asSpectatorInstructions);

    //    // This is after reading connectData, doing some vanilla checks,
    //    // but before game slots are searched
    //    var continueWhileLoopLabel = il.DefineLabel();

    //    whileLoopEndInstruction.labels.Add(continueWhileLoopLabel);

    //    var handleConnectRequestInstructions = new List<CodeInstruction>
    //    {
    //        new(OpCodes.Ldarg_0), // this (Server)
    //        new(OpCodes.Ldloc_S, senderConnectionLocalIndex), // ref senderConnection
    //        new(OpCodes.Ldloca_S, connectDataLocalIndex), // ref data
    //        new(OpCodes.Call, AccessTools.Method(typeof(ServerHandler), nameof(HandleConnectRequest))),
    //        new(OpCodes.Brtrue, continueWhileLoopLabel),
    //    };

    //    var isLocalHostIndex = code.IndexOf(isLocalHostInstruction);
    //    code.InsertRange(isLocalHostIndex, handleConnectRequestInstructions);

    //    // Add help text
    //    // ChatMessage.Show(LanguageHelper.GetText("sfdct.menu.lobby.helpText"), Color.Yellow, "", false);
    //    var afterLobbyHelpTextIndex = code.IndexOf(afterLobbyHelpTextInstruction);
    //    var showCTHelpTextInstructions = new List<CodeInstruction>
    //    {
    //        new(OpCodes.Ldstr, "sfdct.menu.lobby.helpText"),
    //        new(OpCodes.Call, AccessTools.Method(typeof(LanguageHelper), nameof(LanguageHelper.GetText), [typeof(string)])),
    //        new(OpCodes.Call, AccessTools.PropertyGetter(typeof(Color), nameof(Color.Yellow))),
    //        new(OpCodes.Ldstr, ""),
    //        new(OpCodes.Ldc_I4_0),
    //        new(OpCodes.Call, AccessTools.Method(typeof(ChatMessage), nameof(ChatMessage.Show), [typeof(string), typeof(Color), typeof(string), typeof(bool)]))
    //    };

    //    code.InsertRange(afterLobbyHelpTextIndex, showCTHelpTextInstructions);

    //    // Skip checking ReadAccountData if senderConnection is
    //    // the local host, this fixes the dedicated preview being denied
    //    // because the server user is not given an account name
    //    var skipReadAccountDataLabel = il.DefineLabel();

    //    afterNotNegotiatedConnectionInstruction.labels.Add(skipReadAccountDataLabel);

    //    var isReadAccountDataTrueIndex = code.IndexOf(afterReadAccountDataTrueInstruction);
    //    var skipReadAccountDataInstructions = new List<CodeInstruction>
    //    {
    //        new(OpCodes.Ldloc_S, senderConnectionLocalIndex),
    //        new(OpCodes.Call, AccessTools.Method(typeof(LidgrenNetworkExtensions), nameof(LidgrenNetworkExtensions.IsLocalHost), [typeof(NetConnection)])),
    //        new(OpCodes.Brtrue, skipReadAccountDataLabel)
    //    };

    //    code.InsertRange(isReadAccountDataTrueIndex, skipReadAccountDataInstructions);

    //    return code;
    //}

    [HarmonyPostfix]
    [HarmonyPatch(typeof(Server), nameof(Server.HandleChatMessage))]
    private static void Server_HandleChatMessage_Postfix_SecurityChecks(ref bool __result, GameUser senderGameUser, string stringMsg)
    {
        // Already rejected
        if (!__result) return;

        // Long chat messages can cause stuttering on clients,
        // make the server reject those messages as spam using
        // the chat's textbox max character limit
        var maxChars = GameChat.m_textbox.maxChars;
        __result = stringMsg.Length <= maxChars;
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Server), nameof(Server.Start))]
    private static void ServerStart(Server __instance)
    {

    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Server), nameof(Server.Shutdown), [typeof(bool)])]
    private static void ServerShutdown(Server __instance)
    {
        OnlineMouseState = false;
        OnlineMouseList.Clear();
    }
}
