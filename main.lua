-- Debug Menu: one page (F1 > Mods > Debug Menu) that reads and writes the game's state.
-- Every row calls one of the small functions below; the "dbg" command calls the same ones for the tests.

local P, G = cleria.player, cleria.game

-- ---- what the rows do ------------------------------------------------------------------------------------------
local D = {}

function D.level(n) P.set_level(math.max(1, math.min(60, n))) P.refresh() end
function D.sp(n) P.add_sp(n - P.sp()) end                              -- the wallet is set through add_sp
function D.heal() P.set_hp(P.max_hp()) end
function D.weapon(t) P.set_weapon_tier(math.max(0, math.min(8, t))) P.refresh() end

function D.has(id) return (G.flag(id) or 0) >= 1 end
function D.give(id) cleria.content.give(id, 1, "debug") P.refresh() end
function D.take(id) G.set_flag(id, math.max(0, (G.flag(id) or 0) - 1)) P.refresh() end

-- armor and leggings: an item cell (owned) and an upgrade cell (strengthened)
function D.upgraded(id) return id >= 0 and id <= 53 and (G.upgrade(id) or 0) >= 1 end
function D.upgrade(id, on) G.set_upgrade(id, on and 1 or 0) P.refresh() end

-- a skill is three things: its artifact, the power it grants, and a level cell (0 = level 1 ... 2 = level 3)
local SKILLS = {{"Wind", 0x6B, 0x74, 0xB6}, {"Thunder", 0x6C, 0x75, 0xB7}, {"Fire", 0x6D, 0x76, 0xB8}}
function D.skill(k)                                                    -- 0 = not owned, 1..3 = its level
    local s = SKILLS[k]
    return D.has(s[2]) and (math.max(0, G.flag(s[4]) or 0) + 1) or 0
end
function D.set_skill(k, level)
    local s = SKILLS[k]
    if level <= 0 then
        G.set_flag(s[2], 0) G.set_flag(s[3], 0) G.set_flag(s[4], 0)
    else
        G.set_flag(s[2], 1) G.set_flag(s[3], 1) G.set_flag(s[4], math.min(3, level) - 1)
    end
    P.refresh()
end

-- blessings are bits of flag 217
local BLESSINGS = {
    {0, "Increase stationary heal rate"}, {1, "Reduce damage from terrain"}, {3, "Increase item drop rate"},
    {8, "Increase SP gain"}, {13, "Increase movement speed"}, {7, "Increase stun effect"},
    {2, "Reduce bad status duration LV1"}, {20, "Reduce bad status duration LV2"},
    {9, "Bolster bad status resists LV1"}, {22, "Bolster bad status resists LV2"},
    {4, "Extend drop item effects LV1"}, {23, "Extend drop item effects LV2"},
    {12, "Increase effect of herbs LV1"}, {17, "Increase effect of herbs LV2"},
    {5, "Increase Boost recovery LV1"}, {15, "Increase Boost recovery LV2"}, {16, "Increase Boost recovery LV3"},
    {6, "Reduce MP usage LV1"}, {18, "Reduce MP usage LV2"}, {19, "Reduce MP usage LV3"},
    {10, "Hasten Skill recovery LV1"}, {11, "Hasten Skill recovery LV2"}, {14, "Hasten Skill recovery LV3"},
    {21, "Strengthen Eyes of Fact"},
}
function D.blessed(bit) return ((G.flag(217) or 0) >> bit) & 1 == 1 end
function D.bless(bit, on)
    local v = G.flag(217) or 0
    G.set_flag(217, on and (v | (1 << bit)) or (v & ~(1 << bit)))
    P.refresh()
end

function D.warps(on) for i = 0, 23 do G.set_warp_unlocked(i, on) end end

-- the character's own armor and leggings (six each)
local GEAR = {{6, 30}, {12, 36}, {18, 42}}                              -- Yunica, Hugo, Toal: first armor, first leggings
local ITEMS = {}                                                       -- accessories, key items, tools
for id = 54, 63 do ITEMS[#ITEMS + 1] = id end
for id = 78, 112 do if id ~= 94 and id ~= 105 and id ~= 107 and id ~= 108 and id ~= 109 then ITEMS[#ITEMS + 1] = id end end

-- ---- the page --------------------------------------------------------------------------------------------------
local flag_i, flag_v, warp_i = "0", "0", 1

cleria.ui.page("Debug Menu", function(p)
    if not G.in_game() then
        p:section("Debug Menu")
        p:info("No game running", "", "Start or load a game first.")
        return
    end
    local st = P.stats()
    p:section("Player")
    local v, ch = p:slider("Level", st.level, 1, 60, 1, "%.0f", "Sets the level; EXP is put at that level's threshold.")
    if ch then D.level(math.floor(v + 0.5)) end
    v, ch = p:slider("Weapon", st.weapon_tier, 0, 8, 1, "%.0f", "The weapon's upgrade tier (the Cleria Ore upgrades).")
    if ch then D.weapon(math.floor(v + 0.5)) end
    p:info("HP", string.format("%.0f / %.0f", st.hp, st.max_hp), string.format("ATK %g, DEF %g.", st.atk, st.def))
    if p:button("Full HP") then D.heal() end
    p:info("SP", tostring(st.sp))
    if p:button("+ 1 000 SP") then D.sp(st.sp + 1000) end
    if p:button("+ 100 000 SP") then D.sp(st.sp + 100000) end
    if p:button("No SP") then D.sp(0) end

    p:section("Skills")
    for k, s in ipairs(SKILLS) do
        v, ch = p:choice(s[1], D.skill(k) + 1, {"Not owned", "Level 1", "Level 2", "Level 3"}, "The artifact, its power and its level.")
        if ch then D.set_skill(k, v - 1) end
    end

    p:section("Armor and leggings")
    local g = GEAR[G.character()] or GEAR[2]
    for _, base in ipairs(g) do
        for id = base, base + 5 do
            v, ch = p:toggle(G.item_name(id), D.has(id), "Owned or not.")
            if ch then if v then D.give(id) else G.set_flag(id, 0) P.refresh() end end
            if D.has(id) then
                v, ch = p:toggle("   strengthened", D.upgraded(id), "The statue's upgrade of this piece.")
                if ch then D.upgrade(id, v) end
            end
        end
    end

    p:section("Items")
    for _, id in ipairs(ITEMS) do
        local n = math.max(0, G.flag(id) or 0)
        v, ch = p:toggle(G.item_name(id) .. (n > 1 and ("  x" .. n) or ""), n >= 1, "On gives one, off takes one.")
        if ch then if v then D.give(id) else D.take(id) end end
    end

    p:section("Blessings")
    for _, b in ipairs(BLESSINGS) do
        v, ch = p:toggle(b[2], D.blessed(b[1]))
        if ch then D.bless(b[1], v) end
    end

    p:section("Statue warps")
    if p:button("Unlock every statue") then D.warps(true) end
    if p:button("Lock every statue") then D.warps(false) end
    local names = {}
    for i = 0, 23 do names[#names + 1] = "Statue " .. (i + 1) .. (G.warp_unlocked(i) and "" or " (locked)") end
    v, ch = p:choice("Warp to", warp_i, names, "The statues in the game's own order.")
    if ch then warp_i = v end
    if p:button("Warp", "Leaves this page's room at once.") then G.warp_to(warp_i - 1) end

    p:section("Game flags")
    v, ch = p:text_field("Flag", flag_i, {desc = "0 to 511. Story progress, doors, chests and items are all flags."})
    if ch then flag_i = v end
    local i = math.tointeger(tonumber(flag_i))
    p:info("Value now", i and i >= 0 and i <= 511 and tostring(G.flag(i)) or "-")
    v, ch = p:text_field("New value", flag_v, {})
    if ch then flag_v = v end
    if p:button("Set the flag", "Nothing checks that it makes sense for the story.") then
        local n = math.tointeger(tonumber(flag_v))
        if i and n and i >= 0 and i <= 511 then G.set_flag(i, n) P.refresh() end
    end
end)

cleria.speedrun.modification("Debug Menu")

-- ---- the same functions as a command, for the tests: "dbg <what> <a> <b>" --------------------------------------
cleria.command("dbg", function(a)
    local what, x, y = a:match("^(%S*)%s*(%S*)%s*(%S*)")
    local nx, ny = tonumber(x), tonumber(y)
    if what == "level" then D.level(nx)
    elseif what == "sp" then D.sp(nx)
    elseif what == "heal" then D.heal()
    elseif what == "weapon" then D.weapon(nx)
    elseif what == "give" then D.give(nx)
    elseif what == "take" then D.take(nx)
    elseif what == "up" then D.upgrade(nx, ny == 1)
    elseif what == "skill" then D.set_skill(nx, ny)
    elseif what == "bless" then D.bless(nx, ny == 1)
    elseif what == "warps" then D.warps(nx == 1)
    elseif what == "flag" then G.set_flag(nx, ny) end
    local st = P.stats()
    cleria.log(string.format("lv %d hp %.0f/%.0f atk %g def %g sp %d weapon %d skills %d %d %d bless 0x%X", st.level, st.hp, st.max_hp,
                             st.atk, st.def, st.sp, st.weapon_tier, D.skill(1), D.skill(2), D.skill(3), G.flag(217) or 0))
    if what == "give" or what == "take" or what == "up" then
        cleria.log(string.format("item %d %s = %s upgraded %s", nx, G.item_name(nx), tostring(G.flag(nx)), tostring(D.upgraded(nx))))
    end
    if what == "warps" then cleria.log("warp 5 unlocked " .. tostring(G.warp_unlocked(5))) end
end)
cleria.log("Debug Menu loaded")
