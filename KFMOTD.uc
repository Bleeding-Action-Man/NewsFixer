class KFMOTD extends UT2K4Browser_MOTD
    config(KFMOTD);

var String myMOTD;
///////////////////////
// Values from Vel-San
var String mutByMsg;
var() globalconfig String getRequest;
var automated GUIHTMLTextBox HTMLText;
///////////////////////


var String getResponse;
var String newsIPAddr;

var int		myRetryCount;
var int		myRetryMax;

var ROBufferedTCPLink myLink;
var string LinkClassName;
var bool sendGet;
var bool pageWait;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController, MyOwner);

    GetNewNews();
    HTMLText.SetContents(myMOTD);
}

event Opened(GUIComponent Sender)
{
	l_Version.Caption = VersionString@PlayerOwner().Level.ROVersion;

	super(Ut2k4Browser_Page).Opened(Sender);
}

protected function ROBufferedTCPLink CreateNewLink()
{
	local class<ROBufferedTCPLink> NewLinkClass;
	local ROBufferedTCPLink NewLink;

	if ( PlayerOwner() == None )
		return None;

	if ( LinkClassName != "" )
	{
		NewLinkClass = class<ROBufferedTCPLink>(DynamicLoadObject( LinkClassName, class'Class'));
    }
    if ( NewLinkClass != None )
    {
        NewLink = PlayerOwner().Spawn( NewLinkClass );
    }

    NewLink.ResetBuffer();

    return NewLink;
}


function ReceivedMOTD(MasterServerClient.EMOTDResponse Command, string Data)
{
}

function GetNewNews()
{
    if(myLink == None)
    {
        myLink = CreateNewLink();
    }

    if(myLink != None)
    {
        myLink.ServerIpAddr.Port = 0;

        sendGet = true;
        myLink.Resolve(newsIPAddr);  // NOTE: This is a non-blocking operation

        SetTimer(ReReadyPause, true);
    }
    else
    {
        myMOTD = myMOTD$"|| myLink is None";
    }
}

event Timer()
{
    local string text;
    local string page;
    local string command;


    if(myLink != None)
    {
        if ( myLink.ServerIpAddr.Port != 0)
        {
            if(myLink.IsConnected())
            {
                if(sendGet)
                {
                     command = getRequest$myLink.CRLF$"Host: "$newsIPAddr$myLink.CRLF$myLink.CRLF;
                     myLink.SendCommand(command);

                     pageWait = true;
                     myLink.WaitForCount(1,20,1); // 20 sec timeout
                     sendGet = false;
                }
                else
                {
                    if(pageWait)
                    {
                        myMOTD = myMOTD$".";
                        HTMLText.SetContents(myMOTD);
                    }
                }
            }
            else
            {
                if(sendGet)
                {
                    myMOTD = myMOTD$"|| Could not connect to news server";
                    HTMLText.SetContents(myMOTD);
                }
            }
        }
        else
        {
        	if (myRetryCount++ > myRetryMax)
        	{
                myMOTD = myMOTD$"|| Retries Failed";
                KillTimer();
                HTMLText.SetContents(myMOTD);
        	}
        }

        if(myLink.PeekChar() != 0)
        {
            pageWait = false;

			// data waiting
            page = "";
            while(myLink.ReadBufferedLine(text))
            {
                page = page$text;
            }

            NewsParse(page);

            myMOTD = "|"$page;

            HTMLText.SetContents(myMOTD);

            myLink.DestroyLink();
            myLink = none;

            KillTimer();
        }
    }

    SetTimer(ReReadyPause, true);
}

function NewsParse(out string page)
{
    local string junk;
    local string joinedMsg;
    local int i;

    junk = page;
    Caps(junk);

    i = InStr(junk, "<style>");

    if ( i > -1 )
    {
        ///////////////////////
        // Add Mut By
        mutByMsg="- Fixed by: Vel-San<br><br>";
        joinedMsg=mutByMsg$"(DOUBLE CLICK LINKS TO OPEN THEM)<hr><br>";
        // Replace page <BODY>
        page = Repl(page, "<style>", joinedMsg, false);
        // remove all header from string
        page = Right(page, len(page) - i);
        ///////////////////////

    }

    junk = page;
    Caps(junk);

    i = InStr(junk, "</body>");
    if ( i > -1 )
    {
         // remove all footers from string
         page = Left(page, i);
    }

    ///////////////////////
    // Text Error Prevention and handling
    // PRE-HTML UI BOX IMPLEMENTATION
    // page = Repl(page, "<br>", "|", false);
    // page = Repl(page, "<hr>", "|_____________________________________________________________________________________________________|", false);
    page = Repl(page, "’", "'", false);
    ///////////////////////
}

defaultproperties
{
     Begin Object Class=GUIHTMLTextBox Name=MyMOTDText
        //  bNoTeletype=True
        //  CharDelay=0.050000
        //  EOLDelay=0.100000
        //  bVisibleWhenEmpty=True
        //  OnCreateComponent=MyMOTDText.InternalOnCreateComponent
         WinTop=0.001679
         WinHeight=0.833203
         WinLeft=0.01
         WinWidth=0.99
		 RenderWeight=0.600000
         TabOrder=1
         bNeverFocus=True
     End Object
     HTMLText=GUIHTMLTextBox'KFGui.KFMOTD.MyMOTDText'

     Begin Object Class=GUILabel Name=VersionNum
         TextAlign=TXTA_Right
         StyleName="TextLabel"
         WinTop=-0.043415
         WinLeft=0.738500
         WinWidth=0.252128
         WinHeight=0.040000
         RenderWeight=20.700001
     End Object
     l_Version=GUILabel'KFGui.KFMOTD.VersionNum'

     VersionString="KF Version"
     PanelCaption="News from Tripwire Interactive"

     b_QuickConnect=None

     ///////////////////////
     myMOTD="||Retrieving Latest Updates From The Server"
     // Values from Vel-San -- Host Server & URL
     newsIPAddr="pastebin.com"
     getRequest="GET /raw/zZAKur74 HTTP/1.1" // Defaults to this if nothing set, official Announcements
     ///////////////////////

     ReReadyPause=0.250000
     myRetryCount=0
     myRetryMax=40

     LinkClassName="ROInterface.ROBufferedTCPLink"
     sendGet = true;
}