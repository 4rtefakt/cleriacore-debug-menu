LP = "[lua:4rtefakt.debug] "
CASES = {
    # The player: level 30 (the game's own curve), SP set, the weapon tier, a full heal after a hit.
    "player": dict(room="S_10/S_1002/S_1002",
        drive="20:lua=dbg;30:lua=dbg level 30;40:lua=dbg sp 5000;50:lua=dbg weapon 4;60:hurt=60;70:lua=dbg;80:lua=dbg heal;90:quit",
        expect=[LP + "lv 1 hp 60/60 atk 46 def 38 sp 0 weapon 0 skills 0 0 0", LP + "lv 30 hp 60/227 atk 139 def 126 sp 0 weapon 0",
                " sp 5000 weapon 0", "atk 168 def 126 sp 5000 weapon 4", LP + "lv 30 hp 59/227 ", LP + "lv 30 hp 227/227 "]),
    # Items: the Bronze Key given and taken; an armor given and strengthened (DEF follows); the skills: wind at
    # level 2, then removed; a blessing bit set and cleared; every statue unlocked.
    "things": dict(room="S_10/S_1002/S_1002",
        drive="20:lua=dbg give 99;30:lua=dbg take 99;40:lua=dbg give 7;50:lua=dbg up 7 1;60:lua=dbg skill 1 2;70:lua=dbg skill 1 0;"
              "80:lua=dbg bless 13 1;90:lua=dbg bless 13 0;100:lua=dbg warps 1;110:lua=dbg flag 300 7;120:quit",
        expect=[LP + "item 99 Bronze Key = 1 ", LP + "item 99 Bronze Key = 0 ", LP + "item 7 Ring Mail = 1 upgraded false",
                LP + "item 7 Ring Mail = 1 upgraded true", " skills 2 0 0 ", " skills 0 0 0 ", " bless 0x2000", " bless 0x0",
                LP + "warp 5 unlocked true"]),
}
