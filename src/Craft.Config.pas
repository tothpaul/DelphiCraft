unit Craft.Config;

interface

uses
  Neslib.glfw3;

const
// app parameters
  FULLSCREEN = 0;
  WINDOW_WIDTH = 1024;
  WINDOW_HEIGHT = 768;
  VSYNC = 1;
  SCROLL_THRESHOLD = 0.1;
  MAX_MESSAGES = 4;
  DB_PATH = 'craft.db';
  USE_CACHE = True;
  DAY_LENGTH = 600;
  INVERT_MOUSE = False;

// rendering options
  SHOW_LIGHTS = 1;
  SHOW_PLANTS = 1;
  SHOW_CLOUDS = 1;
  SHOW_TREES = 1;
  SHOW_CROSSHAIRS = True;
  SHOW_WIREFRAME = True;
  SHOW_ITEM = True;
  SHOW_INFO_TEXT = True;
  SHOW_CHAT_TEXT = True;
  SHOW_PLAYER_NAMES = True;

// advanced parameters
  CREATE_CHUNK_RADIUS = 10;
  RENDER_CHUNK_RADIUS = 10;
  RENDER_SIGN_RADIUS = 4;
  DELETE_CHUNK_RADIUS = 14;
  CHUNK_SIZE = 32;
  COMMIT_INTERVAL = 5;

// key bindings
  CRAFT_KEY_FORWARD = Ord('W');
  CRAFT_KEY_BACKWARD = Ord('S');
  CRAFT_KEY_LEFT = Ord('A');
  CRAFT_KEY_RIGHT = Ord('D');
  CRAFT_KEY_JUMP = GLFW_KEY_SPACE;
  CRAFT_KEY_FLY = GLFW_KEY_TAB;
  CRAFT_KEY_OBSERVE = 'O';
  CRAFT_KEY_OBSERVE_INSET = 'P';
  CRAFT_KEY_ITEM_NEXT = 'E';
  CRAFT_KEY_ITEM_PREV = 'R';
  CRAFT_KEY_ZOOM = GLFW_KEY_LEFT_SHIFT;
  CRAFT_KEY_ORTHO = Ord('F');
  CRAFT_KEY_CHAT = 't';
  CRAFT_KEY_COMMAND = '/';
  CRAFT_KEY_SIGN = '`';

implementation


end.
