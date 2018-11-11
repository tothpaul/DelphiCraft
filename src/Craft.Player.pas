unit Craft.Player;

interface

uses
  System.Math,
  Execute.CrossGL,
  Neslib.glfw3,
  Craft.Util;

const
  MAX_NAME_LENGTH = 32;

type
  TState = record
    x  : Single;
    y  : Single;
    z  : Single;
    rx : Single;
    ry : Single;
    t  : Single;
  end;
  PState = ^TState;

  TPlayer = record
    id    : Integer;
    name  : array[0..MAX_NAME_LENGTH - 1] of AnsiChar;
    state : TState;
    state1: TState;
    state2: TState;
    buffer: GLuint;
  end;
  PPlayer = ^TPlayer;

function find_player(id: Integer): pPlayer;
procedure update_player(player: pPlayer;
    x, y, z, rx, ry: Single; interpolate: Integer);
procedure interpolate_player(player: pPlayer);
function player_crosshair(player: pPlayer): pPlayer;
procedure delete_player(id: Integer);
procedure delete_all_players();

implementation

uses
  Craft.Main,
  Craft.Render;

function find_player(id: Integer): pPlayer;
var
  i: Integer;
begin
  for i := 0 to g.player_count - 1 do begin
      Result := @g.players[i];
      if (Result.id = id) then begin
          Exit;
      end;
  end;
  Result := nil;
end;

procedure update_player(player: pPlayer;
    x, y, z, rx, ry: Single; interpolate: Integer);
var
  s, s1, s2: pState;
begin
    if (interpolate <> 0) then begin
        s1 := @player.state1;
        s2 := @player.state2;
        //memcpy(s1, s2, sizeof(State));
        s1^ := s2^;
        s2.x := x; s2.y := y; s2.z := z; s2.rx := rx; s2.ry := ry;
        s2.t := glfwGetTime();
        if (s2.rx - s1.rx) > PI then begin
            s1.rx := s1.rx + 2 * PI;
        end;
        if (s1.rx - s2.rx) > PI then begin
            s1.rx := s1.rx - 2 * PI;
        end;
    end
    else begin
        s := @player.state;
        s.x := x; s.y := y; s.z := z; s.rx := rx; s.ry := ry;
        del_buffer(player.buffer);
        player.buffer := gen_player_buffer(s.x, s.y, s.z, s.rx, s.ry);
    end;
end;

procedure interpolate_player(player: pPlayer);
var
  s1, s2: pState;
  t1, t2, p: Single;
begin
    s1 := @player.state1;
    s2 := @player.state2;
    t1 := s2.t - s1.t;
    t2 := glfwGetTime() - s2.t;
    t1 := MIN(t1, 1);
    t1 := MAX(t1, 0.1);
    p := MIN(t2 / t1, 1);
    update_player(
        player,
        s1.x + (s2.x - s1.x) * p,
        s1.y + (s2.y - s1.y) * p,
        s1.z + (s2.z - s1.z) * p,
        s1.rx + (s2.rx - s1.rx) * p,
        s1.ry + (s2.ry - s1.ry) * p,
        0);
end;

procedure delete_player(id: Integer);
var
  player: pPlayer;
  count: Integer;
  other: pPlayer;
begin
    player := find_player(id);
    if (player = nil) then begin
        Exit;
    end;
    count := g.player_count;
    del_buffer(player.buffer);
    Dec(count);
    other := @g.players[count];
    //memcpy(player, other, sizeof(Player));
    player^ := other^;
    g.player_count := count;
end;

procedure delete_all_players();
var
  i: Integer;
  player: pPlayer;
begin
    for i := 0 to g.player_count - 1 do begin
        player := @g.players[i];
        del_buffer(player.buffer);
    end;
    g.player_count := 0;
end;

function player_player_distance(p1, p2: pPlayer): Single;
var
  s1, s2: pState;
  x, y, z: Single;
begin
    s1 := @p1.state;
    s2 := @p2.state;
    x := s2.x - s1.x;
    y := s2.y - s1.y;
    z := s2.z - s1.z;
    Result := sqrt(x * x + y * y + z * z);
end;

function player_crosshair_distance(p1, p2: pPlayer): Single;
var
  s1, s2: pState;
  d, vx, vy, vz: Single;
  px, py, pz: Single;
  x, y, z: Single;
begin
    s1 := @p1.state;
    s2 := @p2.state;
    d := player_player_distance(p1, p2);
    get_sight_vector(s1.rx, s1.ry, &vx, &vy, &vz);
    vx := vx * d; vy := vy * d; vz := vz * d;
    px := s1.x + vx; py := s1.y + vy; pz := s1.z + vz;
    x := s2.x - px;
    y := s2.y - py;
    z := s2.z - pz;
    Result := sqrt(x * x + y * y + z * z);
end;

function player_crosshair(player: pPlayer): pPlayer;
var
  threshold: Single;
  best: Single;
  i: Integer;
  other: pPlayer;
  p, d: Single;
begin
    result := nil;
    threshold := RADIANS(5);
    best := 0;
    for i := 0 to g.player_count - 1 do begin
        other := @g.players[i];
        if (other = player) then begin
            continue;
        end;
        p := player_crosshair_distance(player, other);
        d := player_player_distance(player, other);
        if (d < 96) and (p / d < threshold) then begin
            if (best = 0) or (d < best) then begin
                best := d;
                result := other;
            end;
        end;
    end;
end;

end.
