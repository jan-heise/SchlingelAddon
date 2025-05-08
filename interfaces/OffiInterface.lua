-- Stellt sicher, dass die Haupt-Addon-Tabelle existiert.
-- Wenn SchlingelInc noch nicht existiert, wird eine neue, leere Tabelle erstellt.
SchlingelInc = SchlingelInc or {}
-- SchlingelInc.UIHelpers Namespace wird als existent vorausgesetzt.
-- Dieser Namespace enthält Hilfsfunktionen zum Erstellen von UI-Elementen.

--------------------------------------------------------------------------------
-- Konstanten für das Addon-Interface
-- Diese Konstanten dienen dazu, feste Werte im Code leichter anpassbar
-- und lesbarer zu machen.
--------------------------------------------------------------------------------
local ADDON_PREFIX = SchlingelInc.name or "SchlingelInc" -- Basis-Präfix für UI-Elemente, um Namenskollisionen zu vermeiden.
local OFFIFRAME_NAME = ADDON_PREFIX .. "OffiFrame" -- Name des Hauptfensters des Addons.
local TAB_BUTTON_NAME_PREFIX = ADDON_PREFIX .. "OffiTab" -- Präfix für die Namen der Tab-Buttons.

-- Schriftarten-Konstanten
-- Definiert verschiedene Schriftarten, die im Addon verwendet werden.
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge" -- Große hervorgehobene Schrift.
local FONT_NORMAL = "GameFontNormal" -- Standard-Schrift.
local FONT_HIGHLIGHT_SMALL = "GameFontHighlightSmall" -- Kleine hervorgehobene Schrift.

-- Standard-Backdrop-Einstellungen für Frames
-- Ein Backdrop ist der Hintergrund und Rahmen eines UI-Fensters.
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Textur für den Hintergrund.
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Textur für den Rand.
    tile = true, -- Ob die Texturen gekachelt werden sollen.
    tileSize = 32, -- Größe der Kacheln.
    edgeSize = 32, -- Dicke des Randes.
    insets = { left = 11, right = 12, top = 12, bottom = 11 } -- Innenabstände.
}

-- Konstanten für die Inaktivitätsprüfung
local INACTIVE_DAYS_THRESHOLD = 10 -- Anzahl der Tage, ab denen ein Mitglied als inaktiv gilt.

--------------------------------------------------------------------------------
-- Erstellung der Inhalte für die einzelnen Tabs des Offi-Fensters
-- Jede Funktion hier ist verantwortlich für das Layout und die Grundstruktur
-- eines spezifischen Tabs im Offi-Fenster.
--------------------------------------------------------------------------------

-- Erstellt den Inhalt für den "Gildeninfo"-Tab (Tab 1)
-- Dieser Tab zeigt allgemeine Informationen über den Spieler und die Gilde.
function SchlingelInc:_CreateGuildInfoTabContent(parentFrame)
    -- Erstellt einen neuen Frame für diesen Tab.
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "GuildInfoTabFrame", parentFrame)
    tabFrame:SetAllPoints(true) -- Füllt den gesamten parentFrame aus.

    -- Erstellt ein Textfeld für die Gildeninformationen.
    -- UIHelper wird als global verfügbar angenommen.
    local infoText = self.UIHelpers:CreateStyledText(tabFrame, "Lade Gildeninfos ...", FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -25, 560, 480, "LEFT", "TOP")
    tabFrame.infoText = infoText -- Speichert eine Referenz auf das Textfeld.

    self.guildInfoFrame = tabFrame -- Speichert eine Referenz auf den Tab-Frame im Addon-Objekt.
    return tabFrame
end

-- Erstellt den Inhalt für den "Anfragen"-Tab (Tab 2)
-- Dieser Tab zeigt offene Gildenanfragen an.
function SchlingelInc:_CreateRecruitmentTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "RecruitmentTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Titel für den Tab.
    self.UIHelpers:CreateStyledText(tabFrame, "Gildenanfragen", FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    -- ScrollFrame für die Liste der Anfragen.
    local scrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "RecruitmentScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 380)
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    tabFrame.scrollFrame = scrollFrame

    -- Inhalt des ScrollFrames (dieser Frame wird tatsächlich gescrollt).
    local scrollChildContent = CreateFrame("Frame", ADDON_PREFIX .. "RecruitmentScrollContent", scrollFrame)
    scrollFrame:SetScrollChild(scrollChildContent)
    scrollChildContent:SetSize(560, 1) -- Höhe wird dynamisch angepasst.
    tabFrame.content = scrollChildContent

    -- Frame für die Spaltenüberschriften.
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChildContent)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5)
    columnHeadersFrame:SetSize(550, 20)
    tabFrame.columnHeaders = columnHeadersFrame

    -- Definition der Spaltenpositionen und -breiten.
    local columnPositions = {
        name = { xOffset = 0, width = 100, justification = "LEFT" },
        level = { xOffset = 110, width = 40, justification = "CENTER" },
        zone = { xOffset = 160, width = 120, justification = "LEFT" },
        gold = { xOffset = 290, width = 70, justification = "RIGHT" }
    }

    -- Erstellen der Texte für die Spaltenüberschriften.
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Ort", FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Gold", FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)

    tabFrame.requestsUIElements = {} -- Tabelle zum Speichern der UI-Elemente für jede Anfragezeile.
    return tabFrame
end

-- Erstellt den Inhalt für den "Statistik"-Tab (Tab 3 - NUR Verteilungen)
-- Dieser Tab zeigt verschiedene Gildenstatistiken an, z.B. Klassen- und Levelverteilung.
function SchlingelInc:_CreateStatsTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    tabFrame.title = self.UIHelpers:CreateStyledText(tabFrame, "Gildenstatistiken - Verteilungen", FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    -- Haupt-ScrollFrame für den Statistik-Tab.
    local mainStatsScrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "StatsMainScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    mainStatsScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 10, -45)
    mainStatsScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -10, 10)

    -- Inhalt des ScrollFrames.
    local mainScrollChild = CreateFrame("Frame", ADDON_PREFIX .. "StatsMainScrollChild", mainStatsScrollFrame)
    mainScrollChild:SetWidth(mainStatsScrollFrame:GetWidth() - 20) -- Etwas schmaler für Scrollbalken.
    mainScrollChild:SetHeight(1) -- Höhe wird dynamisch angepasst.
    mainStatsScrollFrame:SetScrollChild(mainScrollChild)
    tabFrame.mainScrollChild = mainScrollChild

    local availableWidth = mainScrollChild:GetWidth()
    local columnWidth = (availableWidth / 2) - 10 -- Breite für jede der beiden Spalten.

    -- Linke Spalte für Statistiken.
    local leftColumnFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsLeftColumn", mainScrollChild)
    leftColumnFrame:SetPoint("TOPLEFT", 0, -10)
    leftColumnFrame:SetWidth(columnWidth)
    leftColumnFrame:SetHeight(1) -- Höhe wird dynamisch angepasst.
    tabFrame.leftColumn = leftColumnFrame

    tabFrame.classText = self.UIHelpers:CreateStyledText(leftColumnFrame, "Lade Klassenverteilung...", FONT_NORMAL,
        "TOPLEFT", leftColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")

    -- Rechte Spalte für Statistiken.
    local rightColumnFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsRightColumn", mainScrollChild)
    rightColumnFrame:SetPoint("TOPLEFT", leftColumnFrame, "TOPRIGHT", 15, 0) -- Rechts neben der linken Spalte.
    rightColumnFrame:SetWidth(columnWidth)
    rightColumnFrame:SetHeight(1) -- Höhe wird dynamisch angepasst.
    tabFrame.rightColumn = rightColumnFrame

    tabFrame.levelText = self.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Levelverteilung...", FONT_NORMAL,
        "TOPLEFT", rightColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
    tabFrame.rankText = self.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Rangverteilung...", FONT_NORMAL,
        "TOPLEFT", tabFrame.levelText, "BOTTOMLEFT", 0, -15, columnWidth, nil, "LEFT") -- Unterhalb des Level-Textes.

    self.guildStatsFrame = tabFrame -- Speichert eine Referenz auf den Tab-Frame.
    return tabFrame
end

-- Erstellt den Inhalt für den "Inaktiv"-Tab (Tab 4)
-- Dieser Tab listet Mitglieder auf, die für eine bestimmte Zeit inaktiv waren.
function SchlingelInc:_CreateInactivityTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "InactivityTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Titeltext, der den Schwellenwert für Inaktivität anzeigt.
    local titleText = string.format("Inaktive Mitglieder (> %d Tage)", INACTIVE_DAYS_THRESHOLD)
    self.UIHelpers:CreateStyledText(tabFrame, titleText, FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    -- ScrollFrame für die Liste der inaktiven Mitglieder.
    local scrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "InactivityScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 420) -- Höhe ggf. anpassen.
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    tabFrame.scrollFrame = scrollFrame

    -- Inhalt des ScrollFrames.
    local scrollChild = CreateFrame("Frame", ADDON_PREFIX .. "InactivityScrollChild", scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10) -- Etwas schmaler für Scrollbalken.
    scrollChild:SetHeight(1) -- Höhe wird dynamisch angepasst.
    tabFrame.scrollChild = scrollChild

    -- Spaltenüberschriften.
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChild)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5)
    columnHeadersFrame:SetSize(550, 20)
    tabFrame.columnHeaders = columnHeadersFrame

    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", 0, 0, 150, nil, "LEFT")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 160, 0, 40, nil, "CENTER")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Rang", FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 210, 0, 120, nil, "LEFT")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Offline Seit", FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 340, 0, 80, nil, "LEFT") -- Breite angepasst

    tabFrame.inactiveListUIElements = {} -- Zum Speichern der UI-Elemente für die Liste.
    self.inactivityTabFrame = tabFrame -- Referenz auf den Tab-Frame speichern.
    return tabFrame
end

--------------------------------------------------------------------------------
-- Hilfsfunktion zum Erstellen einer UI-Zeile für eine Gildenanfrage (Unverändert)
-- Diese Funktion erstellt die visuellen Elemente für eine einzelne Zeile
-- in der Anfragenliste (Name, Level, Ort, Gold, Annahme-/Ablehnbuttons).
--------------------------------------------------------------------------------
function SchlingelInc:_CreateRequestRowUI(parentFrame, requestData, yPositionOffset, rowHeight)
    -- Frame für die gesamte Zeile.
    local requestRowFrame = CreateFrame("Frame", nil, parentFrame)
    requestRowFrame:SetPoint("TOPLEFT", 5, yPositionOffset)
    requestRowFrame:SetSize(550, rowHeight - 2) -- -2 für einen kleinen Abstand.

    local uiElementsGroup = { frame = requestRowFrame } -- Sammelt alle UI-Elemente dieser Zeile.

    -- Spaltenpositionen und -breiten für die Anfragedetails.
    local columnPositions = {
        name = { xOffset = 0, width = 100, justification = "LEFT" },
        level = { xOffset = 110, width = 40, justification = "CENTER" },
        zone = { xOffset = 160, width = 120, justification = "LEFT" },
        gold = { xOffset = 290, width = 70, justification = "RIGHT" },
        acceptButtonStart = 375,
        declineButtonStart = 455
    }

    -- Erstellen der Textfelder für Name, Level, Ort und Gold.
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.name, FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.level, FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.zone, FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.money, FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)

    -- Funktion, die beim Klick auf "Annehmen" ausgeführt wird.
    local function onAcceptClick()
        if self.GuildRecruitment and self.GuildRecruitment.HandleAcceptRequest then
            self.GuildRecruitment:HandleAcceptRequest(requestData.name)
        else
            SchlingelInc:Print("Fehler: HandleAcceptRequest nicht gefunden.")
        end
    end
    uiElementsGroup.acceptButton = self.UIHelpers:CreateStyledButton(requestRowFrame, "Annehmen", 75, rowHeight,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.acceptButtonStart, 0, "UIPanelButtonTemplate", onAcceptClick)

    -- Funktion, die beim Klick auf "Ablehnen" ausgeführt wird.
    local function onDeclineClick()
        if self.GuildRecruitment and self.GuildRecruitment.HandleDeclineRequest then
            self.GuildRecruitment:HandleDeclineRequest(requestData.name)
        else
            SchlingelInc:Print("Fehler: HandleDeclineRequest nicht gefunden.")
        end
    end
    uiElementsGroup.declineButton = self.UIHelpers:CreateStyledButton(requestRowFrame, "Ablehnen", 75, rowHeight,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.declineButtonStart, 0, "UIPanelButtonTemplate", onDeclineClick)

    return uiElementsGroup
end

--------------------------------------------------------------------------------
-- Hauptfunktion zur Erstellung des Offi-Fensters
-- Diese Funktion baut das gesamte Offi-Fenster mit seinen Tabs und
-- grundlegenden Funktionen zusammen.
--------------------------------------------------------------------------------
function SchlingelInc:CreateOffiWindow()
    -- Verhindert, dass das Fenster mehrfach erstellt wird.
    if self.OffiWindow then
        return
    end

    -- Erstellt den Hauptframe des Offi-Fensters.
    local offiWindowFrame = CreateFrame("Frame", OFFIFRAME_NAME, UIParent, "BackdropTemplate")
    offiWindowFrame:SetSize(600, 590)
    offiWindowFrame:SetPoint("RIGHT", -50, 25)
    offiWindowFrame:SetBackdrop(BACKDROP_SETTINGS)
    offiWindowFrame:SetMovable(true) -- Fenster kann verschoben werden.
    offiWindowFrame:EnableMouse(true) -- Mausinteraktionen aktivieren.
    offiWindowFrame:RegisterForDrag("LeftButton") -- Registriert das Ziehen mit der linken Maustaste.
    offiWindowFrame:SetScript("OnDragStart", offiWindowFrame.StartMoving) -- Funktion beim Start des Ziehens.
    offiWindowFrame:SetScript("OnDragStop", offiWindowFrame.StopMovingOrSizing) -- Funktion beim Ende des Ziehens.
    offiWindowFrame:Hide() -- Standardmäßig ausgeblendet.

    -- Schließen-Button oben rechts.
    self.UIHelpers:CreateStyledButton(offiWindowFrame, nil, 22, 22,
        "TOPRIGHT", offiWindowFrame, "TOPRIGHT", -5, -5, "UIPanelCloseButton",
        function() offiWindowFrame:Hide() end)

    -- Fenstertitel.
    self.UIHelpers:CreateStyledText(offiWindowFrame, "Schlingel Inc - Offi Interface", FONT_HIGHLIGHT_LARGE,
        "TOP", offiWindowFrame, "TOP", 0, -20)

    -- Container für den Inhalt der Tabs.
    local tabContentContainer = CreateFrame("Frame", ADDON_PREFIX .. "OffiTabContentContainer", offiWindowFrame)
    tabContentContainer:SetPoint("TOPLEFT", offiWindowFrame, "TOPLEFT", 10, -50)
    tabContentContainer:SetPoint("BOTTOMRIGHT", offiWindowFrame, "BOTTOMRIGHT", -10, 10)

    local tabButtons = {} -- Tabelle für die Tab-Buttons.
    local tabContentFrames = {} -- Tabelle für die Inhaltsframes der Tabs.

    -- Funktion zum Auswählen eines Tabs.
    -- Zeigt den Inhalt des gewählten Tabs an und blendet die anderen aus.
    local function SelectTab(tabIndex)
        for index, button in ipairs(tabButtons) do
            if tabContentFrames[index] then
                if index == tabIndex then
                    PanelTemplates_SelectTab(button) -- Visuelle Hervorhebung des aktiven Tabs.
                    tabContentFrames[index]:Show()
                else
                    PanelTemplates_DeselectTab(button) -- Entfernt Hervorhebung.
                    tabContentFrames[index]:Hide()
                end
            end
        end
    end

    -- Hilfsfunktion zum Erstellen eines Tab-Buttons.
    local function CreateTabButton(tabIndex, buttonText)
        local buttonWidth = 125
        local buttonSpacing = 10
        local startX = 15

        local button = CreateFrame("Button", TAB_BUTTON_NAME_PREFIX .. tabIndex, offiWindowFrame, "OptionsFrameTabButtonTemplate")
        button:SetID(tabIndex)
        button:SetText(buttonText)
        button:SetPoint("BOTTOMLEFT", offiWindowFrame, "BOTTOMLEFT", startX + (tabIndex - 1) * (buttonWidth + buttonSpacing), 10)
        button:SetWidth(buttonWidth)
        button:GetFontString():SetPoint("CENTER", 0, 2) -- Textposition im Button anpassen.
        button:SetScript("OnClick", function() SelectTab(tabIndex) end)

        PanelTemplates_DeselectTab(button) -- Standardmäßig nicht ausgewählt.
        tabButtons[tabIndex] = button
        return button
    end

    -- Erstellt die Tab-Buttons.
    CreateTabButton(1, "Gildeninfo")
    CreateTabButton(2, "Anfragen")
    CreateTabButton(3, "Statistik")
    CreateTabButton(4, "Inaktiv") -- Tab 4 hinzugefügt.

    -- Erstellt die Inhaltsframes für jeden Tab und speichert sie.
    tabContentFrames[1] = self:_CreateGuildInfoTabContent(tabContentContainer)
    tabContentFrames[2] = self:_CreateRecruitmentTabContent(tabContentContainer)
    tabContentFrames[3] = self:_CreateStatsTabContent(tabContentContainer)
    tabContentFrames[4] = self:_CreateInactivityTabContent(tabContentContainer) -- Inhalt für Tab 4.

    offiWindowFrame.recruitmentFrame = tabContentFrames[2] -- Spezielle Referenz für den Anfragen-Tab.
    SelectTab(1) -- Wählt den ersten Tab standardmäßig aus.
    self.OffiWindow = offiWindowFrame -- Speichert den Hauptframe des Fensters.

    -- Funktion zum Aktualisieren der Daten im "Anfragen"-Tab.
    function offiWindowFrame:UpdateRecruitmentTabData(inviteRequestsData)
        if not self.recruitmentFrame or not self.recruitmentFrame.content then
            return -- Abbruch, wenn benötigte UI-Elemente nicht existieren.
        end

        local uiContentFrame = self.recruitmentFrame.content
        local uiElementsTable = self.recruitmentFrame.requestsUIElements
        local scrollFrame = self.recruitmentFrame.scrollFrame

        -- Entfernt alle alten UI-Elemente aus der Liste.
        for _, elementGroup in ipairs(uiElementsTable) do
            if elementGroup.frame then
                elementGroup.frame:Hide()
                elementGroup.frame:SetParent(nil) -- Wichtig, um Referenzen zu lösen.
            end
            if elementGroup.noRequestsText then
                elementGroup.noRequestsText:Hide()
                elementGroup.noRequestsText:SetParent(nil)
            end
        end
        wipe(uiElementsTable) -- Leert die Tabelle der UI-Elemente.

        local yPositionOffsetBase = -25 -- Start-Y-Position unter den Spaltenüberschriften.
        local entryRowHeight = 22 -- Höhe jeder Anfragezeile.

        if inviteRequestsData and #inviteRequestsData > 0 then
            -- Erstellt für jede Anfrage eine neue Zeile.
            for i, requestItemData in ipairs(inviteRequestsData) do
                local currentYPosition = yPositionOffsetBase - (i - 1) * entryRowHeight
                local newRowElements = SchlingelInc:_CreateRequestRowUI(uiContentFrame, requestItemData, currentYPosition, entryRowHeight)
                table.insert(uiElementsTable, newRowElements)
            end
            -- Passt die Höhe des scrollbaren Inhalts an.
            uiContentFrame:SetHeight(math.max(1, 20 + (#inviteRequestsData * entryRowHeight) + 5))
        else
            -- Zeigt eine Nachricht an, wenn keine Anfragen vorhanden sind.
            local noRequestsFontString = SchlingelInc.UIHelpers:CreateStyledText(uiContentFrame, "Keine Gildenanfragen vorhanden.", FONT_NORMAL,
                "TOPLEFT", uiContentFrame, "TOPLEFT", 5, yPositionOffsetBase, 550)
            table.insert(uiElementsTable, { noRequestsText = noRequestsFontString })
            uiContentFrame:SetHeight(math.max(1, 20 + entryRowHeight + 5))
        end
        scrollFrame:SetVerticalScroll(0) -- Scrollt nach ganz oben.
    end
end

--------------------------------------------------------------------------------
-- Funktionen zum Aktualisieren der Tab-Inhalte
-- Diese Funktionen sind dafür zuständig, die Daten in den jeweiligen
-- Tabs zu laden und anzuzeigen.
--------------------------------------------------------------------------------

-- Aktualisiert den "Gildeninfo"-Tab.
-- Lädt und zeigt Spieler- und Gildeninformationen an.
function SchlingelInc:UpdateGuildInfo()
    if not self.guildInfoFrame or not self.guildInfoFrame.infoText then
        return -- Abbruch, wenn das Textfeld nicht existiert.
    end

    local playerName, playerRealm = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerClassLocalized, _ = UnitClass("player")
    local guildName, guildRankName, _, _ = GetGuildInfo("player")

    local infoTextContent = ""

    if not guildName then
        -- Spieler ist in keiner Gilde.
        infoTextContent = string.format(
            "|cff69ccf0Spielerinformationen:|r\n" ..
            "  Name: %s%s\n" ..
            "  Level: %d\n" ..
            "  Klasse: %s\n\n" ..
            "Nicht in einer Gilde.",
            playerName or "Unbekannt",
            playerRealm and (" - " .. playerRealm) or "",
            playerLevel or 0,
            playerClassLocalized or "Unbekannt"
        )
    else
        -- Spieler ist in einer Gilde.
        local totalGuildMembers, onlineGuildMembers = GetNumGuildMembers()
        totalGuildMembers = totalGuildMembers or 0
        onlineGuildMembers = onlineGuildMembers or 0

        local totalLevelSum = 0
        local membersCountedForAverageLevel = 0
        if totalGuildMembers > 0 then
            for i = 1, totalGuildMembers do
                local nameRoster, _, _, levelRoster, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
                if nameRoster and levelRoster and levelRoster > 0 then
                    totalLevelSum = totalLevelSum + levelRoster
                    membersCountedForAverageLevel = membersCountedForAverageLevel + 1
                end
            end
        end

        local averageLevelText = "N/A"
        if membersCountedForAverageLevel > 0 then
            averageLevelText = string.format("%d", math.floor(totalLevelSum / membersCountedForAverageLevel))
        elseif totalGuildMembers > 0 then
            averageLevelText = "0 (Leveldaten fehlen)"
        else
            averageLevelText = "N/A (Keine Mitglieder)"
        end

        infoTextContent = string.format(
            "|cff69ccf0Spielerinformationen:|r\n" ..
            "  Name: %s%s\n" ..
            "  Level: %d\n" ..
            "  Klasse: %s\n" ..
            "  Gildenrang: %s\n\n" ..
            "|cff69ccf0Gildeninformationen:|r\n" ..
            "  Gildenname: %s\n" ..
            "  Mitglieder (Gesamt): %d\n" ..
            "  Mitglieder (Online): %d\n" ..
            "  Durchschnittslevel (Gilde): %s",
            playerName or "Unbekannt",
            playerRealm and (" - " .. playerRealm) or "",
            playerLevel or 0,
            playerClassLocalized or "Unbekannt",
            guildRankName or "Unbekannt",
            guildName,
            totalGuildMembers,
            onlineGuildMembers,
            averageLevelText
        )
    end
    self.guildInfoFrame.infoText:SetText(infoTextContent)
end

-- Aktualisiert den "Statistik"-Tab.
-- Sammelt Daten über Klassen-, Level- und Rangverteilung in der Gilde.
function SchlingelInc:UpdateGuildStats()
    local statisticsTabFrame = self.guildStatsFrame
    if not statisticsTabFrame or not statisticsTabFrame.classText or
       not statisticsTabFrame.levelText or not statisticsTabFrame.rankText or
       not statisticsTabFrame.mainScrollChild or not statisticsTabFrame.leftColumn or
       not statisticsTabFrame.rightColumn then
        return -- Abbruch, wenn wichtige UI-Elemente fehlen.
    end

    local totalGuildMembersClassic, _ = GetNumGuildMembers()
    totalGuildMembersClassic = totalGuildMembersClassic or 0

    if totalGuildMembersClassic == 0 then
        -- Keine Mitglieder, zeige entsprechende Nachrichten.
        statisticsTabFrame.classText:SetText("|cffffff00Klassenverteilung:|r\nKeine Mitglieder.")
        statisticsTabFrame.levelText:SetText("|cffffff00Level-Verteilung:|r\nKeine Mitglieder.")
        statisticsTabFrame.rankText:SetText("|cffffff00Rang-Verteilung:|r\nKeine Mitglieder.")

        local minContentHeight = statisticsTabFrame.classText:GetFontHeight() + 5
        statisticsTabFrame.leftColumn:SetHeight(minContentHeight)
        statisticsTabFrame.rightColumn:SetHeight(minContentHeight * 2 + 15) -- Genug Platz für Level- und Rangtext.
        statisticsTabFrame.mainScrollChild:SetHeight(math.max(statisticsTabFrame.leftColumn:GetHeight(), statisticsTabFrame.rightColumn:GetHeight()) + 20)
        return
    end

    local classDistribution = {} -- Verteilung der Klassen.
    local levelBrackets = { -- Vordefinierte Level-Bereiche.
        {minLevel=1, maxLevel=10, count=0, label="1-10"},
        {minLevel=11, maxLevel=20, count=0, label="11-20"},
        {minLevel=21, maxLevel=30, count=0, label="21-30"},
        {minLevel=31, maxLevel=40, count=0, label="31-40"},
        {minLevel=41, maxLevel=50, count=0, label="41-50"},
        {minLevel=51, maxLevel=60, count=0, label="51-60"}
    }
    local rankDistribution = {} -- Verteilung der Ränge.
    local classLevelSums = {} -- Für Durchschnittslevel pro Klasse.

    -- Durchläuft alle Gildenmitglieder, um Daten zu sammeln.
    for i = 1, totalGuildMembersClassic do
        local name, rankName, _, level, classDisplayName, _, _, _, _, _, classToken, _, _, _ = GetGuildRosterInfo(i)
        if name then
            -- Klassenverteilung und Durchschnittslevel.
            if classToken and classToken ~= "" then
                if not classDistribution[classToken] then
                    local localizedDisplayName = classDisplayName
                    if not localizedDisplayName or localizedDisplayName == "" then
                        -- Fallback auf globale Klassennamen, falls nicht direkt verfügbar.
                        localizedDisplayName = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken
                    end
                    classDistribution[classToken] = {count = 0, localizedName = localizedDisplayName}
                    classLevelSums[classToken] = {totalLevel = 0, memberCount = 0}
                end
                classDistribution[classToken].count = classDistribution[classToken].count + 1
                if level and level > 0 then
                    classLevelSums[classToken].totalLevel = classLevelSums[classToken].totalLevel + level
                    classLevelSums[classToken].memberCount = classLevelSums[classToken].memberCount + 1
                end
            end

            -- Levelverteilung.
            if level and level > 0 then
                for _, bracket in ipairs(levelBrackets) do
                    if level >= bracket.minLevel and level <= bracket.maxLevel then
                        bracket.count = bracket.count + 1
                        break -- Nächstes Mitglied, da Level nur in ein Bracket passt.
                    end
                end
            end

            -- Rangverteilung.
            if rankName and rankName ~= "" then
                rankDistribution[rankName] = (rankDistribution[rankName] or 0) + 1
            end
        end
    end

    -- Bereitet Klassenverteilung für die Anzeige vor.
    local sortedClasses = {}
    for token, data in pairs(classDistribution) do
        local avgL = 0
        if classLevelSums[token] and classLevelSums[token].memberCount > 0 then
            avgL = math.floor(classLevelSums[token].totalLevel / classLevelSums[token].memberCount)
        end
        table.insert(sortedClasses, {
            classToken = token,
            localizedName = data.localizedName,
            count = data.count,
            averageLevel = avgL
        })
    end
    table.sort(sortedClasses, function(a,b) return a.count > b.count end) -- Sortiert nach Anzahl.

    local classDistributionText = "|cffffff00Klassenverteilung:|r\n"
    if #sortedClasses == 0 then
        classDistributionText = classDistributionText .. "Konnte Klassen nicht ermitteln.\n"
    else
        for _, classEntry in ipairs(sortedClasses) do
            local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEntry.classToken]) or {r=1,g=1,b=1} -- Standardfarbe Weiß.
            local colorHexString = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
            local percentageOfTotal = (classEntry.count / totalGuildMembersClassic) * 100
            classDistributionText = classDistributionText .. string.format("%s%s|r: %d (|cffffcc00%.1f%%|r, Ø Lvl %d)\n",
                colorHexString, classEntry.localizedName, classEntry.count, percentageOfTotal, classEntry.averageLevel)
        end
    end
    statisticsTabFrame.classText:SetText(classDistributionText)
    local leftHeight = statisticsTabFrame.classText:GetStringHeight() + 15
    statisticsTabFrame.leftColumn:SetHeight(math.max(50, leftHeight))

    -- Bereitet Level-Verteilung für die Anzeige vor.
    local rightColumnText = ""
    rightColumnText = rightColumnText .. "|cffffff00Level-Verteilung:|r\n"
    local hasLevelData = false
    for _, bracket in ipairs(levelBrackets) do
        if bracket.count > 0 then
            hasLevelData = true
        end
        rightColumnText = rightColumnText .. string.format("Level %s: %d\n", bracket.label, bracket.count)
    end
    if not hasLevelData then
        rightColumnText = rightColumnText .. "Keine Leveldaten verfügbar.\n"
    end
    statisticsTabFrame.levelText:SetText(rightColumnText)

    -- Bereitet Rang-Verteilung für die Anzeige vor.
    local sortedRanks = {}
    local hasRankData = false
    for rankName, count in pairs(rankDistribution) do
        table.insert(sortedRanks, { name = rankName, count = count })
        hasRankData = true
    end
    table.sort(sortedRanks, function(a,b) return a.count > b.count end) -- Sortiert nach Anzahl.

    local rankDistributionText = "\n|cffffff00Rang-Verteilung:|r\n" -- \n für Abstand zum Leveltext.
    if not hasRankData then
        rankDistributionText = rankDistributionText .. "Keine Rangdaten verfügbar.\n"
    else
        for _, rankData in ipairs(sortedRanks) do
            rankDistributionText = rankDistributionText .. string.format("%s: %d\n", rankData.name, rankData.count)
        end
    end
    statisticsTabFrame.rankText:SetText(rankDistributionText)
    local rightHeight = statisticsTabFrame.levelText:GetStringHeight() + statisticsTabFrame.rankText:GetStringHeight() + 30
    statisticsTabFrame.rightColumn:SetHeight(math.max(50, rightHeight))

    -- Passt die Höhe des Scroll-Containers an den größten Inhalt an.
    local totalRequiredHeight = math.max(leftHeight, rightHeight) + 20
    statisticsTabFrame.mainScrollChild:SetHeight(math.max(statisticsTabFrame.mainScrollChild:GetParent():GetHeight(), totalRequiredHeight))
end

-- Aktualisiert den "Inaktiv"-Tab (Tab 4)
-- Listet Gildenmitglieder auf, die länger als INACTIVE_DAYS_THRESHOLD offline sind.
function SchlingelInc:UpdateInactivityTab()
    local inactivityTab = self.inactivityTabFrame
    if not inactivityTab or not inactivityTab.scrollChild or not inactivityTab.inactiveListUIElements then
        return -- Sicherstellen, dass die UI-Elemente existieren.
    end

    local scrollChild = inactivityTab.scrollChild
    local uiElements = inactivityTab.inactiveListUIElements
    local scrollFrame = inactivityTab.scrollFrame

    -- Alte UI-Elemente (Zeilen) entfernen.
    for _, elementGroup in ipairs(uiElements) do
        if elementGroup.rowFrame then
            elementGroup.rowFrame:Hide()
            elementGroup.rowFrame:SetParent(nil) -- Wichtig zum Freigeben.
        end
    end
    wipe(uiElements) -- Leert die Tabelle der UI-Elemente.

    local totalGuildMembersClassic, _ = GetNumGuildMembers()
    totalGuildMembersClassic = totalGuildMembersClassic or 0

    local inactiveMembersList = {} -- Sammelt die Daten der inaktiven Mitglieder.

    if totalGuildMembersClassic > 0 then
        for i = 1, totalGuildMembersClassic do
            -- GetGuildRosterInfo für Classic Era hat 14 Rückgabewerte.
            local name, rankName, _, level, _, _, publicNote, _, isOnline, _, _, _, _, _ = GetGuildRosterInfo(i)

            if name and not isOnline then -- Nur offline Mitglieder betrachten.
                local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)

                local isConsideredInactive = false
                local displayOfflineDuration = "Unbekannt" -- Fallback für Anzeige.
                local totalDaysForSorting = 0 -- Für die Sortierung.

                -- Stelle sicher, dass die Werte Zahlen sind.
                yearsOffline = yearsOffline or 0
                monthsOffline = monthsOffline or 0
                daysOffline = daysOffline or 0
                hoursOffline = hoursOffline or 0

                -- Berechne die gesamte Offline-Zeit in Tagen für die Sortierung.
                totalDaysForSorting = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

                -- Prüfen, ob die Inaktivitätsschwelle erreicht ist.
                if yearsOffline > 0 then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d J", yearsOffline)
                elseif monthsOffline > 0 then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d M", monthsOffline)
                elseif daysOffline >= INACTIVE_DAYS_THRESHOLD then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d T", daysOffline)
                elseif INACTIVE_DAYS_THRESHOLD == 0 then -- Spezialfall: Alle Offline-Mitglieder auflisten, wenn Threshold 0 ist.
                     isConsideredInactive = true
                     if daysOffline > 0 then
                         displayOfflineDuration = string.format("%d T", daysOffline)
                     elseif hoursOffline > 0 then
                         displayOfflineDuration = string.format("%d Std", hoursOffline)
                     else
                         displayOfflineDuration = "<1 Std" -- Wenn alle Zeitwerte 0 sind.
                     end
                end

                if isConsideredInactive then
                     table.insert(inactiveMembersList, {
                         name = name,
                         level = level or 0,
                         rank = rankName or "Unbekannt",
                         note = publicNote or "",
                         displayDuration = displayOfflineDuration, -- Für die Anzeige.
                         sortableOfflineDays = totalDaysForSorting -- Für die Sortierung.
                     })
                end
            end
        end
    end

    -- Inaktive Mitglieder sortieren:
    -- 1. Längste Offline-Zeit zuerst.
    -- 2. Bei gleicher Offline-Zeit: Höchstes Level zuerst.
    table.sort(inactiveMembersList, function(a, b)
        if a.sortableOfflineDays == b.sortableOfflineDays then
            return (a.level or 0) > (b.level or 0)
        end
        return a.sortableOfflineDays > b.sortableOfflineDays
    end)

    -- UI für inaktive Mitglieder erstellen.
    local yOffset = -25 -- Start-Y-Position unterhalb der Spaltenüberschriften.
    local rowHeight = 20 -- Höhe jeder Zeile.
    local colWidths = { name = 150, level = 40, rank = 120, duration = 80, kick = 80 } -- Spaltenbreiten.
    local xOffsets = { name = 5, level = 160, rank = 210, duration = 340, kick = 430 } -- X-Positionen der Spalten.

    if #inactiveMembersList > 0 then
        for i, memberData in ipairs(inactiveMembersList) do
            local rowFrame = CreateFrame("Frame", nil, scrollChild)
            rowFrame:SetSize(scrollChild:GetWidth(), rowHeight)
            rowFrame:SetPoint("TOPLEFT", 0, yOffset)

            -- Text für Name, Level, Rang und Offline-Dauer.
            self.UIHelpers:CreateStyledText(rowFrame, memberData.name, FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.name, 0, colWidths.name, nil, "LEFT", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.level, FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.level, 0, colWidths.level, nil, "CENTER", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.rank, FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.rank, 0, colWidths.rank, nil, "LEFT", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.displayDuration, FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.duration, 0, colWidths.duration, nil, "LEFT", "MIDDLE")

            -- Kick-Button hinzufügen.
            local kickButton = self.UIHelpers:CreateStyledButton(rowFrame, "Entfernen", colWidths.kick, rowHeight - 2,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.kick, 0, "UIPanelButtonTemplate")
            kickButton:SetScript("OnClick", function()
                -- Zeigt einen Bestätigungsdialog vor dem Entfernen.
                StaticPopup_Show("CONFIRM_GUILD_KICK", memberData.name, nil, { memberName = memberData.name })
            end)

            table.insert(uiElements, { rowFrame = rowFrame }) -- Fügt den Frame der Zeile zur UI-Elemente-Liste hinzu.
            yOffset = yOffset - rowHeight -- Nächste Zeile weiter unten.
        end
        -- Passt die Höhe des scrollbaren Inhalts an.
        scrollChild:SetHeight(math.max(1, (#inactiveMembersList * rowHeight) + 30)) -- + Puffer.
    else
        -- Nachricht, wenn keine inaktiven Mitglieder gefunden wurden.
        local noInactiveText = self.UIHelpers:CreateStyledText(scrollChild,
            "Keine inaktiven Mitglieder (> ".. INACTIVE_DAYS_THRESHOLD .." T) gefunden.", FONT_NORMAL,
            "TOP", scrollChild, "TOP", 0, yOffset, scrollChild:GetWidth() - 10, nil, "CENTER")
        table.insert(uiElements, { rowFrame = noInactiveText }) -- Hier ist rowFrame der Text selbst.
        scrollChild:SetHeight(noInactiveText:GetStringHeight() + 30)
    end

    scrollFrame:SetVerticalScroll(0) -- Scrollt nach ganz oben.
end

--------------------------------------------------------------------------------
-- Funktion zum Umschalten der Sichtbarkeit des Offi-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:ToggleOffiWindow()
    -- Erstellt das Fenster, falls es noch nicht existiert.
    if not self.OffiWindow then
        self:CreateOffiWindow()
    end
    if not self.OffiWindow then
        print(ADDON_PREFIX .. ": OffiWindow konnte nicht erstellt/gefunden werden!")
        return
    end

    if self.OffiWindow:IsShown() then
        self.OffiWindow:Hide() -- Fenster ausblenden, wenn es sichtbar ist.
    else
        self.OffiWindow:Show() -- Fenster anzeigen, wenn es ausgeblendet ist.

        -- Alle Tabs beim Anzeigen aktualisieren.
        if self.UpdateGuildInfo then
            self:UpdateGuildInfo()
        end
        if self.UpdateGuildStats then
            self:UpdateGuildStats()
        end
        if self.UpdateInactivityTab then
            self:UpdateInactivityTab() -- Inaktiv-Tab aktualisieren.
        end

        -- Anfragen-Tab aktualisieren, falls die entsprechenden Module existieren.
        if self.GuildRecruitment and self.GuildRecruitment.GetPendingRequests and self.OffiWindow.UpdateRecruitmentTabData then
            self.OffiWindow:UpdateRecruitmentTabData(self.GuildRecruitment.GetPendingRequests())
        end
    end
end

--------------------------------------------------------------------------------
-- Bestätigungsdialog für Gilden-Kick
-- Definiert einen Standard-Dialog, der vor dem Entfernen eines Mitglieds
-- aus der Gilde angezeigt wird.
--------------------------------------------------------------------------------
StaticPopupDialogs["CONFIRM_GUILD_KICK"] = {
    text = "Möchtest du %s wirklich aus der Gilde entfernen?", -- %s wird durch den Spielernamen ersetzt.
    button1 = ACCEPT, -- "Akzeptieren"
    button2 = CANCEL, -- "Abbrechen"
    OnAccept = function(selfDialog, data)
        -- Wird ausgeführt, wenn "Akzeptieren" geklickt wird.
        if data and data.memberName then
            GuildUninvite(data.memberName) -- Entfernt das Mitglied aus der Gilde.
            if SchlingelInc and SchlingelInc.Print then
                SchlingelInc:Print(data.memberName .. " wurde aus der Gilde entfernt.")
            end
            -- Kurze Verzögerung, um sicherzustellen, dass die Gildenliste serverseitig aktualisiert wurde,
            -- bevor die UI neu geladen wird.
            if SchlingelInc then
                C_Timer.After(0.7, function()
                    if SchlingelInc.OffiWindow and SchlingelInc.OffiWindow:IsShown() then
                        -- Aktualisiert alle relevanten Tabs nach dem Kick.
                        if SchlingelInc.UpdateGuildInfo then SchlingelInc:UpdateGuildInfo() end
                        if SchlingelInc.UpdateGuildStats then SchlingelInc:UpdateGuildStats() end
                        if SchlingelInc.UpdateInactivityTab then SchlingelInc:UpdateInactivityTab() end
                    end
                end)
            end
        end
    end,
    OnCancel = function(selfDialog, data)
        -- Wird ausgeführt, wenn "Abbrechen" geklickt wird (tut nichts).
    end,
    timeout = 0, -- Kein automatisches Schließen.
    whileDead = 1, -- Kann auch angezeigt werden, wenn der Spieler tot ist.
    hideOnEscape = 1, -- Schließt bei Drücken von Escape.
    preferredIndex = 3, -- Standard-Popup-Index.
}