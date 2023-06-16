#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>   
#include <colors>
#include <l4d2_playtime_interface>
#include <geoip>
#include <sdktools>
#include <sdkhooks>

char
    authId[65],
    country[3],
    city[32],
    Admin[32],
    Player[32],
    ip[32];

ConVar
    EnablePlugin,
    ShowPlayTime,
    ShowCountry,
    ShowCity,
    ShowIdentity,
    ShowDisconnectInfo;

public Plugin myinfo =    
{   
    name = "Show Your PlayTime",   
    author = "A1R, blueblur",   
    description = "Show the players real play time and their region.",   
    version = "3.1",   
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
    - Fixed codes, added city expression.
  2.2.1
    - Fiexes.
  3.0
    - Add Cvars to control the output.
  3.1
    - Fixed bugs.
  3.2
    - Fixed bugs.
  4.0
    - Added Disconnect Info from AnneHappy.
      - Added a new cvar to control the Disconnect output.
*/

public void OnPluginStart()
{   
    EnablePlugin = CreateConVar("l4d2_enable_welcome", "1", "Enable plugin or not", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowPlayTime = CreateConVar("l4d2_show_welcome_playtime", "1", "Enable playtime output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowCountry = CreateConVar("l4d2_show_welcome_country", "1", "Enable country output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowCity = CreateConVar("l4d2_show_welcome_city", "1", "Enable city output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowIdentity = CreateConVar("l4d2_show_welcome_identity", "1", "Enable Identity output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowDisconnectInfo = CreateConVar("l4d2_show_welcome_disconnect_info", "1", "Enable Disconnect Info Output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    RegConsoleCmd("sm_playerinfo", Player_Time_Country);
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
    LoadTranslations("welcome.phrases");
    CheckEnableStatus();
} 

public Action CheckEnableStatus()
{
    if (!GetConVarBool(EnablePlugin))
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void OnClientConnected(int i)   
{       
    int playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
    bool b_PlayerIdentity = !PlayerIdentity();
    Format(Admin, sizeof(Admin), "%t", "Admin");
    Format(Player, sizeof(Player), "%t", "Player");
    if(!IsFakeClient(i))
    {
        GetClientUserId(i);
        if(playtime > 0)
        {
            if(GetConVarBool(ShowPlayTime))
            {
                CPrintToChatAll("%t", "ConnectingWithHours", (b_PlayerIdentity ? Player : Admin), i, playtime);           //[{orange}!{default}] %s{olive} %N [{olive}%iHours{default}] is connecting...
            }
        }
        else
        {
            CPrintToChatAll("%t", "Connecting", (b_PlayerIdentity ? Player : Admin), i);             //[{orange}!{default}] %s{olive} %N {default}正在连接中...
        }
    }
}

public void OnClientPutInServer(int i)
{
    int playtime;
    bool b_PlayerIdentity = !PlayerIdentity();
    if(GetConVarBool(ShowPlayTime))
    {
        playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
    }
    else
    {
        playtime = 0;
    }
    GetClientIP(i, ip, sizeof(ip));
    GetClientAuthId(i, AuthId_Steam2, authId, sizeof(authId));
    GeoipCode2(ip, country);
    GeoipCity(ip, city, sizeof(city));
    Format(Admin, sizeof(Admin), "%t", "Admin");
    Format(Player, sizeof(Player), "%t", "Player");
    for(i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientUserId(i);
            if(playtime > 0)
            {
                if(GetConVarBool(ShowCountry) && GetConVarBool(ShowCity))
                {
                    if(GeoipCode2(ip, country) && GeoipCity(ip, city, sizeof(city)))
                    {
                        CPrintToChatAll("%t", "ConnectedWithHours_City_Country", (b_PlayerIdentity ? Player : Admin), i, playtime, country, city);            //[{orange}!{default}] %s{olive} %N {default} [{olive}%i 小时{default}] 进入了服务器, 来自[{olive}%s{default}, {olive}%s{default}].
                    }
                    else if(GetConVarBool(ShowCountry))
                    {
                        if(GeoipCode2(ip, country))
                        {
                            CPrintToChatAll("%t", "ConnectedWithHours_City_Or_Country", (b_PlayerIdentity ? Player : Admin), i, playtime, country);          //[{orange}!{default}] %s{olive} %N {default}[{olive}%i 小时{default}] 进入了服务器, 来自[{olive}%s{default}].
                        }
                        else if(GetConVarBool(ShowCity))
                        {
                            if(GeoipCity(ip, city, sizeof(city)))
                            {
                                CPrintToChatAll("%t", "ConnectedWithHours_City_Or_Country", (b_PlayerIdentity ? Player : Admin), i, playtime, city);         //[{orange}!{default}] %s{olive} %N {default}[{olive}%i 小时{default}] 进入了服务器, 来自 [{olive}%s{default}].
                            }
                        }
                        else
                        {
                                CPrintToChatAll("%t", "ConnectedWithHours", (b_PlayerIdentity ? Player : Admin), i, playtime);             //[{orange}!{default}] %s{olive} %N {default}[{olive}%i 小时{default}] 进入了服务器.
                        }
                    }
                }
            }
            else
            {
                if(GetConVarBool(ShowCountry) && GetConVarBool(ShowCity))
                {
                    if(GeoipCode2(ip, country) && GeoipCity(ip, city, sizeof(city)))
                    {
                        CPrintToChatAll("%t", "ConnectedWithCountry_City", (b_PlayerIdentity ? Player : Admin), i, country, city);            //[{orange}!{default}] %s{olive} %N {default}进入了服务器, 来自[{olive}%s{default}, {olive}%s{default}].
                    }
                    else if(GetConVarBool(ShowCountry))
                    {
                        if(GeoipCode2(ip, country))
                        {
                            CPrintToChatAll("%t", "ConnectedWith_City_Or_Country", (b_PlayerIdentity ? Player : Admin), i, country);          //[{orange}!{default}] %s{olive} %N {default}进入了服务器, 来自[{olive}%s{default}].
                        }
                        else if(GetConVarBool(ShowCity))
                        {
                            if(GeoipCity(ip, city, sizeof(city)))
                            {
                                CPrintToChatAll("%t", "ConnectedWith_City_Or_Country", (b_PlayerIdentity ? Player : Admin), i, city);         //[{orange}!{default}] %s{olive} %N {default}进入了服务器, 来自 [{olive}%s{default}].
                            }
                        }
                        else
                        {
                            CPrintToChatAll("%t", "Connected", (b_PlayerIdentity ? Player : Admin), i);             //[{orange}!{default}] %s{olive} %N {default}进入了服务器.
                        }
                    }
                }
            }
        }
    }
}

public Action Player_Time_Country(int client, int args)
{
    char id[64];
    for (int i = 1 ; i <= MaxClients ; i++)
    {
        if(IsClientInGame(i))
	    {
            GetClientAuthId(i, AuthId_Steam2, id, sizeof(id));
            int playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
            GetClientIP(client, ip, sizeof(ip));
            GeoipCode2(ip, country);
            GeoipCity(ip, city, sizeof(city));
            GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	        if(!StrEqual(id, "BOT"))
            {
	            if(playtime > 0 && GeoipCode2(ip, country))
                {
                    CPrintToChat(client, "%t", "RequestTimeAndRegion", i, playtime, country, city);            //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{olive}%i{default}] 小时, 来自 [{olive}%s{default}, {olive}%s{default}] 地区.
                    return Plugin_Handled;
                }
                else if(playtime > 0)
                {
                    CPrintToChat(client, "%t", "RequestTime", i, playtime);          //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{olive}%i{default}] 小时, 来自 [{red}未知{default}] 地区.
                    return Plugin_Handled;
                }
                else if(GeoipCode2(ip, country))
                {
                    CPrintToChat(client, "%t", "RequestRegion", i, country, city);                //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{red}未知{default}] 小时, 来自 [{olive}%s{default}, {olive}%s{default}] 地区.
                    return Plugin_Handled;
                }
	            else
                {
	                CPrintToChat(client, "%t", "RequestFailed", i);             //[{orange}!{default}] 玩家{olive} %N {default}已游玩 [{red}未知{default}] 小时, 来自 [{red}未知{default}] 地区.
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));
    bool b_PlayerIdentity = !PlayerIdentity();
    if (!GetConVarBool(ShowDisconnectInfo))       //Check if enabled
    {
        return Plugin_Handled;
    }
    
    if (!(1 <= client <= MaxClients))
        return Plugin_Handled;

    if (!IsClientInGame(client))
        return Plugin_Handled;

    if (IsFakeClient(client))
        return Plugin_Handled;

    char reason[64], message[64];
    GetEventString(event, "reason", reason, sizeof(reason));

    if(StrContains(reason, "connection rejected", false) != -1)
    {
        Format(message,sizeof(message), "%t", "Rejected");     //连接被拒绝
    }
    else if(StrContains(reason, "timed out", false) != -1)
    {
        Format(message,sizeof(message), "%t", "TimedOut");     //超时
    }
    else if(StrContains(reason, "by console", false) != -1)
    {
        Format(message,sizeof(message), "%t", "ByConsole");     //控制台退出
    }
    else if(StrContains(reason, "by user", false) != -1)
    {
        Format(message,sizeof(message), "%t", "ByUser");     //自己主动断开连接
    }
    else if(StrContains(reason, "ping is too high", false) != -1)
    {
        Format(message,sizeof(message), "%t", "HighPing");     //ping值过高
    }
    else if(StrContains(reason, "No Steam logon", false) != -1)
    {
        Format(message,sizeof(message), "%t", "NoLogen");     //no steam logon/ steam验证失败
    }
    else if(StrContains(reason, "Steam account is being used in another", false) != -1)
    {
        Format(message,sizeof(message), "%t", "BeingUsed");     //该Steam账号已被另一人登录
    }
    else if(StrContains(reason, "Steam Connection lost", false) != -1)
    {
        Format(message,sizeof(message), "%t", "ConnectionLost");        //Steam连接丢失
    }
    else if(StrContains(reason, "This Steam account does not own this game", false) != -1)
    {
        Format(message,sizeof(message), "%t", "NotProperty");       //没有这款游戏
    }
    else if(StrContains(reason, "Validation Rejected", false) != -1)
    {
        Format(message,sizeof(message), "%t", "ValidationRejected");        //验证失败
    }
    else
    {
        message = reason;
    }

    CPrintToChatAll("%t", "Disconnect", (b_PlayerIdentity ? Player : Admin), client, message);       //[{orange}!{default}] %s{green} %N {olive}离开了游戏 - 理由: [{green}%s{olive}]
    return Plugin_Handled;
}

stock bool PlayerIdentity()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            if(GetConVarBool(ShowIdentity))
            {
                /*
                *   This Part is from readyup.sp
                */

                // Check if admin always allowed to do so
		        AdminId id = GetUserAdmin(i);
		        if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
		        {
			        return true;
		        }
            }
        }
    }
    return false;
}
