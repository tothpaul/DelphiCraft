unit CaseyDuncan.noise;

// Delphi Tokyo translation (c)2017 by Execute SARL
// http://www.execute.fr

(*
noise.h and noise.c are derived from this project:

https://github.com/caseman/noise

Copyright (c) 2008 Casey Duncan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*)

interface

function simplex2(
    x, y: Single;
    octaves: Integer; persistence, lacunarity: Single): Single;

function simplex3(
    x, y, z: Single;
    octaves: Integer; persistence, lacunarity: Single): Single;

implementation

function floorf(X: Single): Single;
begin
  Result := Trunc(X);
  if Frac(X) < 0 then
    Result := Result - 1;
end;

const
  F2 = 0.3660254037844386;
  G2 = 0.21132486540518713;

  F3 = 1.0 / 3.0;

  G3 = 1.0 / 6.0;

//#define ASSIGN(a, v0, v1, v2) (a)[0] = v0; (a)[1] = v1; (a)[2] = v2;
type
  TInteger3 = array[0..2] of Integer;

procedure ASSIGN(var a: TInteger3; v0, v1, v2: Integer); inline;
begin
  a[0] := v0;
  a[1] := v1;
  a[2] := v2;
end;

//#define DOT3(v1, v2) ((v1)[0] * (v2)[0] + (v1)[1] * (v2)[1] + (v1)[2] * (v2)[2])
type
  TSingle3 = array[0..2] of Single;

function DOT3(const v1, v2: TSingle3): Single; inline;
begin
  Result := v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
end;

const
  GRAD3: array[0..15] of TSingle3 = (
    ( 1, 1, 0), (-1, 1, 0), ( 1,-1, 0), (-1,-1, 0),
    ( 1, 0, 1), (-1, 0, 1), ( 1, 0,-1), (-1, 0,-1),
    ( 0, 1, 1), ( 0,-1, 1), ( 0, 1,-1), ( 0,-1,-1),
    ( 1, 0,-1), (-1, 0,-1), ( 0,-1, 1), ( 0, 1, 1)
  );

  PERM: array[0..511] of Byte = (
    151, 160, 137,  91,  90,  15, 131,  13,
    201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,
     37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,
     94, 252, 219, 203, 117,  35,  11,  32,
     57, 177,  33,  88, 237, 149,  56,  87,
    174,  20, 125, 136, 171, 168,  68, 175,
     74, 165,  71, 134, 139,  48,  27, 166,
     77, 146, 158, 231,  83, 111, 229, 122,
     60, 211, 133, 230, 220, 105,  92,  41,
     55,  46, 245,  40, 244, 102, 143,  54,
     65,  25,  63, 161,   1, 216,  80,  73,
    209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86,
    164, 100, 109, 198, 173, 186,   3,  64,
     52, 217, 226, 250, 124, 123,   5, 202,
     38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17,
    182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70,
    221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,
     79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193,
    238, 210, 144,  12, 191, 179, 162, 241,
     81,  51, 145, 235, 249,  14, 239, 107,
     49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45,
    127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141,
    128, 195,  78,  66, 215,  61, 156, 180,
    151, 160, 137,  91,  90,  15, 131,  13,
    201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,
     37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,
     94, 252, 219, 203, 117,  35,  11,  32,
     57, 177,  33,  88, 237, 149,  56,  87,
    174,  20, 125, 136, 171, 168,  68, 175,
     74, 165,  71, 134, 139,  48,  27, 166,
     77, 146, 158, 231,  83, 111, 229, 122,
     60, 211, 133, 230, 220, 105,  92,  41,
     55,  46, 245,  40, 244, 102, 143,  54,
     65,  25,  63, 161,   1, 216,  80,  73,
    209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86,
    164, 100, 109, 198, 173, 186,   3,  64,
     52, 217, 226, 250, 124, 123,   5, 202,
     38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17,
    182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70,
    221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,
     79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193,
    238, 210, 144,  12, 191, 179, 162, 241,
     81,  51, 145, 235, 249,  14, 239, 107,
     49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45,
    127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141,
    128, 195,  78,  66, 215,  61, 156, 180
 );

function noise2(x, y: Single): Single;
var
  i1, j1, I_, J_, c: Integer;
  s, i, j, t: Single;
  xx, yy, f, noise: array[0..2] of Single;
  g: array[0..2] of Integer;
begin
    s := (x + y) * F2;
    i := floorf(x + s);
    j := floorf(y + s);
    t := (i + j) * G2;

    FillChar(noise, SizeOf(noise), 0);

    xx[0] := x - (i - t);
    yy[0] := y - (j - t);

    i1 := ord(xx[0] > yy[0]);
    j1 := ord(xx[0] <= yy[0]);

    xx[2] := xx[0] + G2 * 2.0 - 1.0;
    yy[2] := yy[0] + G2 * 2.0 - 1.0;
    xx[1] := xx[0] - i1 + G2;
    yy[1] := yy[0] - j1 + G2;

    I_ := Round(i) and 255;
    J_ := Round(j) and 255;
    g[0] := PERM[I_ + PERM[J_]] mod 12;
    g[1] := PERM[I_ + i1 + PERM[J_ + j1]] mod 12;
    g[2] := PERM[I_ + 1 + PERM[J_ + 1]] mod 12;

    for c := 0 to 2 do begin
        f[c] := 0.5 - xx[c]*xx[c] - yy[c]*yy[c];
    end;

    for c := 0 to 2 do begin
        if (f[c] > 0) then begin
            noise[c] := f[c] * f[c] * f[c] * f[c] *
                (GRAD3[g[c]][0] * xx[c] + GRAD3[g[c]][1] * yy[c]);
        end;
    end;

    Result := (noise[0] + noise[1] + noise[2]) * 70.0;
end;

function noise3(x, y, z: Single): Single;
var
  c: Integer;
  o1, o2: TInteger3;
  g: array[0..3] of Integer;
  I_, J_, K_: Integer;
  f, noise: array[0..3] of Single;
  s, i, j, k, t: Single;
  pos: array[0..3] of TSingle3;
begin
  FillChar(noise, SizeOf(noise), 0);
  s := (x + y + z) * F3;
  i := floorf(x + s);
  j := floorf(y + s);
  k := floorf(z + s);
  t := (i + j + k) * G3;

  pos[0][0] := x - (i - t);
  pos[0][1] := y - (j - t);
  pos[0][2] := z - (k - t);

  if (pos[0][0] >= pos[0][1]) then begin
        if (pos[0][1] >= pos[0][2]) then begin
            ASSIGN(o1, 1, 0, 0);
            ASSIGN(o2, 1, 1, 0);
        end else if (pos[0][0] >= pos[0][2]) then begin
            ASSIGN(o1, 1, 0, 0);
            ASSIGN(o2, 1, 0, 1);
        end else begin
            ASSIGN(o1, 0, 0, 1);
            ASSIGN(o2, 1, 0, 1);
        end;
    end else begin
        if (pos[0][1] < pos[0][2]) then begin
            ASSIGN(o1, 0, 0, 1);
            ASSIGN(o2, 0, 1, 1);
        end else if (pos[0][0] < pos[0][2]) then begin
            ASSIGN(o1, 0, 1, 0);
            ASSIGN(o2, 0, 1, 1);
        end else begin
            ASSIGN(o1, 0, 1, 0);
            ASSIGN(o2, 1, 1, 0);
        end;
    end;

    for c := 0 to 2 do begin
        pos[3][c] := pos[0][c] - 1.0 + 3.0 * G3;
        pos[2][c] := pos[0][c] - o2[c] + 2.0 * G3;
        pos[1][c] := pos[0][c] - o1[c] + G3;
    end;

    I_ := Round(i) and 255;
    J_ := Round(j) and 255;
    K_ := Round(k) and 255;
    g[0] := PERM[I_ + PERM[J_ + PERM[K_]]] mod 12;
    g[1] := PERM[I_ + o1[0] + PERM[J_ + o1[1] + PERM[o1[2] + K_]]] mod 12;
    g[2] := PERM[I_ + o2[0] + PERM[J_ + o2[1] + PERM[o2[2] + K_]]] mod 12;
    g[3] := PERM[I_ + 1 + PERM[J_ + 1 + PERM[K_ + 1]]] mod 12;

    for c := 0 to 3 do begin
        f[c] := 0.6 - pos[c][0] * pos[c][0] - pos[c][1] * pos[c][1] -
            pos[c][2] * pos[c][2];
    end;

    for c := 0 to 3 do begin
        if (f[c] > 0) then begin
            noise[c] := f[c] * f[c] * f[c] * f[c] * DOT3(pos[c], GRAD3[g[c]]);
        end;
    end;

    Result := (noise[0] + noise[1] + noise[2] + noise[3]) * 32.0;
end;

function simplex2(
    x, y: Single;
    octaves: Integer; persistence, lacunarity: Single): Single;
var
  freq: Single;
  amp: Single;
  max: Single;
  total: Single;
  i: Integer;
begin
    freq := 1.0;
    amp := 1.0;
    max := 1.0;
    total := noise2(x, y);
    for i := 1 to octaves - 1 do
    begin
        freq := freq * lacunarity;
        amp := amp * persistence;
        max := max + amp;
        total := total + noise2(x * freq, y * freq) * amp;
    end;
    Result := (1 + total / max) / 2;
end;


function simplex3(
    x, y, z: Single;
    octaves: Integer; persistence, lacunarity: Single): Single;
var
  freq, amp, max, total: Single;
  i: Integer;
begin
    freq := 1.0;
    amp := 1.0;
    max := 1.0;
    total := noise3(x, y, z);
    for i := 1 to octaves - 1 do begin
        freq := freq * lacunarity;
        amp := amp * persistence;
        max := max + amp;
        total := total + noise3(x * freq, y * freq, z * freq) * amp;
    end;
    Result := (1 + total / max) / 2;
end;

end.
