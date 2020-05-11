Class SRLevelCleanup extends Interaction;

var string SwitchToURL;

function NotifyLevelChange()
{
	local int i;

	// Make sure GUI controller leaves no menus referenced.
	GUIController(ViewportOwner.GUIController).ResetFocus();
	GUIController(ViewportOwner.GUIController).FocusedControl = None;

	for( i=(ViewportOwner.LocalInteractions.Length-1); i>=0; --i )
		if( ViewportOwner.LocalInteractions[i]==Self )
			ViewportOwner.LocalInteractions.Remove(i,1);

	if( SwitchToURL!="" )
		ViewportOwner.Console.DelayedConsoleCommand("OPEN "$SwitchToURL); // Switch server.
	else ViewportOwner.Console.DelayedConsoleCommand("OBJ GARBAGE"); // Ensure to cleanup everything releated to this mod.
}

static final function AddSafeCleanup( PlayerController PC, optional string NextURL )
{
	local int i;
	local SRLevelCleanup C;

	if( NextURL!="" )
		PC.Player.Console.DelayedConsoleCommand("DISCONNECT");

	for( i=(PC.Player.LocalInteractions.Length-1); i>=0; --i )
		if( PC.Player.LocalInteractions[i].Class==Default.Class )
		{
			SRLevelCleanup(PC.Player.LocalInteractions[i]).SwitchToURL = NextURL;
			return;
		}
	C = new(None) Class'SRLevelCleanup';
	C.ViewportOwner = PC.Player;
	C.Master = PC.Player.InteractionMaster;
	i = PC.Player.LocalInteractions.Length;
	PC.Player.LocalInteractions.Length = i+1;
	PC.Player.LocalInteractions[i] = C;
	C.Initialize();
	C.SwitchToURL = NextURL;
}

defaultproperties
{
}
