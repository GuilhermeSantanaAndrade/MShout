unit UGlobal;

interface

uses Classes, Forms, Contnrs, SysUtils, Controls, DateUtils, Messages, JwaWinBase, JwaWtsApi32, Windows;

type
  ArrayOfInteger = Array of Integer;
  ArrayOfString  = Array of String;
  SetOfChar      = Set of Char;

  TVarType        = (frString, frInteger, frDouble, frBoolean);
  TShowMode       = (smNone, smFixed, smTemorary);
  TTypeForm       = (tfNone, tfConnected, tfCheck, tfWaiting, tfTimed);

  TEncapForms = record
      Mem:Pointer;
      ShwMode:TShowMode;
      Typ:TTypeForm;
  end;

const
  _True = 'T';
  _False = 'F';

  WM_LiberarToken  = WM_USER+1;
  WM_Silent        = WM_USER+2;
  WM_EntrarFila    = WM_USER+3;
  WM_SairFila      = WM_USER+4;
  WM_Internal      = WM_USER+9999;

  function IsWrongIP(ip: string): Boolean;
  function IsSomenteNumeros(str: string): Boolean;
  function LeadingZeroIPNumber (sIP : string) : string;
  function IIF(Expr:Boolean ; Code1, Code2:Variant):Variant;
  function StrToDateTimeF(Str:String):TDateTime;
  function BoolToStrF(Bool:Boolean ; Upper:Boolean=False):String;
  function RemoveZerosEsq(S:String ; NoRaise:Boolean=False):String;
  function FindWindowByTitle(WindowTitle: string ; pHandle:Hwnd): Hwnd;
  function QtdSeparatorsStr(TXT , Separator:String):Integer;
  function GetLocalComputerName:String;
  function GetDifTempoFmt(AData_Hora:TDateTime): String;
  function GetSessionInfo:String;
  function FileTimeToDTime(FTime: TFileTime): TDateTime;
  procedure FreeAndNil(var Obj);

  // Funções para tratamento dos Forms de Alerta
  function AlocarForm(Frm:Pointer ; Mode:TShowMode ; Typ:TTypeForm):Integer;
  function DesalocarForm(Frm:Pointer):Integer;
  function DesalocarByIndex(Idx:Integer):Boolean;
  function LocateFreePos:Integer;
  function LocateByMem(M:Pointer ; var Idx:Integer):Boolean;
  function Locate(Mode:TShowMode ; ATyp:TTypeForm ; var Idx:Integer):Pointer; overload;
  function Locate(Mode:TShowMode ; var Idx:Integer):Pointer; overload;
  function Locate(ATyp:TTypeForm ; var Idx:Integer):Pointer; overload;
  function Find(ATyp:TTypeForm ; var Idx:Integer):Boolean; overload;
  function Find(Mode:TShowMode ; var Idx:Integer):Boolean; overload;

var
  sPath:String;
  ArrayOfForms:Array of TEncapForms;

const
  cnst_MaxQtdForms = 99;

implementation

Function StrToDateTimeF(Str:String):TDateTime;
var S:String;
begin
    If (Length(Str) <> 14) Or ( not IsSomenteNumeros(STR) ) then
       raise EConvertError.Create(Str + 'is not a valid DATE and TIME');

    S := Copy(Str,1,2) + '/' + Copy(Str,3,2) + '/' + Copy(Str,5,4) + ' ' + Copy(Str,9,2) + ':' + Copy(Str,11,2) + ':' + Copy(Str,13,2);
    Result := StrToDateTime(S);
end;

function BoolToStrF(Bool:Boolean ; Upper:Boolean=False):String;
Begin
    If Bool Then
       Result := 'True'
    Else
       Result := 'False';

    If Upper Then
       Result := UpperCase(Result);
end;

Function IIF(Expr:Boolean ; Code1, Code2:Variant):Variant;
Begin
    If Expr Then
        Result := Code1
    Else
        Result := Code2;
End;

function IsWrongIP(IP: string): Boolean;
var
  i   : byte;
  st  : array[1..4] of Integer;
  sIP : String;
begin
    st[1] := 0;
    st[2] := 0;
    st[3] := 0;
    st[4] := 0;

    Result := False;
    sIP    := IP;
    i      := 0;

    // Conta qtos Pontos
    While Pos( '.' , sIP ) > 0 do
    Begin
        Inc(i);
        sIP := Copy(sIP, Pos( '.' , sIP )+1, Length(sIP) );
    End;
    If i <> 3 then
    begin
       IsWrongIP := True;
       Exit;
    end;

    sIP := StringReplace(IP,'.','',[rfReplaceAll]);

    if not IsSomenteNumeros(sIP) Then
    Begin
       IsWrongIP := True;
       Exit;
    end;

    sIP := LeadingZeroIPNumber(IP);

    if Length(sIP) <> 15 then
    Begin
       IsWrongIP := True;
       Exit
    end;

    st[1] := StrToInt(Copy(sIP,1, 3));
    st[2] := StrToInt(Copy(sIP,5, 3));
    st[3] := StrToInt(Copy(sIP,9, 3));
    st[4] := StrToInt(Copy(sIP,13,3));

    if (( st[1] < 1 ) And ( st[1] > 255 )) or
       (( st[2] > 255 )) or
       (( st[3] > 255 )) or
       (( st[4] < 1 ) And ( st[4] > 255 )) Then
    Begin
       IsWrongIP := True;
       Exit
    end;
end;

Function IsSomenteNumeros(str: string): Boolean;
var
  i : integer; // contador para for
begin
  result := (str <> '');

  For i := 1 to length(str) do
    if not (str[i] in ['0'..'9']) then
       result := False;
end;

function LeadingZeroIPNumber (sIP : string) : string;
var
    i : integer;
    cnt : integer;
begin
    Result := '';
    cnt := 1;
    for i := length(sIP) downto 1 do
    begin
      if sIP[i] = '.' then
      begin
        Result := copy('000', cnt, 3) + Result;
        cnt := 0;
      end;
      Result := sIP[i] + Result;
      cnt := cnt + 1;
    end;
    Result := copy('000', cnt, 3) + Result;
end;

{Retorna a diferença entre duas horas}
function DifHora(Inicio,Fim : String):String;
var
  FIni,FFim : TDateTime;
begin
   Fini := StrTotime(Inicio);
   FFim := StrToTime(Fim);

   If (Inicio > Fim) then
   begin
      Result := TimeToStr((StrTotime('23:59:59')-Fini)+FFim)
   end else
   begin
      Result := TimeToStr(FFim-Fini);
   end;
end;

function RemoveZerosEsq(S:String ; NoRaise:Boolean=False ):String;
Begin
    Try
      Result := IntToStr( StrToInt(S) );
    Except
      On E : Exception Do
      Begin
        Result := '';
        If Not NoRaise Then
           raise;
      end;
    End;
end;

function FindWindowByTitle(WindowTitle: string ; pHandle:Hwnd): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..255] of char;
begin
  // vamos obter a primeira janela
  NextHandle := GetWindow( pHandle, GW_HWNDFIRST);

  while NextHandle > 0 do
    begin
      // vamos obter o título da janela
      GetWindowText(NextHandle, NextTitle, 256);

      // a janela contém o título que procuramos?
      if Pos(Uppercase(WindowTitle), UpperCase(String(NextTitle))) <> 0 then
         begin
           Result := NextHandle;
           Exit;
         end
      else
        // vamos tentar a próxima janela
        NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
    end;

    // não encontramos nada? vamos retornar um handle nulo
    Result := 0;
end; 

function QtdSeparatorsStr(TXT , Separator:String):Integer;
var
  _ : String;
begin
    Result := 0;
    _      := Separator;

    If Separator = '' then
       Exit;

    while Pos( _ , TXT ) > 0 do
    Begin
        Inc(Result);
        TXT := Copy(TXT, Pos( _ , TXT )+1, Length(TXT) );
    end;
end;

function GetSessionInfo:String;
var lSessionId      : DWORD;
    lBuffer         : Pointer;
    lBytesReturned  : DWORD;
    lStationName    : String;
begin
    lSessionId := 0;

    { Descobre a identificação da sessão do usuário com base na identificação do programa no Windows }
    if not ProcessIdToSessionId (GetCurrentProcessId (), {DWORD(@}lSessionId{)}) then
       raise Exception.Create ('Não foi possível obter Remote SessoinId');

    lBuffer := Nil;
    lBytesReturned := 0;
    lStationName := '';

    { Obtem nome da máquina Client }
    if (WTSQuerySessionInformation (WTS_CURRENT_SERVER_HANDLE,
                                    lSessionId,
                                    WTSClientName,
                                    lBuffer,
                                    lBytesReturned)) then
       lStationName := PAnsiChar(lBuffer)
    else
       raise Exception.Create ('Não foi possível obter o nome da estação');

    Result := lStationName;
    
    { Libera a memória alocada automaticamente }
    WTSFreeMemory (lBuffer);
end;

function GetLocalComputerName:String;
Var
  Buffer:Array[0..255] of Char;
  dSize:DWord;
Begin
   Result := '';
   dSize := 256;

   If Windows.GetComputerName(Buffer, dSize) Then
   Begin
       Result := Buffer;
   end;
end;

function GetDifTempoFmt(AData_Hora:TDateTime): String;
Var
  Data_Hora:TDateTime;
  dias:Integer;
  S:String;
begin
    Data_Hora := (StrToTime('23:59:59') + StrToTime('00:00:01') - AData_Hora) + Now();
    dias := DaysBetween(StrToDateTime('31/12/1899'), Data_Hora);

    Result := '';

    // Dias
    If dias > 0 Then
       Result  := Result + IntToStr(dias) + ' dia' + IIF(dias > 1,'s','');

    // Horas
    S := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Data_Hora), 12, 2);

    If StrToIntDef(S,0) > 0 Then
       Result  := Result + RemoveZerosEsq(S) + 'h';

    // Minutos
    S := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Data_Hora), 15, 2);

    If StrToIntDef(S,0) > 0 Then
       Result := Result + RemoveZerosEsq(S) + 'm';

    // Segundos
    S := Copy( FormatDateTime('dd/mm/yyyy hh:nn:ss',Data_Hora), 18, 2);

    If StrToIntDef(S,0) > 0 Then
       Result := Result + RemoveZerosEsq(S) + 's';
end;

procedure FreeAndNil(var Obj);
Begin
    If Assigned(TObject(Obj)) Then
       SysUtils.FreeAndNil(Obj);
end;

function AlocarForm(Frm: Pointer ; Mode:TShowMode ; Typ:TTypeForm): Integer;
Var
  i:integer;
begin
    Result := -1;

    If Mode = smNone Then
      raise Exception.Create('Não é possível alocar Form do tipo "tfNone"');

    i := LocateFreePos;

    If i >= 0 Then
    Begin
        If ArrayOfForms[i].Mem = nil Then
        Begin
            ArrayOfForms[i].Mem     := Frm;
            ArrayOfForms[i].ShwMode := Mode;
            ArrayOfForms[i].Typ     := Typ;
            Result := i;
            Exit;
        end;
    end;

    raise EOverflow.Create('Erro inexperado de memória em AlocarForm.');
end;

function DesalocarForm(Frm:Pointer):Integer;
Var
  i:integer;
begin
    Result := -1;

    If LocateByMem(Frm, i) Then
    Begin
        ArrayOfForms[i].Mem     := nil;
        ArrayOfForms[i].ShwMode := smNone;
        ArrayOfForms[i].Typ     := tfNone;
    end;
end;

function LocateFreePos:Integer;
Var
  i:integer;
Begin
    Result := -1;

    For i := 0 to Pred(cnst_MaxQtdForms) Do
    Begin
        If ArrayOfForms[i].Mem = nil Then
        Begin
            Result := i;
            Exit;
        end;
    end;

    raise EOverflow.Create('Estouro de pilha. "ArrayOfForms"');
end;

function LocateByMem(M:Pointer ; var Idx:Integer):Boolean;
Var
  i:integer;
begin
    idx := -1;
    Result := False;

    For i := 0 to Pred(cnst_MaxQtdForms) Do
    Begin
        If ArrayOfForms[i].Mem = M Then
        Begin
            Result := True;
            idx := i;
            Exit;
        end;
    end;
end;

// Idx utilizado tanto como ENTRADA como SAIDA.
// Na entrada ele diz respeito à posição que deve iniciar a busca (caso seja valida)
// Na saida é a posicao onde foi localizado
function Locate(Mode:TShowMode ; ATyp:TTypeForm ; var Idx:Integer):Pointer;
Var
  i, Initial:integer;
Begin
    Result := nil;
    If (idx < 0) or (idx > Pred(cnst_MaxQtdForms)) Then
       Initial := 0
    Else
       Initial := idx;

    For i := Initial to Pred(cnst_MaxQtdForms) Do
    Begin
        If (ArrayOfForms[i].ShwMode = Mode) And
           (ArrayOfForms[i].Typ = ATyp) Then
        Begin
            Idx := i;
            Result := ArrayOfForms[i].Mem;
            Exit;
        end;
    end;
    Idx := i;
end;

function Locate(Mode:TShowMode ; var Idx:Integer):Pointer; overload;
Var
  i, Initial:integer;
Begin
    Result := nil;
    If (idx < 0) or (idx > Pred(cnst_MaxQtdForms)) Then
       Initial := 0
    Else
       Initial := idx;

    For i := Initial to Pred(cnst_MaxQtdForms) Do
    Begin
        If (ArrayOfForms[i].ShwMode = Mode) Then
        Begin
            Idx := i;
            Result := ArrayOfForms[i].Mem;
            Exit;
        end;
    end;
    Idx := i;
end;

function Locate(ATyp:TTypeForm ; var Idx:Integer):Pointer; overload;
Var
  i, Initial:integer;
Begin
    Result := nil;
    If (idx < 0) or (idx > Pred(cnst_MaxQtdForms)) Then
       Initial := 0
    Else
       Initial := idx;

    For i := Initial to Pred(cnst_MaxQtdForms) Do
    Begin
        If (ArrayOfForms[i].Typ = ATyp) Then
        Begin
            Idx := i;
            Result := ArrayOfForms[i].Mem;
            Exit;
        end;
    end;
    Idx := i;
end;

function Find(ATyp:TTypeForm ; var Idx:Integer):Boolean;
Var
  Mem:Pointer;
Begin
    Result := False;
    Mem := Locate(ATyp, idx);
    Result := (Mem <> nil);
end;

function Find(Mode:TShowMode ; var Idx:Integer):Boolean; overload;
Var
  Mem:Pointer;
Begin
    Result := False;
    Mem := Locate(Mode, idx);
    Result := (Mem <> nil);
end;

function DesalocarByIndex(Idx:Integer):Boolean;
Begin
    Result := False;

    If (ArrayOfForms[idx].Mem <> nil) Then
    Begin
        ArrayOfForms[idx].Mem     := nil;
        ArrayOfForms[idx].ShwMode := smNone;
        ArrayOfForms[idx].Typ     := tfNone;
        Result := True;
    end;
end;

function FileTimeToDTime(FTime: TFileTime): TDateTime;
var
  LocalFTime: TFileTime;
  STime: TSystemTime;
begin
  FileTimeToLocalFileTime(FTime, LocalFTime);
  FileTimeToSystemTime(LocalFTime, STime);
  Result := SystemTimeToDateTime(STime);
end;

Initialization
  // Coleta o Caminho+Nome do executavel corrente (Client ou Server)
  sPath := ExtractFilePath(Application.ExeName);
  If Copy(sPath, Length(sPath),1) <> '\' Then
     sPath := sPath + '\';


end.
