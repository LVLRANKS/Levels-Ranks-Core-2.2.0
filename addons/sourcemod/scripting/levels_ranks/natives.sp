public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("LR_CoreStarted", Native_LR_CoreStarted);
	CreateNative("LR_CoreIsReady", Native_LR_CoreIsReady);
	CreateNative("LR_TypeStatistics", Native_LR_TypeStatistics);
	CreateNative("LR_ModuleCount", Native_LR_ModuleCount);
	CreateNative("LR_GetClientPos", Native_LR_GetClientPos);
	CreateNative("LR_GetClientRank", Native_LR_GetClientRank);
	CreateNative("LR_GetClientValue", Native_LR_GetClientValue);
	CreateNative("LR_GetClientStats", Native_LR_GetClientStats);
	CreateNative("LR_SetClientVIP", Native_LR_SetClientVIP);
	CreateNative("LR_DeleteClientVIP", Native_LR_DeleteClientVIP);
	CreateNative("LR_ChangeClientValue", Native_LR_ChangeClientValue);
	CreateNative("LR_MenuInventory", Native_LR_MenuInventory);

	RegPluginLibrary("levelsranks");
	return APLRes_Success;
}

public int Native_LR_CoreStarted(Handle hPlugin, int iNumParams)
{
	return g_bCoreIsStarted;
}

public int Native_LR_CoreIsReady(Handle hPlugin, int iNumParams)
{
	if(g_iCountPlayers >= 4)
	{
		return true;
	}
	else return false;
}

public int Native_LR_TypeStatistics(Handle hPlugin, int iNumParams)
{
	return g_iTypeStatistics;
}

public int Native_LR_ModuleCount(Handle hPlugin, int iNumParams)
{
	g_iModulesCount++;
}

public int Native_LR_GetClientPos(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		return g_iPlayerPlace[iClient];
	}
	else return 0;
}

public int Native_LR_GetClientRank(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		return g_iClientData[iClient][1];
	}
	else return 0;
}

public int Native_LR_GetClientValue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		return g_iClientData[iClient][0];
	}
	else return 0;
}

public int Native_LR_GetClientStats(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iStats = GetNativeCell(2);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		int iParam;
		switch(iStats)
		{
			case 0: iParam = g_iClientData[iClient][2];
			case 1: iParam = g_iClientData[iClient][3];
			case 2: iParam = g_iClientData[iClient][4];
			case 3: iParam = g_iClientData[iClient][5];
			case 4: iParam = g_iClientData[iClient][6];
			case 5: iParam = g_iClientData[iClient][7];
		}
		return iParam;
	}
	else return 0;
}

public int Native_LR_SetClientVIP(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iTime = GetNativeCell(2);
	int iGroup = GetNativeCell(3);

	if(IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
	{
		g_iClientData[iClient][8] = iTime;
		g_iClientData[iClient][9] = iGroup;
		CheckRank(iClient);
		return true;
	}
	else return false;
}

public int Native_LR_DeleteClientVIP(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(IsValidClient(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
	{
		g_iClientData[iClient][8] = 0;
		CheckRank(iClient);
		return true;
	}
	else return false;
}

public int Native_LR_ChangeClientValue(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	int iValue = GetNativeCell(2);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		return SetExpEvent(iClient, iValue);
	}
	else return ThrowNativeError(SP_ERROR_NATIVE, "Levels Ranks: невалидный индекс игрока (%d)", iClient);
}

public int Native_LR_MenuInventory(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		InventoryMenu(iClient);
	}
}