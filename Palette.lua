local _, ns = ...

--------------------------------------------------------------------------------
-- Algorithmic per-node colour seeding.
--
-- Two passes over GatherMate2's data, both writing into db.profile.nodeColors
-- with copyDefaults-style semantics (nil entries only, never overwrite):
--
-- 1. Per-expansion pass for Mining + Herb Gathering. GM2's nodeExpansion
--    table maps {nodeType, nodeID -> expansion constant} (see GatherMate2's
--    Constants.lua). Each expansion has its own themed hue family; nodes
--    within an expansion are spread across that family so no two nodes from
--    the same expansion share a colour. Hand-picked Midnight defaults in
--    Defaults.lua take precedence (their entries are non-nil after AceDB
--    merge, so this pass skips them).
--
-- 2. Per-category fallback for Fishing, Logging, Treasure, Extract Gas, and
--    Archaeology. nodeExpansion doesn't cover those categories, so we spread
--    a category-themed palette across the full canonical-id list.
--------------------------------------------------------------------------------

-- Theme = hue centre (degrees, 0-360), hue range (degrees), lightness centre.
-- Hue ranges are widened where the bucket is large (Classic, SL) so individual
-- colours stay visually separable even at tight hue spacing.

local EXPANSION_THEMES = {
    [1]  = { hue =  25, range = 120, l = 0.50 }, -- Classic: warm earth
    [2]  = { hue =  95, range =  60, l = 0.50 }, -- BC: fel green
    [3]  = { hue = 210, range =  60, l = 0.55 }, -- Wrath: icy blue
    [4]  = { hue =  10, range =  60, l = 0.50 }, -- Cataclysm: lava red
    [5]  = { hue = 145, range =  60, l = 0.50 }, -- MoP: jade
    [6]  = { hue =  25, range =  50, l = 0.45 }, -- WoD: savage sepia
    [7]  = { hue = 115, range =  60, l = 0.45 }, -- Legion: sickly emerald
    [8]  = { hue = 195, range =  70, l = 0.50 }, -- BfA: ocean troll
    [9]  = { hue = 280, range =  90, l = 0.60 }, -- Shadowlands: ethereal purple
    [10] = { hue =  30, range =  80, l = 0.50 }, -- Dragonflight: ember
    [11] = { hue =  45, range =  50, l = 0.50 }, -- TWW: gold cavern
    [12] = { hue = 240, range =  70, l = 0.55 }, -- Midnight: silver-cobalt
}

local CATEGORY_THEMES = {
    ["Fishing"]     = { hue = 200, range = 100, l = 0.55 }, -- ocean
    ["Treasure"]    = { hue =  50, range =  60, l = 0.55 }, -- gold
    ["Logging"]     = { hue =  30, range =  50, l = 0.45 }, -- wood
    ["Extract Gas"] = { hue = 100, range = 100, l = 0.60 }, -- noxious
    ["Archaeology"] = { hue =  35, range =  40, l = 0.50 }, -- amber
}

local function hslToRgb(h, s, l)
    h = (h % 360) / 360
    local c = (1 - math.abs(2*l - 1)) * s
    local x = c * (1 - math.abs((h*6) % 2 - 1))
    local m = l - c/2
    local r, g, b
    if h < 1/6 then     r, g, b = c, x, 0
    elseif h < 2/6 then r, g, b = x, c, 0
    elseif h < 3/6 then r, g, b = 0, c, x
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else                r, g, b = c, 0, x
    end
    return r + m, g + m, b + m
end

-- Generate `n` colours along a hue ramp within the theme's range, with
-- sinusoidal modulation of saturation and lightness so adjacent indices have
-- enough perceptual distance even when hue spacing is tight.
local function generatePalette(theme, n)
    local out = {}
    if not n or n <= 0 then return out end
    for i = 0, n - 1 do
        local phase = (n == 1) and 0 or (i / (n - 1))
        local h = theme.hue - theme.range/2 + theme.range * phase
        local l = theme.l + 0.18 * math.sin(6 * math.pi * phase)
        local s = 0.70 + 0.15 * math.sin(4 * math.pi * phase)
        if l < 0.20 then l = 0.20 elseif l > 0.80 then l = 0.80 end
        if s < 0.50 then s = 0.50 elseif s > 0.90 then s = 0.90 end
        local r, g, b = hslToRgb(h, s, l)
        out[#out + 1] = { r = r, g = g, b = b, a = 1 }
    end
    return out
end

local function resolveID(gm2, id)
    local m = gm2 and gm2.nodeIDReplacementMap
    return (m and m[id]) or id
end

local function ensureMap(profile, nodeType)
    local m = profile.nodeColors[nodeType]
    if not m then
        m = {}
        profile.nodeColors[nodeType] = m
    end
    return m
end

function ns.SeedNodeColors()
    local addon = ns.addon
    if not addon or not addon.db then return end
    local gm2 = ns.GatherMate
    if not gm2 then return end

    local profile = addon.db.profile
    profile.nodeColors = profile.nodeColors or {}

    -- Pass 1: per-expansion seeding for Mining + Herb Gathering.
    if gm2.nodeExpansion then
        for expConst, theme in pairs(EXPANSION_THEMES) do
            local entries = {}
            local seen    = {}
            for nodeType, idMap in pairs(gm2.nodeExpansion) do
                for id, exp in pairs(idMap) do
                    if exp == expConst then
                        local resolved = resolveID(gm2, id)
                        local key = nodeType .. ":" .. resolved
                        if not seen[key] then
                            seen[key] = true
                            entries[#entries + 1] = { type = nodeType, id = resolved }
                        end
                    end
                end
            end
            -- Deterministic order: nodeType ascending (so "Herb Gathering" sits
            -- before "Mining"), then id ascending within each type.
            table.sort(entries, function(a, b)
                if a.type ~= b.type then return a.type < b.type end
                return a.id < b.id
            end)
            local palette = generatePalette(theme, #entries)
            for i, e in ipairs(entries) do
                local map = ensureMap(profile, e.type)
                if map[e.id] == nil then
                    map[e.id] = palette[i]
                end
            end
        end
    end

    -- Pass 2: per-category seeding for categories without expansion data.
    -- Use reverseNodeIDs (canonical id -> name) so variants and old_ids don't
    -- inflate the palette size.
    for cat, theme in pairs(CATEGORY_THEMES) do
        local revMap = gm2.reverseNodeIDs and gm2.reverseNodeIDs[cat]
        if revMap then
            local seen, ids = {}, {}
            for rawID in pairs(revMap) do
                local id = resolveID(gm2, rawID)
                if not seen[id] then
                    seen[id] = true
                    ids[#ids + 1] = id
                end
            end
            table.sort(ids)
            local palette = generatePalette(theme, #ids)
            local map = ensureMap(profile, cat)
            for i, id in ipairs(ids) do
                if map[id] == nil then
                    map[id] = palette[i]
                end
            end
        end
    end
end
