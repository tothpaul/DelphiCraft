unit Execute.SysUtils;
{-$DEFINE TEST}
interface
{$WARN WIDECHAR_REDUCED OFF}
const
  fmOpenRead       = $0000;
  fmOpenWrite      = $0001;
  fmOpenReadWrite  = $0002;
  fmExclusive      = $0004;
  fmShareExclusive = $0010;
  fmShareDenyWrite = $0020;
  fmShareDenyNone  = $0040;
  fmCreate         = $FF00;

type
  Exception = class(TObject)
  private
    FMessage: string;
  public
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    property Message: string read FMessage;
  end;

  EOSError = class(Exception)
  public
    ErrorCode: Cardinal;
  end;

  EFileError = class(Exception);
  EFOpenError = class(EFileError);
  EFCreateError = class(EFileError);
  EReadError = class(EFileError);
  EWriteError = class(EFileError);

  TSeekOrigin = (soFromBeginning, soFromCurrent, soFromEnd);

  TStream = class
  public
    function Read(var Buffer; Count: NativeInt): NativeInt; virtual;
    procedure ReadBuffer(var Buffer; Count: NativeInt);
    function ReadType<T>:T; inline;
    function Seek(Offset: NativeInt; Origin: TSeekOrigin): NativeInt; virtual;
    function Write(const Buffer; Count: NativeInt): NativeInt; virtual;
    procedure WriteBuffer(const Buffer; Count: NativeInt);
  end;

  THandleStream = class(TStream)
  private
    FHandle: THandle;
  public
    constructor Create(AHandle: THandle);
    function Read(var Buffer; Count: NativeInt): NativeInt; override;
    function Seek(Offset: NativeInt; Origin: TSeekOrigin): NativeInt; override;
    function Write(const Buffer; Count: NativeInt): NativeInt; override;
  end;

  TFileStream = class(THandleStream)
  public
    constructor Create(const AFileName: string; Mode: Integer);
    destructor Destroy; override;
  end;

procedure RaiseLastOSError;
function Format(const Msg: string; const Args: array of const): string;
procedure BSwap(var Value: Cardinal);
function IntToStr(I: NativeInt): string;
function IntToHex(I, Len: NativeInt): string;

function strlen(str: PAnsiChar): Integer;
procedure strncpy(target, source: PAnsiChar; max: Integer);
procedure snprintf(buffer: PAnsiChar; len: Integer; fmt: PAnsiChar; const args: array of const);
function sscanf(buffer, format: PAnsiChar; vars: array of Pointer): Integer;
function strcmp(buffer, value: PAnsiChar): Integer;
procedure strncat(target, source: PAnsiChar; num: Integer);
function atoi(const str: string): Integer;

implementation

uses
{$IFDEF MSWINDOWS}
{$IFDEF TEST}System.SysUtils,{$ENDIF}
  Winapi.Windows,
{$ENDIF}
  System.SysConst,
  System.RTLConsts;

{$IFDEF MSWINDOWS}
function SysErrorMessage(ErrorCode: Cardinal): string;
var
  Buffer: PChar;
  Len: Integer;
  Flags: DWORD;
begin
  Flags := FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_IGNORE_INSERTS or
    FORMAT_MESSAGE_ARGUMENT_ARRAY or
    FORMAT_MESSAGE_ALLOCATE_BUFFER;

  { Obtain the formatted message for the given Win32 ErrorCode
    Let the OS initialize the Buffer variable. Need to LocalFree it afterward.
  }
  Len := FormatMessage(Flags, nil, ErrorCode, 0, @Buffer, 0, nil);

  try
    { Remove the undesired line breaks and '.' char }
    while (Len > 0) and ((Buffer[Len - 1] <= #32) or (Buffer[Len - 1] = '.')) do
      Dec(Len);
    { Convert to Delphi string }
    SetString(Result, Buffer, Len);
  finally
    { Free the OS allocated memory block }
    LocalFree(HLOCAL(Buffer));
  end;
end;
{$ENDIF MSWINDOWS}

{$IFDEF POSIX}
function SysErrorMessage(ErrorCode: Cardinal): string;
var
  Buffer: TBytes;
begin
  Setlength(Buffer, 256);
  if strerror_r(ErrorCode, MarshaledAString(Buffer), Length(Buffer)) = 0 then
    Result := UTF8Decode(MarshaledAString(Buffer))
  else
    Result := Format('System error: %4x',[ErrorCode]);
end;
{$ENDIF POSIX}

procedure RaiseLastOSError;
var
  LastError: Cardinal;
  Error: EOSError;
begin
  LastError := GetLastError;
  if LastError <> 0 then
    Error := EOSError.CreateFmt(SOSError, [LastError, SysErrorMessage(LastError)])
  else
    Error := EOSError.Create(SUnkOSError);
  Error.ErrorCode := LastError;
  raise Error;
end;

function GetInt(var P: PChar; var I: Integer): Boolean;
begin
  Result := P^  in ['0'..'9'];
  if Result then
  begin
    I := Ord(P^) - Ord('0');
    Inc(P);
    while P^ in ['0'..'9'] do
    begin
      I := 10 * I + Ord(P^) - Ord('0');
      Inc(P);
    end;
  end;
end;

(*
  vtInteger       = 0;
  vtBoolean       = 1;
  vtChar          = 2;
  vtExtended      = 3;
  vtString        = 4{$IFDEF NEXTGEN} deprecated 'Type not supported' {$ENDIF NEXTGEN};
  vtPointer       = 5;
  vtPChar         = 6;
  vtObject        = 7;
  vtClass         = 8;
  vtWideChar      = 9;
  vtPWideChar     = 10;
  vtAnsiString    = 11;
  vtCurrency      = 12;
  vtVariant       = 13;
  vtInterface     = 14;
  vtWideString    = 15;
  vtInt64         = 16;
  vtUnicodeString = 17;
*)

function IntLen(Value: Integer; var Signed: Boolean): Integer;
var
  UValue: Cardinal absolute Value;
begin
  Result := 1;
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    Inc(Result);
  end else begin
    Signed := False;
  end;
  while UValue > 10 do
  begin
    Inc(Result);
    UValue := UValue div 10;
  end;
end;


function Int64Len(Value: Int64; var Signed: Boolean): Integer;
var
  UValue: Cardinal absolute Value;
begin
  Result := 1;
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    Inc(Result);
  end else begin
    Signed := False;
  end;
  while UValue > 10 do
  begin
    Inc(Result);
    UValue := UValue div 10;
  end;
end;

procedure IntToBuf(Value: Integer; Buf: PChar; Len: Integer; Signed: Boolean);
var
  UValue: Cardinal absolute Value;
begin
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    Dec(Len);
  end else begin
    Signed := False;
  end;
  while Len > 0 do
  begin
    Dec(Buf);
    Buf^ := Char(UValue mod 10 + Ord('0'));
    UValue := UValue div 10;
    Dec(Len);
  end;
  if Signed then
  begin
    Dec(Buf);
    Buf^ := '-';
  end;
end;

procedure Int64ToBuf(Value: Int64; Buf: PChar; Len: Integer; Signed: Boolean);
var
  UValue: UInt64 absolute Value;
begin
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    Dec(Len);
  end else begin
    Signed := False;
  end;
  while Len > 0 do
  begin
    Buf^ := Char(UValue mod 10 + Ord('0'));
    Dec(Buf);
    UValue := UValue div 10;
    Dec(Len);
  end;
  if Signed then
  begin
    Buf^ := '-';
  end;
end;

procedure IntToBufA(Value: Integer; Buf: PAnsiChar; Len, Max: Integer; Signed: Boolean);
var
  UValue: Cardinal absolute Value;
begin
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    if Len > 0 then
    begin
      Buf^ := '-';
      Inc(Buf);
      Dec(Len);
      Dec(Max);
    end;
  end else begin
    Signed := False;
  end;
  Inc(Buf, Len);
  while (Len > 0) and (Max > 0) do
  begin
    Dec(Buf);
    if Max >= Len then
    begin
      Buf^ := AnsiChar(UValue mod 10 + Ord('0'));
      Dec(Max);
    end;
    UValue := UValue div 10;
    Dec(Len);
  end;
end;

procedure Int64ToBufA(Value: Int64; Buf: PAnsiChar; Len, Max: Integer; Signed: Boolean);
var
  UValue: UInt64 absolute Value;
begin
  if Max = 0 then
    Exit;
  if Signed and (Value < 0) then
  begin
    Value := -Value;
    Buf^ := '-';
    Inc(Buf);
    Dec(Max);
    Dec(Len);
  end else begin
    Signed := False;
  end;
  Inc(Buf, Len);
  while (Len > 0) and (Max > 0) do
  begin
    if Max >= Len then
    begin
      Buf^ := AnsiChar(UValue mod 10 + Ord('0'));
      Dec(Max);
    end;
    Dec(Buf);
    UValue := UValue div 10;
    Dec(Len);
  end;
end;

procedure Pad(Ptr: PChar; Count: Integer; Value: Char);
begin
  while Count > 0 do
  begin
    Ptr^ := Value;
    Inc(Ptr);
    Dec(Count);
  end;
end;

procedure RPad(Ptr: PChar; Count: Integer; Value: Char);
begin
  Dec(Ptr, Count);
  Pad(Ptr, Count, Value);
end;

const
  UpperCaseHexa = '0123456789ABCDEF';
  LowerCaseHexa = '0123456789abcdef';

function HexLen(Value: Integer): Integer;
var
  UValue: Cardinal absolute Value;
begin
  Result := 1;
  while UValue > $F do
  begin
    Inc(Result);
    UValue := UValue shr 4;
  end;
end;

function Hex64Len(Value: Int64): Integer;
var
  UValue: UInt64 absolute Value;
begin
  Result := 1;
  while UValue > $F do
  begin
    Inc(Result);
    UValue := UValue shr 4;
  end;
end;

procedure HexToBuf(Value: Integer; Buf: PChar; Len: Integer; Chars: PChar);
var
  UValue: Cardinal absolute Value;
begin
  while Len > 0 do
  begin
    Dec(Buf);
    Buf^ := Chars[UValue and $F];
    UValue := UValue shr 4;
    Dec(Len);
  end;
end;

procedure Hex64ToBuf(Value: Int64; Buf: PChar; Len: Integer; Chars: PChar);
var
  UValue: UInt64 absolute Value;
begin
  while Len > 0 do
  begin
    Dec(Buf);
    Buf^ := Chars[UValue and $F];
    UValue := UValue shr 4;
    Dec(Len);
  end;
end;

function FormatHexa(var Buffer: PChar; const Value: TVarRec; Left: Boolean; Width, Prec: Integer; Chars: PChar): Integer;
var
  Len: Integer;
begin
  case Value.VType of
    vtPointer : Len := 2 * SizeOf(Pointer);
    vtInteger : Len := HexLen(Value.VInteger);
    vtInt64   : Len := Hex64Len(Value.VInt64^);
  else
    Len := 0;
  end;
  if Len < Prec then
    Len := Prec;
  if Width < 0 then
    Width := Len;
  if Width > Len then
    Result := Width
  else
    Result := Len;
  if Buffer = nil then
    Exit;
  if (Result > Len) and (Left = False) then
  begin
    Pad(Buffer, Result - Len, ' ');
    Inc(Buffer, Result - Len);
  end;
  if Len > 0 then
  begin
    Inc(Buffer, Len);
    case Value.VType of
    {$IF SizeOf(Pointer) = 4}
      vtPointer,
    {$ENDIF}
      vtInteger : HexToBuf(Value.VInteger, Buffer, Len, Chars);
    {$IF SizeOf(Pointer) = 8}
      vtPointer,
    {$ENDIF}
      vtInt64   : Hex64ToBuf(Value.VInt64^, Buffer, Len, Chars);
    else
      RPad(Buffer, Len, ' ');
    end;
  end;
  if (Result > Len) and Left then
  begin
    Pad(Buffer, Result - Len, ' ');
  end;
end;

function FormatDecimal(var Buffer: PChar; const Value: TVarRec; Left: Boolean; Width, Prec: Integer; Signed: Boolean): Integer;
var
  Len: Integer;
begin
  case Value.VType of
    vtInteger : Len := IntLen(Value.VInteger, Signed);
    vtInt64   : Len := Int64Len(Value.VInt64^, Signed);
  else
    Len := 0;
  end;
  if (Prec > 0) and Signed then
    Inc(Prec);
  if Len < Prec then
    Len := Prec;
  if Width < 0 then
    Width := Len;
  if Width > Len then
    Result := Width
  else
    Result := Len;
  if Buffer = nil then
    Exit;

  if (Result > Len) and (Left = False) then
  begin
    Pad(Buffer, Result - Len, ' ');
    Inc(Buffer, Result - Len);
  end;
  if Len > 0 then
  begin
    Inc(Buffer, Len);
    case Value.VType of
      vtInteger : IntToBuf(Value.VInteger, Buffer, Len, Signed);
      vtInt64   : Int64ToBuf(Value.VInt64^, Buffer, Len, Signed);
    else
      RPad(Buffer, Len, ' ');
    end;
  end;
  if (Result > Len) and Left then
  begin
    Pad(Buffer, Result - Len, ' ');
  end;
end;

function VariantToUnicodeString(V: TVarData): string;
begin
  Result := '';
  if V.VType <> varNull then
  begin
    if Assigned(System.VarToUStrProc) then
      System.VarToUStrProc(Result, V)
    else
      System.Error(reVarInvalidOp);
  end;
end;

procedure UpperBuffer(var Buffer: PChar; Len: Integer);
begin
  while Len > 0 do
  begin
    Buffer^ := UpCase(Buffer^);
    Inc(Buffer);
    Dec(Len);
  end;
end;

function PAnsiCharLen(P: PAnsiChar): Integer;
begin
  Result := 0;
  if P = nil then
    Exit;
  while P^ <> #0 do
  begin
    Inc(P);
    Inc(Result);
  end;
end;

function PWideCharLen(P: PWideChar): Integer;
begin
  Result := 0;
  if P = nil then
    Exit;
  while P^ <> #0 do
  begin
    Inc(P);
    Inc(Result);
  end;
end;

function FormatChar(var Buffer: PChar; const Value: TVarRec; Left: Boolean; Width, Prec: Integer; UCase: Boolean): Integer;
begin
  Result := 1;
  if Buffer = nil then
    Exit;
  case Value.VType of
    vtChar     : Buffer^ := Char(Value.VChar);
    vtWideChar : Buffer^ := Value.VWideChar;
  else
    Buffer^ := '?';
  end;
  Inc(Buffer);
end;

function FormatStr(var Buffer: PChar; const Value: TVarRec; Left: Boolean; Width, Prec: Integer; UCase: Boolean): Integer;
var
  Len: Integer;
  Str: string;
begin
  Str := '';
  case Value.VType of
    vtPChar        : Len := PAnsiCharLen(Value.VPChar);
    vtPWideChar    : Len := PWideCharLen(Value.VPWideChar) * SizeOf(Char);
    vtString       : Len := Length(PShortString(Value.VAnsiString)^);
    vtWideString   : Len := Length(WideString(Value.VWideString));
    vtAnsiString   : Len := Length(AnsiString(Value.VAnsiString));
    vtUnicodeString: Len := Length(string(Value.VUnicodeString));
    vtVariant      :
    begin
      Str := VariantToUnicodeString(TVarData(Value.VVariant^));
      Len := Length(Str);
    end
  else
    Len := 0;
  end;
  if Prec < 0 then
    Prec := Len;
  if Len > Prec then
    Len := Prec;
  if Width > Len then
    Result := Width
  else
    Result := Len;
  if (Buffer = nil) or (Len = 0) then
    Exit;
  if (Result > Len) and (Left = False) then
  begin
    Pad(Buffer, Result - Len, ' ');
    Inc(Buffer, Result - Len);
  end;
  if Len > 0 then
  begin
    case Value.VType of
      vtPChar        : Str := string(Value.VPChar);
      vtPWideChar    : Move(Value.VPWideChar^, Buffer^, Len * SizeOf(Char));
      vtString       : Str := string(PShortString(Value.VAnsiString)^);
      vtWideString   : Move(Value.VWideString^, Buffer^, Len * SizeOf(Char));
      vtAnsiString   : Str := string(AnsiString(Value.VAnsiString));
      vtUnicodeString: Move(Value.VUnicodeString^, Buffer^, Len * SizeOf(Char));
    end;
    if Str <> '' then
      Move(Str[1], Buffer^, Len * SizeOf(Char));
    if UCase then
      UpperBuffer(Buffer, Len)
    else
      Inc(Buffer, Len);
  end;
  if (Result > Len) and Left then
  begin
    Pad(Buffer, Result - Len, ' ');
  end;
end;

// "%" [index ":"] ["-"] [width] ["." prec] type
function FormatBuffer(Buffer, Fmt: PChar; const Args: array of const): Integer;
var
  Num  : Integer;
  Index: Integer;
  Left : Boolean;
  Width: Integer;
  Prec : Integer;
  Len  : Integer;

  function GetVarInt(var I: Integer): Boolean;
  begin
    if Fmt^ = '*' then
    begin
      I := -2;
      Inc(Fmt);
      Exit(True);
    end;
    Result := GetInt(Fmt, I);
  end;

  function Skip(C: Char): Boolean;
  begin
    Result := Fmt^ = C;
    if Result then
      Inc(Fmt);
  end;

  function NextInt: Integer;
  begin
    if (Index < Length(Args)) and(Args[Index].VType = vtInteger) then
    begin
      Result := Args[Index].VInteger;
      Inc(Index);
    end else begin
      Result := 0;
    end;
  end;

begin
  Result := 0;
  if Fmt = nil then
    Exit;
  Index := 0;
  // parse Fmt
  while Fmt^ <> #0 do
  begin
    // Format sequence
     if Fmt^ = '%' then
     begin
       Inc(Fmt);
       // '%%' => '%
       if Fmt^ <> '%' then
       begin
         Left  := False;
         Width := -1;
         Prec  := -1;
         if GetVarInt(Num) then
         begin
           // %<index>:
           if Skip(':') then
           begin
             if Num = - 2 then
               Index := NextInt
             else
               Index := Num;
             if Skip('-') then
             begin
               Left := True;
             end;
             GetVarInt(Width);
           end else begin
           // %width
             Width := Num;
           end;
         end else begin
           // %:
           if Skip(':') then
           begin
             Index := 0;
           end;
           if Skip('-') then
           begin
             Left := True;
           end;
           GetVarInt(Width);
         end;
         if Skip('.') then
         begin
           GetVarInt(Prec);
         end;
         if Width = -2 then
           Width := NextInt;
         if Prec = -2 then
           Prec := NextInt;
         if Index < Length(Args) then
         begin
           case Fmt^ of
             'c',
             'C': Len := FormatChar(Buffer, Args[Index], Left, Width, Prec, Fmt^ = 'C');
             'd',
             'u': Len := FormatDecimal(Buffer, Args[Index], Left, Width, Prec, Fmt^ = 'd');
//             'e':
//             'f':
//             'g':
//             'n':
//             'm':
             's',
             'S': Len := FormatStr(Buffer, Args[Index], Left, Width, Prec, Fmt^ = 'S');
             'p',
             'x': Len := FormatHexa(Buffer, Args[Index], Left, Width, Prec, LowerCaseHexa);
             'P',
             'X': Len := FormatHexa(Buffer, Args[Index], Left, Width, Prec, UpperCaseHexa);
           else
             Len := 0;
           end;
           Inc(Fmt);
           Inc(Result, Len);
           Inc(Index);
         end;
         Continue; // dont append "%"
       end;
       // append "%"
     end;
     if Buffer <> nil then
     begin
       Buffer^ := Fmt^;
       Inc(Buffer);
     end;
     Inc(Fmt);
     Inc(Result);
  end;
end;

function Format(const Msg: string; const Args: array of const): string;
var
  Len: Integer;
begin
  Len := FormatBuffer(nil, Pointer(Msg), Args);
  SetLength(Result, Len);
  FormatBuffer(Pointer(Result), Pointer(Msg), Args);
end;

procedure BSwap(var Value: Cardinal);
begin
  Value := Swap(Value) shl 16 + Swap(Value shr 16);
end;

function IntToStr(I: NativeInt): string;
var
  Str: AnsiString;
begin
  System.Str(I, Str);
  Result := string(Str);
end;

const
  HX: array[0..$F] of Char = '0123456789ABCDEF';

function IntToHex(I, Len: NativeInt): string;
begin
  SetLength(Result, Len);
  while Len > 0 do
  begin
    Result[Len] := HX[I and $F];
    Dec(Len);
    I := I shr 4;
  end;
end;

function strlen(str: PAnsiChar): Integer;
begin
  Result := 0;
  if str = nil then
    Exit;
  while str[Result] <> #0 do
    Inc(Result);
end;

procedure strncpy(target, source: PAnsiChar; max: Integer);
begin
  while (max > 0) do begin
    target^ := source^;
    Inc(target);
    if source^ <> #0 then
      Inc(source);
    Dec(max);
  end;
end;

procedure snprintf(buffer: PAnsiChar; len: Integer; fmt: PAnsiChar; const args: array of const);

var
  argc : Integer;
  count: Integer;
  prec : Integer;

  procedure FormatChar(const Value: TVarRec);
  begin
    case Value.VType of
      vtWideChar: Buffer^ := Value.VChar;
    else
      Buffer^ := '?';
    end;
    Inc(Buffer);
    Dec(Len);
  end;

  procedure FormatStr(const Value: TVarRec);
  var
    count: Integer;
    Str  : AnsiString;
  begin
    Str := '';
    case Value.VType of
      vtPChar        : Count := PAnsiCharLen(Value.VPChar);
      vtPWideChar    : Count := PWideCharLen(Value.VPWideChar);
      vtString       : Count := Length(PShortString(Value.VAnsiString)^);
      vtWideString   : Count := Length(WideString(Value.VWideString));
      vtAnsiString   : Count := Length(AnsiString(Value.VAnsiString));
      vtUnicodeString: Count := Length(string(Value.VUnicodeString));
      vtVariant      :
      begin
        Str := AnsiString(VariantToUnicodeString(TVarData(Value.VVariant^)));
        Count := Length(Str);
      end
    else
      Count := 0;
    end;
    if Count > len then
      Count := len;
    if Count = 0 then
      Exit;

    case Value.VType of
      vtPChar        : Str := AnsiString(string(Value.VPChar));
      vtPWideChar    : SetString(Str, PChar(Value.VPWideChar), Count);
      vtString       : Str := PShortString(Value.VAnsiString)^;
      vtWideString   : SetString(Str, PChar(Value.VWideString), Count);
      vtAnsiString   : Str := AnsiString(Value.VAnsiString);
      vtUnicodeString: SetString(Str, PChar(Value.VUnicodeString), Count);
    end;

    Move(Str[1], Buffer^, Count);
    Inc(Buffer, Count);
    Dec(Len, Count);
  end;

  procedure FormatDecimal(const Value: TVarRec; Signed: Boolean = True);
  var
    Count: Integer;
  begin
    case Value.VType of
      vtInteger : Count := IntLen(Value.VInteger, Signed);
      vtInt64   : Count := Int64Len(Value.VInt64^, Signed);
    else
      Count := 0;
    end;

    if Count > Len then
      Count := Len;

    if Count > 0 then
    begin
      case Value.VType of
        vtInteger : IntToBufA(Value.VInteger, Buffer, Count, Len, Signed);
        vtInt64   : Int64ToBufA(Value.VInt64^, Buffer, Count, Len, Signed);
      end;
      Inc(Buffer, Count);
      Dec(Len, Count);
    end;
  end;

  procedure FormatFloat(const Value: TVarRec; Prec: Integer);
  var
    Ext: Extended;
    Neg: Boolean;
    Int: Integer;
    Par: Integer;
    Mul: Integer;
    Str: AnsiString;
    Cnt: Integer;
  begin
    case Value.VType of
      vtExtended:
      begin
//        FloatToBufA(Value.VExtended^, Buffer, Prec
        Ext := Value.VExtended^;
        Neg := Ext < 0;
        if Neg then
          Ext := - Ext;
        Int := Trunc(Ext);
        Mul := 1;
        for Cnt := 1 to Prec do
          Mul := 10 * Mul;
        Par := Round((Ext - Int) * Mul);
        Str := IntToStr(Par);
        while Length(Str) < Prec do
          Str := '0' + Str;
        Str := IntToStr(Int) + '.' + Str;
        if Neg then
          Str := '-' + Str;
        Cnt := Length(Str);
        if Cnt > Len then
          Cnt := Len;
        Move(Str[1], Buffer^, Cnt);
        Inc(Buffer, Cnt);
        Dec(Len, Cnt);
      end;
    end;
  end;

  function GetInt(var P: PAnsiChar; var I: Integer): Boolean;
  begin
    Result := P^  in ['0'..'9'];
    if Result then
    begin
      I := Ord(P^) - Ord('0');
      Inc(P);
      while P^ in ['0'..'9'] do
      begin
        I := 10 * I + Ord(P^) - Ord('0');
        Inc(P);
      end;
    end;
  end;

begin
  argc := 0;
  while (len > 0) and (fmt^ <> #0) do
  begin
    if fmt^ = '\' then
    begin
      Inc(fmt);
      case fmt^ of
        'n':
        begin
          buffer^ := #10;
          Inc(fmt);
          Inc(buffer);
          Dec(len);
        end;
      end;
      Continue;
    end;
    if fmt^ = '%' then
    begin
      Inc(fmt);
      if fmt^ <> '%' then
      begin
        prec := -1;
        if fmt^ = '.' then
        begin
          Inc(fmt);
          getInt(fmt, prec);
        end;
        case fmt^ of
          'c':
          begin
            Inc(fmt);
            FormatChar(args[argc]);
            Inc(argc);
          end;
          's':
          begin
            Inc(fmt);
            FormatStr(args[argc]);
            Inc(argc);
          end;
          'd':
          begin
            Inc(fmt);
            FormatDecimal(args[argc]);
            Inc(argc);
          end;
          'f': // %.2f
          begin
            Inc(fmt);
            FormatFloat(args[argc], prec);
            Inc(argc);
          end;
        end;
        Continue;
      end;
    end;
    buffer^ := fmt^;
    Inc(buffer);
    Inc(fmt);
    Dec(len);
  end;
  if len = 0 then
    Dec(Buffer);
  buffer^ := #0;
end;

function skip(var buffer: PAnsiChar; char: AnsiChar): Boolean;
begin
  Result := buffer^ = char;
  if Result then
    Inc(buffer);
end;

function getFormatSize(var Buffer: PAnsiChar): Integer;
var
  Start: PAnsiChar;
begin
  start := Buffer;
  Result := 0;
  while (Buffer^ in ['0'..'9']) do
  begin
    Result := 10 * Result + Ord(Buffer^) - Ord('0');
    Inc(Buffer);
  end;
  if Buffer = Start then
    Result := -1;
end;

procedure scanBlanks(var source: PAnsiChar);
begin
  while source^ in [#9, #10, #13, ' '] do
    Inc(source);
end;

function scanInt(var source: PAnsiChar; target: PInteger): Boolean;
var
  start: PAnsiChar;
  neg: Boolean;
  value: Integer;
begin
  scanBlanks(source);
  neg := source^ = '-';
  if neg then
    Inc(source);
  start := source;
  value := 0;
  while source^ in ['0'..'9'] do
  begin
    value := 10 * value + ord(source^) - ord('0');
    Inc(source);
  end;
  Result := start <> source;
  if Result then
  begin
    if neg then
      target^ := - value
    else
      target^ := value;
  end;
end;

function scanFloat(var source: PAnsiChar; target: PSingle): Boolean;
var
  start: PAnsiChar;
  neg: Boolean;
  value: Single;
  decimal: Single;
begin
  scanBlanks(source);
  neg := source^ = '-';
  if neg then
    Inc(source);
  start := source;
  value := 0;
  while source^ in ['0'..'9'] do
  begin
    value := 10 * value + ord(source^) - ord('0');
    Inc(source);
  end;
  if source^ = '.' then
  begin
    Inc(source);
    decimal := 10;
    while source^ in ['0'..'9'] do
    begin
      value := value + (ord(source^) - ord('0')) / decimal;
      Inc(source);
      decimal := 10 * decimal;
    end;
  end;
  Result := start <> source;
  if Result then
  begin
    if neg then
      target^ := - value
    else
      target^ := value;
  end;
end;

function scanDouble(var source: PAnsiChar; target: PDouble): Boolean;
var
  start: PAnsiChar;
  neg: Boolean;
  value: Double;
  decimal: Double;
begin
  scanBlanks(source);
  neg := source^ = '-';
  if neg then
    Inc(source);
  start := source;
  value := 0;
  while source^ in ['0'..'9'] do
  begin
    value := 10 * value + ord(source^) - ord('0');
    Inc(source);
  end;
  if source^ = '.' then
  begin
    Inc(source);
    decimal := 10;
    while source^ in ['0'..'9'] do
    begin
      value := value + (ord(source^) - ord('0')) / decimal;
      Inc(source);
      decimal := 10 * decimal;
    end;
  end;
  Result := start <> source;
  if Result then
  begin
  if neg then
    target^ := - value
  else
    target^ := value;
end;
end;

procedure scanStr(var source: PAnsiChar; target: PAnsiChar; size: Integer);
begin
  scanBlanks(source);
  while (size <> 0) and (not (source^ in [#0, #9, #10, #13, ' '])) do
  begin
    target^ := source^;
    Inc(source);
    Inc(target);
    Dec(size);
  end;
  target^ := #0;
end;

procedure scanLN(var source: PAnsiChar; target: PAnsiChar; size: Integer);
begin
  scanBlanks(source);
  while (size <> 0) and (not (source^ in [#0, #10])) do
  begin
    target^ := source^;
    Inc(source);
    Inc(target);
    Dec(size);
  end;
  target^ := #0;
end;

function sscanf(buffer, format: PAnsiChar; vars: array of Pointer): Integer;
var
  pIndex: Integer;
  fSize : Integer;
begin
  Result := 0;
  pIndex := 0;
  while format^ <> #0 do
  begin
    case format^ of
      #9, #10, #13,' ': Inc(format);
      '%':
      begin
        Inc(format);
        fSize := getFormatSize(format);
        case format^ of
          'd': if not scanInt(buffer, PInteger(vars[pIndex])) then
                 Exit;
          'f': if not scanFloat(buffer, PSingle(vars[pIndex])) then
                 Exit;
          'l': begin
            Inc(format);
            case format^ of
              'f': if not scanDouble(buffer, PDouble(vars[pIndex])) then
            end;
          end;
          's': scanStr(buffer, PAnsiChar(vars[pIndex]), fSize);
          '[': // Quick hack for DelphiCraft
            if strcmp(format, '[^'#10']') = 0 then
            begin
              Inc(format, 3);
              scanLN(buffer, PansiChar(vars[pIndex]), fSize);
            end;
        end;
        Inc(format);
        Inc(pIndex);
        Inc(Result);
      end;
    else
      if not skip(buffer, format^) then
        Exit;
      Inc(format);
    end;
  end;
end;

function strcmp(buffer, value: PAnsiChar): Integer;
begin
  repeat
    Result := Ord(buffer^) - Ord(value^);
    if buffer^ = #0 then
      Break;
    if value^ = #0 then
      Break;
    Inc(buffer);
    Inc(value);
  until Result <> 0;
end;

procedure strncat(target, source: PAnsiChar; num: Integer);
begin
  while num > 0 do
  begin
    if source^ = #0 then
      Break;
    target^ := source^;
    Inc(target);
    Inc(source);
    Dec(num);
  end;
  target^ := #0;
end;

function atoi(const str: string): Integer;
var
  Index: Integer;
begin
  Result := 0;
  Index := 1;
  while (Index < Length(Str)) and (Str[Index] in ['0'..'9']) do
  begin
    Result := 10 * Result + Ord(Str[Index]) - Ord('0');
    Inc(Index);
  end;
end;

function FileCreate(const FileName: string; Mode: LongWord; Rights: Integer): THandle;
{$IFDEF MSWINDOWS}
const
  Exclusive: array[0..1] of LongWord = (
    CREATE_ALWAYS,
    CREATE_NEW);
  ShareMode: array[0..4] of LongWord = (
    0,
    0,
    FILE_SHARE_READ,
    FILE_SHARE_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE);
begin
  Result := INVALID_HANDLE_VALUE;
  if (Mode and $F0) <= fmShareDenyNone then
    Result := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
      ShareMode[(Mode and $F0) shr 4], nil, Exclusive[(Mode and $0004) shr 2], FILE_ATTRIBUTE_NORMAL, 0);
end;
{$ENDIF MSWINDOWS}

function FileOpen(const FileName: string; Mode: LongWord): THandle;
{$IFDEF MSWINDOWS}
const
  AccessMode: array[0..2] of LongWord = (
    GENERIC_READ,
    GENERIC_WRITE,
    GENERIC_READ or GENERIC_WRITE);
  ShareMode: array[0..4] of LongWord = (
    0,
    0,
    FILE_SHARE_READ,
    FILE_SHARE_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE);
begin
  Result := INVALID_HANDLE_VALUE;
  if ((Mode and 3) <= fmOpenReadWrite) and
    ((Mode and $F0) <= fmShareDenyNone) then
    Result := CreateFile(PChar(FileName), AccessMode[Mode and 3],
      ShareMode[(Mode and $F0) shr 4], nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
end;
{$ENDIF MSWINDOWS}

function FileRead(Handle: THandle; var Buffer; Count: LongWord): Integer;
begin
{$IFDEF MSWINDOWS}
  if not ReadFile(Handle, Buffer, Count, LongWord(Result), nil) then
    Result := -1;
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Result := __read(Handle, @Buffer, Count);
{$ENDIF POSIX}
end;

function FileSeek(Handle: THandle; Offset, Origin: Integer): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := SetFilePointer(Handle, Offset, nil, Origin);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Result := lseek(Handle, Offset, Origin);
{$ENDIF POSIX}
end;

function FileWrite(Handle: THandle; const Buffer; Count: LongWord): Integer;
begin
{$IFDEF MSWINDOWS}
  if not WriteFile(Handle, Buffer, Count, LongWord(Result), nil) then
    Result := -1;
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Result := __write(Handle, @Buffer, Count);
{$ENDIF POSIX}
end;

procedure FileClose(Handle: THandle);
begin
{$IFDEF MSWINDOWS}
  CloseHandle(Handle);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  __close(Handle); // No need to unlock since all locks are released on close.
{$ENDIF POSIX}
end;

function ExpandFileName(const FileName: string): string;
{$IFDEF MSWINDOWS}
var
  FName: PChar;
  Buffer: array[0..MAX_PATH - 1] of Char;
  Len: Integer;
begin
  Len := GetFullPathName(PChar(FileName), Length(Buffer), Buffer, FName);
  if Len <= Length(Buffer) then
    SetString(Result, Buffer, Len)
  else if Len > 0 then
  begin
    SetLength(Result, Len);
    Len := GetFullPathName(PChar(FileName), Len, PChar(Result), FName);
    if Len < Length(Result) then
      SetLength(Result, Len);
  end;
end;
{$ENDIF MSWINDOWS}

{ Exception }

constructor Exception.Create(const Msg: string);
begin
  FMessage := Msg;
end;

constructor Exception.CreateFmt(const Msg: string; const Args: array of const);
begin
  FMessage := Format(Msg, Args);
end;

{$IFDEF TEST}
procedure TestFormat(const Fmt: string; const Args: array of const);
var
  s1: string;
  s2: string;
begin
  s1 := System.SysUtils.Format(Fmt, Args);
  s2 := Format(Fmt, Args);
  WriteLn(' Format "', Fmt, '"');
  WriteLn('  SysUtils : (',Length(s1),') "', s1,'"');
  WriteLn('  Execute  : (',Length(s2),') "', s2,'"');
  if s1 <> s2 then
  begin
    WriteLn('*** ERROR ***');
  end;
end;

procedure TestPrintf(const Fmt: PAnsiChar; const Args: array of const; const Value: AnsiString);
var
  bf: array[0..511] of AnsiChar;
  st: AnsiString;
begin
  snprintf(bf, SizeOf(bf), Fmt, Args);
  st := bf;
  WriteLn('snprinf = ', st);
  WriteLn('expected = ', value);
  if st <> Value then
  begin
    WriteLn('*** ERROR *** ');
  end;
end;

procedure test;
var
  s1: PAnsiChar;
  s2: AnsiString;
  s3: PWideChar;
  s4: WideString;
  s5: string;
  s6: ShortString;
  s7: UTF8String;
  s8: Variant;
begin
  AllocConsole;
  WriteLn('----------------');
  TestFormat('%d', [1234]);
  TestFormat('%10d', [1234]);
  TestFormat('%-10d', [1234]);
  TestFormat('%.15d', [1234]);
  TestFormat('%10.15d', [1234]);
  TestFormat('%15.15d', [1234]);
  TestFormat('%-.15d', [1234]);
  TestFormat('%1:d', [1,2,3,4]);
  TestFormat('%-2.3d', [4]);
  TestFormat('%1:-*.*d', [1,2,3,4]);
  TestFormat('%*:-*.*d', [1,2,3,4]);

  TestFormat('%d', [-1]);
  TestFormat('%10d', [-1]);
  TestFormat('%-10d', [-1]);
  TestFormat('%.15d', [-1]);
  TestFormat('%10.15d', [-1]);
  TestFormat('%15.15d', [-1]);
  TestFormat('%-.15d', [-1]);

  TestFormat('%u', [-1]);
  TestFormat('%10u', [-1]);
  TestFormat('%-10u', [-1]);
  TestFormat('%.15u', [-1]);
  TestFormat('%10.15u', [-1]);
  TestFormat('%15.15u', [-1]);
  TestFormat('%-.15u', [-1]);

  TestFormat('%X', [1]);

  TestFormat('%X', [-1]);
  TestFormat('%10X', [-1]);
  TestFormat('%-10X', [-1]);
  TestFormat('%.15X', [-1]);
  TestFormat('%10.15X', [-1]);
  TestFormat('%15.15X', [-1]);
  TestFormat('%-.15X', [-1]);

  TestFormat('%X', [Int64(-1)]);

  s1 := 'PAnsiChar';
  s2 := 'AnsiString';
  s3 := 'PWideChar';
  s4 := 'WideString';
  s5 := 'string';
  s6 := 'ShortString';
  s7 := 'UTF8String';
  s8 := 'Variant';
  TestFormat('%s,%s,%s,%s,%s,%s,%s,%s', [s1, s2, s3, s4, s5, s6, s7, s8]);
  TestFormat('%S', [s1]);
  TestFormat('%p', [Pointer(s1)]);
  TestFormat('%15s', [s1]);
  TestFormat('%-15s', [s1]);
  TestFormat('%.5s', [s1]);
  TestFormat('%-.5s', [s1]);

  TestFormat('%.2f', [-0.14]);

  TestPrintf('%.2f', [123.456], '123.46');
  TestPrintf('%.2f', [-0.14], '-0.14');
  TestPrintf('%.2f', [-123.456], '-123.46');

end;
{$ENDIF}

{ TFileStream }

constructor TFileStream.Create(const AFileName: string; Mode: Integer);
var
  LShareMode: Word;
begin
  if (Mode and fmCreate = fmCreate) then
  begin
    LShareMode := Mode and $FF;
    if LShareMode = $FF then
      LShareMode := fmShareExclusive; // For compat in case $FFFF passed as Mode
    inherited Create(FileCreate(AFileName, LShareMode, 0));
    if FHandle = INVALID_HANDLE_VALUE then
      raise EFCreateError.CreateFmt(SFCreateErrorEx, [ExpandFileName(AFileName), SysErrorMessage(GetLastError)]);
  end else begin
    inherited Create(FileOpen(AFileName, Mode));
    if FHandle = INVALID_HANDLE_VALUE then
      raise EFOpenError.CreateFmt(SFOpenErrorEx, [ExpandFileName(AFileName), SysErrorMessage(GetLastError)]);
  end;
end;

destructor TFileStream.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    FileClose(FHandle);
  inherited Destroy;
end;

{ TStream }

function TStream.Read(var Buffer; Count: NativeInt): NativeInt;
begin
  Result := 0;
end;

procedure TStream.ReadBuffer(var Buffer; Count: NativeInt);
var
  LTotalCount,
  LReadCount: NativeInt;
begin
  LTotalCount := Read(Buffer, Count);

  if LTotalCount < 0 then
    raise EReadError.Create(SReadError);

  while (LTotalCount < Count) do
  begin
    LReadCount := Read(PByte(PByte(@Buffer) + LTotalCount)^, (Count - LTotalCount));
    if LReadCount <= 0 then
      raise EReadError.Create(SReadError);
    Inc(LTotalCount, LReadCount);
  end
end;


function TStream.ReadType<T>: T;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.Seek(Offset: NativeInt; Origin: TSeekOrigin): NativeInt;
begin
  Result := 0;
end;

function TStream.Write(const Buffer; Count: NativeInt): NativeInt;
begin
  Result := 0;
end;

procedure TStream.WriteBuffer(const Buffer; Count: NativeInt);
var
  LTotalCount,
  LWrittenCount: NativeInt;
begin
  LTotalCount := Write(Buffer, Count);
  if LTotalCount < 0 then
    raise EWriteError.Create(SWriteError);
  while (LTotalCount < Count) do
  begin
    LWrittenCount := Write(PByte(PByte(@Buffer) + LTotalCount)^, (Count - LTotalCount));
    if LWrittenCount <= 0 then
      raise EWriteError.Create(SWriteError)
    else
      Inc(LTotalCount, LWrittenCount);
  end
end;

{ THandleStream }

constructor THandleStream.Create(AHandle: THandle);
begin
  inherited Create;
  FHandle := AHandle;
end;

function THandleStream.Read(var Buffer; Count: NativeInt): NativeInt;
begin
  Result := FileRead(FHandle, Buffer, Count);
  if Result = -1 then Result := 0;
end;

function THandleStream.Seek(Offset: NativeInt; Origin: TSeekOrigin): NativeInt;
begin
  Result := FileSeek(FHandle, Offset, Ord(Origin));
end;

function THandleStream.Write(const Buffer; Count: NativeInt): NativeInt;
begin
  Result := FileWrite(FHandle, Buffer, Count);
  if Result = -1 then Result := 0;
end;

initialization
{$IFDEF TEST}
  test();
{$ENDIF}
end.
