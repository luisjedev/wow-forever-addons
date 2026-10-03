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
    addon.ApplyLanguage(type(addon.db.settings) == "table" and addon.db.settings.language or nil)
end

function addon.IsItemHidden(id)
    return type(addon.db.hiddenItems) == "table" and addon.db.hiddenItems[id] == true
end

function addon.SetItemHidden(id, hidden)
    if not addon.Integer(id, 1, 2147483647) or type(hidden) ~= "boolean" then return end
    if addon.db.hiddenItems == nil then addon.db.hiddenItems = {} end
    if type(addon.db.hiddenItems) ~= "table" then return end -- Preserve unsupported saved data.
    addon.db.hiddenItems[id] = hidden or nil
    if addon.SyncChanged then addon.SyncChanged() end
end

-- GUILD inventory senders build from this copy at send time, never db.own.
-- Local observations retain all bag contents; hidden IDs and quantities never enter this copy.
function addon.ShareableSnapshot()
    if not addon.db or not addon.snapshot or addon.temporary
        or (addon.db.hiddenItems ~= nil and type(addon.db.hiddenItems) ~= "table") then return nil end
    for id, hidden in pairs(addon.db.hiddenItems or {}) do
        if not addon.Integer(id, 1, 2147483647) or type(hidden) ~= "boolean" then return nil end
    end
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
        else
            local free = addon.Read(api.GetContainerNumFreeSlots, bag)
            if not addon.Integer(free, 0, slots) then return nil end
            local occupied = 0
            for slot = 1, slots do
                if type(api.GetContainerItemInfo) ~= "function" then return nil end
                local ok, info = pcall(api.GetContainerItemInfo, bag, slot)
                if not ok or not addon.Accessible(info) then return nil end
                if info ~= nil then
                    if type(info) ~= "table" or not addon.Integer(info.itemID, 1, 2147483647)
                        or not addon.Integer(info.stackCount, 1, 2147483647)
                        or not addon.Accessible(info.isBound) or type(info.isBound) ~= "boolean"
                        or not addon.Accessible(info.isLocked) or info.isLocked ~= false then return nil end
                    occupied = occupied + 1
                    local item = items[info.itemID] or { count = 0, bound = 0 }
                    item.count = item.count + info.stackCount
                    if not addon.Integer(item.count, 1, 2147483647) then return nil end
                    if info.isBound then item.bound = item.bound + info.stackCount end
                    items[info.itemID] = item
                end
            end
            -- A nil occupied slot is not an observation of zero stock.
            if occupied + free ~= slots then return nil end
        end
    end
    return { items = items, observedAt = time() }
end

function addon.Observe()
    if not addon.db then return end
    local snapshot
    if not InCombatLockdown() then snapshot = addon.ScanBags() end
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
    "PLAYER_REGEN_ENABLED", "ITEM_LOCK_CHANGED", "SKILL_LINES_CHANGED", "GET_ITEM_INFO_RECEIVED", "PLAYER_GUILD_UPDATE" }) do
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
            addon.itemData[loadedName] = nil
            addon.InvalidateMaterials()
            addon.ScheduleRefresh()
        end
    elseif event == "SKILL_LINES_CHANGED" or event == "PLAYER_GUILD_UPDATE" then
        if addon.Refresh then addon.Refresh() end
    else
        addon.ScheduleScan()
    end
end)
