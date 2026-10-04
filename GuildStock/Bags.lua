local _, addon = ...
local L = addon.L
local frames, buttons = {}, {}
local learned, catalog, tooltipHooked, hinted, scheduled

local function OutOfCombat()
    return addon.Read(InCombatLockdown) == false
end

function addon.BagHintsEnabled()
    if not addon.db or addon.temporary then return false end
    local settings = addon.db.settings
    return settings == nil or (type(settings) == "table"
        and (settings.bagHints == nil or settings.bagHints == true))
end

local function CarriedItem(button)
    if addon.Read(button.IsForbidden, button) ~= false then return end
    local bag, slot = addon.Read(button.GetBagID, button), addon.Read(button.GetID, button)
    local counts = Constants and Constants.InventoryConstants
    local lastBag = counts and counts.NumBagSlots + (counts.NumReagentBagSlots or 0)
    if not addon.Integer(bag, 0, lastBag or 0) or not addon.Integer(slot, 1, 1000) then return end
    local info = addon.Read(C_Container and C_Container.GetContainerItemInfo, bag, slot)
    if type(info) == "table" and addon.Integer(info.itemID, 1, 2147483647)
        and addon.Accessible(info.isFiltered) and not info.isFiltered then return info.itemID end
end

local function UsefulFor(id)
    if not id or not learned or not catalog then return end
    local uses = catalog[id]
    if not addon.Accessible(uses) or type(uses) ~= "table" then return end
    local names = {}
    for _, key in ipairs(learned) do
        if addon.Accessible(uses[key]) and uses[key] == true then
            for _, profession in ipairs(addon.professions) do
                if profession[1] == key then
                    names[#names + 1] = "|TInterface\\Icons\\" .. profession[2] .. ":16:16:0:0|t " .. L[key]
                    break
                end
            end
        end
    end
    if #names > 0 then return L["Useful for:"] .. " " .. table.concat(names, ", ") end
end

local function HideBadges()
    for button, badge in pairs(buttons) do
        if badge.icon and addon.Read(button.IsForbidden, button) == false then
            badge.icon:Hide(); badge.background:Hide()
        end
    end
end

local function TooltipHint(tooltip, data)
    if tooltip ~= GameTooltip or hinted or not OutOfCombat() or not addon.BagHintsEnabled()
        or addon.Read(tooltip.IsForbidden, tooltip) ~= false then return end
    local owner = addon.Read(tooltip.GetOwner, tooltip)
    if not owner or not buttons[owner] then return end
    local info = addon.Read(tooltip.GetProcessingTooltipInfo, tooltip)
    if type(info) ~= "table" or not addon.Accessible(info.getterName) or info.getterName ~= "GetBagItem"
        or not addon.Accessible(info.append) or info.append then return end
    if not addon.Accessible(data) or type(data) ~= "table" or not addon.Integer(data.id, 1, 2147483647) then return end
    local id = CarriedItem(owner)
    if id ~= data.id then return end
    local text = UsefulFor(id)
    if text then
        tooltip:AddLine(text, 1, 0.82, 0, true)
        hinted = true
    end
end

local function Schedule()
    if scheduled or not addon.db or type(ContainerFrameUtil_EnumerateContainerFrames) ~= "function" then return end
    scheduled = true
    C_Timer.After(0.05, function()
        scheduled = false
        addon.RefreshBagHints()
    end)
end

function addon.RefreshBagHints()
    HideBadges()
    if not OutOfCombat() or not addon.db then return end
    if type(ContainerFrameUtil_EnumerateContainerFrames) ~= "function" or type(hooksecurefunc) ~= "function" then return end
    if not tooltipHooked and TooltipDataProcessor and Enum and Enum.TooltipDataType
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function" and GameTooltip
        and addon.Read(GameTooltip.IsForbidden, GameTooltip) == false then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipHint)
        GameTooltip:HookScript("OnTooltipCleared", function() hinted = nil end)
        GameTooltip:HookScript("OnHide", function() hinted = nil end)
        tooltipHooked = true
    end
    local enabled = addon.BagHintsEnabled()
    learned = enabled and addon.LearnedProfessions() or nil
    catalog = enabled and addon.Catalog() or nil
    for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
        if addon.Read(frame.IsForbidden, frame) == false and type(frame.EnumerateItems) == "function" then
            if not frames[frame] then
                frames[frame] = true
                -- Hook existing instances: their mixin methods were copied before addon loading.
                if type(frame.UpdateItems) == "function" then hooksecurefunc(frame, "UpdateItems", Schedule) end
                if type(frame.UpdateSearchResults) == "function" then hooksecurefunc(frame, "UpdateSearchResults", Schedule) end
                frame:HookScript("OnShow", Schedule)
            end
            if frame:IsShown() then
                for _, button in frame:EnumerateItems() do
                    if addon.Read(button.IsForbidden, button) == false then
                        local badge = buttons[button]
                        if not badge then badge = {}; buttons[button] = badge end
                        local useful = enabled and button:IsShown() and UsefulFor(CarriedItem(button))
                        if useful then
                            if not badge.icon then
                                badge.background = button:CreateTexture(nil, "OVERLAY", nil, 6)
                                badge.background:SetSize(16, 16)
                                badge.background:SetPoint("TOPRIGHT", -1, -1)
                                badge.background:SetColorTexture(0.06, 0.04, 0.02, 0.95)
                                badge.icon = button:CreateTexture(nil, "OVERLAY", nil, 7)
                                badge.icon:SetSize(14, 14)
                                badge.icon:SetPoint("TOPRIGHT", -2, -2)
                                badge.icon:SetAtlas("bags-icon-profession-goods")
                            end
                            badge.background:Show(); badge.icon:Show()
                        end
                    end
                end
            end
        end
    end
end

function addon.BagHintsChanged()
    -- Dismiss our previous line instead of leaving it on a tooltip after disabling/changing skills.
    if hinted and GameTooltip then GameTooltip:Hide() end
    addon.RefreshBagHints()
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ADDON_LOADED", "BAG_OPEN",
    "BAG_CONTAINER_UPDATE", "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE",
    "TRADE_SKILL_SHOW", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        HideBadges()
        if hinted and GameTooltip then GameTooltip:Hide() end
    else
        if event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_SHOW" then
            learned = nil
            HideBadges()
            if hinted and GameTooltip then GameTooltip:Hide() end
        end
        Schedule()
    end
end)
