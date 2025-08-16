#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <adminmenu>
#include <nmrih_player>

#include "nmrih_dev_menu/utils/consts.sp"
#include "nmrih_dev_menu/utils/utils.sp"

enum
{
	ITEM_NAME,
	ITEM_DISPLAY
};

TopMenu g_TopMenu;

TopMenuObject
	g_TopObj_Kill,
	g_TopObj_SpawnZombie,
	g_TopObj_GodMode,
	g_TopObj_NoClip,
	g_TopObj_Teleport,
	g_TopObj_GiveItem,
	g_TopObj_GiveHp,
	g_TopObj_Infect,
	g_TopObj_Bleed,
	g_TopObj_Respawn,
	g_TopObj_Deprive,
	g_TopObj_Freeze,
	g_TopObj_Drop;

int
	g_iGiveItemMenuPos[NMR_MAXPLAYERS + 1][4],
	g_iZombieClassMenuPos[NMR_MAXPLAYERS + 1],
	g_iNoClipMenuPos[NMR_MAXPLAYERS + 1],
	g_iGodModeMenuPos[NMR_MAXPLAYERS + 1],
	g_iKillMenuPos[NMR_MAXPLAYERS + 1],
	g_iInfectMenuPos[NMR_MAXPLAYERS + 1],
	g_iBleedMenuPos[NMR_MAXPLAYERS + 1],
	g_iHealMenuPos[NMR_MAXPLAYERS + 1],
	g_iTeleportMenuPos[NMR_MAXPLAYERS + 1],
	g_iRespawnMenuPos[NMR_MAXPLAYERS + 1],
	g_DepriveMenuPos[NMR_MAXPLAYERS + 1],
	g_iFreezeMenuPos[NMR_MAXPLAYERS + 1],
	g_iDropMenuPos[NMR_MAXPLAYERS + 1];

#include "nmrih_dev_menu/kill.sp"
#include "nmrih_dev_menu/spawnzombies.sp"
#include "nmrih_dev_menu/god.sp"
#include "nmrih_dev_menu/noclip.sp"
#include "nmrih_dev_menu/teleport.sp"
#include "nmrih_dev_menu/give.sp"
#include "nmrih_dev_menu/heal.sp"
#include "nmrih_dev_menu/respawn.sp"
#include "nmrih_dev_menu/infect.sp"
#include "nmrih_dev_menu/bleed.sp"
#include "nmrih_dev_menu/deprive.sp"
#include "nmrih_dev_menu/freeze.sp"
#include "nmrih_dev_menu/drop.sp"

#define PLUGIN_VERSION "1.0.2"

public Plugin myinfo =
{
	name		= "[NMRiH] Dev Menu",
	author		= "blueblur",
	version		= PLUGIN_VERSION,
	description = "Admin menu for nmrih. Ported from L4D2 Dev Menu by fdxx.",
	url			= "https://github.com/blueblur0730/modified-plugins"

}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char name[64];
	GetGameFolderName(name, sizeof(name));
	if ((GetEngineVersion() != Engine_SDK2013) || strcmp(name, "nmrih") != 0)
	{
		strcopy(error, err_max, "This plugin is only for NMRiH.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("nmrih_dev_menu_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NONE | FCVAR_DONTRECORD);
}

public void OnConfigsExecuted()
{
	static bool shit;
	if (shit)
		return;

	shit = true;

	if (LibraryExists("adminmenu") && ((g_TopMenu = GetAdminTopMenu()) != null))
	{
		TopMenuObject TopObj_DevMenu = g_TopMenu.AddCategory("nmrih_dev_menu", Category_TopMenuHandler, "nmrih_dev_menu", ADMFLAG_ROOT);

		// 可以在 configs/adminmenu_sorting.txt 中设置菜单显示的顺序
		g_TopObj_Kill				 = g_TopMenu.AddItem("nmrih_dev_menu_kill", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_kill", ADMFLAG_ROOT, "处死");
		g_TopObj_SpawnZombie		 = g_TopMenu.AddItem("nmrih_dev_menu_spawnzombie", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_spawnzombie", ADMFLAG_ROOT, "产生丧尸");
		g_TopObj_GodMode			 = g_TopMenu.AddItem("nmrih_dev_menu_godmode", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_godmode", ADMFLAG_ROOT, "切换无敌");
		g_TopObj_NoClip				 = g_TopMenu.AddItem("nmrih_dev_menu_noclip", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_noclip", ADMFLAG_ROOT, "切换穿墙");
		g_TopObj_Teleport			 = g_TopMenu.AddItem("nmrih_dev_menu_teleport", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_teleport", ADMFLAG_ROOT, "传送");
		g_TopObj_GiveItem			 = g_TopMenu.AddItem("nmrih_dev_menu_giveitem", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_giveitem", ADMFLAG_ROOT, "产生物品");
		g_TopObj_GiveHp				 = g_TopMenu.AddItem("nmrih_dev_menu_givehp", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_givehp", ADMFLAG_ROOT, "回血");
		g_TopObj_Infect				 = g_TopMenu.AddItem("nmrih_dev_menu_infect", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_infect", ADMFLAG_ROOT, "切换感染");
		g_TopObj_Bleed				 = g_TopMenu.AddItem("nmrih_dev_menu_bleed", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_bleed", ADMFLAG_ROOT, "切换流血");
		g_TopObj_Respawn			 = g_TopMenu.AddItem("nmrih_dev_menu_respawn", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_respawn", ADMFLAG_ROOT, "复活");
		g_TopObj_Deprive			 = g_TopMenu.AddItem("nmrih_dev_menu_deprive", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_deprive", ADMFLAG_ROOT, "装备剥夺");
		g_TopObj_Freeze				 = g_TopMenu.AddItem("nmrih_dev_menu_freeze", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_freeze", ADMFLAG_ROOT, "切换冻结");
		g_TopObj_Drop				 = g_TopMenu.AddItem("nmrih_dev_menu_drop", Item_TopMenuHandler, TopObj_DevMenu, "nmrih_dev_menu_drop", ADMFLAG_ROOT, "装备掉落");
	}
}

void Category_TopMenuHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(buffer, maxlength, "开发工具");
		case TopMenuAction_DisplayTitle: FormatEx(buffer, maxlength, "开发工具:");
	}
}

void Item_TopMenuHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int client, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			topmenu.GetInfoString(topobj_id, buffer, maxlength);
		}

		case TopMenuAction_SelectOption:
		{
			ResetSubMenuPos(client);	// 重置子菜单位置

			if (topobj_id == g_TopObj_Kill)
				Kill_TargetSelect(client);
			else if (topobj_id == g_TopObj_SpawnZombie)
				SpawnZombie_ClassSelect(client);
			else if (topobj_id == g_TopObj_GodMode)
				GodMode_TargetSelect(client);
			else if (topobj_id == g_TopObj_NoClip)
				NoClip_TargetSelect(client);
			else if (topobj_id == g_TopObj_Teleport)
				Teleport_TypeSelect(client);
			else if (topobj_id == g_TopObj_GiveItem)
				GiveItem_TypeSelect(client);
			else if (topobj_id == g_TopObj_GiveHp)
				GiveHp_TargetSelect(client);
			else if (topobj_id == g_TopObj_Infect)
				Infect_TargetSelect(client);
			else if (topobj_id == g_TopObj_Bleed)
				Bleed_TargetSelect(client);
			else if (topobj_id == g_TopObj_Respawn)
				Respawn_TargetSelect(client);
			else if (topobj_id == g_TopObj_Deprive)
				Deprive_TargetSelect(client);
			else if (topobj_id == g_TopObj_Freeze)
				Freeze_TargetSelect(client);
			else if (topobj_id == g_TopObj_Drop)
				Drop_TargetSelect(client);
		}
	}
}

void ResetSubMenuPos(int client)
{
	for (int i = 0; i < sizeof(g_iGiveItemMenuPos[]); i++)
	{
		g_iGiveItemMenuPos[client][i] = 0;
	}

	g_iZombieClassMenuPos[client] = 0;
	g_iNoClipMenuPos[client]	  = 0;
	g_iGodModeMenuPos[client]	  = 0;
	g_iKillMenuPos[client]		  = 0;
	g_iInfectMenuPos[client]	  = 0;
	g_iBleedMenuPos[client]		  = 0;
	g_iHealMenuPos[client]		  = 0;
	g_iTeleportMenuPos[client]	  = 0;
	g_iRespawnMenuPos[client]	  = 0;
	g_DepriveMenuPos[client]	  = 0;
	g_iFreezeMenuPos[client]	  = 0;
	g_iDropMenuPos[client]		  = 0;
}