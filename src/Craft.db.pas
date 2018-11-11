unit Craft.db;

interface

uses
  Execute.SQLite3,
  Execute.SysUtils,
  Craft.Map,
  Craft.Sign,
  Craft.Ring,
  MarcusGeelnard.TinyCThread;

function db_create(path: PAnsiChar; var db: sqlite3): Integer;

procedure db_enable();
procedure db_disable();
function get_db_enabled(): Boolean;
function db_init(path: PAnsiChar): Integer;
procedure db_close();
procedure db_commit();
procedure db_auth_set(username, identity_token: PAnsiChar);
function db_auth_select(username: PAnsiChar): Integer;
procedure db_auth_select_none();
function db_auth_get(
    username,
    identity_token: PAnsiChar; identity_token_length: Integer): Integer;
function db_auth_get_selected(
    username: PAnsiChar; username_length: Integer;
    identity_token: PAnsiChar; identity_token_length: Integer): Integer;
procedure db_save_state(x, y, z, rx, ry: Single);
function db_load_state(var x, y, z, rx, ry: Single): Boolean;
procedure db_insert_block(p, q, x, y, z, w: Integer);
procedure db_insert_light(p, q, x, y, z, w: Integer);
procedure db_insert_sign(
    p, q, x, y, z, face: Integer; text: PAnsiChar);
procedure db_delete_sign(x, y, z, face: Integer);
procedure db_delete_signs(x, y, z: Integer);
procedure db_delete_all_signs();
procedure db_load_blocks(map: pMap; p, q: Integer);
procedure db_load_lights(map: pMap; p, q: Integer);
procedure db_load_signs(list: pSignList; p, q: Integer);
function db_get_key(p, q: Integer): Integer;
procedure db_set_key(p, q, key: Integer);
procedure db_worker_start(path : PAnsiChar);
procedure db_worker_stop();
function db_worker_run(arg: Pointer): Integer;

implementation

var
  db_enabled: Boolean = False;

  db: sqlite3;
  insert_block_stmt: sqlite3_stmt;
  insert_light_stmt: sqlite3_stmt;
  insert_sign_stmt: sqlite3_stmt;
  delete_sign_stmt: sqlite3_stmt;
  delete_signs_stmt: sqlite3_stmt;
  load_blocks_stmt: sqlite3_stmt;
  load_lights_stmt: sqlite3_stmt;
  load_signs_stmt: sqlite3_stmt;
  get_key_stmt: sqlite3_stmt;
  set_key_stmt: sqlite3_stmt;

  ring: TRing;
  thrd: thrd_t;
  mtx: mtx_t;
  cnd: cnd_t;
  load_mtx: mtx_t;


procedure db_enable();
begin
    db_enabled := True;
end;

procedure db_disable();
begin
    db_enabled := False;
end;

function get_db_enabled(): Boolean;
begin
    Result := db_enabled;
end;

function db_create(path: PAnsiChar; var db: sqlite3): Integer;
const
  create_query : PAnsiChar =
        'attach database ''auth.db'' as auth;'
      + 'create table if not exists auth.identity_token ('
      + '   username text not null,'
      + '   token text not null,'
      + '   selected int not null'
      + ');'
      + 'create unique index if not exists auth.identity_token_username_idx'
      + '   on identity_token (username);'
      + 'create table if not exists state ('
      + '   x float not null,'
      + '   y float not null,'
      + '   z float not null,'
      + '   rx float not null,'
      + '   ry float not null'
      + ');'
      + 'create table if not exists block ('
      + '    p int not null,'
      + '    q int not null,'
      + '    x int not null,'
      + '    y int not null,'
      + '    z int not null,'
      + '    w int not null'
      + ');'
      + 'create table if not exists light ('
      + '    p int not null,'
      + '    q int not null,'
      + '    x int not null,'
      + '    y int not null,'
      + '    z int not null,'
      + '    w int not null'
      + ');'
      + 'create table if not exists key ('
      + '    p int not null,'
      + '    q int not null,'
      + '    key int not null'
      + ');'
      + 'create table if not exists sign ('
      + '    p int not null,'
      + '    q int not null,'
      + '    x int not null,'
      + '    y int not null,'
      + '    z int not null,'
      + '    face int not null,'
      + '    text text not null'
      + ');'
      + 'create unique index if not exists block_pqxyz_idx on block (p, q, x, y, z);'
      + 'create unique index if not exists light_pqxyz_idx on light (p, q, x, y, z);'
      + 'create unique index if not exists key_pq_idx on key (p, q);'
      + 'create unique index if not exists sign_xyzface_idx on sign (x, y, z, face);'
      + 'create index if not exists sign_pq_idx on sign (p, q);';
begin
  Result := sqlite3_open(path, db);
  if Result = 0 then
  begin
    Result := sqlite3_exec(db, create_query, nil, nil, nil);
  end;
end;

function db_init(path: PAnsiChar): Integer;
const
    insert_block_query : PAnsiChar =
        'insert or replace into block (p, q, x, y, z, w) '
      + 'values (?, ?, ?, ?, ?, ?);';
    insert_light_query : PAnsiChar =
        'insert or replace into light (p, q, x, y, z, w) '
      + 'values (?, ?, ?, ?, ?, ?);';
    insert_sign_query : PAnsiChar =
        'insert or replace into sign (p, q, x, y, z, face, text) '
      + 'values (?, ?, ?, ?, ?, ?, ?);';
    delete_sign_query : PAnsiChar =
        'delete from sign where x = ? and y = ? and z = ? and face = ?;';
    delete_signs_query : PAnsiChar =
        'delete from sign where x = ? and y = ? and z = ?;';
    load_blocks_query : PAnsiChar =
        'select x, y, z, w from block where p = ? and q = ?;';
    load_lights_query : PAnsiChar =
        'select x, y, z, w from light where p = ? and q = ?;';
    load_signs_query : PAnsiChar =
        'select x, y, z, face, text from sign where p = ? and q = ?;';
    get_key_query : PAnsiChar =
        'select key from key where p = ? and q = ?;';
    set_key_query : PAnsiChar =
        'insert or replace into key (p, q, key) '
      + 'values (?, ?, ?);';
var
  rc: Integer;
begin
    if (not db_enabled) then begin
        Exit(0);
    end;
    rc := db_create(path, db);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(
        db, insert_block_query, -1, insert_block_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(
        db, insert_light_query, -1, insert_light_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(
        db, insert_sign_query, -1, insert_sign_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(
        db, delete_sign_query, -1, delete_sign_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(
        db, delete_signs_query, -1, delete_signs_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(db, load_blocks_query, -1, load_blocks_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(db, load_lights_query, -1, load_lights_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(db, load_signs_query, -1, load_signs_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(db, get_key_query, -1, get_key_stmt, nil);
    if (rc <> 0) then Exit(rc);
    rc := sqlite3_prepare_v2(db, set_key_query, -1, set_key_stmt, nil);
    if (rc <> 0) then Exit(rc);
    sqlite3_exec(db, 'begin;', nil, nil, nil);
    db_worker_start('db_worker_start');
    Result := 0;
end;

procedure db_close();
begin
    if (not db_enabled) then begin
        Exit;
    end;
    db_worker_stop();
    sqlite3_exec(db, 'commit;', nil, nil, nil);
    sqlite3_finalize(insert_block_stmt);
    sqlite3_finalize(insert_light_stmt);
    sqlite3_finalize(insert_sign_stmt);
    sqlite3_finalize(delete_sign_stmt);
    sqlite3_finalize(delete_signs_stmt);
    sqlite3_finalize(load_blocks_stmt);
    sqlite3_finalize(load_lights_stmt);
    sqlite3_finalize(load_signs_stmt);
    sqlite3_finalize(get_key_stmt);
    sqlite3_finalize(set_key_stmt);
    sqlite3_close(db);
end;

procedure db_commit();
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(mtx);
    ring_put_commit(@ring);
    cnd_signal(cnd);
    mtx_unlock(mtx);
end;

procedure _db_commit();
begin
    sqlite3_exec(db, 'commit; begin;', nil, nil, nil);
end;

procedure db_auth_set(username, identity_token: PAnsiChar);
const
  query : PAnsiChar =
        'insert or replace into auth.identity_token '
      + '(username, token, selected) values (?, ?, ?);';
var
  stmt: sqlite3_stmt;
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    sqlite3_bind_text(stmt, 1, username, -1, nil);
    sqlite3_bind_text(stmt, 2, identity_token, -1, nil);
    sqlite3_bind_int(stmt, 3, 1);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    db_auth_select(username);
end;

function db_auth_select(username: PAnsiChar) : Integer;
const
  query : PAnsiChar =
        'update auth.identity_token set selected = 1 where username = ?;';
var
  stmt: sqlite3_stmt;
begin
    if (not db_enabled) then begin
        Exit(0);
    end;
    db_auth_select_none();
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    sqlite3_bind_text(stmt, 1, username, -1, nil);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    Result := sqlite3_changes(db);
end;

procedure db_auth_select_none();
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_exec(db, 'update auth.identity_token set selected = 0;',
        nil, nil, nil);
end;

function db_auth_get(
    username,
    identity_token: PAnsiChar; identity_token_length: Integer): Integer;
const
  query : PAnsiChar =
        'select token from auth.identity_token '
      + 'where username = ?;';
var
  stmt: sqlite3_stmt;
  a: PAnsiChar;
begin
    if (not db_enabled) then begin
        Exit(0);
    end;
    Result := 0;
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    sqlite3_bind_text(stmt, 1, username, -1, nil);
    if (sqlite3_step(stmt) = SQLITE_ROW) then begin
        a := sqlite3_column_text(stmt, 0);
        strncpy(identity_token, a, identity_token_length - 1);
        identity_token[identity_token_length - 1] := #0;
        result := 1;
    end;
    sqlite3_finalize(stmt);
end;

function db_auth_get_selected(
    username: PAnsiChar; username_length: Integer;
    identity_token: PAnsiChar; identity_token_length: Integer): Integer;
const
  query : PAnsiChar =
        'select username, token from auth.identity_token '
      + 'where selected = 1;';
var
  stmt: sqlite3_stmt;
  a, b: PAnsiChar;
begin
    if (not db_enabled) then begin
        Exit(0);
    end;
    Result := 0;
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    if (sqlite3_step(stmt) = SQLITE_ROW) then begin
        a := sqlite3_column_text(stmt, 0);
        b := sqlite3_column_text(stmt, 1);
        strncpy(username, a, username_length - 1);
        username[username_length - 1] := #0;
        strncpy(identity_token, b, identity_token_length - 1);
        identity_token[identity_token_length - 1] := #0;
        result := 1;
    end;
    sqlite3_finalize(stmt);
end;

procedure db_save_state(x, y, z, rx, ry: Single);
const
  query : PAnsiChar =
        'insert into state (x, y, z, rx, ry) values (?, ?, ?, ?, ?);';
var
  stmt: sqlite3_stmt;
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_exec(db, 'delete from state;', nil, nil, nil);
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    sqlite3_bind_double(stmt, 1, x);
    sqlite3_bind_double(stmt, 2, y);
    sqlite3_bind_double(stmt, 3, z);
    sqlite3_bind_double(stmt, 4, rx);
    sqlite3_bind_double(stmt, 5, ry);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);
end;

function db_load_state(var x, y, z, rx, ry: Single): Boolean;
const
  query : PAnsiChar =
        'select x, y, z, rx, ry from state;';
var
  stmt: sqlite3_stmt;
begin
    if (not db_enabled) then begin
        Exit(False);
    end;
    result := False;
    sqlite3_prepare_v2(db, query, -1, stmt, nil);
    if (sqlite3_step(stmt) = SQLITE_ROW) then begin
        x := sqlite3_column_double(stmt, 0);
        y := sqlite3_column_double(stmt, 1);
        z := sqlite3_column_double(stmt, 2);
        rx := sqlite3_column_double(stmt, 3);
        ry := sqlite3_column_double(stmt, 4);
        Result := True;
    end;
    sqlite3_finalize(stmt);
end;

procedure db_insert_block(p, q, x, y, z, w: Integer);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(mtx);
    ring_put_block(@ring, p, q, x, y, z, w);
    cnd_signal(cnd);
    mtx_unlock(mtx);
end;

procedure _db_insert_block(p, q, x, y, z, w: Integer);
begin
    sqlite3_reset(insert_block_stmt);
    sqlite3_bind_int(insert_block_stmt, 1, p);
    sqlite3_bind_int(insert_block_stmt, 2, q);
    sqlite3_bind_int(insert_block_stmt, 3, x);
    sqlite3_bind_int(insert_block_stmt, 4, y);
    sqlite3_bind_int(insert_block_stmt, 5, z);
    sqlite3_bind_int(insert_block_stmt, 6, w);
    sqlite3_step(insert_block_stmt);
end;

procedure db_insert_light(p, q, x, y, z, w: Integer);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(mtx);
    ring_put_light(@ring, p, q, x, y, z, w);
    cnd_signal(cnd);
    mtx_unlock(mtx);
end;

procedure _db_insert_light(p, q, x, y, z, w: Integer);
begin
    sqlite3_reset(insert_light_stmt);
    sqlite3_bind_int(insert_light_stmt, 1, p);
    sqlite3_bind_int(insert_light_stmt, 2, q);
    sqlite3_bind_int(insert_light_stmt, 3, x);
    sqlite3_bind_int(insert_light_stmt, 4, y);
    sqlite3_bind_int(insert_light_stmt, 5, z);
    sqlite3_bind_int(insert_light_stmt, 6, w);
    sqlite3_step(insert_light_stmt);
end;

procedure db_insert_sign(
    p, q, x, y, z, face: Integer; text: PAnsiChar);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_reset(insert_sign_stmt);
    sqlite3_bind_int(insert_sign_stmt, 1, p);
    sqlite3_bind_int(insert_sign_stmt, 2, q);
    sqlite3_bind_int(insert_sign_stmt, 3, x);
    sqlite3_bind_int(insert_sign_stmt, 4, y);
    sqlite3_bind_int(insert_sign_stmt, 5, z);
    sqlite3_bind_int(insert_sign_stmt, 6, face);
    sqlite3_bind_text(insert_sign_stmt, 7, text, -1, nil);
    sqlite3_step(insert_sign_stmt);
end;

procedure db_delete_sign(x, y, z, face: Integer);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_reset(delete_sign_stmt);
    sqlite3_bind_int(delete_sign_stmt, 1, x);
    sqlite3_bind_int(delete_sign_stmt, 2, y);
    sqlite3_bind_int(delete_sign_stmt, 3, z);
    sqlite3_bind_int(delete_sign_stmt, 4, face);
    sqlite3_step(delete_sign_stmt);
end;

procedure db_delete_signs(x, y, z: Integer);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_reset(delete_signs_stmt);
    sqlite3_bind_int(delete_signs_stmt, 1, x);
    sqlite3_bind_int(delete_signs_stmt, 2, y);
    sqlite3_bind_int(delete_signs_stmt, 3, z);
    sqlite3_step(delete_signs_stmt);
end;

procedure db_delete_all_signs();
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_exec(db, 'delete from sign;', nil, nil, nil);
end;

procedure db_load_blocks(map: pMap; p, q: Integer);
var
  x, y, z, w: Integer;
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(load_mtx);
    sqlite3_reset(load_blocks_stmt);
    sqlite3_bind_int(load_blocks_stmt, 1, p);
    sqlite3_bind_int(load_blocks_stmt, 2, q);
    while (sqlite3_step(load_blocks_stmt) = SQLITE_ROW) do begin
        x := sqlite3_column_int(load_blocks_stmt, 0);
        y := sqlite3_column_int(load_blocks_stmt, 1);
        z := sqlite3_column_int(load_blocks_stmt, 2);
        w := sqlite3_column_int(load_blocks_stmt, 3);
        map_set(map, x, y, z, w);
    end;
    mtx_unlock(load_mtx);
end;

procedure db_load_lights(map: pMap; p, q: Integer);
var
  x, y, z, w: Integer;
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(load_mtx);
    sqlite3_reset(load_lights_stmt);
    sqlite3_bind_int(load_lights_stmt, 1, p);
    sqlite3_bind_int(load_lights_stmt, 2, q);
    while (sqlite3_step(load_lights_stmt) = SQLITE_ROW) do begin
        x := sqlite3_column_int(load_lights_stmt, 0);
        y := sqlite3_column_int(load_lights_stmt, 1);
        z := sqlite3_column_int(load_lights_stmt, 2);
        w := sqlite3_column_int(load_lights_stmt, 3);
        map_set(map, x, y, z, w);
    end;
    mtx_unlock(load_mtx);
end;

procedure db_load_signs(list: pSignList; p, q: Integer);
var
  x, y, z, face: Integer;
  text: PAnsiChar;
begin
    if (not db_enabled) then begin
        Exit;
    end;
    sqlite3_reset(load_signs_stmt);
    sqlite3_bind_int(load_signs_stmt, 1, p);
    sqlite3_bind_int(load_signs_stmt, 2, q);
    while (sqlite3_step(load_signs_stmt) = SQLITE_ROW) do begin
        x := sqlite3_column_int(load_signs_stmt, 0);
        y := sqlite3_column_int(load_signs_stmt, 1);
        z := sqlite3_column_int(load_signs_stmt, 2);
        face := sqlite3_column_int(load_signs_stmt, 3);
        text := sqlite3_column_text(
            load_signs_stmt, 4);
        sign_list_add(list, x, y, z, face, text);
    end;
end;

function db_get_key(p, q: Integer): Integer;
begin
    if (not db_enabled) then begin
        Exit(0);
    end;
    Result := 0;
    sqlite3_reset(get_key_stmt);
    sqlite3_bind_int(get_key_stmt, 1, p);
    sqlite3_bind_int(get_key_stmt, 2, q);
    if (sqlite3_step(get_key_stmt) = SQLITE_ROW) then begin
        Result := sqlite3_column_int(get_key_stmt, 0);
    end;
end;

procedure db_set_key(p, q, key: Integer);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(mtx);
    ring_put_key(@ring, p, q, key);
    cnd_signal(cnd);
    mtx_unlock(mtx);
end;

procedure _db_set_key(p, q, key: Integer);
begin
    sqlite3_reset(set_key_stmt);
    sqlite3_bind_int(set_key_stmt, 1, p);
    sqlite3_bind_int(set_key_stmt, 2, q);
    sqlite3_bind_int(set_key_stmt, 3, key);
    sqlite3_step(set_key_stmt);
end;

procedure db_worker_start(path : PAnsiChar);
begin
    if (not db_enabled) then begin
        Exit;
    end;
    ring_alloc(@ring, 1024);
    mtx_init(mtx, mtx_plain);
    mtx_init(load_mtx, mtx_plain);
    cnd_init(cnd);
    thrd_create(thrd, db_worker_run, path);
end;

procedure db_worker_stop();
begin
    if (not db_enabled) then begin
        Exit;
    end;
    mtx_lock(mtx);
    ring_put_exit(@ring);
    cnd_signal(cnd);
    mtx_unlock(mtx);
    thrd_join(thrd, nil);
    cnd_destroy(cnd);
    mtx_destroy(load_mtx);
    mtx_destroy(mtx);
    ring_free(@ring);
end;

function db_worker_run(arg: Pointer): Integer;
var
  running: Boolean;
  e: TRingEntry;
begin
    running := True;
    while (running) do begin
        mtx_lock(mtx);
        while (not ring_get(@ring, @e)) do begin
            cnd_wait(cnd, mtx);
        end;
        mtx_unlock(mtx);
        case (e.&type) of
            BLOCK:
                _db_insert_block(e.p, e.q, e.x, e.y, e.z, e.w);
            LIGHT:
                _db_insert_light(e.p, e.q, e.x, e.y, e.z, e.w);
            KEY:
                _db_set_key(e.p, e.q, e.key);
            COMMIT:
                _db_commit();
            EXIT_:
                running := False;
        end;
    end;
    Result := 0;
end;

end.
