void MakeHooks_CS()
{
	HookEventEx("weapon_fire", LRHooks);
	HookEventEx("player_death", LRHooks);
	HookEventEx("player_hurt", LRHooks);
	HookEventEx("round_mvp", LRHooks);
	HookEventEx("round_end", LRHooks);
	HookEventEx("round_start", LRHooks);
	HookEventEx("bomb_planted", LRHooks);
	HookEventEx("bomb_defused", LRHooks);
	HookEventEx("bomb_dropped", LRHooks);
	HookEventEx("bomb_pickup", LRHooks);
	HookEventEx("hostage_killed", LRHooks);
	HookEventEx("hostage_rescued", LRHooks);
}

void MakeHooks_TF2()
{
	HookEventEx("arena_round_start", LRHooks_TF2);
	HookEventEx("arena_win_panel", LRHooks_TF2);
	HookEventEx("teamplay_round_start", LRHooks_TF2);
	HookEventEx("teamplay_win_panel", LRHooks_TF2);
	HookEventEx("player_death", LRHooks_TF2);
}

public void LRHooks(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	switch(sEvName[0])
	{
		case 'w':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			if(IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
			{
				char sWeaponName[64];
				GetEventString(hEvent, "weapon", sWeaponName, sizeof(sWeaponName));
				if(!StrEqual(sWeaponName, "hegrenade") || !StrEqual(sWeaponName, "flashbang") || !StrEqual(sWeaponName, "smokegrenade") || !StrEqual(sWeaponName, "molotov") || !StrEqual(sWeaponName, "incgrenade") || !StrEqual(sWeaponName, "decoy"))
				{
					g_iClientData[iClient][4]++;
				}
			}
		}

		case 'p':
		{
			switch(sEvName[7])
			{
				case 'h':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

					if(iAttacker != iClient && IsValidClient(iAttacker) && IsValidClient(iClient) && !IsFakeClient(iAttacker) && !IsFakeClient(iClient) && g_bInitialized[iAttacker])
					{
						if(GetEventInt(hEvent, "hitgroup"))
						{
							g_iClientData[iAttacker][5]++;
						}
					}
				}

				case 'd':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
					bool headshot = GetEventBool(hEvent, "headshot");

					if(!iAttacker || !iClient)
						return;

					if(IsFakeClient(iClient) || IsFakeClient(iAttacker))
						return;

					if(iAttacker == iClient)
					{
						Hook_MakeChatMessage(iClient, g_iGiveSuicide * -1, g_iGiveSuicide, false, "Suicide");
					}
					else
					{
						if(g_iTypeStatistics != 2)
						{
							Hook_MakeChatMessage(iAttacker, g_iGiveKill, g_iGiveKill, false, "Kill");
							Hook_MakeChatMessage(iClient, g_iGiveDeath * -1, g_iGiveDeath, false, "MyDeath");
						}
						else
						{
							int iRankAttacker = g_iClientData[iAttacker][0];
							int iRankVictim = g_iClientData[iClient][0];

							if(iRankAttacker == 0) iRankAttacker = 1;
							if(iRankVictim == 0) iRankVictim = 1;

							int iExpCoeff = RoundToNearest((float(iRankVictim) / float(iRankAttacker)) * 5.00);

							if(iExpCoeff < 0) iExpCoeff = iExpCoeff * -1;
							if(iExpCoeff < 2) iExpCoeff = 2;

							if((g_iClientData[iAttacker][2] >= 10) || (g_iClientData[iAttacker][3] >= 10)) Hook_MakeChatMessage(iAttacker, iExpCoeff, iExpCoeff, false, "Kill");
							else Hook_MakeChatMessage(iAttacker, 20, 20, false, "Kill");

							if((g_iClientData[iClient][2] >= 10) || (g_iClientData[iClient][3] >= 10)) Hook_MakeChatMessage(iClient, iExpCoeff * -1, iExpCoeff, false, "MyDeath");
							else Hook_MakeChatMessage(iClient, -20, 20, false, "MyDeath");
						}

						if(headshot && g_bInitialized[iAttacker])
						{
							g_iClientData[iAttacker][6]++;
							Hook_MakeChatMessage(iAttacker, g_iGiveHeadShot, g_iGiveHeadShot, false, "HeadShotKill");
						}

						if(g_iEngineGame == EngineGameCSGO)
						{
							int iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
							if(iAssister && g_bInitialized[iAssister])
							{
								g_iClientData[iAssister][7]++;
								Hook_MakeChatMessage(iAssister, g_iGiveAssist, g_iGiveAssist, false, "AssisterKill");
							}
						}

						if(g_bInitialized[iAttacker])
						{
							g_iClientData[iAttacker][2]++;
							g_iKillstreak[iAttacker]++;
						}
					}

					if(g_bInitialized[iClient])
					{
						g_iClientData[iClient][3]++;
					}

					SetExpStreakKills(iClient);
				}
			}
		}

		case 'r':
		{
			switch(sEvName[6])
			{
				case 'e': 
				{
					int iTeam, checkteam;
					for(int iClient = 1; iClient <= MaxClients; iClient++)
					{
						if(IsClientInGame(iClient))
						{
							SetExpStreakKills(iClient);
							if((checkteam = GetEventInt(hEvent, "winner")) > 1)
							{
								if((iTeam = GetClientTeam(iClient)) > 1)
								{
									if(iTeam == checkteam)
									{
										Hook_MakeChatMessage(iClient, g_iRoundWin, g_iRoundWin, false, "RoundWin");
									}
									else Hook_MakeChatMessage(iClient, g_iRoundLose * -1, g_iRoundLose, false, "RoundLose");
								}
							}
						}
					}

					SavePlayer_EndRound();
				}

				case 'm':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					Hook_MakeChatMessage(iClient, g_iRoundMVP, g_iRoundMVP, false, "RoundMVP");
				}

				case 's':
				{
					switch(g_iTypeStatistics)
					{
						case 3:
						{
							for(int iClient = 1; iClient <= MaxClients; iClient++)
							{
								if(IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
								{
									g_iClientData[iClient][0] = RankMe_GetPoints(iClient);
									CheckRank(iClient);
								}
							}
						}

						case 4:
						{
							for(int iClient = 1; iClient <= MaxClients; iClient++)
							{
								if(IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
								{
									QueryGameMEStats("playerinfo", iClient, gameMe_GetPoints, 0);
								}
							}
						}
					}

					g_iCountPlayers = 0;
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsValidClient(i) && !IsFakeClient(i) && g_bInitialized[i])
						{
							ClientIsVip(i);
							g_iCountPlayers++;
							RankDataPlayer(i);
						}
					}

					if(g_iCountPlayers < 4 && g_iTypeStatistics < 3)
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsValidClient(i))
							{
								LR_PrintToChat(i, "%t", "RoundStartCheckCount", g_iCountPlayers, 4);
							}
						}
					}

					if(g_bSpawnMessage)
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsValidClient(i))
							{
								LR_PrintToChat(i, "%t", "RoundStartMessageRanks", g_sMainMenuStr[0]);
							}
						}
					}
				}
			}
		}

		case 'b':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[6])
			{
				case 'l': g_bHaveBomb[iClient] = false, Hook_MakeChatMessage(iClient, g_iBombPlanted, g_iBombPlanted, false, "BombPlanted");
				case 'e': Hook_MakeChatMessage(iClient, g_iBombDefused, g_iBombDefused, false, "BombDefused");
				case 'r': if(g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = false; Hook_MakeChatMessage(iClient, g_iBombDropped * -1, g_iBombDropped, false, "BombDropped");}
				case 'i': if(!g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = true; Hook_MakeChatMessage(iClient, g_iBombPickup, g_iBombPickup, false, "BombPickup");}
			}
		}

		case 'h':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[8])
			{
				case 'k': Hook_MakeChatMessage(iClient, g_iHostageKilled * -1, g_iHostageKilled, false, "HostageKilled");
				case 'r': Hook_MakeChatMessage(iClient, g_iHostageRescued, g_iHostageRescued, false, "HostageRescued");
			}
		}
	}
}

public void LRHooks_TF2(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	switch(sEvName[0])
	{
		case 'p':
		{
			switch(sEvName[7])
			{
				case 'd':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
					int iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));

					if(!iAttacker || !iClient)
						return;

					if(IsFakeClient(iClient) || IsFakeClient(iAttacker))
						return;

					if(iAttacker == iClient)
					{
						Hook_MakeChatMessage(iClient, g_iGiveSuicide * -1, g_iGiveSuicide, false, "Suicide");
					}
					else
					{
						if(g_iTypeStatistics != 2)
						{
							Hook_MakeChatMessage(iAttacker, g_iGiveKill, g_iGiveKill, false, "Kill");
							Hook_MakeChatMessage(iClient, g_iGiveDeath * -1, g_iGiveDeath, false, "MyDeath");
						}
						else
						{
							int iRankAttacker = g_iClientData[iAttacker][0];
							int iRankVictim = g_iClientData[iClient][0];

							if(iRankAttacker == 0) iRankAttacker = 1;
							if(iRankVictim == 0) iRankVictim = 1;

							int iExpCoeff = RoundToNearest((float(iRankVictim) / float(iRankAttacker)) * 5.00);

							if(iExpCoeff < 0) iExpCoeff = iExpCoeff * -1;
							if(iExpCoeff < 2) iExpCoeff = 2;

							if((g_iClientData[iAttacker][2] >= 10) || (g_iClientData[iAttacker][3] >= 10)) Hook_MakeChatMessage(iAttacker, iExpCoeff, iExpCoeff, false, "Kill");
							else Hook_MakeChatMessage(iAttacker, 20, 20, false, "Kill");

							if((g_iClientData[iClient][2] >= 10) || (g_iClientData[iClient][3] >= 10)) Hook_MakeChatMessage(iClient, iExpCoeff * -1, iExpCoeff, false, "MyDeath");
							else Hook_MakeChatMessage(iClient, -20, 20, false, "MyDeath");
						}

						if(iAssister && g_bInitialized[iAssister])
						{
							g_iClientData[iAssister][7]++;
							Hook_MakeChatMessage(iAssister, g_iGiveAssist, g_iGiveAssist, false, "AssisterKill");
						}

						if(g_bInitialized[iAttacker])
						{
							g_iClientData[iAttacker][2]++;
							g_iKillstreak[iAttacker]++;
						}
					}

					if(g_bInitialized[iClient])
					{
						g_iClientData[iClient][3]++;
					}

					SetExpStreakKills(iClient);
				}
			}
		}

		case 'a':
		{
			switch(sEvName[6])
			{
				case 'r': LRHooks_TF2_Round(true, hEvent);
				case 'w': LRHooks_TF2_Round(false, hEvent);
			}
		}

		case 't':
		{
			switch(sEvName[9])
			{
				case 'r': LRHooks_TF2_Round(false, hEvent);
				case 'w': LRHooks_TF2_Round(true, hEvent);
			}
		}
	}
}

void LRHooks_TF2_Round(bool bEndRound, Handle hEvent)
{
	if(bEndRound)
	{
		int iTeam, checkteam;
		for(int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsClientInGame(iClient))
			{
				SetExpStreakKills(iClient);
				if((checkteam = GetEventInt(hEvent, "winning_team")) > 1)
				{
					if((iTeam = GetClientTeam(iClient)) > 1)
					{
						if(iTeam == checkteam)
						{
							Hook_MakeChatMessage(iClient, g_iRoundWin, g_iRoundWin, false, "RoundWin");
						}
						else Hook_MakeChatMessage(iClient, g_iRoundLose * -1, g_iRoundLose, false, "RoundLose");
					}
				}
			}
		}
		SavePlayer_EndRound();
	}
	else
	{
		switch(g_iTypeStatistics)
		{
			case 3:
			{
				for(int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if(IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
					{
						g_iClientData[iClient][0] = RankMe_GetPoints(iClient);
						CheckRank(iClient);
					}
				}
			}

			case 4:
			{
				for(int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if(IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
					{
						QueryGameMEStats("playerinfo", iClient, gameMe_GetPoints, 0);
					}
				}
			}
		}

		g_iCountPlayers = 0;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i) && g_bInitialized[i])
			{
				ClientIsVip(i);
				g_iCountPlayers++;
				RankDataPlayer(i);
			}
		}

		if(g_iCountPlayers < 4 && g_iTypeStatistics < 3)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					LR_PrintToChat(i, "%t", "RoundStartCheckCount", g_iCountPlayers, 4);
				}
			}
		}

		if(g_bSpawnMessage)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					LR_PrintToChat(i, "%t", "RoundStartMessageRanks", g_sMainMenuStr[0]);
				}
			}
		}
	}
}

void SetExpStreakKills(int iClient)
{
	if(g_iKillstreak[iClient] > 1)
	{
		switch(g_iKillstreak[iClient])
		{
			case 2: Hook_MakeChatMessage(iClient, g_iBonus[0], g_iBonus[0], false, "DoubleKill");
			case 3: Hook_MakeChatMessage(iClient, g_iBonus[1], g_iBonus[1], false, "TripleKill");
			case 4: Hook_MakeChatMessage(iClient, g_iBonus[2], g_iBonus[2], false, "Domination");
			case 5: Hook_MakeChatMessage(iClient, g_iBonus[3], g_iBonus[3], false, "Rampage");
			case 6: Hook_MakeChatMessage(iClient, g_iBonus[4], g_iBonus[4], false, "MegaKill");
			case 7: Hook_MakeChatMessage(iClient, g_iBonus[5], g_iBonus[5], false, "Ownage");
			case 8: Hook_MakeChatMessage(iClient, g_iBonus[6], g_iBonus[6], false, "UltraKill");
			case 9: Hook_MakeChatMessage(iClient, g_iBonus[7], g_iBonus[7], false, "KillingSpree");
			case 10: Hook_MakeChatMessage(iClient, g_iBonus[8], g_iBonus[8], false, "MonsterKill");
			case 11: Hook_MakeChatMessage(iClient, g_iBonus[9], g_iBonus[9], false, "Unstoppable");
			default: Hook_MakeChatMessage(iClient, g_iBonus[10], g_iBonus[10], false, "GodLike");
		}
	}
	g_iKillstreak[iClient] = 0;
}

void SavePlayer_EndRound()
{
	char sQuery[512], sSaveName[MAX_NAME_LENGTH * 2 + 1];
	Transaction hQuery = new Transaction();
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
		{
			g_hDatabase.Escape(g_sName[iClient], sSaveName, sizeof(sSaveName));
			FormatEx(sQuery, sizeof(sQuery), g_sSQL_SavePlayer, g_iClientData[iClient][0], sSaveName, g_iClientData[iClient][1], g_iClientData[iClient][2], g_iClientData[iClient][3], g_iClientData[iClient][4], g_iClientData[iClient][5], g_iClientData[iClient][6], g_iClientData[iClient][7], g_iClientData[iClient][8], GetTime(), g_sSteamID[iClient]);
			hQuery.AddQuery(sQuery);
		}
	}
	
	g_hDatabase.Execute(hQuery, _, Transaction_ErrorCallback, _, DBPrio_High);
}