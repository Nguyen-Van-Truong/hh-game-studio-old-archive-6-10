using HarmonyLib;
using SFD;
using SFD.Tiles;
using System.Collections.Concurrent;
using System.Reflection.Emit;

namespace SFDCT.Assets;

[HarmonyPatch]
internal static class TexturesLoader
{
    internal static bool Load(GameSFD game)
    {
        game.ShowLoadingText(LanguageHelper.GetText("loading.textures"));

        var contents = SubContent.GetContents().Where(content => Directory.Exists(Path.Combine(content.Directory, SFDPaths.DATA_IMAGES))).Reverse();

        var totalTextures = new ConcurrentDictionary<string, string>();

        // get all texture files and their keys in reversed loading order,
        // so we dont keep duplicates from lower priority content
        foreach (var content in contents)
        {
            Parallel.ForEach(Directory.EnumerateFiles(Path.Combine(content.Directory, SFDPaths.DATA_IMAGES), "*.png", SearchOption.AllDirectories), delegate (string textureFilePath)
            {
                var textureKey = Path.GetFileNameWithoutExtension(textureFilePath).ToUpperInvariant();

                if (totalTextures.ContainsKey(textureKey)) return;
                totalTextures.TryAdd(textureKey, textureFilePath);
            });
        }

        // actually read and load unique textures
        int total = 0;
        int current = 0;

        GameSFD.Handle.SetLoadingProgress(current, total);

        Parallel.ForEach(totalTextures.Values, delegate (string path)
        {
            ConsoleOutput.ShowMessage(ConsoleOutputType.Loading, $"Loading texture file: {path}");

            Textures.m_tileTextures.Load(path);

            Interlocked.Increment(ref current);
            GameSFD.Handle.SetLoadingProgress(current, total);
        });

        GameSFD.Handle.SetLoadingProgress(0, 0);

        return true;
    }

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(TileTextures), nameof(TileTextures.Load))]
    private static IEnumerable<CodeInstruction> TileTexturesAcceptAbsolutePath(IEnumerable<CodeInstruction> instructions)
    {
        // this patch is to support absolute paths instead
        // of only relative paths to SFD's content folder.
        // this makes it possible to re-use the method.

        // change 'Constants.Paths.GetContentAssetPathFromFullPath' to use the unmodified path instead
        instructions.ElementAt(23).opcode = OpCodes.Nop;

        // assume the PNG texture in documents never exists
        instructions.ElementAt(69).opcode = OpCodes.Nop;
        instructions.ElementAt(70).opcode = OpCodes.Ldc_I4_0;

        return instructions;
    }
}
