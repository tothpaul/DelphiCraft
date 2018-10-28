unit Neslib.Glfw3;
{ GLFW3 language bindings for Delphi }

{ Copyright (c) 2016 by Erik van Bilsen
  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. }

{$MINENUMSIZE 4}

interface

uses
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows,
  {$ELSEIF Defined(MACOS) and not Defined(IOS)}
  Macapi.CocoaTypes,
  {$ELSE}
    {$MESSAGE Error 'Unsupported platform'}
  {$ENDIF}
  System.SysUtils;

const
  {$IF Defined(WIN32)}
  { @exclude }
  GLFW3_LIB = 'glfw3_32.dll';
  { @exclude }
  _PU = '';
  {$ELSEIF Defined(WIN64)}
  { @exclude }
  GLFW3_LIB = 'glfw3_64.dll';
  { @exclude }
  _PU = '';
  {$ELSEIF Defined(MACOS) and not Defined(IOS)}
  { @exclude }
  GLFW3_LIB = 'libglfw.3.2.dylib';
  { @exclude }
  _PU = '_';
  {$ELSE}
    {$MESSAGE Error 'Unsupported platform'}
  {$ENDIF}

{$REGION 'glfw3.h'}
{*************************************************************************
 * GLFW 3.2 - www.glfw.org
 * A library for OpenGL, window and input
 *------------------------------------------------------------------------
 * Copyright (c) 2002-2006 Marcus Geelnard
 * Copyright (c) 2006-2016 Camilla Berglund <elmindreda@glfw.org>
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would
 *    be appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source
 *    distribution.
 *
 *************************************************************************}

{*************************************************************************
 * GLFW API tokens
 *************************************************************************}

const
  { The major version number of the GLFW library.
    This is incremented when the API is changed in non-compatible ways. }
  GLFW_VERSION_MAJOR = 3;

const
  { The minor version number of the GLFW library.

    This is incremented when features are added to the API but it remains
    backward-compatible. }
  GLFW_VERSION_MINOR = 2;

const
  { The revision number of the GLFW library.

    This is incremented when a bug fix release is made that does not contain any
    API changes. }
  GLFW_VERSION_REVISION = 1;

const
  { One.

    One. Seriously. You don't <i>need</i> to use this symbol in your code. It's
    just semantic sugar for the number 1. You can use <tt>1</tt> or
    <tt>GL_TRUE</tt> or whatever you want. }
  GLFW_TRUE = 1;

const
  { Zero.

    Zero. Seriously. You don't <i>need</i> to use this symbol in your code. It's
    just just semantic sugar for the number 0. You can use <tt>0</tt> or
    <tt>GL_FALSE</tt> or whatever you want. }
  GLFW_FALSE = 0;

const
  { The key or mouse button was released. }
  GLFW_RELEASE = 0;

const
  { The key or mouse button was pressed. }
  GLFW_PRESS = 1;

const
  { The key was held down until it repeated. }
  GLFW_REPEAT = 2;

const
  { The unknown key }
  GLFW_KEY_UNKNOWN = -1;

const
  { Printable keys }
  GLFW_KEY_SPACE = 32;
  GLFW_KEY_APOSTROPHE = 39;
  GLFW_KEY_COMMA = 44;
  GLFW_KEY_MINUS = 45;
  GLFW_KEY_PERIOD = 46;
  GLFW_KEY_SLASH = 47;
  GLFW_KEY_0 = 48;
  GLFW_KEY_1 = 49;
  GLFW_KEY_2 = 50;
  GLFW_KEY_3 = 51;
  GLFW_KEY_4 = 52;
  GLFW_KEY_5 = 53;
  GLFW_KEY_6 = 54;
  GLFW_KEY_7 = 55;
  GLFW_KEY_8 = 56;
  GLFW_KEY_9 = 57;
  GLFW_KEY_SEMICOLON = 59;
  GLFW_KEY_EQUAL = 61;
  GLFW_KEY_A = 65;
  GLFW_KEY_B = 66;
  GLFW_KEY_C = 67;
  GLFW_KEY_D = 68;
  GLFW_KEY_E = 69;
  GLFW_KEY_F = 70;
  GLFW_KEY_G = 71;
  GLFW_KEY_H = 72;
  GLFW_KEY_I = 73;
  GLFW_KEY_J = 74;
  GLFW_KEY_K = 75;
  GLFW_KEY_L = 76;
  GLFW_KEY_M = 77;
  GLFW_KEY_N = 78;
  GLFW_KEY_O = 79;
  GLFW_KEY_P = 80;
  GLFW_KEY_Q = 81;
  GLFW_KEY_R = 82;
  GLFW_KEY_S = 83;
  GLFW_KEY_T = 84;
  GLFW_KEY_U = 85;
  GLFW_KEY_V = 86;
  GLFW_KEY_W = 87;
  GLFW_KEY_X = 88;
  GLFW_KEY_Y = 89;
  GLFW_KEY_Z = 90;
  GLFW_KEY_LEFT_BRACKET = 91;
  GLFW_KEY_BACKSLASH = 92;
  GLFW_KEY_RIGHT_BRACKET = 93;
  GLFW_KEY_GRAVE_ACCENT = 96;
  GLFW_KEY_WORLD_1 = 161;
  GLFW_KEY_WORLD_2 = 162;

const
  { Function keys }
  GLFW_KEY_ESCAPE = 256;
  GLFW_KEY_ENTER = 257;
  GLFW_KEY_TAB = 258;
  GLFW_KEY_BACKSPACE = 259;
  GLFW_KEY_INSERT = 260;
  GLFW_KEY_DELETE = 261;
  GLFW_KEY_RIGHT = 262;
  GLFW_KEY_LEFT = 263;
  GLFW_KEY_DOWN = 264;
  GLFW_KEY_UP = 265;
  GLFW_KEY_PAGE_UP = 266;
  GLFW_KEY_PAGE_DOWN = 267;
  GLFW_KEY_HOME = 268;
  GLFW_KEY_END = 269;
  GLFW_KEY_CAPS_LOCK = 280;
  GLFW_KEY_SCROLL_LOCK = 281;
  GLFW_KEY_NUM_LOCK = 282;
  GLFW_KEY_PRINT_SCREEN = 283;
  GLFW_KEY_PAUSE = 284;
  GLFW_KEY_F1 = 290;
  GLFW_KEY_F2 = 291;
  GLFW_KEY_F3 = 292;
  GLFW_KEY_F4 = 293;
  GLFW_KEY_F5 = 294;
  GLFW_KEY_F6 = 295;
  GLFW_KEY_F7 = 296;
  GLFW_KEY_F8 = 297;
  GLFW_KEY_F9 = 298;
  GLFW_KEY_F10 = 299;
  GLFW_KEY_F11 = 300;
  GLFW_KEY_F12 = 301;
  GLFW_KEY_F13 = 302;
  GLFW_KEY_F14 = 303;
  GLFW_KEY_F15 = 304;
  GLFW_KEY_F16 = 305;
  GLFW_KEY_F17 = 306;
  GLFW_KEY_F18 = 307;
  GLFW_KEY_F19 = 308;
  GLFW_KEY_F20 = 309;
  GLFW_KEY_F21 = 310;
  GLFW_KEY_F22 = 311;
  GLFW_KEY_F23 = 312;
  GLFW_KEY_F24 = 313;
  GLFW_KEY_F25 = 314;
  GLFW_KEY_KP_0 = 320;
  GLFW_KEY_KP_1 = 321;
  GLFW_KEY_KP_2 = 322;
  GLFW_KEY_KP_3 = 323;
  GLFW_KEY_KP_4 = 324;
  GLFW_KEY_KP_5 = 325;
  GLFW_KEY_KP_6 = 326;
  GLFW_KEY_KP_7 = 327;
  GLFW_KEY_KP_8 = 328;
  GLFW_KEY_KP_9 = 329;
  GLFW_KEY_KP_DECIMAL = 330;
  GLFW_KEY_KP_DIVIDE = 331;
  GLFW_KEY_KP_MULTIPLY = 332;
  GLFW_KEY_KP_SUBTRACT = 333;
  GLFW_KEY_KP_ADD = 334;
  GLFW_KEY_KP_ENTER = 335;
  GLFW_KEY_KP_EQUAL = 336;
  GLFW_KEY_LEFT_SHIFT = 340;
  GLFW_KEY_LEFT_CONTROL = 341;
  GLFW_KEY_LEFT_ALT = 342;
  GLFW_KEY_LEFT_SUPER = 343;
  GLFW_KEY_RIGHT_SHIFT = 344;
  GLFW_KEY_RIGHT_CONTROL = 345;
  GLFW_KEY_RIGHT_ALT = 346;
  GLFW_KEY_RIGHT_SUPER = 347;
  GLFW_KEY_MENU = 348;

  GLFW_KEY_LAST = GLFW_KEY_MENU;

const
  { If this bit is set one or more Shift keys were held down. }
  GLFW_MOD_SHIFT = $0001;

const
  { If this bit is set one or more Control keys were held down. }
  GLFW_MOD_CONTROL = $0002;

const
  { If this bit is set one or more Alt keys were held down. }
  GLFW_MOD_ALT = $0004;

const
  { If this bit is set one or more Super keys were held down. }
  GLFW_MOD_SUPER = $0008;

const
  { Mouse buttons }
  GLFW_MOUSE_BUTTON_1 = 0;
  GLFW_MOUSE_BUTTON_2 = 1;
  GLFW_MOUSE_BUTTON_3 = 2;
  GLFW_MOUSE_BUTTON_4 = 3;
  GLFW_MOUSE_BUTTON_5 = 4;
  GLFW_MOUSE_BUTTON_6 = 5;
  GLFW_MOUSE_BUTTON_7 = 6;
  GLFW_MOUSE_BUTTON_8 = 7;
  GLFW_MOUSE_BUTTON_LAST = GLFW_MOUSE_BUTTON_8;
  GLFW_MOUSE_BUTTON_LEFT = GLFW_MOUSE_BUTTON_1;
  GLFW_MOUSE_BUTTON_RIGHT = GLFW_MOUSE_BUTTON_2;
  GLFW_MOUSE_BUTTON_MIDDLE = GLFW_MOUSE_BUTTON_3;

const
  { Joysticks }
  GLFW_JOYSTICK_1 = 0;
  GLFW_JOYSTICK_2 = 1;
  GLFW_JOYSTICK_3 = 2;
  GLFW_JOYSTICK_4 = 3;
  GLFW_JOYSTICK_5 = 4;
  GLFW_JOYSTICK_6 = 5;
  GLFW_JOYSTICK_7 = 6;
  GLFW_JOYSTICK_8 = 7;
  GLFW_JOYSTICK_9 = 8;
  GLFW_JOYSTICK_10 = 9;
  GLFW_JOYSTICK_11 = 10;
  GLFW_JOYSTICK_12 = 11;
  GLFW_JOYSTICK_13 = 12;
  GLFW_JOYSTICK_14 = 13;
  GLFW_JOYSTICK_15 = 14;
  GLFW_JOYSTICK_16 = 15;
  GLFW_JOYSTICK_LAST = GLFW_JOYSTICK_16;

{ Error codes }

const
  { GLFW has not been initialized.

    This occurs if a GLFW function was called that must not be called unless the
    library is initialized.

    Application programmer error. Initialize GLFW before calling any
    function that requires initialization. }
  GLFW_NOT_INITIALIZED = $00010001;

const
  { No context is current for this thread.

    This occurs if a GLFW function was called that needs and operates on the
    current OpenGL or OpenGL ES context but no context is current on the calling
    thread. One such function is glfwSwapInterval.

    Application programmer error.  Ensure a context is current before
    calling functions that require a current context. }
  GLFW_NO_CURRENT_CONTEXT = $00010002;

const
  { One of the arguments to the function was an invalid enum value.

    One of the arguments to the function was an invalid enum value, for example
    requesting GLFW_RED_BITS with glfwGetWindowAttrib.

    Application programmer error.  Fix the offending call. }
  GLFW_INVALID_ENUM = $00010003;

const
  { One of the arguments to the function was an invalid value.

    One of the arguments to the function was an invalid value, for example
    requesting a non-existent OpenGL or OpenGL ES version like 2.7.

    Requesting a valid but unavailable OpenGL or OpenGL ES version will instead
    result in a GLFW_VERSION_UNAVAILABLE error.

    Application programmer error.  Fix the offending call. }
  GLFW_INVALID_VALUE = $00010004;

const
  { A memory allocation failed.

    A bug in GLFW or the underlying operating system.  Report the bug to our
    issue tracker (https://github.com/glfw/glfw/issues). }
  GLFW_OUT_OF_MEMORY = $00010005;

const
  { GLFW could not find support for the requested API on the system.

    The installed graphics driver does not support the requested
    API, or does not support it via the chosen context creation backend.
    Below are a few examples.

    Some pre-installed Windows graphics drivers do not support OpenGL.  AMD only
    supports OpenGL ES via EGL, while Nvidia and Intel only support it via
    a WGL or GLX extension.  OS X does not provide OpenGL ES at all.  The Mesa
    EGL, OpenGL and OpenGL ES libraries do not interface with the Nvidia binary
    driver.  Older graphics drivers do not support Vulkan. }
  GLFW_API_UNAVAILABLE = $00010006;

const
  { The requested OpenGL or OpenGL ES version is not available.

    The requested OpenGL or OpenGL ES version (including any requested context
    or framebuffer hints) is not available on this machine.

    The machine does not support your requirements.  If your application is
    sufficiently flexible, downgrade your requirements and try again.
    Otherwise, inform the user that their machine does not match your
    requirements.

    Future invalid OpenGL and OpenGL ES versions, for example OpenGL 4.8 if 5.0
    comes out before the 4.x series gets that far, also fail with this error and
    not GLFW_INVALID_VALUE, because GLFW cannot know what future versions
    will exist. }
  GLFW_VERSION_UNAVAILABLE = $00010007;

const
  { A platform-specific error occurred that does not match any of the
    more specific categories.

    A bug or configuration error in GLFW, the underlying operating system or its
    drivers, or a lack of required resources.  Report the issue to our
    issue tracker (https://github.com/glfw/glfw/issues). }
  GLFW_PLATFORM_ERROR = $00010008;

const
  { The requested format is not supported or available.

    If emitted during window creation, the requested pixel format is not
    supported.

    If emitted when querying the clipboard, the contents of the clipboard could
    not be converted to the requested format.

    If emitted during window creation, one or more hard constraints did not
    match any of the available pixel formats.  If your application is
    sufficiently flexible, downgrade your requirements and try again. Otherwise,
    inform the user that their machine does not match your requirements.

    If emitted when querying the clipboard, ignore the error or report it to
    the user, as appropriate. }
  GLFW_FORMAT_UNAVAILABLE = $00010009;

const
  { The specified window does not have an OpenGL or OpenGL ES context.

    A window that does not have an OpenGL or OpenGL ES context was passed to
    a function that requires it to have one.

    Application programmer error.  Fix the offending call. }
  GLFW_NO_WINDOW_CONTEXT = $0001000A;

const
  GLFW_FOCUSED = $00020001;
  GLFW_ICONIFIED = $00020002;
  GLFW_RESIZABLE = $00020003;
  GLFW_VISIBLE = $00020004;
  GLFW_DECORATED = $00020005;
  GLFW_AUTO_ICONIFY = $00020006;
  GLFW_FLOATING = $00020007;
  GLFW_MAXIMIZED = $00020008;

  GLFW_RED_BITS = $00021001;
  GLFW_GREEN_BITS = $00021002;
  GLFW_BLUE_BITS = $00021003;
  GLFW_ALPHA_BITS = $00021004;
  GLFW_DEPTH_BITS = $00021005;
  GLFW_STENCIL_BITS = $00021006;
  GLFW_ACCUM_RED_BITS = $00021007;
  GLFW_ACCUM_GREEN_BITS = $00021008;
  GLFW_ACCUM_BLUE_BITS = $00021009;
  GLFW_ACCUM_ALPHA_BITS = $0002100A;
  GLFW_AUX_BUFFERS = $0002100B;
  GLFW_STEREO = $0002100C;
  GLFW_SAMPLES = $0002100D;
  GLFW_SRGB_CAPABLE = $0002100E;
  GLFW_REFRESH_RATE = $0002100F;
  GLFW_DOUBLEBUFFER = $00021010;

  GLFW_CLIENT_API = $00022001;
  GLFW_CONTEXT_VERSION_MAJOR = $00022002;
  GLFW_CONTEXT_VERSION_MINOR = $00022003;
  GLFW_CONTEXT_REVISION = $00022004;
  GLFW_CONTEXT_ROBUSTNESS = $00022005;
  GLFW_OPENGL_FORWARD_COMPAT = $00022006;
  GLFW_OPENGL_DEBUG_CONTEXT = $00022007;
  GLFW_OPENGL_PROFILE = $00022008;
  GLFW_CONTEXT_RELEASE_BEHAVIOR = $00022009;
  GLFW_CONTEXT_NO_ERROR = $0002200A;
  GLFW_CONTEXT_CREATION_API = $0002200B;

  GLFW_NO_API = 0;
  GLFW_OPENGL_API = $00030001;
  GLFW_OPENGL_ES_API = $00030002;

  GLFW_NO_ROBUSTNESS = 0;
  GLFW_NO_RESET_NOTIFICATION = $00031001;
  GLFW_LOSE_CONTEXT_ON_RESET = $00031002;

  GLFW_OPENGL_ANY_PROFILE = 0;
  GLFW_OPENGL_CORE_PROFILE = $00032001;
  GLFW_OPENGL_COMPAT_PROFILE = $00032002;

  GLFW_CURSOR = $00033001;
  GLFW_STICKY_KEYS = $00033002;
  GLFW_STICKY_MOUSE_BUTTONS = $00033003;

  GLFW_CURSOR_NORMAL = $00034001;
  GLFW_CURSOR_HIDDEN = $00034002;
  GLFW_CURSOR_DISABLED = $00034003;

  GLFW_ANY_RELEASE_BEHAVIOR = 0;
  GLFW_RELEASE_BEHAVIOR_FLUSH = $00035001;
  GLFW_RELEASE_BEHAVIOR_NONE = $00035002;

  GLFW_NATIVE_CONTEXT_API = $00036001;
  GLFW_EGL_CONTEXT_API = $00036002;

{ Standard cursor shapes }

const
  { The regular arrow cursor shape. }
  GLFW_ARROW_CURSOR = $00036001;

const
  { The text input I-beam cursor shape. }
  GLFW_IBEAM_CURSOR = $00036002;

const
  { The crosshair shape. }
  GLFW_CROSSHAIR_CURSOR = $00036003;

const
  { The hand shape. }
  GLFW_HAND_CURSOR = $00036004;

const
  { The horizontal resize arrow shape. }
  GLFW_HRESIZE_CURSOR = $00036005;

const
  { The vertical resize arrow shape. }
  GLFW_VRESIZE_CURSOR = $00036006;

const
  GLFW_CONNECTED = $00040001;
  GLFW_DISCONNECTED = $00040002;

  GLFW_DONT_CARE = -1;

{************************************************************************
 * GLFW API types
 ************************************************************************}

type
  { Client API function pointer type.

    Generic function pointer used for returning client API function pointers
    without forcing a cast from a regular pointer.

    SeeAlso:
      glfwGetProcAddress

    Added in version 3.0. }
  TGLFWglproc = procedure(); cdecl;

type
  { Opaque monitor object.

    Added in version 3.0. }
  PGLFWmonitor = Pointer;
  PPGLFWmonitor = ^PGLFWmonitor;

type
  { Opaque window object.

    Added in version 3.0. }
  PGLFWwindow = Pointer;
  PPGLFWwindow = ^PGLFWwindow;

type
  { Opaque cursor object.

    Added in version 3.1. }
  PGLFWcursor = Pointer;
  PPGLFWcursor = ^PGLFWcursor;

type
  { The function signature for error callbacks.

    Parameters:
      error: An error code.
      description: A UTF-8 encoded string describing the error.

    SeeAlso:
      glfwSetErrorCallback

    Added in version 3.0. }
  TGLFWerrorfun = procedure(error: Integer; const description: PAnsiChar); cdecl;

type
  { The function signature for window position callbacks.

    Parameters:
      window: The window that was moved.
      xpos: The new x-coordinate, in screen coordinates, of the upper-left
        corner of the client area of the window.
      ypos: The new y-coordinate, in screen coordinates, of the upper-left
        corner of the client area of the window.

    SeeAlso:
      glfwSetWindowPosCallback

    Added in version 3.0. }
  TGLFWwindowposfun = procedure(window: PGLFWwindow; xpos, ypos: Integer); cdecl;

type
  { The function signature for window resize callbacks.

    Parameters:
      window: The window that was resized.
      width: The new width, in screen coordinates, of the window.
      height: The new height, in screen coordinates, of the window.

    SeeAlso:
      glfwSetWindowSizeCallback

    Added in version 1.0. GLFW3 added window handle parameter. }
  TGLFWwindowsizefun = procedure(window: PGLFWwindow; width, height: Integer); cdecl;

type
  { The function signature for window close callbacks.

    Parameters:
      window: The window that the user attempted to close.

    SeeAlso:
      glfwSetWindowCloseCallback

    Added in version 2.5. GLFW3 added window handle parameter. }
  TGLFWwindowclosefun = procedure(window: PGLFWwindow); cdecl;

type
  { The function signature for window content refresh callbacks.

    Parameters:
      window: The window whose content needs to be refreshed.

    SeeAlso:
      glfwSetWindowRefreshCallback

    Added in version 2.5. GLFW3 added window handle parameter. }
  TGLFWwindowrefreshfun = procedure(window: PGLFWwindow); cdecl;

type
  { The function signature for window focus/defocus callbacks.

    Parameters:
      window: The window that gained or lost input focus.
      focused: <tt>GLFW_TRUE</tt> if the window was given input focus, or
        <tt>GLFW_FALSE</tt> if it lost it.

    SeeAlso:
      glfwSetWindowFocusCallback

    Added in version 3.0. }
  TGLFWwindowfocusfun = procedure(window: PGLFWwindow; focused: Integer); cdecl;

type
  { The function signature for window iconify/restore callbacks.

    Parameters:
      window: The window that was iconified or restored.
      iconified: <tt>GLFW_TRUE</tt> if the window was iconified, or
        <tt>GLFW_FALSE</tt> if it was restored.

    SeeAlso:
      glfwSetWindowIconifyCallback

    Added in version 3.0. }
  TGLFWwindowiconifyfun = procedure(window: PGLFWwindow; iconified: Integer); cdecl;

type
  { The function signature for framebuffer resize callbacks.

    Parameters:
      window: The window whose framebuffer was resized.
      width: The new width, in pixels, of the framebuffer.
      height: The new height, in pixels, of the framebuffer.

    SeeAlso:
      glfwSetFramebufferSizeCallback

    Added in version 3.0. }
  TGLFWframebuffersizefun = procedure(window: PGLFWwindow; width, height: Integer); cdecl;

type
  { The function signature for mouse button callbacks.

    Parameters:
      window: The window that received the event.
      button: The mouse button that was pressed or released.
      action: One of <tt>GLFW_PRESS</tt> or <tt>GLFW_RELEASE</tt>.
      mods: Bit field describing which modifier keys were held down.

    SeeAlso:
      glfwSetMouseButtonCallback

    Added in version 1.0. GLFW3 added window handle and modifier mask
    parameters. }
  TGLFWmousebuttonfun = procedure(window: PGLFWwindow; button, action, mods: Integer); cdecl;

type
  { The function signature for cursor position callbacks.

    Parameters:
      window: The window that received the event.
      xpos: The new cursor x-coordinate, relative to the left edge of the
        client area.
      ypos: The new cursor y-coordinate, relative to the top edge of the
        client area.

    SeeAlso:
      glfwSetCursorPosCallback

    Added in version 3.0. Replaces <tt>TGLFWmouseposfun</tt>. }
  TGLFWcursorposfun = procedure(window: PGLFWwindow; xpos, ypos: Double); cdecl;

type
  { The function signature for cursor enter/leave callbacks.

    Parameters:
      window: The window that received the event.
      entered: <tt>GLFW_TRUE</tt> if the cursor entered the window's client
        area, or <tt>GLFW_FALSE</tt> if it left it.

    SeeAlso:
      glfwSetCursorEnterCallback

    Added in version 3.0. }
  TGLFWcursorenterfun = procedure(window: PGLFWwindow; entered: Integer); cdecl;

type
  { The function signature for scroll callbacks.

    Parameters:
      window: The window that received the event.
      xoffset: The scroll offset along the x-axis.
      yoffset: The scroll offset along the y-axis.

    SeeAlso:
      glfwSetScrollCallback

    Added in version 3.0. Replaces <tt>TGLFWmousewheelfun</tt>. }
  TGLFWscrollfun = procedure(window: PGLFWwindow; xoffset, yoffset: Double); cdecl;

type
  { The function signature for keyboard key callbacks.

    Parameters:
      window: The window that received the event.
      key: The keyboard key that was pressed or released.
      scancode: The system-specific scancode of the key.
      action: <tt>GLFW_PRESS</tt>, <tt>GLFW_RELEASE</tt> or <tt>GLFW_REPEAT</tt>.
      mods: Bit field describing which modifier keys were held down.

    SeeAlso:
      glfwSetKeyCallback

    Added in version 1.0. GLFW3 added window handle, scancode and modifier mask
    parameters. }
  TGLFWkeyfun = procedure(window: PGLFWwindow; key, scancode, action, mods: Integer); cdecl;

type
  { The function signature for Unicode character callbacks.

    Parameters:
      window: The window that received the event.
      codepoint: The Unicode code point of the character.

    SeeAlso:
      glfwSetCharCallback

    Added in version 2.4. GLFW3 added window handle parameter. }
  TGLFWcharfun = procedure(window: PGLFWwindow; codepoint: Cardinal); cdecl;

type
  { The function signature for Unicode character with modifiers
    callbacks. It is called for each input character, regardless of what
    modifier keys are held down.

    Parameters:
      window: The window that received the event.
      codepoint: The Unicode code point of the character.
      mods: Bit field describing which modifier keys were held down.

    SeeAlso:
      glfwSetCharModsCallback

    Added in version 3.1. }
  TGLFWcharmodsfun = procedure(window: PGLFWwindow; codepoint: Cardinal; mods: Integer); cdecl;

type
  { The function signature for file drop callbacks.

    Parameters:
      window: The window that received the event.
      count: The number of dropped files.
      paths: The UTF-8 encoded file and/or directory path names.

    SeeAlso:
      glfwSetDropCallback

    Added in version 3.1. }
  TGLFWdropfun = procedure(window: PGLFWwindow; count: Integer; const paths: PPAnsiChar); cdecl;

type
  { The function signature for monitor configuration callbacks.

    Parameters:
      monitor: The monitor that was connected or disconnected.
      event: One of <tt>GLFW_CONNECTED</tt> or <tt>GLFW_DISCONNECTED</tt>.

    SeeAlso:
      glfwSetMonitorCallback

    Added in version 3.0. }
  TGLFWmonitorfun = procedure(monitor: PGLFWmonitor; event: Integer); cdecl;

type
  { The function signature for joystick configuration callbacks.

    Parameters:
      joy: The joystick that was connected or disconnected.
      event: One of <tt>GLFW_CONNECTED</tt> or <tt>GLFW_DISCONNECTED</tt>.

    SeeAlso:
      glfwSetJoystickCallback

    Added in version 3.2. }
  TGLFWjoystickfun = procedure(joy, event: Integer); cdecl;

type
  { Video mode type.

    SeeAlso:
      glfwGetVideoMode, glfwGetVideoModes

    Added in version 1.0. GLFW3 added refresh rate member. }
  TGLFWvidmode = record
    width: Integer;
    height: Integer;
    redBits: Integer;
    greenBits: Integer;
    blueBits: Integer;
    refreshRate: Integer;
  end;
  PGLFWvidmode = ^TGLFWvidmode;
  PPGLFWvidmode = ^PGLFWvidmode;

type
  { Describes the gamma ramp for a monitor.

    SeeAlso:
      glfwGetGammaRamp, glfwSetGammaRamp

    Added in version 3.0. }
  TGLFWgammaramp = record
    red: PWord;
    green: PWord;
    blue: PWord;
    size: Cardinal;
  end;
  PGLFWgammaramp = ^TGLFWgammaramp;
  PPGLFWgammaramp = ^PGLFWgammaramp;

type
  { Image data.

    Added in version 2.1. GLFW3 removed format and bytes-per-pixel members. }
  TGLFWimage = record
    width: Integer;
    height: Integer;
    pixels: PByte;
  end;
  PGLFWimage = ^TGLFWimage;
  PPGLFWimage = ^PGLFWimage;

{************************************************************************
 * GLFW API functions
 ************************************************************************}

{ Initializes the GLFW library.

  This function initializes the GLFW library.  Before most GLFW functions can
  be used, GLFW must be initialized, and before an application terminates GLFW
  should be terminated in order to free any resources allocated during or
  after initialization.


  If this function fails, it calls glfwTerminate before returning.  If it
  succeeds, you should call glfwTerminate before the application exits.

  Additional calls to this function after successful initialization but before
  termination will return <tt>GLFW_TRUE</tt> immediately.

  Returns:
    <tt>GLFW_TRUE</tt> if successful, or <tt>GLFW_FALSE</tt> if an error
    occurred.

  Possible errors include GLFW_PLATFORM_ERROR.

  On macOS, this function will change the current directory of the application
  to the <tt>Contents/Resources</tt> subdirectory of the application's bundle,
  if present.

  This function must only be called from the main thread.

  SeeAlso:
    glfwTerminate

  Added in version 1.0. }
function glfwInit(): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwInit';

{ Terminates the GLFW library.

  This function destroys all remaining windows and cursors, restores any
  modified gamma ramps and frees any other allocated resources.  Once this
  function is called, you must again call glfwInit successfully before
  you will be able to use most GLFW functions.

  If GLFW has been successfully initialized, this function should be called
  before the application exits.  If initialization fails, there is no need to
  call this function, as it is called by glfwInit before it returns failure.

  Possible errors include GLFW_PLATFORM_ERROR.

  This function may be called before glfwInit.

  The contexts of any remaining windows must not be current on any other thread
  when this function is called.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwInit

  Added in version 1.0. }
procedure glfwTerminate();
  cdecl external GLFW3_LIB name _PU + 'glfwTerminate';

{ Retrieves the version of the GLFW library.

  This function retrieves the major, minor and revision numbers of the GLFW
  library.  It is intended for when you are using GLFW as a shared library and
  want to ensure that you are using the minimum required version.

  Any or all of the version arguments may be <tt>nil</tt>.

  Parameters:
    major: Where to store the major version number, or <tt>nil</tt>.
    minor: Where to store the minor version number, or <tt>nil</tt>.
    rev: Where to store the revision number, or <tt>nil</tt>.

  This function may be called before glfwInit.

  This function may be called from any thread.

  SeeAlso:
    glfwGetVersionString

  Added in version 1.0. }
procedure glfwGetVersion(major, minor, rev: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetVersion';

{ Returns a string describing the compile-time configuration.

  This function returns the compile-time generated version string of the GLFW
  library binary.  It describes the version, platform, compiler and any
  platform-specific compile-time options.  It should not be confused with the
  OpenGL or OpenGL ES version string, queried with <tt>glGetString</tt>.

  <b>Do not use the version string</b> to parse the GLFW library version.  The
  glfwGetVersion function provides the version of the running library binary in
  numerical format.

  Returns:
    The ASCII encoded GLFW version string.

  This function may be called before glfwInit.

  The returned string is static and compile-time generated.

  This function may be called from any thread.

  SeeAlso:
    glfwGetVersion

  Added in version 3.0. }
function glfwGetVersionString(): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetVersionString';

{ Sets the error callback.

  This function sets the error callback, which is called with an error code
  and a human-readable description each time a GLFW error occurs.

  The error callback is called on the thread where the error occurred.  If you
  are using GLFW from multiple threads, your error callback needs to be
  written accordingly.

  Because the description string may have been generated specifically for that
  error, it is not guaranteed to be valid after the callback has returned.  If
  you wish to use it after the callback returns, you need to make a copy.

  Once set, the error callback remains set even after the library has been
  terminated.

  Parameters:
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set.

  This function may be called before glfwInit.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetErrorCallback(cbfun: TGLFWerrorfun): TGLFWerrorfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetErrorCallback';

{ Returns the currently connected monitors.

  This function returns an array of handles for all currently connected
  monitors.  The primary monitor is always first in the returned array.  If no
  monitors were found, this function returns <tt>nil</tt>.

  Parameters:
    count: Where to store the number of monitors in the returned
      array.  This is set to zero if an error occurred.

  Returns:
    An array of monitor handles, or <tt>nil</tt> if no monitors were found or
    if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  The returned array is allocated and freed by GLFW.  You should not free it
  yourself.  It is guaranteed to be valid only until the monitor configuration
  changes or the library is terminated.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetPrimaryMonitor

  Added in version 3.0. }
function glfwGetMonitors(out count: Integer): PPGLFWmonitor;
  cdecl external GLFW3_LIB name _PU + 'glfwGetMonitors';

{ Returns the primary monitor.

  This function returns the primary monitor.  This is usually the monitor
  where elements like the task bar or global menu bar are located.

  Returns:
    The primary monitor, or <tt>nil</tt> if no monitors were found or if an
    error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  The primary monitor is always first in the array returned by glfwGetMonitors.

  SeeAlso:
    glfwGetMonitors

  Added in version 3.0. }
function glfwGetPrimaryMonitor(): PGLFWmonitor;
  cdecl external GLFW3_LIB name _PU + 'glfwGetPrimaryMonitor';

{ Returns the position of the monitor's viewport on the virtual screen.

  This function returns the position, in screen coordinates, of the upper-left
  corner of the specified monitor.

  Any or all of the position arguments may be <tt>nil</tt>.  If an error occurs,
  all non-<tt>nil</tt> position arguments will be set to zero.

  Parameters:
    monitor: The monitor to query.
    xpos: Where to store the monitor x-coordinate, or <tt>nil</tt>.
    ypos: Where to store the monitor y-coordinate, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.0. }
procedure glfwGetMonitorPos(monitor: PGLFWmonitor; xpos, ypos: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetMonitorPos';

{ Returns the physical size of the monitor.

  This function returns the size, in millimetres, of the display area of the
  specified monitor.

  Some systems do not provide accurate monitor size information, either
  because the monitor EDID (https://en.wikipedia.org/wiki/Extended_display_identification_data)
  data is incorrect or because the driver does not report it accurately.

  Any or all of the size arguments may be <tt>nil</tt>.  If an error occurs, all
  non-<tt>nil</tt> size arguments will be set to zero.

  Parameters:
    monitor: The monitor to query.
    widthMM: Where to store the width, in millimetres, of the
      monitor's display area, or <tt>nil</tt>.
    heightMM: Where to store the height, in millimetres, of the
      monitor's display area, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED.

  On Windows, calculates the returned physical size from the current resolution
  and system DPI instead of querying the monitor EDID data.

  This function must only be called from the main thread.

  Added in version 3.0. }
procedure glfwGetMonitorPhysicalSize(monitor: PGLFWmonitor; widthMM, heightMM: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetMonitorPhysicalSize';

{ Returns the name of the specified monitor.

  This function returns a human-readable name, encoded as UTF-8, of the
  specified monitor.  The name typically reflects the make and model of the
  monitor and is not guaranteed to be unique among the connected monitors.

  Parameters:
    monitor: The monitor to query.

  Returns:
    The UTF-8 encoded name of the monitor, or <tt>nil</tt> if an error
    occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  The returned string is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the specified monitor is disconnected or the
  library is terminated.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwGetMonitorName(monitor: PGLFWmonitor): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetMonitorName';

{ Sets the monitor configuration callback.

  This function sets the monitor configuration callback, or removes the
  currently set callback.  This is called when a monitor is connected to or
  disconnected from the system.

  Parameters:
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetMonitorCallback(cbfun: TGLFWmonitorfun): TGLFWmonitorfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetMonitorCallback';

{ Returns the available video modes for the specified monitor.

  This function returns an array of all video modes supported by the specified
  monitor.  The returned array is sorted in ascending order, first by color
  bit depth (the sum of all channel depths) and then by resolution area (the
  product of width and height).

  Parameters:
    monitor: The monitor to query.
    count: Where to store the number of video modes in the returned
      array.  This is set to zero if an error occurred.

  Returns:
    An array of video modes, or <tt>nil</tt> if an error occurred.


  Possible errors include ref GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The returned array is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the specified monitor is disconnected, this
  function is called again for that monitor or the library is terminated.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetVideoMode

  Added in version 1.0. GLFW3 changed to return an array of modes for a specific
  monitor. }
function glfwGetVideoModes(monitor: PGLFWmonitor; out count: Integer): PGLFWvidmode;
  cdecl external GLFW3_LIB name _PU + 'glfwGetVideoModes';

{ Returns the current mode of the specified monitor.

  This function returns the current video mode of the specified monitor.  If
  you have created a full screen window for that monitor, the return value
  will depend on whether that window is iconified.

  Parameters:
    monitor: The monitor to query.

  Returns:
    The current mode of the monitor, or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The returned array is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the specified monitor is disconnected or the
  library is terminated.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetVideoModes

  Added in version 3.0. Replaces <tt>glfwGetDesktopMode</tt>. }
function glfwGetVideoMode(monitor: PGLFWmonitor): PGLFWvidmode;
  cdecl external GLFW3_LIB name _PU + 'glfwGetVideoMode';

{ Generates a gamma ramp and sets it for the specified monitor.

  This function generates a 256-element gamma ramp from the specified exponent
  and then calls glfwSetGammaRamp with it.  The value must be a finite
  number greater than zero.

  Parameters:
    monitor: The monitor whose gamma ramp to set.
    gamma: The desired exponent.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_VALUE and
  GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.0. }
procedure glfwSetGamma(monitor: PGLFWmonitor; gamma: Single);
  cdecl external GLFW3_LIB name _PU + 'glfwSetGamma';

{ Returns the current gamma ramp for the specified monitor.

  This function returns the current gamma ramp of the specified monitor.

  Parameters:
    monitor: The monitor to query.

  Returns:
    The current gamma ramp, or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The returned structure and its arrays are allocated and freed by GLFW.  You
  should not free them yourself.  They are valid until the specified monitor is
  disconnected, this function is called again for that monitor or the library
  is terminated.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwGetGammaRamp(monitor: PGLFWmonitor): PGLFWgammaramp;
  cdecl external GLFW3_LIB name _PU + 'glfwGetGammaRamp';

{ Sets the current gamma ramp for the specified monitor.

  This function sets the current gamma ramp for the specified monitor.  The
  original gamma ramp for that monitor is saved by GLFW the first time this
  function is called and is restored by glfwTerminate.

  Parameters:
    monitor: The monitor whose gamma ramp to set.
    ramp: The gamma ramp to use.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  Gamma ramp sizes other than 256 are not supported by all platforms or
  graphics hardware.

  On Windows, the gamma ramp size must be 256.

  The specified gamma ramp is copied before this function returns.

  This function must only be called from the main thread.

  Added in version 3.0. }
procedure glfwSetGammaRamp(monitor: PGLFWmonitor; const ramp: PGLFWgammaramp);
  cdecl external GLFW3_LIB name _PU + 'glfwSetGammaRamp';

{ Resets all window hints to their default values.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  SeeAlso:
    glfwWindowHint

  Added in version 3.0. }
procedure glfwDefaultWindowHints();
  cdecl external GLFW3_LIB name _PU + 'glfwDefaultWindowHints';

{ Sets the specified window hint to the desired value.

  This function sets hints for the next call to glfwCreateWindow.  The
  hints, once set, retain their values until changed by a call to
  glfwWindowHint or glfwDefaultWindowHints, or until the library is
  terminated.

  This function does not check whether the specified hint values are valid.
  If you set hints to invalid values this will instead be reported by the next
  call to glfwCreateWindow.

  Parameters:
    hint: The window hint to set.
    value: The new value of the window hint.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_INVALID_ENUM.

  This function must only be called from the main thread.

  SeeAlso:
    glfwDefaultWindowHints

  Added in version 3.0. Replaces <tt>glfwOpenWindowHint</tt>. }
procedure glfwWindowHint(hint: Integer; value: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwWindowHint';

{ Creates a window and its associated context.

  This function creates a window and its associated OpenGL or OpenGL ES
  context.  Most of the options controlling how the window and its context
  should be created are specified with window hints.

  Successful creation does not change which context is current.  Before you
  can use the newly created context, you need to make it current.

  The created window, framebuffer and context may differ from what you
  requested, as not all parameters and hints are hard constraints.  This
  includes the size of the window, especially for full screen windows.  To query
  the actual attributes of the created window, framebuffer and context, see
  glfwGetWindowAttrib, glfwGetWindowSize and glfwGetFramebufferSize.

  To create a full screen window, you need to specify the monitor the window
  will cover.  If no monitor is specified, the window will be windowed mode.
  Unless you have a way for the user to choose a specific monitor, it is
  recommended that you pick the primary monitor.

  For full screen windows, the specified size becomes the resolution of the
  window's <i>desired video mode</i>.  As long as a full screen window is not
  iconified, the supported video mode most closely matching the desired video
  mode is set for the specified monitor.

  Once you have created the window, you can switch it between windowed and
  full screen mode with glfwSetWindowMonitor.  If the window has an OpenGL or
  OpenGL ES context, it will be unaffected.

  By default, newly created windows use the placement recommended by the
  window system.  To create the window at a specific position, make it
  initially invisible using the GLFW_VISIBLE window hint, set its position
  and then show it.

  As long as at least one full screen window is not iconified, the screensaver
  is prohibited from starting.

  Window systems put limits on window sizes.  Very large or very small window
  dimensions may be overridden by the window system on creation.  Check the
  actual size after creation.

  The swap interval is not set during window creation and the initial value may
  vary depending on driver settings and defaults.

  Parameters:
    width: The desired width, in screen coordinates, of the window.
      This must be greater than zero.
    height: The desired height, in screen coordinates, of the window.
      This must be greater than zero.
    title: The initial, UTF-8 encoded window title.
    monitor: The monitor to use for full screen mode, or <tt>nil</tt> for
      windowed mode.
    share: The window whose context to share resources with, or <tt>nil</tt>
      to not share resources.

  Returns:
    The handle of the created window, or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM,
  GLFW_INVALID_VALUE, GLFW_API_UNAVAILABLE, GLFW_VERSION_UNAVAILABLE,
  GLFW_FORMAT_UNAVAILABLE and GLFW_PLATFORM_ERROR.

  On Windows, window creation will fail if the Microsoft GDI software OpenGL
  implementation is the only one available.

  On Windows, if the executable has an icon resource named <tt>GLFW_ICON,</tt>
  it will be set as the initial icon for the window.  If no such icon is
  present, the <tt>IDI_WINLOGO</tt> icon will be used instead.  To set a
  different icon, see glfwSetWindowIcon.

  On Windows, the context to share resources with must not be current on
  any other thread.

  On macOS, the GLFW window has no icon, as it is not a document window, but the
  dock icon will be the same as the application bundle's icon. For more
  information on bundles, see the Bundle Programming Guide
  (https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/)
  in the Mac Developer Library.

  On macOS, the first time a window is created the menu bar is populated with
  common commands like Hide, Quit and About.  The About entry opens a minimal
  about dialog with information from the application's bundle.

  On OS X 10.10 and later the window frame will not be rendered at full
  resolution on Retina displays unless the <tt>NSHighResolutionCapable</tt>
  key is enabled in the application bundle's <tt>Info.plist</tt>.  For more
  information, see High Resolution Guidelines for OS X
  (https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Explained/Explained.html)
  in the Mac Developer Library.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwDestroyWindow

  Added in version 3.0.  Replaces <tt>glfwOpenWindow</tt>. }
function glfwCreateWindow(width: Integer; height: Integer; const title: PAnsiChar; monitor: PGLFWmonitor; share: PGLFWwindow): PGLFWwindow;
  cdecl external GLFW3_LIB name _PU + 'glfwCreateWindow';

{ Destroys the specified window and its context.

  This function destroys the specified window and its context.  On calling
  this function, no further callbacks will be called for that window.

  If the context of the specified window is current on the main thread, it is
  detached before being destroyed.

  Parameters:
    window: The window to destroy.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The context of the specified window must not be current on any other
  thread when this function is called.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwCreateWindow

  Added in version 3.0.  Replaces <tt>glfwCloseWindow</tt>. }
procedure glfwDestroyWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwDestroyWindow';

{ Checks the close flag of the specified window.

  This function returns the value of the close flag of the specified window.

  Parameters:
    window: The window to query.

  Returns:
    The value of the close flag.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.  Access is not synchronized.

  Added in version 3.0. }
function glfwWindowShouldClose(window: PGLFWwindow): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwWindowShouldClose';

{ Sets the close flag of the specified window.

  This function sets the value of the close flag of the specified window.
  This can be used to override the user's attempt to close the window, or
  to signal that it should be closed.

  Parameters:
    window: The window whose flag to change.
    value: The new value.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.  Access is not synchronized.

  Added in version 3.0. }
procedure glfwSetWindowShouldClose(window: PGLFWwindow; value: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowShouldClose';

{ Sets the title of the specified window.

  This function sets the window title, encoded as UTF-8, of the specified
  window.

  Parameters:
    window: The window whose title to change.
    title: The UTF-8 encoded window title.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  On macOS, the window title will not be updated until the next time you
  process events.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 Added window handle parameter. }
procedure glfwSetWindowTitle(window: PGLFWwindow; const title: PAnsiChar);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowTitle';

{ Sets the icon for the specified window.

  This function sets the icon of the specified window.  If passed an array of
  candidate images, those of or closest to the sizes desired by the system are
  selected.  If no images are specified, the window reverts to its default
  icon.

  The desired image sizes varies depending on platform and system settings.
  The selected images will be rescaled as needed.  Good sizes include 16x16,
  32x32 and 48x48.

  Parameters:
    window: The window whose icon to set.
    count: The number of images in the specified array, or zero to
      revert to the default window icon.
    images: The images to create the icon from.  This is ignored if
      count is zero.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The specified image data is copied before this function returns.

  On macOS, the GLFW window has no icon, as it is not a document window, so this
  function does nothing.  The dock icon will be the same as the application
  bundle's icon.  For more information on bundles, see the Bundle Programming
  Guide (https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/)
  in the Mac Developer Library.

  This function must only be called from the main thread.

  Added in version 3.2. }
procedure glfwSetWindowIcon(window: PGLFWwindow; count: Integer; const images: PGLFWimage);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowIcon';

{ Retrieves the position of the client area of the specified window.

  This function retrieves the position, in screen coordinates, of the
  upper-left corner of the client area of the specified window.

  Any or all of the position arguments may be <tt>nil</tt>.  If an error occurs,
  all non-<tt>nil</tt> position arguments will be set to zero.

  Parameters:
    window: The window to query.
    xpos: Where to store the x-coordinate of the upper-left corner of
      the client area, or <tt>nil</tt>.
    ypos: Where to store the y-coordinate of the upper-left corner of
      the client area, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetWindowPos

  Added in version 3.0. }
procedure glfwGetWindowPos(window: PGLFWwindow; xpos, ypos: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowPos';

{ Sets the position of the client area of the specified window.

  This function sets the position, in screen coordinates, of the upper-left
  corner of the client area of the specified windowed mode window.  If the
  window is a full screen window, this function does nothing.

  <b>Do not use this function</b> to move an already visible window unless you
  have very good reasons for doing so, as it will confuse and annoy the user.

  The window manager may put limits on what positions are allowed.  GLFW
  cannot and should not override these limits.

  Parameters:
    window: The window to query.
    xpos: The x-coordinate of the upper-left corner of the client area.
    ypos: The y-coordinate of the upper-left corner of the client area.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetWindowPos

  Added in version 1.0. GLFW3 added window handle parameter. }
procedure glfwSetWindowPos(window: PGLFWwindow; xpos, ypos: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowPos';

{ Retrieves the size of the client area of the specified window.

  This function retrieves the size, in screen coordinates, of the client area
  of the specified window.  If you wish to retrieve the size of the
  framebuffer of the window in pixels, see glfwGetFramebufferSize.

  Any or all of the size arguments may be <tt>nil</tt>.  If an error occurs, all
  non-<tt>nil</tt> size arguments will be set to zero.

  Parameters:
    window: The window whose size to retrieve.
    width: Where to store the width, in screen coordinates, of the
      client area, or <tt>nil</tt>.
    height: Where to store the height, in screen coordinates, of the
      client area, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetWindowSize

  Added in version 1.0. GLFW3 added window handle parameter. }
procedure glfwGetWindowSize(window: PGLFWwindow; width, height: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowSize';

{ Sets the size limits of the specified window.

  This function sets the size limits of the client area of the specified
  window.  If the window is full screen, the size limits only take effect
  once it is made windowed.  If the window is not resizable, this function
  does nothing.

  The size limits are applied immediately to a windowed mode window and may
  cause it to be resized.

  The maximum dimensions must be greater than or equal to the minimum
  dimensions and all must be greater than or equal to zero.

  Parameters:
    window: The window to set limits for.
    minwidth: The minimum width, in screen coordinates, of the client
      area, or <tt>GLFW_DONT_CARE</tt>.
    minheight: The minimum height, in screen coordinates, of the
      client area, or <tt>GLFW_DONT_CARE</tt>.
    maxwidth: The maximum width, in screen coordinates, of the client
      area, or <tt>GLFW_DONT_CARE</tt>.
    maxheight: The maximum height, in screen coordinates, of the
      client area, or <tt>GLFW_DONT_CARE</tt>.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_VALUE and
  GLFW_PLATFORM_ERROR.

  If you set size limits and an aspect ratio that conflict, the results are
  undefined.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetWindowAspectRatio

  Added in version 3.2. }
procedure glfwSetWindowSizeLimits(window: PGLFWwindow; minwidth, minheight, maxwidth, maxheight: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowSizeLimits';

{ Sets the aspect ratio of the specified window.

  This function sets the required aspect ratio of the client area of the
  specified window.  If the window is full screen, the aspect ratio only takes
  effect once it is made windowed.  If the window is not resizable, this
  function does nothing.

  The aspect ratio is specified as a numerator and a denominator and both
  values must be greater than zero.  For example, the common 16:9 aspect ratio
  is specified as 16 and 9, respectively.

  If the numerator and denominator is set to <tt>GLFW_DONT_CARE</tt> then the
  aspect ratio limit is disabled.

  The aspect ratio is applied immediately to a windowed mode window and may
  cause it to be resized.

  Parameters:
    window: The window to set limits for.
    numer: The numerator of the desired aspect ratio, or
      <tt>GLFW_DONT_CARE</tt>.
    denom: The denominator of the desired aspect ratio, or
      <tt>GLFW_DONT_CARE</tt>.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_VALUE and
  GLFW_PLATFORM_ERROR.

  If you set size limits and an aspect ratio that conflict, the
  results are undefined.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetWindowSizeLimits

  Added in version 3.2. }
procedure glfwSetWindowAspectRatio(window: PGLFWwindow; numer, denom: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowAspectRatio';

{ Sets the size of the client area of the specified window.

  This function sets the size, in screen coordinates, of the client area of
  the specified window.

  For full screen windows, this function updates the resolution of its desired
  video mode and switches to the video mode closest to it, without affecting
  the window's context.  As the context is unaffected, the bit depths of the
  framebuffer remain unchanged.

  If you wish to update the refresh rate of the desired video mode in addition
  to its resolution, see glfwSetWindowMonitor.

  The window manager may put limits on what sizes are allowed.  GLFW cannot
  and should not override these limits.

  Parameters:
    window: The window to resize.
    width: The desired width, in screen coordinates, of the window
      client area.
    height: The desired height, in screen coordinates, of the window
      client area.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetWindowSize
    glfwSetWindowMonitor

  Added in version 1.0. GLFW3 added window handle parameter. }
procedure glfwSetWindowSize(window: PGLFWwindow; width, height: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowSize';

{ Retrieves the size of the framebuffer of the specified window.

  This function retrieves the size, in pixels, of the framebuffer of the
  specified window.  If you wish to retrieve the size of the window in screen
  coordinates, see glfwGetWindowSize.

  Any or all of the size arguments may be <tt>nil</tt>.  If an error occurs, all
  non-<tt>nil</tt> size arguments will be set to zero.

  Parameters:
    window: The window whose framebuffer to query.
    width: Where to store the width, in pixels, of the framebuffer,
      or <tt>nil</tt>.
    height: Where to store the height, in pixels, of the framebuffer,
      or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetFramebufferSizeCallback

  Added in version 3.0. }
procedure glfwGetFramebufferSize(window: PGLFWwindow; width, height: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetFramebufferSize';

{ Retrieves the size of the frame of the window.

  This function retrieves the size, in screen coordinates, of each edge of the
  frame of the specified window.  This size includes the title bar, if the
  window has one.  The size of the frame may vary depending on the
  window-related hints used to create it.

  Because this function retrieves the size of each window frame edge and not
  the offset along a particular coordinate axis, the retrieved values will
  always be zero or positive.

  Any or all of the size arguments may be <tt>nil</tt>.  If an error occurs, all
  non-<tt>nil</tt> size arguments will be set to zero.

  Parameters:
    window: The window whose frame size to query.
    left: Where to store the size, in screen coordinates, of the left
      edge of the window frame, or <tt>nil</tt>.
    top: Where to store the size, in screen coordinates, of the top
      edge of the window frame, or <tt>nil</tt>.
    right: Where to store the size, in screen coordinates, of the
      right edge of the window frame, or <tt>nil</tt>.
    bottom: Where to store the size, in screen coordinates, of the
      bottom edge of the window frame, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.1. }
procedure glfwGetWindowFrameSize(window: PGLFWwindow; left, top, right, bottom: PInteger);
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowFrameSize';

{ Iconifies the specified window.

  This function iconifies (minimizes) the specified window if it was
  previously restored.  If the window is already iconified, this function does
  nothing.

  If the specified window is a full screen window, the original monitor
  resolution is restored until the window is restored.

  Parameters:
    window: The window to iconify.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwRestoreWindow
    glfwMaximizeWindow

  Added in version 2.1. GLFW3 added window handle parameter. }
procedure glfwIconifyWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwIconifyWindow';

{ Restores the specified window.

  This function restores the specified window if it was previously iconified
  (minimized) or maximized.  If the window is already restored, this function
  does nothing.

  If the specified window is a full screen window, the resolution chosen for
  the window is restored on the selected monitor.

  Parameters:
    window: The window to restore.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwIconifyWindow
    glfwMaximizeWindow

  Added in version 2.1. GLFW3 added window handle parameter. }
procedure glfwRestoreWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwRestoreWindow';

{ Maximizes the specified window.

  This function maximizes the specified window if it was previously not
  maximized.  If the window is already maximized, this function does nothing.

  If the specified window is a full screen window, this function does nothing.

  Parameters:
    window: The window to maximize.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function may only be called from the main thread.

  SeeAlso:
    glfwIconifyWindow
    glfwRestoreWindow

  Added in GLFW 3.2. }
procedure glfwMaximizeWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwMaximizeWindow';

{ Makes the specified window visible.

  This function makes the specified window visible if it was previously
  hidden.  If the window is already visible or is in full screen mode, this
  function does nothing.

  Parameters:
    window: The window to make visible.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwHideWindow

  Added in version 3.0. }
procedure glfwShowWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwShowWindow';

{ Hides the specified window.

  This function hides the specified window if it was previously visible.  If
  the window is already hidden or is in full screen mode, this function does
  nothing.

  Parameters:
    window: The window to hide.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwShowWindow

  Added in version 3.0. }
procedure glfwHideWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwHideWindow';

{ Brings the specified window to front and sets input focus.

  This function brings the specified window to front and sets input focus.
  The window should already be visible and not iconified.

  By default, both windowed and full screen mode windows are focused when
  initially created.  Set GLFW_FOCUSED to disable this behavior.

  <b>Do not use this function</b> to steal focus from other applications unless
  you are certain that is what the user wants.  Focus stealing can be
  extremely disruptive.

  Parameters:
    window: The window to give input focus.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.2. }
procedure glfwFocusWindow(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwFocusWindow';

{ Returns the monitor that the window uses for full screen mode.

  This function returns the handle of the monitor that the specified window is
  in full screen on.

  Parameters:
    window: The window to query.

  Returns:
    The monitor, or <tt>nil</tt> if the window is in windowed mode or an
    error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetWindowMonitor

  Added in version 3.0. }
function glfwGetWindowMonitor(window: PGLFWwindow): PGLFWmonitor;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowMonitor';

{ Sets the mode, monitor, video mode and placement of a window.

  This function sets the monitor that the window uses for full screen mode or,
  if the monitor is <tt>nil</tt>, makes it windowed mode.

  When setting a monitor, this function updates the width, height and refresh
  rate of the desired video mode and switches to the video mode closest to it.
  The window position is ignored when setting a monitor.

  When the monitor is <tt>nil</tt>, the position, width and height are used to
  place the window client area.  The refresh rate is ignored when no monitor
  is specified.

  If you only wish to update the resolution of a full screen window or the
  size of a windowed mode window, see glfwSetWindowSize.

  When a window transitions from full screen to windowed mode, this function
  restores any previous window settings such as whether it is decorated,
  floating, resizable, has size or aspect ratio limits, etc..

  Parameters:
    window: The window whose monitor, size or video mode to set.
    monitor: The desired monitor, or <tt>nil</tt> to set windowed mode.
    xpos: The desired x-coordinate of the upper-left corner of the
      client area.
    ypos: The desired y-coordinate of the upper-left corner of the
      client area.
    width: The desired with, in screen coordinates, of the client area
      or video mode.
    height: The desired height, in screen coordinates, of the client
      area or video mode.
    refreshRate: The desired refresh rate, in Hz, of the video mode,
      or <tt>GLFW_DONT_CARE</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetWindowMonitor
    glfwSetWindowSize

  Added in version 3.2. }
procedure glfwSetWindowMonitor(window: PGLFWwindow; monitor: PGLFWmonitor; xpos, ypos, width, height, refreshRate: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowMonitor';

{ Returns an attribute of the specified window.

  This function returns the value of an attribute of the specified window or
  its OpenGL or OpenGL ES context.

  Parameters:
    window: The window to query.
    attrib: The window attribute whose value to return.

  Returns:
    The value of the attribute, or zero if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  Framebuffer related hints are not window attributes.

  Zero is a valid value for many window and context related attributes so you
  cannot use a return value of zero as an indication of errors.  However, this
  function should not fail as long as it is passed valid arguments and the
  library has been initialized.

  This function must only be called from the main thread.

  Added in version 3.0.  Replaces <tt>glfwGetWindowParam</tt> and
  <tt>glfwGetGLVersion</tt>. }
function glfwGetWindowAttrib(window: PGLFWwindow; attrib: Integer): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowAttrib';

{ Sets the user pointer of the specified window.

  This function sets the user-defined pointer of the specified window.  The
  current value is retained until the window is destroyed.  The initial value
  is <tt>nil</tt>.

  Parameters:
    window: The window whose pointer to set.
    pointer: The new value.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.  Access is not
  synchronized.

  SeeAlso:
    glfwGetWindowUserPointer

  Added in version 3.0. }
procedure glfwSetWindowUserPointer(window: PGLFWwindow; pointer: Pointer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowUserPointer';

{ Returns the user pointer of the specified window.

  This function returns the current value of the user-defined pointer of the
  specified window.  The initial value is <tt>nil</tt>.

  Parameters:
    window: The window whose pointer to return.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.  Access is not synchronized.

  SeeAlso:
    glfwSetWindowUserPointer

  Added in version 3.0. }
function glfwGetWindowUserPointer(window: PGLFWwindow): Pointer;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWindowUserPointer';

{ Sets the position callback for the specified window.

  This function sets the position callback of the specified window, which is
  called when the window is moved.  The callback is provided with the screen
  position of the upper-left corner of the client area of the window.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetWindowPosCallback(window: PGLFWwindow; cbfun: TGLFWwindowposfun): TGLFWwindowposfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowPosCallback';

{ Sets the size callback for the specified window.

  This function sets the size callback of the specified window, which is
  called when the window is resized.  The callback is provided with the size,
  in screen coordinates, of the client area of the window.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns: The previously set callback, or <tt>nil</tt> if no callback was set
  or the library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 added window handle parameter and return value. }
function glfwSetWindowSizeCallback(window: PGLFWwindow; cbfun: TGLFWwindowsizefun): TGLFWwindowsizefun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowSizeCallback';

{ Sets the close callback for the specified window.

  This function sets the close callback of the specified window, which is
  called when the user attempts to close the window, for example by clicking
  the close widget in the title bar.

  The close flag is set before this callback is called, but you can modify it
  at any time with glfwSetWindowShouldClose.

  The close callback is not triggered by glfwDestroyWindow.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  On macOS, selecting Quit from the application menu will trigger the close
  callback for all windows.

  This function must only be called from the main thread.

  Added in version 2.5. GLFW3 added window handle parameter and return value. }
function glfwSetWindowCloseCallback(window: PGLFWwindow; cbfun: TGLFWwindowclosefun): TGLFWwindowclosefun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowCloseCallback';

{ Sets the refresh callback for the specified window.

  This function sets the refresh callback of the specified window, which is
  called when the client area of the window needs to be redrawn, for example
  if the window has been exposed after having been covered by another window.

  On compositing window systems such as Aero, Compiz or Aqua, where the window
  contents are saved off-screen, this callback may be called only very
  infrequently or never at all.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 2.5. GLFW3 added window handle parameter and return value. }
function glfwSetWindowRefreshCallback(window: PGLFWwindow; cbfun: TGLFWwindowrefreshfun): TGLFWwindowrefreshfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowRefreshCallback';

{ Sets the focus callback for the specified window.

  This function sets the focus callback of the specified window, which is
  called when the window gains or loses input focus.

  After the focus callback is called for a window that lost input focus,
  synthetic key and mouse button release events will be generated for all such
  that had been pressed.  For more information, see glfwSetKeyCallback
  and glfwSetMouseButtonCallback.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetWindowFocusCallback(window: PGLFWwindow; cbfun: TGLFWwindowfocusfun): TGLFWwindowfocusfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowFocusCallback';

{ Sets the iconify callback for the specified window.

  This function sets the iconification callback of the specified window, which
  is called when the window is iconified or restored.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetWindowIconifyCallback(window: PGLFWwindow; cbfun: TGLFWwindowiconifyfun): TGLFWwindowiconifyfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetWindowIconifyCallback';

{ Sets the framebuffer resize callback for the specified window.

  This function sets the framebuffer resize callback of the specified window,
  which is called when the framebuffer of the specified window is resized.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetFramebufferSizeCallback(window: PGLFWwindow; cbfun: TGLFWframebuffersizefun): TGLFWframebuffersizefun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetFramebufferSizeCallback';

{ Processes all pending events.

  This function processes only those events that are already in the event
  queue and then returns immediately.  Processing events will cause the window
  and input callbacks associated with those events to be called.

  On some platforms, a window move, resize or menu operation will cause event
  processing to block.  This is due to how event processing is designed on
  those platforms.  You can use the window refresh callback to redraw the
  contents of your window when necessary during such operations.

  On some platforms, certain events are sent directly to the application
  without going through the event queue, causing callbacks to be called
  outside of a call to one of the event processing functions.

  Event processing is not required for joystick input to work.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwWaitEvents
    glfwWaitEventsTimeout

  Added in version 1.0. }
procedure glfwPollEvents();
  cdecl external GLFW3_LIB name _PU + 'glfwPollEvents';

{ Waits until events are queued and processes them.

  This function puts the calling thread to sleep until at least one event is
  available in the event queue.  Once one or more events are available,
  it behaves exactly like glfwPollEvents, i.e. the events in the queue
  are processed and the function then returns immediately.  Processing events
  will cause the window and input callbacks associated with those events to be
  called.

  Since not all events are associated with callbacks, this function may return
  without a callback having been called even if you are monitoring all
  callbacks.

  On some platforms, a window move, resize or menu operation will cause event
  processing to block.  This is due to how event processing is designed on
  those platforms.  You can use the window refresh callback to redraw the
  contents of your window when necessary during such operations.

  On some platforms, certain callbacks may be called outside of a call to one
  of the event processing functions.

  If no windows exist, this function returns immediately.  For synchronization
  of threads in applications that do not create windows, use your threading
  library of choice.

  Event processing is not required for joystick input to work.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwPollEvents
    glfwWaitEventsTimeout

  Added in version 2.5. }
procedure glfwWaitEvents();
  cdecl external GLFW3_LIB name _PU + 'glfwWaitEvents';

{ Waits with timeout until events are queued and processes them.

  This function puts the calling thread to sleep until at least one event is
  available in the event queue, or until the specified timeout is reached.  If
  one or more events are available, it behaves exactly like glfwPollEvents,
  i.e. the events in the queue are processed and the function then returns
  immediately.  Processing events will cause the window and input callbacks
  associated with those events to be called.

  The timeout value must be a positive finite number.

  Since not all events are associated with callbacks, this function may return
  without a callback having been called even if you are monitoring all
  callbacks.

  On some platforms, a window move, resize or menu operation will cause event
  processing to block.  This is due to how event processing is designed on
  those platforms.  You can use the window refresh callback to redraw the
  contents of your window when necessary during such operations.

  On some platforms, certain callbacks may be called outside of a call to one
  of the event processing functions.

  If no windows exist, this function returns immediately.  For synchronization
  of threads in applications that do not create windows, use your threading
  library of choice.

  Event processing is not required for joystick input to work.

  Parameters:
    timeout: The maximum amount of time, in seconds, to wait.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwPollEvents
    glfwWaitEvents

  Added in version 3.2. }
procedure glfwWaitEventsTimeout(timeout: Double);
  cdecl external GLFW3_LIB name _PU + 'glfwWaitEventsTimeout';

{ Posts an empty event to the event queue.

  This function posts an empty event from the current thread to the event
  queue, causing glfwWaitEvents or glfwWaitEventsTimeout to return.

  If no windows exist, this function returns immediately.  For synchronization
  of threads in applications that do not create windows, use your threading
  library of choice.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function may be called from any thread.

  SeeAlso:
    glfwWaitEvents
    glfwWaitEventsTimeout

  Added in version 3.1. }
procedure glfwPostEmptyEvent();
  cdecl external GLFW3_LIB name _PU + 'glfwPostEmptyEvent';

{ Returns the value of an input option for the specified window.

  This function returns the value of an input option for the specified window.
  The mode must be one of <tt>GLFW_CURSOR</tt>, <tt>GLFW_STICKY_KEYS</tt> or
  <tt>GLFW_STICKY_MOUSE_BUTTONS</tt>.

  Parameters:
    window: The window to query.
    mode: One of <tt>GLFW_CURSOR</tt>, <tt>GLFW_STICKY_KEYS</tt> or
      <tt>GLFW_STICKY_MOUSE_BUTTONS</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_INVALID_ENUM.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetInputMode

  Added in version 3.0. }
function glfwGetInputMode(window: PGLFWwindow; mode: Integer): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwGetInputMode';

{ Sets an input option for the specified window.

  This function sets an input mode option for the specified window.  The mode
  must be one of <tt>GLFW_CURSOR</tt>, <tt>GLFW_STICKY_KEYS</tt> or
  <tt>GLFW_STICKY_MOUSE_BUTTONS</tt>.

  If the mode is <tt>GLFW_CURSOR</tt>, the value must be one of the following
  cursor modes:
  * <tt>GLFW_CURSOR_NORMAL</tt> makes the cursor visible and behaving normally.
  * <tt>GLFW_CURSOR_HIDDEN</tt> makes the cursor invisible when it is over the
    client area of the window but does not restrict the cursor from leaving.
  * <tt>GLFW_CURSOR_DISABLED</tt> hides and grabs the cursor, providing virtual
    and unlimited cursor movement.  This is useful for implementing for
    example 3D camera controls.

  If the mode is <tt>GLFW_STICKY_KEYS</tt>, the value must be either
  <tt>GLFW_TRUE</tt> to enable sticky keys, or <tt>GLFW_FALSE</tt> to disable
  it.  If sticky keys are enabled, a key press will ensure that glfwGetKey
  returns <tt>GLFW_PRESS</tt> the next time it is called even if the key had
  been released before the call.  This is useful when you are only interested
  in whether keys have been pressed but not when or in which order.

  If the mode is <tt>GLFW_STICKY_MOUSE_BUTTONS</tt>, the value must be either
  <tt>GLFW_TRUE</tt> to enable sticky mouse buttons, or <tt>GLFW_FALSE</tt> to
  disable it. If sticky mouse buttons are enabled, a mouse button press will
  ensure that glfwGetMouseButton returns <tt>GLFW_PRESS</tt> the next time it
  is called even if the mouse button had been released before the call.  This
  is useful when you are only interested in whether mouse buttons have been
  pressed but not when or in which order.

  Parameters:
    window: The window whose input mode to set.
    mode: One of <tt>GLFW_CURSOR</tt>, <tt>GLFW_STICKY_KEYS</tt> or
      <tt>GLFW_STICKY_MOUSE_BUTTONS</tt>.
    value: The new value of the specified input mode.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetInputMode

  Added in version 3.0.  Replaces <tt>glfwEnable</tt> and <tt>glfwDisable</tt>. }
procedure glfwSetInputMode(window: PGLFWwindow; mode, value: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSetInputMode';

{ Returns the localized name of the specified printable key.

  This function returns the localized name of the specified printable key.
  This is intended for displaying key bindings to the user.

  If the key is <tt>GLFW_KEY_UNKNOWN</tt>, the scancode is used instead,
  otherwise the scancode is ignored.  If a non-printable key or (if the key is
  <tt>GLFW_KEY_UNKNOWN</tt>) a scancode that maps to a non-printable key is
  specified, this function returns <tt>nil</tt>.

  This behavior allows you to pass in the arguments passed to the
  key callback without modification.

  The printable keys are:
  * <tt>GLFW_KEY_APOSTROPHE</tt>
  * <tt>GLFW_KEY_COMMA</tt>
  * <tt>GLFW_KEY_MINUS</tt>
  * <tt>GLFW_KEY_PERIOD</tt>
  * <tt>GLFW_KEY_SLASH</tt>
  * <tt>GLFW_KEY_SEMICOLON</tt>
  * <tt>GLFW_KEY_EQUAL</tt>
  * <tt>GLFW_KEY_LEFT_BRACKET</tt>
  * <tt>GLFW_KEY_RIGHT_BRACKET</tt>
  * <tt>GLFW_KEY_BACKSLASH</tt>
  * <tt>GLFW_KEY_WORLD_1</tt>
  * <tt>GLFW_KEY_WORLD_2</tt>
  * <tt>GLFW_KEY_0</tt> to <tt>GLFW_KEY_9</tt>
  * <tt>GLFW_KEY_A</tt> to <tt>GLFW_KEY_Z</tt>
  * <tt>GLFW_KEY_KP_0</tt> to <tt>GLFW_KEY_KP_9</tt>
  * <tt>GLFW_KEY_KP_DECIMAL</tt>
  * <tt>GLFW_KEY_KP_DIVIDE</tt>
  * <tt>GLFW_KEY_KP_MULTIPLY</tt>
  * <tt>GLFW_KEY_KP_SUBTRACT</tt>
  * <tt>GLFW_KEY_KP_ADD</tt>
  * <tt>GLFW_KEY_KP_EQUAL</tt>

  Parameters:
    key: The key to query, or <tt>GLFW_KEY_UNKNOWN</tt>.
    scancode: The scancode of the key to query.

  Returns:
    The localized name of the key, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The returned string is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the next call to glfwGetKeyName, or until the
  library is terminated.

  This function must only be called from the main thread.

  Added in version 3.2. }
function glfwGetKeyName(key: Integer; scancode: Integer): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetKeyName';

{ Returns the last reported state of a keyboard key for the specified
  window.

  This function returns the last state reported for the specified key to the
  specified window.  The returned state is one of <tt>GLFW_PRESS</tt> or
  <tt>GLFW_RELEASE</tt>.  The higher-level action <tt>GLFW_REPEAT</tt> is only
  reported to the key callback.

  If the <tt>GLFW_STICKY_KEYS</tt> input mode is enabled, this function returns
  <tt>GLFW_PRESS</tt> the first time you call it for a key that was pressed,
  even if that key has already been released.

  The key functions deal with physical keys, with key tokens named after their
  use on the standard US keyboard layout.  If you want to input text, use the
  Unicode character callback instead.

  The modifier key bit masks are not key tokens and cannot be used with this
  function.

  <b>Do not use this function</b> to implement text input.

  Parameters:
    window: The desired window.
    key: The desired keyboard key.  <tt>GLFW_KEY_UNKNOWN</tt> is
     not a valid key for this function.

  Returns:
    One of <tt>GLFW_PRESS</tt> or <tt>GLFW_RELEASE</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_INVALID_ENUM.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 added window handle parameter. }
function glfwGetKey(window: PGLFWwindow; key: Integer): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwGetKey';

{ Returns the last reported state of a mouse button for the specified
  window.

  This function returns the last state reported for the specified mouse button
  to the specified window.  The returned state is one of <tt>GLFW_PRESS</tt> or
  <tt>GLFW_RELEASE</tt>.

  If the <tt>GLFW_STICKY_MOUSE_BUTTONS</tt> input mode is enabled, this function
  <tt>GLFW_PRESS</tt> the first time you call it for a mouse button that was
  pressed, even if that mouse button has already been released.

  Parameters:
    window: The desired window.
    button: The desired mouse button.

  Returns:
    One of <tt>GLFW_PRESS</tt> or <tt>GLFW_RELEASE</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_INVALID_ENUM.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 added window handle parameter. }
function glfwGetMouseButton(window: PGLFWwindow; button: Integer): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwGetMouseButton';

{ Retrieves the position of the cursor relative to the client area of
  the window.

  This function returns the position of the cursor, in screen coordinates,
  relative to the upper-left corner of the client area of the specified
  window.

  If the cursor is disabled (with <tt>GLFW_CURSOR_DISABLED</tt>) then the cursor
  position is unbounded and limited only by the minimum and maximum values of
  a <tt>double</tt>.

  The coordinate can be converted to their integer equivalents with the
  <tt>floor</tt> function.  Casting directly to an integer type works for
  positive coordinates, but fails for negative ones.

  Any or all of the position arguments may be <tt>nil</tt>.  If an error occurs,
  all non-<tt>nil</tt> position arguments will be set to zero.

  Parameters:
    window: The desired window.
    xpos: Where to store the cursor x-coordinate, relative to the
      left edge of the client area, or <tt>nil</tt>.
    ypos: Where to store the cursor y-coordinate, relative to the to
      top edge of the client area, or <tt>nil</tt>.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetCursorPos

  Added in version 3.0.  Replaces <tt>glfwGetMousePos</tt>. }
procedure glfwGetCursorPos(window: PGLFWwindow; xpos, ypos: PDouble);
  cdecl external GLFW3_LIB name _PU + 'glfwGetCursorPos';

{ Sets the position of the cursor, relative to the client area of the
  window.

  This function sets the position, in screen coordinates, of the cursor
  relative to the upper-left corner of the client area of the specified
  window.  The window must have input focus.  If the window does not have
  input focus when this function is called, it fails silently.

  <b>Do not use this function</b> to implement things like camera controls.
  GLFW already provides the <tt>GLFW_CURSOR_DISABLED</tt> cursor mode that hides
  the cursor, transparently re-centers it and provides unconstrained cursor
  motion.  See glfwSetInputMode for more information.

  If the cursor mode is <tt>GLFW_CURSOR_DISABLED</tt> then the cursor position
  is unconstrained and limited only by the minimum and maximum values of
  a <tt>double</tt>.

  Parameters:
    window: The desired window.
    xpos: The desired x-coordinate, relative to the left edge of the
      client area.
    ypos: The desired y-coordinate, relative to the top edge of the
      client area.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetCursorPos

  Added in version 3.0.  Replaces <tt>glfwSetMousePos</tt>. }
procedure glfwSetCursorPos(window: PGLFWwindow; xpos, ypos: Double);
  cdecl external GLFW3_LIB name _PU + 'glfwSetCursorPos';

{ Creates a custom cursor.

  Creates a new custom cursor image that can be set for a window with
  glfwSetCursor.  The cursor can be destroyed with glfwDestroyCursor.
  Any remaining cursors are destroyed by glfwTerminate.

  The pixels are 32-bit, little-endian, non-premultiplied RGBA, i.e. eight
  bits per channel.  They are arranged canonically as packed sequential rows,
  starting from the top-left corner.

  The cursor hotspot is specified in pixels, relative to the upper-left corner
  of the cursor image.  Like all other coordinate systems in GLFW, the X-axis
  points to the right and the Y-axis points down.

  Parameters:
    image: The desired cursor image.
    xhot: The desired x-coordinate, in pixels, of the cursor hotspot.
    yhot: The desired y-coordinate, in pixels, of the cursor hotspot.

  Returns:
    The handle of the created cursor, or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The specified image data is copied before this function
  returns.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwDestroyCursor
    glfwCreateStandardCursor

  Added in version 3.1. }
function glfwCreateCursor(const image: PGLFWimage; xhot: Integer; yhot: Integer): PGLFWcursor;
  cdecl external GLFW3_LIB name _PU + 'glfwCreateCursor';

{ Creates a cursor with a standard shape.

  Returns a cursor with a standard shape, that can be set for a window with
  glfwSetCursor.

  Parameters:
    shape: One of the standard shapes.

  Returns:
    A new cursor ready to use or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwCreateCursor

  Added in version 3.1. }
function glfwCreateStandardCursor(shape: Integer): PGLFWcursor;
  cdecl external GLFW3_LIB name _PU + 'glfwCreateStandardCursor';

{ Destroys a cursor.

  This function destroys a cursor previously created with
  glfwCreateCursor.  Any remaining cursors will be destroyed by
  glfwTerminate.

  Parameters:
    cursor: The cursor object to destroy.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must not be called from a callback.

  This function must only be called from the main thread.

  SeeAlso:
    glfwCreateCursor

  Added in version 3.1. }
procedure glfwDestroyCursor(cursor: PGLFWcursor);
  cdecl external GLFW3_LIB name _PU + 'glfwDestroyCursor';

{ Sets the cursor for the window.

  This function sets the cursor image to be used when the cursor is over the
  client area of the specified window.  The set cursor will only be visible
  when the cursor mode of the window is <tt>GLFW_CURSOR_NORMAL</tt>.

  On some platforms, the set cursor may not be visible unless the window also
  has input focus.

  Parameters:
    window: The window to set the cursor for.
    cursor: The cursor to set, or <tt>nil</tt> to switch back to the default
      arrow cursor.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.1. }
procedure glfwSetCursor(window: PGLFWwindow; cursor: PGLFWcursor);
  cdecl external GLFW3_LIB name _PU + 'glfwSetCursor';

{ Sets the key callback.

  This function sets the key callback of the specified window, which is called
  when a key is pressed, repeated or released.

  The key functions deal with physical keys, with layout independent
  key tokens named after their values in the standard US keyboard
  layout.  If you want to input text, use the character callback instead.

  When a window loses input focus, it will generate synthetic key release
  events for all pressed keys.  You can tell these events from user-generated
  events by the fact that the synthetic ones are generated after the focus
  loss event has been processed, i.e. after the window focus callback
  (glfwSetWindowFocusCallback) has been called.

  The scancode of a key is specific to that platform or sometimes even to that
  machine.  Scancodes are intended to allow users to bind keys that don't have
  a GLFW key token.  Such keys have <tt>key</tt> set to
  <tt>GLFW_KEY_UNKNOWN</tt>, their state is not saved and so it cannot be
  queried with glfwGetKey.

  Sometimes GLFW needs to generate synthetic key events, in which case the
  scancode may be zero.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new key callback, or <tt>nil</tt> to remove the currently
     set callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 added window handle parameter and return value. }
function glfwSetKeyCallback(window: PGLFWwindow; cbfun: TGLFWkeyfun): TGLFWkeyfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetKeyCallback';

{ Sets the Unicode character callback.

  This function sets the character callback of the specified window, which is
  called when a Unicode character is input.

  The character callback is intended for Unicode text input.  As it deals with
  characters, it is keyboard layout dependent, whereas the key callback
  (glfwSetKeyCallback) is not.  Characters do not map 1:1 to physical keys, as
  a key may produce zero, one or more characters.  If you want to know whether
  a specific physical key was pressed or released, see the key callback instead.

  The character callback behaves as system text input normally does and will
  not be called if modifier keys are held down that would prevent normal text
  input on that platform, for example a Super (Command) key on OS X or Alt key
  on Windows.  There is a character with modifiers callback
  (glfwSetCharModsCallback) that receives these events.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 2.4. GLFW3 added window handle parameter and return value. }
function glfwSetCharCallback(window: PGLFWwindow; cbfun: TGLFWcharfun): TGLFWcharfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetCharCallback';

{ Sets the Unicode character with modifiers callback.

  This function sets the character with modifiers callback of the specified
  window, which is called when a Unicode character is input regardless of what
  modifier keys are used.

  The character with modifiers callback is intended for implementing custom
  Unicode character input.  For regular Unicode text input, see the
  character callback (glfwSetCharCallback).  Like the character callback, the
  character with modifiers callback deals with characters and is keyboard
  layout dependent.  Characters do not map 1:1 to physical keys, as a key may
  produce zero, one or more characters.  If you want to know whether a
  specific physical key was pressed or released, see the  key callback
  (glfwSetKeyCallback) instead.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or an
    error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.1. }
function glfwSetCharModsCallback(window: PGLFWwindow; cbfun: TGLFWcharmodsfun): TGLFWcharmodsfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetCharModsCallback';

{ Sets the mouse button callback.

  This function sets the mouse button callback of the specified window, which
  is called when a mouse button is pressed or released.

  When a window loses input focus, it will generate synthetic mouse button
  release events for all pressed mouse buttons.  You can tell these events
  from user-generated events by the fact that the synthetic ones are generated
  after the focus loss event has been processed, i.e. after the
  window focus callback (glfwSetWindowFocusCallback) has been called.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 1.0. GLFW3 added window handle parameter and return value. }
function glfwSetMouseButtonCallback(window: PGLFWwindow; cbfun: TGLFWmousebuttonfun): TGLFWmousebuttonfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetMouseButtonCallback';

{ Sets the cursor position callback.

  This function sets the cursor position callback of the specified window,
  which is called when the cursor is moved.  The callback is provided with the
  position, in screen coordinates, relative to the upper-left corner of the
  client area of the window.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0.  Replaces <tt>glfwSetMousePosCallback</tt>. }
function glfwSetCursorPosCallback(window: PGLFWwindow; cbfun: TGLFWcursorposfun): TGLFWcursorposfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetCursorPosCallback';

{ Sets the cursor enter/exit callback.

  This function sets the cursor boundary crossing callback of the specified
  window, which is called when the cursor enters or leaves the client area of
  the window.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwSetCursorEnterCallback(window: PGLFWwindow; cbfun: TGLFWcursorenterfun): TGLFWcursorenterfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetCursorEnterCallback';

{ Sets the scroll callback.

  This function sets the scroll callback of the specified window, which is
  called when a scrolling device is used, such as a mouse wheel or scrolling
  area of a touchpad.

  The scroll callback receives all scrolling input, like that from a mouse
  wheel or a touchpad scrolling area.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new scroll callback, or <tt>nil</tt> to remove the currently
      set callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.0.  Replaces <tt>glfwSetMouseWheelCallback</tt>. }
function glfwSetScrollCallback(window: PGLFWwindow; cbfun: TGLFWscrollfun): TGLFWscrollfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetScrollCallback';

{ Sets the file drop callback.

  This function sets the file drop callback of the specified window, which is
  called when one or more dragged files are dropped on the window.

  Because the path array and its strings may have been generated specifically
  for that event, they are not guaranteed to be valid after the callback has
  returned.  If you wish to use them after the callback returns, you need to
  make a deep copy.

  Parameters:
    window: The window whose callback to set.
    cbfun: The new file drop callback, or <tt>nil</tt> to remove the
      currently set callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.1. }
function glfwSetDropCallback(window: PGLFWwindow; cbfun: TGLFWdropfun): TGLFWdropfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetDropCallback';

{ Returns whether the specified joystick is present.

  This function returns whether the specified joystick is present.

  Parameters:
    joy: The joystick to query.

  Returns:
    <tt>GLFW_TRUE</tt> if the joystick is present, or <tt>GLFW_FALSE</tt>
    otherwise.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  This function must only be called from the main thread.

  Added in version 3.0.  Replaces <tt>glfwGetJoystickParam</tt>. }
function glfwJoystickPresent(joy: Integer): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwJoystickPresent';

{ Returns the values of all axes of the specified joystick.

  This function returns the values of all axes of the specified joystick.
  Each element in the array is a value between -1.0 and 1.0.

  Querying a joystick slot with no device present is not an error, but will
  cause this function to return <tt>nil</tt>.  Call glfwJoystickPresent to
  check device presence.

  Parameters:
    joy: The joystick to query.
    count: Where to store the number of axis values in the returned
      array.  This is set to zero if the joystick is not present or an error
      occurred.

  Returns:
    An array of axis values, or <tt>nil</tt> if the joystick is not present or
    an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  The returned array is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the specified joystick is disconnected, this
  function is called again for that joystick or the library is terminated.

  This function must only be called from the main thread.

  Added in version 3.0.  Replaces <tt>glfwGetJoystickPos</tt>. }
function glfwGetJoystickAxes(joy: Integer; out count: Integer): PSingle;
  cdecl external GLFW3_LIB name _PU + 'glfwGetJoystickAxes';

{ Returns the state of all buttons of the specified joystick.

  This function returns the state of all buttons of the specified joystick.
  Each element in the array is either <tt>GLFW_PRESS</tt> or <tt>GLFW_RELEASE</tt>.

  Querying a joystick slot with no device present is not an error, but will
  cause this function to return <tt>nil</tt>.  Call glfwJoystickPresent to
  check device presence.

  Parameters:
    joy: The joystick to query.
    count: Where to store the number of button states in the returned
      array.  This is set to zero if the joystick is not present or an error
      occurred.

  Returns:
    An array of button states, or <tt>nil</tt> if the joystick is not present
    or an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  The returned array is allocated and freed by GLFW.  You should not free it
  yourself.  It is valid until the specified joystick is disconnected, this
  function is called again for that joystick or the library is terminated.

  This function must only be called from the main thread.

  Added in version 2.2. GLFW3 changed to return a dynamic array. }
function glfwGetJoystickButtons(joy: Integer; out count: Integer): PByte;
  cdecl external GLFW3_LIB name _PU + 'glfwGetJoystickButtons';

{ Returns the name of the specified joystick.

  This function returns the name, encoded as UTF-8, of the specified joystick.
  The returned string is allocated and freed by GLFW.  You should not free it
  yourself.

  Querying a joystick slot with no device present is not an error, but will
  cause this function to return <tt>nil</tt>.  Call glfwJoystickPresent to
  check device presence.

  Parameters:
    joy: The joystick to query.

  Returns:
    The UTF-8 encoded name of the joystick, or <tt>nil</tt> if the joystick
    is not present or an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_INVALID_ENUM and
  GLFW_PLATFORM_ERROR.

  The returned string is allocated and freed by GLFW.  You should not free
  it yourself.  It is valid until the specified joystick is disconnected, this
  function is called again for that joystick or the library is terminated.

  This function must only be called from the main thread.

  Added in version 3.0. }
function glfwGetJoystickName(joy: Integer): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetJoystickName';

{ Sets the joystick configuration callback.

  This function sets the joystick configuration callback, or removes the
  currently set callback.  This is called when a joystick is connected to or
  disconnected from the system.

  Parameters:
    cbfun: The new callback, or <tt>nil</tt> to remove the currently set
      callback.

  Returns:
    The previously set callback, or <tt>nil</tt> if no callback was set or the
    library had not been initialized.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function must only be called from the main thread.

  Added in version 3.2. }
function glfwSetJoystickCallback(cbfun: TGLFWjoystickfun): TGLFWjoystickfun;
  cdecl external GLFW3_LIB name _PU + 'glfwSetJoystickCallback';

{ Sets the clipboard to the specified string.

  This function sets the system clipboard to the specified, UTF-8 encoded
  string.

  Parameters:
    window: The window that will own the clipboard contents.
    text: string A UTF-8 encoded string.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The specified string is copied before this function returns.

  This function must only be called from the main thread.

  SeeAlso:
    glfwGetClipboardString

  Added in version 3.0. }
procedure glfwSetClipboardString(window: PGLFWwindow; const text: PAnsiChar);
  cdecl external GLFW3_LIB name _PU + 'glfwSetClipboardString';

{ Returns the contents of the clipboard as a string.

  This function returns the contents of the system clipboard, if it contains
  or is convertible to a UTF-8 encoded string.  If the clipboard is empty or
  if its contents cannot be converted, <tt>nil</tt> is returned and a
  GLFW_FORMAT_UNAVAILABLE error is generated.

  Parameters:
    window: The window that will request the clipboard contents.

  Returns:
    The contents of the clipboard as a UTF-8 encoded string, or <tt>nil</tt>
    if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_PLATFORM_ERROR.

  The returned string is allocated and freed by GLFW.  You should not free
  it yourself.  It is valid until the next call to glfwGetClipboardString or
  glfwSetClipboardString, or until the library is terminated.

  This function must only be called from the main thread.

  SeeAlso:
    glfwSetClipboardString

  Added in version 3.0. }
function glfwGetClipboardString(window: PGLFWwindow): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetClipboardString';

{ Returns the value of the GLFW timer.

  This function returns the value of the GLFW timer.  Unless the timer has
  been set using glfwSetTime, the timer measures time elapsed since GLFW
  was initialized.

  The resolution of the timer is system dependent, but is usually on the order
  of a few micro- or nanoseconds.  It uses the highest-resolution monotonic
  time source on each supported platform.

  Returns: The current value, in seconds, or zero if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.  Reading and
  writing of the internal timer offset is not atomic, so it needs to be
  externally synchronized with calls to glfwSetTime.

  Added in version 1.0. }
function glfwGetTime(): Double;
  cdecl external GLFW3_LIB name _PU + 'glfwGetTime';

{ Sets the GLFW timer.

  This function sets the value of the GLFW timer.  It then continues to count
  up from that value.  The value must be a positive finite number less than
  or equal to 18446744073.0, which is approximately 584.5 years.

  Parameters:
    time: The new value, in seconds.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_INVALID_VALUE.

  This function may be called from any thread.  Reading and
  writing of the internal timer offset is not atomic, so it needs to be
  externally synchronized with calls to glfwGetTime.

  Added in version 2.2. }
procedure glfwSetTime(time: Double);
  cdecl external GLFW3_LIB name _PU + 'glfwSetTime';

{ Returns the current value of the raw timer.

  This function returns the current value of the raw timer, measured in
  1/frequency seconds.  To get the frequency, call glfwGetTimerFrequency.

  Returns: The value of the timer, or zero if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.

  SeeAlso:
    glfwGetTimerFrequency

  Added in version 3.2. }
function glfwGetTimerValue(): UInt64;
  cdecl external GLFW3_LIB name _PU + 'glfwGetTimerValue';

{ Returns the frequency, in Hz, of the raw timer.

  This function returns the frequency, in Hz, of the raw timer.

  Returns:
    The frequency of the timer, in Hz, or zero if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.

  SeeAlso:
    glfwGetTimerValue

  Added in version 3.2. }
function glfwGetTimerFrequency(): UInt64;
  cdecl external GLFW3_LIB name _PU + 'glfwGetTimerFrequency';

{ Makes the context of the specified window current for the calling thread.

  This function makes the OpenGL or OpenGL ES context of the specified window
  current on the calling thread.  A context can only be made current on
  a single thread at a time and each thread can have only a single current
  context at a time.

  By default, making a context non-current implicitly forces a pipeline flush.
  On machines that support <tt>GL_KHR_context_flush_control</tt>, you can control
  whether a context performs this flush by setting the
  GLFW_CONTEXT_RELEASE_BEHAVIOR window hint.

  The specified window must have an OpenGL or OpenGL ES context.  Specifying
  a window without a context will generate a GLFW_NO_WINDOW_CONTEXT error.

  Parameters:
    window: The window whose context to make current, or <tt>nil</tt> to
      detach the current context.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_NO_WINDOW_CONTEXT and
  GLFW_PLATFORM_ERROR.

  This function may be called from any thread.

  SeeAlso:
    glfwGetCurrentContext

  Added in version 3.0. }
procedure glfwMakeContextCurrent(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwMakeContextCurrent';

{ Returns the window whose context is current on the calling thread.

  This function returns the window whose OpenGL or OpenGL ES context is
  current on the calling thread.

  Returns: The window whose context is current, or <tt>nil</tt> if no window's
  context is current.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.

  SeeAlso:
    glfwMakeContextCurrent

  Added in version 3.0. }
function glfwGetCurrentContext(): PGLFWwindow;
  cdecl external GLFW3_LIB name _PU + 'glfwGetCurrentContext';

{ Swaps the front and back buffers of the specified window.

  This function swaps the front and back buffers of the specified window when
  rendering with OpenGL or OpenGL ES.  If the swap interval is greater than
  zero, the GPU driver waits the specified number of screen updates before
  swapping the buffers.

  The specified window must have an OpenGL or OpenGL ES context.  Specifying
  a window without a context will generate a GLFW_NO_WINDOW_CONTEXT error.

  This function does not apply to Vulkan.  If you are rendering with Vulkan,
  see <tt>vkQueuePresentKHR</tt> instead.

  Parameters:
    window: The window whose buffers to swap.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_NO_WINDOW_CONTEXT and
  GLFW_PLATFORM_ERROR.

  This function may be called from any thread.

  SeeAlso:
    glfwSwapInterval

  Added in version 1.0. GLFW3 added window handle parameter. }
procedure glfwSwapBuffers(window: PGLFWwindow);
  cdecl external GLFW3_LIB name _PU + 'glfwSwapBuffers';

{ Sets the swap interval for the current context.

  This function sets the swap interval for the current OpenGL or OpenGL ES
  context, i.e. the number of screen updates to wait from the time
  glfwSwapBuffers was called before swapping the buffers and returning.  This
  is sometimes called <i>vertical synchronization</i>, <i>vertical retrace
  synchronization</i> or just <i>vsync</i>.

  Contexts that support either of the <tt>WGL_EXT_swap_control_tear</tt> and
  <tt>GLX_EXT_swap_control_tear</tt> extensions also accept negative swap intervals,
  which allow the driver to swap even if a frame arrives a little bit late.
  You can check for the presence of these extensions using
  glfwExtensionSupported.  For more information about swap tearing, see the
  extension specifications.

  A context must be current on the calling thread.  Calling this function
  without a current context will cause a GLFW_NO_CURRENT_CONTEXT error.

  This function does not apply to Vulkan.  If you are rendering with Vulkan,
  see the present mode of your swapchain instead.

  Parameters:
    interval: The minimum number of screen updates to wait for until the
      buffers are swapped by glfwSwapBuffers.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_NO_CURRENT_CONTEXT and
  GLFW_PLATFORM_ERROR.

  This function is not called during context creation, leaving the
  swap interval set to whatever is the default on that platform.  This is done
  because some swap interval extensions used by GLFW do not allow the swap
  interval to be reset to zero once it has been set to a non-zero value.

  Some GPU drivers do not honor the requested swap interval, either
  because of a user setting that overrides the application's request or due to
  bugs in the driver.

  This function may be called from any thread.

  SeeAlso:
    glfwSwapBuffers

  Added in version 1.0. }
procedure glfwSwapInterval(interval: Integer);
  cdecl external GLFW3_LIB name _PU + 'glfwSwapInterval';

{ Returns whether the specified extension is available.

  This function returns whether the specified API extension is supported by
  the current OpenGL or OpenGL ES context.  It searches both for client API
  extension and context creation API extensions.

  A context must be current on the calling thread.  Calling this function
  without a current context will cause a GLFW_NO_CURRENT_CONTEXT error.

  As this functions retrieves and searches one or more extension strings each
  call, it is recommended that you cache its results if it is going to be used
  frequently.  The extension strings will not change during the lifetime of
  a context, so there is no danger in doing this.

  This function does not apply to Vulkan.  If you are using Vulkan, see
  glfwGetRequiredInstanceExtensions, <tt>vkEnumerateInstanceExtensionProperties</tt>
  and <tt>vkEnumerateDeviceExtensionProperties</tt> instead.

  Parameters:
    extension: The ASCII encoded name of the extension.

  Returns:
    <tt>GLFW_TRUE</tt> if the extension is available, or <tt>GLFW_FALSE</tt>
    otherwise.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_NO_CURRENT_CONTEXT,
  GLFW_INVALID_VALUE and GLFW_PLATFORM_ERROR.

  This function may be called from any thread.

  SeeAlso:
    glfwGetProcAddress

  Added in version 1.0. }
function glfwExtensionSupported(const extension: PAnsiChar): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwExtensionSupported';

{ Returns the address of the specified function for the current context.

  This function returns the address of the specified OpenGL or OpenGL ES
  core or extension function, if it is supported by the current context.

  A context must be current on the calling thread.  Calling this function
  without a current context will cause a GLFW_NO_CURRENT_CONTEXT error.

  This function does not apply to Vulkan.  If you are rendering with Vulkan,
  see glfwGetInstanceProcAddress, <tt>vkGetInstanceProcAddr</tt> and
  <tt>vkGetDeviceProcAddr</tt> instead.

  Parameters:
    procname: The ASCII encoded name of the function.

  Returns:
    The address of the function, or <tt>nil</tt> if an error occurred.

  Possible errors include GLFW_NOT_INITIALIZED, GLFW_NO_CURRENT_CONTEXT and
  GLFW_PLATFORM_ERROR.

  The address of a given function is not guaranteed to be the same
  between contexts.

  This function may return a non-<tt>nil</tt> address despite the
  associated version or extension not being available.  Always check the
  context version or extension string first.

  The returned function pointer is valid until the context
  is destroyed or the library is terminated.

  This function may be called from any thread.

  SeeAlso:
    glfwExtensionSupported

  Added in version 1.0. }
function glfwGetProcAddress(const procname: PAnsiChar): TGLFWglproc;
  cdecl external GLFW3_LIB name _PU + 'glfwGetProcAddress';

{ Returns whether the Vulkan loader has been found.

  This function returns whether the Vulkan loader has been found.  This check
  is performed by glfwInit.

  The availability of a Vulkan loader does not by itself guarantee that window
  surface creation or even device creation is possible.  Call
  glfwGetRequiredInstanceExtensions to check whether the extensions necessary
  for Vulkan surface creation are available and
  glfwGetPhysicalDevicePresentationSupport to check whether a queue family of
  a physical device supports image presentation.

  Returns:
    <tt>GLFW_TRUE</tt> if Vulkan is available, or <tt>GLFW_FALSE</tt> otherwise.

  Possible errors include GLFW_NOT_INITIALIZED.

  This function may be called from any thread.

  Added in version 3.2. }
function glfwVulkanSupported(): Integer;
  cdecl external GLFW3_LIB name _PU + 'glfwVulkanSupported';

{ Returns the Vulkan instance extensions required by GLFW.

  This function returns an array of names of Vulkan instance extensions required
  by GLFW for creating Vulkan surfaces for GLFW windows.  If successful, the
  list will always contains <tt>VK_KHR_surface</tt>, so if you don't require any
  additional extensions you can pass this list directly to the
  <tt>VkInstanceCreateInfo</tt> struct.

  If Vulkan is not available on the machine, this function returns <tt>nil</tt>
  and generates a GLFW_API_UNAVAILABLE error.  Call glfwVulkanSupported
  to check whether Vulkan is available.

  If Vulkan is available but no set of extensions allowing window surface
  creation was found, this function returns <tt>nil</tt>.  You may still use Vulkan
  for off-screen rendering and compute work.

  Parameters:
    count: Where to store the number of extensions in the returned
      array.  This is set to zero if an error occurred.

  Returns:
    An array of ASCII encoded extension names, or <tt>nil</tt> if an
    error occurred.

  Possible errors include GLFW_NOT_INITIALIZED and GLFW_API_UNAVAILABLE.

  Additional extensions may be required by future versions of GLFW.
  You should check if any extensions you wish to enable are already in the
  returned array, as it is an error to specify an extension more than once in
  the <tt>VkInstanceCreateInfo</tt> struct.

  The returned array is allocated and freed by GLFW.  You should not free
  it yourself.  It is guaranteed to be valid only until the library is
  terminated.

  This function may be called from any thread.

  Added in version 3.2. }
function glfwGetRequiredInstanceExtensions(out count: UInt32): PPAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetRequiredInstanceExtensions';
{$ENDREGION 'glfw3.h'}

{$REGION 'glfw3native.h'}
{************************************************************************
 Functions
***********************************************************************}

{$IF Defined(MSWINDOWS)}
{ Returns the adapter device name of the specified monitor.

  Returns: The UTF-8 encoded adapter device name (for example <tt>\\.\DISPLAY1</tt>)
  of the specified monitor, or <tt>nil</tt> if an error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.1. }
function glfwGetWin32Adapter(monitor: PGLFWmonitor): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWin32Adapter';

{ Returns the display device name of the specified monitor.

  Returns: The UTF-8 encoded display device name (for example
  <tt>\\.\DISPLAY1\Monitor0</tt>) of the specified monitor, or <tt>nil</tt> if an
  error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.1. }
function glfwGetWin32Monitor(monitor: PGLFWmonitor): PAnsiChar;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWin32Monitor';

{ Returns the <tt>HWND</tt> of the specified window.

  Returns: The <tt>HWND</tt> of the specified window, or <tt>nil</tt> if an
  error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.0. }
function glfwGetWin32Window(window: PGLFWwindow): HWND;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWin32Window';

{ Returns the <tt>HGLRC</tt> of the specified window.

  Returns: The <tt>HGLRC</tt> of the specified window, or <tt>nil</tt> if an
  error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.0. }
function glfwGetWGLContext(window: PGLFWwindow): HGLRC;
  cdecl external GLFW3_LIB name _PU + 'glfwGetWGLContext';
{$ENDIF}

{$IF Defined(MACOS)}
{ Returns the <tt>CGDirectDisplayID</tt> of the specified monitor.

  Returns: The <tt>CGDirectDisplayID</tt> of the specified monitor, or
  <tt>kCGNullDirectDisplay</tt> if an error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.1. }
function glfwGetCocoaMonitor(monitor: PGLFWmonitor): CGDirectDisplayID;
  cdecl external GLFW3_LIB name _PU + 'glfwGetCocoaMonitor';

{ Returns the <tt>NSWindow</tt> of the specified window.

  Returns: The <tt>NSWindow</tt> of the specified window, or <tt>nil</tt> if an
  error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.0. }
function glfwGetCocoaWindow(window: PGLFWwindow): Id;
  cdecl external GLFW3_LIB name _PU + 'glfwGetCocoaWindow';

{ Returns the <tt>NSOpenGLContext</tt> of the specified window.

  Returns: The <tt>NSOpenGLContext</tt> of the specified window,
  or <tt>nil</tt> if an error occurred.

  This function may be called from any thread.  Access is not
  synchronized.

  Added in version 3.0. }
function glfwGetNSGLContext(window: PGLFWwindow): Id;
  cdecl external GLFW3_LIB name _PU + 'glfwGetNSGLContext';
{$ENDIF}
{$ENDREGION 'glfw3native.h'}

implementation

end.
