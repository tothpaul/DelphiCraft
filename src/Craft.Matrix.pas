unit Craft.Matrix;

interface

uses
  System.Math;

type
  TPlanes = array[0..5, 0..3] of Single;

procedure normalize(var x, y, z: Single);
procedure mat_identity(matrix: PSingle);
procedure mat_translate(matrix: PSingle; dx, dy, dz: Single);
procedure mat_rotate(matrix: PSingle; x, y, z, angle: Single);
procedure mat_multiply(matrix, a, b: PSingle);
procedure mat_apply(data, matrix: PSingle; count, offset, stride: Integer);
procedure frustum_planes(var planes: TPlanes; radius: Integer; matrix: PSingle);

procedure set_matrix_2d(matrix: PSingle; width, height: Integer);

procedure set_matrix_3d(
    matrix: PSingle; width, height: Integer;
    x, y, z, rx, ry, fov: Single;
    ortho, radius: Integer);

procedure set_matrix_item(matrix: PSingle; width, height, scale: Integer);

implementation
{$POINTERMATH ON}

procedure normalize(var x, y, z: Single);
var
  d: Single;
begin
  d := sqrt(x * x + y * y + z * z);
  x := x/d;
  y := y/d;
  z := z/d;
end;

procedure mat_identity(matrix: PSingle);
begin
    matrix[0] := 1;
    matrix[1] := 0;
    matrix[2] := 0;
    matrix[3] := 0;
    matrix[4] := 0;
    matrix[5] := 1;
    matrix[6] := 0;
    matrix[7] := 0;
    matrix[8] := 0;
    matrix[9] := 0;
    matrix[10] := 1;
    matrix[11] := 0;
    matrix[12] := 0;
    matrix[13] := 0;
    matrix[14] := 0;
    matrix[15] := 1;
end;

procedure mat_translate(matrix: PSingle; dx, dy, dz: Single);
begin
    matrix[0] := 1;
    matrix[1] := 0;
    matrix[2] := 0;
    matrix[3] := 0;
    matrix[4] := 0;
    matrix[5] := 1;
    matrix[6] := 0;
    matrix[7] := 0;
    matrix[8] := 0;
    matrix[9] := 0;
    matrix[10] := 1;
    matrix[11] := 0;
    matrix[12] := dx;
    matrix[13] := dy;
    matrix[14] := dz;
    matrix[15] := 1;
end;

procedure mat_rotate(matrix: PSingle; x, y, z, angle: Single);
var
  s, c: Single;
  m: Single;
begin
  normalize(x, y, z);
  s := sin(angle);
  c := cos(angle);
  m := 1 - c;
  matrix[0] := m * x * x + c;
  matrix[1] := m * x * y - z * s;
  matrix[2] := m * z * x + y * s;
  matrix[3] := 0;
  matrix[4] := m * x * y + z * s;
  matrix[5] := m * y * y + c;
  matrix[6] := m * y * z - x * s;
  matrix[7] := 0;
  matrix[8] := m * z * x - y * s;
  matrix[9] := m * y * z + x * s;
  matrix[10] := m * z * z + c;
  matrix[11] := 0;
  matrix[12] := 0;
  matrix[13] := 0;
  matrix[14] := 0;
  matrix[15] := 1;
end;

procedure mat_vec_multiply(vector, a, b: PSingle);
var
  result: array[0..3] of Single;
  i: Integer;
  total: Single;
  j: Integer;
  p, q: Integer;
begin
    for i := 0 to 3 do begin
        total := 0;
        for j := 0 to 3 do begin
            p := j * 4 + i;
            q := j;
            total := total + a[p] * b[q];
        end;
        result[i] := total;
    end;
    for i := 0 to 3 do begin
        vector[i] := result[i];
    end;
end;

procedure mat_multiply(matrix, a, b: PSingle);
var
  result: array[0..15] of Single;
  c, r: Integer;
  index: Integer;
  total: Single;
  i,p,q: Integer;
begin
  for c := 0 to 3 do
  begin
    for r := 0 to 3 do
    begin
      index := c * 4 + r;
      total := 0;
      for i := 0 to 3 do
      begin
        p := i * 4 + r;
        q := c * 4 + i;
        total := total + a[p] * b[q];
      end;
      result[index] := total;
    end;
  end;
  for i := 0 to 15 do
  begin
    matrix[i] := result[i];
  end;
end;

procedure mat_apply(data, matrix: PSingle; count, offset, stride: Integer);
var
  vec: array[0..3] of Single;
  i: Integer;
  d: PSingle;
begin
    vec[3] := 1;
    for i := 0 to count - 1 do begin
        d := @data[offset + stride * i];
        vec[0] := d^; Inc(d); vec[1] := d^; Inc(d); vec[2] := d^;
        mat_vec_multiply(@vec, matrix, @vec);
        d := @data[offset + stride * i];
        d^ := vec[0]; Inc(d); d^ := vec[1]; Inc(d); d^ := vec[2];
    end;
end;

procedure frustum_planes(var planes: TPlanes; radius: Integer; matrix: PSingle);
var
  znear, zfar: Single;
  m: PSingle;
begin
    znear := 0.125;
    zfar := radius * 32 + 64;
    m := matrix;
    planes[0][0] := m[3] + m[0];
    planes[0][1] := m[7] + m[4];
    planes[0][2] := m[11] + m[8];
    planes[0][3] := m[15] + m[12];
    planes[1][0] := m[3] - m[0];
    planes[1][1] := m[7] - m[4];
    planes[1][2] := m[11] - m[8];
    planes[1][3] := m[15] - m[12];
    planes[2][0] := m[3] + m[1];
    planes[2][1] := m[7] + m[5];
    planes[2][2] := m[11] + m[9];
    planes[2][3] := m[15] + m[13];
    planes[3][0] := m[3] - m[1];
    planes[3][1] := m[7] - m[5];
    planes[3][2] := m[11] - m[9];
    planes[3][3] := m[15] - m[13];
    planes[4][0] := znear * m[3] + m[2];
    planes[4][1] := znear * m[7] + m[6];
    planes[4][2] := znear * m[11] + m[10];
    planes[4][3] := znear * m[15] + m[14];
    planes[5][0] := zfar * m[3] - m[2];
    planes[5][1] := zfar * m[7] - m[6];
    planes[5][2] := zfar * m[11] - m[10];
    planes[5][3] := zfar * m[15] - m[14];
end;

procedure mat_frustum(
    matrix: PSingle; left, right, bottom,
    top, znear, zfar: Single);
var
  temp, temp2, temp3, temp4: Single;
begin
  temp := 2.0 * znear;
  temp2 := right - left;
  temp3 := top - bottom;
  temp4 := zfar - znear;
  matrix[0] := temp / temp2;
  matrix[1] := 0.0;
  matrix[2] := 0.0;
  matrix[3] := 0.0;
  matrix[4] := 0.0;
  matrix[5] := temp / temp3;
  matrix[6] := 0.0;
  matrix[7] := 0.0;
  matrix[8] := (right + left) / temp2;
  matrix[9] := (top + bottom) / temp3;
  matrix[10] := (-zfar - znear) / temp4;
  matrix[11] := -1.0;
  matrix[12] := 0.0;
  matrix[13] := 0.0;
  matrix[14] := (-temp * zfar) / temp4;
  matrix[15] := 0.0;
end;

procedure mat_perspective(
    matrix: PSingle; fov, aspect,
    znear, zfar: Single);
var
  ymax, xmax: Single;
begin
  ymax := znear * tan(fov * PI / 360.0);
  xmax := ymax * aspect;
  mat_frustum(matrix, -xmax, xmax, -ymax, ymax, znear, zfar);
end;

procedure mat_ortho(
    matrix: PSingle;
    left, right, bottom, top, &near, &far: Single);
begin
  matrix[0] := 2 / (right - left);
  matrix[1] := 0;
  matrix[2] := 0;
  matrix[3] := 0;
  matrix[4] := 0;
  matrix[5] := 2 / (top - bottom);
  matrix[6] := 0;
  matrix[7] := 0;
  matrix[8] := 0;
  matrix[9] := 0;
  matrix[10] := -2 / (&far - &near);
  matrix[11] := 0;
  matrix[12] := -(right + left) / (right - left);
  matrix[13] := -(top + bottom) / (top - bottom);
  matrix[14] := -(&far + &near) / (&far - &near);
  matrix[15] := 1;
end;

procedure set_matrix_2d(matrix: PSingle; width, height: Integer);
begin
    mat_ortho(matrix, 0, width, 0, height, -1, 1);
end;

procedure set_matrix_3d(
    matrix: PSingle; width, height: Integer;
    x, y, z, rx, ry, fov: Single;
    ortho, radius: Integer);
var
  a, b: array[0..15] of Single;
  aspect: Single;
  znear : Single;
  zfar  : Single;
  size  : Integer;
begin
  aspect := width / height;
  znear := 0.125;
  zfar := radius * 32 + 64;
  mat_identity(@a);
  mat_translate(@b, -x, -y, -z);
  mat_multiply(@a, @b, @a);
  mat_rotate(@b, cos(rx), 0, sin(rx), ry);
  mat_multiply(@a, @b, @a);
  mat_rotate(@b, 0, 1, 0, -rx);
  mat_multiply(@a, @b, @a);
  if (ortho <> 0) then
  begin
    size := ortho;
    mat_ortho(@b, -size * aspect, size * aspect, -size, size, -zfar, zfar);
  end else begin
    mat_perspective(@b, fov, aspect, znear, zfar);
  end;
  mat_multiply(@a, @b, @a);
  mat_identity(matrix);
  mat_multiply(matrix, @a, matrix);
end;

procedure set_matrix_item(matrix: PSingle; width, height, scale: Integer);
var
  a, b: array[0..15] of Single;
  aspect, size, box, xoffset, yoffset: Single;
begin
    aspect := width / height;
    size := 64 * scale;
    box := height / size / 2;
    xoffset := 1 - size / width * 2;
    yoffset := 1 - size / height * 2;
    mat_identity(@a);
    mat_rotate(@b, 0, 1, 0, -PI / 4);
    mat_multiply(@a, @b, @a);
    mat_rotate(@b, 1, 0, 0, -PI / 10);
    mat_multiply(@a, @b, @a);
    mat_ortho(@b, -box * aspect, box * aspect, -box, box, -1, 1);
    mat_multiply(@a, @b, @a);
    mat_translate(@b, -xoffset, -yoffset, 0);
    mat_multiply(@a, @b, @a);
    mat_identity(matrix);
    mat_multiply(matrix, @a, matrix);
end;

end.
