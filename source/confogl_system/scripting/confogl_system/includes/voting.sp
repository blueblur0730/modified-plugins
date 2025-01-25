#if defined __confogl_voting_included
	#endinput
#endif
#define __confogl_voting_included

enum struct VoteData
{
	bool bVoteInProgress;
	bool bVoteStart;
	char sDisplayText[64];
	char sInfoStr[512];
	int iInitiator;
	int iYesCount;
	int iNoCount;
	int iPlayerCount;
	bool bCanVote[MAXPLAYERS+1];
}

static VoteData g_VoteData;
static int g_iVoteController;
static PrivateForward g_hFwd;
static ConVar g_cvInitiatorAutoVoteYes;
static Handle g_hEndVoteTimer;

void VT_OnPluginStart()
{
	g_cvInitiatorAutoVoteYes = CreateConVarEx("initiator_auto_voteyes", "1", "If 1, initiator will auto vote yes", FCVAR_NONE, true, 0.0, true, 1.0);
	AddCommandListener(CommandListener_Vote, "vote");
}

void VT_OnMapStart()
{
	delete g_hEndVoteTimer;
	g_VoteData.bVoteInProgress = false;
}

void VT_OnMapEnd()
{
	delete g_hEndVoteTimer;
	g_VoteData.bVoteInProgress = false;
}

methodmap L4D2NativeVote {
    public L4D2NativeVote(L4D2VoteHandler handler) {
        if (!ShouldAllowNewVote())
        {
		    g_hLogger.Info("[Confogl] Failed to create new vote, a vote is in progress.");
            return view_as<L4D2NativeVote>(0);
        }

	    ResetVote();
	    g_hFwd = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	    g_hFwd.AddFunction(GetMyHandle(), handler);
	    SetVoteEntityStatus(0);
	    g_VoteData.bVoteInProgress = true;

        return view_as<L4D2NativeVote>(1);
    }

    public void SetTitle(const char[] title, any ...) {
        VFormat(g_VoteData.sDisplayText, sizeof(g_VoteData.sDisplayText), title, 3);
    }

	public void GetTitle(char[] buffer, int maxlength) {
        Format(buffer, maxlength, g_VoteData.sDisplayText);
    }

	public void SetInfo(const char[] fmt, any ...) {
        VFormat(g_VoteData.sInfoStr, sizeof(g_VoteData.sInfoStr), fmt, 3);
    }

	public void GetInfo(char[] buffer, int maxlength) {
        Format(buffer, maxlength, g_VoteData.sInfoStr);
    }

	property int Initiator {
		public set(int client) {
            g_VoteData.iInitiator = client;
        }

		public get() {
            return g_VoteData.iInitiator;
        }
	}

	// Broadcasts a vote to a list of clients.  
	//
	// @param clients		Array of clients to broadcast to.
	// @param numClients	Number of clients in the array.
	// @param time			Maximum time to leave vote on the screen.
	// @return				True on success, False if in game numClients < 1 
	//						Or vote is invalid, Or there are other vote in progress.
	public bool DisplayVote(int[] clients, int numClients, float time) {
        if (!this || !g_VoteData.bVoteInProgress || g_VoteData.bVoteStart)
		    return false;

	    int client;
	    for (int i = 0; i < numClients; i++)
	    {
		    client = clients[i];
		    if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
		    {
		    	clients[g_VoteData.iPlayerCount++] = client;
		    	g_VoteData.bCanVote[client] = true;
		    }
	    }
	
	    if (g_VoteData.iPlayerCount < 1)
	    {
		    ResetVote();
		    return false;
	    }
	
	    int initiator = g_VoteData.iInitiator;
	    char sName[128];
	    if (initiator > 0 && initiator <= MaxClients && IsClientInGame(initiator))
	    {
		    FormatEx(sName, sizeof(sName), "%N", initiator);
		    if (g_cvInitiatorAutoVoteYes.BoolValue)
			    CreateTimer(0.1, InitiatorVote_Timer, GetClientUserId(initiator));
	    }

	    BfWrite bf = UserMessageToBfWrite(StartMessage("VoteStart", clients, g_VoteData.iPlayerCount, USERMSG_RELIABLE));
	    bf.WriteByte(-1);							// team. Valve represents no team as -1
	    bf.WriteByte(initiator);					// initiator
	    bf.WriteString("#L4D_TargetID_Player");		// issue. L4D_TargetID_Player which will let you create any vote you want.
	    bf.WriteString(g_VoteData.sDisplayText);	// Vote issue text
	    bf.WriteString(sName);						// initiatorName
	    EndMessage();

	    g_VoteData.bVoteStart = true;
	    delete g_hEndVoteTimer;
	    g_hEndVoteTimer = CreateTimer(time, EndVote_Timer);

	    UpdateVotes(VoteAction_Start, initiator);
	    return true;
    }

	property int YesCount {
		public set(int value) {
            g_VoteData.iYesCount = value;
        }

		public get() {
            return g_VoteData.iYesCount;
        }
	}

	property int NoCount {
		public set(int value) {
            g_VoteData.iNoCount = value;
        }

		public get() {
            return g_VoteData.iNoCount;
        }
	}

	property int PlayerCount {
		public get() {
            return g_VoteData.iPlayerCount;
        }
	}
	
	public void SetPass(const char[] fmt, any ...) {
        char buffer[256];
        BfWrite bf = UserMessageToBfWrite(StartMessageAll("VotePass", USERMSG_RELIABLE));
	    bf.WriteByte(-1);
	    bf.WriteString("#L4D_TargetID_Player");
        VFormat(buffer, sizeof(buffer), fmt, 3);
	    bf.WriteString(buffer);
	    EndMessage();
        RequestFrame(OnNextFrame_ResetVote);
    }

	public void SetFail() {
	    BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteFail", USERMSG_RELIABLE));
	    bf.WriteByte(-1);
	    EndMessage();
    }
}

static void InitiatorVote_Timer(Handle timer, int userid)
{
	if (!g_VoteData.bVoteInProgress)
		return;

	int client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		FakeClientCommand(client, "Vote Yes");
}

static void EndVote_Timer(Handle timer)
{
	if (g_VoteData.bVoteInProgress)
		UpdateVotes(VoteAction_End, VOTEEND_TIMEEND);
	
	g_hEndVoteTimer = null;
}

static Action CommandListener_Vote(int client, const char[] command, int argc)
{
	if (g_VoteData.bVoteInProgress && g_VoteData.bCanVote[client])
	{
		g_VoteData.bCanVote[client] = false;
		char sVote[4];
		if (GetCmdArgString(sVote, sizeof(sVote)) > 1)
		{
			if (strcmp(sVote, "Yes", false) == 0)
			{
				g_VoteData.iYesCount++;
				UpdateVotes(VoteAction_PlayerVoted, client, VOTE_YES);
			}
			else if (strcmp(sVote, "No", false) == 0)
			{
				g_VoteData.iNoCount++;
				UpdateVotes(VoteAction_PlayerVoted, client, VOTE_NO);
			}
		}
	}

	return Plugin_Continue;
}

// function void (L4D2NativeVote vote, VoteAction action, int param1, int param2);
static void UpdateVotes(VoteAction action, int param1 = -1, int param2 = -1)
{
	if (!g_VoteData.bVoteInProgress) return;

	Event event = CreateEvent("vote_changed", true);
	event.SetInt("yesVotes", g_VoteData.iYesCount);
	event.SetInt("noVotes", g_VoteData.iNoCount);
	event.SetInt("potentialVotes", g_VoteData.iPlayerCount);
	event.Fire();

	switch (action)
	{
		case VoteAction_Start, VoteAction_PlayerVoted:
		{
			Call_StartForward(g_hFwd);
			Call_PushCell(0);
			Call_PushCell(action);
			Call_PushCell(param1);
			Call_PushCell(param2);
			Call_Finish();

			if (g_VoteData.iYesCount + g_VoteData.iNoCount >= g_VoteData.iPlayerCount)
			{
				for (int i; i <= MaxClients; i++)
					g_VoteData.bCanVote[i] = false;
					
				UpdateVotes(VoteAction_End, VOTEEND_FULLVOTED);
			}
		}
		case VoteAction_End:
		{
			Call_StartForward(g_hFwd);
			Call_PushCell(0);
			Call_PushCell(action);
			Call_PushCell(param1);
			Call_PushCell(param2);
			Call_Finish();
		}
	}
}

static void OnNextFrame_ResetVote()
{
	ResetVote();
}

static void ResetVote()
{
	g_VoteData.bVoteInProgress = false;
	g_VoteData.bVoteStart = false;

	delete g_hEndVoteTimer;
	delete g_hFwd;

	if (CheckVoteController())
		SetVoteEntityStatus(-1);

	g_VoteData.sDisplayText[0] = '\0';
	g_VoteData.sInfoStr[0] = '\0';
	g_VoteData.iInitiator = 0;
	g_VoteData.iYesCount = 0;
	g_VoteData.iNoCount = 0;
	g_VoteData.iPlayerCount = 0;

	for (int i; i <= MaxClients; i++)
		g_VoteData.bCanVote[i] = false;
}

bool ShouldAllowNewVote()
{
	if (!g_VoteData.bVoteInProgress && CheckVoteController())
		return GetVoteEntityStatus() == -1;
	
	return false;
}

bool CheckVoteController()
{
	g_iVoteController = FindEntityByClassname(MaxClients+1, "vote_controller");
	return g_iVoteController != -1;
}

int GetVoteEntityStatus()
{
	return GetEntProp(g_iVoteController, Prop_Send, "m_activeIssueIndex");
}

void SetVoteEntityStatus(int value)
{
	SetEntProp(g_iVoteController, Prop_Send, "m_activeIssueIndex", value);
}