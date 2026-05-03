local addonName, ns = ...

local LibStub = _G.LibStub
local AceAddon = LibStub("AceAddon-3.0")

local addon = AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
ns.addon = addon
_G.GM2_NodeTint = addon

local function resolveNodeID(id)
    local gm2 = ns.GatherMate
    if gm2 and gm2.nodeIDReplacementMap then
        return gm2.nodeIDReplacementMap[id] or id
    end
    return id
end
ns.ResolveNodeID = resolveNodeID

--------------------------------------------------------------------------------
-- Bridge to GatherMate2 db.profile.trackColors
--
-- When the user enables the bridge, we mirror our per-category palette into
-- GM2's own trackColors table so GM2's own tracking-circle mode honours the
-- same colours even when our addon is otherwise inactive (e.g. tinting
-- toggled off). On first activation we snapshot GM2's existing trackColors
-- into db.global.originalTrackColors; on deactivation we restore that
-- snapshot. The snapshot is global (not per-profile) so switching between
-- our profiles does not lose the original GM2 palette.
--------------------------------------------------------------------------------

local function getGM2TrackColors()
    local gm2 = ns.GatherMate
    if not gm2 or not gm2.db or not gm2.db.profile then return nil end
    return gm2.db.profile.trackColors
end

local function snapshotIfNeeded()
    local tc = getGM2TrackColors()
    if not tc then return end
    if addon.db.global.originalTrackColors then return end
    local snap = {}
    for cat, c in pairs(tc) do
        snap[cat] = { Red = c.Red, Green = c.Green, Blue = c.Blue, Alpha = c.Alpha }
    end
    addon.db.global.originalTrackColors = snap
end

local function writeCategoryToGM2(cat)
    local tc = getGM2TrackColors()
    if not tc or not tc[cat] then return end
    local p = addon.db.profile
    local c = p.categoryColors[cat]
    if c then
        tc[cat].Red, tc[cat].Green, tc[cat].Blue, tc[cat].Alpha = c.r, c.g, c.b, c.a
    else
        local snap = addon.db.global.originalTrackColors
        local o = snap and snap[cat]
        if o then
            tc[cat].Red, tc[cat].Green, tc[cat].Blue, tc[cat].Alpha = o.Red, o.Green, o.Blue, o.Alpha
        end
    end
end

local function pushAllCategoriesToGM2()
    local tc = getGM2TrackColors()
    if not tc then return end
    for cat in pairs(tc) do
        writeCategoryToGM2(cat)
    end
end

local function restoreOriginalsToGM2()
    local tc = getGM2TrackColors()
    if not tc then return end
    local snap = addon.db.global.originalTrackColors
    if not snap then return end
    for cat, o in pairs(snap) do
        if tc[cat] then
            tc[cat].Red, tc[cat].Green, tc[cat].Blue, tc[cat].Alpha = o.Red, o.Green, o.Blue, o.Alpha
        end
    end
end

-- Idempotent: brings GM2's trackColors into the state implied by the current
-- profile's bridgeTrackColors flag. Safe to call any time after Setup().
function addon:ApplyBridgeState()
    if not getGM2TrackColors() then return end
    if self.db.profile.bridgeTrackColors then
        snapshotIfNeeded()
        pushAllCategoriesToGM2()
        ns._bridgedActive = true
    else
        if ns._bridgedActive then
            restoreOriginalsToGM2()
        end
        ns._bridgedActive = false
    end
end

function addon:SetBridgeTrackColors(enabled)
    self.db.profile.bridgeTrackColors = enabled and true or false
    self:ApplyBridgeState()
    self:RefreshPins()
end

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GM2NodeTintDB", ns.DEFAULTS, true)

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied",  "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset",   "RefreshConfig")

    self:RegisterChatCommand("gmnt", "OnSlashCommand")
    self:RegisterChatCommand("gm2nodetint", "OnSlashCommand")

    if _G.GatherMate2 then
        self:Setup()
    else
        self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    end
end

function addon:OnAddonLoaded(_, name)
    if name == "GatherMate2" or _G.GatherMate2 then
        self:UnregisterEvent("ADDON_LOADED")
        self:Setup()
    end
end

function addon:Setup()
    if ns._setupDone then return end
    if not _G.GatherMate2 then return end
    ns.GatherMate = _G.GatherMate2
    ns._setupDone = true

    if ns.InstallHooks then ns.InstallHooks() end
    if ns.SeedNodeColors then ns.SeedNodeColors() end
    if ns.RegisterOptions then ns.RegisterOptions() end
    self:ApplyBridgeState()
end

function addon:GetColor(nodeType, nodeID)
    local p = self.db.profile
    if not p.enabled then return nil end
    if not nodeType then return nil end

    nodeID = resolveNodeID(nodeID)

    local nm = p.nodeColors[nodeType]
    local nc = nm and nm[nodeID]
    if nc then return nc.r, nc.g, nc.b, nc.a end

    local cc = p.categoryColors[nodeType]
    if cc then return cc.r, cc.g, cc.b, cc.a end

    return nil
end

function addon:SetCategoryColor(nodeType, r, g, b, a)
    self.db.profile.categoryColors[nodeType] = { r = r, g = g, b = b, a = a }
    if self.db.profile.bridgeTrackColors then
        writeCategoryToGM2(nodeType)
    end
    self:RefreshPins()
end

function addon:ClearCategoryColor(nodeType)
    self.db.profile.categoryColors[nodeType] = nil
    if self.db.profile.bridgeTrackColors then
        writeCategoryToGM2(nodeType)
    end
    self:RefreshPins()
end

function addon:SetNodeColor(nodeType, nodeID, r, g, b, a)
    nodeID = resolveNodeID(nodeID)
    local m = self.db.profile.nodeColors[nodeType]
    if not m then
        m = {}
        self.db.profile.nodeColors[nodeType] = m
    end
    m[nodeID] = { r = r, g = g, b = b, a = a }
    self:RefreshPins()
end

function addon:ClearNodeColor(nodeType, nodeID)
    nodeID = resolveNodeID(nodeID)
    local m = self.db.profile.nodeColors[nodeType]
    if m then m[nodeID] = nil end
    self:RefreshPins()
end

function addon:RefreshPins()
    local gm2 = ns.GatherMate
    if not gm2 then return end
    local Display = gm2:GetModule("Display", true)
    if not Display then return end
    if Display.UpdateWorldMap then Display:UpdateWorldMap() end
    if Display.UpdateMiniMap  then Display:UpdateMiniMap()  end
end

function addon:RefreshConfig()
    if ns.SeedNodeColors then ns.SeedNodeColors() end
    self:ApplyBridgeState()
    self:RefreshPins()
    if ns.NotifyConfigChanged then ns.NotifyConfigChanged() end
end

local function printUsage(self)
    self:Print("|cff33ff99GM2 NodeTint|r commands:")
    self:Print("  /gmnt          - open the options panel")
    self:Print("  /gmnt toggle   - enable/disable tinting")
    self:Print("  /gmnt reset    - reset the active profile to defaults")
end

function addon:OnSlashCommand(input)
    input = (input or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if input == "" or input == "config" or input == "options" then
        if ns.optionsCategoryID and _G.Settings and _G.Settings.OpenToCategory then
            _G.Settings.OpenToCategory(ns.optionsCategoryID)
        else
            self:Print("|cffff4040GM2 NodeTint|r: settings panel not registered yet.")
        end
    elseif input == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        self:RefreshPins()
        if ns.NotifyConfigChanged then ns.NotifyConfigChanged() end
        self:Print(("|cff33ff99GM2 NodeTint|r: tinting %s."):format(self.db.profile.enabled and "enabled" or "disabled"))
    elseif input == "reset" then
        self.db:ResetProfile()
        self:Print("|cff33ff99GM2 NodeTint|r: profile reset to defaults.")
    else
        printUsage(self)
    end
end
