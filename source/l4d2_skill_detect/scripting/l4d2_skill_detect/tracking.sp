#if defined _skill_detect_tracking_included
	#endinput
#endif
#define _skill_detect_tracking_included

#define L4D2_MAXPLAYERS		  32

#define SHOTGUN_BLAST_TIME	  0.1
#define POUNCE_CHECK_TIME	  0.1
#define HOP_CHECK_TIME		  0.1
#define HOPEND_CHECK_TIME	  0.1	 // after streak end (potentially) detected, to check for realz?
#define SHOVE_TIME			  0.05
#define MAX_CHARGE_TIME		  12.0	  // maximum time to pass before charge checking ends
#define CHARGE_CHECK_TIME	  0.25	  // check interval for survivors flying from impacts
#define CHARGE_END_CHECK	  2.5	  // after client hits ground after getting impact-charged: when to check whether it was a death
#define CHARGE_END_RECHECK	  3.0	  // safeguard wait to recheck on someone getting incapped out of bounds
#define VOMIT_DURATION_TIME	  2.25	  // how long the boomer vomit stream lasts -- when to check for boom count
#define ROCK_CHECK_TIME		  0.34	  // how long to wait after rock entity is destroyed before checking for skeet/eat (high to avoid lag issues)
#define CARALARM_MIN_TIME	  0.11	  // maximum time after touch/shot => alarm to connect the two events (test this for LAG)

#define WITCH_CHECK_TIME	  0.1	  // time to wait before checking for witch crown after shoots fired
#define WITCH_DELETE_TIME	  0.15	  // time to wait before deleting entry from witch Map after entity is destroyed

#define MIN_DC_TRIGGER_DMG	  300	   // minimum amount a 'trigger' / drown must do before counted as a death action
#define MIN_DC_FALL_DMG		  175	   // minimum amount of fall damage counts as death-falling for a deathcharge
#define WEIRD_FLOW_THRESH	  900.0	   // -9999 seems to be break flow.. but meh
#define MIN_FLOWDROPHEIGHT	  350.0	   // minimum height a survivor has to have dropped before a WEIRD_FLOW value is treated as a DC spot
#define MIN_DC_RECHECK_DMG	  100	   // minimum damage from map to have taken on first check, to warrant recheck

#define HOP_ACCEL_THRESH	  0.01	  // bhop speed increase must be higher than this for it to count as part of a hop streak

#define DMGARRAYEXT			  7	   // L4D2_MAXPLAYERS+# -- extra indices in witch_dmg_array + 1

#define CUT_SHOVED			  1	   // smoker got shoved
#define CUT_SHOVEDSURV		  2	   // survivor got shoved
#define CUT_KILL			  3	   // reason for tongue break (release_type)
#define CUT_SLASH			  4	   // this is used for others shoving a survivor free too, don't trust .. it involves tongue damage?

#define VICFLG_CARRIED		  (1 << 0)	  // was the one that the charger carried (not impacted)
#define VICFLG_FALL			  (1 << 1)	  // flags stored per charge victim, to check for deathchargeroony -- fallen
#define VICFLG_DROWN		  (1 << 2)	  // drowned
#define VICFLG_HURTLOTS		  (1 << 3)	  // whether the victim was hurt by 400 dmg+ at once
#define VICFLG_TRIGGER		  (1 << 4)	  // killed by trigger_hurt
#define VICFLG_AIRDEATH		  (1 << 5)	  // died before they hit the ground (impact check)
#define VICFLG_KILLEDBYOTHER  (1 << 6)	  // if the survivor was killed by an SI other than the charger
#define VICFLG_WEIRDFLOW	  (1 << 7)	  // when survivors get out of the map and such
#define VICFLG_WEIRDFLOWDONE  (1 << 8)	  //      checked, don't recheck for this

#define ZC_SMOKER			  1
#define ZC_BOOMER			  2
#define ZC_HUNTER			  3
#define ZC_SPITTER			  4
#define ZC_JOCKEY			  5
#define ZC_CHARGER			  6
#define ZC_WITCH			  7
#define ZC_TANK				  8

#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

// Map values: weapon type
enum strWeaponType
{
	WPTYPE_SNIPER,
	WPTYPE_MAGNUM,
	WPTYPE_GL
};

// Map values: OnEntityCreated classname
enum strOEC
{
	OEC_WITCH,
	OEC_TANKROCK,
	OEC_TRIGGER,
	OEC_CARALARM,
	OEC_CARGLASS
};

// Map values: special abilities
enum strAbility
{
	ABL_HUNTERLUNGE,
	ABL_ROCKTHROW
};

enum
{
	rckDamage,
	rckTank,
	rckSkeeter,
	strRockData
};

// witch array enMaps (L4D2_MAXPLAYERS+index)
enum
{
	WTCH_NONE,
	WTCH_HEALTH,
	WTCH_GOTSLASH,
	WTCH_STARTLED,
	WTCH_CROWNER,
	WTCH_CROWNSHOT,
	WTCH_CROWNTYPE,
	strWitchArray
};

enum
{
	CALARM_UNKNOWN,
	CALARM_HIT,
	CALARM_TOUCHED,
	CALARM_EXPLOSION,
	CALARM_BOOMER,
	enAlarmReasons
};

enum struct SISkillCache_t
{
	// all SI / pinners
	float m_flSpawnTime;	   // time the SI spawned up
	float m_flPinTime[2];	   // time the SI pinned a target: 0 = start of pin (tongue pull, charger carry); 1 = carry end / tongue reigned in
	int	  m_iSpecialVictim;	   // current victim (set in traceattack, so we can check on death)

	// rocks
	int	  m_iTankRock;	  // rock entity per tank
}
static SISkillCache_t g_SISkillCache[L4D2_MAXPLAYERS + 1];

enum struct TankRockTrace_t
{
	int m_iThrower;
	int m_iRock;
	int m_iDamageTaken;
	int m_iSkeeter;
}
static ArrayList g_hArray_TankRockTrace;

enum struct SkillCache_t
{
	// hunters: skeets/pounces
	int	  m_iHunterShotDmgTeam;						   // counting shotgun blast damage for hunter, counting entire survivor team's damage
	int	  m_iHunterShotDmg[L4D2_MAXPLAYERS + 1];	   // counting shotgun blast damage for hunter / skeeter combo
	float m_flHunterShotStart[L4D2_MAXPLAYERS + 1];	   // when the last shotgun blast on hunter started (if at any time) by an attacker
	float m_flHunterTracePouncing;					   // time when the hunter was still pouncing (in traceattack) -- used to detect pouncing status
	float m_flHunterLastShot;						   // when the last shotgun damage was done (by anyone) on a hunter
	int	  m_iHunterLastHealth;						   // last time hunter took any damage, how much health did it have left?
	int	  m_iHunterOverkill;						   // how much more damage a hunter would've taken if it wasn't already dead
	bool  m_bHunterKilledPouncing;					   // whether the hunter was killed when actually pouncing
	int	  m_iPounceDamage;							   // how much damage on last 'highpounce' done
	float m_flPouncePosition[3];					   // position that a hunter (jockey?) pounced from (or charger started his carry)

	// deadstops
	float m_flVictimLastShove[L4D2_MAXPLAYERS + 1];	   // when was the player shoved last by attacker? (to prevent doubles)

	// levels / charges
	int	  m_iChargerHealth;			 // how much health the charger had the last time it was seen taking damage
	float m_flChargeTime;			 // time the charger's charge last started, or if victim, when impact started
	int	  m_iChargeVictim;			 // who got charged
	float m_flChargeVictimPos[3];	 // location of each survivor when it got hit by the charger
	int	  m_iVictimCharger;			 // for a victim, by whom they got charge(impacted)
	int	  m_iVictimFlags;			 // flags stored per charge victim: VICFLAGS_
	int	  m_iVictimMapDmg;			 // for a victim, how much the cumulative map damage is so far (trigger hurt / drowning)

	// pops
	bool  m_bBoomerHitSomebody;	   // false if boomer didn't puke/exploded on anybody
	int	  m_iBoomerGotShoved;	   // how many times the boomer got shoved
	int	  m_iBoomerVomitHits;	   // how many booms in one vomit so far

	// crowns
	float m_flWitchShotStart;	 // when the last shotgun blast from a survivor started (on any witch)

	// smoker clears
	bool  m_bSmokerClearCheck;		// [smoker] smoker dies and this is set, it's a self-clear if m_iSmokerVictim is the killer
	int	  m_iSmokerVictim;			// [smoker] the one that's being pulled
	int	  m_iSmokerVictimDamage;	// [smoker] amount of damage done to a smoker by the one he pulled
	bool  m_bSmokerShoved;			// [smoker] set if the victim of a pull manages to shove the smoker

	// hops
	bool  m_bIsHopping;			 // currently in a hop streak
	bool  m_bHopCheck;			 // flag to check whether a hopstreak has ended (if on ground for too long.. ends)
	int	  m_iHops;				 // amount of hops in streak
	float m_flLastHop[3];		 // velocity vector of last jump
	float m_flHopTopVelocity;	 // maximum velocity in hopping streak

	// alarms
	int	  m_iLastCarAlarmReason;	// what this survivor did to set the last alarm off
}
static SkillCache_t g_SkillCache[L4D2_MAXPLAYERS + 1];

static float		g_fLastCarAlarm			 = 0.0;	   // time when last car alarm went off
static int			g_iLastCarAlarmBoomer;			   // if a boomer triggered an alarm, remember it

void _skill_detect_tracking_OnPluginStart()
{
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClientInGame(client))
			{
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
			}	
		}
	}

	g_hArray_TankRockTrace = new ArrayList(sizeof(TankRockTrace_t));
}

void _skill_detect_tracking_OnPluginEnd()
{
	delete g_hArray_TankRockTrace;
}

void _skill_detect_tracking_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
}

void HookSkillDetectEvent()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
	HookEvent("lunge_pounce", Event_LungePounce, EventHookMode_Post);
	HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
	HookEvent("player_jump", Event_PlayerJumped, EventHookMode_Post);
	HookEvent("player_jump_apex", Event_PlayerJumpApex, EventHookMode_Post);

	HookEvent("player_now_it", Event_PlayerBoomed, EventHookMode_Post);
	HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);

	HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet, EventHookMode_Post);

	HookEvent("tongue_grab", Event_TongueGrab, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);
	HookEvent("choke_start", Event_ChokeStart, EventHookMode_Post);
	HookEvent("choke_stopped", Event_ChokeStop, EventHookMode_Post);
	HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Post);
	HookEvent("charger_carry_start", Event_ChargeCarryStart, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargeCarryEnd, EventHookMode_Post);
	HookEvent("charger_impact", Event_ChargeImpact, EventHookMode_Post);
	HookEvent("charger_pummel_start", Event_ChargePummelStart, EventHookMode_Post);

	HookEvent("player_incapacitated_start", Event_IncapStart, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_CarAlarmGoesOff, EventHookMode_Post);
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_SkillCache[i].m_bIsHopping = false;

		for (int j = 1; j <= MaxClients; j++)
			g_SkillCache[i].m_flVictimLastShove[j] = 0.0;
	}

	g_hArray_TankRockTrace.Clear();
}

static void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// clean Map, new cars will be created
	g_hCarMap.Clear();
}

static void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsValidClientInGame(victim) || !IsValidClientInGame(attacker))
		return;

	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	int damage	   = event.GetInt("dmg_health");
	int damagetype = event.GetInt("type");

	if (IsValidInfected(victim))
	{	 
		int health	 = event.GetInt("health");
		int hitgroup = event.GetInt("hitgroup");

		if (damage < 1)
			return;

		switch (zClass)
		{
			case ZC_HUNTER:
			{
				// if it's not a survivor doing the work, only get the remaining health
				if (!IsValidSurvivor(attacker))
				{
					g_SkillCache[victim].m_iHunterLastHealth = health;
					return;
				}

				// if the damage done is greater than the health we know the hunter to have remaining, reduce the damage done
				if (g_SkillCache[victim].m_iHunterLastHealth > 0 && damage > g_SkillCache[victim].m_iHunterLastHealth)
				{
					damage = g_SkillCache[victim].m_iHunterLastHealth;
					g_SkillCache[victim].m_iHunterOverkill	 = g_SkillCache[victim].m_iHunterLastHealth - damage;
					g_SkillCache[victim].m_iHunterLastHealth = 0;
				}

				/*
					handle old shotgun blast: too long ago? not the same blast
				*/
				if (g_SkillCache[victim].m_iHunterShotDmg[attacker] > 0 && (GetGameTime() - g_SkillCache[victim].m_flHunterShotStart[attacker]) > SHOTGUN_BLAST_TIME)
					g_SkillCache[victim].m_flHunterShotStart[attacker] = 0.0;

				/*
					m_isAttemptingToPounce is set to 0 here if the hunter is actually skeeted
					so the g_SkillCache[victim].m_flHunterTracePouncing value indicates when the hunter was last seen pouncing in traceattack
					(should be DIRECTLY before this event for every shot).
				*/
				bool isPouncing = view_as<bool>(GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce") || g_SkillCache[victim].m_flHunterTracePouncing != 0.0 && (GetGameTime() - g_SkillCache[victim].m_flHunterTracePouncing) < 0.001);

				if (isPouncing)
				{
					if (damagetype & DMG_BUCKSHOT)
					{
						// first pellet hit?
						if (g_SkillCache[victim].m_flHunterShotStart[attacker] == 0.0)
						{
							// new shotgun blast
							g_SkillCache[victim].m_flHunterShotStart[attacker] = GetGameTime();
							g_SkillCache[victim].m_flHunterLastShot			   = g_SkillCache[victim].m_flHunterShotStart[attacker];
						}

						g_SkillCache[victim].m_iHunterShotDmg[attacker] += damage;
						g_SkillCache[victim].m_iHunterShotDmgTeam += damage;

						if (health == 0)
							g_SkillCache[victim].m_bHunterKilledPouncing = true;
					}
					else if (damagetype & (DMG_BLAST | DMG_PLASMA) && health == 0)
					{
						// direct GL hit?
						/*
							direct hit is DMG_BLAST | DMG_PLASMA
							indirect hit is DMG_AIRBOAT
						*/

						char		  weaponB[32];
						strWeaponType weaponTypeB;
						event.GetString("weapon", weaponB, sizeof(weaponB));

						if (g_hMapWeapons.GetValue(weaponB, weaponTypeB) && weaponTypeB == WPTYPE_GL)
						{
							if (g_hCvar_AllowGLSkeet.BoolValue)
								HandleSkeet(attacker, victim, false, false, true);
						}
					}
					else if (damagetype & DMG_BULLET && health == 0 && hitgroup == HITGROUP_HEAD)
					{
						// headshot with bullet based weapon (only single shots) -- only snipers
						char		  weaponA[32];
						strWeaponType weaponTypeA;
						event.GetString("weapon", weaponA, sizeof(weaponA));

						if (g_hMapWeapons.GetValue(weaponA, weaponTypeA) && (weaponTypeA == WPTYPE_SNIPER || weaponTypeA == WPTYPE_MAGNUM))
						{
							if (damage >= g_iPounceInterrupt)
							{
								g_SkillCache[victim].m_iHunterShotDmgTeam = 0;
								if (g_hCvar_AllowSniper.BoolValue)
									HandleSkeet(attacker, victim, false, true);

								ResetHunter(victim);
							}
							else
							{
								// hurt skeet
								if (g_hCvar_AllowSniper.BoolValue)
									HandleNonSkeet(attacker, victim, damage, (g_SkillCache[victim].m_iHunterOverkill + g_SkillCache[victim].m_iHunterShotDmgTeam > g_iPounceInterrupt), false, true);

								ResetHunter(victim);
							}
						}

						// already handled hurt skeet above
						// g_SkillCache[victim].m_bHunterKilledPouncing = true;
					}
					else if (damagetype & DMG_SLASH || damagetype & DMG_CLUB)
					{
						// melee skeet
						if (damage >= g_iPounceInterrupt)
						{
							g_SkillCache[victim].m_iHunterShotDmgTeam = 0;
							if (g_hCvar_AllowMelee.BoolValue)
								HandleSkeet(attacker, victim, true);

							ResetHunter(victim);
							// g_SkillCache[victim].m_bHunterKilledPouncing = true;
						}
						else if (health == 0)
						{
							// hurt skeet (always overkill)
							if (g_hCvar_AllowMelee.BoolValue)
								HandleNonSkeet(attacker, victim, damage, true, true, false);

							ResetHunter(victim);
						}
					}
				}
				else if (health == 0)
				{
					// make sure we don't mistake non-pouncing hunters as 'not skeeted'-warnable
					g_SkillCache[victim].m_bHunterKilledPouncing = false;
				}

				// store last health seen for next damage event
				g_SkillCache[victim].m_iHunterLastHealth = health;
			}

			case ZC_CHARGER:
			{
				if (IsValidSurvivor(attacker))
				{
					// check for levels
					if (health == 0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH))
					{
						int iChargeHealth = g_hCvar_ChargerHealth.IntValue;
						int abilityEnt	  = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
						if (IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging"))
						{
							// fix fake damage?
							if (g_hCvar_HideFakeDamage.BoolValue)
								damage = iChargeHealth - g_SkillCache[victim].m_iChargerHealth;

							// charger was killed, was it a full level?
							(damage > (iChargeHealth * 0.65)) ? HandleLevel(attacker, victim) : HandleLevelHurt(attacker, victim, damage);
						}
					}
				}

				// store health for next damage it takes
				if (health > 0)
					g_SkillCache[victim].m_iChargerHealth = health;
			}

			case ZC_SMOKER:
			{
				if (!IsValidSurvivor(attacker))
					return;

				g_SkillCache[victim].m_iSmokerVictimDamage += damage;
			}
		}
	}
	else if (IsValidInfected(attacker))
	{
		switch (zClass)
		{
			case ZC_HUNTER:
			{
				// a hunter pounce landing is DMG_CRUSH
				if (damagetype & DMG_CRUSH)
					g_SkillCache[attacker].m_iPounceDamage = damage;
			}

			case ZC_TANK:
			{
				char weapon[10];
				event.GetString("weapon", weapon, sizeof(weapon));

				if (StrEqual(weapon, "tank_rock"))
				{
					if (IsValidSurvivor(victim))
						HandleRockEaten(attacker, victim);
				}

				return;
			}
		}
	}

	// check for deathcharge flags
	if (IsValidSurvivor(victim))
	{
		// debug
		if (damagetype & DMG_DROWN || damagetype & DMG_FALL)
			g_SkillCache[victim].m_iVictimMapDmg += damage;

		if (damagetype & DMG_DROWN && damage >= MIN_DC_TRIGGER_DMG)
		{
			g_SkillCache[victim].m_iVictimFlags = g_SkillCache[victim].m_iVictimFlags | VICFLG_HURTLOTS;
		}
		else if (damagetype & DMG_FALL && damage >= MIN_DC_FALL_DMG)
		{
			g_SkillCache[victim].m_iVictimFlags = g_SkillCache[victim].m_iVictimFlags | VICFLG_HURTLOTS;
		}
	}
}

static void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidInfected(client))
		return;

	int zClass							  = GetEntProp(client, Prop_Send, "m_zombieClass");

	g_SISkillCache[client].m_flSpawnTime  = GetGameTime();
	g_SISkillCache[client].m_flPinTime[0] = 0.0;
	g_SISkillCache[client].m_flPinTime[1] = 0.0;

	switch (zClass)
	{
		case ZC_BOOMER:
		{
			g_SkillCache[client].m_bBoomerHitSomebody = false;
			g_SkillCache[client].m_iBoomerGotShoved	  = 0;
		}

		case ZC_SMOKER:
		{
			g_SkillCache[client].m_bSmokerClearCheck   = false;
			g_SkillCache[client].m_iSmokerVictim	   = 0;
			g_SkillCache[client].m_iSmokerVictimDamage = 0;
		}

		case ZC_HUNTER:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Hunter);
			g_SkillCache[client].m_flPouncePosition[0] = 0.0;
			g_SkillCache[client].m_flPouncePosition[1] = 0.0;
			g_SkillCache[client].m_flPouncePosition[2] = 0.0;
		}

		case ZC_JOCKEY:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Jockey);
			g_SkillCache[client].m_flPouncePosition[0] = 0.0;
			g_SkillCache[client].m_flPouncePosition[1] = 0.0;
			g_SkillCache[client].m_flPouncePosition[2] = 0.0;
		}

		case ZC_CHARGER:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Charger);
			g_SkillCache[client].m_iChargerHealth = g_hCvar_ChargerHealth.IntValue;
		}
	}
}

// player about to get incapped
static void Event_IncapStart(Event event, const char[] name, bool dontBroadcast)
{
	// test for deathcharges

	int	   client	 = GetClientOfUserId(event.GetInt("userid"));
	// int attacker = GetClientOfUserId( event.GetInt("attacker") );
	int	   attackent = event.GetInt("attackerentid");
	int	   dmgtype	 = event.GetInt("type");

	char   classname[24];
	strOEC classnameOEC;
	if (IsValidEntity(attackent))
	{
		GetEdictClassname(attackent, classname, sizeof(classname));
		if (g_hMapEntityCreated.GetValue(classname, classnameOEC))
			g_SkillCache[client].m_iVictimFlags = g_SkillCache[client].m_iVictimFlags | VICFLG_TRIGGER;
	}

	float flow = GetSurvivorDistance(client);
	// PrintDebug("Incap Pre on [%N]: attk: %i / %i (%s) - dmgtype: %i - flow: %.1f", client, attacker, attackent, classname, dmgtype, flow );

	// drown is damage type
	if (dmgtype & DMG_DROWN)
		g_SkillCache[client].m_iVictimFlags = g_SkillCache[client].m_iVictimFlags | VICFLG_DROWN;

	if (flow < WEIRD_FLOW_THRESH)
		g_SkillCache[client].m_iVictimFlags = g_SkillCache[client].m_iVictimFlags | VICFLG_WEIRDFLOW;
}

// trace attacks on hunters
static Action TraceAttack_Hunter(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	g_SISkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_pounceVictim");

	if (!IsValidSurvivor(attacker) || !IsValidEdict(inflictor))
		return Plugin_Continue;

	// track flight
	if (GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
	{
		g_SkillCache[victim].m_flHunterTracePouncing = GetGameTime();
	}
	else
	{
		g_SkillCache[victim].m_flHunterTracePouncing = 0.0;
	}

	return Plugin_Continue;
}

static Action TraceAttack_Charger(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	int victimA = GetEntPropEnt(victim, Prop_Send, "m_carryVictim");

	if (victimA != -1)
	{
		g_SISkillCache[victim].m_iSpecialVictim = victimA;
	}
	else
	{
		g_SISkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_pummelVictim");
	}

	return Plugin_Continue;
}

static Action TraceAttack_Jockey(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	g_SISkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim");

	return Plugin_Continue;
}

static void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IsValidInfected(victim))
	{
		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

		switch (zClass)
		{
			case ZC_HUNTER:
			{
				if (!IsValidSurvivor(attacker))
					return;

				if (g_SkillCache[victim].m_iHunterShotDmgTeam > 0 && g_SkillCache[victim].m_bHunterKilledPouncing)
				{
					// skeet?
					if (g_SkillCache[victim].m_iHunterShotDmgTeam > g_SkillCache[victim].m_iHunterShotDmg[attacker] && g_SkillCache[victim].m_iHunterShotDmgTeam >= g_iPounceInterrupt)
					{
						// team skeet
						HandleSkeet(-2, victim);
					}
					else if (g_SkillCache[victim].m_iHunterShotDmg[attacker] >= g_iPounceInterrupt)
					{
						// single player skeet
						HandleSkeet(attacker, victim);
					}
					else if (g_SkillCache[victim].m_iHunterOverkill > 0)
					{
						// overkill? might've been a skeet, if it wasn't on a hurt hunter (only for shotguns)
						HandleNonSkeet(attacker, victim, g_SkillCache[victim].m_iHunterShotDmgTeam, (g_SkillCache[victim].m_iHunterOverkill + g_SkillCache[victim].m_iHunterShotDmgTeam > g_iPounceInterrupt));
					}
					else
					{
						// not a skeet at all
						HandleNonSkeet(attacker, victim, g_SkillCache[victim].m_iHunterShotDmg[attacker]);
					}
				}
				else
				{
					// check whether it was a clear
					if (g_SISkillCache[victim].m_iSpecialVictim > 0)
						HandleClear(attacker, victim, g_SISkillCache[victim].m_iSpecialVictim, ZC_HUNTER, (GetGameTime() - g_SISkillCache[victim].m_flPinTime[0]), -1.0);
				}

				ResetHunter(victim);
			}

			case ZC_SMOKER:
			{
				if (!IsValidSurvivor(attacker))
					return;

				if (g_SkillCache[victim].m_bSmokerClearCheck && g_SkillCache[victim].m_iSmokerVictim == attacker && g_SkillCache[victim].m_iSmokerVictimDamage >= g_hCvar_SelfClearThresh.IntValue)
				{
					HandleSmokerSelfClear(attacker, victim);
				}
				else
				{
					g_SkillCache[victim].m_bSmokerClearCheck = false;
					g_SkillCache[victim].m_iSmokerVictim	 = 0;
				}
			}

			case ZC_JOCKEY:
			{
				// check whether it was a clear
				if (g_SISkillCache[victim].m_iSpecialVictim > 0)
					HandleClear(attacker, victim, g_SISkillCache[victim].m_iSpecialVictim, ZC_JOCKEY, (GetGameTime() - g_SISkillCache[victim].m_flPinTime[0]), -1.0);
			}

			case ZC_CHARGER:
			{
				// is it someone carrying a survivor (that might be DC'd)?
				// switch charge victim to 'impact' check (reset checktime)
				if (IsValidClientInGame(g_SkillCache[victim].m_iChargeVictim))
					g_SkillCache[g_SkillCache[victim].m_iChargeVictim].m_flChargeTime = GetGameTime();

				// check whether it was a clear
				if (g_SISkillCache[victim].m_iSpecialVictim > 0)
					HandleClear(attacker, victim, g_SISkillCache[victim].m_iSpecialVictim, ZC_CHARGER, (g_SISkillCache[victim].m_flPinTime[1] > 0.0) ? (GetGameTime() - g_SISkillCache[victim].m_flPinTime[1]) : -1.0, (GetGameTime() - g_SISkillCache[victim].m_flPinTime[0]));
			}
		}
	}
	else if (IsValidSurvivor(victim))
	{
		// check for deathcharges
		// new atkent = hEvent.GetInt("attackerentid");
		int dmgtype = event.GetInt("type");

		// PrintDebug("Died [%N]: attk: %i / %i - dmgtype: %i", victim, attacker, atkent, dmgtype );

		if (dmgtype & DMG_FALL)
		{
			g_SkillCache[victim].m_iVictimFlags = g_SkillCache[victim].m_iVictimFlags | VICFLG_FALL;
		}
		else if (IsValidInfected(attacker) && attacker != g_SkillCache[victim].m_iVictimCharger)
		{
			// if something other than the charger killed them, remember (not a DC)
			g_SkillCache[victim].m_iVictimFlags = g_SkillCache[victim].m_iVictimFlags | VICFLG_KILLEDBYOTHER;
		}
	}
}

static void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	PrintDebug("Shove from %i on %i", attacker, victim);

	if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
		return;

	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	PrintDebug(" --> Shove from %N on %N (class: %i) -- (last shove time: %.2f / %.2f)", attacker, victim, zClass, g_SkillCache[victim].m_flVictimLastShove[attacker], (GetGameTime() - g_SkillCache[victim].m_flVictimLastShove[attacker]));

	// track on boomers
	if (zClass == ZC_BOOMER)
	{
		g_SkillCache[victim].m_iBoomerGotShoved++;
	}
	else
	{
		// check for clears
		switch (zClass)
		{
			case ZC_HUNTER:
			{
				if (GetEntPropEnt(victim, Prop_Send, "m_pounceVictim") > 0)
					HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_pounceVictim"), ZC_HUNTER, (GetGameTime() - g_SISkillCache[victim].m_flPinTime[0]), -1.0, true);
			}
			case ZC_JOCKEY:
			{
				if (GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim") > 0)
					HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim"), ZC_JOCKEY, (GetGameTime() - g_SISkillCache[victim].m_flPinTime[0]), -1.0, true);
			}
		}
	}

	if (g_SkillCache[victim].m_flVictimLastShove[attacker] == 0.0 || (GetGameTime() - g_SkillCache[victim].m_flVictimLastShove[attacker]) >= SHOVE_TIME)
	{
		if (GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
			HandleDeadstop(attacker, victim);

		HandleShove(attacker, victim, zClass);
		g_SkillCache[victim].m_flVictimLastShove[attacker] = GetGameTime();
	}

	// check for shove on smoker by pull victim
	if (g_SkillCache[victim].m_iSmokerVictim == attacker)
		g_SkillCache[victim].m_bSmokerShoved = true;

	PrintDebug("shove by %i on %i", attacker, victim);
}

static void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	int client							  = GetClientOfUserId(event.GetInt("userid"));
	int victim							  = GetClientOfUserId(event.GetInt("victim"));

	g_SISkillCache[client].m_flPinTime[0] = GetGameTime();

	// clear hunter-hit stats (not skeeted)
	ResetHunter(client);

	// check if it was a DP
	// ignore if no real pounce start pos
	if (g_SkillCache[client].m_flPouncePosition[0] == 0.0
		&& g_SkillCache[client].m_flPouncePosition[1] == 0.0
		&& g_SkillCache[client].m_flPouncePosition[2] == 0.0)
	{
		return;
	}

	float endPos[3];
	GetClientAbsOrigin(client, endPos);
	float fHeight  = g_SkillCache[client].m_flPouncePosition[2] - endPos[2];

	// from pounceannounce:
	// distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
	// http://forums.alliedmods.net/showthread.php?t=93207

	float fMin	   = g_hCvar_MinPounceDistance.FloatValue;
	float fMax	   = g_hCvar_MaxPounceDistance.FloatValue;
	float fMaxDmg  = g_hCvar_MaxPounceDamage.FloatValue;

	// calculate 2d distance between previous position and pounce position
	int	  distance = RoundToNearest(GetVectorDistance(g_SkillCache[client].m_flPouncePosition, endPos));

	// get damage using hunter damage formula
	// check if this is accurate, seems to differ from actual damage done!
	float fDamage  = (((float(distance) - fMin) / (fMax - fMin)) * fMaxDmg) + 1.0;

	// apply bounds
	if (fDamage < 0.0)
	{
		fDamage = 0.0;
	}
	else if (fDamage > fMaxDmg + 1.0)
	{
		fDamage = fMaxDmg + 1.0;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(victim);
	pack.WriteFloat(fDamage);
	pack.WriteFloat(fHeight);
	CreateTimer(0.05, Timer_HunterDP, pack);
}

static void Timer_HunterDP(Handle timer, DataPack pack)
{
	pack.Reset();
	int	  client  = pack.ReadCell();
	int	  victim  = pack.ReadCell();
	float fDamage = pack.ReadFloat();
	float fHeight = pack.ReadFloat();
	delete pack;

	HandleHunterDP(client, victim, g_SkillCache[client].m_iPounceDamage, fDamage, fHeight);
}

static void Event_PlayerJumped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidInfected(client))
	{
		int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zClass != ZC_JOCKEY)
			return;

		// where did jockey jump from?
		GetClientAbsOrigin(client, g_SkillCache[client].m_flPouncePosition);
	}
	else if (IsValidSurvivor(client))
	{
		// could be the start or part of a hopping streak

		float fPos[3];
		float fVel[3];
		GetClientAbsOrigin(client, fPos);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2] = 0.0;	  // safeguard

		float fLengthNew;
		float fLengthOld;
		fLengthNew						 = GetVectorLength(fVel);

		g_SkillCache[client].m_bHopCheck = false;

		if (!g_SkillCache[client].m_bIsHopping)
		{
			if (fLengthNew >= g_hCvar_BHopMinInitSpeed.FloatValue)
			{
				// starting potential hop streak
				g_SkillCache[client].m_flHopTopVelocity = fLengthNew;
				g_SkillCache[client].m_bIsHopping		= true;
				g_SkillCache[client].m_iHops			= 0;
			}
		}
		else
		{
			// check for hopping streak
			fLengthOld = GetVectorLength(g_SkillCache[client].m_flLastHop);

			// if they picked up speed, count it as a hop, otherwise, we're done hopping
			if (fLengthNew - fLengthOld > HOP_ACCEL_THRESH || fLengthNew >= g_hCvar_BHopContSpeed.FloatValue)
			{
				g_SkillCache[client].m_iHops++;

				// this should always be the case...
				if (fLengthNew > g_SkillCache[client].m_flHopTopVelocity)
					g_SkillCache[client].m_flHopTopVelocity = fLengthNew;

				// PrintToChat( client, "bunnyhop %i: speed: %.1f / increase: %.1f", g_SkillCache[client].m_iHops, fLengthNew, fLengthNew - fLengthOld );
			}
			else
			{
				g_SkillCache[client].m_bIsHopping = false;

				if (g_SkillCache[client].m_iHops)
				{
					HandleBHopStreak(client, g_SkillCache[client].m_iHops, g_SkillCache[client].m_flHopTopVelocity);
					g_SkillCache[client].m_iHops = 0;
				}
			}
		}

		g_SkillCache[client].m_flLastHop[0] = fVel[0];
		g_SkillCache[client].m_flLastHop[1] = fVel[1];
		g_SkillCache[client].m_flLastHop[2] = fVel[2];

		if (g_SkillCache[client].m_iHops != 0)
		{
			// check when the player returns to the ground
			CreateTimer(HOP_CHECK_TIME, Timer_CheckHop, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

// player back to ground = end of hop (streak)?
static void Timer_CheckHop(Handle timer, int client)
{
	// streak stopped by dying / teamswitch / disconnect?
	if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
		return;

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		float fVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2]							 = 0.0;	   // safeguard

		// PrintToChatAll("grounded %i: vel length: %.1f", client, GetVectorLength(fVel) );
		g_SkillCache[client].m_bHopCheck = true;
		CreateTimer(HOPEND_CHECK_TIME, Timer_CheckHopStreak, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void Timer_CheckHopStreak(Handle timer, int client)
{
	if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
		return;

	// check if we have any sort of hop streak, and report
	if (g_SkillCache[client].m_bHopCheck && g_SkillCache[client].m_iHops)
	{
		HandleBHopStreak(client, g_SkillCache[client].m_iHops, g_SkillCache[client].m_flHopTopVelocity);
		g_SkillCache[client].m_bIsHopping		= false;
		g_SkillCache[client].m_iHops			= 0;
		g_SkillCache[client].m_flHopTopVelocity = 0.0;
	}

	g_SkillCache[client].m_bHopCheck = false;
}

static void Event_PlayerJumpApex(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_SkillCache[client].m_bIsHopping)
	{
		float fVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2]		  = 0.0;
		float fLength = GetVectorLength(fVel);

		if (fLength > g_SkillCache[client].m_flHopTopVelocity)
		{
			g_SkillCache[client].m_flHopTopVelocity = fLength;
		}
	}
}

static void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!IsValidInfected(client) || !IsValidSurvivor(victim))
		return;

	g_SISkillCache[client].m_flPinTime[0] = GetGameTime();

	// minimum distance travelled?
	// ignore if no real pounce start pos
	if (g_SkillCache[client].m_flPouncePosition[0] == 0.0 && g_SkillCache[client].m_flPouncePosition[1] == 0.0 && g_SkillCache[client].m_flPouncePosition[2] == 0.0)
		return;

	float endPos[3];
	GetClientAbsOrigin(client, endPos);
	float fHeight = g_SkillCache[client].m_flPouncePosition[2] - endPos[2];

	// (high) pounce
	HandleJockeyDP(client, victim, fHeight);
}

static void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	// track hunters pouncing
	int	 client = GetClientOfUserId(event.GetInt("userid"));
	char abilityName[64];
	event.GetString("ability", abilityName, sizeof(abilityName));

	if (!IsValidClientInGame(client))
		return;

	strAbility ability;
	if (!g_hMapAbility.GetValue(abilityName, ability))
		return;

	switch (ability)
	{
		case ABL_HUNTERLUNGE:
		{
			// hunter started a pounce
			ResetHunter(client);
			GetClientAbsOrigin(client, g_SkillCache[client].m_flPouncePosition);
		}
	}
}

// charger carrying
static void Event_ChargeCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!IsValidInfected(client))
		return;

	PrintDebug("Charge carry start: %i - %i -- time: %.2f", client, victim, GetGameTime());

	g_SkillCache[client].m_flChargeTime	  = GetGameTime();
	g_SISkillCache[client].m_flPinTime[0] = g_SkillCache[client].m_flChargeTime;
	g_SISkillCache[client].m_flPinTime[1] = 0.0;

	if (!IsValidSurvivor(victim))
		return;

	g_SkillCache[client].m_iChargeVictim  = victim;			   // store who we're carrying (as long as this is set, it's not considered an impact charge flight)
	g_SkillCache[victim].m_iVictimCharger = client;			   // store who's charging whom
	g_SkillCache[victim].m_iVictimFlags	  = VICFLG_CARRIED;	   // reset flags for checking later - we know only this now
	g_SkillCache[victim].m_flChargeTime	  = g_SkillCache[client].m_flChargeTime;
	g_SkillCache[victim].m_iVictimMapDmg  = 0;

	GetClientAbsOrigin(victim, g_SkillCache[victim].m_flChargeVictimPos);

	// CreateTimer( CHARGE_CHECK_TIME, Timer_ChargeCheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

static void Event_ChargeImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!IsValidInfected(client) || !IsValidSurvivor(victim))
		return;

	// remember how many people the charger bumped into, and who, and where they were
	GetClientAbsOrigin(victim, g_SkillCache[victim].m_flChargeVictimPos);

	g_SkillCache[victim].m_iVictimCharger = client;			  // store who we've bumped up
	g_SkillCache[victim].m_iVictimFlags	  = 0;				  // reset flags for checking later
	g_SkillCache[victim].m_flChargeTime	  = GetGameTime();	  // store time per victim, for impacts
	g_SkillCache[victim].m_iVictimMapDmg  = 0;

	CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

static void Event_ChargePummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidInfected(client))
		return;

	g_SISkillCache[client].m_flPinTime[1] = GetGameTime();
}

static void Event_ChargeCarryEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client < 1 || client > MaxClients)
		return;

	g_SISkillCache[client].m_flPinTime[1] = GetGameTime();

	// delay so we can check whether charger died 'mid carry'
	CreateTimer(0.1, Timer_ChargeCarryEnd, client, TIMER_FLAG_NO_MAPCHANGE);
}

static void Timer_ChargeCarryEnd(Handle timer, int client)
{
	// set charge time to 0 to avoid deathcharge timer continuing
	g_SkillCache[client].m_iChargeVictim = 0;	 // unset this so the repeated timer knows to stop for an ongroundcheck
}

static void Timer_ChargeCheck(Handle timer, int client)
{
	static float flTime = 0.0;
	if (GetGameTime() - flTime < 1.0)
		return;

	flTime = GetGameTime();

	// if something went wrong with the survivor or it was too long ago, forget about it
	if (!IsValidSurvivor(client) || !g_SkillCache[client].m_iVictimCharger || g_SkillCache[client].m_flChargeTime == 0.0 || (GetGameTime() - g_SkillCache[client].m_flChargeTime) > MAX_CHARGE_TIME)
		return;

	// we're done checking if either the victim reached the ground, or died
	if (!IsPlayerAlive(client))
	{
		// player died (this was .. probably.. a death charge)
		g_SkillCache[client].m_iVictimFlags = g_SkillCache[client].m_iVictimFlags | VICFLG_AIRDEATH;

		// check conditions now
		CreateTimer(0.0, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (GetEntityFlags(client) & FL_ONGROUND && g_SkillCache[g_SkillCache[client].m_iVictimCharger].m_iChargeVictim != client)
	{
		// survivor reached the ground and didn't die (yet)
		// the client-check condition checks whether the survivor is still being carried by the charger
		//      (in which case it doesn't matter that they're on the ground)

		// check conditions with small delay (to see if they still die soon)
		CreateTimer(CHARGE_END_CHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void Timer_DeathChargeCheck(Handle timer, int client)
{
	if (!IsValidClientInGame(client))
		return;

	// check conditions.. if flags match up, it's a DC
	PrintDebug("Checking charge victim: %i - %i - flags: %i (alive? %i)", g_SkillCache[client].m_iVictimCharger, client, g_SkillCache[client].m_iVictimFlags, IsPlayerAlive(client));

	int flags = g_SkillCache[client].m_iVictimFlags;

	if (!IsPlayerAlive(client))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		float fHeight = g_SkillCache[client].m_flChargeVictimPos[2] - pos[2];

		/*
			it's a deathcharge when:
				the survivor is dead AND
					they drowned/fell AND took enough damage or died in mid-air
					AND not killed by someone else
					OR is in an unreachable spot AND dropped at least X height
					OR took plenty of map damage

			old.. need?
				fHeight > g_hCvar_DeathChargeHeight.FloatValue
		*/
		if (((flags & VICFLG_DROWN || flags & VICFLG_FALL) && (flags & VICFLG_HURTLOTS || flags & VICFLG_AIRDEATH) || (flags & VICFLG_WEIRDFLOW && fHeight >= MIN_FLOWDROPHEIGHT) || g_SkillCache[client].m_iVictimMapDmg >= MIN_DC_TRIGGER_DMG) && !(flags & VICFLG_KILLEDBYOTHER))
			HandleDeathCharge(g_SkillCache[client].m_iVictimCharger, client, fHeight, GetVectorDistance(g_SkillCache[client].m_flChargeVictimPos, pos, false), view_as<bool>(flags & VICFLG_CARRIED));
	}
	else if ((flags & VICFLG_WEIRDFLOW || g_SkillCache[client].m_iVictimMapDmg >= MIN_DC_RECHECK_DMG) && !(flags & VICFLG_WEIRDFLOWDONE))
	{
		// could be incapped and dying more slowly
		// flag only gets set on preincap, so don't need to check for incap
		g_SkillCache[client].m_iVictimFlags = g_SkillCache[client].m_iVictimFlags | VICFLG_WEIRDFLOWDONE;

		CreateTimer(CHARGE_END_RECHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void ResetHunter(int client)
{
	g_SkillCache[client].m_iHunterShotDmgTeam = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_SkillCache[client].m_iHunterShotDmg[i]	= 0;
		g_SkillCache[client].m_flHunterShotStart[i] = 0.0;
	}

	g_SkillCache[client].m_iHunterOverkill = 0;
}

// entity creation
void _skill_detect_tracking_OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1 || !IsValidEntity(entity) || !IsValidEdict(entity))
		return;
	// track infected / witches, so damage on them counts as hits

	strOEC classnameOEC;
	if (!g_hMapEntityCreated.GetValue(classname, classnameOEC))
		return;

	switch (classnameOEC)
	{
		case OEC_TANKROCK:
		{
			TankRockTrace_t rockTrace;
			rockTrace.m_iRock = entity;
			rockTrace.m_iThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");	// CTankRock < CBaseGrenade.
			g_hArray_TankRockTrace.PushArray(rockTrace, sizeof(rockTrace));

			SDKHook(entity, SDKHook_TraceAttackPost, TraceAttackPost_Rock);
			SDKHook(entity, SDKHook_TouchPost, OnTouchPost_Rock);
		}

		case OEC_CARALARM:
		{
			char car_key[10];
			FormatEx(car_key, sizeof(car_key), "%x", entity);

			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Car);
			SDKHook(entity, SDKHook_Touch, OnTouch_Car);

			SDKHook(entity, SDKHook_Spawn, OnEntitySpawned_CarAlarm);
		}

		case OEC_CARGLASS:
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKHook(entity, SDKHook_Touch, OnTouch_CarGlass);

			// g_hCarMap.SetValue(car_key, );
			SDKHook(entity, SDKHook_Spawn, OnEntitySpawned_CarAlarmGlass);
		}
	}
}

static Action OnEntitySpawned_CarAlarm(int entity)
{
	if (!IsValidEntity(entity))
		return Plugin_Continue;

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);

	char target[48];
	GetEntPropString(entity, Prop_Data, "m_iName", target, sizeof(target));

	g_hCarMap.SetValue(target, entity);
	g_hCarMap.SetValue(car_key, 0);	   // who shot the car?
	HookSingleEntityOutput(entity, "OnCarAlarmStart", Hook_CarAlarmStart);

	return Plugin_Continue;
}

static Action OnEntitySpawned_CarAlarmGlass(int entity)
{
	if (!IsValidEntity(entity))
		return Plugin_Continue;

	// glass is parented to a car, link the two through the Map
	// find parent and save both
	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);

	char parent[48];
	GetEntPropString(entity, Prop_Data, "m_iParent", parent, sizeof(parent));
	int parentEntity;

	// find targetname in Map
	if (g_hCarMap.GetValue(parent, parentEntity))
	{
		// if valid entity, save the parent entity
		if (IsValidEntity(parentEntity))
		{
			g_hCarMap.SetValue(car_key, parentEntity);

			char car_key_p[10];
			FormatEx(car_key_p, sizeof(car_key_p), "%x_A", parentEntity);
			int testEntity;

			if (g_hCarMap.GetValue(car_key_p, testEntity))
			{
				// second glass
				FormatEx(car_key_p, sizeof(car_key_p), "%x_B", parentEntity);
			}

			g_hCarMap.SetValue(car_key_p, entity);
		}
	}

	return Plugin_Continue;
}

// entity destruction
void _skill_detect_tracking_OnEntityDestroyed(int entity)
{
	int index = g_hArray_TankRockTrace.FindValue(entity, TankRockTrace_t::m_iRock);
	if (index != -1)
	{
		CreateTimer(ROCK_CHECK_TIME, Timer_CheckRockSkeet, index);
		SDKUnhook(entity, SDKHook_TraceAttack, TraceAttackPost_Rock);
		return;
	}

	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", entity);

	int witch_array[L4D2_MAXPLAYERS + DMGARRAYEXT];
	if (g_hWitchMap.GetArray(witch_key, witch_array, sizeof(witch_array)))
	{
		// witch
		//  delayed deletion, to avoid potential problems with crowns not detecting
		CreateTimer(WITCH_DELETE_TIME, Timer_WitchKeyDelete, entity);
		SDKUnhook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);
		return;
	}
}

static void Timer_WitchKeyDelete(Handle timer, any witch)
{
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	g_hWitchMap.Remove(witch_key);
}

static void Timer_CheckRockSkeet(Handle timer, any index)
{
	TankRockTrace_t rockTrace;
	g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace))
	g_hArray_TankRockTrace.Erase(index);

	if (rockTrace.m_iDamageTaken > 0)
		HandleRockSkeeted(rockTrace.m_iSkeeter, rockTrace.m_iThrower);
}

// boomer got somebody
static void Event_PlayerBoomed(Event event, const char[] name, bool dontBroadcast)
{
	int	 attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool byBoom	  = event.GetBool("by_boomer");

	if (byBoom && IsValidInfected(attacker))
	{
		g_SkillCache[attacker].m_bBoomerHitSomebody = true;

		// check if it was vomit spray
		bool byExplosion							= event.GetBool("exploded");
		if (!byExplosion)
		{
			// count amount of booms
			if (!g_SkillCache[attacker].m_iBoomerVomitHits)
			{
				// check for boom count later
				CreateTimer(VOMIT_DURATION_TIME, Timer_BoomVomitCheck, attacker, TIMER_FLAG_NO_MAPCHANGE);
			}

			g_SkillCache[attacker].m_iBoomerVomitHits++;
		}
	}
}

// check how many booms landed
static void Timer_BoomVomitCheck(Handle timer, int client)
{
	HandleVomitLanded(client, g_SkillCache[client].m_iBoomerVomitHits);
	g_SkillCache[client].m_iBoomerVomitHits = 0;
}

// boomers that didn't bile anyone
static void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
	int	 client = GetClientOfUserId(event.GetInt("userid"));
	bool biled	= event.GetBool("splashedbile");
	if (!biled && !g_SkillCache[client].m_bBoomerHitSomebody)
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidSurvivor(attacker))
			HandlePop(attacker, client, g_SkillCache[client].m_iBoomerGotShoved, (GetGameTime() - g_SISkillCache[client].m_flSpawnTime));
	}
}

// crown tracking
static void Event_WitchSpawned(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");

	SDKHook(witch, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);

	int	 witch_dmg_array[L4D2_MAXPLAYERS + DMGARRAYEXT];
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);

	witch_dmg_array[L4D2_MAXPLAYERS + WTCH_HEALTH] = g_hCvar_WitchHealth.IntValue;
	g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, false);
}

static void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int witch	 = event.GetInt("witchid");
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(witch, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);

	if (!IsValidSurvivor(attacker))
		return;

	bool	 bOneShot = event.GetBool("oneshot");

	// is it a crown / drawcrown?
	DataPack pack	  = new DataPack();
	pack.WriteCell(attacker);
	pack.WriteCell(witch);
	pack.WriteCell((bOneShot) ? 1 : 0);
	CreateTimer(WITCH_CHECK_TIME, Timer_CheckWitchCrown, pack);
}

static void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
	int	 witch = event.GetInt("witchid");

	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	int witch_dmg_array[L4D2_MAXPLAYERS + DMGARRAYEXT];

	if (!g_hWitchMap.GetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT))
	{
		for (int i = 0; i <= L4D2_MAXPLAYERS; i++)
			witch_dmg_array[i] = 0;

		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_HEALTH]	 = g_hCvar_WitchHealth.IntValue;
		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_STARTLED] = 1;	 // harasser set
		g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, false);
	}
	else
	{
		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_STARTLED] = 1;	 // harasser set
		g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, true);
	}
}

static Action OnTakeDamageByWitch(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	// if a survivor is hit by a witch, note it in the witch damage array (L4D2_MAXPLAYERS+2 = 1)
	if (IsValidSurvivor(victim) && damage > 0.0)
	{
		// not a crown if witch hit anyone for > 0 damage
		if (IsWitch(attacker))
		{
			char witch_key[10];
			FormatEx(witch_key, sizeof(witch_key), "%x", attacker);
			int witch_dmg_array[L4D2_MAXPLAYERS + DMGARRAYEXT];

			if (!g_hWitchMap.GetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT))
			{
				for (int i = 0; i <= L4D2_MAXPLAYERS; i++)
					witch_dmg_array[i] = 0;

				witch_dmg_array[L4D2_MAXPLAYERS + WTCH_HEALTH]	 = g_hCvar_WitchHealth.IntValue;
				witch_dmg_array[L4D2_MAXPLAYERS + WTCH_GOTSLASH] = 1;	 // failed
				g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, false);
			}
			else
			{
				witch_dmg_array[L4D2_MAXPLAYERS + WTCH_GOTSLASH] = 1;	 // failed
				g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, true);
			}
		}
	}

	return Plugin_Continue;
}

static void OnTakeDamagePost_Witch(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	// only called for witches, so no check required

	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", victim);
	int witch_dmg_array[L4D2_MAXPLAYERS + DMGARRAYEXT];

	if (!g_hWitchMap.GetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT))
	{
		for (int i = 0; i <= L4D2_MAXPLAYERS; i++)
			witch_dmg_array[i] = 0;

		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_HEALTH] = g_hCvar_WitchHealth.IntValue;
		g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, false);
	}

	// store damage done to witch
	if (IsValidSurvivor(attacker))
	{
		witch_dmg_array[attacker] += RoundToFloor(damage);
		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_HEALTH] -= RoundToFloor(damage);

		// remember last shot
		if (g_SkillCache[attacker].m_flWitchShotStart == 0.0 || (GetGameTime() - g_SkillCache[attacker].m_flWitchShotStart) > SHOTGUN_BLAST_TIME)
		{
			// reset last shot damage count and attacker
			g_SkillCache[attacker].m_flWitchShotStart		  = GetGameTime();
			witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNER]	  = attacker;
			witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] = 0;
			witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNTYPE] = (damagetype & DMG_BUCKSHOT) ? 1 : 0;	// only allow shotguns
		}

		// continued blast, add up
		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] += RoundToFloor(damage);
		g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, true);
	}
	else
	{
		// store all chip from other sources than survivor in [0]
		witch_dmg_array[0] += RoundToFloor(damage);
		// witch_dmg_array[L4D2_MAXPLAYERS+1] -= RoundToFloor(damage);
		g_hWitchMap.SetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT, true);
	}
}

static void Timer_CheckWitchCrown(Handle timer, DataPack pack)
{
	pack.Reset();
	int	 attacker = pack.ReadCell();
	int	 witch	  = pack.ReadCell();
	bool bOneShot = view_as<bool>(pack.ReadCell());
	delete pack;

	CheckWitchCrown(witch, attacker, bOneShot);
}

static void CheckWitchCrown(int witch, int attacker, bool bOneShot = false)
{
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	int witch_dmg_array[L4D2_MAXPLAYERS + DMGARRAYEXT];
	if (!g_hWitchMap.GetArray(witch_key, witch_dmg_array, L4D2_MAXPLAYERS + DMGARRAYEXT))
	{
		PrintDebug("Witch Crown Check: Error: Map entry missing (entity: %i, oneshot: %i)", witch, bOneShot);
		return;
	}

	int chipDamage	 = 0;
	int iWitchHealth = g_hCvar_WitchHealth.IntValue;

	if (bOneShot)
		witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNTYPE] = 1;

	if (witch_dmg_array[L4D2_MAXPLAYERS + WTCH_GOTSLASH] || !witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNTYPE])
	{
		PrintDebug("Witch Crown Check: Failed: bungled: %i / crowntype: %i (entity: %i)",
				   witch_dmg_array[L4D2_MAXPLAYERS + WTCH_GOTSLASH],
				   witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNTYPE],
				   witch);
		PrintDebug("Witch Crown Check: Further details: attacker: %N, attacker dmg: %i, teamless dmg: %i",
				   attacker,
				   witch_dmg_array[attacker],
				   witch_dmg_array[0]);
		return;
	}

	PrintDebug("Witch Crown Check: crown shot: %i, harrassed: %i (full health: %i / drawthresh: %i / oneshot %i)",
			   witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT],
			   witch_dmg_array[L4D2_MAXPLAYERS + WTCH_STARTLED],
			   iWitchHealth,
			   g_hCvar_DrawCrownThresh.IntValue,
			   bOneShot);

	// full crown? unharrassed
	if (!witch_dmg_array[L4D2_MAXPLAYERS + WTCH_STARTLED] && (bOneShot || witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] >= iWitchHealth))
	{
		// make sure that we don't count any type of chip
		if (g_hCvar_HideFakeDamage.BoolValue)
		{
			chipDamage = 0;
			for (int i = 0; i <= L4D2_MAXPLAYERS; i++)
			{
				if (i == attacker) { continue; }
				chipDamage += witch_dmg_array[i];
			}

			witch_dmg_array[attacker] = iWitchHealth - chipDamage;
		}

		HandleCrown(attacker, witch_dmg_array[attacker]);
	}
	else if (witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] >= g_hCvar_DrawCrownThresh.IntValue)
	{
		// draw crown: harassed + over X damage done by one survivor -- in ONE shot

		for (int i = 0; i <= L4D2_MAXPLAYERS; i++)
		{
			if (i == attacker)
			{
				// count any damage done before final shot as chip
				chipDamage += witch_dmg_array[i] - witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT];
			}
			else
			{
				chipDamage += witch_dmg_array[i];
			}
		}

		// make sure that we don't count any type of chip
		if (g_hCvar_HideFakeDamage.BoolValue)
		{
			// unlikely to happen, but if the chip was A LOT
			if (chipDamage >= iWitchHealth)
			{
				chipDamage										  = iWitchHealth - 1;
				witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] = 1;
			}
			else
			{
				witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] = iWitchHealth - chipDamage;
			}

			// re-check whether it qualifies as a drawcrown:
			if (witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT] < g_hCvar_DrawCrownThresh.IntValue)
				return;
		}

		// plus, set final shot as 'damage', and the rest as chip
		HandleDrawCrown(attacker, witch_dmg_array[L4D2_MAXPLAYERS + WTCH_CROWNSHOT], chipDamage);
	}

	// remove Map
}

// tank rock
static void TraceAttackPost_Rock(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
	if (IsValidSurvivor(attacker))
	{
		int index = g_hArray_TankRockTrace.FindValue(victim, TankRockTrace_t::m_iRock);
		if (index != -1)
		{
			TankRockTrace_t rockTrace;
			g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace));
			rockTrace.m_iDamageTaken = RoundToFloor(damage);
			rockTrace.m_iSkeeter = attacker;
			g_hArray_TankRockTrace.SetArray(index, rockTrace, sizeof(rockTrace));
		}
	}
}

static void OnTouchPost_Rock(int entity, int other)
{
	int index = g_hArray_TankRockTrace.FindValue(entity, TankRockTrace_t::m_iRock);
	if (index != -1)
	{
		TankRockTrace_t rockTrace;
		g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace));
		rockTrace.m_iDamageTaken = -1;
		g_hArray_TankRockTrace.SetArray(index, rockTrace, sizeof(rockTrace));

		SDKUnhook(entity, SDKHook_TouchPost, OnTouchPost_Rock);
	}
}

// smoker tongue cutting & self clears
static void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim	 = GetClientOfUserId(event.GetInt("victim"));
	int smoker	 = GetClientOfUserId(event.GetInt("smoker"));
	int reason	 = event.GetInt("release_type");

	if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
		return;

	// clear check -  if the smoker itself was not shoved, handle the clear
	HandleClear(attacker, smoker, victim,
				ZC_SMOKER,
				(g_SISkillCache[smoker].m_flPinTime[1] > 0.0) ? (GetGameTime() - g_SISkillCache[smoker].m_flPinTime[1]) : -1.0,
				(GetGameTime() - g_SISkillCache[smoker].m_flPinTime[0]),
				view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));

	if (attacker != victim)
		return;

	if (reason == CUT_KILL)
	{
		g_SkillCache[smoker].m_bSmokerClearCheck = true;
	}
	else if (g_SkillCache[smoker].m_bSmokerShoved)
	{
		HandleSmokerSelfClear(attacker, smoker, true);
	}
	else if (reason == CUT_SLASH)	 // note: can't trust this to actually BE a slash..
	{
		// check weapon
		char weapon[32];
		GetClientWeapon(attacker, weapon, 32);

		// this doesn't count the chainsaw, but that's no-skill anyway
		if (StrEqual(weapon, "weapon_melee", false))
			HandleTongueCut(attacker, smoker);
	}
}

static void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim	 = GetClientOfUserId(event.GetInt("victim"));

	if (IsValidInfected(attacker) && IsValidSurvivor(victim))
	{
		// new pull, clean damage
		g_SkillCache[attacker].m_bSmokerClearCheck	 = false;
		g_SkillCache[attacker].m_bSmokerShoved		 = false;
		g_SkillCache[attacker].m_iSmokerVictim		 = victim;
		g_SkillCache[attacker].m_iSmokerVictimDamage = 0;
		g_SISkillCache[attacker].m_flPinTime[0]		 = GetGameTime();
		g_SISkillCache[attacker].m_flPinTime[1]		 = 0.0;
	}
}

static void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));

	if (g_SISkillCache[attacker].m_flPinTime[0] == 0.0)
		g_SISkillCache[attacker].m_flPinTime[0] = GetGameTime();

	g_SISkillCache[attacker].m_flPinTime[1] = GetGameTime();
}

static void Event_ChokeStop(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim	 = GetClientOfUserId(event.GetInt("victim"));
	int smoker	 = GetClientOfUserId(event.GetInt("smoker"));
	int reason	 = event.GetInt("release_type");

	if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
		return;

	// if the smoker itself was not shoved, handle the clear
	HandleClear(attacker, smoker, victim,
				ZC_SMOKER,
				(g_SISkillCache[smoker].m_flPinTime[1] > 0.0) ? (GetGameTime() - g_SISkillCache[smoker].m_flPinTime[1]) : -1.0,
				(GetGameTime() - g_SISkillCache[smoker].m_flPinTime[0]),
				view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));
}

// car alarm handling
static void Hook_CarAlarmStart(const char[] output, int caller, int activator, float delay)
{
	// char car_key[10];
	// FormatEx(car_key, sizeof(car_key), "%x", entity);

	PrintDebug("calarm trigger: caller %i / activator %i / delay: %.2f", caller, activator, delay);
}

static void Event_CarAlarmGoesOff(Event event, const char[] name, bool dontBroadcast)
{
	g_fLastCarAlarm = GetGameTime();
}

static Action OnTakeDamage_Car(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (!IsValidSurvivor(attacker))
		return Plugin_Continue;
	/*
		boomer popped on alarmed car =
			DMG_BLAST_SURFACE| DMG_BLAST
		and inflictor is the boomer

		melee slash/club =
			DMG_SLOWBURN|DMG_PREVENT_PHYSICS_FORCE + DMG_CLUB or DMG_SLASH
		shove is without DMG_SLOWBURN
	*/

	CreateTimer(0.01, Timer_CheckAlarm, victim, TIMER_FLAG_NO_MAPCHANGE);

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", victim);
	g_hCarMap.SetValue(car_key, attacker);

	if (damagetype & DMG_BLAST)
	{
		if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
		{
			g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_BOOMER;
			g_iLastCarAlarmBoomer						 = inflictor;
		}
		else
		{
			g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_EXPLOSION;
		}
	}
	else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
	{
		g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_TOUCHED;
	}
	else
	{
		g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_HIT;
	}

	return Plugin_Continue;
}

static Action OnTouch_Car(int entity, int client)
{
	if (!IsValidSurvivor(client))
		return Plugin_Continue;

	CreateTimer(0.01, Timer_CheckAlarm, entity, TIMER_FLAG_NO_MAPCHANGE);

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);
	g_hCarMap.SetValue(car_key, client);

	g_SkillCache[client].m_iLastCarAlarmReason = CALARM_TOUCHED;
	return Plugin_Continue;
}

static Action OnTakeDamage_CarGlass(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	// check for either: boomer pop or survivor
	if (!IsValidSurvivor(attacker))
		return Plugin_Continue;

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", victim);
	int parentEntity;

	if (g_hCarMap.GetValue(car_key, parentEntity))
	{
		CreateTimer(0.01, Timer_CheckAlarm, parentEntity, TIMER_FLAG_NO_MAPCHANGE);

		FormatEx(car_key, sizeof(car_key), "%x", parentEntity);
		g_hCarMap.SetValue(car_key, attacker);

		if (damagetype & DMG_BLAST)
		{
			if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
			{
				g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_BOOMER;
				g_iLastCarAlarmBoomer						 = inflictor;
			}
			else
			{
				g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_EXPLOSION;
			}
		}
		else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
		{
			g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_TOUCHED;
		}
		else
		{
			g_SkillCache[attacker].m_iLastCarAlarmReason = CALARM_HIT;
		}
	}

	return Plugin_Continue;
}

static Action OnTouch_CarGlass(int entity, int client)
{
	if (!IsValidSurvivor(client))
		return Plugin_Continue;

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);
	int parentEntity;

	if (g_hCarMap.GetValue(car_key, parentEntity))
	{
		CreateTimer(0.01, Timer_CheckAlarm, parentEntity, TIMER_FLAG_NO_MAPCHANGE);

		FormatEx(car_key, sizeof(car_key), "%x", parentEntity);
		g_hCarMap.SetValue(car_key, client);

		g_SkillCache[client].m_iLastCarAlarmReason = CALARM_TOUCHED;
	}

	return Plugin_Continue;
}

static void Timer_CheckAlarm(Handle timer, any entity)
{
	// PrintToChatAll( "checking alarm: time: %.3f", GetGameTime() - g_fLastCarAlarm );

	if ((GetGameTime() - g_fLastCarAlarm) < CARALARM_MIN_TIME)
	{
		// got a match, drop stuff from Map and handle triggering
		char car_key[10];
		int	 testEntity;
		int	 survivor = -1;

		// remove car glass
		FormatEx(car_key, sizeof(car_key), "%x_A", entity);
		if (g_hCarMap.GetValue(car_key, testEntity))
		{
			g_hCarMap.Remove(car_key);
			SDKUnhook(testEntity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKUnhook(testEntity, SDKHook_Touch, OnTouch_CarGlass);
		}

		FormatEx(car_key, sizeof(car_key), "%x_B", entity);
		if (g_hCarMap.GetValue(car_key, testEntity))
		{
			g_hCarMap.Remove(car_key);
			SDKUnhook(testEntity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKUnhook(testEntity, SDKHook_Touch, OnTouch_CarGlass);
		}

		// remove car
		FormatEx(car_key, sizeof(car_key), "%x", entity);
		if (g_hCarMap.GetValue(car_key, survivor))
		{
			g_hCarMap.Remove(car_key);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Car);
			SDKUnhook(entity, SDKHook_Touch, OnTouch_Car);
		}

		// check for infected assistance
		int infected = 0;
		if (IsValidSurvivor(survivor))
		{
			if (g_SkillCache[survivor].m_iLastCarAlarmReason == CALARM_BOOMER)
			{
				infected = g_iLastCarAlarmBoomer;
			}
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_carryAttacker")))
			{
				infected = GetEntPropEnt(survivor, Prop_Send, "m_carryAttacker");
			}
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_jockeyAttacker")))
			{
				infected = GetEntPropEnt(survivor, Prop_Send, "m_jockeyAttacker");
			}
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_tongueOwner")))
			{
				infected = GetEntPropEnt(survivor, Prop_Send, "m_tongueOwner");
			}
		}

		HandleCarAlarmTriggered(survivor, infected, (IsValidClientInGame(survivor)) ? g_SkillCache[survivor].m_iLastCarAlarmReason : CALARM_UNKNOWN);
	}
}

static stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}

	return false;
}

static stock float GetSurvivorDistance(int client)
{
	return L4D2Direct_GetFlowDistance(client);
}