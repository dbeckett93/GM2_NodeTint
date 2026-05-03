local _, ns = ...

local LibStub = _G.LibStub

local function safeKey(s)
    return (s:gsub("%s+", "_")):lower()
end

local function isAddonLoaded(name)
    if _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded then
        return _G.C_AddOns.IsAddOnLoaded(name)
    end
    if _G.IsAddOnLoaded then
        return _G.IsAddOnLoaded(name)
    end
    return false
end

local function buildGeneralArgs(addon)
    local db = addon.db
    return {
        desc = {
            type  = "description",
            order = 1,
            name  = "GM2 NodeTint overlays per-node and per-category colours on top of GatherMate2's gathering pins, on both the world map and the minimap.\n\n"
                 .. "|cffffd200Note about GatherMate2 tracking circles:|r when GatherMate2's |cff7eb6ffTrack Distance|r is enabled, close-range pins switch to a generic ring icon instead of the per-node icon. The colour you set here still applies, but the visual icon distinction is lost in close range. Disable Track Distance in GatherMate2 if you want the icons back.\n",
        },
        enabled = {
            type  = "toggle",
            order = 10,
            name  = "Enable tinting",
            desc  = "Master switch. When off, all GatherMate2 pins paint with their default GM2 appearance.",
            width = "full",
            get   = function() return db.profile.enabled end,
            set   = function(_, v) db.profile.enabled = v; addon:RefreshConfig() end,
        },
        applyWorldMap = {
            type  = "toggle",
            order = 20,
            name  = "Tint world map pins",
            get   = function() return db.profile.applyWorldMap end,
            set   = function(_, v) db.profile.applyWorldMap = v; addon:RefreshConfig() end,
        },
        applyMinimap = {
            type  = "toggle",
            order = 30,
            name  = "Tint minimap pins",
            get   = function() return db.profile.applyMinimap end,
            set   = function(_, v) db.profile.applyMinimap = v; addon:RefreshConfig() end,
        },
        minimapProximityOnly = {
            type  = "toggle",
            order = 31,
            name  = "Minimap: only show pins in proximity",
            desc  = "Hide minimap pins beyond GatherMate2's tracking distance, and replace GatherMate2's tracking-circle ring with the neutral coloured icon. Within range, pins use the per-node / per-category palette. Outside range, nothing is rendered on the minimap.\n\nThe distance is GatherMate2's own |cff7eb6ffTrack Distance|r setting (configure it in GM2's options). World-map pins are unaffected.",
            width = "full",
            get   = function() return db.profile.minimapProximityOnly end,
            set   = function(_, v) db.profile.minimapProximityOnly = v; addon:RefreshConfig() end,
        },
        useNeutralIcons = {
            type  = "toggle",
            order = 35,
            name  = "Use neutral icons (vivid colours)",
            desc  = "Replace GatherMate2's coloured icons with white silhouettes (one shape per category) before tinting. Vertex colour multiplies against the source pixels, so a white base reaches full saturation — your chosen colour appears exactly as picked rather than muted by the icon's built-in hue.\n\nGatherMate2's tracking-circle ring is left alone in close range, so the in-range indicator behaves as normal.",
            width = "full",
            get   = function() return db.profile.useNeutralIcons end,
            set   = function(_, v) db.profile.useNeutralIcons = v; addon:RefreshConfig() end,
        },
        pinScale = {
            type  = "range",
            order = 36,
            name  = "Pin scale",
            desc  = "Multiplier on GatherMate2's pin size. 1.00 leaves GM2's size unchanged. Useful when neutral icons feel too small at the default GM2 pin size (12 pixels).",
            min   = 0.5, max = 3.0, step = 0.05,
            isPercent = true,
            width = "full",
            get   = function() return db.profile.pinScale end,
            set   = function(_, v) db.profile.pinScale = v; addon:RefreshConfig() end,
        },
        pinAlpha = {
            type  = "range",
            order = 37,
            name  = "Pin opacity",
            desc  = "Multiplier on GatherMate2's pin alpha. 1.00 leaves GM2's opacity unchanged. Lower for a translucent overlay that doesn't obscure the underlying map.",
            min   = 0.1, max = 1.0, step = 0.05,
            isPercent = true,
            width = "full",
            get   = function() return db.profile.pinAlpha end,
            set   = function(_, v) db.profile.pinAlpha = v; addon:RefreshConfig() end,
        },
        spacer = { type = "description", name = " ", order = 40 },
        bridgeTrackColors = {
            type  = "toggle",
            order = 41,
            name  = "Sync category palette into GatherMate2's tracking circles",
            desc  = "Mirror the per-category colours below into GatherMate2's own |cff7eb6fftrackColors|r table, so GatherMate2's close-range tracking-circle mode uses the same palette. Your original GM2 palette is snapshotted on first enable and restored when this toggle is turned off.\n\nNote: per-node colours always override the circle in close range via our hook regardless of this toggle.",
            width = "full",
            get   = function() return db.profile.bridgeTrackColors end,
            set   = function(_, v) addon:SetBridgeTrackColors(v); ns.NotifyConfigChanged() end,
        },
        bridgeSpacer = { type = "description", name = " ", order = 42 },
        reset = {
            type    = "execute",
            order   = 50,
            name    = "Reset profile to defaults",
            confirm = true,
            confirmText = "Reset all GM2 NodeTint colours and toggles for the active profile?",
            func    = function() addon.db:ResetProfile() end,
        },
    }
end

local function buildCategoriesArgs(addon)
    local db = addon.db
    local args = {
        header = {
            type  = "description",
            order = 1,
            name  = "Set a default colour for each gathering category. These apply to every node in the category unless overridden in the Per-Node tab.\n",
        },
    }

    for i, cat in ipairs(ns.CATEGORIES) do
        local key = safeKey(cat)
        args[key] = {
            type    = "color",
            order   = i * 10,
            name    = cat,
            hasAlpha = true,
            get     = function()
                local c = db.profile.categoryColors[cat]
                if c then return c.r, c.g, c.b, c.a end
                return 1, 1, 1, 1
            end,
            set     = function(_, r, g, b, a) addon:SetCategoryColor(cat, r, g, b, a) end,
        }
        args[key .. "_clear"] = {
            type    = "execute",
            order   = i * 10 + 1,
            name    = "Clear",
            width   = "half",
            func    = function() addon:ClearCategoryColor(cat) end,
            disabled = function() return db.profile.categoryColors[cat] == nil end,
        }
    end

    return args
end

local function buildNodesArgs(addon)
    local db = addon.db
    local gm2 = ns.GatherMate
    local args = {
        hint = {
            type  = "description",
            order = 1,
            name  = "|cffff8040Note:|r GatherMate2_Data is not loaded. You will not see pins for nodes you haven't personally gathered yet, even though they appear in this list. Run GatherMate2's data import to populate.\n",
            hidden = function() return isAddonLoaded("GatherMate2_Data") end,
        },
        header = {
            type  = "description",
            order = 2,
            name  = "Pick a category, then assign a colour to a specific node. The list reflects every node GatherMate2 currently knows about. Per-node colours override the category default for that node only.\n",
        },
    }

    if not gm2 then return args end

    for i, cat in ipairs(ns.CATEGORIES) do
        local entries = {}
        local seen = {}

        -- Prefer reverseNodeIDs: keyed by id with the canonical name. nodeIDs
        -- maps every variant name to the same id, so iterating it produces
        -- collisions that hide most variant-bearing nodes (Dragonflight herbs,
        -- TWW herbs, Midnight herbs).
        local revMap = gm2.reverseNodeIDs and gm2.reverseNodeIDs[cat]
        if revMap then
            for rawID, name in pairs(revMap) do
                local id = ns.ResolveNodeID(rawID)
                if not seen[id] then
                    seen[id] = true
                    entries[#entries + 1] = { name = name, id = id }
                end
            end
        elseif gm2.nodeIDs and gm2.nodeIDs[cat] then
            for name, rawID in pairs(gm2.nodeIDs[cat]) do
                local id = ns.ResolveNodeID(rawID)
                if not seen[id] then
                    seen[id] = true
                    entries[#entries + 1] = { name = name, id = id }
                end
            end
        end

        if #entries > 0 then
            table.sort(entries, function(a, b) return a.name < b.name end)

            local subArgs = {}
            for j, e in ipairs(entries) do
                local idKey = tostring(e.id)
                subArgs[idKey] = {
                    type    = "color",
                    order   = j * 2,
                    name    = e.name,
                    hasAlpha = true,
                    get     = function()
                        local m = db.profile.nodeColors[cat]
                        local v = m and m[e.id]
                        if v then return v.r, v.g, v.b, v.a end
                        local c = db.profile.categoryColors[cat]
                        if c then return c.r, c.g, c.b, c.a end
                        return 1, 1, 1, 1
                    end,
                    set     = function(_, r, g, b, a)
                        addon:SetNodeColor(cat, e.id, r, g, b, a)
                    end,
                }
                subArgs[idKey .. "_reset"] = {
                    type    = "execute",
                    order   = j * 2 + 1,
                    name    = "Reset",
                    width   = "half",
                    func    = function() addon:ClearNodeColor(cat, e.id) end,
                    disabled = function()
                        local m = db.profile.nodeColors[cat]
                        return not (m and m[e.id])
                    end,
                }
            end

            args[safeKey(cat)] = {
                type  = "group",
                order = 10 + i,
                name  = cat,
                args  = subArgs,
            }
        end
    end

    return args
end

function ns.RegisterOptions()
    if ns._optionsRegistered then return end

    local AceConfig       = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local AceDBOptions    = LibStub("AceDBOptions-3.0")

    local addon = ns.addon

    local options = {
        type        = "group",
        name        = "GM2 NodeTint",
        childGroups = "tab",
        args        = {
            general = {
                type  = "group",
                order = 10,
                name  = "General",
                args  = buildGeneralArgs(addon),
            },
            categories = {
                type  = "group",
                order = 20,
                name  = "Categories",
                args  = buildCategoriesArgs(addon),
            },
            nodes = {
                type        = "group",
                order       = 30,
                name        = "Per-Node",
                childGroups = "select",
                args        = buildNodesArgs(addon),
            },
            profiles = AceDBOptions:GetOptionsTable(addon.db),
        },
    }
    options.args.profiles.order = 40

    AceConfig:RegisterOptionsTable("GM2_NodeTint", options)

    local _, categoryID = AceConfigDialog:AddToBlizOptions("GM2_NodeTint", "GM2 NodeTint")
    ns.optionsCategoryID = categoryID
    ns._optionsRegistered = true
end

function ns.NotifyConfigChanged()
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange("GM2_NodeTint")
    end
end
