local _, ns = ...

ns.CATEGORIES = {
    "Mining",
    "Herb Gathering",
    "Fishing",
    "Logging",
    "Extract Gas",
    "Treasure",
    "Archaeology",
}

ns.DEFAULTS = {
    profile = {
        enabled = true,
        applyMinimap = true,
        applyWorldMap = true,
        bridgeTrackColors = false,
        useNeutralIcons = false,
        minimapProximityOnly = false,
        pinScale = 1.0,
        pinAlpha = 1.0,
        categoryColors = {
            ["Mining"]         = { r = 0.95, g = 0.30, b = 0.20, a = 1 },
            ["Herb Gathering"] = { r = 0.20, g = 0.85, b = 0.20, a = 1 },
            ["Fishing"]        = { r = 0.20, g = 0.55, b = 0.95, a = 1 },
            ["Logging"]        = { r = 0.65, g = 0.40, b = 0.20, a = 1 },
            ["Extract Gas"]    = { r = 0.20, g = 0.95, b = 0.95, a = 1 },
            ["Treasure"]       = { r = 0.95, g = 0.30, b = 0.95, a = 1 },
            ["Archaeology"]    = { r = 0.95, g = 0.85, b = 0.40, a = 1 },
        },
        -- Pre-seeded per-node palette for Midnight-era gathering nodes.
        -- Hand-picked to be distinct within each category and thematically
        -- tied to the node (e.g. Sanguithorn -> crimson, Mana Lily -> arcane
        -- purple, Refulgent Copper -> copper, Umbral Tin -> shadow grey).
        -- AceDB copyDefaults only fills missing keys, so users who have
        -- already set per-node colours keep their existing choices.
        nodeColors = {
            ["Herb Gathering"] = {
                [1481] = { r = 0.85, g = 0.88, b = 0.92, a = 1 }, -- Argentleaf (silver)
                [1482] = { r = 0.20, g = 0.50, b = 0.95, a = 1 }, -- Azeroot (azure)
                [1483] = { r = 0.65, g = 0.45, b = 0.95, a = 1 }, -- Mana Lily (arcane lavender)
                [1484] = { r = 0.85, g = 0.15, b = 0.20, a = 1 }, -- Sanguithorn (crimson)
                [1485] = { r = 0.40, g = 0.85, b = 0.80, a = 1 }, -- Tranquility Bloom (calm teal)
            },
            ["Mining"] = {
                [1245] = { r = 0.80, g = 0.82, b = 0.88, a = 1 }, -- Brilliant Silver (pale silver)
                [1246] = { r = 0.95, g = 0.95, b = 1.00, a = 1 }, -- Brilliant Silver Seam (bright white-silver)
                [1247] = { r = 0.85, g = 0.50, b = 0.20, a = 1 }, -- Refulgent Copper (copper)
                [1248] = { r = 1.00, g = 0.65, b = 0.25, a = 1 }, -- Refulgent Copper Seam (gold-copper)
                [1249] = { r = 0.40, g = 0.45, b = 0.55, a = 1 }, -- Umbral Tin (shadow grey-blue)
                [1250] = { r = 0.55, g = 0.60, b = 0.70, a = 1 }, -- Umbral Tin Seam (lighter shadow)
            },
            ["Logging"] = {
                [715] = { r = 0.85, g = 0.30, b = 0.40, a = 1 },  -- Thalassian Lumber (Sin'dorei red-gold)
            },
        },
    },
    global = {
        -- Snapshot of GatherMate2's db.profile.trackColors taken the first time
        -- the bridge is enabled. Used to restore GM2's original palette when
        -- the bridge is turned off. Stored with GM2's capitalised RGBA keys.
        originalTrackColors = nil,
    },
}
