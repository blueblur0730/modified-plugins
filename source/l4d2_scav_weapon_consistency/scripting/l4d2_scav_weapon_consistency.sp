/*
 * changelog.
 *
 * v1.0: 8/26/23
 *  - initial build.
 * 
 * v1.1: 8/27/23
 *  - use the way to remove entity and store entity from weapon_loadout_vote.sp by sir.
 *  - improved way to store datas in array.
 * 
 * v1.2: 8/27/23
 *  - code optimization.
 *  - initial release.
 *  - (to do) since number of pills and adrenalines are restricted by confogl, need some improvment to store and spawn these items properly 
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2util>

#define MAX_ENTITY_NAME_LENGTH 64

ArrayList
	g_hWeaponArray;

enum struct WeaponInfo
{
	int	  wepid;
	float origin[3];
	float angle[3];
}

static const char sRemoveWeaponNames[][] = {
	"spawn",
	"pain_pills_spawn",
	"adrenaline_spawn"
};

public Plugin myinfo =
{
	name		= "[L4D2] Scavenge Weapon Consistency",
	description = "Makes scavenge weapons, pills, adrenaline spawn at the same position and (weapons)same tier in one scavenge round.",
	author		= "blueblur",
	version		= "1.2",
	url			= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	g_hWeaponArray = new ArrayList(sizeof(WeaponInfo));
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	CheckGameMode();
}

public Action CheckGameMode()
{
	if (IsScavengeMode())
		return Plugin_Continue;
	else
		return Plugin_Handled;
}

// check every round start
public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, Timer_WeaponEntStoreAndRemove);
}

public Action Timer_WeaponEntStoreAndRemove(Handle timer)
{
	if (InSecondHalfOfRound())	  // if the round is in second half, remove the weapons
	{
		int	 iOwner	 = -1;
		int	 iEntity = INVALID_ENT_REFERENCE;
		char sEntityName[MAX_ENTITY_NAME_LENGTH];
		// from weapon_loadout_vote.sp
		while ((iEntity = FindEntityByClassname(iEntity, "weapon_*")) != INVALID_ENT_REFERENCE)
		{
			if (iEntity <= MaxClients || !IsValidEntity(iEntity))
			{
				continue;
			}

			GetEntityClassname(iEntity, sEntityName, sizeof(sEntityName));
			for (int i = 0; i < sizeof(sRemoveWeaponNames); i++)
			{
				// weapon_ - 7
				if (strcmp(sEntityName[7], sRemoveWeaponNames[i]) == 0)
				{
					// ignore the weapon we are handing
					iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
					if (iOwner == -1 || !IsClientInGame(iOwner))
					{
						RemoveEntity(iEntity);
					}
					break;
				}
			}
		}
		ReplaceWeapons();	 // spawn the first half round weapons
	}
	else
	{
		// in the first half round, clear the array stored weapons from last round.
		g_hWeaponArray.Clear();

		int	 iOwner	 = -1;
		int	 iEntity = INVALID_ENT_REFERENCE;
		char sEntityName[MAX_ENTITY_NAME_LENGTH];

		while ((iEntity = FindEntityByClassname(iEntity, "weapon_*")) != INVALID_ENT_REFERENCE)
		{
			if (iEntity <= MaxClients || !IsValidEntity(iEntity))
			{
				continue;
			}

			GetEntityClassname(iEntity, sEntityName, sizeof(sEntityName));
			for (int i = 0; i < sizeof(sRemoveWeaponNames); i++)
			{
				if (strcmp(sEntityName[7], sRemoveWeaponNames[i]) == 0)
				{
					iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
					if (iOwner == -1 || !IsClientInGame(iOwner))
					{
						StoreWeapons(iEntity);
					}
					break;
				}
			}
		}
	}
	return Plugin_Handled;
}

void StoreWeapons(int ent)
{
	WeaponInfo esWeaponInfo;

	if (IdentifyWeapon(ent) != WEPID_NONE)
	{
		esWeaponInfo.wepid = IdentifyWeapon(ent);
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", esWeaponInfo.origin);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", esWeaponInfo.angle);
		g_hWeaponArray.PushArray(esWeaponInfo, sizeof(WeaponInfo));
	}
}

void ReplaceWeapons()
{
	int iWeaponSize = g_hWeaponArray.Length;

	WeaponInfo esWeaponInfo;

	for (int i = 0; i < iWeaponSize; i++)
	{
		g_hWeaponArray.GetArray(i, esWeaponInfo, sizeof(WeaponInfo));
		SpawnWeapon(esWeaponInfo.wepid, esWeaponInfo.origin, esWeaponInfo.angle, 5);
	}
}

void SpawnWeapon(int wepid, float origin[3], float angles[3], int count)
{
	if (HasValidWeaponModel(wepid))
	{
		int iEntity = CreateEntityByName("weapon_spawn");
		if (IsValidEntity(iEntity))
		{
			SetEntProp(iEntity, Prop_Send, "m_weaponID", wepid);
			char buf[256];
			GetWeaponModel(wepid, buf, 64);
			DispatchKeyValue(iEntity, "solid", "6");
			DispatchKeyValue(iEntity, "model", buf);
			DispatchKeyValue(iEntity, "rendermode", "3");
			DispatchKeyValue(iEntity, "disableshadows", "1");
			IntToString(count, buf, 64);
			TeleportEntity(iEntity, origin, angles, NULL_VECTOR);
			DispatchKeyValue(iEntity, "count", buf);
			DispatchSpawn(iEntity);
			SetEntityMoveType(iEntity, MOVETYPE_NONE);
		}
	}
}

stock bool IsScavengeMode()
{
	char   sCurGameMode[64];
	ConVar hCurGameMode = FindConVar("mp_gamemode");
	hCurGameMode.GetString(sCurGameMode, sizeof(sCurGameMode));
	if (strcmp(sCurGameMode, "scavenge") == 0)
		return true;
	else
		return false;
}