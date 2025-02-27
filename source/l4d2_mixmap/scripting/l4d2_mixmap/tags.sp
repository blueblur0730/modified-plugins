#if defined _l4d2_mixmap_tags_included
	#endinput
#endif
#define _l4d2_mixmap_tags_included

/**
 * To be honest, I never thought that I have to do this.
 * This is the unliest way to translate the tags.
 * 
 * Maybe is the stuctrue too huge to break the buffers.
 * 
 * [2025-02-22 18:00:23.788] [Mixmap] [error] Failed to find "Tokens" key in resource file: "resource/l4d360ui_english.txt"
 * KeyValues Error: LoadFromBuffer: missing { in file resource/l4d360ui_english.txt
*/

static const char g_sTitles[][][] = {
    {"L4D360UI_CampaignName_C1",		"Dead Center"},
    {"L4D360UI_CampaignName_C2",		"Dark Carnival"},
    {"L4D360UI_CampaignName_C3",		"Swamp Fever"},
    {"L4D360UI_CampaignName_C4",		"Hard Rain"},
    {"L4D360UI_CampaignName_C5",		"The Parish"},

    {"L4D360UI_CampaignName_C6",		"The Passing"},
    {"L4D360UI_CampaignName_C7",		"The Sacrifice"},
    {"L4D360UI_CampaignName_C8",		"No Mercy"},
    {"L4D360UI_CampaignName_C9",		"Crash Course"},
    {"L4D360UI_CampaignName_C10",		"Death Toll"},
    {"L4D360UI_CampaignName_C11",		"Dead Air"},
    {"L4D360UI_CampaignName_C12",		"Blood Harvest"},
    {"L4D360UI_CampaignName_C13",		"Cold Stream"},
    {"L4D360UI_CampaignName_C14",		"The Last Stand"}
};

static const char g_sCoopMaps[][][] = {
    {"L4D360UI_LevelName_COOP_C1M1",	"1: Hotel"},
    {"L4D360UI_LevelName_COOP_C1M2",	"2: Streets"},
    {"L4D360UI_LevelName_COOP_C1M3",	"3: Mall"},
    {"L4D360UI_LevelName_COOP_C1M4",	"4: Atrium"},
    {"L4D360UI_LevelName_COOP_C1M5",	"5: Fifth Chapter"},
        
    {"L4D360UI_LevelName_COOP_C2M1",	"1: Highway"},
    {"L4D360UI_LevelName_COOP_C2M2",	"2: Fairground"},
    {"L4D360UI_LevelName_COOP_C2M3",	"3: Coaster"},
    {"L4D360UI_LevelName_COOP_C2M4",    "4: Barns"},
    {"L4D360UI_LevelName_COOP_C2M5",	"5: Concert"},
        
    {"L4D360UI_LevelName_COOP_C3M1",	"1: Plank Country"},
    {"L4D360UI_LevelName_COOP_C3M2",	"2: Swamp"},
    {"L4D360UI_LevelName_COOP_C3M3",	"3: Shanty Town"},
    {"L4D360UI_LevelName_COOP_C3M4",	"4: Plantation"},
        
    {"L4D360UI_LevelName_COOP_C4M1",	"1: Milltown"},
    {"L4D360UI_LevelName_COOP_C4M2",	"2: Sugar Mill"},
    {"L4D360UI_LevelName_COOP_C4M3",	"3: Mill Escape"},
    {"L4D360UI_LevelName_COOP_C4M4",	"4: Return to Town"},
    {"L4D360UI_LevelName_COOP_C4M5",	"5: Town Escape"},
        
    {"L4D360UI_LevelName_COOP_C5M1",	"1: Waterfront"},
    {"L4D360UI_LevelName_COOP_C5M2",	"2: Park"},
    {"L4D360UI_LevelName_COOP_C5M3",	"3: Cemetery"},
    {"L4D360UI_LevelName_COOP_C5M4",	"4: Quarter"},
    {"L4D360UI_LevelName_COOP_C5M5",	"5: Bridge"},

    {"L4D360UI_LevelName_COOP_C13M1",	"1: Alpine Creek"},
    {"L4D360UI_LevelName_COOP_C13M2",	"2: South Pine Stream"},
    {"L4D360UI_LevelName_COOP_C13M3",	"3: Memorial Bridge"},
    {"L4D360UI_LevelName_COOP_C13M4",	"4: Cut-throat Creek"},

    {"L4D360UI_LevelName_COOP_C6M1",	"1: Riverbank"},
    {"L4D360UI_LevelName_COOP_C6M2",	"2: Underground"},
    {"L4D360UI_LevelName_COOP_C6M3",	"3: Port"},

    {"L4D360UI_LevelName_COOP_C7M1",	"1: Docks"},
    {"L4D360UI_LevelName_COOP_C7M2",	"2: Barge"},
    {"L4D360UI_LevelName_COOP_C7M3",	"3: Port"},

    {"L4D360UI_LevelName_COOP_C8M1",	"1: The Apartments"},
    {"L4D360UI_LevelName_COOP_C8M2",	"2: The Subway"},
    {"L4D360UI_LevelName_COOP_C8M3",	"3: The Sewer"},
    {"L4D360UI_LevelName_COOP_C8M4",	"4: The Hospital"},
    {"L4D360UI_LevelName_COOP_C8M5",	"5: Rooftop Finale"},

    {"L4D360UI_LevelName_COOP_C10M1",	"1: The Turnpike"},
    {"L4D360UI_LevelName_COOP_C10M2",	"2: The Drains"},
    {"L4D360UI_LevelName_COOP_C10M3",	"3: The Church"},
    {"L4D360UI_LevelName_COOP_C10M4",	"4: The Town"},
    {"L4D360UI_LevelName_COOP_C10M5",	"5: Boathouse Finale"},

    {"L4D360UI_LevelName_COOP_C9M1",	"1: The Alleys"},
    {"L4D360UI_LevelName_COOP_C9M2",	"2: The Truck Depot Finale"},

    {"L4D360UI_LevelName_COOP_C11M1",	"1: The Greenhouse"},
    {"L4D360UI_LevelName_COOP_C11M2",	"2: The Crane"},
    {"L4D360UI_LevelName_COOP_C11M3",	"3: The Construction Site"},
    {"L4D360UI_LevelName_COOP_C11M4",	"4: The Terminal"},
    {"L4D360UI_LevelName_COOP_C11M5",	"5: Runway Finale"},

    {"L4D360UI_LevelName_COOP_C12M1",	"1: The Woods"},
    {"L4D360UI_LevelName_COOP_C12M2",	"2: The Tunnel"},
    {"L4D360UI_LevelName_COOP_C12M3",	"3: The Bridge"},
    {"L4D360UI_LevelName_COOP_C12M4",	"4: The Train Station"},
    {"L4D360UI_LevelName_COOP_C12M5",	"5: Farmhouse Finale"},

    {"L4D360UI_LevelName_COOP_C14M1",	"1: The Junkyard"},
    {"L4D360UI_LevelName_COOP_C14M2",	"2: Lighthouse Finale"}
};

static const char g_sVersusMaps[][][] = {
    {"L4D360UI_LevelName_VERSUS_C1M1",	"1: Hotel (VS)"},
    {"L4D360UI_LevelName_VERSUS_C1M2",	"2: Streets (VS)"},
    {"L4D360UI_LevelName_VERSUS_C1M3",	"3: Mall (VS)"},
    {"L4D360UI_LevelName_VERSUS_C1M4",	"4: Atrium (VS)"},
    {"L4D360UI_LevelName_VERSUS_C1M5",	"5: Fifth Chapter (VS)"},
        
    {"L4D360UI_LevelName_VERSUS_C2M1",	"1: Highway (VS)"},
    {"L4D360UI_LevelName_VERSUS_C2M2",	"2: Fairground (VS)"},
    {"L4D360UI_LevelName_VERSUS_C2M3",	"3: Coaster (VS)"},
    {"L4D360UI_LevelName_VERSUS_C2M4",	"4: Barns (VS)"},
    {"L4D360UI_LevelName_VERSUS_C2M5",	"5: Concert (VS)"},
        
    {"L4D360UI_LevelName_VERSUS_C3M1",	"1: Plank Country (VS)"},
    {"L4D360UI_LevelName_VERSUS_C3M2",	"2: Swamp (VS)"},
    {"L4D360UI_LevelName_VERSUS_C3M3",	"3: Shanty Town (VS)"},
    {"L4D360UI_LevelName_VERSUS_C3M4",	"4: Plantation (VS)"},
        
    {"L4D360UI_LevelName_VERSUS_C4M1",	"1: Milltown (VS)"},
    {"L4D360UI_LevelName_VERSUS_C4M2",	"2: Sugar Mill (VS)"},
    {"L4D360UI_LevelName_VERSUS_C4M3",	"3: Mill Escape (VS)"},
    {"L4D360UI_LevelName_VERSUS_C4M4",	"4: Return to Town (VS)"},
    {"L4D360UI_LevelName_VERSUS_C4M5",	"5: Town Escape (VS)"},
        
    {"L4D360UI_LevelName_VERSUS_C5M1",	"1: Waterfront (VS)"},
    {"L4D360UI_LevelName_VERSUS_C5M2",	"2: Park (VS)"},
    {"L4D360UI_LevelName_VERSUS_C5M3",	"3: Cemetery (VS)"},
    {"L4D360UI_LevelName_VERSUS_C5M4",	"4: Quarter (VS)"},
    {"L4D360UI_LevelName_VERSUS_C5M5",	"5: Bridge (VS)"},

    {"L4D360UI_LevelName_VERSUS_C6M1",	"1: Riverbank (VS)"},
    {"L4D360UI_LevelName_VERSUS_C6M2",	"2: Underground (VS)"},
    {"L4D360UI_LevelName_VERSUS_C6M3",	"3: Port (VS)"},

    {"L4D360UI_LevelName_VERSUS_C7M1",	"1: Docks (VS)"},
    {"L4D360UI_LevelName_VERSUS_C7M2",	"2: Barge (VS)"},
    {"L4D360UI_LevelName_VERSUS_C7M3",	"3: Port (VS)"},

    {"L4D360UI_LevelName_VERSUS_C8M1",	"1: The Apartments (VS)"},
    {"L4D360UI_LevelName_VERSUS_C8M2",	"2: The Subway (VS)"},
    {"L4D360UI_LevelName_VERSUS_C8M3",	"3: The Sewer (VS)"},
    {"L4D360UI_LevelName_VERSUS_C8M4",	"4: The Hospital (VS)"},
    {"L4D360UI_LevelName_VERSUS_C8M5",	"5: Rooftop Finale (VS)"},

    {"L4D360UI_LevelName_VERSUS_C9M1",	"1: The Alleys (VS)"},
    {"L4D360UI_LevelName_VERSUS_C9M2",	"2: The Truck Depot Finale (VS)"},

    {"L4D360UI_LevelName_VERSUS_C10M1",	"1: The Turnpike (VS)"},
    {"L4D360UI_LevelName_VERSUS_C10M2",	"2: The Drains (VS)"},
    {"L4D360UI_LevelName_VERSUS_C10M3",	"3: The Church (VS)"},
    {"L4D360UI_LevelName_VERSUS_C10M4",	"4: The Town (VS)"},
    {"L4D360UI_LevelName_VERSUS_C10M5",	"5: Boathouse Finale (VS)"},

    {"L4D360UI_LevelName_VERSUS_C11M1",	"1: The Greenhouse (VS)"},
    {"L4D360UI_LevelName_VERSUS_C11M2",	"2: The Crane (VS)"},
    {"L4D360UI_LevelName_VERSUS_C11M3",	"3: The Construction Site (VS)"},
    {"L4D360UI_LevelName_VERSUS_C11M4",	"4: The Terminal (VS)"},
    {"L4D360UI_LevelName_VERSUS_C11M5",	"5: Runway Finale (VS)"},

    {"L4D360UI_LevelName_VERSUS_C12M1",	"1: The Woods (VS)"},
    {"L4D360UI_LevelName_VERSUS_C12M2",	"2: The Tunnel (VS)"},
    {"L4D360UI_LevelName_VERSUS_C12M3",	"3: The Bridge (VS)"},
    {"L4D360UI_LevelName_VERSUS_C12M4",	"4: The Train Station (VS)"},
    {"L4D360UI_LevelName_VERSUS_C12M5",	"5: Farmhouse Finale (VS)"},

    {"L4D360UI_LevelName_VERSUS_C13M1",	"1: Alpine Creek (VS)"},
    {"L4D360UI_LevelName_VERSUS_C13M2",	"2: South Pine Stream (VS)"},
    {"L4D360UI_LevelName_VERSUS_C13M3",	"3: Memorial Bridge (VS)"},
    {"L4D360UI_LevelName_VERSUS_C13M4",	"4: Cut-throat Creek (VS)"},

    {"L4D360UI_LevelName_VERSUS_C14M1",	"1: The Junkyard (VS)"},
    {"L4D360UI_LevelName_VERSUS_C14M2",	"2: Lighthouse Finale (VS)"}
};

static const char g_sScavengeMaps[][][] = {

    {"L4D360UI_LevelName_SCAVENGE_C1M4",	"Mall Atrium"},
        
    {"L4D360UI_LevelName_SCAVENGE_C2M1",	"Motel"},
        
    {"L4D360UI_LevelName_SCAVENGE_C3M1",	"Plank Country"},
        
    {"L4D360UI_LevelName_SCAVENGE_C4M1",	"Milltown"},
    {"L4D360UI_LevelName_SCAVENGE_C4M2",	"Sugar Mill"},
    {"L4D360UI_LevelName_SCAVENGE_C4M5",	"Milltown Escape"},
        
    {"L4D360UI_LevelName_SCAVENGE_C5M2",	"Park"},

    {"L4D360UI_LevelName_SCAVENGE_C6M1",	"Riverbank"},
    {"L4D360UI_LevelName_SCAVENGE_C6M2",	"Underground"},
    {"L4D360UI_LevelName_SCAVENGE_C6M3",	"Port"},

    {"L4D360UI_LevelName_SCAVENGE_C7M1",	"Brick Factory"},
    {"L4D360UI_LevelName_SCAVENGE_C7M2",	"Barge"},

    {"L4D360UI_LevelName_SCAVENGE_C8M1",	"The Apartments"},
    {"L4D360UI_LevelName_SCAVENGE_C8M5",	"The Rooftop"},

    {"L4D360UI_LevelName_SCAVENGE_C9M1",	"The Alleys"},

    {"L4D360UI_LevelName_SCAVENGE_C10M3",	"The Church"},

    {"L4D360UI_LevelName_SCAVENGE_C11M4",	"The Terminal"},

    {"L4D360UI_LevelName_SCAVENGE_C12M5",	"The Farmhouse"},

    {"L4D360UI_LevelName_SCAVENGE_C14M1",	"The Village"},
    {"L4D360UI_LevelName_SCAVENGE_C14M2",	"The Lighthouse"}
};

// Thanks valve I love you.
stock void ConvertOfficialMapTag(char[] sTag, int size, const char[] sMode)
{
	// strip "#"
	if (!strncmp(sTag[0], "#", false))
		strcopy(sTag, size, sTag[1]);

    LoopThroughTags(sTag, size, g_sTitles, sizeof(g_sTitles));

    switch (sMode[0])
    {
        case 'c':
            LoopThroughTags(sTag, size, g_sCoopMaps, sizeof(g_sCoopMaps));

        case 'v':
            LoopThroughTags(sTag, size, g_sVersusMaps, sizeof(g_sVersusMaps));

        case 's':
            LoopThroughTags(sTag, size, g_sScavengeMaps, sizeof(g_sScavengeMaps));
    }
}

static void LoopThroughTags(char[] sTag, int size, const char[][][] sTagPhrases, int maxlength)
{
    for (int i = 0; i < maxlength; i++)
    {
        if (!strcmp(sTag, sTagPhrases[i][0]))
            strcopy(sTag, size, sTagPhrases[i][1]);
    }
}