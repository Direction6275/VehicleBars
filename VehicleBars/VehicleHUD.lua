local addonName, Addon = ...
if not ElvUI then return end

local E, P = ElvUI[1], ElvUI[4]
local EP = LibStub("LibElvUIPlugin-1.0")
local MOVER = "VehicleBarsHUDMover"
P.vehicleBarsHUD = { enabled = true, size = 36, spacing = 4 }

local hud, preview, queued, registered
local cells, sourceSlots = {}, {}
local previewSlots = { 1, 2, 3, 12 }
local previewTextures = {
    "Interface\\Icons\\Spell_Fire_FireBall02",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    "Interface\\Icons\\INV_Misc_Bomb_04",
    "Interface\\Icons\\Spell_Shadow_SacrificialShield",
}

local function IsVehicleActive()
    return Addon.controller and Addon.controller:GetAttribute("state-mode") == "vehicle"
end

-- isActive and shouldReplaceNormalCooldown are explicitly NeverSecret in the
-- Retail API. Duration objects go directly to the Cooldown widget: no time math.
local function DisplayDuration(source)
    local loc = source:GetLoCCooldownInfo()
    if loc and loc.isActive and loc.shouldReplaceNormalCooldown and source.config.lossOfControlCooldown then
        return source:GetLoCCooldownDuration()
    end
    local cooldown = source:GetCooldownInfo()
    if cooldown and cooldown.isActive then return source:GetCooldownDuration() end
    local charge = source:GetChargeInfo()
    if charge and charge.isActive then return source:GetChargeDuration() end
end

local function HideTooltip(cell)
    if not GameTooltip:IsForbidden() and GameTooltip:IsOwned(cell) then
        GameTooltip:Hide()
    end
end

local function ShowTooltip(cell)
    if GameTooltip:IsForbidden() then return end
    if cell:GetAttribute("sample") then
        GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
        GameTooltip:SetText("Vehicle HUD preview")
        GameTooltip:AddLine("Preview icons do not perform actions.", 1, 1, 1)
        GameTooltip:Show()
    elseif cell:GetAttribute("displayed") and IsVehicleActive() and cell.source:HasAction() then
        GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
        cell.source:SetTooltip()
        local key = Addon.controller:GetAttribute("hotkey" .. cell.slot)
        if key then GameTooltip:AddLine("Key: " .. GetBindingText(key, true), 1, 1, 1) end
        GameTooltip:Show()
    else
        HideTooltip(cell)
    end
end

local function SyncLayout()
    if not hud or InCombatLockdown() then return end
    local db = E.db.vehicleBarsHUD
    hud:SetAttribute("enabled", db.enabled)
    hud:SetAttribute("size", db.size)
    hud:SetAttribute("spacing", db.spacing)
    hud:SetAttribute("preview", preview or hud.mover:IsShown() or nil)
    hud:Execute([[self:RunAttribute("layout")]])
end

local function Refresh()
    queued = false
    if not hud then return end
    SyncLayout()
    local size = hud:GetAttribute("size")
    for slot, cell in ipairs(cells) do
        local source = cell.source
        local sample = cell:GetAttribute("sample")
        local live = cell:GetAttribute("displayed") and IsVehicleActive() and source:HasAction()
        cell.key:FontTemplate(nil, math.max(10, math.floor(size * 0.34)), "OUTLINE")
        cell.count:FontTemplate(nil, math.max(10, math.floor(size * 0.3)), "OUTLINE")
        -- Alpha and texture changes are allowed on protected buttons in combat.
        -- Geometry and visibility belong exclusively to the secure layout.
        cell:SetAlpha((sample or live) and 1 or 0)
        if sample then
            cell.icon:SetTexture(previewTextures[sample])
            cell.key:SetText(GetBindingText(GetBindingKey("ACTIONBUTTON" .. (13 - slot)), true))
            cell.count:SetText("")
            cell.cooldown:Clear()
            cell.pressed:Hide()
        elseif live then
            cell.icon:SetTexture(source:GetTexture())
            cell.key:SetText(GetBindingText(Addon.controller:GetAttribute("hotkey" .. slot), true))
            cell.count:SetText(source.Count:GetText())
            local duration = DisplayDuration(source)
            if duration then cell.cooldown:SetCooldownFromDurationObject(duration) else cell.cooldown:Clear() end
            cell.pressed:SetShown(cell.isPressed or cell.mousePressed or false)
        else
            cell.isPressed, cell.mousePressed = false, false
            cell.pressed:Hide()
            cell.cooldown:Clear()
        end
        if cell.hovered then ShowTooltip(cell) end
    end
    hud.previewLabel:SetShown(hud:GetAttribute("showing-preview") or false)
end

local function QueueRefresh()
    if not hud or queued then return end
    queued = true
    -- A single event can update all twelve LAB buttons. Render their final
    -- state once, after ElvUI finishes its page transition. No polling loop.
    C_Timer.After(0, Refresh)
end
Addon.RefreshHUD = QueueRefresh

local function OnSourceUpdate(_, source)
    if sourceSlots[source] and IsVehicleActive() then QueueRefresh() end
end

local function TogglePreview()
    if InCombatLockdown() then
        print("Vehicle Bars: leave combat before using the preview.")
        return
    end
    preview = not preview
    Refresh()
end

local function MoveHUD()
    if InCombatLockdown() then
        print("Vehicle Bars: leave combat before moving the HUD.")
        return
    end
    E:ToggleMoveMode(MOVER)
end

local function AddOptions()
    E.Options.args.vehicleBars = {
        type = "group", name = "Vehicle Bars", order = 100,
        args = {
            description = {
                type = "description", order = 1,
                name = "A compact, clickable vehicle HUD with hover tooltips. Button positions stay fixed during combat; new gaps close afterward. Your regular action bars and vehicle key remapping stay active.",
            },
            enabled = {
                type = "toggle", name = "Show vehicle HUD", order = 2, disabled = InCombatLockdown,
                get = function() return E.db.vehicleBarsHUD.enabled end,
                set = function(_, value) E.db.vehicleBarsHUD.enabled = value; Refresh() end,
            },
            size = {
                type = "range", name = "Icon size", order = 3, disabled = InCombatLockdown, min = 24, max = 64, step = 1,
                get = function() return E.db.vehicleBarsHUD.size end,
                set = function(_, value) E.db.vehicleBarsHUD.size = value; Refresh() end,
            },
            spacing = {
                type = "range", name = "Spacing", order = 4, disabled = InCombatLockdown, min = 0, max = 12, step = 1,
                get = function() return E.db.vehicleBarsHUD.spacing end,
                set = function(_, value) E.db.vehicleBarsHUD.spacing = value; Refresh() end,
            },
            preview = {
                type = "execute", name = "Toggle preview", order = 5,
                disabled = InCombatLockdown, func = TogglePreview,
            },
            move = {
                type = "execute", name = "Move HUD", order = 6,
                disabled = InCombatLockdown, func = MoveHUD,
            },
        },
    }
end

local function Initialize()
    if hud or not E.Initialized or not Addon.controller or InCombatLockdown() then return end
    if #Addon.elvButtons ~= 12 then return end
    hud = CreateFrame("Frame", "VehicleBarsHUD", E.UIParent, "SecureHandlerStateTemplate")
    hud:SetSize(156, 36)
    hud:SetPoint("CENTER", E.UIParent, "CENTER", 0, -180)
    hud:SetFrameStrata("MEDIUM")
    hud:EnableMouse(false)

    for slot, source in ipairs(Addon.elvButtons) do
        local cell = CreateFrame("Button", "VehicleBarsHUDButton" .. slot, hud, "SecureActionButtonTemplate")
        cell.source, cell.slot = source, slot
        cell:SetAttribute("slot", slot)
        cell:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
        -- The same custom action implementation ElvUI uses for its exit slot.
        cell:SetAttribute("_custom", function() source:RunCustom() end)
        hud:SetFrameRef("source" .. slot, source)
        hud:SetFrameRef("cell" .. slot, cell)
        for index, previewSlot in ipairs(previewSlots) do
            if slot == previewSlot then cell:SetAttribute("preview-index", index) end
        end
        hud:WrapScript(cell, "OnClick", Addon.HUDPreClick)
        cell:HookScript("OnClick", function(_, _, down)
            cell.mousePressed = cell:GetAttribute("displayed") and down or false
            cell.pressed:SetShown(cell.isPressed or cell.mousePressed or false)
        end)
        cell:SetScript("OnEnter", function() cell.hovered = true; ShowTooltip(cell) end)
        local function ReleaseMouse()
            cell.mousePressed = false
            cell.pressed:SetShown(cell.isPressed or false)
        end
        cell:HookScript("OnMouseUp", ReleaseMouse)
        cell:SetScript("OnLeave", function()
            cell.hovered = false
            ReleaseMouse()
            HideTooltip(cell)
        end)
        cell:HookScript("OnHide", function()
            cell.hovered, cell.isPressed, cell.mousePressed = false, false, false
            HideTooltip(cell)
        end)
        cell:SetTemplate("Default")
        cell:EnableMouse(false)
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetPoint("TOPLEFT", 1, -1)
        cell.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        cell.cooldown = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
        cell.cooldown:SetAllPoints(cell.icon)
        cell.cooldown:SetDrawEdge(false)
        cell.cooldown:SetDrawBling(false)
        cell.cooldown:SetSwipeColor(0, 0, 0, 0.7)
        cell.cooldown:EnableMouse(false)
        E:RegisterCooldown(cell.cooldown, "actionbar")

        local textLayer = CreateFrame("Frame", nil, cell)
        textLayer:SetAllPoints(cell)
        textLayer:SetFrameLevel(cell.cooldown:GetFrameLevel() + 2)
        textLayer:EnableMouse(false)
        cell.key = textLayer:CreateFontString(nil, "OVERLAY")
        cell.key:SetPoint("TOPRIGHT", -2, -2)
        cell.key:SetTextColor(1, 1, 1)
        cell.count = textLayer:CreateFontString(nil, "OVERLAY")
        cell.count:SetPoint("BOTTOMRIGHT", -2, 2)
        cell.pressed = textLayer:CreateTexture(nil, "OVERLAY")
        cell.pressed:SetAllPoints(cell)
        cell.pressed:SetColorTexture(1, 1, 1, 0.25)
        cell.pressed:Hide()
        cell:Hide()
        cells[slot], sourceSlots[source] = cell, slot
        source:HookScript("OnClick", function(_, _, down)
            cell.isPressed = IsVehicleActive() and down or false
            cell.pressed:SetShown(cell.isPressed or cell.mousePressed or false)
        end)
    end
    hud:SetFrameRef("bar", Addon.elvButtons[1].header)
    hud:SetAttribute("layout", Addon.HUDLayout)
    hud:SetAttribute("_onstate-mode", [[
        self:RunAttribute("layout")
        self:CallMethod("QueueRefresh")
    ]])
    hud:SetAttribute("_onstate-combat", [[
        if newstate == 1 then self:SetAttribute("preview", nil) end
        self:RunAttribute("layout")
        self:CallMethod("QueueRefresh")
    ]])
    -- ElvUI writes its new page before updating its child buttons. Use its
    -- preconfigured labtype/labaction page data to compact combat vehicle entry.
    hud:WrapScript(Addon.elvButtons[1].header, "OnAttributeChanged", [[
        if name == "state" then return nil, true end
    ]], [[
        if name == "state" then
            control:RunAttribute("layout")
            control:CallMethod("QueueRefresh")
        end
    ]])
    hud.QueueRefresh = QueueRefresh
    hud.previewLabel = hud:CreateFontString(nil, "OVERLAY")
    hud.previewLabel:FontTemplate(nil, 11, "OUTLINE")
    hud.previewLabel:SetPoint("BOTTOM", hud, "TOP", 0, 5)
    hud.previewLabel:SetText("Vehicle HUD - Preview")
    E:CreateMover(hud, MOVER, "Vehicle HUD", nil, nil, nil, "ALL,ACTIONBARS", nil, "vehicleBars")
    hud.mover:HookScript("OnShow", QueueRefresh)
    hud.mover:HookScript("OnHide", QueueRefresh)
    E.Libs.LAB.RegisterCallback(Addon, "OnButtonUpdate", OnSourceUpdate)
    E.Libs.LAB.RegisterCallback(Addon, "OnCooldownUpdate", OnSourceUpdate)
    hooksecurefunc(E, "UpdateAll", QueueRefresh)
    SyncLayout()
    RegisterStateDriver(hud, "combat", "[combat] 1; 0")
    RegisterStateDriver(hud, "mode", "[petbattle] normal; [vehicleui][overridebar][possessbar] vehicle; normal")
    Refresh()
end

Addon.HandleHUDCommand = function(command)
    if command ~= "preview" and command ~= "move" then return false end
    Initialize()
    if not hud then
        print("Vehicle Bars: the HUD requires ElvUI action bar 1 to be initialized outside combat.")
    elseif command == "preview" then
        TogglePreview()
    else
        MoveHUD()
    end
    return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function(_, event)
    if not registered then
        EP:RegisterPlugin(addonName, AddOptions)
        registered = true
    end
    if event == "PLAYER_REGEN_DISABLED" then preview = false end
    Initialize()
    QueueRefresh()
end)
