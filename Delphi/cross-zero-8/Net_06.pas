unit Net_06;

interface

uses
  System.IniFiles
  , Common.Constants
  , Common.Interfaces
  ;

type
  TNet_05 = class(TInterfacedObject, INet)
  strict private
    FId: string;
    FNetData: TNetData;
    FField: TField;
    FMyValue: TCellValue;
    FIniFile: TMemIniFile;

    procedure UpdateIniFile;

    procedure NormalizeWeightsAll;
    procedure NormalizeWeightsLayer(ALayer: TLayer);

    procedure CheckNet(ANetData: TNetData);

    procedure CalculateAll;
    procedure CalculateLayer(ACount_Neurons: Integer; ANeurons_Values: TNeurons_Values; ALayer: TLayer);

    procedure GetLinkSum(const ANeurons_Values: TNeurons_Values; const ALinks_Weights_Post: array of Double; out ANeuron_Active_Links_Count: Integer; out ANeuron_Active_Links_Sum: Double; out ANeuron_All_Links_Sum: Double);

  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure CreateRandom;
    procedure FillRandom;
    procedure FillMutate(const AProbability: Double; const ASize: Double; const AForceLastNeuron: Boolean);
    procedure CopyAll(ANet: INet);
    procedure CopyReproduce(ANet1: INet; ANet2: INet);

//    function CanFillMutateAddNeuron: Boolean;
//    function TryFillMutateAddNeuron: Boolean;
    procedure FillMutateAddNeuron;

    procedure FillMutateDeleteNeuron(const AUseThresholdOrWeight: Boolean; const AUseLimit: Boolean; const ALimit: Double);

//    function CanFillMutateAddLevel: Boolean;
//    function TryFillMutateAddLevel: Boolean;
//    procedure FillMutateAddLevel;

    procedure BackPropagation_Old(const AField: TField; const AMoveOld: TMoveEx; const AMoveExpected: TMoveEx; const ACheck: Boolean);
    procedure BackPropagation(const AField: TField; const AMoveOld: TMoveEx; const AMoveExpected: TMoveEx; const ACheck: Boolean);
    procedure BackPropagation_test(const LInput0: Integer; const LInput1: Integer; const LExpectedOutput0: Integer; const LExpectedOutput1: Integer);

    function GetNetDescription: string;
    function GetNetData: TNetData;

    procedure ReadIniFile(const AFileName: string);
    procedure WriteIniFile;

    procedure Init(AField: TField; AMyValue: TCellValue);
    function GetNextMove: TMove;
    function GetNextMoveEx: TMoveEx;

    procedure Reward(AReward: Integer);

    function GetId: string;
    property Id: string read GetId;
  end;

implementation

uses
  System.SysUtils
  , System.Math
  , System.Types
  , Utils
  ;

constructor TNet_05.Create;
begin
  inherited Create;

  FIniFile := nil;
  FId := TGUID.NewGuid.ToString;
end;

destructor TNet_05.Destroy;
begin
  FreeAndNil(FIniFile);
end;

function TNet_05.GetId: string;
begin
  Result := FId;
end;

function TNet_05.GetNetDescription: string;
var
  LIndex: Integer;
  LCounts: string;
begin
  LCounts := string.Empty;
  for LIndex := 0 to FNetData.Count_Hidden_Layers - 1 do
  begin
    if (LCounts <> string.Empty) then
    begin
      LCounts := LCounts + ',';
    end;
    LCounts := LCounts + FNetData.HiddenLayers[LIndex].Count_Neurons.ToString;
  end;
  if (LCounts <> string.Empty) then
  begin
    LCounts := '(' +  LCounts + ')';
  end;

  Result := Format('I=%d, H=%d%s, O=%d ', [
    FNetData.InputLayer.Count_Neurons, FNetData.Count_Hidden_Layers, LCounts, FNetData.OutputLayer.Count_Neurons]);
end;

function TNet_05.GetNetData: TNetData;
begin
  Result := FNetData;
end;

procedure TNet_05.Reset;
begin
  FId := TGUID.NewGuid.ToString;

  FNetData.InputLayer.Count_Neurons := 0;
  SetLength(FNetData.InputLayer.Neurons_Values, 0);

  FNetData.Count_Hidden_Layers := 0;
  SetLength(FNetData.HiddenLayers, 0);

  FNetData.OutputLayer.Count_Neurons := 0;
  SetLength(FNetData.OutputLayer.Links_Weights, 0);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, 0);
  SetLength(FNetData.OutputLayer.Neurons_Values, 0);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, 0);

  CheckNet(FNetData);

end;

procedure TNet_05.CreateRandom;
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LNeuronThreshold: Double;
  LLinkWeight: Double;
  LSumPositive: Double;
begin
  FId := TGUID.NewGuid.ToString;

  // input
  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  Assert(__COUNT_INPUT_NEURONS = LInput_Neurons_Count);

  SetLength(FNetData.InputLayer.Neurons_Values, LInput_Neurons_Count);
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := __DEFAULT_COUNT_HIDDEN_LAYERS;
  SetLength(FNetData.HiddenLayers, LCountHiddenLayers);
  FNetData.Count_Hidden_Layers := LCountHiddenLayers;

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    LHidden_Neurons_Count := __DEFAULT_COUNT_HIDDEN_NEURONS;
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);

    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := LHidden_Neurons_Count;
    FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput := (__COUNT_INPUT_NEURONS = __COUNT_INPUT_NEURONS_9);
    FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput := False;

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
      begin
        LNeuronThreshold := -1 + Floor(Random(3));
      end
      else
      begin
        LNeuronThreshold := __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LHidden_Neurons_Count_Previous) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
      end;
      FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);
      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;

      Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput);
      LSumPositive := 0.0;
      for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
      begin
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

        LSumPositive := LSumPositive + FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
      end;
      Assert(LSumPositive >= 0.0);
      Assert(LSumPositive <= __NORMALIZATION_VALUE);

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
        begin
          LLinkWeight := -1 + Floor(Random(3));
        end
        else
        begin
          LLinkWeight := IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
          LLinkWeight := LLinkWeight * (__NORMALIZATION_VALUE - (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]));
          Assert(LLinkWeight >= 0.0);
          if not (LLinkWeight <= __NORMALIZATION_VALUE) then //test
            Assert(LLinkWeight <= __NORMALIZATION_VALUE);

          if (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight) > __NORMALIZATION_VALUE then
          begin
            LLinkWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
            Assert(LLinkWeight >= 0.0);
            Assert(LLinkWeight <= __NORMALIZATION_VALUE);
          end;

          LSumPositive := LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight;
          Assert(LSumPositive >= 0.0);
          Assert(LSumPositive <= __NORMALIZATION_VALUE);
        end;
        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := __COUNT_OUTPUT_NEURONS;
  SetLength(FNetData.OutputLayer.Links_Weights, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, LOutput_Neurons_Count);

  FNetData.OutputLayer.Count_Neurons := LOutput_Neurons_Count;
  FNetData.OutputLayer.HasNegativeInput := False;
  FNetData.OutputLayer.IsOutput := True;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    Assert(not FNetData.OutputLayer.HasNegativeInput);
    LNeuronThreshold := __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LOutput_Links_Count) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
    FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    Assert(not FNetData.OutputLayer.HasNegativeInput);
    LSumPositive := 0.0;
    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

      LSumPositive := LSumPositive + FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
    end;
    Assert(LSumPositive >= 0.0);
    Assert(LSumPositive <= __NORMALIZATION_VALUE);

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      Assert(not FNetData.OutputLayer.HasNegativeInput);

      LLinkWeight := __NORMALIZATION_VALUE * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
      Assert(LLinkWeight >= 0.0);
      Assert(LLinkWeight <= __NORMALIZATION_VALUE);

      if (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight) > __NORMALIZATION_VALUE then
      begin
        LLinkWeight := Max(0.0, 1 - (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
        Assert(LLinkWeight >= 0.0);
        Assert(LLinkWeight <= __NORMALIZATION_VALUE);
      end;

      LSumPositive := LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight;
      Assert(LSumPositive >= 0.0);
      Assert(LSumPositive <= __NORMALIZATION_VALUE);

      FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
    end;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.FillRandom;
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LNeuronThreshold: Double;
  LLinkWeight: Double;
begin
  FId := TGUID.NewGuid.ToString;

  // input
  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := Length(FNetData.HiddenLayers);
  Assert(FNetData.Count_Hidden_Layers = LCountHiddenLayers);

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;

    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights) = LHidden_Neurons_Count);
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds) = LHidden_Neurons_Count);
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values) = LHidden_Neurons_Count);

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
      begin
        LNeuronThreshold := -1 + Floor(Random(3));
      end
      else
      begin
        LNeuronThreshold := __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LHidden_Neurons_Count_Previous) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
      end;
      FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons]) = LHidden_Neurons_Count_Previous);
      Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links = LHidden_Neurons_Count_Previous);

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
        begin
          LLinkWeight := -1 + Floor(Random(3));
        end
        else
        begin
          LLinkWeight := __NORMALIZATION_VALUE * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
        end;
        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := __COUNT_OUTPUT_NEURONS;
  SetLength(FNetData.OutputLayer.Links_Weights, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, LOutput_Neurons_Count);

  FNetData.OutputLayer.Count_Neurons := LOutput_Neurons_Count;
  Assert(not FNetData.OutputLayer.HasNegativeInput);
  Assert(not FNetData.OutputLayer.IsOutput);

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    Assert(not FNetData.OutputLayer.HasNegativeInput);
    LNeuronThreshold := __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LOutput_Links_Count) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
    FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      Assert(not FNetData.OutputLayer.HasNegativeInput);
      LLinkWeight := __NORMALIZATION_VALUE * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
      FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
    end;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.FillMutate(const AProbability: Double; const ASize: Double; const AForceLastNeuron: Boolean);
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LMin: Double;
  LMax: Double;
  LSumPositive: Double;
  LNewWeight: Double;
begin
  FId := TGUID.NewGuid.ToString;

  Assert(AProbability >= 0.0);
  Assert(AProbability <= 1.0);

  Assert(ASize >= 0.0);
  Assert(ASize <= 1.0);

  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;

  // hidden
  LCountHiddenLayers := Length(FNetData.HiddenLayers);

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      if (Random <= AProbability) or (AForceLastNeuron and (LIndexNeurons = LHidden_Neurons_Count - 1)) then
      begin
        if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
        begin
          FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := -1 + Floor(Random(3));
        end
        else
        begin
          LMin := Max(0, FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] - ASize);
          LMax := Min(__NORMALIZATION_VALUE, FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] + ASize);

          FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] :=
            LMin + ((LMax - LMin)* IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
        end;
      end;
    end;

    if (AForceLastNeuron) then
    begin
      LIndexNeurons := LHidden_Neurons_Count - 1;

      Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput);
      LSumPositive := 0.0;
      for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
      begin
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

        LSumPositive := LSumPositive + FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
      end;
      Assert(LSumPositive >= 0.0);
      Assert(LSumPositive <= __NORMALIZATION_VALUE);

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        if (Random <= AProbability) then
        begin
          if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
          begin
            FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := -1 + Floor(Random(3));
          end
          else
          begin
            LMin := Max(0, FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] - ASize);
            LMax := Min(__NORMALIZATION_VALUE, FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + ASize);

            LNewWeight := LMin + ((LMax - LMin)* IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
            Assert(LNewWeight >= 0.0);
            Assert(LNewWeight <= __NORMALIZATION_VALUE);

            if (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight) > __NORMALIZATION_VALUE then
            begin
              LNewWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
              Assert(LNewWeight >= 0.0);
              Assert(LNewWeight <= __NORMALIZATION_VALUE);
            end;

            LSumPositive := LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight;
            Assert(LSumPositive >= 0.0);
            Assert(LSumPositive <= __NORMALIZATION_VALUE);

            FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LNewWeight;
          end;
        end;
      end;
    end
    else
    begin
      for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
      begin
        Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput);
        LSumPositive := 0.0;
        for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
        begin
          Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
          Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

          LSumPositive := LSumPositive + FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
        end;
        Assert(LSumPositive >= 0.0);
        if not (LSumPositive <= __NORMALIZATION_VALUE) then // test
          if not (CompareValue(LSumPositive, __NORMALIZATION_VALUE) <= GreaterThanValue) then // test
            Assert(LSumPositive <= __NORMALIZATION_VALUE);

        for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
        begin
          if (Random <= AProbability) then
          begin
            if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
            begin
              FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := -1 + Floor(Random(3));
            end
            else
            begin
              LMin := Max(0, FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] - ASize);
              LMax := Min(__NORMALIZATION_VALUE, FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + ASize);

              LNewWeight := LMin + ((LMax - LMin)* IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
              Assert(LNewWeight >= 0.0);
              Assert(LNewWeight <= __NORMALIZATION_VALUE);

              if (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight) > __NORMALIZATION_VALUE then
              begin
                LNewWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
                Assert(LNewWeight >= 0.0);
                Assert(LNewWeight <= __NORMALIZATION_VALUE);
              end;

              LSumPositive := LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight;
              Assert(LSumPositive >= 0.0);
              Assert(LSumPositive <= __NORMALIZATION_VALUE);

              FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LNewWeight;
            end;
          end;
        end;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := __COUNT_OUTPUT_NEURONS;
  Assert(FNetData.OutputLayer.IsOutput);
  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    if (Random <= AProbability) then
    begin
      Assert(not FNetData.OutputLayer.HasNegativeInput);
    end;
  end;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    Assert(not FNetData.OutputLayer.HasNegativeInput);
    LSumPositive := 0.0;
    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

      LSumPositive := LSumPositive + FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
    end;
    Assert(LSumPositive >= 0.0);
    if not (LSumPositive <= __NORMALIZATION_VALUE) then // test
      if not (CompareValue(LSumPositive, __NORMALIZATION_VALUE) <= GreaterThanValue) then // test
        Assert(LSumPositive <= __NORMALIZATION_VALUE);

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      if (Random <= AProbability) then
      begin
        Assert(not FNetData.OutputLayer.HasNegativeInput);

        LMin := Max(0, FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] - ASize);
        LMax := Min(__NORMALIZATION_VALUE, FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + ASize);

        LNewWeight := LMin + ((LMax - LMin)* IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
        Assert(LNewWeight >= 0.0);
        Assert(LNewWeight <= __NORMALIZATION_VALUE);

        if (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight) > __NORMALIZATION_VALUE then
        begin
          LNewWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
          Assert(LNewWeight >= 0.0);
          Assert(LNewWeight <= __NORMALIZATION_VALUE);
        end;

        LSumPositive := LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LNewWeight;
        Assert(LSumPositive >= 0.0);
        Assert(LSumPositive <= __NORMALIZATION_VALUE);

        FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LNewWeight;
      end;
    end;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

//function TNet_05.CanFillMutateAddNeuron: Boolean;
//var
//  LIndexHiddenLayers: Integer;
//  LIndexNeurons: Integer;
//  LIndexLinks: Integer;
//begin
//  Result := False;
//
//  for LIndexHiddenLayers := 0 to FNetData.Count_Hidden_Layers - 1 do
//  begin
//    LIndexNeurons := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1;
//    if (CompareValue(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons], FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links) <> EqualsValue) then
//    begin
//      for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
//      begin
//        if CompareValue(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks], 0.0) <> EqualsValue then
//        begin
//          Result := True;
//          Exit;
//        end;
//      end;
//    end;
//  end;
//
//end;

//function TNet_05.TryFillMutateAddNeuron: Boolean;
//begin
//  Result := CanFillMutateAddNeuron;
//  if not Result then
//  begin
//    Exit;
//  end;
//
//  FillMutateAddNeuron;
//end;

procedure TNet_05.FillMutateAddNeuron;
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
begin
  FId := TGUID.NewGuid.ToString;

  // input
  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := Length(FNetData.HiddenLayers);
  Assert(FNetData.Count_Hidden_Layers = LCountHiddenLayers);

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons + 1;
    LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;

    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := FNetData.HiddenLayers[LIndexHiddenLayers - 1].Count_Neurons;
    end;

    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LHidden_Neurons_Count - 1] := __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LHidden_Neurons_Count_Previous);
    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values[LHidden_Neurons_Count - 1] := 0.0;
    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw[LHidden_Neurons_Count - 1] := 0.0;

    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;
    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      if Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons]) <> LHidden_Neurons_Count_Previous then
      begin
        SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);

        if (LIndexNeurons = LHidden_Neurons_Count - 1) then
        begin
          for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
          begin
            FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := 0.0;
          end;
        end
        else
        begin
          FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LHidden_Neurons_Count_Previous - 1] := 0.0;
        end;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := __COUNT_OUTPUT_NEURONS;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := FNetData.HiddenLayers[FNetData.Count_Hidden_Layers - 1].Count_Neurons;
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    FNetData.OutputLayer.Links_Weights[LIndexNeurons][LOutput_Links_Count - 1] := 0.0;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.FillMutateDeleteNeuron(const AUseThresholdOrWeight: Boolean; const AUseLimit: Boolean; const ALimit: Double);
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LMaxThreshold: Double;
  LMaxThresholdLimit: Double;
  LMaxThresholdIndex: Integer;
  LMinWeight: Double;
  LSumWeight: Double;
  LMinWeightLimit: Double;
  LMinWeightIndex: Integer;
  LDeleted: Boolean;
  LDeletedIndex: Integer;
  LOldNet: INet; // test
  LNet_05: TNet_05;
begin
  // test
  LOldNet := TNet_05.Create;
  LOldNet.CopyAll(Self);

  FId := TGUID.NewGuid.ToString;

  // input
  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := Length(FNetData.HiddenLayers);
  Assert(FNetData.Count_Hidden_Layers = LCountHiddenLayers);

  LDeleted := False;
  LDeletedIndex := -1;

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    if FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons < __COUNT_MIN_DELETE_NEURON then
    begin
      Continue;
    end;

    if AUseThresholdOrWeight then
    begin
      LMaxThreshold := -999999;
      LMaxThresholdIndex := -1;
      for LIndexNeurons := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 do
      begin
        if LMaxThreshold < FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] then
        begin
          LMaxThreshold := FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons];
          LMaxThresholdIndex := LIndexNeurons;
        end;
      end;

      if AUseLimit then
      begin
        LMaxThresholdLimit := IfThen(__THRESHOLD_MAX_1, 1, FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links) * ALimit;
        if LMaxThreshold < LMaxThresholdLimit then
        begin
          Continue;
        end;
      end;

      LDeleted := True;
      LDeletedIndex := LMaxThresholdIndex;
      if LDeletedIndex = -1 then   // test
        LDeletedIndex := LMaxThresholdIndex;

    end
    else
    begin
      LMinWeight := +999999;
      LMinWeightIndex := -1;
      for LIndexNeurons := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 do
      begin
        LSumWeight := Sum(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons]);

        if LMinWeight > LSumWeight then
        begin
          LMinWeight := LSumWeight;
          LMinWeightIndex := LIndexNeurons;
        end;
      end;

      if AUseLimit then
      begin
        LMinWeightLimit := 1 - ALimit;
        if LMinWeight > LMinWeightLimit then
        begin
          Continue;
        end;
      end;

      LDeleted := True;
      LDeletedIndex := LMinWeightIndex;
      if LDeletedIndex = -1 then   // test
        LDeletedIndex := LMinWeightIndex;

    end;

    if LDeleted then
    begin
      for LIndexNeurons := LDeletedIndex to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 - 1 do
      begin
        FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons + 1];
      end;

      if LIndexHiddenLayers = 0 then
      begin
        LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
      end
      else
      begin
        LHidden_Neurons_Count_Previous := FNetData.HiddenLayers[LIndexHiddenLayers - 1].Count_Neurons;
      end;

      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;
      for LIndexNeurons := LDeletedIndex to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 - 1 do
      begin
        for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
        begin
          FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] :=
            FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons + 1][LIndexLinks];
        end;
      end;

      LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1;

      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := LHidden_Neurons_Count;

      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);
    end;
  end;

  // Output
  if LDeleted then
  begin
    if Length(FNetData.HiddenLayers) = 0 then
    begin
      LOutput_Links_Count := LInput_Neurons_Count;
    end
    else
    begin
      LOutput_Links_Count := FNetData.HiddenLayers[FNetData.Count_Hidden_Layers - 1].Count_Neurons;
    end;

    for LIndexNeurons := 0 to FNetData.OutputLayer.Count_Neurons - 1 do
    begin
      for LIndexLinks := LDeletedIndex to FNetData.OutputLayer.Count_Links - 1 - 1 do
      begin
        FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] :=
          FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks + 1];
      end;
      SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    end;

    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    if __USE_NORMALIZATION then
      NormalizeWeightsAll;

    // test
    LNet_05 := TNet_05(LOldNet);
    LOldNet := nil;
    LNet_05 := nil;

    CheckNet(FNetData);

  end;

end;

//function TNet_05.CanFillMutateAddLevel: Boolean;
//var
//  LIndexHiddenLayers: Integer;
//  LIndexNeurons: Integer;
//  LIndexLinks: Integer;
//begin
//  Result := False;
//
//  if (FNetData.Count_Hidden_Layers > 2) then
//  begin
//    Exit(False);
//  end;
//
//  LIndexHiddenLayers := FNetData.Count_Hidden_Layers - 1;
//
//  for LIndexNeurons := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 do
//  begin
//    if CompareValue(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons], FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links) <> EqualsValue then
//    begin
//      for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
//      begin
//        if (LIndexLinks = LIndexNeurons) then
//        begin
//          if CompareValue(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks], 1) <> EqualsValue then
//          begin
//            Result := True;
//            Exit;
//          end;
//        end
//        else
//        begin
//          if CompareValue(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks], 0) <> EqualsValue then
//          begin
//            Result := True;
//            Exit;
//          end;
//        end;
//      end;
//    end;
//  end;
//
//end;
//
//function TNet_05.TryFillMutateAddLevel: Boolean;
//begin
//  Result := CanFillMutateAddLevel;
//  if not Result then
//  begin
//    Exit;
//  end;
//
//  FillMutateAddLevel;
//end;
//
//procedure TNet_05.FillMutateAddLevel;
//var
//  LCountHiddenLayers: Integer;
//  LHidden_Neurons_Count: Integer;
//  LHidden_Neurons_Count_Previous: Integer;
//  LIndexHiddenLayers: Integer;
//  LIndexNeurons: Integer;
//  LIndexLinks: Integer;
//begin
//  FId := TGUID.NewGuid.ToString;
//
//  // hidden
//  LCountHiddenLayers := Length(FNetData.HiddenLayers) + 1;
//  SetLength(FNetData.HiddenLayers, LCountHiddenLayers);
//  FNetData.Count_Hidden_Layers := LCountHiddenLayers;
//
//  Assert(FNetData.Count_Hidden_Layers >= 2);
//
//  LIndexHiddenLayers := LCountHiddenLayers - 1;
//
//  FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := FNetData.HiddenLayers[LIndexHiddenLayers - 1].Count_Neurons;
//  LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
//
//  SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
//  SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
//  SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
//  SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);
//
//  LHidden_Neurons_Count_Previous := FNetData.HiddenLayers[LIndexHiddenLayers - 1].Count_Neurons;
//
//  FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;
//  for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
//  begin
//    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := LHidden_Neurons_Count_Previous;
//    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values[LIndexNeurons] := 0.0;
//    FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw[LIndexNeurons] := 0.0;
//
//    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);
//
//    for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
//    begin
//      if (LIndexLinks = LIndexNeurons) then
//      begin
//        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := 1.0;
//      end
//      else
//      begin
//        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := 0.0;
//      end;
//    end;
//  end;
//
//  if __USE_NORMALIZATION then
//  NormalizeWeightsAll;
//
//  CheckNet(FNetData);
//
//end;

procedure TNet_05.CopyAll(ANet: INet);
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LNeuronThreshold: Double;
  LLinkWeight: Double;
begin
  FId := ANet.Id;

  // input
  LInput_Neurons_Count := ANet.GetNetData.InputLayer.Count_Neurons;
  Assert(__COUNT_INPUT_NEURONS = LInput_Neurons_Count);

  SetLength(FNetData.InputLayer.Neurons_Values, LInput_Neurons_Count);
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := ANet.GetNetData.Count_Hidden_Layers;
  SetLength(FNetData.HiddenLayers, LCountHiddenLayers);
  FNetData.Count_Hidden_Layers := LCountHiddenLayers;

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    LHidden_Neurons_Count := ANet.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);

    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := LHidden_Neurons_Count;
    FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput := ANet.GetNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput;
    FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput := ANet.GetNetData.HiddenLayers[LIndexHiddenLayers].IsOutput;
    Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput);

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      LNeuronThreshold := ANet.GetNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons];
      FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
    end;

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);
      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        LLinkWeight := ANet.GetNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := ANet.GetNetData.OutputLayer.Count_Neurons;
  Assert(LOutput_Neurons_Count = __COUNT_OUTPUT_NEURONS);
  SetLength(FNetData.OutputLayer.Links_Weights, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, LOutput_Neurons_Count);

  FNetData.OutputLayer.Count_Neurons := LOutput_Neurons_Count;
  FNetData.OutputLayer.HasNegativeInput := ANet.GetNetData.OutputLayer.HasNegativeInput;
  Assert(not FNetData.OutputLayer.HasNegativeInput);
  FNetData.OutputLayer.IsOutput := ANet.GetNetData.OutputLayer.IsOutput;
  Assert(FNetData.OutputLayer.IsOutput);

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    LNeuronThreshold := ANet.GetNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons];
    FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
  end;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      LLinkWeight := ANet.GetNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
      FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
    end;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.CopyReproduce(ANet1: INet; ANet2: INet);
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LNeuronThreshold: Double;
  LLinkWeight: Double;
  LSumPositive: Double;
  LMin: Integer;
  LMax: Integer;
  LHas1: Boolean;
  LHas2: Boolean;
  LUse1: Boolean;
  LUse2: Boolean;
begin
  FId := TGUID.NewGuid.ToString;

  Assert(ANet1 <> nil);
  Assert(ANet2 <> nil);

  LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  Assert(__COUNT_INPUT_NEURONS = LInput_Neurons_Count);

  SetLength(FNetData.InputLayer.Neurons_Values, LInput_Neurons_Count);
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  if ANet1.GetNetData.Count_Hidden_Layers = ANet2.GetNetData.Count_Hidden_Layers then
  begin
    LCountHiddenLayers := ANet1.GetNetData.Count_Hidden_Layers;
  end
  else
  begin
    LMin := Min(ANet1.GetNetData.Count_Hidden_Layers, ANet2.GetNetData.Count_Hidden_Layers);
    LMax := Max(ANet1.GetNetData.Count_Hidden_Layers, ANet2.GetNetData.Count_Hidden_Layers);
    LCountHiddenLayers := LMin + Round((LMax - LMin) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
  end;

  SetLength(FNetData.HiddenLayers, LCountHiddenLayers);
  FNetData.Count_Hidden_Layers := LCountHiddenLayers;

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    if (LIndexHiddenLayers > ANet1.GetNetData.Count_Hidden_Layers - 1) and
       (LIndexHiddenLayers <= ANet2.GetNetData.Count_Hidden_Layers - 1) then
    begin
      LHidden_Neurons_Count := ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
    end
    else if (LIndexHiddenLayers > ANet2.GetNetData.Count_Hidden_Layers - 1) and
       (LIndexHiddenLayers <= ANet1.GetNetData.Count_Hidden_Layers - 1) then
    begin
      LHidden_Neurons_Count := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
    end
    else if (LIndexHiddenLayers <= ANet1.GetNetData.Count_Hidden_Layers - 1) and
       (LIndexHiddenLayers <= ANet2.GetNetData.Count_Hidden_Layers - 1) then
    begin
      if (ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons = ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons) then
      begin
        LHidden_Neurons_Count := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
      end
      else
      begin
        LMin := Min(ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons, ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);
        LMax := Max(ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons, ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);
        LHidden_Neurons_Count := LMin + Round((LMax - LMin) * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM));
      end;
    end
    else
    begin
      Assert(False);
      LHidden_Neurons_Count := 0;
    end;

    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);

    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := LHidden_Neurons_Count;

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      LHas1 := (LIndexHiddenLayers <= ANet1.GetNetData.Count_Hidden_Layers - 1) and
        (LIndexNeurons <= ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1) ;

      LHas2 := (LIndexHiddenLayers <= ANet2.GetNetData.Count_Hidden_Layers - 1) and
        (LIndexNeurons <= ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1) ;

      if (Random > 0.5) then
      begin
        if (LHas1) then
        begin
          LUse1 := True;
          LUse2 := False;
        end
        else if (LHas2) then
        begin
          LUse1 := False;
          LUse2 := True;
        end
        else
        begin
          LUse1 := False;
          LUse2 := False;
        end;
      end
      else
      begin
        if (LHas2) then
        begin
          LUse1 := False;
          LUse2 := True;
        end
        else if (LHas1) then
        begin
          LUse1 := True;
          LUse2 := False;
        end
        else
        begin
          LUse1 := False;
          LUse2 := False;
        end;
      end;

      if (LUse1) then
      begin
        LNeuronThreshold := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons];
      end
      else if (LUse2) then
      begin
        LNeuronThreshold := ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons];
      end
      else
      begin
        if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
        begin
          LNeuronThreshold := -1 + Floor(Random(3));
        end
        else
        begin
          LNeuronThreshold := __NORMALIZATION_VALUE * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
        end;
      end;

      FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := Min(LNeuronThreshold, __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LHidden_Neurons_Count_Previous));
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);
      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;
      FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput;
      Assert(ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput = ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput);
      FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].IsOutput;
      Assert(ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].IsOutput = ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].IsOutput);
      Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput);

      Assert(not FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput);
      LSumPositive := 0.0;
      for LIndexLinks := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1 do
      begin
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
        Assert(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

        LSumPositive := LSumPositive + FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
      end;
      Assert(LSumPositive >= 0.0);
      Assert(LSumPositive <= __NORMALIZATION_VALUE);

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        LHas1 := (LIndexHiddenLayers <= ANet1.GetNetData.Count_Hidden_Layers - 1) and
          (LIndexNeurons <= ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1) and
          (LIndexLinks <= ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1);

        LHas2 := (LIndexHiddenLayers <= ANet2.GetNetData.Count_Hidden_Layers - 1) and
          (LIndexNeurons <= ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1) and
          (LIndexLinks <= ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Count_Links - 1);

        if (Random > 0.5) then
        begin
          if (LHas1) then
          begin
            LUse1 := True;
            LUse2 := False;
          end
          else if (LHas2) then
          begin
            LUse1 := False;
            LUse2 := True;
          end
          else
          begin
            LUse1 := False;
            LUse2 := False;
          end;
        end
        else
        begin
          if (LHas2) then
          begin
            LUse1 := False;
            LUse2 := True;
          end
          else if (LHas1) then
          begin
            LUse1 := True;
            LUse2 := False;
          end
          else
          begin
            LUse1 := False;
            LUse2 := False;
          end;
        end;

        if (LUse1) then
        begin
          LLinkWeight := ANet1.GetNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
        end
        else if (LUse2) then
        begin
          LLinkWeight := ANet2.GetNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks];
        end
        else
        begin
          if FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput then
          begin
            LLinkWeight := -1 + Floor(Random(3));
          end
          else
          begin
            LLinkWeight := __NORMALIZATION_VALUE * IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
          end;
        end;

        Assert(LLinkWeight >= 0.0);
        Assert(LLinkWeight <= __NORMALIZATION_VALUE);

        if (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight) > __NORMALIZATION_VALUE then
        begin
          LLinkWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
          Assert(LLinkWeight >= 0.0);
          Assert(LLinkWeight <= __NORMALIZATION_VALUE);
        end;

        LSumPositive := LSumPositive - FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight;
        Assert(LSumPositive >= 0.0);
        Assert(LSumPositive <= __NORMALIZATION_VALUE);

        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := __COUNT_OUTPUT_NEURONS;
  SetLength(FNetData.OutputLayer.Links_Weights, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, LOutput_Neurons_Count);

  FNetData.OutputLayer.Count_Neurons := LOutput_Neurons_Count;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    if (Random > 0.5) then
    begin
      LNeuronThreshold := ANet1.GetNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons];
    end
    else
    begin
      LNeuronThreshold := ANet2.GetNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons];
    end;
    FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons] := Min(__NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, LOutput_Links_Count), LNeuronThreshold);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    FNetData.OutputLayer.HasNegativeInput := False;
    Assert(not ANet1.GetNetData.OutputLayer.HasNegativeInput);
    Assert(not ANet2.GetNetData.OutputLayer.HasNegativeInput);

    FNetData.OutputLayer.IsOutput := True;
    Assert(ANet1.GetNetData.OutputLayer.IsOutput);
    Assert(ANet2.GetNetData.OutputLayer.IsOutput);

    Assert(not FNetData.OutputLayer.HasNegativeInput);
    LSumPositive := 0.0;
    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] >= 0.0);
      Assert(FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] <= __NORMALIZATION_VALUE);

      LSumPositive := LSumPositive + FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
    end;
    Assert(LSumPositive >= 0.0);
    Assert(LSumPositive <= __NORMALIZATION_VALUE);

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      LHas1 := (LIndexNeurons <= ANet1.GetNetData.OutputLayer.Count_Neurons - 1) and
        (LIndexLinks <= ANet1.GetNetData.OutputLayer.Count_Links - 1);

      LHas2 := (LIndexNeurons <= ANet2.GetNetData.OutputLayer.Count_Neurons - 1) and
        (LIndexLinks <= ANet2.GetNetData.OutputLayer.Count_Links - 1);

      if (Random > 0.5) then
      begin
        if (LHas1) then
        begin
          LUse1 := True;
          LUse2 := False;
        end
        else if (LHas2) then
        begin
          LUse1 := False;
          LUse2 := True;
        end
        else
        begin
          LUse1 := False;
          LUse2 := False;
        end;
      end
      else
      begin
        if (LHas2) then
        begin
          LUse1 := False;
          LUse2 := True;
        end
        else if (LHas1) then
        begin
          LUse1 := True;
          LUse2 := False;
        end
        else
        begin
          LUse1 := False;
          LUse2 := False;
        end;
      end;

      if (LUse1) then
      begin
        LLinkWeight := ANet1.GetNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
      end
      else if (LUse2) then
      begin
        LLinkWeight := ANet2.GetNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks];
      end
      else
      begin
        Assert(not FNetData.OutputLayer.HasNegativeInput);
        LLinkWeight := IfThen(__USE_RANDOM_1, Random(), Random(__MAX_RANDOM + 1) / __MAX_RANDOM);
      end;

      Assert(LLinkWeight >= 0.0);
      Assert(LLinkWeight <= __NORMALIZATION_VALUE);

      if (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight) > __NORMALIZATION_VALUE then
      begin
        LLinkWeight := Max(0.0, __NORMALIZATION_VALUE - (LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks]) - __ROUND_DELTA);
        Assert(LLinkWeight >= 0.0);
        Assert(LLinkWeight <= __NORMALIZATION_VALUE);
      end;

      LSumPositive := LSumPositive - FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] + LLinkWeight;
      Assert(LSumPositive >= 0.0);
      Assert(LSumPositive <= __NORMALIZATION_VALUE);

      FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
    end;
  end;

  Assert(Length(FNetData.InputLayer.Neurons_Values) = FNetData.InputLayer.Count_Neurons);

  Assert(Length(FNetData.HiddenLayers) = FNetData.Count_Hidden_Layers);
  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);
    Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons);

    for LIndexNeurons := 0 to FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons - 1 do
    begin
      if not (Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons]) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links) then
        Assert(Length(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons]) = FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links);
    end;
  end;

  Assert(Length(FNetData.OutputLayer.Neurons_Thresholds) = FNetData.OutputLayer.Count_Neurons);
  Assert(Length(FNetData.OutputLayer.Neurons_Values) = FNetData.OutputLayer.Count_Neurons);
  Assert(Length(FNetData.OutputLayer.Neurons_Values_Raw) = FNetData.OutputLayer.Count_Neurons);

  Assert(Length(FNetData.OutputLayer.Links_Weights) = FNetData.OutputLayer.Count_Neurons);
  for LIndexNeurons := 0 to FNetData.OutputLayer.Count_Neurons - 1 do
  begin
    if Length(FNetData.HiddenLayers) = 0 then
    begin
      Assert(Length(FNetData.OutputLayer.Links_Weights[LIndexNeurons]) = FNetData.InputLayer.Count_Neurons);
    end
    else
    begin
      Assert(Length(FNetData.OutputLayer.Links_Weights[LIndexNeurons]) = FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Count_Neurons);
    end;
  end;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.ReadIniFile(const AFileName: string);
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Neurons_Count_Previous: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LNeuronThreshold: Double;
  LLinkWeight: Double;
  LString: string;
begin
  FIniFile := TMemIniFile.Create(AFileName);
  FId := FIniFile.ReadString('Main', 'Id', '-1');

  // input
  LInput_Neurons_Count := FIniFile.ReadInteger('Input_Neurons', 'Count', __COUNT_INPUT_NEURONS);
  if not (__COUNT_INPUT_NEURONS = LInput_Neurons_Count) then
  begin
//    Assert(__COUNT_INPUT_NEURONS = LInput_Neurons_Count);
    LInput_Neurons_Count := __COUNT_INPUT_NEURONS;
  end;

  SetLength(FNetData.InputLayer.Neurons_Values, LInput_Neurons_Count);
  FNetData.InputLayer.Count_Neurons := LInput_Neurons_Count;

  // hidden
  LCountHiddenLayers := FIniFile.ReadInteger('Main', 'CountHiddenLayers', -1);
  SetLength(FNetData.HiddenLayers, LCountHiddenLayers);
  FNetData.Count_Hidden_Layers := LCountHiddenLayers;

  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
    LHidden_Neurons_Count := FIniFile.ReadInteger('Hidden_' + LIndexHiddenLayers.ToString + '_Neurons', 'Count', -1);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values, LHidden_Neurons_Count);
    SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Values_Raw, LHidden_Neurons_Count);

    FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons := LHidden_Neurons_Count;
    FNetData.HiddenLayers[LIndexHiddenLayers].HasNegativeInput := False;
    FNetData.HiddenLayers[LIndexHiddenLayers].IsOutput := False;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      LString := FIniFile.ReadString('Hidden_' + LIndexHiddenLayers.ToString + '_Neurons', 'Neuron_' + LIndexNeurons.ToString + '_Threshold', string.Empty);
      LString := StringReplace(LString, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      LString := StringReplace(LString, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      LNeuronThreshold := StrToFloat(LString);
      FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
    end;

    if LIndexHiddenLayers = 0 then
    begin
      LHidden_Neurons_Count_Previous := LInput_Neurons_Count;
    end
    else
    begin
      LHidden_Neurons_Count_Previous := Length(FNetData.HiddenLayers[LIndexHiddenLayers - 1].Neurons_Thresholds);
    end;

    for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
    begin
      SetLength(FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons], LHidden_Neurons_Count_Previous);
      FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links := LHidden_Neurons_Count_Previous;

      for LIndexLinks := 0 to LHidden_Neurons_Count_Previous - 1 do
      begin
        LString := FIniFile.ReadString('Hidden_' + LIndexHiddenLayers.ToString + '_Links', 'Neuron_' + LIndexNeurons.ToString + '_Link_' + LIndexLinks.ToString + '_Weight', string.Empty);
        LString := StringReplace(LString, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
        LString := StringReplace(LString, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
        LLinkWeight := StrToFloat(LString);
        FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
      end;
    end;
  end;

  // Output
  LOutput_Neurons_Count := FIniFile.ReadInteger('Output_Neurons', 'Count', __COUNT_OUTPUT_NEURONS);
  SetLength(FNetData.OutputLayer.Links_Weights, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Thresholds, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values, LOutput_Neurons_Count);
  SetLength(FNetData.OutputLayer.Neurons_Values_Raw, LOutput_Neurons_Count);

  FNetData.OutputLayer.Count_Neurons := LOutput_Neurons_Count;
  FNetData.OutputLayer.HasNegativeInput := False;
  FNetData.OutputLayer.IsOutput := True;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    LString := FIniFile.ReadString('Output_Neurons', 'Neuron_' + LIndexNeurons.ToString + '_Threshold', string.Empty);
    LString := StringReplace(LString, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
    LString := StringReplace(LString, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
    LNeuronThreshold := StrToFloat(LString);
    FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons] := LNeuronThreshold;
  end;

  if Length(FNetData.HiddenLayers) = 0 then
  begin
    LOutput_Links_Count := LInput_Neurons_Count;
  end
  else
  begin
    LOutput_Links_Count := Length(FNetData.HiddenLayers[Length(FNetData.HiddenLayers) - 1].Neurons_Thresholds);
  end;

  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    SetLength(FNetData.OutputLayer.Links_Weights[LIndexNeurons], LOutput_Links_Count);
    FNetData.OutputLayer.Count_Links := LOutput_Links_Count;

    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      LString := FIniFile.ReadString('Output_Links', 'Neuron_' + LIndexNeurons.ToString + '_Link_' + LIndexLinks.ToString + '_Weight', string.Empty);
      LString := StringReplace(LString, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      LString := StringReplace(LString, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      LLinkWeight := StrToFloat(LString);
      FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks] := LLinkWeight;
    end;
  end;

  FreeAndNil(FIniFile);

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

end;

procedure TNet_05.WriteIniFile;
var
  LInput_Neurons_Count: Integer;
  LCountHiddenLayers: Integer;
  LHidden_Neurons_Count: Integer;
  LHidden_Links_Count: Integer;
  LIndexHiddenLayers: Integer;
  LOutput_Neurons_Count: Integer;
  LOutput_Links_Count: Integer;
  LIndexNeurons: Integer;
  LIndexLinks: Integer;
  LId: string;
begin
  LId := FId;
  LId := StringReplace(LId, '{', '', []);
  LId := StringReplace(LId, '}', '', []);

  FIniFile := TMemIniFile.Create(Self.ClassName + '_' + LId + '.ini');
  FIniFile.WriteString('Main', 'Id', FId);
  FIniFile.WriteDateTime('Main', 'DateTime', Now());

  // input
  LInput_Neurons_Count := FNetData.InputLayer.Count_Neurons;
  FIniFile.WriteInteger('Input_Neurons', 'Count', LInput_Neurons_Count);

  // hidden
  LCountHiddenLayers := FNetData.Count_Hidden_Layers;
  FIniFile.WriteInteger('Main', 'CountHiddenLayers', LCountHiddenLayers);
  for LIndexHiddenLayers := 0 to LCountHiddenLayers - 1 do
  begin
   LHidden_Neurons_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Neurons;
   FIniFile.WriteInteger('Hidden_' + LIndexHiddenLayers.ToString + '_Neurons', 'Count', LHidden_Neurons_Count);
   for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
   begin
     FIniFile.WriteFloat('Hidden_' + LIndexHiddenLayers.ToString + '_Neurons', 'Neuron_' + LIndexNeurons.ToString + '_Threshold', FNetData.HiddenLayers[LIndexHiddenLayers].Neurons_Thresholds[LIndexNeurons]);
   end;

   LHidden_Links_Count := FNetData.HiddenLayers[LIndexHiddenLayers].Count_Links;
   FIniFile.WriteInteger('Hidden_' + LIndexHiddenLayers.ToString + '_Links', 'Count', LHidden_Links_Count);
   for LIndexNeurons := 0 to LHidden_Neurons_Count - 1 do
   begin
     for LIndexLinks := 0 to LHidden_Links_Count - 1 do
     begin
       FIniFile.WriteFloat('Hidden_' + LIndexHiddenLayers.ToString + '_Links', 'Neuron_' + LIndexNeurons.ToString + '_Link_' + LIndexLinks.ToString + '_Weight', FNetData.HiddenLayers[LIndexHiddenLayers].Links_Weights[LIndexNeurons][LIndexLinks]);
     end;
   end;
  end;

  // Output
  LOutput_Neurons_Count := FNetData.OutputLayer.Count_Neurons;
  FIniFile.WriteInteger('Output_Neurons', 'Count', LOutput_Neurons_Count);
  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    FIniFile.WriteFloat('Output_Neurons', 'Neuron_' + LIndexNeurons.ToString + '_Threshold', FNetData.OutputLayer.Neurons_Thresholds[LIndexNeurons]);
  end;

  LOutput_Links_Count := FNetData.OutputLayer.Count_Links;
  FIniFile.WriteInteger('Output_Links', 'Count', LOutput_Links_Count);
  for LIndexNeurons := 0 to LOutput_Neurons_Count - 1 do
  begin
    for LIndexLinks := 0 to LOutput_Links_Count - 1 do
    begin
      FIniFile.WriteFloat('Output_Links', 'Neuron_' + LIndexNeurons.ToString + '_Link_' + LIndexLinks.ToString + '_Weight', FNetData.OutputLayer.Links_Weights[LIndexNeurons][LIndexLinks]);
    end;
  end;

  UpdateIniFile;

  FreeAndNil(FIniFile);

//  CheckNet(FNetData);

end;

procedure TNet_05.UpdateIniFile;
begin
  FIniFile.UpdateFile;
end;

procedure TNet_05.Init(AField: TField; AMyValue: TCellValue);
var
  LIndexY: Integer;
  LIndexX: Integer;
begin
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      FField[LIndexY, LIndexX] := AField[LIndexY, LIndexX];
    end;
  end;

  FMyValue := AMyValue;

end;

function TNet_05.GetNextMoveEx: TMoveEx;
var
  LResult: TMove;
begin
  LResult := GetNextMove;

  Result.Y := LResult.Y;
  Result.X := LResult.X;
  Result.SelectedFigure := LResult.SelectedFigure;
  Result.Neurons_Values := FNetData.OutputLayer.Neurons_Values;

end;

function TNet_05.GetNextMove: TMove;
var
  LIndexY: Integer;
  LIndexX: Integer;
  LEmptyCount: Integer;
  LIndex_Neurons: Integer;
  LMaxValue: Double;
  LMaxValueIndex: Integer;
begin
  Result.SelectedFigure := TCellValue.___;
  Result.Y := -1;
  Result.X := -1;

  LEmptyCount := 0;
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      if (FField[LIndexY, LIndexX] = TCellValue.___) then
      begin
        Inc(LEmptyCount);
      end;
    end;
  end;

  if (LEmptyCount = 0) then
  begin
    Exit;
  end;

  for LIndex_Neurons := 0 to __NEURON_EMPTY_COUNT - 1 do
  begin
    if (FField[__MAP_NEURON_TO_FIELD[LIndex_Neurons][0],__MAP_NEURON_TO_FIELD[LIndex_Neurons][1]] = TCellValue.___) then
    begin
      FNetData.InputLayer.Neurons_Values[__NEURON_EMPTY_START + LIndex_Neurons] := 1;
    end
    else
    begin
      FNetData.InputLayer.Neurons_Values[__NEURON_EMPTY_START + LIndex_Neurons] := 0;
    end;
  end;

  for LIndex_Neurons := 0 to __NEURON_MY_COUNT - 1 do
  begin
    if (FField[__MAP_NEURON_TO_FIELD[LIndex_Neurons][0],__MAP_NEURON_TO_FIELD[LIndex_Neurons][1]] = FMyValue) then
    begin
      FNetData.InputLayer.Neurons_Values[__NEURON_MY_START + LIndex_Neurons] := 1;
    end
    else
    begin
      FNetData.InputLayer.Neurons_Values[__NEURON_MY_START + LIndex_Neurons] := 0;
    end;
  end;

  CalculateAll;

  LMaxValue := 0;
  LMaxValueIndex := -1;
  for LIndex_Neurons := 0 to Length(FNetData.OutputLayer.Neurons_Values) - 1 do
  begin
    if (LMaxValue < FNetData.OutputLayer.Neurons_Values[LIndex_Neurons]) then
    begin
      LMaxValue := FNetData.OutputLayer.Neurons_Values[LIndex_Neurons];
      LMaxValueIndex := LIndex_Neurons;
    end;
  end;

  if (LMaxValue > 0.0) and (LMaxValueIndex > -1) then
  begin
    Result.SelectedFigure := FMyValue;
    Result.Y := __MAP_NEURON_TO_FIELD[LMaxValueIndex][0];
    Result.X := __MAP_NEURON_TO_FIELD[LMaxValueIndex][1];
  end
  else
  begin
    Result.SelectedFigure := TCellValue.___;
    Result.Y := -1;
    Result.X := -1;
  end;

end;

procedure TNet_05.CalculateAll;
var
  LIndex_HiddenLayers: Integer;
begin
  LIndex_HiddenLayers := 0;
  if FNetData.Count_Hidden_Layers = 0 then
  begin
    Assert(FNetData.OutputLayer.HasNegativeInput);
    CalculateLayer(FNetData.InputLayer.Count_Neurons, FNetData.InputLayer.Neurons_Values, FNetData.OutputLayer);
  end
  else
  begin
    CalculateLayer(FNetData.InputLayer.Count_Neurons, FNetData.InputLayer.Neurons_Values, FNetData.HiddenLayers[LIndex_HiddenLayers]);

    for LIndex_HiddenLayers := 0 + 1 to FNetData.Count_Hidden_Layers - 1 do
    begin
      CalculateLayer(FNetData.HiddenLayers[LIndex_HiddenLayers - 1].Count_Neurons, FNetData.HiddenLayers[LIndex_HiddenLayers - 1].Neurons_Values, FNetData.HiddenLayers[LIndex_HiddenLayers]);
    end;

    CalculateLayer(FNetData.HiddenLayers[FNetData.Count_Hidden_Layers - 1].Count_Neurons, FNetData.HiddenLayers[FNetData.Count_Hidden_Layers - 1].Neurons_Values, FNetData.OutputLayer);
  end;

end;

procedure TNet_05.CalculateLayer(ACount_Neurons: Integer; ANeurons_Values: TNeurons_Values; ALayer: TLayer);
var
  LIndex_Neurons: Integer;
  LIndex_Links: Integer;
  LSum: Double;
begin
  Assert(ACount_Neurons = Length(ANeurons_Values));

  Assert(ALayer.Count_Neurons = Length(ALayer.Links_Weights));
  if not (ALayer.Count_Neurons = Length(ALayer.Neurons_Thresholds)) then
    Assert(ALayer.Count_Neurons = Length(ALayer.Neurons_Thresholds));
  if not (ALayer.Count_Neurons = Length(ALayer.Neurons_Values)) then
    Assert(ALayer.Count_Neurons = Length(ALayer.Neurons_Values));
  if ALayer.IsOutput then
  begin
    if not (ALayer.Count_Neurons = Length(ALayer.Neurons_Values_Raw)) then
      Assert(ALayer.Count_Neurons = Length(ALayer.Neurons_Values_Raw));
  end;

  for LIndex_Neurons := 0 to ALayer.Count_Neurons - 1 do
  begin
    if not (ACount_Neurons = ALayer.Count_Links) then
      Assert(ACount_Neurons = ALayer.Count_Links);
    if not (ACount_Neurons = Length(ALayer.Links_Weights[LIndex_Neurons])) then
      Assert(ACount_Neurons = Length(ALayer.Links_Weights[LIndex_Neurons]));

    LSum := 0.0;
    for LIndex_Links := 0 to ALayer.Count_Links - 1 do
    begin
      if ALayer.HasNegativeInput then
      begin
        Assert(ANeurons_Values[LIndex_Links] >= -1.0);
      end
      else
      begin
        Assert(ANeurons_Values[LIndex_Links] >= 0.0);
      end;
      Assert(ANeurons_Values[LIndex_Links] <= __NORMALIZATION_VALUE);

      if ALayer.HasNegativeInput then
      begin
        Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] >= -1.0);
        Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);
      end
      else
      begin
        Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] >= 0.0);
        Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);
      end;

      LSum := LSum +
        ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] *
        ANeurons_Values[LIndex_Links];
    end;

    if ALayer.HasNegativeInput then
    begin
      Assert((CompareValue(LSum, -1) >= EqualsValue));
    end
    else
    begin
      Assert((CompareValue(LSum, 0) >= EqualsValue));
    end;

    if not ((CompareValue(LSum, __NORMALIZATION_VALUE * ALayer.Count_Links) <= EqualsValue)) then //test
      Assert((CompareValue(LSum, __NORMALIZATION_VALUE * ALayer.Count_Links) <= EqualsValue));

    if ALayer.HasNegativeInput then
    begin
      if LSum < -1.0 then
      begin
        LSum := -1.0;
      end;
    end
    else
    begin
      if LSum < 0.0 then
      begin
        LSum := 0.0;
      end;
    end;

    if LSum > ALayer.Count_Links then
    begin
      LSum := ALayer.Count_Links;
    end;

    if ALayer.IsOutput then
    begin
      ALayer.Neurons_Values[LIndex_Neurons] := LSum;
      ALayer.Neurons_Values_Raw[LIndex_Neurons] := LSum;
    end
    else
    begin
      ALayer.Neurons_Values_Raw[LIndex_Neurons] := LSum;

      if (CompareValue(LSum, ALayer.Neurons_Thresholds[LIndex_Neurons]) >= EqualsValue) then
      begin
        ALayer.Neurons_Values[LIndex_Neurons] := 1;
      end
      else
      begin
        ALayer.Neurons_Values[LIndex_Neurons] := 0;
      end;
    end;
  end;
end;

procedure TNet_05.Reward(AReward: Integer);
begin
  WriteIniFile;
  UpdateIniFile;
end;

procedure TNet_05.NormalizeWeightsAll;
var
  LIndex_HiddenLayers: Integer;
begin
  Assert(FNetData.InputLayer.Count_Neurons = Length(FNetData.InputLayer.Neurons_Values));
  Assert(FNetData.Count_Hidden_Layers = Length(FNetData.HiddenLayers));

  for LIndex_HiddenLayers := 0 to FNetData.Count_Hidden_Layers - 1 do
  begin
    if LIndex_HiddenLayers = 0 then
    begin
      NormalizeWeightsLayer(FNetData.HiddenLayers[LIndex_HiddenLayers]);
    end
    else
    begin
      NormalizeWeightsLayer(FNetData.HiddenLayers[LIndex_HiddenLayers]);
    end;
  end;

  NormalizeWeightsLayer(FNetData.OutputLayer);
end;

procedure TNet_05.NormalizeWeightsLayer(ALayer: TLayer);
var
  LIndex_Neurons: Integer;
  LIndex_Links: Integer;
  LSumPositive: Double;
  LSumNegative: Double;
  LSumResult: Double;
  LSumCheckPositive: Double;
  LSumCheckNegative: Double;
begin
  Assert(ALayer.Count_Neurons = Length(ALayer.Links_Weights));
  Assert(ALayer.Count_Neurons = Length(ALayer.Neurons_Thresholds));
  Assert(ALayer.Count_Neurons = Length(ALayer.Neurons_Values));

  for LIndex_Neurons := 0 to ALayer.Count_Neurons - 1 do
  begin
    // > 0.0
    LSumPositive := 0.0;
    for LIndex_Links := 0 to ALayer.Count_Links - 1 do
    begin
      if ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] > 0.0 then
      begin
        LSumPositive := LSumPositive + ALayer.Links_Weights[LIndex_Neurons][LIndex_Links];
      end;
    end;

    // < 0.0
    LSumNegative := 0.0;
    for LIndex_Links := 0 to ALayer.Count_Links - 1 do
    begin
      if ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] < 0.0 then
      begin
        if ALayer.HasNegativeInput then
        begin
          LSumNegative := LSumNegative + ALayer.Links_Weights[LIndex_Neurons][LIndex_Links];
        end
        else
        begin
          //
          ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] := 0.0;
        end;
      end;
    end;

    Assert(LSumPositive >= 0.0);

    if ALayer.HasNegativeInput then
    begin
      Assert(LSumNegative <= 0.0);
    end
    else
    begin
      Assert(LSumNegative = 0.0);
    end;

    LSumResult := Max(LSumPositive, Abs(LSumNegative));

    if (LSumResult <> 0) and (CompareValue(LSumResult, __NORMALIZATION_VALUE * Length(ALayer.Links_Weights[0])) > EqualsValue) then
    begin
      for LIndex_Links := 0 to ALayer.Count_Links - 1 do
      begin
        if ALayer.HasNegativeInput then
        begin
          ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] := __NORMALIZATION_VALUE * ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] / (2 * LSumResult);
        end
        else
        begin
          ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] := __NORMALIZATION_VALUE * ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] / LSumResult;
        end;
      end;

      LSumCheckPositive := 0.0;
      LSumCheckNegative := 0.0;

      for LIndex_Links := 0 to ALayer.Count_Links - 1 do
      begin
        if ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] > 0.0 then
        begin
          Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] >= 0);
          Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);

          LSumCheckPositive := LSumCheckPositive + ALayer.Links_Weights[LIndex_Neurons][LIndex_Links];
        end;

        if ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] < 0.0 then
        begin
          Assert(ALayer.HasNegativeInput);

          Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] >= -1.0);
          Assert(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] <= 0.0);

          LSumCheckNegative := LSumCheckNegative + ALayer.Links_Weights[LIndex_Neurons][LIndex_Links];
        end;
      end;

      Assert((CompareValue(LSumCheckPositive, 0) = EqualsValue) or (CompareValue(LSumCheckPositive, 0) = GreaterThanValue));
      Assert((CompareValue(LSumCheckPositive, __NORMALIZATION_VALUE) = EqualsValue) or (CompareValue(LSumCheckPositive, __NORMALIZATION_VALUE) = LessThanValue));

      if ALayer.HasNegativeInput then
      begin
        if not ((CompareValue(LSumCheckNegative, -1) = EqualsValue) or (CompareValue(LSumCheckNegative, -1) = GreaterThanValue)) then
          Assert((CompareValue(LSumCheckNegative, -1) = EqualsValue) or (CompareValue(LSumCheckNegative, -1) = GreaterThanValue));
        Assert((CompareValue(LSumCheckNegative, 0)  = EqualsValue) or (CompareValue(LSumCheckNegative, 0)  = LessThanValue));
      end
      else
      begin
        Assert(CompareValue(LSumCheckNegative, 0)  = EqualsValue);
      end;

    end;
  end;

//  for LIndex_Neurons := 0 to ALayer.Count_Neurons - 1 do
//  begin
//    ALayer.Neurons_Thresholds[LIndex_Neurons] := Trunc(__TRUNC_PRECISION * RoundTo(ALayer.Neurons_Thresholds[LIndex_Neurons], __ROUND_PRECISION)) / __TRUNC_PRECISION;
//    for LIndex_Links := 0 to ALayer.Count_Links - 1 do
//    begin
//      ALayer.Links_Weights[LIndex_Neurons][LIndex_Links] := Trunc(__TRUNC_PRECISION * RoundTo(ALayer.Links_Weights[LIndex_Neurons][LIndex_Links], __ROUND_PRECISION)) / __TRUNC_PRECISION;
//    end;
//  end;

end;

procedure TNet_05.CheckNet(ANetData: TNetData);
var
  LIndex_HiddenLayers: Integer;
  LIndex_Neurons: Integer;
  LIndex_Links: Integer;
begin
  Assert(ANetData.InputLayer.Count_Neurons = Length(ANetData.InputLayer.Neurons_Values));
  Assert(ANetData.Count_Hidden_Layers = Length(ANetData.HiddenLayers));

  for LIndex_HiddenLayers := 0 to ANetData.Count_Hidden_Layers - 1 do
  begin
    Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Neurons = Length(ANetData.HiddenLayers[LIndex_HiddenLayers].Links_Weights));
    Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Neurons = Length(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Thresholds));
    Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Neurons = Length(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Values));
    Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Neurons = Length(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Values_Raw));

    Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].HasNegativeInput = False);
    Assert(not ANetData.HiddenLayers[LIndex_HiddenLayers].IsOutput);

    for LIndex_Neurons := 0 to ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Neurons - 1 do
    begin
      if ANetData.HiddenLayers[LIndex_HiddenLayers].HasNegativeInput then
      begin
        Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Thresholds[LIndex_Neurons] >= -1);
      end
      else
      begin
        Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Thresholds[LIndex_Neurons] >= 0);
      end;
      if not (ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Thresholds[LIndex_Neurons] <= __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Links)) then //
        Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Neurons_Thresholds[LIndex_Neurons] <= __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Links));

      for LIndex_Links := 0 to ANetData.HiddenLayers[LIndex_HiddenLayers].Count_Links - 1 do
      begin
        if ANetData.HiddenLayers[LIndex_HiddenLayers].HasNegativeInput then
        begin
          Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Links_Weights[LIndex_Neurons][LIndex_Links] >= -1.0);
          Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);
        end
        else
        begin
          Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Links_Weights[LIndex_Neurons][LIndex_Links] >= 0.0);
          Assert(ANetData.HiddenLayers[LIndex_HiddenLayers].Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);
        end;
      end;
    end;
  end;

  for LIndex_Neurons := 0 to ANetData.OutputLayer.Count_Neurons - 1 do
  begin
    if not (not ANetData.OutputLayer.HasNegativeInput) then
      Assert(not ANetData.OutputLayer.HasNegativeInput);
    if not (ANetData.OutputLayer.IsOutput) then
      Assert(ANetData.OutputLayer.IsOutput);

    Assert(ANetData.OutputLayer.Neurons_Thresholds[LIndex_Neurons] >= 0);
    Assert(ANetData.OutputLayer.Neurons_Thresholds[LIndex_Neurons] <= __NORMALIZATION_VALUE * IfThen(__THRESHOLD_MAX_1, 1, ANetData.OutputLayer.Count_Links));

    for LIndex_Links := 0 to ANetData.OutputLayer.Count_Links - 1 do
    begin
      Assert(not ANetData.OutputLayer.HasNegativeInput);
      Assert(ANetData.OutputLayer.Links_Weights[LIndex_Neurons][LIndex_Links] >= 0.0);
      Assert(ANetData.OutputLayer.Links_Weights[LIndex_Neurons][LIndex_Links] <= __NORMALIZATION_VALUE);
    end;
  end;

end;

procedure TNet_05.BackPropagation_Old(const AField: TField; const AMoveOld: TMoveEx; const AMoveExpected: TMoveEx; const ACheck: Boolean);
var
  LMoveEx: TMoveEx;
  LIndex: Integer;
  LNeuron_Index_Output_Old: Integer;
  LNeuron_Index_Output_Expected: Integer;
  LNeuron_Index_Output: Integer;
  LNeuron_Index_Hidden: Integer;
  LNeuron_Index_Input: Integer;
  LNeuron_Delta_Output: Double;
  LNeuron_Delta_3: Double;
  LNeuron_Delta_Hidden: Double;
  LNeuron_Active_Links_Sum: Double;
  LNeuron_All_Links_Sum: Double;
  LNew_Link_Weight: Double;
  LIndex_Link_Sum: Integer;
  LIndex_Link_Output: Integer;
  LIndex_Link_Hidden: Integer;
  LIndex_Hidden_Layer: Integer;
//  LNeuron_Delta_Weighted: Double;
  LMultiplier: Double;
  LMoveNew: TMoveEx;
  LMaxPrev: Double;
  LMaxPrevIndex: Integer;
begin
  if ACheck then
  begin
    LMoveEx := GetNextMoveEx;

    Assert(LMoveEx.Y = AMoveOld.Y);
    Assert(LMoveEx.X = AMoveOld.X);

    for LIndex := 0 to Length(LMoveEx.Neurons_Values) - 1 do
    begin
      Assert(LMoveEx.Neurons_Values[LIndex] = AMoveOld.Neurons_Values[LIndex]);
    end;
  end;

  SetLength(LMoveNew.Neurons_Values, Length(AMoveOld.Neurons_Values));
  for LIndex := 0 to Length(AMoveOld.Neurons_Values) - 1 do
  begin
    LMoveNew.Neurons_Values[LIndex] := AMoveOld.Neurons_Values[LIndex];
  end;

  LNeuron_Index_Output_Expected := __MAP_FIELD_TO_NEURON[AMoveExpected.Y, AMoveExpected.X];

  if (AMoveOld.Y = -1) and (AMoveOld.X = -1) then
  begin
    Assert(LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] = 0.0);
    LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] := __WEIGHT_DELTA;
  end
  else
  begin
    LNeuron_Index_Output_Old := __MAP_FIELD_TO_NEURON[AMoveOld.Y,      AMoveOld.X];

    LMaxPrev := -99999.0;
    LMaxPrevIndex := -1;

    for LIndex := 0 to Length(AMoveOld.Neurons_Values) - 1 do
    begin
      if LIndex <> LNeuron_Index_Output_Old then
      begin
        if LMaxPrev < AMoveOld.Neurons_Values[LIndex] then
        begin
          LMaxPrev := AMoveOld.Neurons_Values[LIndex];
          LMaxPrevIndex := LIndex;
        end;
      end;
    end;

    Assert(LMaxPrev >= 0.0);
    if not (LMaxPrev <= 1.0) then // test
      Assert(LMaxPrev <= 1.0);
    Assert(LMaxPrevIndex >= 0);
    Assert(LMaxPrevIndex <= Length(AMoveOld.Neurons_Values) - 1);

    LMoveNew.Neurons_Values[LNeuron_Index_Output_Old] := (LMoveNew.Neurons_Values[LNeuron_Index_Output_Old] + LMaxPrev) / 2;

    if LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] < 1.0 then
    begin
      LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] := Min(1.0, LMoveNew.Neurons_Values[LNeuron_Index_Output_Old] + __WEIGHT_DELTA);
    end
    else
    begin
      for LIndex := 0 to Length(LMoveNew.Neurons_Values) - 1 do
      begin
        if LMoveNew.Neurons_Values[LIndex] = 1.0 then
        begin
          LMoveNew.Neurons_Values[LIndex] := 1.0 - __WEIGHT_DELTA;
        end;
      end;
    end;
  end;

  Assert(LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] >= 0.0);
  if not (LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] <= 1.0) then
  begin
    Assert(LMoveNew.Neurons_Values[LNeuron_Index_Output_Expected] <= 1.0);
    Exit;
  end;

  Assert(FNetData.Count_Hidden_Layers = 1);
  LIndex_Hidden_Layer := 0;

  for LNeuron_Index_Output := 0 to FNetData.OutputLayer.Count_Neurons - 1 do
  begin
    LNeuron_Delta_Output := LMoveNew.Neurons_Values[LNeuron_Index_Output] - AMoveOld.Neurons_Values[LNeuron_Index_Output];

    if LNeuron_Delta_Output <> 0.0 then
    begin
      LNeuron_Delta_3 := LNeuron_Delta_Output / 3;

      LNeuron_All_Links_Sum := 0.0;
      LNeuron_Active_Links_Sum := 0.0;
      for LIndex_Link_Sum := 0 to FNetData.OutputLayer.Count_Links - 1 do
      begin
        LNeuron_Index_Hidden := LIndex_Link_Sum;
        Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);
        LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
        if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Sum] = 1.0 then
        begin
          LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
        end;
      end;

      Assert(LNeuron_All_Links_Sum >= 0.0);
      if not (LNeuron_All_Links_Sum <= 1.0) then
        Assert(LNeuron_All_Links_Sum <= 1.0);

      Assert(LNeuron_Active_Links_Sum >= 0.0);
      if not (LNeuron_Active_Links_Sum <= 1.0) then
        Assert(LNeuron_Active_Links_Sum <= 1.0);

      for LIndex_Link_Output := 0 to FNetData.OutputLayer.Count_Links - 1 do
      begin
        LNeuron_Index_Hidden := LIndex_Link_Output;
        Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);

        if LNeuron_Delta_Output < 0.0 then
        begin
          if not (LNeuron_Active_Links_Sum > 0.0) then
            Assert(LNeuron_Active_Links_Sum > 0.0);

          if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 1.0 then
          begin
            LNew_Link_Weight := Max(0.0,
              FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] +
              LNeuron_Delta_3 * FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] / LNeuron_Active_Links_Sum);

            Assert(LNew_Link_Weight >= 0.0);
            Assert(LNew_Link_Weight <= 1.0);

            LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum - FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] + LNew_Link_Weight;
            FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] := LNew_Link_Weight;

            Assert(LNeuron_Active_Links_Sum >= 0.0);
            Assert(LNeuron_Active_Links_Sum <= 1.0);

            Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] >= 0.0);
            Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] <= 1.0);

            LNeuron_All_Links_Sum := 0.0;
            LNeuron_Active_Links_Sum := 0.0;
            for LIndex_Link_Sum := 0 to FNetData.OutputLayer.Count_Links - 1 do
            begin
              LNeuron_Index_Hidden := LIndex_Link_Sum;
              Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);
              LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Sum] = 1.0 then
              begin
                LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              end;
            end;

            Assert(LNeuron_All_Links_Sum >= 0.0);
            Assert(LNeuron_All_Links_Sum <= 1.0);

            Assert(LNeuron_Active_Links_Sum >= 0.0);
            Assert(LNeuron_Active_Links_Sum <= 1.0);

          end;
        end
        else if LNeuron_Delta_Output > 0.0 then
        begin
          Assert(FNetData.OutputLayer.Count_Links > 0.0);

          LNew_Link_Weight := Min(1.0,
            FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] +
            LNeuron_Delta_3 / FNetData.OutputLayer.Count_Links);

          Assert(LNew_Link_Weight >= 0.0);
          Assert(LNew_Link_Weight <= 1.0);

          if (LNeuron_All_Links_Sum - FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] + LNew_Link_Weight) <= 1.0 then
          begin
            LNeuron_All_Links_Sum := LNeuron_All_Links_Sum - FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] + LNew_Link_Weight;
            FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] := LNew_Link_Weight;

            Assert(LNeuron_All_Links_Sum >= 0.0);
            Assert(LNeuron_All_Links_Sum <= 1.0);

            LNeuron_All_Links_Sum := 0.0;
            LNeuron_Active_Links_Sum := 0.0;
            for LIndex_Link_Sum := 0 to FNetData.OutputLayer.Count_Links - 1 do
            begin
              LNeuron_Index_Hidden := LIndex_Link_Sum;
              Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);
              LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Sum] = 1.0 then
              begin
                LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              end;
            end;

            Assert(LNeuron_All_Links_Sum >= 0.0);
            Assert(LNeuron_All_Links_Sum <= 1.0);

            Assert(LNeuron_Active_Links_Sum >= 0.0);
            Assert(LNeuron_Active_Links_Sum <= 1.0);
          end
          else
          begin
            FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] :=
              FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] + (1.0 - LNeuron_All_Links_Sum);
            LNeuron_All_Links_Sum := 1.0;

            Assert(LNeuron_All_Links_Sum >= 0.0);
            Assert(LNeuron_All_Links_Sum <= 1.0);

            Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] >= 0.0);
            Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] <= 1.0);

            LNeuron_All_Links_Sum := 0.0;
            LNeuron_Active_Links_Sum := 0.0;
            for LIndex_Link_Sum := 0 to FNetData.OutputLayer.Count_Links - 1 do
            begin
              LNeuron_Index_Hidden := LIndex_Link_Sum;
              Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);
              LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Sum] = 1.0 then
              begin
                LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Sum];
              end;
            end;

            Assert(LNeuron_All_Links_Sum >= 0.0);
            Assert(LNeuron_All_Links_Sum <= 1.0);

            Assert(LNeuron_Active_Links_Sum >= 0.0);
            Assert(LNeuron_Active_Links_Sum <= 1.0);

          end;
        end
        else
        begin
          Assert(False);
        end;

        LNeuron_Delta_Hidden := 0.0;

        if LNeuron_Delta_Output < 0.0 then
        begin
          if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 1.0 then
          begin
            if not(CompareValue(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden], FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden]) >= EqualsValue) then
              Assert(CompareValue(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden], FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden]) >= EqualsValue);

            LNeuron_Delta_Hidden := (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] - FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden]);

            FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] :=
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] +
              LNeuron_Delta_Hidden *
              LNeuron_Delta_3
              //* (1 - FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output])
              ;
          end;
        end
        else if LNeuron_Delta_Output > 0.0 then
        begin
          if FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 0.0 then
          begin
            Assert(CompareValue(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden], FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden]) < EqualsValue);

            LNeuron_Delta_Hidden := (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] - FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden]);

            FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] :=
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] -
              LNeuron_Delta_Hidden *
              LNeuron_Delta_3
              //* (1 - FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output])
              ;
          end;
        end
        else
        begin
          Assert(False);
        end;

        LNeuron_All_Links_Sum := 0.0;
        LNeuron_Active_Links_Sum := 0.0;
        for LIndex_Link_Sum := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
        begin
          LNeuron_Index_Input := LIndex_Link_Sum;
          Assert(LNeuron_Index_Input <= FNetData.InputLayer.Count_Neurons - 1);
          LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
          if FNetData.InputLayer.Neurons_Values[LNeuron_Index_Input] = 1.0 then
          begin
            LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
          end;
        end;

        Assert(LNeuron_All_Links_Sum >= 0.0);
        if not (LNeuron_All_Links_Sum <= 1.0) then
          Assert(LNeuron_All_Links_Sum <= 1.0);

        Assert(LNeuron_Active_Links_Sum >= 0.0);
        if not (LNeuron_Active_Links_Sum <= 1.0) then
          Assert(LNeuron_Active_Links_Sum <= 1.0);

        for LIndex_Link_Hidden := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
        begin
          LNeuron_Index_Input := LIndex_Link_Hidden;
          Assert(LNeuron_Index_Input <= FNetData.InputLayer.Count_Neurons - 1);

          if LNeuron_Delta_Hidden < 0.0 then
          begin
            Assert(LNeuron_Active_Links_Sum > 0.0);

            if FNetData.InputLayer.Neurons_Values[LNeuron_Index_Input] = 1.0 then
            begin
              LNew_Link_Weight := Max(0.0,
                FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] +
                LNeuron_Delta_3 / FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links);

              Assert(LNew_Link_Weight >= 0.0);
              Assert(LNew_Link_Weight <= 1.0);

              LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum - FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] + LNew_Link_Weight;
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] := LNew_Link_Weight;

              Assert(LNeuron_Active_Links_Sum >= 0.0);
              Assert(LNeuron_Active_Links_Sum <= 1.0);

              Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] >= 0.0);
              Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] <= 1.0);

              LNeuron_All_Links_Sum := 0.0;
              LNeuron_Active_Links_Sum := 0.0;
              for LIndex_Link_Sum := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
              begin
                LNeuron_Index_Input := LIndex_Link_Sum;
                Assert(LNeuron_Index_Input <= FNetData.InputLayer.Count_Neurons - 1);
                LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                if FNetData.InputLayer.Neurons_Values[LNeuron_Index_Input] = 1.0 then
                begin
                  LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                end;
              end;

              Assert(LNeuron_All_Links_Sum >= 0.0);
              Assert(LNeuron_All_Links_Sum <= 1.0);

              Assert(LNeuron_Active_Links_Sum >= 0.0);
              Assert(LNeuron_Active_Links_Sum <= 1.0);

            end;
          end
          else if LNeuron_Delta_Hidden > 0.0 then
          begin
            Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links > 0.0);

            LNew_Link_Weight := Min(1.0,
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] +
              LNeuron_Delta_3 / FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links);

            Assert(LNew_Link_Weight >= 0.0);
            Assert(LNew_Link_Weight <= 1.0);

            if (LNeuron_All_Links_Sum - FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] + LNew_Link_Weight) <= 1.0 then
            begin
              LNeuron_All_Links_Sum := LNeuron_All_Links_Sum - FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] + LNew_Link_Weight;
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] := LNew_Link_Weight;

              Assert(LNeuron_All_Links_Sum >= 0.0);
              Assert(LNeuron_All_Links_Sum <= 1.0);

              LNeuron_All_Links_Sum := 0.0;
              LNeuron_Active_Links_Sum := 0.0;
              for LIndex_Link_Sum := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
              begin
                LNeuron_Index_Input := LIndex_Link_Sum;
                Assert(LNeuron_Index_Input <= FNetData.InputLayer.Count_Neurons - 1);
                LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                if FNetData.InputLayer.Neurons_Values[LNeuron_Index_Input] = 1.0 then
                begin
                  LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                end;
              end;

              Assert(LNeuron_All_Links_Sum >= 0.0);
              Assert(LNeuron_All_Links_Sum <= 1.0);

              Assert(LNeuron_Active_Links_Sum >= 0.0);
              Assert(LNeuron_Active_Links_Sum <= 1.0);

            end
            else
            begin
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] :=
                FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] + (1.0 - LNeuron_All_Links_Sum);
              LNeuron_All_Links_Sum := 1.0;

              Assert(LNeuron_All_Links_Sum >= 0.0);
              Assert(LNeuron_All_Links_Sum <= 1.0);

              if not(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] <= 1.0) then
                Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] >= 0.0);
              if not(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] >= 0.0) then
                Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] >= 0.0);

              LNeuron_All_Links_Sum := 0.0;
              LNeuron_Active_Links_Sum := 0.0;
              for LIndex_Link_Sum := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
              begin
                LNeuron_Index_Input := LIndex_Link_Sum;
                Assert(LNeuron_Index_Input <= FNetData.InputLayer.Count_Neurons - 1);
                LNeuron_All_Links_Sum := LNeuron_All_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                if FNetData.InputLayer.Neurons_Values[LNeuron_Index_Input] = 1.0 then
                begin
                  LNeuron_Active_Links_Sum := LNeuron_Active_Links_Sum  + FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Sum];
                end;
              end;

              Assert(LNeuron_All_Links_Sum >= 0.0);
              Assert(LNeuron_All_Links_Sum <= 1.0);

              Assert(LNeuron_Active_Links_Sum >= 0.0);
              Assert(LNeuron_Active_Links_Sum <= 1.0);

            end;
          end;

        end;
      end;
    end;

  end;

//  if ACheck then
//  begin
//    LMoveEx := GetNextMoveEx;
//    if not ((LMoveEx.Y <> AMoveExpected.Y) or (LMoveEx.X <> AMoveExpected.X)) then
//      LMoveEx := GetNextMoveEx;
////      Assert((LMoveEx.Y <> AMoveExpected.Y) or (LMoveEx.X <> AMoveExpected.X));
//  end;

//  NormalizeWeightsAll;

end;

procedure TNet_05.BackPropagation(const AField: TField; const AMoveOld: TMoveEx; const AMoveExpected: TMoveEx; const ACheck: Boolean);
var
  LIndex: Integer;
  LError: Double;
begin

  FNetData.HiddenLayers[0].Neurons_Thresholds[0] := 0.5;
  FNetData.HiddenLayers[0].Neurons_Thresholds[1] := 0.5;

  FNetData.HiddenLayers[0].Links_Weights[0][0] := 0.3;
  FNetData.HiddenLayers[0].Links_Weights[0][1] := 0.4;
  FNetData.HiddenLayers[0].Links_Weights[1][0] := 0.5;
  FNetData.HiddenLayers[0].Links_Weights[1][1] := 0.6;

  FNetData.OutputLayer.Neurons_Thresholds[0] := 0.5;
  FNetData.OutputLayer.Neurons_Thresholds[1] := 0.5;

  FNetData.OutputLayer.Links_Weights[0][0] := 0.9;
  FNetData.OutputLayer.Links_Weights[0][1] := 1.0;
  FNetData.OutputLayer.Links_Weights[1][0] := 0.1;
  FNetData.OutputLayer.Links_Weights[1][1] := 0.2;

  if __USE_NORMALIZATION then
    NormalizeWeightsAll;

  CheckNet(FNetData);

  for LIndex := 1 to 100000 do
  begin
    LError := 0.0;

    BackPropagation_test(0, 0, 0, 0);
    LError := LError +
      sqr(0 - FNetData.OutputLayer.Neurons_Values[0]) +
      sqr(0 - FNetData.OutputLayer.Neurons_Values[0])
      ;

    BackPropagation_test(0, 1, 0, 1);
    LError := LError +
      sqr(0 - FNetData.OutputLayer.Neurons_Values[0]) +
      sqr(1 - FNetData.OutputLayer.Neurons_Values[0])
      ;

    BackPropagation_test(1, 0, 1, 0);
    LError := LError +
      sqr(1 - FNetData.OutputLayer.Neurons_Values[0]) +
      sqr(0 - FNetData.OutputLayer.Neurons_Values[0])
      ;

    BackPropagation_test(1, 1, 1, 1);
    LError := LError +
      sqr(1 - FNetData.OutputLayer.Neurons_Values[0]) +
      sqr(1 - FNetData.OutputLayer.Neurons_Values[0])
      ;

  end;

  if LError = 0.0 then // test
    CheckNet(FNetData);

end;

procedure TNet_05.GetLinkSum(const ANeurons_Values: TNeurons_Values; const ALinks_Weights_Post: array of Double; out ANeuron_Active_Links_Count: Integer; out ANeuron_Active_Links_Sum: Double; out ANeuron_All_Links_Sum: Double);
var
  LIndex_Link_Sum: Integer;
begin
  Assert(Length(ANeurons_Values) = Length(ALinks_Weights_Post));

  ANeuron_Active_Links_Count := 0;
  ANeuron_Active_Links_Sum := 0.0;
  ANeuron_All_Links_Sum := 0.0;
  for LIndex_Link_Sum := 0 to Length(ALinks_Weights_Post) - 1 do
  begin
    Assert(LIndex_Link_Sum <= Length(ANeurons_Values) - 1);
    ANeuron_All_Links_Sum := ANeuron_All_Links_Sum  + ALinks_Weights_Post[LIndex_Link_Sum];
    if ANeurons_Values[LIndex_Link_Sum] = 1.0 then
    begin
      ANeuron_Active_Links_Count := ANeuron_Active_Links_Count + 1;
      ANeuron_Active_Links_Sum := ANeuron_Active_Links_Sum  + ALinks_Weights_Post[LIndex_Link_Sum];
    end;
  end;

  Assert(ANeuron_All_Links_Sum >= 0.0);
  if not (ANeuron_All_Links_Sum <= 1.0) then
    Assert(ANeuron_All_Links_Sum <= 1.0);

  Assert(ANeuron_Active_Links_Sum >= 0.0);
  if not (ANeuron_Active_Links_Sum <= 1.0) then
    Assert(ANeuron_Active_Links_Sum <= 1.0);

end;

procedure TNet_05.BackPropagation_test(const LInput0: Integer; const LInput1: Integer; const LExpectedOutput0: Integer; const LExpectedOutput1: Integer);
var
  LMoveEx: TMoveEx;
  LIndex: Integer;
  LNeuron_Index_Output_Old: Integer;
  LNeuron_Index_Output_Expected: Integer;
  LNeuron_Index_Output: Integer;
  LNeuron_Index_Hidden: Integer;
  LNeuron_Index_Input: Integer;
  LNeuron_Delta_Output: Double;
  LNeuron_Delta_Hidden: Double;
  LNeuron_Active_Links_Sum_Output: Double;
  LNeuron_Active_Links_Count_Output: Integer;
  LNeuron_All_Links_Sum_Output: Double;
  LNeuron_Active_Links_Sum_Hidden: Double;
  LNeuron_Active_Links_Count_Hidden: Integer;
  LNeuron_All_Links_Sum_Hidden: Double;
  LNeuron_Active_Links_Sum_Test: Double;
  LNeuron_Active_Links_Count_Test: Integer;
  LNeuron_All_Links_Sum_Test: Double;
  LNew_Link_Weight_Delta: Double;
  LIndex_Link_Output: Integer;
  LIndex_Link_Hidden: Integer;
  LIndex_Hidden_Layer: Integer;
  LMultiplier: Double;
  LMoveOld: TMoveEx;
  LMoveNew: TMoveEx;
  LMaxPrev: Double;
  LMaxPrevIndex: Integer;
begin

  FNetData.InputLayer.Neurons_Values[0] := LInput0;
  FNetData.InputLayer.Neurons_Values[1] := LInput1;

  CalculateAll;

  if (FNetData.OutputLayer.Neurons_Values[0] = LExpectedOutput0) and (FNetData.OutputLayer.Neurons_Values[1] = LExpectedOutput1) then
  begin
    LMoveOld.Y := 0;
    Exit;
  end;

  LMoveOld.Y := 0;
  LMoveOld.X := 0;
  LMoveOld.SelectedFigure := TCellValue.___;
  SetLength(LMoveOld.Neurons_Values, 2);
  LMoveOld.Neurons_Values[0] := FNetData.OutputLayer.Neurons_Values[0];
  LMoveOld.Neurons_Values[1] := FNetData.OutputLayer.Neurons_Values[1];

  LMoveNew.Y := 0;
  LMoveNew.X := 0;
  LMoveNew.SelectedFigure := TCellValue.___;
  SetLength(LMoveNew.Neurons_Values, 2);
  LMoveNew.Neurons_Values[0] := LExpectedOutput0;
  LMoveNew.Neurons_Values[1] := LExpectedOutput1;

  Assert(FNetData.Count_Hidden_Layers = 1);
  LIndex_Hidden_Layer := 0;

  for LNeuron_Index_Output := 0 to FNetData.OutputLayer.Count_Neurons - 1 do
  begin
//    LNeuron_Delta_Output := LMoveNew.Neurons_Values[LNeuron_Index_Output] - AMoveOld.Neurons_Values[LNeuron_Index_Output];
    LNeuron_Delta_Output := LMoveNew.Neurons_Values[LNeuron_Index_Output] - LMoveOld.Neurons_Values[LNeuron_Index_Output];

    if LNeuron_Delta_Output <> 0.0 then
    begin
      GetLinkSum(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values, FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output],
        LNeuron_Active_Links_Count_Output, LNeuron_Active_Links_Sum_Output, LNeuron_All_Links_Sum_Output);

      for LIndex_Link_Output := 0 to FNetData.OutputLayer.Count_Links - 1 do
      begin
        LNeuron_Index_Hidden := LIndex_Link_Output;
        Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);

        LNeuron_Delta_Hidden := 0.0;
        LNew_Link_Weight_Delta := 0.0;

        if (LNeuron_Delta_Output > 0.0) then
        begin
          LNew_Link_Weight_Delta := Max(0.0, (LNeuron_Delta_Output - LNeuron_All_Links_Sum_Output)) / FNetData.OutputLayer.Count_Links;

          if (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 0.0) then
          begin
//            LNeuron_Delta_Hidden := 0.5 * LNeuron_Delta_Output * FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output];
            LNeuron_Delta_Hidden := 0.5 * (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LIndex_Link_Output] - FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LIndex_Link_Output]);

            Assert(LNeuron_Delta_Hidden > 0.0);

          end
          else if (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 1.0) then
          begin
            LNeuron_Delta_Hidden := 0;
          end
          else
          begin
            Assert(False);
          end;
        end
        else if (LNeuron_Delta_Output < 0.0) then
        begin
          if (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 0.0) then
          begin
            Continue;
          end
          else if (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values[LIndex_Link_Output] = 1.0) then
          begin
            if LNeuron_Active_Links_Count_Output <> 0 then
            begin
              LNew_Link_Weight_Delta := (LNeuron_Delta_Output) / LNeuron_Active_Links_Count_Output;
            end;

            Assert(CompareValue(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden], FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden]) >= EqualsValue);

//            LNeuron_Delta_Hidden := (FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] - FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LNeuron_Index_Hidden]);
            LNeuron_Delta_Hidden := 0.5 * (
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LIndex_Link_Output] -
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values_Raw[LIndex_Link_Output] +
              LNeuron_Delta_Output * FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output]
              );

            Assert(LNeuron_Delta_Hidden <= 0.0);
          end
          else
          begin
            Assert(False);
          end
        end
        else
        begin
          Assert(False);
        end;

        Assert(LNew_Link_Weight_Delta >= -1.0);
        Assert(LNew_Link_Weight_Delta <=  1.0);

        FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] := Max(0.0, Min(1.0,
          FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] + __LEARN_RATE * LNew_Link_Weight_Delta));

        GetLinkSum(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Values, FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output],
          LNeuron_Active_Links_Count_Test, LNeuron_Active_Links_Sum_Test, LNeuron_All_Links_Sum_Test);

        Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] >= 0.0);
        Assert(FNetData.OutputLayer.Links_Weights[LNeuron_Index_Output][LIndex_Link_Output] <= 1.0);

//        FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] := Max(0.0, Min(1.0,
//          FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] -
//          __LEARN_RATE * LNeuron_Delta_Hidden));

        Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] >= 0.0);
        Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Neurons_Thresholds[LNeuron_Index_Hidden] <= 1.0);


        GetLinkSum(FNetData.InputLayer.Neurons_Values, FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden],
          LNeuron_Active_Links_Count_Hidden, LNeuron_Active_Links_Sum_Hidden, LNeuron_All_Links_Sum_Hidden);

        for LIndex_Link_Hidden := 0 to FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Links - 1 do
        begin
          LNeuron_Index_Hidden := LIndex_Link_Output;
          Assert(LNeuron_Index_Hidden <= FNetData.HiddenLayers[LIndex_Hidden_Layer].Count_Neurons - 1);

          LNew_Link_Weight_Delta := 0.0;

          if (LNeuron_Delta_Hidden > 0.0) then
          begin
            if (FNetData.InputLayer.Neurons_Values[LIndex_Link_Hidden] = 1.0) then
            begin
              if LNeuron_Active_Links_Count_Hidden <> 0 then
              begin
                LNew_Link_Weight_Delta := Max(0.0, (LNeuron_Delta_Hidden - LNeuron_All_Links_Sum_Hidden)) / LNeuron_Active_Links_Count_Hidden;
              end;
            end;
          end
          else if (LNeuron_Delta_Hidden < 0.0) then
          begin
            if (FNetData.InputLayer.Neurons_Values[LIndex_Link_Hidden] = 1.0) then
            begin
              if LNeuron_Active_Links_Count_Hidden <> 0 then
              begin
                LNew_Link_Weight_Delta := Max(0.0, (LNeuron_Delta_Hidden - LNeuron_All_Links_Sum_Hidden)) / LNeuron_Active_Links_Count_Hidden;
              end;
            end;
          end
          else
          begin
            // possible
          end;

          if LNew_Link_Weight_Delta <> 0.0 then
          begin
            Assert(LNew_Link_Weight_Delta >= -1.0);
            Assert(LNew_Link_Weight_Delta <=  1.0);

            FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] := Max(0.0, Min(1.0,
              FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] + __LEARN_RATE * LNew_Link_Weight_Delta));

            GetLinkSum(FNetData.InputLayer.Neurons_Values, FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden],
              LNeuron_Active_Links_Count_Test, LNeuron_Active_Links_Sum_Test, LNeuron_All_Links_Sum_Test);

            Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] >= 0.0);
            Assert(FNetData.HiddenLayers[LIndex_Hidden_Layer].Links_Weights[LNeuron_Index_Hidden][LIndex_Link_Hidden] <= 1.0);
          end;

        end;

      end;
    end;

  end;

end;

end.
