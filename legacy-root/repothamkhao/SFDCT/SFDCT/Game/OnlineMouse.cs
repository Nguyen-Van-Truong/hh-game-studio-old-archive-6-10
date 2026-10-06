using Box2D.XNA;
using Microsoft.Xna.Framework;
using Networking.LidgrenAdapter;
using SFD;
using SFDCT.Sync;

namespace SFDCT.Game;

internal class OnlineMouse
{
    internal double NetUpdate;
    internal bool IsDisposed => m_disposed;
    internal bool IsInactive => NetTime.Now - NetUpdate >= 3.0;

    private bool m_disposed;
    private GameConnectionTag m_tag;
    // private ExNetMessage.MouseClientUpdate.Data m_data;
    private Vector2 m_b2Position;
    private MouseJoint m_joint;
    private ObjectData m_object;
    private World m_world;
    private bool m_isLeftMouseButtonPressed;
    private bool m_isControlPressed;
    private bool m_isDeletePressed;
    private bool m_wasDeletePressed;

    internal OnlineMouse(GameConnectionTag tag)
    {
        m_disposed = false;
        m_tag = tag;
        m_joint = null;
        m_world = null;
        m_object = null;

        ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Created");
    }

    internal GameConnectionTag GameConnectionTag()
    {
        return m_tag;
    }

    internal void SetData(ExNetMessage.MouseClientUpdate.Data data)
    {
        m_isLeftMouseButtonPressed = data.LeftMouseButtonPressed;
        m_isControlPressed = data.ControlPressed;

        m_wasDeletePressed = m_isDeletePressed;
        m_isDeletePressed = data.DeletePressed;

        m_b2Position = data.Box2DPosition;
    }

    internal void Update(GameWorld world)
    {
        // the majority of the structure of this code is taken from 'GameWorld.UpdateDebugMouse'

        if (m_isDeletePressed && !m_wasDeletePressed)
        {
            m_wasDeletePressed = m_isDeletePressed;

            var allObjectsAtPosition = world.GetAllObjectsAtPosition(m_b2Position);
            if (allObjectsAtPosition.Count > 0)
            {
                allObjectsAtPosition.Sort(new Comparison<ObjectData>(world.DeleteObjectAtCursorSorting));

                ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Deleting ({allObjectsAtPosition[0].ObjectID}) {allObjectsAtPosition[0].MapObjectID}");
                allObjectsAtPosition[0].Destroy();
            }

            return;
        }

        if (!m_isLeftMouseButtonPressed)
        {
            DestroyJoint();
            m_world = null;
        }
        else
        {
            if (m_isControlPressed) return;

            if (m_object == null)
            {
                var objectAtPosition = world.GetObjectAtPosition(m_b2Position, true, true, true, world.EditGroupID, new Func<ObjectData, bool>(world.DebugMouseFilter));

                if (objectAtPosition != null && objectAtPosition.IsDynamic)
                {
                    CreateJoint(objectAtPosition);
                }
            }

            if (m_object != null && !m_object.IsDisposed && m_object.IsPlayer)
            {
                var player = (Player)m_object.InternalData;
                if (!player.IsRemoved && !player.Falling) player.Fall();
            }

            if (m_joint != null && !m_joint.IsRemoved)
            {
                m_joint.SetTarget(m_b2Position);
            }
        }
    }

    internal void Dispose()
    {
        if (m_disposed) return;
        m_disposed = true;

        ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Disposing...");

        m_tag = null;
        DestroyJoint();
        m_world = null;
        m_object = null;
    }

    internal void CreateJoint(ObjectData target)
    {
        m_world = target.Body.GetWorld();
        m_object = target;
        var body = m_object.Body;

        body.SetAwake(true);

        var totalMass = body.GetMass();
        var weldedBodies = body.GetConnectedWeldedBodies();
        if (weldedBodies != null)
        {
            foreach (var weldedBody in weldedBodies)
            {
                totalMass += weldedBody.GetMass();
            }
        }

        var jointDef = GetJointDef();
        jointDef.target = m_b2Position;
        jointDef.localAnchor = body.GetLocalPoint(m_b2Position);
        jointDef.maxForce *= totalMass;
        jointDef.bodyA = m_world.GroundBody;
        jointDef.bodyB = body;

        ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Adding ({m_object.ObjectID}) {m_object.MapObjectID}");

        m_joint = (MouseJoint)m_world.CreateJoint(jointDef);
    }

    internal void DestroyJoint()
    {
        if (m_world == null || m_joint == null) return;

        if (m_object != null && !m_object.IsDisposed)
        {
            ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Releasing ({m_object.ObjectID}) {m_object.MapObjectID}");
        }
        else
        {
            ConsoleOutput.ShowMessage(ConsoleOutputType.GameStatus, $"[Mouse '{m_tag.FirstGameUser.GetProfileName()}']: Releasing");
        }

        m_world.DestroyJoint(m_joint);
        m_joint = null;
        m_object = null;
    }

    internal static MouseJointDef GetJointDef()
    {
        // these are the values GameWorld.UpdateDebugMouse uses
        return new MouseJointDef()
        {
            maxForce = 150,
            dampingRatio = 1,
            frequencyHz = 40,
            collideConnected = false,
        };
    }
}
