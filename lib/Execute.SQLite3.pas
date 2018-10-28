unit Execute.SQLite3;

interface
{$DEFINE LINK_OBJ}
{-$DEFINE DEBUG}

uses
  Winapi.Windows;

type
  sqlite3 = Pointer;
  sqlite3_stmt = Pointer;

  PUTF8Char  = PAnsiChar;
  PPUTF8Char = ^PUTF8Char;

const
  SQLITE_OK         =   0;
  SQLITE_ERROR      =   1;
  SQLITE_INTERNAL   =   2;
  SQLITE_PERM       =   3;
  SQLITE_ABORT      =   4;
  SQLITE_BUSY       =   5;
  SQLITE_LOCKED     =   6;
  SQLITE_NOMEM      =   7;
  SQLITE_READONLY   =   8;
  SQLITE_INTERRUPT  =   9;
  SQLITE_IOERR      =  10;
  SQLITE_CORRUPT    =  11;
  SQLITE_NOTFOUND   =  12;
  SQLITE_FULL       =  13;
  SQLITE_CANTOPEN   =  14;
  SQLITE_PROTOCOL   =  15;
  SQLITE_EMPTY      =  16;
  SQLITE_SCHEMA     =  17;
  SQLITE_TOOBIG     =  18;
  SQLITE_CONSTRAINT =  19;
  SQLITE_MISMATCH   =  20;
  SQLITE_MISUSE     =  21;
  SQLITE_NOLFS      =  22;
  SQLITE_AUTH       =  23;
  SQLITE_FORMAT     =  24;
  SQLITE_RANGE      =  25;
  SQLITE_NOTADB     =  26;
  SQLITE_ROW        = 100;
  SQLITE_DONE       = 101;

type
  TSQLiteCallBack = function(param: Pointer; col_count: Integer; const col_text, col_names: array of PUTF8Char): Integer; cdecl;

function sqlite3_open(filename: PUTF8Char; var db: sqlite3): Integer; cdecl;
function sqlite3_close(db: sqlite3): Integer; cdecl;

function sqlite3_errmsg(db: sqlite3): PUTF8Char; cdecl;

function sqlite3_prepare_v2(db: sqlite3; zSql: PUTF8Char; nByte: Integer; var pStmt: sqlite3_stmt; pzTail: PPUTF8Char): integer; cdecl;
function sqlite3_step(stmt: sqlite3_stmt): Integer; cdecl;
function sqlite3_column_count(stmt: sqlite3_stmt): Integer; cdecl;
function sqlite3_column_name(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl;
function sqlite3_column_type(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl;
function sqlite3_column_int(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl;
function sqlite3_column_int64(stmt: sqlite3_stmt; iCol: Integer): Int64; cdecl;
function sqlite3_column_double(stmt: sqlite3_stmt; iCol: Integer): Double; cdecl;
function sqlite3_column_text(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl;
function sqlite3_column_blob(stmt: sqlite3_stmt; iCol: Integer): Pointer; cdecl;
function sqlite3_column_bytes(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl;

function sqlite3_bind_text(stmt: sqlite3_stmt; iCol: Integer; text: PAnsiChar; size: Integer; freeproc: Pointer): Integer; cdecl;
function sqlite3_bind_int(stmt: sqlite3_stmt; iCol: Integer; value: Integer): Integer; cdecl;
function sqlite3_bind_double(stmt: sqlite3_stmt; iCol: Integer; value: Double): Integer; cdecl;
function sqlite3_changes(stmt: sqlite3_stmt): Integer; cdecl;

function sqlite3_last_insert_rowid(db: sqlite3): Int64; cdecl;

function sqlite3_reset(stmt: sqlite3_stmt): Integer; cdecl;
function sqlite3_finalize(stmt: sqlite3_stmt): Integer; cdecl;

function sqlite3_exec(db: sqlite3; sql: PUTF8Char; callback: TSQLiteCallBack; param: Pointer; errmsg: PPUTF8Char): integer; cdecl;

implementation

{$IFDEF LINK_OBJ}

{$LINK sqlite3.obj}

var __turbofloat: word; { not used, but must be present for linking }

procedure _lldiv;
asm
  jmp System.@_lldiv
end;

procedure _llmod;
asm
  jmp System.@_llmod
end;

procedure _llmul;
asm
  jmp System.@_llmul
end;

procedure _llumod;
asm
  jmp System.@_llumod
end;

procedure _lludiv;
asm
  jmp System.@_lludiv
end;

procedure _llshl;
asm
  jmp System.@_llshl
end;

procedure _llushr;
asm
  jmp System.@_llushr
end;

function _ftol: Int64;
asm
  jmp System.@Trunc  // FST(0) -> EDX:EAX, as expected by BCC32 compiler
end;

function memset(P: Pointer; B: Integer; count: Integer): pointer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  result := P;
  FillChar(P^, count, B);
end;

var
  { as standard C library documentation states:
  Statically allocated buffer, shared by the functions gmtime() and localtime().
  Each call of these functions overwrites the content of this structure.
  -> since timing is not thread-dependent, it's OK to share this buffer :) }
  atm: packed record
    tm_sec: Integer;            { Seconds.      [0-60] (1 leap second) }
    tm_min: Integer;            { Minutes.      [0-59]  }
    tm_hour: Integer;           { Hours.        [0-23]  }
    tm_mday: Integer;           { Day.          [1-31]  }
    tm_mon: Integer;            { Month.        [0-11]  }
    tm_year: Integer;           { Year          - 1900. }
    tm_wday: Integer;           { Day of week.  [0-6]   }
    tm_yday: Integer;           { Days in year. [0-365] }
    tm_isdst: Integer;          { DST.          [-1/0/1]}
    __tm_gmtoff: Integer;       { Seconds east of UTC.  }
    __tm_zone: ^Char;           { Timezone abbreviation.}
  end;

function localtime(t: PCardinal): pointer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
var uTm: TFileTime;
    lTm: TFileTime;
    S: TSystemTime;
begin
  Int64(uTm) := (Int64(t^) + 11644473600)*10000000; // unix time to dos file time
  FileTimeToLocalFileTime(uTM,lTM);
  FileTimeToSystemTime(lTM,S);
  with atm do begin
    tm_sec := S.wSecond;
    tm_min := S.wMinute;
    tm_hour := S.wHour;
    tm_mday := S.wDay;
    tm_mon := S.wMonth-1;
    tm_year := S.wYear-1900;
    tm_wday := S.wDayOfWeek;
  end;
  result := @atm;
end;

function malloc(size: cardinal): Pointer; cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4/SynScaleMM fast heap manager
begin
  GetMem(Result, size);
end;

procedure free(P: Pointer); cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4 very fast heap manager
begin
  FreeMem(P);
end;

function realloc(P: Pointer; Size: Integer): Pointer; cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4/SynScaleMM very fast heap manager
begin
  result := P;
  ReallocMem(result,Size);
end;

procedure memmove(dest, source: pointer; count: Integer); cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  Move(source^, dest^, count); // move() is overlapping-friendly
end;

procedure memcpy(dest, source: Pointer; count: Integer); cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  Move(source^, dest^, count);
end;

function memcmp(p1, p2: pByte; Size: integer): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  if (p1<>p2) and (Size<>0) then
    if p1<>nil then
      if p2<>nil then begin
        repeat
          if p1^<>p2^ then begin
            result := p1^-p2^;
            exit;
          end;
          dec(Size);
          inc(p1);
          inc(p2);
        until Size=0;
        result := 0;
      end else
      result := 1 else
    result := -1 else
  result := 0;
end;

function strcmp(p1, p2: PByte): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  result := p1^-p2^;
  while (result = 0) and (p1^ <> 0) and (p2^ <> 0) do
  begin
    inc(p1);
    inc(p2);
    result := p1^-p2^;
  end;
end;

function strncmp(p1, p2: PByte; Size: integer): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
var i: integer;
begin
  for i := 1 to Size do begin
    result := p1^-p2^;
    if (result<>0) or (p1^=0) then
      exit;
    inc(p1);
    inc(p2);
  end;
  result := 0;
end;

function sqlite3_open(filename: PUTF8Char; var db: sqlite3): Integer; cdecl; external;
function sqlite3_close(db: sqlite3): Integer; cdecl; external;

function sqlite3_errmsg(db: sqlite3): PUTF8Char; cdecl; external;

function sqlite3_prepare_v2(db: sqlite3; zSql: PUTF8Char; nByte: Integer; var pStmt: sqlite3_stmt; pzTail: PPUTF8Char): integer; cdecl; external;
function sqlite3_step(stmt: sqlite3_stmt): Integer; cdecl; external;
function sqlite3_column_count(stmt: sqlite3_stmt): Integer; cdecl; external;
function sqlite3_column_name(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl; external;
function sqlite3_column_type(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external;
function sqlite3_column_int(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external;
function sqlite3_column_int64(stmt: sqlite3_stmt; iCol: Integer): Int64; cdecl; external;
function sqlite3_column_double(stmt: sqlite3_stmt; iCol: Integer): Double; cdecl; external;
function sqlite3_column_text(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl; external;
function sqlite3_column_blob(stmt: sqlite3_stmt; iCol: Integer): Pointer; cdecl; external;
function sqlite3_column_bytes(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external;

function sqlite3_bind_text(stmt: sqlite3_stmt; iCol: Integer; text: PAnsiChar; size: Integer; freeproc: Pointer): Integer; cdecl; external;
function sqlite3_bind_int(stmt: sqlite3_stmt; iCol: Integer; value: Integer): Integer; cdecl; external;
function sqlite3_bind_double(stmt: sqlite3_stmt; iCol: Integer; value: Double): Integer; cdecl; external;


function sqlite3_changes(stmt: sqlite3_stmt): Integer; cdecl; external;

function sqlite3_last_insert_rowid(db: sqlite3): Int64; cdecl; external;

function sqlite3_reset(stmt: sqlite3_stmt): Integer; cdecl; external;
function sqlite3_finalize(stmt: sqlite3_stmt): Integer; cdecl; external;

function sqlite3_exec(db: sqlite3; sql: PUTF8Char; callback: TSQLiteCallBack; param: Pointer; errmsg: PPUTF8Char): integer; cdecl; external;

{$ELSE}
const
  libSQLite3 = 'sqlite3.dll';

function sqlite3_open(filename: PUTF8Char; var db: sqlite3): Integer; cdecl; external libSQLite3;
function sqlite3_close(db: sqlite3): Integer; cdecl; external libSQLite3;

function sqlite3_errmsg(db: sqlite3): PUTF8Char; cdecl; external libSQLite3;

function sqlite3_prepare_v2(db: sqlite3; zSql: PUTF8Char; nByte: Integer; var pStmt: sqlite3_stmt; pzTail: PPUTF8Char): integer; cdecl; external libSQLite3;
function sqlite3_step(stmt: sqlite3_stmt): Integer; cdecl; external libSQLite3;
function sqlite3_column_count(stmt: sqlite3_stmt): Integer; cdecl; external libSQLite3;
function sqlite3_column_name(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl; external libSQLite3;
function sqlite3_column_type(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external libSQLite3;
function sqlite3_column_int(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external libSQLite3;
function sqlite3_column_int64(stmt: sqlite3_stmt; iCol: Integer): Int64; cdecl; external libSQLite3;
function sqlite3_column_double(stmt: sqlite3_stmt; iCol: Integer): Double; cdecl; external libSQLite3;
function sqlite3_column_text(stmt: sqlite3_stmt; iCol: Integer): PUTF8Char; cdecl; external libSQLite3;
function sqlite3_column_blob(stmt: sqlite3_stmt; iCol: Integer): Pointer; cdecl; external libSQLite3;
function sqlite3_column_bytes(stmt: sqlite3_stmt; iCol: Integer): Integer; cdecl; external libSQLite3;

function sqlite3_last_insert_rowid(db: sqlite3): Int64; cdecl; external libSQLite3;

function sqlite3_bind_text(stmt: sqlite3_stmt; iCol: Integer; text: PAnsiChar; size: Integer; freeproc: Pointer): Integer; cdecl; external libSQLite3;
function sqlite3_bind_int(stmt: sqlite3_stmt; iCol: Integer; value: Integer): Integer; cdecl; external libSQLite3;
function sqlite3_bind_double(stmt: sqlite3_stmt; iCol: Integer; value: Double): Integer; cdecl; external libSQLite3;

function sqlite3_changes(stmt: sqlite3_stmt): Integer; cdecl; external libSQLite3;

function sqlite3_reset(stmt: sqlite3_stmt): Integer; cdecl; external libSQLite3;
function sqlite3_finalize(stmt: sqlite3_stmt): Integer; cdecl; external libSQLite3;

function sqlite3_exec(db: sqlite3; sql: PUTF8Char; callback: TSQLiteCallBack; param: Pointer; errmsg: PPUTF8Char): integer; cdecl; external libSQLite3;
{$ENDIF}

end.
