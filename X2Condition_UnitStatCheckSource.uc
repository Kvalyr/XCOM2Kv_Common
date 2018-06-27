//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitStatCheck.uc
//  AUTHOR:  Timothy Talley
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016-2018 Kvalyr. All Rights Reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitStatCheckSource extends X2Condition_UnitStatCheck;

/* //Z// Inherited
struct CheckStat
{
	var ECharStatType   StatType;
	var CheckConfig     ConfigValue;
	var bool            bCheckAsPercent;
};
var array<CheckStat> m_aCheckStats;

function AddCheckStat(ECharStatType StatType, int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0, optional bool bCheckAsPercent=false)
{
	local CheckStat AddStat;
	AddStat.StatType = StatType;
	AddStat.ConfigValue.CheckType = CheckType;
	AddStat.ConfigValue.Value = Value;
	AddStat.ConfigValue.ValueMin = ValueMin;
	AddStat.ConfigValue.ValueMax = ValueMax;
	AddStat.bCheckAsPercent = bCheckAsPercent;
	m_aCheckStats.AddItem(AddStat);
}
*/

//Override
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit UnitState;
	local name RetCode;
	local int StatValue, i;

	RetCode = 'AA_Success';
	UnitState = XComGameState_Unit(kSource);
	if (UnitState != none)
	{
		
		for (i = 0; (i < m_aCheckStats.Length) && (RetCode == 'AA_Success'); ++i)
		{
			if (m_aCheckStats[i].bCheckAsPercent)
			{
				// Check this value as a percentage of the max
				StatValue = 100 * (UnitState.GetCurrentStat(m_aCheckStats[i].StatType) / UnitState.GetMaxStat(m_aCheckStats[i].StatType));
			}
			else
			{
				StatValue = UnitState.GetCurrentStat(m_aCheckStats[i].StatType);
			}

			RetCode = PerformValueCheck(StatValue, m_aCheckStats[i].ConfigValue);
		}
		`log(")()()()(_)(_+_)(_)(_)(+_)(+_)(+_)(_+*) CallMeetsConditionWithSource() Unit: " @ UnitState.GetName(eNameType_FullNick) @ " - RetCode: " @ RetCode);
	}
	return RetCode;
}

// Override
event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	return 'AA_Success';
}