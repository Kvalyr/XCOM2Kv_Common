class Kv_C_Manager extends UIScreen;

var private array<UIScreenListener> Listeners;

static function Log(string LogString)
{
	`log("= = = = KvC_Manager: " @ LogString);
}

static function Kv_C_Manager GetOrCreateManager(optional UIScreenListener NewListener)
{
	local Kv_C_Manager KvCM;
	KvCM = GetManager();
	if(KvCM == none)
	{
		KvCM = `XCOMGAME.spawn( class'Kv_C_Manager' );
	}
	if(NewListener == none)
	{
		KvCM.AddListener(NewListener);
	}
	return KvCM;
}

static function Kv_C_Manager GetManager()
{
	return Kv_C_Manager(`SCREENSTACK.GetFirstInstanceOf( class'Kv_C_Manager' ));
}

function int AddListener(UIScreenListener NewListener)
{
	local int i;
	Log("Kv_C_Manager SetListener()");
	if(Listeners.Find(NewListener) < 0) // Find returns -1 on failure
	{
		i = Listeners.Length;
		Listeners.AddItem(NewListener);
		return i;
	}
	else
	{
		Log("KV_C_ScreenListener already exists! : " @ GetManager());
	}
	return -1;
}

function UIScreenListener GetFirstListenerForScreen(class<UIscreen> ScreenClass)
{
	local int i;
	local UIScreenListener Listener;
	for(i = 0; i < Listeners.Length; ++i)
	{
		Listener = Listeners[i];
		if(Listener != none && Listener.ScreenClass == ScreenClass)
		{
			return Listener;
		}
	}
}

function array<UIScreenListener> GetAllListenersForScreen(class<UIscreen> ScreenClass)
{
	local int i;
	local UIScreenListener Listener;
	local array<UIScreenListener> ListenersForScreen;
	for(i = 0; i < Listeners.Length; ++i)
	{
		Listener = Listeners[i];
		if(Listener != none && Listener.ScreenClass == ScreenClass)
		{
			ListenersForScreen.AddItem(Listener);
		}
	}
	return ListenersForScreen;
}

DefaultProperties
{
	Package = "NONE";
	MCName = "theScreen"; // this matches the instance name of the EmptyScreen MC in components.swf
	LibID = "EmptyScreen"; // this is used to determine whether a LibID was overridden when UIMovie loads a screen
	
	bIsFocused = false;
	bCascadeFocus = false;
	bHideOnLoseFocus = true;

	bAnimateOnInit = false;
	bAnimateOut = false;

	CinematicWatch = -1;	
	bShowDuringCinematic = false;

	bConsumeMouseEvents	= false;
	bProcessMouseEventsIfNotFocused = false;
	bAutoSelectFirstNavigable = false;
	InputState = eInputState_None;

	MouseGuardClass = class'UIMouseGuard';
}
