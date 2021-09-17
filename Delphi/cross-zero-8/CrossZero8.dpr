program CrossZero8;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in 'MainForm.pas' {Form1},
  Common.Interfaces in 'Common.Interfaces.pas',
  Player.Random in 'Player.Random.pas',
  Stage in 'Stage.pas',
  Utils in 'Utils.pas',
  Player.Compositon in 'Player.Compositon.pas',
  Common.Constants in 'Common.Constants.pas',
  Net_06 in 'Net_06.pas',
  Player.Net_06 in 'Player.Net_06.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
