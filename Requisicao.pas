unit Requisicao;

interface

uses Classes, Contnrs, SysUtils, UGlobal, Usuario;

Type
  IArquitetura = interface
  ['{62A2765A-338B-4EED-8207-A21130BA0611}']
  end;

  PIArquitetura = ^IArquitetura;

  TRequisicoesClass = class of TRequisicoes;

  TRequisicoes = class(TObject)
  protected
    function Check(IP:String ; InfoVersion:Integer = -MaxInt):String; virtual;
  public
    class function GetRequisicaoInt(AClass:TRequisicoesClass ; const sInput:String):Integer;
    class function GetRequisicaoStr(AClass:TRequisicoesClass ; const sInput:String):String;
  end;

  TListRequisicoes = class(TStringList)
  private
  public
  end;

  TFormatedString = (fsNumber_Name_IP);

  TFilaItem = class
  private
    fUsuario:TUsuario;
    fOrdem:Integer;
    fPrioridade:Word;
  public
    function ToString(SubSep:string):String;
    property Usuario : TUsuario read fUsuario write fUsuario;
    property Ordem : Integer read fOrdem write fOrdem;
    property Prioridade : Word read fPrioridade write fPrioridade;
  end;

  TFila = class(TRequisicoes)
  private
     fFila:TStringList;
     fListInteressados:TStringList;
     fFilaVersion:Integer;
     fStr:String;
     fSep, fSubSep:String;
     fServerFila:Boolean;

     procedure ReCalcula_Ordem(var ALastOrdem:Integer); overload;
     procedure ReCalcula_Ordem; overload;
     function  LocateByOrdem(Ordem:Integer; var idx:Integer):Boolean;
  public
     procedure   Clear;
     function    GetItemByIndex(idx:Integer):TFilaItem;
     function    IPExists(IP:String; var idx:Integer):Boolean;

     function    FilaToStr(Sep, SubSep:String):String; overload;
     function    FilaToStr:String; overload;
     function    FilaToFormatedStr(Format:TFormatedString):String;

     function    GetMaxOrdem:Integer;
     function    Count:Integer;

     procedure   Add(AUsr:TUsuario ; APrioridade:Word = 0); overload;
     procedure   Add(AItem:TFilaItem); overload;
     procedure   AddInteressado(IP:String);

     function    Delete(const IP:String):Boolean; overload;
     procedure   Delete(Index: Integer); overload;
     function    DeleteInteressado(IP:String):Boolean;

     function    FiFo:TFilaItem;
     function    Check(IP:String ; InfoVersion:Integer = -MaxInt):String; override;

     class procedure SplitFila(const StrVrs: String; PSender:Pointer ;Separator, Sub_Separator: String; out Fila: TFila);

     constructor Create(); overload;
     constructor Create(PSender:PIArquitetura ; Sep, SubSep:String); overload;
     destructor  Destroy; override;

     property    FilaVersion: Integer read fFilaVersion write fFilaVersion;
     property    FilaString: String read fStr write fStr;
  end;

  TVersaoFila = class(TRequisicoes)
  private
     fFila:TStringList;
     fListInteressados:TStringList;
     fFilaVersion:Integer;
     fStr:String;
     fSep, fSubSep:String;
     fServerFila:Boolean;

     procedure ReCalcula_Ordem(var ALastOrdem:Integer); overload;
     procedure ReCalcula_Ordem; overload;
     function  LocateByOrdem(Ordem:Integer; var idx:Integer):Boolean;
  public
     procedure   Clear;
     function    GetItemByIndex(idx:Integer):TFilaItem;
     function    IPExists(IP:String; var idx:Integer):Boolean;

     function    FilaToStr(Sep, SubSep:String):String; overload;
     function    FilaToStr:String; overload;
     function    FilaToFormatedStr(Format:TFormatedString):String;

     function    GetMaxOrdem:Integer;
     function    Count:Integer;

     procedure   Add(AUsr:TUsuario ; APrioridade:Word = 0); overload;
     procedure   Add(AItem:TFilaItem); overload;
     procedure   AddInteressado(IP:String);

     function    Delete(const IP:String):Boolean; overload;
     procedure   Delete(Index: Integer); overload;
     function    DeleteInteressado(IP:String):Boolean;

     function    FiFo:TFilaItem;
     function    Check(IP:String ; InfoVersion:Integer = -MaxInt):String; override;

     class procedure SplitFila(const StrVrs: String; PSender:Pointer ;Separator, Sub_Separator: String; out Fila: TFila);

     constructor Create(); overload;
     constructor Create(PSender:PIArquitetura ; Sep, SubSep:String); overload;
     destructor  Destroy; override;

     property    FilaVersion: Integer read fFilaVersion write fFilaVersion;
     property    FilaString: String read fStr write fStr;
  end;

  TLostTime = class(TRequisicoes)
  private
     fUsuario:TUsuario;
  public
     constructor Create(Usuario:TUsuario);
     function Check(IP:String ; InfoVersion:Integer = -MaxInt):String; virtual;
  end;

implementation

uses Variants;

{ TRequisicoes }

function TRequisicoes.Check(IP: String ; InfoVersion:Integer = -MaxInt): String;
begin
    Exception.Create('Abstract error TRequisicoes.Check.');
end;

class function TRequisicoes.GetRequisicaoStr(AClass: TRequisicoesClass; const sInput: String): String;
Var
  S, S1:String;
  i, i1, Lgt:integer;
  c:Char;
begin
    If AClass = TFila Then
    Begin
        S := '$FILA=';
        i := Pos(S, sInput);

        If i > 0 Then
        Begin
            i1  := i + Length(S);
            S1  := '';
            Lgt := Length(sInput);

            While (sInput[i1] <> '|' ) And (i1 <= Lgt) Do
            Begin
               S1 := S1 + sInput[i1];
               Inc(i1);
            end;
            Result := S1;
        end;
    end Else
    Begin
        Exception.Create('Erro em GetRequisicaoInt. Classe "'+ String(AClass) +'" incompatível.');
    end;
end;

class function TRequisicoes.GetRequisicaoInt(AClass: TRequisicoesClass; const sInput:String): Integer;
begin
    Result := StrToIntDef( GetRequisicaoStr(AClass, sInput) , -MaxInt );
end;

{ TFilaItem }

function TFilaItem.ToString(SubSep:string): String;
begin
    Result := '(' + Self.Usuario.IP + SubSep + Self.Usuario.Nome + SubSep + IntToStr(Self.fPrioridade) + ')';
end;

{ TFila }

// #overload
procedure TFila.Add(AUsr: TUsuario; APrioridade: Word = 0);
var
  Idx:Integer;
  FilaItem:TFilaItem;
begin
    If not fFila.Find( AUsr.IP , Idx ) then
    Begin
        FilaItem             := TFilaItem.Create;
        FilaItem.fUsuario    := AUsr;
        FilaItem.fOrdem      := Self.GetMaxOrdem;
        FilaItem.fPrioridade := APrioridade;

        fFila.AddObject(FilaItem.fUsuario.IP, Pointer(FilaItem) );
        If fServerFila Then
           Self.ReCalcula_Ordem;
    end else
    Begin
        raise Exception.Create('Usuário já está na fila.');
    end;
end;

// #overload
procedure TFila.Add(AItem: TFilaItem);
var
  idx:Integer;
begin
    if not Assigned(AItem) or (AItem = nil) Then
       raise Exception.Create('Erro inexperado no método TFila.Add'+#13+'Item nulo.');

    if not Assigned(AItem.fUsuario) or (AItem.fUsuario = nil) Then
       raise Exception.Create('Erro inexperado no método TFila.Add'+#13+'Usuário nulo.');

    If not fFila.Find( AItem.fUsuario.IP , Idx ) then
    Begin
        AItem.fOrdem      := Self.GetMaxOrdem;

        fFila.AddObject(AItem.fUsuario.IP, Pointer(AItem) );
        If fServerFila Then
           Self.ReCalcula_Ordem;
    end else
    Begin
        raise Exception.Create('Usuário já está na fila.');
    end;
end;

constructor TFila.Create(PSender:PIArquitetura ; Sep, SubSep:String);
begin
    inherited Create;

    fFila        := TStringList.Create;
    fFila.Sorted := True;

    fListInteressados        := TStringList.Create;
    fListInteressados.Sorted := True;

    fSep    := Sep;
    fSubSep := SubSep;

    fFilaVersion := 0;

    If TObject(PSender).ClassNameIs('TFrmMShoutClient') Then
    Begin
        fServerFila := False;
    end else
    If TObject(PSender).ClassNameIs('TFrmServer') Then
    Begin
        fServerFila := True;
    End Else
       Exception.Create('Classe de IArquitetura inválida.');
end;

constructor TFila.Create;
begin
    raise Exception.Create('Erro em TFila.Create(); Construtor vazio não permitido.');
end;

destructor TFila.Destroy;
begin
    inherited;
    FreeAndNil(fFila);
    FreeAndNil(fListInteressados);
end;

function TFila.FilaToStr(Sep, SubSep:String):String;
Var
  ordem, index:Integer;
  Cnt:Integer;
begin
    Cnt    := 1;
    ordem  := 0;
    Result := '';

    while (Cnt <= fFila.Count) Do
    Begin
        if LocateByOrdem(ordem, index) Then
        Begin
           if Result <> '' then
              Result := Result + Sep;

           Result := Result + TFilaItem(fFila.Objects[index]).ToString(SubSep);

           Inc(Cnt);
        end;

        Inc(ordem);
    end;

    If fFila.Count > 0 Then
       Result := Result + Sep + 'FILAVERSION=' + IntToStr(Self.fFilaVersion);

    fStr := Result;
end;

function TFila.GetMaxOrdem: Integer;
var
  I:Integer;
begin
    Result := 0;

    if fFila.Count = 0 Then
       Exit;

    for i:= 0 to fFila.Count-1 Do
    Begin
        If TFilaItem(fFila.Objects[i]).fOrdem > Result then
           Result := TFilaItem(fFila.Objects[i]).fOrdem;
    end;

    Result := Result + 1;
end;

procedure TFila.ReCalcula_Ordem(var ALastOrdem:Integer);
Var
  ListAuxiliar:TStringList;
  MaxPrioridade,i, j, idx:Integer;
  vIP, vStr:String;
begin
    ListAuxiliar           := TStringList.Create;
    MaxPrioridade          := -1;

    Try
      for i := 0 to fFila.Count - 1 Do
      begin
          if TFilaItem(fFila.Objects[i]).Prioridade > MaxPrioridade then
              MaxPrioridade := TFilaItem(fFila.Objects[i]).Prioridade;
      end;

      if fFila.Count > 0 then
      begin
          ListAuxiliar.Clear;

          for i := 0 To fFila.Count - 1 Do
          begin
              If Assigned(TFilaItem(fFila.Objects[i]).fUsuario) and (TFilaItem(fFila.Objects[i]).fUsuario <> nil) Then
                 ListAuxiliar.Add( IntToStr(Abs(TFilaItem(fFila.Objects[i]).fPrioridade - MaxPrioridade)) + '.' + IntToStr(TFilaItem(fFila.Objects[i]).fOrdem) + '|' + TFilaItem(fFila.Objects[i]).fUsuario.IP)
              Else
                 fFila.Delete(i);
          end;

          ListAuxiliar.Sort;
          idx := 0;

          for j := 0 To ListAuxiliar.Count - 1 Do
          Begin
              vStr := ListAuxiliar[j];
              vIP  := Copy(vStr, Pos('|', vStr)+1, Length(vStr));

              if fFila.Find(vIP, i) then
              Begin
                  TFilaItem(fFila.Objects[i]).fOrdem := idx;
                  Inc(idx);
              end;
          end;

          if idx = 0 then
             ALastOrdem := -1
          Else
             ALastOrdem := idx;

          Inc(fFilaVersion);
      end;

      Self.FilaToStr(fSep, fSubSep);
    Finally
       ListAuxiliar.Free;
    End;
end;

function TFila.LocateByOrdem(Ordem: Integer; var idx: Integer): Boolean;
var
  i:integer;
begin
    Result := False;
    idx    := -1;

    for i:=0 To fFila.Count-1 Do
    Begin
        if TFilaItem(fFila.Objects[i]).fOrdem = Ordem then
        Begin
            idx    := i;
            Result := True;
            Break;
        End;
    end;
end;

procedure TFila.ReCalcula_Ordem;
Var
  x:Integer;
begin
    // não aproveita o 'X'
    ReCalcula_Ordem(x);
end;

class procedure TFila.SplitFila(const StrVrs: String; PSender:Pointer ;Separator, Sub_Separator: String; out Fila: TFila);
Var
  Str, SubStr, Values, S, S1, _ :String;
  I, Y : Integer;
  F    : TFilaItem;
  IsAttbr:Boolean;
const
  QtdParams = 3;
begin
    if not Assigned(Fila) or (Fila = nil) Then
        Fila := TFila.Create(PSender, Separator, Sub_Separator);
    Fila.fFila.Clear;

    _     := Separator;
    Str   := StrVrs + _ ;

    While Pos( _ , Str ) > 0 do
    begin
        Values  := Copy(Str, 1, Pos( _ , Str )-1);
        Str     := Copy(Str, Pos( _ , Str )+1, Length(Str) );
        IsAttbr := False;

        If (Values <> '') then
        begin
            If (Copy(Values, 1, 1) <> '(') Then
               IsAttbr := True;

            If (Not IsAttbr) And (QtdSeparatorsStr(Values , Sub_Separator) <> (QtdParams-1)) Then
               raise Exception.Create('Erro ao executar "SplitVersoes". Quantidade de parâmetros diferente da esperada.');

            if (Copy(Values, 1, 1) = '(') And (not IsAttbr) then
               Values := Copy(Values, 2, Length(Values));

            Y := Length(Values);
            if (Copy(Values, Y, 1) = ')') And (not IsAttbr) then
               Values := Copy(Values, 1, Y-1);
            Y := Length(Values);

            If IsAttbr Then
            Begin
                S := '';
                i := 1;

                While (Values[i] <> Separator) And (i <= Length(Values)) Do
                Begin
                    S := S + Values[i];
                    Inc(i);
                end;

                i := Pos('=', S);

                If i = 0 Then
                   raise Exception.Create('Erro em TFila.SplitFila. Atributo sem operador de atribuição.'+#13+S);

                S1 := Copy(S, 1, i-1);

                If UpperCase(S1) = 'FILAVERSION' Then
                Begin
                    S1 := Copy(S, i+1, MaxInt);
                    Try
                      Fila.fFilaVersion := StrToInt(S1);
                    Except
                      On E : Exception Do
                      Begin
                        E.Message := 'Erro de conversão em TFila.SpitFila. '+ S1 + E.Message;
                        raise;
                      end;
                    End;
                end Else
                Begin
                   raise Exception.Create('Erro em TFila.SplitFila. Atributo desconhecido.'+#13+S);
                end;
            end Else
            Begin
                Values    := Values + Sub_Separator;
                I         := 0;
                F         := TFilaItem.Create;
                F.Usuario := TUsuario.Create;

                While Pos( Sub_Separator , Values ) > 0 do
                begin
                    SubStr := Copy(Values, 1, Pos( Sub_Separator , Values )-1);
                    Values := Copy(Values, Pos( Sub_Separator , Values )+1, Y );

                    if SubStr <> '' Then
                    Begin
                        Case I of
                          0: F.Usuario.IP   := SubStr;
                          1: F.Usuario.Nome := SubStr;
                          2: F.fPrioridade  := StrToInt(SubStr);
                        end;
                        Inc(I);
                    end;
                end;

                Fila.Add(F);
            End;
        end;
    end;

    Fila.FilaToStr;
end;

function TFila.Delete(const IP: String): Boolean;
var
  idx:Integer;
begin
    Result := False;

    If fFila.Find(IP, idx) then
    begin
       fFila.Delete(idx);

       If fServerFila Then
          Self.ReCalcula_Ordem;

       Result := True;
    end;
end;

procedure TFila.AddInteressado(IP: String);
var
  idx:Integer;
begin
    If not Self.fListInteressados.Find(IP, idx) Then
    Begin
        Self.fListInteressados.Add(IP);
    end;
end;

function TFila.DeleteInteressado(IP: String):Boolean;
Var
  idx:Integer;
begin
    Result := False;
    If Self.fListInteressados.Find(IP, idx) Then
    Begin
        Self.fListInteressados.Delete(idx);
        Result := True;
    end;
end;

function TFila.FilaToStr: String;
begin
    Result := FilaToStr(fSep, fSubSep);
end;

function TFila.Check(IP: String ; InfoVersion:Integer = -MaxInt): String;
Var
  idx:Integer;
begin
    If IsWrongIP(IP) then
       raise Exception.Create('IP inválido em "TFila.Check".');

    If fListInteressados.Find(IP, idx) Then
    Begin
        Result := Self.fStr
    end;
end;

function TFila.FiFo: TFilaItem;
Var
  idx:Integer;
begin
    Result := nil;
    If Self.LocateByOrdem(0,idx) Then
    Begin
        Result := GetItemByIndex(idx);
        Self.Delete(idx);
    end;
end;

function TFila.GetItemByIndex(idx: Integer): TFilaItem;
begin
    Result := nil;
    If (idx > -1) And (idx < fFila.Count) Then
       Result := TFilaItem(fFila.Objects[idx]);
end;

procedure TFila.Delete(Index: Integer);
begin
  fFila.Delete(Index);
  ReCalcula_Ordem;
end;

function TFila.FilaToFormatedStr(Format: TFormatedString): String;
Var
  y, idx:Integer;
  cnt:Word;
  str:String;
  FI:TFilaItem;
begin
    Result := '';
    y      := 0;
    cnt    := 0;

    If Format = fsNumber_Name_IP Then
    Begin
       while (Cnt < fFila.Count) Do
       Begin
           If Self.LocateByOrdem(y, idx) Then
           Begin
               FI     := Self.GetItemByIndex(idx);
               If Result <> '' Then
                  Result := Result + #13;
                  
               Result := Result + IntToStr(FI.fOrdem + 1) + ' - ' + FI.fUsuario.Nome + ' (' + FI.fUsuario.IP + ') ';
               Inc(Cnt); 
           end;

           Inc(y);
       End;
    end Else
       Exception.Create('Formato inválido em TFila.FilaToFormatedStr.');
end;

function TFila.Count: Integer;
begin
    Result := fFila.Count;
end;

function TFila.IPExists(IP: String; var idx: Integer): Boolean;
var
  i:integer;
begin
    Result := False;
    idx    := -1;

    for i:=0 To fFila.Count-1 Do
    Begin
        if TFilaItem(fFila.Objects[i]).Usuario.IP = IP then
        Begin
            idx    := i;
            Result := True;
            Break;
        End;
    end;
end;

procedure TFila.Clear;
begin
    Self.fFila.Clear;
    Self.fListInteressados.Clear;
    Self.FilaToStr;
end;

{ TLostTime }

function TLostTime.Check(IP: String; InfoVersion: Integer): String;
const
   Verdadeiro = 'TRUE';
begin
    Result := '';

    Try
      If Assigned(Self.fUsuario) Then;
    Except
      FreeAndNil(Self);
      Exit;
    End;

    If IP = Self.fUsuario.IP Then
       Result := Verdadeiro;
end;

constructor TLostTime.Create(Usuario: TUsuario);
begin
    If not Assigned(Usuario) Then
       raise Exception.Create('Erro ao criar objeto TLostTime sem usuário.');

    Self.fUsuario := Usuario;
end;

end.
