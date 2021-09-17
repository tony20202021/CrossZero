unit Common.Interfaces;

interface

uses
  Common.Constants
  ;

type
  TLimit = record
    ResultMax: Integer;
    ResultMin: Integer;
  end;

type
  TCellValue = (___, _X_, _0_);

  TField = array[__MIN_Y..__MAX_Y, __MIN_X..__MAX_X] of TCellValue;

  TNeurons_Values = array of Double;

  TMove = record
    Y: Integer;
    X: Integer;
    SelectedFigure: TCellValue;
  end;

  TMoveEx = record
    Y: Integer;
    X: Integer;
    SelectedFigure: TCellValue;
    Neurons_Values: TNeurons_Values;
  end;

  TMoveSide = (sideLeft, sideRight);

  TMoveResult = record
    Y: Integer;
    X: Integer;
    IsEnd: Boolean;
    IsWin: Boolean;
    IsLost: Boolean;
    IsEmpty: Boolean;
    Count_2_In_Line: Integer;
  end;

  TPartyResult = array[TMoveSide] of Integer;

const
  TSideValues: array[TMoveSide] of TCellValue = (TCellValue._X_, TCellValue._0_);

  TCellLabel: array[TCellValue] of string = ('', 'X', '0');
  TCellKey: array[TCellValue] of string = ('_', 'X', '0');

type
  TLayerNoLinks = record
    Count_Neurons: Integer;
    Neurons_Values: TNeurons_Values;
  end;

  TLayer = record
    Count_Neurons: Integer;
    Neurons_Values: TNeurons_Values;
    Neurons_Values_Raw: TNeurons_Values;
    Count_Links: Integer;
    Links_Weights: array of array of Double;
    Neurons_Thresholds: array of Double;
    HasNegativeInput: Boolean;
    IsOutput: Boolean;
  end;

  TNetData = record
    Count_Hidden_Layers: Integer;
    InputLayer: TLayerNoLinks;
    HiddenLayers: array of TLayer;
    OutputLayer: TLayer;
  end;

type
  IPlayer = interface
  ['{4B50767E-2973-4476-9D6C-483888D5F023}']
    function GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
  end;

  INet = interface;

  IPlayerEx = interface(IPlayer)
  ['{7C624366-F0AE-4B74-AEED-32E82F599250}']
    function GetNet: INet;
    procedure SetNet(AValue: INet);
    property Net: INet read GetNet write SetNet;

    procedure SetId(AValue: string);
    function GetId: string;
    property Id: string read GetId write SetId;
  end;

  INet = interface
  ['{986F5386-5876-4CA7-BD9C-1CF122D43BE4}']
    procedure Init(AField: TField; AMyValue: TCellValue);
    function GetNextMove: TMove;
    function GetNextMoveEx: TMoveEx;

    procedure Reset;
    procedure CreateRandom;
    procedure FillRandom;
    procedure FillMutate(const AProbability: Double; const ASize: Double; const AForceLastNeuron: Boolean);
    procedure CopyAll(ANet: INet);
    procedure CopyReproduce(ANet1: INet; ANet2: INet);

    procedure FillMutateAddNeuron;
//    function CanFillMutateAddNeuron: Boolean;
//    function TryFillMutateAddNeuron: Boolean;

    procedure FillMutateDeleteNeuron(const AUseThresholdOrWeight: Boolean; const AUseLimit: Boolean; const ALimit: Double);

//    function CanFillMutateAddLevel: Boolean;
//    function TryFillMutateAddLevel: Boolean;
//    procedure FillMutateAddLevel;

    procedure BackPropagation(const AField: TField; const AMoveOld: TMoveEx; const AMoveExpected: TMoveEx; const ACheck: Boolean);

    function GetNetDescription: string;
    function GetNetData: TNetData;

    procedure ReadIniFile(const AFileName: string);
    procedure WriteIniFile;

    procedure Reward(AReward: Integer);

    function GetId: string;
    property Id: string read GetId;
  end;

type
  TPartyPlayers = array[TMoveSide] of IPlayer;

  TInstance = record
    Player: IPlayerEx;
    HasResult: Boolean;
    ResultMax: Int64;
    ResultMin: Int64;
    ResultAvg: Int64;
    ResultTemplateEmpty: Int64;
    ResultTemplateLineMy: Int64;
    ResultTemplateLineEnemy: Int64;
    ResultRandom: Int64;
    ResultValue: Int64;
    Id: string;
  end;

  TInstanceArray = record
    Count: Integer;
    Instances: array [0 .. __POPULATION_COUNT_ARRAY - 1] of TInstance;
  end;

  TLevel = record
    Limit: TLimit;
    Origin: TInstanceArray;
    Winners: TInstanceArray;
  end;

  TPopulaton = array of TLevel;

type
  TMapNeuronToField = array [0..8] of array [0..1] of Integer;
  TMapFieldToNeuron = array [1..3] of array [1..3] of Integer;

const
  __MAP_NEURON_TO_FIELD: TMapNeuronToField = ((1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3));
  __MAP_FIELD_TO_NEURON: TMapFieldToNeuron = ((0, 1, 2), (3, 4, 5), (6, 7, 8));

  __NEURON_EMPTY_START = 0;
  __NEURON_EMPTY_COUNT = 9;
  __NEURON_MY_START = 9;
  __NEURON_MY_COUNT = 9;
  __NEURON_FIELD_START = 0;
  __NEURON_FIELD_COUNT = 9;

type
  TWeightedNet = record
    Net: INet;
//    Weight: Double;
  end;

implementation

end.
