unit Craft.Chunk;
{
   Parts of Craft.main about Chunks
}

interface

uses
  System.Math,
  Execute.CrossGL,
  Craft.Config,
  Craft.Util,
  Craft.Map,
  Craft.Sign,
  Craft.Matrix;

type
  TChunk = record
    map        : TMap;
    lights     : TMap;
    signs      : TSignList;
    p          : Integer;
    q          : Integer;
    faces      : Integer;
    sign_faces : Integer;
    dirty      : Integer;
    miny       : Integer;
    maxy       : Integer;
    buffer     : GLuint;
    sign_buffer: GLuint;
  end;
  pChunk = ^TChunk;

function chunked(x: Single): Integer;
function find_chunk(p, q: Integer): pChunk;
function chunk_distance(chunk: pChunk; p, q: Integer): Integer;
function chunk_visible(const planes: TPlanes; p, q, miny, maxy: Integer): Integer;
procedure dirty_chunk(chunk: pChunk);
procedure delete_all_chunks();

implementation

uses
  Craft.Main;

function chunked(x: Single): Integer;
begin
  Result := Floor(Round(x) / CHUNK_SIZE);
end;

function find_chunk(p, q: Integer): pChunk;
var
  i: Integer;
begin
  for i := 0 to g.chunk_count - 1 do
  begin
    Result := @g.chunks[i];
    if (Result.p = p) and (Result.q = q) then
      Exit;
  end;
  Result := nil;
end;

function chunk_distance(chunk: pChunk; p, q: Integer): Integer;
var
  dp, dq: Integer;
begin
  dp := ABS(chunk.p - p);
  dq := ABS(chunk.q - q);
  Result := MAX(dp, dq);
end;

function chunk_visible(const planes: TPlanes; p, q, miny, maxy: Integer): Integer;
var
  x, z, d: Integer;
  points: array[0..7, 0..2] of Single;
  n, i, in_, out_, j: Integer;
  d_: Single;
begin
    x := p * CHUNK_SIZE - 1;
    z := q * CHUNK_SIZE - 1;
    d := CHUNK_SIZE + 1;
    points[0][0] := x + 0; points[0, 1] := miny; points[0, 2] := z + 0;
    points[1][0] := x + d; points[1, 1] := miny; points[1, 2] := z + 0;
    points[2][0] := x + 0; points[2, 1] := miny; points[2, 2] := z + d;
    points[3][0] := x + d; points[3, 1] := miny; points[3, 2] := z + d;
    points[4][0] := x + 0; points[4, 1] := maxy; points[4, 2] := z + 0;
    points[5][0] := x + d; points[5, 1] := maxy; points[5, 2] := z + 0;
    points[6][0] := x + 0; points[6, 1] := maxy; points[6, 2] := z + d;
    points[7][0] := x + d; points[7, 1] := maxy; points[7, 2] := z + d;
    if g.ortho <> 0 then
      n := 4
    else
      n := 6;
    for i := 0 to n - 1 do
    begin
        in_ := 0;
        out_ := 0;
        for j := 0 to 7 do begin
            d_ :=
                planes[i][0] * points[j][0] +
                planes[i][1] * points[j][1] +
                planes[i][2] * points[j][2] +
                planes[i][3];
            if (d_ < 0) then begin
                Inc(out_);
            end
            else begin
                Inc(in_);
            end;
            if (in_ <> 0) and (out_ <> 0) then begin
                break;
            end;
        end;
        if (in_ = 0) then begin
            Exit(0);
        end;
    end;
    Result := 1;
end;

function has_lights(chunk: pChunk): Integer;
var
  dp: Integer;
  dq: Integer;
  other: pChunk;
  map: pMap;
begin
    if (SHOW_LIGHTS = 0) then begin
        Exit(0);
    end;
    for dp := -1 to +1 do begin
        for dq := -1 to +1 do begin
            other := chunk;
            if (dp <> 0) or (dq <> 0) then begin
                other := find_chunk(chunk.p + dp, chunk.q + dq);
            end;
            if (other = nil) then begin
                continue;
            end;
            map := @other.lights;
            if (map.size <> 0) then  begin
                Exit(1);
            end;
        end;
    end;
    Result := 0;
end;

procedure dirty_chunk(chunk: pChunk);
var
  dp: Integer;
  dq: Integer;
  other: pChunk;
begin
  chunk.dirty := 1;
  if (has_lights(chunk) <> 0) then begin
        for dp := -1 to + 1 do begin
            for dq := -1 to + 1 do begin
                other := find_chunk(chunk.p + dp, chunk.q + dq);
                if (other <> nil) then begin
                    other.dirty := 1;
                end;
            end;
        end;
  end;
end;

procedure delete_all_chunks();
var
  i: Integer;
  chunk: pChunk;
begin
  for i := 0 to g.chunk_count - 1 do begin
    chunk := @g.chunks[i];
    map_free(&chunk.map);
    map_free(&chunk.lights);
    sign_list_free(@chunk.signs);
    del_buffer(chunk.buffer);
    del_buffer(chunk.sign_buffer);
  end;
  g.chunk_count := 0;
end;

end.
