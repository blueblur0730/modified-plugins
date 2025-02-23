#if defined __confogl_logging_included
	#endinput
#endif
#define __confogl_logging_included

#define LOGFILE_PATH			 "/logs/confogl_system/"
#define PLUGIN_TAG				 "Confogl"
#define PLUGIN_TAG_SERVERCONSOLE "Confogl_console"

// we want them seperately output the stream on the same log level.
Logger g_hLogger			   = null;
Logger g_hLogger_ServerConsole = null;

static ConVar
	 g_hCvarDebugConVar = null;

void LG_OnPluginStart()
{
	g_hCvarDebugConVar = CreateConVarEx("debug", "0", "Turn on debug logging in all confogl modules", _, true, 0.0, true, 1.0);
	g_hCvarDebugConVar.AddChangeHook(OnDebugChange);

	g_hLogger = CreateBaseFileLoggerOrFailed(PLUGIN_TAG);
	g_hLogger.SetLevel(LogLevel_Info);
	g_hLogger.SetPattern("[%Y-%m-%d %H:%M:%S.%e] [%n] %v");
	g_hLogger.Info("--- Confogl System " ... PLUGIN_VERSION... " Loaded. ---");
	g_hLogger.Flush();
	g_hLogger.FlushOn(LogLevel_Info);

	g_hLogger_ServerConsole = CreateServerConsoleLoggerOrFailed(PLUGIN_TAG_SERVERCONSOLE);
	g_hLogger_ServerConsole.SetLevel(LogLevel_Info);
	g_hLogger_ServerConsole.SetPattern("");
	g_hLogger_ServerConsole.FlushOn(LogLevel_Info);

	if (!LibraryExists("log4sp"))
	{
		g_hLogger.Info("[Confogl] log4sp not loaded, logging will use sourcemod default.");
		g_hLogger_ServerConsole.Info("[Confogl] log4sp not loaded, logging will use sourcemod default.");
	}
}

void LG_OnPluginEnd()
{
	if (g_hLogger) delete g_hLogger;
	if (g_hLogger_ServerConsole) delete g_hLogger_ServerConsole;
}

void LG_OnMapStart()
{
	if (!g_hLogger)
		g_hLogger = CreateBaseFileLoggerOrFailed(PLUGIN_TAG);

	if (!g_hLogger_ServerConsole)
		g_hLogger_ServerConsole = CreateServerConsoleLoggerOrFailed(PLUGIN_TAG_SERVERCONSOLE);
}

Logger CreateServerConsoleLoggerOrFailed(const char[] name)
{
	Logger log = Logger.Get(name);

	if (!log)
	{
		log = ServerConsoleSink.CreateLogger(name);
		if (!log) SetFailState("[Confogl] Failed to create logger.");
	}

	return log;
}

Logger CreateBaseFileLoggerOrFailed(const char[] name)
{
	Logger log = Logger.Get(name);

	if (!log)
	{
		char sChatFilePath[PLATFORM_MAX_PATH], sDate[32];
		FormatTime(sDate, sizeof(sDate), "%d-%m-%y", -1);
		BuildPath(Path_SM, sChatFilePath, sizeof(sChatFilePath), "" ... LOGFILE_PATH... "log-[%s]-port-[%i].log", sDate, FindConVar("hostport").IntValue);
		log = BasicFileSink.CreateLogger(name, sChatFilePath);
		if (!log) SetFailState("[Confogl] Failed to create logger.");
	}

	return log;
}

static void OnDebugChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	hConVar.BoolValue ? g_hLogger.SetLevel(LogLevel_Debug) : g_hLogger.SetLevel(LogLevel_Info);
}