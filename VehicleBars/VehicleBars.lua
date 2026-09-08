local _, Addon = ...
Addon = Addon or {}

local VERSION = "@project-version@"
--@debug@
VERSION = "1.2.0-dev"
--@end-debug@

local BUTTON_COUNT = 12
local STATE_DRIVER = "[petbattle] normal; [vehicleui][overridebar][possessbar] vehicle; normal"
local controller
local buttons = {}
local elvButtons = {}
Addon.elvButtons = elvButtons
local pendingRefresh = false

-- Only font strings are changed here. Native button attributes, command names,
-- action slots, and click handlers remain owned by Blizzard.
local function UpdateHotkey(button)
    local key
    if controller:GetAttribute("state-mode") == "vehicle" then
        -- Use the key from the last applied secure mapping, including while a
        -- binding edit is waiting for combat to end.
        key = controller:GetAttribute("hotkey" .. button:GetID())
    else
        key = GetBindingKey("ACTIONBUTTON" .. button:GetID())
            or GetBindingKey("CLICK " .. button:GetName() .. ":LeftButton")
    end

    local hotkey = button.HotKey
    local text = GetBindingText(key, true)
    if text == "" then
        hotkey:SetText(RANGE_INDICATOR)
        hotkey:Hide()
        return
    end

    -- Match Blizzard's keyboard/controller glyph sizing for the effective key.
    if IsBindingForGamePad(key) then
        hotkey:SetSize(button:GetWidth(), 16)
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT",
            button.hotkeyTextGamepadX or 0, button.hotkeyTextGamepadY or 0)
    else
        hotkey:SetSize(button:GetWidth() - 8, 10)
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT",
            button.hotkeyTextKeyboardX or 0, button.hotkeyTextKeyboardY or 0)
    end
    hotkey:SetText(text)
    hotkey:Show()
end

-- LibActionButton refreshes hotkeys through GetHotkey, then applies ElvUI's
-- postKeybind formatter. Wrap only that cosmetic getter; never its click code.
local function AttachElvUI()
    if #elvButtons > 0 then return end
    for index = 1, BUTTON_COUNT do
        local button = _G["ElvUI_Bar1Button" .. index]
        if not button or not button.GetHotkey or not button.config then return end
    end
    for index = 1, BUTTON_COUNT do
        local slot = index
        local button = _G["ElvUI_Bar1Button" .. slot]
        local originalGetHotkey = button.GetHotkey
        button.GetHotkey = function(self)
            if controller:GetAttribute("state-mode") == "vehicle" then
                local key = controller:GetAttribute("hotkey" .. slot)
                return key and GetBindingText(key, true) or nil
            end
            return originalGetHotkey(self)
        end
        elvButtons[slot] = button
        controller:SetAttribute("clicktarget" .. slot, button:GetName())
    end
end

local function RefreshElvHotkey(button)
    local key = button:GetHotkey()
    if not key or key == "" or button.config.hideElements.hotkey then
        button.HotKey:SetText(RANGE_INDICATOR)
        button.HotKey:Hide()
    else
        button.HotKey:SetText(key)
        button.HotKey:Show()
    end
    if button.postKeybind then
        button.postKeybind(nil, button)
    end
end

local function Initialize()
    controller = CreateFrame("Frame", "VehicleBarsBindingController", UIParent,
        "SecureHandlerStateTemplate")
    Addon.controller = controller

    controller.RefreshHotkeys = function()
        for _, button in ipairs(buttons) do
            UpdateHotkey(button)
        end
        for _, button in ipairs(elvButtons) do
            RefreshElvHotkey(button)
        end
        if Addon.RefreshHUD then Addon.RefreshHUD() end
    end

    controller:SetAttribute("_applybindings", [[
        self:ClearBindings()
        if self:GetAttribute("state-mode") == "vehicle" then
            for target = 1, 12 do
                local keys = newtable(GetBindingKey("ACTIONBUTTON" .. (13 - target)))
                self:SetAttribute("hotkey" .. target, keys[1])
                for _, key in ipairs(keys) do
                    local clickTarget = self:GetAttribute("clicktarget" .. target)
                    if clickTarget then
                        self:SetBindingClick(true, key, clickTarget, "LeftButton")
                    else
                        self:SetBinding(true, key, "ACTIONBUTTON" .. target)
                    end
                end
            end
        end
        self:CallMethod("RefreshHotkeys")
    ]])
    controller:SetAttribute("_onstate-mode", [[
        self:RunAttribute("_applybindings")
    ]])

    for _, prefix in ipairs({ "ActionButton", "OverrideActionBarButton" }) do
        for index = 1, BUTTON_COUNT do
            local button = _G[prefix .. index]
            if button then
                buttons[#buttons + 1] = button
                hooksecurefunc(button, "UpdateHotkeys", UpdateHotkey)
            end
        end
    end

    -- The state transition executes in WoW's restricted environment, so entry
    -- and exit can change these temporary bindings during combat.
    AttachElvUI()
    RegisterStateDriver(controller, "mode", STATE_DRIVER)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(self, event)
    if InCombatLockdown() then
        pendingRefresh = true
        return
    end
    if not controller then
        Initialize()
        self:RegisterEvent("UPDATE_BINDINGS")
    elseif event == "UPDATE_BINDINGS" or event == "PLAYER_ENTERING_WORLD" or pendingRefresh then
        -- AceAddon startup can finish after our PLAYER_LOGIN callback.
        AttachElvUI()
        controller:Execute([[self:RunAttribute("_applybindings")]])
    end
    pendingRefresh = false
end)

SLASH_VEHICLEBARS1 = "/vehiclebars"
SlashCmdList.VEHICLEBARS = function(command)
    command = (command or ""):lower():match("^%s*(.-)%s*$")
    if Addon.HandleHUDCommand and Addon.HandleHUDCommand(command) then return end
    local active = controller and controller:GetAttribute("state-mode") == "vehicle"
    local backend = #elvButtons > 0 and "ElvUI" or "Blizzard"
    print("Vehicle Bars " .. VERSION .. " (" .. backend .. "): "
        .. (active and "vehicle mapping active." or "normal bindings active."))
    if pendingRefresh then
        print("Vehicle Bars: binding refresh waiting for combat to end.")
    end
end
