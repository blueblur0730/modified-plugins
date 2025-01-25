#if defined __confogl_constants_included
	#endinput
#endif
#define __confogl_constants_included

#define TRANSLATION_FILE "confogl_system.phrases"
#define MATCHMODES_PATH "configs/matchmodes.txt"
#define TEAM_SPECTATE 1

enum
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor, // Probably for maps that contain survivors from the first part and from part 2

	L4D2Team_Size // 5 size
};

enum VoteAction
{
	VoteAction_Start,		// param1 = initiator
	VoteAction_PlayerVoted,	// param1 = client, param2 = VOTE_YES Or VOTE_NO
	VoteAction_End,			// param1 = reason
};

enum 
{
	VOTE_YES = 1,
	VOTE_NO = 2,
};

// VoteAction_End reason
enum 
{
	VOTEEND_FULLVOTED = 1,	// All players have voted
	VOTEEND_TIMEEND = 2,	// Time to vote ends
};

/**
 * Called when a VoteAction is completed.
 *
 * @param vote              The vote being acted upon.
 * @param action            The action of the vote.
 * @param param1            First action parameter.
 * @param param2            Second action parameter.
 */
typedef L4D2VoteHandler = function void (L4D2NativeVote vote, VoteAction action, int param1, int param2);