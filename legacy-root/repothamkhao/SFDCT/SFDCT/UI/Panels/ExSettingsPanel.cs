using Microsoft.Xna.Framework;
using SFD;
using SFD.MenuControls;
using SFDCT.Bootstrap;
using SFDCT.Configuration;
using SFDCT.Helper;
using SFDCT.UI.MenuItems;
using Color = Microsoft.Xna.Framework.Color;
using Keys = Microsoft.Xna.Framework.Input.Keys;
using Panel = SFD.MenuControls.Panel;

namespace SFDCT.UI.Panels;

internal class ExSettingsPanel : Panel
{
    private Menu m_menu;
    private bool m_settingsNeedGameRestart;

    private readonly bool m_originalSoundPanningEnabled = ExConfig.Get<bool>(ExSettingKey.SoundPanningEnabled);
    private readonly float m_originalSoundPanningStrength = ExConfig.Get<float>(ExSettingKey.SoundPanningStrength);
    private readonly bool m_originalSoundPanningForceScreenSpace = ExConfig.Get<bool>(ExSettingKey.SoundPanningForceScreenSpace);
    private readonly int m_originalSoundPanningInworldThreshold = ExConfig.Get<int>(ExSettingKey.SoundPanningInworldThreshold);
    private readonly int m_originalSoundPanningInworldDistance = ExConfig.Get<int>(ExSettingKey.SoundPanningInworldDistance);
    private readonly float m_originalLowHealthSaturationFactor = ExConfig.Get<float>(ExSettingKey.LowHealthSaturationFactor);
    private readonly float m_originalLowHealthThreshold = ExConfig.Get<float>(ExSettingKey.LowHealthThreshold);
    private readonly float m_originalLowHealthHurtLevel1Threshold = ExConfig.Get<float>(ExSettingKey.LowHealthHurtLevel1Threshold);
    private readonly float m_originalLowHealthHurtLevel2Threshold = ExConfig.Get<float>(ExSettingKey.LowHealthHurtLevel2Threshold);
    private readonly bool m_originalHideFilmgrain = ExConfig.Get<bool>(ExSettingKey.HideFilmgrain);
    private readonly string m_originalLanguage = ExConfig.Get<string>(ExSettingKey.Language);
    //private readonly int m_originalSpectatorsMaximum = ExConfig.Get<int>(ExSettingKey.SpectatorsMaximum);
    //private readonly bool m_originalSpectatorsOnlyModerators = ExConfig.Get<bool>(ExSettingKey.SpectatorsOnlyModerators);
    //private readonly bool m_originalVoteKickEnabled = ExConfig.Get<bool>(ExSettingKey.VoteKickEnabled);
    //private readonly int m_originalVoteKickFailCooldown = ExConfig.Get<int>(ExSettingKey.VoteKickFailCooldown);
    //private readonly int m_originalVoteKickSuccessCooldown = ExConfig.Get<int>(ExSettingKey.VoteKickSuccessCooldown);
    private readonly bool m_originalSubContent = ExConfig.Get<bool>(ExSettingKey.SubContent);
    private readonly string m_originalSubContentDisabledFolders = ExConfig.Get<string>(ExSettingKey.SubContentDisabledFolders);
    private readonly string m_originalSubContentEnabledFolders = ExConfig.Get<string>(ExSettingKey.SubContentEnabledFolders);
    private readonly string m_originalPrimaryColorHex = COLORS.MENU_BLUE.ToHex();
    private readonly int m_originalChatWidth = ExConfig.Get<int>(ExSettingKey.ChatWidth);
    private readonly int m_originalChatHeight = ExConfig.Get<int>(ExSettingKey.ChatHeight);
    private readonly int m_originalChatExtraHeight = ExConfig.Get<int>(ExSettingKey.ChatExtraHeight);

    public ExSettingsPanel() : base(LanguageHelper.GetText("sfdct.setting.header"), 500, 500)
    {
        m_menu = new Menu(new Vector2(0, 50), Width, Height - 50, this, []);
        m_settingsNeedGameRestart = false;

        // Credits
        m_menu.Add(new MenuItemButton(LanguageHelper.GetText("sfdct.credits.name"), new ControlEvents.ChooseEvent(_ => OpenSubPanel(new ExCreditsPanel()))));

        // Sound Panning
        m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.soundpanning")));
        m_menu.Add(CreateBoolSetting(ExSettingKey.SoundPanningEnabled, "sfdct.setting.name.soundpanningenabled"));
        m_menu.Add(CreateFloatPercentSetting(ExSettingKey.SoundPanningStrength, "sfdct.setting.name.soundpanningstrength"));
        m_menu.Add(CreateBoolSetting(ExSettingKey.SoundPanningForceScreenSpace, "sfdct.setting.name.soundpanningforcescreenspace"));
        m_menu.Add(CreateIntSetting(ExSettingKey.SoundPanningInworldThreshold, 0, 1000, 5, "sfdct.setting.name.soundpanninginworldthreshold", "sfdct.setting.help.soundpanninginworldthreshold"));
        m_menu.Add(CreateIntSetting(ExSettingKey.SoundPanningInworldDistance, 0, 1000, 5, "sfdct.setting.name.soundpanninginworlddistance", "sfdct.setting.help.soundpanninginworlddistance"));

        // Low Health
        m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.lowhealth")));
        m_menu.Add(CreateFloatPercentSetting(ExSettingKey.LowHealthSaturationFactor, "sfdct.setting.name.lowhealthsaturationfactor", null, true));
        m_menu.Add(CreateFloatPercentSetting(ExSettingKey.LowHealthThreshold, "sfdct.setting.name.lowhealththreshold", null, true));
        m_menu.Add(CreateFloatPercentSetting(ExSettingKey.LowHealthHurtLevel1Threshold, "sfdct.setting.name.lowhealthhurtlevel1threshold", null, true));
        m_menu.Add(CreateFloatPercentSetting(ExSettingKey.LowHealthHurtLevel2Threshold, "sfdct.setting.name.lowhealthhurtlevel2threshold", null, true));

        // Spectators
        //m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.spectators")));
        //m_menu.Add(CreateIntSetting(ExSettingKey.SpectatorsMaximum, 0, 4, 1, "sfdct.setting.name.spectatorsmaximum"));
        //m_menu.Add(CreateBoolSetting(ExSettingKey.SpectatorsOnlyModerators, "sfdct.setting.name.spectatorsonlymoderators", "sfdct.setting.help.spectatorsonlymoderators"));

        // Vote Kick
        //m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.votekick")));
        //m_menu.Add(CreateBoolSetting(ExSettingKey.VoteKickEnabled, "sfdct.setting.name.votekickenabled"));
        //m_menu.Add(CreateTimeSetting(ExSettingKey.VoteKickFailCooldown, TimeSpan.FromSeconds(15), TimeSpan.FromSeconds(300), "sfdct.setting.name.votekickfailcooldown"));
        //m_menu.Add(CreateTimeSetting(ExSettingKey.VoteKickSuccessCooldown, TimeSpan.FromSeconds(15), TimeSpan.FromSeconds(300), "sfdct.setting.name.votekicksuccesscooldown"));

        // Misc
        m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.misc")));
        m_menu.Add(CreateBoolSetting(ExSettingKey.HideFilmgrain, "sfdct.setting.name.hidefilmgrain"));

        // these ranges and steps make it easier to set back the default value,
        // the true range is from half to double
        m_menu.Add(CreateIntSetting(ExSettingKey.ChatWidth, 218, 848, 10, "sfdct.setting.name.chatwidth"));
        m_menu.Add(CreateIntSetting(ExSettingKey.ChatHeight, 90, 360, 10, "sfdct.setting.name.chatheight"));
        m_menu.Add(CreateIntSetting(ExSettingKey.ChatExtraHeight, 0, 180, 10, "sfdct.setting.name.chatextraheight", "sfdct.setting.help.chatextraheight"));

        var availableExLanguages = LanguageHandler.GetExLanguages();
        var m_menuItemLanguage = new MenuItemDropdown(LanguageHelper.GetText("sfdct.setting.name.language"), availableExLanguages);
        m_menuItemLanguage.SetStartValue(Math.Max(0, Array.IndexOf(availableExLanguages, ExConfig.Get<string>(ExSettingKey.Language))));
        m_menuItemLanguage.DropdownItemVisibleCount = availableExLanguages.Length;
        Hooker.Add(m_menuItemLanguage, "ValueChangedEvent", new MenuItemValueChangedEvent(_ =>
        {
            m_settingsNeedGameRestart = true;
            ExConfig.Set(ExSettingKey.Language, m_menuItemLanguage.Value);
        }));
        m_menu.Add(m_menuItemLanguage);

        // Subcontent
        m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.subcontent")));
        m_menu.Add(CreateBoolSetting(ExSettingKey.SubContent, "sfdct.setting.name.subcontentenabled", "sfdct.setting.help.subcontentenabled", true));
        m_menu.Add(new MenuItemButton(LanguageHelper.GetText("sfdct.setting.name.subcontentfolders"), _ => OpenSubPanel(new ExSubContentPanel()), MenuIcons.Settings));

        // Primary Color
        MenuItemText m_menuItemPrimaryColorHex = null;
        ExMenuItemDropdownColor m_menuItemPrimaryColor = null;

        m_menuItemPrimaryColorHex = new MenuItemText(LanguageHelper.GetText("sfdct.setting.name.primarycolorhex"), COLORS.MENU_BLUE.ToHex());
        Hooker.Add(m_menuItemPrimaryColorHex.TextSetValidationItem, "TextValidationEvent", new TextValidationEvent((string setText, TextValidationEventArgs _) =>
        {
            if (setText.IsHex())
            {
                COLORS.MENU_BLUE = setText.ToColor();

                if (m_menuItemPrimaryColor.Color != COLORS.MENU_BLUE)
                {
                    m_menuItemPrimaryColor.SetColor(COLORS.MENU_BLUE);
                }
            }
            else
            {
                m_menuItemPrimaryColorHex.SetValue(COLORS.MENU_BLUE.ToHex());
            }
        }));

        m_menuItemPrimaryColor = new ExMenuItemDropdownColor(LanguageHelper.GetText("sfdct.setting.name.primarycolor"), COLORS.MENU_BLUE, [
            new Color(064, 064, 064),
            new Color(232, 96, 96),
            new Color(180, 032, 000),
            new Color(192, 096, 000),
            new Color(208, 192, 000),
            new Color(016, 128, 000),
            new Color(008, 096, 096),
            new Color(48, 48, 192),
            new Color(160, 032, 160),
            new Color(096, 048, 032),
            new Color(32, 0, 192), // MENU_BLUE Default
        ]);
        m_menuItemPrimaryColor.ValueChangedEvent += (MenuItem _) =>
        {
            COLORS.MENU_BLUE = m_menuItemPrimaryColor.Color;

            if (m_menuItemPrimaryColorHex.Value != COLORS.MENU_BLUE.ToHex())
            {
                m_menuItemPrimaryColorHex.SetValue(COLORS.MENU_BLUE.ToHex());
            }
        };

        m_menu.Add(new MenuItemSeparator(LanguageHelper.GetText("sfdct.setting.category.primarycolor")));
        m_menu.Add(m_menuItemPrimaryColorHex);
        m_menu.Add(m_menuItemPrimaryColor);

        m_menu.Add(new MenuItemSeparator(string.Empty));
        m_menu.Add(new MenuItemButton(LanguageHelper.GetText("button.done"), new ControlEvents.ChooseEvent(ok), MenuIcons.Ok));
        m_menu.Add(new MenuItemButton(LanguageHelper.GetText("button.back"), new ControlEvents.ChooseEvent(back), MenuIcons.Cancel));

        members.Add(m_menu);
        m_menu.SelectFirst();
    }

    private MenuItemDropdown CreateBoolSetting(ExSettingKey configKey, string labelKey, string tooltipKey = null, bool requiresRestart = false)
    {
        var item = new MenuItemDropdown(
            LanguageHelper.GetText(labelKey),
            [LanguageHelper.GetText("general.on"), LanguageHelper.GetText("general.off")]
        );
        item.SetStartValue(ExConfig.Get<bool>(configKey) ? 0 : 1);
        item.DropdownItemVisibleCount = 2;
        item.Tooltip = tooltipKey != null ? LanguageHelper.GetText(tooltipKey) : null;

        Hooker.Add(item, "ValueChangedEvent", new MenuItemValueChangedEvent(_ =>
        {
            if (requiresRestart) m_settingsNeedGameRestart = true;
            ExConfig.Set(configKey, item.ValueId == 0);
        }));

        return item;
    }

    private MenuItemSlider CreateIntSetting(ExSettingKey configKey, int min, int max, int step, string labelKey, string tooltipKey = null, bool requiresRestart = false)
    {
        var item = new MenuItemSlider(
            LanguageHelper.GetText(labelKey),
            ExConfig.Get<int>(configKey),
            min, max, step
        );
        item.SetStartValue(ExConfig.Get<int>(configKey));
        item.Tooltip = tooltipKey != null ? LanguageHelper.GetText(tooltipKey) : null;

        Hooker.Add(item, "ValueChangedEvent", new MenuItemValueChangedEvent(_ =>
        {
            if (requiresRestart) m_settingsNeedGameRestart = true;
            ExConfig.Set(configKey, item.Value);
        }));

        return item;
    }

    private MenuItemTime CreateTimeSetting(ExSettingKey configKey, TimeSpan min, TimeSpan max, string labelKey, string tooltipKey = null, bool requiresRestart = false)
    {
        var value = TimeSpan.FromSeconds(ExConfig.Get<int>(configKey));
        var item = new MenuItemTime(
            LanguageHelper.GetText(labelKey),
            value, min, max
        );
        item.SetStartValue(value);
        item.Tooltip = tooltipKey != null ? LanguageHelper.GetText(tooltipKey) : null;

        item.ChooseEvent = (ControlEvents.ChooseEvent)Delegate.Combine(item.ChooseEvent, (ControlEvents.ChooseEvent)(_ =>
        {
            var timePanel = (TimePanel)item.ParentMenu.ParentPanel.SubPanel;
            var timePanelOkButton = (MenuItemButton)timePanel.m_menu.Items[0];

            timePanelOkButton.ChooseEvent = (ControlEvents.ChooseEvent)Delegate.Combine(timePanelOkButton.ChooseEvent, (ControlEvents.ChooseEvent)(_ =>
            {
                ExConfig.Set(configKey, item.Value.Seconds);
            }));
        }));

        return item;
    }

    private MenuItemSlider CreateFloatPercentSetting(ExSettingKey configKey, string labelKey, string tooltipKey = null, bool requiresRestart = false)
    {
        var item = new MenuItemSlider(
            LanguageHelper.GetText(labelKey),
            (int)(100 * ExConfig.Get<float>(configKey)),
            0, 100, 1
        );
        item.SetStartValue((int)(100 * ExConfig.Get<float>(configKey)));
        item.Tooltip = tooltipKey != null ? LanguageHelper.GetText(tooltipKey) : null;

        Hooker.Add(item, "ValueChangedEvent", new MenuItemValueChangedEvent(_ =>
        {
            if (requiresRestart) m_settingsNeedGameRestart = true;
            ExConfig.Set(configKey, item.Value * 0.01f);
        }));

        return item;
    }

    public override void KeyPress(Keys key)
    {
        if (key == Keys.Escape)
        {
            back(null);
            return;
        }

        base.KeyPress(key);
    }

    private void ok(object _)
    {
        if (m_settingsNeedGameRestart)
        {
            MessageStack.Show(LanguageHelper.GetText("menu.settings.restartrequiredmessage"), MessageStackType.Information);
        }

        ExConfig.Save();

        if (m_originalPrimaryColorHex != COLORS.MENU_BLUE.ToHex())
        {
            SFDConfig.SaveConfig(SFDConfigSaveMode.Settings);
        }

        ParentPanel.CloseSubPanel();
    }

    private void back(object _)
    {
        OpenSubPanel(new ConfirmYesNoPanel(LanguageHelper.GetText("menu.settings.confirmcancel"), LanguageHelper.GetText("general.yes"), LanguageHelper.GetText("general.no"), _ =>
        {
            ExConfig.Set(ExSettingKey.SoundPanningEnabled, m_originalSoundPanningEnabled);
            ExConfig.Set(ExSettingKey.SoundPanningStrength, m_originalSoundPanningStrength);
            ExConfig.Set(ExSettingKey.SoundPanningForceScreenSpace, m_originalSoundPanningForceScreenSpace);
            ExConfig.Set(ExSettingKey.SoundPanningInworldThreshold, m_originalSoundPanningInworldThreshold);
            ExConfig.Set(ExSettingKey.SoundPanningInworldDistance, m_originalSoundPanningInworldDistance);
            ExConfig.Set(ExSettingKey.LowHealthSaturationFactor, m_originalLowHealthSaturationFactor);
            ExConfig.Set(ExSettingKey.LowHealthThreshold, m_originalLowHealthThreshold);
            ExConfig.Set(ExSettingKey.LowHealthHurtLevel1Threshold, m_originalLowHealthHurtLevel1Threshold);
            ExConfig.Set(ExSettingKey.LowHealthHurtLevel2Threshold, m_originalLowHealthHurtLevel2Threshold);
            ExConfig.Set(ExSettingKey.HideFilmgrain, m_originalHideFilmgrain);
            ExConfig.Set(ExSettingKey.Language, m_originalLanguage);
            //ExConfig.Set(ExSettingKey.SpectatorsMaximum, m_originalSpectatorsMaximum);
            //ExConfig.Set(ExSettingKey.SpectatorsOnlyModerators, m_originalSpectatorsOnlyModerators);
            //ExConfig.Set(ExSettingKey.VoteKickEnabled, m_originalVoteKickEnabled);
            //ExConfig.Set(ExSettingKey.VoteKickFailCooldown, m_originalVoteKickFailCooldown);
            //ExConfig.Set(ExSettingKey.VoteKickSuccessCooldown, m_originalVoteKickSuccessCooldown);
            ExConfig.Set(ExSettingKey.SubContent, m_originalSubContent);
            ExConfig.Set(ExSettingKey.SubContentDisabledFolders, m_originalSubContentDisabledFolders);
            ExConfig.Set(ExSettingKey.SubContentEnabledFolders, m_originalSubContentEnabledFolders);
            ExConfig.Set(ExSettingKey.ChatWidth, m_originalChatWidth);
            ExConfig.Set(ExSettingKey.ChatHeight, m_originalChatHeight);
            ExConfig.Set(ExSettingKey.ChatExtraHeight, m_originalChatExtraHeight);

            if (m_originalPrimaryColorHex != COLORS.MENU_BLUE.ToHex())
            {
                COLORS.MENU_BLUE = m_originalPrimaryColorHex.ToColor();
                SFDConfig.SaveConfig(SFDConfigSaveMode.Settings);
            }

            if (m_settingsNeedGameRestart)
            {
                MessageStack.Show(LanguageHelper.GetText("menu.settings.restartrequiredmessage"), MessageStackType.Information);
            }

            ParentPanel.CloseSubPanel();
        }, _ =>
        {
            CloseSubPanel();
        }));
    }
}
