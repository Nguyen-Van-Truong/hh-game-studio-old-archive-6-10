using SFD;

namespace SFDCT.Voting;

internal class GameVoteManual : GameVoteYesNo
{
    internal GameVoteManual(int voteID, params string[] description) : base(voteID, description) { }

    private void ShowResults(GameInfo gameInfo)
    {
        gameInfo.ShowChatMessage(new(LanguageHelper.GetText("sfdct.vote.manual", DescriptionParameters[0], Answers.Count(a => a.SelectedAlternativeIndex == ALTERNATIVE_INDEX_YES).ToString(), Answers.Count(a => a.SelectedAlternativeIndex == ALTERNATIVE_INDEX_NO).ToString()), Microsoft.Xna.Framework.Color.Yellow));
    }

    public override void OnTie(GameInfo gameInfo)
    {
        ShowResults(gameInfo);
    }

    public override void OnNo(GameInfo gameInfo)
    {
        ShowResults(gameInfo);
    }

    public override void OnYes(GameInfo gameInfo)
    {
        ShowResults(gameInfo);
    }
}
