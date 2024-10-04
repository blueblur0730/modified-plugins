#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <gamedata_wrapper>

#define GAMEDATA_FILE  "animating_library"
#define PLUGIN_VERSION "1.0"

Handle
	g_hSDKCall_GetBaseAnimating	   = null,
	g_hSDKCall_FindBodygroupByName = null,
	g_hSDKCall_SetBodygroup		   = null;

methodmap CBaseAnimating
{
	public CBaseAnimating(int entity) {
		return view_as<CBaseAnimating>(view_as<Address>(SDKCall(g_hSDKCall_GetBaseAnimating, entity)));
	}

	public int FindBodygroupByName(const char[] name) {
		return SDKCall(g_hSDKCall_FindBodygroupByName, view_as<Address>(this), name);
	}

	public void SetBodygroup(int iGroup, int iValue) {
		SDKCall(g_hSDKCall_SetBodygroup, this, iGroup, iValue);
	}
}

CBaseAnimating pWrapper;

public Plugin myinfo =
{
	name		= "[L4D2/ANY?] Library for CBaseAnimating",
	author		= "blueblur",
	description = "Just a library for CBaseAnimating.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");	// for now?
		return APLRes_SilentFailure;
	}

	CreateNatives();

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameDataWrapper	gd = new GameDataWrapper(GAMEDATA_FILE);

	// weird sourcemod shit
	// https://forums.alliedmods.net/showthread.php?t=344325
	SDKCallParamsWrapper ret = {
		SDKType_PlainOldData, SDKPass_Plain
	};

	SDKCallParamsWrapper params[] = {
		{SDKType_String, SDKPass_Pointer}
	};

	SDKCallParamsWrapper ret2 = {
		SDKType_PlainOldData, SDKPass_Plain
	};

	SDKCallParamsWrapper params2[] = {
		{ SDKType_PlainOldData,	SDKPass_Plain},
		{ SDKType_PlainOldData, SDKPass_Plain}
	};

	g_hSDKCall_GetBaseAnimating	   = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Virtual, "CBaseAnimating::GetBaseAnimating", _, _, true, ret);

	if (gd.OS == OS_Windows)
		g_hSDKCall_FindBodygroupByName = gd.CreateSDKCallOrFailEx(SDKCall_Raw, "CBaseAnimating::FindBodygroupByName", params, sizeof(params), true, ret2);
	else
		g_hSDKCall_FindBodygroupByName = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "CBaseAnimating::FindBodygroupByName", params, sizeof(params), true, ret2);
		
	g_hSDKCall_SetBodygroup		   = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "CBaseAnimating::SetBodygroup", params2, sizeof(params2));

	delete gd;
}

void CreateNatives()
{
	CreateNative("CBaseAnimating.CBaseAnimating", Native_CBaseAnimating);
	CreateNative("CBaseAnimating.FindBodygroupByName", Native_FindBodygroupByName);
	CreateNative("CBaseAnimating.SetBodygroup", Native_SetBodyGroup);
}

any Native_CBaseAnimating(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	pWrapper = CBaseAnimating(entity);

	return view_as<Address>(pWrapper);
}

int Native_FindBodygroupByName(Handle plugin, int numParams)
{
	int maxlength;
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] name = new char[maxlength];
	GetNativeString(2, name, maxlength);

	return pWrapper.FindBodygroupByName(name);
}

int Native_SetBodyGroup(Handle plugin, int numParams)
{
	int iGroup = GetNativeCell(2);
	int iValue = GetNativeCell(3);

	pWrapper.SetBodygroup(iGroup, iValue);

	return 0;
}