class Kv_Common extends Object;

var(Kv_Common) Delegate<TemplateUpdateDelegate> UpdateFn;
var(Kv_Common) Delegate<GetTemplatesDelegate> GetTemplatesFn;
delegate TemplateUpdateDelegate(X2ItemTemplate Template);				// The delegate function that makes actual changes to a single template
delegate GetTemplatesDelegate(out array<X2DataTemplate> Templates);		// The delegate function that retrieves an array of templates to work on


static function bool UpdateTemplatesByType(string WhichTemplates, delegate<TemplateUpdateDelegate> UpdateFunc)
{
	local Kv_Common KvC;
	local bool success;
	KvC = new class'Kv_Common';
	KvC.TemplateUpdateDelegate = UpdateFunc;
	success = KvC.UpdateAllTemplatesForAllDifficultiesOfType(WhichTemplates);
	return success;
}


static function array<X2ItemTemplate> GetItemTemplatesByType(string WhichTemplates)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2ItemTemplate> Templates;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	switch(WhichTemplates)
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
			`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% GetItemTemplatesByType() No match:" @ WhichTemplates);
			break;
	}
	return Templates;
}


private function bool UpdateAllTemplatesForAllDifficultiesOfType(string WhichTemplates)
{
	local array<X2ItemTemplate> Templates;
	local X2ItemTemplate Template;
	local int TemplateIndex;
	
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local XComGameState_CampaignSettings Settings;
    local XComGameStateHistory History;

	History = `XCOMHISTORY;
    Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
    OriginalDifficulty = Settings.DifficultySetting;
    OriginalLowestDifficulty = Settings.LowestDifficultySetting;

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
    {
		//Z// Set difficulty temporarily
        Settings.SetDifficulty(DifficultyIndex, true);

		Templates = GetItemTemplatesByType(WhichTemplates);

		// For each template, pass it to TemplateUpdateDelegate to make whatever changes are necessary
		for(TemplateIndex = 0; TemplateIndex < Templates.Length; ++TemplateIndex)
		{
			Template = Templates[TemplateIndex];
			if(Template != none)
				TemplateUpdateDelegate(Template);
		}
	}
	//Z//Restore difficulty values
	Settings.SetDifficulty(OriginalLowestDifficulty, true);
    Settings.SetDifficulty(OriginalDifficulty, false);

	/*
	Templates = GetItemTemplatesByType(WhichTemplates);
	`log("^&%^%&^&%^&^%&^%&^$&^$^&%^&$^&%&$&^%*&^$*&^^%^% UpdateAllTemplatesForAllDifficultiesOfType() Templates.Length:" @ Templates.Length);
	// For each template, pass it to TemplateUpdateDelegate to make whatever changes are necessary
	for(TemplateIndex = 0; TemplateIndex < Templates.Length; ++TemplateIndex)
	{
		Template = Templates[TemplateIndex];
		if(Template != none)
			TemplateUpdateDelegate(Template);
	}
	*/
	return true;
}