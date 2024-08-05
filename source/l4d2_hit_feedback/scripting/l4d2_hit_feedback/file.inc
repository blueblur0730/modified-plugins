#if defined _l4d2_hit_feedback_file_included
	#endinput
#endif
#define _l4d2_hit_feedback_file_included

void LoadResources(char[] sPath)
{
	char sBuffer[PLATFORM_MAX_PATH];
	int iLen; char SoundFile[PLATFORM_MAX_PATH];
	FileType fileType;

	/**
	 * Note: When use OpenDirectory(), you need to specify concisely the folder in the base game dir.
	 * When use PrecacheSound() and EmitSound*(), the path string dose not need the prefix 'sound/',
	 * the function will automatically search the file under the dir 'sound/' based on the path you put in.
	 */
	Format(sBuffer, PLATFORM_MAX_PATH, sPath);
	Format(sPath, PLATFORM_MAX_PATH, "sound/%s", sPath);
	DirectoryListing hDir = OpenDirectory(sPath, false);
	if (hDir)
	{
		int i = 0;
		while (hDir.GetNext(SoundFile, PLATFORM_MAX_PATH, fileType))
		{
			if (fileType == FileType_File)
			{
				iLen = strlen(SoundFile);
				
				// maybe we should use .wav instead? issues with .mp3 really messed me up.
				if (iLen >= 4 && (strcmp(SoundFile[iLen - 4], ".mp3") == 0 || strcmp(SoundFile[iLen - 4], ".wav") == 0))
				{
					Format(SoundFile, sizeof(SoundFile), "%s/%s", sBuffer, SoundFile);
					if (bCheerOrJeer) g_hArrayCheerFile.PushString(SoundFile);
					else g_hArrayJeerFile.PushString(SoundFile);
					i++;
				}
			}
		}
		if (i == 0)
			LogError("[Cheer!] No sound files found in '%s'.", sPath);
	}
	else
		LogError("[Cheer!] handle 'hDir' is null! '%s' is not a valid directory.", sPath);

    delete hDir;
}

void PreCacheResources()
{
	PrecacheSound(g_sSoundHeadShot, true);
	PrecacheSound(g_sSoundHeadShotDefualt, true);
	PrecacheSound(g_sSoundBodyHit, true);
	PrecacheSound(g_sSoundBodyHitDefualt, true);
	PrecacheSound(g_sSoundKill, true);
	PrecacheSound(g_sSoundKillDefualt, true);

	char overlays_file[64];
	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sOverlayHeadShot);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sOverlayBodyHit);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sOverlayKill);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sOverlayHeadShot);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sOverlayBodyHit);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sOverlayKill);
	PrecacheDecal(overlays_file, true);
}