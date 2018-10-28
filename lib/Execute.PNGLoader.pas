unit Execute.PNGLoader;

{
   PNGLoader for Delphi Tokyo (c)2017 by Execute SARL
   http://www.execute.fr
}

interface
{$IFOPT Q+}{$DEFINE QP}{$ENDIF}
uses
  Execute.SysUtils,
  Execute.Textures,
  Execute.Inflate;

procedure LoadPNG(const AFileName: string; var Texture: TTexture);

implementation

const
 // supported Chunks
  IHDR: array[0..3] of AnsiChar = 'IHDR'; // Image Header
  IEND: array[0..3] of AnsiChar = 'IEND'; // Image End
  PLTE: array[0..3] of AnsiChar = 'PLTE'; // Palette
  IDAT: array[0..3] of AnsiChar = 'IDAT'; // Image Data

 // Image Format
  COLOR_GRAYSCALE      = 0;
  COLOR_RGB            = 2; // support 2017.07.23
  COLOR_PALETTE        = 3;
  COLOR_GRAYSCALEALPHA = 4;
  COLOR_RGBA           = 6; // support 2017.07.22

 // Filter Mode
  FILTER_NONE    = 0; // support 2017.07.22
  FILTER_SUB     = 1; // support 2017.07.22
  FILTER_UP      = 2; // support 2017.07.22
  FILTER_AVERAGE = 3;
  FILTER_PAETH   = 4; // support 2017.07.22

type
  TPNGSignature = record
    PNG  : Cardinal;
    CRLF : Cardinal;
  end;

  TPNGHeader = packed record
    Width             : Cardinal;
    Height            : Cardinal;
    BitDepth          : Byte;
    ColorType         : Byte;
    CompressionMethod : Byte;
    FilterMethod      : Byte;
    InterlaceMethod   : Byte;
  end;

  TRGBColor = record
    R, G, B: Byte;
  end;
  TPalette = array of TRGBColor;

  TChunk = packed record
    Size: Cardinal;
    Name: Cardinal;
  end;

  TPNGContext = record
  private
    FStream   : TStream;     // source Stream
    FTexture  : PTexture;    // target Texture
    FHeader   : TPNGHeader;  // PNG header
    FChunk    : TChunk;      // current Chunk
    FPalette  : TPalette;    // PLTE chunk
    FLineSize : NativeInt;   // number of bytes per line in the decompressed stream (without Filter byte)
    FBPP      : NativeInt;   // number of byte per pixel (3, 4 or 0 for monochrome)
    FReadLine : NativeInt;
    FFilter   : Byte;
    FIndex    : NativeInt;
    procedure ReadChunk;
    procedure LoadIDAT;
    procedure ReadIDAT(var AData; ASize: NativeInt);
    procedure WriteTexture(const AData; ASize: NativeInt);
    procedure FilterRow;
  public
    procedure ReadHeader;
    procedure ReadChunks;
  end;

function Paeth(a, b, c: Byte): Byte;
// a = left, b = above, c = upper left
var
  pa, pb, pc: NativeInt;
begin
  pa := abs(b - c);
  pb := abs(a - c);
  pc := abs(a + b - 2 * c);
  if (pa <= pb) and (pa <= pc) then
    Exit(a);
  if pb <= pc then
    Result := b
  else
    Result := c;
end;

procedure TPNGContext.ReadChunk;
begin
  FStream.ReadBuffer(FChunk, SizeOf(FChunk));
  BSwap(FChunk.Size);
end;

procedure TPNGContext.ReadHeader;
var
  Sign  : TPNGSignature;
  Format: TTextureFormat;
begin
  // Signature is required
  FStream.ReadBuffer(Sign, SizeOf(Sign));
  // First chunk
  ReadChunk;
  if (Cardinal(Sign.PNG) <> $474E5089)
  or (Sign.CRLF <> $A1A0A0D)
  or (FChunk.Size <> SizeOf(FHeader))
  or (FChunk.Name <> Cardinal(IHDR)) then
    raise Exception.Create('Not a PNG file');
  // Read Header
  FStream.ReadBuffer(FHeader, SizeOf(FHeader));
  if (FHeader.CompressionMethod <> 0)
  or (FHeader.FilterMethod <> 0)
  or (FHeader.InterlaceMethod <> 0) then
    raise Exception.Create('Unsupported PNG');

  // Endianness
  BSwap(FHeader.Width);
  BSwap(FHeader.Height);

  case FHeader.BitDepth of
    1:
    case FHeader.ColorType of
      COLOR_GRAYSCALE,
      COLOR_PALETTE :
      begin
        FBPP := 0; // 1/8 - not used
        FLineSize := (FHeader.Width + 7) div 8;
        Format := tfLUMINANCE_8;
      end;
    else
      raise Exception.Create('Unsupported PNG ColorType = ' + IntToStr(FHeader.ColorType) + ' for BitDepth 1');
    end;
    8:
    begin
      case FHeader.ColorType of
        COLOR_GRAYSCALE      :
        begin
          FBPP := 1; // Grayscale
          Format := tfLUMINANCE_8;
        end;
        COLOR_PALETTE        :
        begin
          FBPP := 1; // Palette Index
          Format := tfRGB_24;
        end;
        COLOR_RGB            :
        begin
          FBPP := 3; // R, G, B
          Format := tfRGB_24;
        end;
        COLOR_RGBA           :
        begin
          FBPP := 4; // R, G, B, A
          Format := tfARGB_32;
        end;
        COLOR_GRAYSCALEALPHA :
        begin
          FBPP := 2; // Grayscale, Alpha
          Format := tfLUMINACE_ALPHA_16;
        end
      else
        raise Exception.Create('Unsupported PNG ColorType = ' + IntToStr(FHeader.ColorType) + ' for BitDepth 8');
      end;
      FLineSize := NativeInt(FHeader.Width) * FBPP;
    end;
  else
    raise Exception.Create('Unsupported PNG (BitDepth = ' + IntToStr(FHeader.BitDepth) + ')');
  end;

  FTexture.Setup(FHeader.Width, FHeader.Height, Format);

  // Skip Chunk CRC
  FStream.Seek(4, soFromCurrent);
end;

procedure TPNGContext.ReadChunks;
begin
  // Next Chunk
  ReadChunk;
  // while not Image End
  while FChunk.Name <> Cardinal(IEND) do
  begin
    // Found Image Data
    if FChunk.Name = Cardinal(IDAT) then
    begin
      LoadIDAT;
      // don't need to parse the remaining chunks
      Break;
    end;
    // Found Image Palette
    if FChunk.Name = Cardinal(PLTE) then
    begin
      if ((FChunk.Size mod 3) <> 0)  or (FChunk.Size > 3 * 256) then
        raise Exception.Create('Invalid PLTE chunk');
      SetLength(FPalette, FChunk.Size div 3);
      FStream.ReadBuffer(FPalette[0], FChunk.Size);
      FChunk.Size := 0; // consumed
    end;
    // skip unsupported Chunk + CRC
    FStream.Seek(FChunk.Size + 4, soFromCurrent);
    // Next Chunk
    ReadChunk;
  end;
end;

procedure TPNGContext.LoadIDAT;
begin
  FReadLine := 0;
  FIndex := 0;
  // skip GZIP Header
  Dec(FChunk.Size, 2);
  FStream.Seek(2, soFromCurrent);
  // deflate data
  InflateMethods(ReadIDAT, WriteTexture);
  // Filter last row
  FilterRow;
end;

procedure TPNGContext.ReadIDAT(var AData; ASize: NativeInt);
var
  Len : NativeInt;
begin
  while ASize > 0 do
  begin
    // need to read a new IDAT chunk
    if FChunk.Size = 0 then
    begin
      FStream.Seek(4, soFromCurrent); // CRC
      ReadChunk;
      if FChunk.Name <> Cardinal(IDAT) then
        raise Exception.Create('Out of IDAT chunk');
    end;
    Len := FChunk.Size;
    if Len > ASize then
      Len := ASize;
    FStream.ReadBuffer(AData, Len);
    Dec(ASize, Len);
    Dec(FChunk.Size, Len);
  end;
end;

procedure TPNGContext.WriteTexture(const AData; ASize: NativeInt);
var
  Source: PByte;
  Pixels: NativeInt;
begin
  Source := @AData;

  while ASize > 0 do
  begin
    // start of a new Line
    if FReadLine = 0 then
    begin
      // Filter previous row
      FilterRow;
      // Filter byte
      FFilter := Source^;
      Inc(Source);
      Dec(ASize);
    end;
    // output per line pixels
    if ASize > FReadLine then
      Pixels := FReadLine
    else
      Pixels := ASize;
    Move(Source^, FTexture.Bytes[FIndex], Pixels);
    // next position
    Inc(FIndex, Pixels);
    // move source
    Inc(Source, Pixels);
    // line progression
    Dec(FReadLine, Pixels);
    // Written bytes
    Dec(ASize, Pixels);
  end;
end;

procedure TPNGContext.FilterRow;
var
  Pixel  : PByte;
  Above  : PByte;
  x      : NativeInt;
  Left   : PByte;
  TopLeft: PByte;
  Color  : PByte;
begin
  // Bytes needed
  FReadLine := FLineSize;
  // do not filter the first line until it is loaded
  if FIndex = 0 then
    Exit;
  case FFilter of
    FILTER_NONE : { do nothing };
    FILTER_SUB  : // Pixel[x, y] := Pixel[x, y] + Pixel[x - 1, y]
    begin
      Pixel := @FTexture.Bytes[FIndex - FLineSize];
      Left := Pixel;
      // Ignore first Pixel
      Inc(Pixel, FBPP);
      for x := (FBPP * (NativeInt(FHeader.Width) - 1)) - 1 downto 0 do
      begin
      {$IFDEF QP}{$Q-}{$ENDIF}
        Inc(Pixel^, Left^);
      {$IFDEF QP}{$Q+}{$ENDIF}
        Inc(Pixel);
        Inc(Left);
      end;
    end;
    FILTER_UP   :  // Pixel[x, y] := Pixel[x, y] + Pixel[x, y - 1]
    begin
      if FIndex = FLineSize then // do not filter first line
        Exit;
      Pixel := @FTexture.Bytes[FIndex - FLineSize];
      Above := Pixel;
      Dec(Above, FLineSize);
      for x := (FBPP * NativeInt(FHeader.Width)) - 1 downto 0 do
      begin
      {$IFDEF QP}{$Q-}{$ENDIF}
        Inc(Pixel^, Above^);
      {$IFDEF QP}{$Q+}{$ENDIF}
        Inc(Pixel);
        Inc(Above);
      end;
    end;
    FILTER_AVERAGE:  // Pixel[x, y] := Pixel[x, y] + (Pixel[x - 1, y] + Pixel[x, y - 1]) div 2
    begin
      Pixel := @FTexture.Bytes[FIndex - FLineSize];
      Left := Pixel;
      if FIndex = FLineSize then // special case, first line
      begin
        Inc(Pixel, FBPP);
        for x := (FBPP * (NativeInt(FHeader.Width) - 1)) - 1 downto 0 do
        begin
          Inc(Pixel^, Left^ div 2);
          Inc(Pixel);
          Inc(Left);
        end;
      end else begin
        Above := Pixel;
        Dec(Above, FLineSize);
        for x := FBPP - 1 downto 0 do  // special case, first pixel
        begin
          Inc(Pixel^, Above^ div 2);
          Inc(Pixel);
          Inc(Above);
        end;
        for x := (FBPP * (NativeInt(FHeader.Width) - 1)) - 1 downto 0 do
        begin
          Inc(Pixel^, (Above^ + Left^) div 2);
          Inc(Pixel);
          Inc(Above);
          Inc(Left);
        end;
      end;
    end;
    FILTER_PAETH: // Pixel[x, y] := Pixel[x, y] + Paeth(Pixel[x - 1, y], Pixel[x, y - 1], Pixel[x - 1, y - 1])
    begin
      Pixel := @FTexture.Bytes[FIndex - FLineSize];
      Left := Pixel;
      if FIndex = FLineSize then // first line
      begin
        Inc(Pixel, FBPP);
        for x := (FBPP * (NativeInt(FHeader.Width) - 1)) - 1 downto 0 do
        begin
          Inc(Pixel^, Paeth(Left^, 0, 0));
          Inc(Pixel);
          Inc(Left);
        end;
      end else begin
        Above := Pixel;
        Dec(Above, FLineSize);
        TopLeft := Above;
        for x := FBPP - 1 downto 0 do // first pixel
        begin
        {$IFDEF QP}{$Q-}{$ENDIF}
          Inc(Pixel^, Paeth(0, Above^, 0));
        {$IFDEF QP}{$Q+}{$ENDIF}
          Inc(Pixel);
          Inc(Above);
        end;
        // rest of the line
        for x := (FBPP * (NativeInt(FHeader.Width) - 1)) - 1 downto 0 do
        begin
        {$IFDEF QP}{$Q-}{$ENDIF}
          Inc(Pixel^, Paeth(Left^, Above^, TopLeft^));
        {$IFDEF QP}{$Q+}{$ENDIF}
          Inc(Pixel);
          Inc(Left);
          Inc(Above);
          Inc(TopLeft);
        end;
      end;
    end;
  else
    raise Exception.Create('Unknow Filter ' + IntToStr(FFilter));
  end;
  if Length(FPalette) > 0 then
  begin
    Color := @FTexture.Bytes[FIndex];
    Pixel := @FTexture.Bytes[FIndex - FLineSize + 3 * NativeInt(FHeader.Width)];
    for x := 0 to FLineSize - 1 do
    begin
      Dec(Pixel, 3);
      Move(FPalette[Color^], Pixel^, 3);
      Dec(Color);
    end;
  end;
end;

procedure LoadPNG(const AFileName: string; var Texture: TTexture);
var
  Context: TPNGContext;
begin
  Context.FStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Context.FTexture := @Texture;
    Context.ReadHeader;
    Context.ReadChunks;
  finally
    Context.FStream.Free;
  end;
end;

end.
