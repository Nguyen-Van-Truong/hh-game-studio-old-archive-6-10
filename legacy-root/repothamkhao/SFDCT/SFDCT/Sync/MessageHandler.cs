using HarmonyLib;
using Networking.LidgrenAdapter;
using SDR.Networking;
using SFD;

namespace SFDCT.Sync;

[HarmonyPatch]
internal static partial class MessageHandler
{
    internal static void Send(ClientServerBase owner, ExMessageType messageType, object information, NetConnection except = null, NetConnection single = null)
    {
        NetOutgoingMessage outgoingMessage;
        NET_DELIVERY delivery;

        if (owner is Client ownerClient)
        {
            outgoingMessage = Write(messageType, information, ownerClient.m_client.CreateMessage(), out delivery);

            ownerClient.m_client.SendMessage(outgoingMessage, delivery.Method, delivery.Channel);
        }
        else if (owner is Server ownerServer)
        {
            outgoingMessage = Write(messageType, information, ownerServer.m_server.CreateMessage(), out delivery);

            if (single == null)
            {
                ownerServer.m_server.SendToAll(outgoingMessage, except, delivery.Method, delivery.Channel);
            }
            else
            {
                ownerServer.m_server.SendMessage(outgoingMessage, single, delivery.Method, delivery.Channel);
            }
        }
    }

    internal static NetOutgoingMessage Write(ExMessageType messageType, object information, NetOutgoingMessage outgoingMessage, out NET_DELIVERY delivery)
    {
        NetMessage.WriteDataType(ExNetMessage.EX_MESSAGE_MESSAGE_TYPE, outgoingMessage);
        outgoingMessage.Write((byte)messageType);

        switch (messageType)
        {
            default:
                ConsoleOutput.ShowMessage(ConsoleOutputType.Error, $"Trying to write ExMessageType '{messageType}' not implemented!");
                break;
            case ExMessageType.ProfileChangeRequest:
                ExNetMessage.ProfileChangeRequest.Write((ExNetMessage.ProfileChangeRequest.Data)information, ref outgoingMessage);
                break;
            case ExMessageType.MouseStateChangeSignal:
                ExNetMessage.MouseServerStateUpdate.Write((ExNetMessage.MouseServerStateUpdate.Data)information, ref outgoingMessage);
                break;
            case ExMessageType.MouseClientUpdate:
                ExNetMessage.MouseClientUpdate.Write((ExNetMessage.MouseClientUpdate.Data)information, ref outgoingMessage);
                break;
        }

        delivery.Channel = ExNetMessage.EX_MESSAGE_NET_DELIVERY.Channel;
        delivery.Method = ExNetMessage.EX_MESSAGE_NET_DELIVERY.Method;

        return outgoingMessage;
    }
}
