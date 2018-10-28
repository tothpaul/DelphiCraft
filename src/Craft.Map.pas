unit Craft.Map;

interface
{$POINTERMATH ON}
type
  TMapEntry = packed record
  case boolean of
    false: (value: Cardinal);
    true : (
      e: record
        x: Byte;
        y: Byte;
        z: Byte;
        w: ShortInt;
      end
    );
  end;
  pMapEntry = ^TMapEntry;

  TMap = record
    dx   : Integer;
    dy   : Integer;
    dz   : Integer;
    mask : Cardinal;
    size : Cardinal;
    data : pMapEntry;
  end;
  pMap = ^TMap;

  TMapForEach = reference to procedure(ex, ey, ez, ew: Integer);

procedure MAP_FOR_EACH(map: pMap; proc: TMapForEach);

procedure map_alloc(var map: TMap; dx, dy, dz, mask: Integer);
procedure map_free(var map: TMap);
procedure map_copy(dst, src: pMap);
function map_set(map: pMap; x, y, z, w: Integer): Integer;
function map_get(map: pMap; x, y, z: Integer): Integer;
procedure map_grow(map: pMap);

implementation

// #define EMPTY_ENTRY(entry) ((entry)->value == 0)
function EMPTY_ENTRY(entry: pMapEntry): Boolean; inline;
begin
  Result := entry.value = 0;
end;

//#define MAP_FOR_EACH(map, ex, ey, ez, ew) \
//    for (unsigned int i = 0; i <= map->mask; i++) { \
//        MapEntry *entry = map->data + i; \
//        if (EMPTY_ENTRY(entry)) { \
//            continue; \
//        } \
//        int ex = entry->e.x + map->dx; \
//        int ey = entry->e.y + map->dy; \
//        int ez = entry->e.z + map->dz; \
//        int ew = entry->e.w;
//
//#define END_MAP_FOR_EACH }

procedure MAP_FOR_EACH(map: pMap; proc: TMapForEach);
var
  i: Cardinal;
  entry: pMapEntry;
  ex, ey, ez, ew: Integer;
begin
  for i := 0 to map.mask do
  begin
    entry := @map.data[i];
    if EMPTY_ENTRY(entry) then
    begin
      Continue;
    end;
    ex := entry.e.x + map.dx;
    ey := entry.e.y + map.dy;
    ez := entry.e.z + map.dz;
    ew := entry.e.w;
    proc(ex, ey, ez, ew);
  end;
end;

function sar(i, bits: Integer): Integer;  inline;
begin
  if i < 0 then
    Result := not ((not i) shr bits)
  else
    result := i shr bits;
end;

function hash_int(key: Integer): Integer;
begin
    key := not key + (key shl 15);
    key := key xor sar(key, 12);
    key := key + (key shl 2);
    key := key xor sar(key, 4);
  {$IFOPT Q+}{$DEFINE QP}{$Q-}{$ENDIF}
    key := key * 2057;
  {$IFDEF QP}{$Q+}{$ENDIF}
    key := key xor sar(key, 16);
    Result := key;
end;

function hash(x, y, z: Integer): Integer;
begin
    x := hash_int(x);
    y := hash_int(y);
    z := hash_int(z);
    Result := x xor y xor z;
end;

procedure map_alloc(var map: TMap; dx, dy, dz, mask: Integer);
begin
    map.dx := dx;
    map.dy := dy;
    map.dz := dz;
    map.mask := mask;
    map.size := 0;
    map.data := pMapEntry(AllocMem((map.mask + 1) * sizeof(TMapEntry)));
end;

procedure map_free(var map: TMap);
begin
  FreeMem(map.data);
end;

procedure map_copy(dst, src: pMap);
begin
    dst.dx := src.dx;
    dst.dy := src.dy;
    dst.dz := src.dz;
    dst.mask := src.mask;
    dst.size := src.size;
    dst.data := pMapEntry(AllocMem((dst.mask + 1) * sizeof(TMapEntry)));
    Move(src.data^, dst.data^, (dst.mask + 1) * sizeof(TMapEntry));
end;

function map_set(map: pMap; x, y, z, w: Integer): Integer;
var
  index: Cardinal;
  entry: pMapEntry;
  overwrite: Integer;
begin
    index := hash(x, y, z) and map.mask;
    Dec(x, map.dx);
    Dec(y, map.dy);
    Dec(z, map.dz);
    entry := @map.data[index];
    overwrite := 0;
    while (not EMPTY_ENTRY(entry)) do begin
        if (entry.e.x = x) and (entry.e.y = y) and (entry.e.z = z) then begin
            overwrite := 1;
            break;
        end;
        index := (index + 1) and map.mask;
        entry := @map.data[index];
    end;
    if (overwrite <> 0) then begin
        if (entry.e.w <> w) then begin
            entry.e.w := w;
            Exit(1);
        end;
    end
    else if (w <> 0) then begin
        entry.e.x := x;
        entry.e.y := y;
        entry.e.z := z;
        entry.e.w := w;
        Inc(map.size);
        if (map.size * 2 > map.mask) then begin
            map_grow(map);
        end;
        Exit(1);
    end;
    Result := 0;
end;

function map_get(map: pMap; x, y, z: Integer): Integer;
var
  index: Cardinal;
  entry: pMapEntry;
begin
    index := hash(x, y, z) and map.mask;
    Dec(x, map.dx);
    Dec(y, map.dy);
    Dec(z, map.dz);
    if (x < 0) or (x > 255) then Exit(0);
    if (y < 0) or (y > 255) then Exit(0);
    if (z < 0) or (z > 255) then Exit(0);
    entry := @map.data[index];
    while (EMPTY_ENTRY(entry) = False) do begin
        if (entry.e.x = x) and (entry.e.y = y) and (entry.e.z = z) then begin
            Exit(entry.e.w);
        end;
        index := (index + 1) and map.mask;
        entry := @map.data[index];
    end;
    Result := 0;
end;

procedure map_grow(map: pMap);
var
  new_map: TMap;
begin
    new_map.dx := map.dx;
    new_map.dy := map.dy;
    new_map.dz := map.dz;
    new_map.mask := (map.mask shl 1) or 1;
    new_map.size := 0;
//    new_map.data := (MapEntry *)calloc(new_map.mask + 1, sizeof(MapEntry));
    new_map.data := AllocMem((new_map.mask + 1) * SizeOf(TMapEntry));
    MAP_FOR_EACH(map, procedure (ex, ey, ez, ew: Integer)
    begin
        map_set(@new_map, ex, ey, ez, ew);
    end);// END_MAP_FOR_EACH;
    freemem(map.data);
    map.mask := new_map.mask;
    map.size := new_map.size;
    map.data := new_map.data;
end;

initialization
  Assert(SizeOf(TMapEntry) = SizeOf(Cardinal));
end.
