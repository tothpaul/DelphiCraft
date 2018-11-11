unit Craft.Render;
{
  parts of Craft.main about rendering
}
interface
{$POINTERMATH ON}
uses
  System.Math,
  Execute.CrossGL,
  Execute.SysUtils,
  Craft.Config,
  Craft.Util,
  Craft.Matrix,
  Craft.Cube,
  Craft.Chunk,
  Craft.Item,
  Craft.Sign,
  Craft.Player;

type
  TAttrib = record
    &program : GLuint;
    position : GLuint;
    normal   : GLuint;
    uv       : GLuint;
    matrix   : GLuint;
    sampler  : GLuint;
    camera   : GLuint;
    timer    : GLuint;
    extra1   : GLuint;
    extra2   : GLuint;
    extra3   : GLuint;
    extra4   : GLuint;
  end;

function gen_crosshair_buffer(): GLuint;
function gen_player_buffer(x, y, z, rx, ry: Single): GLuint;
function gen_sky_buffer: GLuint;
procedure gen_sign_buffer(chunk :pChunk);

procedure draw_chunk(var attrib: TAttrib; chunk: pChunk);
procedure draw_signs(var attrib: TAttrib; chunk: pChunk);
procedure draw_sign(var attrib: TAttrib; buffer: GLuint; length: Integer);
procedure draw_player(var attrib: TAttrib; player :pPlayer);

procedure render_sky(var attrib: TAttrib; player: pPlayer; buffer: GLuint);
procedure render_wireframe(var attrib: TAttrib; player: pPlayer);
procedure render_crosshairs(var attrib: TAttrib);
procedure render_item(var attrib: TAttrib);
procedure render_text(var attrib: TAttrib; justify: Integer; x, y, n: Single; text: PAnsiChar);
function render_chunks(var attrib: TAttrib; player: PPlayer): Integer;
procedure render_signs(var attrib: TAttrib; player: pPlayer);
procedure render_sign(var attrib: TAttrib; player: pPlayer);
procedure render_players(var attrib: TAttrib; player: pPlayer);

implementation

uses
  Craft.Main;

function gen_crosshair_buffer(): GLuint;
var
  x, y, p: Integer;
  data: array[0..7] of Single;
begin
    x := g.width div 2;
    y := g.height div 2;
    p := 10 * g.scale;
    data[0] := x;
    data[1] := y - p;
    data[2] := x;
    data[3] := y + p;
    data[4] := x - p;
    data[5] := y;
    data[6] := x + p;
    data[7] := y;
    Result := gen_buffer(sizeof(data), @data);
end;

function gen_wireframe_buffer(x, y, z, n: Single): GLuint;
var
  data: array[0..71] of Single;
begin
  make_cube_wireframe(@data, x, y, z, n);
  Result := gen_buffer(sizeof(data), @data);
end;

function gen_sky_buffer: GLuint;
var
  data: array[0..12287] of single;
begin
  make_sphere(@data, 1, 3);
  Result := gen_buffer(SizeOf(data), @data);
end;

function gen_cube_buffer(x, y, z, n: Single; w: Integer): GLuint;
var
  data: pGLfloat;
  ao: tfloat_6_4;
const
  light: tfloat_6_4 = (
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5)
  );
begin
    data := malloc_faces(10, 6);
    FillChar(ao, SizeOf(ao), 0);
    make_cube(data, ao, light, True, True, True, True, True, True, x, y, z, n, w);
    Result := gen_faces(10, 6, data);
end;

function gen_plant_buffer(x, y, z, n: Single; w: Integer): GLuint;
var
  data: pGLfloat;
  ao: Single;
  light: Single;
begin
    data := malloc_faces(10, 4);
    ao := 0;
    light := 1;
    make_plant(data, ao, light, x, y, z, n, w, 45);
    Result := gen_faces(10, 4, data);
end;

function gen_player_buffer(x, y, z, rx, ry: Single): GLuint;
var
  data: pGLFloat;
begin
  data := malloc_faces(10, 6);
  make_player(data, x, y, z, rx, ry);
  Result := gen_faces(10, 6, data);
end;

function gen_text_buffer(x, y, n: Single; text: PAnsiChar): GLuint;
var
  length: Integer;
  data: pGLFloat;
  i: Integer;
begin
    length := strlen(text);
    data := malloc_faces(4, length);
    for i := 0 to length - 1 do begin
        make_character(data + i * 24, x, y, n / 2, n, text[i]);
        x := x + n;
    end;
    Result := gen_faces(4, length, data);
end;

function _gen_sign_buffer(
    data: pGLfloat; x, y, z: Single; face: Integer; text: PAnsiChar): Integer;
const
  glyph_dx: array[0..7] of Integer = (0, 0, -1, 1, 1, 0, -1, 0);
  glyph_dz: array[0..7] of Integer = (1, -1, 0, 0, 0, -1, 0, 1);
  line_dx : array[0..7] of Integer = (0, 0, 0, 0, 0, 1, 0, -1);
  line_dy : array[0..7] of Integer = (-1, -1, -1, -1, 0, 0, 0, 0);
  line_dz : array[0..7] of Integer = (0, 0, 0, 0, 1, 0, -1, 0);
  max_width = 64;
var
  count: Integer;
  line_height: Single;
  lines: array[0..1023] of AnsiChar;
  rows: Integer;
  dx, dz, ldx, ldy, ldz: Integer;
  n, sx, sy, sz: Single;
  key, line: PAnsiChar;
  length: Integer;
  line_width: Integer;
  rx, ry, rz: Single;
  i: Integer;
  width: Integer;
begin
    if (face < 0) or (face >= 8) then
    begin
        Exit(0);
    end;
    count := 0;
    line_height := 1.25;
    rows := wrap(text, max_width, lines, 1024);
    rows := MIN(rows, 5);
    dx := glyph_dx[face];
    dz := glyph_dz[face];
    ldx := line_dx[face];
    ldy := line_dy[face];
    ldz := line_dz[face];
    n := 1.0 / (max_width / 10);
    sx := x - n * (rows - 1) * (line_height / 2) * ldx;
    sy := y - n * (rows - 1) * (line_height / 2) * ldy;
    sz := z - n * (rows - 1) * (line_height / 2) * ldz;
    line := tokenize(lines, #10, key);
    while (line <> nil) do
    begin
        length := strlen(line);
        line_width := string_width(line);
        line_width := MIN(line_width, max_width);
        rx := sx - dx * line_width / max_width / 2;
        ry := sy;
        rz := sz - dz * line_width / max_width / 2;
        for i := 0 to length - 1 do
        begin
            width := char_width(line[i]);
            Dec(line_width, width);
            if (line_width < 0) then
            begin
                break;
            end;
            rx := rx + dx * width / max_width / 2;
            rz := rz + dz * width / max_width / 2;
            if (line[i] <> ' ') then
            begin
                make_character_3d(
                    @data[count * 30], rx, ry, rz, n / 2, face, line[i]);
                Inc(count);
            end;
            rx := rx + dx * width / max_width / 2;
            rz := rz + dz * width / max_width / 2;
        end;
        sx := sx + n * line_height * ldx;
        sy := sy + n * line_height * ldy;
        sz := sz + n * line_height * ldz;
        line := tokenize(nil, #10, key);
        Dec(rows);
        if (rows <= 0) then
        begin
            break;
        end;
    end;
    Result := count;
end;

procedure gen_sign_buffer(chunk :pChunk);
var
  signs: pSignList;
  max_faces: Integer;
  i: Integer;
  e: pSign;
  data: pGLfloat;
  faces: Integer;
begin
  signs := @chunk.signs;

  if signs.size = 0 then // Execute
    Exit;

  // first pass - count characters
  max_faces := 0;
  for i := 0 to signs.size - 1 do
  begin
      e := @signs.data[i];
      Inc(max_faces, strlen(e.text));
  end;

  // second pass - generate geometry
  data := malloc_faces(5, max_faces);
  faces := 0;
  for i := 0 to signs.size - 1 do
  begin
      e := @signs.data[i];
      Inc(faces, _gen_sign_buffer(
          @data[faces * 30], e.x, e.y, e.z, e.face, e.text));
  end;

  del_buffer(chunk.sign_buffer);
  chunk.sign_buffer := gen_faces(5, faces, data);
  chunk.sign_faces := faces;
end;

procedure draw_triangles_3d_ao(var attrib: TAttrib; buffer: GLuint; count: Integer);
begin
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glEnableVertexAttribArray(attrib.position);
    glEnableVertexAttribArray(attrib.normal);
    glEnableVertexAttribArray(attrib.uv);
    glVertexAttribPointer(attrib.position, 3, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 10, Pointer(0));
    glVertexAttribPointer(attrib.normal, 3, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 10, Pointer(sizeof(GLfloat) * 3));
    glVertexAttribPointer(attrib.uv, 4, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 10, Pointer(sizeof(GLfloat) * 6));
    glDrawArrays(GL_TRIANGLES, 0, count);
    glDisableVertexAttribArray(attrib.position);
    glDisableVertexAttribArray(attrib.normal);
    glDisableVertexAttribArray(attrib.uv);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure draw_triangles_3d_text(var attrib: TAttrib; buffer: GLuint; count: Integer);
begin
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glEnableVertexAttribArray(attrib.position);
    glEnableVertexAttribArray(attrib.uv);
    glVertexAttribPointer(attrib.position, 3, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 5, Pointer(0));
    glVertexAttribPointer(attrib.uv, 2, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 5, GLvoid(sizeof(GLfloat) * 3));
    glDrawArrays(GL_TRIANGLES, 0, count);
    glDisableVertexAttribArray(attrib.position);
    glDisableVertexAttribArray(attrib.uv);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure draw_triangles_3d(var attrib: TAttrib; buffer: GLuint; count: Integer);
begin
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  glEnableVertexAttribArray(attrib.position);
  glEnableVertexAttribArray(attrib.normal);
  glEnableVertexAttribArray(attrib.uv);
  glVertexAttribPointer(attrib.position, 3, GL_FLOAT, GL_FALSE,
      sizeof(GLfloat) * 8, nil);
  glVertexAttribPointer(attrib.normal, 3, GL_FLOAT, GL_FALSE,
      sizeof(GLfloat) * 8, GLvoid(sizeof(GLfloat) * 3));
  glVertexAttribPointer(attrib.uv, 2, GL_FLOAT, GL_FALSE,
      sizeof(GLfloat) * 8, GLvoid(sizeof(GLfloat) * 6));
  glDrawArrays(GL_TRIANGLES, 0, count);
  glDisableVertexAttribArray(attrib.position);
  glDisableVertexAttribArray(attrib.normal);
  glDisableVertexAttribArray(attrib.uv);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure draw_triangles_2d(var attrib: TAttrib; buffer: GLuint; count: Integer);
begin
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glEnableVertexAttribArray(attrib.position);
    glEnableVertexAttribArray(attrib.uv);
    glVertexAttribPointer(attrib.position, 2, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 4, Pointer(0));
    glVertexAttribPointer(attrib.uv, 2, GL_FLOAT, GL_FALSE,
        sizeof(GLfloat) * 4, Pointer(sizeof(GLfloat) * 2));
    glDrawArrays(GL_TRIANGLES, 0, count);
    glDisableVertexAttribArray(attrib.position);
    glDisableVertexAttribArray(attrib.uv);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure draw_lines(var attrib: TAttrib; buffer: GLuint; components, count: Integer);
begin
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glEnableVertexAttribArray(attrib.position);
    glVertexAttribPointer(
        attrib.position, components, GL_FLOAT, GL_FALSE, 0, Pointer(0));
    glDrawArrays(GL_LINES, 0, count);
    glDisableVertexAttribArray(attrib.position);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure draw_chunk(var attrib: TAttrib; chunk: pChunk);
begin
  draw_triangles_3d_ao(attrib, chunk.buffer, chunk.faces * 6);
end;

procedure draw_item(var attrib: TAttrib; buffer: GLuint; count: Integer);
begin
    draw_triangles_3d_ao(attrib, buffer, count);
end;

procedure draw_text(var attrib: TAttrib; buffer: GLuint; length: Integer);
begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    draw_triangles_2d(attrib, buffer, length * 6);
    glDisable(GL_BLEND);
end;

procedure draw_signs(var attrib: TAttrib; chunk: pChunk);
begin
  if chunk.sign_faces > 0 then begin // Execute
    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(-8, -1024);
    draw_triangles_3d_text(attrib, chunk.sign_buffer, chunk.sign_faces * 6);
    glDisable(GL_POLYGON_OFFSET_FILL);
  end;
end;

procedure draw_sign(var attrib: TAttrib; buffer: GLuint; length: Integer);
begin
    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(-8, -1024);
    draw_triangles_3d_text(attrib, buffer, length * 6);
    glDisable(GL_POLYGON_OFFSET_FILL);
end;

procedure draw_cube(var attrib: TAttrib; buffer: GLuint);
begin
    draw_item(attrib, buffer, 36);
end;

procedure draw_plant(var attrib: TAttrib; buffer: GLuint);
begin
    draw_item(attrib, buffer, 24);
end;

procedure draw_player(var attrib: TAttrib; player :pPlayer);
begin
    draw_cube(attrib, player.buffer);
end;

procedure render_sky(var attrib: TAttrib; player: pPlayer; buffer: GLuint);
var
  s: ^TState;
  matrix: array[0..15] of Single;
begin
  s := @player.state;
  set_matrix_3d(
    @matrix, g.width, g.height, 0, 0, 0, s.rx, s.ry, g.fov, 0, g.render_radius
  );
  glUseProgram(attrib.&program);
  glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
  glUniform1i(attrib.sampler, 2);
  glUniform1f(attrib.timer, time_of_day());
  draw_triangles_3d(attrib, buffer, 512 * 3);
end;

procedure render_wireframe(var attrib: TAttrib; player: pPlayer);
var
  s: pState;
  matrix: array[0..15] of Single;
  hx, hy, hz, hw: Integer;
  wireframe_buffer: GLuint;
begin
    s := @player.state;
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    hw := hit_test(0, s.x, s.y, s.z, s.rx, s.ry, &hx, &hy, &hz);
    if (is_obstacle(hw)) then begin
        glUseProgram(attrib.&program);
        glLineWidth(1);
        glEnable(GL_COLOR_LOGIC_OP);
        glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
        wireframe_buffer := gen_wireframe_buffer(hx, hy, hz, 0.53);
        draw_lines(attrib, wireframe_buffer, 3, 24);
        del_buffer(wireframe_buffer);
        glDisable(GL_COLOR_LOGIC_OP);
    end;
end;

procedure render_crosshairs(var attrib: TAttrib);
var
  matrix: array[0..15] of Single;
  crosshair_buffer: GLuint;
begin
    set_matrix_2d(@matrix, g.width, g.height);
    glUseProgram(attrib.&program);
    glLineWidth(4 * g.scale);
    glEnable(GL_COLOR_LOGIC_OP);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    crosshair_buffer := gen_crosshair_buffer();
    draw_lines(attrib, crosshair_buffer, 2, 4);
    del_buffer(crosshair_buffer);
    glDisable(GL_COLOR_LOGIC_OP);
end;

procedure render_item(var attrib: TAttrib);
var
  matrix: array[0..15] of Single;
  w: Integer;
  buffer: GLuint;
begin
    set_matrix_item(@matrix, g.width, g.height, g.scale);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform3f(attrib.camera, 0, 0, 5);
    glUniform1i(attrib.sampler, 0);
    glUniform1f(attrib.timer, time_of_day());
    w := items[g.item_index];
    if (is_plant(w)) then begin
        buffer := gen_plant_buffer(0, 0, 0, 0.5, w);
        draw_plant(attrib, buffer);
        del_buffer(buffer);
    end
    else begin
        buffer := gen_cube_buffer(0, 0, 0, 0.5, w);
        draw_cube(attrib, buffer);
        del_buffer(buffer);
    end;
end;

procedure render_text(
    var attrib: TAttrib; justify: Integer; x, y, n: Single; text: PAnsiChar);
var
  matrix: array[0..15] of Single;
  length: Integer;
  buffer: GLuint;
begin
    set_matrix_2d(@matrix, g.width, g.height);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform1i(attrib.sampler, 1);
    glUniform1i(attrib.extra1, 0);
    length := strlen(text);
    x := x - n * justify * (length - 1) / 2;
    buffer := gen_text_buffer(x, y, n, text);
    draw_text(attrib, buffer, length);
    del_buffer(buffer);
end;

function render_chunks(var attrib: TAttrib; player: PPlayer): Integer;
var
  s: pState;
  p: Integer;
  q: Integer;
  light: Single;
  matrix: array[0..15] of Single;
  planes: TPlanes;
  i: Integer;
  chunk: pChunk;
begin
    result := 0;
    s := @player.state;
    ensure_chunks(player);
    p := chunked(s.x);
    q := chunked(s.z);
    light := get_daylight();
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    frustum_planes(planes, g.render_radius, @matrix);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform3f(attrib.camera, s.x, s.y, s.z);
    glUniform1i(attrib.sampler, 0);
    glUniform1i(attrib.extra1, 2);
    glUniform1f(attrib.extra2, light);
    glUniform1f(attrib.extra3, g.render_radius * CHUNK_SIZE);
    glUniform1i(attrib.extra4, g.ortho);
    glUniform1f(attrib.timer, time_of_day());
    for i := 0 to g.chunk_count - 1 do
    begin
        chunk := @g.chunks[i];
        if (chunk_distance(chunk, p, q) > g.render_radius) then
        begin
            continue;
        end;
        if (0 = chunk_visible(
            planes, chunk.p, chunk.q, chunk.miny, chunk.maxy)) then
        begin
            continue;
        end;
        draw_chunk(attrib, chunk);
        Inc(result, chunk.faces);
    end;
end;

procedure render_signs(var attrib: TAttrib; player: pPlayer);
var
  s: pState;
  p, q: Integer;
  matrix: array[0..15] of Single;
  planes: TPlanes;
  i: Integer;
  chunk: pChunk;
begin
    s := @player.state;
    p := chunked(s.x);
    q := chunked(s.z);
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    frustum_planes(planes, g.render_radius, @matrix);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform1i(attrib.sampler, 3);
    glUniform1i(attrib.extra1, 1);
    for i := 0 to g.chunk_count - 1 do begin
        chunk := @g.chunks[i];
        if (chunk_distance(chunk, p, q) > g.sign_radius) then begin
            continue;
        end;
        if (0 = chunk_visible(
            planes, chunk.p, chunk.q, chunk.miny, chunk.maxy))
        then begin
            continue;
        end;
        draw_signs(attrib, chunk);
    end;
end;

procedure render_sign(var attrib: TAttrib; player: pPlayer);
var
  x, y, z, face: Integer;
  s: pState;
  matrix: array[0..15] of Single;
  text: array[0..MAX_SIGN_LENGTH - 1] of AnsiChar;
  data: pGLFloat;
  length: Integer;
  buffer: GLuint;
begin
    if (g.typing = 0) or (g.typing_buffer[0] <> CRAFT_KEY_SIGN) then begin
        Exit;
    end;
    if not hit_test_face(player, &x, &y, &z, &face) then begin
        Exit;
    end;
    s := @player.state;
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform1i(attrib.sampler, 3);
    glUniform1i(attrib.extra1, 1);
    strncpy(text, g.typing_buffer + 1, MAX_SIGN_LENGTH);
    text[MAX_SIGN_LENGTH - 1] := #0;
    data := malloc_faces(5, strlen(text));
    length := _gen_sign_buffer(data, x, y, z, face, text);
    buffer := gen_faces(5, length, data);
    draw_sign(attrib, buffer, length);
    del_buffer(buffer);
end;

procedure render_players(var attrib: TAttrib; player: pPlayer);
var
  s: pState;
  matrix: array[0..15] of Single;
  i: Integer;
  other: pPlayer;
begin
    s := @player.state;
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    glUseProgram(attrib.&program);
    glUniformMatrix4fv(attrib.matrix, 1, GL_FALSE, @matrix);
    glUniform3f(attrib.camera, s.x, s.y, s.z);
    glUniform1i(attrib.sampler, 0);
    glUniform1f(attrib.timer, time_of_day());
    for i := 0 to g.player_count - 1 do begin
        other := @g.players[i];
        if (other <> player) then begin
            draw_player(attrib, other);
        end;
    end;
end;

end.
