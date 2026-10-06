using Microsoft.Xna.Framework.Graphics;
using SFD;
using SFD.MenuControls;
using SFDCT.UI.Panels;
using Color = Microsoft.Xna.Framework.Color;
using Rectangle = Microsoft.Xna.Framework.Rectangle;

namespace SFDCT.UI.MenuItems;

internal class ExMenuItemDropdownColor : MenuItemButton
{
    internal ExMenuItemDropdownColor(string name, Color color, params Color[] availableColors) : base(name, null)
    {
        ChooseEvent = (ControlEvents.ChooseEvent)Delegate.Combine(ChooseEvent, new ControlEvents.ChooseEvent(actionOpenDropdown));

        m_color = color;
        m_availableColors = availableColors;
    }

    public Color Color
    {
        get { return m_color; }
    }

    public Color[] Colors
    {
        get { return m_availableColors; }
    }

    public override void Draw(SpriteBatch batch, float elapsed)
    {
        base.Draw(batch, elapsed);

        var colorRectangle = new Rectangle((int)Position.X + Width - 16 - 8, (int)Position.Y + Menu.ITEM_HEIGHT / 2 - 8, 16, 16);

        batch.Draw(Icons.WhitePixel, colorRectangle, Color.Gray);
        colorRectangle.Inflate(-2, -2);
        batch.Draw(Icons.WhitePixel, colorRectangle, m_color);
    }

    private void TriggerValueChangedEvent()
    {
        ValueChangedEvent?.Invoke(this);
    }

    internal void SetColor(Color newColor)
    {
        m_color = newColor;

        TriggerValueChangedEvent();

        Deselect();
        CloseSubPanel();
    }

    private void actionOpenDropdown(object _)
    {
        m_subPanel = new(this);
        m_subPanel.SetSelectedColor(m_availableColors.ToList().IndexOf(m_color));

        ParentMenu.OpenSubPanel(m_subPanel);
        Focus = Focus.HardFocus;
    }

    internal event MenuItemValueChangedEvent ValueChangedEvent;
    private ExDropdownColorPanel m_subPanel;
    private Color m_color;
    private Color[] m_availableColors;
}
