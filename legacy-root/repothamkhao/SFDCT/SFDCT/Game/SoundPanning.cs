using HarmonyLib;
using Microsoft.Xna.Framework;
using SFD;
using SFD.Projectiles;
using SFD.Sounds;
using SFDCT.Configuration;
using System.Reflection.Emit;

namespace SFDCT.Game;

[HarmonyPatch]
internal static class SoundPanning
{
    [HarmonyTranspiler]
    [HarmonyPatch(typeof(SoundHandler), nameof(SoundHandler.PlaySound), [typeof(string), typeof(Vector2), typeof(float), typeof(GameWorld)])]
    private static IEnumerable<CodeInstruction> PanningPrePlaySound(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        // call SoundPanning.PlayGlobalSound with all parameters instead of SoundHandler.PlayGlobalSound,
        // since the original method only passes it the sound id and volume modifier

        code[33].operand = AccessTools.Method(typeof(SoundPanning), nameof(PlayGlobalSound), [typeof(string), typeof(Vector2), typeof(float), typeof(GameWorld)]);
        code.Insert(33, new(OpCodes.Ldarg_3));
        code.Insert(32, new(OpCodes.Ldarg_1));

        return code;
    }

    internal static void CalculatePanning(GameWorld world, Vector2 position, out float panning)
    {
        panning = 0f;

        var invalidLocalPlayer = GameInfo.LocalPlayerCount > 1 || world.PrimaryLocalPlayer == null || world.PrimaryLocalPlayer.IsDisposed || world.PrimaryLocalPlayer.IsRemoved || world.PrimaryLocalPlayer.IsDead;
        if (position == Vector2.Zero) return;

        if (ExConfig.Get<bool>(ExSettingKey.SoundPanningEnabled))
        {
            if (invalidLocalPlayer || ExConfig.Get<bool>(ExSettingKey.SoundPanningForceScreenSpace))
            {
                panning = (Camera.ConvertWorldToScreenX(position.X) - Resolution.GAME_WIDTHf * 0.5f) / Resolution.GAME_WIDTHf * 0.5f;
            }
            else
            {
                var spWorldThreshold = (float)ExConfig.Get<int>(ExSettingKey.SoundPanningInworldThreshold);
                var spWorldDistance = (float)ExConfig.Get<int>(ExSettingKey.SoundPanningInworldDistance);

                var distanceX = position.X - world.PrimaryLocalPlayer.Position.X;

                if (Math.Abs(distanceX) >= spWorldThreshold)
                {
                    panning = (distanceX - spWorldThreshold) / spWorldDistance;
                }
            }

            panning = MathHelper.Clamp(panning * ExConfig.Get<float>(ExSettingKey.SoundPanningStrength), -1f, 1f);
        }
    }

    public static void PlayGlobalSound(string id, Vector2 position, float volumeModifier, GameWorld world)
    {
        if (SoundHandler.m_soundsDisabled) return;
        if (id == "NONE") return;

        SoundHandler.SoundEffectGroup group = SoundHandler.soundEffects.Find(id);
        if (group == null)
        {
            ConsoleOutput.ShowMessage(ConsoleOutputType.Warning, $"Sound '{id} ' could not be found");
            return;
        }


        var pan = 0f;
        var volume = 1f;

        CalculatePanning(world, position, out pan);

        var pitch = world.SlowmotionHandler.SlowmotionModifier - 1f;

        SoundHandler.PlaySoundEffectGroup(group, volume * group.VolumeModifier * volumeModifier, pitch, pan);
    }

    // A lot of objects in SFD play sounds and don't specify their world position,
    // so they are played as a global sound, these patches fix a majority of these,
    // but not all.

    // TODO:
    // re-add more patches to fix all the remaining cases of this (projectiles and some specific objects)

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(ObjectData), nameof(ObjectData.OnDestroyGenericCheck))]
    private static IEnumerable<CodeInstruction> ObjectDestroySoundPositionFix(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        code.Insert(29, new(OpCodes.Ldarg_0));
        code.Insert(30, new(OpCodes.Call, AccessTools.Method(typeof(ObjectData), nameof(ObjectData.GetWorldPosition))));
        code.ElementAt(33).operand = AccessTools.Method(typeof(SoundHandler), nameof(SoundHandler.PlaySound), [typeof(string), typeof(Vector2), typeof(GameWorld)]);

        return code;
    }

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(Projectile), nameof(Projectile.DefaultHitObject))]
    private static IEnumerable<CodeInstruction> ProjectileHitSoundPositionFix(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        code.ElementAt(33).operand = AccessTools.Method(typeof(SoundHandler), nameof(SoundHandler.PlaySound), [typeof(string), typeof(Vector2), typeof(GameWorld)]);
        code.Insert(31, new CodeInstruction(OpCodes.Ldarg_0));
        code.Insert(32, new CodeInstruction(OpCodes.Call, AccessTools.PropertyGetter(typeof(Projectile), nameof(Projectile.Position))));

        return code;
    }

    [HarmonyTranspiler]
    [HarmonyPatch(typeof(Projectile), nameof(Projectile.DefaultHitPlayer))]
    private static IEnumerable<CodeInstruction> ProjectileHitPlayerSoundPositionFix(IEnumerable<CodeInstruction> instructions)
    {
        var code = new List<CodeInstruction>(instructions);

        code.ElementAt(22).operand = AccessTools.Method(typeof(SoundHandler), nameof(SoundHandler.PlaySound), [typeof(string), typeof(Vector2), typeof(GameWorld)]);
        code.Insert(20, new CodeInstruction(OpCodes.Ldarg_0));
        code.Insert(21, new CodeInstruction(OpCodes.Call, AccessTools.PropertyGetter(typeof(Projectile), nameof(Projectile.Position))));

        return code;
    }
}
