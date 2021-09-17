unit Player.Compositon;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , Common.Constants
  , Common.Interfaces
  ;

type
  TPlayer_Compositon = class(TInterfacedObject, IPlayer, IPlayerEx)
  strict private
    FNetList: TList<TWeightedNet>;
    FResultArray: array of Integer;
    FWeightArray: array of Double;
    FId: string;

    procedure LoadIni;
    procedure EvaluateNets;
  public
    constructor Create;
    destructor Destroy; override;

    function GetNextMove(AField: TField; AMyValue: TCellValue): TMove;

    function GetNet: INet;
    procedure SetNet(AValue: INet);

    procedure SetId(AValue: string);
    function GetId: string;
    property Id: string read GetId write SetId;
  end;

implementation

uses
  System.Types
  , System.IOUtils
  , System.Math
  , WinApi.Windows
  , Utils
  , Player.Random
  ;

constructor TPlayer_Compositon.Create;
begin
  inherited Create;

  FId := TGUID.NewGuid.ToString;

  FNetList := TList<TWeightedNet>.Create;
  SetLength(FWeightArray, 0);
  SetLength(FResultArray, 0);

  LoadIni();
  EvaluateNets();

end;

destructor TPlayer_Compositon.Destroy;
begin
  FreeAndNil(FNetList);
  SetLength(FWeightArray, 0);
  SetLength(FResultArray, 0);
end;

procedure TPlayer_Compositon.LoadIni;
var
  LWeightedNet: TWeightedNet;
  LFiles: TStringDynArray;
  LFileName: string;
begin
  if TDirectory.Exists('ini') then
  begin
    LFiles := TDirectory.GetFiles(TPath.Combine(TDirectory.GetCurrentDirectory,'ini'), '*.ini', TSearchOption.soAllDirectories);
    for LFileName in LFiles do
    begin
      LWeightedNet.Net := GUtils.Create_Net;
      LWeightedNet.Net.ReadIniFile(LFileName);

      FNetList.Add(LWeightedNet);
      SetLength(FWeightArray, Length(FWeightArray) + 1);
      SetLength(FResultArray, Length(FResultArray) + 1);
    end;
  end;
end;

procedure TPlayer_Compositon.EvaluateNets;
var
  LWeightedNet: TWeightedNet;
  LIndex_Net: Integer;
  LEnemy: IPlayer;
  LIndexParty: Integer;
  LPartyResult: TPartyResult;
  LPartyPlayers: TPartyPlayers;
  LPlayer: IPlayer;
  LPlayerEx: IPlayerEx;
  LFieldsLearning: array of TField;
  LResultSum: Int64;
  LResultMax: Int64;
begin
  Assert(FNetList.Count = Length(FResultArray));
  Assert(Length(FResultArray) = Length(FWeightArray));
  Assert(Length(FWeightArray) = FNetList.Count);

  SetLength(LFieldsLearning, 1);

  LEnemy := TPlayer_Random.Create;

  // calc scores
  for LIndex_Net := 0 to FNetList.Count - 1 do
  begin
    LWeightedNet := FNetList[LIndex_Net];
    LResultSum := 0;

    for LIndexParty := 0 to __PARTIES_COUNT_EVALUATE - 1 do
    begin
      LPlayer := GUtils.Create_Player;
      Assert(Supports(LPlayer, IPlayerEx, LPlayerEx));
      LPlayerEx.Net := LWeightedNet.Net;

      LPartyPlayers[TMoveSide.sideLeft] := LPlayer;
      LPartyPlayers[TMoveSide.sideRight] := LEnemy;

      LPartyResult := GUtils.Play_Party(LFieldsLearning, LPartyPlayers, True);

      LPartyPlayers[TMoveSide.sideLeft] := nil;
      LPartyPlayers[TMoveSide.sideRight] := nil;

      LResultSum := LResultSum + LPartyResult[TMoveSide.sideLeft];

    end;

    FResultArray[LIndex_Net] := Floor(LResultSum / __PARTIES_COUNT_EVALUATE);

  end;

  // find max
  LResultMax := 0;
  for LIndex_Net := 0 to Length(FResultArray) - 1 do
  begin
    if (LResultMax < FResultArray[LIndex_Net]) then
    begin
      LResultMax := FResultArray[LIndex_Net];
    end;
  end;

  // calc weights
  for LIndex_Net := 0 to Length(FResultArray) - 1 do
  begin
    FWeightArray[LIndex_Net] := FResultArray[LIndex_Net] / LResultMax;
  end;

  // evaluate compositoin (must not raise assert)
  for LIndexParty := 0 to __PARTIES_COUNT_EVALUATE - 1 do
  begin
    LPartyPlayers[TMoveSide.sideLeft] := Self;
    LPartyPlayers[TMoveSide.sideRight] := LEnemy;

    LPartyResult := GUtils.Play_Party(LFieldsLearning, LPartyPlayers, True);

    LPartyPlayers[TMoveSide.sideLeft] := nil;
    LPartyPlayers[TMoveSide.sideRight] := nil;
  end;

end;

function TPlayer_Compositon.GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
var
  LWeightedNet: TWeightedNet;
  LIndex_Net: Integer;
  LIndex_Neurons: Integer;
  LMoveEx: TMoveEx;
  LNeurons_Values: TNeurons_Values;
  LMaxValue: Double;
  LMaxValueIndex: Integer;
begin
  Result.SelectedFigure := TCellValue.___;
  Result.Y := -1;
  Result.X := -1;

  for LIndex_Net := 0 to FNetList.Count - 1 do
  begin
    if FWeightArray[LIndex_Net] >= __WEIGHT_TRESHOLD then
    begin
      LWeightedNet := FNetList[LIndex_Net];
      LWeightedNet.Net.Init(AField, AMyValue);
      LMoveEx := LWeightedNet.Net.GetNextMoveEx;

      if Length(LNeurons_Values) = 0 then
      begin
        SetLength(LNeurons_Values, LWeightedNet.Net.GetNetData.OutputLayer.Count_Neurons);

        for LIndex_Neurons := 0 to Length(LNeurons_Values) - 1 do
        begin
          LNeurons_Values[LIndex_Neurons] := 0.0;
        end;
      end;

      for LIndex_Neurons := 0 to Length(LNeurons_Values) - 1 do
      begin
        LNeurons_Values[LIndex_Neurons] := LNeurons_Values[LIndex_Neurons] + LMoveEx.Neurons_Values[LIndex_Neurons] * FWeightArray[LIndex_Net];
      end;
    end;

  end;

  LMaxValue := 0;
  LMaxValueIndex := -1;
  for LIndex_Neurons := 0 to Length(LNeurons_Values) - 1 do
  begin
    if (LMaxValue < LNeurons_Values[LIndex_Neurons]) then
    begin
      LMaxValue := LNeurons_Values[LIndex_Neurons];
      LMaxValueIndex := LIndex_Neurons;
    end;
  end;

  if (LMaxValue > 0.0) and (LMaxValueIndex > -1) then
  begin
    Result.SelectedFigure := AMyValue;
    Result.Y := __MAP_NEURON_TO_FIELD[LMaxValueIndex][0];
    Result.X := __MAP_NEURON_TO_FIELD[LMaxValueIndex][1];
  end;

  if not (AField[Result.Y, Result.X] = TCellValue.___) then
  begin
    if not (AField[Result.Y, Result.X] = TCellValue.___) then
    begin
      Assert(AField[Result.Y, Result.X] = TCellValue.___);
    end;
  end;

end;

function TPlayer_Compositon.GetNet: INet;
begin
  Result := nil;
end;

procedure TPlayer_Compositon.SetNet(AValue: INet);
begin
  //
end;

procedure TPlayer_Compositon.SetId(AValue: string);
begin
  FId := AValue;
end;

function TPlayer_Compositon.GetId: string;
begin
  Result := FId;
end;

end.
