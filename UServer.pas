unit UServer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ScktComp, Buttons, INIFiles,
  DBTables, Usuario, Versao, Requisicao, Registry, ShellAPI, Menus, MShoutProtocol, UGlobal,
  IdBaseComponent, IdComponent, Commctrl, CoolTrayIcon, ImgList, Contnrs, SyncObjs,
  WinSkinData, DateUtils, HintBalloon;

const
  WM_TRAYICON=WM_USER+1;
  TTS_BALLOON = $40;
  TTM_SETTITLE = (WM_USER + 32);

type
  TTimeForUsr = class
  public
    Usuario:TUsuario;
    SecondsLeft:Word;
    constructor Create(Usr:TUsuario ; SecondsLeft:Word);
  End;

  TfrmServer = class(TForm, IArquitetura)
    PageControl1: TPageControl;
    tsConfig: TTabSheet;
    Bevel1: TBevel;
    Label1: TLabel;
    ListBox_User: TListBox;
    ServerSocket1: TServerSocket;
    btnStart: TSpeedButton;
    lblStatus: TLabel;
    Label2: TLabel;
    lblPort: TLabel;
    Label3: TLabel;
    PopupMenu: TPopupMenu;
    mnuConfiguraes: TMenuItem;
    mnuLigaDesliga: TMenuItem;
    N1: TMenuItem;
    mnuFechar: TMenuItem;
    Label4: TLabel;
    lblIPControl: TLabel;
    TrayIcon: TCoolTrayIcon;
    ImageList1: TImageList;
    SkinData1: TSkinData;
    memLog: TRichEdit;
    Timer1: TTimer;
    Timer2: TTimer;
    Button2: TButton;
    btn1: TButton;
    btn2: TButton;
    tsVersoes: TTabSheet;
    bvl1: TBevel;
    lbl1: TLabel;
    ListBox_Versao: TListBox;
    tsDadosOcu: TTabSheet;
    pnlDadosOcupante: TPanel;
    lblDadosOcupante: TLabel;
    Image1: TImage;
    Shape1: TShape;
    Label5: TLabel;
    lblLivre: TLabel;
    lblUsuario: TLabel;
    Label10: TLabel;
    lblIP: TLabel;
    Label12: TLabel;
    lblTempo: TLabel;
    bullet_red: TImage;
    bullet_green: TImage;
    btnKick: TBitBtn;
    tsFila: TTabSheet;
    TimerTimedUsr: TTimer;
    Button1: TButton;
    Button3: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ServerSocket1Listen(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1ClientDisconnect(Sender: TObject;  Socket: TCustomWinSocket);
    procedure FormDestroy(Sender: TObject);
    procedure mnuFecharClick(Sender: TObject);
    procedure mnuLigaDesligaClick(Sender: TObject);
    procedure mnuConfiguraesClick(Sender: TObject);
    procedure ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure TrayIconDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ServerSocket1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ListBox_UserDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure lblDadosOcupanteClick(Sender: TObject);
    procedure btnKickClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure TimerTimedUsrTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    //QtdePingFail:Integer;
    Procedure ReadINIFile();
    Procedure ReadPrioridadeFile();
    Procedure PreencheListBox_User();
    Procedure PreencheListBox_Versao();

    {TrayIcon}
    procedure WMSysCommand(var Msg: TWMSysCommand); Message WM_SysCommand;
    procedure WMNotification(var Msg: TWMSysCommand); Message WM_Notification;
  public
    { Public declarations }
    function  LigaDesligaServico( Ligar : Boolean ):Boolean;
    procedure AddLog(Msg:String);
    function  IsTokenDisponivel():TUsuario;
    function  OcuparToken(Usuario:TUsuario ; sVersoes:String = ''):Boolean;
    function  DesocuparToken():Boolean;
    procedure AtualizaDadosOcupador;
  end;

  {ENUM utilizado para simular chamadas internas}
  NCall = (cDisconect, cSaiFila);

  {Classe utilizada para chamadas internas ao Socket de entrada}
  TInternalCall = class
  private
    FCall:NCall;
    ExtraValue:String;
  public
    constructor Create; overload;
    constructor Create(Call:NCall); overload;
    procedure SetCall(Call:NCall);
    function  AsString:String;

    property Value:NCall read FCall write SetCall;
  end;

var
  frmServer: TfrmServer;
  sArrayUsers         : Array of Array of String;
  ListaUsers          : TListUsuario;
  ListaVersoes        : TListVersao;
  ListaVersoes_A_Gerar: TListVersao;
  SecaoCritica, SecaoCritica2, SecaoCriticaFila, SecaoCriticaSessionInfo:TCriticalSection;
  ListRequisicoes:TListRequisicoes;
  Fila:TFila;
  LostTime:TLostTime;
  ListPrioridade:TValuesList;
  Usr_TOKEN:TUsuario;
  Session_PCName:String;
  Vsr_TOKEN:TVersao;
  Alterando_Token:Boolean;
  ObjLog:^TRichEdit;
  SSKT:TCustomWinSocket;
  sVersoesGerando, StrEncodedVersoes: string;
  TFUsr:TTimeForUsr;

  //INI Vars
  INI_Port, INI_Title, INI_IPControl           : String;
  INI_Minimized, INI_StartActive, INI_AUTOINI  : Boolean;
  INI_Versoes, INI_Separador, INI_SubSeparador, INI_DirGeradores : String;

  blbl:Boolean;
implementation


{$R *.dfm}

{ TInternalCall }

constructor TInternalCall.Create;
begin
   inherited;
end;

constructor TInternalCall.Create(Call: NCall);
begin
   inherited Create;
   Self.Value := Call;
end;

procedure TInternalCall.SetCall(Call: NCall);
begin
    Self.FCall := Call;
end;

function TInternalCall.AsString: String;
begin
    Result := '';
    if Self.FCall = cDisconect Then
       Result := cnst_Disconect
    else
    if Self.FCall = cSaiFila Then
       Result := cnst_SairFila 
    else
       raise EConvertError.Create('Erro ao converter Call para String. (AsString)');
end;

{ TFrmServer }

function TfrmServer.IsTokenDisponivel():TUsuario;
Begin
    SecaoCritica.Acquire;
    Try
       If Assigned(Usr_TOKEN) Then
       Begin
          Result := Usr_TOKEN;
       End Else
          Result := nil;
    finally
       SecaoCritica.Release;
    End;
end;

procedure TfrmServer.AddLog(Msg: String);
Var
  sStart, sFinish: word;
begin
    sStart := ObjLog.SelStart;
    ObjLog.Lines.Add( FormatDateTime('hh:nn:ss',Now()) + ' - ' + Msg);

    sFinish := ObjLog.SelStart;
    ObjLog.SelStart  := sStart;
    ObjLog.SelLength := 8;
    ObjLog.SelAttributes.Color := clGray;        // set color
    ObjLog.SelAttributes.Style := [fsBold]; // set attributes
    Application.Processmessages;
    ObjLog.SelStart  := sFinish;
    ObjLog.SelLength := 0;
end;

procedure TfrmServer.btnStartClick(Sender: TObject);
begin
    // Se ligado Desligado, Senão Liga
    Try
      LigaDesligaServico( not ServerSocket1.Active );
    Except
      On E : Exception Do
      Begin
        AddLog( 'Não foi possível iniciar serviço. Erro: '+ E.Message );
      end;
    end;
end;

procedure TfrmServer.FormCreate(Sender: TObject);
Var
  Reg: TRegistry;
begin
    // Arq. Existe validado no MShout.dpr
    ReadINIFile;

    If INI_AUTOINI Then
    Begin
      // Inicializa a variavel do tipo TRegistry
      Reg:= TRegistry.Create;

      try
         // Define a hirearquia das pasta, a qual irá trabalhar.
         Reg.RootKey:= HKEY_LOCAL_MACHINE;

         // Cria/entra, dentro da pasta do registro no qual irá aguardar informação
         Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', False);

         Reg.WriteString('MShout', Application.ExeName);

         // Fecha a chave do registro
         Reg.CloseKey;
      Finally
         Reg.Free;
      end;
    End;

    Try
       StrToInt(INI_Port);
    Except
       MessageDlg('Parâmetro "Porta" inválido.',mtError,[mbOK],0);
       Application.Terminate;
    End;

    If (INI_Port = '') Or (StrToInt(INI_Port) = 0) Then
    Begin
        MessageDlg('Parâmetro "Porta" não está informado no arquivo de configuração.',mtError,[mbOK],0);
        Application.Terminate;
    End;

    // Ativa Skin
    SkinData1.Active := True;

    Self.Caption            := INI_Title;
    ServerSocket1.Port      := StrToInt(INI_Port);
    lblPort.Caption         := INI_Port;
    lblIPControl.Caption    := INI_IPControl;
    ObjLog                  := @memLog; // ObjLog Recebe posição da memória de memLog
    PageControl1.ActivePage := tsConfig;

    TrayIcon.Hint := cnst_NomeServer + ' (port: '+ INI_Port + ')';

    memLOG.Clear;
    ObjLog        := @memLog;

    SecaoCritica     := TCriticalSection.Create;
    SecaoCritica2    := TCriticalSection.Create;
    SecaoCriticaFila := TCriticalSection.Create;
    SecaoCriticaSessionInfo := TCriticalSection.Create;

    SetLength(sArrayUsers, 0);
    ListaUsers      := TListUsuario.Create;

    ListRequisicoes := TListRequisicoes.Create;

    AtualizaDadosOcupador;

    ListaVersoes         := TListVersao.Create;
    ListaVersoes_A_Gerar := TListVersao.Create;

//    StrEncodedVersoes := TListVersao.EncodeVersoesToStr(INI_Versoes, sPath + 'Versoes.rdo', INI_Separador, INI_SubSeparador);
//    TListVersao.DecodeVersoesToList(StrEncodedVersoes, INI_Separador , INI_SubSeparador , ListaVersoes );

    ListaVersoes.LoadFromDirectory( INI_DirGeradores , 'bat');

    PreencheListBox_Versao;

    Fila  := TFila.Create(Pointer(frmServer), INI_Separador , INI_SubSeparador );

    If INI_StartActive Then
       LigaDesligaServico(True);

    ReadPrioridadeFile;
end;

procedure TfrmServer.ReadINIFile;
Var
  INIFile:TIniFile;
Begin
    // Coleta o Caminho+Nome do executavel e muda extensao de .exe para .ini
    INIFile       := TIniFile.Create(sPath + 'MShout.ini');

    // Extrai informações do arquivo de inicialização e atribui às variaveis globais
    {Geral}
    INI_Port      := INIFile.ReadString('GERAL','PORT','');
    INI_Title     := INIFile.ReadString('GERAL','Title','MShout');
    INI_IPControl := INIFile.ReadString('GERAL','IPControl','');

    INI_Minimized   := IIF( INIFile.ReadString('GERAL','Start_Minimized','F') = _True, True, False);
    INI_StartActive := IIF( INIFile.ReadString('GERAL','Start_Active','F')    = _True, True, False);
    INI_AUTOINI     := IIF( INIFile.ReadString('GERAL','AutoINI','F')         = _True, True, False);

    {Base}
    INI_Separador    := INIFile.ReadString('BASE','Sep',';');
    INI_SubSeparador := INIFile.ReadString('BASE','SubSep','#');
    INI_Versoes      := INIFile.ReadString('BASE','Versoes','');
    INI_DirGeradores := INIFile.ReadString('BASE','DirGeradores', sPath);

    INIFile.WriteInteger('INSTANCE','HANDLE', Self.Handle );

    INIFile.Free;
end;

procedure TfrmServer.ServerSocket1Listen(Sender: TObject; Socket: TCustomWinSocket);
begin
    AddLog('Servidor Ligado!');
end;

procedure TfrmServer.PreencheListBox_User;
Var
  I:Integer;
begin
    Try
      ListBox_User.Clear;

      For I := 0 to ListaUsers.Count-1 Do
      Begin
          ListBox_User.Items.Add(ListaUsers.Items[I].Nome + ' ( ' + ListaUsers.Items[I].IP + ' ) ');
      End;
    except
      On E : Exception Do
      Begin
          AddLog(E.Message);
      End;
    End;
end;

procedure TfrmServer.ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
Var I:Integer;
    Nome, IP:String;
    Call:TInternalCall;
begin
    Try
      IP := Socket.RemoteAddress;

      if Fila.IPExists(Socket.RemoteAddress, I) Then
      Begin
         Call := TInternalCall.Create(cSaiFila);
         ServerSocket1ClientRead(Call, Socket);
         Call.Free;
      end;

      // Caso o usuário que está desconectando esteja com o TOKEN, deve-se chamar ClientRead
      // passando como Sender um objeto InternalCall que contêm como valor a operação a ser executada
      if Assigned(Usr_TOKEN) and (Usr_TOKEN.IP = Socket.RemoteAddress) Then
      Begin
         Call := TInternalCall.Create(cDisconect);
         ServerSocket1ClientRead(Call, Socket);
         Call.Free;
      end;

      // Deleta usuário e resgata Nome.
      // Se conseguir deletar retorna True
      if Not ListaUsers.Delete( IP , Nome ) Then
      Begin
          // Ao executar o comando "Connections[I].Close" a procedure Disconnect será chamada novamente.
          // Essa linha garante que ele saia sem tentar reexecutar
          Exit;
      End;

      // Se ClassType = Exception, evento foi chamada a partir de um AsyncronousError
      // Ou seja, algum usuário desconectou inexperadamente. Necessário desconecta-lo manualmente
      If Sender.ClassType = Exception then
      Begin
          WITH ServerSocket1.Socket DO
          BEGIN
              FOR I := 0 TO ActiveConnections-1 DO
              BEGIN
                If Connections[I].RemoteAddress = IP then
                Begin
                  Connections[I].Close;
                end;
              END;
          END;
      End;

      AddLog(Nome + '( '+ IP +' ) Desconectou.');
      PreencheListBox_User;
    except
      On E : Exception Do
      Begin
          AddLog(E.Message);
      End;
    end;
end;

procedure TfrmServer.FormDestroy(Sender: TObject);
begin
    ListaUsers.Clear;
    ListaVersoes.Clear;
    ListaVersoes_A_Gerar.Clear;
    FreeAndNil( Fila );
    FreeAndNil( LostTime );
    FreeAndNil( SecaoCritica );
    FreeAndNil( SecaoCritica2);
    FreeAndNil( SecaoCriticaFila);
    FreeAndNil( SecaoCriticaSessionInfo );
    FreeAndNil( ListBox_User );
    FreeAndNil( ListBox_Versao );
    FreeAndNil( ListaUsers );
    FreeAndNil( ListaVersoes  );
    FreeAndNil( ListaVersoes_A_Gerar );
    FreeAndNil( ListPrioridade );
end;

procedure TfrmServer.WMSysCommand(var Msg: TWMSysCommand);
var sMsg:String;
begin
    {Capturando estas mensagens para esconder o ícone da aplicação da Barra de Tarefas
     do Windows e para criar / destruir o ícone que ficará ao lado do relógio.}
    Case (Msg.CmdType) of
      SC_MINIMIZE:
      Begin
          Application.Minimize;
          TrayIcon.HideMainForm;
          sMsg := 'Aplicação em execução.';
          TrayIcon.ShowBalloonHint(cnst_NomeServer, sMsg, bitInfo, 10);
      End;
      SC_MAXIMIZE:
      Begin
          TrayIcon.ShowMainForm;
      End
      Else
        Inherited
    End;
end;

procedure TfrmServer.mnuFecharClick(Sender: TObject);
begin
    Try
      LigaDesligaServico(False);
    Finally
      Close;
    End;
end;

function TfrmServer.LigaDesligaServico(Ligar: Boolean): Boolean;
var sMsg:String;
    bmp:TBitmap;
begin
    Result := False;
    bmp := TBitmap.Create;

    Try
      if Ligar Then
      Begin
          If IsWrongIP(INI_IPControl) then
          Begin
             sMsg := 'IP Controlado inválido! ( '+ INI_IPControl +' )';
             MessageDlg(sMsg,mtError,[mbOK],0);
             raise Exception.Create(sMsg);
          end;

          ServerSocket1.Active      := True;
          btnStart.Caption          := 'Parar Servidor';
          ImageList1.GetBitmap(1,bmp);
          lblStatus.Color           := clGreen;
          lblStatus.Caption         := 'Ligado';
          mnuLigaDesliga.Caption    := 'Desligar &Serviço';
          mnuLigaDesliga.ImageIndex := 1;
          Session_PCName            := GetSessionInfo;
      end Else
      Begin
          ListaUsers.Clear;
          Fila.Clear;
          if Usr_Token <> nil Then
             DesocuparToken;

          PreencheListBox_User;
          ServerSocket1.Active := False;

          AddLog('Servidor Desligado!');
          btnStart.Caption          := 'Iniciar Servidor';
          ImageList1.GetBitmap(2,bmp);
          lblStatus.Color           := $00404080;
          lblStatus.Caption         := 'Desligado';
          mnuLigaDesliga.Caption    := 'Iniciar &Serviço';
          mnuLigaDesliga.ImageIndex := 2;
          Session_PCName            := '';
      end;

      TFUsr    := nil;
      btnStart.Glyph := bmp;
      Result := True;
      bmp.Free;
    Except
      On E : Exception Do
      Begin
          bmp.Free;
          AddLog(E.Message);
      End;
    End;
end;

procedure TfrmServer.mnuLigaDesligaClick(Sender: TObject);
begin
    btnStartClick(Sender);
end;

procedure TfrmServer.mnuConfiguraesClick(Sender: TObject);
begin
    Self.Visible:= True;
    BringWindowToTop(Application.Handle);
end;

procedure TfrmServer.TrayIconDblClick(Sender: TObject);
begin
    mnuConfiguraesClick(Sender);
end;

procedure TfrmServer.FormClose(Sender: TObject; var Action: TCloseAction);
Var
  INIFile:TIniFile;
begin
    IniFile := TIniFile.Create(sPath + 'MShout.ini');
    INIFile.WriteInteger('INSTANCE','HANDLE', 0 );
    FreeAndNil(IniFile);

    If ( ServerSocket1.Active ) And (MessageDlg('Finalizar aplicação?', mtInformation,[mbYes,mbNo],0) = mrNo) Then
    begin
      Abort;
    end;
end;

procedure TfrmServer.ServerSocket1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;  var ErrorCode: Integer);
var
   ERR:Exception;
const
   Err_Asyncronous = 10053;
begin
    If ErrorCode = Err_Asyncronous Then
    Begin
        ERR := Exception.Create('');
        ServerSocket1ClientDisconnect(ERR, Socket);
        ERR.Free;
        Abort;
    end;
end;

procedure TfrmServer.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
   Usr, Usr2:TUsuario;
   StrRecebida, StrEnviar, S, S1, otp:String;
   IgnoreRaisedLog, lLivre, vOK:Boolean;
   iLoop, idx:Integer;
   Dias:Integer;

    // #OVERLOAD Verifica Se Token Ocupado
    Function CheckToken():Boolean; overload;
    begin
        StrEnviar   := '';
        Usr  := IsTokenDisponivel;
        If Usr = nil Then
        begin
            If Not Alterando_Token Then
            Begin
                Result := True;
                If not Assigned(TFUsr) Then
                   StrEnviar := cnst_CHECKTOKEN + _ + cnst_TokenLivre
                Else
                   StrEnviar := cnst_CHECKTOKEN + _ + cnst_TimeForUser + _ + TFUsr.Usuario.Nome + _ + TFUsr.Usuario.IP + _ + TFUsr.Usuario.Data;
            end Else
            Begin
                iLoop := 0;
                While True Do
                Begin
                   Sleep(1000);
                   Usr := IsTokenDisponivel;
                   if Usr <> nil Then
                   Begin
                      Result         := False;
                      sVersoesGerando := ListaVersoes_A_Gerar.ListToString( INI_Separador, INI_SubSeparador );

                      // A Partir do 3º param. Apenas Atributos de TUsuario. Para adicionar mais Params necessário alterar no Client
                      If not Assigned(TFUsr) Then
                         StrEnviar := cnst_CHECKTOKEN + _ + cnst_TokenOcupado + _ + sVersoesGerando + _ + Usr.Nome +  _ + Usr.IP + _ + Usr.Data
                      Else
                         StrEnviar := cnst_CHECKTOKEN + _ + cnst_TimeForUser + _ + TFUsr.Usuario.Nome + _ + TFUsr.Usuario.IP + _ + Usr.Data;

                      Break;
                   end;

                   Inc(iLoop);
                   If iLoop > 5 Then
                   Begin
                      Result   := False;
                      StrEnviar := cnst_CHECKTOKEN + _ + cnst_FAIL + _ + cnst_ErrorTimeOut;
                      Break;
                   end;
                end;
            end;
        end Else
        Begin
            Result          := False;
            sVersoesGerando := ListaVersoes_A_Gerar.ListToString( INI_Separador, INI_SubSeparador );

            StrEnviar         := cnst_CHECKTOKEN  + _ +  cnst_TokenOcupado + _ + sVersoesGerando + _ + Usr.Nome + _ + Usr.IP + _ + Usr.Data;
        end;
    end;

    // #OVERLOAD Verifica se Token ocupado e retorna o Usuário que está ocupando
    Function CheckToken(var UsrOcupando:TUsuario ; RaiseON:Boolean=True):Boolean; overload;
    begin
        StrEnviar   := '';
        UsrOcupando := nil;
        UsrOcupando := IsTokenDisponivel;
        If UsrOcupando = nil Then
        begin
            If Not Alterando_Token Then
            Begin
                Result := True;
                If RaiseON Then
                   raise TMSProtocolException.Create('<ASSERT> CheckToken for Disconect. Token vazio');
            end Else
            Begin
                iLoop := 0;
                While True Do
                Begin
                   Sleep(1000);
                   UsrOcupando := IsTokenDisponivel;
                   if UsrOcupando <> nil Then
                   Begin
                      Result   := False;
                      Break;
                   end;

                   Inc(iLoop);
                   If iLoop > 5 Then
                   Begin
                      Result    := False;
                      raise TMSProtocolException.Create(cnst_ErrorTimeOut);
                      Break;
                   end;
                end;
            end;
        end Else
        Begin
            Result := False;
        end;
    end;
begin
    IgnoreRaisedLog := False;
    Usr  := nil;
    Usr2 := nil;

    Try
      // Se Sender for da classe InternalCall recebe seu valor encapsulado
      // Senão recebe texto de entrada do Socket
      if Sender is TInternalCall then
      Begin
         StrRecebida := TInternalCall(Sender).AsString + TInternalCall(Sender).ExtraValue;
      end Else
         StrRecebida := Socket.ReceiveText;

      If LerParam(StrRecebida, 0) = cnst_LOGIN then
      Begin
          Usr := TServerProtocol.readLogin( StrRecebida, Socket );
          if Usr <> nil Then
          Begin
              Try
                If ListaUsers.ExisteIP(Usr.IP) then
                Begin
                    AddLog('Tentativa de conexão dupla ('+ Usr.IP +' )');
                    IgnoreRaisedLog := True;
                    raise TMSProtocolException.Create('Já existe uma conexão ativa para o IP atual ('+ Usr.IP +' )');
                end;

                ListaUsers.Add(Usr);

                AddLog(Usr.Nome + '( '+ Usr.IP +' ) Conectou.');
                PreencheListBox_User;
                StrEnviar := cnst_Login + _ + cnst_ConnectOK + _ + INI_IPControl + _ + ListaVersoes.ListToString(INI_Separador, INI_SubSeparador)  + _ + INI_Separador + _ + INI_SubSeparador;
                Socket.SendText(StrEnviar);
              except
                raise;
              end;
          end;
      end Else
      If LerParam(StrRecebida, 0) = cnst_CONNECT then
      Begin
          If CheckToken Then
          begin
            Try
              Alterando_Token := True;

              Usr := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);

              // ASSERT
              if Usr = nil Then
              Begin
                  raise TMSProtocolException.Create('<ASSERT> IP ('+ Socket.RemoteAddress +') solicitando Token mas não consta na lista');
              end;

              If OcuparToken(Usr , LerParam(StrRecebida, 1) ) then
              Begin
                 AddLog('Servidor foi ocupado por: '+ Usr.Nome + '( '+ Usr.IP +' )');

                 StrEnviar    := cnst_Connect + _ + cnst_ConnectOK;

                 SecaoCritica2.Acquire;
                 Try
                   Usr.QtdePingFail := 0;
                 Finally
                   SecaoCritica2.Release;
                 end;

                 // Adiciona na Lista de interessados na Fila para que possa acompanhar atualizações da mesma
                 Fila.AddInteressado(Usr.IP);

                 S1 := Fila.Check( Socket.RemoteAddress , TRequisicoes.GetRequisicaoInt(TFila, StrRecebida) );

                 If S1 <> '' Then
                    StrEnviar := StrEnviar + _ + '$FILA=' + S1
                 Else
                    StrEnviar := StrEnviar;

                 If Session_PCName <> '' Then
                    StrEnviar := StrEnviar + _ + '$PCCONNECTED=' + Session_PCName;

                 Socket.SendText(StrEnviar);
              end else
                 raise TMSProtocolException.Create('Erro ao tentar ocupar token.');
            Finally
              Alterando_Token := False;
            end;
          end Else
          begin
             Socket.SendText(StrEnviar);
          end;
      End Else
      If LerParam(StrRecebida, 0) = cnst_CHECKTOKEN then
      Begin
          CheckToken;
          S := LerParam(StrEnviar, 1);
          Usr2 := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);

          If S = cnst_TokenOcupado Then
          Begin
             AddLog('Token Check por: '+ Usr2.Nome + '( '+ Usr2.IP +' ) #Ocupado por: '+ Usr.Nome + '( '+ Usr.IP +' )');
          end Else
          If S = cnst_TokenLivre Then
          Begin
             AddLog('Token Check por: '+ Usr2.Nome + '( '+ Usr2.IP +' ) #Livre');
          end Else
          If S = cnst_Fail Then
          Begin
             AddLog('Token Check por: '+ Usr2.Nome + '( '+ Usr2.IP +' ) #Fail: '+ LerParam(StrRecebida, 2));
          end else
             AddLog('Unexpected Check # '+ StrRecebida);

          S1 := '';
          If (Fila.FilaString <> '') Then
             S1 := Fila.FilaString;

          If S1 <> '' Then
             StrEnviar := StrEnviar + _ + '$FILA=' + S1
          Else
             StrEnviar := StrEnviar;

          If Session_PCName <> '' Then
             StrEnviar := StrEnviar + _ + '$PCCONNECTED=' + Session_PCName;

          Socket.SendText(StrEnviar);
      end Else
      If LerParam(StrRecebida, 0) = cnst_FASTCHECK then
      Begin
          lLivre := CheckToken(Usr, False);

          if ParamExists(StrRecebida, 1) and (StrToBoolDef( LerParam(StrRecebida, 1) , False ) = True) then
          begin
              {True para verificar se o requisitante é o ocupante}
              if Assigned(Usr) And (Usr <> nil) And (Socket.RemoteAddress = Usr.IP) then
                 StrEnviar := cnst_FastCheck + _ + '1'
              Else
                 StrEnviar := cnst_FastCheck + _ + '0';
          end else
          Begin
              {False para verificar apenas se está livre ou ocupado}
              if lLivre Then
                 StrEnviar := cnst_FastCheck + _ + '1'
              else
                 StrEnviar := cnst_FastCheck + _ + '0';
          End;

          S1 := Fila.Check( Socket.RemoteAddress , TRequisicoes.GetRequisicaoInt(TFila, StrRecebida) );
          If S1 <> '' Then
             StrEnviar := StrEnviar + _ + '$FILA=' + S1;

          If (LerDynamicParam(StrRecebida, 'USR_TOKEN', otp, True, True) > -1) And
             (StrToBool(otp)) Then
          Begin
             If (USR_TOKEN <> nil) And (Assigned(USR_TOKEN)) Then
                StrEnviar := StrEnviar + _ + '$USR_TOKENNOME=' + USR_TOKEN.Nome + _ + '$USR_TOKENIP=' + USR_TOKEN.IP;
          End;

          If (Session_PCName <> '') And
             ((LerDynamicParam(StrRecebida, 'PCCONNECTED', otp, True, True) > -1) And (StrToBool(otp)))
          Then
             StrEnviar := StrEnviar + _ + '$PCCONNECTED=' + Session_PCName;

          Socket.SendText(StrEnviar);
      end Else
      If LerParam(StrRecebida, 0) = cnst_DISCONECT then
      Begin
          If not CheckToken(Usr) Then
          begin
            Try
              If StrEnviar <> '' Then
                 Socket.SendText(StrEnviar);

              If not (Sender is TInternalCall) Then
                 Usr2 := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);

              // ASSERT
              if (Usr2 <> nil) And not TUsuario.CompareObjects(Usr, Usr2, False) Then
              Begin
                  raise TMSProtocolException.Create('<ASSERT> Token ocupado por usuário diferente do atual.');
              end;

              Alterando_Token := True;

              If DesocuparToken() then
              Begin
                 if (Socket <> nil) And (not (Sender is TInternalCall)) then
                 Begin
                     StrEnviar := cnst_Disconect + _ + cnst_DisconectOK;
                     Socket.SendText(StrEnviar);
                 end;
              end else
                 raise TMSProtocolException.Create('Erro ao tentar desocupar token.');
            Finally
              Alterando_Token := False;
            end;
          end Else
          begin
             If StrRecebida<>'' Then
                Socket.SendText(StrEnviar);
          end;
      End Else
      If LerParam(StrRecebida, 0) = cnst_PING then
      Begin
          Usr2 := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);
          If (not Assigned(Usr2)) or (Usr2 = nil) Then
              raise Exception.Create('Ping falhou. Não foi encontrado usuário para o IP: '+ Socket.RemoteAddress);

          SecaoCritica2.Acquire;
          Try
             Usr2.QtdePingFail := 0;
          finally
             SecaoCritica2.Release;
          End;

          StrEnviar := cnst_Pong;

          S1 := Fila.Check( Socket.RemoteAddress , TRequisicoes.GetRequisicaoInt(TFila, StrRecebida) );
          If S1 <> '' Then
             StrEnviar := StrEnviar + _ + '$FILA=' + S1;

          If (LerDynamicParam(StrRecebida, 'USR_TOKEN', otp, True, True) > -1) And
             (StrToBool(otp)) Then
          Begin
             If (USR_TOKEN <> nil) And (Assigned(USR_TOKEN)) Then
                StrEnviar := StrEnviar + _ + '$USR_TOKENNOME=' + USR_TOKEN.Nome + _ + '$USR_TOKENIP=' + USR_TOKEN.IP;
          End;

          If Assigned(LostTime) Then
             S1 := LostTime.Check(Socket.RemoteAddress);
          If S1 <> '' Then
          Begin
             StrEnviar := StrEnviar + _ + '$LOSTTIME=' + S1;
             FreeAndNil(LostTime);
          End;

          If (Session_PCName <> '') And
             ((LerDynamicParam(StrRecebida, 'PCCONNECTED', otp, True, True) > -1) And (StrToBool(otp)))
          Then
             StrEnviar := StrEnviar + _ + '$PCCONNECTED=' + Session_PCName;

          If Assigned(TFUsr) And ( Socket.RemoteAddress = TFUsr.Usuario.IP ) Then
             StrEnviar := StrEnviar + _ + '$SECONDSLEFT=' + IntToStr(TFUsr.SecondsLeft);

          Socket.SendText(StrEnviar);

          If ParamExists(StrRecebida, 1) And
             Not (StrToBoolDef( LerParam(StrRecebida, 1) , False )) Then // <- Se True = Silent (Nao imprime Log)
          begin
             AddLog('Ping por: '+ Usr2.Nome + '( '+ Usr2.IP +' )');
          end;
      End Else
      If LerParam(StrRecebida, 0) = cnst_EntrarFila then
      Begin
          Usr := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);
          If (not Assigned(Usr)) or (Usr = nil) Then
              raise Exception.Create('Erro inexperado. Não foi encontrado usuário para o IP: '+ Socket.RemoteAddress);

          vOK := False;

          If (Fila.FilaString = '') Then
          Begin
              vOK := True;
              If ListPrioridade.FieldExists( Usr.ComputerName ) Then
                 Fila.Add(Usr, StrToInt(ListPrioridade.Value[ Usr.ComputerName ]))
              Else
                 Fila.Add(Usr, 1);
          end else
          Begin
              If Not Fila.IPExists(Socket.RemoteAddress, idx) Then
              Begin
                  vOk := True;
                  If ListPrioridade.FieldExists( Usr.ComputerName ) Then
                     Fila.Add(Usr, StrToInt(ListPrioridade.Value[ Usr.ComputerName ]))
                  Else
                     Fila.Add(Usr, 1);
              end;
          end;

          // Adiciona na Lista de interessados na Fila para que possa acompanhar atualizações da mesma
          If LerParam(StrRecebida, 1) = '1' Then
             Fila.AddInteressado(Usr.IP);

          if vOK Then
              StrEnviar := cnst_OK
          else
              StrEnviar := cnst_Nothing;

          S1 := Fila.Check( Socket.RemoteAddress , TRequisicoes.GetRequisicaoInt(TFila, StrRecebida) );
          If S1 <> '' Then
             StrEnviar := StrEnviar  + _ + '$FILA=' + S1;

          If sVersoesGerando <> '' Then
             StrEnviar := StrEnviar + _ + '$VERSOES=' + sVersoesGerando;

          If (USR_TOKEN <> nil) And (Assigned(USR_TOKEN)) Then
             StrEnviar := StrEnviar + _ + '$USR_TOKENNOME=' + USR_TOKEN.Nome + _ + '$USR_TOKENIP=' + USR_TOKEN.IP;

          Socket.SendText(StrEnviar);
      End else
      If LerParam(StrRecebida, 0) = cnst_SairFila then
      Begin
          If (Sender is TInternalCall) And (LerDynamicParam(StrRecebida, 'INTERNALCALL', OTP, True, True) > -1) And (StrToBool(otp)) Then
          Begin
              Usr := TFUsr.Usuario;
          End Else
          Begin
              Usr := ListaUsers.GetUsuarioPorIP(Socket.RemoteAddress);
              If (not Assigned(Usr)) or (Usr = nil) Then
                  raise Exception.Create('Erro inexperado. Não foi encontrado usuário para o IP: '+ Socket.RemoteAddress);
          End;

          vOk := False;

          If (Fila.FilaString <> '') Then
          Begin
              If Fila.IPExists(Usr.IP, idx) Then
              Begin
                  Fila.Delete(Usr.IP);
                  Fila.DeleteInteressado(Usr.IP);

                  vOk := True;
              end;
          end;

          If Assigned(TFUsr) And (Usr.IP = TFUsr.Usuario.IP) Then
             FreeAndNil(TFUsr);

          If vOK Then
             StrEnviar := cnst_OK
          Else
             StrEnviar := cnst_Nothing;

          If not (Sender is TInternalCall) Then
             Socket.SendText(StrEnviar);
      End Else
      Begin
          raise TMSProtocolException.Create('Comando desconhecido: '+ StrRecebida);
      end;
    except
      On E : TMSProtocolException Do
      Begin
         If not IgnoreRaisedLog Then
            AddLog( 'ReadProtocolError: ' + E.Message );
         Socket.SendText( cnst_ErrorProtocol + _ + E.Message );
      end;

      On E : Exception Do
      Begin
         If not IgnoreRaisedLog Then
            AddLog( 'ReadError: ' + E.Message );
         Socket.SendText( cnst_Error + _ + E.Message );
      end;
    End;
end;

function TfrmServer.DesocuparToken():Boolean;
Var
  sIP:String;
begin
    SecaoCritica.Acquire;
    Try
      Try
        sIP := Usr_TOKEN.IP;
        AddLog('Servidor foi desocupado por: '+ Usr_TOKEN.Nome + '( '+ sIP +' )');

        If Assigned(Usr_TOKEN) then
           Usr_TOKEN.Free;

        Usr_TOKEN := nil;
        ListaVersoes_A_Gerar.Clear;

        Fila.DeleteInteressado(sIP);

        If Assigned(TFUsr) Then
            FreeAndNil(TFUsr);

        If Assigned(Fila) And (Fila.Count > 0) Then
        Begin
           TFUsr := TTimeForUsr.Create( TFilaItem(Fila.GetItemByIndex(0)).Usuario , cnst_SecondsForUsr);
           TimerTimedUsr.Enabled := True;
        End;

        AtualizaDadosOcupador;
        Result := True;
      Except
        Result := False;
      End;
    finally
       SecaoCritica.Release;
    End;
end;

function TfrmServer.OcuparToken(Usuario: TUsuario ; sVersoes:String = ''): Boolean;
Var
  Usr: TUsuario;
  I:Integer;
  Call:TInternalCall;
begin
    SecaoCritica.Acquire;
    Try
      // Clona o objeto Usuario e atribui no novo a Data de ocupação do Token
      Usr := nil;
      TUsuario.Clone(Usuario,Usr);
      Usr.Data := FormatDateTime('ddmmyyyyhhnnss', Now());

      // Atribui versões informadas pelo usuário
      ListaVersoes_A_Gerar.Clear;
      TListVersao.DecodeVersoesToList(sVersoes, INI_Separador , INI_SubSeparador , ListaVersoes_A_Gerar );

      Try
        if Usr_TOKEN = nil Then
           Usr_TOKEN := Usr
        else
           raise TMSProtocolException.Create('<ASSERT> (OcuparToken) Token not nil.');

        If Assigned(TFUsr) And (USR_Token.IP = TFUsr.Usuario.IP) Then
        Begin
           if Fila.IPExists(TFUsr.Usuario.IP, I) Then
           Begin
              Call := TInternalCall.Create(cSaiFila);
              Call.ExtraValue := _ + 'INTERNALCALL=TRUE';
              ServerSocket1ClientRead(Call, nil);
              Call.Free;
           end;

           FreeAndNil(TFUsr);
        End;

        AtualizaDadosOcupador;
        Result := True;
      Except
         Result := False;
      End;
    finally
       SecaoCritica.Release;
    End;
end;

procedure TfrmServer.ListBox_UserDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
    with (Control as TListBox).Canvas do
    begin
        if odFocused In State Then
        Begin
            Brush.Color := $00FBEFD0;
            Font.Color := clBlack;
        end else
        if not Odd(Index) then
        begin
            //cor de fundo da linha
            Brush.Color := $00F7F7F7;
            //cor da fonte do texto
            Font.Color := clBlack;
        end
        else
        begin
            Brush.Color := clWhite;
            Font.Color := clBlack;
        end;

        Brush.Style := bsSolid;
        FillRect(Rect);
        Brush.Style := bsClear;
        TextOut(Rect.Left, Rect.Top,(Control as TListBox).Items[Index]);
    end;
end;

procedure TfrmServer.Timer1Timer(Sender: TObject);
begin
    Timer1.Enabled := False;
    If Usr_TOKEN <> nil Then
    Begin
        SecaoCritica2.Acquire;
        Try
           ListaUsers.IncPing;

           If Usr_TOKEN.QtdePingFail = cnst_MaxQtdePing Then
           Begin
               DesocuparToken();
               AddLog('Desconectado por falta de resposta.');
               Usr_TOKEN.QtdePingFail := 0;
           End;
        finally
           SecaoCritica2.Release;
        End;
    End;
    Timer1.Enabled := True;
end;

procedure TfrmServer.AtualizaDadosOcupador;
var ini_Hora, fin_Hora, Result_Hora :TDateTime;
    dias:Integer;
    dd, hh, mm, ss:string;
begin
    If Usr_TOKEN <> nil Then
    Begin
        bullet_red.Visible   := False;
        bullet_Green.Visible := True;

        btnKick.Visible    := True;
        lblUsuario.Caption := Usr_TOKEN.Nome;
        lblIP.Caption      := Usr_TOKEN.IP;
        lblLivre.Caption   := 'Ocupado';

        ini_Hora  := StrToDateTimeF(Usr_TOKEN.Data);
        fin_Hora  := Now();

        Result_Hora := (StrToTime('23:59:59') + StrToTime('00:00:01') - ini_Hora) + fin_Hora;
        dias := DaysBetween(0, Result_Hora);

        // dias
        dd := IntToStr(dias);
        // Horas
        hh := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Result_Hora), 12, 2);
        // Minutos
        mm := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Result_Hora), 15, 2);
        // Segundos
        ss := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Result_Hora), 18, 2);

        lblTempo.Caption := '';
        If dias > 0 Then
           lblTempo.Caption := 'Dia(s): ' + IntToStr(dias);
        lblTempo.Caption := lblTempo.Caption + FormatDateTime('hh:nn:ss', Result_Hora);
    End Else
    Begin
        bullet_red.Visible   := True;
        bullet_Green.Visible := False;

        btnKick.Visible    := False;
        lblUsuario.Caption := '';
        lblIP.Caption      := '';
        lblTempo.Caption   := '';
        lblLivre.Caption   := 'Livre';
    End;
end;

procedure TfrmServer.Timer2Timer(Sender: TObject);
begin
    Try
      Timer2.Enabled := False;
      AtualizaDadosOcupador;

      SecaoCriticaSessionInfo.Acquire;
      Try
        Try
          If Not blbl Then
             Session_PCName := GetSessionInfo
          Else
             Session_PCName := 'teste';
        Except
          On E : Exception DO
          Begin
             AddLog('Erro em SessionName: ' + E.Message);
          End;
        End
      Finally
        SecaoCriticaSessionInfo.Release;
      end;
    Finally
      Timer2.Enabled := True;
    End;
end;

procedure TfrmServer.lblDadosOcupanteClick(Sender: TObject);
begin
    If pnlDadosOcupante.Height = lblDadosOcupante.Height then
       pnlDadosOcupante.Height := 135
    Else
       pnlDadosOcupante.Height := lblDadosOcupante.Height;
end;

procedure TfrmServer.PreencheListBox_Versao;
Var
  I:Integer;
begin
    Try
      ListBox_Versao.Clear;

      For I := 0 to ListaVersoes.Count-1 Do
      Begin
          ListBox_Versao.Items.Add(ListaVersoes.Items[I].ID);
      End;
    except
      On E : Exception Do
      Begin
          AddLog(E.Message);
      End;
    End;
end;

procedure TfrmServer.btnKickClick(Sender: TObject);
var
  Call:TInternalCall;
begin
    if Assigned(Usr_TOKEN) Then
    Begin
       Call := TInternalCall.Create(cDisconect);
       ServerSocket1ClientRead(Call, Usr_TOKEN.Socket );
       Call.Free;
    end;
end;

procedure TfrmServer.Button2Click(Sender: TObject);
Var
  fi:TFilaItem;
  s:string;
  us:TUsuario;
  Fila2:TFila;
begin
          If not Assigned(Fila) or (Fila = nil) Then
          Begin
              Fila := TFila.Create(Pointer(frmServer), INI_Separador , INI_SubSeparador );
          end;

    us    := TUsuario.Create;
    us.IP := '192.168.1.1';
    us.Nome := 'Jefferson';
    us.Data := FormatDateTime('ddmmyyyyhhnnss', Now());

    Fila.Add(us, 1);

    us    := TUsuario.Create;
    us.IP := '192.168.1.2';
    us.Nome := 'Guilherme';
    us.Data := FormatDateTime('ddmmyyyyhhnnss', Now());

    Fila.Add(us, 1);

    us    := TUsuario.Create;
    us.IP := '192.168.1.3';
    us.Nome := 'Cris';
    us.Data := FormatDateTime('ddmmyyyyhhnnss', Now());

    Fila.Add(us, 2);

    Fila.AddInteressado('127.0.0.1');

    s := Fila.FilaToStr( INI_Separador, INI_SubSeparador );

//    TFila.SplitFila(s, frmServer, INI_Separador, INI_SubSeparador, Fila2);
//    Sleep(1);
end;

procedure TfrmServer.btn1Click(Sender: TObject);
begin
    Fila.FiFo;
end;

procedure TfrmServer.btn2Click(Sender: TObject);
begin
   GetSessionInfo;
end;

procedure TfrmServer.ReadPrioridadeFile;
Var
  tmpArq:TStringList;
  i:integer;
  NomePC, Prioridade, Erro:String;

  function ValidaRow(const R:String ; var Tag , Value , Error:String ):Boolean;
  Var
     ChTag, ChValue:String;
     I, Len:Integer;
     Found:Boolean;
  Begin
      ChTag   := '';
      ChValue := '';
      Len     := Length(R);
      Found   := False;
      Try
        for I := 1 To Len Do
        Begin
            If (R[i] = '=') And (Not Found) Then
            Begin
               Found := True;
            end Else
            Begin
               If Not Found Then
                 ChTag := ChTag + R[i]
               Else
                 ChValue := ChValue + R[i];
            End;
        end;

        If (Not Found) Or (Trim(ChTag) = '') Or (Trim(ChValue) = '') Then
        Begin
           Erro   := '''prioridade.rdo Error:'' Linha('+ R +') ; inválida.';
           Result := False;
        End Else
        Begin
           If Not IsSomenteNumeros(chValue) Then
           Begin
              Erro   := 'prioridade.rdo Error: Linha('+ R +') ; Valor não numérico.';
              Result := False;
           end Else
           Begin
              Result := True;
              Tag    := chTag;
              Value  := chValue;
           End;
        end;
      Except
         On E : Exception Do
         Begin
           Erro   := 'prioridade.rdo Error: ' + E.Message;
           Result := False;
         end;
      End;
  end;
begin
    tmpArq := TStringList.Create;
    tmpArq.LoadFromFile( sPath + 'prioridade.rdo');
    ListPrioridade := TValuesList.Create;

    for i:= 0 To tmpArq.Count-1 do
    Begin
        If ValidaRow(tmpArq[i], NomePC, Prioridade, Erro) Then
        Begin
            ListPrioridade.Value[NomePC] := Prioridade;
        end Else
        Begin
            AddLog(Erro);
        end;
    end;

    tmpArq.Free;
end;

procedure TfrmServer.WMNotification(var Msg: TWMSysCommand);
begin
    Case (Msg.CmdType) of
      SC_GERANDOVERSAO:
      Begin
          SHOWMESSAGE('A');
      End Else
        Inherited
    End;
end;

{ TTimeForUsr }

constructor TTimeForUsr.Create(Usr: TUsuario ; SecondsLeft:Word);
begin
    If not Assigned(Usr) Then
       raise Exception.Create('Usuário inválido em "TimeForUser".');
    Self.Usuario     := Usr;
    Self.SecondsLeft := SecondsLeft;
end;

procedure TfrmServer.TimerTimedUsrTimer(Sender: TObject);

    procedure UsrLostTime;
    Var
      Call:TInternalCall;
      I:Integer;
    Begin
      LostTime := TLostTime.Create(TFUsr.Usuario);

      if Fila.IPExists(TFUsr.Usuario.IP, I) Then
      Begin
         Call := TInternalCall.Create(cSaiFila);
         Call.ExtraValue := _ + 'INTERNALCALL=TRUE';
         ServerSocket1ClientRead(Call, nil);
         Call.Free;
      end;

      If Assigned(Fila) And (Fila.Count > 0) Then
         TFUsr := TTimeForUsr.Create( TFilaItem(Fila.GetItemByIndex(0)).Usuario , cnst_SecondsForUsr )
      Else
         FreeAndNil(TFUsr);
    end;
begin
    if not Assigned(TFUsr) or (TFUsr.SecondsLeft <= 0) Then
    Begin
       TimerTimedUsr.Enabled := False;
       Exit;
    End;

    If TFUsr.SecondsLeft > 0 Then
       Dec(TFUsr.SecondsLeft);

    If TFUsr.SecondsLeft <= 0 Then
       UsrLostTime;  
end;

procedure TfrmServer.Button1Click(Sender: TObject);
begin
    blbl := Not blbl;
end;

procedure TfrmServer.Button3Click(Sender: TObject);
Var
  HandleINI:TIniFile;
  iHandle:HWND;
begin
    HandleINI := TIniFile.Create('C:\Projetos\MShout_Client\Handle.ini');
    iHandle := HandleINI.ReadInteger('HANDLE','HANDLE', 0);
    Windows.SendMessage( iHandle , WM_LIBERARTOKEN, SC_CLOSE, WM_Silent);

    FreeAndNil(HandleINI);
end;

end.
