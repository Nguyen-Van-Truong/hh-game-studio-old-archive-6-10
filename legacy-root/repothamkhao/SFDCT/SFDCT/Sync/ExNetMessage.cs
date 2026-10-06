using Microsoft.Xna.Framework;
using Networking.LidgrenAdapter;
using SFD;

namespace SFDCT.Sync;

internal static class ExNetMessage
{
    internal static readonly NET_DELIVERY EX_MESSAGE_NET_DELIVERY = new(NetDeliveryMethod.ReliableOrdered, 31);
    internal const MessageType EX_MESSAGE_MESSAGE_TYPE = (MessageType)33; // MessageTypes 33, 34 and 36 are unused

    internal static class ProfileChangeRequest
    {
        internal static Data Read(NetIncomingMessage incomingMessage)
        {
            var data = new Data()
            {
                PlayerIndex = incomingMessage.ReadByte(),
                Profile = NetMessage.PlayerProfileMessage.Read(incomingMessage, Profile.ValidateProfileType.CanEquip)
            };

            return data;
        }

        internal static NetOutgoingMessage Write(Data data, ref NetOutgoingMessage outgoingMessage)
        {
            outgoingMessage.Write(data.PlayerIndex);
            NetMessage.PlayerProfileMessage.Write(data.Profile, outgoingMessage);

            return outgoingMessage;
        }

        internal class Data
        {
            internal byte PlayerIndex;
            internal Profile Profile;
        }
    }

    internal static class MouseServerStateUpdate
    {
        internal static Data Read(NetIncomingMessage incomingMessage)
        {
            var data = new Data()
            {
                State = incomingMessage.ReadBoolean(),
            };

            return data;
        }

        internal static NetOutgoingMessage Write(Data data, ref NetOutgoingMessage outgoingMessage)
        {
            outgoingMessage.Write(data.State);

            return outgoingMessage;
        }

        internal struct Data
        {
            internal bool State;
        }
    }

    internal static class MouseClientUpdate
    {
        internal static Data Read(NetIncomingMessage incomingMessage)
        {
            var data = new Data();
            data.Buttons = incomingMessage.ReadByte();
            data.Box2DPosition = incomingMessage.ReadVector2Position();

            return data;
        }

        internal static NetOutgoingMessage Write(Data data, ref NetOutgoingMessage outgoingMessage)
        {
            outgoingMessage.Write(data.Buttons);
            outgoingMessage.WriteVector2Position(data.Box2DPosition);

            return outgoingMessage;
        }

        internal class Data
        {
            internal bool LeftMouseButtonPressed { get { return (Buttons & 0b00000001) != 0; } set { Buttons = (byte)(value ? (Buttons | 0b00000001) : (Buttons & 0b11111110)); } }
            internal bool RightMouseButtonPressed { get { return (Buttons & 0b00000010) != 0; } set { Buttons = (byte)(value ? (Buttons | 0b00000010) : (Buttons & 0b11111101)); } }
            internal bool ControlPressed { get { return (Buttons & 0b00000100) != 0; } set { Buttons = (byte)(value ? (Buttons | 0b00000100) : (Buttons & 0b11111011)); } }
            internal bool DeletePressed { get { return (Buttons & 0b00001000) != 0; } set { Buttons = (byte)(value ? (Buttons | 0b00001000) : (Buttons & 0b11110111)); } }

            internal Vector2 Box2DPosition;
            internal byte Buttons;
        }
    }
}
