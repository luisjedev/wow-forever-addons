local _, addon = ...
local L = addon.L
local prefix = "GuildStockP0"
local state = { received = 0, confirmed = 0, unmatched = 0 }
addon.probe = state
local registered, pending, expires, lastProbe, guild, lastReply
local replied = {}

function addon.ResultName(enum, result)
    if not addon.Accessible(result) or result == nil then return L["Unavailable"] end
    for key, value in pairs(enum or {}) do
        if value == result then return key end
    end
    return L["Unavailable"]
end

function addon.RegisterProbe()
    local result = addon.Read(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix, prefix)
    local values = Enum and Enum.RegisterAddonMessagePrefixResult
    state.registration = addon.ResultName(values, result)
    registered = values and (result == values.Success or result == values.DuplicatePrefix)
end

local function Guild()
    return addon.Read(C_Club and C_Club.GetGuildClubId)
end

local function CanSend()
    return registered and addon.Read(InCombatLockdown) == false
        and addon.Read(C_ChatInfo and C_ChatInfo.InChatMessagingLockdown) == false
        and Guild() ~= nil
end

local function Send(message)
    if not CanSend() then return false end
    local result = addon.Read(C_ChatInfo and C_ChatInfo.SendAddonMessage, prefix, message, "GUILD")
    local values = Enum and Enum.SendAddonMessageResult
    state.GUILD = addon.ResultName(values, result)
    return values and result == values.Success
end

local function Peer(sender)
    local club = Guild()
    if not club or club ~= guild then return false end
    local members = addon.Read(C_Club and C_Club.GetClubMembers, club)
    if type(members) ~= "table" or #members > 2000 then return false end
    local presence = Enum and Enum.ClubMemberPresence
    if not presence then return false end
    for _, id in ipairs(members) do
        if not addon.Accessible(id) then return false end
        local info = addon.Read(C_Club.GetMemberInfo, club, id)
        if type(info) == "table" and addon.Accessible(info.name) and addon.Accessible(info.isSelf)
            and addon.Accessible(info.presence) and info.name == sender and info.isSelf == false then
            return info.presence == presence.Online or info.presence == presence.Away or info.presence == presence.Busy
        end
    end
    return false
end

function addon.StartProbe()
    local now = GetTime()
    if lastProbe and now - lastProbe < 60 then return L["Probe cooldown: 60 seconds."] end
    if not CanSend() then return L["Probe unavailable: check Settings and /guildstock diagnostics."] end
    lastProbe, expires, guild = now, now + 60, Guild()
    pending = string.format("%d-%d", time(), math.random(1, 2147483647))
    replied, lastReply = {}, nil
    state.received, state.confirmed, state.unmatched = 0, 0, 0
    if not Send("2|P|" .. pending) then
        pending, expires = nil, nil
        return L["Probe unavailable: check Settings and /guildstock diagnostics."]
    end
    return L["Probe active for 60 seconds. Run /guildstock probe on a second guild client."]
end

function addon.ReceiveProbe(messagePrefix, message, channel, sender)
    if not expires or GetTime() >= expires then return end
    for i = 1, 4 do
        local value = select(i, messagePrefix, message, channel, sender)
        if not addon.Accessible(value) or type(value) ~= "string" then return end
    end
    if messagePrefix ~= prefix or #message > 64 or #sender > 200
        or channel ~= "GUILD" then return end
    local kind, token = message:match("^2|([PA])|(%d+%-%d+)$")
    if not kind then return end
    -- Own broadcast echoes cannot establish delivery to another client.
    if kind == "P" and token == pending then return end
    if not Peer(sender) then state.unmatched = state.unmatched + 1; return end
    if kind == "P" and not replied[sender]
        and state.received < 5 and (not lastReply or GetTime() - lastReply >= 2) then
        replied[sender], lastReply = true, GetTime()
        state.received = state.received + 1
        Send("2|A|" .. token)
    elseif kind == "A" and token == pending then
        state.confirmed = state.confirmed + 1
        pending = nil -- One matched acknowledgement per probe; duplicates prove nothing.
    end
    if addon.Refresh then addon.Refresh() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("PLAYER_GUILD_UPDATE")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        addon.ReceiveProbe(...)
    else
        pending, expires, guild = nil, nil, nil
        replied = {}
    end
end)
