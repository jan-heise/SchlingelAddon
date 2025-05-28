-- Stellt sicher, dass die Haupt-Addon-Tabelle und die UIHelpers existieren
SchlingelInc = SchlingelInc or {}
SchlingelInc.UIHelpers = SchlingelInc.UIHelpers or {}

-- Konstanten für Addon-Namen und Frame-Namen, um Tippfehler zu vermeiden
local ADDON_NAME = SchlingelInc.name or "SchlingelInc"
local SCHLINGEL_INTERFACE_FRAME_NAME = ADDON_NAME .. "SchlingelInterfaceFrame"
local TAB_BUTTON_NAME_PREFIX = ADDON_NAME .. "SchlingelInterfaceTab"

-- Schriftart-Konstanten für konsistente UI-Gestaltung
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"
local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL = "GameFontNormalSmall"

-- Standard-Hintergrundeinstellungen für Frames
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

-- Regeltexte, die im Info-Tab angezeigt werden
local Rulestext = {
    "Die Nutzung des Briefkastens ist verboten!",
    "Die Nutzung des Auktionshauses ist verboten!",
    "Gruppen mit Spielern außerhalb der Gilden sind verboten!",
    "Handeln mit Spielern außerhalb der Gilden ist verboten!"
}

-- Hilfsfunktion zur Formatierung von Sekunden in einen d/h/m String
local function FormatSeconds(totalSeconds)
    if totalSeconds and totalSeconds > 0 then
        local d = math.floor(totalSeconds / 86400)
        local h = math.floor((totalSeconds % 86400) / 3600)
        local m = math.floor((totalSeconds % 3600) / 60)
        return string.format("%dd %dh %dm", d, h, m)
    elseif totalSeconds == 0 then
        return "0d 0h 0m" -- Zeigt 0 explizit an, wenn die Spielzeit genau 0 ist.
    else
        return "Lade..."  -- Zeigt "Lade..." an, wenn Daten nil sind (z.B. noch nicht vom Server empfangen).
    end
end


--------------------------------------------------------------------------------
-- Funktionen zur Erstellung der Tab-Inhalte
--------------------------------------------------------------------------------

-- Tab 1: Charakter-Informationen
function SchlingelInc:_CreateCharacterTabContent_SchlingelInterface(parentFrame)
    -- Erstellt den Hauptframe für diesen Tab
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "CharacterTabSI", parentFrame)
    tabFrame:SetAllPoints(true) -- Füllt den gesamten parentFrame aus

    -- Erstellt einen inneren Frame für den Inhalt mit etwas Abstand
    local contentFrame = CreateFrame("Frame", nil, tabFrame)
    contentFrame:SetPoint("TOPLEFT", 20, -20)
    contentFrame:SetPoint("BOTTOMRIGHT", -20, 20)

    -- Definiert Spaltenpositionen und Zeilenhöhe
    local xCol1 = 0
    local xCol2 = contentFrame:GetWidth() * 0.55 -- Rechte Spalte beginnt bei 55% der Breite
    local lineHeight = 22
    local currentY_Col1 = 0                      -- Aktuelle Y-Position für Spalte 1
    local currentY_Col2 = 0                      -- Aktuelle Y-Position für Spalte 2

    -- --- Spalte 1: Allgemeine Charakterdaten ---
    tabFrame.playerNameText = self.UIHelpers:CreateStyledText(contentFrame, "Name: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.levelText = self.UIHelpers:CreateStyledText(contentFrame, "Level: ...", FONT_NORMAL, "TOPLEFT", contentFrame,
        "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.classText = self.UIHelpers:CreateStyledText(contentFrame, "Klasse: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.raceText = self.UIHelpers:CreateStyledText(contentFrame, "Rasse: ...", FONT_NORMAL, "TOPLEFT", contentFrame,
        "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.zoneText = self.UIHelpers:CreateStyledText(contentFrame, "Zone: ...", FONT_NORMAL, "TOPLEFT", contentFrame,
        "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.deathCountText = self.UIHelpers:CreateStyledText(contentFrame, "Tode: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, currentY_Col1)

    -- --- Spalte 2: Weitere Charakterdaten ---
    tabFrame.moneyText = self.UIHelpers:CreateStyledText(contentFrame, "Geld: ...", FONT_NORMAL, "TOPLEFT", contentFrame,
        "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    tabFrame.xpText = self.UIHelpers:CreateStyledText(contentFrame, "XP: ...", FONT_NORMAL, "TOPLEFT", contentFrame,
        "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    -- Spielzeit-Felder initial mit "Lade..." erstellen, da diese asynchron geladen werden
    tabFrame.timePlayedTotalText = self.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Gesamt): Lade...",
        FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    tabFrame.timePlayedLevelText = self.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Level): Lade...",
        FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)

    -- --- Gildeninformationen unterhalb der beiden Spalten ---
    local guildYStart = math.min(currentY_Col1, currentY_Col2) - (lineHeight * 2) -- Startet unter der kürzeren Spalte
    tabFrame.guildNameText = self.UIHelpers:CreateStyledText(contentFrame, "Gilde: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, guildYStart)
    guildYStart = guildYStart - lineHeight
    tabFrame.guildRankText = self.UIHelpers:CreateStyledText(contentFrame, "Gildenrang: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, guildYStart)
    guildYStart = guildYStart - lineHeight
    tabFrame.guildMembersText = self.UIHelpers:CreateStyledText(contentFrame, "Mitglieder: ...", FONT_NORMAL, "TOPLEFT",
        contentFrame, "TOPLEFT", xCol1, guildYStart)

    -- Update-Funktion für diesen Tab, um die angezeigten Werte zu aktualisieren
    tabFrame.Update = function(selfTab)
        -- Aktualisiert die Position der rechten Spalte, falls sich die Fensterbreite geändert hat
        xCol2 = contentFrame:GetWidth() * 0.55
        selfTab.moneyText:ClearAllPoints()
        selfTab.moneyText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, 0)

        local currentY_Col2_Update = 0 - lineHeight
        selfTab.xpText:ClearAllPoints()
        selfTab.xpText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

        currentY_Col2_Update = currentY_Col2_Update - lineHeight
        selfTab.timePlayedTotalText:ClearAllPoints()
        selfTab.timePlayedTotalText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

        currentY_Col2_Update = currentY_Col2_Update - lineHeight
        selfTab.timePlayedLevelText:ClearAllPoints()
        selfTab.timePlayedLevelText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

        -- Liest aktuelle Spielerdaten
        local pName = UnitName("player") or "Unbekannt"
        local pLevel = UnitLevel("player") or 0
        local pClassLoc, pClassToken = UnitClass("player")
        pClassLoc = pClassLoc or "Unbekannt"
        local pRaceLoc, _ = UnitRace("player")
        pRaceLoc = pRaceLoc or "Unbekannt"
        local currentZone = GetZoneText() or "Unbekannt"
        local pMoney = GetMoneyString(GetMoney(), true) or "0c"

        -- Setzt die Texte der UI-Elemente
        selfTab.playerNameText:SetText("Name: " .. pName)
        selfTab.levelText:SetText("Level: " .. pLevel)

        local classColor = pClassToken and RAID_CLASS_COLORS[pClassToken]
        if classColor then
            selfTab.classText:SetText(string.format("Klasse: |cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g *
                255, classColor.b * 255, pClassLoc))
        else
            selfTab.classText:SetText("Klasse: " .. pClassLoc)
        end
        selfTab.raceText:SetText("Rasse: " .. pRaceLoc)
        selfTab.zoneText:SetText("Zone: " .. currentZone)
        selfTab.moneyText:SetText("Geld: " .. pMoney)

        local deaths = CharacterDeaths or 0
        selfTab.deathCountText:SetText("Tode: " .. deaths)

        local currentXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local restXP = GetXPExhaustion()
        if pLevel == MAX_PLAYER_LEVEL then
            selfTab.xpText:SetText("XP: Max Level")
        else
            local xpString = string.format("XP: %s / %s", currentXP, maxXP)
            if restXP and restXP > 0 then
                xpString = xpString .. string.format(" (|cff80c0ff+%.0f Erholt|r)", restXP)
            end
            selfTab.xpText:SetText(xpString)
        end

        -- Liest die globalen Spielzeit-Variablen (in Sekunden) aus der SchlingelInc Tabelle
        local timePlayedTotalSeconds = SchlingelInc.GameTimeTotal
        local timePlayedLevelSeconds = SchlingelInc.GameTimePerLevel

        -- Verwendet die FormatSeconds Hilfsfunktion zur Anzeige
        selfTab.timePlayedTotalText:SetText("Spielzeit (Gesamt): " .. FormatSeconds(timePlayedTotalSeconds))
        selfTab.timePlayedLevelText:SetText("Spielzeit (Level): " .. FormatSeconds(timePlayedLevelSeconds))

        -- Liest und zeigt Gildeninformationen an
        local gName, gRank = GetGuildInfo("player")
        if gName then
            local numTotal, numOnline = GetNumGuildMembers()
            selfTab.guildNameText:SetText("Gilde: " .. gName)
            selfTab.guildRankText:SetText("Gildenrang: " .. (gRank or "Unbekannt"))
            selfTab.guildMembersText:SetText(string.format("Mitglieder: %d (%d Online)", numTotal or 0, numOnline or 0))
            selfTab.guildNameText:Show()
            selfTab.guildRankText:Show()
            selfTab.guildMembersText:Show()
        else
            selfTab.guildNameText:SetText("Gilde: Nicht in einer Gilde")
            selfTab.guildRankText:Hide()
            selfTab.guildMembersText:Hide()
        end
    end
    return tabFrame
end

-- Tab 2: Info / Übersicht (MOTD, Regeln)
function SchlingelInc:_CreateInfoTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "InfoTabSI", parentFrame)
    tabFrame:SetAllPoints(true)

    local currentY = -20                                            -- Start Y-Position
    local leftPadding = 20                                          -- Linker Randabstand
    local contentWidth = parentFrame:GetWidth() - (leftPadding * 2) -- Verfügbare Breite für Textblöcke
    local textBlockSpacing = -20                                    -- Zusätzlicher Abstand zwischen Textblöcken

    -- Gilden-MOTD Label
    tabFrame.motdLabel = self.UIHelpers:CreateStyledText(tabFrame, "Gilden-MOTD:", FONT_NORMAL, "TOPLEFT", tabFrame,
        "TOPLEFT", leftPadding, currentY)
    currentY = currentY - tabFrame.motdLabel:GetHeight() - 7 -- Y-Position für MOTD Text (mit mehr Abstand)
    -- Gilden-MOTD Textfeld (mehrzeilig)
    tabFrame.motdTextDisplay = self.UIHelpers:CreateStyledText(tabFrame, "Lade MOTD...", FONT_NORMAL, "TOPLEFT", tabFrame,
        "TOPLEFT", leftPadding, currentY, contentWidth, 100, "LEFT", "TOP")
    currentY = currentY - 100 + textBlockSpacing -- Y-Position für das nächste Element

    -- Regeln Label
    tabFrame.rulesLabel = self.UIHelpers:CreateStyledText(tabFrame, "Regeln der Gilden:", FONT_NORMAL, "TOPLEFT",
        tabFrame, "TOPLEFT", leftPadding, currentY)
    currentY = currentY - tabFrame.rulesLabel:GetHeight() - 7 -- Y-Position für Regeltext (mit mehr Abstand)
    -- Regeln Textfeld (mehrzeilig)
    local ruleTextContent = ""
    for i, value in ipairs(Rulestext) do
        ruleTextContent = ruleTextContent .. "• " .. value
        if i < #Rulestext then
            ruleTextContent = ruleTextContent .. "\n\n" -- Zwei Zeilenumbrüche für besseren Abstand
        else
            ruleTextContent = ruleTextContent .. "\n"   -- Ein Zeilenumbruch am Ende
        end
    end
    tabFrame.rulesTextDisplay = self.UIHelpers:CreateStyledText(tabFrame, ruleTextContent, FONT_NORMAL, "TOPLEFT",
        tabFrame, "TOPLEFT", leftPadding, currentY, contentWidth, 150, "LEFT", "TOP")

    -- Update-Funktion für diesen Tab
    tabFrame.Update = function(selfTab)
        local guildMOTD = GetGuildRosterMOTD()
        if guildMOTD and guildMOTD ~= "" then
            selfTab.motdTextDisplay:SetText(guildMOTD)
        else
            selfTab.motdTextDisplay:SetText("Keine Gilden-MOTD festgelegt.")
        end
    end
    return tabFrame
end

-- Tab 3: Community / Kanäle & Gilde
function SchlingelInc:_CreateCommunityTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "CommunityTabSI", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Definiert Dimensionen und Abstände für Buttons
    local buttonWidth = 220
    local buttonHeight = 30
    local buttonSpacingY = 10
    -- Berechnet X-Positionen für zwei Spalten, zentriert
    local col1X = (parentFrame:GetWidth() - (buttonWidth * 2 + 40)) / 2
    local col2X = col1X + buttonWidth + 40
    local currentY_Labels = -20                   -- Y-Position für Spaltenüberschriften
    local currentY_Buttons = currentY_Labels - 30 -- Y-Position für die erste Button-Reihe

    -- --- Spalte 1: Gildenbeitritt ---
    self.UIHelpers:CreateStyledText(tabFrame, "Gildenbeitritt:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", col1X,
        currentY_Labels)
    local currentY_Col1_Buttons = currentY_Buttons
    local joinMainGuildBtnFunc = function()
        if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.SendGuildRequest then
            SchlingelInc.GuildRecruitment:SendGuildRequest("Schlingel Inc")
        else
            SchlingelInc:Print("Fehler - GuildRecruitment Modul nicht gefunden.")
        end
    end
    self.UIHelpers:CreateStyledButton(tabFrame, "Schlingel Inc beitreten", buttonWidth, buttonHeight, "TOPLEFT", tabFrame,
        "TOPLEFT", col1X, currentY_Col1_Buttons, "UIPanelButtonTemplate", joinMainGuildBtnFunc)
    currentY_Col1_Buttons = currentY_Col1_Buttons - buttonHeight - buttonSpacingY

    -- --- Spalte 2: Chatkanäle ---
    self.UIHelpers:CreateStyledText(tabFrame, "Chatkanäle:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", col2X,
        currentY_Labels)
    local currentY_Col2_Buttons = currentY_Buttons
    -- Funktion, die ausgeführt wird, wenn der "Globale Kanäle verlassen"-Button geklickt wird.
    local leaveChannelsBtnFunc = function()
        -- Liste von Namensmustern für Kanäle, die verlassen werden sollen.
        -- Dies ermöglicht das Verlassen von Kanälen, auch wenn der genaue Name leicht variiert (z.B. durch Nummerierung).
        local channelsToLeavePatterns = {
            "Allgemein",          -- Sucht nach "Allgemein" (z.B. "1. Allgemein - Stadt")
            "General",            -- Englische Variante
            "Handel",             -- Sucht nach "Handel"
            "Trade",              -- Englische Variante
            "LokaleVerteidigung", -- Sucht nach "LokaleVerteidigung"
            "LocalDefense",       -- Englische Variante
            "SucheNachGruppe",    -- Sucht nach "SucheNachGruppe"
            "LookingForGroup",    -- Englische Variante
            "WeltVerteidigung",   -- Sucht nach "WeltVerteidigung"
            "WorldDefense"        -- Englische Variante
        }

        -- Tabelle, um die Namen der tatsächlich verlassenen Kanäle zu speichern.
        local channelsActuallyLeft = {}

        -- Ruft die Liste der aktuell beigetretenen Kanäle ab.
        -- GetChannelList() gibt eine flache Liste zurück: id1, name1, flags1, id2, name2, flags2, ...
        local joinedChannelInfo = { GetChannelList() }

        -- Iteriert durch die Informationen der beigetretenen Kanäle.
        -- Jeder Kanal belegt 3 Plätze in der 'joinedChannelInfo'-Tabelle (ID, Name, Flags).
        local i = 1
        while i <= #joinedChannelInfo do
            -- local channelID = joinedChannelInfo[i] -- Die Kanal-ID wird hier nicht unbedingt benötigt.
            local channelName = joinedChannelInfo[i + 1] -- Der Name des Kanals.
            -- local channelFlags = joinedChannelInfo[i+2] -- Flags könnten Informationen über den Kanaltyp enthalten.

            -- Stellt sicher, dass ein Kanalname vorhanden ist.
            if channelName then
                -- Iteriert durch die Muster der zu verlassenden Kanäle.
                for _, patternToLeave in ipairs(channelsToLeavePatterns) do
                    -- Konvertiert den aktuellen Kanalnamen und das Muster in Kleinbuchstaben für einen nicht-case-sensitiven Vergleich.
                    local lowerChannelName = string.lower(channelName)
                    local lowerPattern = string.lower(patternToLeave)

                    -- Überprüft, ob das Muster im Kanalnamen enthalten ist (einfacher Teilstring-Vergleich).
                    -- Der Parameter 'true' bei string.find aktiviert den "plain" Modus für literale Vergleiche.
                    if string.find(lowerChannelName, lowerPattern, 1, true) then
                        -- Versucht, den Kanal zu verlassen.
                        LeaveChannelByName(channelName, nil)
                        -- Fügt den Namen des verlassenen Kanals zur Liste hinzu.
                        table.insert(channelsActuallyLeft, channelName)
                        -- Gibt eine Bestätigungsnachricht im Chat aus.
                        SchlingelInc:Print("Verlasse Kanal '" .. channelName .. "'")
                        -- Bricht die innere Schleife ab, da ein passendes Muster für diesen Kanal gefunden wurde.
                        break
                    end
                end
            end
            -- Geht zu den Informationen des nächsten Kanals (springt 3 Elemente weiter).
            i = i + 3
        end

        -- Gibt eine Nachricht aus, falls keine der zu verlassenden Kanäle gefunden wurden.
        if #channelsActuallyLeft == 0 then
            SchlingelInc:Print("Keine der zu verlassenden globalen Kanäle gefunden.")
        end
    end

    -- Erstellt den Button "Globale Kanäle verlassen".
    local col2X = col1X + buttonWidth + 40         -- Definiert an anderer Stelle im Code
    local currentY_Col2_Buttons = currentY_Buttons -- Definiert an anderer Stelle im Code
    self.UIHelpers:CreateStyledButton(tabFrame, "Globale Kanäle verlassen", buttonWidth, buttonHeight, "TOPLEFT",
        tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", leaveChannelsBtnFunc)
    currentY_Col2_Buttons = currentY_Col2_Buttons - buttonHeight - buttonSpacingY
    -- ... (Rest der Funktion) ...

    local joinChannelsBtnFunc = function()
        local cID = ChatFrame1 and ChatFrame1:GetID()
        if not cID then
            SchlingelInc:Print(ADDON_NAME .. ": Konnte ChatFrame1 ID nicht ermitteln.")
            return
        end
        JoinChannelByName("SchlingelTrade", nil, cID)
        JoinChannelByName("SchlingelGroup", nil, cID)
        SchlingelInc:Print("Versuche Schlingel-Chats beizutreten.")
    end
    self.UIHelpers:CreateStyledButton(tabFrame, "Schlingel-Chats beitreten", buttonWidth, buttonHeight, "TOPLEFT",
        tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", joinChannelsBtnFunc)

    -- --- Informationen unterhalb der Buttons (Discord, Version) ---
    local infoY = math.min(currentY_Col1_Buttons, currentY_Col2_Buttons) - buttonHeight - (buttonSpacingY * 2)
    local infoWidth = (buttonWidth * 2) + 30 -- Breite über beide Spalten

    tabFrame.discordText = self.UIHelpers:CreateStyledText(tabFrame, "Discord: ...", FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY,
        infoWidth, nil, "CENTER")
    infoY = infoY - 25 -- Mehr Abstand zwischen Discord und Version

    tabFrame.versionText = self.UIHelpers:CreateStyledText(tabFrame, "Version: ...", FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY,
        infoWidth, nil, "CENTER")

    -- Update-Funktion für diesen Tab
    tabFrame.Update = function(selfTab)
        selfTab.discordText:SetText("Discord: " .. (SchlingelInc.discordLink or "N/A"))
        selfTab.versionText:SetText("Version: " .. (SchlingelInc.version or "N/A"))
    end
    return tabFrame
end

-- Tab 4: Todeslog (mit ScrollFrame)
function SchlingelInc:_CreateDeathlogTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "DeathlogTab", parentFrame)
    tabFrame:SetAllPoints(true)

    local headerFont = FONT_NORMAL
    local contentFont = FONT_SMALL
    local leftPadding, topPadding = 10, -10
    local rowHeight = 20
    local visibleRows = 10
    local headers = { "Name", "Klasse", "Level", "Zone", "Todesursache" }
    local columnWidths = { 120, 80, 40, 110, 180 }

    -- Überschriften
    for i, text in ipairs(headers) do
        local xOffset = leftPadding
        for j = 1, i - 1 do
            xOffset = xOffset + columnWidths[j] + 10
        end
        SchlingelInc.UIHelpers:CreateStyledText(tabFrame, text, headerFont, "TOPLEFT", tabFrame, "TOPLEFT", xOffset,
            topPadding)
    end

    -- ScrollFrame + ContentFrame
    local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME .. "DeathlogScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", leftPadding, topPadding - 30)
    scrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -30, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    tabFrame.rows = {}

    for i = 1, 100 do
        local row = {}
        local yOffset = -((i - 1) * rowHeight)
        local xOffset = 0

        for j = 1, #headers do
            local cell = SchlingelInc.UIHelpers:CreateStyledText(content, "", contentFont, "TOPLEFT", content, "TOPLEFT",
                xOffset, yOffset)
            table.insert(row, cell)
            xOffset = xOffset + columnWidths[j] + 10
        end
        table.insert(tabFrame.rows, row)
    end

    -- Update-Funktion
    tabFrame.Update = function(selfTab)
        local data = SchlingelInc.DeathLogData or {}

        -- Lokalisierter Name -> Token-Mapping vorbereiten (z. B. "Hexenmeister" → "WARLOCK")
        local localizedToToken = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
            localizedToToken[name] = token
        end
        for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
            localizedToToken[name] = token -- sicherstellen, dass auch weibliche Namen korrekt erkannt werden
        end

        for i, row in ipairs(selfTab.rows) do
            local entry = data[i]
            if entry then
                row[1]:SetText(entry.name)
                -- Klassenfarbe
                local classToken = localizedToToken[entry.class]
                local color = classToken and RAID_CLASS_COLORS[classToken]

                if color then
                    row[2]:SetText(string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, entry.class))
                else
                    row[2]:SetText(entry.class)
                end

                row[3]:SetText(tostring(entry.level))
                row[4]:SetText(entry.zone)
                row[5]:SetText(entry.cause or "Unbekannt")
                for _, cell in ipairs(row) do cell:Show() end
            else
                for _, cell in ipairs(row) do
                    cell:SetText("")
                    cell:Hide()
                end
            end
        end

        -- Höhe dynamisch anpassen
        content:SetHeight(math.max(#data * rowHeight, visibleRows * rowHeight))
    end

    return tabFrame
end

--------------------------------------------------------------------------------
-- Hauptfunktion zur Erstellung des SchlingelInterface-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:CreateInfoWindow()
    -- Wenn das Fenster bereits existiert, zeige es einfach an und kehre zurück
    if self.infoWindow then
        self.infoWindow:Show()
        return
    end

    -- Erstellt den Hauptframe für das Interface
    local mainFrame = CreateFrame("Frame", SCHLINGEL_INTERFACE_FRAME_NAME, UIParent, "BackdropTemplate")
    mainFrame:SetSize(600, 420)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetBackdrop(BACKDROP_SETTINGS)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("MEDIUM") -- Stellt sicher, dass es über den meisten UI-Elementen liegt
    mainFrame:Hide()                   -- Standardmäßig versteckt

    -- Fenstertitel
    self.UIHelpers:CreateStyledText(mainFrame, "Schlingel Inc Interface", FONT_HIGHLIGHT_LARGE, "TOP", mainFrame, "TOP",
        0, -15)
    -- Schließen-Button
    local closeButtonFunc = function() mainFrame:Hide() end
    self.UIHelpers:CreateStyledButton(mainFrame, nil, 22, 22, "TOPRIGHT", mainFrame, "TOPRIGHT", -7, -7,
        "UIPanelCloseButton", closeButtonFunc)

    -- Container für die Tab-Inhalte
    local tabContentContainer = CreateFrame("Frame", ADDON_NAME .. "SITabContentContainer", mainFrame)
    tabContentContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -50)
    tabContentContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 45)

    -- Tabellen zur Speicherung der Tab-Buttons und Inhaltsframes
    local tabButtons = {}
    mainFrame.tabContentFrames = {}
    mainFrame.selectedTab = 1 -- Standardmäßig ist der erste Tab ausgewählt

    -- Funktion zum Wechseln des Tabs
    local function SelectTab(tabIndex)
        mainFrame.selectedTab = tabIndex
        for index, button in ipairs(tabButtons) do
            local contentFrame = mainFrame.tabContentFrames[index]
            if contentFrame then
                if index == tabIndex then
                    PanelTemplates_SelectTab(button) -- Visuelle Auswahl des Buttons
                    contentFrame:Show()
                    if contentFrame.Update then      -- Ruft die Update-Funktion des Tabs auf, falls vorhanden
                        contentFrame:Update(contentFrame)
                    end
                else
                    PanelTemplates_DeselectTab(button) -- Visuelle Abwahl des Buttons
                    contentFrame:Hide()
                end
            end
        end
    end

    -- Definitionen der Tabs (Name und Erstellungsfunktion)
    local tabDefinitions = {
        { name = "Charakter", CreateFunc = self._CreateCharacterTabContent_SchlingelInterface },
        { name = "Info",      CreateFunc = self._CreateInfoTabContent_SchlingelInterface },
        { name = "Community", CreateFunc = self._CreateCommunityTabContent_SchlingelInterface },
        { name = "Todeslog", CreateFunc = self._CreateDeathlogTabContent_SchlingelInterface }
    }

    -- Erstellt die Tab-Buttons und die zugehörigen Inhaltsframes
    local tabButtonWidth = 130
    local tabButtonSpacing = 5
    local initialXOffsetForTabs = 20
    for i, tabDef in ipairs(tabDefinitions) do
        local button = CreateFrame("Button", TAB_BUTTON_NAME_PREFIX .. i, mainFrame, "OptionsFrameTabButtonTemplate")
        button:SetID(i)
        button:SetText(tabDef.name)
        button:SetWidth(tabButtonWidth)
        button:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
            initialXOffsetForTabs + (i - 1) * (tabButtonWidth + tabButtonSpacing), 12)
        button:GetFontString():SetPoint("CENTER", 0, 1) -- Zentriert den Text im Button
        local selectThisTabFunc = function() SelectTab(i) end
        button:SetScript("OnClick", selectThisTabFunc)
        PanelTemplates_DeselectTab(button) -- Standardmäßig nicht ausgewählt
        tabButtons[i] = button

        if tabDef.CreateFunc then
            local newTab = tabDef.CreateFunc(self, tabContentContainer)
            if newTab then
                newTab:Hide() -- Standardmäßig versteckt
                mainFrame.tabContentFrames[i] = newTab
            end
        end
    end

    -- Speichert Referenz zum Hauptfenster und wählt den ersten Tab aus
    self.infoWindow = mainFrame
    if #tabButtons > 0 then
        SelectTab(1)
    end
    mainFrame:Show() -- Zeigt das Fenster nach der Erstellung an
end

-- Funktion zum Anzeigen/Verstecken des Info-Fensters
function SchlingelInc:ToggleInfoWindow()
    if not self.infoWindow then
        self:CreateInfoWindow() -- Erstellt das Fenster, falls es noch nicht existiert
    elseif self.infoWindow:IsShown() then
        self.infoWindow:Hide()
    else
        self.infoWindow:Show()
        -- Aktualisiert den Inhalt des aktuell sichtbaren Tabs beim Anzeigen
        local activeTabIndex = self.infoWindow.selectedTab or 1
        local activeTabFrame = self.infoWindow.tabContentFrames and self.infoWindow.tabContentFrames[activeTabIndex]
        if activeTabFrame and activeTabFrame:IsShown() and activeTabFrame.Update then
            activeTabFrame:Update(activeTabFrame)
        end
    end
end