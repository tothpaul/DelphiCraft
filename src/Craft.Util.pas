unit Craft.Util;

interface

uses
  Execute.SysUtils,
  Execute.CrossGL,
  Execute.Textures,
  Execute.PNGLoader;

type
  tbool_27   = array[0..26] of Boolean;
  tbyte_27   = array[0..26] of Byte;
  tfloat_27  = array[0..26] of Single;
  tfloat_6_4 = array[0..5, 0..3] of Single;

function DEGREES(radians: Single): Single; inline;
function RADIANS(degrees: Single): Single; inline;

{
function MAX(a, b: Integer): Integer; overload;
function MAX(a, b: Single): Single; overload;
function MIN(a, b: Integer): Integer; overload;
function MIN(a, b: Single): Single; overload;
}

type
  TFPS = record
    fps    : Cardinal;
    frames : Cardinal;
    since  : Double;
  end;
  PFPS = ^TFPS;

procedure update_fps(fps: PFPS);

procedure load_png_texture(const AFileName: string);
function load_program(path1, path2: string): GLuint;

function gen_buffer(size: GLsizei; data: PSingle): GLuint;
procedure del_buffer(buffer: GLuint);
function malloc_faces(components, faces: Integer): pGLfloat;
function gen_faces(components, faces: Integer; data: pGLfloat): GLuint;

function strlen(s: PAnsiChar): Integer;
function strcpy(dst, src: PAnsiChar): PAnsiChar;

function tokenize(str, delim: PAnsiChar; var key: PAnsiChar): PAnsiChar;
function char_width(input: AnsiChar): Integer;
function string_width(input: PAnsiChar): Integer;
function wrap(input: PAnsiChar; max_width: Integer; output: PansiChar; max_length: Integer): Integer;

implementation

uses Neslib.glfw3;

procedure update_fps(fps: PFPS);
var
  now: Double;
  elapsed: Double;
begin
  Inc(fps.frames);
  now := glfwGetTime();
  elapsed := now - fps.since;
  if (elapsed >= 1) then begin
      fps.fps := round(fps.frames / elapsed);
      fps.frames := 0;
      fps.since := now;
  end;
end;

function DEGREES(radians: Single): Single;
begin
  Result := ((radians) * 180 / PI);
end;

function RADIANS(degrees: Single): Single;
begin
  Result := ((degrees) * PI / 180);
end;
{
function MAX(a, b: Integer): Integer;
begin
  if a > b then
    Result := a
  else
    Result := b;
end;

function MAX(a, b: Single): Single;
begin
  if a > b then
    Result := a
  else
    Result := b;
end;

function MIN(a, b: Integer): Integer;
begin
  if a < b then
    Result := a
  else
    Result := b;
end;

function MIN(a, b: Single): Single;
begin
  if a < b then
    Result := a
  else
    Result := b;
end;
}
function strlen(s: PAnsiChar): Integer;
begin
  Result := 0;
  while s[Result] <> #0 do
  begin
    Inc(Result);
  end;
end;

function strcpy(dst, src: PAnsiChar): PAnsiChar;
var
  c: AnsiChar;
begin
  repeat
    c := src^;
    Inc(src);
    dst^ := c;
    Inc(dst);
  until c = #0;
end;

function charpos(ch: AnsiChar; p: PAnsiChar): Integer;
begin
  Result := 0;
  while p[Result] <> #0 do
  begin
    if p[Result] = ch then
      Exit;
    Inc(Result);
  end;
  Result := -1;
end;

// Returns the length of the initial portion of str1 which consists only of characters that are part of str2.
function strspn(str1, str2: PAnsiChar): Integer;
begin
  Result := 0;
  while str1[Result] <> #0 do
  begin
    if charpos(str1[Result], str2) < 0 then
      Exit;
    Inc(Result);
  end;
end;

// Scans str1 for the first occurrence of any of the characters that are part of str2,
// returning the number of characters of str1 read before this first occurrence.
function strcspn(str1, str2: PAnsiChar): Integer;
begin
  Result := 0;
  while str1[Result] <> #0 do
  begin
    if charpos(str1[Result], str2) >= 0 then
      Exit;
    Inc(Result);
  end;
end;

function strncat(dst, src: PAnsiChar; num: Integer): PAnsiChar;
var
  i: Integer;
  c: AnsiChar;
begin
  Result := dst;
  while dst^ <> #0 do
    Inc(dst);
  for i := 0 to num do
  begin
    c := src^;
    dst^ := c;
    if c = #0 then
      break;
    Inc(src);
    Inc(dst);
  end;
  dst^ := #0;
end;

function load_file(path: string): AnsiString;
var
  f: file;
  l: Integer;
begin
  Assignfile(f, path);
  Reset(f, 1);
  l := filesize(f);
  SetLength(Result, l);
  BlockRead(f, Result[1], l);
  CloseFile(f);
end;

procedure load_png_texture(const AFileName: string);
var
  Texture: TTexture;
begin
  LoadPNG(AFileName, Texture);
//  Texture.SaveAsBitmap(AFileName + '.1.BMP');
  Texture.Flip;
//  Texture.SaveAsBitmap(AFileName + '.2.BMP');
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Texture.Width, Texture.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Pointer(Texture.Bytes));
end;

function make_shader(&type: GLenum; source: AnsiString): GLuint;
var
  status: GLint;
  length: GLint;
  src   : PGLchar;
  info  : string;
begin
  Result := glCreateShader(&type);
  length := System.Length(Source) - 1;
  src := PGLchar(source);
  glShaderSource(Result, 1, @src, @length);
  glCompileShader(Result);
  glGetShaderiv(Result, GL_COMPILE_STATUS, @status);
  if (status = GL_FALSE) then
  begin
    glGetShaderiv(Result, GL_INFO_LOG_LENGTH, @length);
    SetLength(info, length);
    glGetShaderInfoLog(Result, length, nil, Pointer(info));
    raise Exception.Create('glCompileShader failed : ' + info);
  end;
end;

function load_shader(&type: GLenum; path: string): GLuint;
var
  data: AnsiString;
begin
  data := load_file(path);
  Result := make_shader(&type, data);
end;

function make_program(shader1, shader2: GLuint ): GLuint;
var
  status: GLint;
  length: GLint;
  info  : AnsiString;
begin
  Result := glCreateProgram();
  glAttachShader(Result, shader1);
  glAttachShader(Result, shader2);
  glLinkProgram(Result);
  glGetProgramiv(Result, GL_LINK_STATUS, @status);
  if (status = GL_FALSE) then
  begin
    glGetProgramiv(Result, GL_INFO_LOG_LENGTH, @length);
    SetLength(info, length);
    glGetProgramInfoLog(Result, length, nil, PGLchar(info));
    raise Exception.Create('glLinkProgram failed: ' + string(info));
  end;
  glDetachShader(Result, shader1);
  glDetachShader(Result, shader2);
  glDeleteShader(shader1);
  glDeleteShader(shader2);
end;

function load_program(path1, path2: string): GLuint;
var
  shader1, shader2: GLuint;
begin
  shader1 := load_shader(GL_VERTEX_SHADER, path1);
  shader2 := load_shader(GL_FRAGMENT_SHADER, path2);
  Result := make_program(shader1, shader2);
end;

function gen_buffer(size: GLsizei; data: PSingle): GLuint;
begin
  glGenBuffers(1, @Result);
  glBindBuffer(GL_ARRAY_BUFFER, Result);
  glBufferData(GL_ARRAY_BUFFER, size, data, GL_STATIC_DRAW);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure del_buffer(buffer: GLuint);
begin
  glDeleteBuffers(1, @buffer);
end;

function malloc_faces(components, faces: Integer): pGLfloat;
begin
  Result := AllocMem(sizeof(GLfloat) * 6 * components * faces);
end;

function gen_faces(components, faces: Integer; data: pGLfloat): GLuint;
var
  buffer: GLuint;
begin
  buffer := gen_buffer(sizeof(GLfloat) * 6 * components * faces, data);
  FreeMem(data);
  Result := buffer;
end;

function tokenize(str, delim: PAnsiChar; var key: PAnsiChar): PAnsiChar;
begin
    if (str = nil) then
    begin
        str := key;
    end;
    Inc(str, strspn(str, delim));
    if (str^ = #0) then
      Exit(nil);
    result := str;
    Inc(str, strcspn(str, delim));
    if (str^ <> #0) then
    begin
      str^ := #0;
      Inc(str);
    end;
    key := str;
end;

function char_width(input: AnsiChar): Integer;
const
  lookup:array[0..127] of Integer = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        4, 2, 4, 7, 6, 9, 7, 2, 3, 3, 4, 6, 3, 5, 2, 7,
        6, 3, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 5, 6, 5, 7,
        8, 6, 6, 6, 6, 6, 6, 6, 6, 4, 6, 6, 5, 8, 8, 6,
        6, 7, 6, 6, 6, 6, 8,10, 8, 6, 6, 3, 6, 3, 6, 6,
        4, 7, 6, 6, 6, 6, 5, 6, 6, 2, 5, 5, 2, 9, 6, 6,
        6, 6, 6, 6, 5, 6, 6, 6, 6, 6, 6, 4, 2, 5, 7, 0
    );
begin
  if Ord(Input) > 127 then
  begin
    WriteLn('char_width overflow for ', input);
    Result := 0;
  end else begin
  Result := lookup[Ord(input)];
end;
end;

function string_width(input: PAnsiChar): Integer;
var
  length: Integer;
  i: Integer;
begin
    result := 0;
    length := strlen(input);
    for i := 0 to length - 1 do
    begin
        Inc(Result, char_width(input[i]));
    end;
end;

function wrap(input: PAnsiChar; max_width: Integer; output: PansiChar; max_length: Integer): Integer;
var
  text: PAnsiChar;
  space_width: Integer;
  line_number: Integer;
  key1, key2, line: PAnsiChar;
  line_width: Integer;
  token: PAnsiChar;
  token_width: Integer;
begin
    output^ := #0;
    GetMem(text, sizeof(Ansichar) * (strlen(input) + 1));
    strcpy(text, input);
    space_width := char_width(' ');
    line_number := 0;
    line := tokenize(text, #13#10, key1);
    while (line <> nil) do
    begin
        line_width := 0;
        token := tokenize(line, ' ', key2);
        while (token <> nil) do
        begin
            token_width := string_width(token);
            if (line_width <> 0) then
            begin
                if (line_width + token_width > max_width) then
                begin
                    line_width := 0;
                    Inc(line_number);
                    strncat(output, #10, max_length - strlen(output) - 1);
                end
                else begin
                    strncat(output, ' ', max_length - strlen(output) - 1);
                end;
            end;
            strncat(output, token, max_length - strlen(output) - 1);
            Inc(line_width, token_width + space_width);
            token := tokenize(nil, ' ', key2);
        end;
        Inc(line_number);
        strncat(output, #10, max_length - strlen(output) - 1);
        line := tokenize(nil, #13#10, key1);
    end;
    FreeMem(text);
    Result := line_number;
end;


end.
