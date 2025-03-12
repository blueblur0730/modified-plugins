#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>
#include <gamedata_wrapper>

// all references from https://github.com/nillerusr/source-engine
#define GAMEDATA_FILE		  "l4d2_block_no_steam_logon"
#define DETOUR_FUNCTION		  "CSteam3Server::OnValidateAuthTicketResponseHelper"
#define SDKCALL_GETCLIENTNAME "CBaseClient::GetClientName"
#define SDKCALL_ISTIMINGOUT	  "CNetChan::IsTimingOut"
#define SDKCALL_DISCONNECT	  "CBaseClient::Disconnect"
#define SDKCALL_GETNETCHANNEL "CBaseClient::GetNetChannel"
#define OFFSET_NAME			  "CBaseClient->m_Name"
#define CLIENTNAME_TIMED_OUT  "%s timed out."

Handle
	g_hSDKCall_GetClientName,
	g_hSDKCall_IsTimingOut,
	g_hSDKCall_Disconnect,
	g_hSDKCall_GetNetChannel;

GlobalForward	g_hFWD_OnValidateAuthTicketResponseHelper = null;
ConVar			g_hCvar_DropOrNot						  = null;
ConVar			g_hCvar_CheckTimeOut					  = null;
bool			g_bDropOrNot							  = false;
bool			g_bCheckTimeOut							  = false;

OperatingSystem g_iOS									  = OS_UnknownPlatform;
int				g_iOff_CBaseClient_m_Name				  = -1;

enum EAuthSessionResponse
{
	k_EAuthSessionResponseOK						   = 0,	   // Steam has verified the user is online, the ticket is valid and ticket has not been reused.
	k_EAuthSessionResponseUserNotConnectedToSteam	   = 1,	   // The user in question is not connected to steam
	k_EAuthSessionResponseNoLicenseOrExpired		   = 2,	   // The license has expired.
	k_EAuthSessionResponseVACBanned					   = 3,	   // The user is VAC banned for this game.
	k_EAuthSessionResponseLoggedInElseWhere			   = 4,	   // The user account has logged in elsewhere and the session containing the game instance has been disconnected.
	k_EAuthSessionResponseVACCheckTimedOut			   = 5,	   // VAC has been unable to perform anti-cheat checks on this user
	k_EAuthSessionResponseAuthTicketCanceled		   = 6,	   // The ticket has been canceled by the issuer
	k_EAuthSessionResponseAuthTicketInvalidAlreadyUsed = 7,	   // This ticket has already been used, it is not valid.
	k_EAuthSessionResponseAuthTicketInvalid			   = 8,	   // This ticket is not from a user instance currently connected to steam.
															   // k_EAuthSessionResponsePublisherIssuedBan = 9,			// The user is banned for this game. The ban came via the web api and not VAC (not in l4d engine)
}

methodmap INetChannel{
	public bool IsTimingOut(){
		return SDKCall(g_hSDKCall_IsTimingOut, view_as<Address>(this));
	}
}

methodmap CBaseClient
{
	public INetChannel GetNetChannel(){
		return view_as<INetChannel>(SDKCall(g_hSDKCall_GetNetChannel, view_as<Address>(this)));
	}

	public void Disconnect(const char[] reason){
		SDKCall(g_hSDKCall_Disconnect, view_as<Address>(this), reason);
	}

	public void GetClientName(char[] name, int maxlen){
		SDKCall(g_hSDKCall_GetClientName, view_as<Address>(this), name, maxlen);
	}
}

#define PLUGIN_VERSION "1.2.3"

public Plugin myinfo =
{
	name		= "[L4D2] Block No Steam Logon",
	author		= "blueblur",
	description = "Attempts to bypass server's 'no steam logon' disconnection.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	// forward void OnValidateAuthTicketResponseHelper(const char[] sName, EAuthSessionResponse response);
	g_hFWD_OnValidateAuthTicketResponseHelper = new GlobalForward("OnValidateAuthTicketResponseHelper", ET_Event, Param_Any, Param_String);
	RegPluginLibrary("l4d2_block_no_steam_logon");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_no_steam_logon_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvar_DropOrNot = CreateConVar("l4d2_block_no_steam_logon_enable", "1", "Enable to prevent no steam logon disconnection.", _, true, 0.0, true, 1.0);
	g_hCvar_DropOrNot.AddChangeHook(OnCvarChange);

	g_hCvar_CheckTimeOut = CreateConVar("l4d2_block_no_steam_logon_check_timeout", "1", "Enable to check client's timeout.", _, true, 0.0, true, 1.0);
	g_hCvar_CheckTimeOut.AddChangeHook(OnCvarChange);
	OnCvarChange(null, "", "");
	InitGameData();
}

void OnCvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDropOrNot	= g_hCvar_DropOrNot.BoolValue;
	g_bCheckTimeOut = g_hCvar_CheckTimeOut.BoolValue;
}

MRESReturn DTR_OnValidateAuthTicketResponseHelper_Pre(DHookParam hParam)
{
	CBaseClient pBaseClient = view_as<CBaseClient>(hParam.Get(1));

	// invalid addresses cause crashes.
	if (view_as<Address>(pBaseClient) == Address_Null)
		return MRES_Ignored;

	char sName[128];
	switch (g_iOS)
	{
		// not sure with windows.
		case OS_Windows:
			ReadMemoryString(view_as<Address>(pBaseClient) + view_as<Address>(g_iOff_CBaseClient_m_Name), sName, sizeof(sName));

		case OS_Linux:
		{
			pBaseClient.GetClientName(sName, sizeof(sName));
			if (sName[0] == '\0')
				ReadMemoryString(view_as<Address>(pBaseClient) + view_as<Address>(g_iOff_CBaseClient_m_Name), sName, sizeof(sName));
		}
	}

	EAuthSessionResponse response = view_as<EAuthSessionResponse>(hParam.Get(2));
	PrintLog("### Found a client with auth problem, name: %s, EAuthSessionResponse: %d", sName, response);

	Call_StartForward(g_hFWD_OnValidateAuthTicketResponseHelper);
	Call_PushCell(response);
	Call_PushString(sName);
	Call_Finish();

	// to know if your steam no logon is caused by game crash or internet cut off anything related.
	// in that case, we drop the client manully. this code is not represented in l4d2 engine, maybe the newer engine?
	// by default the time out check time is 4.0s in CNetChan::IsTimingOut().
	// https://github.com/nillerusr/source-engine/blob/29985681a18508e78dc79ad863952f830be237b6/engine/sv_steamauth.cpp#L623
	// https://github.com/nillerusr/source-engine/blob/29985681a18508e78dc79ad863952f830be237b6/engine/net_chan.cpp#L58
	if (g_bCheckTimeOut)
	{
		INetChannel netchan = pBaseClient.GetNetChannel();
		if (netchan && netchan.IsTimingOut())
		{
			char reason[128];
			Format(reason, sizeof(reason), CLIENTNAME_TIMED_OUT, sName);
			PrintLog("### Disconnecting timed out client, reason: %s", reason);
			pBaseClient.Disconnect(reason);	   // console msg: Dropped xxx from server ('reason')
			return MRES_Supercede;
		}
	}

	/*
		cmp     dword ptr [edi+98h], 1 ; jumptable 00200ADB cases 1,6-8
		jz      short loc_200B10
		mov     eax, [ebx]
		mov     [ebp+arg_4], offset aNoSteamLogon ; "No Steam logon\n"

		1, 6, 7, 8 indicates no steam logon failure.
		in the newer engine, the message is different, not all using "No Steam logon\n". see the leaked code.
	*/

	switch (response)
	{
		// dont let no steam logon drop you.
		case k_EAuthSessionResponseUserNotConnectedToSteam,
			k_EAuthSessionResponseAuthTicketCanceled,
			k_EAuthSessionResponseAuthTicketInvalidAlreadyUsed,
			k_EAuthSessionResponseAuthTicketInvalid:
		{
			if (g_bDropOrNot)
			{
				PrintLog("### Bypassing no steaam logon disconnection for client: %s", sName);
				return MRES_Supercede;
			}
		}
	}

	return MRES_Ignored;
}

void InitGameData()
{
	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
	g_iOS			   = gd.OS;
	if (g_iOS == OS_UnknownPlatform)
		SetFailState("Invalid operating system.");

	g_iOff_CBaseClient_m_Name = gd.GetOffset(OFFSET_NAME);
	gd.CreateDetourOrFailEx(DETOUR_FUNCTION, DTR_OnValidateAuthTicketResponseHelper_Pre);

	// SDKCallParamsWrapper params1[] = {{SDKType_PlainOldData, SDKPass_Plain}};
	// SDKCallParamsWrapper ret1 = {SDKType_PlainOldData, SDKPass_Plain};
	// g_hSDKCall_GetClient = gd.CreateSDKCallOrFail(SDKCall_Server, SDKConf_Signature, SDKCALL_GETCLIENT, params1, sizeof(params1), true, ret1);

	if (g_iOS == OS_Linux)
	{
		SDKCallParamsWrapper ret1 = { SDKType_String, SDKPass_Pointer };
		g_hSDKCall_GetClientName  = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_GETCLIENTNAME, _, _, true, ret1);
	}

	SDKCallParamsWrapper ret2	   = { SDKType_Bool, SDKPass_Plain };
	g_hSDKCall_IsTimingOut		   = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_ISTIMINGOUT, _, _, true, ret2);

	SDKCallParamsWrapper params3[] = {
		{SDKType_String, SDKPass_Pointer}
	};
	g_hSDKCall_Disconnect	  = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_DISCONNECT, params3, sizeof(params3));

	SDKCallParamsWrapper ret3 = { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetNetChannel  = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETNETCHANNEL, _, _, true, ret3);

	delete gd;
}

stock void PrintLog(const char[] Message, any...)
{
	char sFormat[256];
	VFormat(sFormat, sizeof(sFormat), Message, 2);

	static char Path[PLATFORM_MAX_PATH];
	if (Path[0] == '\0')
		BuildPath(Path_SM, Path, PLATFORM_MAX_PATH, "/logs/l4d2_block_no_steam_logon.log");

	LogToFileEx(Path, sFormat);
}

// from L4D_ReadMemoryString, left4dhooks.
stock void ReadMemoryString(Address addr, char[] buffer, int size)
{
	int max = size - 1;

	int i	= 0;
	for (; i < max; i++)
		if ((buffer[i] = view_as<char>(LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8))) == '\0')
			return;

	buffer[i] = '\0';
}

/*
methodmap CBaseServer {
	// from FullUpdate by BotoX.
	// https://forums.alliedmods.net/showpost.php?p=2646904&postcount=5
	public static CBaseClient GetClient(int index) {
		// neccassary to classify sourcetv or reply bot.
		if(IsFakeClient(index) || IsClientSourceTV(index) || IsClientReplay(index)) {
			return view_as<CBaseClient>(-1);
		}

		//Engine client index is entity index minus one
		return view_as<CBaseClient>(SDKCall(g_hSDKCall_GetClient, index - 1));
	}
}
*/

//#define SDKCALL_GETCLIENT "CBaseServer::GetClient"
// g_hSDKCall_GetClient = null,