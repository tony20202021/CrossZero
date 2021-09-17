unit Stage;

interface

uses
  Common.Interfaces
  ;

type
  TRules = record
    ClearNotWinners     : Boolean;
    Winners             : Double;
    EnemyNetLimit       : Double;
    PartiesCount        : Integer;
    NewCopy             : Double;
    NewReproduce        : Double;
    NewMutateAddNeuron  : Double;
    NewMutateAddLevel   : Double;
    NewMutateFewLow     : Double;
    NewMutateFewHigh    : Double;
    NewMutateManyLow    : Double;
    NewMutateManyHigh   : Double;
  end;

  TStage = class
  strict private
    FName: string;
    FLoad: Boolean;
    FIsMaster: Boolean;
    FPopulationCount: Integer;
    FRepeatLevelLast: Integer;
    FPopulaton: TPopulaton;
    FHasInput: Boolean;
    FIsWaiting: Boolean;
    FInput: TPopulaton;
    FInputLock: TObject;
    FIsInited: Boolean;
  public
    Rules: TRules;

    constructor Create;
    destructor Destroy; override;

    procedure SetInputLength(ALength: Integer);
    procedure SetPopulatonLength(ALength: Integer);

    property Name: string read FName write FName;
    property Load: Boolean read FLoad write FLoad;
    property IsMaster: Boolean read FIsMaster write FIsMaster;
    property Populaton: TPopulaton read FPopulaton write FPopulaton;
    property HasInput: Boolean read FHasInput write FHasInput;
    property IsWaiting: Boolean read FIsWaiting write FIsWaiting;
    property Input: TPopulaton read FInput write FInput;
    property InputLock: TObject read FInputLock write FInputLock;
    property PopulationCount: Integer read FPopulationCount write FPopulationCount;
    property RepeatLevelLast: Integer read FRepeatLevelLast write FRepeatLevelLast;
    property IsInited: Boolean read FIsInited write FIsInited;
  end;

implementation

uses
  System.SysUtils
  ;

constructor TStage.Create;
begin
  inherited;

  InputLock := TObject.Create;
end;

destructor TStage.Destroy;
begin
  FreeAndNil(InputLock);

  inherited;
end;

procedure TStage.SetInputLength(ALength: Integer);
begin
  SetLength(FInput, ALength);
end;

procedure TStage.SetPopulatonLength(ALength: Integer);
begin
  SetLength(FPopulaton, ALength);
end;

end.
