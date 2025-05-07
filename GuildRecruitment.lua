-- Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = {}

-- Lokale Variablen
local inviteRequests = {}

-- Debug-Flag: Bei Aktivierung wird die Anfrage direkt an Pudidev gesendet
local DEBUG_MODE = false -- Standardmäßig deaktiviert, zum Aktivieren auf true setzen

-- Funktion zum Senden einer Gildenanfrage
function SchlingelInc.GuildRecruitment:SendGuildRequest(guildName)
    -- if IsInGuild() then
    --     SchlingelInc:Print("Du bist bereits in einer Gilde.")
    --     return
    -- end

    -- einkommentieren sobald die Übergangsphase vorbei ist
    -- if UnitLevel("player") > 1 then
    -- SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
    -- return
    -- end

    -- Sicherstellen, dass ein Gildenname übergeben wurde
    if not guildName or guildName == "" then
        SchlingelInc:Print("Kein Gildenname angegeben.")
        return
    end

    if DEBUG_MODE then
        local playerName = UnitName("player")
        local playerLevel = UnitLevel("player")
        local playerExp = UnitXP("player")
        local zone, mapID
        mapID = C_Map.GetBestMapForUnit("player")
        zone = C_Map.GetMapInfo(mapID).name
        local money = GetMoney()
        local playerGold = GetMoneyString(money, true)
        local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", "Pudidev") -- Direkt an Pudidev
        SchlingelInc:Print("Gildenanfrage im DEBUG_MODE an Pudidev gesendet.")
        return
    end

    -- WHO-Abfrage senden
    local whoString = string.format('g-"%s"', guildName)
    C_FriendList.SendWho(whoString)

    C_Timer.After(0.5, function()
        if FriendsFrame:IsShown() then
            HideUIPanel(FriendsFrame)
        end
    end)

    -- Temporären Event-Handler erstellen
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("WHO_LIST_UPDATE")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "WHO_LIST_UPDATE" then
            local numResults = C_FriendList.GetNumWhoResults()
            if numResults == 0 then
                SchlingelInc:Print(string.format("Keine Ergebnisse für Gilde '%s' gefunden.", guildName))
                self:UnregisterEvent("WHO_LIST_UPDATE")
                return
            end

            -- Spieler Infos für den Invite vorbereiten
            local playerName = UnitName("player")
            local playerLevel = UnitLevel("player")
            local playerExp = UnitXP("player")
            local zone, mapID
            mapID = C_Map.GetBestMapForUnit("player")
            zone = C_Map.GetMapInfo(mapID).name
            local money = GetMoney()
            local playerGold = GetMoneyString(money, true)
            local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)

            local currentIndex = 1
            local maxWhoResults = C_FriendList.GetNumWhoResults()
            local requestWasForwarded = false

            -- Event-Frame zur Registrierung von Addon-Nachrichten
            local eventFrame = CreateFrame("Frame")
            eventFrame:RegisterEvent("CHAT_MSG_ADDON")
            eventFrame:SetScript("OnEvent", function(_, event, prefix, msg, _, sender)
                if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
                    if msg == "REQUEST_FORWARDED" then
                        requestWasForwarded = true
                    end
                end
            end)

            -- Funktion, um rekursiv durch die Who-Ergebnisse zu gehen
            local function SendNextRequest()
                -- Wenn wir eine Bestätigung bekommen haben, abbrechen
                if requestWasForwarded then
                    SchlingelInc:Print("Anfrage gesendet")
                    return
                end

                -- Wenn keine weiteren Ergebnisse übrig sind
                if currentIndex > maxWhoResults then
                    SchlingelInc:Print("Anfrage konnte nicht gesendet werden")
                    SchlingelInc:Print("Bitte über Discord melden")
                    return
                end

                local info = C_FriendList.GetWhoInfo(currentIndex)
                if info then
                    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", info.fullName)
                end

                currentIndex = currentIndex + 1

                -- Warte 0.5s, dann sende an den nächsten
                C_Timer.After(0.5, SendNextRequest)
            end

            -- Start der Anfragekette
            SendNextRequest()

            -- Deregistrieren, damit der Handler nicht aktiv bleibt
            self:UnregisterEvent("WHO_LIST_UPDATE")
        end
    end)
end

-- Addon-Nachrichten abfangen
local function HandleAddonMessage(prefix, message, _, sender)
    --if CanGuildInvite() then
        if prefix ~= SchlingelInc.prefix then return end

        -- INVITE_REQUEST-Nachricht verarbeiten
        local name, level, exp, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if name and level then
            -- Überprüfen, ob die Anfrage bereits existiert
            for _, existing in ipairs(inviteRequests) do
                if existing.name == name then return end
            end

            -- Neue Anfrage hinzufügen
            table.insert(inviteRequests, { name = name, level = tonumber(level), exp = tonumber(exp), zone = zone, money = money })
            SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) in %s erhalten.", name, level, zone))

            -- UI aktualisieren, falls es sichtbar ist
            if SchlingelInc.GuildRecruitment.requestUI and SchlingelInc.GuildRecruitment.requestUI:IsShown() then
                SchlingelInc.GuildRecruitment:UpdateRequestUI()
            end
        end
    --end
end

function SchlingelInc.GuildRecruitment:UpdateRequestUI()
    local ui = self.requestUI
    if not ui then return end

    -- Alle vorherigen Einträge entfernen
    for _, requestFrame in ipairs(ui.requests) do
        requestFrame:Hide()
        requestFrame:SetParent(nil)
    end
    wipe(ui.requests)

    if #inviteRequests > 0 then
        local yOffset = -30
        for i, request in ipairs(inviteRequests) do
            local requestFrame = CreateFrame("Frame", nil, ui.content)
            requestFrame:SetPoint("TOPLEFT", 5, yOffset - (i - 1) * 20)
            requestFrame:SetSize(550, 20)
            ui.requests[i] = requestFrame

            local nameText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", 0, 0)
            nameText:SetText(request.name)
            nameText:SetWidth(120)

            local levelText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            levelText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
            levelText:SetText(request.level)
            levelText:SetWidth(50)
            levelText:SetJustifyH("CENTER")

            local zoneText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            zoneText:SetPoint("LEFT", levelText, "RIGHT", 10, 0)
            zoneText:SetText(request.zone)
            zoneText:SetWidth(150)

            local goldText = requestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            goldText:SetPoint("LEFT", zoneText, "RIGHT", 10, 0)
            goldText:SetText(request.money)
            goldText:SetWidth(100)
            goldText:SetJustifyH("RIGHT")
        end
        ui.content:SetHeight(#inviteRequests * 20 + 5) -- Dynamische Höhe anpassen
    else
        ui.content.text:SetText("Keine Anfragen empfangen.")
        ui.content:SetHeight(20)
    end
    ui.scrollFrame:SetVerticalScroll(0)
end

-- Event-Handler für Addon-Nachrichten registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...)
    end
end)

-- UI für Gildenanfragen erstellen
local function CreateRequestUI()
    local ui = CreateFrame("Frame", "SchlingelRequestUI", UIParent, "BasicFrameTemplateWithInset")
    ui:SetSize(480, 400)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", ui.StopMovingOrSizing)

    ui.title = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    ui.title:SetPoint("TOP", 0, -2)
    ui.title:SetText("Anfragen")

    ui.scrollFrame = CreateFrame("ScrollFrame", nil, ui, "UIPanelScrollFrameTemplate")
    ui.scrollFrame:SetSize(424, 372)
    ui.scrollFrame:SetPoint("TOP", 0, -24)

    ui.content = CreateFrame("Frame", nil, ui.scrollFrame)
    ui.scrollFrame:SetScrollChild(ui.content)
    ui.content:SetSize(260, 280)

    ui.content.text = ui.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.content.text:SetPoint("TOPLEFT", 5, -5)
    ui.content.text:SetJustifyH("LEFT")
    ui.content.text:SetText("Noch keine Daten...")
    ui.requests = {}

    ui:Hide()
    return ui
end

-- Slash-Befehl für Gildenanfragen
function SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    SLASH_SCHLINGELINC1 = "/schlingel"
    SLASH_SCHLINGELINC2 = "/si"

    SlashCmdList["SCHLINGELINC"] = function(msg)
        if msg == "request main" then
            self:SendGuildRequest("Schlingel Inc")
        elseif msg == "request twink" then
            self:SendGuildRequest("Schlingel IInc")
        elseif msg == "requests" and CanGuildInvite() then
            if not self.requestUI then
                self.requestUI = CreateRequestUI()
            end
            self.requestUI:Show()
            self:UpdateRequestUI()
        elseif msg == "debug" then -- Neuer Debug-Befehl
            DEBUG_MODE = not DEBUG_MODE -- Toggle-Funktion
            if DEBUG_MODE then
                SchlingelInc:Print("DEBUG MODE AKTIVIERT: Anfragen werden direkt an Pudidev gesendet!")
            else
                SchlingelInc:Print("DEBUG MODE DEAKTIVIERT: Anfragen werden über /who gesendet.")
            end
        elseif msg == "addtestdata" then
            -- Füge 3 Testdaten hinzu
            table.insert(inviteRequests, { name = "TestUser1", level = 10, exp = 1000, zone = "Durotar", money = "5" })
            table.insert(inviteRequests, { name = "TestUser2", level = 20, exp = 2500, zone = "Elwynn Forest", money = "12" })
            table.insert(inviteRequests, { name = "TestUser3", level = 15, exp = 1800, zone = "Darkshore", money = "8" })
            if SchlingelInc.GuildRecruitment.requestUI and SchlingelInc.GuildRecruitment.requestUI:IsShown() then
                SchlingelInc.GuildRecruitment:UpdateRequestUI()
            end
        else
            SchlingelInc:Print("Usage: /schlingel request [main/twink] or /schlingel requests or /schlingel debug or /schlingel addtestdata")
        end
    end
end

-- Initialisierung
SchlingelInc.GuildRecruitment:InitializeSlashCommands()
