#if defined __confogl_configs_included
	#endinput
#endif
#define __confogl_configs_included

#define CONFIGS_MODULE_NAME				"Configs"

static const char
	customCfgDir[] = "cfgogl";

static char
	DirSeparator = '\0',
	configsPath[PLATFORM_MAX_PATH] = "\0",
	cfgPath[PLATFORM_MAX_PATH] = "\0",
	customCfgPath[PLATFORM_MAX_PATH] = "\0",
	customCfgName[PLATFORM_MAX_PATH] = "\0";

static ConVar
	hCustomConfig = null;

void Configs_OnModuleStart()
{
	InitPaths();

	hCustomConfig = CreateConVar("confoglcompmod_customcfg", "", "DONT TOUCH THIS CVAR! This is more magic bullshit!", FCVAR_DONTRECORD|FCVAR_UNLOGGED);

	char cfgString[PLATFORM_MAX_PATH];
	hCustomConfig.GetString(cfgString, sizeof(cfgString));
	SetCustomCfg(cfgString);

	hCustomConfig.RestoreDefault();
}

static void InitPaths()
{
	BuildPath(Path_SM, configsPath, sizeof(configsPath), "configs/confogl/");
	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "../../cfg/");

	DirSeparator = cfgPath[(strlen(cfgPath) - 1)];
}

bool SetCustomCfg(const char[] cfgname)
{
	if (!strlen(cfgname)) 
	{
		customCfgPath[0] = 0;
		hCustomConfig.RestoreDefault();

		if (IsDebugEnabled()) 
			LogMessage("[%s] Custom Config Path Reset - Using Default", CONFIGS_MODULE_NAME);

		return true;
	}

	Format(customCfgPath, sizeof(customCfgPath), "%s%s%c%s", cfgPath, customCfgDir, DirSeparator, cfgname);
	if (!DirExists(customCfgPath)) 
	{
		Debug_LogError(CONFIGS_MODULE_NAME, "Custom config directory %s does not exist!", customCfgPath);
		// Revert customCfgPath
		customCfgPath[0] = 0;
		return false;
	}

	int thislen = strlen(customCfgPath);
	if ((thislen + 1) < sizeof(customCfgPath)) 
	{
		customCfgPath[thislen] = DirSeparator;
		customCfgPath[(thislen + 1)] = 0;
	}
	else 
	{
		Debug_LogError(CONFIGS_MODULE_NAME, "Custom config directory %s path too long!", customCfgPath);
		customCfgPath[0] = 0;
		return false;
	}

	strcopy(customCfgName, sizeof(customCfgName), cfgname);
	hCustomConfig.SetString(cfgname);

	return true;
}

void BuildConfigPath(char[] buffer, const int maxlength, const char[] sFileName)
{
	if (customCfgPath[0]) {
		Format(buffer, maxlength, "%s%s", customCfgPath, sFileName);

		if (FileExists(buffer)) 
		{
			if (IsDebugEnabled()) 
				LogMessage("[%s] Built custom config path: %s", CONFIGS_MODULE_NAME, buffer);

			return;
		}
		else 
		{
			if (IsDebugEnabled()) 
				LogMessage("[%s] Custom config not available: %s", CONFIGS_MODULE_NAME, buffer);
		}
	}

	Format(buffer, maxlength, "%s%s", configsPath, sFileName);
	if (IsDebugEnabled()) 
		LogMessage("[%s] Built default config path: %s", CONFIGS_MODULE_NAME, buffer);
}