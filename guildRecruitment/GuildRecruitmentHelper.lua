-- Diese Datei enthält Hilfsfunktionen für das Gildenrekrutierungsmodul
-- Ziel ist die Auslagerung wiederverwendbarer Logik zur besseren Übersicht und Wartbarkeit

SchlingelInc.GuildRecruitmentHelper = {}

-- Gibt formatierten Zonennamen zurück
function SchlingelInc.GuildRecruitmentHelper:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unbekannt"
    end
    return GetZoneText() or "Unbekannt"
end

-- Gibt formatierten Goldbetrag zurück
function SchlingelInc.GuildRecruitmentHelper:GetFormattedGold()
    return GetMoneyString(GetMoney(), true)
end

-- Parst eine INVITE_REQUEST Nachricht
function SchlingelInc.GuildRecruitmentHelper:ParseInviteRequestMessage(message)
    return message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
end

-- Parst eine INVITE_SENT Nachricht
function SchlingelInc.GuildRecruitmentHelper:ParseInviteSentMessage(message)
    return message:match("^INVITE_SENT:([^:]+)$")
end

-- Prüft ob Nachricht Addon-Präfix hat
function SchlingelInc.GuildRecruitmentHelper:IsValidAddonPrefix(prefix)
    return prefix == SchlingelInc.prefix
end

-- Prüft ob Nachricht Gildenanfrage ist
function SchlingelInc.GuildRecruitmentHelper:IsInviteRequest(message)
    return message:find("^INVITE_REQUEST:") ~= nil
end

-- Prüft ob Nachricht Einladungsbestätigung ist
function SchlingelInc.GuildRecruitmentHelper:IsInviteSent(message)
    return message:find("^INVITE_SENT:") ~= nil
end

-- Entfernt einen Spieler aus der Invite-Liste nach Namen und gibt true zurück, wenn erfolgreich
function SchlingelInc.GuildRecruitmentHelper:RemovePlayerFromList(inviteRequests, playerName)
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            return true
        end
    end
    return false
end

return SchlingelInc.GuildRecruitmentHelper
