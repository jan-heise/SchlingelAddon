-- Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = {}

-- Lokale Variablen
local inviteRequests = {}

-- Funktion zum Senden einer Gildenanfrage
function SchlingelInc.GuildRecruitment:SendGuildRequest(guildName)
    -- Sicherstellen, dass ein Gildenname übergeben wurde
    if not guildName or guildName == "" then
        print("[Schlingel] Kein Gildenname angegeben.")
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

            local playerName = UnitName("player")
            local playerLevel = UnitLevel("player")
            local message = string.format("INVITE_REQUEST:%s:%d", playerName, playerLevel)

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
    if CanGuildInvite() then
        if prefix ~= SchlingelInc.prefix then return end

        -- INVITE_REQUEST-Nachricht verarbeiten
        local name, level = message:match("^INVITE_REQUEST:([^:]+):(%d+)$")
        if name and level then
            -- Überprüfen, ob die Anfrage bereits existiert
            for _, existing in ipairs(inviteRequests) do
                if existing.name == name then return end
            end

            -- Neue Anfrage hinzufügen
            table.insert(inviteRequests, { name = name, level = tonumber(level) })
            SchlingelInc:Print(string.format("Neue Gildenanfrage von %s (Level %d) erhalten.", name, level))

            -- UI aktualisieren, falls es sichtbar ist
            if SchlingelInc.GuildRecruitment.requestUI and SchlingelInc.GuildRecruitment.requestUI:IsShown() then
                SchlingelInc.GuildRecruitment:UpdateRequestUI()
            end
        end
    end
end

-- UI aktualisieren
function SchlingelInc.GuildRecruitment:UpdateRequestUI()
    local ui = self.requestUI
    if not ui then return end

    -- Vorhandene Inhalte löschen
    for _, child in ipairs({ ui.content:GetChildren() }) do
        child:Hide()
    end

    if #inviteRequests == 0 then
        ui.content.text:SetText("Keine Anfragen empfangen.")
        return
    end

    ui.content.text:SetText("")
    local yOffset = -10

    for i, req in ipairs(inviteRequests) do
        local row = CreateFrame("Frame", nil, ui.content)
        row:SetSize(424, 24)
        row:SetPoint("TOPLEFT", 0, yOffset)

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        text:SetText(req.name .. " (Level " .. req.level .. ")")

        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        inviteBtn:SetSize(80, 24)
        inviteBtn:SetPoint("RIGHT", -34, 0)
        inviteBtn:SetText("Einladen")
        inviteBtn:SetScript("OnClick", function()
            C_GuildInfo.Invite(req.name)
            table.remove(inviteRequests, i)
            self:UpdateRequestUI()
        end)

        local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        removeBtn:SetSize(24, 24)
        removeBtn:SetPoint("RIGHT", -2, 0)
        removeBtn:SetText("X")
        removeBtn:SetScript("OnClick", function()
            table.remove(inviteRequests, i)
            self:UpdateRequestUI()
        end)

        yOffset = yOffset - 28
    end
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
            self:SendGuildRequest("Schlingel Inc II")
        elseif msg == "requests" and CanGuildInvite() then
            if not self.requestUI then
                self.requestUI = CreateRequestUI()
            end
            self.requestUI:Show()
            self:UpdateRequestUI()
        else
            SchlingelInc:Print("Usage: /schlingel request [main/twink] or /schlingel requests")
        end
    end
end

-- Initialisierung
SchlingelInc.GuildRecruitment:InitializeSlashCommands()
