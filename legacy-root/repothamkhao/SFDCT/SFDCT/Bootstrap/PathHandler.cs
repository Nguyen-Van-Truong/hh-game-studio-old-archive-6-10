using HarmonyLib;
using SFD;
using System.Reflection.Emit;

namespace SFDCT.Bootstrap;

/// <summary>
/// Since the executable is not in SFD's root directory, SFD's code tries to use invalid paths
/// like "Superfighters Deluxe/*/Content/Data/", crashing the game when it tries to load assets
/// or verify some directories exist
/// </summary>
[HarmonyPatch]
internal static class PathHandler
{
    [HarmonyTranspiler]
    [HarmonyPatch(typeof(SFDPaths), nameof(SFDPaths.SetupPaths))]
    private static IEnumerable<CodeInstruction> FixExecutablePath(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        for (int i = 0; i < code.Count; i++)
        {
            var instruction = code[i];

            if (instruction.opcode.Equals(OpCodes.Stsfld) && instruction.operand.Equals(AccessTools.Field(typeof(SFDPaths), nameof(SFDPaths.ExecutablePath))))
            {
                // fix 'SFDPaths.ExecutablePath' not pointing to 'Superfighters Deluxe'

                code.RemoveRange(0, i);
                code.Insert(0, new(OpCodes.Ldstr, Globals.Paths.SFD));
                i = 2;
                break;
            }
        }

        return code;
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(SFDPaths), nameof(SFDPaths.GetFullContentPath))]
    private static void FixGetFullContentPath(ref string __result, string path)
    {
        // this is only used in 'ContentLoader.Load', changing it to an absolute path
        // fixes content loading without patching a lot more code
        __result = Path.Combine(Globals.Paths.SFD, "Content", path);
    }

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(GameSFD), MethodType.Constructor)]
    private static IEnumerable<CodeInstruction> FixContentPath(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        foreach (var instruction in code)
        {
            if (instruction.operand != null && instruction.operand.Equals("Content"))
            {
                // change 'ContentManager.RootDirectory' to point to 'Superfighters Deluxe/Content'
                // instead of 'Superfighters Deluxe/*/Content', this solves the loading of certain
                // assets like effects and fonts that are loaded using regular 'Content.Load'

                instruction.operand = Path.Combine(Globals.Paths.SFD, "Content");
                break;
            }
        }

        return code;
    }
}
