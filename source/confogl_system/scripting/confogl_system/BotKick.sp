#if defined __bot_kick_included
	#endinput
#endif
#define __bot_kick_included

#define BK_MODULE_NAME				"BotKick"

#define CHECKALLOWEDTIME			0.1
#define BOTREPLACEVALIDTIME			0.2

static const char InfectedNames[][] =
{
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger"
};

static const char SurvivorNames[][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Louis",
	"Francis"
};

static int
	BK_iEnableInfBK = 0,
	BK_iEnableSurBK = 0,
	BK_lastvalidbot = -1;

static ConVar
	BK_hEnableInfBK = null,
	BK_hEnableSurBK = null;

void BK_OnModuleStart()
{
	BK_hEnableInfBK = CreateConVarEx( \
		"blockinfectedbots", \
		"0", \
		"Blocks infected bots from joining the game.", \
		_, true, 0.0, true, 1.0 \
	);

	BK_hEnableSurBK = CreateConVarEx( \
		"blocksurvivorsbots", \
		"0", \
		"Blocks survivor bots from joining the game.", \
		_, true, 0.0, true, 1.0 \
	);

	BK_iEnableInfBK = BK_hEnableInfBK.IntValue;
	BK_iEnableSurBK = BK_hEnableSurBK.IntValue;
	BK_hEnableSurBK.AddChangeHook(BK_ConVarChange);
	BK_hEnableInfBK.AddChangeHook(BK_ConVarChange);

	HookEvent("player_bot_replace", BK_PlayerBotReplace);
}

static void BK_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	BK_iEnableInfBK = BK_hEnableInfBK.IntValue;
	BK_iEnableSurBK = BK_hEnableSurBK.IntValue;
}

bool BK_OnClientConnect(int iClient)
{
	if (!IsPluginEnabled() || !IsFakeClient(iClient))
		return true;

	// If the client doesn't have a bot infected's name, let it in
	if (BK_iEnableInfBK == 0 || !IsInvalidInfected(iClient))
		return true;

	if (BK_iEnableSurBK == 0 || !IsInvalidSurvivors(iClient))
		return true;

	if (BK_iEnableInfBK == 1 || BK_iEnableSurBK == 1) 
	{
		// Check this bot in CHECKALLOWEDTIME seconds to see if he's supposed to be allowed.
		CreateTimer(CHECKALLOWEDTIME, BK_CheckBotReplace_Timer, iClient, TIMER_FLAG_NO_MAPCHANGE);
		//BK_bAllowBot = false;
		return true;
	}

	g_hLogger.InfoEx("[%s] Kicking infected bot %N", BK_MODULE_NAME, iClient)
	KickClient(iClient, "[Confogl] Kicking infected bot..."); // If all else fails, bots arent allowed and must be kicked

	return false;
}

static void BK_CheckBotReplace_Timer(Handle hTimer, int iClient)
{
	if (iClient != BK_lastvalidbot && IsClientInGame(iClient) && IsFakeClient(iClient))
	{
		g_hLogger.InfoEx("[%s] Kicking late bot %N", BK_MODULE_NAME, iClient)
		KickClient(iClient, "[Confogl] Kicking late bot...");
	}

	else BK_lastvalidbot = -1;
}

static void BK_PlayerBotReplace(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("player"));

	if (iClient > 0 && IsClientInGame(iClient) && GetClientTeam(iClient) == L4D2Team_Infected) 
	{
		BK_lastvalidbot = GetClientOfUserId(hEvent.GetInt("bot"));
		CreateTimer(BOTREPLACEVALIDTIME, BK_CancelValidBot_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void BK_CancelValidBot_Timer(Handle hTimer)
{
	BK_lastvalidbot = -1;
}

static bool IsInvalidInfected(int iClient)
{
	char sBotName[11];
	GetClientName(iClient, sBotName, sizeof(sBotName));

	for (int i = 0; i < sizeof(InfectedNames); i++) 
	{
		if (StrContains(sBotName, InfectedNames[i], false) != -1)
			return false;
	}

	return true;
}

static bool IsInvalidSurvivors(int iClient)
{
	char sBotName[11];
	GetClientName(iClient, sBotName, sizeof(sBotName));

	for (int i = 0; i < sizeof(SurvivorNames); i++) 
	{
		if (StrContains(sBotName, SurvivorNames[i], false) != -1)
			return false;
	}

	return true;
}