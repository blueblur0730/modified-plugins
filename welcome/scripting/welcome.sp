#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>   
#include <colors>
#include <l4d2_playtime_interface>
#include <geoip>
#include <sdktools>
#include <sdkhooks>

//StringMap
    //ArrPlayerInfo;

char
    Admin[32],
    Player[32],
    authId[65],
    country[3],
    city[32],
    ip[32],
    f_country[128],
    f_city[128];

ConVar
    EnablePlugin,
    ShowPlayTime,
    ShowCountry,
    ShowCity,
    ShowIdentity,
    ShowDisconnectInfo;

bool
    b_PlayerIdentity;

int
    hours;

public Plugin myinfo =    
{   
    name = "Show Your PlayTime",   
    author = "A1R, 东, modified by blueblur",   
    description = "Show the players real play time and their region.",   
    version = "4.1",   
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
    4.1
        - Fixed a bug that the identity result was totally contrary to the right identity.
        - optimized codes.
    
    To Do:
    Create a list to output all player's information.
*/

public void OnPluginStart()
{   
    // ConVars
    EnablePlugin = CreateConVar("l4d2_enable_welcome", "1", "Enable plugin or not", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowPlayTime = CreateConVar("l4d2_show_welcome_playtime", "1", "Enable playtime output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowCountry = CreateConVar("l4d2_show_welcome_country", "1", "Enable country output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowCity = CreateConVar("l4d2_show_welcome_city", "1", "Enable city output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowIdentity = CreateConVar("l4d2_show_welcome_identity", "1", "Enable Identity output", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    ShowDisconnectInfo = CreateConVar("l4d2_show_welcome_disconnect_info", "1", "Enable Disconnect Info Output", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Cmd
    RegConsoleCmd("sm_playerinfo", Player_Time_Country);

    // Hook
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

    // Translations
    LoadTranslations("welcome.phrases");

    // Global Varibles
    Format(Admin, sizeof(Admin), "%t", "Admin");
    Format(Player, sizeof(Player), "%t", "Player");
    b_PlayerIdentity = PlayerIdentity();

    // Create Array
    //ArrPlayerInfo = new StringMap();

    // Check Enable
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

public void GetClientInformation(int client, int playtime)
{
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));

    if(GetConVarBool(ShowPlayTime))
    {
        playtime = L4D2_GetTotalPlaytime(authId, true) / 60 / 60;
    }
    else
    {
        playtime = 0;
    }

    GetClientIP(client, ip, sizeof(ip));
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
    GeoipCode2(ip, country);
    GeoipCity(ip, city, sizeof(city));
    Format(f_country, sizeof(f_country), "%t", "Country", country);
    Format(f_city, sizeof(f_city), "%t", "City", city);
}

public void OnClientConnected(int iclient)   
{   
    GetClientInformation(iclient, hours);
    if(!IsFakeClient(iclient))
    {
        GetClientUserId(iclient);
        if(hours > 0)
        {
            CPrintToChatAll("%t", "ConnectingWithHours", (b_PlayerIdentity ? Player : Admin), iclient, hours);           //[{orange}!{default}] %s{olive} %N [{olive}%iHours{default}] is connecting...
        }
        else
        {
            CPrintToChatAll("%t", "Connecting", (b_PlayerIdentity ? Player : Admin), iclient);             //[{orange}!{default}] %s{olive} %N {default}正在连接中...
        }
    }
}

public void OnClientPutInServer(int iclient)
{
    GetClientInformation(iclient, hours);
    for(iclient = 1; iclient <= MaxClients; iclient++)
    {
        if(IsClientInGame(iclient) && !IsFakeClient(iclient))
        {
            GetClientUserId(iclient);
            if(hours > 0)
            {
                CPrintToChatAll("%t", "PrintConnected_Hours", (b_PlayerIdentity ? Player : Admin), iclient, hours, (GetConVarBool(ShowCountry)? f_country : ""), (GetConVarBool(ShowCity)? city : ""));
            }
            else
            {
                CPrintToChatAll("%t", "PrintConnected", (b_PlayerIdentity ? Player : Admin), iclient, (GetConVarBool(ShowCountry)? f_country : ""), (GetConVarBool(ShowCity)? city : ""));
            }
        }
    }
}

public Action Player_Time_Country(int iclient, int args)
{
    char id[64];
    GetClientInformation(iclient, hours);
    for (iclient = 1 ; iclient <= MaxClients ; iclient++)
    {
        if(IsClientInGame(iclient))
	    {
            GetClientAuthId(iclient, AuthId_Steam2, id, sizeof(id));
	        if(!StrEqual(id, "BOT"))
            {
	            if(hours > 0)
                {
                    CPrintToChat(iclient, "%t", "RequestInfo_Hours", (b_PlayerIdentity ? Player : Admin), iclient, hours, (GetConVarBool(ShowCountry)? f_country : ""), (GetConVarBool(ShowCity)? f_city : ""));
                }
                else
                {
                    CPrintToChat(iclient, "%t", "RequestInfo", (b_PlayerIdentity ? Player : Admin), iclient, (GetConVarBool(ShowCountry)? f_country : ""), (GetConVarBool(ShowCity)? f_city : ""));
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));
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
