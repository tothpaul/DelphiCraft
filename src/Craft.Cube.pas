unit Craft.Cube;

interface
{$POINTERMATH ON}
uses
  System.Math,
  Craft.Util,
  Craft.Item,
  Craft.Matrix;

procedure make_cube(
    data: PSingle; const ao, light: tfloat_6_4;
    left, right, top, bottom, front, back: Boolean;
    x, y, z, n: Single; w: Integer);

procedure make_plant(
    data: PSingle; ao, light,
    px, py, pz, n: Single; w: Integer; rotation: Single);

procedure make_player(
    data: PSingle; x, y, z, rx, ry: Single);

procedure make_cube_wireframe(data: PSingle; x, y, z, n: Single);

procedure make_character(
    data: PSingle;
    x, y, n, m: Single; c: AnsiChar);

procedure make_character_3d(
    data: PSingle; x, y, z, n: Single; face: Integer; c: AnsiChar);

procedure make_sphere(data: PSingle; r: Single; detail: Integer);

implementation

procedure make_cube_faces(
    data: PSingle; const ao, light: tfloat_6_4;
    left, right, top, bottom, front, back: Boolean;
    wleft, wright, wtop, wbottom, wfront, wback: Integer;
    x, y, z, n: Single);
const
    positions: array[0..5, 0..3, 0..2] of Single = (
        ((-1, -1, -1), (-1, -1, +1), (-1, +1, -1), (-1, +1, +1)),
        ((+1, -1, -1), (+1, -1, +1), (+1, +1, -1), (+1, +1, +1)),
        ((-1, +1, -1), (-1, +1, +1), (+1, +1, -1), (+1, +1, +1)),
        ((-1, -1, -1), (-1, -1, +1), (+1, -1, -1), (+1, -1, +1)),
        ((-1, -1, -1), (-1, +1, -1), (+1, -1, -1), (+1, +1, -1)),
        ((-1, -1, +1), (-1, +1, +1), (+1, -1, +1), (+1, +1, +1))
    );
    normals: array[0..5, 0..2] of Single = (
        (-1, 0, 0),
        (+1, 0, 0),
        (0, +1, 0),
        (0, -1, 0),
        (0, 0, -1),
        (0, 0, +1)
    );
    uvs: array[0..5, 0..3, 0..1] of Byte = (
        ((0, 0), (1, 0), (0, 1), (1, 1)),
        ((1, 0), (0, 0), (1, 1), (0, 1)),
        ((0, 1), (0, 0), (1, 1), (1, 0)),
        ((0, 0), (0, 1), (1, 0), (1, 1)),
        ((0, 0), (0, 1), (1, 0), (1, 1)),
        ((1, 0), (1, 1), (0, 0), (0, 1))
    );
    indices: array[0..5, 0..5] of Integer = (
        (0, 3, 2, 0, 1, 3),
        (0, 3, 1, 0, 2, 3),
        (0, 3, 2, 0, 1, 3),
        (0, 3, 1, 0, 2, 3),
        (0, 3, 2, 0, 1, 3),
        (0, 3, 1, 0, 2, 3)
    );
    flipped: array[0..5, 0..5] of Integer = (
        (0, 1, 2, 1, 3, 2),
        (0, 2, 1, 2, 3, 1),
        (0, 1, 2, 1, 3, 2),
        (0, 2, 1, 2, 3, 1),
        (0, 1, 2, 1, 3, 2),
        (0, 2, 1, 2, 3, 1)
    );
var
  d: PSingle;
  s, a, b: Single;
  faces: array[0..5] of Boolean;
  tiles: array[0..5] of Integer;
  i: Integer;
  du, dv: Single;
  flip: Boolean;
  v, j: Integer;
begin
    d := data;
    s := 0.0625;
    a := 0 + 1 / 2048.0;
    b := s - 1 / 2048.0;
    faces[0] := left;
    faces[1] := right;
    faces[2] := top;
    faces[3] := bottom;
    faces[4] := front;
    faces[5] := back;
    tiles[0] := wleft;
    tiles[1] := wright;
    tiles[2] := wtop;
    tiles[3] := wbottom;
    tiles[4] := wfront;
    tiles[5] := wback;
    for i := 0 to 5 do begin
        if (faces[i] = False) then begin
            continue;
        end;
        du := (tiles[i] mod 16) * s;
        dv := (tiles[i] div 16) * s;
        flip := ao[i][0] + ao[i][3] > ao[i][1] + ao[i][2];
        for v := 0 to 5 do begin
            if flip then
              j := flipped[i, v]
            else
              j := indices[i, v];
            d^ := x + n * positions[i][j][0]; Inc(d);
            d^ := y + n * positions[i][j][1]; Inc(d);
            d^ := z + n * positions[i][j][2]; Inc(d);
            d^ := normals[i][0]; Inc(d);
            d^ := normals[i][1]; Inc(d);
            d^ := normals[i][2]; Inc(d);
            if uvs[i][j][0] <> 0 then
              d^ := du + b
            else
              d^ := du + a;
            Inc(d);
            if uvs[i][j][1] <> 0 then
              d^ := dv + b
            else
              d^ := dv + a;
            Inc(d);
            d^ := ao[i][j]; Inc(d);
            d^ := light[i][j]; Inc(d);
        end;
    end;
end;

procedure make_cube(
    data: PSingle; const ao, light: tfloat_6_4;
    left, right, top, bottom, front, back: Boolean;
    x, y, z, n: Single; w: Integer);
var
  wleft, wright, wtop, wbottom, wfront, wback: Integer;
begin
    wleft := blocks[w][0];
    wright := blocks[w][1];
    wtop := blocks[w][2];
    wbottom := blocks[w][3];
    wfront := blocks[w][4];
    wback := blocks[w][5];
    make_cube_faces(
        data, ao, light,
        left, right, top, bottom, front, back,
        wleft, wright, wtop, wbottom, wfront, wback,
        x, y, z, n);
end;

procedure make_plant(
    data: PSingle; ao, light,
    px, py, pz, n: Single; w: Integer; rotation: Single);
const
    positions:array[0..3,0..3,0..2] of Single = (
        (( 0, -1, -1), ( 0, -1, +1), ( 0, +1, -1), ( 0, +1, +1)),
        (( 0, -1, -1), ( 0, -1, +1), ( 0, +1, -1), ( 0, +1, +1)),
        ((-1, -1,  0), (-1, +1,  0), (+1, -1,  0), (+1, +1,  0)),
        ((-1, -1,  0), (-1, +1,  0), (+1, -1,  0), (+1, +1,  0))
    );
    normals: array[0..3, 0..2] of Single = (
        (-1, 0, 0),
        (+1, 0, 0),
        (0, 0, -1),
        (0, 0, +1)
    );
    uvs: array[0..3, 0..3, 0..1] of Single = (
        ((0, 0), (1, 0), (0, 1), (1, 1)),
        ((1, 0), (0, 0), (1, 1), (0, 1)),
        ((0, 0), (0, 1), (1, 0), (1, 1)),
        ((1, 0), (1, 1), (0, 0), (0, 1))
    );
    indices: array[0..3, 0..5] of Integer = (
        (0, 3, 2, 0, 1, 3),
        (0, 3, 1, 0, 2, 3),
        (0, 3, 2, 0, 1, 3),
        (0, 3, 1, 0, 2, 3)
    );
var
  d: pSingle;
  s, a, b: Single;
  du, dv: Single;
  i, v, j: Integer;
  ma, mb: array[0..15] of Single;
begin
    d := data;
    s := 0.0625;
    a := 0;
    b := s;
    du := (plants[w] mod 16) * s;
    dv := (plants[w] div 16) * s;
    for i := 0 to 3 do begin
        for v := 0 to 5 do begin
            j := indices[i][v];
            d^ := n * positions[i][j][0]; Inc(d);
            d^ := n * positions[i][j][1]; Inc(d);
            d^ := n * positions[i][j][2]; Inc(d);
            d^ := normals[i][0]; Inc(d);
            d^ := normals[i][1]; Inc(d);
            d^ := normals[i][2]; Inc(d);
            if uvs[i][j][0] <> 0 then
              d^ := du + b
            else
              d^ := du + a;
            Inc(d);
            if uvs[i][j][1] <> 0 then
              d^ := dv + b
            else
              d^ := dv + a;
            Inc(d);
            d^ := ao; Inc(d);
            d^ := light; Inc(d);
        end;
    end;
    mat_identity(@ma);
    mat_rotate(@mb, 0, 1, 0, RADIANS(rotation));
    mat_multiply(@ma, @mb, @ma);
    mat_apply(data, @ma, 24, 3, 10);
    mat_translate(@mb, px, py, pz);
    mat_multiply(@ma, @mb, @ma);
    mat_apply(data, @ma, 24, 0, 10);
end;


procedure make_player(
    data: PSingle;
    x, y, z, rx, ry: Single);
var
    ao: tfloat_6_4;
const
    light: tfloat_6_4 = (
        (0.8, 0.8, 0.8, 0.8),
        (0.8, 0.8, 0.8, 0.8),
        (0.8, 0.8, 0.8, 0.8),
        (0.8, 0.8, 0.8, 0.8),
        (0.8, 0.8, 0.8, 0.8),
        (0.8, 0.8, 0.8, 0.8)
    );
var
  ma, mb:array[0..15] of Single;
begin
    FillChar(ao, SizeOf(ao), 0);
    make_cube_faces(
        data, ao, light,
        true, true, true, true, true, true,
        226, 224, 241, 209, 225, 227,
        0, 0, 0, 0.4);
    mat_identity(@ma);
    mat_rotate(@mb, 0, 1, 0, rx);
    mat_multiply(@ma, @mb, @ma);
    mat_rotate(@mb, cos(rx), 0, sin(rx), -ry);
    mat_multiply(@ma, @mb, @ma);
    mat_apply(data, @ma, 36, 3, 10);
    mat_translate(@mb, x, y, z);
    mat_multiply(@ma, @mb, @ma);
    mat_apply(data, @ma, 36, 0, 10);
end;

procedure make_cube_wireframe(data: PSingle; x, y, z, n: Single);
const
  positions:array[0..7,0..2] of Single = (
        (-1, -1, -1),
        (-1, -1, +1),
        (-1, +1, -1),
        (-1, +1, +1),
        (+1, -1, -1),
        (+1, -1, +1),
        (+1, +1, -1),
        (+1, +1, +1)
    );
  indices: array[0..23] of Integer = (
        0, 1, 0, 2, 0, 4, 1, 3,
        1, 5, 2, 3, 2, 6, 3, 7,
        4, 5, 4, 6, 5, 7, 6, 7
    );
var
  d: PSingle;
  i, j: Integer;
begin
    d := data;
    for i := 0 to 23 do begin
        j := indices[i];
        d^ := x + n * positions[j][0]; Inc(d);
        d^ := y + n * positions[j][1]; Inc(d);
        d^ := z + n * positions[j][2]; Inc(d);
    end;
end;

procedure make_character(
    data: PSingle;
    x, y, n, m: Single; c: AnsiChar);
var
  d: PSingle;
  s, a, b: Single;
  w: Integer;
  du, dv: Single;
begin
    d := data;
    s := 0.0625;
    a := s;
    b := s * 2;
    w := Ord(c) - 32;
    du := (w mod 16) * a;
    dv := 1 - (w div 16) * b - b;
    d^ := x - n; Inc(d); d^ := y - m; Inc(d);
    d^ := du + 0; Inc(d); d^ := dv; Inc(d);
    d^ := x + n; Inc(d); d^ := y - m; Inc(d);
    d^ := du + a; Inc(d); d^ := dv; Inc(d);
    d^ := x + n; Inc(d); d^ := y + m; Inc(d);
    d^ := du + a; Inc(d); d^ := dv + b; Inc(d);
    d^ := x - n; Inc(d); d^ := y - m; Inc(d);
    d^ := du + 0; Inc(d); d^ := dv; Inc(d);
    d^ := x + n; Inc(d); d^ := y + m; Inc(d);
    d^ := du + a; Inc(d); d^ := dv + b; Inc(d);
    d^ := x - n; Inc(d); d^ := y + m; Inc(d);
    d^ := du + 0; Inc(d); d^ := dv + b; Inc(d);
end;

procedure make_character_3d(
    data: PSingle; x, y, z, n: Single; face: Integer; c: AnsiChar);
const
  positions: array[0..7,0..5,0..2] of Single = (
        ((0, -2, -1), (0, +2, +1), (0, +2, -1),
         (0, -2, -1), (0, -2, +1), (0, +2, +1)),
        ((0, -2, -1), (0, +2, +1), (0, -2, +1),
         (0, -2, -1), (0, +2, -1), (0, +2, +1)),
        ((-1, -2, 0), (+1, +2, 0), (+1, -2, 0),
         (-1, -2, 0), (-1, +2, 0), (+1, +2, 0)),
        ((-1, -2, 0), (+1, -2, 0), (+1, +2, 0),
         (-1, -2, 0), (+1, +2, 0), (-1, +2, 0)),
        ((-1, 0, +2), (+1, 0, +2), (+1, 0, -2),
         (-1, 0, +2), (+1, 0, -2), (-1, 0, -2)),
        ((-2, 0, +1), (+2, 0, -1), (-2, 0, -1),
         (-2, 0, +1), (+2, 0, +1), (+2, 0, -1)),
        ((+1, 0, +2), (-1, 0, -2), (-1, 0, +2),
         (+1, 0, +2), (+1, 0, -2), (-1, 0, -2)),
        ((+2, 0, -1), (-2, 0, +1), (+2, 0, +1),
         (+2, 0, -1), (-2, 0, -1), (-2, 0, +1))
    );
  uvs: array[0..7,0..5,0..1] of Single = (
        ((0, 0), (1, 1), (0, 1), (0, 0), (1, 0), (1, 1)),
        ((1, 0), (0, 1), (0, 0), (1, 0), (1, 1), (0, 1)),
        ((1, 0), (0, 1), (0, 0), (1, 0), (1, 1), (0, 1)),
        ((0, 0), (1, 0), (1, 1), (0, 0), (1, 1), (0, 1)),
        ((0, 0), (1, 0), (1, 1), (0, 0), (1, 1), (0, 1)),
        ((0, 1), (1, 0), (1, 1), (0, 1), (0, 0), (1, 0)),
        ((0, 1), (1, 0), (1, 1), (0, 1), (0, 0), (1, 0)),
        ((0, 1), (1, 0), (1, 1), (0, 1), (0, 0), (1, 0))
    );
  offsets: array[0..7,0..2] of single= (
        (-1, 0, 0), (+1, 0, 0), (0, 0, -1), (0, 0, +1),
        (0, +1, 0), (0, +1, 0), (0, +1, 0), (0, +1, 0)
    );
var
  d: pSingle;
  s: Single;
  pu: Single;
  pv: Single;
  u1, v1, u2, v2: Single;
  p: Single;
  w: Integer;
  du, dv: Single;
  i: Integer;
begin
   d := data;
   s := 0.0625;
   pu := s / 5;
   pv := s / 2.5;
   u1 := pu;
   v1 := pv;
   u2 := s - pu;
   v2 := s * 2 - pv;
   p := 0.5;
   w := Ord(c) - 32;
   du := (w mod 16) * s;
   dv := 1 - (w div 16 + 1) * s * 2;
   x := x + p * offsets[face][0];
   y := y + p * offsets[face][1];
   z := z + p * offsets[face][2];
   for i := 0 to 5 do
   begin
     d^ := x + n * positions[face][i][0]; Inc(d);
     d^ := y + n * positions[face][i][1]; Inc(d);
     d^ := z + n * positions[face][i][2]; Inc(d);
     if uvs[face][i][0] <> 0 then
       d^ := du + u2
     else
       d^ := du + u1;
     Inc(d);
     if uvs[face][i][1] <> 0 then
       d^ := dv + v2
     else
       d^ := dv + v1;
     Inc(d);
   end;
end;

function _make_sphere(
    data: PSingle; r: Single; detail: Integer;
    a, b, c, ta, tb, tc: PSingle): Integer;
var
  d: PSingle;
  ab, ac, bc: array[0..2] of Single;
  i: Integer;
  tab, tac, tbc: array[0..1] of Single;
  n: Integer;
begin
  if (detail = 0) then
  begin
    d := data;
    d^ := a[0] * r; Inc(d);
    d^ := a[1] * r; Inc(d);
    d^ := a[2] * r; Inc(d);

    d^ := a[0]; Inc(d);
    d^ := a[1]; Inc(d);
    d^ := a[2]; Inc(d);

    d^ := ta[0]; Inc(d);
    d^ := ta[1]; Inc(d);

    d^ := b[0] * r; Inc(d);
    d^ := b[1] * r; Inc(d);
    d^ := b[2] * r; Inc(d);

    d^ := b[0]; Inc(d);
    d^ := b[1]; Inc(d);
    d^ := b[2]; Inc(d);

    d^ := tb[0]; Inc(d);
    d^ := tb[1]; Inc(d);

    d^ := c[0] * r; Inc(d);
    d^ := c[1] * r; Inc(d);
    d^ := c[2] * r; Inc(d);

    d^ := c[0]; Inc(d);
    d^ := c[1]; Inc(d);
    d^ := c[2]; Inc(d);

    d^ := tc[0]; Inc(d);
    d^ := tc[1]; Inc(d);
    Exit(1);
  end;
  for i := 0 to 2 do
  begin
    ab[i] := (a[i] + b[i]) / 2;
    ac[i] := (a[i] + c[i]) / 2;
    bc[i] := (b[i] + c[i]) / 2;
  end;
  normalize(ab[0], ab[1], ab[2]);
  normalize(ac[0], ac[1], ac[2]);
  normalize(bc[0], bc[1], bc[2]);
  tab[0] := 0; tab[1] := 1 - arccos(ab[1]) / PI;
  tac[0] := 0; tac[1] := 1 - arccos(ac[1]) / PI;
  tbc[0] := 0; tbc[1] := 1 - arccos(bc[1]) / PI;
  Result := 0;
  n := _make_sphere(data, r, detail - 1, a, @ab, @ac, ta, @tab, @tac);
  Inc(result, n); Inc(data, n * 24);
  n := _make_sphere(data, r, detail - 1, b, @bc, @ab, tb, @tbc, @tab);
  Inc(Result, n); Inc(data, n * 24);
  n := _make_sphere(data, r, detail - 1, c, @ac, @bc, tc, @tac, @tbc);
  Inc(Result, n); Inc(data, n * 24);
  n := _make_sphere(data, r, detail - 1, @ab, @bc, @ac, @tab, @tbc, @tac);
  Inc(Result, n); Inc(data, n * 24);
end;

procedure make_sphere(data: PSingle; r: Single; detail: Integer);
// detail, triangles, floats
// 0, 8, 192
// 1, 32, 768
// 2, 128, 3072
// 3, 512, 12288
// 4, 2048, 49152
// 5, 8192, 196608
// 6, 32768, 786432
// 7, 131072, 3145728
const
  indices: array[0..7, 0..2] of Integer = (
    (4, 3, 0), (1, 4, 0),
    (3, 4, 5), (4, 1, 5),
    (0, 3, 2), (0, 2, 1),
    (5, 2, 3), (5, 1, 2)
  );
  positions: array[0..5, 0..2] of Single = (
    ( 0, 0,-1), ( 1, 0, 0),
    ( 0,-1, 0), (-1, 0, 0),
    ( 0, 1, 0), ( 0, 0, 1)
  );
  uvs: array[0..5, 0..1] of Single = (
    (0, 0.5), (0, 0.5),
    (0, 0), (0, 0.5),
    (0, 1), (0, 0.5)
  );
var
  total: Integer;
  i, n : Integer;
begin
  total := 0;
  for i := 0 to 7 do
  begin
    n := _make_sphere(
            data, r, detail,
            @positions[indices[i][0]],
            @positions[indices[i][1]],
            @positions[indices[i][2]],
            @uvs[indices[i][0]],
            @uvs[indices[i][1]],
            @uvs[indices[i][2]]
    );
    Inc(total, n);
    Inc(data, n * 24);
  end;
end;

end.
