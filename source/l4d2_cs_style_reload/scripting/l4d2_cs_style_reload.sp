#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>
#include <gamedata_wrapper>

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo =
{
	name = "[L4D2] CS Style Reload",
	author = "blueblur",
	description = "Reload like CS style",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

MemoryPatch g_hPatch1, g_hPatch2;
public void OnPluginStart()
{
    GameDataWrapper gd = new GameDataWrapper("l4d2_cs_style_reload");
    g_hPatch1 = gd.CreateMemoryPatchOrFail("CTerrorGun::Reload__AddClip", true);
    g_hPatch2 = gd.CreateMemoryPatchOrFail("CTerrorGun::Reload__ClipToZero", true);
    delete gd;
}

public void OnPluginEnd()
{
    delete g_hPatch1;
    delete g_hPatch2;
}