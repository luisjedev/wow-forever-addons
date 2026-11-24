local _, addon = ...
addon = addon or {}

local WELL_FED_SPELL = 19705 -- any "Well Fed" spell; only its localized name is used
local WELL_FED_ICON = 136000 -- Spell_Misc_Food, shared by Well Fed buffs
local FIND_MINERALS_SPELL = 2580

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
    rested = "Interface\\Icons\\Spell_Nature_Sleep",
    minerals = C_Spell.GetSpellTexture(FIND_MINERALS_SPELL) or "Interface\\Icons\\Spell_Nature_Earthquake",
}
local SIZE, GAP = 40, 6

local bar = CreateFrame("Frame", "MissingBuffsFrame", UIParent)
bar:SetPoint("CENTER", 0, 120)
bar:SetSize(SIZE, SIZE)
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
        rested = (GetXPExhaustion() or 0) > 0,
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

local function Update()
    -- Aura data may be secret in combat; keep the last row until it ends.
    if InCombatLockdown() then return end
    local state = ReadState()
    if not state then return end
    for _, icon in pairs(icons) do icon:Hide() end
    local list = addon.Missing(state)
    local width = #list * SIZE + math.max(#list - 1, 0) * GAP
    for i, key in ipairs(list) do
        icons[key]:SetPoint("LEFT", bar, "CENTER", -width / 2 + (i - 1) * (SIZE + GAP), 0)
        icons[key]:Show()
    end
end

bar:SetScript("OnEvent", Update)
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "UPDATE_EXHAUSTION", "PLAYER_XP_UPDATE",
    "PLAYER_LEVEL_UP", "SPELLS_CHANGED" }) do
    bar:RegisterEvent(event)
end
bar:RegisterUnitEvent("UNIT_AURA", "player")
