#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>   
#include <colors>
#include <l4d2_playtime_interface>
#include <geoip>

char
    authId[65],
    country[12],
    city[32],
    ip[32];

ConVar
    EnablePlugin,
    ShowPlayTime,
    ShowCountry,
    ShowProvince,
    ShowCity;

public Plugin myinfo =    
{   
    name = "Show Your PlayTime",   
    author = "A1R, blueblur",   
    description = "Show the players real play time and their region.",   
    version = "3.0",   
    url = "https://github.com/A1oneR/AirMod/blob/main/addons/sourcemod/scripting/Welcome.sp (Original version)"
};
/*
  1.0
    - Initial version from A1R.
  2.0
    - Optimized Codes, added conutry display, added translations supports.
  2.1
    - Optimized Codes, added more expression.
  2.2
    - Fix codes, added city expression.
  2.2.1
    - Fiexes.
  3.0
    - Add Cvars to control the output.
*/

public void OnPluginStart()
{   
    EnablePlugin = CreateConVar("l4d2_enable_welcome", "1", "Enable plugin or not", true, 0.0, true 1.0);
    ShowPlayTime = CreateConVar("l4d2_show_welcome_playtime", "1", "Enable playtime output", true, 0.0, true, 1.0);
    ShowCountry = CreateConVar("l4d2_show_welcome_country", "1", "Enable country output", true, 0.0, true, 1.0);
    ShowProvince = CreateConVar("l4d2_show_welcome_province", "1", "Enable province output", true, 0.0, true, 1.0);
    ShowCity = CreateConVar("l4d2_show_welcome_city", "1", "Enable city output", true, 0.0, true, 1.0);
    RegConsoleCmd("sm_playerinfo", Player_Time_Country);
    LoadTranslations("welcome.phrases");
    CheckEnableStatus();
} 

public void CheckEnableStatus()
{
    if (!GetConVarBool(EnablePlugin))
    {
        return Plugin_Handled;
    }
}

public void OnClientConnected(int client)   
{       
    char authId[65];
    int playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
    if(!IsFakeClient(client))
    {
        if (playtime > 0 && GetConVarBool(ShowPlayTime))
        {
           CPrintToChatAll("%t", "ConnectingWithHours", client, playtime);           //[{orange}!{default}] Player{olive} %N [{olive}%iHours{default}] is connecting...
        }
        else
        {
           CPrintToChatAll("%t", "Connecting", client);             //[{orange}!{default}] 玩家{olive} %N {default}正在连接中...
        }
    }
}

public void OnClientPutInServer(int client)
{
    int playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
    GetClientIP(client, ip, sizeof(ip));
    GeoipRegionCode(ip, country);
    GeoipCity(ip, city, sizeof(city));
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
    if(!IsFakeClient(client))
    {   
        if (playtime > 0 && GeoipRegionCode(ip, country))
        {
            CPrintToChatAll("%t", "ConnectedWithHoursAndRegion", client, playtime, country, city);            //[{orange}!{default}] 玩家{olive} %N {default} [{olive}%i 小时{default}] 进入了服务器, 来自[{olive}%s{default}, {olive}%s{default}].
        }
        else if(playtime > 0)
        {
            CPrintToChatAll("%t", "ConnectedWithHours", client, playtime);          //[{orange}!{default}] 玩家{olive} %N {default}[{olive}%i 小时{default}] 进入了服务器.
        }
        else if(GeoipRegionCode(ip, country))
        {
            CPrintToChatAll("%t", "ConnectedWithRegion", client, country, city);         //[{orange}!{default}] 玩家{olive} %N {default}进入了服务器, 来自 [{olive}%s{default}, {olive}%s{default}].
        }
        else
        {
            CPrintToChatAll("%t", "Connected", client);             //[{orange}!{default}] 玩家{olive} %N {default} 进入了服务器
        }
    }
}

public Action Player_Time_Country(int client, int args)
{
   char id[30];
   for (int i = 1 ; i <= MaxClients ; i++)
   {
        if (IsClientConnected(i) && IsClientInGame(i))
	    {
            int playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
            GetClientIP(client, ip, sizeof(ip));
            GeoipRegionCode(ip, country);
            GeoipCity(ip, city, sizeof(city));
            GetClientAuthId(i, AuthId_Steam2, authId, sizeof(authId));
	        GetClientAuthId(i, AuthId_Steam2, id, sizeof(id));
	        if (!StrEqual(id, "BOT"))
            {
	            if(playtime > 0 && GeoipRegionCode(ip, country))
                {
                    CPrintToChat(client, "%t", "RequestTimeAndRegion", i, playtime, country, city);            //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{olive}%i{default}] 小时, 来自 [{olive}%s{default}, {olive}%s{default}] 地区
                    return Plugin_Handled;
                }
                else if(playtime > 0)
                {
                    CPrintToChat(client, "%t", "RequestTime", i, playtime);          //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{olive}%i{default}] 小时, 来自 [{red}未知{default}] 地区
                    return Plugin_Handled;
                }
                else if(GeoipRegionCode(ip, country))
                {
                    CPrintToChat(client, "%t", "RequestRegion", i, country, city);                //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{red}未知{default}] 小时, 来自 [{olive}%s{default}, {olive}%s{default}] 地区
                    return Plugin_Handled;
                }
	            else
                {
	                CPrintToChat(client, "%t", "RequestFailed", i);             //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{red}未知{default}] 小时, 来自 [{red}未知{default}] 地区
                }
            }
        }
    }
    return Plugin_Handled;
}

//stock bool GetString(char country[12], char city)