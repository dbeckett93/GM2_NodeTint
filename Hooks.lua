local _, ns = ...

-- White-on-transparent silhouettes shipped under Textures/. Used when the
-- useNeutralIcons profile toggle is on so that SetVertexColor produces vivid
-- arbitrary colours rather than multiplying against GM2's pre-coloured icons.
-- Path is the standard interface-relative form (no extension; engine resolves
-- to .blp/.tga/.png in that order).
local TEX_BASE = "Interface\\AddOns\\GM2_NodeTint\\Textures\\"
ns.NEUTRAL_TEXTURES = {
    ["Mining"]         = TEX_BASE .. "mining",
    ["Herb Gathering"] = TEX_BASE .. "herb",
    ["Fishing"]        = TEX_BASE .. "fishing",
    ["Logging"]        = TEX_BASE .. "logging",
    ["Extract Gas"]    = TEX_BASE .. "gas",
    ["Treasure"]       = TEX_BASE .. "treasure",
    ["Archaeology"]    = TEX_BASE .. "archaeology",
}

local function applyPinColor(pin, applyHere, surface)
    if not pin or not pin.texture or not pin.nodeType then return end

    local profile = ns.addon.db.profile
    local forceNeutral = false

    -- Minimap proximity-only mode: hide pins beyond GM2's trackDistance,
    -- show our coloured neutral icon for the rest. Reuses GM2's setting as
    -- the single source of truth for the threshold. Gated on applyHere so a
    -- user who turned off "Tint minimap pins" gets a true no-op on minimap.
    if surface == "minimap" and applyHere and profile.minimapProximityOnly then
        local gm2  = ns.GatherMate
        local hbd  = gm2 and gm2.HBD
        local gdb  = gm2 and gm2.db and gm2.db.profile
        local thresh = (gdb and gdb.trackDistance) or 100
        if hbd and pin.x1 and pin.y1 then
            local px, py = hbd:GetPlayerWorldPosition()
            if px and py then
                local dx, dy = px - pin.x1, py - pin.y1
                if dx*dx + dy*dy > thresh*thresh then
                    pin:Hide()
                    return
                end
            end
        end
        pin:Show()
        forceNeutral = true
    end

    if not applyHere then
        pin.texture:SetVertexColor(1, 1, 1, 1)
        return
    end

    -- Opacity multiplier on GM2's just-set alpha. GM2 re-sets alpha every
    -- addMiniPin tick (Display.lua:557) and on every OnAcquired (Display.lua
    -- :791), so reading the just-set value and multiplying once is stable.
    local alphaMul = profile.pinAlpha or 1
    if alphaMul ~= 1 then
        pin:SetAlpha(pin:GetAlpha() * alphaMul)
    end

    -- Texture swap (must run before the scale block so the scale block's
    -- explicit anchors are the final word on texture position). Force in
    -- proximity-only mode so we override GM2's tracking-circle ring with our
    -- coloured icon. Otherwise honour the useNeutralIcons toggle and skip in
    -- circle mode to leave GM2's ring alone. World-map pins have no isCircle
    -- field so the check is naturally false there.
    if (profile.useNeutralIcons or forceNeutral) and (forceNeutral or not pin.isCircle) then
        local tex = ns.NEUTRAL_TEXTURES[pin.nodeType]
        if tex then pin.texture:SetTexture(tex) end
    end

    -- Scale multiplier. Implemented by oversizing the inner pin.texture
    -- relative to the pin frame, NOT by pin:SetScale or pin:SetSize.
    -- - SetScale would change the pin's coordinate space; GM2's pre-calculated
    --   SetPoint offsets in addMiniPin (~L555-556) would then be reinterpreted
    --   in scaled space, dragging pins off their real coordinates.
    -- - SetSize would compound because GM2's addMiniPin only re-sets pin size
    --   on tracking-circle transitions (~L491,L500), not every tick.
    -- The explicit TOPLEFT/BOTTOMRIGHT anchors here also override GM2's
    -- tracking-circle texture offsets (-1, 1 at Display.lua:495-497) when we
    -- forced a neutral icon under proximity-only mode. At scale = 1 the
    -- anchors collapse to the frame, equivalent to SetAllPoints.
    local s = profile.pinScale or 1
    if forceNeutral or not pin.isCircle then
        local w, h = pin:GetSize()
        if w and w > 0 then
            local extraW = w * (s - 1) / 2
            local extraH = h * (s - 1) / 2
            pin.texture:ClearAllPoints()
            pin.texture:SetPoint("TOPLEFT",     pin, "TOPLEFT",     -extraW,  extraH)
            pin.texture:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT",  extraW, -extraH)
        end
    end

    local r, g, b, a = ns.addon:GetColor(pin.nodeType, pin.nodeID)
    if r then
        pin.texture:SetVertexColor(r, g, b, a)
    else
        pin.texture:SetVertexColor(1, 1, 1, 1)
    end
end
ns.ApplyPinColor = applyPinColor

function ns.InstallHooks()
    if ns._hooksInstalled then return end

    local addon = ns.addon
    local gm2   = ns.GatherMate

    local worldMixin = _G.GatherMate2WorldMapPinMixin
    if worldMixin and worldMixin.OnAcquired then
        hooksecurefunc(worldMixin, "OnAcquired", function(self)
            applyPinColor(self, addon.db.profile.applyWorldMap, "worldmap")
        end)
    else
        addon:Print("|cffff4040GM2 NodeTint|r: GatherMate2WorldMapPinMixin missing; world map hook skipped.")
    end

    local Display = gm2 and gm2:GetModule("Display", true)
    if Display and Display.addMiniPin then
        hooksecurefunc(Display, "addMiniPin", function(_self, pin)
            applyPinColor(pin, addon.db.profile.applyMinimap, "minimap")
        end)
    else
        addon:Print("|cffff4040GM2 NodeTint|r: GatherMate2 Display.addMiniPin missing; minimap hook skipped.")
    end

    ns._hooksInstalled = true
end
