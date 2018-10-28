unit Craft.Ring;

// [100%] Translation from C to Delphi by Execute SARL

interface
{$POINTERMATH ON}
type
  TRingEntryType = (
    BLOCK,
    LIGHT,
    KEY,
    COMMIT,
    EXIT_
  );

  TRingEntry = record
    &type: TRingEntryType;
    p: Integer;
    q: Integer;
    x: Integer;
    y: Integer;
    z: Integer;
    w: Integer;
    key: Integer;
  end;
  pRingEntry = ^TRingEntry;

  TRing = record
    capacity: Cardinal;
    start: Cardinal;
    &end: Cardinal;
    data: pRingEntry;
  end;
  pRing = ^TRing;

procedure ring_alloc(ring: pRing; capacity: Integer);
procedure ring_free(ring: pRing);
function ring_empty(ring: pRing): Boolean;
function ring_full(ring: pRing): Boolean;
function ring_size(ring: pRing): Integer;
procedure ring_grow(ring: pRing);
procedure ring_put(ring: pRing; entry: pRingEntry);
procedure ring_put_block(ring: pRing; p, q, x, y, z, w: Integer);
procedure ring_put_light(ring: pRing; p, q, x, y, z, w: Integer);
procedure ring_put_key(ring: pRing; p, q, key: Integer);
procedure ring_put_commit(ring: pRing);
procedure ring_put_exit(ring: pRing);
function ring_get(ring: pRing; entry: pRingEntry): Boolean;

implementation

procedure ring_alloc(ring: pRing; capacity: Integer);
begin
    ring.capacity := capacity;
    ring.start := 0;
    ring.&end := 0;
    ring.data := AllocMem(capacity * sizeof(TRingEntry));
end;

procedure ring_free(ring: pRing);
begin
    FreeMem(ring.data);
end;

function ring_empty(ring: pRing) : Boolean;
begin
    Result := ring.start = ring.&end;
end;

function ring_full(ring: pRing): Boolean;
begin
    Result := ring.start = (ring.&end + 1) mod ring.capacity;
end;

function ring_size(ring: pRing): Integer;
begin
    if (ring.&end >= ring.start) then begin
        Result := ring.&end - ring.start;
    end
    else begin
        Result := ring.capacity - (ring.start - ring.&end);
    end;
end;

procedure ring_grow(ring: pRing);
var
  new_ring: TRing;
  entry: TRingEntry;
begin
    ring_alloc(@new_ring, ring.capacity * 2);
    while (ring_get(ring, @entry)) do begin
        ring_put(@new_ring, @entry);
    end;
    FreeMem(ring.data);
    ring.capacity := new_ring.capacity;
    ring.start := new_ring.start;
    ring.&end := new_ring.&end;
    ring.data := new_ring.data;
end;

procedure ring_put(ring: pRing; entry: pRingEntry);
var
  e: pRingEntry;
begin
    if (ring_full(ring)) then begin
        ring_grow(ring);
    end;
    e := ring.data + ring.&end;
    //memcpy(e, entry, sizeof(RingEntry));
    e^ := entry^;
    ring.&end := (ring.&end + 1) mod ring.capacity;
end;

procedure ring_put_block(ring: pRing; p, q, x, y, z, w: Integer);
var
  entry: TRingEntry;
begin
    entry.&type := BLOCK;
    entry.p := p;
    entry.q := q;
    entry.x := x;
    entry.y := y;
    entry.z := z;
    entry.w := w;
    ring_put(ring, @entry);
end;

procedure ring_put_light(ring: pRing; p, q, x, y, z, w: Integer);
var
  entry: TRingEntry;
begin
    entry.&type := LIGHT;
    entry.p := p;
    entry.q := q;
    entry.x := x;
    entry.y := y;
    entry.z := z;
    entry.w := w;
    ring_put(ring, @entry);
end;

procedure ring_put_key(ring: pRing; p, q, key: Integer);
var
  entry: TRingEntry;
begin
    entry.&type := TRingEntryType.KEY;
    entry.p := p;
    entry.q := q;
    entry.key := key;
    ring_put(ring, @entry);
end;

procedure ring_put_commit(ring: pRing);
var
  entry: TRingEntry;
begin
    entry.&type := COMMIT;
    ring_put(ring, @entry);
end;

procedure ring_put_exit(ring: pRing);
var
  entry: TRingEntry;
begin
    entry.&type := EXIT_;
    ring_put(ring, @entry);
end;

function ring_get(ring: pRing; entry: pRingEntry): Boolean;
var
  e: pRingEntry;
begin
    if (ring_empty(ring)) then begin
        Exit(False);
    end;
    e := ring.data + ring.start;
    //memcpy(entry, e, sizeof(RingEntry));
    entry^ := e^;
    ring.start := (ring.start + 1) mod ring.capacity;
    Exit(True);
end;

end.
