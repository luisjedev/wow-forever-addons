local _, addon = ...
local L = addon.L
local window, scroll, content, text, note, page

local function Label(parent, value, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end

local function DiagnosticText()
    local version, build, _, interface = GetBuildInfo()
    local lines = {}
    local function Line(key, value)
        lines[#lines + 1] = L[key] .. ": " .. tostring(value or L["Not tested"])
    end
    Line("Build", version .. "." .. build)
    Line("Interface", interface)
    local restricted = addon.Read(C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)
    Line("Outgoing messages restricted", restricted == nil and L["Unavailable"] or (restricted and L["Yes"] or L["No"]))
    Line("Prefix registration", addon.probe.registration)
    Line("Last GUILD send", addon.probe.GUILD)
    Line("Last WHISPER send", addon.probe.WHISPER)
    Line("Received guild probes", addon.probe.received)
    Line("Confirmed round trips", addon.probe.confirmed)
    Line("Unmatched senders", addon.probe.unmatched)
    Line("Professions", addon.ProfessionNames())
    lines[#lines + 1] = "\n" .. L["No inventory is transmitted by this prototype."]
    return table.concat(lines, "\n\n")
end

function addon.Refresh()
    if not window or not window:IsShown() then return end
    local lines = {}
    if page == "diagnostics" then
        text:SetText(DiagnosticText())
    else
        local snapshot = addon.snapshot
        if snapshot then
            local ids = {}
            for id in pairs(snapshot.items) do ids[#ids + 1] = id end
            table.sort(ids)
            for _, id in ipairs(ids) do
                local item = snapshot.items[id]
                local itemName = addon.itemNames[id]
                if itemName == nil then
                    itemName = addon.Read(C_Item and C_Item.GetItemInfo, id)
                    -- GetItemInfo requests uncached data; do not repeat failed requests on every refresh.
                    addon.itemNames[id] = type(itemName) == "string" and itemName or false
                end
                if type(itemName) ~= "string" then itemName = L["Item"] .. " #" .. id end
                lines[#lines + 1] = string.format("%s  —  %s: %d  (%s: %d)",
                    itemName:gsub("|", "||"), L["Bags"], item.count, L["Bound"], item.bound)
            end
            if #ids == 0 then lines[1] = L["Bags are empty."] end
            lines[#lines + 1] = "\n" .. string.format(L["Observed: %s"], date("%Y-%m-%d %H:%M:%S", snapshot.observedAt))
        else
            lines[1] = L["No complete bag observation yet."]
        end
        if addon.incomplete then lines[#lines + 1] = "\n" .. L["Incomplete bag read; retaining the previous observation."] end
        if addon.temporary then lines[#lines + 1] = "\n" .. L["Saved data is unsupported; using temporary data without replacing it."] end
        text:SetText(table.concat(lines, "\n\n"))
    end
    note:SetText(page == "diagnostics" and L["API prototype"] or L["All bag items; profession catalog pending validation."])
    content:SetHeight(math.max(1, text:GetStringHeight() + 16))
    scroll:UpdateScrollChildRect()
    scroll.ScrollBar:SetValue(math.min(scroll.ScrollBar:GetValue(), scroll:GetVerticalScrollRange()))
end

local function CreateWindow()
    window = CreateFrame("Frame", "GuildStockFrame", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(700, 480)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window.TitleText:SetText("GuildStock · " .. L["API prototype"])
    UISpecialFrames[#UISpecialFrames + 1] = "GuildStockFrame"
    for i, tab in ipairs({ { "My bags", "bags" }, { "Diagnostics", "diagnostics" } }) do
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(160, 26)
        button:SetPoint("TOPLEFT", 18 + (i - 1) * 170, -35)
        button:SetText(L[tab[1]])
        button:SetScript("OnClick", function()
            page = tab[2]
            scroll.ScrollBar:SetValue(0)
            addon.Refresh()
        end)
    end
    note = Label(window, "", 18, -75)
    note:SetWidth(655)
    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -112)
    scroll:SetPoint("BOTTOMRIGHT", -36, 18)
    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(635)
    content:SetHeight(1)
    text = Label(content, "", 0, -4)
    text:SetWidth(625)
    text:SetJustifyV("TOP")
    scroll:SetScrollChild(content)
    window:SetScript("OnShow", addon.Refresh)
    page = "bags"
end

local function Toggle()
    if not addon.db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

function addon.CreateMinimapButton()
    local button = CreateFrame("Button", "GuildStockMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    button:RegisterForClicks("LeftButtonUp")
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Crate_01")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local function Position()
        local angle = addon.db.minimapAngle
        if not addon.Accessible(angle) or type(angle) ~= "number" or angle ~= angle or math.abs(angle) == math.huge then return end
        local width, height = Minimap:GetWidth(), Minimap:GetHeight()
        if not addon.Accessible(width) or not addon.Accessible(height) then return end
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * (width / 2 + 8), math.sin(angle) * (height / 2 + 8))
    end
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            if not addon.Accessible(x) or not addon.Accessible(y) or not addon.Accessible(cx)
                or not addon.Accessible(cy) or not addon.Accessible(scale) then return end
            if not cx or not cy then return end
            x, y = x / scale - cx, y / scale - cy
            if x == 0 and y == 0 then return end
            addon.db.minimapAngle = math.atan2(y, x)
            Position()
        end)
    end)
    local function Stop(self) self:SetScript("OnUpdate", nil); GameTooltip:Hide() end
    button:SetScript("OnDragStop", Stop)
    button:SetScript("OnHide", Stop)
    button:SetScript("OnClick", Toggle)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GuildStock", 1, 0.82, 0)
        GameTooltip:AddLine(L["Left-click: Open / close"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: Move"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Position()
end

SLASH_GUILDSTOCK1 = "/guildstock"
SlashCmdList.GUILDSTOCK = function(command)
    if command:lower():match("^%s*(.-)%s*$") == "probe" then
        print("GuildStock: " .. addon.StartProbe())
        addon.Refresh()
    else
        Toggle()
    end
end
