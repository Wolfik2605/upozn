program upozn;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  data,
  menu;

begin
  InitializeData;
  ShowWelcome;
  RunMainLoop;
  ClearData;
end.
