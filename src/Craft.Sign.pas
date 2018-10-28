unit Craft.Sign;

interface
{$POINTERMATH ON}
uses
  Execute.SysUtils;

const
  MAX_SIGN_LENGTH = 64;

type
  TSign = record
    x    : Integer;
    y    : Integer;
    z    : Integer;
    face : Integer;
    text : array[0..MAX_SIGN_LENGTH - 1] of AnsiChar;
  end;
  pSign = ^TSign;

  TSignList = record
    capacity : Cardinal;
    size     : Integer;
    data     : pSign;
  end;
  pSignList = ^TSignList;

procedure sign_list_alloc(list: pSignList; capacity: Integer);
procedure sign_list_free(list: pSignList);
procedure sign_list_grow(list: pSignList);
procedure sign_list_add(
    list: pSignList; x, y, z, face: Integer; text: PAnsiChar);
function sign_list_remove(list: pSignList; x, y, z, face: Integer): Integer;
function sign_list_remove_all(list: pSignList; x, y, z: Integer): Integer;


implementation

procedure sign_list_alloc(list: pSignList; capacity: Integer);
begin
    list.capacity := capacity;
    list.size := 0;
    //list.data := pSign(calloc(capacity, sizeof(TSign)));
    list.data := AllocMem(capacity * SizeOf(TSign));
end;


procedure sign_list_free(list: pSignList);
begin
    FreeMem(list.data);
end;

procedure sign_list_grow(list: pSignList);
var
  new_list: TSignList;
begin
    sign_list_alloc(@new_list, list.capacity * 2);
    //memcpy(new_list.data, list->data, list->size * sizeof(Sign));
    move(list.data^, new_list.data^, list.size * SizeOf(TSign));
    freemem(list.data);
    list.capacity := new_list.capacity;
    list.data := new_list.data;
end;

procedure _sign_list_add(list: pSignList; sign: pSign);
var
  e: pSign;
begin
    if (list.size = list.capacity) then begin
        sign_list_grow(list);
    end;
    e := list.data + list.size;
    Inc(list.size);
    //memcpy(e, sign, sizeof(Sign));
    e^ := sign^;
end;

procedure sign_list_add(
    list: pSignList; x, y, z, face: Integer; text: PAnsiChar);
var
  sign: TSign;
begin
    sign_list_remove(list, x, y, z, face);
    sign.x := x;
    sign.y := y;
    sign.z := z;
    sign.face := face;
    strncpy(sign.text, text, MAX_SIGN_LENGTH);
    sign.text[MAX_SIGN_LENGTH - 1] := #0;
    _sign_list_add(list, @sign);
end;


function sign_list_remove(list: pSignList; x, y, z, face: Integer): Integer;
var
  i: Integer;
  e: pSign;
  other: pSign;
begin
    result := 0;
    i := 0;
    while (i < list.size) do begin
        e := @list.data[i];
        if (e.x = x) and (e.y = y) and (e.z = z) and (e.face = face) then begin
            Dec(list.Size);
            other := @list.data[list.size];
            //memcpy(e, other, sizeof(Sign));
            e^ := other^;
            Dec(i);
            Inc(result);
        end;
        Inc(i);
    end;
end;

function sign_list_remove_all(list: pSignList; x, y, z: Integer): Integer;
var
  i: Integer;
  e: pSign;
  other: pSign;
begin
    result := 0;
    i := 0;
    while (i < list.size) do begin
        e := list.data + i;
        if (e.x = x) and (e.y = y) and (e.z = z) then
        begin
            Dec(list.size);
            other := list.data + list.size;
            //memcpy(e, other, sizeof(Sign));
            e^ := other^;
            Dec(i);
            Inc(result);
        end;
        Inc(i);
    end;
end;

end.
