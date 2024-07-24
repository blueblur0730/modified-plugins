#if defined _l4d2_hit_feedback_cookies_included
	#endinput
#endif
#define _l4d2_hit_feedback_cookies_included

void ReadClientCookies(int client)
{
	char sBuffer[4];

	GetClientCookie(client, g_hStyleCookie, sBuffer, sizeof(sBuffer));
	g_iStyle[client] = (sBuffer[0] == '\0' ? 3 : StringToInt(sBuffer));
}

void SetClientCookies(int client)
{
	char sValue[4];

	Format(sValue, sizeof(sValue), "%i", g_iStyle[client]);
	SetClientCookie(client, g_hStyleCookie, sValue);
}