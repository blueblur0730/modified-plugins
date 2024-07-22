#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define PL_VERSION "2.0"

ConVar g_hCvarBlockGunSound;
int    g_iBlockGunSound, g_iWeaponIndex[MAXPLAYERS + 1];
float  g_fSoundVolume[MAXPLAYERS + 1] = { 1.0, ... };
Handle g_hSDKCall_StopWeaponSound;
bool   g_bLateLoad = false;
DynamicDetour g_hDetour_EmitSound;
//DynamicDetour g_hDetour_WeaponSound;

#define DEBUG 1
#define MAX_WEAPON_SOUNDS 33
#define GAMEDATA_FILE "l4d2_block_gun_sound"
#define SDKCALL_FUNCTION "CBaseCombatWeapon::StopWeaponSound"
#define DETOUR_FUNCTION "CBaseCombatWeapon::WeaponSound"
#define DETOUR_FUNCTION_TWO "CBaseEntity::EmitSound"

// game_weapon_sounds.txt
static const char g_sWeaponSoundPath[MAX_WEAPON_SOUNDS][] = 
{
	"weapons/50cal/50cal_shoot.wav",									   // .50cal
	"weapons/magnum/gunfire/magnum_shoot.wav",							   // magnum
	"weapons/pistol/gunfire/pistol_fire.wav",							   // pistol
	"weapons/pistol/gunfire/pistol_dual_fire.wav",						   // pistol dual
	"weapons/pistol_silver/gunfire/pistol_fire.wav",					   // pistol silver
	"weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav",				   // chrome
	"weapons/shotgun/gunfire/shotgun_fire_1.wav",						   // pump
	"weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav",				   // spas
	"weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav",				   // autoshotgun
	"weapons/SMG/gunfire/smg_fire_1.wav",								   // SMG
	"weapons/SMG_silenced/gunfire/smg_fire_1.wav",						   // SMG silenced
	"weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav",			   // hunting rifle
	"weapons/sniper_military/gunfire/sniper_military_fire_1.wav",		   // military sniper
	"weapons/rifle/gunfire/rifle_fire_1.wav",							   // m16
	"weapons/rifle_desert/gunfire/rifle_fire_1.wav",					   // scar
	"weapons/rifle_ak47/gunfire/rifle_fire_1.wav",						   // ak47
	"weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav",	   // grenade launcher (not explosion)
	"weapons/minigun/gunfire/minigun_fire.wav",							   // minigun
	"weapons/awp/gunfire/awp1.wav",										   // awp
	"weapons/scout/gunfire/scout_fire-1.wav",							   // scout
	"weapons/mp5Navy/gunfire/mp5-1.wav",								   // mp5
	"weapons/sg552/gunfire/sg552-1.wav",								   // sg552

	// incendiary
	"weapons/shotgun_chrome/gunfire/shotgun_fire_1_incendiary.wav",				// chrome
	"weapons/shotgun/gunfire/shotgun_fire_1_incendiary.wav",					// pump
	"weapons/auto_shotgun_spas/gunfire/shotgun_fire_1_incendiary.wav",			// spas
	"weapons/auto_shotgun/gunfire/auto_shotgun_fire_1_Incendiary.wav",			// autoshotgun
	"weapons/SMG/gunfire/smg_fire_1_incendiary.wav",							// SMG
	"weapons/SMG_silenced/gunfire/smg_fire_1_incendiary.wav",					// SMG silenced
	"weapons/hunting_rifle/gunfire/hunting_rifle_fire_1_Incendiary.wav",		// hunting rifle
	"weapons/sniper_military/gunfire/sniper_military_fire_1_Incendiary.wav",	// military sniper
	"weapons/rifle/gunfire/rifle_fire_1_incendiary.wav",						// m16
	"weapons/rifle_desert/gunfire/rifle_fire_1_incendiary.wav",					// scar
	"weapons/rifle_ak47/gunfire/rifle_fire_1_incendiary.wav",					// ak47
};

//https://github.com/alliedmodders/hl2sdk/blob/4c27c1305c5e042ae1f62f6dc6ba7e96fd06e05d/game/shared/weapon_parse.h#L45
enum WeaponSound_t
{
	EMPTY,		// fire but no ammo
	SINGLE,		// the primary attack of the weapon
	SINGLE_NPC, // this thing is actually your second pistol.
	WPN_DOUBLE,	// the secondary attack of the weapon
	DOUBLE_NPC,	// NPC weapon
	BURST,
	RELOAD,		// reload the weapon
	RELOAD_NPC,
	MELEE_MISS,
	MELEE_HIT,
	MELEE_HIT_WORLD,
	SPECIAL1,
	SPECIAL2,
	SPECIAL3,
	TAUNT,
	DEPLOY,

	NUM_SHOOT_SOUND_TYPES,
};

public Plugin myinfo =
{
	name = "[L4D2] Block Gun Sound",
	author = "blueblur",
	description = "Blocks the gun sounds when shooting.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_gun_sound_version", PL_VERSION, "L4D2 Block Gun Sound version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_hCvarBlockGunSound = CreateConVar("l4d2_block_gun_sound", "1",
										"0 = Do nothing,\
                                         1 = Block the sound of the gun globally for all players,\
                                         2 = Set the sound volume of the gun of other players.");
	RegConsoleCmd("sm_sound_volume", Command_SoundVolume, "Set the gun sound volume. It is only activated when 'l4d2_block_gun_sound' is set to 2.");
	g_hCvarBlockGunSound.AddChangeHook(OnConVarChanged);
	SetCvar();

	if (g_bLateLoad)
		LateHook();

	PrepSDKCall();
	SetUpDetour();
	CreateNative("StopWeaponSound", Native_StopWeaponSound);
	AddNormalSoundHook(NormalSoundHook);

	for (int i = 0; i < MAX_WEAPON_SOUNDS; i++)
		PrecacheSound(g_sWeaponSoundPath[i]);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetCvar();
}

void SetCvar()
{
	g_iBlockGunSound = g_hCvarBlockGunSound.IntValue;
}

void LateHook()
{
	for (int i = 0; i < MaxClients; i++)
	{
		if (IsSurvivor(i))
			SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	}
}

Action Command_SoundVolume(int client, int args)
{
	if (args == 0 || args > 1)
	{
		ReplyToCommand(client, "Usage: sm_sound_volume <volume>, <volume> range is 0.0 to 1.0.");
		return Plugin_Handled;
	}

	if (g_iBlockGunSound == 2)
	{
		g_fSoundVolume[client] = GetCmdArgFloat(1);
		ReplyToCommand(client, "Successfully set. volume: %.1f", g_fSoundVolume[client]);
	}
	else
	{
		ReplyToCommand(client, "The 'l4d2_block_gun_sound' cvar is not set to 2.");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

void OnWeaponEquipPost(int client, int weapon)
{
	if (!IsValidEntity(weapon))
		return;

	g_iWeaponIndex[client] = weapon;
}

/**
 * https://forums.alliedmods.net/showpost.php?p=2301102&postcount=6 Hook is late for prediction. so we use detour.
 * https://developer.valvesoftware.com/wiki/Soundscripts#Sound_Characters here to see the definitions of sound indexes.
 */

Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
					   int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
					   char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (g_iBlockGunSound != 2)
		return Plugin_Continue;

	if (channel == SNDCHAN_WEAPON)
	{
		for (int i = 0; i < MAX_WEAPON_SOUNDS; i++)
		{
			if (StrContains(sample, g_sWeaponSoundPath[i]) > -1)
			{
				for (int a = 0; a < MaxClients; a++)
				{
					if (entity == a)
						volume = g_fSoundVolume[entity];
				}

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

void PrepSDKCall()
{
	GameData hGd = new GameData(GAMEDATA_FILE);
	if (hGd == null)
		SetFailState("Failed to load gamedata file \""...GAMEDATA_FILE..."\"");

	StartPrepSDKCall(SDKCall_Entity);

	// https://github.com/alliedmodders/hl2sdk/blob/4c27c1305c5e042ae1f62f6dc6ba7e96fd06e05d/game/shared/basecombatweapon_shared.cpp#L1947
	if (!PrepSDKCall_SetFromConf(hGd, SDKConf_Signature, SDKCALL_FUNCTION))
		LogError("Failed to find signature \""...SDKCALL_FUNCTION..."\"");
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	// WeaponSound_t
	g_hSDKCall_StopWeaponSound = EndPrepSDKCall();

	if (g_hSDKCall_StopWeaponSound == null)
		LogError("Failed to prepare SDK call for \""...SDKCALL_FUNCTION..."\".");

	delete hGd;
}

void SetUpDetour()
{
	GameData hGd = new GameData(GAMEDATA_FILE);
	if (hGd == null)
		SetFailState("Failed to load gamedata file \""...GAMEDATA_FILE..."\"");
/*
	// https://github.com/alliedmodders/hl2sdk/blob/4c27c1305c5e042ae1f62f6dc6ba7e96fd06e05d/game/shared/basecombatweapon_shared.cpp#L1886
	g_hDetour_WeaponSound = DynamicDetour.FromConf(hGd, DETOUR_FUNCTION);
	if (g_hDetour_WeaponSound == null)
		SetFailState("Failed to set up detour for \""...DETOUR_FUNCTION..."\"");

	delete hGd;
	if (!g_hDetour_WeaponSound.Enable(Hook_Post, DTR_CBaseCombatWeapon_WeaponSound))
		SetFailState("Failed to enable detour for \""...DETOUR_FUNCTION..."\"");
*/
	g_hDetour_EmitSound = DynamicDetour.FromConf(hGd, DETOUR_FUNCTION_TWO);
	if (g_hDetour_EmitSound == null)
		SetFailState("Failed to set up detour for \""...DETOUR_FUNCTION_TWO..."\"");

	delete hGd;
	if (!g_hDetour_EmitSound.Enable(Hook_Pre, DTR_CBaseEntity_EmitSound))
		SetFailState("Failed to enable detour for \""...DETOUR_FUNCTION_TWO..."\"");
}
/*
MRESReturn DTR_CBaseCombatWeapon_WeaponSound(int pThis, DHookParam hParams)
{
	if (g_iBlockGunSound > 1)
		return MRES_Ignored;
#if DEBUG
	PrintToServer("### DTR_CBaseCombatWeapon_WeaponSound, weapon: %d", pThis);
#endif

	if (!IsValidEntity(pThis))
		return MRES_Ignored;

	for (int i = 0; i < MaxClients; i++)
	{
		if (pThis == g_iWeaponIndex[i])
		{
			WeaponSound_t sound_type = view_as<WeaponSound_t>(hParams.Get(1));
			if (sound_type)
			{
			#if DEBUG
				PrintToServer("sound_type: %d", view_as<int>(sound_type));
			#endif
				if (sound_type == SINGLE || sound_type == WPN_DOUBLE)
					SDKCall(g_hSDKCall_StopWeaponSound, pThis, view_as<int>(sound_type));
			}
		}
	}

	return MRES_Ignored;
}
*/
MRESReturn DTR_CBaseEntity_EmitSound(DHookParam hParams)
{
/*
	int entity = hParams.Get(2);
	#if DEBUG
		PrintToServer("### DTR_CBaseEntity_EmitSound, entity: %d", entity);
	#endif

	if (!IsValidEntity(entity))
		return MRES_Ignored;

	char soundName[PLATFORM_MAX_PATH];
	hParams.GetString(3, soundName, sizeof(soundName));
	#if DEBUG
		PrintToServer("### DTR_CBaseEntity_EmitSound, sound: %s", soundName);
	#endif
*/
	return MRES_Supercede;
}

public int Native_StopWeaponSound(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1); char sName[32];
	if (GetEntityClassname(weapon, sName, sizeof(sName)))
	{
		if (StrContains(sName, "weapon_") > -1)
		{
			WeaponSound_t sound_type = GetNativeCell(2);
			SDKCall(g_hSDKCall_StopWeaponSound, weapon, view_as<int>(sound_type));
		}
		else
			ThrowNativeError(SP_ERROR_INDEX, "Invalid weapon index: %d.", weapon);
	}

	return 0;
}

/**
 * from left4dhooks_silver.inc
 * 
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == 2);
}