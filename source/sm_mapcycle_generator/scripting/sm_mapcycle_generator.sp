#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define MAPCYCLE_FILE "cfg/mapcycle.txt"
#define OFFICIAL_MAPS "maps"
#define DOWNLOAD_MAPS "download/maps"
#define MAX_MAP_NAME  64

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[ANY] MapCycle Generator",
	author = "blueblur",
	description = "Generates or updates a mapcycle.txt file by the existing maps.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    RegServerCmd("sm_mapcycle_generate", Cmd_Generate);
}

Action Cmd_Generate(int args)
{
	// create the mapcycle file, write at the end.
	File hFile = OpenFile(MAPCYCLE_FILE, "w");
	if (!hFile)
	{
		PrintToServer("[MapCycle Generator] Failed to open or create mapcycle file: %s", MAPCYCLE_FILE);
		return Plugin_Handled;
	}

	DirectoryListing hDir = null;
	OpenAndWrite(hFile, hDir, OFFICIAL_MAPS);
	OpenAndWrite(hFile, hDir, DOWNLOAD_MAPS);

	if (args > 0)
	{
		char buffer[256];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (buffer[0] != '\0')
		{
			Format(buffer, sizeof(buffer), "custom/%s/maps", buffer);
			OpenAndWrite(hFile, hDir, buffer);
		}
	}

	delete hDir;
	hFile.Close();
	PrintToServer("[MapCycle Generator] Mapcycle file generated/updated successfully.");
	return Plugin_Handled;
}

void OpenAndWrite(File hFile, DirectoryListing hDir, const char[] path)
{
    hDir = OpenDirectory(path);
    if (hDir)
	{
		char buffer[256];
		FileType type;
		while (hDir.GetNext(buffer, sizeof(buffer), type))
		{
			// Ignore "." and ".."
			if(!strcmp(buffer, ".") || !strcmp(buffer, ".."))
				continue;

			if (type != FileType_File)
				continue;

			int len = strlen(buffer);
			if (len < 4 || strcmp(buffer[len - 4], ".bsp"))
				continue;

			// Remove .bsp extension
			buffer[len - 4] = '\0';  // Terminate string before .bsp
			hFile.WriteLine(buffer);
		}
	}
}