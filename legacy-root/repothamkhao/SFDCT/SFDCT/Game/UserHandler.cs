using HarmonyLib;

namespace SFDCT.Game;

[HarmonyPatch]
internal static class UserHandler
{
    //    [HarmonyPrefix]
    //    [HarmonyPatch(typeof(GameInfo), nameof(GameInfo.TotalGameUserCount), MethodType.Getter)]
    //    private static bool FixSpectatorCheck(GameInfo __instance, ref int __result)
    //    {
    //        // the original method only checks if the user is not the dedicated server preview,
    //        // counting other users joined as spectators (that are not the host) as normal users

    //        __result = __instance.GetGameUsers().Count(u => u.IsUser && !u.JoinedAsSpectator);
    //        return false;
    //    }

    //[HarmonyPostfix]
    //[HarmonyPatch(typeof(GameUser), nameof(GameUser.IsDedicatedPreview), MethodType.Getter)]
    //private static void GameUser_Getter_IsDedicatedPreview_Postfix_ChangeDSCheck(GameUser __instance, ref bool __result)
    //{
    //    // The server creates a "local" and "remote" at
    //    // 'Server.SetupServerUsers()', these game users
    //    // are used by the dedicated server preview, they
    //    // count as the host, join as a spectator, have
    //    // an empty account name and their user identifiers
    //    // are set to 1

    //    __result = __result && __instance.UserIdentifier == 1;
    //}

    //[HarmonyPostfix]
    //[HarmonyPatch(typeof(GameUser), nameof(GameUser.CanWin), MethodType.Getter)]
    //private static void GameUser_Getter_CanWin_Postfix_SpectatorFix(GameUser __instance, ref bool __result)
    //{
    //    // Add a check for regular spectators, they shouldn't be able to win
    //    // because they wont be spawned next match

    //    __result = __result && !__instance.JoinedAsSpectator;
    //}

    //internal static bool IsNotJoinedAsSpectatorAndIsSpectatingWhileWaitingToPlay(GameUser user)
    //{
    //    return !user.JoinedAsSpectator && user.SpectatingWhileWaitingToPlay;
    //}
}
