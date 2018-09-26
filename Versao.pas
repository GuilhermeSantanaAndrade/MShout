unit Versao;

interface

uses Classes, Contnrs, SysUtils, UGlobal, TypInfo, CheckLst, IniFiles;

type
  TVersaoType  = (None, Branches, Congelada);
  TVersoesType = set of TVersaoType;

  TFormatString = (fsDesc_Virgula, fsID_Virgula, fsDesc_Enter);

  TVersao = class
  private
    fID:String;
    fNome:String;
    fTipoVersao:TVersaoType;
    fDirGerador:String;
    fDirOutput:String;
    fArqPrincipal:String;
    fDTCreate:TDateTime;

    procedure AtualizaDTVersao;
  public
    function toString(SubSep:String):String;
    function GetDTVersao:TDateTime;

    procedure ParseAttributes(Atbr, Separator: string);
    class procedure Clone(var Vrs, NewVrs:TVersao);
    class function  CompareObjects(Vrs1, Vrs2:TVersao):Boolean;
    property  ID           : String      read fID            write fID;
    property  Nome         : String      read fNome          write fNome;
    property  TipoVersao   : TVersaoType read fTipoVersao    write fTipoVersao;
    property  DirGerador   : String      read fDirGerador    write fDirGerador;
    property  DirOutput    : String      read fDirOutput     write fDirOutput;
    property  ArqPrincipal : String      read fArqPrincipal  write fArqPrincipal;
  end;

  TListVersao = class(TList)
  private

  public
    constructor Create;
    destructor  Destroy;override;
    procedure   SetVersao(const Index:Integer ; vrs : TVersao);
    function    ListToString(Sep, SubSep:String):String; overload;
    function    ListToString(Sep, SubSep:String ; ArrayOfIndex : ArrayOfInteger):String; overload;
    function    ListToFormatedString(Tipo:TFormatString):String;
    function    GetVersao(const Index:Integer):TVersao;
    function    GetVersaoPorID(const ID:String):TVersao;
    function    Add(Vrs:TVersao):Integer; overload;
    function    Add(pID, pNome:String ; pTipo:TVersaoType):Integer; overload;
    function    ExisteID(sID:String):Boolean;
    procedure   Clear();override;
    function    Delete(ID:String ; out Nome:String):Boolean; overload;
    procedure   Delete(Index:Integer); overload;

    procedure LoadFromDirectory(Dir, Ext: String);

    class procedure DecodeVersoesToList(const StrVrs: String; Separator, Sub_Separator: String; out Lista: TListVersao);
    class function  EncodeVersoesToStr(const KeyString: String; DirRDO_Versoes:String ; Sep, SubSep:String):String;

    class function  ChkListToStr(ChkLst : TCheckListBox):String; overload;
    class function  ChkListToStr(ChkLst : TCheckListBox ; SupportArray:Array of String):String; overload;

    property    Items[const Index: Integer]: TVersao read GetVersao write SetVersao; default;
  end;

  TVersaoConverter =class
  public
    constructor Create;
    destructor Destroy; override;
    class function EnumToString(E:TVersaoType):String;
    class function StringToEnum(S:string):TVersaoType;
    class function VersaoListIsEmpty(T:TVersoesType):Boolean;
    class function VersoesToString(T: TVersoesType; Separator: String): String;
  end;

implementation

{ TVersao }

procedure TVersao.AtualizaDTVersao;
var
  SR: TSearchRec;
  CreateDT: TDateTime;
begin
  if FindFirst(Self.fDirOutput + Self.fArqPrincipal, faAnyFile, SR) = 0 then
  begin
    CreateDT := SR.FindData.ftCreationTime.dwLowDateTime;
    //CreateDT       := FileTimeToDTime(SR.FindData.ftCreationTime);
    Self.fDTCreate := CreateDT;
  end else
     raise Exception.Create('Desculpe, arquivo não encontrado leitorbinario');

  FindClose(SR);
end;

class procedure TVersao.Clone(var Vrs, NewVrs: TVersao);
begin
    if not Assigned(Vrs) Then
        raise Exception.Create('Erro ao tentar clonar objeto TVersao. Parâmetro de entrada não inicializado.');

    if Assigned(NewVrs) Then
        NewVrs.Free;

    NewVrs               := TVersao.Create;
    NewVrs.fNome         := Vrs.fNome;
    NewVrs.fID           := Vrs.fID;
    NewVrs.fTipoVersao   := Vrs.fTipoVersao;
    NewVrs.fDirGerador   := Vrs.fDirGerador;
    NewVrs.fDirOutput    := Vrs.fDirOutput ;
    NewVrs.fArqPrincipal := Vrs.fArqPrincipal;
end;

class function  TVersao.CompareObjects(Vrs1, Vrs2:TVersao):Boolean;
begin
    Result := False;

    if not Assigned(Vrs1) or not Assigned(Vrs2) Then
        raise Exception.Create('Erro ao tentar comparar objetos TVersao. Parâmetro de entrada não inicializado.');

    if (Vrs1.fNome = Vrs2.fNome) and
       (Vrs1.fID   = Vrs2.fID)   and
       (Vrs1.fTipoVersao   = Vrs2.fTipoVersao)  And
       (Vrs1.fDirGerador   = Vrs2.fDirGerador ) And
       (Vrs1.fDirOutput    = Vrs2.fDirOutput)   And
       (Vrs1.fArqPrincipal = Vrs2.fArqPrincipal)  Then
    Begin
       Result := True;
    end;
end;

function TVersao.GetDTVersao: TDateTime;
begin

end;

procedure TListVersao.LoadFromDirectory(Dir, Ext: String);
Var
  SR : TSearchRec;
  V  : TVersao;
begin
    Self.Clear;
    If FindFirst(Dir + '\*.' + Ext, faArchive, SR) = 0 Then
    Begin
        repeat
           V     := TVersao.Create;
           V.fID := ChangeFileExt(SR.Name,'');

           Self.Add(V);
        until FindNext(SR) <> 0;

        FindClose(SR);
    end;
end;

procedure TVersao.ParseAttributes(Atbr, Separator: string);
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
          0: Self.fID           := Value;
          1: Self.fNome         := Value;
          2: begin
                 if UpperCase(Value) = UpperCase(TVersaoConverter.EnumToString(Branches)) Then
                    Self.fTipoVersao := Branches
                 else
                 if UpperCase(Value) = UpperCase(TVersaoConverter.EnumToString(Congelada)) Then
                    Self.fTipoVersao := Congelada
                 else
                 if UpperCase(Value) = UpperCase(TVersaoConverter.EnumToString(None)) Then
                    Self.fTipoVersao := None;
             end;
          3: Self.fDirGerador   := Value;
          4: Self.fDirOutput    := Value;
          5: Self.fArqPrincipal := Value;
        End;

        Inc(I);
    end;
end;

function TVersao.toString(SubSep:String):String;
begin
    Result := '(' + Self.fID         + SubSep +
                    Self.fNome       + SubSep +
                    TVersaoConverter.EnumToString(Self.fTipoVersao) + SubSep +
                    Self.fDirGerador + SubSep +
                    Self.fDirOutput  + SubSep +
                    Self.fArqPrincipal + ')';
end;

{ TListVersao }

function TListVersao.Add(pID, pNome: String; pTipo: TVersaoType): Integer;
Var
  Vrs:TVersao;
begin
    Vrs       := TVersao.Create;
    Vrs.fNome := pNome;
    Vrs.fID   := pID;
    Vrs.fTipoVersao := pTipo;

    Result := Add(Vrs);
end;

function TListVersao.Add(Vrs: TVersao): Integer;
begin
    Result := inherited Add(Vrs);
end;

class function TListVersao.ChkListToStr(ChkLst: TCheckListBox  ; SupportArray:Array of String): String;
var
  I:Integer;
begin
    Result := '(';

    For I:= 0 To ChkLst.Count-1 Do
    Begin
        Try
          If ChkLst.Checked[I] then
          Begin
             Result := Result + SupportArray[I] + ',';
          End;
        Except
          raise Exception.Create('Procedure: ChkListToStr'#13'Array de suporte incompatível com ChkList');
        End;
    end;

    if Copy(Result, Length(Result), 1) = ',' then
       Result := Copy(Result, 1, Length(Result)-1);

    Result := Result + ')';
    if Result = '()' then
       Result := '';
end;

class function TListVersao.ChkListToStr(ChkLst: TCheckListBox): String;
begin

end;

procedure TListVersao.Clear;
begin
    while Self.Count > 0 Do
       Self.Delete(0);

    inherited;
end;

constructor TListVersao.Create;
begin
    inherited Create;
end;

procedure TListVersao.Delete(Index: Integer);
var
  Temp:TVersao;
begin
  Temp := Self.GetVersao(Index);
  FreeAndNil(Temp);

  inherited;
end;

function TListVersao.Delete(ID: String; out Nome: String): Boolean;
var
  I:Integer;
begin
    Result := False;

    For I := 0 to Self.Count-1 do
    Begin
        If Trim(Self.Items[I].ID) = ID then
        Begin
            Nome := Self.Items[I].Nome;

            Self.Delete(I);
            Result := True;
        End;
    End;
end;

destructor TListVersao.Destroy;
begin
  Self.Clear;
  inherited;
end;

function TListVersao.ExisteID(sID: String): Boolean;
var
  I:Integer;
begin
    Result := False;
    For I := 0 To  Self.Count-1 do
    Begin
       if Items[I].ID = sID Then
          Result := True;
    End;
end;

function TListVersao.GetVersao(const Index: Integer): TVersao;
begin
    Result := inherited Get(Index);
end;

function TListVersao.GetVersaoPorID(const ID: String): TVersao;
Var
  I:Integer;
begin
    Result := nil;

    For I := 0 to Self.Count-1 do
    Begin
        If Trim(Items[I].ID) = ID then
        Begin
            Result := GetVersao(I);
        End;
    end;
end;

function TListVersao.ListToString(Sep, SubSep: String): String;
Var
  I:Integer;
begin
    Result := '';

    for  I:= 0 to Self.Count-1 Do
    begin
        If Result <> '' then
           Result := Result + Sep;

        Result := Result + Self.GetVersao(I).toString(SubSep);
    end;
end;

function TListVersao.ListToFormatedString(Tipo:TFormatString): String;
var
  I:Integer;
begin
    Result := '';
    if Tipo = fsDesc_Virgula then
    Begin
        for I:= 0 To Self.Count-1 Do
        begin
           if Result <> '' Then
              Result := Result + ', ';

           Result := Result + Self.Items[I].fNome;
        end;
    end else
    if Tipo = fsID_Virgula then
    Begin
        for I:= 0 To Self.Count-1 Do
        begin
           if Result <> '' Then
              Result := Result + ', ';

           Result := Result + Self.Items[I].fID;
        end;
    end else
    if Tipo = fsDesc_Enter then
    Begin
        for I:= 0 To Self.Count-1 Do
        begin
           if Result <> '' Then
              Result := Result + #13;

           Result := Result + Self.Items[I].fNome;
        end;
    end;
end;

function TListVersao.ListToString(Sep, SubSep: String; ArrayOfIndex: ArrayOfInteger): String;
var
  i:integer;
begin
    Result := '';

    for i:= Low(ArrayOfIndex) to High(ArrayOfIndex) Do
    begin
        If Result <> '' then
           Result := Result + Sep;

        try
           Self.GetVersao(ArrayOfIndex[i]);
        Except
           raise Exception.Create('Índice fora de faixa em TListVersao.ListToString. Index('+ IntToStr(ArrayOfIndex[i]) +')');
        End;

        Result := Result + Self.GetVersao(ArrayOfIndex[i]).toString(SubSep);
    end;
end;

procedure TListVersao.SetVersao(const Index: Integer; vrs: TVersao);
begin
    inherited Put(Index, Vrs);
end;

class procedure TListVersao.DecodeVersoesToList(const StrVrs: String; Separator, Sub_Separator: String; out Lista: TListVersao);
Var
  Str, SubStr, Values, _ :String;
  I, Y : Integer;
  V    : TVersao;
const
  QtdParams = 6;
begin
    if not Assigned(Lista) or (Lista = nil) Then
        Lista := TListVersao.Create();
    Lista.Clear;

    _    := Separator;
    Str  := StrVrs + _ ;

    While Pos( _ , Str ) > 0 do
    begin
        Values := Copy(Str, 1, Pos( _ , Str )-1);
        Str    := Copy(Str, Pos( _ , Str )+1, Length(Str) );

        If (Values <> '') then
        begin
            If QtdSeparatorsStr(Values , Sub_Separator) <> (QtdParams-1) Then
               raise Exception.Create('Erro ao executar "DecodeVersoesToList". Quantidade de parâmetros diferente da esperada.');

            if Copy(Values, 1, 1) = '(' then
               Values := Copy(Values, 2, Length(Values));

            Y := Length(Values);
            if Copy(Values, Y, 1) = ')' then
               Values := Copy(Values, 1, Y-1);
            Y := Length(Values);

            Values := Values + Sub_Separator;
            I      := 0;
            V      := TVersao.Create;

            While Pos( Sub_Separator , Values ) > 0 do
            begin
                SubStr := Copy(Values, 1, Pos( Sub_Separator , Values )-1);
                Values := Copy(Values, Pos( Sub_Separator , Values )+1, Y );

                if SubStr <> '' Then
                Begin
                    Case I of
                      0: V.fID   := SubStr;
                      1: V.fNome := SubStr;
                      2: begin
                            if UpperCase(SubStr) = UpperCase(TVersaoConverter.EnumToString(Branches)) Then
                               V.fTipoVersao := Branches
                            else
                            if UpperCase(SubStr) = UpperCase(TVersaoConverter.EnumToString(Congelada)) Then
                               V.fTipoVersao := Congelada
                            else
                            if UpperCase(SubStr) = UpperCase(TVersaoConverter.EnumToString(None)) Then
                               V.fTipoVersao := None;
                         end;
                      3: V.fDirGerador    := SubStr;
                      4: V.fDirOutput     := SubStr;
                      5: V.fArqPrincipal  := SubStr;
                    end;
                    Inc(I);
                end;
            end;

            Lista.Add(V);
        end;
    end;
end;

{ TParamConverter }

constructor TVersaoConverter.Create;
begin
end;

destructor TVersaoConverter.Destroy;
begin
  inherited;
end;

class function TVersaoConverter.EnumToString(E: TVersaoType): String;
begin
    Result := GetEnumName( TypeInfo(TVersaoType), Integer(E));
end;

class function TVersaoConverter.VersaoListIsEmpty(T: TVersoesType): Boolean;
Var
  I:Integer;
  Name:string;
  Enum:TVersaoType;
begin
    Result := True;
    for I := Ord(Low(TVersaoType)) to Ord(High(TVersaoType)) do
    Begin
        Name := GetEnumName( TypeInfo(TVersaoType), I);
        Enum := StringToEnum(Name);

        if Enum in T then
        Begin
           Result := False;
           Break;
        End;
    end;
end;

class function TVersaoConverter.VersoesToString(T: TVersoesType; Separator: String): String;
Var
  Param:TVersaoType;
begin
    Result := '';

    for Param := Low(Param) to High(Param) do
    Begin
        if Param in T then
        Begin
           If Result <> '' then
              Result := Result + Separator;

           Result := Result + EnumToString(Param);
        End;
    end;
end;

class function TVersaoConverter.StringToEnum(S: string): TVersaoType;
Var
  EN:TVersaoType;
begin
    EN     := TVersaoType( GetEnumValue( TypeInfo(TVersaoType) , S ) );
    Result := EN;
end;

class function TListVersao.EncodeVersoesToStr(const KeyString: String; DirRDO_Versoes: String ; Sep, SubSep:String): String;
Var
  Str, S, sValue, sIndentName, sEncodedVersao:String;
  Y, I:Integer;
  ArqRDO:TIniFile;
begin
    If Not FileExists(DirRDO_Versoes) Then
       raise Exception.Create('Diretório inexistente "EncodeVersoesToStr".'+#13+ DirRDO_Versoes);

    ArqRDO := TIniFile.Create(DirRDO_Versoes);
    Try
      If Copy(KeyString, Length(KeyString), 1) <> Sep Then
         Str := KeyString + Sep
      Else
         Str := KeyString;

      Result := '';

      While Pos(Sep, Str) > 0 Do
      Begin
          Y              := Pos(Sep, Str);
          S              := Copy(Str, 1, Y-1);
          Str            := Copy(Str, Y+1, Length(Str));
          sEncodedVersao := '';

          If ArqRDO.SectionExists(S) Then
          Begin
             sEncodedVersao := '(';

             For I := 0 To 5 Do
             Begin
                 Case I of
                     0: sIndentName := 'ID';
                     1: sIndentName := 'Nome';
                     2: sIndentName := 'Tipo';
                     3: sIndentName := 'Gerador';
                     4: sIndentName := 'DirSaida';
                     5: sIndentName := 'ArqPrincipal';
                 end;

                 If I > 0 Then
                 Begin
                    sValue := ArqRDO.ReadString(S, sIndentName, '');
                    If sValue = '' Then raise Exception.Create('Dados inconsistentes em '+ DirRDO_Versoes);

                    sEncodedVersao := sEncodedVersao + SubSep;
                    sEncodedVersao := sEncodedVersao + sValue;
                 End Else
                    sEncodedVersao := sEncodedVersao + S;
             End;

             sEncodedVersao := sEncodedVersao + ')';

             If Result <> '' Then
                Result := Result + Sep + sEncodedVersao
             Else
                Result := sEncodedVersao;
          end Else
             raise Exception.Create('Section "'+ S +'" inexistente em '+ DirRDO_Versoes);
      end;
    Finally
      FreeAndNil(ArqRDO);
    End;
end;

end.
