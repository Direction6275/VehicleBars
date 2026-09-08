local _, Addon = ...

-- Called by secure state/page transitions, or explicitly outside combat.
-- A page transition can introduce a vehicle while combat is already running.
Addon.HUDLayout = [[
    local active = self:GetAttribute("state-mode") == "vehicle"
    local preview = not active and self:GetAttribute("preview") and self:GetAttribute("state-combat") ~= 1
    local enabled = self:GetAttribute("enabled")
    local size = self:GetAttribute("size")
    local spacing = self:GetAttribute("spacing")
    local page = self:GetFrameRef("bar"):GetAttribute("state")
    local count = 0
    for slot = 1, 12 do
        local cell = self:GetFrameRef("cell" .. slot)
        local source = self:GetFrameRef("source" .. slot)
        local populated = false
        if active and page then
            local kind = source:GetAttribute("labtype-" .. page)
            local action = source:GetAttribute("labaction-" .. page)
            populated = (kind == "action" and action and HasAction(action)) or kind == "custom"
        end
        local sample = preview and cell:GetAttribute("preview-index")
        local displayed = enabled and active and populated
        cell:SetAttribute("displayed", displayed and true or nil)
        cell:SetAttribute("sample", enabled and sample or nil)
        -- No action remains armed between mouse events or in a preview.
        cell:SetAttribute("type", nil)
        if displayed or (enabled and sample) then
            cell:SetWidth(size)
            cell:SetHeight(size)
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", self, "LEFT", count * (size + spacing), 0)
            cell:EnableMouse(true)
            cell:Show()
            count = count + 1
        else
            cell:EnableMouse(false)
            cell:Hide()
        end
    end
    self:SetWidth(max(size, count * (size + spacing) - spacing))
    self:SetHeight(size)
    self:SetAttribute("showing-preview", enabled and preview and count > 0 or nil)
    if count > 0 then self:Show() else self:Hide() end
]]

-- Refresh the action from the source for each physical press/release. Never
-- use an insecure OnClick to cast, or forward Click() and lose its down edge.
Addon.HUDPreClick = [[
    self:SetAttribute("type", nil)
    if button ~= "LeftButton" or not self:GetAttribute("displayed") or control:GetAttribute("state-mode") ~= "vehicle" then return end
    local source = control:GetFrameRef("source" .. self:GetAttribute("slot"))
    local kind = source:GetAttribute("type")
    local action = source:GetAttribute("action")
    if kind == "action" and action and HasAction(action) then
        self:SetAttribute("action", action)
    elseif kind ~= "custom" then
        return
    end
    for _, attribute in ipairs(newtable("useOnKeyDown", "pressAndHoldAction", "typerelease", "checkselfcast", "checkfocuscast", "checkmouseovercast", "unit", "unit2")) do
        self:SetAttribute(attribute, source:GetAttribute(attribute))
    end
    self:SetAttribute("type", kind)
]]
