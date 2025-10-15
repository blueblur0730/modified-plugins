
/**
 * From smmem by Scags.
*/

//----------------------

stock int GetEntityFromHandle(any handle)
{
	int ent = handle & 0xFFF;
	if (ent == 0xFFF)
		ent = -1;
	return ent;
}

// Props to nosoop
stock int GetEntityFromAddress(Address pEntity)
{
	if (pEntity == Address_Null)
		return -1;

	return GetEntityFromHandle(Deref(pEntity + view_as< Address >(FindDataMapInfo(0, "m_angRotation") + 12)));
}

stock any Deref(any addr, NumberType numt = NumberType_Int32)
{
	return LoadFromAddress(view_as< Address >(addr), numt);
}

//----------------------

stock void StripNumberSign(char[] buffer, int maxlen)
{
    // strip "#"
    if (!strncmp(buffer[0], "#", false))
        strcopy(buffer, maxlen, buffer[1]);
}

/**
 * From localizer.inc by Stanislav "Dragokas" Polshyn.
 * https://forums.alliedmods.net/showthread.php?t=339741&highlight=localizer
*/

//----------------------

stock bool ConvertFile_UTF16LE_UTF8(char[] sourceFile, char[] targetFile)
{
	//LogError("Decode: %s", sourceFile);
	
    EngineVersion engine = GetEngineVersion();
	bool use_valve_fs = !(engine == Engine_CSGO); // walkaround CSGO engine (SM?) ERROR_HANDLE_EOF bug

	File hr = OpenFile(sourceFile, "rb", use_valve_fs);

	if( hr )
	{
		// TODO: Add profiler control
		
		File hw = OpenFile(targetFile, "wb", false);
		if( hw )
		{
			// Note: it seems various buffer sizes doesn't affect performance too much
			// 
			int bytesRead, bytesWrite, buff[512/* MUST MOD 4*/], out[sizeof(buff)*3/* MUST MULTIPLY 3*/];
			
			while( !hr.EndOfFile() )
			{
				bytesRead = hr.Read(buff, sizeof(buff), 2);
				WideCharToMultiByte(buff, bytesRead, out, bytesWrite);
				hw.Write(out, bytesWrite, 1);
			}

			delete hw;
		}

		delete hr;
	}
    else
    {
        return false;
    }

	return true;
}

// Note: Little Endian only.
//
stock void WideCharToMultiByte(const int[] input, int maxlen, int[] output, int &bytesWrite)
{
	static int i, n, high_surrogate;
	n = 0;
	high_surrogate = 0;
	for( i = 0; i < maxlen; i++ ) 
    { 
		if( high_surrogate ) // for characters in range 0x10000 <= X <= 0x10FFFF
		{
			int data;
			data = ((high_surrogate - 0xD800) << 10) + (input[i]/*Low surrogate*/ - 0xDC00) + 0x10000;
			output[n++] = ((data >> 18) & 0x07) | 0xF0;
			output[n++] = ((data >> 12) & 0x3F) | 0x80;
			output[n++] = ((data >> 6) & 0x3F) | 0x80;
			output[n++] = (data & 0x3F) | 0x80;
			high_surrogate = 0;
		}
		else if( input[i] < 0x80 ) 
        {
			output[n++] = input[i];
		}
		else if( input[i] < 0x800 ) 
        {
			output[n++] = ((input[i] >> 6) & 0x1F) | 0xC0;
			output[n++] = (input[i] & 0x3F) | 0x80;
		} 
        else if( input[i] <= 0xFFFF ) 
        {
			if( 0xD800 <= input[i] <= 0xDFFF ) 
            {
				high_surrogate = input[i];
				continue;
			}

			output[n++] = ((input[i] >> 12) & 0x0F) | 0xE0;
			output[n++] = ((input[i] >> 6) & 0x3F) | 0x80;
			output[n++] = (input[i] & 0x3F) | 0x80;
		}
	}

	bytesWrite = n;
}

#define LC_MAX_TRANSLATION_LENGTH	3072

stock void ParseFile(char[] sFile, bool use_fallback, StringMap hMap)
{
	int pa /*absolute*/, pr /*relative*/, pc /*current*/, ps = -1 /*start*/, tok /*token number*/, qts /*quote started?*/;
	int p[2] = {-1, ...} /*result tok #0,1*/, p_len[2] /*length of found*/;
	int iLangIndex = -1;
	char str[LC_MAX_TRANSLATION_LENGTH];
	File hr = OpenFile(sFile, "rt");
	if( hr )
	{
		while( !hr.EndOfFile() && hr.ReadLine(str, sizeof(str)) )
		{
			pa = 0;	ps = -1; p[0] = -1;	p[1] = -1; qts = 0; tok = 0;
			
			while( -1 != (pr = FindCharInString(str[pa], '"')) )
			{
				pc = pa+pr;
				if( ps == -1 ) ps = pc + 1;
				if( qts ) 
                {
					if( str[pc-1] != '\\' ) 
                    { 
                        // skip screened quote
						str[pc] = '\0';
						p[tok] = ps;
						p_len[tok] = pc - ps;

						if( tok == 1 ) 
                            break;

						qts = 0;
						ps = -1;
						++ tok;
					}
				}
				else 
                {
					qts = 1;
				}

				pa += pr + 1;
			}
			// TODO: Add multiline translations support
			if( p[0] != -1 && p[1] != -1 && str[p[0]] != 0 && str[p[1]] != 0 && !( p_len[1] == 1 && str[p[1]] == ' ') )
			{
				if( OnProcessKeyValue(str[p[0]], str[p[1]], iLangIndex, use_fallback, hMap) == Plugin_Stop )
				{
					//PrintToServer("[Localizer] [WARN] File %s is skipped. Reason: language name is not recognized.", sFile);
					break;
				}
			}
		}

		delete hr;
	}
}

static const char LC_LANGUAGE_KEY[] =			"Language";

stock Action OnProcessKeyValue(char[] key, char[] value, int &lang_num, bool use_fallback, StringMap hMap)
{
	int indent;
	
	if( key[0] == '[' )
	{
		if( use_fallback ) // for CSGO: "[english]phrase" "translation"
		{
			indent = 9;
		}
		else 
        {
			return Plugin_Continue;
		}
	}
	
	if( lang_num == -1 )
	{
		if( strcmp(key, LC_LANGUAGE_KEY) == 0 )
		{
			lang_num = GetLanguageByName(value);
			if( lang_num == -1 )
				return Plugin_Stop;
		}
	}
	else 
    {
		if( key[indent+0] == '#' )
		{
            hMap.SetString(key[indent+1], value);
			//Loc_AddPhrase(isFallback ? LANG_SERVER : lang_num, key[indent+1], value, false, true, true);
		}
		else 
        {
            hMap.SetString(key[indent+0], value);
			//Loc_AddPhrase(isFallback ? LANG_SERVER : lang_num, key[indent+0], value, false, true, true);
		}
	}

	return Plugin_Continue;
}

//----------------------

static const char g_sOfficialMaps[][] = 
{
    "nmo_broadway",
    "nmo_cabin",
    "nmo_chinatown",
    "nmo_toxteth",
    "nmo_lakeside",
    "nmo_junction",
    "nmo_brooklyn",
    "nmo_zephyr",
    "nmo_cleopas",
    "nmo_fema",
    "nmo_broadwalk",
    "nmo_broadway2",
    "nmo_quarantine",
    "nmo_shelter",
    "nmo_suzhou",
    "nmo_underground",
    "nmo_anxiety",
    "nmo_rockpit",
    "nmo_asylum",
    "nmo_shoreline"
};

stock bool IsOfficialMap(const char[] mapname)
{
    for (int i = 0; i < sizeof(g_sOfficialMaps); i++)
    {
        if (StrEqual(mapname, g_sOfficialMaps[i], false))
        {
            return true;
        }
    }

    return false;
}

stock bool IsClientAdmin(int client, int flag = ADMFLAG_GENERIC)
{
	if (!IsClientInGame(client)) 
        return false;
    
    int flags = GetUserFlagBits(client);
	return (GetUserAdmin(client) != INVALID_ADMIN_ID && flags != 0 && flags & flag != 0);
}

stock int FindEntityByTargetName(const char[] targetname)
{
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "*")) != -1)
    {
        char m_iName[64];
        GetEntPropString(ent, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
        //PrintToServer("Found: %s, %s, %d", targetname, m_iName, ent);
        if (StrEqual(targetname, m_iName))
        {
            //PrintToServer("Found: %s, %d", targetname, ent);
            return ent;
        }
    }

    return -1;
}