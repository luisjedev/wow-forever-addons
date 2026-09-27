-- Run from the repository root: luajit TDL/TDL.test.lua
-- Font metrics are simulated; ellipsis, wrapping and clipping also need an in-game check.
local methods, frames = {}, {}
local function frame(parent)
    return setmetatable({parent = parent, scripts = {}, events = {}, points = {}, shown = true}, {__index = methods})
end
for _, name in ipairs({"SetFrameLevel", "SetFrameStrata", "SetClampedToScreen", "SetMovable",
    "EnableMouse", "EnableMouseWheel", "RegisterForClicks", "RegisterForDrag", "SetHighlightTexture",
    "SetPushedTexture", "SetDisabledTexture", "SetAllPoints", "SetTexture", "SetAutoFocus", "SetMaxBytes",
    "SetJustifyH", "SetJustifyV", "SetColorTexture", "SetTexCoord", "SetVertexColor",
    "SetFontObject", "SetMultiLine", "SetCursorPosition", "HighlightText", "SetTextColor", "UpdateScrollChildRect"}) do
    methods[name] = function() end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterEvent(name) self.events[name] = nil end
function methods:SetPoint(anchor, ...) self.points[anchor] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:GetWidth() return self.width or 560 end
function methods:GetHeight() return self.height or 328 end
function methods:GetFrameLevel() return 1 end
function methods:SetText(text)
    self.label = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, true) end
end
function methods:GetText() return self.label end
function methods:SetFocus() self.focused = true end
function methods:ClearFocus()
    if not self.focused then return end
    self.focused = false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:SetWordWrap(wrap) self.wrap = wrap end
function methods:SetNonSpaceWrap(wrap) self.nonSpaceWrap = wrap end
function methods:GetLineHeight() return 14 end
function methods:GetUnboundedStringWidth() return #self.label * 14 end
function methods:GetNumLines()
    local count = 0
    for line in ((self.label or "") .. "\n"):gmatch("(.-)\n") do
        count = count + math.max(1, math.ceil(#line / 40))
    end
    return count
end
function methods:GetStringHeight() return 14 * self:GetNumLines() end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:SetNormalTexture(texture) self.normalTexture = texture end
function methods:SetScrollChild(child) self.child = child end
function methods:GetVerticalScrollRange() return math.max(0, self.child:GetHeight() - self:GetHeight()) end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(value) self.value = value end
function methods:IsShown() return self.shown end
function methods:SetShown(shown)
    if self.shown == shown then return end
    self.shown = shown
    local callback = self.scripts[shown and "OnShow" or "OnHide"]
    if callback then callback(self) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
methods.CreateTexture, methods.CreateFontString = frame, frame
CreateFrame = function(_, name, parent)
    local result = frame(parent)
    result.TitleText, result.Inset, result.ScrollBar = frame(result), frame(result), frame(result)
    frames[#frames + 1] = result
    if name then _G[name] = result end
    return result
end
UIParent, Minimap, GameTooltip = frame(), frame(), frame()
UIErrorsFrame = {AddMessage = function(self, message) self.message = message end}
StaticPopupDialogs, UISpecialFrames, SlashCmdList = {}, {}, {}
StaticPopup_Hide = function() end
local function event(name, ...)
    for _, f in ipairs(frames) do
        if f.events[name] then f.scripts.OnEvent(f, name, ...) end
    end
end
local function click(button) button.scripts.OnClick(button) end
local function button(label, parent)
    for _, f in ipairs(frames) do
        if f.label == label and (not parent or f.parent == parent) then return f end
    end
    error("Missing button: " .. label)
end
local saved = {tasks = {}, position = {"CENTER", "CENTER", 10, 20}}
TDLDB = saved
local addon = {L = setmetatable({}, {__index = function(_, key) return key end})}
assert(loadfile("TDL/TDL.lua"))("TDL", addon)
event("PLAYER_LOGIN")
assert(TDLDB == saved and saved.position[3] == 10, "initialization preserves existing data")
event("PLAYER_ENTERING_WORLD", true, false)
assert(not TDLFrame, "empty list stays closed")
for i = 1, 9 do saved.tasks[i] = {text = "Completed task " .. i, done = true} end
event("PLAYER_ENTERING_WORLD", true, false)
assert(not TDLFrame, "completed list stays closed")
saved.tasks[9].done = false
event("PLAYER_ENTERING_WORLD", true, false)
assert(TDLFrame:IsShown(), "login opens pending tasks")
local rows = {}
for _, f in ipairs(frames) do
    if f.task then rows[#rows + 1] = f end
end
assert(#rows == 9 and rows[9].task == saved.tasks[9], "all tasks appear in one list, including past eight")
TDLFrame:Hide()
event("PLAYER_ENTERING_WORLD", false, false)
assert(not TDLFrame:IsShown(), "zone changes respect a closed window")
event("PLAYER_ENTERING_WORLD", false, true)
assert(TDLFrame:IsShown(), "reload opens pending tasks")
local longText = string.rep("Task text with spaces ", 10)
saved.tasks[1].text = longText
TDLFrame.scripts.OnShow()
assert(rows[1]:GetHeight() == 70 and rows[1].text:GetHeight() == 14
    and not rows[1].text.wrap and not rows[1].text.nonSpaceWrap
    and rows[1].delete:IsShown(),
    "collapsed text stays on one line with its actions visible underneath")
click(rows[1])
assert(rows[1].expanded and rows[1].text.wrap and rows[1].text.nonSpaceWrap
    and rows[1].delete:IsShown() and rows[1]:GetHeight() > 70)
assert(rows[2].points.TOPLEFT[2] == -rows[1]:GetHeight() - 2, "expansion pushes later rows down")
assert(TDLScrollFrame:GetVerticalScrollRange() > 0, "overflow remains scrollable")
TDLScrollFrame.ScrollBar:SetValue(TDLScrollFrame:GetVerticalScrollRange())
click(rows[1])
assert(rows[1]:GetHeight() == 70 and rows[2].points.TOPLEFT[2] == -72
    and rows[1].delete:IsShown())
assert(TDLScrollFrame.ScrollBar:GetValue() == TDLScrollFrame:GetVerticalScrollRange(), "collapse clamps scrolling")
click(rows[2])
assert(not rows[2].expanded and not rows[2].disclosure:IsShown()
    and rows[2].delete:IsShown(), "short tasks keep their actions without an accordion")
TDLInput:SetText("New task draft")
rows[9].scripts.OnDoubleClick()
assert(rows[9].editor.focused and rows[9].editor:IsShown() and not rows[9].text:IsShown())
rows[9].editor:SetText("  Español 中文 |cff00ff00 test\nSecond line  ")
assert(saved.tasks[9].text == "Completed task 9", "inline changes wait for autosave")
assert(rows[9]:GetHeight() > 70, "multiline editing grows the row")
rows[9].editor.scripts.OnCursorChanged(rows[9].editor, 0, -14, 1, 14)
assert(TDLScrollFrame.ScrollBar:GetValue() > 0, "caret scrolls into view")
rows[9].editor:ClearFocus()
assert(saved.tasks[9].text == "Español 中文 |cff00ff00 test\nSecond line" and not saved.tasks[9].done)
assert(rows[9].text.label == "Español 中文 ||cff00ff00 test\nSecond line", "literal markup stays escaped")
assert(TDLInput:GetText() == "New task draft", "inline editing preserves the new-task input")
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText("Saved when switching tasks")
rows[2].scripts.OnDoubleClick()
assert(saved.tasks[9].text == "Saved when switching tasks" and rows[2].editor.focused)
rows[2].editor.scripts.OnEscapePressed()
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText("Español 中文 |cff00ff00 test\nSecond line")
rows[9].editor:ClearFocus()
click(rows[9])
assert(not rows[9].text.label:find("\n"), "collapsed multiline tasks stay on one line")
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText(" \n ")
rows[9].editor:ClearFocus()
assert(saved.tasks[9].text:find("Second line") and UIErrorsFrame.message == "Enter a task before saving.",
    "empty edits preserve the saved task and report validation")
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText(string.rep("x", 241))
rows[9].editor:ClearFocus()
assert(saved.tasks[9].text:find("Second line") and UIErrorsFrame.message == "Shorten the task text.")
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText("Saved on close")
TDLFrame:Hide()
assert(saved.tasks[9].text == "Saved on close", "closing the addon saves the active edit")
TDL_Toggle()
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText("Saved on reload or logout")
event("PLAYER_LOGOUT")
assert(saved.tasks[9].text == "Saved on reload or logout")
rows[9].scripts.OnDoubleClick()
rows[9].editor:SetText("Saved on completion")
rows[9].check:SetChecked(true)
click(rows[9].check)
assert(saved.tasks[9].done and saved.tasks[9].text == "Saved on completion")
TDLFrame:Hide()
event("PLAYER_ENTERING_WORLD", false, true)
assert(not TDLFrame:IsShown(), "completing the last task prevents auto-open")
TDL_Toggle()
TDLInput:SetText("  ")
click(button("Add"))
assert(#saved.tasks == 9, "blank tasks are rejected")
TDLInput:SetText("New task")
click(button("Add"))
assert(#saved.tasks == 10 and saved.tasks[10].text == "New task" and not saved.tasks[10].done)
assert(TDLScrollFrame.ScrollBar:GetValue() == TDLScrollFrame:GetVerticalScrollRange(), "new tasks scroll into view")
StaticPopupDialogs.TDL_DELETE.OnAccept(nil, saved.tasks[10])
StaticPopupDialogs.TDL_DELETE.OnAccept(nil, saved.tasks[9])
assert(#saved.tasks == 8 and not rows[9]:IsShown(), "deleted rows are hidden")
StaticPopupDialogs.TDL_DELETE.OnAccept(nil, saved.tasks[1])
assert(rows[1].task == saved.tasks[1] and not rows[1].expanded, "reused rows reset their expansion")
while #saved.tasks > 1 do StaticPopupDialogs.TDL_DELETE.OnAccept(nil, saved.tasks[1]) end
assert(TDLScrollFrame:GetVerticalScrollRange() == 0 and TDLScrollFrame.ScrollBar:IsShown()
    and not TDLScrollFrame.scrollBarHideable, "short lists keep the native scrollbar visible")
StaticPopupDialogs.TDL_DELETE.OnAccept(nil, saved.tasks[1])
assert(not rows[1]:IsShown() and TDLScrollFrame.ScrollBar:GetValue() == 0
    and TDLScrollFrame.ScrollBar:IsShown(), "empty list hides rows but keeps the scrollbar visible")
print("TDL accordion, continuous scrolling, editing and automatic opening: OK")
