//---------------------------------------------------------------------------------------
//  FILE:    Kv_Common.uc
//  AUTHOR:  Kvalyr
//           
//---------------------------------------------------------------------------------------
//	This file is an attempt to provide some common, reusable code for XCOM2 mods, particularly in the area of template modification.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016-2018 Kvalyr. All Rights Reserved.
//---------------------------------------------------------------------------------------
class Kv_Common extends Object;

var(Kv_Common) Delegate<UpdateTemplateDelegate> UpdateFn;
var(Kv_Common) Delegate<GetTemplatesDelegate> GetTemplatesFn;
var(Kv_Common) Delegate<AllDifficultiesDelegate> AllDifficultiesFn;
var string WhichItemTemplatesToGet;
var private array<X2DataTemplate> FallbackTemplates;															// For calling UpdateTemplates with an array of templates instead of a delegate that returns an array

private delegate bool UpdateTemplateDelegate(X2DataTemplate Template);											// The delegate function that makes actual changes to a single template
private delegate array<X2DataTemplate> GetTemplatesDelegate();													// The delegate function that retrieves an array of templates to work on
private delegate bool AllDifficultiesDelegate();																// The delegate function that gets called for every difficulty

// ================================================================================================================================
// Public methods - Math
// ================================================================================================================================
static function int RoundToMultiple(int num, int multiple)
{
	local int remainder;
	remainder = Abs(num) % multiple;

	if(multiple == 0 || remainder == 0)
	{
		return num;
	}
	return num + multiple - remainder;
}


// Round to multiple A if above a given threshold, else round to multipleB
static function int RoundToMultipleConditional(int num, optional int multipleA=5, optional int multipleB=1, optional int threshold=5)
{
	if(num >= threshold)
		return RoundToMultiple(num, multipleA);
	else
		return RoundToMultiple(num, multipleB);
}

static function float ceil(float num)
{
	return float(int(num + 0.5));
}

// ================================================================================================================================
// Public methods - Managers and Screen Listeners
// ================================================================================================================================

static function Log(string LogString)
{
	`log("= = = = = = = = = = = = = = = = KvC: " @ LogString);
}

/*
// Get the instance of our KvC manager
static function Kv_C_Manager GetManager(optional UIScreenListener ScreenListener)
{
	return class'Kv_C_Manager'.static.GetOrCreateManager(ScreenListener);
}

// Create a reference to a UIScreenListener that we can access via our manager
static function int StoreListener(UIScreenListener ScreenListener)
{	
	GetManager(ScreenListener);	// Now this manager can be fetched from the screenstack and contains a reference to this UIScreenListener for reuse
	return 0;
}
*/


// ================================================================================================================================
// Public methods - Templates
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

	return KvC._UpdateTemplatesWithDelegate();
}

// Public
static function bool UpdateTemplatesFromArray(delegate<UpdateTemplateDelegate> TemplateUpdateFunc, array<X2DataTemplate> Templates, optional bool NoDifficulties)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	//KvC.UpdateTemplateDelegate = TemplateUpdateFunc;

	`KvCLog("UpdateTemplatesFromArray --- Templates.Length:" @ Templates.Length);

	KvC.FallbackTemplates = Templates;

	`KvCLog("UpdateTemplatesFromArray --- KvC.FallbackTemplates.Length:" @ KvC.FallbackTemplates.Length);

	return KvC._UpdateTemplatesWithDelegate();
}

// Public
static function bool UpdateAllItemTemplatesOfType(string TemplateType, delegate<UpdateTemplateDelegate> TemplateUpdateFunc, optional bool NoDifficulties)
{
	local Kv_Common KvC;
	KvC = new class'Kv_Common';
	
	KvC.UpdateTemplateDelegate = TemplateUpdateFunc;

	KvC.WhichItemTemplatesToGet = TemplateType;
	KvC.GetTemplatesDelegate = KvC._GetItemTemplatesByType;

	return KvC._UpdateTemplatesWithDelegate();
}

// ================================================================================================================================
// Template Resource Costs
// ================================================================================================================================
static function bool GetResourceCostFromItemTemplateByName(X2ItemTemplate ItemTemplate, name ResourceTemplateName, out ArtifactCost ExistingResource, out int ExistingResourceIndex, optional bool bArtifactCost)
{
	local int i;
	local array<ArtifactCost> ArrayToSearch;

	if(bArtifactCost)
		ArrayToSearch = ItemTemplate.Cost.ArtifactCosts;
	else
		ArrayToSearch = ItemTemplate.Cost.ResourceCosts;

	// Try to find an existing resource with same DataName
	for(i = 0; i < ArrayToSearch.Length; ++i)
	{
		if(ArrayToSearch[i].ItemTemplateName == ResourceTemplateName)
		{	
			ExistingResource = ArrayToSearch[i];
			ExistingResourceIndex = i;
			return true;
		}
	}	
	return false;
}

static function UpdateAllExistingResources(X2ItemTemplate ItemTemplate, optional int quantity=-1, optional float multiplier=-1.0f, optional bool bArtifactCost)
{
	local int i;
	local ArtifactCost ExistingResource;
	local array<ArtifactCost> ArrayToSearch;

	if(bArtifactCost)
		ArrayToSearch = ItemTemplate.Cost.ArtifactCosts;
	else
		ArrayToSearch = ItemTemplate.Cost.ResourceCosts;

	for(i = 0; i < ArrayToSearch.Length; ++i)
	{
		ExistingResource = ArrayToSearch[i];
		if(ExistingResource.ItemTemplateName != '')
		{
			//`KvCLog("__++__++__++__ UpdateAllExistingResources() BEFORE: " @ ItemTemplate.DataName @ " - Resource cost: " @ ArrayToSearch[i].ItemTemplateName @ " : " @ ArrayToSearch[i].Quantity);
			UpdateOrCreateResourceCost(ItemTemplate, '', quantity, multiplier, bArtifactCost, ExistingResource, i);
			//`KvCLog("__++__++__++__ UpdateAllExistingResources() AFTER: " @ ItemTemplate.DataName @ " - Resource cost: " @ ArrayToSearch[i].ItemTemplateName @ " : " @ ArrayToSearch[i].Quantity);
		}
	}
}

static function UpdateOrCreateResourceCost(X2ItemTemplate ItemTemplate, name ResourceTemplateName, optional int quantity=-1, optional float multiplier=-1.0f, optional bool bArtifactCost, optional ArtifactCost ExistingResource, optional int ExistingResourceIndex=-1, optional bool bNoRounding)
{
	//local int i;
	local float NewQuantity;
	local ArtifactCost NewResource;
	//local array<ArtifactCost> ArrayToSearch;
	local bool ResourceFoundOnTemplate;

	local bool bQuantity, bMultiplier;
	bQuantity = (quantity >= 0);
	bMultiplier = (multiplier >= 0.0f);

	// Return early if there's nothing to update or if values are invalid (negative)
	if( !(bQuantity || bMultiplier) )
		return;

	/*
	//`KvCLog("__++__++__++__ UpdateOrCreateResourceCost() Item: " @ ItemTemplate.DataName @ " -- bQuantity: " @ bQuantity @ " : " @ quantity @ " - bMultiplier: " @ bMultiplier @ " : " @ multiplier);
	if(bArtifactCost)
		ArrayToSearch = ItemTemplate.Cost.ArtifactCosts;
	else
		ArrayToSearch = ItemTemplate.Cost.ResourceCosts;
	*/

	if(ExistingResource.ItemTemplateName != '' && ExistingResourceIndex >= 0) // Don't search if we don't need to (if we know the resource exists)
	{
		ResourceTemplateName = ExistingResource.ItemTemplateName;
		ResourceFoundOnTemplate = true;
	}
	else
	{
		ResourceFoundOnTemplate = GetResourceCostFromItemTemplateByName(ItemTemplate, ResourceTemplateName, ExistingResource, ExistingResourceIndex, bArtifactCost);
	}

	if(!ResourceFoundOnTemplate)	// No pre-existing resource found - Add a new resource with the specified quantity
	{
		// Return early if quantity isn't specified - Can't apply multiplier without an existing resource
		if(!bQuantity)
			return;

		NewResource.ItemTemplateName = ResourceTemplateName;
		if(!bNoRounding)
			NewResource.Quantity = RoundToMultipleConditional(quantity);
		else
			NewResource.Quantity = quantity;
		
		// Don't add new resources with quantity == 0
		if(NewResource.Quantity > 0)
		{
			if(bArtifactCost)
				ItemTemplate.Cost.ArtifactCosts.AddItem(NewResource);
			else
				ItemTemplate.Cost.ResourceCosts.AddItem(NewResource);
		}
		//return NewResource;
	}
	else	// Resource already exists, update its quantity appropriately
	{
		`KvCLog("*_*_*_*_*_*_*__ Old quantity: " @ ExistingResource.Quantity);
		if(bQuantity)	// Quantity takes precedence over multiplier - Don't do both
		{
			NewQuantity = quantity;
		}
		else
		{
			NewQuantity = ExistingResource.Quantity;
			//`KvCLog("*_*_*_*_*_*_*__ NewQuantity simple: " @ NewQuantity);
			NewQuantity = float(ExistingResource.Quantity) * multiplier;
			//`KvCLog("*_*_*_*_*_*_*__ NewQuantity after multi: " @ NewQuantity);
			NewQuantity = ceil(NewQuantity);
			//`KvCLog("*_*_*_*_*_*_*__ NewQuantity after ceil: " @ NewQuantity);
			if(!bNoRounding)
			{
				NewQuantity = RoundToMultipleConditional(int(NewQuantity));
				//`KvCLog("*_*_*_*_*_*_*__ NewQuantity after rounding: " @ NewQuantity);
			}
			if(NewQuantity <= 0 && multiplier > 0)
			{
				NewQuantity = 1;
				//`KvCLog("*_*_*_*_*_*_*__ NewQuantity after clamping: " @ NewQuantity);
			}
		}

		ExistingResource.Quantity = int(NewQuantity);
		//`KvCLog("*_*_*_*_*_*_*__ NewQuantity on object: " @ ExistingResource.Quantity);

		if(bArtifactCost)
			ItemTemplate.Cost.ArtifactCosts[ExistingResourceIndex] = ExistingResource;
		else
			ItemTemplate.Cost.ResourceCosts[ExistingResourceIndex] = ExistingResource;
	}
}


// ================================================================================================================================
// Private stuff below here
// ================================================================================================================================

// Returns an X2DataTemplates array of item templates. Class.WhichItemTemplatesToGet must be set beforehand.
private function array<X2DataTemplate> _GetItemTemplatesByType()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> Templates;//, FilteredTemplates;
	local X2DataTemplate Template;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2GrenadeTemplate GrenadeTemplate;
	local X2QuestItemTemplate QuestItemTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local X2AmmoTemplate AmmoTemplate;

	//local int ForIndex_i;

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
		case ("equipment"):
			foreach ItemTemplateManager.IterateTemplates(Template, none)
			{
				EquipmentTemplate = X2EquipmentTemplate(Template);
				if(EquipmentTemplate != none)
					Templates.AddItem(EquipmentTemplate);
			}
			break;
		case ("grenade"):
		case ("grenades"):
			foreach ItemTemplateManager.IterateTemplates(Template, none)
			{
				GrenadeTemplate = X2GrenadeTemplate(Template);
				if(GrenadeTemplate != none)
					Templates.AddItem(GrenadeTemplate);
			}
			break;
		case ("quest"):
		case ("questitem"):
			foreach ItemTemplateManager.IterateTemplates(Template, none)
			{
				QuestItemTemplate = X2QuestItemTemplate(Template);
				if(QuestItemTemplate != none)
					Templates.AddItem(QuestItemTemplate);
			}
			break;
		case ("weaponupgrade"):
			foreach ItemTemplateManager.IterateTemplates(Template, none)
			{
				WeaponUpgradeTemplate = X2WeaponUpgradeTemplate(Template);
				if(WeaponUpgradeTemplate != none)
					Templates.AddItem(WeaponUpgradeTemplate);
			}
			break;
		case ("ammo"):
			foreach ItemTemplateManager.IterateTemplates(Template, none)
			{
				AmmoTemplate = X2AmmoTemplate(Template);
				if(AmmoTemplate != none)
					Templates.AddItem(AmmoTemplate);
			}
			break;
		default:
			break;
	}
	return Templates;
}


/*	
// Calls a function once for each difficulty setting in the game. Useful for updating templates with difficulty variants.
// Shouldn't be necessary when using OnPostTemplatesCreated() in X2DLCInfo
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
			// Function signature seems to have changed in WotC:
			//SetDifficulty(
				//int NewDifficulty, 
				//optional float NewTacticalDifficulty = -1, 
				//optional float NewStrategyDifficulty = -1, 
				//optional float NewGameLength = -1, 
				//optional bool IsPlayingGame = false, 
				//optional bool InitialDifficultyUpdate = false
			//)
			Settings.SetDifficulty(DifficultyIndex, , , , , true);

			//`log("_+_+_+_+_+_+_+_+_+_+_+_+ _CallDelegateFunctionForAllDifficulties() calling AllDifficultiesDelegate(). Iteration:" @ DifficultyIndex);
			success = AllDifficultiesDelegate();
		}
		//Z//Restore difficulty values
		Settings.SetDifficulty(OriginalLowestDifficulty, , , , , true);
		Settings.SetDifficulty(OriginalDifficulty, , , , , false);
		return success;
	}

	return false;
}
*/

// Updates all templates in an array using the UpdateTemplateDelegate function.
// UpdateTemplateDelegate and GetTemplatesDelegate must be set beforehand.
private function bool _UpdateTemplatesWithDelegate()
{
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Template, Variant;
	local int TemplateIndex;



	local X2ItemTemplateManager ItemManager;
	local array<X2DataTemplate> DifficultyVariants;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Call GetTemplatesDelegate to get an array of templates to update
	if (GetTemplatesDelegate != none)
		Templates = GetTemplatesDelegate();
	else
		Templates = FallbackTemplates;
		//`log("KvC: _+_+_+_+_+_+_+_+_+_+_+_+ GetTemplatesDelegate IS NONE. Using FallbackTemplates: " @ FallbackTemplates.Length);

	if (Templates.Length > 0)
	{
		// For each template, pass it to UpdateTemplateDelegate to make whatever changes are necessary
		for(TemplateIndex = 0; TemplateIndex < Templates.Length; ++TemplateIndex)
		{
			Template = Templates[TemplateIndex];
			ItemManager.FindDataTemplateAllDifficulties(Template.DataName, DifficultyVariants);   
			foreach DifficultyVariants(Variant)
			{
				UpdateTemplateDelegate(Variant);
			}
		}
		return true;
	}
	else
		`log("KvC: _+_+_+_+_+_+_+_+_+_+_+_+ Kv_Common _UpdateTemplatesWithDelegate() received empty templates array.");

	return false;
}
