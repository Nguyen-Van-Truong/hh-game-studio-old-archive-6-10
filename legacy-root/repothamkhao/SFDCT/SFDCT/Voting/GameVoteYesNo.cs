using SFD;
using SFD.Voting;

namespace SFDCT.Voting;

internal class GameVoteYesNo : GameVote
{
    internal const sbyte ALTERNATIVE_INDEX_YES = 0;
    internal const sbyte ALTERNATIVE_INDEX_NO = 1;

    private bool m_resolved;

    internal GameVoteYesNo(int voteID, params string[] description) : base(voteID, (GameVote.Type)2)
    {
        DescriptionTextID = "button.vote";
        DescriptionParameters = description;

        Alternatives.Add(new(ALTERNATIVE_INDEX_YES, "general.yes"));
        Alternatives.Add(new(ALTERNATIVE_INDEX_NO, "general.no"));
    }

    private GameVoteAlternative GetWinningAlternative()
    {
        int highestVoteCount;
        int overHalfCount = ValidRemoteUniqueIdentifiers.Count / 2 + 1;
        GameVoteAlternative highestVoted = GetHighestVoteCount(out highestVoteCount);

        if (highestVoted != null && highestVoteCount >= overHalfCount)
        {
            return highestVoted;
        }

        return null;
    }

    public override void AnswersUpdated(GameInfo gameInfo)
    {
        if (ValidRemoteUniqueIdentifiers.Count == VotedRemoteUniqueIdentifiers.Count)
        {
            VoteTimeout(gameInfo);
            Remove();
            return;
        }

        GameVoteAlternative winnerAlternative = GetWinningAlternative();
        if (winnerAlternative != null)
        {
            VoteTimeout(gameInfo);
            Remove();
        }
    }

    public override void VoteTimeout(GameInfo gameInfo)
    {
        if (m_resolved) return;
        m_resolved = true;

        GameVoteAlternative winnerAlternative = GetWinningAlternative();
        if (winnerAlternative != null)
        {
            if (winnerAlternative.Index == ALTERNATIVE_INDEX_YES)
            {
                OnYes(gameInfo);
            }
            else
            {
                OnNo(gameInfo);
            }
        }
        else
        {
            OnTie(gameInfo);
        }

        gameInfo.VoteInfo.DeleteVote(this);
    }

    public virtual void OnTie(GameInfo gameInfo) { }
    public virtual void OnNo(GameInfo gameInfo) { }
    public virtual void OnYes(GameInfo gameInfo) { }
}
