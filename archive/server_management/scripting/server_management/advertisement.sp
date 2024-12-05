#if defined _server_management_advertisement_included
 #endinput
#endif
#define _server_management_advertisement_included

//---------------------------------------------------------------
// Advertisements Plugin by Tsunami, fdxx, modified by blueblur
//---------------------------------------------------------------

#define DEBUG_AD 0

#define CFG_PATH "data/server_info.cfg"

#define AD_SEQUENTIAL	0
#define AD_RANDOM		1

static ConVar g_cvPrintType, g_cvTime, g_cvCfgPath;
static ArrayList g_aAdList = null;
static Handle g_hTimer = null;
static int g_iPrintType;
static float g_fTime;
static char g_sCfgPath[PLATFORM_MAX_PATH];
static bool g_bLate = false;

void _advertisement_AskPluginLoad2(bool bLate)
{
	g_bLate = bLate;
}

void _advertisement_OnPluginStart()
{
    LoadTranslation("server_management.advertisement.phrases");
	g_cvPrintType = CreateConVar("l4d2_advertisements_type", "0", "Print type. 0=Sequential, 1=Random");
	g_cvTime = CreateConVar("l4d2_advertisements_time", "120.0", "Print interval time");
	g_cvCfgPath = CreateConVar("l4d2_advertisements_cfg", CFG_PATH, "config file path");

	OnConVarChanged(null, "", "");

	g_cvPrintType.AddChangeHook(OnConVarChanged);
	g_cvTime.AddChangeHook(OnConVarChanged);
	g_cvCfgPath.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_adreload", Cmd_AdReload, ADMFLAG_CONFIG);
	RegAdminCmd("sm_adreprint", Cmd_AdRePrint, ADMFLAG_CONFIG);

#if DEBUG_AD
	RegAdminCmd("sm_adtest", Cmd_AdTest, ADMFLAG_ROOT); // Test command
#endif

	LoadAdvertisements();
	if (g_bLate)
	{
		if (g_fTime >= 0.1)
			g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void _advertisement_OnPluginEnd()
{
	if (g_hTimer != INVALID_HANDLE) 
		g_hTimer = null;
}

void _advertisement_OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
}

void _advertisement_OnMapStart()
{
	if (g_fTime >= 0.1)
		g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

static void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPrintType = g_cvPrintType.IntValue;
	g_fTime = g_cvTime.FloatValue;
	g_cvCfgPath.GetString(g_sCfgPath, sizeof(g_sCfgPath));

	if (convar == g_cvCfgPath)
		LoadAdvertisements();
}

static void LoadAdvertisements()
{
	char sBuffer[MAX_MESSAGE_LENGTH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "%s", g_sCfgPath);

	KeyValues kv = new KeyValues("");
	kv.SetEscapeSequences(true); // Allow newline characters to be read.

	if (!kv.ImportFromFile(sBuffer))
    {
        delete kv;
		LogError("Failed to load: %s", sBuffer);
        return;
    }

	FindConVar("hostport").GetString(sBuffer, sizeof(sBuffer)); // Get config by port
	Format(sBuffer, sizeof(sBuffer), "%s/advertisements", sBuffer);

	if (kv.JumpToKey(sBuffer) && kv.GotoFirstSubKey(false))
	{
		if (g_aAdList) delete g_aAdList;
		g_aAdList = new ArrayList(ByteCountToCells(MAX_MESSAGE_LENGTH));

		do
		{
			kv.GetString(NULL_STRING, sBuffer, sizeof(sBuffer));
			g_aAdList.PushString(sBuffer);
		}
		while (kv.GotoNextKey(false));
	}

	delete kv;
}

static void PrintAd_Timer(Handle timer)
{
#if DEBUG_AD
	PrintToServer("Advertising: timer triggered, g_aAdList.Length: %d.", g_aAdList.Length);
#endif
	if (!g_aAdList || !g_aAdList.Length)
		return;

	char buffer[MAX_MESSAGE_LENGTH];
	char time[128], sMap[128];
	char sTranlated[MAX_MESSAGE_LENGTH];
	FormatTime(time, sizeof(time), "%F %T");
    GetCurrentMap(sMap, sizeof(sMap));
    g_aAdList.GetString(GetIndex(), buffer, sizeof(buffer));

#if DEBUG_AD
	PrintToServer("Advertising: Retreived string: %s.", buffer);
#endif

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        Format(sTranlated, sizeof(sTranlated), "%T", buffer, i);
#if DEBUG_AD
		PrintToServer("Advertising: Translated for %N's string: %s", i, sTranlated);
#endif
	    ReplaceString(sTranlated, sizeof(sTranlated), "{time}", time);
        ReplaceString(sTranlated, sizeof(sTranlated), "{map}", sMap);
	    CPrintToChat(i, "%s", sTranlated);
    }
}

static int GetIndex()
{
	if (g_iPrintType == AD_RANDOM)
		return GetRandomIntEx(0, g_aAdList.Length-1);

	if (g_iPrintType == AD_SEQUENTIAL)
	{
		static int index = -1;
		if (++index >= g_aAdList.Length)
			index = 0;
		return index;
	}

	return -1;
}

static stock int GetRandomIntEx(int min, int max)
{
	return GetURandomInt() % (max - min + 1) + min;
}

static Action Cmd_AdReload(int client, int args)
{
	LoadAdvertisements();
	return Plugin_Handled;
}

static Action Cmd_AdRePrint(int client, int args)
{
	if (g_hTimer != INVALID_HANDLE) KillTimer(g_hTimer);
	if (g_fTime >= 0.1)
		g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

#if DEBUG_AD
static Action Cmd_AdTest(int client, int args)
{
	if (!g_aAdList || !g_aAdList.Length)
		ReplyToCommand(client, "No advertisements loaded.");

	char buffer[MAX_MESSAGE_LENGTH];
	char time[128], sMap[128];
	FormatTime(time, sizeof(time), "%F %T");
    GetCurrentMap(sMap, sizeof(sMap));
    g_aAdList.GetString(GetIndex(), buffer, sizeof(buffer));
	ReplyToCommand(client, "Ad: %s", buffer);

    static char sTranlated[MAX_MESSAGE_LENGTH];
    Format(sTranlated, sizeof(sTranlated), "%T", buffer, client);
	ReplaceString(sTranlated, sizeof(sTranlated), "{time}", time);
    ReplaceString(sTranlated, sizeof(sTranlated), "{map}", sMap);
	CReplyToCommand(client, "sTranslated: %s", sTranlated);

	return Plugin_Handled;
}
#endif