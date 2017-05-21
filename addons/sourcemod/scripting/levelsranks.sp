/***************************************************************************
****
****		Author :			RoadSide Romeo	creator of the plug-in
****		Partners :		R1KO			module system
****						Pheonix			synchronization with RankMe, gameMe
****						White Wolf		transaction method
****						Lord FEAR		web-interface
****						Grey™			new syntax
****
****		Date of creation :	November 27, 2014
****		Date of release :	April 12, 2015
****		Last update :		May 22, 2017
****
***************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>

#define EngineGameCSGO 1
#define EngineGameCSS 2
#define EngineGameTF2 3

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <rankme>
#include <gameme>
#include <cstrike>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

#include <SteamWorks>
#pragma newdecls required
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"
#define PLUGIN_SITE "http://hlmod.ru/resources/levels-ranks-core.177/"

#define API_KEY "9b73eb261988f297fcd7b69a6f027025"
#define SNDCHAN_LR_RANK 80

//	g_iClientData - значения
//	0 - value, 1 - rank, 2 - kills, 3 - deaths, 4 - shoots, 5 - hits, 6 - headshots, 7 - assists, 8 - vip, 9 - vipgroup

int			g_iClientData[MAXPLAYERS + 1][10],
			g_iCompetitiveRank[MAXPLAYERS + 1],
			g_iKillstreak[MAXPLAYERS + 1],
			g_iModulesCount,
			g_iEngineGame,
			g_iCountPlayers,
			g_iRankOffset;

bool			g_bHaveBomb[MAXPLAYERS + 1] = false,
			g_bCoreIsStarted = false;

Handle		g_hTimerGiver[MAXPLAYERS + 1],
			g_hVIPGroup,
			g_hForward_OnCoreStarted,
			g_hForward_OnMenuCreated,
			g_hForward_OnMenuItemSelected;

#include "levels_ranks/settings.sp"
#include "levels_ranks/database.sp"
#include "levels_ranks/custom_functions.sp"
#include "levels_ranks/menus.sp"
#include "levels_ranks/hooks.sp"
#include "levels_ranks/natives.sp"

public Plugin myinfo = {name = "[LR] Core", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION, url = PLUGIN_SITE}
public void OnPluginStart()
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO: g_bCoreIsStarted = true, g_iEngineGame = EngineGameCSGO;
		case Engine_CSS: g_bCoreIsStarted = true, g_iEngineGame = EngineGameCSS;
		case Engine_TF2: g_bCoreIsStarted = true, g_iEngineGame = EngineGameTF2;
		default: SetFailState("Levels Ranks работает только в CS:GO, CS:S или TF2");
	}

	g_hVIPGroup = RegClientCookie("LR_VIPGroup", "LR_VIPGroup", CookieAccess_Private);
	g_hForward_OnCoreStarted = CreateGlobalForward("LR_OnCoreStarted", ET_Ignore);
	g_hForward_OnMenuCreated = CreateGlobalForward("LR_OnMenuCreated", ET_Ignore, Param_Cell, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelected = CreateGlobalForward("LR_OnMenuItemSelected", ET_Ignore, Param_Cell, Param_Cell, Param_String);

	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}

	LoadTranslations("levels_ranks_core.phrases");
	RegAdminCmd("sm_lvl_reset", ResetStatsFull, ADMFLAG_ROOT);
	RegAdminCmd("sm_lvl_zeroing", ResetStatsZeroing, ADMFLAG_ROOT);
	SetSettings();
}

public void OnConfigsExecuted()
{
	AddFileToDownloadsTable("sound/levels_ranks/levelup.mp3");
	AddFileToDownloadsTable("sound/levels_ranks/leveldown.mp3");
	LR_PrecacheSound();

	if(g_bOverLays)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		AddFileToDownloadsTable("materials/lvl_overlays/lvl_up.vtf");
		AddFileToDownloadsTable("materials/lvl_overlays/lvl_up.vmt");
		AddFileToDownloadsTable("materials/lvl_overlays/lvl_down.vtf");
		AddFileToDownloadsTable("materials/lvl_overlays/lvl_down.vmt");
	}
}

public void OnAllPluginsLoaded()
{
	switch(g_iTypeStatistics)
	{
		case 3: if(!LibraryExists("rankme")) SetFailState("Levels Ranks: RankMe отсутствует, синхронизация невозможна");
		case 4: if(!LibraryExists("gameme")) SetFailState("Levels Ranks: gameMe отсутствует, синхронизация невозможна");
	}

	Call_StartForward(g_hForward_OnCoreStarted);
	Call_Finish();
}

public void OnMapStart()
{
	SteamWorks_SteamServersConnected();
	if(g_bFakeRank && (g_iEngineGame == EngineGameCSGO))
	{
		g_iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
		SDKHook(FindEntityByClassname(MaxClients + 1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
	}
}

public void OnMapEnd()
{
	if(g_bFakeRank && (g_iEngineGame == EngineGameCSGO))
	{
		SDKUnhook(FindEntityByClassname(MaxClients + 1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
	}

	SaveDataPlayer_OnMapEnd();
	PurgeDatabase();
}

public Action OnPlayerRunCmd(int iClient, int& buttons, int& impulse, float fVel[3], float fAngles[3], int& iWeapon)
{
	if(g_iEngineGame == EngineGameCSGO)
	{
		if(StartMessageOne("ServerRankRevealAll", iClient) != INVALID_HANDLE) EndMessage();
	}
}

public void Hook_OnThinkPost(int iEnt)
{
	SetEntDataArray(iEnt, g_iRankOffset, g_iCompetitiveRank, MaxClients + 1);
}

void CheckRank(int iClient)
{
	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		int iRank = g_iClientData[iClient][1];

		if(ClientIsVip(iClient))
		{
			g_iClientData[iClient][1] = g_iVIPGroupRanks[g_iClientData[iClient][9]];
		}
		else
		{
			if(g_iTypeStatistics < 2)
			{
				for(int i = 18; i >= 1; i--)
				{
					if(i == 1)
					{
						g_iClientData[iClient][1] = 1;
					}
					else if(g_iShowExp[i] <= g_iClientData[iClient][0])
					{
						g_iClientData[iClient][1] = i;
						break;
					}
				}
			}
			else
			{
				if((g_iClientData[iClient][2] >= 10) || (g_iClientData[iClient][3] >= 10) || (g_iTypeStatistics != 2))
				{
					for(int i = 18; i >= 1; i--)
					{
						if(i == 1)
						{
							g_iClientData[iClient][1] = 1;
						}
						else if(g_iShowExp[i] + g_iEloStartCount <= g_iClientData[iClient][0])
						{
							g_iClientData[iClient][1] = i;
							break;
						}
					}
				}
			}
		}

		if(g_iClientData[iClient][1] > iRank)
		{
			LR_EmitSound(iClient, "levels_ranks/levelup.mp3");
			LR_PrintToChat(iClient, "%t", "LevelUp", g_sShowRank[g_iClientData[iClient][1]]);
			if(g_bOverLays) ClientCommand(iClient, "r_screenoverlay lvl_overlays/lvl_up"), CreateTimer(3.0, DeleteOverlay, GetClientUserId(iClient));
		}
		else if(g_iClientData[iClient][1] < iRank)
		{
			LR_EmitSound(iClient, "levels_ranks/leveldown.mp3");
			LR_PrintToChat(iClient, "%t", "LevelDown", g_sShowRank[g_iClientData[iClient][1]]);
			if(g_bOverLays) ClientCommand(iClient, "r_screenoverlay lvl_overlays/lvl_down"), CreateTimer(3.0, DeleteOverlay, GetClientUserId(iClient));
		}

		g_iCompetitiveRank[iClient] = g_iClientData[iClient][1];
	}
}

public Action DeleteOverlay(Handle hTimer, any iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if(IsValidClient(iClient))
	{
		ClientCommand(iClient, "r_screenoverlay off");
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsValidClient(iClient))
	{
		LoadDataPlayer(iClient);
		if(g_iTypeStatistics == 1)
		{
			g_hTimerGiver[iClient] = CreateTimer(1.0, TimerGiver, GetClientUserId(iClient), TIMER_REPEAT);
		}
	}
}

public Action TimerGiver(Handle hTimer, int iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if((g_iCountPlayers >= 4) && IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient] && GetClientTeam(iClient) > 1)
	{
		g_iClientData[iClient][0] += 1;
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[4];
	GetClientCookie(iClient, g_hVIPGroup, sCookie, sizeof(sCookie));
	g_iClientData[iClient][9] = StringToInt(sCookie);
}

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sCookie[4];
		FormatEx(sCookie, sizeof(sCookie), "%i", g_iClientData[iClient][9]);
		SetClientCookie(iClient, g_hVIPGroup, sCookie);		
	}

	if(g_hTimerGiver[iClient] != null)
	{
		KillTimer(g_hTimerGiver[iClient]);
		g_hTimerGiver[iClient] = null;
	}

	if(IsClientInGame(iClient) && g_bInitialized[iClient])
	{
		SaveDataPlayer(iClient);
		g_bInitialized[iClient] = false;
		g_iKillstreak[iClient] = 0;
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);	
		}
	}
}