unit Utils;

interface

uses
  System.Classes
  , System.Generics.Collections
  , FMX.TabControl
  , FMX.StdCtrls
  , FMX.Memo
  , FMX.Types
  , Common.Constants
  , Common.Interfaces
  , Stage

  , Player.Net_06
  , Net_06

  ;

type
  TGroup = record
    Stage: TStage;
    TabItem: TTabItem;
    Label_Net_Description: TLabel;
    Memo_Log: TMemo;
    Thread: TThread;
  end;

type
  IUtils = interface
  ['{EAB4469F-2DF9-48E8-AEC5-0C5656737ABF}']
    function GetNeedStop: Boolean;
    procedure SetNeedStop(const AValue: Boolean);
    function GetIsPaused: Boolean;
    procedure SetIsPaused(const AValue: Boolean);
    property NeedStop: Boolean read GetNeedStop write SetNeedStop;
    property IsPaused: Boolean read GetIsPaused write SetIsPaused;

    procedure Start_Learn_Genetic(const ATabControl: TTabControl);
    procedure Start_Learn_BackPropagation(const ATabControl: TTabControl);

    function Check_Win_Side(const AField: TField; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
    function Check_Win_Vertical(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
    function Check_Win_Horizontal(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
    function Check_Win_Diagonal_11_33(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
    function Check_Win_Diagonal_31_13(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
    function Check_2_in_Line(const AField: TField; const ACellValue: TCellValue): Integer;
    function Count_Line(const ACellValueToFind: TCellValue; const ACellValue1: TCellValue; const ACellValue2: TCellValue; const ACellValue3: TCellValue): Integer;

    function Play_Party(var AFieldsLearning: array of TField; const APartyPlayers: TPartyPlayers; AResultEx: Boolean): TPartyResult;

    function Create_Player: IPlayerEx;
    function Create_Net: INet;
  end;

type
  TTemplate = record
    Name: string;
    MyValue: TCellValue;
    Field: TField;
    Is_2_In_Line_My: Boolean;
    Is_2_In_Line_Enemy: Boolean;
    ExpectedMove: TMoveEx;
  end;

  TCellValuesArray = array [0..7] of TCellValue;

const
  __CellValuesArray_X_: TCellValuesArray = (
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_, TCellValue._0_
  );

  __CellValuesArray_0_: TCellValuesArray = (
    TCellValue._0_,
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_, TCellValue._0_,
    TCellValue._X_
  );

type
  TUtils = class(TInterfacedObject, IUtils)
  strict private
    FMoves_X_: TDictionary<string, TTemplate>;
    FMoves_0_: TDictionary<string, TTemplate>;

    FCountLineMy: Integer;
    FCountLineEnemy: Integer;

    FNeedStop: Boolean;
    FIsPaused: Boolean;

    FFieldsPlay: TList<TField>;

    FGenerators: array of TGroup;
    FPreCandidates: array of TGroup;
    FCandidates: array of TGroup;
    FMaster: TGroup;

    FIndexThreadSafeGenerators: Integer;
    FIndexThreadSafePreCandidates: Integer;
    FIndexThreadSafeCandidates: Integer;
    FIndexThreadSafeLockGenerators: TObject;
    FIndexThreadSafeLockPreCandidates: TObject;
    FIndexThreadSafeLockCandidates: TObject;

    procedure FillField(const AMoves: TDictionary<string, TTemplate>; const AMyValue: TCellValue; const AFieldsLearning: TField; const ACellValuesArray: TCellValuesArray; const AIndexValues: Integer);
    procedure AddMovesAll(const AMoves: TDictionary<string, TTemplate>; const ACellValuesArray: TCellValuesArray; const AMyValue: TCellValue);
    procedure AddMove(const AMoves: TDictionary<string, TTemplate>; ATemplate: TTemplate; AForce: Boolean);

    function GetKey(AField: TField): string;
    function FlipVertical(ATemplate: TTemplate): TTemplate;
    function FlipHorizontal(ATemplate: TTemplate): TTemplate;
    function Turn(ATemplate: TTemplate): TTemplate;

    function Play_Template(const AMoves: TDictionary<string, TTemplate>; const APlayer: IPlayer; ACheckEmpty: Boolean; ACheck_2_In_Line_My: Boolean; ACheck_2_In_Line_Enemy: Boolean): Integer;

    procedure Learning_Field_Create(var AFieldsLearning: array of TField);

    procedure SortInstances(var AInstanceArray: TInstanceArray; APopulationCount: Integer);
    procedure TakeWinnersFromInput(const AGroup: TGroup; var AMaxWinnerLevel: Integer);
    procedure CopyInstance(const AInstanceFrom: TInstance; var AInstanceTo: TInstance);
    procedure ClearInstance(var AInstance: TInstance);

    procedure InitLevel(var AGroup: TLevel; APopulationCount: Integer);
    procedure CopyLevel(var AGroupFrom: TLevel; var AGroupTo: TLevel; APopulationCount: Integer);

    procedure FillRulesRandom(var AGroup: TGroup);
    procedure FillRulesMaster(var AGroup: TGroup);

    function CompareSort(const AInstance1: TInstance; const AInstance2: TInstance): Boolean; inline;
//    procedure CheckNet(APlayer: IPlayerEx; AResultTemplateOld: Integer);

    procedure UpdateLabel(const ALabel: TLabel; const AText: string);
    procedure UpdateLog(const AMemo: TMemo; const AText: string);

    procedure CreateGroup(const ATabControl: TTabControl; var AGroup: TGroup; AName: string; AUseLoad: Boolean; AIsMaster: Boolean; AHasInput: Boolean; AInputLength: Integer; APopulationCount: Integer; ARepeatLevelLast: Integer);

    procedure LearnAll(AGroup: TGroup; AOutput: array of TGroup);
    procedure Learn_BackPropagation(AGroup: TGroup; AOutput: array of TGroup);

    function Get_Count_Template_X_: Integer;
    function Get_Count_Template_0_: Integer;

    function Get_2_in_Line_Cell(const AField: TField; const ACellValue: TCellValue): TMoveEx;
    function Find_In_Line(const ACellValueToFind: TCellValue; const ACellValue1: TCellValue; const ACellValue2: TCellValue; const ACellValue3: TCellValue): Integer;

    function Play_Move(var AFieldsLearning: array of TField; const APlayer: IPlayer; const ACellValue: TCellValue; const ACountMoves: Integer; const AIsTeacher: Boolean; const AChangeField: Boolean): TMoveResult;

  public
    constructor Create;
    destructor Destroy; override;

    function GetNeedStop: Boolean;
    procedure SetNeedStop(const AValue: Boolean);
    function GetIsPaused: Boolean;
    procedure SetIsPaused(const AValue: Boolean);
    property NeedStop: Boolean read GetNeedStop write SetNeedStop;
    property IsPaused: Boolean read GetIsPaused write SetIsPaused;

    procedure Start_Learn_Genetic(const ATabControl: TTabControl);
    procedure Start_Learn_BackPropagation(const ATabControl: TTabControl);

    function Check_Win_Side(const AField: TField; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
    function Check_Win_Vertical(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
    function Check_Win_Horizontal(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
    function Check_Win_Diagonal_11_33(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
    function Check_Win_Diagonal_31_13(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
    function Check_2_in_Line(const AField: TField; const ACellValue: TCellValue): Integer;
    function Count_Line(const ACellValueToFind: TCellValue; const ACellValue1: TCellValue; const ACellValue2: TCellValue; const ACellValue3: TCellValue): Integer;

    function Play_Party(var AFieldsLearning: array of TField; const APartyPlayers: TPartyPlayers; AResultEx: Boolean): TPartyResult;
    function Play_Templates_All(const APlayer: IPlayer; ACheckEmpty: Boolean; ACheck_2_In_Line_My: Boolean; ACheck_2_In_Line_Enemy: Boolean): Integer;

    function Get_Count_Templates_All: Integer;
    function Get_Count_Line_My: Integer;
    function Get_Count_Line_Enemy: Integer;

    procedure CompareNetData(ANetData1: TNetData; ANetData2: TNetData);

    function Create_Player: IPlayerEx;
    function Create_Net: INet;
  end;

//public
var
  GUtils: IUtils;

implementation

uses
  System.SysUtils
  , System.StrUtils
  , System.Math
  , System.Types
  , System.IOUtils
  , Winapi.Windows
  , Player.Random
  ;

constructor TUtils.Create;
var
  LIndex: Integer;
begin
  inherited Create;

  FCountLineMy := 0;
  FCountLineEnemy := 0;

  FMoves_X_ := TDictionary<string, TTemplate>.Create;
  FMoves_0_ := TDictionary<string, TTemplate>.Create;

  AddMovesAll(FMoves_X_, __CellValuesArray_X_, TCellValue._X_);
  AddMovesAll(FMoves_0_, __CellValuesArray_0_, TCellValue._X_);

  FFieldsPlay := TList<TField>.Create;

  SetLength(FGenerators, __GENERATORS_COUNT);
  SetLength(FPreCandidates, __PRE_CANDIDATES_COUNT);
  SetLength(FCandidates, __CANDIDATES_COUNT);

  for LIndex := 0 to __GENERATORS_COUNT - 1 do
  begin
    FGenerators[LIndex].Stage := TStage.Create;
  end;

  for LIndex := 0 to __PRE_CANDIDATES_COUNT - 1 do
  begin
    FPreCandidates[LIndex].Stage := TStage.Create;
  end;

  for LIndex := 0 to __CANDIDATES_COUNT - 1 do
  begin
    FCandidates[LIndex].Stage := TStage.Create;
  end;

  FMaster.Stage := TStage.Create;

  FIndexThreadSafeLockGenerators := TObject.Create;
  FIndexThreadSafeLockPreCandidates := TObject.Create;
  FIndexThreadSafeLockCandidates := TObject.Create;

end;

destructor TUtils.Destroy;
var
  LIndex: Integer;
begin
  FreeAndNil(FMoves_X_);
  FreeAndNil(FMoves_0_);

  FFieldsPlay.Clear;

  for LIndex := 0 to __GENERATORS_COUNT - 1 do
  begin
    if (FGenerators[LIndex].Thread <> nil) then
    begin
      try
        FGenerators[LIndex].Thread.Terminate;
        FGenerators[LIndex].Thread.WaitFor;
        FreeAndNil(FGenerators[LIndex].Stage);
      except
        on E:EThread do
        begin
          // none
        end;
        on E:EAccessViolation do
        begin
          // none
        end;
        on E:Exception do
        begin
          // none
        end;
      end;
    end;
  end;
  for LIndex := 0 to __PRE_CANDIDATES_COUNT - 1 do
  begin
    if (FPreCandidates[LIndex].Thread <> nil) then
    begin
      try
        FPreCandidates[LIndex].Thread.Terminate;
        FPreCandidates[LIndex].Thread.WaitFor;
        FreeAndNil(FPreCandidates[LIndex].Stage);
      except
        on E:EThread do
        begin
          // none
        end;
        on E:EAccessViolation do
        begin
          // none
        end;
        on E:Exception do
        begin
          // none
        end;
      end;
    end;
  end;

  for LIndex := 0 to __CANDIDATES_COUNT - 1 do
  begin
    if (FCandidates[LIndex].Thread <> nil) then
    begin
      try
        FCandidates[LIndex].Thread.Terminate;
        FCandidates[LIndex].Thread.WaitFor;
        FreeAndNil(FCandidates[LIndex].Stage);
      except
        on E:EThread do
        begin
          // none
        end;
        on E:EAccessViolation do
        begin
          // none
        end;
        on E:Exception do
        begin
          // none
        end;
      end;
    end;
  end;

  if (FMaster.Thread <> nil) then
  begin
    try
      FMaster.Thread.Terminate;
      FMaster.Thread.WaitFor;
      FreeAndNil(FMaster.Stage);
    except
      on E:EThread do
      begin
        // none
      end;
      on E:EAccessViolation do
      begin
        // none
      end;
      on E:Exception do
      begin
        // none
      end;
    end;
  end;

  FreeAndNil(FIndexThreadSafeLockGenerators);
  FreeAndNil(FIndexThreadSafeLockPreCandidates);
  FreeAndNil(FIndexThreadSafeLockCandidates);

  inherited Destroy;

end;

function TUtils.GetNeedStop: Boolean;
begin
  Result := FNeedStop;
end;

procedure TUtils.SetNeedStop(const AValue: Boolean);
begin
  FNeedStop := AValue;
end;

function TUtils.GetIsPaused: Boolean;
begin
  Result := FIsPaused;
end;

procedure TUtils.SetIsPaused(const AValue: Boolean);
begin
  FIsPaused := AValue;
end;

procedure TUtils.FillField(const AMoves: TDictionary<string, TTemplate>; const AMyValue: TCellValue; const AFieldsLearning: TField; const ACellValuesArray: TCellValuesArray; const AIndexValues: Integer);
var
  LIndexY: Integer;
  LIndexX: Integer;
  LIndexTemplateY: Integer;
  LIndexTemplateX: Integer;
  LTemplateNew: TTemplate;
  LFieldsLearning: TField;
begin
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      if AFieldsLearning[LIndexY, LIndexX] = TCellValue.___ then
      begin
        for LIndexTemplateY := __MIN_Y to __MAX_Y do
        begin
          for LIndexTemplateX := __MIN_X to __MAX_X do
          begin
            LFieldsLearning[LIndexTemplateY, LIndexTemplateX] := AFieldsLearning[LIndexTemplateY, LIndexTemplateX];
          end;
        end;

        LFieldsLearning[LIndexY, LIndexX] := ACellValuesArray[AIndexValues];

        if AMyValue <> ACellValuesArray[AIndexValues] then
        begin
          LTemplateNew.Name := GetKey(LFieldsLearning);
          LTemplateNew.Field := LFieldsLearning;
          LTemplateNew.MyValue := AMyValue;
          LTemplateNew.Is_2_In_Line_My := False;
          LTemplateNew.Is_2_In_Line_Enemy := False;
          AddMove(AMoves, LTemplateNew, False);
        end;

        if AIndexValues < Length(ACellValuesArray) - 1 then
        begin
          FillField(AMoves, AMyValue, LFieldsLearning, ACellValuesArray, AIndexValues + 1);
        end
      end;
    end;
  end;
end;

procedure TUtils.AddMovesAll(const AMoves: TDictionary<string, TTemplate>; const ACellValuesArray: TCellValuesArray; const AMyValue: TCellValue);
var
  LIndexY: Integer;
  LIndexX: Integer;
  LFieldsLearning: TField;
  LIndexTemplate: Integer;
  LTemplate: TTemplate;
  LTemplateNew: TTemplate;
  LKeys: TArray<string>;
  LFieldNew: TField;
begin
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      LFieldsLearning[LIndexY, LIndexX] := TCellValue.___;
    end;
  end;

  FillField(AMoves, AMyValue, LFieldsLearning, ACellValuesArray, 0);

  LKeys := AMoves.Keys.ToArray;
  for LIndexTemplate := 0 to Length(LKeys) - 1 do
  begin
    LTemplate := AMoves[LKeys[LIndexTemplate]];

    if (Check_Win_Side(LTemplate.Field, TCellValue._X_, False)) or
       (Check_Win_Side(LTemplate.Field, TCellValue._0_, False)) then
    begin
      AMoves.Remove(LKeys[LIndexTemplate]);
      Continue;
    end;

    LTemplate.Is_2_In_Line_My := (Check_2_in_Line(LTemplate.Field, TCellValue._X_) > 0);
    if LTemplate.Is_2_In_Line_My then
    begin
      LTemplate.ExpectedMove := Get_2_in_Line_Cell(LTemplate.Field, TCellValue._X_);
      if (LTemplate.ExpectedMove.Y = -1) and (LTemplate.ExpectedMove.X = -1) then
      begin
        Assert(False);
      end
      else
      begin
        for LIndexY := __MIN_Y to __MAX_Y do
        begin
          for LIndexX := __MIN_X to __MAX_X do
          begin
            LFieldNew[LIndexY, LIndexX] := LTemplate.Field[LIndexY, LIndexX];
          end;
        end;
        LFieldNew[LTemplate.ExpectedMove.Y, LTemplate.ExpectedMove.X] := TCellValue._X_;
        if not Check_Win_Side(LFieldNew, TCellValue._X_, False) then
        begin
          Assert(False);
        end;
      end;
    end;
    AddMove(AMoves, LTemplate, True);
    if LTemplate.Is_2_In_Line_My then
    begin
      FCountLineMy := FCountLineMy + 1;
      Continue;
    end;

    LTemplate.Is_2_In_Line_Enemy := (Check_2_in_Line(LTemplate.Field, TCellValue._0_) > 0);
    if LTemplate.Is_2_In_Line_Enemy then
    begin
      LTemplate.ExpectedMove := Get_2_in_Line_Cell(LTemplate.Field, TCellValue._0_);
      if (LTemplate.ExpectedMove.Y = -1) and (LTemplate.ExpectedMove.X = -1) then
      begin
        Assert(False);
      end
      else
      begin
        for LIndexY := __MIN_Y to __MAX_Y do
        begin
          for LIndexX := __MIN_X to __MAX_X do
          begin
            LFieldNew[LIndexY, LIndexX] := LTemplate.Field[LIndexY, LIndexX];
          end;
        end;
        LFieldNew[LTemplate.ExpectedMove.Y, LTemplate.ExpectedMove.X] := TCellValue._X_;
        if Check_Win_Side(LFieldNew, TCellValue._0_, False) then
        begin
          Assert(False);
        end;
      end;
    end;
    AddMove(AMoves, LTemplate, True);
    if LTemplate.Is_2_In_Line_Enemy then
    begin
      FCountLineEnemy := FCountLineEnemy + 1;
      Continue;
    end;
  end;

  LKeys := AMoves.Keys.ToArray;
  for LIndexTemplate := 0 to Length(LKeys) - 1 do
  begin
    LTemplate := AMoves[LKeys[LIndexTemplate]];

    LTemplateNew := FlipVertical(LTemplate);
    AddMove(AMoves, LTemplateNew, False);

    LTemplateNew := FlipHorizontal(LTemplate);
    AddMove(AMoves, LTemplateNew, False);

    LTemplateNew := Turn(LTemplate);
    AddMove(AMoves, LTemplateNew, False);

    LTemplateNew := Turn(LTemplateNew);
    AddMove(AMoves, LTemplateNew, False);

    LTemplateNew := Turn(LTemplateNew);
    AddMove(AMoves, LTemplateNew, False);
  end;

end;

procedure TUtils.AddMove(const AMoves: TDictionary<string, TTemplate>; ATemplate: TTemplate; AForce: Boolean);
var
  LKey: string;
begin
  LKey := GetKey(ATemplate.Field);
  if (AForce) or (not AMoves.ContainsKey(LKey)) then
  begin
    AMoves.AddOrSetValue(LKey, ATemplate);
  end;
end;

function TUtils.GetKey(AField: TField): string;
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  Result := string.Empty;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    if not Result.IsEmpty then
    begin
      Result := Result + '/';
    end;
    for LIndexX := __MIN_X to __MAX_X do
    begin
      Result := Result + TCellKey[AField[LIndexY, LIndexX]];
    end;
  end;
end;

function TUtils.FlipVertical(ATemplate: TTemplate): TTemplate;
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  Result.MyValue := ATemplate.MyValue;
  Result.Name := ATemplate.Name + '.FlipVertical';
  Result.Is_2_In_Line_My := ATemplate.Is_2_In_Line_My;
  Result.Is_2_In_Line_Enemy := ATemplate.Is_2_In_Line_Enemy;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      Result.Field[LIndexY, LIndexX] := ATemplate.Field[__MAX_Y + 1 - LIndexY, LIndexX];
    end;
  end;

end;

function TUtils.FlipHorizontal(ATemplate: TTemplate): TTemplate;
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  Result.MyValue := ATemplate.MyValue;
  Result.Name := ATemplate.Name + '.FlipHorizontal';
  Result.Is_2_In_Line_My := ATemplate.Is_2_In_Line_My;
  Result.Is_2_In_Line_Enemy := ATemplate.Is_2_In_Line_Enemy;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      Result.Field[LIndexY, LIndexX] := ATemplate.Field[LIndexY, __MAX_X + 1 - LIndexX];
    end;
  end;

end;

function TUtils.Turn(ATemplate: TTemplate): TTemplate;
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  Result.MyValue := ATemplate.MyValue;
  Result.Name := ATemplate.Name + '.Turn';
  Result.Is_2_In_Line_My := ATemplate.Is_2_In_Line_My;
  Result.Is_2_In_Line_Enemy := ATemplate.Is_2_In_Line_Enemy;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      Result.Field[LIndexY, LIndexX] := ATemplate.Field[__MAX_X + 1 - LIndexX, LIndexY];
    end;
  end;

end;

function TUtils.Check_Win_Side(const AField: TField; const ACellValue: TCellValue; const AVisible: Boolean): Boolean;
begin
  Result := False;

  if (Check_Win_Vertical(AField, 3, ACellValue, 1)) or
     (Check_Win_Vertical(AField, 3, ACellValue, 2)) or
     (Check_Win_Vertical(AField, 3, ACellValue, 3)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 1)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 2)) or
     (Check_Win_Horizontal(AField, 3, ACellValue, 3)) or
     (Check_Win_Diagonal_11_33(AField, 3, ACellValue)) or
     (Check_Win_Diagonal_31_13(AField, 3, ACellValue)) then
  begin
    Result := True;
  end;

end;

function TUtils.Get_2_in_Line_Cell(const AField: TField; const ACellValue: TCellValue): TMoveEx;
begin
  Result.SelectedFigure := ACellValue;

  if ((Check_Win_Vertical(AField, 2, ACellValue, 1) and (Check_Win_Vertical(AField, 1, TCellValue.___, 1)))) then
  begin
    Result.X := 1;
    Result.Y := Find_In_Line(TCellValue.___, AField[1, Result.X], AField[2, Result.X], AField[3, Result.X]);
  end
  else if ((Check_Win_Vertical(AField, 2, ACellValue, 2) and (Check_Win_Vertical(AField, 1, TCellValue.___, 2)))) then
  begin
    Result.X := 2;
    Result.Y := Find_In_Line(TCellValue.___, AField[1, Result.X], AField[2, Result.X], AField[3, Result.X]);
  end
  else if ((Check_Win_Vertical(AField, 2, ACellValue, 3) and (Check_Win_Vertical(AField, 1, TCellValue.___, 3)))) then
  begin
    Result.X := 3;
    Result.Y := Find_In_Line(TCellValue.___, AField[1, Result.X], AField[2, Result.X], AField[3, Result.X]);
  end
  else if ((Check_Win_Horizontal(AField, 2, ACellValue, 1) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 1)))) then
  begin
    Result.Y := 1;
    Result.X := Find_In_Line(TCellValue.___, AField[Result.Y, 1], AField[Result.Y, 2], AField[Result.Y, 3]);
  end
  else if ((Check_Win_Horizontal(AField, 2, ACellValue, 2) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 2)))) then
  begin
    Result.Y := 2;
    Result.X := Find_In_Line(TCellValue.___, AField[Result.Y, 1], AField[Result.Y, 2], AField[Result.Y, 3]);
  end
  else if ((Check_Win_Horizontal(AField, 2, ACellValue, 3) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 3)))) then
  begin
    Result.Y := 3;
    Result.X := Find_In_Line(TCellValue.___, AField[Result.Y, 1], AField[Result.Y, 2], AField[Result.Y, 3]);
  end
  else if ((Check_Win_Diagonal_11_33(AField, 2, ACellValue) and (Check_Win_Diagonal_11_33(AField, 1, TCellValue.___)))) then
  begin
    Result.Y := Find_In_Line(TCellValue.___, AField[1, 1], AField[2, 2], AField[3, 3]);
    Result.X := Find_In_Line(TCellValue.___, AField[1, 1], AField[2, 2], AField[3, 3]);
  end
  else if ((Check_Win_Diagonal_31_13(AField, 2, ACellValue) and (Check_Win_Diagonal_31_13(AField, 1, TCellValue.___)))) then
  begin
    Result.Y := Find_In_Line(TCellValue.___, AField[1, 3], AField[2, 2], AField[3, 1]);
    Result.X := Find_In_Line(TCellValue.___, AField[3, 1], AField[2, 2], AField[1, 3]);
  end
  else
  begin
    Assert(False);
  end;

end;

function TUtils.Check_2_in_Line(const AField: TField; const ACellValue: TCellValue): Integer;
begin
  Result := 0;

  if ((Check_Win_Vertical(AField, 2, ACellValue, 1) and (Check_Win_Vertical(AField, 1, TCellValue.___, 1)))) then
  begin
    Result := Result + 1;
  end;
  if ((Check_Win_Vertical(AField, 2, ACellValue, 2) and (Check_Win_Vertical(AField, 1, TCellValue.___, 2)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Vertical(AField, 2, ACellValue, 3) and (Check_Win_Vertical(AField, 1, TCellValue.___, 3)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Horizontal(AField, 2, ACellValue, 1) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 1)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Horizontal(AField, 2, ACellValue, 2) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 2)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Horizontal(AField, 2, ACellValue, 3) and (Check_Win_Horizontal(AField, 1, TCellValue.___, 3)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Diagonal_11_33(AField, 2, ACellValue) and (Check_Win_Diagonal_11_33(AField, 1, TCellValue.___)))) then
  begin
    Result := Result + 1;
  end;

  if ((Check_Win_Diagonal_31_13(AField, 2, ACellValue) and (Check_Win_Diagonal_31_13(AField, 1, TCellValue.___)))) then
  begin
    Result := Result + 1;
  end;

end;

function TUtils.Count_Line(const ACellValueToFind: TCellValue; const ACellValue1: TCellValue; const ACellValue2: TCellValue; const ACellValue3: TCellValue): Integer;
begin
  Result := 0;

  if (ACellValueToFind = ACellValue1) then
  begin
    Result := Result + 1;
  end;

  if (ACellValueToFind = ACellValue2) then
  begin
    Result := Result + 1;
  end;

  if (ACellValueToFind = ACellValue3) then
  begin
    Result := Result + 1;
  end;

end;

function TUtils.Find_In_Line(const ACellValueToFind: TCellValue; const ACellValue1: TCellValue; const ACellValue2: TCellValue; const ACellValue3: TCellValue): Integer;
begin
  Result := 0;

  if (ACellValueToFind = ACellValue1) then
  begin
    Result := 1;
  end;

  if (ACellValueToFind = ACellValue2) then
  begin
    Result := 2;
  end;

  if (ACellValueToFind = ACellValue3) then
  begin
    Result := 3;
  end;

end;

function TUtils.Check_Win_Vertical(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
begin
  Result := (Count_Line(ACellValue, AField[1, AIndex], AField[2, AIndex], AField[3, AIndex]) = ACount);
end;

function TUtils.Check_Win_Horizontal(const AField: TField; const ACount: Integer; const ACellValue: TCellValue; const AIndex: Integer): Boolean;
begin
  Result := (Count_Line(ACellValue, AField[AIndex, 1], AField[AIndex, 2], AField[AIndex, 3]) = ACount);
end;

function TUtils.Check_Win_Diagonal_11_33(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
begin
  Result := (Count_Line(ACellValue, AField[1, 1], AField[2, 2], AField[3, 3]) = ACount);
end;

function TUtils.Check_Win_Diagonal_31_13(const AField: TField; const ACount: Integer; const ACellValue: TCellValue): Boolean;
begin
  Result := (Count_Line(ACellValue, AField[3, 1], AField[2, 2], AField[1, 3]) = ACount);
end;

function TUtils.Play_Party(var AFieldsLearning: array of TField; const APartyPlayers: TPartyPlayers; AResultEx: Boolean): TPartyResult;
var
  LIndexY: Integer;
  LIndexX: Integer;
  LEmptyCount: Integer;
  LMoveSide: TMoveSide;
  LMoveResult: TMoveResult;
  LCount_2_In_Line: Integer;
  LCountMoves: Integer;
  LIsTeacher : Boolean;
begin
  Result[TMoveSide.sideLeft] := 0;
  Result[TMoveSide.sideRight] := 0;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      AFieldsLearning[0][LIndexY, LIndexX] := TCellValue.___;
    end;
  end;

  LMoveSide := TMoveSide.sideLeft;
  LCountMoves := 0;
  LCount_2_In_Line := 0;

  repeat
    LIsTeacher := (LMoveSide = TMoveSide.sideRight);
    LMoveResult := Play_Move(AFieldsLearning, APartyPlayers[LMoveSide], TSideValues[LMoveSide], LCountMoves, LIsTeacher, True);

    if not LIsTeacher then
    begin
      LCount_2_In_Line := LCount_2_In_Line + LMoveResult.Count_2_In_Line;
    end;

    case LMoveSide of
      TMoveSide.sideLeft:
      begin
        LMoveSide := TMoveSide.sideRight;
      end;
      TMoveSide.sideRight:
      begin
        LMoveSide := TMoveSide.sideLeft;
      end;
    end;

    LEmptyCount := 0;
    for LIndexY := __MIN_Y to __MAX_Y do
    begin
      for LIndexX := __MIN_X to __MAX_X do
      begin
        if (AFieldsLearning[0][LIndexY, LIndexX] = TCellValue.___) then
        begin
          Inc(LEmptyCount);
        end;
      end;
    end;

    if (LEmptyCount = 0) then
    begin
      Break;
    end;

    LCountMoves := LCountMoves + 1;

  until (LMoveResult.IsEnd) or (LCountMoves >= __COUNT_MOVES_IN_PARTY_MAX);

  if AResultEx then
  begin
    if LMoveResult.IsWin then
    begin
      Result[TMoveSide.sideLeft] := __GOOD_WIN + (__COUNT_MOVES_IN_PARTY_MAX - LCountMoves);
    end
    else if not LMoveResult.IsLost then
    begin
      Result[TMoveSide.sideLeft] := __GOOD_NOT_LOST + LCount_2_In_Line * __GOOD_2_IN_LINE;
    end
    else
    begin
      Result[TMoveSide.sideLeft] := LCount_2_In_Line * __GOOD_2_IN_LINE;
    end;
  end
  else
  begin
    if LMoveResult.IsLost then
    begin
      Result[TMoveSide.sideLeft] := 0;
    end
    else
    begin
      Result[TMoveSide.sideLeft] := 1;
    end;
  end;

end;

function TUtils.Play_Move(var AFieldsLearning: array of TField; const APlayer: IPlayer; const ACellValue: TCellValue; const ACountMoves: Integer; const AIsTeacher: Boolean; const AChangeField: Boolean): TMoveResult;
var
  LMove: TMove;
begin
  Result.IsEnd := False;
  Result.IsWin := False;
  Result.IsLost := False;
  Result.IsEmpty := False;
  Result.Count_2_In_Line := 0;
  Result.Y := -1;
  Result.X := -1;

  if AIsTeacher then
  begin
    LMove := APlayer.GetNextMove(AFieldsLearning[0], ACellValue);

    if AFieldsLearning[0][LMove.Y, LMove.X] = TCellValue.___ then
    begin
      Result.Y := LMove.Y;
      Result.X := LMove.X;
      AFieldsLearning[0][LMove.Y, LMove.X] := LMove.SelectedFigure;
    end
    else
    begin
      repeat
        LMove.Y := __MIN_Y + Random(1 + __MAX_Y - __MIN_Y);
        LMove.X := __MIN_X + Random(1 + __MAX_X - __MIN_X);
      until (AFieldsLearning[0][LMove.Y, LMove.X] = TCellValue.___);

      Result.Y := LMove.Y;
      Result.X := LMove.X;
      AFieldsLearning[0][LMove.Y, LMove.X] := LMove.SelectedFigure;
    end;

    if Check_Win_Side(AFieldsLearning[0], ACellValue, False) then
    begin
      Result.IsWin := False;
      Result.IsLost := True;
      Result.IsEnd := True;
    end;

  end
  else
  begin
    LMove := APlayer.GetNextMove(AFieldsLearning[0], ACellValue);

    Result.Y := LMove.Y;
    Result.X := LMove.X;

    if (AFieldsLearning[0][LMove.Y, LMove.X] <> TCellValue.___) then
    begin
      Result.IsEmpty := False;
      Result.IsWin := False;
      Result.IsLost := True;
      Result.IsEnd := True;
      Exit;
    end;

    Result.IsEmpty := True;

    if AChangeField then
    begin
      AFieldsLearning[0][LMove.Y, LMove.X] := LMove.SelectedFigure;
    end;

    Result.Count_2_In_Line := Check_2_in_Line(AFieldsLearning[0], ACellValue);

    if Check_Win_Side(AFieldsLearning[0], ACellValue, False) then
    begin
      Result.IsWin := True;
      Result.IsLost := False;
      Result.IsEnd := True;
    end;

  end;

end;

function TUtils.Get_Count_Template_X_: Integer;
begin
  Result := FMoves_X_.Keys.Count;
end;

function TUtils.Get_Count_Template_0_: Integer;
begin
  Result := FMoves_0_.Keys.Count;
end;

function TUtils.Get_Count_Templates_All: Integer;
begin
  Result :=
    FMoves_X_.Keys.Count +
    FMoves_0_.Keys.Count;
end;

function TUtils.Get_Count_Line_My: Integer;
begin
  Result := FCountLineMy;
end;

function TUtils.Get_Count_Line_Enemy: Integer;
begin
  Result := FCountLineEnemy;
end;

function TUtils.Play_Templates_All(const APlayer: IPlayer; ACheckEmpty: Boolean; ACheck_2_In_Line_My: Boolean; ACheck_2_In_Line_Enemy: Boolean): Integer;
begin
  Result :=
    Play_Template(FMoves_X_, APlayer, ACheckEmpty, ACheck_2_In_Line_My, ACheck_2_In_Line_Enemy) +
    Play_Template(FMoves_0_, APlayer, ACheckEmpty, ACheck_2_In_Line_My, ACheck_2_In_Line_Enemy);
end;

function TUtils.Play_Template(const AMoves: TDictionary<string, TTemplate>; const APlayer: IPlayer; ACheckEmpty: Boolean; ACheck_2_In_Line_My: Boolean; ACheck_2_In_Line_Enemy: Boolean): Integer;
var
  LMySide: TMoveSide;
//  LEnemySide: TMoveSide;
  LField: TField;
  LIndexTemplate: Integer;
  LTemplate: TTemplate;
  LKeys: TArray<string>;
  LMove: TMove;
begin
  Result := 0;

  Assert(IfThen(ACheckEmpty, 1, 0) + IfThen(ACheck_2_In_Line_My, 1, 0) + IfThen(ACheck_2_In_Line_Enemy, 1, 0) = 1);

  LMySide := TMoveSide.sideLeft;
//  LEnemySide := TMoveSide.sideLeft;

  LKeys := AMoves.Keys.ToArray;

  for LIndexTemplate := 0 to Length(LKeys) - 1 do
  begin
    LTemplate := AMoves[LKeys[LIndexTemplate]];
    LField := LTemplate.Field;
    LMove := APlayer.GetNextMove(LField, TSideValues[LMySide]);
    if (LMove.Y <> -1) and (LMove.X <> -1) then
    begin
      if (LField[LMove.Y, LMove.X] = TCellValue.___) then
      begin
        if (ACheckEmpty) then
        begin
          Result := Result + __GOOD_TEMPLATE;
          Continue;
        end;
      end
      else
      begin
        Continue;
      end;

      if (ACheck_2_In_Line_My) and (LTemplate.Is_2_In_Line_My) then
      begin
        Assert(LTemplate.ExpectedMove.Y <> -1);
        Assert(LTemplate.ExpectedMove.X <> -1);
        if (LTemplate.ExpectedMove.Y = LMove.Y) and (LTemplate.ExpectedMove.X = LMove.X) then
        begin
          Result := Result + __GOOD_TEMPLATE;
          Continue;
        end;
      end;

      if (ACheck_2_In_Line_Enemy) and (LTemplate.Is_2_In_Line_Enemy) then
      begin
        Assert(LTemplate.ExpectedMove.Y <> -1);
        Assert(LTemplate.ExpectedMove.X <> -1);
        if (LTemplate.ExpectedMove.Y = LMove.Y) and (LTemplate.ExpectedMove.X = LMove.X) then
        begin
          Result := Result + __GOOD_TEMPLATE;
          Continue;
        end;
      end;

    end;
  end;

end;

procedure TUtils.CompareNetData(ANetData1: TNetData; ANetData2: TNetData);
var
  LCount_Hidden_Layers: Integer;
  LCount_Neurons: Integer;
  LCount_Links: Integer;
begin
    Assert(ANetData1.Count_Hidden_Layers = ANetData2.Count_Hidden_Layers);

    for LCount_Hidden_Layers := 0 to ANetData1.Count_Hidden_Layers - 1 do
    begin
      if not(ANetData1.HiddenLayers[LCount_Hidden_Layers].Count_Neurons = ANetData2.HiddenLayers[LCount_Hidden_Layers].Count_Neurons) then
        Assert(ANetData1.HiddenLayers[LCount_Hidden_Layers].Count_Neurons = ANetData2.HiddenLayers[LCount_Hidden_Layers].Count_Neurons);
      for LCount_Neurons := 0 to ANetData1.HiddenLayers[LCount_Hidden_Layers].Count_Neurons - 1 do
      begin
        if not (CompareValue(ANetData1.HiddenLayers[LCount_Hidden_Layers].Neurons_Thresholds[LCount_Neurons], ANetData2.HiddenLayers[LCount_Hidden_Layers].Neurons_Thresholds[LCount_Neurons]) = EqualsValue) then
          Assert(CompareValue(ANetData1.HiddenLayers[LCount_Hidden_Layers].Neurons_Thresholds[LCount_Neurons], ANetData2.HiddenLayers[LCount_Hidden_Layers].Neurons_Thresholds[LCount_Neurons]) = EqualsValue);

        for LCount_Links := 0 to ANetData1.HiddenLayers[LCount_Hidden_Layers].Count_Links - 1 do
        begin
          if not (CompareValue(ANetData1.HiddenLayers[LCount_Hidden_Layers].Links_Weights[LCount_Neurons][LCount_Links], ANetData2.HiddenLayers[LCount_Hidden_Layers].Links_Weights[LCount_Neurons][LCount_Links]) = EqualsValue) then
            Assert(CompareValue(ANetData1.HiddenLayers[LCount_Hidden_Layers].Links_Weights[LCount_Neurons][LCount_Links], ANetData2.HiddenLayers[LCount_Hidden_Layers].Links_Weights[LCount_Neurons][LCount_Links]) = EqualsValue);
        end;
      end;
    end;

    if not (ANetData1.OutputLayer.Count_Neurons = ANetData1.OutputLayer.Count_Neurons)then
      Assert(ANetData1.OutputLayer.Count_Neurons = ANetData1.OutputLayer.Count_Neurons);
    for LCount_Neurons := 0 to ANetData1.OutputLayer.Count_Neurons - 1 do
    begin
      if not (ANetData1.OutputLayer.Neurons_Thresholds[LCount_Neurons] = ANetData2.OutputLayer.Neurons_Thresholds[LCount_Neurons]) then
        Assert(ANetData1.OutputLayer.Neurons_Thresholds[LCount_Neurons] = ANetData2.OutputLayer.Neurons_Thresholds[LCount_Neurons]);

      for LCount_Links := 0 to ANetData1.OutputLayer.Count_Links - 1 do
      begin
        if not (CompareValue(ANetData1.OutputLayer.Links_Weights[LCount_Neurons][LCount_Links], ANetData2.OutputLayer.Links_Weights[LCount_Neurons][LCount_Links]) = EqualsValue) then
          Assert(CompareValue(ANetData1.OutputLayer.Links_Weights[LCount_Neurons][LCount_Links], ANetData2.OutputLayer.Links_Weights[LCount_Neurons][LCount_Links]) = EqualsValue);
      end;
    end;

end;

procedure TUtils.LearnAll(AGroup: TGroup; AOutput: array of TGroup);
var
  LCountLevels: Integer;
  LIndexGenerate: Integer;
  LIndexOrigin: Integer;
  LIndexPopulationLeft: Integer;
  LIndexPopulationRight: Integer;
  LPartiesCount: Integer;
  LResultSum: Integer;
  LResultRandomSum: Integer;
  LEnemyRandom: IPlayer;
  LIndexGeneration: Integer;
  LIndexReproduce1: Integer;
  LIndexReproduce2: Integer;
  LIndexParty: Integer;
  LResultParty: TPartyResult;
  LPartyPlayers: TPartyPlayers;
  LPlayer: IPlayer;
  LResult: Integer;
  LIndexLevel: Integer;
  LMaxWinnerLevel: Integer;
  LLimitCurrent: Integer;
  LCopyWinner: Boolean;
  LLimitNext: TLimit;
  LLimitMaxWinner: TLimit;
  LIndexWinners: Integer;
  LIndexMerge: Integer;
  LLevelGenerateCount: Integer;
  LIndexLevelGenerate: Integer;
  LMergeWinners: TInstanceArray;
  LFiles: TStringDynArray;
  LFileName: string;
  LWinnerUp: Boolean;
  LFieldsLearning: array of TField;
  LIndexOutput: Integer;
  LFoundOutput: Boolean;
  LOutputLengthMin: Integer;
  LOutputLengthMinIndex: Integer;
  LForceLastNeuron: Boolean;
  LCount_Neurons: Integer;
  LProbabilityAdd: Double;
  LProbabilityDelete: Double;
  LResultValueMax: Int64;
  LResultValueMaxNeuronCount: Int64;
  LTestMaxWinnerResult: Int64;
  LNeuronAdded: Boolean;
  LNeuronDeleted: Boolean;
  LLastNeuronAddedOrDeleted: Boolean;
  LTempInstance: TInstance;
  LTempResultWinner1: Int64;
  LTempResulteOrigin1: Int64;
  LTempResultWinner2: Int64;
  LTempResulteOrigin2: Int64;
  LTempResultWinner3: Int64;
  LTempResulteOrigin3: Int64;
begin
  UpdateLog(AGroup.Memo_Log, 'Start');
  UpdateLabel(AGroup.Label_Net_Description, Format('Generations=%d, Population=%d, Repeat=%d', [__GENERATION_COUNT, AGroup.Stage.PopulationCount, AGroup.Stage.RepeatLevelLast]));

  SetLength(LFieldsLearning, 1);
  Learning_Field_Create(LFieldsLearning);

  FNeedStop := False;
  FIsPaused := False;

  LCountLevels := 1;
  AGroup.Stage.SetPopulatonLength(LCountLevels);

  LIndexLevel := 0;
  InitLevel(AGroup.Stage.Populaton[LIndexLevel], AGroup.Stage.PopulationCount);

  LEnemyRandom := TPlayer_Random.Create;

  if AGroup.Stage.IsMaster then
  begin
    FillRulesMaster(AGroup);
  end;

  if AGroup.Stage.Load then
  begin
    if TDirectory.Exists('ini') then
    begin
      LFiles := TDirectory.GetFiles(TPath.Combine(TDirectory.GetCurrentDirectory,'ini'), '*.ini', TSearchOption.soAllDirectories);

      if AGroup.Stage.Rules.NewCopy * AGroup.Stage.PopulationCount > Length(LFiles) then
      begin
        UpdateLog(AGroup.Memo_Log, Format('loading (%d)...', [Length(LFiles)]));
      end
      else
      begin
        UpdateLog(AGroup.Memo_Log, Format('loading (%d of %d)...', [Round(AGroup.Stage.Rules.NewCopy * AGroup.Stage.PopulationCount), Length(LFiles)]));
      end;

      if (Length(LFiles) > 0) then
      begin
        AGroup.Stage.IsInited := True;
      end;

      LIndexLevel := 0;
      LIndexWinners := 0;

      for LFileName in LFiles do
      begin
        ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners]);
        AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player := Create_Player;
        AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet.ReadIniFile(LFileName);
        AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Id := LIndexWinners.ToString;
        AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Id := '.i.' + LIndexLevel.ToString + '.' + AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet.Id;

        AGroup.Stage.Populaton[LIndexLevel].Winners.Count := AGroup.Stage.Populaton[LIndexLevel].Winners.Count + 1;
        LIndexWinners := LIndexWinners + 1;
        if LIndexWinners >= AGroup.Stage.Rules.NewCopy * AGroup.Stage.PopulationCount - 1 then
        begin
          Break;
        end;
      end;
      SortInstances(AGroup.Stage.Populaton[LIndexLevel].Winners, AGroup.Stage.PopulationCount);
    end
    else
    begin
      UpdateLog(AGroup.Memo_Log, Format('no ini directory...', []));
    end;
  end;

  LCountLevels := 1;
  LMaxWinnerLevel := 0;
  LIndexLevel := 0;

  LResultValueMax := 0;
  LResultValueMaxNeuronCount := 0;
  LLastNeuronAddedOrDeleted := True;

  AGroup.Stage.IsWaiting := False;

  for LIndexGeneration := 0 to __GENERATION_COUNT - 1 do
  begin
    AGroup.Stage.Populaton[LIndexLevel].Limit.ResultMax := 0;
    AGroup.Stage.Populaton[LIndexLevel].Limit.ResultMin := 0;

    LLevelGenerateCount := AGroup.Stage.RepeatLevelLast;

    if (not AGroup.Stage.IsInited) then
    begin
      AGroup.Stage.IsInited := True;
      UpdateLog(AGroup.Memo_Log, 'init...');

      LLevelGenerateCount := Round(__REPEAT_GENERATOR / 2);
    end;

    if (AGroup.Stage.HasInput) and (AGroup.Stage.Populaton[LIndexLevel].Winners.Count = 0) then
    begin
      UpdateLog(AGroup.Memo_Log, 'no winners...');

      TMonitor.Enter(AGroup.Stage.InputLock);
      try
        if Length(AGroup.Stage.Input) > 0 then
        begin
          UpdateLog(AGroup.Memo_Log, Format('winners: %d level(s)', [Length(AGroup.Stage.Input)]));
        end
        else
        begin
          UpdateLog(AGroup.Memo_Log, 'init...');
        end;
      finally
        TMonitor.Exit(AGroup.Stage.InputLock);
      end;

      if (AGroup.Stage.HasInput) then
      begin
        TakeWinnersFromInput(AGroup, LMaxWinnerLevel);
      end;
    end;

    if not AGroup.Stage.IsMaster then
    begin
      FillRulesRandom(AGroup);
    end;

    begin
      LWinnerUp := False;
      LIndexLevelGenerate := 0;
      while (LIndexLevelGenerate <= LLevelGenerateCount - 1) and (not LWinnerUp) do
      begin
        LIndexOrigin := 0;
        AGroup.Stage.Populaton[LIndexLevel].Origin.Count := 0;

        LForceLastNeuron := False;
        LNeuronAdded := False;
        LNeuronDeleted := False;

//        // test
//        if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
//        begin
//          CopyInstance(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0], LTempInstance);
//          LTempInstance.Player := Create_Player;
//          LTempInstance.Player.Net.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].Player.Net);
//        end
//        else
//        begin
//          LTempInstance.Player := nil;
//          LTempInstance.ResultTemplateEmpty := 0;
//        end;

        if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
        begin
          LProbabilityAdd := __NEW_MUTATE_ADD_NEURON;
          LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON;

          if (AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].Player.Net.GetNetData.Count_Hidden_Layers >= 1) then
          begin
            LCount_Neurons := AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].Player.Net.GetNetData.HiddenLayers[0].Count_Neurons;

            if (LCount_Neurons <= (__ADD_DELETE_NEURON_COUNT_LIMIT * LResultValueMaxNeuronCount)) then
            begin
              LProbabilityAdd := __NEW_MUTATE_ADD_NEURON * 2;
              LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON / 2;
            end
            else if (LCount_Neurons <= (LResultValueMaxNeuronCount)) then
            begin
              LProbabilityAdd := __NEW_MUTATE_ADD_NEURON;
              LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON;
            end
            else if (LCount_Neurons > (LResultValueMaxNeuronCount)) then
            begin
              LProbabilityAdd := __NEW_MUTATE_ADD_NEURON / 2;
              LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON * 2;
            end
            else
            begin
              Assert(False);
            end;

            if LCount_Neurons <> 0 then
            begin
              LProbabilityAdd := LProbabilityAdd + 1/LCount_Neurons;
              LProbabilityDelete := LProbabilityDelete - 1/LCount_Neurons;
            end;

          end;

//          if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
//          begin
//            //__NEW_MUTATE_ADD_NEURON
//            if LCount_Neurons < 50 then
//            begin
//              LProbabilityAdd := __NEW_MUTATE_ADD_NEURON;
//            end
//            else
//            begin
//              LProbabilityAdd := 0.1;
//            end;
//
//            //__NEW_MUTATE_DELETE_NEURON
//            LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON;
//            if (AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].Player.Net.GetNetData.Count_Hidden_Layers >= 1) then
//            begin
//              LCount_Neurons := AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].Player.Net.GetNetData.HiddenLayers[0].Count_Neurons;
//              if LCount_Neurons < 5 then
//              begin
//                LProbabilityDelete := 0.3;
//              end
//              else if LCount_Neurons < 15 then
//              begin
//                LProbabilityDelete := 0.4;
//              end
//              else if LCount_Neurons < 40 then
//              begin
//                LProbabilityDelete := 0.5;
//              end
//              else
//              begin
//                LProbabilityDelete := 0.6;
//              end;
//            end;
//          end;

          if (not LLastNeuronAddedOrDeleted) and (Random() <= LProbabilityAdd) then
          begin
            //__NEW_MUTATE_ADD_NEURON
            LNeuronAdded := True;

            LForceLastNeuron := True;
            for LIndexWinners := 0 to AGroup.Stage.Populaton[LIndexLevel].Winners.Count - 1 do
            begin
              Assert(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player <> nil);

              AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet.FillMutateAddNeuron;
            end;
          end
          else if (not LLastNeuronAddedOrDeleted) and (Random() <= LProbabilityDelete) then
          begin
            //__NEW_MUTATE_DELETE_NEURON
            LNeuronDeleted := True;

            for LIndexWinners := 0 to AGroup.Stage.Populaton[LIndexLevel].Winners.Count - 1 do
            begin
              Assert(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player <> nil);

              AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet.FillMutateDeleteNeuron(
                Random() < 0.5,
                AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].HasResult,
                IfThen(LResultValueMax = 0, 0.0, AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultValue / LResultValueMax));
            end;
          end;

          LLastNeuronAddedOrDeleted := LNeuronAdded or LNeuronDeleted;

//          if LNeuronAdded or LNeuronDeleted then
//          begin
//            for LIndexWinners := 0 to AGroup.Stage.Populaton[LIndexLevel].Winners.Count - 1 do
//            begin
//              ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player;
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id :=
//                IfThen(LNeuronAdded, '.w.na.', IfThen(LNeuronDeleted, '.w.nd.', '???')) +
//                LIndexWinners.ToString;
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;
//
//              LIndexOrigin := LIndexOrigin + 1;
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;
//            end;
//          end
//          else
          begin
            // copy
            for LIndexWinners := 0 to Max(1, Min(AGroup.Stage.Populaton[LIndexLevel].Winners.Count, Trunc(AGroup.Stage.Rules.NewCopy * AGroup.Stage.PopulationCount))) - 1 do
            begin
              ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player;
              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.c.' + LIndexWinners.ToString;
              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

              LIndexOrigin := LIndexOrigin + 1;
              AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;
            end;

            begin
              //reproduce
              if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 2) then
              begin
                for LIndexGenerate := 0 to Trunc(AGroup.Stage.Rules.NewReproduce * AGroup.Stage.PopulationCount) - 1 do
                begin
                  LIndexReproduce1 := Trunc(Random() * Min(AGroup.Stage.Rules.NewCopy * AGroup.Stage.PopulationCount, AGroup.Stage.Populaton[LIndexLevel].Winners.Count) - 1);
                  LIndexReproduce2 := Trunc(Random() * (AGroup.Stage.Populaton[LIndexLevel].Winners.Count - 1));

                  Assert(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexReproduce1].Player <> nil);
                  // test
                  if not(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexReproduce2].Player <> nil) then
                    Assert(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexReproduce2].Player <> nil);

                  ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyReproduce(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexReproduce1].Player.GetNet, AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexReproduce2].Player.GetNet);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.r.' + LIndexLevel.ToString + '' + LIndexOrigin.ToString;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

                  AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

                  LIndexOrigin := LIndexOrigin + 1;
                end;
              end;

  //            //__NEW_WINNER_MUTATE_ADD_LEVEL
  //            if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
  //            begin
  //              LIndexWinners := 0;
  //              for LIndexGenerate := 0 to Ceil(AGroup.Stage.Rules.NewMutateAddLevel * AGroup.Stage.PopulationCount) - 1 do
  //              begin
  //                ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
  //                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
  //                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet);
  //                if not AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.TryFillMutateAddLevel then
  //                begin
  //                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.FillMutate(__NEW_WINNER_MUTATE_FEW, __NEW_WINNER_MUTATE_LOW, False);
  //                end;
  //                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.m.a.l.' + LIndexOrigin.ToString;
  //                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;
  //
  //                AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;
  //
  //                LIndexOrigin := LIndexOrigin + 1;
  //                LIndexWinners := LIndexWinners + 1;
  //                if (LIndexWinners >= AGroup.Stage.Populaton[LIndexLevel].Winners.Count) then
  //                begin
  //                  LIndexWinners := 0;
  //                end;
  //              end;
  //            end;

              //__NEW_WINNER_MUTATE_FEW_LOW
              if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
              begin
                LIndexWinners := 0;
                for LIndexGenerate := 0 to Ceil(AGroup.Stage.Rules.NewMutateFewLow * AGroup.Stage.PopulationCount) - 1 do
                begin
                ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.FillMutate(__NEW_WINNER_MUTATE_FEW, __NEW_WINNER_MUTATE_LOW, LForceLastNeuron);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.m.fl.' + LIndexOrigin.ToString;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

                  AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

                  LIndexOrigin := LIndexOrigin + 1;
                  LIndexWinners := LIndexWinners + 1;
                  if (LIndexWinners >= AGroup.Stage.Populaton[LIndexLevel].Winners.Count) then
                  begin
                    LIndexWinners := 0;
                  end;
                end;
              end;

              //__NEW_WINNER_MUTATE_FEW_HIGH
              if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
              begin
                LIndexWinners := 0;
                for LIndexGenerate := 0 to Ceil(AGroup.Stage.Rules.NewMutateFewHigh * AGroup.Stage.PopulationCount) - 1 do
                begin
                  ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.FillMutate(__NEW_WINNER_MUTATE_FEW, __NEW_WINNER_MUTATE_HIGH, LForceLastNeuron);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.m.fh.' + LIndexOrigin.ToString;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

                  AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

                  LIndexOrigin := LIndexOrigin + 1;
                  LIndexWinners := LIndexWinners + 1;
                  if (LIndexWinners >= AGroup.Stage.Populaton[LIndexLevel].Winners.Count) then
                  begin
                    LIndexWinners := 0;
                  end;
                end;
              end;

              //__NEW_WINNER_MUTATE_MANY_LOW
              if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
              begin
                LIndexWinners := 0;
                for LIndexGenerate := 0 to Ceil(AGroup.Stage.Rules.NewMutateManyLow * AGroup.Stage.PopulationCount) - 1 do
                begin
                  ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.FillMutate(__NEW_WINNER_MUTATE_MANY, __NEW_WINNER_MUTATE_LOW, LForceLastNeuron);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.m.ml.' + LIndexOrigin.ToString;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

                  AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

                  LIndexOrigin := LIndexOrigin + 1;
                  LIndexWinners := LIndexWinners + 1;
                  if (LIndexWinners >= AGroup.Stage.Populaton[LIndexLevel].Winners.Count) then
                  begin
                    LIndexWinners := 0;
                  end;
                end;
              end;

              //__NEW_WINNER_MUTATE_MANY_HIGH
              if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count >= 1) then
              begin
                LIndexWinners := 0;
                for LIndexGenerate := 0 to Ceil(AGroup.Stage.Rules.NewMutateManyHigh * AGroup.Stage.PopulationCount) - 1 do
                begin
                  ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CopyAll(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.GetNet);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.FillMutate(__NEW_WINNER_MUTATE_MANY, __NEW_WINNER_MUTATE_HIGH, LForceLastNeuron);
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.w.m.mh.' + LIndexOrigin.ToString;
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

                  AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

                  LIndexOrigin := LIndexOrigin + 1;
                  LIndexWinners := LIndexWinners + 1;
                  if (LIndexWinners >= AGroup.Stage.Populaton[LIndexLevel].Winners.Count) then
                  begin
                    LIndexWinners := 0;
                  end;
                end;
              end;
            end;
          end;
        end;

        // random
        while (LIndexOrigin <= AGroup.Stage.PopulationCount - 1) do
        begin
          ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player := Create_Player;
          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.CreateRandom;
          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id := '.r.' + LIndexOrigin.ToString;
          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Id := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.Id + '.' + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.GetNetDescription + AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].Player.GetNet.Id;

          AGroup.Stage.Populaton[LIndexLevel].Origin.Count := AGroup.Stage.Populaton[LIndexLevel].Origin.Count  + 1;

          LIndexOrigin := LIndexOrigin + 1;
        end;

        if not (LIndexOrigin = AGroup.Stage.PopulationCount) then
          Assert(LIndexOrigin = AGroup.Stage.PopulationCount);
        if not (AGroup.Stage.Populaton[LIndexLevel].Origin.Count = AGroup.Stage.PopulationCount) then
          Assert(AGroup.Stage.Populaton[LIndexLevel].Origin.Count = AGroup.Stage.PopulationCount);

        LTestMaxWinnerResult := 0;
        if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count > 0) then
        begin
          if AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].HasResult then
          begin
            LTestMaxWinnerResult := AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[0].ResultValue;
          end;
        end;

        for LIndexWinners := 0 to AGroup.Stage.PopulationCount - 1 do
        begin
          ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners]);
        end;
        AGroup.Stage.Populaton[LIndexLevel].Winners.Count := 0;

        // play
        for LIndexPopulationLeft := 0 to AGroup.Stage.Populaton[LIndexLevel].Origin.Count - 1 do
        begin
          Assert(Supports(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player, IPlayer, LPartyPlayers[TMoveSide.sideLeft]));

//          // test
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineMy := 0;
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy := 0;
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty := 0;

          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineMy    := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], False, True, False);
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], False, False, True);
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty     := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);

          // template - my
//          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineMy := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], False, True, False);
//          if AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineMy < Get_Count_Line_My * __SKIP_LIMIT then
//          begin
//            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy := 0;
//            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty := 0;
//          end
//          else
//          begin
//            // template - enemy
//            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], False, False, True);
//
//            if AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy < Get_Count_Line_Enemy * __SKIP_LIMIT then
//            begin
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty := 0;
//            end
//            else
//            begin
//              // template - empty
//              AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);
//            end;
//          end;

//          // test
//          if LTempInstance.Player <> nil then
//          begin
//            if (not LNeuronAdded) and (not LNeuronDeleted) then
//            begin
//              CompareNetData(LTempInstance.Player.Net.GetNetData, AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].Player.Net.GetNetData);
//            end;
//
//            LTempResulteOrigin1 := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].ResultTemplateEmpty;
//            LTempResultWinner1 := LTempInstance.ResultTemplateEmpty;
//
//            if (LTempInstance.ResultTemplateEmpty <> AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].ResultTemplateEmpty) and (not LNeuronDeleted) then
//            begin
//              Assert(Supports(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player, IPlayer, LPartyPlayers[TMoveSide.sideLeft]));
//              LTempResulteOrigin2 := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);
//
//              Assert(Supports(LTempInstance.Player, IPlayer, LPartyPlayers[TMoveSide.sideLeft]));
//              LTempResultWinner2 := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);
//            end;
//          end;

          if AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty < Get_Count_Templates_All * __SKIP_LIMIT then
          begin
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultAvg := 0;
          end
          else
          begin
            // origin
            LResultSum := 0;
            LPartiesCount := Min(AGroup.Stage.Rules.PartiesCount, AGroup.Stage.Populaton[LIndexLevel].Origin.Count);
            for LIndexParty := 0 to LPartiesCount - 1 do
            begin
              LIndexPopulationRight := LIndexParty;
              Assert(Supports(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationRight].Player, IPlayer, LPartyPlayers[TMoveSide.sideRight]));

              LResultParty := Play_Party(LFieldsLearning, LPartyPlayers, True);

              LPartyPlayers[TMoveSide.sideRight] := nil;
              if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].HasResult) then
              begin
                if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMin > LResultParty[TMoveSide.sideLeft]) then
                begin
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMin := LResultParty[TMoveSide.sideLeft];
                end;
                if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMax < LResultParty[TMoveSide.sideLeft]) then
                begin
                  AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMax := LResultParty[TMoveSide.sideLeft];
                end;
              end
              else
              begin
                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].HasResult := True;

                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMin := LResultParty[TMoveSide.sideLeft];
                AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultMax := LResultParty[TMoveSide.sideLeft];
              end;

              LResultSum := LResultSum + LResultParty[TMoveSide.sideLeft];
            end;

            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultAvg := Round(LResultSum / LPartiesCount);
          end;

          if AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultAvg < __GOOD_WIN * __SKIP_LIMIT then
          begin
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultRandom := 0;
          end
          else
          begin
            // random
            LResultRandomSum := 0;
            Assert(Supports(LEnemyRandom, IPlayer, LPartyPlayers[TMoveSide.sideRight]));
            for LIndexParty := 0 to AGroup.Stage.Rules.PartiesCount - 1 do
            begin
              LResultParty := Play_Party(LFieldsLearning, LPartyPlayers, False);
              LResultRandomSum := LResultRandomSum + LResultParty[TMoveSide.sideLeft]
            end;
            LPartyPlayers[TMoveSide.sideRight] := nil;
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultRandom := LResultRandomSum;
          end;

//          CheckNet(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player, AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplate);

          LPartyPlayers[TMoveSide.sideLeft] := nil;

          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].HasResult := True;

          AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultValue :=
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineMy    * (__LEN_RANDOM * __LEN_AVG * __LEN_TEMPLATE_EMPTY * __LEN_TEMPLATE_ENEMY) +
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateLineEnemy * (__LEN_RANDOM * __LEN_AVG * __LEN_TEMPLATE_EMPTY) +
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultTemplateEmpty     * (__LEN_RANDOM * __LEN_AVG) +
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultAvg               * (__LEN_RANDOM) +
            AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultRandom;

          if (LResultValueMax < AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultValue) then
          begin
            LResultValueMax := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultValue;
            if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player.Net.GetNetData.Count_Hidden_Layers >= 1) then
            begin
              LResultValueMaxNeuronCount := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player.Net.GetNetData.HiddenLayers[0].Count_Neurons;
            end;
          end
          else if (LResultValueMax = AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].ResultValue) then
          begin
            if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player.Net.GetNetData.Count_Hidden_Layers >= 1) then
            begin
              if (LResultValueMaxNeuronCount > AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player.Net.GetNetData.HiddenLayers[0].Count_Neurons) then
              begin
                LResultValueMaxNeuronCount := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player.Net.GetNetData.HiddenLayers[0].Count_Neurons;
              end;
            end;
          end;
        end;

        SortInstances(AGroup.Stage.Populaton[LIndexLevel].Origin, AGroup.Stage.PopulationCount);

//        // test
//        if LTempInstance.Player <> nil then
//        begin
//          if (LTempInstance.ResultTemplateEmpty > AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].ResultTemplateEmpty) and (not LNeuronDeleted) then
//          begin
//            LTempResulteOrigin1 := LTempResulteOrigin1;
//            LTempResultWinner1 := LTempResultWinner1;
//
//            LTempResulteOrigin2 := LTempResulteOrigin2;
//            LTempResultWinner2 := LTempResultWinner2;
//
//            Assert(Supports(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexPopulationLeft].Player, IPlayer, LPartyPlayers[TMoveSide.sideLeft]));
//            LTempResulteOrigin3 := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);
//
//            Assert(Supports(LTempInstance.Player, IPlayer, LPartyPlayers[TMoveSide.sideLeft]));
//            LTempResultWinner3 := Play_Templates_All(LPartyPlayers[TMoveSide.sideLeft], True, False, False);
//          end;
//        end;

        if (LTestMaxWinnerResult > 0) then
        begin
          if (AGroup.Stage.Populaton[LIndexLevel].Origin.Count > 0) then
          begin
            if AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].HasResult then
            begin
              if (LTestMaxWinnerResult) > (1.5 * AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[0].ResultValue) then
              begin
                LTestMaxWinnerResult := 0;
              end;
            end;
          end;
        end;

        LIndexOrigin := 0;
        LLimitCurrent := AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].ResultValue;

        LIndexWinners := 0;
        AGroup.Stage.Populaton[LIndexLevel].Winners.Count := 0;

        if (LNeuronDeleted) and (LTempInstance.Player <> nil) and (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].ResultValue < (LTempInstance.ResultValue * __WINNER_RESTORE_LIMIT)) then
        begin
          CopyInstance(LTempInstance, AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners]);
          AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Id := 'restored';

          LIndexWinners := LIndexWinners + 1;
          AGroup.Stage.Populaton[LIndexLevel].Winners.Count := AGroup.Stage.Populaton[LIndexLevel].Winners.Count + 1;
        end;

        for LIndexOrigin := 0 to AGroup.Stage.Populaton[LIndexLevel].Origin.Count - 1 do
        begin
          if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].HasResult) then
          begin
            if (AGroup.Stage.Rules.ClearNotWinners) then
            begin
              if (AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin].ResultValue >= LLimitCurrent) then
              begin
                LCopyWinner := True;
              end
              else
              begin
                LCopyWinner := False;
              end;
            end
            else
            begin
              if (LIndexWinners <= Trunc(AGroup.Stage.Rules.Winners * AGroup.Stage.PopulationCount)) then
              begin
                LCopyWinner := True;
              end
              else
              begin
                LCopyWinner := False;
              end;
            end;
          end
          else
          begin
            LCopyWinner := False;
          end;

          if LCopyWinner then
          begin
            CopyInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin], AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners]);

            LIndexWinners := LIndexWinners + 1;
            AGroup.Stage.Populaton[LIndexLevel].Winners.Count := AGroup.Stage.Populaton[LIndexLevel].Winners.Count + 1;
          end;

          ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Origin.Instances[LIndexOrigin]);
        end;

        for LIndexWinners := AGroup.Stage.Populaton[LIndexLevel].Winners.Count to AGroup.Stage.PopulationCount - 1 do
        begin
          ClearInstance(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners]);
        end;

        AGroup.Stage.Populaton[LIndexLevel].Origin.Count := 0;

        UpdateLabel(AGroup.Label_Net_Description, Format('Generations=%d, Population=%d, Repeat=%d, ClearNotWinners=%s(%.2f), Templates(%d,%d,%d), Enemy(Parties=%d), MaxResult=%d(neurons=%d)', [
              __GENERATION_COUNT, AGroup.Stage.PopulationCount, AGroup.Stage.RepeatLevelLast,
              BoolToStr(AGroup.Stage.Rules.ClearNotWinners, True), AGroup.Stage.Rules.Winners,
              Get_Count_Line_My, Get_Count_Line_Enemy, Get_Count_Templates_All,
              AGroup.Stage.Rules.PartiesCount,
              LResultValueMax, LResultValueMaxNeuronCount
        ]));

        if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count > 0) then
        begin
          LIndexWinners := 0;
          UpdateLog(AGroup.Memo_Log, Format('%d/%d; Val=%d, Tmpl=(%d,%d,%d), Avg=%d (Min=%d, Max=%d), Rndm=%d, Win=%d; net=%s %s %s', [
            LIndexLevelGenerate, LLevelGenerateCount - 1,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultValue,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplateLineMy,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplateLineEnemy,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplateEmpty,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultAvg,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultMin,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultMax,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultRandom,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Count,
            AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Id + ': ' +
              AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Net.GetNetDescription + ': ' +
              AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Net.Id,
            IfThen(LNeuronAdded, '(Neuron Add)', ''),
            IfThen(LNeuronDeleted, '(Neuron Delete)', '')
          ]));

//          if AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplateEmpty >= Get_Count_Templates_All then
          begin
//            if AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultMin >= __GOOD_WIN then
            begin
//              CheckNet(AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player, AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplate);
              AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].Player.Net.WriteIniFile;
            end;
          end;

        end
        else
        begin
          UpdateLog(AGroup.Memo_Log, Format('Gen=%d/%d; Lvl=%d/%d; repeat=%d/%d; no winners', [
            LIndexGeneration, __GENERATION_COUNT - 1, LIndexLevel, LCountLevels - 1, LIndexLevelGenerate, LLevelGenerateCount - 1
          ]));
        end;

        if AGroup.Thread.CheckTerminated then
        begin
          Exit;
        end;

        if FNeedStop then
        begin
          Break;
        end;

        while (FIsPaused) do
        begin
          Sleep(1000);
        end;

        if (AGroup.Stage.HasInput) then
        begin
          TakeWinnersFromInput(AGroup, LMaxWinnerLevel);
        end;

        LIndexLevelGenerate := LIndexLevelGenerate + 1;
      end; // LIndexLevelGenerate

      if FNeedStop then
      begin
        Break;
      end;

    end;  // LIndexLevel

//    if (AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count >= 1) then
//    begin
//      LIndexWinners := 0;
//      AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Instances[LIndexWinners].Player.GetNet.WriteIniFile;
//    end;

    if FNeedStop then
    begin
      Break;
    end;

    if Length(AOutput) > 0 then
    begin
      LFoundOutput := False;
      for LIndexOutput := 0 to Length(AOutput) - 1 do
      begin
        if (AOutput[LIndexOutput].Stage <> nil) and (AOutput[LIndexOutput].Stage.HasInput) and (AOutput[LIndexOutput].Stage.IsWaiting) then
        begin
          LFoundOutput := True;
          Break;
        end;
      end;

      if (not LFoundOutput) and (Length(AOutput) > 0) then
      begin
        LOutputLengthMinIndex := 0;
        LOutputLengthMin := Length(AOutput[0].Stage.Input);
        for LIndexOutput := 0 to Length(AOutput) - 1 do
        begin
          if (AOutput[LIndexOutput].Stage <> nil) and (AOutput[LIndexOutput].Stage.HasInput) and
            (LOutputLengthMin > Length(AOutput[LIndexOutput].Stage.Input)) then
          begin
            LOutputLengthMinIndex := LIndexOutput;
            LOutputLengthMin := Length(AOutput[LIndexOutput].Stage.Input);
          end;
        end;

        LFoundOutput := True;
        LIndexOutput := LOutputLengthMinIndex;
      end;

      if (LFoundOutput) then
      begin
        TMonitor.Enter(AOutput[LIndexOutput].Stage.InputLock);
        try
          UpdateLog(AGroup.Memo_Log, Format('WinnersForOutput: %d(%d)', [
            AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count,
            AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Instances[0].ResultValue
          ]));

          AOutput[LIndexOutput].Stage.SetInputLength(Length(AOutput[LIndexOutput].Stage.Input) + 1);
          CopyLevel(AGroup.Stage.Populaton[LMaxWinnerLevel], AOutput[LIndexOutput].Stage.Input[Length(AOutput[LIndexOutput].Stage.Input) - 1], AGroup.Stage.PopulationCount);

        finally
          TMonitor.Exit(AOutput[LIndexOutput].Stage.InputLock);
        end;
      end;

      AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count := 0;
    end
    else
    begin
      if (AGroup.Stage.Populaton[LIndexLevel].Winners.Count > 0) then
      begin
        if AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultTemplateEmpty >= Get_Count_Templates_All then
        begin
          if AGroup.Stage.Populaton[LIndexLevel].Winners.Instances[LIndexWinners].ResultMin >= __GOOD_WIN then
          begin
            AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count := 0;
          end;
        end;
      end;
    end;

  end; // index generation

//  if (AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count >= 1) then
//  begin
//    if (Length(AOutput) > 0) then
//    begin
//      LIndexWinners := 0;
//      AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Instances[LIndexWinners].Player.GetNet.WriteIniFile;
//    end
//    else
//    begin
//      for LIndexWinners := 0 to AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Count - 1 do
//      begin
//        AGroup.Stage.Populaton[LMaxWinnerLevel].Winners.Instances[LIndexWinners].Player.GetNet.WriteIniFile;
//      end;
//    end
//  end;

  UpdateLog(AGroup.Memo_Log, Format('stop', []));

end;

procedure TUtils.CopyInstance(const AInstanceFrom: TInstance; var AInstanceTo: TInstance);
begin
  AInstanceTo.Player                  := AInstanceFrom.Player;
  AInstanceTo.HasResult               := AInstanceFrom.HasResult;
  AInstanceTo.ResultMin               := AInstanceFrom.ResultMin;
  AInstanceTo.ResultMax               := AInstanceFrom.ResultMax;
  AInstanceTo.ResultAvg               := AInstanceFrom.ResultAvg;
  AInstanceTo.ResultTemplateEmpty     := AInstanceFrom.ResultTemplateEmpty;
  AInstanceTo.ResultTemplateLineMy    := AInstanceFrom.ResultTemplateLineMy;
  AInstanceTo.ResultTemplateLineEnemy := AInstanceFrom.ResultTemplateLineEnemy;
  AInstanceTo.ResultRandom            := AInstanceFrom.ResultRandom;
  AInstanceTo.ResultValue             := AInstanceFrom.ResultValue;
  AInstanceTo.Id                      := AInstanceFrom.Id;
end;

procedure TUtils.ClearInstance(var AInstance: TInstance);
begin
  AInstance.Player                  := nil;
  AInstance.HasResult               := False;
  AInstance.ResultMin               := 0;
  AInstance.ResultMax               := 0;
  AInstance.ResultAvg               := 0;
  AInstance.ResultTemplateEmpty     := 0;
  AInstance.ResultTemplateLineMy    := 0;
  AInstance.ResultTemplateLineEnemy := 0;
  AInstance.ResultRandom            := 0;
  AInstance.ResultValue             := 0;
  AInstance.Id                      := string.Empty;
end;

procedure TUtils.TakeWinnersFromInput(const AGroup: TGroup; var AMaxWinnerLevel: Integer);
var
  LIndexWinners: Integer;
  LIndexLevelWinnersForMaster: Integer;
  LIndexWinnersForMaster: Integer;
  LWinnersTemp: TInstanceArray;
  LIndexWinnersTemp: Integer;
begin
  TMonitor.Enter(AGroup.Stage.InputLock);
  try
    if Length(AGroup.Stage.Input) > 0 then
    begin
      for LIndexLevelWinnersForMaster := 0 to Length(AGroup.Stage.Input) - 1 do
      begin
        UpdateLog(AGroup.Memo_Log, Format('Winners from Input: %d(%d)', [
          AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Count,
          AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Instances[0].ResultValue
        ]));

        for LIndexWinners := 0 to AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count - 1 do
        begin
          CopyInstance(AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners], LWinnersTemp.Instances[LIndexWinners]);
        end;
        LWinnersTemp.Count := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count;

        LIndexWinners := 0;
        LIndexWinnersForMaster := 0;
        LIndexWinnersTemp := 0;
        AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count := 0;

        while (LIndexWinners <= Length(AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances) - 1) do
        begin
          if (LIndexWinnersForMaster <= AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Count - 1) and
             (LIndexWinnersTemp <= LWinnersTemp.Count - 1) then
          begin
            if (AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Instances[LIndexWinnersForMaster].ResultValue >= LWinnersTemp.Instances[LIndexWinnersTemp].ResultValue) then
            begin
              CopyInstance(AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Instances[LIndexWinnersForMaster], AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners]);
              LIndexWinnersForMaster := LIndexWinnersForMaster + 1;
              LIndexWinners := LIndexWinners + 1;
              AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count + 1;
            end
            else
            begin
              CopyInstance(LWinnersTemp.Instances[LIndexWinnersTemp], AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners]);
              LIndexWinnersTemp := LIndexWinnersTemp + 1;
              LIndexWinners := LIndexWinners + 1;
              AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count + 1;
            end;
          end
          else if (LIndexWinnersForMaster <= AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Count - 1) and
              not (LIndexWinnersTemp <= LWinnersTemp.Count - 1) then
          begin
            CopyInstance(AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Instances[LIndexWinnersForMaster], AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners]);
            LIndexWinnersForMaster := LIndexWinnersForMaster + 1;
            LIndexWinners := LIndexWinners + 1;
            AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count + 1;
          end
          else if (not(LIndexWinnersForMaster <= AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Count - 1)) and
                      (LIndexWinnersTemp <= LWinnersTemp.Count - 1) then
          begin
            CopyInstance(LWinnersTemp.Instances[LIndexWinnersTemp], AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners]);
            LIndexWinnersTemp := LIndexWinnersTemp + 1;
            LIndexWinners := LIndexWinners + 1;
            AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count + 1;
          end
          else if (not(LIndexWinnersForMaster <= AGroup.Stage.Input[LIndexLevelWinnersForMaster].Winners.Count - 1)) and
                   not (LIndexWinnersTemp <= LWinnersTemp.Count - 1) then
          begin
            Break;
          end
          else
          begin
            Assert(False); // сюда не должны попадать
          end;
        end;

        for LIndexWinners := AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Count to Length(AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances) - 1 do
        begin
          ClearInstance(AGroup.Stage.Populaton[AMaxWinnerLevel].Winners.Instances[LIndexWinners]);
        end;

      end;

      AGroup.Stage.SetInputLength(0);

    end;
  finally
    TMonitor.Exit(AGroup.Stage.InputLock);
  end;
end;

procedure TUtils.UpdateLabel(const ALabel: TLabel; const AText: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      ALabel.Text := AText;
    end
  );
end;

procedure TUtils.UpdateLog(const AMemo: TMemo; const AText: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      AMemo.Lines.Add(AText);
      AMemo.SelStart := Length(AMemo.Text);
    end
  );
end;

procedure TUtils.SortInstances(var AInstanceArray: TInstanceArray; APopulationCount: Integer);
var
  LIndexPopulationSort1: Integer;
  LIndexPopulationSort2: Integer;
  LInstanceForSwap: TInstance;
begin
  for LIndexPopulationSort1 := 0 to APopulationCount - 1 do
  begin
    for LIndexPopulationSort2 := LIndexPopulationSort1 + 1 to APopulationCount - 1 do
    begin
      if (AInstanceArray.Instances[LIndexPopulationSort2].HasResult = False) then
      begin
        Continue;
      end
      else if (AInstanceArray.Instances[LIndexPopulationSort1].HasResult = False) then
      begin
        CopyInstance(AInstanceArray.Instances[LIndexPopulationSort2], AInstanceArray.Instances[LIndexPopulationSort1]);
        ClearInstance(AInstanceArray.Instances[LIndexPopulationSort2]);
      end
      else if CompareSort(AInstanceArray.Instances[LIndexPopulationSort1], AInstanceArray.Instances[LIndexPopulationSort2]) then
      begin
        CopyInstance(AInstanceArray.Instances[LIndexPopulationSort1], LInstanceForSwap);
        CopyInstance(AInstanceArray.Instances[LIndexPopulationSort2], AInstanceArray.Instances[LIndexPopulationSort1]);
        CopyInstance(LInstanceForSwap, AInstanceArray.Instances[LIndexPopulationSort2]);
      end;
    end;
  end;
end;

function TUtils.CompareSort(const AInstance1: TInstance; const AInstance2: TInstance): Boolean;
begin
  Result := (AInstance1.ResultValue < AInstance2.ResultValue);
end;

//procedure TUtils.CheckNet(APlayer: IPlayerEx; AResultTemplateOld: Integer);
//var
//  APlayer_Load: IPlayerEx;
//  LResultTemplate1: Integer;
//  LResultTemplate2: Integer;
//begin
//  APlayer.Net.WriteIniFile;
//
//  APlayer_Load := Create_Player;
//  APlayer_Load.Net.ReadIniFile(TObject(APlayer.Net).ClassName + '_' + StringReplace(StringReplace(APlayer.Net.Id, '}', '', []), '{', '', []) + '.ini');
//
//  CompareNetData(APlayer.Net.GetNetData, APlayer_Load.Net.GetNetData);
//
//  LResultTemplate1 := Play_Template_X_(APlayer);
//  if not (LResultTemplate1 = AResultTemplateOld) then
//    Assert(LResultTemplate1 = AResultTemplateOld);
//
//  LResultTemplate2 := Play_Template_X_(APlayer_Load);
//  if not (LResultTemplate2 = AResultTemplateOld) then
//    Assert(LResultTemplate2 = AResultTemplateOld);
//
//end;

procedure TUtils.Learning_Field_Create(var AFieldsLearning: array of TField);
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      AFieldsLearning[0][LIndexY, LIndexX] := TCellValue.___;
    end;
  end;

end;

procedure TUtils.FillRulesRandom(var AGroup: TGroup);
var
  LWinners             : Double;
  LEnemyNetLimit       : Double;
  LPartiesCount        : Integer;
  LNewCopy             : Double;
  LNewReproduce        : Double;
  LNewMutateAddLevel   : Double;
  LNewMutateFewLow     : Double;
  LNewMutateFewHigh    : Double;
  LNewMutateManyLow    : Double;
  LNewMutateManyHigh   : Double;
  LSum: Double;
begin
  LWinners            := Random(__MAX_RANDOM + 1) / __MAX_RANDOM;
  LEnemyNetLimit      := Random(__MAX_RANDOM + 1) / __MAX_RANDOM;
  LPartiesCount       := Round(__PARTIES_COUNT_MIN           + (__PARTIES_COUNT_MAX                - __PARTIES_COUNT_MIN)                * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewCopy            := (__NEW_WINNER_MIN_COPY              + (__NEW_WINNER_MAX_COPY              - __NEW_WINNER_MIN_COPY)              * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewReproduce       := (__NEW_WINNER_MIN_REPRODUCE         + (__NEW_WINNER_MAX_REPRODUCE         - __NEW_WINNER_MIN_REPRODUCE)         * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewMutateAddLevel  := (__NEW_WINNER_MIN_MUTATE_ADD_LEVEL  + (__NEW_WINNER_MAX_MUTATE_ADD_LEVEL  - __NEW_WINNER_MIN_MUTATE_ADD_LEVEL)  * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewMutateFewLow    := (__NEW_WINNER_MIN_MUTATE_FEW_LOW    + (__NEW_WINNER_MAX_MUTATE_FEW_LOW    - __NEW_WINNER_MIN_MUTATE_FEW_LOW)    * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewMutateFewHigh   := (__NEW_WINNER_MIN_MUTATE_FEW_HIGH   + (__NEW_WINNER_MAX_MUTATE_FEW_HIGH   - __NEW_WINNER_MIN_MUTATE_FEW_HIGH)   * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewMutateManyLow   := (__NEW_WINNER_MIN_MUTATE_MANY_LOW   + (__NEW_WINNER_MAX_MUTATE_MANY_LOW   - __NEW_WINNER_MIN_MUTATE_MANY_LOW)   * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
  LNewMutateManyHigh  := (__NEW_WINNER_MIN_MUTATE_MANY_HIGH  + (__NEW_WINNER_MAX_MUTATE_MANY_HIGH  - __NEW_WINNER_MIN_MUTATE_MANY_HIGH)  * Random(__MAX_RANDOM + 1) / __MAX_RANDOM);

  LSum := LNewCopy + LNewReproduce + LNewMutateAddLevel + LNewMutateFewLow + LNewMutateFewHigh + LNewMutateManyLow + LNewMutateManyHigh + __NEW_RANDOM;

  AGroup.Stage.Rules.ClearNotWinners    := False;
  AGroup.Stage.Rules.EnemyNetLimit      := LEnemyNetLimit;
  AGroup.Stage.Rules.PartiesCount       := LPartiesCount;
  AGroup.Stage.Rules.Winners            := LWinners;
  AGroup.Stage.Rules.NewCopy            := LNewCopy            / LSum;
  AGroup.Stage.Rules.NewReproduce       := LNewReproduce       / LSum;
  AGroup.Stage.Rules.NewMutateAddLevel  := LNewMutateAddLevel  / LSum;
  AGroup.Stage.Rules.NewMutateFewLow    := LNewMutateFewLow    / LSum;
  AGroup.Stage.Rules.NewMutateFewHigh   := LNewMutateFewHigh   / LSum;
  AGroup.Stage.Rules.NewMutateManyLow   := LNewMutateManyLow   / LSum;
  AGroup.Stage.Rules.NewMutateManyHigh  := LNewMutateManyHigh  / LSum;
end;

procedure TUtils.FillRulesMaster(var AGroup: TGroup);
var
  LNewCopy             : Double;
  LNewReproduce        : Double;
  LNewMutateAddLevel   : Double;
  LNewMutateFewLow     : Double;
  LNewMutateFewHigh    : Double;
  LNewMutateManyLow    : Double;
  LNewMutateManyHigh   : Double;
  LSum: Double;
begin
  LNewCopy            := __NEW_WINNER_MASTER_COPY;
  LNewReproduce       := __NEW_WINNER_MASTER_REPRODUCE;
  LNewMutateAddLevel  := __NEW_WINNER_MASTER_MUTATE_ADD_LEVEL;
  LNewMutateFewLow    := __NEW_WINNER_MASTER_MUTATE_FEW_LOW;
  LNewMutateFewHigh   := __NEW_WINNER_MASTER_MUTATE_FEW_HIGH;
  LNewMutateManyLow   := __NEW_WINNER_MASTER_MUTATE_MANY_LOW;
  LNewMutateManyHigh  := __NEW_WINNER_MASTER_MUTATE_MANY_HIGH;

  LSum := LNewCopy + LNewReproduce + LNewMutateAddLevel + LNewMutateFewLow + LNewMutateFewHigh + LNewMutateManyLow + LNewMutateManyHigh + __NEW_RANDOM;

  AGroup.Stage.Rules.ClearNotWinners    := False;
  AGroup.Stage.Rules.EnemyNetLimit      := 1.0;
  AGroup.Stage.Rules.PartiesCount       := __PARTIES_COUNT_MAX;
  AGroup.Stage.Rules.Winners            := 1.0;
  AGroup.Stage.Rules.NewCopy            := LNewCopy            / LSum;
  AGroup.Stage.Rules.NewReproduce       := LNewReproduce       / LSum;
  AGroup.Stage.Rules.NewMutateAddLevel  := LNewMutateAddLevel  / LSum;
  AGroup.Stage.Rules.NewMutateFewLow    := LNewMutateFewLow    / LSum;
  AGroup.Stage.Rules.NewMutateFewHigh   := LNewMutateFewHigh   / LSum;
  AGroup.Stage.Rules.NewMutateManyLow   := LNewMutateManyLow   / LSum;
  AGroup.Stage.Rules.NewMutateManyHigh  := LNewMutateManyHigh  / LSum;
end;

procedure TUtils.InitLevel(var AGroup: TLevel; APopulationCount: Integer);
var
  LIndexOrigin: Integer;
begin
  AGroup.Limit.ResultMin := 0;
  AGroup.Limit.ResultMax := 0;

  AGroup.Winners.Count := 0;
  AGroup.Origin.Count := 0;
  for LIndexOrigin := 0 to APopulationCount - 1 do
  begin
    ClearInstance(AGroup.Origin.Instances[LIndexOrigin])
  end;
end;

procedure TUtils.CopyLevel(var AGroupFrom: TLevel; var AGroupTo: TLevel; APopulationCount: Integer);
var
  LIndexOrigin: Integer;
  LIndexWinners: Integer;
begin
  AGroupTo.Limit.ResultMin :=    AGroupFrom.Limit.ResultMin;
  AGroupTo.Limit.ResultMax :=    AGroupFrom.Limit.ResultMax;

  AGroupTo.Origin.Count := AGroupFrom.Origin.Count;
  AGroupFrom.Origin.Count := 0;

  for LIndexOrigin := 0 to APopulationCount - 1 do
  begin
    ClearInstance(AGroupTo.Origin.Instances[LIndexOrigin]);
    AGroupTo.Origin.Instances[LIndexOrigin].Player    := AGroupFrom.Origin.Instances[LIndexOrigin].Player;
    AGroupTo.Origin.Instances[LIndexOrigin].Id        := AGroupFrom.Origin.Instances[LIndexOrigin].Id;

    ClearInstance(AGroupFrom.Origin.Instances[LIndexOrigin]);
  end;

  AGroupTo.Winners.Count := AGroupFrom.Winners.Count;
  AGroupFrom.Winners.Count := 0;

  for LIndexWinners := 0 to APopulationCount - 1 do
  begin
    CopyInstance(AGroupFrom.Winners.Instances[LIndexWinners], AGroupTo.Winners.Instances[LIndexWinners]);
    ClearInstance(AGroupFrom.Winners.Instances[LIndexWinners]);
  end;
end;

procedure TUtils.CreateGroup(const ATabControl: TTabControl; var AGroup: TGroup; AName: string; AUseLoad: Boolean; AIsMaster: Boolean; AHasInput: Boolean; AInputLength: Integer; APopulationCount: Integer; ARepeatLevelLast: Integer);
begin
  AGroup.Stage.Name := AName;
  AGroup.Stage.Load := AUseLoad;
  AGroup.Stage.IsMaster := AIsMaster;
  AGroup.Stage.PopulationCount := APopulationCount;
  AGroup.Stage.RepeatLevelLast := ARepeatLevelLast;
  AGroup.Stage.HasInput := AHasInput;
  AGroup.Stage.SetInputLength(AInputLength);
  AGroup.Stage.IsInited := False;

  AGroup.TabItem := TTabItem.Create(ATabControl);
  AGroup.TabItem.Parent := ATabControl;
  AGroup.TabItem.Text := AName;

  AGroup.Label_Net_Description := TLabel.Create(AGroup.TabItem);
  AGroup.Label_Net_Description.Parent := AGroup.TabItem;
  AGroup.Label_Net_Description.Align := TAlignLayout.Top;
  AGroup.Label_Net_Description.AutoSize := True;
  AGroup.Label_Net_Description.WordWrap := True;
  AGroup.Label_Net_Description.Text := AName;

  AGroup.Memo_Log := TMemo.Create(AGroup.TabItem);
  AGroup.Memo_Log.Parent := AGroup.TabItem;
  AGroup.Memo_Log.Align := TAlignLayout.Client;
  AGroup.Memo_Log.Lines.Add(AName);
end;

procedure TUtils.Start_Learn_Genetic(const ATabControl: TTabControl);
var
  LIndexGenerator: Integer;
  LIndexPreCandidate: Integer;
  LIndexCandidate: Integer;
  LIndexPopulation: Integer;
  LIndexLevelRepeat: Integer;
  LPopulation: Integer;
  LLevelRepeat: Integer;
begin
  FFieldsPlay.Clear;

  for LIndexGenerator := 0 to __GENERATORS_COUNT - 1 do
  begin
    CreateGroup(ATabControl, FGenerators[LIndexGenerator], 'Generator_' + LIndexGenerator.ToString, False, False, False, 0, __POPULATION_COUNT_GENERATOR, __REPEAT_GENERATOR);
  end;

  LIndexCandidate := 0;
  if (__PRE_CANDIDATES_COUNT > 1) then
  begin
    LIndexPopulation := Floor(Sqrt(__PRE_CANDIDATES_COUNT));
    LIndexLevelRepeat := Floor(Sqrt(__PRE_CANDIDATES_COUNT));
  end;

  LPopulation := __POPULATION_COUNT_PRE_CANDIDATE_MIN;
  LLevelRepeat := __REPEAT_PRE_CANDIDATE_MIN;

  while (LIndexCandidate <= __PRE_CANDIDATES_COUNT - 1) do
  begin
    if (__PRE_CANDIDATES_COUNT > 1) then
    begin
      if Floor(Sqrt(__PRE_CANDIDATES_COUNT)) = 1 then
      begin
        if LIndexPopulation = 0 then
        begin
          LPopulation := __POPULATION_COUNT_PRE_CANDIDATE_MIN;
        end
        else if LIndexPopulation = 1 then
        begin
          LPopulation := __POPULATION_COUNT_PRE_CANDIDATE_MAX;
        end
        else
        begin
          Assert(False);
        end;

        if LIndexLevelRepeat = 0 then
        begin
          LLevelRepeat := __REPEAT_PRE_CANDIDATE_MIN;
        end
        else if LIndexLevelRepeat = 1 then
        begin
          LLevelRepeat := __REPEAT_PRE_CANDIDATE_MAX;
        end
        else
        begin
          Assert(False);
        end;
      end
      else
      begin
        LPopulation := Round(RoundTo(__POPULATION_COUNT_PRE_CANDIDATE_MAX - (Floor(Sqrt(__PRE_CANDIDATES_COUNT)) - LIndexPopulation) * (__POPULATION_COUNT_PRE_CANDIDATE_MAX - __POPULATION_COUNT_PRE_CANDIDATE_MIN) / (Floor(Sqrt(__PRE_CANDIDATES_COUNT)) - 1), 2));
        LLevelRepeat := Round(RoundTo(__REPEAT_PRE_CANDIDATE_MAX - (Floor(Sqrt(__PRE_CANDIDATES_COUNT)) - LIndexLevelRepeat) * (__REPEAT_PRE_CANDIDATE_MAX - __REPEAT_PRE_CANDIDATE_MIN) / (Floor(Sqrt(__PRE_CANDIDATES_COUNT)) - 1), 1));
      end;
    end
    else
    begin
      LPopulation := __POPULATION_COUNT_PRE_CANDIDATE_MIN;
      LLevelRepeat := __REPEAT_PRE_CANDIDATE_MIN;
    end;

    CreateGroup(ATabControl, FPreCandidates[LIndexCandidate], 'PreCandidate_' + LIndexCandidate.ToString, False, False, True, 0, LPopulation, LLevelRepeat);

    LIndexCandidate := LIndexCandidate + 1;

    if (__PRE_CANDIDATES_COUNT > 1) then
    begin
      LIndexLevelRepeat := LIndexLevelRepeat - 1;
      if (LIndexLevelRepeat <= 0) then
      begin
        LIndexPopulation := LIndexPopulation - 1;
        LIndexLevelRepeat := Floor(Sqrt(__PRE_CANDIDATES_COUNT));
      end;
    end;
  end;

  LIndexCandidate := 0;
  if (__CANDIDATES_COUNT > 1) then
  begin
    LIndexPopulation := Floor(Sqrt(__CANDIDATES_COUNT));
    LIndexLevelRepeat := Floor(Sqrt(__CANDIDATES_COUNT));
  end;

  LPopulation := __POPULATION_COUNT_CANDIDATE_MIN;
  LLevelRepeat := __REPEAT_CANDIDATE_MIN;

  while (LIndexCandidate <= __CANDIDATES_COUNT - 1) do
  begin
    if (__CANDIDATES_COUNT > 1) then
    begin
      if Floor(Sqrt(__CANDIDATES_COUNT)) = 1 then
      begin
        if LIndexPopulation = 0 then
        begin
          LPopulation := __POPULATION_COUNT_CANDIDATE_MIN;
        end
        else if LIndexPopulation = 1 then
        begin
          LPopulation := __POPULATION_COUNT_CANDIDATE_MAX;
        end
        else
        begin
          Assert(False);
        end;

        if LIndexLevelRepeat = 0 then
        begin
          LLevelRepeat := __REPEAT_CANDIDATE_MIN;
        end
        else if LIndexLevelRepeat = 1 then
        begin
          LLevelRepeat := __REPEAT_CANDIDATE_MAX;
        end
        else
        begin
          Assert(False);
        end;
      end
      else
      begin
        LPopulation := Round(RoundTo(__POPULATION_COUNT_CANDIDATE_MAX - (Floor(Sqrt(__CANDIDATES_COUNT)) - LIndexPopulation) * (__POPULATION_COUNT_CANDIDATE_MAX - __POPULATION_COUNT_CANDIDATE_MIN) / (Floor(Sqrt(__CANDIDATES_COUNT)) - 1), 2));
        LLevelRepeat := Round(RoundTo(__REPEAT_CANDIDATE_MAX - (Floor(Sqrt(__CANDIDATES_COUNT)) - LIndexLevelRepeat) * (__REPEAT_CANDIDATE_MAX - __REPEAT_CANDIDATE_MIN) / (Floor(Sqrt(__CANDIDATES_COUNT)) - 1), 1));
      end;
    end
    else
    begin
      LPopulation := __POPULATION_COUNT_CANDIDATE_MIN;
      LLevelRepeat := __REPEAT_CANDIDATE_MIN;
    end;

    CreateGroup(ATabControl, FCandidates[LIndexCandidate], 'Candidate_' + LIndexCandidate.ToString, False, False, True, 0, LPopulation, LLevelRepeat);

    LIndexCandidate := LIndexCandidate + 1;

    if (__CANDIDATES_COUNT > 1) then
    begin
      LIndexLevelRepeat := LIndexLevelRepeat - 1;
      if (LIndexLevelRepeat <= 0) then
      begin
        LIndexPopulation := LIndexPopulation - 1;
        LIndexLevelRepeat := Floor(Sqrt(__CANDIDATES_COUNT));
      end;
    end;
  end;

  CreateGroup(ATabControl, FMaster, 'Master', True, True, True, 0, __POPULATION_COUNT_MASTER, __REPEAT_MASTER);

  FIndexThreadSafeGenerators := 0;
  for LIndexGenerator := 0 to Length(FGenerators) - 1 do
  begin
    FGenerators[LIndexGenerator].Thread := TThread.CreateAnonymousThread(
      procedure
      var
        LThreadIndex: Integer;
      begin
        TMonitor.Enter(FIndexThreadSafeLockGenerators);
        try
          LThreadIndex := FIndexThreadSafeGenerators;
          FIndexThreadSafeGenerators := FIndexThreadSafeGenerators + 1;
        finally
          TMonitor.Exit(FIndexThreadSafeLockGenerators);
        end;

        TThread.NameThreadForDebugging(FGenerators[LThreadIndex].Stage.Name);

        LearnAll(FGenerators[LThreadIndex], FPreCandidates);

      end);
    FGenerators[LIndexGenerator].Thread.Start;
  end;

  FIndexThreadSafePreCandidates := 0;
  for LIndexPreCandidate := 0 to Length(FPreCandidates) - 1 do
  begin
    FPreCandidates[LIndexPreCandidate].Thread := TThread.CreateAnonymousThread(
      procedure
      var
        LThreadIndex: Integer;
      begin
        TMonitor.Enter(FIndexThreadSafeLockPreCandidates);
        try
          LThreadIndex := FIndexThreadSafePreCandidates;
          FIndexThreadSafePreCandidates := FIndexThreadSafePreCandidates + 1;
        finally
          TMonitor.Exit(FIndexThreadSafeLockPreCandidates);
        end;

        TThread.NameThreadForDebugging(FPreCandidates[LThreadIndex].Stage.Name);

        LearnAll(FPreCandidates[LThreadIndex], FCandidates);

      end);
    FPreCandidates[LIndexPreCandidate].Thread.Start;
  end;

  FIndexThreadSafeCandidates := 0;
  for LIndexCandidate := 0 to Length(FCandidates) - 1 do
  begin
    FCandidates[LIndexCandidate].Thread := TThread.CreateAnonymousThread(
      procedure
      var
        LThreadIndex: Integer;
      begin
        TMonitor.Enter(FIndexThreadSafeLockCandidates);
        try
          LThreadIndex := FIndexThreadSafeCandidates;
          FIndexThreadSafeCandidates := FIndexThreadSafeCandidates + 1;
        finally
          TMonitor.Exit(FIndexThreadSafeLockCandidates);
        end;

        TThread.NameThreadForDebugging(FCandidates[LThreadIndex].Stage.Name);

        LearnAll(FCandidates[LThreadIndex], FMaster);

      end);
    FCandidates[LIndexCandidate].Thread.Start;
  end;

  FMaster.Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      TThread.NameThreadForDebugging(FMaster.Stage.Name);
      LearnAll(FMaster, []);
    end);
  FMaster.Thread.Start;

end;

procedure TUtils.Start_Learn_BackPropagation(const ATabControl: TTabControl);
begin
  FFieldsPlay.Clear;

  CreateGroup(ATabControl, FMaster, 'Master', True, True, True, 0, __POPULATION_COUNT_MASTER, __REPEAT_MASTER);

  FMaster.Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      TThread.NameThreadForDebugging(FMaster.Stage.Name);
      Learn_BackPropagation(FMaster, []);
    end);
  FMaster.Thread.Start;

end;

procedure TUtils.Learn_BackPropagation(AGroup: TGroup; AOutput: array of TGroup);
var
  LIndexGeneration: Integer;
  LPlayer: IPlayerEx;
  LFieldsLearning: array of TField;
  LCount_Neurons: Integer;
  LProbabilityAdd: Double;
  LProbabilityDelete: Double;
  LResultTemplateMax: Integer;
  LSideMy: TMoveSide;
//  LSideEnemy: TMoveSide;
  LKeys: TArray<string>;
  LIndexTemplate: Integer;
  LTemplate: TTemplate;
  LField: TField;
  LMoveEx: TMoveEx;
//  LExpectedMove: TMoveEx;
  LResultTemplate: Integer;
begin
  UpdateLog(AGroup.Memo_Log, 'Start');
  UpdateLabel(AGroup.Label_Net_Description, Format('Generations=%d', [__GENERATION_COUNT]));

  SetLength(LFieldsLearning, 1);
  Learning_Field_Create(LFieldsLearning);

  FNeedStop := False;
  FIsPaused := False;

  LResultTemplateMax := 0;
  LResultTemplate := 0;

  LPlayer := Create_Player;

  LPlayer.Net.CreateRandom;
//  LPlayer.Net.Reset;
  LPlayer.Net.BackPropagation(LField, LMoveEx, LTemplate.ExpectedMove, True);

  for LIndexGeneration := 0 to __GENERATION_COUNT - 1 do
  begin
    begin
      begin
        begin
          //__NEW_MUTATE_ADD_NEURON
          LProbabilityAdd := __NEW_MUTATE_ADD_NEURON;
          if (LPlayer.Net.GetNetData.Count_Hidden_Layers >= 1) then
          begin
            LCount_Neurons := LPlayer.Net.GetNetData.HiddenLayers[0].Count_Neurons;

            if LCount_Neurons < 50 then
            begin
              LProbabilityAdd := __NEW_MUTATE_ADD_NEURON;
            end
            else
            begin
              LProbabilityAdd := 0.1;
            end;
          end;

          //__NEW_MUTATE_DELETE_NEURON
          LProbabilityDelete := __NEW_MUTATE_DELETE_NEURON;
          if (LPlayer.Net.GetNetData.Count_Hidden_Layers >= 1) then
          begin
            LCount_Neurons := LPlayer.Net.GetNetData.HiddenLayers[0].Count_Neurons;
            if LCount_Neurons < 5 then
            begin
              LProbabilityDelete := 0.3;
            end
            else if LCount_Neurons < 15 then
            begin
              LProbabilityDelete := 0.4;
            end
            else if LCount_Neurons < 40 then
            begin
              LProbabilityDelete := 0.5;
            end
            else
            begin
              LProbabilityDelete := 0.6;
            end;
          end;

          if (Random() <= LProbabilityAdd) then
          begin
            //__NEW_MUTATE_ADD_NEURON
            LPlayer.GetNet.FillMutateAddNeuron;
          end
          else if (Random() <= LProbabilityDelete) then
          begin
            //__NEW_MUTATE_DELETE_NEURON
            LPlayer.GetNet.FillMutateDeleteNeuron(
              Random() < 0.5,
              LResultTemplate > 0,
              LResultTemplate / LResultTemplateMax);
          end;

          // back propagation
          LResultTemplate := 0;
          LSideMy := TMoveSide.sideLeft;
//          LSideEnemy := TMoveSide.sideRight;
          LKeys := FMoves_X_.Keys.ToArray;

          for LIndexTemplate := 0 to Length(LKeys) - 1 do
          begin
            LTemplate := FMoves_X_[LKeys[LIndexTemplate]];
            LField := LTemplate.Field;
            LPlayer.Net.Init(LField, TSideValues[LSideMy]);
            LMoveEx := LPlayer.Net.GetNextMoveEx;

//            if (LMoveEx.Y <> -1) and (LMoveEx.X <> -1) and (LField[LMoveEx.Y, LMoveEx.X] <> TCellValue.___) then
//            begin
//              // empty
//              LPlayer.Net.BackPropagation(False, LField, LMoveEx, True);
//            end
//            else if (Check_2_in_Line(LField, TSideValues[LSideMy]) > 0) then
//            begin
//              // 2-0 self
//              LExpectedMove := Get_2_in_Line_Cell(LField, TSideValues[LSideMy]);
//
//              if (LMoveEx.Y <> -1) and (LMoveEx.X <> -1) then
//              begin
//                LPlayer.Net.BackPropagation(False, LField, LMoveEx, True);
//              end;
//              LPlayer.Net.BackPropagation(True, LField, LExpectedMove, True);
//            end
//            else if (Check_2_in_Line(LField, TSideValues[LSideEnemy]) > 0) then
//            begin
//              // 2-0 enemy
//              LExpectedMove := Get_2_in_Line_Cell(LField, TSideValues[LSideEnemy]);
//              LExpectedMove.SelectedFigure := TSideValues[LSideMy];
//
//              if (LMoveEx.Y <> -1) and (LMoveEx.X <> -1) then
//              begin
//                LPlayer.Net.BackPropagation(False, LField, LMoveEx, True);
//              end;
//              LPlayer.Net.BackPropagation(True, LField, LExpectedMove, True);
//            end
//            else
//            begin
//              LResultTemplate := LResultTemplate + 1;
//            end;


            if (LTemplate.Is_2_In_Line_My) then
            begin
              Assert(LTemplate.ExpectedMove.Y <> -1);
              Assert(LTemplate.ExpectedMove.X <> -1);
              if (LTemplate.ExpectedMove.Y = LMoveEx.Y) and (LTemplate.ExpectedMove.X = LMoveEx.X) then
              begin
                LResultTemplate := LResultTemplate + __GOOD_TEMPLATE;
              end
              else
              begin
                LPlayer.Net.BackPropagation(LField, LMoveEx, LTemplate.ExpectedMove, True);
              end;
            end;

          end;

          LResultTemplateMax := Max(LResultTemplateMax, LResultTemplate);
          if LResultTemplate = Length(LKeys) then
          begin
            LPlayer.Net.WriteIniFile;
          end;

          UpdateLabel(AGroup.Label_Net_Description, Format('Generations=%d, Templates(%d+%d=%d)', [
                __GENERATION_COUNT,
                Get_Count_Template_X_, Get_Count_Template_0_, Get_Count_Templates_All
          ]));

          UpdateLog(AGroup.Memo_Log, Format('%3d/%3d; Result=%6d;   net=%s', [
            LIndexGeneration, __GENERATION_COUNT,
            LResultTemplate,
            LPlayer.Net.GetNetDescription + ': ' + LPlayer.Net.Id
          ]));

        end;
      end;
    end;
  end;
end;

function TUtils.Create_Player: IPlayerEx;
begin
  Result := TPlayer_Net_05.Create;
end;

function TUtils.Create_Net: INet;
begin
  Result := TNet_05.Create;
end;

initialization
  GUtils := TUtils.Create;

end.
