//---------------------------------------------------------------------------------------
//  FILE:    UIMPShell_MainMenuuc
//  AUTHOR:  Kvalyr
//  PURPOSE: This screenlistener pushes an instance of our common code manager as UIScreen to the screenstack for global access
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016-2018 Kvalyr. All Rights Reserved.
//---------------------------------------------------------------------------------------
class Kv_C_ScreenListener extends UIScreenListener;

/*
// Inherited
var class<UIScreen> ScreenClass;

var private bool ListenerSet;
var Kv_C_Manager KvCM;

var(self) private array<delegate <ListenerCallback> > ListenerCallbacks;
var private array<bool> RepeatBools;
var private array<bool> OnInitBools;
var private array<bool> OnReceiveFocusBools;
var private array<bool> OnLoseFocusBools;
var private array<bool> OnRemovedBools;

var private array<bool> DoOnceBools; // 0 = OnInit, 1=OnFocusReceived, 2=OnFocusLost, 3=OnRemoved
var private array<string> EventStrings;	// 0 = OnInit, 1=OnFocusReceived, 2=OnFocusLost, 3=OnRemoved

// ========================================
// End of Vars
// ========================================================================================

delegate bool ListenerCallback();

// Create a reference to this object on a UIScreen that can be fetched from the ScreenStack globally
function SetupGlobalManager()
{
	if(!ListenerSet)
	{
		KvCM = `XCOMGAME.spawn( class'Kv_C_Manager' );
		KvCM.SetListener(self); // Now this manager can be fetched from the screenstack and contains a reference to this UIScreenListener for reuse
		ListenerSet = true;
	}
}

function SetScreenClass(class<UIScreen> Screen)
{
	ScreenClass = Screen;
}

// ========================================================================================
// Misc private/helper junk
// ========================================================================================

private function bool GetDoOnceForEvent(string EventString)
{
	local int i;
	i = EventStringToIndex(EventString);
	if(i > -1)
	{
		return DoOnceBools[i];
	}
	return false;
}

private function UpdateDoOnceForEvent(string EventString)
{
	local int i;
	i = EventStringToIndex(EventString);
	if(i > -1)
	{
		DoOnceBools[i] = true;
	}
}

private function int EventStringToIndex(string EventString)
{
	return EventStrings.Find(EventString);
}



static function Log(string LogString)
{
	`log("= = = = KvC: " @ LogString);
}

// ========================================================================================
// Callbacks
// ========================================================================================

function int AddCallback(delegate<ListenerCallback> CallbackFn, optional bool OnInit=true, optional bool OnReceiveFocus=false, optional bool OnLoseFocus=false, optional bool OnRemoved=false, optional bool Repeat=false)
{
	local int i;
	i = ListenerCallbacks.Length;

	ListenerCallbacks.AddItem(CallbackFn);
	OnInitBools[i] = OnInit;
	OnReceiveFocusBools[i] = OnReceiveFocus;
	OnLoseFocusBools[i] = OnLoseFocus;
	OnRemovedBools[i] = OnRemoved;
	RepeatBools[i] = Repeat;

	return i;	// Return index of new callback
}

function int AddRepeatingCallback(delegate<ListenerCallback> Callback, optional bool OnInit=true, optional bool OnReceiveFocus=false, optional bool OnLoseFocus=false, optional bool OnRemoved=false)
{
	return AddCallback(Callback, OnInit, OnReceiveFocus, OnLoseFocus, OnRemoved, true);
}

function bool RemoveCallback(int CallbackIndex)
{
	ListenerCallbacks.Remove(CallbackIndex, 1);
	OnInitBools.Remove(CallbackIndex, 1);
	OnReceiveFocusBools.Remove(CallbackIndex, 1);
	OnLoseFocusBools.Remove(CallbackIndex, 1);
	OnRemovedBools.Remove(CallbackIndex, 1);
	RepeatBools.Remove(CallbackIndex, 1);

	return true;
}

private function bool GetEventBoolFromString(int i, string EventString)
{
	switch(EventString)
	{
		case ("OnInit"):
			return OnInitBools[i];
			break;
		case ("OnReceiveFocus"):
			return OnReceiveFocusBools[i];
			break;
		case ("OnLoseFocus"):
			return OnLoseFocusBools[i];
			break;
		case ("OnRemoved"):
			return OnRemovedBools[i];
			break;
	}
	return false;
}

private function ProcessCallbacksForEvent(string EventString)
{
	local int i;
	local bool Success;

	Log("+_+_+_+_+_ ProcessCallbacksForEvent() EventString: " @ EventString @ " - Screen: " @ ScreenClass @ " - Self: " @ self);
	
	// Once-off callbacks
    if(!GetDoOnceForEvent(EventString))
	{
		for(i = 0; i < ListenerCallbacks.Length; ++i)
		{
			if(!RepeatBools[i] && GetEventBoolFromString(i, EventString))
			{
				//Success = ListenerCallbacks[i]();
				ListenerCallback = ListenerCallbacks[i];
				Success = ListenerCallback();
				Log("+_+_+_+_+_ ProcessCallbacksForEvent() ListenerCallback: " @ ListenerCallback @ " - Success: " @ Success);
				if(Success)
				{
					RemoveCallback(i);	// Remove DoOnce callbacks after success
				}
				else
				{
					`redscreen("Callback for ScreenListener on screen " @ ScreenClass @ "failed:" @ ListenerCallback);
					Log("Callback for ScreenListener on screen " @ ScreenClass @ "failed:" @ ListenerCallback);
				}
				ListenerCallback = None; // Reset the class-level delegate (ugh)
			}
		}
		UpdateDoOnceForEvent(EventString);
	}
	
	// Repeating callbacks
	for(i = 0; i < ListenerCallbacks.Length; ++i)
	{
		if(RepeatBools[i] && GetEventBoolFromString(i, EventString))
		{
			ListenerCallback = ListenerCallbacks[i];
			Success = ListenerCallback();
			Log("+_+_+_+_+_ ProcessCallbacksForEvent() Repeating ListenerCallback: " @ ListenerCallback @ " - Success: " @ Success);
			if(!Success)
			{	
				// Setting up a repeating callback for something that might fail at the main menu but succeed elsewhere is probably a reasonable use case
				Log("Repeating Callback for ScreenListener on screen " @ ScreenClass @ "failed:" @ ListenerCallback);
			}
			ListenerCallback = None; // Reset the class-level delegate (ugh)
		}
	}
}

// ========================================================================================
// Events
// ========================================================================================

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	if(!ListenerSet)
	{
		SetupGlobalManager();
	}
	ProcessCallbacksForEvent("OnInit");
}

// This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen)
{
	ProcessCallbacksForEvent("OnReceiveFocus");
}

// This event is triggered after a screen loses focus
event OnLoseFocus(UIScreen Screen)
{
	ProcessCallbacksForEvent("OnLoseFocus");
}

// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	ProcessCallbacksForEvent("OnRemoved");
}

// ========================================================================================
// Defaults
// ========================================================================================
defaultproperties
{
    // Trigger when the main view of the HQ shows
	ScreenClass = none;
	Events=("OnInit", "OnFocusReceived", "OnFocusLost", "OnRemoved");
	Events=(false, false, false, false);
}
*/