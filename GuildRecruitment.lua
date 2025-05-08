-- Initialisiert den Namespace für das Gildenrekrutierungsmodul, falls noch nicht vorhanden.
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
-- Tabelle zum Speichern aller offenen Gildenanfragen.
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}
-- Lokale Referenz auf die Anfragenliste für kürzeren Zugriff im Modul.
local inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests

-- Debug-Modus: true sendet Anfragen direkt an "Pudidev", false nutzt den normalen /who-Mechanismus.
local DEBUG_MODE = false

-- Gibt die aktuelle Liste der Gildenanfragen zurück.
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
        -- Optional: Level-Beschränkung für Anfragen (auskommentiert).
    -- if UnitLevel("player") > 1 then
    --     SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
    --     return
    -- end
    if not guildName or guildName == "" then
        SchlingelInc:Print("Kein Gildenname angegeben.")
        return
    end

    -- Sammelt Spielerinformationen für die Anfrage.
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")
    local zone
    if C_Map and C_Map.GetBestMapForUnit then -- Moderne API für Zonennamen
        local mapID = C_Map.GetBestMapForUnit("player")
        zone = mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unbekannt"
    else -- Fallback für ältere Clients
        zone = GetZoneText() or "Unbekannt"
    end
    local money = GetMoney()
    local playerGold = GetMoneyString(money, true)
    -- Erstellt die Addon-Nachricht mit den Spielerdaten.
    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)

    if DEBUG_MODE then
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Pudidev")
            SchlingelInc:Print("Gildenanfrage im DEBUG_MODE an Pudidev gesendet.")
        else
            SchlingelInc:Print("DEBUG_MODE: C_ChatInfo nicht verfügbar.")
        end
        return
    end

    if C_FriendList and C_FriendList.SendWho then
        local whoString = string.format('g-"%s"', guildName)
        C_FriendList.SendWho(whoString)
    else
        SchlingelInc:Print("WHO-Funktion nicht verfügbar.")
        return
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
            if FriendsFrame and FriendsFrame:IsShown() then
                HideUIPanel(FriendsFrame)
            end
        end)
    end

    local whoFrameHandler = CreateFrame("Frame")
    whoFrameHandler:RegisterEvent("WHO_LIST_UPDATE")
    whoFrameHandler:SetScript("OnEvent", function(selfEventFrame, event, ...)
        if event == "WHO_LIST_UPDATE" then
            selfEventFrame:UnregisterEvent("WHO_LIST_UPDATE")
            whoFrameHandler:Hide()

            if not C_FriendList or not C_FriendList.GetNumWhoResults then
                 SchlingelInc:Print("Fehler beim Verarbeiten der WHO-Antwort.")
                 return
            end

            local numResults = C_FriendList.GetNumWhoResults()
            if numResults == 0 then
                SchlingelInc:Print(string.format("Keine Ergebnisse für Gilde '%s' gefunden.", guildName))
                return
            end

            local currentIndex = 1
            local maxWhoResults = numResults
            local requestWasForwarded = false

            local addonMsgResponseHandler = CreateFrame("Frame")
            addonMsgResponseHandler:RegisterEvent("CHAT_MSG_ADDON")
            addonMsgResponseHandler:SetScript("OnEvent", function(_, eventArg, prefixArg, msgArg, channelArg, senderArg)
                if eventArg == "CHAT_MSG_ADDON" and prefixArg == SchlingelInc.prefix and msgArg == "REQUEST_FORWARDED" then
                    requestWasForwarded = true
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end)

            local function SendNextRequest()
                if requestWasForwarded then
                    SchlingelInc:Print("Anfrage gesendet.")
                    return
                end

                if currentIndex > maxWhoResults then
                    SchlingelInc:Print("Anfrage konnte nicht an alle Mitglieder gesendet werden.")
                    SchlingelInc:Print("Bitte über Discord melden, falls keine Antwort kommt.")
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                    return
                end

                local info = C_FriendList.GetWhoInfo(currentIndex)
                if info and info.fullName and C_ChatInfo and C_ChatInfo.SendAddonMessage then
                    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", info.fullName)
                end

                currentIndex = currentIndex + 1
                if not requestWasForwarded and C_Timer and C_Timer.After then
                    C_Timer.After(0.5, SendNextRequest)
                elseif not requestWasForwarded then
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end
            SendNextRequest()
        end
    end)
end

-- Verarbeitet eingehende Addon-Nachrichten.
local function HandleAddonMessage(prefix, message, channel, sender)
    if prefix ~= SchlingelInc.prefix then return end
    -- if not CanGuildInvite() then return end -- Optional: Nur Offiziere verarbeiten

    local name, levelStr, expStr, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
    if name and levelStr then
        local level = tonumber(levelStr)
        local exp = tonumber(expStr)

        for _, existing in ipairs(inviteRequests) do
            if existing.name == name then return end
        end

        table.insert(inviteRequests, { name = name, level = level, exp = exp, zone = zone, money = money })
        SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, level, zone))

        RefreshAllRequestUIs()
    end
end

-- Hilfsfunktion zum Aktualisieren aller relevanten UIs nach einer Änderung der Anfragenliste.
-- Wird jetzt nur das Offi-Fenster aktualisieren, wenn es offen ist.
local function RefreshAllRequestUIs()
    if SchlingelInc.OffiWindow and SchlingelInc.OffiWindow:IsShown() and SchlingelInc.OffiWindow.UpdateRecruitmentTabData then
        SchlingelInc.OffiWindow:UpdateRecruitmentTabData(inviteRequests)
    end
end

-- Verarbeitet das Akzeptieren einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
        return
    end

    local found = false
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            found = true
            break
        end
    end

    if found then
        RefreshAllRequestUIs()
    end
end

-- Verarbeitet das Ablehnen einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")

    local found = false
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            found = true
            break
        end
    end

    if found then
        RefreshAllRequestUIs()
    end
end

-- Initialisiert die Slash-Befehle für das Addon.
function SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    SLASH_SCHLINGELINC1 = "/schlingel"
    SLASH_SCHLINGELINC2 = "/si"

    SlashCmdList["SCHLINGELINC"] = function(msg)
        local cmd, param = msg:match("^(%S+)%s*(.-)$")
        cmd = cmd and cmd:lower() or ""
        param = param == "" and nil or param

        -- In self.GuildRecruitment aufrufen, damit die Methoden korrekt referenziert sind
        local GR = SchlingelInc.GuildRecruitment

        if cmd == "request" and param == "main" then
            GR:SendGuildRequest("Schlingel Inc")
        elseif cmd == "request" and param == "twink" then
            GR:SendGuildRequest("Schlingel IInc")
        -- ENTFERNT: elseif cmd == "requests" then ...
        elseif cmd == "debug" then
            DEBUG_MODE = not DEBUG_MODE
            SchlingelInc:Print("DEBUG MODE " .. (DEBUG_MODE and "AKTIVIERT." or "DEAKTIVIERT."))
        elseif cmd == "addtestdata" then
            table.insert(inviteRequests, { name = "TestUser1-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Durotar", money = random(1,100).."g" })
            table.insert(inviteRequests, { name = "TestUser2-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Elwynn", money = random(1,100).."s" })
            table.insert(inviteRequests, { name = "TestUser3-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Darkshore", money = random(1,100).."c" })
            SchlingelInc:Print("Testdaten hinzugefügt.")
            RefreshAllRequestUIs()
        elseif cmd == "offi" then
            if SchlingelInc.ToggleOffiWindow then
                SchlingelInc:ToggleOffiWindow()
            else
                SchlingelInc:Print("Offi Interface Modul nicht geladen.")
            end
        else
            SchlingelInc:Print("Befehle: /si [offi|request main|request twink|debug|addtestdata]") -- Angepasste Hilfe
        end
    end
end

-- Globaler Event-Handler-Frame für eingehende Addon-Nachrichten.
local addonMessageGlobalHandlerFrame = CreateFrame("Frame")
addonMessageGlobalHandlerFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageGlobalHandlerFrame:SetScript("OnEvent", function(selfFrame, event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...)
    end
end)

-- Ruft die Initialisierungsfunktion für Slash-Befehle auf.
SchlingelInc.GuildRecruitment:InitializeSlashCommands()