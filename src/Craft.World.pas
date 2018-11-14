unit Craft.World;

interface

// typedef void (*world_func)(int, int, int, int, void *);
type
  world_func = procedure(x, y, z, w : Integer; p: Pointer);

procedure create_world(p, q: Integer; func: world_func; arg: Pointer);

implementation

uses Craft.Config, CaseyDuncan.noise;

procedure create_world(p, q: Integer; func: world_func; arg: Pointer);
var
  pad: Integer;
  dx: Integer;
  dz: Integer;
  flag: Integer;
  x, z: Integer;
  f, g: Single;
  mh, h, w, t: Integer;
  y: Integer;
  ok: Integer;
  ox, oz, d: Integer;
begin
    pad := 1;
    for dx := -pad to pad + CHUNK_SIZE - 1 do begin
        for dz := -pad to pad + CHUNK_SIZE - 1 do begin
            flag := 1;
            if (dx < 0) or (dz < 0) or (dx >= CHUNK_SIZE) or (dz >= CHUNK_SIZE) then begin
                flag := -1;
            end;
            x := p * CHUNK_SIZE + dx;
            z := q * CHUNK_SIZE + dz;
            f := simplex2( x * 0.01,  z * 0.01, 4, 0.5, 2);
            g := simplex2(-x * 0.01, -z * 0.01, 2, 0.9, 2);
            mh := Trunc(g * 32) + 16;
            h := Trunc(f * mh);
            w := 1;
            t := 12;
            if (h <= t) then begin
                h := t;
                w := 2;
            end;
            // sand and grass terrain
            for y := 0 to h - 1 do begin
                func(x, y, z, w * flag, arg);
            end;
            if (w = 1) then begin
                if (SHOW_PLANTS <> 0) then begin
                    // grass
                    if (simplex2(-x * 0.1, z * 0.1, 4, 0.8, 2) > 0.6) then begin
                        func(x, h, z, 17 * flag, arg);
                    end;
                    // flowers
                    if (simplex2(x * 0.05, -z * 0.05, 4, 0.8, 2) > 0.7) then begin
                        w := 18 + Trunc(simplex2(x * 0.1, z * 0.1, 4, 0.8, 2) * 7);
                        func(x, h, z, w * flag, arg);
                    end;
                end;
                // trees
                ok := SHOW_TREES;
                if (dx - 4 < 0) or (dz - 4 < 0) or
                    (dx + 4 >= CHUNK_SIZE) or (dz + 4 >= CHUNK_SIZE) then
                begin
                    ok := 0;
                end;
                if (ok <> 0) and (simplex2(x, z, 6, 0.5, 2) > 0.84) then begin
                    for y := h + 3 to  h + 7 do begin
                        for ox := -3 to +3 do begin
                            for oz := -3 to +3 do begin
                                d := (ox * ox) + (oz * oz) +
                                    (y - (h + 4)) * (y - (h + 4));
                                if (d < 11) then begin
                                    func(x + ox, y, z + oz, 15, arg);
                                end;
                            end;
                        end;
                    end;
                    for y := h to h + 6 do begin
                        func(x, y, z, 5, arg);
                    end;
                end;
            end;
            // clouds
            if (SHOW_CLOUDS <> 0) then begin
                for y := 64 to 71 do begin
                    if (simplex3(
                        x * 0.01, y * 0.1, z * 0.01, 8, 0.5, 2) > 0.75) then
                    begin
                        func(x, y, z, 16 * flag, arg);
                    end;
                end;
            end;
        end;
    end;
end;

end.
