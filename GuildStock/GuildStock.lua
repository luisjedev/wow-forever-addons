local name, addon = ...
local L = addon.L

function addon.Accessible(value)
    return not canaccessvalue or canaccessvalue(value)
end

function addon.Integer(value, minimum, maximum)
    return addon.Accessible(value) and type(value) == "number" and value == value
        and value >= minimum and value <= maximum and value == math.floor(value)
end

-- Failed or restricted reads stay unknown. pcall is not used to declassify values.
function addon.Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and addon.Accessible(value) then return value end
end

local function ValidSnapshot(snapshot)
    if type(snapshot) ~= "table" or not addon.Integer(snapshot.observedAt, 0, time())
        or type(snapshot.items) ~= "table" then return false end
    for id, item in pairs(snapshot.items) do
        if not addon.Integer(id, 1, 2147483647) or type(item) ~= "table"
            or not addon.Integer(item.count, 1, 2147483647)
            or not addon.Integer(item.bound, 0, item.count) then return false end
    end
    return true
end
addon.ValidSnapshot = ValidSnapshot

function addon.Initialize()
    if addon.db then return end
    if GuildStockDB == nil then GuildStockDB = { version = 1 } end
    local saved = GuildStockDB
    if type(saved) ~= "table" or saved.version ~= 1 then
        addon.temporary = true
        addon.db = { version = 1 }
    else
        addon.db = saved
        if ValidSnapshot(saved.own) then addon.snapshot = saved.own end
    end
    addon.ResetInventory()
    addon.ApplyLanguage(type(addon.db.settings) == "table" and addon.db.settings.language or nil)
end

function addon.IsItemHidden(id)
    return type(addon.db.hiddenItems) == "table" and addon.db.hiddenItems[id] == true
end

function addon.IsSharingEnabled()
    if not addon.db or addon.temporary then return false end
    local settings = addon.db.settings
    return settings == nil or (type(settings) == "table"
        and (settings.shareInventory == nil or settings.shareInventory == true))
end

function addon.SetSharingEnabled(enabled)
    if not addon.db or addon.temporary or type(enabled) ~= "boolean" then return end
    if addon.db.settings == nil then addon.db.settings = {} end
    if type(addon.db.settings) ~= "table" then return end
    addon.db.settings.shareInventory = enabled
    if addon.SyncChanged then addon.SyncChanged() end
end

function addon.SetItemHidden(id, hidden)
    if not addon.IsSharingEnabled() then return end
    if not addon.Integer(id, 1, 2147483647) or type(hidden) ~= "boolean" then return end
    if addon.db.hiddenItems == nil then addon.db.hiddenItems = {} end
    if type(addon.db.hiddenItems) ~= "table" then return end -- Preserve unsupported saved data.
    addon.db.hiddenItems[id] = hidden or nil
    if addon.SyncChanged then addon.SyncChanged() end
end

-- GUILD inventory senders build from this copy at send time, never db.own.
-- Local observations retain all bag contents; hidden IDs and quantities never enter this copy.
function addon.ShareableSnapshot()
    if not addon.db or addon.temporary
        or (addon.db.hiddenItems ~= nil and type(addon.db.hiddenItems) ~= "table") then return nil end
    for id, hidden in pairs(addon.db.hiddenItems or {}) do
        if not addon.Integer(id, 1, 2147483647) or type(hidden) ~= "boolean" then return nil end
    end
    local settings = addon.db.settings
    if settings ~= nil and (type(settings) ~= "table"
        or (settings.shareInventory ~= nil and type(settings.shareInventory) ~= "boolean")) then return nil end
    -- An explicit opt-out withdraws old stock even before bags can be read.
    if not addon.IsSharingEnabled() then return {items = {}, observedAt = time()} end
    if not addon.snapshot then return nil end
    local result = {items = {}, observedAt = addon.snapshot.observedAt}
    for id, item in pairs(addon.snapshot.items) do
        if not addon.IsItemHidden(id) then
            result.items[id] = {count = item.count, bound = item.bound}
        end
    end
    return result
end

-- Complete observations only; saved history never authorizes membership or presence.
function addon.GuildCharacters(search)
    local result, data = {}, addon.guildData
    local guild = addon.Read(C_Club and C_Club.GetGuildClubId)
    if not guild or type(data) ~= "table" or data.guildID ~= guild or type(data.characters) ~= "table" then return result end
    search = (search or ""):lower()
    for id, character in pairs(data.characters) do
        local member = addon.SyncMember and addon.SyncMember(id)
        if type(id) == "string" and type(character) == "table" and addon.Accessible(character.name)
            and type(character.name) == "string" and character.name ~= "" and ValidSnapshot(character.snapshot)
            and (not addon.SyncMember or (member and not member.isSelf
                and (character.memberID == nil or character.memberID == member.id)))
            and character.name:lower():find(search, 1, true) then
            result[#result + 1] = {id = id, name = character.name:gsub("|", "||"), snapshot = character.snapshot,
                skills = character.skills, online = member and member.online, offline = member and member.offline,
                race = member and member.race, receivedAt = character.receivedAt}
        end
    end
    table.sort(result, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    return result
end

function addon.MaterialOwners(id, showOffline)
    local result = {}
    for _, character in ipairs(addon.GuildCharacters("")) do
        if character.snapshot.items[id] and (showOffline or character.online) then
            result[#result + 1] = character
        end
    end
    table.sort(result, function(a, b)
        if a.online ~= b.online then return a.online == true end
        return a.name < b.name
    end)
    return result
end

function addon.WhisperCharacter(id)
    local member = addon.SyncMember and addon.SyncMember(id)
    if member and not member.isSelf and member.online and ChatFrameUtil and ChatFrameUtil.SendTell then
        ChatFrameUtil.SendTell(id) -- Native draft only; no ordinary or addon message is submitted.
    end
end

-- Both bags and purchased character-bank tabs use the same complete-read checks.
local function ScanContainer(bag, slots, items)
    local api = C_Container
    local free = addon.Read(api.GetContainerNumFreeSlots, bag)
    if not addon.Integer(free, 0, slots) then return end
    local occupied = 0
    for slot = 1, slots do
        if type(api.GetContainerItemInfo) ~= "function" then return end
        local ok, info = pcall(api.GetContainerItemInfo, bag, slot)
        if not ok or not addon.Accessible(info) then return end
        if info ~= nil then
            if type(info) ~= "table" or not addon.Integer(info.itemID, 1, 2147483647)
                or not addon.Integer(info.stackCount, 1, 2147483647)
                or not addon.Accessible(info.isBound) or type(info.isBound) ~= "boolean"
                or not addon.Accessible(info.isLocked) or info.isLocked ~= false then return end
            occupied = occupied + 1
            local item = items[info.itemID] or {count = 0, bound = 0}
            item.count = item.count + info.stackCount
            if not addon.Integer(item.count, 1, 2147483647) then return end
            if info.isBound then item.bound = item.bound + info.stackCount end
            items[info.itemID] = item
        end
    end
    return occupied + free == slots -- A nil occupied slot is not zero stock.
end

function addon.ScanBags()
    local api = C_Container
    local constants = Constants and Constants.InventoryConstants
    if not api or not constants or not Enum or not Enum.BagIndex then return nil end
    local bags, reagent = constants.NumBagSlots, constants.NumReagentBagSlots
    if not addon.Integer(bags, 0, 5) or not addon.Integer(reagent, 0, 1)
        or bags + reagent > Enum.BagIndex.ReagentBag then return nil end
    local items = {}
    for bag = Enum.BagIndex.Backpack, bags + reagent do
        local slots = addon.Read(api.GetContainerNumSlots, bag)
        if not addon.Integer(slots, bag == Enum.BagIndex.Backpack and 1 or 0, 200) then return nil end
        if slots == 0 then
            local inventorySlot = addon.Read(api.ContainerIDToInventoryID, bag)
            if not addon.Integer(inventorySlot, 1, 100) or type(GetInventoryItemID) ~= "function" then return nil end
            local ok, equipped = pcall(GetInventoryItemID, "player", inventorySlot)
            if not ok or not addon.Accessible(equipped) or equipped ~= nil then return nil end
        elseif not ScanContainer(bag, slots, items) then
            return nil
        end
    end
    return {items = items, observedAt = time()}
end

local bankOpen, allCounts, previousBags, previousBank
local observedIDs, dirty = {}, {}
function addon.ResetInventory()
    local known = addon.db.knownMaterials
    if known == nil then known = {}; addon.db.knownMaterials = known end
    local valid = type(known) == "table"
    if valid then
        for id, value in pairs(known) do
            if not addon.Integer(id, 1, 2147483647) or value ~= true then valid = false; break end
        end
    end
    -- Keep unsupported saved data intact; new discoveries can still work in RAM.
    addon.knownMaterials = valid and known or {}
    bankOpen, allCounts, previousBags, previousBank = false, true, nil, nil
    observedIDs, dirty = {}, {}
end

local function CharacterTab(id)
    local index = Enum and Enum.BagIndex
    return index and addon.Integer(index.CharacterBankTab_1, 0, 100)
        and addon.Integer(index.CharacterBankTab_9, index.CharacterBankTab_1, 100)
        and addon.Integer(id, index.CharacterBankTab_1, index.CharacterBankTab_9)
end

local function ScanBank()
    local bankType = Enum and Enum.BankType and Enum.BankType.Character
    if bankType == nil or not C_Container then return end
    local visible = addon.Read(C_Bank and C_Bank.CanViewBank, bankType)
    if visible == false then return {} end -- An account-only visit is outside our scope.
    if visible ~= true then return end
    local tabs = addon.Read(C_Bank and C_Bank.FetchPurchasedBankTabData, bankType)
    if type(tabs) ~= "table" then return end
    local items, seenTabs = {}, {}
    for _, tab in pairs(tabs) do
        if not addon.Accessible(tab) or type(tab) ~= "table" or not CharacterTab(tab.ID) or seenTabs[tab.ID] then return end
        seenTabs[tab.ID] = true
        local slots = addon.Read(C_Container.GetContainerNumSlots, tab.ID)
        if not addon.Integer(slots, 1, 200) or not ScanContainer(tab.ID, slots, items) then return end
    end
    return items
end

local function Remember(items)
    local catalog = addon.Catalog({items = items})
    for id in pairs(items) do
        observedIDs[id] = true
        if type(catalog[id]) == "table" and not addon.knownMaterials[id] then
            addon.knownMaterials[id], dirty[id] = true, true
        end
    end
end

-- Metadata and recipe discovery only refresh IDs actually observed on this character.
function addon.InventoryMaterialLoaded(id)
    if observedIDs[id] then dirty[id] = true; addon.ScheduleScan() end
end

local function MarkChanged(before, after)
    for id, item in pairs(before or {}) do
        local current = after[id]
        if not current or current.count ~= item.count or current.bound ~= item.bound then dirty[id] = true end
    end
    for id, item in pairs(after) do
        local old = before and before[id]
        if not old or old.count ~= item.count or old.bound ~= item.bound then dirty[id] = true end
    end
end

function addon.ScanInventory()
    local bags = addon.ScanBags()
    if not bags then return end
    if not previousBags and addon.snapshot then Remember(addon.snapshot.items) end
    Remember(bags.items)
    MarkChanged(previousBags, bags.items)
    local bank
    if bankOpen then
        bank = ScanBank()
        if not bank then return end
        Remember(bank)
        MarkChanged(previousBank, bank)
    end
    for id in pairs(dirty) do
        if observedIDs[id] then Remember({[id] = true}) end
    end
    local items = {}
    for id, item in pairs(bags.items) do items[id] = item end
    for id in pairs(addon.knownMaterials) do
        local carried = items[id]
        local old = addon.snapshot and addon.snapshot.items[id]
        if allCounts or dirty[id] then
            local minimum = (carried and carried.count or 0) + (bank and bank[id] and bank[id].count or 0)
            local count = addon.Read(C_Item and C_Item.GetItemCount, id, true, false, false, false)
            if not addon.Integer(count, minimum, 2147483647) then return end
            -- bound is a confirmed minimum from carried bags, not a tradeability calculation.
            items[id] = count > 0 and {count = count, bound = carried and carried.bound or 0} or nil
        else
            items[id] = old
        end
    end
    -- Keep the carried observation separate from the absolute native totals.
    previousBags = bags.items
    previousBank, dirty, allCounts = bank or previousBank, {}, false
    return {items = items, observedAt = time()}
end

function addon.Observe()
    if not addon.db then return end
    local snapshot
    if not InCombatLockdown() then snapshot = addon.ScanInventory() end
    addon.incomplete = snapshot == nil
    if snapshot then
        addon.snapshot = snapshot
        addon.db.own = snapshot
    end
    if addon.SyncChanged then addon.SyncChanged() end
    if addon.Refresh then addon.Refresh() end
end

function addon.ProfessionNames()
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return L["Unavailable"] end
    local result = { pcall(GetProfessions) }
    if not result[1] then return L["Unavailable"] end
    local names = {}
    -- There are five optional returns; ipairs would stop at an unlearned profession.
    for i = 2, 6 do
        local index = result[i]
        if not addon.Accessible(index) then return L["Unavailable"] end
        if index ~= nil then
            if not addon.Integer(index, 1, 1000) then return L["Unavailable"] end
            local profession = addon.Read(GetProfessionInfo, index)
            if type(profession) ~= "string" then return L["Unavailable"] end
            names[#names + 1] = profession:gsub("|", "||")
        end
    end
    return #names > 0 and table.concat(names, ", ") or "—"
end

local refreshScheduled = false
function addon.ScheduleRefresh()
    if refreshScheduled then return end
    refreshScheduled = true
    C_Timer.After(0.05, function()
        refreshScheduled = false
        if addon.Refresh then addon.Refresh() end
    end)
end

local scheduled = false
function addon.ScheduleScan()
    if scheduled then return end
    scheduled = true
    C_Timer.After(0.5, function()
        scheduled = false
        addon.Observe()
    end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
    "PLAYER_REGEN_ENABLED", "ITEM_LOCK_CHANGED", "ITEM_COUNT_CHANGED", "BAG_UPDATE",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BANK_TABS_CHANGED", "PLAYERBANKSLOTS_CHANGED", "SKILL_LINES_CHANGED", "GET_ITEM_INFO_RECEIVED", "PLAYER_GUILD_UPDATE" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, loadedName, success)
    if event == "ADDON_LOADED" then
        if loadedName == name then addon.Initialize() end
    elseif event == "PLAYER_LOGIN" then
        addon.Initialize()
        addon.RegisterProbe()
        addon.CreateMinimapButton()
        addon.ScheduleScan()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if addon.Integer(loadedName, 1, 2147483647) and addon.Accessible(success) and success == true
            and addon.itemData[loadedName] ~= nil then
            addon.InventoryMaterialLoaded(loadedName)
            addon.itemData[loadedName] = nil
            addon.InvalidateMaterials()
            addon.ScheduleRefresh()
        end
    elseif event == "ITEM_COUNT_CHANGED" then
        if addon.Integer(loadedName, 1, 2147483647) then
            -- A material can move out of bags before the coalesced slot scan runs.
            observedIDs[loadedName], dirty[loadedName] = true, true
            addon.ScheduleScan()
        end
    elseif event == "BANKFRAME_OPENED" then
        bankOpen = true
        addon.ScheduleScan()
    elseif event == "BANKFRAME_CLOSED" then
        bankOpen = false
        for id in pairs(previousBank or {}) do dirty[id] = true end
        addon.ScheduleScan()
    elseif event == "BAG_UPDATE" then
        if bankOpen and CharacterTab(loadedName) then addon.ScheduleScan() end
    elseif event == "BANK_TABS_CHANGED" or event == "PLAYERBANKSLOTS_CHANGED" then
        if bankOpen then addon.ScheduleScan() end
    elseif event == "SKILL_LINES_CHANGED" or event == "PLAYER_GUILD_UPDATE" then
        if addon.Refresh then addon.Refresh() end
    else
        if event == "PLAYER_ENTERING_WORLD" then allCounts = true end
        addon.ScheduleScan()
    end
end)
