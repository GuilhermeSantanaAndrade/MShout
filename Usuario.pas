unit Usuario;

interface

uses Classes,Contnrs, SysUtils, UGlobal, ScktComp;

type

  TUsuario = class
  private
    fNome:String;
    fIP:String;
    fData:String;
    fQtdePingFail:Integer;
    fSocket: TCustomWinSocket;
    fComputerName:String;
  public
    procedure ParseAttributes(Atbr, Separator: string);
    class procedure Clone(var Usr, NewUsr:TUsuario);
    class function  CompareObjects(Usr1, Usr2:TUsuario ; CompareDate:Boolean = True):Boolean;
    property  Nome: String read fNome write fNome;
    property  IP  : String read fIP   write fIP;
    property  Data: String read fData write fData;
    property  QtdePingFail: Integer read fQtdePingFail write fQtdePingFail;
    property  Socket: TCustomWinSocket read fSocket write fSocket;
    property  ComputerName: String read fComputerName write fComputerName;
  End;

  TListUsuario = class(TList)
  private
//    FListaUsuario:TList;
  public
    constructor Create;
    destructor  Destroy;override;
    procedure   SetUsuario(const Index:Integer ; usr : TUsuario);
    function    GetUsuario(const Index:Integer):TUsuario;
    function    GetUsuarioPorIP(const IP:String):TUsuario;
    function    Add(Usr:TUsuario):Integer; overload;
    function    Add(pNome, pIP:String):Integer; overload;
    function    ExisteIP(sIP:String):Boolean;
    procedure   Clear();override;
    function    Delete(IP:String ; out Nome:String):Boolean; overload;
    procedure   Delete(Index:Integer); overload;
    property    Items[const Index: Integer]: TUsuario read GetUsuario write SetUsuario; default;
    procedure   IncPing(Usr:TUsuario=nil);
  end;

implementation

{ TListUsuario }

function TListUsuario.Add(Usr: TUsuario): Integer;
begin
    Result := inherited Add(Usr);
end;

function TListUsuario.Add(pNome, pIP: String): Integer;
Var
  Usr:TUsuario;
begin
    Usr       := TUsuario.Create;
    Usr.fNome := pNome;
    Usr.fIP   := pIP;

    Result := Add(Usr);
end;

procedure TListUsuario.Clear;
begin
    while Self.Count > 0 Do
       Self.Delete(0);

    inherited;
end;

constructor TListUsuario.Create;
begin
    inherited Create;
end;

function TListUsuario.Delete(IP: String ; out Nome:String): Boolean;
var
  I:Integer;
begin
    Result := False;
    If IsWrongIP(IP) then
       raise Exception.Create('IP inválido.');

    For I := 0 to Self.Count-1 do
    Begin
        If Trim(Self.Items[I].IP) = IP then
        Begin
            Nome := Self.Items[I].Nome;

            Self.Delete(I);
            Result := True;
            Break;
        End;
    End;
end;

procedure TListUsuario.Delete(Index: Integer);
var
  Temp:TUsuario;
begin
  Temp := Self.GetUsuario(Index);
  FreeAndNil(Temp);

  inherited;
end;

destructor TListUsuario.Destroy;
begin
    Self.Clear;
    inherited;
end;

function TListUsuario.ExisteIP(sIP:String): Boolean;
var
  I:Integer;
begin
    Result := False;
    For I := 0 To  Self.Count-1 do
    Begin
       if Items[I].IP = sIP Then
          Result := True;
    End;
end;

function TListUsuario.GetUsuario(const Index: Integer): TUsuario;
begin
    Result := inherited Get(Index);
end;

function TListUsuario.GetUsuarioPorIP(const IP: String): TUsuario;
Var
  I:Integer;
begin
    If (IP <> '') And IsWrongIP(IP) then
       raise Exception.Create('IP inválido. (class: Usuario ; value: '+ IP +')');

    Result := nil;

    For I := 0 to Self.Count-1 do
    Begin
        If Trim(Items[I].IP) = IP then
        Begin
            Result := GetUsuario(I);
        End;
    end;
end;

procedure TListUsuario.IncPing(Usr: TUsuario=nil);
var i:integer;
    Temp:TUsuario;
begin
    for i:=0 To Self.Count-1 do
    begin
       Temp := GetUsuario(I);

       if (Usr = nil) or ((Usr <> Nil) And (Temp.IP = Usr.IP)) then
          Temp.QtdePingFail := Temp.QtdePingFail + 1;
    end;
end;

procedure TListUsuario.SetUsuario(const Index: Integer; usr: TUsuario);
begin
    inherited Put(Index, Usr);
end;

{ TUsuario }

class procedure TUsuario.Clone(var Usr, NewUsr: TUsuario);
begin
    if not Assigned(Usr) Then
        raise Exception.Create('Erro ao tentar clonar objeto TUsuario. Parâmetro de entrada não inicializado.');

    if Assigned(NewUsr) Then
        NewUsr.Free;

    NewUsr               := TUsuario.Create;
    NewUsr.fNome         := Usr.fNome;
    NewUsr.fIP           := Usr.fIP;
    NewUsr.fData         := Usr.fData;
    NewUsr.fQtdePingFail := 0;
end;

class function  TUsuario.CompareObjects(Usr1, Usr2:TUsuario ; CompareDate:Boolean = True):Boolean;
begin
    Result := False;

    if not Assigned(Usr1) or not Assigned(Usr2) Then
        raise Exception.Create('Erro ao tentar comparar objetos TUsuario. Parâmetro de entrada não inicializado.');

    if (Usr1.fNome = Usr2.fNome) and
       (Usr1.fIP   = Usr2.fIP)   and
       (((CompareDate) and (Usr1.fData = Usr2.fData)) or (not CompareDate)) Then
    Begin
       Result := True;
    end;
end;

procedure TUsuario.ParseAttributes(Atbr, Separator: string);
Var
  I     :Integer;
  Value :Variant;
  _     :String;
const
  QtdParams = 3;
begin
    _    := Separator;
    I    := 0;
    Atbr := Atbr + _ ;

    While Pos( _ , Atbr ) > 0 do
    begin
        Value := Copy(Atbr, 1, Pos( _ , Atbr )-1);
        Atbr := Copy(Atbr, Pos( _ , Atbr )+1, Length(Atbr) );

        case I of
          0: Self.fNome := Value;
          1: Self.IP    := Value;
          2: Self.Data  := Value;
        End;

        Inc(I);
    end;
end;

end.
