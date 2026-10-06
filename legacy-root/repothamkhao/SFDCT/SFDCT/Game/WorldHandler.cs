using HarmonyLib;
using SFD;
using SFDCT.Configuration;
using SFDCT.Sync;
using System.Reflection.Emit;

namespace SFDCT.Game;

[HarmonyPatch]
internal static class WorldHandler
{
    /// <summary>
    ///     For unknown reasons players tempt to crash when joining a game.
    ///     This is caused because a collection is being modified during its iteration.
    ///     Therefore we iterate the collection backwards so it can be modified without throwing an exception.
    /// </summary>
    //[HarmonyPrefix]
    //[HarmonyPatch(typeof(GameWorld), nameof(GameWorld.FinalizeProperties))]
    //private static bool GameWorld_FinalizeProperties_Prefix_Cleanup(GameWorld __instance)
    //{
    //    __instance.b2_settings.timeStep = 0f;
    //    __instance.Step(__instance.b2_settings);

    //    for (int i = __instance.DynamicObjects.Count - 1; i >= 0; i--)
    //    {
    //        __instance.DynamicObjects.ElementAt(i).Value.FinalizeProperties();
    //    }

    //    for (int i = __instance.StaticObjects.Count - 1; i >= 0; i--)
    //    {
    //        __instance.StaticObjects.ElementAt(i).Value.FinalizeProperties();
    //    }

    //    return false;
    //}

    //[HarmonyTranspiler]
    //[HarmonyPatch(typeof(GameWorld), nameof(GameWorld.UpdateGameOverData), [typeof(bool)])]
    //private static IEnumerable<CodeInstruction> WorldSpectatorGameOverFix(IEnumerable<CodeInstruction> instructions)
    //{
    //    var code = new List<CodeInstruction>(instructions);

    //    // The original IL code uses LINQ keywords and checks
    //    // if the users are 'SpectatingWhileWaitingToPlay',
    //    // add 'JoinedAsSpectator'

    //    var enumeratorAnyInstruction = code[554];
    //    enumeratorAnyInstruction.operand = AccessTools.Method(typeof(UserHandler), nameof(UserHandler.IsNotJoinedAsSpectatorAndIsSpectatingWhileWaitingToPlay));

    //    return code;
    //}

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(GameWorld), nameof(GameWorld.Update))]
    private static IEnumerable<CodeInstruction> WorldHealthSaturation(IEnumerable<CodeInstruction> instructions)
    {
        bool flag1 = false;
        bool flag2 = false;

        // this is a loop to avoid using specific index that can change
        // after an update that changes the Update method

        foreach (var instruction in instructions)
        {
            if (instruction.opcode == OpCodes.Call && instruction.operand?.Equals(AccessTools.Method(typeof(Camera), nameof(Camera.Update))) == true)
            {
                flag1 = true;
            }

            if (flag1)
            {
                // the only instances of loading 0.25f and 0.7f in the instructions are
                // to use them for the saturation calculations

                if (instruction.opcode == OpCodes.Ldc_R4 && instruction.operand.Equals(0.25f) == true)
                {
                    instruction.operand = ExConfig.Get<float>(ExSettingKey.LowHealthThreshold);
                }
                else if (instruction.opcode == OpCodes.Ldc_R4 && instruction.operand.Equals(0.7f) == true)
                {
                    instruction.operand = ExConfig.Get<float>(ExSettingKey.LowHealthSaturationFactor);
                }
                else if (instruction.opcode == OpCodes.Ldc_R4 && instruction.operand.Equals(400f) == true)
                {
                    flag2 = true;
                    // instruction.operand = ExConfig.Get<float>(ExSettingKey.LowHealthHeartbeatMaximumDelay);
                }
            }

            if (flag2)
            {
                if (instruction.opcode == OpCodes.Ldc_R4 && instruction.operand.Equals(1f) == true)
                {
                    flag2 = false;
                    // instruction.operand = ExConfig.Get<float>(ExSettingKey.LowHealthHeartbeatVolume);
                }
            }
        }

        return instructions;
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameWorld), nameof(GameWorld.Update))]
    private static void UpdateWorld(GameWorld __instance, float chunkMs, float totalMs, bool isLast, bool isFirst)
    {
        if (__instance.GameOwner == GameOwnerEnum.Local)
        {
            if (__instance.m_game.CurrentState is State.GameOffline && ServerHandler.OnlineMouseState && isLast)
            {
                __instance.UpdateDebugMouse();
            }
        }
        else if (__instance.GameOwner == GameOwnerEnum.Server)
        {
            ServerHandler.UpdateWorld(__instance.m_game.Server, __instance, chunkMs, totalMs, isLast, isFirst);
        }
        else if (__instance.GameOwner == GameOwnerEnum.Client)
        {
            ClientHandler.UpdateWorld(__instance.m_game.Client, __instance, chunkMs, totalMs, isLast, isFirst);
        }
    }
}