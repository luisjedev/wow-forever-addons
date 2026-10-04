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

function addon.BagHintSize()
    local settings = addon.db and addon.db.settings
    local size = type(settings) == "table" and settings.bagHintSize
    return addon.Integer(size, 10, 24) and size or 14
end

local function CharacterBankPanel()
    if not BankFrame or addon.Read(BankFrame.IsForbidden, BankFrame) ~= false then return end
    local panel = BankFrame.BankPanel
    if not panel or addon.Read(panel.IsForbidden, panel) ~= false then return end
    return panel
end

local function BankVisible()
    local panel = CharacterBankPanel()
    local character = Enum and Enum.BankType and Enum.BankType.Character
    return panel and character ~= nil and addon.Read(BankFrame.IsShown, BankFrame) == true
        and addon.Read(panel.IsShown, panel) == true
        and addon.Read(panel.GetActiveBankType, panel) == character
        and addon.Read(C_Bank and C_Bank.CanViewBank, character) == true
end

local function ButtonItem(button)
    if addon.Read(button.IsForbidden, button) ~= false then return end
    local bank = buttons[button] and buttons[button].bank
    local bag, slot
    if bank then
        if not BankVisible() then return end
        bag, slot = addon.Read(button.GetBankTabID, button), addon.Read(button.GetContainerSlotID, button)
        local index = Enum and Enum.BagIndex
        if not index or not addon.Integer(index.CharacterBankTab_1, 0, 100)
            or not addon.Integer(index.CharacterBankTab_9, index.CharacterBankTab_1, 100)
            or not addon.Integer(bag, index.CharacterBankTab_1, index.CharacterBankTab_9) then return end
    else
        bag, slot = addon.Read(button.GetBagID, button), addon.Read(button.GetID, button)
        local counts = Constants and Constants.InventoryConstants
        local lastBag = counts and counts.NumBagSlots + (counts.NumReagentBagSlots or 0)
        if not addon.Integer(bag, 0, lastBag or 0) then return end
    end
    if not addon.Integer(slot, 1, 1000) then return end
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
            badge.icon:Hide(); badge.outline:Hide()
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
    local id = ButtonItem(owner)
    if id ~= data.id then return end
    local text = UsefulFor(id)
    if text then
        tooltip:AddLine(text, 1, 0.82, 0, true)
        hinted = true
    end
end

local function Schedule()
    if scheduled or not addon.db then return end
    if type(ContainerFrameUtil_EnumerateContainerFrames) ~= "function" and not CharacterBankPanel() then return end
    scheduled = true
    C_Timer.After(0.05, function()
        scheduled = false
        addon.RefreshBagHints()
    end)
end

local function RefreshButton(button, bank, enabled, size)
    if addon.Read(button.IsForbidden, button) ~= false then return end
    local badge = buttons[button]
    if not badge then badge = {}; buttons[button] = badge end
    badge.bank = bank
    if not enabled or addon.Read(button.IsShown, button) ~= true or not UsefulFor(ButtonItem(button)) then return end
    if not badge.icon then
        badge.outline = button:CreateTexture(nil, "OVERLAY", nil, 6)
        badge.outline:SetPoint("TOPRIGHT", -1, -1)
        badge.outline:SetVertexColor(0, 0, 0, 0.9)
        badge.icon = button:CreateTexture(nil, "OVERLAY", nil, 7)
        badge.icon:SetPoint("TOPRIGHT", -2, -2)
        for _, texture in ipairs({badge.outline, badge.icon}) do
            texture:SetTexture("Interface\\MerchantFrame\\UI-Merchant-RepairIcons")
            texture:SetTexCoord(0, 0.28125, 0, 0.5625)
        end
    end
    badge.icon:SetSize(size, size)
    badge.outline:SetSize(size + 2, size + 2)
    badge.outline:Show(); badge.icon:Show()
end

local function HookContainer(frame, bank)
    if frames[frame] then return end
    frames[frame] = true
    -- Hook existing instances: their mixin methods were copied before addon loading.
    local methods = bank and {"GenerateItemSlotsForSelectedTab", "RefreshAllItemsForSelectedTab", "UpdateSearchResults"}
        or {"UpdateItems", "UpdateSearchResults"}
    for _, method in ipairs(methods) do
        if type(frame[method]) == "function" then hooksecurefunc(frame, method, Schedule) end
    end
    frame:HookScript("OnShow", Schedule)
    frame:HookScript("OnHide", Schedule)
end

function addon.RefreshBagHints()
    HideBadges()
    if not OutOfCombat() or not addon.db then return end
    if type(hooksecurefunc) ~= "function" then return end
    local bankPanel = CharacterBankPanel()
    local hasBags = type(ContainerFrameUtil_EnumerateContainerFrames) == "function"
    if not hasBags and not bankPanel then return end
    if not tooltipHooked and TooltipDataProcessor and Enum and Enum.TooltipDataType
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function" and GameTooltip
        and addon.Read(GameTooltip.IsForbidden, GameTooltip) == false then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipHint)
        GameTooltip:HookScript("OnTooltipCleared", function() hinted = nil end)
        GameTooltip:HookScript("OnHide", function() hinted = nil end)
        tooltipHooked = true
    end
    local enabled = addon.BagHintsEnabled()
    local size = addon.BagHintSize()
    learned = enabled and addon.LearnedProfessions() or nil
    catalog = enabled and addon.Catalog() or nil
    if hasBags then
        for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
            if addon.Read(frame.IsForbidden, frame) == false and type(frame.EnumerateItems) == "function" then
                HookContainer(frame, false)
                if frame:IsShown() then
                    for _, button in frame:EnumerateItems() do RefreshButton(button, false, enabled, size) end
                end
            end
        end
    end
    if bankPanel and type(bankPanel.EnumerateValidItems) == "function" then
        HookContainer(bankPanel, true)
        if BankVisible() then
            for button in bankPanel:EnumerateValidItems() do RefreshButton(button, true, enabled, size) end
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
    "TRADE_SKILL_SHOW", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BANK_TABS_CHANGED", "PLAYERBANKSLOTS_CHANGED"}) do
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
