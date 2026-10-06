using HarmonyLib;
using Microsoft.Xna.Framework;
using Networking.LidgrenAdapter;
using SFD;

namespace SFDCT.Sync;

[HarmonyPatch]
internal static class ClientHandler
{
    //internal static bool NextConnectionAsSpectator = false;
    internal static bool OnlineMouseState = false;
    internal static float OnlineMouseUpdateTime = 0.0f;
    internal static Vector2 OnlineMouseBox2DPosition = Vector2.Zero;

    internal static void HandleExMessage(Client client, NetMessage.MessageData messageData, NetIncomingMessage incomingMessage)
    {
        var messageType = (ExMessageType)incomingMessage.ReadByte();

        switch (messageType)
        {
            default:
                ConsoleOutput.ShowMessage(ConsoleOutputType.Error, $"Client: ExMessageType '{messageType}' not implemented!");
                break;
            case ExMessageType.MouseStateChangeSignal:
                var mouseStateData = ExNetMessage.MouseServerStateUpdate.Read(incomingMessage);

                OnlineMouseState = mouseStateData.State;
                break;
        }
    }

    internal static void UpdateWorld(Client client, GameWorld world, float chunkMs, float totalMs, bool isLast, bool isFirst)
    {
        var currentState = world.m_game.CurrentState;
        if (currentState is State.Game && OnlineMouseState && isLast)
        {
            OnlineMouseUpdateTime -= totalMs;
            if (OnlineMouseUpdateTime <= 0)
            {
                OnlineMouseUpdateTime = 1000f / CoreConstants.NET.MESSAGES_PER_SECOND_SERVER;

                var anyAction = SFD.Input.Mouse.LeftButton.IsPressed || SFD.Input.Mouse.RightButton.IsPressed || SFD.Input.Keyboard.IsCtrlDown() || SFD.Input.Keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.Delete);

                var currentMouseBox2DPosition = world.GetMouseBox2DPosition();
                if (Vector2.DistanceSquared(OnlineMouseBox2DPosition, currentMouseBox2DPosition) > 0 || anyAction)
                {
                    OnlineMouseBox2DPosition = currentMouseBox2DPosition;

                    var data = new ExNetMessage.MouseClientUpdate.Data()
                    {
                        LeftMouseButtonPressed = SFD.Input.Mouse.LeftButton.IsPressed,
                        RightMouseButtonPressed = SFD.Input.Mouse.RightButton.IsPressed,
                        ControlPressed = SFD.Input.Keyboard.IsCtrlDown(),
                        DeletePressed = SFD.Input.Keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.Delete),
                        Box2DPosition = OnlineMouseBox2DPosition,
                    };

                    MessageHandler.Send(world.m_game.Client, ExMessageType.MouseClientUpdate, data);
                }
            }
        }
    }

    //[HarmonyPrefix]
    //[HarmonyPatch(typeof(NetMessage.Connection.DiscoveryConnectRequest), nameof(NetMessage.Connection.DiscoveryConnectRequest.Write))]
    //private static void ChangeDiscoveryConnectRequest(NetMessage.Connection.DiscoveryConnectRequest.Data dataToWrite)
    //{
    //    if (NextConnectionAsSpectator)
    //    {
    //        NextConnectionAsSpectator = false;

    //        dataToWrite.AsSpectators = true;
    //    }
    //}

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Client), nameof(Client.HandleDataMessage))]
    private static bool CheckExMessage(Client __instance, NetMessage.MessageData messageData, NetIncomingMessage msg)
    {
        if (messageData.MessageType != ExNetMessage.EX_MESSAGE_MESSAGE_TYPE) return true;

        HandleExMessage(__instance, messageData, msg);
        return false;
    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Client), nameof(Client.Start), [typeof(bool)])]
    private static void ClientStart(Client __instance)
    {

    }

    [HarmonyPrefix]
    [HarmonyPatch(typeof(Client), nameof(Client.Shutdown))]
    private static void ClientShutdown(Client __instance)
    {
        //NextConnectionAsSpectator = false;
        OnlineMouseState = false;
        OnlineMouseUpdateTime = 0.0f;
    }
}
