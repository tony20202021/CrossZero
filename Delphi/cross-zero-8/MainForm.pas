unit MainForm;

{$INLINE ON}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FMX.TabControl, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Memo.Types
  , System.Generics.Collections
  , Common.Interfaces
  ;

type
  TForm1 = class(TForm)
    GridLayout1: TGridLayout;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Button_Forward: TButton;
    Button_Back: TButton;
    Label_Move_Left: TLabel;
    Label_Move_Right: TLabel;
    Button_Start: TButton;
    Panel_Left: TPanel;
    Label1: TLabel;
    Panel_Right: TPanel;
    Label2: TLabel;
    Panel_Center: TPanel;
    Line_v_1: TLine;
    Line_v_2: TLine;
    Line_v_3: TLine;
    Line_h_1: TLine;
    Line_h_2: TLine;
    Line_h_3: TLine;
    Line_d_11_33: TLine;
    Line_d_31_13: TLine;
    Label_Player_Left: TLabel;
    Label_Player_Right: TLabel;
    Button_Genetic: TButton;
    Panel10: TPanel;
    CheckBox_Stop: TCheckBox;
    CheckBox_Pause: TCheckBox;
    TabControl1: TTabControl;
    Button_BackProp: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button_StartClick(Sender: TObject);
    procedure Button_ForwardClick(Sender: TObject);
    procedure Button_GeneticClick(Sender: TObject);
    procedure CheckBox_StopChange(Sender: TObject);
    procedure CheckBox_PauseChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button_BackPropClick(Sender: TObject);

  private
    FPlayer_Left: IPlayer;
    FPlayer_Right: IPlayer;

    FFieldsPlay: TList<TField>;
    FMoveSide: TMoveSide;
    FMove: TMove;

    procedure Clear_Lines;

    procedure Check_Win_All(const AField: TField);
    function Check_Win_Side(const AField: TField; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
    function Check_Win_Vertical(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer; const AVisible: Boolean): Boolean;
    function Check_Win_Horizontal(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer; const AVisible: Boolean): Boolean;
    function Check_Win_Diagonal_11_33(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
    function Check_Win_Diagonal_31_13(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;

    procedure Play_Field_Create;
    procedure Draw_Field(AField: TField);

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  System.Math
  , System.StrUtils
  , FMX.DialogService.Sync
  , Player.Random
  , Player.Compositon
  , Common.Constants
  , Utils
  ;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := (IDYes = TDialogServiceSync.MessageDialog('Exit?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FFieldsPlay := TList<TField>.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FFieldsPlay.Clear;

  FPlayer_Left := nil;
  FPlayer_Right := nil;

  GUtils.NeedStop := True;
  GUtils.IsPaused := False;

end;

procedure TForm1.Button_StartClick(Sender: TObject);
var
//  LRandom: Double;
  LPlayerEx: IPlayerEx;
begin

  FFieldsPlay.Clear;

//  LRandom := Random(3);
//  if (LRandom < 1.0) then
//  begin
//    FPlayer_Left := GUtils.Create_Player;
    if FPlayer_Left = nil then
    begin
      FPlayer_Left := TPlayer_Compositon.Create;
    end;

    Assert(Supports(FPlayer_Left, IPlayerEx, LPlayerEx));
//    LPlayerEx.GetNet.ReadIniFile;

    FPlayer_Right := TPlayer_Random.Create;
//  end
//  else if (LRandom < 2.0) then
//  begin
//    FPlayer_Left := TPlayer_Random.Create;
//
//    FPlayer_Right := GUtils.Create_Player
//    Assert(Supports(FPlayer_Right, IPlayerEx, LPlayerEx));
////    LPlayerEx.GetNet.ReadIniFile;
//  end
//  else
//  begin
//    FPlayer_Left := GUtils.Create_Player
//    Assert(Supports(FPlayer_Left, IPlayerEx, LPlayerEx));
////    LPlayerEx.GetNet.ReadIniFile;
//
//    FPlayer_Right := GUtils.Create_Player
//    Assert(Supports(FPlayer_Right, IPlayerEx, LPlayerEx));
////    LPlayerEx.GetNet.ReadIniFile;
//  end;

  Label_Player_Left.Text := TObject(FPlayer_Left).ClassName;
  Label_Player_Right.Text := TObject(FPlayer_Right).ClassName;

  Play_Field_Create;
  Draw_Field(FFieldsPlay.Last);

  FMoveSide := TMoveSide.sideLeft;

  Label_Move_Left.Visible := False;
  Label_Move_Right.Visible := False;

  Button_Back.Enabled := False;
  Button_Forward.Enabled := True;

  Clear_Lines;

end;

procedure TForm1.Play_Field_Create;
var
  LIndexY: Integer;
  LIndexX: Integer;
  LField: TField;
begin
  FFieldsPlay.Clear;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      LField[LIndexY, LIndexX] := TCellValue.___;
    end;
  end;

  FFieldsPlay.Add(LField);

end;

procedure TForm1.Clear_Lines;
var
  LControlName: string;
begin
  LControlName := 'Line_v_1';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_v_2';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_v_3';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_h_1';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_h_2';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_h_3';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_d_11_33';
  TLine(FindComponent(LControlName)).Visible := False;

  LControlName := 'Line_d_31_13';
  TLine(FindComponent(LControlName)).Visible := False;

end;

procedure TForm1.Draw_Field(AField: TField);
var
  LIndexY: Integer;
  LIndexX: Integer;
  LControlName: string;
begin
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      LControlName := 'Label' + LIndexY.ToString + LIndexX.ToString;
      TLabel(FindComponent(LControlName)).Text := TCellLabel[AField[LIndexY, LIndexX]];
      TLabel(FindComponent(LControlName)).TextSettings.FontColor := TAlphaColorRec.Black;
    end;
  end;

end;

procedure TForm1.Button_ForwardClick(Sender: TObject);
var
  LIndexY: Integer;
  LIndexX: Integer;
  LFieldNew: TField;
  LControlName: string;
begin
  case FMoveSide of
    TMoveSide.sideLeft:
    begin
      FMove := FPlayer_Left.GetNextMove(FFieldsPlay.Last, TSideValues[FMoveSide]);

      Label_Move_Left.Visible := True;
      Label_Move_Right.Visible := False;

      FMoveSide := TMoveSide.sideRight;
    end;
    TMoveSide.sideRight:
    begin
      FMove := FPlayer_Right.GetNextMove(FFieldsPlay.Last, TSideValues[FMoveSide]);

      Label_Move_Left.Visible := False;
      Label_Move_Right.Visible := True;

      FMoveSide := TMoveSide.sideLeft;
    end;
  end;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      LFieldNew[LIndexY, LIndexX] := FFieldsPlay.Last[LIndexY, LIndexX];
    end;
  end;

  if (FMove.SelectedFigure <> TCellValue.___) then
  begin
    LFieldNew[FMove.Y, FMove.X] := FMove.SelectedFigure;
  end;

  FFieldsPlay.Add(LFieldNew);

  Draw_Field(FFieldsPlay.Last);

  if (FMove.SelectedFigure <> TCellValue.___) then
  begin
    LControlName := 'Label' + FMove.Y.ToString + FMove.X.ToString;
    TLabel(FindComponent(LControlName)).TextSettings.FontColor := TAlphaColorRec.Darkviolet;
  end;

  Check_Win_All(FFieldsPlay.Last);

end;

procedure TForm1.CheckBox_PauseChange(Sender: TObject);
begin
  GUtils.IsPaused := CheckBox_Pause.IsChecked;
end;

procedure TForm1.CheckBox_StopChange(Sender: TObject);
begin
  GUtils.NeedStop := CheckBox_Stop.IsChecked;
  if GUtils.NeedStop then
  begin
    GUtils.IsPaused := False;
  end;
end;

procedure TForm1.Check_Win_All(const AField: TField);
begin
  if (Check_Win_Side(AField, TSideValues[TMoveSide.sideLeft], True)) or
     (Check_Win_Side(AField, TSideValues[TMoveSide.sideRight], True)) then
  begin
    Button_Back.Enabled := False;
    Button_Forward.Enabled := False;
  end;
end;

function TForm1.Check_Win_Side(const AField: TField; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
begin
  Result := False;

  if (Check_Win_Vertical(AField, 3, ACellValue, 1, AVisible)) or
     (Check_Win_Vertical(AField, 3, ACellValue, 2, AVisible)) or
     (Check_Win_Vertical(AField, 3, ACellValue, 3, AVisible)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 1, AVisible)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 2, AVisible)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 3, AVisible)) or
     (Check_Win_Diagonal_11_33(AField, 3, ACellValue, AVisible)) or
     (Check_Win_Diagonal_31_13(AField, 3, ACellValue, AVisible)) then
  begin
    Result := True;
  end;

end;

function TForm1.Check_Win_Vertical(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer; const AVisible: Boolean): Boolean;
var
  LControlName: string;
begin
  Result := False;

  if (GUtils.Check_Win_Vertical(AField, ACount, ACellValue, AIndex)) then
  begin
    if AVisible then
    begin
      LControlName := 'Line_v_' + AIndex.ToString;
      TLine(FindComponent(LControlName)).Visible := True;
    end;
    Result := True;
  end;
end;

function TForm1.Check_Win_Horizontal(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer; const AVisible: Boolean): Boolean;
var
  LControlName: string;
begin
  Result := False;

  if (GUtils.Check_Win_Horizontal(AField, ACount, ACellValue, AIndex)) then
  begin
    if AVisible then
    begin
      LControlName := 'Line_h_' + AIndex.ToString;
      TLine(FindComponent(LControlName)).Visible := True;
    end;
    Result := True;
  end;
end;

function TForm1.Check_Win_Diagonal_11_33(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
var
  LControlName: string;
begin
  Result := False;

  if (GUtils.Check_Win_Diagonal_11_33(AField, ACount, ACellValue)) then
  begin
    if AVisible then
    begin
      LControlName := 'Line_d_11_33';
      TLine(FindComponent(LControlName)).Visible := True;
    end;
    Result := True;
  end;
end;

function TForm1.Check_Win_Diagonal_31_13(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
var
  LControlName: string;
begin
  Result := False;

  if (GUtils.Check_Win_Diagonal_31_13(AField, ACount, ACellValue)) then
  begin
    if AVisible then
    begin
      LControlName := 'Line_d_31_13';
      TLine(FindComponent(LControlName)).Visible := True;
    end;
    Result := True;
  end;
end;

procedure TForm1.Button_GeneticClick(Sender: TObject);
begin
  ASSERT(__GENETIC);
  ASSERT(not __BACK_PROPAGATION);

  CheckBox_Stop.IsChecked := False;
  CheckBox_Pause.IsChecked := False;

  GUtils.Start_Learn_Genetic(TabControl1);
end;

procedure TForm1.Button_BackPropClick(Sender: TObject);
begin
  ASSERT(not __GENETIC);
  ASSERT(__BACK_PROPAGATION);

  CheckBox_Stop.IsChecked := False;
  CheckBox_Pause.IsChecked := False;

  GUtils.Start_Learn_BackPropagation(TabControl1);
end;

end.
