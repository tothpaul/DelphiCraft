unit Craft.Item;

interface

const
  EMPTY =0;
  GRASS =1;
  SAND =2;
  STONE =3;
  BRICK =4;
  WOOD =5;
  CEMENT =6;
  DIRT =7;
  PLANK =8;
  SNOW =9;
  GLASS =10;
  COBBLE =11;
  LIGHT_STONE =12;
  DARK_STONE =13;
  CHEST =14;
  LEAVES =15;
  CLOUD =16;
  TALL_GRASS =17;
  YELLOW_FLOWER =18;
  RED_FLOWER =19;
  PURPLE_FLOWER =20;
  SUN_FLOWER =21;
  WHITE_FLOWER =22;
  BLUE_FLOWER =23;
  COLOR_00 =32;
  COLOR_01 =33;
  COLOR_02 =34;
  COLOR_03 =35;
  COLOR_04 =36;
  COLOR_05 =37;
  COLOR_06 =38;
  COLOR_07 =39;
  COLOR_08 =40;
  COLOR_09 =41;
  COLOR_10 =42;
  COLOR_11 =43;
  COLOR_12 =44;
  COLOR_13 =45;
  COLOR_14 =46;
  COLOR_15 =47;
  COLOR_16 =48;
  COLOR_17 =49;
  COLOR_18 =50;
  COLOR_19 =51;
  COLOR_20 =52;
  COLOR_21 =53;
  COLOR_22 =54;
  COLOR_23 =55;
  COLOR_24 =56;
  COLOR_25 =57;
  COLOR_26 =58;
  COLOR_27 =59;
  COLOR_28 =60;
  COLOR_29 =61;
  COLOR_30 =62;
  COLOR_31 =63;


const
  items: array[0..53] of Integer = (
    // items the user can build
    GRASS,
    SAND,
    STONE,
    BRICK,
    WOOD,
    CEMENT,
    DIRT,
    PLANK,
    SNOW,
    GLASS,
    COBBLE,
    LIGHT_STONE,
    DARK_STONE,
    CHEST,
    LEAVES,
    TALL_GRASS,
    YELLOW_FLOWER,
    RED_FLOWER,
    PURPLE_FLOWER,
    SUN_FLOWER,
    WHITE_FLOWER,
    BLUE_FLOWER,
    COLOR_00,
    COLOR_01,
    COLOR_02,
    COLOR_03,
    COLOR_04,
    COLOR_05,
    COLOR_06,
    COLOR_07,
    COLOR_08,
    COLOR_09,
    COLOR_10,
    COLOR_11,
    COLOR_12,
    COLOR_13,
    COLOR_14,
    COLOR_15,
    COLOR_16,
    COLOR_17,
    COLOR_18,
    COLOR_19,
    COLOR_20,
    COLOR_21,
    COLOR_22,
    COLOR_23,
    COLOR_24,
    COLOR_25,
    COLOR_26,
    COLOR_27,
    COLOR_28,
    COLOR_29,
    COLOR_30,
    COLOR_31
  );
  item_count = Length(items);

  blocks: array[0..63, 0..5] of Integer = (
   // w => (left, right, top, bottom, front, back) tiles
    (0, 0, 0, 0, 0, 0), // 0 - empty
    (16, 16, 32, 0, 16, 16), // 1 - grass
    (1, 1, 1, 1, 1, 1), // 2 - sand
    (2, 2, 2, 2, 2, 2), // 3 - stone
    (3, 3, 3, 3, 3, 3), // 4 - brick
    (20, 20, 36, 4, 20, 20), // 5 - wood
    (5, 5, 5, 5, 5, 5), // 6 - cement
    (6, 6, 6, 6, 6, 6), // 7 - dirt
    (7, 7, 7, 7, 7, 7), // 8 - plank
    (24, 24, 40, 8, 24, 24), // 9 - snow
    (9, 9, 9, 9, 9, 9), // 10 - glass
    (10, 10, 10, 10, 10, 10), // 11 - cobble
    (11, 11, 11, 11, 11, 11), // 12 - light stone
    (12, 12, 12, 12, 12, 12), // 13 - dark stone
    (13, 13, 13, 13, 13, 13), // 14 - chest
    (14, 14, 14, 14, 14, 14), // 15 - leaves
    (15, 15, 15, 15, 15, 15), // 16 - cloud
    (0, 0, 0, 0, 0, 0), // 17
    (0, 0, 0, 0, 0, 0), // 18
    (0, 0, 0, 0, 0, 0), // 19
    (0, 0, 0, 0, 0, 0), // 20
    (0, 0, 0, 0, 0, 0), // 21
    (0, 0, 0, 0, 0, 0), // 22
    (0, 0, 0, 0, 0, 0), // 23
    (0, 0, 0, 0, 0, 0), // 24
    (0, 0, 0, 0, 0, 0), // 25
    (0, 0, 0, 0, 0, 0), // 26
    (0, 0, 0, 0, 0, 0), // 27
    (0, 0, 0, 0, 0, 0), // 28
    (0, 0, 0, 0, 0, 0), // 29
    (0, 0, 0, 0, 0, 0), // 30
    (0, 0, 0, 0, 0, 0), // 31
    (176, 176, 176, 176, 176, 176), // 32
    (177, 177, 177, 177, 177, 177), // 33
    (178, 178, 178, 178, 178, 178), // 34
    (179, 179, 179, 179, 179, 179), // 35
    (180, 180, 180, 180, 180, 180), // 36
    (181, 181, 181, 181, 181, 181), // 37
    (182, 182, 182, 182, 182, 182), // 38
    (183, 183, 183, 183, 183, 183), // 39
    (184, 184, 184, 184, 184, 184), // 40
    (185, 185, 185, 185, 185, 185), // 41
    (186, 186, 186, 186, 186, 186), // 42
    (187, 187, 187, 187, 187, 187), // 43
    (188, 188, 188, 188, 188, 188), // 44
    (189, 189, 189, 189, 189, 189), // 45
    (190, 190, 190, 190, 190, 190), // 46
    (191, 191, 191, 191, 191, 191), // 47
    (192, 192, 192, 192, 192, 192), // 48
    (193, 193, 193, 193, 193, 193), // 49
    (194, 194, 194, 194, 194, 194), // 50
    (195, 195, 195, 195, 195, 195), // 51
    (196, 196, 196, 196, 196, 196), // 52
    (197, 197, 197, 197, 197, 197), // 53
    (198, 198, 198, 198, 198, 198), // 54
    (199, 199, 199, 199, 199, 199), // 55
    (200, 200, 200, 200, 200, 200), // 56
    (201, 201, 201, 201, 201, 201), // 57
    (202, 202, 202, 202, 202, 202), // 58
    (203, 203, 203, 203, 203, 203), // 59
    (204, 204, 204, 204, 204, 204), // 60
    (205, 205, 205, 205, 205, 205), // 61
    (206, 206, 206, 206, 206, 206), // 62
    (207, 207, 207, 207, 207, 207)  // 63
  );

var
  plants: array[17..23] of Integer = (
    48, // 17 - tall grass
    49, // 18 - yellow flower
    50, // 19 - red flower
    51, // 20 - purple flower
    52, // 21 - sun flower
    53, // 22 - white flower
    54  // 23 - blue flower
  );


function is_plant(w: Integer): Boolean;
function is_obstacle(w: Integer): Boolean;
function is_transparent(w: Integer): Boolean;
function is_destructable(w: Integer): Boolean;

implementation

function is_plant(w: Integer): Boolean;
begin
    case (w) of
        TALL_GRASS,
        YELLOW_FLOWER,
        RED_FLOWER,
        PURPLE_FLOWER,
        SUN_FLOWER,
        WHITE_FLOWER,
        BLUE_FLOWER:
            Result := True;
        else
            Result := False;
    end;
end;

function is_obstacle(w: Integer): Boolean;
begin
    w := ABS(w);
    if (is_plant(w)) then begin
        Exit(False);
    end;
    case (w) of
        EMPTY,
        CLOUD:
            Exit(False);
        else
            Exit(True);
    end;
end;

function is_transparent(w: Integer): Boolean;
begin
    if (w = EMPTY) then begin
        Exit(True);
    end;
    w := ABS(w);
    if (is_plant(w)) then begin
        Exit(True);
    end;
    case (w) of
        EMPTY,
        GLASS,
        LEAVES:
            Result := True;
    else
        Result := False;
    end;
end;

function is_destructable(w: Integer): Boolean;
begin
    case (w) of
        EMPTY,
        CLOUD:
            Exit(False);
        else
            Exit(True);
    end;
end;

end.
