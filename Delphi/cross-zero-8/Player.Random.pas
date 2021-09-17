unit Player.Random;

interface

uses
  Common.Constants
  , Common.Interfaces
  ;

type
  TPlayer_Random = class(TInterfacedObject, IPlayer)
  public
    function GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
  end;

implementation

function TPlayer_Random.GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
var
  LIndexY: Integer;
  LIndexX: Integer;
  LEmptyCount: Integer;
begin
  LEmptyCount := 0;
  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      if (AField[LIndexY, LIndexX] = TCellValue.___) then
      begin
        Inc(LEmptyCount);
      end;
    end;
  end;

  if (LEmptyCount = 0) then
  begin
    Result.SelectedFigure := TCellValue.___;
    Exit;
  end;

  Result.SelectedFigure := AMyValue;

  repeat
    Result.Y := __MIN_Y + Random(1 + __MAX_Y - __MIN_Y);
    Result.X := __MIN_X + Random(1 + __MAX_X - __MIN_X);
  until (AField[Result.Y, Result.X] = TCellValue.___);

end;

end.
