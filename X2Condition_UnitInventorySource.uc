class X2Condition_UnitInventorySource extends X2Condition_UnitInventory;

// Override
event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	return 'AA_Success';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Item RelevantItem;
	local XComGameState_Unit UnitState;
	local X2WeaponTemplate WeaponTemplate;

	UnitState = XComGameState_Unit(kSource);
	if (UnitState == none)
		return 'AA_NotAUnit';

	RelevantItem = UnitState.GetItemInSlot(RelevantSlot);
	if (RelevantItem != none)
		WeaponTemplate = X2WeaponTemplate(RelevantItem.GetMyTemplate());

	if (ExcludeWeaponCategory != '')
	{		
		if (WeaponTemplate != none && WeaponTemplate.WeaponCat == ExcludeWeaponCategory)
			return 'AA_WeaponIncompatible';
	}
	if (RequireWeaponCategory != '')
	{
		if (RelevantItem == none || X2WeaponTemplate(RelevantItem.GetMyTemplate()).WeaponCat != RequireWeaponCategory)
			return 'AA_WeaponIncompatible';
	}

	return 'AA_Success';
}