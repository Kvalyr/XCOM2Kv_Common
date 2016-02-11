class Kv_Common extends Object;

var(Kv_Common) Delegate<UpdateTemplateDelegate> UpdateFn;
var(Kv_Common) Delegate<GetTemplatesDelegate> GetTemplatesFn;
var(Kv_Common) Delegate<AllDifficultiesDelegate> AllDifficultiesFn;
var string WhichItemTemplatesToGet;
private delegate UpdateTemplateDelegate(X2DataTemplate Template);				// The delegate function that makes actual changes to a single template
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
static function bool UpdateTemplates(delegate<UpdateTemplateDelegate> TemplateUpdateFunc, delegate<GetTemplatesDelegate> GetTemplatesFunc)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	KvC.UpdateTemplateDelegate = TemplateUpdateFunc;
	KvC.GetTemplatesDelegate = GetTemplatesFunc;
	KvC.AllDifficultiesDelegate = _UpdateTemplates;
	return KvC._CallFunctionForAllDifficulties();
}

// Public
static function bool UpdateAllItemTemplatesOfType(string TemplateType, delegate<UpdateTemplateDelegate> TemplateUpdateFunc)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	
	KvC.UpdateTemplateDelegate = TemplateUpdateFunc;

	KvC.WhichItemTemplatesToGet = TemplateType;
	KvC.GetTemplatesDelegate = KvC._GetItemTemplatesByType;

	KvC.AllDifficultiesDelegate = KvC._UpdateTemplates;
	
	return KvC._CallFunctionForAllDifficulties();
}

// ================================================================================================================================
// Private stuff below here
// ================================================================================================================================

private function array<X2DataTemplate> _GetItemTemplatesByType()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> Templates;
	local array<X2ItemTemplate> ItemTemplates;

	//`log("^*^*^*^*^*^*^^__+_+_+_+_+_+_+_+_+_+__^*^*^*^*^*^*^*^*^*^_+_+_+_+_+_ _GetItemTemplatesByType()" @ " ' " @ UpdateTemplateDelegate @ " ' " @ WhichItemTemplatesToGet @ " ' " @ GetTemplatesDelegate @ "'" );

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
			//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _GetItemTemplatesByType() No match:" @ WhichItemTemplatesToGet);
			break;
	}
	//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _GetItemTemplatesByType() length:" @ Templates.Length);
	return Templates;
}

private function bool _CallFunctionForAllDifficulties()
{
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local XComGameState_CampaignSettings Settings;
    local XComGameStateHistory History;

	//`log("^*^*^*^*^*^*^^__+_+_+_+_+_+_+_+_+_+__^*^*^*^*^*^*^*^*^*^_+_+_+_+_+_ _CallFunctionForAllDifficulties()" @ " ' " @ UpdateTemplateDelegate @ " ' " @ WhichItemTemplatesToGet @ " ' " @ GetTemplatesDelegate @ "'" @ AllDifficultiesDelegate  @ "'" );
	
	History = `XCOMHISTORY;
    Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(Settings != none)
	{
		OriginalDifficulty = Settings.DifficultySetting;
		OriginalLowestDifficulty = Settings.LowestDifficultySetting;

		for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
		{
			//Z// Set difficulty temporarily
			Settings.SetDifficulty(DifficultyIndex, true);

			//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _CallFunctionForAllDifficulties Iteration::" @ DifficultyIndex);
			//`log("^*^*^*^*^*^*^*^*^*^_+_+_+_+_+ _CallFunctionForAllDifficulties()" @ " ' " @ UpdateTemplateDelegate @ " ' " @ WhichItemTemplatesToGet @ " ' " @ GetTemplatesDelegate @ "'" );
			AllDifficultiesDelegate();
		}
		//Z//Restore difficulty values
		Settings.SetDifficulty(OriginalLowestDifficulty, true);
		Settings.SetDifficulty(OriginalDifficulty, false);
		return true;
	}
	return false;

	//return AllDifficultiesDelegate();

	
}


private function bool _UpdateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Template;
	local int TemplateIndex;

	//`log("^*^*^*^*^*^*^*^*^*^_+_+_+_+_+_ _UpdateTemplates()" @ " ' " @ UpdateTemplateDelegate @ " ' " @ WhichItemTemplatesToGet @ " ' " @ GetTemplatesDelegate @ "'" );

	// Call GetTemplatesDelegate to get an array of templates to update
	
	if (GetTemplatesDelegate != none)
	{
		//`log("!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!£!££! _UpdateTemplates -- GetTemplatesDelegate is NOT none!");
		//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _UpdateTemplates -- WhichItemTemplatesToGet:" @ WhichItemTemplatesToGet);
		Templates = GetTemplatesDelegate();
	}
	else
	{
		//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _UpdateTemplates -- GetTemplatesDelegate is none!");
		//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _UpdateTemplates -- WhichItemTemplatesToGet:" @ WhichItemTemplatesToGet);
	}

	//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% _UpdateTemplates. Length: " @ Templates.Length);

	// For each template, pass it to UpdateTemplateDelegate to make whatever changes are necessary
	for(TemplateIndex = 0; TemplateIndex < Templates.Length; ++TemplateIndex)
	{
		Template = Templates[TemplateIndex];
		if(Template != none)
			//`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% Calling UpdateTemplateDelegate()...");
			UpdateTemplateDelegate(Template);
	}

	return true;
}