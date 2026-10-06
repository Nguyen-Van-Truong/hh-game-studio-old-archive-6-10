namespace SFDCT.Game;

//[HarmonyPatch]
//internal static class DSHandler
//{
//    [HarmonyPostfix]
//    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.StateKeyDownEvent))]
//    private static void DSHomeKeyDown(Keys key)
//    {
//        if (GameSFD.Handle.GetRunningState() is not StateDSHome state) return;

//        KeyEvent(true, key, state);
//    }

//    [HarmonyPostfix]
//    [HarmonyPatch(typeof(GameSFD), nameof(GameSFD.StateKeyUpEvent))]
//    private static void DSHomeKeyUp(Keys key)
//    {
//        if (GameSFD.Handle.GetRunningState() is not StateDSHome state) return;

//        KeyEvent(false, key, state);
//    }

//    private static void KeyEvent(bool down, Keys key, StateDSHome state)
//    {
//        Client client = state.m_game?.Client;

//        if (client != null)
//        {
//            if (down)
//            {
//                client.KeyDownEvent(key);
//            }
//            else
//            {
//                client.KeyUpEvent(key);
//            }
//        }
//    }
//}
