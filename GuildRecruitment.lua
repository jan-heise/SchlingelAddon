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
    if IsInGuild() then
        SchlingelInc:Print("Du bist bereits in einer Gilde.")
        return
    end

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

    -- -- DEBUG MODUS: Direkter Versand an einen Zielbenutzer
    -- if SchlingelInc.GuildRecruitment.DEBUG_MODE_ENABLED and SchlingelInc.GuildRecruitment.DEBUG_TARGET_USER then
    --     if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    --         C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", SchlingelInc.GuildRecruitment.DEBUG_TARGET_USER)
    --         SchlingelInc:Print(string.format("DEBUG: Gildenanfrage-Nachricht direkt an '%s' gesendet.", SchlingelInc.GuildRecruitment.DEBUG_TARGET_USER))
    --     else
    --         SchlingelInc:Print("DEBUG: C_ChatInfo.SendAddonMessage nicht verfügbar. Nachricht konnte nicht gesendet werden.")
    --     end
    --     return -- Normalen Workflow umgehen
    -- end
    -- -- ENDE DEBUG MODUS

    -- Sendet einen /who-Befehl, um Gildenmitglieder zu finden.
    -- Der String 'g-"Gildenname"' sucht nach Mitgliedern der spezifischen Gilde.
    if C_FriendList and C_FriendList.SendWho then
        local whoString = string.format('g-"%s"', guildName)
        C_FriendList.SendWho(whoString)
    else
        SchlingelInc:Print("WHO-Funktion nicht verfügbar.")
        return
    end

    -- Versteckt das "Wer"-Fenster (Freundefenster) kurz nach dem Senden des /who-Befehls,
    -- um die Benutzeroberfläche nicht zu stören.
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
            if FriendsFrame and FriendsFrame:IsShown() then
                HideUIPanel(FriendsFrame)
            end
        end)
    end

    -- Erstellt einen temporären Frame, um auf das Ergebnis der /who-Anfrage zu warten.
    local whoFrameHandler = CreateFrame("Frame")
    whoFrameHandler:RegisterEvent("WHO_LIST_UPDATE") -- Event wird ausgelöst, wenn die /who-Liste aktualisiert wird.
    whoFrameHandler:SetScript("OnEvent", function(selfEventFrame, event, ...)
        if event == "WHO_LIST_UPDATE" then
            selfEventFrame:UnregisterEvent("WHO_LIST_UPDATE") -- Event abmelden, um Mehrfachausführung zu verhindern.
            whoFrameHandler:Hide() -- Frame verstecken, da er nicht mehr benötigt wird.

            if not C_FriendList or not C_FriendList.GetNumWhoResults then
                 SchlingelInc:Print("Fehler beim Verarbeiten der WHO-Antwort.")
                 return
            end

            local numResults = C_FriendList.GetNumWhoResults()
            if numResults == 0 then
                SchlingelInc:Print(string.format("Keine Online-Mitglieder in der Gilde '%s' gefunden, an die eine Anfrage gesendet werden könnte.", guildName))
                return
            end

            local currentIndex = 1
            local maxWhoResults = numResults -- Anzahl der gefundenen Gildenmitglieder.
            local requestWasForwarded = false -- Flag, um zu prüfen, ob die Anfrage erfolgreich weitergeleitet wurde.

            -- Temporärer Frame, um auf eine Bestätigungsnachricht ("REQUEST_FORWARDED") vom empfangenden Addon zu warten.
            local addonMsgResponseHandler = CreateFrame("Frame")
            addonMsgResponseHandler:RegisterEvent("CHAT_MSG_ADDON")
            addonMsgResponseHandler:SetScript("OnEvent", function(_, eventArg, prefixArg, msgArg, channelArg, senderArg)
                if eventArg == "CHAT_MSG_ADDON" and prefixArg == SchlingelInc.prefix and msgArg == "REQUEST_FORWARDED" then
                    requestWasForwarded = true
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end)

            -- Funktion, die versucht, die Addon-Nachricht an das nächste Gildenmitglied in der /who-Liste zu senden.
            -- Dies geschieht nacheinander mit einer kleinen Verzögerung, um das System nicht zu überlasten
            -- und um auf eine mögliche "REQUEST_FORWARDED"-Antwort zu warten.
            local function SendNextRequest()
                if requestWasForwarded then
                    SchlingelInc:Print(string.format("Anfrage an Gilde '%s' erfolgreich gesendet.", guildName))
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON") -- Sicherstellen, dass der Handler abgemeldet wird.
                    addonMsgResponseHandler:Hide()
                    return
                end

                if currentIndex > maxWhoResults then
                    -- Alle Mitglieder wurden durchlaufen, ohne dass die Anfrage weitergeleitet wurde.
                    SchlingelInc:Print(string.format("Anfrage an Gilde '%s' konnte nicht zugestellt werden (kein Offizier mit Addon online?).", guildName))
                    SchlingelInc:Print("Bitte über Discord melden, falls keine Antwort kommt.")
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                    return
                end

                local info = C_FriendList.GetWhoInfo(currentIndex)
                if info and info.fullName and C_ChatInfo and C_ChatInfo.SendAddonMessage then
                    -- Sendet die Gildenanfrage-Nachricht per Whisper an das aktuelle Gildenmitglied.
                    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", info.fullName)
                end

                currentIndex = currentIndex + 1
                -- Wartet kurz, bevor der nächste Versuch gestartet wird, falls die Anfrage noch nicht weitergeleitet wurde.
                if not requestWasForwarded and C_Timer and C_Timer.After then
                    C_Timer.After(0.5, SendNextRequest) -- Rekursiver Aufruf mit Verzögerung.
                elseif not requestWasForwarded then
                    -- Fallback, falls C_Timer nicht verfügbar ist oder etwas schiefgeht.
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end
            -- Startet den Prozess des Nachrichtenversands.
            SendNextRequest()
        end
    end)
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
    if name and levelStr then
        -- Zu Debugzwekcen diese Zeile auskommentieren
        if not CanGuildInvite() then return end

        -- Wenn die Anfrage von einem Gildenmitglied kommt, das die Anfrage weiterleiten kann,
        -- sendet dieses eine Bestätigung zurück an den ursprünglichen Absender.
        if sender and C_ChatInfo and C_ChatInfo.SendAddonMessage and CanGuildInvite() then
            -- Wir prüfen hier NICHT, ob der Sender in der eigenen Gilde ist, da die `SendGuildRequest` Logik
            -- die Anfrage an Mitglieder der Zielgilde schickt. Wenn ein Mitglied der Zielgilde (mit Rechten)
            -- diese Nachricht empfängt, soll es die Anfrage intern bearbeiten und dem Sender der Anfrage
            -- mitteilen, dass sie weitergeleitet wurde.
            -- Dies ist wichtig, damit der Anfragende weiß, dass seine Anfrage angekommen ist.
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "REQUEST_FORWARDED", "WHISPER", sender)
        end


        local level = tonumber(levelStr)
        local exp = tonumber(expStr)

        -- Verhindert doppelte Anfragen desselben Spielers.
        for _, existing in ipairs(inviteRequests) do
            if existing.name == name then
                return
            end
        end

        -- Fügt die neue Anfrage zur Liste hinzu.
        table.insert(inviteRequests, { name = name, level = level, exp = exp, zone = zone, money = money })
        SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, level, zone))

        -- Aktualisiert die Benutzeroberfläche, um die neue Anfrage anzuzeigen.
        SchlingelInc:RefreshAllRequestUIs()
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
        RefreshAllRequestUIs() -- Aktualisiert die UI.
    end
end

-- DEBUG: SlashCommands nicht produktiv einsetzen, damit Logik nicht umgangen werden kann.
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