#if defined __unreserve_lobby_included
	#endinput
#endif
#define __unreserve_lobby_included

#define UL_MODULE_NAME "UnreserveLobby"

static ConVar
	UL_hEnable = null;

static GlobalForward
	 UL_OnRemoveLobby = null;

void UL_APL()
{
	UL_OnRemoveLobby = new GlobalForward("LGO_OnRemoveLobby", ET_Event);
}

void UL_OnModuleStart()
{
	UL_hEnable = CreateConVarEx("match_killlobbyres", "0",\
								"Sets whether the plugin will clear lobby reservation once a match have begun",\
								_, true, 0.0, true, 1.0);

	RegAdminCmd("sm_killlobbyres", UL_KillLobbyRes, ADMFLAG_BAN, "Forces the plugin to kill lobby reservation");
}

void UL_OnClientPutInServer()
{
	if (!IsPluginEnabled() || !UL_hEnable.BoolValue)
		return;

	UL_RemoveLobby();
}

static Action UL_KillLobbyRes(int client, int args)
{
	UL_RemoveLobby();
	CReplyToCommand(client, "%t %t", "Tag", "RemovedLobby");	//[Confogl] Removed lobby reservation.
	return Plugin_Handled;
}

static void UL_RemoveLobby()
{
	if (!LibraryExists("left4dhooks"))
	{
		g_hLogger.WarnEx("[%s] Left4DHook library not found, lobby reservation will not be removed.", UL_MODULE_NAME);
		return;
	}

	if (L4D_LobbyIsReserved())
	{
		g_hLogger.InfoEx("[%s] Removed lobby reservation.", UL_MODULE_NAME);
		L4D_LobbyUnreserve();

		Call_StartForward(UL_OnRemoveLobby);
		Call_Finish();
	}
}