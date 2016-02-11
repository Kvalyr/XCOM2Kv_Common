//---------------------------------------------------------------------------------------
//  FILE:    Kv_Common.uc
//  AUTHOR:  Kvalyr
//           
//---------------------------------------------------------------------------------------
//	This file is an attempt to provide some common, reusable code for XCOM2 mods, particularly in the area of template modification.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Robert Voigt. All Rights Reserved.
//  Stating ARR above to prevent someone else using this in a paid-for mod.
//	I'm otherwise open to people using my code as long as they contact me first via Steam or NexusMods, just for the above reason!
//
//	Credit and thanks to Amineri and the others at Long War Studios for spearheading XCOM modding and showing the rest of us how it's done.
//---------------------------------------------------------------------------------------
class Kv_Common extends Object;

var(Kv_Common) Delegate<UpdateTemplateDelegate> UpdateFn;
var(Kv_Common) Delegate<GetTemplatesDelegate> GetTemplatesFn;
var(Kv_Common) Delegate<AllDifficultiesDelegate> AllDifficultiesFn;
var string WhichItemTemplatesToGet;
private delegate bool UpdateTemplateDelegate(X2DataTemplate Template);				// The delegate function that makes actual changes to a single template
private delegate array<X2DataTemplate> GetTemplatesDelegate();					// The delegate function that retrieves an array of templates to work on
private delegate bool AllDifficultiesDelegate();								// The delegate function that gets called for every difficulty

// ================================================================================================================================
// Public methods
// ================================================================================================================================

static function array<X2ItemTemplate> GetItemTemplatesByType(string TemplateType)
{
	// Public Wrapper for _GetItemTemplatesByType()
	local Kv_Common KvC;
	local array<X2DataTemplate> Templates;
	local array<X2ItemTemplate> ItemTemplates;
	local int i;
	KvC = new class'Kv_Common';
	KvC.WhichItemTemplatesToGet = TemplateType;
	Templates = KvC._GetItemTemplatesByType();

	// Typecast each of the templates from X2DataTemplate to X2ItemTemplate. This is kludgy..
	if(Templates.Length > 0)
	{
		for(i = 0; i < Templates.Length; ++i)
		{
			ItemTemplates.AddItem( X2ItemTemplate(Templates[i]) );
		}
	}

	return ItemTemplates;

}

// Public
static function bool UpdateTemplates(delegate<UpdateTemplateDelegate> TemplateUpdateFunc, delegate<GetTemplatesDelegate> GetTemplatesFunc, optional bool NoDifficulties)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	KvC.UpdateTemplateDelegate = TemplateUpdateFunc;
	KvC.GetTemplatesDelegate = GetTemplatesFunc;
	if(!NoDifficulties)
	{
		KvC.AllDifficultiesDelegate =  KvC._UpdateTemplatesWithDelegate;
		return KvC._CallDelegateFunctionForAllDifficulties();
	}
	else
	{
		return KvC._UpdateTemplatesWithDelegate();
	}
}

// Public
static function bool UpdateAllItemTemplatesOfType(string TemplateType, delegate<UpdateTemplateDelegate> TemplateUpdateFunc, optional bool NoDifficulties)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	
	KvC.UpdateTemplateDelegate = TemplateUpdateFunc;

	KvC.WhichItemTemplatesToGet = TemplateType;
	KvC.GetTemplatesDelegate = KvC._GetItemTemplatesByType;
		
	if(!NoDifficulties)
	{
		KvC.AllDifficultiesDelegate =  KvC._UpdateTemplatesWithDelegate;
		return KvC._CallDelegateFunctionForAllDifficulties();
	}
	else
	{
		return KvC._UpdateTemplatesWithDelegate();
	}
}

// ================================================================================================================================
// Private stuff below here
// ================================================================================================================================

// Returns an X2DataTemplates array of item templates. Class.WhichItemTemplatesToGet must be set beforehand.
private function array<X2DataTemplate> _GetItemTemplatesByType()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> Templates;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	switch(WhichItemTemplatesToGet)
	{
		case ("armor"):
		case ("armors"):
			Templates = ItemTemplateManager.GetAllArmorTemplates();
			break;
		case ("weapon"):
		case ("weapons"):
			Templates = ItemTemplateManager.GetAllWeaponTemplates();
			break;
		case ("schematic"):
		case ("schematics"):
			Templates = ItemTemplateManager.GetAllSchematicTemplates();
			break;
		case ("upgrade"):
		case ("upgrades"):
			Templates = ItemTemplateManager.GetAllUpgradeTemplates();
			break;

		default:
			break;
	}
	return Templates;
}

// Calls a function once for each difficulty setting in the game. Useful for updating templates with difficulty variants.
private function bool _CallDelegateFunctionForAllDifficulties()
{
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local XComGameState_CampaignSettings Settings;
    local XComGameStateHistory History;
	local bool success;
	
	History = `XCOMHISTORY;
    Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(Settings != none)
	{
		OriginalDifficulty = Settings.DifficultySetting;
		OriginalLowestDifficulty = Settings.LowestDifficultySetting;

		for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
		{
			//Z// We only really care about the last call to AllDifficultiesDelegate() since we want ALL calls to return true to count as success
			success = false; 
			
			//Z// Set difficulty temporarily
			Settings.SetDifficulty(DifficultyIndex, true);

			success = AllDifficultiesDelegate();
		}
		//Z//Restore difficulty values
		Settings.SetDifficulty(OriginalLowestDifficulty, true);
		Settings.SetDifficulty(OriginalDifficulty, false);
		return success;
	}
	return false;
}

// Updates all templates in an array using the UpdateTemplateDelegate function.
// UpdateTemplateDelegate and GetTemplatesDelegate must be set beforehand.
private function bool _UpdateTemplatesWithDelegate()
{
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Template;
	local int TemplateIndex;

	// Call GetTemplatesDelegate to get an array of templates to update
	if (GetTemplatesDelegate != none)
		Templates = GetTemplatesDelegate();
	else
		`log("_+_+_+_+_+_+_+_+_+_+_+_+ GetTemplatesDelegate IS NONE.");

	if (Templates.Length > 0)
	{
		// For each template, pass it to UpdateTemplateDelegate to make whatever changes are necessary
		for(TemplateIndex = 0; TemplateIndex < Templates.Length; ++TemplateIndex)
		{
			Template = Templates[TemplateIndex];
			if(Template != none)
				UpdateTemplateDelegate(Template);
		}
		return true;
	}
	else
	{
		`log("_+_+_+_+_+_+_+_+_+_+_+_+ Kv_Common _UpdateTemplatesWithDelegate() received empty templates array.");
	}
	return false;
}