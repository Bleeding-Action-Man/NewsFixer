class Custom_MOTD extends KFMOTD
  config(MOTD_Config);

var String mutByMsg;
var config String getRequest, newsSource, newsIPAddr;
var automated GUIHTMLTextBox HTMLText;

var String getResponse;

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
  PanelCaption="News source: "$newsSource;
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

      myMOTD = "<br>"$page;

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
  local string junk, joinedMsg, velsanMail, marcoMail, velsanCreds, marcoCreds, urlNote;
  local int i;

  junk = page;
  Caps(junk);

  i = InStr(junk, "<html>");

  if ( i > -1 )
  {
    velsanMail="http://steamcommunity.com/id/Vel-San/";
    marcoMail="http://steamcommunity.com/profiles/76561197975509070";
    velsanCreds="<font color=yellow size=2>- Fixed by: <a href="$velsanMail$">Vel-San</a></font>";
    marcoCreds="<font color=yellow size=2>- Base HTML Rendering Enhanced by Vel-San, Originally Created by <a href="$marcoMail$">Marco</a></font>";
    urlNote="<hr><br><body BGCOLOR=black>";
    mutByMsg=velsanCreds$"<br><br>"$marcoCreds$"<br>";
    joinedMsg=mutByMsg$urlNote;
    // Replace page <BODY>
    page = Repl(page, "<html>", joinedMsg, false);
    // remove all header from string
    page = Right(page, len(page) - i);
  }

  junk = page;
  Caps(junk);

  i = InStr(junk, "</body>");
  if ( i > -1 )
  {
    // remove all footers from string
    page = Left(page, i);
  }

  page = Repl(page, "’", "'", false);
}

defaultproperties
{
  Begin Object Class=GUIHTMLTextBox Name=MyMOTDText
    WinTop=0.001679
    WinHeight=0.833203
    WinLeft=0.01
    WinWidth=0.99
    RenderWeight=0.600000
    TabOrder=1
    bNeverFocus=True
  End Object
  HTMLText=GUIHTMLTextBox'KFGui.Custom_MOTD.MyMOTDText'

  Begin Object Class=GUILabel Name=VersionNum
    TextAlign=TXTA_Right
    StyleName="TextLabel"
    WinTop=-0.043415
    WinLeft=0.738500
    WinWidth=0.252128
    WinHeight=0.040000
    RenderWeight=20.700001
  End Object
  l_Version=GUILabel'KFGui.Custom_MOTD.VersionNum'

  VersionString="KF Version"

  b_QuickConnect=None

  myMOTD="Retrieving Latest Updates From The Server"
  // newsIPAddr="pastebin.com"
  // getRequest="GET /raw/zZAKur74 HTTP/1.1" // Defaults to this if nothing set, official Announcements
  // newsSource="TRIPWIRE INTERACTIVE"

  ReReadyPause=0.250000
  myRetryCount=0
  myRetryMax=40

  LinkClassName="ROInterface.ROBufferedTCPLink"
  sendGet = true;
}