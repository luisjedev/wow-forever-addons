local _, addon = ...
addon = addon or {}

local WELL_FED_SPELL = 19705 -- any "Well Fed" spell; only its localized name is used
local WELL_FED_ICON = 136000 -- Spell_Misc_Food, shared by Well Fed buffs
local FIND_MINERALS_SPELL = 2580
local WELL_RESTED_SPELL = 429959 -- Cozy Sleeping Bag buff (+1% XP per stack)

-- Returns the ordered list of keys to show for a plain state table.
function addon.Missing(state)
    local list = {}
    if not state.wellFed then list[#list + 1] = "wellFed" end
    if state.canRest and not state.rested then list[#list + 1] = "rested" end
    if state.knowsMinerals and not state.minerals then list[#list + 1] = "minerals" end
    return list
end

if not CreateFrame then return addon end

local ICONS = {
    wellFed = WELL_FED_ICON,
    rested = C_Spell.GetSpellTexture(WELL_RESTED_SPELL) or 133662, -- 133662: the bag's item icon
    minerals = C_Spell.GetSpellTexture(FIND_MINERALS_SPELL) or "Interface\\Icons\\Spell_Nature_Earthquake",
}
local SIZE, GAP = 40, 6

local bar = CreateFrame("Frame", "MissingBuffsFrame", UIParent)
bar:SetPoint("CENTER", 0, 120)
bar:SetSize(SIZE, SIZE)
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", bar.StartMoving)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    MissingBuffsDB.point = { point, relativePoint, x, y }
end)
local placeholder = bar:CreateTexture(nil, "BACKGROUND")
placeholder:SetPoint("TOPLEFT", -4, 4)
placeholder:SetPoint("BOTTOMRIGHT", 4, -4)
placeholder:SetColorTexture(0, 0.6, 1, 0.35)
placeholder:Hide()
local unlocked = false
local icons = {}
for key, texture in pairs(ICONS) do
    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(SIZE, SIZE)
    icon:SetTexture(texture)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:Hide()
    icons[key] = icon
end

local function ReadState()
    local wellFedName = C_Spell.GetSpellName(WELL_FED_SPELL)
    local state = {
        canRest = UnitLevel("player") < GetMaxPlayerLevel(),
        rested = C_UnitAuras.GetPlayerAuraBySpellID(WELL_RESTED_SPELL) ~= nil,
        knowsMinerals = IsPlayerSpell(FIND_MINERALS_SPELL),
        minerals = C_UnitAuras.GetPlayerAuraBySpellID(FIND_MINERALS_SPELL) ~= nil,
    }
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        if issecretvalue and (issecretvalue(aura.icon) or issecretvalue(aura.name)) then return nil end
        if aura.icon == WELL_FED_ICON or aura.name == wellFedName then state.wellFed = true break end
    end
    return state
end

local function Layout(list)
    for _, icon in pairs(icons) do icon:Hide() end
    local width = #list * SIZE + math.max(#list - 1, 0) * GAP
    bar:SetWidth(math.max(width, SIZE))
    for i, key in ipairs(list) do
        icons[key]:SetPoint("LEFT", bar, "CENTER", -width / 2 + (i - 1) * (SIZE + GAP), 0)
        icons[key]:Show()
    end
end

local function Update()
    if unlocked then return Layout({ "wellFed", "rested", "minerals" }) end
    -- Aura data may be secret in combat; keep the last row until it ends.
    if InCombatLockdown() then return end
    local state = ReadState()
    if state then Layout(addon.Missing(state)) end
end

-- Called from the minimap addon list (## AddonCompartmentFunc): toggles the movable placeholder.
function MissingBuffs_OnCompartmentClick()
    unlocked = not unlocked
    bar:EnableMouse(unlocked)
    placeholder:SetShown(unlocked)
    Update()
end

bar:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= "MissingBuffs" then return end
        MissingBuffsDB = type(MissingBuffsDB) == "table" and MissingBuffsDB or {}
        local p = MissingBuffsDB.point
        if type(p) == "table" and type(p[1]) == "string" and tonumber(p[3]) and tonumber(p[4]) then
            bar:ClearAllPoints()
            bar:SetPoint(p[1], UIParent, p[2] or p[1], p[3], p[4])
        end
        return
    end
    Update()
end)
bar:RegisterEvent("ADDON_LOADED")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_LEVEL_UP", "SPELLS_CHANGED" }) do
    bar:RegisterEvent(event)
end
bar:RegisterUnitEvent("UNIT_AURA", "player")
