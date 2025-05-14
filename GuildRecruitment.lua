-- Initialisiert den Namespace für das Gildenrekrutierungsmodul, falls noch nicht vorhanden.
-- Dies stellt sicher, dass das Modul eine eigene, saubere "Umgebung" innerhalb des Haupt-Addons hat.
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}

-- Tabelle zum Speichern aller offenen Gildenanfragen.
-- Wird initialisiert, falls sie noch nicht existiert, um Datenverlust bei Reloads zu vermeiden.
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

-- Lokale Referenz auf die Anfragenliste für kürzeren und schnelleren Zugriff im Modul.
local inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests

-- Globale Variablen für den Debug-Modus
SchlingelInc.GuildRecruitment.DEBUG_MODE_ENABLED = false -- Standardmäßig deaktiviert
SchlingelInc.GuildRecruitment.DEBUG_TARGET_USER = nil    -- Kein Standard-Zielbenutzer

-- Gibt die aktuelle Liste der Gildenanfragen zurück.
-- Diese Funktion dient als Schnittstelle, um von außerhalb des Moduls auf die Anfragen zuzugreifen.
function SchlingelInc.GuildRecruitment:GetPendingRequests()
    return inviteRequests
end

-- Sendet eine Gildenanfrage an die angegebene Gilde.
function SchlingelInc.GuildRecruitment:SendGuildRequest(guildName)
    -- Prüft, ob der Spieler bereits in einer Gilde ist.
    -- if IsInGuild() then
    --     SchlingelInc:Print("Du bist bereits in einer Gilde.")
    --     return
    -- end

    -- Optional: Level-Beschränkung für Anfragen (derzeit auskommentiert).
    -- if UnitLevel("player") > 1 then
    --     SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
    --     return
    -- end

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

    --GuildRoster() -- Aktualisiert einmal die Gilde und cached sie im Client.
    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, _, _, _, _, _, online, _, _, _, _, _, _, _ = GetGuildRosterInfo(i);
        -- if online and name and (rank == "Oberlootwichtel" or rank == "Lootwichtel" or rank == "GroßSchlingel") then
        --     C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
        --     SchlingelInc:Print(SchlingelInc:RemoveRealmFromName(name) .. " ist online und würde die Anfrage erhalten.")
        --     return
        -- else
        --     SchlingelInc:Print("Aktuell ist kein Offi online.")
        --     return
        -- end
    end
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Pudidev")
end

-- Verarbeitet eingehende Addon-Nachrichten.
-- Diese Funktion wird aufgerufen, wenn das Addon eine Nachricht über den Addon-Kanal empfängt.
local function HandleAddonMessage(prefix, message, channel, sender)
    -- Ignoriert Nachrichten, die nicht für dieses Addon bestimmt sind.
    if prefix ~= SchlingelInc.prefix then
        return
    end

    -- Verarbeitet die "INVITE_REQUEST"-Nachricht.
    local name, levelStr, expStr, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
    --if CanGuildInvite() then
        -- Fügt die neue Anfrage zur Liste hinzu.
        table.insert(inviteRequests, { name = name, level = levelStr, exp = expStr, zone = zone, money = money })
        --SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, levelStr, zone))

        -- Aktualisiert die Benutzeroberfläche, um die neue Anfrage anzuzeigen.
        --SchlingelInc:RefreshAllRequestUIs()
    --end
end


-- -- Hilfsfunktion zum Aktualisieren aller relevanten UIs nach einer Änderung der Anfragenliste.
-- -- Aktualisiert das Offi-Fenster auch wenn es geschlossen ist.
-- function SchlingelInc:RefreshAllRequestUIs()
--     SchlingelInc.OffiWindow:UpdateRecruitmentTabData(inviteRequests)
-- end

-- Verarbeitet das Akzeptieren einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then
        return
    end

    -- Prüft, ob der Spieler die Berechtigung hat, andere einzuladen.

    if CanGuildInvite() then
    SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName) -- Führt die Gilden-Einladung aus.
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
        return
    end

    -- Entfernt die Anfrage aus der Liste, nachdem sie akzeptiert (oder versucht) wurde.
    local found = false
    for i = #inviteRequests, 1, -1 do -- Iteriert rückwärts, um Probleme beim Entfernen zu vermeiden.
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

-- Verarbeitet das Ablehnen einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then
        return
    end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")

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

-- -- DEBUG: SlashCommands nicht produktiv einsetzen, damit Logik nicht umgangen werden kann.
-- -- Initialisiert die Slash-Befehle für das Addon.
-- function SchlingelInc.GuildRecruitment:InitializeSlashCommands()
--     SLASH_SCHLINGELINC1 = "/schlingel" -- Haupt-Slash-Befehl.
--     SLASH_SCHLINGELINC2 = "/si"      -- Kurzform des Slash-Befehls.

--     SlashCmdList["SCHLINGELINC"] = function(msg)
--         -- Zerlegt die Eingabe in Befehl und Parameter.
--         local cmd, param = msg:match("^(%S+)%s*(.-)$")
--         cmd = cmd and cmd:lower() or "" -- Kleinschreibung für den Befehl.
--         param = param == "" and nil or param -- Parameter ist nil, wenn leer.

--         -- Ruft die Methoden im Kontext von self.GuildRecruitment auf,
--         -- damit `self` korrekt auf das GuildRecruitment-Objekt verweist.
--         local GR = SchlingelInc.GuildRecruitment

--         if cmd == "request" and param == "main" then
--             GR:SendGuildRequest("Schlingel Inc") -- Sendet Anfrage an die Hauptgilde.
--         elseif cmd == "request" and param == "twink" then
--             GR:SendGuildRequest("Schlingel IInc") -- Sendet Anfrage an die Twinkgilde.
--         elseif cmd == "addtestdata" then
--             -- Fügt Testdaten zur Anfragenliste hinzu, um die UI zu testen.
--             table.insert(inviteRequests, { name = "TestUser1-"..math.random(100,999), level = math.random(1,60), exp = math.random(100,50000), zone = "Durotar", money = math.random(1,100).."g" })
--             table.insert(inviteRequests, { name = "TestUser2-"..math.random(100,999), level = math.random(1,60), exp = math.random(100,50000), zone = "Elwynn", money = math.random(1,100).."s" })
--             table.insert(inviteRequests, { name = "TestUser3-"..math.random(100,999), level = math.random(1,60), exp = math.random(100,50000), zone = "Darkshore", money = math.random(1,100).."c" })
--             SchlingelInc:Print("Testdaten hinzugefügt.")
--             RefreshAllRequestUIs()
--         elseif cmd == "debugmode" then
--             if param == "on" then
--                 GR.DEBUG_MODE_ENABLED = true
--                 SchlingelInc:Print("Gildenrekrutierung Debug-Modus: ANGESCHALTET.")
--             elseif param == "off" then
--                 GR.DEBUG_MODE_ENABLED = false
--                 SchlingelInc:Print("Gildenrekrutierung Debug-Modus: AUSGESCHALTET.")
--             else
--                 SchlingelInc:Print("Verwendung: /si debugmode on|off")
--             end
--         elseif cmd == "debugtarget" then
--             if param then
--                 GR.DEBUG_TARGET_USER = param
--                 SchlingelInc:Print(string.format("Gildenrekrutierung Debug-Ziel: %s.", param))
--             else
--                  SchlingelInc:Print("Verwendung: /si debugtarget <Spielername-Servername> (oder nur Spielername wenn gleicher Server)")
--                  SchlingelInc:Print(string.format("Aktuelles Debug-Ziel: %s", GR.DEBUG_TARGET_USER or "Nicht gesetzt"))
--             end
--         else
--             -- Zeigt die verfügbaren Befehle an.
--             SchlingelInc:Print("Verfügbare Befehle für /si:")
--             SchlingelInc:Print("  request main|twink         - Sendet eine Gildenanfrage.")
--             SchlingelInc:Print("  addtestdata                - Fügt Testdaten zur UI hinzu.")
--             SchlingelInc:Print("  debugmode on|off           - Schaltet den Debug-Modus um.")
--             SchlingelInc:Print("  debugtarget <Spielername>  - Setzt den Zielspieler für den Debug-Modus.")
--         end
--     end
-- end

-- Globaler Event-Handler-Frame für eingehende Addon-Nachrichten.
-- Dieser Frame lauscht permanent auf CHAT_MSG_ADDON Events.
local addonMessageGlobalHandlerFrame = CreateFrame("Frame")
addonMessageGlobalHandlerFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageGlobalHandlerFrame:SetScript("OnEvent", function(selfFrame, event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...) -- Ruft die zentrale Verarbeitungsfunktion auf.
    end
end)

-- -- Ruft die Initialisierungsfunktion für Slash-Befehle auf, sobald das Modul geladen wird.
--SchlingelInc.GuildRecruitment:InitializeSlashCommands()
