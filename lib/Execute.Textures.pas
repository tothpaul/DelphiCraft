unit Execute.Textures;

interface

uses
  Execute.SysUtils;

type
  TTextureFormat = (
    tfLUMINANCE_8,
    tfLUMINACE_ALPHA_16,
    tfRGB_24,
    tfARGB_32
  );

  TTexture = record
    Width : Integer;
    Height: Integer;
    Format: TTextureFormat;
    BPP   : Integer;
    Bytes : array of Byte;
    procedure Setup(AWidth, AHeight: Integer; AFormat: TTextureFormat);
    procedure SaveAsBitmap(const AFileName: string);
    procedure Flip;
  end;
  PTexture = ^TTexture;

implementation

type
  TBitmap32 = packed record // 54 bytes
  // 14 header bytes
    bfType         : array[0..1] of AnsiChar;
    bfSize         : Integer;
    brReserved     : Integer;
    bgOffBits      : Integer;
  // 40 dib info
    biSize         : Integer; // 40
    biWidth        : Integer;
    biHeight       : Integer;
    biPlanes       : Word;    // 1
    biBitCount     : Word;    // 32
    biCompression  : Integer; // 0
    biSizeImage    : Integer; // 0
    biXPelsPerMeter: Integer;
    biYPelsPerMeter: Integer;
    biClrUsed      : Integer; // 0
    biClrImportant : Integer; // 0
  end;

{ TTexture }

procedure BGR2RGB(var AColor; ACount: NativeInt);
type
  TRGB = record
    r, g, b: Byte;
  end;
var
  Color: ^TRGB;
  Index: Integer;
  t: Byte;
begin
  Color := @AColor;
  for Index := 0 to ACount - 1 do
  begin
    t := Color.r;
    Color.r := Color.b;
    Color.b := t;
    Inc(Color);
  end;
end;

procedure ABGR2ARGB(var AColor; ACount: NativeInt);
var
  Color: PCardinal;
  Index: Integer;
begin
  Color := @AColor;
  for Index := 0 to ACount - 1 do
  begin
    Color^ := Color^ and $FF00FF00 + Color^ and $FF shl 16 + (Color^ shr 16) and $FF;
    Inc(Color);
  end;
end;

procedure TTexture.Flip;
var
  a, b: PByte;
  l: array of Byte;
begin
  a := @Bytes[0];
  b := @Bytes[BPP * Width * (Height - 1)];
  SetLength(l, BPP * Width);
  while b > a do
  begin
    move(a^, l[0], length(l));
    move(b^, a^, length(l));
    move(l[0], b^, length(l));
    Inc(a, BPP * Width);
    Dec(b, BPP * Width);
  end;
end;

procedure TTexture.SaveAsBitmap(const AFileName: string);
var
  Stream: TFileStream;
  Bitmap: TBitmap32;
  y     : NativeInt;
  Line  : array of Cardinal;
  BSize : Integer;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    Bitmap.bfType := 'BM';
    Bitmap.bfSize := BPP * Width * Height + SizeOf(Bitmap);
    Bitmap.brReserved := 0;
    Bitmap.bgOffBits := SizeOf(Bitmap);
    Bitmap.biSize := 40;
    Bitmap.biWidth := Width;
    Bitmap.biHeight := Height;
    Bitmap.biPlanes := 1;
    Bitmap.biBitCount :=  8 * BPP;
    Bitmap.biCompression := 0;
    Bitmap.biSizeImage := 0;
    Bitmap.biXPelsPerMeter := 0;
    Bitmap.biYPelsPerMeter := 0;
    if BPP = 1 then
    begin
      Bitmap.biClrUsed := 256;
    end else begin
      Bitmap.biClrUsed := 0;
    end;
    Bitmap.biClrImportant := 0;
    Stream.WriteBuffer(Bitmap, SizeOf(Bitmap));
    if BPP = 1 then // Grayscale
    begin
      SetLength(Line, 256);
      for y := 0 to 255 do
      begin
        Line[y] := $02000000 + y + y shl 8 + y shl 16;
      end;
      Stream.WriteBuffer(Line[0], 256 * SizeOf(Cardinal));
    end;
    SetLength(Line, Width);
    BSize := BPP * Width;
    BSize := 4 * ((BSize + 3) div 4);
    for y := Height - 1 downto 0 do
    begin
      Move(Bytes[BPP * Width * y], Line[0], BPP * Width);
      case BPP of
        3: BGR2RGB(Line[0], Width);
        4: ABGR2ARGB(Line[0], Width);
      end;
      Stream.WriteBuffer(Line[0], BSize);
    end;
  finally
    Stream.Free;
  end;
end;

procedure TTexture.Setup(AWidth, AHeight: Integer; AFormat: TTextureFormat);
begin
  if (Width = AWidth) and (Height = AHeight) and (Format = AFormat) then
    Exit;
  Width := AWidth;
  Height := AHeight;
  Format := AFormat;
  case Format of
    tfLUMINANCE_8       : BPP := 1;
    tfLUMINACE_ALPHA_16 : BPP := 2;
    tfRGB_24            : BPP := 3;
    tfARGB_32           : BPP := 4;
  end;
  SetLength(Bytes, Width * Height * BPP);
end;

end.
