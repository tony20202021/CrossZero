unit Player.Algorithm;

interface

uses
  Player.Interfaces
  ;

type
  TPlayer_Algorithm = class(TInterfacedObject, IPlayer)
  public
    function GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
  end;

implementation

uses
  System.Math
  , Utils
  ;

function TPlayer_Algorithm.GetNextMove(AField: TField; AMyValue: TCellValue): TMove;
var
  LIndexY: Integer;
  LIndexX: Integer;
  LEmptyCount: Integer;
//  LMyCount: Integer;
  LEnemyCount: Integer;
begin
  LEmptyCount := 0;
//  LMyCount := 0;
  LEnemyCount := 0;

  for LIndexY := __MIN_Y to __MAX_Y do
  begin
    for LIndexX := __MIN_X to __MAX_X do
    begin
      if (AField[LIndexY, LIndexX] = TCellValue.___) then
      begin
        Inc(LEmptyCount);
      end
      else if (AField[LIndexY, LIndexX] = AMyValue) then
      begin
//        Inc(LMyCount);
      end
      else if (AField[LIndexY, LIndexX] <> AMyValue) then
      begin
        Inc(LEnemyCount);
      end
      else
      begin
        // сюда не должны попадать
        Assert(False);
      end;
    end;
  end;

  if (LEmptyCount = 0) then
  begin
    // все занято
    Result.X := -1;
    Result.Y := -1;
    Result.SelectedFigure := TCellValue.___;
    Exit;
  end;

  if (TUtils.IsEmpty(AField, AMyValue)) then
  begin
    Result.X := IfThen(Random() > 0.5, 1, 3);
    Result.Y := IfThen(Random() > 0.5, 1, 3);
    Result.SelectedFigure := AMyValue;
    Exit;
  end;

  if (LEnemyCount = 1) then
  begin
    if (TUtils.IsEnemyInCorner(AField, AMyValue)) then
    begin
      Result.X := 1;
      Result.Y := 1;
      Result.SelectedFigure := AMyValue;
      Exit;
    end
    else
    begin
      Result.X := IfThen(Random() > 0.5, 1, 3);
      Result.Y := IfThen(Random() > 0.5, 1, 3);
      Result.SelectedFigure := AMyValue;
      Exit;
    end;
  end;

//  if TUtils.Check_Win_Vertical(AField, 2, AMyValue, 1)

  Result.SelectedFigure := AMyValue;
  repeat
    Result.Y := __MIN_Y + Random(1 + __MAX_Y - __MIN_Y);
    Result.X := __MIN_X + Random(1 + __MAX_X - __MIN_X);
  until (AField[Result.Y, Result.X] = TCellValue.___);


end;

end.
