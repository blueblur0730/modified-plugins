
// sm1.11 and older compatability.
int Native_GetHideRange(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
        ThrowNativeError(SP_ERROR_PARAM, "Invalid client index: %d", client);

    if (!AreClientCookiesCached(client))
        ThrowNativeError(SP_ERROR_ABORTED, "Client %N's cookie not cached.", client);

    return g_hCookie.GetInt(client, 0);
}

int Native_SetHideRange(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int value = GetNativeCell(2);

    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
        ThrowNativeError(SP_ERROR_PARAM, "Invalid client index: %d", client);

    if (!AreClientCookiesCached(client))
        ThrowNativeError(SP_ERROR_ABORTED, "Client %N's cookie not cached.", client);

    if (value < 0)
        value = 0;

    g_hCookie.SetInt(client, value);
    return 0;
}