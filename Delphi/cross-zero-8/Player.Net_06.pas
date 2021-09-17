unit Player.Net_06;

interface

uses
  System.SysUtils
  , Common.Interfaces
  ;

type
  TPlayer_Net_05 = class(TInterfacedObject, IPlayer, IPlayerEx)
  strict private
    FNet: INet;
    FId: string;

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
  Utils
  ;

constructor TPlayer_Net_05.Create;
begin
  inherited Create;

  FNet := GUtils.Create_Net;
  FId := TGUID.NewGuid.ToString;
end;

destructor TPlayer_Net_05.Destroy;
begin
  FNet := nil;
end;

function TPlayer_Net_05.GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
begin
  FNet.Init(AField, AMyValue);
  Result := FNet.GetNextMove;
end;

function TPlayer_Net_05.GetNet: INet;
begin
  Result := FNet;
end;

procedure TPlayer_Net_05.SetNet(AValue: INet);
begin
  FNet := AValue;
end;

procedure TPlayer_Net_05.SetId(AValue: string);
begin
  FId := AValue;
end;

function TPlayer_Net_05.GetId: string;
begin
  Result := FId;
end;

end.
