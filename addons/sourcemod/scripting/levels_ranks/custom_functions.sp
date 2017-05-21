public int SteamWorks_SteamServersConnected()
{
	int iIp[4];
	if(SteamWorks_GetPublicIP(iIp) && iIp[0] && iIp[1] && iIp[2] && iIp[3])
	{
		char szBuffer[256];
		Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "http://stats.scriptplugs.info/add_server.php");
		FormatEx(szBuffer, sizeof(szBuffer), "key=%s&ip=%d.%d.%d.%d:%d&version=%s", API_KEY, iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, PLUGIN_VERSION);
		SteamWorks_SetHTTPRequestRawPostBody(hRequest, "application/x-www-form-urlencoded", szBuffer, sizeof(szBuffer));
		SteamWorks_SetHTTPCallbacks(hRequest, OnTransferComplete);
		SteamWorks_SendHTTPRequest(hRequest);
	}
}

public int OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	delete hRequest;
	switch(eStatusCode)
	{
		case k_EHTTPStatusCode200OK:					LogAction(-1, -1, "[LR] Сервер успешно добавлен/обновлен");
		case k_EHTTPStatusCode400BadRequest:			LogError("[LR] Не верный запрос");
		case k_EHTTPStatusCode404NotFound:				LogError("[LR] Сервер или версия не найдены в базе данных");
		case k_EHTTPStatusCode406NotAcceptable:			LogError("[LR] Не верный API KEY");
		case k_EHTTPStatusCode413RequestEntityTooLarge:	LogError("[LR] Не верный размер аргументов");
	}
}

void Hook_MakeChatMessage(int iClient, int iValue, int iValueShow, bool bAdmin, char[] sTitlePhrase)
{
	if((g_iTypeStatistics < 3) && iValue != 0 && (g_iCountPlayers >= 4 || bAdmin) && IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
	{
		char sFirstPart[64], sLastPart[64];
		SetGlobalTransTarget(iClient);
		SetExpEvent(iClient, iValue);
		switch(g_iTypeStatistics)
		{
			case 1:
			{
				FormatEx(sFirstPart, sizeof(sFirstPart), "%t:", "Message_Hook_Time");
				FormatEx(sLastPart, sizeof(sLastPart), "%02d : %02d : %02d", g_iClientData[iClient][0] / 3600, g_iClientData[iClient][0] / 60 % 60, g_iClientData[iClient][0] % 60);
			}

			default:
			{
				FormatEx(sFirstPart, sizeof(sFirstPart), "%t:", "Message_Hook_Exp");
				FormatEx(sLastPart, sizeof(sLastPart), "%d", g_iClientData[iClient][0]);
			}
		}
		LR_PrintToChat(iClient, "%t", sTitlePhrase, sFirstPart, sLastPart, iValueShow);
	}
}

int SetExpEvent(int iClient, int iAmount)
{
	g_iClientData[iClient][0] += iAmount;

	if((g_iTypeStatistics < 2) && (g_iClientData[iClient][0] < 0))
	{
		g_iClientData[iClient][0] = 0;
	}

	CheckRank(iClient);
	return g_iClientData[iClient][0];
}

public int gameMe_GetPoints(int command, int payload, int iClient, Handle& datapack)
{
	if(iClient && (command == RAW_MESSAGE_CALLBACK_PLAYER))
	{
		Handle hData = CloneHandle(datapack);
		SetPackPosition(hData, view_as<DataPackPos>(18));
		g_iClientData[iClient][0] = ReadPackCell(hData);
		CloseHandle(datapack);
		CheckRank(iClient);
	}
}

bool ClientIsVip(int iClient)
{
	if(g_iClientData[iClient][8] >= GetTime())
	{
		return true;
	}
	else g_iClientData[iClient][8] = 0;
	return false;
}

void LR_PrecacheSound()
{
	switch(g_iEngineGame)
	{
		case EngineGameCSGO: AddToStringTable(FindStringTable("soundprecache"), "*levels_ranks/levelup.mp3"), AddToStringTable(FindStringTable("soundprecache"), "*levels_ranks/leveldown.mp3");
		case EngineGameCSS, EngineGameTF2: PrecacheSound("levels_ranks/levelup.mp3"), PrecacheSound("levels_ranks/leveldown.mp3");
	}
}

void LR_EmitSound(int iClient, char[] sPath)
{
	char sBuffer[256];
	switch(g_iEngineGame)
	{
		case EngineGameCSGO: FormatEx(sBuffer, sizeof(sBuffer), "*%s", sPath);
		case EngineGameCSS, EngineGameTF2: FormatEx(sBuffer, sizeof(sBuffer), sPath);
	}
	EmitSoundToClient(iClient, sBuffer, SOUND_FROM_PLAYER, SNDCHAN_LR_RANK);
}