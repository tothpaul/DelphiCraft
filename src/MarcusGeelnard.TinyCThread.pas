unit MarcusGeelnard.TinyCThread;

// Delphi Tokyo translation (c)2017 by Execute SARL

// https://github.com/tinycthread/tinycthread

// original copyright:
(*
Copyright (c) 2012 Marcus Geelnard

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*)

interface

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;
{$ENDIF}

//type
//  _ttherad_timespec = record
//    tv_src : time_t;
//    tv_nsec: longint;
//  end;
//  timespec = _ttherad_timespec;

const
(* Function return values *)
  thrd_error   = 0; (**< The requested operation failed *)
  thrd_success = 1; (**< The requested operation succeeded *)
  thrd_timeout = 2; (**< The time specified in the call was reached without acquiring the requested resource *)
  thrd_busy    = 3; (**< The requested operation failed because a tesource requested by a test and return function is already in use *)
  thrd_nomem   = 4; (**< The requested operation failed because it was unable to allocate memory *)

const
(* Mutex types *)
  mtx_plain     = 1;
  mtx_timed     = 2;
  mtx_try       = 4;
  mtx_recursive = 8;

(* Thread *)
type
{$IFDEF MSWINDOWS}
  thrd_t = THandle;
{$ELSE}
  thrd_t = pthread_t;
{$ENDIF}

(* Mutex *)
type
{$IFDEF MSWINDOWS}
  mtx_t = record
    mHandle        : TRTLCriticalSection; (* Critical section handle *)
    mAlreadyLocked : Boolean; (* TRUE if the mutex is already locked *)
    mRecursive     : Boolean; (* TRUE if the mutex is recursive *)
  end;
{$ELSE}
  mtx_t = pthread_mutex_t;
{$ENDIF}

(* Condition variable *)
type
{$IFDEF MSWINDOWS}
  cnd_t = record
    mEvents: array[0..1] of THandle;        (* Signal and broadcast event HANDLEs. *)
    mWaitersCount: Cardinal;                (* Count of the number of waiters. *)
    mWaitersCountLock: TRTLCriticalSection; (* Serialize access to mWaitersCount. *)
  end;
{$ELSE}
typedef pthread_cond_t cnd_t;
{$ENDIF}

(** Thread start function.
* Any thread that is started with the @ref thrd_create() function must be
* started through a function of this type.
* @param arg The thread argument (the @c arg argument of the corresponding
*        @ref thrd_create() call).
* @return The thread return value, which can be obtained by another thread
* by using the @ref thrd_join() function.
*)
  thrd_start_t = function(arg: Pointer): Integer;


(** Create a mutex object.
* @param mtx A mutex object.
* @param type Bit-mask that must have one of the following six values:
*   @li @c mtx_plain for a simple non-recursive mutex
*   @li @c mtx_timed for a non-recursive mutex that supports timeout
*   @li @c mtx_try for a non-recursive mutex that supports test and return
*   @li @c mtx_plain | @c mtx_recursive (same as @c mtx_plain, but recursive)
*   @li @c mtx_timed | @c mtx_recursive (same as @c mtx_timed, but recursive)
*   @li @c mtx_try | @c mtx_recursive (same as @c mtx_try, but recursive)
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function mtx_init(var mtx: mtx_t; &type: Integer): Integer;

(** Release any resources used by the given mutex.
* @param mtx A mutex object.
*)
procedure mtx_destroy(var mtx: mtx_t);

(** Lock the given mutex.
* Blocks until the given mutex can be locked. If the mutex is non-recursive, and
* the calling thread already has a lock on the mutex, this call will block
* forever.
* @param mtx A mutex object.
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function mtx_lock(var mtx: mtx_t): Integer;

(** NOT YET IMPLEMENTED.
*)
//function mtx_timedlock(var mtx: mtx_t; var ts: timespec): Integer;

function mtx_unlock(var mtx: mtx_t): Integer;

(** Create a condition variable object.
* @param cond A condition variable object.
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function cnd_init(var cond :cnd_t): Integer;

(** Release any resources used by the given condition variable.
* @param cond A condition variable object.
*)
procedure cnd_destroy(var cond: cnd_t);

(** Signal a condition variable.
* Unblocks one of the threads that are blocked on the given condition variable
* at the time of the call. If no threads are blocked on the condition variable
* at the time of the call, the function does nothing and return success.
* @param cond A condition variable object.
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function cnd_signal(var cond: cnd_t): Integer;

(** Wait for a condition variable to become signaled.
* The function atomically unlocks the given mutex and endeavors to block until
* the given condition variable is signaled by a call to cnd_signal or to
* cnd_broadcast. When the calling thread becomes unblocked it locks the mutex
* before it returns.
* @param cond A condition variable object.
* @param mtx A mutex object.
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function cnd_wait(var cond: cnd_t; var mtx: mtx_t): Integer;

(** Create a new thread.
* @param thr Identifier of the newly created thread.
* @param func A function pointer to the function that will be executed in
*        the new thread.
* @param arg An argument to the thread function.
* @return @ref thrd_success on success, or @ref thrd_nomem if no memory could
* be allocated for the thread requested, or @ref thrd_error if the request
* could not be honored.
* @note A thread’s identifier may be reused for a different thread once the
* original thread has exited and either been detached or joined to another
* thread.
*)
function thrd_create(var thr: thrd_t; func: thrd_start_t; arg: Pointer): Integer;

(** Wait for a thread to terminate.
* The function joins the given thread with the current thread by blocking
* until the other thread has terminated.
* @param thr The thread to join with.
* @param res If this pointer is not NULL, the function will store the result
*        code of the given thread in the integer pointed to by @c res.
* @return @ref thrd_success on success, or @ref thrd_error if the request could
* not be honored.
*)
function thrd_join(thr: thrd_t; res: PInteger): Integer;

implementation

function mtx_init(var mtx: mtx_t; &type: Integer): Integer;
begin
{$IFDEF MSWINDOWS}
  mtx.mAlreadyLocked := FALSE;
  mtx.mRecursive := (&type and mtx_recursive) <> 0;
  InitializeCriticalSection(mtx.mHandle);
  Result := thrd_success;
{$else}
  int ret;
  pthread_mutexattr_t attr;
  pthread_mutexattr_init(&attr);
  if (type & mtx_recursive)
  {
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
  }
  ret = pthread_mutex_init(mtx, &attr);
  pthread_mutexattr_destroy(&attr);
  return ret == 0 ? thrd_success : thrd_error;
{$endif}
end;


procedure mtx_destroy(var mtx: mtx_t);
begin
{$IFDEF MSWINDOWS}
  DeleteCriticalSection(mtx.mHandle);
{$ELSE}
  pthread_mutex_destroy(mtx);
{$ENDIF}
end;

function mtx_lock(var mtx: mtx_t): Integer;
begin
{$IFDEF MSWINDOWS}
  EnterCriticalSection(mtx.mHandle);
  if (not mtx.mRecursive) then
  begin
    while (mtx.mAlreadyLocked) do Sleep(1000); (* Simulate deadlock... *)
    mtx.mAlreadyLocked := TRUE;
  end;
  Result := thrd_success;
{$ELSE}
  return pthread_mutex_lock(mtx) == 0 ? thrd_success : thrd_error;
{$ENDIF}
end;

function mtx_unlock(var mtx: mtx_t): Integer;
begin
{$IFDEF MSWINDOWS}
  mtx.mAlreadyLocked := FALSE;
  LeaveCriticalSection(mtx.mHandle);
  Result := thrd_success;
{$else}
  return pthread_mutex_unlock(mtx) == 0 ? thrd_success : thrd_error;;
{$endif}
end;

{$IFDEF MSWINDOWS}
const
  _CONDITION_EVENT_ONE = 0;
  _CONDITION_EVENT_ALL = 1;
{$ENDIF}

function cnd_init(var cond :cnd_t): Integer;
begin
{$IFDEF MSWINDOWS}
  cond.mWaitersCount := 0;

  (* Init critical section *)
  InitializeCriticalSection(cond.mWaitersCountLock);

  (* Init events *)
  cond.mEvents[_CONDITION_EVENT_ONE] := CreateEvent(nil, FALSE, FALSE, nil);
  if (cond.mEvents[_CONDITION_EVENT_ONE] = 0) then
  begin
    cond.mEvents[_CONDITION_EVENT_ALL] := 0;
    Exit(thrd_error);
  end;
  cond.mEvents[_CONDITION_EVENT_ALL] := CreateEvent(nil, TRUE, FALSE, nil);
  if (cond.mEvents[_CONDITION_EVENT_ALL] = 0) then
  begin
    CloseHandle(cond.mEvents[_CONDITION_EVENT_ONE]);
    cond.mEvents[_CONDITION_EVENT_ONE] := 0;
    Exit(thrd_error);
  end;

  REsult := thrd_success;
{$else}
  return pthread_cond_init(cond, NULL) == 0 ? thrd_success : thrd_error;
{$endif}
end;

procedure cnd_destroy(var cond: cnd_t);
begin
{$IFDEF MSWINDOWS}
  if (cond.mEvents[_CONDITION_EVENT_ONE] <> 0) then
  begin
    CloseHandle(cond.mEvents[_CONDITION_EVENT_ONE]);
  end;
  if (cond.mEvents[_CONDITION_EVENT_ALL] <> 0) then
  begin
    CloseHandle(cond.mEvents[_CONDITION_EVENT_ALL]);
  end;
  DeleteCriticalSection(cond.mWaitersCountLock);
{$ELSE}
  pthread_cond_destroy(cond);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
function _cnd_timedwait_win32(var cond: cnd_t; var mtx: mtx_t; timeout: DWORD): Integer;
var
  lastWaiter: Boolean;
begin

  (* Increment number of waiters *)
  EnterCriticalSection(cond.mWaitersCountLock);
  Inc(cond.mWaitersCount);
  LeaveCriticalSection(cond.mWaitersCountLock);

  (* Release the mutex while waiting for the condition (will decrease
     the number of waiters when done)... *)
  mtx_unlock(mtx);

  (* Wait for either event to become signaled due to cnd_signal() or
     cnd_broadcast() being called *)
  result := WaitForMultipleObjects(2, @cond.mEvents, FALSE, timeout);
  if (result = WAIT_TIMEOUT) then
  begin
    Exit(thrd_timeout);
  end
  else if (result = WAIT_FAILED) then
  begin
    Exit(thrd_error);
  end;

  (* Check if we are the last waiter *)
  EnterCriticalSection(cond.mWaitersCountLock);
  Dec(cond.mWaitersCount);
  lastWaiter := (result = (WAIT_OBJECT_0 + _CONDITION_EVENT_ALL)) and
               (cond.mWaitersCount = 0);
  LeaveCriticalSection(cond.mWaitersCountLock);

  (* If we are the last waiter to be notified to stop waiting, reset the event *)
  if (lastWaiter) then
  begin
    if (ResetEvent(cond.mEvents[_CONDITION_EVENT_ALL]) = False) then
    begin
      Exit(thrd_error);
    end;
  end;

  (* Re-acquire the mutex *)
  mtx_lock(mtx);

  Result := thrd_success;
end;
{$ENDIF}

function cnd_wait(var cond: cnd_t; var mtx: mtx_t): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := _cnd_timedwait_win32(cond, mtx, INFINITE);
{$ELSE}
  return pthread_cond_wait(cond, mtx) == 0 ? thrd_success : thrd_error;
{$ENDIF}
end;


function cnd_signal(var cond: cnd_t): Integer;
{$IFDEF MSWINDOWS}
var
  haveWaiters: Boolean;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  (* Are there any waiters? *)
  EnterCriticalSection(cond.mWaitersCountLock);
  haveWaiters := (cond.mWaitersCount > 0);
  LeaveCriticalSection(cond.mWaitersCountLock);

  (* If we have any waiting threads, send them a signal *)
  if(haveWaiters) then
  begin
    if (SetEvent(cond.mEvents[_CONDITION_EVENT_ONE]) = FALSE) then
    begin
      Exit(thrd_error);
    end;
  end;

  Result := thrd_success;
{$else}
  return pthread_cond_signal(cond) == 0 ? thrd_success : thrd_error;
{$endif}
end;

type
(** Information to pass to the new thread (what to run). *)
  _thread_start_info = record
    mFunction: thrd_start_t; (**< Pointer to the function to be executed. *)
    mArg     : Pointer;      (**< Function argument for the thread function. *)
  end;
  pthread_start_info = ^_thread_start_info;

(* Thread wrapper function. *)
{$IFDEF MSWINDOWS}
function _thrd_wrapper_function(aArg: Pointer): Cardinal; stdcall;
{$ELSE}
static void * _thrd_wrapper_function(void * aArg)
{$ENDIF}
var
  fun: thrd_start_t;
  arg: Pointer;
  res: Integer;
//#if defined(_TTHREAD_POSIX_)
//  void *pres;
//#endif
  ti: pthread_start_info;
begin
  (* Get thread startup information *)
  ti := aArg;
  fun := ti.mFunction;
  arg := ti.mArg;

  (* The thread is responsible for freeing the startup information *)
  Dispose(ti);

  (* Call the actual client thread function *)
  res := fun(arg);

{$IFDEF MSWINDOWS}
  Result := res;
{$ELSE}
  pres = malloc(sizeof(int));
  if (pres != NULL)
  {
    *(int*)pres = res;
  }
  return pres;
{$ENDIF}
end;

function thrd_create(var thr: thrd_t; func: thrd_start_t; arg: Pointer): Integer;
var
  ti: pthread_start_info;
  dummy: DWORD;
begin
  (* Fill out the thread startup information (passed to the thread wrapper,
     which will eventually free it) *)
  //_thread_start_info* ti = (_thread_start_info*)malloc(sizeof(_thread_start_info));
  new(ti);
  if (ti = nil) then
  begin
    Exit(thrd_nomem);
  end;
  ti.mFunction := func;
  ti.mArg := arg;

  (* Create the thread *)
{$IFDEF MSWINDOWS}
//  thr := _beginthreadex(NULL, 0, _thrd_wrapper_function, ti, 0, nil);
  thr := CreateThread(nil, 0, @_thrd_wrapper_function, ti, 0, dummy);
{$ELSE}
  if(pthread_create(thr, NULL, _thrd_wrapper_function, (void *)ti) != 0)
  {
    *thr = 0;
  }
{$ENDIF}

  (* Did we fail to create the thread? *)
  if(thr = 0) then
  begin
    Dispose(ti);
    Exit(thrd_error);
  end;

  Result := thrd_success;
end;

function thrd_join(thr: thrd_t; res: PInteger): Integer;
{$IFDEF MSWINDOWS}
var
  dwRes: DWORD;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if (WaitForSingleObject(thr, INFINITE) = WAIT_FAILED) then
  begin
    Exit(thrd_error);
  end;
  if (res <> nil) then
  begin
    GetExitCodeThread(thr, dwRes);
    res^ := dwRes;
  end;
{$ELSE}
  void *pres;
  int ires = 0;
  if (pthread_join(thr, &pres) != 0)
  {
    return thrd_error;
  }
  if (pres != NULL)
  {
    ires = *(int*)pres;
    free(pres);
  }
  if (res != NULL)
  {
    *res = ires;
  }
{$ENDIF}
  Result := thrd_success;
end;

initialization
  IsMultiThread := True;
end.
