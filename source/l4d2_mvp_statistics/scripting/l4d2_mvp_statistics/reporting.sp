#if defined _l4d2_mvp_statistics_reporting_included
    #endinput
#endif
#define _l4d2_mvp_statistics_reporting_included

void PrintMVPString()
{
    if (g_iBrevityFlags & BREV_RANK)
        PrintRank();

    char mvp_SI_name[64], mvp_Common_name[64], mvp_FF_name[64];
    int mvp_SI, mvp_Common,  mvp_FF = 0;
    bool bSI_bot, bCI_bot, bFF_bot = false;

    if (g_iBrevityFlags & BREV_SI)
        FindMVPName(1, mvp_SI_name, sizeof(mvp_SI_name), mvp_SI, bSI_bot);
    
    if (g_iBrevityFlags & BREV_CI)
        FindMVPName(2, mvp_Common_name, sizeof(mvp_Common_name), mvp_Common, bCI_bot);
    
    if (g_iBrevityFlags & BREV_FF)
        FindMVPName(3, mvp_FF_name, sizeof(mvp_FF_name), mvp_FF, bFF_bot);
    
    // report
    if (mvp_SI == 0 && mvp_Common == 0 && ((g_iBrevityFlags & BREV_SI) && (g_iBrevityFlags & BREV_CI)))
    {
        CPrintToChatAll("%t", "NotEnoughAction");
    }
    else
    {
        if (g_iBrevityFlags & BREV_SI)
        {
            if (mvp_SI > 0)
            {
                CPrintToChatAll("%t", "MVP_SI", bSI_bot ? "[BOT]" : mvp_SI_name, 
                                                g_Statistics[mvp_SI].m_iAllDamage, 
                                                (float(g_Statistics[mvp_SI].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, 
                                                g_Statistics[mvp_SI].m_iSIKills, 
                                                (float(g_Statistics[mvp_SI].m_iSIKills) / float(g_iTotalKills)) * 100);
            }
            else
            {
                CPrintToChatAll("%t", "MVP_SI_Nobody");
            }
        }
        
        if (g_iBrevityFlags & BREV_CI)
        {
            if (mvp_Common > 0)
            {
                CPrintToChatAll("%t", "MVP_CI", bCI_bot ? "[BOT]" : mvp_Common_name, 
                                                g_Statistics[mvp_Common].m_iCIKills, 
                                                (float(g_Statistics[mvp_Common].m_iCIKills) / float(g_iTotalCommon)) * 100);
            }
            else
            {
                CPrintToChatAll("%t", "MVP_CI_Nobody");
            }
        }
    }
    
    // FF
    if ((g_iBrevityFlags & BREV_FF))
    {
        if (mvp_FF == 0)
        {
            CPrintToChatAll("%t", "LVP_FF_Nobody");
        }
        else
        {
            CPrintToChatAll("%t", "LVP_FF", bFF_bot ? "[BOT]" : mvp_FF_name, 
                                            g_Statistics[mvp_FF].m_iFFDamage, 
                                            (float(g_Statistics[mvp_FF].m_iFFDamage) / float(g_iTotalFF)) * 100,
                                            g_Statistics[mvp_FF].m_iTICount, 
                                            g_Statistics[mvp_FF].m_iTKCount);
        }
    }
}

enum struct DataSet_t
{
    int index;
    int data;
}

void PrintRank()
{
    switch (g_hCvar_RankOrder.IntValue)
    {
        case 1:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                if (i <= 0 || i > MaxClients || !IsClientInGame(i))
                    continue;

                if (GetClientTeam(i) != L4D2Team_Survivor)
                    continue;

                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iSIKills;
                hArray.PushArray(data, sizeof(data));
            }

            int count = 0;
            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                count++;
                CPrintToChatAll("%t", "RankMessage", count, g_Statistics[client].m_szName, 
                                                            g_Statistics[client].m_iSIKills, 
                                                            g_Statistics[client].m_iSIDamage, 
                                                            g_Statistics[client].m_iCIKills, 
                                                            g_Statistics[client].m_iFFDamage, 
                                                            g_Statistics[client].m_iAllDamage, 
                                                            g_Statistics[client].m_iTICount, 
                                                            g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }

        case 2:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                if (i <= 0 || i > MaxClients || !IsClientInGame(i))
                    continue;

                if (GetClientTeam(i) != L4D2Team_Survivor)
                    continue;

                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iSIDamage;
                hArray.PushArray(data, sizeof(data));
            }

            int count = 0;
            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                count++;
                CPrintToChatAll("%t", "RankMessage", count, g_Statistics[client].m_szName, 
                                                            g_Statistics[client].m_iSIKills, 
                                                            g_Statistics[client].m_iSIDamage, 
                                                            g_Statistics[client].m_iCIKills, 
                                                            g_Statistics[client].m_iFFDamage, 
                                                            g_Statistics[client].m_iAllDamage, 
                                                            g_Statistics[client].m_iTICount, 
                                                            g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }

        case 3:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                if (i <= 0 || i > MaxClients || !IsClientInGame(i))
                    continue;

                if (GetClientTeam(i) != L4D2Team_Survivor)
                    continue;

                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iAllDamage;
                hArray.PushArray(data, sizeof(data));
            }

            int count = 0;
            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                count++;
                CPrintToChatAll("%t", "RankMessage_TotalOrder", count, g_Statistics[client].m_szName, 
                                                                        g_Statistics[client].m_iAllDamage, 
                                                                        g_Statistics[client].m_iSIKills, 
                                                                        g_Statistics[client].m_iSIDamage, 
                                                                        g_Statistics[client].m_iCIKills, 
                                                                        g_Statistics[client].m_iFFDamage, 
                                                                        g_Statistics[client].m_iTICount, 
                                                                        g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }
    }
}

void PrintLoserz(bool bSolo, int client)
{
    char tmpBuffer[1024];
    // also find the three non-mvp survivors and tell them they sucked
    // tell them they sucked with SI
    if (g_iTotalDamageAll > 0)
    {
        int mvp_SI = FindMVP(1);
        int mvp_SI_losers[3];
        mvp_SI_losers[0] = FindMVP(1, mvp_SI);                                           // second place
        mvp_SI_losers[1] = FindMVP(1, mvp_SI, mvp_SI_losers[0]);                         // third
        mvp_SI_losers[2] = FindMVP(1, mvp_SI, mvp_SI_losers[0], mvp_SI_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_SI_losers[i]) && !IsFakeClient(mvp_SI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_SI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankSI", client, (i + 2), g_Statistics[mvp_SI_losers[i]].m_iAllDamage, (float(g_Statistics[mvp_SI_losers[i]].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, g_Statistics[mvp_SI_losers[i]].m_iSIKills, (float(g_Statistics[mvp_SI_losers[i]].m_iSIKills) / float(g_iTotalKills)) * 100);
                        CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                    }
                }
                else 
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankSI", mvp_SI_losers[i], (i + 2), g_Statistics[mvp_SI_losers[i]].m_iAllDamage, (float(g_Statistics[mvp_SI_losers[i]].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, g_Statistics[mvp_SI_losers[i]].m_iSIKills, (float(g_Statistics[mvp_SI_losers[i]].m_iSIKills) / float(g_iTotalKills)) * 100);
                    CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they sucked with Common
    if (g_iTotalCommon > 0)
    {
        int mvp_CI = FindMVP(2);
        int mvp_CI_losers[3];
        mvp_CI_losers[0] = FindMVP(2, mvp_CI);                                           // second place
        mvp_CI_losers[1] = FindMVP(2, mvp_CI, mvp_CI_losers[0]);                         // third
        mvp_CI_losers[2] = FindMVP(2, mvp_CI, mvp_CI_losers[0], mvp_CI_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_CI_losers[i]) && !IsFakeClient(mvp_CI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_CI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankCI", client, (i + 2), g_Statistics[mvp_CI_losers[i]].m_iCIKills, (float(g_Statistics[mvp_CI_losers[i]].m_iCIKills) / float(g_iTotalCommon)) * 100);
                        CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankCI", mvp_CI_losers[i], (i + 2), g_Statistics[mvp_CI_losers[i]].m_iCIKills, (float(g_Statistics[mvp_CI_losers[i]].m_iCIKills) / float(g_iTotalCommon)) * 100);
                    CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they were better with FF (I know, I know, losers = winners)
    if (g_iTotalFF > 0)
    {
        int mvp_FF = FindMVP(3);
        int mvp_FF_losers[3];
        mvp_FF_losers[0] = FindMVP(3, mvp_FF);                                           // second place
        mvp_FF_losers[1] = FindMVP(3, mvp_FF, mvp_FF_losers[0]);                         // third
        mvp_FF_losers[2] = FindMVP(3, mvp_FF, mvp_FF_losers[0], mvp_FF_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_FF_losers[i]) &&  !IsFakeClient(mvp_FF_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_FF_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankFF", client, (i + 2), g_Statistics[mvp_FF_losers[i]].m_iFFDamage, (float(g_Statistics[mvp_FF_losers[i]].m_iFFDamage) / float(g_iTotalFF)) * 100);
                        CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankFF", mvp_FF_losers[i], (i + 2), g_Statistics[mvp_FF_losers[i]].m_iFFDamage, (float(g_Statistics[mvp_FF_losers[i]].m_iFFDamage) / float(g_iTotalFF)) * 100);
                    CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }    
}

static int ArraySortFunc(int index1, int index2, ArrayList array, Handle hndl)
{
    DataSet_t data1, data2;
    array.GetArray(index1, data1, sizeof(data1));
    array.GetArray(index2, data2, sizeof(data2));

    if (data1.data < data2.data)
    {
        return 1;
    }
    else if (data1.data > data2.data)
    {
        return -1;
    }
    else
    {
        return 0;
    }
}

static void FindMVPName(int type, char[] name, int maxlen, int &mvp, bool &bBot)
{
    mvp = FindMVP(type);
    if (mvp > 0)
    {
        if (IsClientConnected(mvp))
        {
            GetClientName(mvp, name, maxlen);
            if (IsFakeClient(mvp))
                bBot = true;
        } 
        else
        {
            strcopy(name, maxlen, g_Statistics[mvp].m_szName);
        }
    } 
}

static int FindMVP(int type, int excludeMeA = 0, int excludeMeB = 0, int excludeMeC = 0)
{
    int i, maxIndex = 0;
    switch (type)
    {
        case 1:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iAllDamage > g_Statistics[maxIndex].m_iAllDamage  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }

        case 2:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iCIKills > g_Statistics[maxIndex].m_iCIKills && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }

        case 3:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iFFDamage > g_Statistics[maxIndex].m_iFFDamage && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }
    }

    return maxIndex;
}

static stock int getSurvivor(int exclude[4])
{
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsSurvivor(i)) 
        {
            int tagged = false;
            // exclude already tagged survs
            for (int j = 0; j < 4; j++) 
            {
                if (exclude[j] == i) 
                    tagged = true;
            }

            if (!tagged)
                return i;
        }
    }

    return 0;
}