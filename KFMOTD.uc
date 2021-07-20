class KFMOTD extends UT2K4Browser_MOTD
  config(MOTD_Config);

var String mutByMsg;
var config String newsIPAddr, getRequest, newsSource;
var automated GUIHTMLTextBox HTMLText;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  super.InitComponent(MyController, MyOwner);

  GetNewNews();
  HTMLText.SetContents(myMOTD);
  PanelCaption="News source: "$newsSource;
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
            HTMLText.SetContents(myMOTD); // Modified for HTML Support
          }
        }
      }
      else
      {
        if(sendGet)
        {
          myMOTD = myMOTD$"|| Could not connect to news server";
          HTMLText.SetContents(myMOTD); // Modified for HTML Support
        }
      }
    }
    else
    {
      if (myRetryCount++ > myRetryMax)
      {
        myMOTD = myMOTD$"|| Retries Failed";
        KillTimer();
        HTMLText.SetContents(myMOTD); // Modified for HTML Support
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
      myMOTD = "<br>"$page; // Added <br>
      HTMLText.SetContents(myMOTD); // Modified for HTML Support

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
    // Simple credits section, because why not xd
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

  // Text Error Prevention and handling
  // PRE-HTML UI BOX IMPLEMENTATION
  // page = Repl(page, "<br>", "|", false);
  // page = Repl(page, "<hr>", "|_____________________________________________________________________________________________________|", false);
  page = Repl(page, "’", "'", false);
}

defaultproperties
{
  ////// Config Variables Default Values //////
  // News Source text, shows at the top of the News Screen
  // Customizable, defaults to TWI
  newsSource="TRIPWIRE INTERACTIVE"
  newsIPAddr="pastebin.com"
  getRequest="GET /raw/zZAKur74 HTTP/1.1"

  // Message that shows before loading the news
  myMOTD="<br><br>Retrieving latest updates from the server..."

  // HTML Text Box
  Begin Object Class=GUIHTMLTextBox Name=MyMOTDText
    WinTop=0.001679
    WinHeight=0.833203
    WinLeft=0.01
    WinWidth=0.99
    RenderWeight=0.600000
    TabOrder=1
    bNeverFocus=True
  End Object
  HTMLText=GUIHTMLTextBox'KFGui.KFMOTD.MyMOTDText'
}