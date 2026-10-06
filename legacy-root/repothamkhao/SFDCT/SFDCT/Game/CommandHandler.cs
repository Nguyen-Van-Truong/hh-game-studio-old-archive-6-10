using HarmonyLib;
using Microsoft.Xna.Framework;
using SFD;
using SFD.Core;
using SFD.GUI.Text;
using SFD.Parser;
using SFD.Voting;
using SFDCT.Bootstrap;
using SFDCT.Sync;
using Color = Microsoft.Xna.Framework.Color;

namespace SFDCT.Game;

[HarmonyPatch]
internal static class CommandHandler
{
    [HarmonyPrefix]
    [HarmonyPatch(typeof(GameInfo), nameof(GameInfo.HandleCommand), typeof(ProcessCommandArgs))]
    private static bool PreHandleCommand(ref bool __result, GameInfo __instance, ProcessCommandArgs args)
    {
        if (__instance.GameOwner == GameOwnerEnum.Client || __instance.GameOwner == GameOwnerEnum.Local)
        {
            if (PreHandleClient(__instance, args))
            {
                __result = true;
                return false;
            }
        }

        if (__instance.GameOwner == GameOwnerEnum.Server || __instance.GameOwner == GameOwnerEnum.Local)
        {
            if (PreHandleServer(__instance, args))
            {
                __result = true;
                return false;
            }
        }

        return true;
    }

    [HarmonyPostfix]
    [HarmonyPatch(typeof(GameInfo), nameof(GameInfo.HandleCommand), typeof(ProcessCommandArgs))]
    private static void PostHandleCommand(ref bool __result, GameInfo __instance, ProcessCommandArgs args)
    {
        if (__instance.GameOwner == GameOwnerEnum.Client || __instance.GameOwner == GameOwnerEnum.Local)
        {
            PostHandleClient(__instance, args, __result);
        }

        if (__instance.GameOwner == GameOwnerEnum.Server || __instance.GameOwner == GameOwnerEnum.Local)
        {
            PostHandleServer(__instance, args, __result);
        }
    }

    internal static bool IsAndCanUseModeratorCommand(ProcessCommandArgs args, params string[] commands) => args.IsCommand(commands) && args.CanUseModeratorCommand(commands);

    internal static void ProcessCommandFile(ref ProcessCommandArgs args, GameInfo gameInfo, string fileName)
    {
        fileName = fileName.Trim();
        fileName = fileName.Replace('/', Path.DirectorySeparatorChar).Replace('\\', Path.DirectorySeparatorChar);

        try
        {
            string filePath = Path.Combine(Globals.Paths.Commands, fileName);
            filePath = Path.GetFullPath(filePath);
            filePath = Path.ChangeExtension(filePath, ".txt");

            if (!File.Exists(filePath))
            {
                args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.exec.fail.nofile"), Color.Red, args.SenderGameUser));
                return;
            }

            string[] fileLines = File.ReadAllLines(filePath);

            foreach (string line in fileLines)
            {
                string command = line.Trim();

                if (string.IsNullOrWhiteSpace(command)) continue;
                if (string.IsNullOrEmpty(command)) continue;
                if (command.StartsWith("//")) continue;
                if (command.StartsWith("/EXEC", StringComparison.OrdinalIgnoreCase) && command.EndsWith(fileName)) continue;

                var handleCommandArgs = new HandleCommandArgs
                {
                    Command = command,
                    UserIdentifier = args.SenderGameUserIdentifier,
                    LastWhisperedUserIdentifier = args.LastWhisperedUserIdentifier,
                    Origin = HandleCommandOrigin.User
                };

                bool handled = gameInfo.HandleCommand(handleCommandArgs);
                if (!handled)
                {
                    if (!command.StartsWith("/")) command = "/" + command;

                    gameInfo.HandleMessageInScripts(args.SenderGameUserIdentifier, command);
                }
            }
        }
        catch (Exception ex)
        {
            args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.exec.fail.error"), Color.Red, args.SenderGameUser));

            ConsoleOutput.ShowMessage(ConsoleOutputType.Error, string.Format("Exception trying to execute commands file: '{0}'", fileName));
            ConsoleOutput.ShowMessage(ConsoleOutputType.Error, ex.Message);
        }
    }

    internal static bool PreHandleClient(GameInfo gameInfo, ProcessCommandArgs args)
    {
        Client client = GameSFD.Handle.Client;
        if ((client == null || !client.IsRunning) && gameInfo.GameOwner == GameOwnerEnum.Client) return false;

        if (args.IsCommand("PLAYERS", "LISTPLAYERS", "SHOWPLAYERS", "USERS", "LISTUSERS", "SHOWUSERS"))
        {
            int gameUserCount = 0;

            foreach (GameUser gameUser in gameInfo.GetGameUsers().OrderBy(g => g.GameSlotIndex))
            {
                var messageColor = gameUser.IsHost ? Color.LightPink : gameUser.IsModerator ? Color.LightGreen : Color.LightBlue;
                string message;

                messageColor *= (gameUserCount % 2 == 0) ? 0.8f : 0.9f;

                if (gameUser.IsBot)
                {
                    message = $"- {gameUser.GameSlotIndex}: '{gameUser.GetProfileName()}'";
                }
                else
                {
                    if (gameUser.GameSlotIndex == -1) messageColor *= 0.8f;

                    message = $"- {(gameUser.GameSlotIndex == -1 ? "#" : gameUser.GameSlotIndex)}: '{gameUser.GetProfileName()}' {(gameUser.IsHost ? "HOST" : gameUser.IsModerator ? "MOD" : "")}" + (gameUser.JoinedAsSpectator ? " (SPECTATOR)" : "");
                }

                args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.players.message", message), messageColor, args.SenderGameUser));

                gameUserCount++;
            }

            return true;
        }
        else if (args.IsCommand("CLEARCHAT"))
        {
            GameChat.ClearChat();
            return true;
        }
        else if (args.IsCommand("CTHELP"))
        {
            var colYellow = Color.Yellow;

            args.Feedback.Add(new(args.SenderGameUser, "'/CLEARCHAT' to clear the chat in your screen.", colYellow, args.SenderGameUser, null));

            // return false here to also trigger the default help command
            return false;
        }

        return false;
    }

    internal static void PostHandleClient(GameInfo gameInfo, ProcessCommandArgs args, bool handled)
    {
        Client client = GameSFD.Handle.Client;
        if ((client == null || !client.IsRunning) && gameInfo.GameOwner == GameOwnerEnum.Client) return;
    }

    internal static bool PreHandleServer(GameInfo gameInfo, ProcessCommandArgs args)
    {
        Server server = GameSFD.Handle.Server;
        if ((server == null || !server.Running) && gameInfo.GameOwner == GameOwnerEnum.Server) return false;

        if (args.HostPrivileges)
        {
            if (args.IsCommand("MODCMD", "MODCMDS", "MODCOMMANDS", "MODCOMMAND"))
            {
                var action = args.Parameters.ElementAtOrDefault(0).ToUpperInvariant();
                var commands = new List<string>();

                if (args.Parameters.Count >= 2) commands = args.Parameters.GetRange(1, args.Parameters.Count - 1);
                if (args.Parameters.Count == 2 && args.Parameters[1] == "*") commands = GameInfo.ALL_MODERATOR_COMMANDS.ToList();

                string header1, header2, message1;
                var colLightGreen = new Color(159, 255, 64);
                var shouldSave = false;

                switch (action)
                {
                    default:
                        header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.help");

                        args.Feedback.Add(new(args.SenderGameUser, header1, colLightGreen, args.SenderGameUser));
                        break;
                    case "L":
                    case "LIST":
                        header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.list");
                        message1 = "- {0}";

                        args.Feedback.Add(new(args.SenderGameUser, header1, colLightGreen, args.SenderGameUser));
                        args.Feedback.Add(new(args.SenderGameUser, string.Format(message1, string.Join(" ", CoreConstants.MODDERATOR_COMMANDS)), colLightGreen * 0.5f, args.SenderGameUser));
                        break;
                    case "C":
                    case "CLEAR":
                        header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.clear");

                        int clearedCount = 0;
                        shouldSave = true;

                        clearedCount += CoreConstants.MODDERATOR_COMMANDS.Count;
                        CoreConstants.MODDERATOR_COMMANDS.Clear();

                        args.Feedback.Add(new(args.SenderGameUser, string.Format(header1, clearedCount), colLightGreen, args.SenderGameUser));
                        break;
                    case "R":
                    case "REMOVE":
                        if (commands.Count > 0)
                        {
                            header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.remove");
                            message1 = "- {0}";

                            int removedCount = 0;
                            shouldSave = true;

                            foreach (string modderatorCommand in CoreConstants.MODDERATOR_COMMANDS.ToList())
                            {
                                if (commands.Contains(modderatorCommand, StringComparer.OrdinalIgnoreCase))
                                {
                                    if (CoreConstants.MODDERATOR_COMMANDS.Remove(modderatorCommand))
                                    {
                                        removedCount++;
                                    }
                                }
                            }

                            args.Feedback.Add(new(args.SenderGameUser, string.Format(header1, removedCount), colLightGreen, args.SenderGameUser));
                            if (removedCount > 0)
                            {
                                args.Feedback.Add(new(args.SenderGameUser, string.Format(message1, string.Join(" ", commands)), colLightGreen * 0.5f, args.SenderGameUser));
                            }
                        }
                        break;
                    case "A":
                    case "ADD":
                        if (commands.Count > 0)
                        {
                            header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.add");
                            message1 = "- {0}";

                            int addedCount = 0;
                            shouldSave = true;

                            foreach (string command in commands)
                            {
                                if (!CoreConstants.MODDERATOR_COMMANDS.Contains(command, StringComparer.OrdinalIgnoreCase))
                                {
                                    CoreConstants.MODDERATOR_COMMANDS.Add(command.ToUpperInvariant());
                                    addedCount++;
                                }
                            }

                            args.Feedback.Add(new(args.SenderGameUser, string.Format(header1, addedCount), colLightGreen, args.SenderGameUser));
                            if (addedCount > 0)
                            {
                                args.Feedback.Add(new(args.SenderGameUser, string.Format(message1, string.Join(" ", commands)), colLightGreen * 0.5f, args.SenderGameUser));
                            }
                        }
                        break;
                    case "T":
                    case "TRY":
                        if (commands.Count > 0)
                        {
                            header1 = LanguageHelper.GetText("sfdct.command.modcommands.header.try.true");
                            header2 = LanguageHelper.GetText("sfdct.command.modcommands.header.try.false");
                            message1 = "- {0}";

                            List<string> canUseList = [];
                            List<string> canNotUseList = [];

                            foreach (string command in commands)
                            {
                                if (CoreConstants.MODDERATOR_COMMANDS.Count > 0 && !CoreConstants.MODDERATOR_COMMANDS.Contains(command))
                                {
                                    canNotUseList.Add(command);
                                }
                                else
                                {
                                    canUseList.Add(command);
                                }
                            }

                            args.Feedback.Add(new(args.SenderGameUser, string.Format(header2), colLightGreen, args.SenderGameUser));
                            if (canNotUseList.Count > 0)
                            {
                                args.Feedback.Add(new(args.SenderGameUser, string.Format(message1, string.Join(" ", canNotUseList)), colLightGreen * 0.5f, args.SenderGameUser));
                            }
                            args.Feedback.Add(new(args.SenderGameUser, string.Format(header1), colLightGreen, args.SenderGameUser));

                            if (canUseList.Count > 0)
                            {
                                args.Feedback.Add(new(args.SenderGameUser, string.Format(message1, string.Join(" ", canUseList)), colLightGreen * 0.5f, args.SenderGameUser));
                            }
                        }
                        break;
                }

                if (shouldSave) SFDConfig.SaveConfig(CoreHandler.SAVE_MODERATOR_COMMANDS);

                return true;
            }
        }

        if (args.ModeratorPrivileges)
        {
            if (gameInfo.GameWorld != null)
            {
                if (IsAndCanUseModeratorCommand(args, "GRAVITY", "GRAV"))
                {
                    var defaultGravity = new Vector2(0, -26);
                    if (args.Parameters.Count < 2)
                    {
                        gameInfo.GameWorld.GetActiveWorld.Gravity = defaultGravity;
                        gameInfo.GameWorld.GetBackgroundWorld.Gravity = defaultGravity;
                        return true;
                    }

                    float gravityX, gravityY;
                    if (!SFDXParser.TryParseFloat(args.Parameters[0], out gravityX)) gravityX = defaultGravity.X;
                    if (!SFDXParser.TryParseFloat(args.Parameters[1], out gravityY)) gravityY = defaultGravity.Y;

                    var newGravity = new Vector2(gravityX, gravityY);

                    gameInfo.GameWorld.GetActiveWorld.Gravity = newGravity;
                    gameInfo.GameWorld.GetBackgroundWorld.Gravity = newGravity;

                    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.gravity.message", newGravity.ToString())));
                    return true;
                }

                if (IsAndCanUseModeratorCommand(args, "DAMAGE", "HURT"))
                {
                    if (args.Parameters.Count < 2) return true;

                    GameUser user = gameInfo.GetGameUserByStringInput(args.Parameters[0], args.SenderGameUser);
                    if (user == null || user.IsDisposed) return true;

                    Player userPlayer = gameInfo.GameWorld.GetPlayerByUserIdentifier(user.UserIdentifier);
                    if (userPlayer == null || userPlayer.IsDisposed) return true;

                    var damage = 0f;
                    if (!SFDXParser.TryParseFloat(args.Parameters[1], out damage)) return true;

                    if (damage > 0f)
                    {
                        userPlayer.TakeMiscDamage(damage, false);
                    }
                    else if (damage < 0f)
                    {
                        userPlayer.HealAmount(-damage);
                    }

                    string message = LanguageHelper.GetText("sfdct.command.damage.message", damage.ToString(), user.GetProfileName());
                    args.Feedback.Add(new(args.SenderGameUser, message));

                    return true;
                }
            }

            if (IsAndCanUseModeratorCommand(args, "M", "MOUSE"))
            {
                if (args.Parameters.Count < 1)
                {
                    ServerHandler.OnlineMouseState = !ServerHandler.OnlineMouseState;
                }
                else
                {
                    if (args.Parameters[0] == "0" || args.Parameters[0].ToUpperInvariant() == "FALSE")
                    {
                        ServerHandler.OnlineMouseState = false;
                    }
                    else if (args.Parameters[0] == "1" || args.Parameters[0].ToUpperInvariant() == "TRUE")
                    {
                        ServerHandler.OnlineMouseState = true;
                    }
                }

                if (gameInfo.GameOwner == GameOwnerEnum.Server)
                {
                    ServerHandler.SyncMouseState(server);
                }

                string message = LanguageHelper.GetText("sfdct.command.debugmouse.message", LanguageHelper.GetBooleanText(ServerHandler.OnlineMouseState));
                args.Feedback.Add(new(args.SenderGameUser, message));

                return true;
            }

            if (IsAndCanUseModeratorCommand(args, "EXEC"))
            {
                ProcessCommandFile(ref args, gameInfo, args.SourceParameters);
                return true;
            }

            if (IsAndCanUseModeratorCommand(args, "META"))
            {
                if (string.IsNullOrEmpty(args.SourceParameters))
                {
                    string exampleMetaText = "- Default. [#FF00FF]Magenta[#]. [#FF0]Yellow[#]. Icon [ICO=TEAM_1]";

                    args.Feedback.Add(new(args.SenderGameUser, "Meta-formatting allows to specify text color ('[#FFFFFF]'), reset text color ('[#]'), and display icons ('[ICO=]'). Example:", args.SenderGameUser));
                    args.Feedback.Add(new(args.SenderGameUser, exampleMetaText, true, COLORS.LIGHT_GRAY, args.SenderGameUser));
                    args.Feedback.Add(new(args.SenderGameUser, exampleMetaText, false, COLORS.LIGHT_GRAY, args.SenderGameUser));

                    var availableIcons = TextIcons.m_icons.Keys.Select(iconKey => $"{TextMeta.EscapeText(iconKey)} ([ICO={iconKey}])");
                    string availableIconsText = "- " + string.Join(", ", availableIcons);

                    args.Feedback.Add(new(args.SenderGameUser, "Available Icons:", args.SenderGameUser));
                    args.Feedback.Add(new(args.SenderGameUser, availableIconsText, true, COLORS.LIGHT_GRAY, args.SenderGameUser));

                    return true;
                }

                var message = args.SourceParameters;
                var chatMessageData = new NetMessage.ChatMessage.Data(message, Color.White, args.SenderGameUser.GetProfileName(), true, args.SenderGameUser.UserIdentifier);
                gameInfo.ShowChatMessage(chatMessageData);

                return true;
            }

            if (IsAndCanUseModeratorCommand(args, "VOTE"))
            {
                if (gameInfo.InLobby) return true;
                if (gameInfo.VoteInfo == null) return true;
                if (gameInfo.VoteInfo.ActiveVotes.Count >= 1) return true;
                if (args.Parameters.Count <= 0) return true;

                ConsoleOutput.ShowMessage(ConsoleOutputType.Information, string.Format($"SFDCT: Creating yes-no vote: {args.SourceParameters}"));

                var vote = new Voting.GameVoteManual(GameVote.GetNextVoteID(), args.SourceParameters);
                gameInfo.VoteInfo.AddVote(vote);

                if (gameInfo.GameOwner == GameOwnerEnum.Server)
                {
                    long[] validRemoteUniqueIdentifiers = server.GetConnectedUniqueIdentifiers(n => n.GameConnectionTag() != null
                                                                            && n.GameConnectionTag().FirstGameUser != null
                                                                            && n.GameConnectionTag().FirstGameUser.CanVote);

                    vote.ValidRemoteUniqueIdentifiers.AddRange(validRemoteUniqueIdentifiers);
                    server.SendMessage(MessageType.GameVote, new Pair<GameVote, bool>(vote, false));
                }
                else
                {
                    vote.ValidRemoteUniqueIdentifiers.Add(1L);
                }

                return true;
            }

            if (gameInfo.GameOwner == GameOwnerEnum.Server)
            {
                if (IsAndCanUseModeratorCommand(args, "SERVERMOVEMENT", "SVMOV"))
                {
                    if (args.Parameters.Count < 2) return true;

                    var gameUser = gameInfo.GetGameUserByStringInput(args.Parameters[0], args.SenderGameUser);
                    if (gameUser == null || gameUser.IsDisposed || gameUser.IsBot) return true;

                    var gameUserTag = gameUser.GetGameConnectionTag();
                    if (gameUserTag == null || gameUserTag.IsDisposed || gameUserTag.GameUsers == null) return true;

                    var serverMovement = -1;
                    int.TryParse(args.Parameters[1], out serverMovement);

                    gameUserTag.ForcedServerMovementToggleTime = serverMovement == 1 ? ServerHandler.SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_TRUE : serverMovement == 0 ? ServerHandler.SERVER_MOVEMENT_TOGGLE_TIME_MS_FORCE_FALSE : CoreConstants.HOST_GAME_FORCED_SERVER_MOVEMENT_TOGGLE_TIME_MS;

                    string messageKey = "sfdct.command.servermovement.message";
                    string message = LanguageHelper.GetText(messageKey, gameUser.GetProfileName(), serverMovement == 1 ? LanguageHelper.GetBooleanText(true) : serverMovement == 0 ? LanguageHelper.GetBooleanText(false) : LanguageHelper.GetText("properties.script.spawnFire.type.default"));
                    args.Feedback.Add(new(args.SenderGameUser, message, args.SenderGameUser));

                    return true;
                }
            }
        }

        if (gameInfo.GameOwner == GameOwnerEnum.Server)
        {
            //if (args.IsCommand("VOTEKICK"))
            //{
            //    if (gameInfo.InLobby) return true;
            //    if (gameInfo.VoteInfo == null) return true;
            //    if (gameInfo.VoteInfo.ActiveVotes.Count >= 1) return true;
            //    if (args.Parameters.Count <= 0) return true;
            //    if (!ExConfig.Get<bool>(ExSettingKey.VoteKickEnabled)) return true;

            //    if (!Voting.GameVoteKick.CanStartVoteKick(gameInfo))
            //    {
            //        args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.fail"), Color.Red, args.SenderGameUser));
            //        return true;
            //    }

            //    var kickOwnerUser = args.SenderGameUser;
            //    var userToKick = gameInfo.GetGameUserByStringInput(args.SourceParameters);

            //    if (userToKick == null || userToKick.IsDisposed || userToKick == args.SenderGameUser) return true;
            //    if (userToKick.IsHost || userToKick.IsModerator || userToKick.IsBot)
            //    {
            //        args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.fail.invaliduser"), Color.Red, args.SenderGameUser));
            //        return true;
            //    }

            //    string userToKickProfileName = userToKick.GetProfileName();
            //    string userTokickAccountName = userToKick.AccountName;

            //    string kickOwnerUserProfileName = kickOwnerUser.GetProfileName();
            //    string kickOwnerUserAccountName = kickOwnerUser.AccountName;

            //    long[] validRemoteUniqueIdentifiers = server.GetConnectedUniqueIdentifiers(n => n.GameConnectionTag() != null
            //                                                                                && n.GameConnectionTag().FirstGameUser != null
            //                                                                                && n.GameConnectionTag().FirstGameUser.CanVote
            //                                                                                && n.GameConnectionTag().FirstGameUser != kickOwnerUser
            //                                                                                && n.GameConnectionTag().FirstGameUser != userToKick);

            //    if (validRemoteUniqueIdentifiers.Length <= 2)
            //    {
            //        args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.fail.notenoughusers"), Color.Red, args.SenderGameUser));
            //        return true;
            //    }

            //    ConsoleOutput.ShowMessage(ConsoleOutputType.Information, string.Format("SFDCT: Creating vote-kick from '{0}' ({1}) against '{2}' ({3})", kickOwnerUserProfileName, kickOwnerUserAccountName, userToKickProfileName, userTokickAccountName));

            //    var vote = new Voting.GameVoteKick(GameVote.GetNextVoteID(), userToKick);
            //    vote.ValidRemoteUniqueIdentifiers.AddRange(validRemoteUniqueIdentifiers);

            //    foreach (var id in validRemoteUniqueIdentifiers)
            //    {
            //        var connection = server.GetConnectionByRemoteUniqueIdentifier(id);
            //        if (connection == null) continue;

            //        server.SendMessage(MessageType.GameVote, new Pair<GameVote, bool>(vote, false), null, connection);
            //        server.SendMessage(MessageType.Sound, new NetMessage.Sound.Data("PlayerLeave", true, Vector2.Zero, 1f), null, connection);
            //    }

            //    gameInfo.VoteInfo.AddVote(vote);
            //    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.message", kickOwnerUserProfileName, kickOwnerUserAccountName, userToKickProfileName, userTokickAccountName), Color.Yellow));
            //    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.message.victim", kickOwnerUserProfileName, kickOwnerUserAccountName), Color.Yellow * 0.6f, userToKick));
            //    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.votekick.message.owner", userToKickProfileName, userTokickAccountName), Color.Yellow * 0.6f, args.SenderGameUser));
            //    return true;
            //}
        }

        //if (args.IsCommand("JOIN"))
        //{
        //    if (!args.SenderGameUser.JoinedAsSpectator) return true;

        //    List<GameSlot> availableGameSlots = null;
        //    if (gameInfo.GameOwner == GameOwnerEnum.Server)
        //    {
        //        var connectionTag = args.SenderGameUser.GetGameConnectionTag();
        //        if (connectionTag == null) return true;
        //        if (connectionTag.GameUsers.Length > 1) return true;

        //        availableGameSlots = server.FindOpenGameSlots(gameInfo.DropInMode, 1, gameInfo.EvenTeams);
        //    }
        //    else
        //    {
        //        availableGameSlots = [gameInfo.GameSlots[0]];
        //    }

        //    if (availableGameSlots == null || availableGameSlots.Count == 0)
        //    {
        //        args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.join.fail.nogameslot"), Color.Red, args.SenderGameUser));
        //        return true;
        //    }

        //    GameSlot gameSlot = availableGameSlots[0];
        //    gameSlot.ClearGameUser(gameInfo);
        //    gameSlot.GameUser = args.SenderGameUser;
        //    gameSlot.CurrentState = GameSlot.State.Occupied;
        //    args.SenderGameUser.GameSlot = gameSlot;
        //    args.SenderGameUser.JoinedAsSpectator = false;
        //    args.SenderGameUser.SpectatingWhileWaitingToPlay = true;

        //    var messageKey = "menu.lobby.newPlayerJoined";
        //    var messageArgs = new List<string>();
        //    var messageColor = COLORS.PLAYER_CONNECTED;

        //    messageArgs.Add(args.SenderGameUser.GetProfileName());
        //    if (gameSlot.CurrentTeam != Team.Independent)
        //    {
        //        messageKey = "menu.lobby.newPlayerJoinedTeam";
        //        messageArgs.Add(((int)gameSlot.CurrentTeam).ToString());
        //    }

        //    gameInfo.ShowChatMessage(new(messageKey, messageColor, messageArgs.ToArray()));
        //    SFD.Sounds.SoundHandler.PlaySound("PlayerJoin", gameInfo.GameWorld);

        //    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.join.message"), Color.Gray, args.SenderGameUser));
        //    return true;
        //}
        //else if (args.IsCommand("SPECTATE"))
        //{
        //    if (args.SenderGameUser.JoinedAsSpectator) return true;
        //    if (!args.ModeratorPrivileges && ExConfig.Get<bool>(ExSettingKey.SpectatorsOnlyModerators)) return true;
        //    if (gameInfo.SpectatorGameUserCount >= ExConfig.Get<int>(ExSettingKey.SpectatorsMaximum)) return true;

        //    var gameSlot = args.SenderGameUser.GameSlot;
        //    var userIdentifier = args.SenderGameUser.UserIdentifier;
        //    var connectionTag = args.SenderGameUser.GetGameConnectionTag();

        //    if (gameInfo.GameOwner == GameOwnerEnum.Server)
        //    {
        //        if (connectionTag == null) return true;
        //        if (connectionTag.GameUsers.Length > 1) return true;
        //    }

        //    gameSlot.ClearGameUser(null);

        //    args.SenderGameUser.GameSlot = null;
        //    args.SenderGameUser.JoinedAsSpectator = true;
        //    args.SenderGameUser.SpectatingWhileWaitingToPlay = false;

        //    Player senderGamePlayer = gameInfo.GameWorld?.GetPlayerByUserIdentifier(userIdentifier);
        //    senderGamePlayer?.SetUser(0);
        //    senderGamePlayer?.Kill();

        //    var messageKey = "menu.lobby.newPlayerJoinedTeam";
        //    var messageArgs = new string[] { args.SenderGameUser.GetProfileName(), LanguageHelper.GetText("general.spectator") };
        //    var messageColor = Color.LightGray;

        //    gameInfo.ShowChatMessage(new(messageKey, messageColor, messageArgs));
        //    SFD.Sounds.SoundHandler.PlaySound("PlayerLeave", gameInfo.GameWorld);

        //    args.Feedback.Add(new(args.SenderGameUser, LanguageHelper.GetText("sfdct.command.spectate.message.info"), Color.Gray, args.SenderGameUser));
        //    return true;
        //}

        return false;
    }

    internal static void PostHandleServer(GameInfo gameInfo, ProcessCommandArgs args, bool handled)
    {
        Server server = GameSFD.Handle.Server;
        if ((server == null || !server.Running) && gameInfo.GameOwner == GameOwnerEnum.Server) return;

        if (args.IsCommand("HELP"))
        {
            var colorYellow = Color.Yellow;
            var colorOrange = new Color(255, 181, 26);
            var colorModeratorGreen = new Color(159, 255, 64);
            var colorHost = new Color(255, 91, 51);

            //if (args.ModeratorPrivileges || !ExConfig.Get<bool>(ExSettingKey.SpectatorsOnlyModerators))
            //{
            //    args.Feedback.Add(new(args.SenderGameUser, "'/SPECTATE' become a spectator", colorYellow, args.SenderGameUser));
            //    args.Feedback.Add(new(args.SenderGameUser, "'/JOIN' join back from spectating to an available game-slot", colorYellow, args.SenderGameUser));
            //}

            //if (gameInfo.GameOwner == GameOwnerEnum.Server)
            //{
            //    if (ExConfig.Get<bool>(ExSettingKey.VoteKickEnabled))
            //    {
            //        args.Feedback.Add(new(args.SenderGameUser, "'/VOTEKICK' [PLAYER] to start a vote-kick against a player.", colorYellow, args.SenderGameUser));
            //    }
            //}

            if (args.ModeratorPrivileges)
            {
                if (args.CanUseModeratorCommand("GRAVITY", "GRAV")) args.Feedback.Add(new(args.SenderGameUser, "'/GRAVITY [X] [Y]' to set the world's gravity, leave empty to reset it.", colorOrange, args.SenderGameUser));
                if (args.CanUseModeratorCommand("DAMAGE", "HURT")) args.Feedback.Add(new(args.SenderGameUser, "'/HURT [PLAYER] [AMOUNT]' to deal damage to a player, negative amounts heal.", colorOrange, args.SenderGameUser));
                if (args.CanUseModeratorCommand("VOTE")) args.Feedback.Add(new(args.SenderGameUser, "'/VOTE [...]' to start a yes/no vote with the parameters given.", colorOrange, args.SenderGameUser));

                if (args.CanUseModeratorCommand("M", "MOUSE", "DEBUGMOUSE")) args.Feedback.Add(new(args.SenderGameUser, "'/MOUSE [1/0]' to enable or disable the debug mouse.", colorModeratorGreen, args.SenderGameUser));
                if (args.CanUseModeratorCommand("EXEC")) args.Feedback.Add(new(args.SenderGameUser, "'/EXEC [PATH/TO/FILE]' to execute a commands file.", colorModeratorGreen, args.SenderGameUser));
                if (args.CanUseModeratorCommand("META")) args.Feedback.Add(new(args.SenderGameUser, "'/META [...]' to send a message with meta formatting.", colorModeratorGreen, args.SenderGameUser));

                if (gameInfo.GameOwner == GameOwnerEnum.Server)
                {
                    if (args.HostPrivileges)
                    {
                        args.Feedback.Add(new(args.SenderGameUser, "'/MODCMD [A|R|L|C|T] [...]' to add/remove/list/clear/try moderator commands separated by spaces.", colorHost, args.SenderGameUser));
                    }

                    if (args.CanUseModeratorCommand("SERVERMOVEMENT", "SVMOV")) args.Feedback.Add(new(args.SenderGameUser, "'/SERVERMOVEMENT [PLAYER] [0|1]' to control the server-movement state (empty is default, 0 is off, 1 is on).", colorModeratorGreen, args.SenderGameUser));
                }
            }

            args.Feedback.Add(new ProcessCommandMessage(args.SenderGameUser, "Scroll the chat using the scroll-wheel to see all commands.", Color.LightBlue, args.SenderGameUser));
        }
    }
}