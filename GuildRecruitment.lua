-- Initialisiert den Namespace für das Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

local inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests

-- Verwende eine Lookup/Table, da diese die for-Schleife für die Invite Message stark optimiert. siehe Zeile 52
local guildOfficers = {
    ["Kurtibrown"] = true,
    ["Schlingbank"] = true,
    ["Schlinglbank"] = true,
    ["Dörtchen"] = true,
    ["Schmurt"] = true,
    ["Siegdörty"] = true,
    ["Syluri"] = true,
    ["Totanka"] = true,
    ["Syltank"] = true,
    ["Heilkrampf"] = true,
    ["Fenriic"] = true,
    ["Totärztin"] = true,
    ["Totemtanz"] = true,
    ["Bärmuut"] = true,
    ["Mortblanche"] = true,
    ["Pfarrer"] = true,
    ["Luminette"] = true,
    ["Cricksumage"] = true,
    ["Devschlingel"] = true,
    ["Pudidev"] = true,
}
function SchlingelInc.GuildRecruitment:GetPendingRequests()
    return inviteRequests
end

function SchlingelInc.GuildRecruitment:SendGuildRequest()
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")

    if playerLevel > 1 then
        SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
        return
    end

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()
    local playerGold = GetMoneyString(GetMoney(), true)
    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)

    -- Sendet die Anfrage an alle Officer.
    for i = 1, GetNumGuildMembers() do
        local fullName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        local shortName = SchlingelInc:RemoveRealmFromName(fullName)
        -- Dieser Vergleich ist O(1), da nicht jedes Element der Liste durchiteriert wird.
        if guildOfficers[shortName] and online then
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", shortName)
        end
    end
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local name, level, xp, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if name and level and xp and zone and money then
            local requestData = {
                name = name,
                level = level,
                xp = tonumber(xp),
                zone = zone,
                money = money,
            }
            table.insert(inviteRequests, requestData)
            SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %s) in %s erhalten.", name, level, zone))
            SchlingelInc:RefreshAllRequestUIs()
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        local playerName = message:match("^INVITE_SENT:([^:]+)$")
        SchlingelInc:RemovePlayerFromListAndUpdateUI(playerName)
    end
end


function SchlingelInc:RefreshAllRequestUIs()
    if SchlingelInc.Tabs and SchlingelInc.Tabs.Recruitment and SchlingelInc.Tabs.Recruitment.UpdateData then
        SchlingelInc.Tabs.Recruitment:UpdateData(SchlingelInc.GuildRecruitment:GetPendingRequests())
    else
        SchlingelInc:Print("Fehler: Recruitment Tab oder UpdateData Methode nicht gefunden.")
    end
end


function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "OFFICER")
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "OFFICER")
end

local addonMessageGlobalHandlerFrame = CreateFrame("Frame")
addonMessageGlobalHandlerFrame:RegisterEvent("CHAT_MSG_ADDON")

addonMessageGlobalHandlerFrame:SetScript("OnEvent", function(self, event, prefix, message)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        if message:find("INVITE_REQUEST") or message:find("INVITE_SENT") then
            HandleAddonMessage(message)
        end
    end
end)

function SchlingelInc:RemovePlayerFromListAndUpdateUI(playerName)
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            SchlingelInc:RefreshAllRequestUIs()
            break
        end
    end
end

-- Gibt formatierten Zonennamen zurück
function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unbekannt"
    end
    return GetZoneText() or "Unbekannt"
end