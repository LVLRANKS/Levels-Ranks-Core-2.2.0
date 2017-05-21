public Action ResetStatsFull(int iClient, int args) {ResetStats(); return Plugin_Handled;}
public Action ResetStatsZeroing(int iClient, int args) {ResetStatsZero(); return Plugin_Handled;}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(IsValidClient(iClient))
	{
		if(StrEqual(sArgs, "top", false))
		{
			switch(g_iTypeStatistics)
			{
				case 2: PrintTop(iClient, 0);
				case 3: FakeClientCommand(iClient, "say !top");
				case 4: FakeClientCommand(iClient, "say top10");
			}
		}
		else if(StrEqual(sArgs, "rank", false))
		{
			if(g_iTypeStatistics == 2)
			{
				int iKills, iDeaths;

				if(g_iClientData[iClient][2] == 0) iKills = 1;
				else iKills = g_iClientData[iClient][2];

				if(g_iClientData[iClient][3] == 0) iDeaths = 1;
				else iDeaths = g_iClientData[iClient][3];

				if(g_bRankMessage)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsValidClient(i)) LR_PrintToChat(i, "%t", "RankPlayer", iClient, g_iPlayerPlace[iClient], g_iPlayerCount, g_iClientData[iClient][0], iKills, iDeaths, float(iKills) / float(iDeaths));
					}
				}
				else
				{
					LR_PrintToChat(iClient, "%t", "RankPlayer", iClient, g_iPlayerPlace[iClient], g_iPlayerCount, g_iClientData[iClient][0], iKills, iDeaths, float(iKills) / float(iDeaths));
				}
			}
		}

		for(int i = 0; i < sizeof(g_sMainMenuStr); i++)
		{
			if(StrEqual(sArgs, g_sMainMenuStr[i], false))
			{
				MainMenu(iClient);
			}
		}
	}
	
	return Plugin_Continue;
}

void MainMenu(int iClient)
{
	char sBuffer[96], sText[128];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(MainMenuHandler);

	switch(ClientIsVip(iClient))
	{
		case true: FormatEx(sBuffer, sizeof(sBuffer), "%t", "MainMenu_VIP", g_sVIPGroup[g_iClientData[iClient][9]]);
		case false: FormatEx(sBuffer, sizeof(sBuffer), "%t", "MainMenu_Rank", g_sShowRank[g_iClientData[iClient][1]]);
	}

	switch(g_iTypeStatistics)
	{
		case 0: hMenu.SetTitle("%t\n ", "MainMenu_Exp", PLUGIN_NAME, sBuffer, g_iClientData[iClient][0], g_iPlayerPlace[iClient], g_iPlayerCount);
		case 1: hMenu.SetTitle("%t\n ", "MainMenu_Time", PLUGIN_NAME, sBuffer, g_iClientData[iClient][0] / 3600, g_iClientData[iClient][0] / 60 % 60, g_iClientData[iClient][0] % 60, g_iPlayerPlace[iClient], g_iPlayerCount);
		case 2: hMenu.SetTitle("%t\n ", "MainMenu_Exp", PLUGIN_NAME, sBuffer, g_iClientData[iClient][0], g_iPlayerPlace[iClient], g_iPlayerCount);
		default: hMenu.SetTitle("%t\n ", "MainMenu_None", PLUGIN_NAME, sBuffer, g_iClientData[iClient][0]);
	}

	FormatEx(sText, sizeof(sText), "%t", "AllRanks"); hMenu.AddItem("0", sText);
	FormatEx(sText, sizeof(sText), "%t\n -----------------------------", "TOP"); hMenu.AddItem("1", sText);

	if(g_iModulesCount > 0)
	{
		FormatEx(sText, sizeof(sText), "%t", "Inventory"); hMenu.AddItem("2", sText);
	}

	if(g_iTypeStatistics < 3)
	{
		FormatEx(sText, sizeof(sText), "%t", "FullMyStats"); hMenu.AddItem("3", sText);
	}

	int flags = GetUserFlagBits(iClient);
	if(flags & g_iAdminFlag || flags & ADMFLAG_ROOT)
	{
		FormatEx(sText, sizeof(sText), "%t", "MainAdminMenu"); hMenu.AddItem("4", sText);
	}

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[16];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: AllRankMenu(iClient);
				case 1:
				{
					switch(g_iTypeStatistics)
					{
						case 3: FakeClientCommand(iClient, "say !top");
						case 4: FakeClientCommand(iClient, "say top10");
						default: PrintTop(iClient, 0);
					}
				}
				case 2: InventoryMenu(iClient);
				case 3: FullMyStats(iClient);
				case 4: MainAdminMenu(iClient);
			}
		}
	}
}

void AllRankMenu(int iClient)
{
	char sText[192];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(AllRankMenuHandler);

	FormatEx(sText, sizeof(sText), "%t", "AllRanks");
	hMenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);

	for(int i = 1; i <= 18; i++)
	{
		if(i > 1)
		{
			switch(g_iTypeStatistics)
			{
				case 0: FormatEx(sText, sizeof(sText), "[%i] %s", g_iShowExp[i], g_sShowRank[i]);
				case 1: FormatEx(sText, sizeof(sText), "[%02d : %02d : %02d] %s", g_iShowExp[i] / 3600, g_iShowExp[i] / 60 % 60, g_iShowExp[i] % 60, g_sShowRank[i]);
				default: FormatEx(sText, sizeof(sText), "[%i] %s", g_iShowExp[i] + g_iEloStartCount, g_sShowRank[i]);
			}
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%s", g_sShowRank[i]);
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
	}

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int AllRankMenuHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
	}
}

void PrintTop(int iClient, int iValue)
{
	if(IsValidClient(iClient))
	{
		char sQuery[512];
		DataPack hDataPack = new DataPack();
		hDataPack.WriteCell(iClient);

		if(iValue > 0)
		{
			hDataPack.WriteCell(iValue - 1);
		}
		else
		{
			hDataPack.WriteCell(0);
			iValue = 1;
		}

		FormatEx(sQuery, sizeof(sQuery), g_sSQL_CallTOP, iValue - 1);
		g_hDatabase.Query(SQL_PrintTop, sQuery, hDataPack);
	}
}

public void SQL_PrintTop(Database db, DBResultSet dbRs, const char[] sError, any data)
{
	if(dbRs == null)
	{
		LogError("Levels Ranks: SQL_PrintTop - ошибка получения ТОПа (%s)", sError);
		return;
	}

	DataPack hDataPack = view_as<DataPack>(data);
	hDataPack.Reset();
	int iClient = hDataPack.ReadCell();
	int iValue = hDataPack.ReadCell();
	delete hDataPack;

	if(IsValidClient(iClient))
	{
		int i;
		char sName[64], sTemp[512], sTemp1[20], sBuffer[256];

		if(!dbRs.HasResults || dbRs.RowCount == 0)
		{
			PrintTop(iClient, g_iPlayerCount - 9);
			return;
		}

		Menu hMenu = CreateMenuEx(GetMenuStyleHandle(view_as<MenuStyle>(MenuStyle_Radio)), MenuHandler_Top);
		hMenu.SetTitle("");

		FormatEx(sTemp, sizeof(sTemp), "%t\n \n", "TOPCount", iValue + 1, iValue + 10, g_iPlayerCount);
		while(dbRs.HasResults && dbRs.FetchRow())
		{
			i++;
			dbRs.FetchString(0, sName, sizeof(sName));
			int iStats = dbRs.FetchInt(1);

			switch(g_iTypeStatistics)
			{
				case 1: FormatEx(sBuffer, sizeof(sBuffer), "%d - [%02d : %02d : %02d] - %s\n", i + iValue, iStats / 3600, iStats / 60 % 60, iStats % 60, sName);
				default: FormatEx(sBuffer, sizeof(sBuffer), "%d - [ %i exp ] - %s\n", i + iValue, iStats, sName);
			}

			if(strlen(sTemp) + strlen(sBuffer) < 512)
			{
				Format(sTemp, sizeof(sTemp), "%s%s", sTemp, sBuffer);
				sBuffer = "\0";
			}
		}

		Format(sTemp, sizeof(sTemp), "%s\n ", sTemp);
		hMenu.AddItem(sTemp, sTemp);

		IntToString(iValue + i, sTemp, sizeof(sTemp));
		FormatEx(sTemp1, sizeof(sTemp1), "%t", "Next");
		if(i > 9)
		{
			hMenu.AddItem(sTemp, sTemp1);
		}

		IntToString(iValue - i, sTemp, sizeof(sTemp));
		FormatEx(sTemp1, sizeof(sTemp1), "%t", "Back");
		if(iValue + i - 1 > 9)
		{
			hMenu.AddItem(sTemp, sTemp1);
		}

		hMenu.ExitButton = true;
		hMenu.DisplayAt(iClient, iValue, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_Top(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_Exit) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sTemp[512];
			hMenu.GetItem(iSlot, sTemp, sizeof(sTemp));

			if(StringToInt(sTemp) >= 0)
			{
				PrintTop(iClient, StringToInt(sTemp) + 1);
			}
			else PrintTop(iClient, 0);
		}
	}
}

void InventoryMenu(int iClient)
{
	char sText[64];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(MenuHandler_Category);
	FormatEx(sText, sizeof(sText), "%t", "Inventory");
	hMenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;

	for(int iRank = 0; iRank <= 18; iRank++)
	{
		Call_StartForward(g_hForward_OnMenuCreated);
		Call_PushCell(iClient);
		Call_PushCell(iRank);
		Call_PushCellRef(hMenu);
		Call_Finish();
	}

	if(hMenu.ItemCount == 0)
	{
		hMenu.AddItem("", "-----");
	}

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Category(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[64];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			for(int iRank = 0; iRank <= 18; iRank++)
			{
				Call_StartForward(g_hForward_OnMenuItemSelected);
				Call_PushCell(iClient);
				Call_PushCell(iRank);
				Call_PushString(sInfo);
				Call_Finish();
			}
		}
	}

	return 0;
}

void FullMyStats(int iClient)
{
	int iKills, iDeaths, iHeadShots, iShoots, iHits;
	char sText[512];

	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(FullStats_Callback);

	if(g_iClientData[iClient][2] == 0) iKills = 1;
	else iKills = g_iClientData[iClient][2];

	if(g_iClientData[iClient][3] == 0) iDeaths = 1;
	else iDeaths = g_iClientData[iClient][3];

	if(g_iClientData[iClient][4] == 0) iShoots = 1;
	else iShoots = g_iClientData[iClient][4];

	if(g_iClientData[iClient][5] == 0) iHits = 1;
	else iHits = g_iClientData[iClient][5];

	if(g_iClientData[iClient][6] == 0) iHeadShots = 1;
	else iHeadShots = g_iClientData[iClient][6];

	switch(g_iEngineGame)
	{
		case EngineGameTF2: hMenu.SetTitle("%t\n ", "FullStatsTF2", PLUGIN_NAME, g_iClientData[iClient][2], g_iClientData[iClient][3], g_iClientData[iClient][7], float(iKills) / float(iDeaths));
		default: hMenu.SetTitle("%t\n ", "FullStats", PLUGIN_NAME, g_iClientData[iClient][2], g_iClientData[iClient][3], g_iClientData[iClient][7], g_iClientData[iClient][6], RoundToCeil((100.00 / float(iKills)) * float(iHeadShots)), float(iKills) / float(iDeaths), g_iClientData[iClient][4], g_iClientData[iClient][5], RoundToCeil((100.00 / float(iShoots)) * float(iHits)));
	}

	FormatEx(sText, sizeof(sText), "%t", "ResetMyStats");
	hMenu.AddItem("", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int FullStats_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_Exit) {MainMenu(iClient);}
		case MenuAction_Select: ResetMyStatsMenu(iClient);
	}
}

void ResetMyStatsMenu(int iClient)
{
	char sText[192];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(ResetMyStatsMenu_Callback);

	FormatEx(sText, sizeof(sText), "%t", "ResetMyStatsMenu");
	hMenu.SetTitle("%s\n \n", sText);

	FormatEx(sText, sizeof(sText), "%t", "Yes");
	hMenu.AddItem("", sText);

	FormatEx(sText, sizeof(sText), "%t", "No");
	hMenu.AddItem("", sText);

	hMenu.ExitButton = false;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int ResetMyStatsMenu_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			switch(iSlot)
			{
				case 0:
				{
					switch(g_iTypeStatistics)
					{
						case 0: g_iClientData[iClient][0] = 0;
						case 1: g_iClientData[iClient][0] = 0;
						case 2: g_iClientData[iClient][0] = g_iEloStartCount;
						case 3: g_iClientData[iClient][0] = g_iEloStartCount;
						case 4: g_iClientData[iClient][0] = g_iEloStartCount;
					}
					g_iClientData[iClient][1] = 0;
					g_iClientData[iClient][2] = 0;
					g_iClientData[iClient][3] = 0;
					g_iClientData[iClient][4] = 0;
					g_iClientData[iClient][5] = 0;
					g_iClientData[iClient][6] = 0;
					g_iClientData[iClient][7] = 0;
					g_iClientData[iClient][8] = 0;
					CheckRank(iClient);
					MainMenu(iClient);
				}
				case 1: MainMenu(iClient);
			}
		}
	}
}

void MainAdminMenu(int iClient)
{
	char sText[192];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(MainAdminMenu_Callback);

	FormatEx(sText, sizeof(sText), "%t", "MainAdminMenu");
	hMenu.SetTitle("%s | %s\n \n", PLUGIN_NAME, sText);

	switch(g_iTypeStatistics)
	{
		case 0: FormatEx(sText, sizeof(sText), "%t", "GiveTakeExp"), hMenu.AddItem("0", sText);
		case 1: FormatEx(sText, sizeof(sText), "%t", "GiveTakeTime"), hMenu.AddItem("0", sText);
	}

	FormatEx(sText, sizeof(sText), "%t", "VIPGive");
	hMenu.AddItem("1", sText);

	FormatEx(sText, sizeof(sText), "%t", "VIPTake");
	hMenu.AddItem("2", sText);

	FormatEx(sText, sizeof(sText), "%t", "VIPAddTime");
	hMenu.AddItem("3", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MainAdminMenu_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot) 
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_Exit) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[16];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: GiveTakeValue(iClient);
				case 1: VIPStatusChange(iClient, 0);
				case 2: VIPStatusChange(iClient, 1);
				case 3: VIPStatusChange(iClient, 2);
			}
		}
	}
}

void GiveTakeValue(int iClient)
{
	char sID[16], sNickName[32], sText[64];
	Menu Mmenu = new Menu(ChangeExpPlayers_CallBack);
	SetGlobalTransTarget(iClient);

	switch(g_iTypeStatistics)
	{
		case 0: FormatEx(sText, sizeof(sText), "%t", "GiveTakeExp");
		case 1: FormatEx(sText, sizeof(sText), "%t", "GiveTakeTime");
	}

	Mmenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), sID, 16);
			sNickName[0] = '\0';
			GetClientName(i, sNickName, 32);
			Mmenu.AddItem(sID, sNickName);
		}
	}
	
	Mmenu.ExitBackButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int ChangeExpPlayers_CallBack(Menu Mmenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainAdminMenu(iClient);}
		case MenuAction_Select:
		{
			char sID[16];
			Mmenu.GetItem(iSlot, sID, 16);
			GiveTakeValueEND(iClient, sID);
		}
	}
}

public void GiveTakeValueEND(int iClient, char[] sID) 
{
	char sText[64];
	SetGlobalTransTarget(iClient);
	switch(g_iTypeStatistics)
	{
		case 0: FormatEx(sText, sizeof(sText), "%t", "GiveTakeExp");
		case 1: FormatEx(sText, sizeof(sText), "%t", "GiveTakeTime");
	}
	Menu Mmenu = new Menu(ChangeExpPlayersENDHandler);
	Mmenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);

	switch(g_iTypeStatistics)
	{
		case 0:
		{
			Mmenu.AddItem(sID, "100");
			Mmenu.AddItem(sID, "1000");
			Mmenu.AddItem(sID, "10000");
			Mmenu.AddItem(sID, "-10000");
			Mmenu.AddItem(sID, "-1000");
			Mmenu.AddItem(sID, "-100");
		}

		case 1:
		{
			Mmenu.AddItem(sID, "5");
			Mmenu.AddItem(sID, "60");
			Mmenu.AddItem(sID, "300");
			Mmenu.AddItem(sID, "-300");
			Mmenu.AddItem(sID, "-60");
			Mmenu.AddItem(sID, "-5");
		}
	}
	Mmenu.ExitBackButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int ChangeExpPlayersENDHandler(Menu Mmenu, MenuAction mAction, int iClient, int iSlot) 
{	
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {GiveTakeValue(iClient);}
		case MenuAction_Select:
		{
			char info[32], s_buffer[32];
			Mmenu.GetItem(iSlot, info, sizeof(info), _, s_buffer, sizeof(s_buffer));
			int IDGivePP = GetClientOfUserId(StringToInt(info));
			int iBuffer = StringToInt(s_buffer);

			if(IsClientInGame(IDGivePP) && !IsFakeClient(IDGivePP))
			{
				GiveTakeValueEND(iClient, info);

				if(iBuffer > 0)
				{
					Hook_MakeChatMessage(IDGivePP, iBuffer, iBuffer, true, "ValueGive");
					switch(g_iTypeStatistics)
					{
						case 0: LR_PrintToChat(iClient, "%N - {GRAY}%i (+%i)", IDGivePP, g_iClientData[IDGivePP][0], iBuffer);
						case 1: LR_PrintToChat(iClient, "%N - {GRAY}%02d:%02d:%02d (+%i)", IDGivePP, g_iClientData[IDGivePP][0] / 3600, g_iClientData[IDGivePP][0] / 60 % 60, g_iClientData[IDGivePP][0] % 60, iBuffer);
					}
				}
				else
				{
					Hook_MakeChatMessage(IDGivePP, iBuffer, iBuffer, true, "ValueTake");
					switch(g_iTypeStatistics)
					{
						case 0: LR_PrintToChat(iClient, "%N - {GRAY}%i (%i)", IDGivePP, g_iClientData[IDGivePP][0], iBuffer);
						case 1: LR_PrintToChat(iClient, "%N - {GRAY}%02d:%02d:%02d (%i)", IDGivePP, g_iClientData[IDGivePP][0] / 3600, g_iClientData[IDGivePP][0] / 60 % 60, g_iClientData[IDGivePP][0] % 60, iBuffer);
					}
				}
			}
		}
	}
}

void VIPStatusChange(int iClient, int iType)
{
	char sInfo[8], sNickName[32], sText[64];
	SetGlobalTransTarget(iClient);

	Menu Mmenu = new Menu(VIPStatusChange_CallBack);
	switch(iType)
	{
		case 0: FormatEx(sText, sizeof(sText), "%t", "VIPGive");
		case 1: FormatEx(sText, sizeof(sText), "%t", "VIPTake");
		case 2: FormatEx(sText, sizeof(sText), "%t", "VIPAddTime");
	}
	Mmenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			sNickName[0] = '\0';
			FormatEx(sInfo, sizeof(sInfo), "%i;%i;", GetClientUserId(i), iType);
			GetClientName(i, sNickName, 32);
			
			if(iType == 2)
			{
				if(g_iClientData[i][8] > GetTime())
				{
					Mmenu.AddItem(sInfo, sNickName);
				}
			}
			else	Mmenu.AddItem(sInfo, sNickName);
		}
	}

	Mmenu.ExitBackButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int VIPStatusChange_CallBack(Menu Mmenu, MenuAction mAction, int iClient, int iSlot) 
{	
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainAdminMenu(iClient);}
		case MenuAction_Select:
		{
			char sID[8], sInfo[2][4];
			Mmenu.GetItem(iSlot, sID, sizeof(sID));
			ExplodeString(sID, ";", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iUserid = StringToInt(sInfo[0]);
			int iPlayer = GetClientOfUserId(iUserid);

			if(IsValidClient(iPlayer))
			{
				int iType = StringToInt(sInfo[1]);
				switch(iType)
				{
					case 0: VIPStatusChange_Group(iClient, iUserid, iType);
					case 1: g_iClientData[iPlayer][8] = 0, g_iClientData[iPlayer][1] = 0, CheckRank(iPlayer);
					case 2: VIPStatusChange_Time(iClient, iUserid, iType);
				}
			}
		}
	}
}

void VIPStatusChange_Group(int iClient, int iUserid, int iType)
{
	char sInfo[16], sText[64];
	SetGlobalTransTarget(iClient);

	Menu Mmenu = new Menu(VIPStatusChange_Group_CallBack);
	FormatEx(sText, sizeof(sText), "%t", "VIPGroupChoose");
	Mmenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);

	FormatEx(sInfo, sizeof(sInfo), "%i;%i;", iUserid, iType);
	for(int i = 0; i < g_iVIPGroupCount; i++)
	{
		Mmenu.AddItem(sInfo, g_sVIPGroup[i]);
	}

	Mmenu.ExitBackButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int VIPStatusChange_Group_CallBack(Menu Mmenu, MenuAction mAction, int iClient, int iSlot) 
{	
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainAdminMenu(iClient);}
		case MenuAction_Select:
		{
			char sID[8], sInfo[2][4];
			Mmenu.GetItem(iSlot, sID, sizeof(sID));
			ExplodeString(sID, ";", sInfo, sizeof(sInfo), sizeof(sInfo[]));

			int iUserid = StringToInt(sInfo[0]);
			int iPlayer = GetClientOfUserId(iUserid);
			int iType = StringToInt(sInfo[1]);

			if(IsValidClient(iPlayer))
			{
				g_iClientData[iPlayer][9] = iSlot;
				VIPStatusChange_Time(iClient, iUserid, iType);
			}
			else MainAdminMenu(iClient);
		}
	}
}

void VIPStatusChange_Time(int iClient, int iUserid, int iType)
{
	char sInfo[16], sText[64];
	SetGlobalTransTarget(iClient);

	Menu Mmenu = new Menu(VIPStatusChange_Time_CallBack);
	switch(iType)
	{
		case 0: FormatEx(sText, sizeof(sText), "%t", "VIPGive");
		case 2: FormatEx(sText, sizeof(sText), "%t", "VIPAddTime");
	}
	Mmenu.SetTitle("%s | %s (days)\n ", PLUGIN_NAME, sText);
	FormatEx(sInfo, sizeof(sInfo), "%i;%i;", iUserid, iType);

	Mmenu.AddItem(sInfo, "1");
	Mmenu.AddItem(sInfo, "5");
	Mmenu.AddItem(sInfo, "10");
	Mmenu.AddItem(sInfo, "30");
	Mmenu.AddItem(sInfo, "60");
	Mmenu.AddItem(sInfo, "180");
	Mmenu.ExitBackButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int VIPStatusChange_Time_CallBack(Menu Mmenu, MenuAction mAction, int iClient, int iSlot) 
{	
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainAdminMenu(iClient);}
		case MenuAction_Select:
		{
			char sID[8], sInfo[2][4], sBuffer[8];
			Mmenu.GetItem(iSlot, sID, sizeof(sID), _, sBuffer, sizeof(sBuffer));
			ExplodeString(sID, ";", sInfo, sizeof(sInfo), sizeof(sInfo[]));

			int iUserid = StringToInt(sInfo[0]);
			int iPlayer = GetClientOfUserId(iUserid);
			int iType = StringToInt(sInfo[1]);
			int iValue = StringToInt(sBuffer);

			if(IsValidClient(iPlayer))
			{
				switch(iType)
				{
					case 0:
					{
						LR_PrintToChat(iClient, "%t", "VIPAdded", iPlayer, iValue);
						g_iClientData[iPlayer][8] = GetTime() + (iValue * 86400);
					}
					case 2:
					{
						LR_PrintToChat(iClient, "%t", "VIPChange", iPlayer, iValue);
						g_iClientData[iPlayer][8] += iValue * 86400;
					}
				}
				CheckRank(iClient);
				VIPStatusChange_Time(iClient, iUserid, iType);
			}
			else MainAdminMenu(iClient);
		}
	}
}