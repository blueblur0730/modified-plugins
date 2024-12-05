#if defined __confogl_autoloader_included
	#endinput
#endif
#define __confogl_autoloader_included

static ConVar sv_hibernate_when_empty = null;
static ConVar AL_hCvar_AutoLoaderConfig = null;
static bool bHibernating = false;
static bool bNoPlayer = false;
static char szConfigName[PLATFORM_MAX_PATH];

void AL_OnPluginStart()
{
	AL_hCvar_AutoLoaderConfig = CreateConVarEx("autoloader_config", "", "Choose a config to load upon server start. If empty nothing will be loaded.");
	AL_hCvar_AutoLoaderConfig.AddChangeHook(OnConVarChanged);
	sv_hibernate_when_empty = FindConVar("sv_hibernate_when_empty");
	sv_hibernate_when_empty.AddChangeHook(OnConVarChanged);
	OnConVarChanged(null, "", "");
}

void AL_OnConfigsExecuted()
{
	if (!strlen(szConfigName))
		return;
		
	AutoLoad();
}

void AL_OnServerEnterHibernation()
{
	bHibernating = true;
}

void AL_OnServerExitHibernation()
{
	bHibernating = false;
}

void AL_OnClientPutInServer(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	bNoPlayer = false;
}

void AL_OnClientDisconnect()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		bNoPlayer = false;
		break; 
	} 

	if (!bNoPlayer)
		return;

	bNoPlayer = true;
}

static void OnConVarChanged(ConVar convar, const char[] sOldValue, const char[] sOldValue)
{
	AL_hCvar_AutoLoaderConfig.GetString(szConfigName, sizeof(szConfigName));
}

static void AutoLoad()
{
	if ((sv_hibernate_when_empty.BoolValue && bNoPlayer) || bHibernating)
	{
		if (RM_bIsMatchModeLoaded)
			return;

		if (SetCustomCfg(szConfigName))
		{
			PrintToServer("[Confogl] AutoLoader: Config loaded: %s\n", szConfigName);
			LogMessage("[Confogl] AutoLoader: Config loaded: %s\n", szConfigName);
		}
	}
}
