unit Player.Interfaces;

interface

const
  __MIN_Y = 1;
  __MAX_Y = 3;

  __MIN_X = 1;
  __MAX_X = 3;

  __COUNT_MOVES_IN_PARTY_MAX = 10;

  __BAD_MAX = -999999;
  __GOOD_MOVE_ONE   = -9999999;
  __GOOD_CELL_EMPTY = +100;
//  __GOOD_2_IN_LINE  = +10;
  __GOOD_WIN        = +50;

  __GOOD_TEMPLATE_ONE   = +1;
  __GOOD_TEMPLATE_ALL   = +1000;

type
  TLimit = record
    ResultMax: Integer;
    ResultMin: Integer;
  end;

const
  __WIN_LIMITS_NOT_GROW_COUNT_MAX = 100;

  __POPULATION_COUNT_ARRAY     = 5000;

  __GENERATORS_COUNT     = 1;
  __PRE_CANDIDATES_COUNT = 1;
  __CANDIDATES_COUNT     = 1;
  __MASTER_COUNT         = 1;

  __POPULATION_COUNT_GENERATOR         = 1000;
  __POPULATION_COUNT_PRE_CANDIDATE_MIN = 1000;   __POPULATION_COUNT_PRE_CANDIDATE_MAX = 2000;
  __POPULATION_COUNT_CANDIDATE_MIN     = 3000;   __POPULATION_COUNT_CANDIDATE_MAX     = 4000;
                                                 __POPULATION_COUNT_MASTER            = 5000;

  __REPEAT_GENERATOR         = 100;
  __REPEAT_PRE_CANDIDATE_MIN = 200;   __REPEAT_PRE_CANDIDATE_MAX =  500;
  __REPEAT_CANDIDATE_MIN     = 500;   __REPEAT_CANDIDATE_MAX     = 1000;
                                      __REPEAT_MASTER            = 1000;

  __GENERATION_COUNT = 100000000;
  __PARTIES_COUNT = 200;

  __NEW_WINNER_MIN_COPY               = 0.1;     __NEW_WINNER_MAX_COPY               = 0.1;      __NEW_WINNER_MASTER_COPY               = 0.1;
  __NEW_WINNER_MIN_REPRODUCE          = 0.001;   __NEW_WINNER_MAX_REPRODUCE          = 0.4;      __NEW_WINNER_MASTER_REPRODUCE          = 0.07;
  __NEW_WINNER_MIN_MUTATE_ADD_NEURON  = 0.0000;  __NEW_WINNER_MAX_MUTATE_ADD_NEURON  = 0.0000;   __NEW_WINNER_MASTER_MUTATE_ADD_NEURON  = 0.0001;
  __NEW_WINNER_MIN_MUTATE_ADD_LEVEL   = 0.0;     __NEW_WINNER_MAX_MUTATE_ADD_LEVEL   = 0.0;      __NEW_WINNER_MASTER_MUTATE_ADD_LEVEL   = 0.0;
  __NEW_WINNER_MIN_MUTATE_FEW_LOW     = 0.001;   __NEW_WINNER_MAX_MUTATE_FEW_LOW     = 0.4;      __NEW_WINNER_MASTER_MUTATE_FEW_LOW     = 0.4;
  __NEW_WINNER_MIN_MUTATE_FEW_HIGH    = 0.001;   __NEW_WINNER_MAX_MUTATE_FEW_HIGH    = 0.1;      __NEW_WINNER_MASTER_MUTATE_FEW_HIGH    = 0.01;
  __NEW_WINNER_MIN_MUTATE_MANY_LOW    = 0.001;   __NEW_WINNER_MAX_MUTATE_MANY_LOW    = 0.4;      __NEW_WINNER_MASTER_MUTATE_MANY_LOW    = 0.4;
  __NEW_WINNER_MIN_MUTATE_MANY_HIGH   = 0.001;   __NEW_WINNER_MAX_MUTATE_MANY_HIGH   = 0.1;      __NEW_WINNER_MASTER_MUTATE_MANY_HIGH   = 0.01;
  __NEW_RANDOM = 0.01;

  __NEW_WINNER_MUTATE_FEW  = 0.01;
  __NEW_WINNER_MUTATE_MANY = 0.90;
  __NEW_WINNER_MUTATE_LOW  = 0.01;
  __NEW_WINNER_MUTATE_HIGH = 0.90;

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
    MoveResult: Integer;
    IsEnd: Boolean;
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
    Count_Links: Integer;
    Links_Weights: array of array of Double;
    Neurons_Thresholds: array of Double;
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
    procedure FillMutate(AProbability: Double; ASize: Double);
    procedure CopyAll(ANet: INet);
    procedure CopyReproduce(ANet1: INet; ANet2: INet);

    procedure FillMutateAddNeuron;
    function CanFillMutateAddNeuron: Boolean;
    function TryFillMutateAddNeuron: Boolean;

    function CanFillMutateAddLevel: Boolean;
    function TryFillMutateAddLevel: Boolean;
    procedure FillMutateAddLevel;

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
    ResultMax: Integer;
    ResultMin: Integer;
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

const
  __MAX_RANDOM = 10000;

  __COUNT_INPUT_NEURONS = 18;
  __COUNT_OUTPUT_NEURONS = 9;

  __DEFAULT_COUNT_HIDDEN_LAYERS = 1;
  __DEFAULT_COUNT_HIDDEN_NEURONS = 18;

type
  TMapNeuronToField = array [0..8] of array [0..1] of Integer;

const
  __MAP_NEURON_TO_FIELD: TMapNeuronToField = ((1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3));
  __NEURON_EMPTY_START = 0;
  __NEURON_EMPTY_COUNT = 9;
  __NEURON_MY_START = 9;
  __NEURON_MY_COUNT = 9;

type
  TWeightedNet = record
    Net: INet;
    Weight: Double;
  end;


implementation

end.
