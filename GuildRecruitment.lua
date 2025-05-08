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
        -- Im Debug-Modus wird die Nachricht direkt an einen bestimmten Spieler gesendet.
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Pudidev")
            SchlingelInc:Print("Gildenanfrage im DEBUG_MODE an Pudidev gesendet.")
        else
            SchlingelInc:Print("DEBUG_MODE: C_ChatInfo nicht verfügbar.")
        end
        return
    end

    -- Sendet eine /who-Abfrage für die angegebene Gilde.
    if C_FriendList and C_FriendList.SendWho then
        local whoString = string.format('g-"%s"', guildName) -- Format für Gildensuche
        C_FriendList.SendWho(whoString)
    else
        SchlingelInc:Print("WHO-Funktion nicht verfügbar.")
        return
    end

    -- Versteckt das Freundesfenster (FriendsFrame), falls es durch /who geöffnet wurde.
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
            if FriendsFrame and FriendsFrame:IsShown() then
                HideUIPanel(FriendsFrame)
            end
        end)
    end

    -- Temporärer Frame, um auf das "WHO_LIST_UPDATE"-Event zu warten.
    local whoFrameHandler = CreateFrame("Frame")
    whoFrameHandler:RegisterEvent("WHO_LIST_UPDATE")
    whoFrameHandler:SetScript("OnEvent", function(selfEventFrame, event, ...)
        if event == "WHO_LIST_UPDATE" then
            selfEventFrame:UnregisterEvent("WHO_LIST_UPDATE") -- Event sofort deregistrieren.
            whoFrameHandler:Hide() -- Frame verstecken/aufräumen.

            if not C_FriendList or not C_FriendList.GetNumWhoResults then
                 SchlingelInc:Print("Fehler beim Verarbeiten der WHO-Antwort.")
                 return
            end

            local numResults = C_FriendList.GetNumWhoResults()
            if numResults == 0 then
                SchlingelInc:Print(string.format("Keine Ergebnisse für Gilde '%s' gefunden.", guildName))
                return
            end

            -- Variablen für das Senden der Anfragen an die gefundenen Gildenmitglieder.
            local currentIndex = 1
            local maxWhoResults = numResults
            local requestWasForwarded = false -- Flag, ob die Anfrage bereits weitergeleitet wurde.

            -- Temporärer Frame, um auf eine Bestätigungs-Addon-Nachricht ("REQUEST_FORWARDED") zu warten.
            local addonMsgResponseHandler = CreateFrame("Frame")
            addonMsgResponseHandler:RegisterEvent("CHAT_MSG_ADDON")
            addonMsgResponseHandler:SetScript("OnEvent", function(_, eventArg, prefixArg, msgArg, channelArg, senderArg)
                if eventArg == "CHAT_MSG_ADDON" and prefixArg == SchlingelInc.prefix and msgArg == "REQUEST_FORWARDED" then
                    requestWasForwarded = true
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end)

            -- Funktion, die rekursiv versucht, die Anfrage an das nächste Gildenmitglied zu senden.
            local function SendNextRequest()
                if requestWasForwarded then -- Abbruch, wenn schon weitergeleitet.
                    SchlingelInc:Print("Anfrage gesendet.")
                    return
                end

                if currentIndex > maxWhoResults then -- Abbruch, wenn alle Mitglieder durchlaufen wurden.
                    SchlingelInc:Print("Anfrage konnte nicht an alle Mitglieder gesendet werden.")
                    SchlingelInc:Print("Bitte über Discord melden, falls keine Antwort kommt.")
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                    return
                end

                -- Sendet die Anfrage an das aktuelle Mitglied aus der /who-Liste.
                local info = C_FriendList.GetWhoInfo(currentIndex)
                if info and info.fullName and C_ChatInfo and C_ChatInfo.SendAddonMessage then
                    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", info.fullName)
                end

                currentIndex = currentIndex + 1
                -- Wartet kurz und versucht dann das nächste Mitglied, falls noch nicht weitergeleitet.
                if not requestWasForwarded and C_Timer and C_Timer.After then
                    C_Timer.After(0.5, SendNextRequest)
                elseif not requestWasForwarded then -- Keine weiteren Versuche, Handler aufräumen.
                    addonMsgResponseHandler:UnregisterEvent("CHAT_MSG_ADDON")
                    addonMsgResponseHandler:Hide()
                end
            end
            SendNextRequest() -- Startet den Sendevorgang.
        end
    end)
end

-- Verarbeitet eingehende Addon-Nachrichten.
local function HandleAddonMessage(prefix, message, channel, sender)
    -- Ignoriert Nachrichten, die nicht unserem Addon-Präfix entsprechen.
    if prefix ~= SchlingelInc.prefix then return end

    -- Optional: Nur Offiziere/berechtigte Spieler verarbeiten Anfragen (auskommentiert).
    -- if not CanGuildInvite() then return end

    -- Parst die "INVITE_REQUEST"-Nachricht.
    local name, levelStr, expStr, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
    if name and levelStr then
        local level = tonumber(levelStr)
        local exp = tonumber(expStr)

        -- Verhindert das Hinzufügen von Duplikaten.
        for _, existing in ipairs(inviteRequests) do
            if existing.name == name then return end
        end

        -- Fügt die neue Anfrage zur Liste hinzu.
        table.insert(inviteRequests, { name = name, level = level, exp = exp, zone = zone, money = money })
        SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, level, zone))

        -- Aktualisiert die UIs, falls sie sichtbar sind.
        RefreshAllRequestUIs()
    end
end

-- Aktualisiert das separate UI für Gildenanfragen (das mit /si requests geöffnet wird).
function SchlingelInc.GuildRecruitment:UpdateRequestUI_Separate()
    local ui = self.requestUI -- Referenz auf das separate UI-Fenster.
    if not ui or not ui:IsShown() then return end

    -- Entfernt alte UI-Elemente.
    if ui.requests then
        for _, requestFrame in ipairs(ui.requests) do
            requestFrame:Hide()
            requestFrame:SetParent(nil)
        end
        wipe(ui.requests)
    else
        ui.requests = {}
    end

    -- Zeichnet die Liste der Anfragen neu.
    if #inviteRequests > 0 then
        local yOffset = -5
        for i, request in ipairs(inviteRequests) do
            local requestFrame = CreateFrame("Frame", nil, ui.content)
            requestFrame:SetPoint("TOPLEFT", 5, yOffset - (i - 1) * 20)
            requestFrame:SetSize(ui.content:GetWidth() - 10, 20)
            ui.requests[i] = requestFrame

            -- Erstellt Textfelder für die Details jeder Anfrage.
            local nameText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", 0, 0); nameText:SetText(request.name); nameText:SetWidth(120)

            local levelText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            levelText:SetPoint("LEFT", nameText, "RIGHT", 10, 0); levelText:SetText(request.level); levelText:SetWidth(50); levelText:SetJustifyH("CENTER")

            local zoneText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            zoneText:SetPoint("LEFT", levelText, "RIGHT", 10, 0); zoneText:SetText(request.zone); zoneText:SetWidth(150)

            local goldText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            goldText:SetPoint("LEFT", zoneText, "RIGHT", 10, 0); goldText:SetText(request.money); goldText:SetWidth(100); goldText:SetJustifyH("RIGHT")
        end
        ui.content:SetHeight(#inviteRequests * 20 + 5)
        if ui.content.text then ui.content.text:Hide() end -- Versteckt "Keine Daten"-Text.
    else
        -- Zeigt "Keine Anfragen"-Text, wenn die Liste leer ist.
        if ui.content.text then
            ui.content.text:SetText("Keine Anfragen empfangen.")
            ui.content.text:Show()
        end
        ui.content:SetHeight(20)
    end
    if ui.scrollFrame then ui.scrollFrame:SetVerticalScroll(0) end -- Scrollbalken zurücksetzen.
end

-- Erstellt das separate UI-Fenster für Gildenanfragen.
local function CreateRequestUI()
    local ui = CreateFrame("Frame", "SchlingelRequestUI", UIParent, "BasicFrameTemplateWithInset")
    ui:SetSize(480, 400); ui:SetPoint("CENTER"); ui:SetMovable(true); ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton"); ui:SetScript("OnDragStart", ui.StartMoving); ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
    ui:SetFrameStrata("DIALOG") -- Stellt sicher, dass das Fenster über anderen UI-Elementen liegt.

    local closeButton = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() ui:Hide() end)

    ui.title = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); ui.title:SetPoint("TOP", 0, -5); ui.title:SetText("Gildenanfragen (Extern)")
    ui.scrollFrame = CreateFrame("ScrollFrame", nil, ui, "UIPanelScrollFrameTemplate"); ui.scrollFrame:SetSize(424, 340); ui.scrollFrame:SetPoint("TOP", 0, -28)
    ui.content = CreateFrame("Frame", nil, ui.scrollFrame); ui.scrollFrame:SetScrollChild(ui.content); ui.content:SetSize(ui.scrollFrame:GetWidth() - 20, 1)
    ui.content.text = ui.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); ui.content.text:SetPoint("TOPLEFT", 5, -5); ui.content.text:SetJustifyH("LEFT"); ui.content.text:SetText("Noch keine Daten...")
    ui.requests = {} -- Tabelle für die UI-Elemente der Anfragen in diesem Fenster.
    ui:Hide() -- Standardmäßig versteckt.
    return ui
end

-- Hilfsfunktion zum Aktualisieren aller relevanten UIs nach einer Änderung der Anfragenliste.
local function RefreshAllRequestUIs()
    -- Aktualisiert den Anfragen-Tab im Offi-Fenster, falls sichtbar.
    if SchlingelInc.OffiWindow and SchlingelInc.OffiWindow:IsShown() and SchlingelInc.OffiWindow.UpdateRecruitmentTabData then
        SchlingelInc.OffiWindow:UpdateRecruitmentTabData(inviteRequests)
    end
    -- Aktualisiert das separate Anfragen-Fenster, falls sichtbar.
    if SchlingelInc.GuildRecruitment.requestUI and SchlingelInc.GuildRecruitment.requestUI:IsShown() then
        -- Ruft die Update-Funktion des Moduls auf. 'self' ist hier implizit SchlingelInc.GuildRecruitment.
        SchlingelInc.GuildRecruitment:UpdateRequestUI_Separate()
    end
end

-- Verarbeitet das Akzeptieren einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    -- Prüft, ob der Spieler die Berechtigung zum Einladen hat.
    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName) -- Moderne API zum Einladen in Gilden.
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
        return -- Bricht ab, wenn keine Berechtigung vorhanden ist; Anfrage bleibt in der Liste.
    end

    -- Entfernt den Spieler aus der Anfragenliste, nachdem der Einladeversuch unternommen wurde.
    local found = false
    for i = #inviteRequests, 1, -1 do -- Rückwärts iterieren ist sicherer beim Entfernen.
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            found = true
            break
        end
    end

    if found then
        RefreshAllRequestUIs() -- Aktualisiert die Anzeigen.
    end
end

-- Verarbeitet das Ablehnen einer Gildenanfrage.
function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")

    -- Entfernt den Spieler aus der Anfragenliste.
    local found = false
    for i = #inviteRequests, 1, -1 do
        if inviteRequests[i].name == playerName then
            table.remove(inviteRequests, i)
            found = true
            break
        end
    end

    if found then
        RefreshAllRequestUIs() -- Aktualisiert die Anzeigen.
    end
end

-- Initialisiert die Slash-Befehle für das Addon.
function SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    SLASH_SCHLINGELINC1 = "/schlingel"
    SLASH_SCHLINGELINC2 = "/si"

    SlashCmdList["SCHLINGELINC"] = function(msg)
        -- Parst den Slash-Befehl und seine Parameter.
        local cmd, param = msg:match("^(%S+)%s*(.-)$")
        cmd = cmd and cmd:lower() or ""
        param = param == "" and nil or param

        -- Verarbeitet die verschiedenen Befehle.
        if cmd == "request" and param == "main" then
            self:SendGuildRequest("Schlingel Inc")
        elseif cmd == "request" and param == "twink" then
            self:SendGuildRequest("Schlingel IInc")
        elseif cmd == "requests" then
            -- Zeigt das separate Anfragen-Fenster.
            if not self.requestUI then
                self.requestUI = CreateRequestUI()
            end
            self.requestUI:Show()
            self:UpdateRequestUI_Separate()
        elseif cmd == "debug" then
            -- Schaltet den Debug-Modus um.
            DEBUG_MODE = not DEBUG_MODE
            SchlingelInc:Print("DEBUG MODE " .. (DEBUG_MODE and "AKTIVIERT." or "DEAKTIVIERT."))
        elseif cmd == "addtestdata" then
            -- Fügt Testdaten zur Anfragenliste hinzu.
            table.insert(inviteRequests, { name = "TestUser1-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Durotar", money = random(1,100).."g" })
            table.insert(inviteRequests, { name = "TestUser2-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Elwynn", money = random(1,100).."s" })
            table.insert(inviteRequests, { name = "TestUser3-"..random(100,999), level = random(1,60), exp = random(100,50000), zone = "Darkshore", money = random(1,100).."c" })
            SchlingelInc:Print("Testdaten hinzugefügt.")
            RefreshAllRequestUIs()
        elseif cmd == "offi" then
            -- Öffnet/Schließt das Haupt-Offi-Fenster.
            if SchlingelInc.ToggleOffiWindow then -- Stellt sicher, dass die Funktion aus OffiInterface.lua geladen ist.
                SchlingelInc:ToggleOffiWindow()
            else
                SchlingelInc:Print("Offi Interface Modul nicht geladen.")
            end
        else
            -- Gibt eine Hilfe-Nachricht aus, wenn der Befehl unbekannt ist.
            SchlingelInc:Print("Befehle: /si [offi|request main|request twink|requests|debug|addtestdata]")
        end
    end
end

-- Globaler Event-Handler-Frame für eingehende Addon-Nachrichten.
local addonMessageGlobalHandlerFrame = CreateFrame("Frame")
addonMessageGlobalHandlerFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageGlobalHandlerFrame:SetScript("OnEvent", function(selfFrame, event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...) -- Leitet die Nachricht an die Verarbeitungsfunktion weiter.
    end
end)

-- Ruft die Initialisierungsfunktion für Slash-Befehle auf.
SchlingelInc.GuildRecruitment:InitializeSlashCommands()