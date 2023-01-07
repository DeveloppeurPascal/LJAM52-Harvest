unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Ani, FMX.StdCtrls, FMX.Controls.Presentation, cButton,
  FMX.DzHTMLText;

Const
  CDefaultMarginsTop = 5;
  // top margin of content text on screens with Title visible
  CGameCellSize = 50; // Widht/Height of a drawn cell on the game grid

type
{$SCOPEDENUMS ON}
  TGameScreen = (Home, Credit, Options, GameStart, GameContinue);

  TfrmMain = class(TForm)
    ScreenHome: TLayout;
    ScreenGame: TLayout;
    ScreenCredit: TLayout;
    ScreenSettings: TLayout;
    Background: TLayout;
    BackgroundImage: TRectangle;
    animHideScreen: TFloatAnimation;
    animShowScreen: TFloatAnimation;
    GameTitle: TLayout;
    GameTitleText: TLabel;
    ScreenHomeMenu: TLayout;
    btnMenuExit: TcadButton;
    btnMenuCredits: TcadButton;
    btnMenuOptions: TcadButton;
    btnMenuContinue: TcadButton;
    btnMenuPlay: TcadButton;
    btnBackFromCredits: TcadButton;
    btnBackFromSettings: TcadButton;
    ScreenCreditContent: TVertScrollBox;
    ScreenCreditText: TDzHTMLText;
    ScreenSettingsContent: TVertScrollBox;
    PlayerInventory: TRectangle;
    btnPauseGame: TRectangle;
    btnPauseGameSVG: TPath;
    GameGrid: TImage;
    procedure FormCreate(Sender: TObject);
    procedure animHideScreenFinish(Sender: TObject);
    procedure animShowScreenFinish(Sender: TObject);
    procedure btnMenuExitClick(Sender: TObject);
    procedure btnMenuContinueClick(Sender: TObject);
    procedure btnMenuPlayClick(Sender: TObject);
    procedure btnMenuOptionsClick(Sender: TObject);
    procedure btnMenuCreditsClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure btnPauseGameClick(Sender: TObject);
    procedure GameGridResize(Sender: TObject);
  private
    { D�clarations priv�es }
    DisplayedScreen: TLayout;
    GridViewportX, GridViewportY: integer;
  public
    { D�clarations publiques }
    procedure DisplayScreen(ScreenToDisplay: TGameScreen);
    procedure DisplayGameTitle(Visible: boolean);
    procedure InitGameText;
    procedure InitCreditScreen;
    procedure InitSettingsScreen;
    procedure CalcScreenHomeMenuHeight;
    procedure PauseGame;
    procedure InitGameStart(ContinuePreviousGame: boolean = false);
    procedure RefreshGameGrid;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses uGameData, cInventoryItem;

procedure TfrmMain.animHideScreenFinish(Sender: TObject);
begin
  animHideScreen.enabled := false;
  Assert(animHideScreen.Parent is TLayout, animHideScreen.Parent.Name +
    ' is not a TLayout.');
  (animHideScreen.Parent as TLayout).Visible := false;
end;

procedure TfrmMain.animShowScreenFinish(Sender: TObject);
begin
  animShowScreen.enabled := false;
  Assert(animShowScreen.Parent is TLayout, animShowScreen.Parent.Name +
    ' is not a TLayout.');
  (animShowScreen.Parent as TLayout).Visible := true;
  (animShowScreen.Parent as TLayout).enabled := true;
end;

procedure TfrmMain.btnBackClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Home);
end;

procedure TfrmMain.btnMenuContinueClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.GameContinue);
end;

procedure TfrmMain.btnMenuCreditsClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Credit);
end;

procedure TfrmMain.btnMenuExitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.btnMenuOptionsClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Options);
end;

procedure TfrmMain.btnMenuPlayClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.GameStart);
end;

procedure TfrmMain.btnPauseGameClick(Sender: TObject);
begin
  PauseGame;
end;

procedure TfrmMain.CalcScreenHomeMenuHeight;
begin
  ScreenHomeMenu.BeginUpdate;
  try
    ScreenHomeMenu.Height := 0;
    for var i := 0 to ScreenHomeMenu.ChildrenCount - 1 do
      if (ScreenHomeMenu.Children[i] is TcadButton) then
      begin
        var
        btn := (ScreenHomeMenu.Children[i] as TcadButton);
        if btn.Visible then
          ScreenHomeMenu.Height := ScreenHomeMenu.Height + btn.margins.top +
            btn.Height + btn.margins.bottom;
      end;
  finally
    ScreenHomeMenu.endupdate;
  end;
end;

procedure TfrmMain.DisplayGameTitle(Visible: boolean);
begin
  GameTitle.Visible := Visible;
  if Visible then
    GameTitle.BringToFront;
end;

procedure TfrmMain.DisplayScreen(ScreenToDisplay: TGameScreen);
var
  NewScreen: TLayout;
begin
  // Show the background if it's not shown
  if not Background.Visible then
  begin
    Background.Visible := true;
    Background.BringToFront;
  end;

  case ScreenToDisplay of
    TGameScreen.Home:
      NewScreen := ScreenHome;
    TGameScreen.Credit:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitCreditScreen;
          end);
        NewScreen := ScreenCredit;
      end;
    TGameScreen.Options:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitSettingsScreen;
          end);
        NewScreen := ScreenSettings;
      end;
    TGameScreen.GameStart, TGameScreen.GameContinue:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitGameStart(ScreenToDisplay = TGameScreen.GameContinue);
          end);
        NewScreen := ScreenGame;
      end;
  else
    raise exception.Create('Unknow Screen to display.');
  end;

  // Hide actual diplayed screen
  if assigned(DisplayedScreen) and (DisplayedScreen <> NewScreen) then
  begin
    if animHideScreen.enabled then
      raise exception.Create('An other screen is already hiding.');
    DisplayedScreen.enabled := false;
    animHideScreen.Parent := DisplayedScreen;
    animHideScreen.enabled := true;
  end;

  // Show new screen
  NewScreen.Opacity := 1;
  NewScreen.Visible := true;
  NewScreen.enabled := false;
  NewScreen.BringToFront;
  if animShowScreen.enabled then
    raise exception.Create('An other screen is already showing.');
  animShowScreen.Parent := NewScreen;
  animShowScreen.enabled := true;
  DisplayedScreen := NewScreen;

  // Show/Hide game title on top of the screen
  DisplayGameTitle(ScreenToDisplay in [TGameScreen.Home, TGameScreen.Credit,
    TGameScreen.Options]);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Hide all screens
  for var i := 0 to ChildrenCount - 1 do
    if (Children[i] is TLayout) then
      (Children[i] as TLayout).Visible := false;

  DisplayedScreen := nil;

  // Defer Home screen display
  tthread.ForceQueue(nil,
    procedure
    begin
      DisplayScreen(TGameScreen.Home);
    end);

  InitGameText;

  // Disable "Continue" button if no previous game data
  btnMenuContinue.DisableButton;
  // TODO : enable the button if previous game data exists

  // hide Settings button (nothing in the screen for now)
  btnMenuOptions.Visible := false;

{$IF Defined(IOS) or Defined(ANDROID)}
  // remove EXIT button on iOS&Android
  btnMenuExit.enabled := false;
{$ENDIF}
  CalcScreenHomeMenuHeight;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
var KeyChar: Char; Shift: TShiftState);
begin
  if Key in [vkEscape, vkHardwareBack] then
  begin
    if (DisplayedScreen = ScreenCredit) then
    begin
      Key := 0;
      KeyChar := #0;
      btnBackFromCredits.onclick(Self);
    end
    else if (DisplayedScreen = ScreenSettings) then
    begin
      Key := 0;
      KeyChar := #0;
      btnBackFromSettings.onclick(Self);
    end
    else if (DisplayedScreen = ScreenGame) then
    begin
      Key := 0;
      KeyChar := #0;
      btnPauseGame.onclick(Self);
    end
{$IF Defined(IOS) or Defined(ANDROID)}
    else;
{$ELSE}
    else
    begin
      Key := 0;
      KeyChar := #0;
      btnMenuExit.onclick(Self);
    end;
{$ENDIF}
  end;
end;

procedure TfrmMain.GameGridResize(Sender: TObject);
begin
  GameGrid.Bitmap.SetSize(trunc(GameGrid.Width), trunc(GameGrid.Height));
  if (ScreenGame.Visible) then
    RefreshGameGrid;
end;

procedure TfrmMain.InitCreditScreen;
begin
  ScreenCreditContent.margins.top := GameTitle.Position.Y + GameTitle.Height +
    GameTitle.margins.top + GameTitle.margins.bottom + CDefaultMarginsTop;
end;

procedure TfrmMain.InitGameStart(ContinuePreviousGame: boolean);
var
  GameData: TGameData;
  InventoryItemBox: tcadInventoryItem;
begin
  // Init or load game data
  GameData := TGameData.Current;
  if ContinuePreviousGame then
    GameData.LoadFromFile('PreviousGameData')
    // TODO : change game data filename
  else
    GameData.NewGame;

  // Init the game screen
  while PlayerInventory.ChildrenCount > 0 do
    PlayerInventory.Children[0].Free;

  for var i := 0 to GameData.inventory.count - 1 do
  begin
    InventoryItemBox := tcadInventoryItem.Create(Self);
    InventoryItemBox.Parent := PlayerInventory;
    InventoryItemBox.InventoryItem := GameData.inventory.Get(i);
  end;

  GridViewportX := CGameGridWidth div 2;
  GridViewportY := CGameGridHeight div 2;

  RefreshGameGrid;

  // TODO : � compl�ter
end;

procedure TfrmMain.InitGameText;
begin
  // TODO : translate texts if needed

  btnMenuPlay.Text.Text := 'Play';
  btnMenuContinue.Text.Text := 'Continue';
  btnMenuOptions.Text.Text := 'Options';
  btnMenuCredits.Text.Text := 'Credits';
  btnMenuExit.Text.Text := 'Exit';
  btnBackFromCredits.Text.Text := 'Home';
  btnBackFromSettings.Text.Text := 'Home';

  ScreenCreditText.BeginUpdate;
  try
    ScreenCreditText.Text := '<b>' + GameTitleText.Text + '</b><br>' +
      '(c) Patrick Pr�martin 2023<br>' + '<br>' +
      'Thanks to <a:https://github.com/digao-dalpiaz>Rodrigo Depin� Dalpiaz</a> for his <a:https://github.com/digao-dalpiaz/DzHTMLText>DzHTMLText</a> component.';
  finally
    ScreenCreditText.endupdate;
  end;

  caption := GameTitleText.Text;
end;

procedure TfrmMain.InitSettingsScreen;
begin
  ScreenSettingsContent.margins.top := GameTitle.Position.Y + GameTitle.Height +
    GameTitle.margins.top + GameTitle.margins.bottom + CDefaultMarginsTop;
end;

procedure TfrmMain.PauseGame;
begin
  // TODO : do what is needed when the game is stopped

  DisplayScreen(TGameScreen.Home);
end;

procedure TfrmMain.RefreshGameGrid;
var
  NbCol, NbRow: integer;
  GameData: TGameData;
  item: TGameItem;
  GridCanvas: tcanvas;
  x, Y, w, h: single;
  bmpscale: single;
begin
  GameData := TGameData.Current;

  NbCol := (trunc(GameGrid.Width) div CGameCellSize) + 1;
  NbRow := (trunc(GameGrid.Height) div CGameCellSize) + 1;

  bmpscale := GameGrid.Bitmap.BitmapScale;
  GameGrid.BeginUpdate;
  try
    GridCanvas := GameGrid.Bitmap.Canvas;
    GridCanvas.BeginScene;
    try
      GridCanvas.Clear(talphacolors.Darkorange);
      for var i := 0 to NbCol - 1 do
        for var j := 0 to NbRow - 1 do
        begin
          item := GameData.GameGrid.GetItem(GridViewportX + i,
            GridViewportY + j);
          if assigned(item) then
          begin
            x := i * CGameCellSize * bmpscale;
            Y := j * CGameCellSize * bmpscale;
            w := CGameCellSize * bmpscale;
            h := CGameCellSize * bmpscale;
            GridCanvas.Fill.Color := item.Color;
            GridCanvas.Fill.Kind := TBrushKind.Solid;
            GridCanvas.FillRect(trectf.Create(x, Y, x + w, Y + h), 1);
          end;
        end;
    finally
      GridCanvas.endscene;
    end;
  finally
    GameGrid.endupdate;
  end;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.
