-- Initialisiert den Namespace für das Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

local inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests
local Helper = SchlingelInc.GuildRecruitmentHelper

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

    local zone = Helper:GetPlayerZone()
    local playerGold = Helper:GetFormattedGold()
    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)

    SchlingelInc:Print("Anfrage gesendet " .. message)
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Pudidev")
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local request = Helper:ParseInviteRequestMessage(message)
        if request then
            table.insert(inviteRequests, request)
            SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", request.name, request.level, request.zone))
            SchlingelInc:RefreshAllRequestUIs()
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        local playerName = message:match("^INVITE_SENT:([^:]+)$")
        SchlingelInc:RemovePlayerFromListAndUpdateUI(playerName)
    end
end

function SchlingelInc:RefreshAllRequestUIs()
    SchlingelInc.OffiWindow:UpdateRecruitmentTabData(inviteRequests)
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

SLASH_SCHLINGELSENDINVITE1 = "/gildenanfrage"
SLASH_SCHLINGELSENDINVITE2 = "/ga"

SlashCmdList["SCHLINGELSENDINVITE"] = function()
    SchlingelInc.GuildRecruitment:SendGuildRequest()
end
