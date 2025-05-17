-- Initialisiert den Namespace für das Gildenrekrutierungsmodul, falls noch nicht vorhanden.
-- Dies stellt sicher, dass das Modul eine eigene, saubere "Umgebung" innerhalb des Haupt-Addons hat.
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}

-- Tabelle zum Speichern aller offenen Gildenanfragen.
-- Wird initialisiert, falls sie noch nicht existiert, um Datenverlust bei Reloads zu vermeiden.
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

-- Lokale Referenz auf die Anfragenliste für kürzeren und schnelleren Zugriff im Modul.
local inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests

-- Gibt die aktuelle Liste der Gildenanfragen zurück.
-- Diese Funktion dient als Schnittstelle, um von außerhalb des Moduls auf die Anfragen zuzugreifen.
function SchlingelInc.GuildRecruitment:GetPendingRequests()
    return inviteRequests
end

-- Sendet eine Gildenanfrage an die angegebene Gilde.
function SchlingelInc.GuildRecruitment:SendGuildRequest(guildName)
    --Prüft, ob der Spieler bereits in einer Gilde ist.
    if IsInGuild() then
        SchlingelInc:Print("Du bist bereits in einer Gilde.")
        return
    end

    -- Überprüft, ob ein Gildenname angegeben wurde.
    if not guildName or guildName == "" then
        SchlingelInc:Print("Kein Gildenname angegeben.")
        return
    end

    -- Sammelt Spielerinformationen für die Anfrage.
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")
    local zone

    -- Optional: Level-Beschränkung für Anfragen (derzeit auskommentiert).
    if playerLevel > 1 then
        SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
        return
    end

    -- Verwendet moderne API für Zonennamen, falls verfügbar, sonst Fallback.
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        zone = mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unbekannt"
    else
        zone = GetZoneText() or "Unbekannt"
    end
    local money = GetMoney()
    local playerGold = GetMoneyString(money, true) -- Formatierter Goldbetrag.

    -- Erstellt die Addon-Nachricht mit den Spielerdaten im Format "BEFEHL:Daten1:Daten2:..."
    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)
    -- for _, offi in ipairs(SchlingelInc.Offis) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Cricksumage")
    -- end
end

-- Verarbeitet eingehende Addon-Nachrichten.
-- Diese Funktion wird aufgerufen, wenn das Addon eine Nachricht über den Addon-Kanal empfängt.
local function HandleAddonMessage(prefix, message)
    -- Ignoriert Nachrichten, die nicht für dieses Addon bestimmt sind.
    if prefix ~= SchlingelInc.prefix then
        return
    end

    -- Verarbeitet die "INVITE_REQUEST"-Nachricht.
    if message:find("^INVITE_REQUEST:") then
        local name, levelStr, expStr, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if CanGuildInvite() then
            -- Fügt die neue Anfrage zur Liste hinzu.
            table.insert(inviteRequests, { name = name, level = levelStr, exp = expStr, zone = zone, money = money })
            SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, levelStr, zone))

            -- Aktualisiert die Benutzeroberfläche, um die neue Anfrage anzuzeigen.
            SchlingelInc:RefreshAllRequestUIs()
        end
    end

    --Verarbeite die Löschrequest
    if message:find("^INVITE_SENT:") then
        if CanGuildInvite() then
            local playerName = message:match("^INVITE_SENT:([^:]+)$")
            SchlingelInc:RemovePlayerFromListAndUpdateUI(playerName)
        end
    end
end


-- Hilfsfunktion zum Aktualisieren aller relevanten UIs nach einer Änderung der Anfragenliste.
-- Aktualisiert das Offi-Fenster auch wenn es geschlossen ist.
function SchlingelInc:RefreshAllRequestUIs()
    SchlingelInc.OffiWindow:UpdateRecruitmentTabData(inviteRequests)
end

-- Verarbeitet das Akzeptieren einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then
        return
    end

    -- Prüft, ob der Spieler die Berechtigung hat, andere einzuladen.

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName) -- Führt die Gilden-Einladung aus.
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "OFFICER")

    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
        return
    end
end

-- Verarbeitet das Ablehnen einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then
        return
    end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "OFFICER")
end

-- Globaler Event-Handler-Frame für eingehende Addon-Nachrichten.
-- Dieser Frame lauscht permanent auf CHAT_MSG_ADDON Events.
local addonMessageGlobalHandlerFrame = CreateFrame("Frame")
addonMessageGlobalHandlerFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageGlobalHandlerFrame:RegisterEvent("CLUB_MEMBER_ADDED")
--function(self, event, prefix, message, channel, sender, target, zoneChannelID, localID, name, instanceID)
addonMessageGlobalHandlerFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender, target, zoneChannelID, localID, name, instanceID)
    if (event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix and message:find("INVITE_REQUEST") or message:find("INVITE_SENT")) then
        HandleAddonMessage(prefix, message) -- Ruft die zentrale Verarbeitungsfunktion auf.
    end
end)

-- MessageHandler der den namen löscht und das UI refreshed
function SchlingelInc:RemovePlayerFromListAndUpdateUI(playerName)
    -- Entfernt die Anfrage aus der Liste.
    local found = false
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            found = true
            break
        end
    end

    if found then
        SchlingelInc:RefreshAllRequestUIs() -- Aktualisiert die UI.
    end
end