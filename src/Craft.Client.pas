unit Craft.Client;

interface
{$POINTERMATH ON}
uses
  Winapi.Windows,
  Winapi.Winsock,
  Execute.SysUtils,
  MarcusGeelnard.TinyCThread;

const
  DEFAULT_PORT = 4080;

procedure client_enable();
procedure client_disable();
function get_client_enabled(): Boolean;
procedure client_connect(hostname: PAnsiChar; port: Integer);
procedure client_start();
procedure client_stop();
procedure client_send(data: PAnsiChar);
function client_recv(): PAnsiChar;
procedure client_version(version: Integer);
procedure client_login(username, identity_token: PAnsiChar);
procedure client_position(x, y, z, rx, ry: Single);
procedure client_chunk(p, q, key: Integer);
procedure client_block(x, y, z, w: Integer);
procedure client_light(x, y, z, w: Integer);
procedure client_sign(x, y, z, face: Integer; text: PAnsiChar);
procedure client_talk(text: PAnsiChar);

implementation

{
#ifdef _WIN32
    #include <winsock2.h>
    #include <windows.h>
    #define close closesocket
    #define sleep Sleep
#else
    #include <netdb.h>
    #include <unistd.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "client.h"
#include "tinycthread.h"
}

const
  QUEUE_SIZE = 1048576;
  RECV_SIZE  = 4096;

var
  client_enabled : Boolean = False;
  running : Boolean = False;
  sd : Integer = 0;
  bytes_sent : Integer = 0;
  bytes_received : Integer = 0;
  queue : PAnsiChar = nil;
  qsize : Integer = 0;
  recv_thread: thrd_t;
  mutex: mtx_t;

procedure client_enable();
{$IFDEF MSWINDOWS}
var
  WSA: TWSAData;
{$ENDIF}
begin
    client_enabled := True;
{$IFDEF MSWINDOWS}
  WSAStartup($202, WSA);
{$ENDIF}
end;

procedure client_disable();
begin
    client_enabled := False;
end;

function get_client_enabled(): Boolean;
begin
    Result := client_enabled;
end;

function client_sendall(sd: Integer; data: PAnsiChar; length: Integer): Integer;
var
  count, n : Integer;
begin
    if (not client_enabled) then begin
        Exit(0);
    end;
    count := 0;
    while (count < length) do begin
        n := send(sd, data[count], length, 0);
        if (n = -1) then begin
            Exit(-1);
        end;
        Inc(count, n);
        Dec(length, n);
        Inc(bytes_sent, n);
    end;
    Result := 0;
end;

procedure client_send(data: PAnsiChar);
begin
    if (not client_enabled) then begin
        Exit;
    end;
    if (client_sendall(sd, data, strlen(data)) = -1) then begin
        //perror('client_sendall');
        Halt(1);
    end;
end;

procedure client_version(version: Integer);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'V,%d\n', [version]);
    client_send(buffer);
end;

procedure client_login(username, identity_token: PAnsiChar);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'A,%s,%s\n', [username, identity_token]);
    client_send(buffer);
end;

var
  px : Single = 0;
  py : Single = 0;
  pz : Single = 0;
  prx : Single = 0;
  pry : Single = 0;

procedure client_position(x, y, z, rx, ry: Single);
var
  distance: Single;
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    distance :=
        (px - x) * (px - x) +
        (py - y) * (py - y) +
        (pz - z) * (pz - z) +
        (prx - rx) * (prx - rx) +
        (pry - ry) * (pry - ry);
    if (distance < 0.0001) then begin
        Exit;
    end;
    px := x; py := y; pz := z; prx := rx; pry := ry;
    snprintf(buffer, 1024, 'P,%.2f,%.2f,%.2f,%.2f,%.2f\n', [x, y, z, rx, ry]);
    client_send(buffer);
end;

procedure client_chunk(p, q, key: Integer);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'C,%d,%d,%d\n', [p, q, key]);
    client_send(buffer);
end;

procedure client_block(x, y, z, w: Integer);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'B,%d,%d,%d,%d\n', [x, y, z, w]);
    client_send(buffer);
end;

procedure client_light(x, y, z, w: Integer);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'L,%d,%d,%d,%d\n', [x, y, z, w]);
    client_send(buffer);
end;

procedure client_sign(x, y, z, face: Integer; text: PAnsiChar);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'S,%d,%d,%d,%d,%s\n', [x, y, z, face, text]);
    client_send(buffer);
end;

procedure client_talk(text: PAnsiChar);
var
  buffer: array[0..1023] of AnsiChar;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    if (strlen(text) = 0) then begin
        Exit;
    end;
    snprintf(buffer, 1024, 'T,%s\n', [text]);
    client_send(buffer);
end;

function client_recv(): PAnsiChar;
var
  p: PAnsiChar;
  length: Integer;
  remaining: Integer;
begin
    if (not client_enabled) then begin
        Exit(nil);
    end;
    result := nil;
    mtx_lock(mutex);
    p := queue + qsize - 1;
    while (p >= queue) and (p^ <> #10) do begin
        Dec(p);
    end;
    if (p >= queue) then begin
        length := p - queue + 1;
        //result := malloc(sizeof(char) * (length + 1));
        //memcpy(result, queue, sizeof(char) * length);
        GetMem(Result, length + 1);
        move(queue^, result^, length);
        result[length] := #0;
        remaining := qsize - length;
        //memmove(queue, p + 1, remaining);
        move(p[1], queue^, remaining);
        Dec(qsize, length);
        Inc(bytes_received, length);
    end;
    mtx_unlock(mutex);
end;

function recv_worker(arg: Pointer): Integer;
var
  data: PAnsiChar;
  length: Integer;
  done: Boolean;
begin
    //char *data = malloc(sizeof(char) * RECV_SIZE);
    GetMem(data, RECV_SIZE);
    while (true) do begin
        length := recv(sd, data[0], RECV_SIZE - 1, 0);
        if (length  <= 0) then begin
            if (running) then begin
                //perror("recv");
                Exit(1);
            end
            else begin
                break;
            end;
        end;
        data[length] := #0;
        while (true) do begin
            done := False;
            mtx_lock(mutex);
            if (qsize + length < QUEUE_SIZE) then begin
                //memcpy(queue + qsize, data, sizeof(char) * (length + 1));
                move(data^, queue[qsize], length + 1);
                Inc(qsize, length);
                done := True;
            end;
            mtx_unlock(mutex);
            if (done) then begin
                break;
            end;
            sleep(0);
        end;
    end;
    freemem(data);
    Result := 0;
end;

procedure client_connect(hostname: PAnsiChar; port: Integer);
var
  host: phostent;
  address: sockaddr_in;
begin
    if (not client_enabled) then begin
        Exit;
    end;
    host := gethostbyname(hostname);
    if (host = nil) then begin
        //perror("gethostbyname");
        halt(1);
    end;
    FillChar(address, sizeof(address), 0);
    address.sin_family := AF_INET;
    address.sin_addr.s_addr := PInAddr(Pointer(host.h_addr_list)^).s_addr;
    address.sin_port := htons(port);
    sd := socket(AF_INET, SOCK_STREAM, 0);
    if (sd = -1) then begin
        //perror("socket");
        Halt(1);
    end;
    if (connect(sd, address, sizeof(address)) = -1) then begin
        //perror("connect");
        Halt(1);
    end;
end;

procedure client_start();
begin
    if (not client_enabled) then begin
        Exit;
    end;
    running := True;
    GetMem(queue, QUEUE_SIZE);
    qsize := 0;
    mtx_init(mutex, mtx_plain);
    if (thrd_create(recv_thread, recv_worker, nil) <> thrd_success) then begin
        //perror("thrd_create");
        Halt(1);
    end;
end;

procedure client_stop();
begin
    if (not client_enabled) then begin
        Exit;
    end;
    running := False;
    closesocket(sd);
    // if (thrd_join(recv_thread, NULL) != thrd_success) {
    //     perror("thrd_join");
    //     exit(1);
    // }
    // mtx_destroy(&mutex);
    qsize := 0;
    freemem(queue);
    // printf("Bytes Sent: %d, Bytes Received: %d\n",
    //     bytes_sent, bytes_received);
end;


end.
