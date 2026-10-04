-- Isolated native-bag fixtures; no client, network, or SavedVariables files are accessed.
local combat, callbacks, frames, timers = false, {}, {}, {}
local secret = setmetatable({}, {__tostring = function() error("inaccessible value") end})
canaccessvalue = function(value) return value ~= secret end
InCombatLockdown = function() return combat end
GetLocale = function() return "enUS" end
C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
local function Drain()
    local pending = timers; timers = {}
    for _, callback in ipairs(pending) do callback() end
end
local methods = {}
function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:HookScript(key, fn)
    local old = self.scripts[key]
    self.scripts[key] = function(...) if old then old(...) end; fn(...) end
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:IsForbidden() return self.forbidden or false end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:GetBagID() return self.bag end
function methods:GetID() return self.slot end
function methods:GetOwner() return self.owner end
function methods:GetProcessingTooltipInfo() return self.info end
function methods:EnumerateItems() return ipairs(self.items) end
function methods:UpdateItems() self.updates = (self.updates or 0) + 1 end
function methods:UpdateSearchResults() self.searches = (self.searches or 0) + 1 end
function methods:AddLine(text) self.lines[#self.lines + 1] = text end
local function Frame()
    return setmetatable({shown = true, scripts = {}, events = {}, textures = {}, lines = {}}, {__index = methods})
end
function methods:CreateTexture()
    assert(combat == false, "never allocate bag artwork in combat")
    local texture = Frame(); self.textures[#self.textures + 1] = texture
    return texture
end
CreateFrame = function() local f = Frame(); frames[#frames + 1] = f; return f end
hooksecurefunc = function(object, key, callback)
    local old = object[key]
    object[key] = function(...) old(...); callback(...) end
end
GameTooltip = Frame()
Enum = {TooltipDataType = {Item = 0}, Profession = {Mining = 1, Engineering = 2, Cooking = 3}}
Constants = {InventoryConstants = {NumBagSlots = 4, NumReagentBagSlots = 1}}
TooltipDataProcessor = {AddTooltipPostCall = function(kind, callback)
    assert(kind == Enum.TooltipDataType.Item); callbacks[#callbacks + 1] = callback
end}
local bags = {[0] = {{itemID = 10}, {itemID = 20}}, [5] = {{itemID = 10}}, [6] = {{itemID = 10}}}
C_Container = {GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end}
GetProfessions = function() return 1, 2, nil, nil, 3 end
GetProfessionInfo = function(index) return "Localized name", nil, nil, nil, nil, nil, index end
C_TradeSkillUI = {GetProfessionInfoBySkillLineID = function(id) return {profession = id} end}
local addon = {}
for _, file in ipairs({"Locales", "GuildStock", "Catalog", "Bags"}) do
    assert(loadfile("GuildStock/" .. file .. ".lua"))("GuildStock", addon)
end
local function Event(event)
    -- Exercise only this module's registered events; core behavior has its own suite.
    local listener = frames[#frames]
    if listener.events[event] then listener.scripts.OnEvent(listener, event) end
end
local function Button(bag, slot)
    local button = Frame(); button.bag, button.slot = bag, slot
    button.scripts.OnClick = function() end
    return button
end
local first, second, reagent, bank = Button(0, 1), Button(0, 2), Button(5, 1), Button(6, 1)
local individual, combined = Frame(), Frame()
individual.items, combined.items = {first, second}, {reagent, bank}
combined:Hide()
local containers = {individual, combined}
local function Enumerate() return ipairs(containers) end
local function Visible(button)
    if #button.textures == 0 then return false end
    assert(button.textures[1]:IsShown() == button.textures[2]:IsShown(), "outline follows the badge")
    return button.textures[2]:IsShown()
end
local function Tooltip(owner, id, getter, append)
    GameTooltip.owner, GameTooltip.lines = owner, {}
    GameTooltip.info = {getterName = getter or "GetBagItem", append = append}
    GameTooltip:Show()
    if GameTooltip.scripts.OnTooltipCleared then GameTooltip.scripts.OnTooltipCleared(GameTooltip) end
    for _, callback in ipairs(callbacks) do callback(GameTooltip, {id = id}) end
    return GameTooltip.lines
end

Event("PLAYER_LOGIN"); Drain()
assert(#callbacks == 0 and not addon.BagHintsEnabled(), "startup before initialization is harmless")
local saved = {version = 1, catalog = {[10] = {Mining = true, Engineering = true, Cooking = true, Alchemy = true}, [20] = {}},
    favorites = {[10] = true}, hiddenItems = {[10] = true}, settings = {scale = 0.9}}
addon.db = saved
Event("PLAYER_LOGIN"); Drain()
assert(#callbacks == 0, "native bags may not be loaded yet")
ContainerFrameUtil_EnumerateContainerFrames = Enumerate
combat = true; Event("ADDON_LOADED"); Drain()
assert(#callbacks == 0 and #first.textures == 0, "attachment defers during combat")
combat = false; Event("PLAYER_REGEN_ENABLED"); Drain()
assert(#callbacks == 1 and Visible(first) and not Visible(second))
assert(saved.settings.bagHints == nil and saved.settings.scale == 0.9 and saved.favorites[10] and saved.hiddenItems[10],
    "defaults do not rewrite settings; sharing exclusions do not hide personal hints")
assert(addon.BagHintSize() == 14 and saved.settings.bagHintSize == nil and first.textures[2].width == 14,
    "existing characters receive the smaller default without rewriting preferences")
for _, size in ipairs({10, 24, 14}) do
    saved.settings.bagHintSize = size; addon.RefreshBagHints()
    assert(first.textures[2].width == size and first.textures[2].height == size
        and first.textures[1].width == size + 2 and #first.textures == 2, "resize existing artwork and outline together")
end
for _, invalid in ipairs({9, 25, 14.5, "18", false, 0/0, math.huge, secret}) do
    saved.settings.bagHintSize = invalid; addon.RefreshBagHints()
    assert(addon.BagHintSize() == 14 and first.textures[2].width == 14, "invalid sizes fall back safely")
    assert(rawequal(saved.settings.bagHintSize, invalid) or invalid ~= invalid, "invalid preferences are preserved")
end
saved.settings.bagHintSize = 18
combat = true; addon.RefreshBagHints()
assert(not Visible(first) and first.textures[2].width == 14, "size changes defer in combat")
combat = false; Event("PLAYER_REGEN_ENABLED"); Drain()
assert(Visible(first) and first.textures[2].width == 18)
saved.settings.bagHintSize = nil; addon.RefreshBagHints()
local nativeClick, nativeUpdate = first.scripts.OnClick, individual.updates
local lines = Tooltip(first, 10)
assert(#lines == 1 and lines[1]:find("Useful for:", 1, true) and lines[1]:find("|TInterface\\Icons\\Trade_Mining:16:16:0:0|t Mining", 1, true))
assert(lines[1]:find("Engineering", 1, true) and lines[1]:find("Cooking", 1, true) and not lines[1]:find("Alchemy", 1, true))
callbacks[1](GameTooltip, {id = 10}); assert(#lines == 1, "repeated callback cannot duplicate the line")
assert(#Tooltip(first, 20) == 0 and #Tooltip(first, secret) == 0 and #Tooltip(first, 10, "GetItemByID") == 0)
assert(#Tooltip(first, 10, "GetBagItem", true) == 0 and #Tooltip(Frame(), 10) == 0)
assert(#Tooltip(second, 20) == 0, "unknown relationships have no negative or invented hint")

-- Recycling, sorting, empty slots and search must never retain another item's badge.
bags[0][1], bags[0][2] = bags[0][2], bags[0][1]
individual:UpdateItems(); individual:UpdateItems()
assert(#timers == 1, "native update bursts coalesce")
Drain(); assert(not Visible(first) and Visible(second))
bags[0][2].isFiltered = true; individual:UpdateSearchResults(); Drain()
assert(not Visible(second) and #Tooltip(second, 10) == 0)
bags[0][2].isFiltered = false; individual:UpdateSearchResults(); Drain(); assert(Visible(second))
bags[0][2] = nil; individual:UpdateItems(); Drain(); assert(not Visible(second))
bags[0][1] = {itemID = 10}; individual:UpdateItems(); Drain(); assert(Visible(first))
for _, value in ipairs({secret, {itemID = secret}, {itemID = 10, isFiltered = secret}}) do
    bags[0][1] = value; individual:UpdateItems(); Drain(); assert(not Visible(first))
end
bags[0][1] = {itemID = 10}
first.bag = secret; addon.RefreshBagHints(); assert(not Visible(first))
first.bag = 0; first.slot = secret; addon.RefreshBagHints(); assert(not Visible(first))
first.slot = 1
combined:Show(); Drain()
assert(Visible(reagent) and not Visible(bank) and #Tooltip(bank, 10) == 0, "only carried bags, including reagent bags")
individual:Hide(); addon.RefreshBagHints(); assert(not Visible(first))
individual:Show(); Drain(); assert(Visible(first))

saved.settings.bagHints = false; Tooltip(first, 10); addon.BagHintsChanged()
assert(not Visible(first) and not Visible(reagent) and #Tooltip(first, 10) == 0)
saved.settings.bagHintSize = 12; addon.RefreshBagHints()
assert(not Visible(first), "resizing cannot enable disabled hints")
saved.settings.bagHints = true; addon.BagHintsChanged(); Tooltip(first, 10)
assert(first.textures[2].width == 12 and reagent.textures[2].width == 12, "re-enabled hints use the saved size")
saved.settings.bagHints = false; addon.BagHintsChanged()
assert(not GameTooltip:IsShown(), "disabling removes an already visible hint")
local originalSettings = saved.settings
for _, value in ipairs({"unsupported", {bagHints = "unsupported"}}) do
    saved.settings = value; addon.BagHintsChanged()
    assert(saved.settings == value and not Visible(first) and not addon.BagHintsEnabled())
end
saved.settings = originalSettings; saved.settings.bagHints = true
addon.temporary = true; addon.BagHintsChanged(); assert(not Visible(first))
addon.temporary = nil; addon.BagHintsChanged(); assert(Visible(first))

-- Complete profession changes clear badges even with the addon window closed.
GetProfessions = function() return nil, nil, nil, nil, 3 end
Event("SKILL_LINES_CHANGED"); Drain()
lines = Tooltip(first, 10)
assert(#lines == 1 and lines[1]:find("Cooking", 1, true) and not lines[1]:find("Mining", 1, true))
GetProfessions = function() return end
Event("SKILL_LINES_CHANGED"); Drain(); assert(not Visible(first) and #Tooltip(first, 10) == 0)
GetProfessions = function() return secret end
Event("SKILL_LINES_CHANGED"); Drain(); assert(not Visible(first))
GetProfessions = function() return 1 end
Event("SKILL_LINES_CHANGED"); Drain(); assert(Visible(first))
saved.catalog[10] = secret; addon.BagHintsChanged(); assert(not Visible(first))
saved.catalog[10] = {Mining = secret}; addon.BagHintsChanged(); assert(not Visible(first))
saved.catalog[10] = {}; addon.BagHintsChanged(); assert(not Visible(first))
saved.catalog[10].Mining = true
Event("TRADE_SKILL_LIST_UPDATE"); Drain(); assert(Visible(first), "new discoveries become visible")

Tooltip(first, 10); combat = true; Event("PLAYER_REGEN_DISABLED")
assert(not Visible(first) and not GameTooltip:IsShown() and #Tooltip(first, 10) == 0)
individual:UpdateItems(); Drain(); assert(not Visible(first))
combat = false; Event("PLAYER_REGEN_ENABLED"); Drain(); assert(Visible(first))
combat = secret; addon.RefreshBagHints(); assert(not Visible(first))
combat = false
local late = Frame(); late.items = {Button(0, 1)}; containers[#containers + 1] = late
Event("BAG_OPEN"); Drain(); assert(Visible(late.items[1]))
Event("ADDON_LOADED"); Drain(); assert(#callbacks == 1 and #first.textures == 2, "hooks and artwork are reused")
assert(first.scripts.OnClick == nativeClick and individual.updates > (nativeUpdate or 0), "native clicks and updates are preserved")
local forbidden = Frame(); forbidden.forbidden = true
forbidden.EnumerateItems = function() error("forbidden container read") end
containers[#containers + 1] = forbidden
local forbiddenButton = Button(0, 1); forbiddenButton.forbidden = true
forbiddenButton.GetBagID = function() error("forbidden button read") end
late.items[#late.items + 1] = forbiddenButton
addon.RefreshBagHints()
assert(#forbiddenButton.textures == 0)
GameTooltip.forbidden = true; assert(#Tooltip(first, 10) == 0)
GameTooltip.forbidden = false
addon.ApplyLanguage("esES"); lines = Tooltip(first, 10)
assert(lines[1]:find("Útil para:", 1, true) and lines[1]:find("Minería", 1, true))

print("GuildStock: native bag hints, tooltips, preferences and restricted reads OK")
