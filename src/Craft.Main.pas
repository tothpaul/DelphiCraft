unit Craft.Main;

interface
{$POINTERMATH ON}
uses
  Execute.CrossGL,
  Execute.SysUtils,
  Neslib.glfw3,
  Winapi.Windows,
  System.Math,
  MarcusGeelnard.TinyCThread,
  CaseyDuncan.noise,
  Craft.Map,
  Craft.Item,
  Craft.Sign,
  Craft.db,
  Craft.Client,
  Craft.Config,
  Craft.World,
  Craft.Chunk,
  Craft.Player,
  Craft.Auth,
  Craft.Render;

const
  MAX_CHUNKS = 8192;
  MAX_PLAYERS = 128;
  WORKERS = 4;
  MAX_TEXT_LENGTH = 256;
  MAX_PATH_LENGTH = 256;
  MAX_ADDR_LENGTH = 256;

  ALIGN_LEFT = 0;
  ALIGN_CENTER = 1;

  MODE_OFFLINE = 0;
  MODE_ONLINE  = 1;

  WORKER_IDLE = 0;
  WORKER_BUSY = 1;
  WORKER_DONE = 2;

type
  TWorkerItem = record
    p          : Integer;
    q          : Integer;
    load       : Integer;
    block_maps : array[0..2,0..2] of pMap;
    light_maps : array[0..2,0..2] of pMap;
    miny       : Integer;
    maxy       : Integer;
    faces      : Integer;
    data       : pGLFloat;
  end;
  pWorkerItem = ^TWorkerItem;

  TWorker = record
    index : Integer;
    state : Integer;
    thrd  : thrd_t;
    mtx   : mtx_t;
    cnd   : cnd_t;
    item  : TWorkerItem;
  end;
  pWorker = ^TWorker;

  TBlock = record
    x: Integer;
    y: Integer;
    z: Integer;
    w: Integer;
  end;
  pBlock = ^TBlock;

  TModel = record
    window        : pGLFWwindow;
    Workers       : array[0..WORKERS - 1] of TWorker;
    Chunks        : array[0..MAX_CHUNKS - 1] of TChunk;
    chunk_count   : Integer;
    create_radius : Integer;
    render_radius : Integer;
    delete_radius : Integer;
    sign_radius   : Integer;
    players       : array[0..MAX_PLAYERS - 1] of TPlayer;
    player_count  : Integer;
    typing        : Integer;
    typing_buffer : array[0..MAX_TEXT_LENGTH] of AnsiChar;
    message_index : Integer;
    messages      : array[0..MAX_MESSAGES - 1, 0.. MAX_TEXT_LENGTH - 1] of AnsiChar;
    width         : Integer;
    height        : Integer;
    observe1      : Integer;
    observe2      : Integer;
    flying        : Integer;
    item_index    : Integer;
    scale         : Integer;
    ortho         : Integer;
    fov           : Single;
    suppress_char : Integer;
    mode          : Integer;
    mode_changed  : Integer;
    db_path       : array[0..MAX_PATH_LENGTH - 1] of AnsiChar;
    server_addr   : array[0..MAX_ADDR_LENGTH - 1] of AnsiChar;
    server_port   : Integer;
    day_length    : Integer;
    time_changed  : Integer;
    block0        : TBlock;
    block1        : TBlock;
    copy0         : TBlock;
    copy1         : TBlock;
  end;


var
  g: TModel;

function main(): Integer;
function time_of_day: Single;
function get_daylight(): Single;
function hit_test(
    previous: Integer; x, y, z, rx, ry: Single;
    var bx, by, bz: Integer): Integer;
function hit_test_face(player: pPlayer; var x, y, z, face: Integer): Boolean;
procedure get_sight_vector(rx, ry: Single; var vx, vy, vz: Single);
procedure ensure_chunks(player: pPlayer);

implementation

uses
  Craft.Util, Craft.Cube, Craft.Matrix;

function time_of_day: Single;
begin
  if (g.day_length <= 0) then
  begin
    Exit(0.5);
  end;
  Result := glfwGetTime();
  Result := Result / g.day_length;
  Result := Result - Int(Result);
end;

function get_daylight(): Single;
var
  timer, t: Single;
begin
    timer := time_of_day();
    if (timer < 0.5) then begin
        t := (timer - 0.25) * 100;
        Result := 1 / (1 + Power(2, -t));
    end
    else begin
        t := (timer - 0.85) * 100;
        Result := 1 - 1 / (1 + Power(2, -t));
    end;
end;

function get_scale_factor(): Integer;
var
  window_width, window_height: Integer;
  buffer_width, buffer_height: Integer;
begin
  glfwGetWindowSize(g.window, @window_width, @window_height);
  glfwGetFramebufferSize(g.window, @buffer_width, @buffer_height);
  Result := buffer_width div window_width;
  result := MAX(1, result);
  result := MIN(2, result);
end;

procedure get_sight_vector(rx, ry: Single; var vx, vy, vz: Single);
var
  m: Single;
begin
    m := cos(ry);
    vx := cos(rx - RADIANS(90)) * m;
    vy := sin(ry);
    vz := sin(rx - RADIANS(90)) * m;
end;

procedure get_motion_vector(flying, sz, sx: Integer; rx, ry: Single;
    var vx, vy, vz: Single);
var
  strafe: Single;
  m, y: Single;
begin
    vx := 0; vy := 0; vz := 0;
    if (sz = 0) and (sx = 0) then begin
        Exit;
    end;
    strafe := arctan2(sz, sx);
    if (flying <> 0) then begin
        m := cos(ry);
        y := sin(ry);
        if (sx <> 0) then begin
            if (sz = 0) then begin
                y := 0;
            end;
            m := 1;
        end;
        if (sz > 0) then begin
            y := -y;
        end;
        vx := cos(rx + strafe) * m;
        vy := y;
        vz := sin(rx + strafe) * m;
    end
    else begin
        vx := cos(rx + strafe);
        vy := 0;
        vz := sin(rx + strafe);
    end;
end;

function highest_block(x, z: Single): Integer;
var
  nx, nz, p, q: Integer;
  chunk: pChunk;
  map: pMap;
  return: Integer;
begin
    return := -1;
    nx := round(x);
    nz := round(z);
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk <> nil) then begin
        map := @chunk.map;
        MAP_FOR_EACH(map, procedure (ex, ey, ez, ew: Integer)
        begin
            if is_obstacle(ew) and (ex = nx) and (ez = nz) then begin
                return := MAX(return, ey);
            end;
        end);
    end;
    Result := return;
end;


procedure request_chunk(p, q: Integer);
var
  key: Integer;
begin
  key := db_get_key(p, q);
  client_chunk(p, q, key);
end;

function _hit_test(
    map: pMap; max_distance: Single; previous: Integer;
    x, y, z,
    vx, vy, vz: Single;
    var hx, hy, hz: Integer): Integer;
var
  m, px, py, pz, i: Integer;
  nx, ny, nz: Integer;
  hw: Integer;
begin
    m := 32;
    px := 0;
    py := 0;
    pz := 0;
    for i := 0 to Round(max_distance * m) - 1 do begin
        nx := round(x);
        ny := round(y);
        nz := round(z);
        if (nx <> px) or (ny <> py) or (nz <> pz) then begin
            hw := map_get(map, nx, ny, nz);
            if (hw > 0) then begin
                if (previous <> 0) then begin
                    hx := px; hy := py; hz := pz;
                end
                else begin
                    hx := nx; hy := ny; hz := nz;
                end;
                Exit(hw);
            end;
            px := nx; py := ny; pz := nz;
        end;
        x := x + vx / m; y := y + vy / m; z := z + vz / m;
    end;
    Result := 0;
end;

function hit_test(
    previous: Integer; x, y, z, rx, ry: Single;
    var bx, by, bz: Integer): Integer;
var
  best: Single;
  p, q: Integer;
  vx, vy, vz: Single;
  i: Integer;
  chunk: pChunk;
  hx, hy, hz, hw: Integer;
  d: Single;
begin
  Result := 0;
  best := 0;
  p := chunked(x);
  q := chunked(z);
  get_sight_vector(rx, ry, vx, vy, vz);
  for i := 0 to g.chunk_count - 1 do begin
        chunk := @g.chunks[i];
        if (chunk_distance(chunk, p, q) > 1) then begin
            continue;
        end;
        hw := _hit_test(@chunk.map, 8, previous,
            x, y, z, vx, vy, vz, hx, hy, hz);
        if (hw > 0) then begin
            d := sqrt(
                power(hx - x, 2) + power(hy - y, 2) + power(hz - z, 2));
            if (best = 0) or (d < best) then begin
                best := d;
                bx := hx; by := hy; bz := hz;
                result := hw;
            end;
        end;
    end;
end;

function hit_test_face(player: pPlayer; var x, y, z, face: Integer): Boolean;
var
  s: pState;
  w: Integer;
  hx, hy, hz: Integer;
  dx, dy, dz: Integer;
  _degrees: Integer;
  top: Integer;
begin
    s := @player.state;
    w := hit_test(0, s.x, s.y, s.z, s.rx, s.ry, x, y, z);
    if (is_obstacle(w)) then begin
        hit_test(1, s.x, s.y, s.z, s.rx, s.ry, hx, hy, hz);
        dx := hx - x;
        dy := hy - y;
        dz := hz - z;
        if (dx = -1) and (dy = 0) and (dz = 0) then begin
            face := 0; Exit(True);
        end;
        if (dx = 1) and (dy = 0) and (dz = 0) then begin
            face := 1; Exit(True);
        end;
        if (dx = 0) and (dy = 0) and (dz = -1) then begin
            face := 2; Exit(True);
        end;
        if (dx = 0) and (dy = 0) and (dz = 1) then begin
            face := 3; Exit(True);
        end;
        if (dx = 0) and (dy = 1) and (dz = 0) then begin
            _degrees := round(DEGREES(arctan2(s.x - hx, s.z - hz)));
            if (_degrees < 0) then begin
                Inc(_degrees, 360);
            end;
            top := Trunc((_degrees + 45) / 90) mod 4;
            face := 4 + top; Exit(True);
        end;
    end;
    Result := False;
end;

function collide(height: Integer; var x,  y, z: Single): Integer;
var
  p, q: Integer;
  chunk: pChunk;
  map: pMap;
  nx, ny, nz: Integer;
  px, py, pz: Single;
  pad: Single;
  dy: Integer;
begin
    result := 0;
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk = nil) then begin
        Exit;
    end;
    map := @chunk.map;
    nx := round(x);
    ny := round(y);
    nz := round(z);
    px := x - nx;
    py := y - ny;
    pz := z - nz;
    pad := 0.25;
    for dy := 0 to height - 1 do begin
        if (px < -pad) and (is_obstacle(map_get(map, nx - 1, ny - dy, nz))) then begin
            x := nx - pad;
        end;
        if (px > pad) and (is_obstacle(map_get(map, nx + 1, ny - dy, nz))) then begin
            x := nx + pad;
        end;
        if (py < -pad) and (is_obstacle(map_get(map, nx, ny - dy - 1, nz))) then begin
            y := ny - pad;
            result := 1;
        end;
        if (py > pad) and (is_obstacle(map_get(map, nx, ny - dy + 1, nz))) then begin
            y := ny + pad;
            result := 1;
        end;
        if (pz < -pad) and (is_obstacle(map_get(map, nx, ny - dy, nz - 1))) then begin
            z := nz - pad;
        end;
        if (pz > pad) and (is_obstacle(map_get(map, nx, ny - dy, nz + 1))) then begin
            z := nz + pad;
        end;
    end;
end;

function player_intersects_block(
    height: Integer;
    x, y, z: Single;
    hx, hy, hz: Integer): Boolean;
var
  nx, ny, nz, i: Integer;
begin
    nx := round(x);
    ny := round(y);
    nz := round(z);
    for i := 0 to height - 1 do begin
        if (nx = hx) and (ny - i = hy) and (nz = hz) then begin
            Exit(True);
        end;
    end;
    Result := False;
end;

procedure occlusion(
    var neighbors: tbool_27; var lights: tbyte_27; shades: tfloat_27;
    var ao, light: tfloat_6_4);
const
  lookup3: array[0..5, 0..3, 0..2] of Integer = (
        ((0, 1, 3), (2, 1, 5), (6, 3, 7), (8, 5, 7)),
        ((18, 19, 21), (20, 19, 23), (24, 21, 25), (26, 23, 25)),
        ((6, 7, 15), (8, 7, 17), (24, 15, 25), (26, 17, 25)),
        ((0, 1, 9), (2, 1, 11), (18, 9, 19), (20, 11, 19)),
        ((0, 3, 9), (6, 3, 15), (18, 9, 21), (24, 15, 21)),
        ((2, 5, 11), (8, 5, 17), (20, 11, 23), (26, 17, 23))
    );
   lookup4: array[0..5, 0..3, 0..3] of Integer = (
        ((0, 1, 3, 4), (1, 2, 4, 5), (3, 4, 6, 7), (4, 5, 7, 8)),
        ((18, 19, 21, 22), (19, 20, 22, 23), (21, 22, 24, 25), (22, 23, 25, 26)),
        ((6, 7, 15, 16), (7, 8, 16, 17), (15, 16, 24, 25), (16, 17, 25, 26)),
        ((0, 1, 9, 10), (1, 2, 10, 11), (9, 10, 18, 19), (10, 11, 19, 20)),
        ((0, 3, 9, 12), (3, 6, 12, 15), (9, 12, 18, 21), (12, 15, 21, 24)),
        ((2, 5, 11, 14), (5, 8, 14, 17), (11, 14, 20, 23), (14, 17, 23, 26))
    );
    curve: array[0..3] of Single = (0.0, 0.25, 0.5, 0.75);
var
  i, j: Integer;
  corner, side1, side2, value: Integer;
  shade_sum, light_sum: Single;
  is_light: Boolean;
  k: Integer;
  total: Single;
begin
    for i := 0 to 5 do begin
        for j := 0 to 3 do begin
            corner := Ord(neighbors[lookup3[i][j][0]]);
            side1 := Ord(neighbors[lookup3[i][j][1]]);
            side2 := Ord(neighbors[lookup3[i][j][2]]);
            //int value = side1 && side2 ? 3 : corner + side1 + side2;
            if (side1 <> 0) and (side2 <> 0) then
              value := 3
            else
              value := corner + side1 + side2;
            shade_sum := 0;
            light_sum := 0;
            is_light := lights[13] = 15;
            for k := 0 to 3 do begin
                shade_sum := shade_sum + shades[lookup4[i][j][k]];
                light_sum := light_sum + lights[lookup4[i][j][k]];
            end;
            if (is_light) then begin
                light_sum := 15 * 4 * 10;
            end;
            total := curve[value] + shade_sum / 4.0;
            ao[i][j] := MIN(total, 1.0);
            light[i][j] := light_sum / 15.0 / 4.0;
        end;
    end;
end;

const
  XZ_SIZE = CHUNK_SIZE * 3 + 2;
  XZ_LO   = CHUNK_SIZE;
  XZ_HI   = CHUNK_SIZE * 2 + 1;
  Y_SIZE  = 258;
//#define XYZ(x, y, z) ((y) * XZ_SIZE * XZ_SIZE + (x) * XZ_SIZE + (z))
function XYZ(x, y, z: Integer): Integer; begin Result := y * XZ_SIZE * XZ_SIZE + x * XZ_SIZE + z; end;
//#define XZ(x, z) ((x) * XZ_SIZE + (z))
function XZ(x, z: Integer): Integer; begin Result := x * XZ_SIZE + z; end;

procedure light_fill(
    opaque: PBoolean; light: PByte;
    x, y, z, w, force: Integer);
begin
    if (x + w < XZ_LO) or (z + w < XZ_LO) then begin
        Exit;
    end;
    if (x - w > XZ_HI) or (z - w > XZ_HI) then begin
        Exit;
    end;
    if (y < 0) or (y >= Y_SIZE) then begin
        Exit;
    end;
    if (light[XYZ(x, y, z)] >= w) then begin
        Exit;
    end;
    if (force = 0) and (opaque[XYZ(x, y, z)]) then begin
        Exit;
    end;
    light[XYZ(x, y, z)] := w; Dec(w);
    light_fill(opaque, light, x - 1, y, z, w, 0);
    light_fill(opaque, light, x + 1, y, z, w, 0);
    light_fill(opaque, light, x, y - 1, z, w, 0);
    light_fill(opaque, light, x, y + 1, z, w, 0);
    light_fill(opaque, light, x, y, z - 1, w, 0);
    light_fill(opaque, light, x, y, z + 1, w, 0);
end;


procedure compute_chunk(item: pWorkerItem);
var
  opaque : PBoolean;
  light  : PByte;
  highest: PWord;
  ox, oy, oz: Integer;
  has_light: Integer;
  a, b: Integer;
  map: pMap;
  miny, maxy: Integer;
  faces: Integer;
  data: pGLfloat;
  offset: Integer;

begin
    opaque := AllocMem(XZ_SIZE * XZ_SIZE * Y_SIZE * SizeOf(Boolean));
    light := AllocMem(XZ_SIZE * XZ_SIZE * Y_SIZE);
    highest := AllocMem(XZ_SIZE * XZ_SIZE* SizeOf(Word));

    ox := item.p * CHUNK_SIZE - CHUNK_SIZE - 1;
    oy := -1;
    oz := item.q * CHUNK_SIZE - CHUNK_SIZE - 1;

    // check for lights
    has_light := 0;
    if (SHOW_LIGHTS <> 0) then begin
        for a := 0 to 2 do begin
            for b := 0 to 2 do begin
                map := item.light_maps[a][b];
                if (map <> nil) and (map.size <> 0) then begin
                    has_light := 1;
                end;
            end;
        end;
    end;

    // populate opaque array
    for a := 0 to 2 do begin
        for b := 0 to 2 do begin
            map := item.block_maps[a][b];
            if (map = nil) then begin
                continue;
            end;
            MAP_FOR_EACH(map, procedure(ex, ey, ez, ew: Integer)
            var
                x, y, z, w: Integer;
            begin
                x := ex - ox;
                y := ey - oy;
                z := ez - oz;
                w := ew;
                // TODO: this should be unnecessary
                if (x < 0) or (y < 0) or (z < 0) then begin
                    Exit;//continue;
                end;
                if (x >= XZ_SIZE) or (y >= Y_SIZE) or (z >= XZ_SIZE) then begin
                    Exit;//continue;
                end;
                // END TODO
                opaque[XYZ(x, y, z)] := not is_transparent(w);
                if (opaque[XYZ(x, y, z)]) then begin
                    highest[XZ(x, z)] := MAX(highest[XZ(x, z)], y);
                end;
            end); // END_MAP_FOR_EACH;
        end;
    end;

    // flood fill light intensities
    if (has_light <> 0) then begin
        for a := 0 to 2 do begin
            for b := 0 to 2 do begin
                map := item.light_maps[a][b];
                if (map = nil) then begin
                    continue;
                end;
                MAP_FOR_EACH(map, procedure(ex, ey, ez, ew: Integer)
                var
                  x, y, z: Integer;
                begin
                    x := ex - ox;
                    y := ey - oy;
                    z := ez - oz;
                    light_fill(opaque, light, x, y, z, ew, 1);
                end);
            end;
        end;
    end;

    map := item.block_maps[1][1];

    // count exposed faces
    miny := 256;
    maxy := 0;
    faces := 0;
    MAP_FOR_EACH(map, procedure(ex, ey, ez, ew: Integer)
    var
      x, y, z: Integer;
      f1, f2, f3, f4, f5, f6: Boolean;
      total: Integer;
    begin
        if (ew <= 0) then begin
            Exit;//continue;
        end;
        x := ex - ox;
        y := ey - oy;
        z := ez - oz;
        f1 := not opaque[XYZ(x - 1, y, z)];
        f2 := not opaque[XYZ(x + 1, y, z)];
        f3 := not opaque[XYZ(x, y + 1, z)];
        f4 := not opaque[XYZ(x, y - 1, z)] and (ey > 0);
        f5 := not opaque[XYZ(x, y, z - 1)];
        f6 := not opaque[XYZ(x, y, z + 1)];
        total := ord(f1) + ord(f2) + ord(f3) + ord(f4) + ord(f5) + ord(f6);
        if (total = 0) then begin
            Exit;//continue;
        end;
        if (is_plant(ew)) then begin
            total := 4;
        end;
        miny := MIN(miny, ey);
        maxy := MAX(maxy, ey);
        Inc(faces, total);
    end);// END_MAP_FOR_EACH;

    // generate geometry
    data := malloc_faces(10, faces);
    offset := 0;
    MAP_FOR_EACH(map, procedure(ex, ey, ez, ew: Integer)
    var
      x, y, z: Integer;
      f1, f2, f3, f4, f5, f6: Boolean;
      total: Integer;

      neighbors: tbool_27;
      lights: tbyte_27;
      shades: tfloat_27;
      index: Integer;
      dx, dy, dz, _oy: Integer;

      ao: tfloat_6_4;
      light_: tfloat_6_4;

      min_ao: Single;
      max_light: Single;

      a, b: Integer;

      rotation: Single;

    begin
        if (ew <= 0) then begin
            Exit;//continue;
        end;
        x := ex - ox;
        y := ey - oy;
        z := ez - oz;
        f1 := not opaque[XYZ(x - 1, y, z)];
        f2 := not opaque[XYZ(x + 1, y, z)];
        f3 := not opaque[XYZ(x, y + 1, z)];
        f4 := not opaque[XYZ(x, y - 1, z)] and (ey > 0);
        f5 := not opaque[XYZ(x, y, z - 1)];
        f6 := not opaque[XYZ(x, y, z + 1)];
        total := ord(f1) + ord(f2) + ord(f3) + ord(f4) + ord(f5) + ord(f6);
        if (total = 0) then begin
            Exit;//continue;
        end;
        index := 0;
        for dx := -1 to +1 do begin
            for dy := -1 to +1 do begin
                for dz := -1 to +1 do begin
                    neighbors[index] := opaque[XYZ(x + dx, y + dy, z + dz)];
                    lights[index] := light[XYZ(x + dx, y + dy, z + dz)];
                    shades[index] := 0;
                    if (y + dy <= highest[XZ(x + dx, z + dz)]) then begin
                        for _oy := 0 to 7 do begin
                            if (opaque[XYZ(x + dx, y + dy + _oy, z + dz)]) then begin
                                shades[index] := 1.0 - _oy * 0.125;
                                break;
                            end;
                        end;
                    end;
                    Inc(index);
                end;
            end;
        end;
        occlusion(neighbors, lights, shades, ao, light_);
        if (is_plant(ew)) then begin
            total := 4;
            min_ao := 1;
            max_light := 0;
            for a := 0 to 5 do begin
                for b := 0 to 3 do begin
                    min_ao := MIN(min_ao, ao[a][b]);
                    max_light := MAX(max_light, light_[a][b]);
                end;
            end;
            rotation := simplex2(ex, ez, 4, 0.5, 2) * 360;
            make_plant(
                @data[offset], min_ao, max_light,
                ex, ey, ez, 0.5, ew, rotation);
        end
        else begin
            make_cube(
                @data[offset], ao, light_,
                f1, f2, f3, f4, f5, f6,
                ex, ey, ez, 0.5, ew);
        end;
        Inc(offset, total * 60);
    end);// END_MAP_FOR_EACH;

    freemem(opaque);
    freemem(light);
    freemem(highest);

    item.miny := miny;
    item.maxy := maxy;
    item.faces := faces;
    item.data := data;
end;

procedure generate_chunk(chunk: pChunk; item: pWorkerItem);
begin
  chunk.miny := item.miny;
  chunk.maxy := item.maxy;
  chunk.faces := item.faces;
  del_buffer(chunk.buffer);
  chunk.buffer := gen_faces(10, item.faces, item.data);
  gen_sign_buffer(chunk);
end;

procedure gen_chunk_buffer(chunk: pChunk);
var
  _item: TWorkerItem;
  item : pWorkerItem;
  dp, dq: Integer;
  other: pChunk;
begin
    FillChar(_item, SizeOf(_item), 0);
    item := @_item;
    item.p := chunk.p;
    item.q := chunk.q;
    for dp := -1 to +1 do begin
        for dq := -1 to +1 do begin
            other := chunk;
            if (dp <> 0) or (dq <> 0) then begin
                other := find_chunk(chunk.p + dp, chunk.q + dq);
            end;
            if (other <> nil) then begin
                item.block_maps[dp + 1][dq + 1] := @other.map;
                item.light_maps[dp + 1][dq + 1] := @other.lights;
            end
            else begin
                item.block_maps[dp + 1][dq + 1] := nil;
                item.light_maps[dp + 1][dq + 1] := nil;
            end;
        end;
    end;
    compute_chunk(item);
    generate_chunk(chunk, item);
    chunk.dirty := 0;
end;

procedure check_workers();
var
  i: Integer;
  worker: pWorker;
  item: pWorkerItem;
  chunk: pChunk;
  block_map: pMap;
  light_map: pMap;
  a: Integer;
  b: Integer;
begin
    for i := 0 to WORKERS - 1 do
    begin
        worker := @g.workers[i];
        mtx_lock(worker.mtx);
        if (worker.state = WORKER_DONE) then
        begin
            item := @worker.item;
            chunk := find_chunk(item.p, item.q);
            if (chunk <> nil) then
            begin
                if (item.load <> 0) then
                begin
                    block_map := item.block_maps[1][1];
                    light_map := item.light_maps[1][1];
                    map_free(chunk.map);
                    map_free(chunk.lights);
                    map_copy(@chunk.map, block_map);
                    map_copy(@chunk.lights, light_map);
                    request_chunk(item.p, item.q);
                end;
                generate_chunk(chunk, item);
            end;
            for a := 0 to 2 do
            begin
                for b := 0 to 2 do
                begin
                    block_map := item.block_maps[a][b];
                    light_map := item.light_maps[a][b];
                    if (block_map <> nil) then
                    begin
                        map_free(block_map^);
                        FreeMem(block_map);
                    end;
                    if (light_map <> nil) then
                    begin
                        map_free(light_map^);
                        FreeMem(light_map);
                    end;
                end;
            end;
            worker.state := WORKER_IDLE;
        end;
        mtx_unlock(worker.mtx);
    end;
end;

procedure map_set_func(x, y, z, w: Integer; arg: Pointer);
begin
    map_set(pMap(arg), x, y, z, w);
end;


procedure load_chunk(item: pWorkerItem);
var
  p, q: Integer;
  block_map, light_map: pMap;
begin
    p := item.p;
    q := item.q;
    block_map := item.block_maps[1][1];
    light_map := item.light_maps[1][1];
    create_world(p, q, map_set_func, block_map);
    db_load_blocks(block_map, p, q);
    db_load_lights(light_map, p, q);
end;

procedure init_chunk(chunk: pChunk; p, q: Integer);
var
  signs: pSignList;
  block_map: pMap;
  light_map: pMap;
  dx, dy, dz: Integer;
begin
    chunk.p := p;
    chunk.q := q;
    chunk.faces := 0;
    chunk.sign_faces := 0;
    chunk.buffer := 0;
    chunk.sign_buffer := 0;
    dirty_chunk(chunk);
    signs := @chunk.signs;
    sign_list_alloc(signs, 16);
    db_load_signs(signs, p, q);
    block_map := @chunk.map;
    light_map := @chunk.lights;
    dx := p * CHUNK_SIZE - 1;
    dy := 0;
    dz := q * CHUNK_SIZE - 1;
    map_alloc(block_map^, dx, dy, dz, $7fff);
    map_alloc(light_map^, dx, dy, dz, $f);
end;

procedure create_chunk(chunk: pChunk; p, q: Integer);
var
  _item: TWorkerItem;
  item : pWorkerItem;
begin
    init_chunk(chunk, p, q);

    item := @_item;
    item.p := chunk.p;
    item.q := chunk.q;
    item.block_maps[1][1] := @chunk.map;
    item.light_maps[1][1] := @chunk.lights;
    load_chunk(item);

    request_chunk(p, q);
end;

procedure delete_chunks();
var
  count: Integer;
  s1, s2, s3: pState;
  states: array[0..2] of pState;
  i: Integer;
  chunk: pChunk;
  delete: Integer;
  j: Integer;
  s: pState;
  p, q: Integer;
  other: pChunk;
begin
    count := g.chunk_count;
    s1 := @g.players[0].state;
    s2 := @g.players[g.observe1].state;
    s3 := @g.players[g.observe2].state;
    states[0] := s1;
    states[1] := s2;
    states[2] := s3;
    for i := 0 to count - 1 do begin
        chunk := @g.chunks[i];
        delete := 1;
        for j := 0 to 2 do begin
            s := states[j];
            p := chunked(s.x);
            q := chunked(s.z);
            if (chunk_distance(chunk, p, q) < g.delete_radius) then begin
                delete := 0;
                break;
            end;
        end;
        if (delete <> 0) then begin
            map_free(chunk.map);
            map_free(chunk.lights);
            sign_list_free(@chunk.signs);
            del_buffer(chunk.buffer);
            del_buffer(chunk.sign_buffer);
            Dec(Count); other := @g.chunks[count];
            //memcpy(chunk, other, sizeof(Chunk));
            chunk^ := other^;
        end;
    end;
    g.chunk_count := count;
end;

procedure force_chunks(player: pPlayer);
var
  s: pState;
  p, q, r: Integer;
  dp, dq: Integer;
  a, b: Integer;
  chunk: pChunk;
begin
    s := @player.state;
    p := chunked(s.x);
    q := chunked(s.z);
    r := 1;
    for dp := -r to +r do begin
        for dq := -r to +r do begin
            a := p + dp;
            b := q + dq;
            chunk := find_chunk(a, b);
            if (chunk <> nil) then begin
                if (chunk.dirty <> 0) then begin
                    gen_chunk_buffer(chunk);
                end;
            end
            else if (g.chunk_count < MAX_CHUNKS) then begin
                chunk := @g.chunks[g.chunk_count]; Inc(g.chunk_count);
                create_chunk(chunk, a, b);
                gen_chunk_buffer(chunk);
            end;
        end;
    end;
end;

procedure ensure_chunks_worker(player: pPlayer; worker: pWorker);
var
  s: pState;
  matrix: array[0..15] of Single;
  planes: TPlanes;
  p, q, r, start, best_score, best_a, best_b, dp, dq: Integer;
  a, b, index: Integer;
  chunk: pChunk;
  distance, invisible, priority, score: Integer;
  load: Integer;
  item: pWorkerItem;
  other: pChunk;
  block_map, light_map: pMap;
begin
    s := @player.state;
    set_matrix_3d(
        @matrix, g.width, g.height,
        s.x, s.y, s.z, s.rx, s.ry, g.fov, g.ortho, g.render_radius);
    frustum_planes(planes, g.render_radius, @matrix);
    p := chunked(s.x);
    q := chunked(s.z);
    r := g.create_radius;
    start := $0fffffff;
    best_score := start;
    best_a := 0;
    best_b := 0;
    for dp := -r to r do begin
        for dq := -r to r do begin
            a := p + dp;
            b := q + dq;
            index := (ABS(a) xor ABS(b)) mod WORKERS;
            if (index <> worker.index) then begin
                continue;
            end;
            chunk := find_chunk(a, b);
            if (chunk <> nil) and (chunk.dirty = 0) then begin
                continue;
            end;
            distance := MAX(ABS(dp), ABS(dq));
            invisible := not chunk_visible(planes, a, b, 0, 256);
            priority := 0;
            if (chunk <> nil) then begin
                priority := ord(chunk.buffer <> 0) and ord(chunk.dirty <> 0);
            end;
            score := (invisible shl 24) or (priority shl 16) or distance;
            if (score < best_score) then begin
                best_score := score;
                best_a := a;
                best_b := b;
            end;
        end;
    end;
    if (best_score = start) then begin
        Exit;
    end;
    a := best_a;
    b := best_b;
    load := 0;
    chunk := find_chunk(a, b);
    if (chunk = nil) then begin
        load := 1;
        if (g.chunk_count < MAX_CHUNKS) then begin
            chunk := @g.chunks[g.chunk_count];
            Inc(g.chunk_count);
            init_chunk(chunk, a, b);
        end
        else begin
            Exit;
        end;
    end;
    item := @worker.item;
    item.p := chunk.p;
    item.q := chunk.q;
    item.load := load;
    for dp := -1 to 1 do begin
        for dq := -1 to 1 do begin
            other := chunk;
            if (dp <> 0) or (dq <> 0) then begin
                other := find_chunk(chunk.p + dp, chunk.q + dq);
            end;
            if (other <> nil) then begin
                new(block_map);// := malloc(sizeof(Map));
                map_copy(block_map, @other.map);
                new(light_map);// := malloc(sizeof(Map));
                map_copy(light_map, @other.lights);
                item.block_maps[dp + 1][dq + 1] := block_map;
                item.light_maps[dp + 1][dq + 1] := light_map;
            end
            else begin
                item.block_maps[dp + 1][dq + 1] := nil;
                item.light_maps[dp + 1][dq + 1] := nil;
            end;
        end;
    end;
    chunk.dirty := 0;
    worker.state := WORKER_BUSY;
    cnd_signal(worker.cnd);
end;

procedure ensure_chunks(player: pPlayer);
var
  i: Integer;
  worker: pWorker;
begin
    check_workers();
    force_chunks(player);
    for i := 0 to WORKERS - 1 do
    begin
        worker := @g.workers[i];
        mtx_lock(worker.mtx);
        if (worker.state = WORKER_IDLE) then
        begin
            ensure_chunks_worker(player, worker);
        end;
        mtx_unlock(worker.mtx);
    end;
end;

function worker_run(arg: Pointer): Integer;
var
  worker: pWorker;
  running: Integer;
  item: pWorkerItem;
begin
    worker := arg;
    running := 1;
    while (running <> 0) do begin
        mtx_lock(worker.mtx);
        while (worker.state <> WORKER_BUSY) do begin
            cnd_wait(worker.cnd, worker.mtx);
        end;
        mtx_unlock(worker.mtx);
        item := @worker.item;
        if (item.load <> 0) then begin
            load_chunk(item);
        end;
        compute_chunk(item);
        mtx_lock(worker.mtx);
        worker.state := WORKER_DONE;
        mtx_unlock(worker.mtx);
    end;
    Result := 0;
end;

procedure unset_sign(x, y, z: Integer);
var
  p, q: Integer;
  chunk: pChunk;
  signs: pSignList;
begin
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk <> nil) then
    begin
        signs := @chunk.signs;
        if (sign_list_remove_all(signs, x, y, z) <> 0) then
        begin
            chunk.dirty := 1;
            db_delete_signs(x, y, z);
        end;
    end
    else begin
        db_delete_signs(x, y, z);
    end;
end;

procedure unset_sign_face(x, y, z, face: Integer);
var
  p, q: Integer;
  chunk: pChunk;
  signs: pSignList;
begin
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk <> nil) then begin
        signs := @chunk.signs;
        if (sign_list_remove(signs, x, y, z, face) <> 0) then begin
            chunk.dirty := 1;
            db_delete_sign(x, y, z, face);
        end;
    end
    else begin
        db_delete_sign(x, y, z, face);
    end;
end;

procedure _set_sign(
    p, q, x, y, z, face: Integer; text: PAnsiChar; dirty: Integer);
var
  chunk: pChunk;
  signs: pSignList;
begin
    if (strlen(text) = 0) then begin
        unset_sign_face(x, y, z, face);
        Exit;
    end;
    chunk := find_chunk(p, q);
    if (chunk <> nil) then begin
        signs := @chunk.signs;
        sign_list_add(signs, x, y, z, face, text);
        if (dirty <> 0) then begin
            chunk.dirty := 1;
        end;
    end;
    db_insert_sign(p, q, x, y, z, face, text);
end;

procedure set_sign(x, y, z, face: Integer; text: PAnsiChar);
var
  p, q: Integer;
begin
    p := chunked(x);
    q := chunked(z);
    _set_sign(p, q, x, y, z, face, text, 1);
    client_sign(x, y, z, face, text);
end;

procedure toggle_light(x, y, z: Integer);
var
  p, q: Integer;
  chunk: pChunk;
  map: pMap;
  w: Integer;
begin
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk <> nil) then begin
        map := @chunk.lights;
        if map_get(map, x, y, z) <> 0 then w := 0 else w := 15;
        map_set(map, x, y, z, w);
        db_insert_light(p, q, x, y, z, w);
        client_light(x, y, z, w);
        dirty_chunk(chunk);
    end;
end;

procedure set_light(p, q, x, y, z, w: Integer);
var
  chunk: pChunk;
  map: pMap;
begin
    chunk := find_chunk(p, q);
    if (chunk <> nil) then
    begin
        map := @chunk.lights;
        if (map_set(map, x, y, z, w) <> 0) then
        begin
            dirty_chunk(chunk);
            db_insert_light(p, q, x, y, z, w);
        end;
    end
    else begin
        db_insert_light(p, q, x, y, z, w);
    end;
end;

procedure _set_block(p, q, x, y, z, w, dirty: Integer);
var
  chunk: pChunk;
  map: pMap;
begin
    chunk := find_chunk(p, q);
    if (chunk <> nil) then
    begin
        map := @chunk.map;
        if (map_set(map, x, y, z, w) <> 0) then
        begin
            if (dirty <> 0) then
            begin
                dirty_chunk(chunk);
            end;
            db_insert_block(p, q, x, y, z, w);
        end;
    end
    else begin
        db_insert_block(p, q, x, y, z, w);
    end;
    if (w = 0) and (chunked(x) = p) and (chunked(z) = q) then
    begin
        unset_sign(x, y, z);
        set_light(p, q, x, y, z, 0);
    end;
end;

procedure set_block(x, y, z, w: Integer);
var
  p, q: Integer;
  dx, dz: Integer;
begin
    p := chunked(x);
    q := chunked(z);
    _set_block(p, q, x, y, z, w, 1);
    for dx := -1 to +1 do
    begin
        for dz := -1 to +1 do
        begin
            if (dx = 0) and (dz = 0) then
            begin
                continue;
            end;
            if (dx <> 0) and (chunked(x + dx) = p) then
            begin
                continue;
            end;
            if (dz <> 0) and(chunked(z + dz) = q) then
            begin
                continue;
            end;
            _set_block(p + dx, q + dz, x, y, z, -w, 1);
        end;
    end;
    client_block(x, y, z, w);
end;

procedure record_block(x, y, z, w: Integer);
begin
//    memcpy(&g->block1, &g->block0, sizeof(Block));
  g.block0 := g.block1;
  g.block0.x := x;
  g.block0.y := y;
  g.block0.z := z;
  g.block0.w := w;
end;

function get_block(x, y, z: Integer): Integer;
var
  p, q: Integer;
  chunk: pChunk;
  map: pMap;
begin
    p := chunked(x);
    q := chunked(z);
    chunk := find_chunk(p, q);
    if (chunk <> nil) then begin
        map := @chunk.map;
        Exit(map_get(map, x, y, z));
    end;
    Result := 0;
end;

procedure builder_block(x, y, z, w: Integer);
begin
    if (y <= 0) or (y >= 256) then
    begin
        Exit;
    end;
    if (is_destructable(get_block(x, y, z))) then
    begin
        set_block(x, y, z, 0);
    end;
    if (w <> 0) then
    begin
        set_block(x, y, z, w);
    end;
end;

procedure reset_model();
begin
    FillChar(g.chunks, sizeof(TChunk) * MAX_CHUNKS, 0);
    g.chunk_count := 0;
    FillChar(g.players, sizeof(TPlayer) * MAX_PLAYERS, 0);
    g.player_count := 0;
    g.observe1 := 0;
    g.observe2 := 0;
    g.flying := 0;
    g.item_index := 0;
    //memset(g->typing_buffer, 0, sizeof(char) * MAX_TEXT_LENGTH);
    g.typing_buffer := '';
    g.typing := 0;
//    memset(g->messages, 0, sizeof(char) * MAX_MESSAGES * MAX_TEXT_LENGTH);
//    g.message_index := 0;
    g.day_length := DAY_LENGTH;
    glfwSetTime(g.day_length / 3.0);
    g.time_changed := 1;
end;

procedure add_message(text: PAnsiChar);
begin
    //printf('%s\n', text);
    snprintf(
        g.messages[g.message_index], MAX_TEXT_LENGTH, '%s', [text]);
    g.message_index := (g.message_index + 1) mod MAX_MESSAGES;
end;

procedure login();
var
  username: array[0..127] of AnsiChar;
  identity_token: array[0..127] of AnsiChar;
  access_token: array[0..127] of AnsiChar;
begin
  username[0] := #0;
  identity_token[0] := #0;
  access_token[0] := #0;
  if (db_auth_get_selected(username, 128, identity_token, 128) <> 0) then begin
        //printf("Contacting login server for username: %s\n", username);
        if (get_access_token(
            access_token, 128, username, identity_token)) then
        begin
            //printf("Successfully authenticated with the login server\n");
            client_login(username, access_token);
        end
        else begin
            //printf("Failed to authenticate with the login server\n");
            client_login('', '');
        end;
    end
    else begin
        //printf("Logging in anonymously\n");
        client_login('', '');
    end;
end;

procedure copy();
begin
//    memcpy(&g->copy0, &g->block0, sizeof(Block));
  g.copy0 := g.block0;
//    memcpy(&g->copy1, &g->block1, sizeof(Block));
  g.copy1 := g.block1;
end;

procedure paste();
var
  c1, c2, p1, p2: pBlock;
  scx, scz, spx, spz, oy, dx, dz: Integer;
  y, x, z, w: Integer;
begin
    c1 := @g.copy1;
    c2 := @g.copy0;
    p1 := @g.block1;
    p2 := @g.block0;
    scx := SIGN(c2.x - c1.x);
    scz := SIGN(c2.z - c1.z);
    spx := SIGN(p2.x - p1.x);
    spz := SIGN(p2.z - p1.z);
    oy := p1.y - c1.y;
    dx := ABS(c2.x - c1.x);
    dz := ABS(c2.z - c1.z);
    for y := 0 to 255 do begin
        for x := 0 to dx do begin
            for z := 0 to dz do begin
                w := get_block(c1.x + x * scx, y, c1.z + z * scz);
                builder_block(p1.x + x * spx, y + oy, p1.z + z * spz, w);
            end;
        end;
    end;
end;

procedure &array(b1, b2: pBlock; xc, yc, zc: Integer);
var
  w, dx, dy, dz, i, x, j, y, k, z: Integer;
begin
    if (b1.w <> b2.w) then
    begin
        Exit;
    end;
    w := b1.w;
    dx := b2.x - b1.x;
    dy := b2.y - b1.y;
    dz := b2.z - b1.z;
    if dx = 0 then xc := 1;
    if dy = 0 then yc := 1;
    if dz = 0 then zc := 1;
    for i := 0 to xc - 1 do
    begin
        x := b1.x + dx * i;
        for j := 0 to yc - 1 do
        begin
            y := b1.y + dy * j;
            for k := 0 to zc - 1 do
            begin
                z := b1.z + dz * k;
                builder_block(x, y, z, w);
            end;
        end;
    end;
end;

procedure cube(b1, b2: pBlock; fill: Integer);
var
  w, x1, y1, z1, x2, y2, z2, a, x, y, z, n: Integer;
begin
    if (b1.w <> b2.w) then
    begin
        Exit;
    end;
    w := b1.w;
    x1 := MIN(b1.x, b2.x);
    y1 := MIN(b1.y, b2.y);
    z1 := MIN(b1.z, b2.z);
    x2 := MAX(b1.x, b2.x);
    y2 := MAX(b1.y, b2.y);
    z2 := MAX(b1.z, b2.z);
    a := ord(x1 = x2) + ord(y1 = y2) + ord(z1 = z2);
    for x := x1 to x2 do
    begin
        for y := y1 to y2 do
        begin
            for z := z1 to z2 do
            begin
                if (0 = fill) then
                begin
                    n := 0;
                    Inc(n, Ord(x = x1) or Ord(x = x2));
                    Inc(n, Ord(y = y1) or Ord(y = y2));
                    Inc(n, Ord(z = z1) or Ord(z = z2));
                    if (n <= a) then
                    begin
                        continue;
                    end;
                end;
                builder_block(x, y, z, w);
            end;
        end;
    end;
end;

procedure sphere(center: pBlock; radius, fill, fx, fy, fz: Integer);
const
  offsets:array[0..7,0..2] of Single = (
        (-0.5, -0.5, -0.5),
        (-0.5, -0.5, 0.5),
        (-0.5, 0.5, -0.5),
        (-0.5, 0.5, 0.5),
        (0.5, -0.5, -0.5),
        (0.5, -0.5, 0.5),
        (0.5, 0.5, -0.5),
        (0.5, 0.5, 0.5)
    );
var
  cx, cy, cz, w, x, y, z, inside, outside, i: Integer;
  dx, dy, dz, d: Single;
begin
    cx := center.x;
    cy := center.y;
    cz := center.z;
    w := center.w;
    for x := cx - radius to cx + radius do
    begin
        if (fx <> 0) and (x <> cx) then
        begin
            continue;
        end;
        for y := cy - radius to cy + radius do
        begin
            if (fy  <> 0) and (y <> cy) then
            begin
                continue;
            end;
            for z := cz - radius to cz + radius do
            begin
                if (fz <> 0) and (z <> cz) then
                begin
                    continue;
                end;
                inside := 0;
                outside := fill;
                for i := 0 to 7 do
                begin
                    dx := x + offsets[i][0] - cx;
                    dy := y + offsets[i][1] - cy;
                    dz := z + offsets[i][2] - cz;
                    d := sqrt(dx * dx + dy * dy + dz * dz);
                    if (d < radius) then
                    begin
                        inside := 1;
                    end
                    else begin
                        outside := 1;
                    end;
                end;
                if (inside <> 0) and (outside <> 0) then
                begin
                    builder_block(x, y, z, w);
                end;
            end;
        end;
    end;
end;

procedure cylinder(b1, b2: pBlock; radius, fill: Integer);
var
  w, x1, y1, z1, x2, y2, z2, fx, fy, fz : Integer;
  block: pBlock;
  x, y, z : Integer;
begin
    if (b1.w) <> (b2.w) then
    begin
        Exit;
    end;
    w := b1.w;
    x1 := MIN(b1.x, b2.x);
    y1 := MIN(b1.y, b2.y);
    z1 := MIN(b1.z, b2.z);
    x2 := MAX(b1.x, b2.x);
    y2 := MAX(b1.y, b2.y);
    z2 := MAX(b1.z, b2.z);
    fx := ord(x1 <> x2);
    fy := ord(y1 <> y2);
    fz := ord(z1 <> z2);
    if (fx + fy + fz <> 1) then
    begin
        Exit;
    end;
    block.x := x1;
    block.y := y1;
    block.z := z1;
    block.w := w;
    if (fx <> 0) then
    begin
        for x := x1 to x2 do
        begin
            block.x := x;
            sphere(@block, radius, fill, 1, 0, 0);
        end;
    end;
    if (fy <> 0) then
    begin
        for y := y1 to y2 do
        begin
            block.y := y;
            sphere(@block, radius, fill, 0, 1, 0);
        end;
    end;
    if (fz <> 0) then
    begin
        for z := z1 to z2 do
        begin
            block.z := z;
            sphere(@block, radius, fill, 0, 0, 1);
        end;
    end;
end;

procedure tree(block: pBlock);
var
  bx, by, bz, y, dx, dz, dy, d: Integer;
begin
    bx := block.x;
    by := block.y;
    bz := block.z;
    for y := by + 3 to by + 7 do
    begin
        for dx := -3 to +3 do
        begin
            for dz := -3 to + 3 do
            begin
                dy := y - (by + 4);
                d := (dx * dx) + (dy * dy) + (dz * dz);
                if (d < 11) then
                begin
                    builder_block(bx + dx, y, bz + dz, 15);
                end;
            end;
        end;
    end;
    for y := by to by + 6 do
    begin
        builder_block(bx, y, bz, 5);
    end;
end;

procedure parse_command(buffer: PAnsiChar; &forward: Integer);
var
  username: array[0..127] of AnsiChar;
  token: array[0..127] of AnsiChar;
  server_addr: array[0..MAX_ADDR_LENGTH - 1] of AnsiChar;
  server_port: Integer;
  filename: array[0..MAX_PATH_LENGTH - 1] of AnsiChar;
  radius, count, xc, yc, zc: Integer;
begin
    username[0] := #0;
    token[0] := #0;
    server_port := DEFAULT_PORT;
    if (sscanf(buffer, '/identity %128s %128s', [@username, @token]) = 2) then begin
        db_auth_set(username, token);
        add_message('Successfully imported identity token!');
        login();
    end
    else if (strcmp(buffer, '/logout') = 0) then begin
        db_auth_select_none();
        login();
    end
    else if (sscanf(buffer, '/login %128s', [@username]) = 1) then begin
        if (db_auth_select(username) <> 0) then begin
            login();
        end
        else begin
            add_message('Unknown username.');
        end;
    end
    else if (sscanf(buffer,
        '/online %128s %d', [@server_addr, @server_port]) >= 1) then
    begin
        g.mode_changed := 1;
        g.mode := MODE_ONLINE;
        strncpy(g.server_addr, server_addr, MAX_ADDR_LENGTH);
        g.server_port := server_port;
        snprintf(g.db_path, MAX_PATH_LENGTH,
            'cache.%s.%d.db', [g.server_addr, g.server_port]);
    end
    else if (sscanf(buffer, '/offline %128s', [@filename]) = 1) then begin
        g.mode_changed := 1;
        g.mode := MODE_OFFLINE;
        snprintf(g.db_path, MAX_PATH_LENGTH, '%s.db', [filename]);
    end
    else if (strcmp(buffer, '/offline') = 0) then begin
        g.mode_changed := 1;
        g.mode := MODE_OFFLINE;
        snprintf(g.db_path, MAX_PATH_LENGTH, '%s', [DB_PATH]);
    end
    else if (sscanf(buffer, '/view %d', [@radius]) = 1) then begin
        if (radius >= 1) and (radius <= 24) then begin
            g.create_radius := radius;
            g.render_radius := radius;
            g.delete_radius := radius + 4;
        end
        else begin
            add_message('Viewing distance must be between 1 and 24.');
        end;
    end
    else if (strcmp(buffer, '/copy') = 0) then begin
        copy();
    end
    else if (strcmp(buffer, '/paste') = 0) then begin
        paste();
    end
    else if (strcmp(buffer, '/tree') = 0) then begin
        tree(@g.block0);
    end
    else if (sscanf(buffer, '/array %d %d %d', [@xc, @yc, @zc]) = 3) then begin
        &array(@g.block1, @g.block0, xc, yc, zc);
    end
    else if (sscanf(buffer, '/array %d', [@count]) = 1) then begin
        &array(@g.block1, @g.block0, count, count, count);
    end
    else if (strcmp(buffer, '/fcube') = 0) then begin
        cube(@g.block0, @g.block1, 1);
    end
    else if (strcmp(buffer, '/cube') = 0) then begin
        cube(@g.block0, @g.block1, 0);
    end
    else if (sscanf(buffer, '/fsphere %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 1, 0, 0, 0);
    end
    else if (sscanf(buffer, '/sphere %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 0, 0, 0, 0);
    end
    else if (sscanf(buffer, '/fcirclex %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 1, 1, 0, 0);
    end
    else if (sscanf(buffer, '/circlex %d',[@radius]) = 1) then begin
        sphere(@g.block0, radius, 0, 1, 0, 0);
    end
    else if (sscanf(buffer, '/fcircley %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 1, 0, 1, 0);
    end
    else if (sscanf(buffer, '/circley %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 0, 0, 1, 0);
    end
    else if (sscanf(buffer, '/fcirclez %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 1, 0, 0, 1);
    end
    else if (sscanf(buffer, '/circlez %d', [@radius]) = 1) then begin
        sphere(@g.block0, radius, 0, 0, 0, 1);
    end
    else if (sscanf(buffer, '/fcylinder %d', [@radius]) = 1) then begin
        cylinder(@g.block0, @g.block1, radius, 1);
    end
    else if (sscanf(buffer, '/cylinder %d', [@radius]) = 1) then begin
        cylinder(@g.block0, @g.block1, radius, 0);
    end
    else if (&forward <> 0) then begin
        client_talk(buffer);
    end;
end;

procedure on_light();
var
  s: pState;
  hx, hy, hz, hw: Integer;
begin
    s := @g.players[0].state;
    hw := hit_test(1, s.x, s.y, s.z, s.rx, s.ry, hx, hy, hz);
    if (hy > 0) and (hy < 256) and is_destructable(hw) then begin
        toggle_light(hx, hy, hz);
    end;
end;

procedure on_left_click();
var
  s: pState;
  hx, hy, hz, hw: Integer;
begin
    s := @g.players[0].state;
    hw := hit_test(0, s.x, s.y, s.z, s.rx, s.ry, hx, hy, hz);
    if (hy > 0) and (hy < 256) and is_destructable(hw) then begin
        set_block(hx, hy, hz, 0);
        record_block(hx, hy, hz, 0);
        if (is_plant(get_block(hx, hy + 1, hz))) then begin
            set_block(hx, hy + 1, hz, 0);
        end;
    end;
end;

procedure on_right_click();
var
  s: pState;
  hx, hy, hz, hw: Integer;
begin
    s := @g.players[0].state;
    hw := hit_test(1, s.x, s.y, s.z, s.rx, s.ry, hx, hy, hz);
    if (hy > 0) and (hy < 256) and is_obstacle(hw) then begin
        if (False = player_intersects_block(2, s.x, s.y, s.z, hx, hy, hz)) then begin
            set_block(hx, hy, hz, items[g.item_index]);
            record_block(hx, hy, hz, items[g.item_index]);
        end;
    end;
end;


procedure on_middle_click();
var
  s: pState;
  hx, hy, hz, hw, i: Integer;
begin
    s := @g.players[0].state;
    hw := hit_test(1, s.x, s.y, s.z, s.rx, s.ry, hx, hy, hz);
    for i := 0 to item_count - 1 do begin
        if (items[i] = hw) then begin
            g.item_index := i;
            break;
        end;
    end;
end;

procedure on_key(window: pGLFWwindow; key, scancode, action, mods: Integer); cdecl;
var
  control: Integer;
  exclusive: Boolean;
  n: Integer;
  player: pPlayer;
  x, y, z, face: Integer;
  buffer: PAnsiChar;
begin
    control := mods and (GLFW_MOD_CONTROL or GLFW_MOD_SUPER);
    exclusive :=
        glfwGetInputMode(window, GLFW_CURSOR) = GLFW_CURSOR_DISABLED;
    if (action = GLFW_RELEASE) then begin
        Exit;
    end;
    if (key = GLFW_KEY_BACKSPACE) then begin
        if (g.typing <> 0) then begin
            n := strlen(g.typing_buffer);
            if (n > 0) then begin
                g.typing_buffer[n - 1] := #0;
            end;
        end;
    end;
    if (action <> GLFW_PRESS) then begin
        Exit;
    end;
    if (key = GLFW_KEY_ESCAPE) then begin
        if (g.typing <> 0) then begin
            g.typing := 0;
        end
        else if (exclusive) then begin
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
        end;
    end;
    if (key = GLFW_KEY_ENTER) then begin
        if (g.typing <> 0) then begin
            if (mods and GLFW_MOD_SHIFT) <> 0 then begin
                n := strlen(g.typing_buffer);
                if (n < MAX_TEXT_LENGTH - 1) then begin
                    g.typing_buffer[n] := #13;
                    g.typing_buffer[n + 1] := #0;
                end;
            end
            else begin
                g.typing := 0;
                if (g.typing_buffer[0] = CRAFT_KEY_SIGN) then begin
                    player := @g.players;
                    if (hit_test_face(player, x, y, z, face)) then begin
                        set_sign(x, y, z, face, g.typing_buffer + 1);
                    end;
                end
                else if (g.typing_buffer[0] = '/') then begin
                    parse_command(g.typing_buffer, 1);
                end
                else begin
                    client_talk(g.typing_buffer);
                end;
            end;
        end
        else begin
            if (control <> 0) then begin
                on_right_click();
            end
            else begin
                on_left_click();
            end;
        end;
    end;
    if (control <> 0) and (key = ord('V')) then begin
        buffer := glfwGetClipboardString(window);
        if (g.typing <> 0) then begin
            g.suppress_char := 1;
            strncat(g.typing_buffer, buffer,
                MAX_TEXT_LENGTH - strlen(g.typing_buffer) - 1);
        end
        else begin
            parse_command(buffer, 0);
        end;
    end;
    if (0 = g.typing) then begin
        if (key = CRAFT_KEY_FLY) then begin
            g.flying := not g.flying;
        end;
        if (key >= Ord('1')) and (key <= Ord('9')) then begin
            g.item_index := key - Ord('1');
        end;
        if (key = Ord('0')) then begin
            g.item_index := 9;
        end;
        if key = Ord(CRAFT_KEY_ITEM_NEXT) then begin
            g.item_index := (g.item_index + 1) mod item_count;
        end;
        if key = Ord(CRAFT_KEY_ITEM_PREV) then begin
            Dec(g.item_index);
            if (g.item_index < 0) then begin
                g.item_index := item_count - 1;
            end;
        end;
        if key = Ord(CRAFT_KEY_OBSERVE) then begin
            g.observe1 := (g.observe1 + 1) mod g.player_count;
        end;
        if key = Ord(CRAFT_KEY_OBSERVE_INSET) then begin
            g.observe2 := (g.observe2 + 1) mod g.player_count;
        end;
    end;
end;
{
key = 346, scancode = 312, action = 2
key = 346, scancode = 312, action = 2
key = 346, scancode = 312, action = 2
key = 346, scancode = 312, action = 2
key = 346, scancode = 312, action = 2
key = 346, scancode = 312, action = 2  REPEAT
key = 55, scancode = 8, action = 1   PRESS
key = 55, scancode = 8, action = 0
key = 346, scancode = 312, action = 0
key = 256, scancode = 1, action = 1
char = 96

}

procedure on_char(window: PGLFWwindow; u: Cardinal); cdecl;
var
  c: AnsiChar;
  n: Integer;
begin
    if (g.suppress_char <> 0) then begin
        g.suppress_char := 0;
        Exit;
    end;
    if (g.typing <> 0) then begin
        if (u >= 32) and (u < 128) then begin
            c := AnsiChar(u);
            n := strlen(g.typing_buffer);
            if (n < MAX_TEXT_LENGTH - 1) then begin
                g.typing_buffer[n] := c;
                g.typing_buffer[n + 1] := #0;
            end;
        end;
    end
    else begin
        if u = Ord(CRAFT_KEY_CHAT) then begin
            g.typing := 1;
            g.typing_buffer[0] := #0;
        end;
        if u = Ord(CRAFT_KEY_COMMAND) then begin
            g.typing := 1;
            g.typing_buffer[0] := '/';
            g.typing_buffer[1] := #0;
        end;
        if u = Ord(CRAFT_KEY_SIGN) then begin
            g.typing := 1;
            g.typing_buffer[0] := CRAFT_KEY_SIGN;
            g.typing_buffer[1] := #0;
        end;
    end;
end;

var
  ypos: Double = 0;
procedure on_scroll(window: pGLFWwindow; xdelta, ydelta: Double); cdecl;
begin
    ypos := ypos + ydelta;
    if (ypos < -SCROLL_THRESHOLD) then begin
        g.item_index := (g.item_index + 1) mod item_count;
        ypos := 0;
    end;
    if (ypos > SCROLL_THRESHOLD) then begin
        Dec(g.item_index);
        if (g.item_index < 0) then begin
            g.item_index := item_count - 1;
        end;
        ypos := 0;
    end;
end;

procedure on_mouse_button(window: pGLFWwindow; button, action, mods: Integer); cdecl;
var
  control: Integer;
  exclusive: Boolean;
begin
    control := mods and (GLFW_MOD_CONTROL or GLFW_MOD_SUPER);
    exclusive :=
        glfwGetInputMode(window, GLFW_CURSOR) = GLFW_CURSOR_DISABLED;
    if (action <> GLFW_PRESS) then begin
        Exit;
    end;
    if (button = GLFW_MOUSE_BUTTON_LEFT) then begin
        if (exclusive) then begin
            if (control <> 0) then begin
                on_right_click();
            end
            else begin
                on_left_click();
            end;
        end
        else begin
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
        end;
    end;
    if (button = GLFW_MOUSE_BUTTON_RIGHT) then begin
        if (exclusive) then begin
            if (control <> 0) then begin
                on_light();
            end
            else begin
                on_right_click();
            end;
        end;
    end;
    if (button = GLFW_MOUSE_BUTTON_MIDDLE) then begin
        if (exclusive) then begin
            on_middle_click();
        end;
    end;
end;

procedure create_window();
var
  _window_width: Integer;
  _window_height: Integer;
  monitor: pGLFWmonitor;
  mode_count: Integer;
  modes: pGLFWvidmode;
begin
  _window_width := WINDOW_WIDTH;
  _window_height := WINDOW_HEIGHT;
  monitor := nil;
  if (FULLSCREEN <> 0) then begin
    monitor := glfwGetPrimaryMonitor();
    modes := glfwGetVideoModes(monitor, mode_count);
    _window_width := modes[mode_count - 1].width;
    _window_height := modes[mode_count - 1].height;
  end;
  g.window := glfwCreateWindow(
        _window_width, _window_height, 'Craft', monitor, nil);
end;

var // static
  px: Double = 0;
  py: Double = 0;

procedure handle_mouse_input();
var
  exclusive: Boolean;
  s: pState;
  mx, my: Double;
  m: Single;
begin
    exclusive :=
        glfwGetInputMode(g.window, GLFW_CURSOR) = GLFW_CURSOR_DISABLED;
    s := @g.players[0].state;
    if exclusive and ((px <> 0) or (py <> 0)) then begin
        glfwGetCursorPos(g.window, @mx, @my);
        m := 0.0025;
        s.rx := s.rx + (mx - px) * m;
        if (INVERT_MOUSE) then begin
            s.ry := s.ry + (my - py) * m;
        end
        else begin
            s.ry := s.ry - (my - py) * m;
        end;
        if (s.rx < 0) then begin
            s.rx := s.rx + RADIANS(360);
        end;
        if (s.rx >= RADIANS(360)) then begin
            s.rx := s.rx - RADIANS(360);
        end;
        s.ry := MAX(s.ry, -RADIANS(90));
        s.ry := MIN(s.ry, RADIANS(90));
        px := mx;
        py := my;
    end
    else begin
        glfwGetCursorPos(g.window, @px, @py);
    end;
end;

var // static
  dy: Single = 0;

procedure handle_movement(dt: double);
var
  s: pState;
  sz, sx: Integer;
  m: Single;
  vx, vy, vz: Single;
  speed: Single;
  estimate: Integer;
  step: Integer;
  ut: Single;
  i: Integer;
begin
    s := @g.players[0].state;
    sz := 0;
    sx := 0;
    if (g.typing = 0) then begin
        m := dt * 1.0;
        if glfwGetKey(g.window, CRAFT_KEY_ORTHO) <> 0 then g.ortho := 64 else g.ortho := 0;
        if glfwGetKey(g.window, CRAFT_KEY_ZOOM) <> 0 then g.fov := 15 else g.fov := 65;
        if (glfwGetKey(g.window, CRAFT_KEY_FORWARD)) <> 0 then Dec(sz);
        if (glfwGetKey(g.window, CRAFT_KEY_BACKWARD))  <> 0 then Inc(sz);
        if (glfwGetKey(g.window, CRAFT_KEY_LEFT))  <> 0 then Dec(sx);
        if (glfwGetKey(g.window, CRAFT_KEY_RIGHT))  <> 0 then Inc(sx);
        if (glfwGetKey(g.window, GLFW_KEY_LEFT))  <> 0 then s.rx := s.rx - m;
        if (glfwGetKey(g.window, GLFW_KEY_RIGHT))  <> 0 then s.rx := s.rx + m;
        if (glfwGetKey(g.window, GLFW_KEY_UP))  <> 0 then s.ry := s.ry + m;
        if (glfwGetKey(g.window, GLFW_KEY_DOWN))  <> 0 then s.ry := s.ry - m;
    end;
    get_motion_vector(g.flying, sz, sx, s.rx, s.ry, vx, vy, vz);
    if (g.typing = 0) then begin
        if (glfwGetKey(g.window, CRAFT_KEY_JUMP) <> 0) then begin
            if (g.flying <> 0) then begin
                vy := 1;
            end
            else if (dy = 0) then begin
                dy := 8;
            end;
        end;
    end;
    if g.flying <> 0 then speed := 20 else speed := 5;
    estimate := round(sqrt(
        power(vx * speed, 2) +
        power(vy * speed + ABS(dy) * 2, 2) +
        power(vz * speed, 2)) * dt * 8);
    step := MAX(8, estimate);
    ut := dt / step;
    vx := vx * ut * speed;
    vy := vy * ut * speed;
    vz := vz * ut * speed;
    for i := 0 to step - 1 do begin
        if (g.flying <> 0) then begin
            dy := 0;
        end
        else begin
            dy := dy - ut * 25;
            dy := MAX(dy, -250);
        end;
        s.x := s.x + vx;
        s.y := s.y + vy + dy * ut;
        s.z := s.z + vz;
        if (collide(2, s.x, s.y, s.z) <> 0) then begin
            dy := 0;
        end;
    end;
    if (s.y < 0) then begin
        s.y := highest_block(s.x, s.z) + 2;
    end;
end;

procedure parse_buffer(buffer: PAnsiChar);
var
  me: pPlayer;
  s: pState;
  key: PAnsiChar;
  line: PAnsiChar;
  pid: Integer;
  ux, uy, uz, urx, ury: Single;
  bp, bq, bx, by, bz, bw: Integer;
  px, py, pz, prx, pry: Single;
  player: pPlayer;
  kp, kq, kk: Integer;
  chunk: pChunk;
  elapsed: Double;
  day_length: Integer;
  text: PAnsiChar;
  format: array[0..63] of AnsiChar;
  name: array[0..MAX_NAME_LENGTH-1] of AnsiChar;
  face: Integer;
  text_:array[0..MAX_SIGN_LENGTH - 1] of AnsiChar;
begin
    me := @g.players;
    s := @g.players[0].state;
    line := tokenize(buffer, #10, key);
    while (line <> nil) do begin
        if (sscanf(line, 'U,%d,%f,%f,%f,%f,%f',
            [@pid, @ux, @uy, @uz, @urx, @ury]) = 6)
        then begin
            me.id := pid;
            s.x := ux; s.y := uy; s.z := uz; s.rx := urx; s.ry := ury;
            force_chunks(me);
            if (uy = 0) then begin
                s.y := highest_block(s.x, s.z) + 2;
            end;
      end else
        if (sscanf(line, 'B,%d,%d,%d,%d,%d,%d',
            [@bp, @bq, @bx, @by, @bz, @bw]) = 6)
        then begin
            _set_block(bp, bq, bx, by, bz, bw, 0);
            if (player_intersects_block(2, s.x, s.y, s.z, bx, by, bz)) then begin
                s.y := highest_block(s.x, s.z) + 2;
            end;
      end else
        if (sscanf(line, 'L,%d,%d,%d,%d,%d,%d',
            [@bp, @bq, @bx, @by, @bz, @bw]) = 6)
        then begin
            set_light(bp, bq, bx, by, bz, bw);
      end else
        if (sscanf(line, 'P,%d,%f,%f,%f,%f,%f',
            [@pid, @px, @py, @pz, @prx, @pry]) = 6)
        then begin
            player := find_player(pid);
            if (player = nil) and (g.player_count < MAX_PLAYERS) then begin
                player := @g.players[g.player_count];
                Inc(g.player_count);
                player.id := pid;
                player.buffer := 0;
                snprintf(player.name, MAX_NAME_LENGTH, 'player%d', [pid]);
                update_player(player, px, py, pz, prx, pry, 1); // twice
            end;
            if (player <> nil) then begin
                update_player(player, px, py, pz, prx, pry, 1);
            end;
      end else
        if (sscanf(line, 'D,%d', [@pid]) = 1) then begin
            delete_player(pid);
      end else
        if (sscanf(line, 'K,%d,%d,%d', [@kp, @kq, @kk]) = 3) then begin
            db_set_key(kp, kq, kk);
      end else
        if (sscanf(line, 'R,%d,%d', [@kp, @kq]) = 2) then begin
            chunk := find_chunk(kp, kq);
            if (chunk <> nil) then begin
                dirty_chunk(chunk);
            end;
      end else
        if (sscanf(line, 'E,%lf,%d', [@elapsed, @day_length]) = 2) then begin
            glfwSetTime(fmod(elapsed, day_length));
            g.day_length := day_length;
            g.time_changed := 1;
      end else
        if (line[0] = 'T') and (line[1] = ',') then begin
            text := line + 2;
            add_message(text);
      end else begin
        snprintf(
            format, sizeof(format), 'N,%%d,%%%ds', [MAX_NAME_LENGTH - 1]);
        if (sscanf(line, format, [@pid, @name]) = 2) then begin
            player := find_player(pid);
            if (player <> nil) then begin
                strncpy(player.name, name, MAX_NAME_LENGTH);
            end;
        end else begin
        snprintf(
            format, sizeof(format),
            'S,%%d,%%d,%%d,%%d,%%d,%%d,%%%d[^\n]', [MAX_SIGN_LENGTH - 1]);
        if (sscanf(line, format,
            [@bp, @bq, @bx, @by, @bz, @face, @text_]) >= 6)
        then begin
            _set_sign(bp, bq, bx, by, bz, face, @text_, 0);
          end else begin
            if line[0] <> 'C' then // CHUNK
              WriteLn('?? ', line);
          end;
        end;
        end;
      line := tokenize(nil, #10, key);
    end;
end;

function main(): Integer;
var
  texture, font, sky, sign: GLuint;
  block_attrib: TAttrib;
  line_attrib : TAttrib;
  text_attrib : TAttrib;
  sky_attrib  : TAttrib;
  &program: GLuint;
  i: Integer;
  worker: pWorker;
  running: Integer;
  fps: TFPS;
  last_commit: Double;
  last_update: Double;
  sky_buffer: GLuint;
  me: pPlayer;
  s: pState;
  loaded: Boolean;
  previous: Double;
  now, dt: Double;
  buffer: PAnsiChar;
  player: pPlayer;
  face_count: Integer;
  text_buffer: array[0..1023] of AnsiChar;
  ts, tx, ty: Single;
  hour: Integer;
  am_pm: Char;
  Index: Integer;
  other: pPlayer;
  pw, ph, offset: Integer;
  pad, sw, sh: Integer;
begin
    // INITIALIZATION //

    //curl_global_init(CURL_GLOBAL_DEFAULT);
    //srand(time(NULL));
    //rand();

    // WINDOW INITIALIZATION //
    if (glfwInit() = 0) then begin
        Exit(-1);
    end;
    create_window();
    if (g.window = nil) then begin
        glfwTerminate();
        Exit(-1);
    end;

    glfwMakeContextCurrent(g.window);
    glfwSwapInterval(VSYNC);
    glfwSetInputMode(g.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glfwSetKeyCallback(g.window, on_key);
    glfwSetCharCallback(g.window, on_char);
    glfwSetMouseButtonCallback(g.window, on_mouse_button);
    glfwSetScrollCallback(g.window, on_scroll);

//    if (glewInit() <> GLEW_OK) then begin
//        Exit(-1);
//    end;

    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glLogicOp(GL_INVERT);
    glClearColor(0, 0, 0, 1);

    // LOAD TEXTURES //
    glGenTextures(1, @texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    load_png_texture('textures/texture.png');

    glGenTextures(1, @font);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, font);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    load_png_texture('textures/font.png');

    glGenTextures(1, @sky);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, sky);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    load_png_texture('textures/sky.png');

    glGenTextures(1, @sign);
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, sign);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    load_png_texture('textures/sign.png');

    // LOAD SHADERS //
    &program := load_program(
        'shaders/block_vertex.glsl', 'shaders/block_fragment.glsl');
    block_attrib.&program := &program;
    block_attrib.position := glGetAttribLocation(&program, 'position');
    block_attrib.normal := glGetAttribLocation(&program, 'normal');
    block_attrib.uv := glGetAttribLocation(&program, 'uv');
    block_attrib.matrix := glGetUniformLocation(&program, 'matrix');
    block_attrib.sampler := glGetUniformLocation(&program, 'sampler');
    block_attrib.extra1 := glGetUniformLocation(&program, 'sky_sampler');
    block_attrib.extra2 := glGetUniformLocation(&program, 'daylight');
    block_attrib.extra3 := glGetUniformLocation(&program, 'fog_distance');
    block_attrib.extra4 := glGetUniformLocation(&program, 'ortho');
    block_attrib.camera := glGetUniformLocation(&program, 'camera');
    block_attrib.timer := glGetUniformLocation(&program, 'timer');

    &program := load_program(
        'shaders/line_vertex.glsl', 'shaders/line_fragment.glsl');
    line_attrib.&program := &program;
    line_attrib.position := glGetAttribLocation(&program, 'position');
    line_attrib.matrix := glGetUniformLocation(&program, 'matrix');

    &program := load_program(
        'shaders/text_vertex.glsl', 'shaders/text_fragment.glsl');
    text_attrib.&program := &program;
    text_attrib.position := glGetAttribLocation(&program, 'position');
    text_attrib.uv := glGetAttribLocation(&program, 'uv');
    text_attrib.matrix := glGetUniformLocation(&program, 'matrix');
    text_attrib.sampler := glGetUniformLocation(&program, 'sampler');
    text_attrib.extra1 := glGetUniformLocation(&program, 'is_sign');

    &program := load_program(
        'shaders/sky_vertex.glsl', 'shaders/sky_fragment.glsl');
    sky_attrib.&program := &program;
    sky_attrib.position := glGetAttribLocation(&program, 'position');
    sky_attrib.normal := glGetAttribLocation(&program, 'normal');
    sky_attrib.uv := glGetAttribLocation(&program, 'uv');
    sky_attrib.matrix := glGetUniformLocation(&program, 'matrix');
    sky_attrib.sampler := glGetUniformLocation(&program, 'sampler');
    sky_attrib.timer := glGetUniformLocation(&program, 'timer');

    // CHECK COMMAND LINE ARGUMENTS //
    if (ParamCount = 1) or (ParamCount = 2) then
    begin
        g.mode := MODE_ONLINE;
        strncpy(g.server_addr, PAnsiChar(AnsiString(ParamStr(1))), MAX_ADDR_LENGTH);
        if ParamCount = 2 then
          g.server_port := atoi(ParamStr(2))
        else
          g.server_port := DEFAULT_PORT;
        snprintf(g.db_path, MAX_PATH_LENGTH,
            'cache.%s.%d.db', [g.server_addr, g.server_port]);
    end
    else begin
        g.mode := MODE_OFFLINE;
        snprintf(g.db_path, MAX_PATH_LENGTH, '%s', [DB_PATH]);
    end;

    g.create_radius := CREATE_CHUNK_RADIUS;
    g.render_radius := RENDER_CHUNK_RADIUS;
    g.delete_radius := DELETE_CHUNK_RADIUS;
    g.sign_radius := RENDER_SIGN_RADIUS;

    // INITIALIZE WORKER THREADS
    for i := 0 to WORKERS - 1 do begin
        worker := @g.workers[i];
        worker.index := i;
        worker.state := WORKER_IDLE;
        mtx_init(worker.mtx, mtx_plain);
        cnd_init(worker.cnd);
        thrd_create(worker.thrd, worker_run, worker);
    end;

    // OUTER LOOP //
    running := 1;
    while (running <> 0) do begin
        // DATABASE INITIALIZATION //
        if (g.mode = MODE_OFFLINE) or (USE_CACHE) then begin
            db_enable();
            if (db_init(g.db_path) <> 0) then begin
                Exit(-1);
            end;
            if (g.mode = MODE_ONLINE) then begin
                // TODO: support proper caching of signs (handle deletions)
                db_delete_all_signs();
            end;
        end;

        // CLIENT INITIALIZATION //
        if (g.mode = MODE_ONLINE) then begin
            client_enable();
            client_connect(g.server_addr, g.server_port);
            client_start();
            client_version(1);
            login();
        end;

        // LOCAL VARIABLES //
        reset_model();
        // fps = {0, 0, 0};
        FillChar(fps, SizeOf(fps), 0);
        last_commit := glfwGetTime();
        last_update := glfwGetTime();
        sky_buffer := gen_sky_buffer();

        me := @g.players;
        s := @g.players[0].state;
        me.id := 0;
        me.name := ''; //[0] := #0;
        me.buffer := 0;
        g.player_count := 1;

        // LOAD STATE FROM DATABASE //
        loaded := db_load_state(s.x, s.y, s.z, s.rx, s.ry);
        force_chunks(me);
        if (not loaded) then begin
            s.y := highest_block(s.x, s.z) + 2;
        end;

        // BEGIN MAIN LOOP //
        previous := glfwGetTime();
        while (True) do begin
            // WINDOW SIZE AND SCALE //
            g.scale := get_scale_factor();
            glfwGetFramebufferSize(g.window, @g.width, @g.height);
            glViewport(0, 0, g.width, g.height);

            // FRAME RATE //
            if (g.time_changed <> 0) then begin
                g.time_changed := 0;
                last_commit := glfwGetTime();
                last_update := glfwGetTime();
                FillChar(fps, sizeof(fps), 0);
            end;
            update_fps(@fps);
            now := glfwGetTime();
            dt := now - previous;
            dt := MIN(dt, 0.2);
            dt := MAX(dt, 0.0);
            previous := now;

            // HANDLE MOUSE INPUT //
            handle_mouse_input();

            // HANDLE MOVEMENT //
            handle_movement(dt);

            // HANDLE DATA FROM SERVER //
            buffer := client_recv();
            if (buffer <> nil) then begin
                parse_buffer(buffer);
                freemem(buffer);
            end;

            // FLUSH DATABASE //
            if (now - last_commit > COMMIT_INTERVAL) then begin
                last_commit := now;
                db_commit();
            end;

            // SEND POSITION TO SERVER //
            if (now - last_update > 0.1) then begin
                last_update := now;
                client_position(s.x, s.y, s.z, s.rx, s.ry);
            end;

            // PREPARE TO RENDER //
            g.observe1 := g.observe1 mod g.player_count;
            g.observe2 := g.observe2 mod g.player_count;
            delete_chunks();
            del_buffer(me.buffer);
            me.buffer := gen_player_buffer(s.x, s.y, s.z, s.rx, s.ry);
            for i := 1 to g.player_count - 1 do begin
                interpolate_player(@g.players[i]);
            end;
            player := @g.players[g.observe1];

            // RENDER 3-D SCENE //
            glClear(GL_COLOR_BUFFER_BIT);
            glClear(GL_DEPTH_BUFFER_BIT);
            render_sky(&sky_attrib, player, sky_buffer);
            glClear(GL_DEPTH_BUFFER_BIT);
            face_count := render_chunks(block_attrib, player);
            render_signs(text_attrib, player);
            render_sign(text_attrib, player);
            render_players(block_attrib, player);
            if (SHOW_WIREFRAME) then begin
                render_wireframe(line_attrib, player);
            end;

            // RENDER HUD //
            glClear(GL_DEPTH_BUFFER_BIT);
            if (SHOW_CROSSHAIRS) then begin
                render_crosshairs(line_attrib);
            end;
            if (SHOW_ITEM) then begin
                render_item(block_attrib);
            end;

            // RENDER TEXT //
            ts := 12 * g.scale;
            tx := ts / 2;
            ty := g.height - ts;
            if (SHOW_INFO_TEXT) then begin
                hour := Round(time_of_day() * 24);
                if hour < 12 then am_pm := 'a' else am_pm := 'p';
                hour := hour mod 12;
                if hour = 0 then hour := 12;
                snprintf(
                    text_buffer, 1024,
                    '(%d, %d) (%.2f, %.2f, %.2f) [%d, %d, %d] %d%cm %dfps',
                    [chunked(s.x), chunked(s.z), s.x, s.y, s.z,
                    g.player_count, g.chunk_count,
                    face_count * 2, hour, am_pm, fps.fps]);
                render_text(text_attrib, ALIGN_LEFT, tx, ty, ts, text_buffer);
                ty := ty - ts * 2;
            end;
            if (SHOW_CHAT_TEXT) then begin
                for i := 0 to MAX_MESSAGES - 1 do begin
                    index := (g.message_index + i) mod MAX_MESSAGES;
                    if (strlen(g.messages[index]) > 0) then begin
                        render_text(text_attrib, ALIGN_LEFT, tx, ty, ts,
                            g.messages[index]);
                        ty := ty - ts * 2;
                    end;
                end;
            end;
            if (g.typing <> 0) then begin
                snprintf(text_buffer, 1024, '> %s', [g.typing_buffer]);
                render_text(&text_attrib, ALIGN_LEFT, tx, ty, ts, text_buffer);
                //ty := ty - ts * 2;
            end;
            if (SHOW_PLAYER_NAMES) then begin
                if (player <> me) then begin
                    render_text(&text_attrib, ALIGN_CENTER,
                        g.width / 2, ts, ts, player.name);
                end;
                other := player_crosshair(player);
                if (other <> nil) then begin
                    render_text(&text_attrib, ALIGN_CENTER,
                        g.width / 2, g.height / 2 - ts - 24, ts,
                        other.name);
                end;
            end;

            // RENDER PICTURE IN PICTURE //
            if (g.observe2 <> 0) then begin
                player := @g.players[g.observe2];

                pw := 256 * g.scale;
                ph := 256 * g.scale;
                offset := 32 * g.scale;
                pad := 3 * g.scale;
                sw := pw + pad * 2;
                sh := ph + pad * 2;

                glEnable(GL_SCISSOR_TEST);
                glScissor(g.width - sw - offset + pad, offset - pad, sw, sh);
                glClear(GL_COLOR_BUFFER_BIT);
                glDisable(GL_SCISSOR_TEST);
                glClear(GL_DEPTH_BUFFER_BIT);
                glViewport(g.width - pw - offset, offset, pw, ph);

                g.width := pw;
                g.height := ph;
                g.ortho := 0;
                g.fov := 65;

                render_sky(&sky_attrib, player, sky_buffer);
                glClear(GL_DEPTH_BUFFER_BIT);
                render_chunks(&block_attrib, player);
                render_signs(&text_attrib, player);
                render_players(&block_attrib, player);
                glClear(GL_DEPTH_BUFFER_BIT);
                if (SHOW_PLAYER_NAMES) then begin
                    render_text(&text_attrib, ALIGN_CENTER,
                        pw / 2, ts, ts, player.name);
                end;
            end;

            // SWAP AND POLL //
            glfwSwapBuffers(g.window);
            glfwPollEvents();
            if (glfwWindowShouldClose(g.window) <> 0) then begin
                running := 0;
                break;
            end;
            if (g.mode_changed <> 0) then begin
                g.mode_changed := 0;
                break;
            end;
        end;

        // SHUTDOWN //
        db_save_state(s.x, s.y, s.z, s.rx, s.ry);
        db_close();
        db_disable();
        client_stop();
        client_disable();
        del_buffer(sky_buffer);
        delete_all_chunks();
        delete_all_players();
    end;

    glfwTerminate();
//    curl_global_cleanup();
//    return 0;
end;

end.
