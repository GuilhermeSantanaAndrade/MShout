program MShout;

uses
  Forms,
  SysUtils,
  Windows,
  Dialogs,
  UServer in 'UServer.pas' {frmServer},
  Usuario in 'Usuario.pas',
  MShoutProtocol in '..\Lib\MShoutProtocol\MShoutProtocol.pas',
  UGlobal in 'UGlobal.pas',
  Versao in 'Versao.pas',
  Requisicao in 'Requisicao.pas';

{$R *.res}

begin
    // Verifica se o Arquivo .ini est� na pasta do .exe
    If Not FileExists(ChangeFileExt(ParamStr(0),'.ini')) Then
    Begin
        MessageDlg('N�o foi poss�vel encontrar o arquivo de configura��o.'+#13+ChangeFileExt(ParamStr(0),'.ini'),mtError,[mbOK],0);
        Application.Terminate;
    End Else
    Begin
        Application.Initialize;
        Application.CreateForm(TfrmServer, frmServer);
        Application.Run;
    End;
end.
