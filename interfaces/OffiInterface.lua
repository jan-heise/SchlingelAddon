-- Stellt sicher, dass die Haupt-Addon-Tabelle existiert.
SchlingelInc = SchlingelInc or {}
-- SchlingelInc.UIHelpers Namespace wird als existent vorausgesetzt.

--------------------------------------------------------------------------------
-- Konstanten für das Addon-Interface
--------------------------------------------------------------------------------
local ADDON_PREFIX = SchlingelInc.name or "SchlingelInc"
local OFFIFRAME_NAME = ADDON_PREFIX .. "OffiFrame"
local TAB_BUTTON_NAME_PREFIX = ADDON_PREFIX .. "OffiTab"

-- Schriftarten-Konstanten
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"
local FONT_NORMAL = "GameFontNormal"
local FONT_HIGHLIGHT_SMALL = "GameFontHighlightSmall"

-- Standard-Backdrop-Einstellungen für Frames
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

-- Konstanten für die Inaktivitätsprüfung
local INACTIVE_DAYS_THRESHOLD = 10 -- Anzahl der Tage, ab denen ein Mitglied als inaktiv gilt

--------------------------------------------------------------------------------
-- Erstellung der Inhalte für die einzelnen Tabs des Offi-Fensters
--------------------------------------------------------------------------------

-- Erstellt den Inhalt für den "Gildeninfo"-Tab (Tab 1)
function SchlingelInc:_CreateGuildInfoTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "GuildInfoTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)
    -- UIHelper wird als global verfügbar angenommen
    local infoText = self.UIHelpers:CreateStyledText(tabFrame, "Lade Gildeninfos ...", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", 10, -25, 560, 480, "LEFT", "TOP")
    tabFrame.infoText = infoText
    self.guildInfoFrame = tabFrame
    return tabFrame
end

-- Erstellt den Inhalt für den "Anfragen"-Tab (Tab 2)
function SchlingelInc:_CreateRecruitmentTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "RecruitmentTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)
    self.UIHelpers:CreateStyledText(tabFrame, "Gildenanfragen", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)
    local scrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "RecruitmentScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 380); scrollFrame:SetPoint("TOPLEFT", 10, -45)
    tabFrame.scrollFrame = scrollFrame
    local scrollChildContent = CreateFrame("Frame", ADDON_PREFIX .. "RecruitmentScrollContent", scrollFrame)
    scrollFrame:SetScrollChild(scrollChildContent); scrollChildContent:SetSize(560, 1)
    tabFrame.content = scrollChildContent
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChildContent)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5); columnHeadersFrame:SetSize(550, 20)
    tabFrame.columnHeaders = columnHeadersFrame
    local columnPositions = { name = { xOffset = 0,   width = 100, justification = "LEFT" }, level= { xOffset = 110, width = 40,  justification = "CENTER" }, zone = { xOffset = 160, width = 120, justification = "LEFT" }, gold = { xOffset = 290, width = 70,  justification = "RIGHT" } }
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", FONT_HIGHLIGHT_SMALL, "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", FONT_HIGHLIGHT_SMALL, "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Ort", FONT_HIGHLIGHT_SMALL, "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Gold", FONT_HIGHLIGHT_SMALL, "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)
    tabFrame.requestsUIElements = {}; return tabFrame
end

-- Erstellt den Inhalt für den "Statistik"-Tab (Tab 3 - NUR Verteilungen)
function SchlingelInc:_CreateStatsTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsTabFrame", parentFrame); tabFrame:SetAllPoints(true)
    tabFrame.title = self.UIHelpers:CreateStyledText(tabFrame, "Gildenstatistiken - Verteilungen", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)
    local mainStatsScrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "StatsMainScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    mainStatsScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 10, -45)
    mainStatsScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -10, 10)
    local mainScrollChild = CreateFrame("Frame", ADDON_PREFIX .. "StatsMainScrollChild", mainStatsScrollFrame)
    mainScrollChild:SetWidth(mainStatsScrollFrame:GetWidth() - 20); mainScrollChild:SetHeight(1)
    mainStatsScrollFrame:SetScrollChild(mainScrollChild); tabFrame.mainScrollChild = mainScrollChild
    local availableWidth = mainScrollChild:GetWidth(); local columnWidth = (availableWidth / 2) - 10
    local leftColumnFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsLeftColumn", mainScrollChild)
    leftColumnFrame:SetPoint("TOPLEFT", 0, -10); leftColumnFrame:SetWidth(columnWidth); leftColumnFrame:SetHeight(1); tabFrame.leftColumn = leftColumnFrame
    tabFrame.classText = self.UIHelpers:CreateStyledText(leftColumnFrame, "Lade Klassenverteilung...", FONT_NORMAL, "TOPLEFT", leftColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
    local rightColumnFrame = CreateFrame("Frame", ADDON_PREFIX .. "StatsRightColumn", mainScrollChild)
    rightColumnFrame:SetPoint("TOPLEFT", leftColumnFrame, "TOPRIGHT", 15, 0); rightColumnFrame:SetWidth(columnWidth); rightColumnFrame:SetHeight(1); tabFrame.rightColumn = rightColumnFrame
    tabFrame.levelText = self.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Levelverteilung...", FONT_NORMAL, "TOPLEFT", rightColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
    tabFrame.rankText = self.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Rangverteilung...", FONT_NORMAL, "TOPLEFT", tabFrame.levelText, "BOTTOMLEFT", 0, -15, columnWidth, nil, "LEFT")
    self.guildStatsFrame = tabFrame; return tabFrame
end

-- Erstellt den Inhalt für den "Inaktiv"-Tab (Tab 4)
function SchlingelInc:_CreateInactivityTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_PREFIX.."InactivityTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    local titleText = string.format("Inaktive Mitglieder (> %d Tage)", INACTIVE_DAYS_THRESHOLD)
    self.UIHelpers:CreateStyledText(tabFrame, titleText, FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    local scrollFrame = CreateFrame("ScrollFrame", ADDON_PREFIX .. "InactivityScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 420) -- Höhe ggf. anpassen
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    tabFrame.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", ADDON_PREFIX.."InactivityScrollChild", scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1) -- Dynamisch
    tabFrame.scrollChild = scrollChild

    -- Spaltenüberschriften
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChild)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5); columnHeadersFrame:SetSize(550, 20)
    tabFrame.columnHeaders = columnHeadersFrame
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", FONT_HIGHLIGHT_SMALL, "TOPLEFT", 0, 0, 150, nil, "LEFT")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", FONT_HIGHLIGHT_SMALL, "LEFT", columnHeadersFrame, "LEFT", 160, 0, 40, nil, "CENTER")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Rang", FONT_HIGHLIGHT_SMALL, "LEFT", columnHeadersFrame, "LEFT", 210, 0, 120, nil, "LEFT")
    self.UIHelpers:CreateStyledText(columnHeadersFrame, "Offline Seit", FONT_HIGHLIGHT_SMALL, "LEFT", columnHeadersFrame, "LEFT", 340, 0, 80, nil, "LEFT") -- Breite angepasst

    tabFrame.inactiveListUIElements = {} -- UI Elemente für die Liste speichern
    self.inactivityTabFrame = tabFrame -- Referenz auf den Tab-Frame speichern
    return tabFrame
end

--------------------------------------------------------------------------------
-- Hilfsfunktion zum Erstellen einer UI-Zeile für eine Gildenanfrage (Unverändert)
--------------------------------------------------------------------------------
function SchlingelInc:_CreateRequestRowUI(parentFrame, requestData, yPositionOffset, rowHeight)
    local requestRowFrame = CreateFrame("Frame", nil, parentFrame)
    requestRowFrame:SetPoint("TOPLEFT", 5, yPositionOffset); requestRowFrame:SetSize(550, rowHeight - 2)
    local uiElementsGroup = { frame = requestRowFrame }
    local columnPositions = { name = { xOffset = 0,   width = 100, justification = "LEFT" }, level= { xOffset = 110, width = 40,  justification = "CENTER" }, zone = { xOffset = 160, width = 120, justification = "LEFT" }, gold = { xOffset = 290, width = 70,  justification = "RIGHT" }, acceptButtonStart = 375, declineButtonStart = 455 }
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.name, FONT_NORMAL, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.level, FONT_NORMAL, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.zone, FONT_NORMAL, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    self.UIHelpers:CreateStyledText(requestRowFrame, requestData.money, FONT_NORMAL, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)
    local function onAcceptClick() if self.GuildRecruitment and self.GuildRecruitment.HandleAcceptRequest then self.GuildRecruitment:HandleAcceptRequest(requestData.name) else SchlingelInc:Print("Fehler: HandleAcceptRequest nicht gefunden.") end end
    uiElementsGroup.acceptButton = self.UIHelpers:CreateStyledButton(requestRowFrame, "Annehmen", 75, rowHeight, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.acceptButtonStart, 0, "UIPanelButtonTemplate", onAcceptClick)
    local function onDeclineClick() if self.GuildRecruitment and self.GuildRecruitment.HandleDeclineRequest then self.GuildRecruitment:HandleDeclineRequest(requestData.name) else SchlingelInc:Print("Fehler: HandleDeclineRequest nicht gefunden.") end end
    uiElementsGroup.declineButton = self.UIHelpers:CreateStyledButton(requestRowFrame, "Ablehnen", 75, rowHeight, "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.declineButtonStart, 0, "UIPanelButtonTemplate", onDeclineClick)
    return uiElementsGroup
end

--------------------------------------------------------------------------------
-- Hauptfunktion zur Erstellung des Offi-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:CreateOffiWindow()
    if self.OffiWindow then return end
    local offiWindowFrame = CreateFrame("Frame", OFFIFRAME_NAME, UIParent, "BackdropTemplate")
    offiWindowFrame:SetSize(600, 590); offiWindowFrame:SetPoint("RIGHT", -50, 25)
    offiWindowFrame:SetBackdrop(BACKDROP_SETTINGS); offiWindowFrame:SetMovable(true); offiWindowFrame:EnableMouse(true)
    offiWindowFrame:RegisterForDrag("LeftButton"); offiWindowFrame:SetScript("OnDragStart", offiWindowFrame.StartMoving); offiWindowFrame:SetScript("OnDragStop", offiWindowFrame.StopMovingOrSizing)
    offiWindowFrame:Hide()
    self.UIHelpers:CreateStyledButton(offiWindowFrame, nil, 22, 22, "TOPRIGHT", offiWindowFrame, "TOPRIGHT", -5, -5, "UIPanelCloseButton", function() offiWindowFrame:Hide() end)
    self.UIHelpers:CreateStyledText(offiWindowFrame, "Schlingel Inc - Offi Interface", FONT_HIGHLIGHT_LARGE, "TOP", offiWindowFrame, "TOP", 0, -20)
    local tabContentContainer = CreateFrame("Frame", ADDON_PREFIX .. "OffiTabContentContainer", offiWindowFrame)
    tabContentContainer:SetPoint("TOPLEFT", offiWindowFrame, "TOPLEFT", 10, -50); tabContentContainer:SetPoint("BOTTOMRIGHT", offiWindowFrame, "BOTTOMRIGHT", -10, 10)
    local tabButtons = {}; local tabContentFrames = {}
    local function SelectTab(tabIndex) for index, button in ipairs(tabButtons) do if tabContentFrames[index] then if index == tabIndex then PanelTemplates_SelectTab(button); tabContentFrames[index]:Show() else PanelTemplates_DeselectTab(button); tabContentFrames[index]:Hide() end end end end
    local function CreateTabButton(tabIndex, buttonText)
        local buttonWidth = 125; local buttonSpacing = 10; local startX = 15
        local button = CreateFrame("Button", TAB_BUTTON_NAME_PREFIX .. tabIndex, offiWindowFrame, "OptionsFrameTabButtonTemplate")
        button:SetID(tabIndex); button:SetText(buttonText)
        button:SetPoint("BOTTOMLEFT", offiWindowFrame, "BOTTOMLEFT", startX + (tabIndex - 1) * (buttonWidth + buttonSpacing), 10) 
        button:SetWidth(buttonWidth); button:GetFontString():SetPoint("CENTER", 0, 2)
        button:SetScript("OnClick", function() SelectTab(tabIndex) end); PanelTemplates_DeselectTab(button); tabButtons[tabIndex] = button; return button 
    end

    CreateTabButton(1, "Gildeninfo")
    CreateTabButton(2, "Anfragen")
    CreateTabButton(3, "Statistik")
    CreateTabButton(4, "Inaktiv") -- Tab 4 hinzugefügt

    tabContentFrames[1] = self:_CreateGuildInfoTabContent(tabContentContainer)
    tabContentFrames[2] = self:_CreateRecruitmentTabContent(tabContentContainer)
    tabContentFrames[3] = self:_CreateStatsTabContent(tabContentContainer)
    tabContentFrames[4] = self:_CreateInactivityTabContent(tabContentContainer) -- Inhalt für Tab 4

    offiWindowFrame.recruitmentFrame = tabContentFrames[2]; SelectTab(1); self.OffiWindow = offiWindowFrame
    
    function offiWindowFrame:UpdateRecruitmentTabData(inviteRequestsData)
        if not self.recruitmentFrame or not self.recruitmentFrame.content then return end
        local uiContentFrame = self.recruitmentFrame.content; local uiElementsTable = self.recruitmentFrame.requestsUIElements; local scrollFrame = self.recruitmentFrame.scrollFrame
        for _, elementGroup in ipairs(uiElementsTable) do if elementGroup.frame then elementGroup.frame:Hide(); elementGroup.frame:SetParent(nil) end; if elementGroup.noRequestsText then elementGroup.noRequestsText:Hide(); elementGroup.noRequestsText:SetParent(nil) end end; wipe(uiElementsTable)
        local yPositionOffsetBase = -25; local entryRowHeight = 22
        if inviteRequestsData and #inviteRequestsData > 0 then
            for i, requestItemData in ipairs(inviteRequestsData) do local currentYPosition = yPositionOffsetBase - (i - 1) * entryRowHeight; local newRowElements = SchlingelInc:_CreateRequestRowUI(uiContentFrame, requestItemData, currentYPosition, entryRowHeight); table.insert(uiElementsTable, newRowElements) end
            uiContentFrame:SetHeight(math.max(1, 20 + (#inviteRequestsData * entryRowHeight) + 5))
        else
            local noRequestsFontString = SchlingelInc.UIHelpers:CreateStyledText(uiContentFrame, "Keine Gildenanfragen vorhanden.", FONT_NORMAL, "TOPLEFT", uiContentFrame, "TOPLEFT", 5, yPositionOffsetBase, 550)
            table.insert(uiElementsTable, { noRequestsText = noRequestsFontString }); uiContentFrame:SetHeight(math.max(1, 20 + entryRowHeight + 5))
        end
        scrollFrame:SetVerticalScroll(0)
    end
end

--------------------------------------------------------------------------------
-- Funktionen zum Aktualisieren der Tab-Inhalte
--------------------------------------------------------------------------------
function SchlingelInc:UpdateGuildInfo()
    if not self.guildInfoFrame or not self.guildInfoFrame.infoText then return end
    local playerName, playerRealm = UnitName("player"); local playerLevel = UnitLevel("player")
    local playerClassLocalized, _ = UnitClass("player"); local guildName, guildRankName, _, _ = GetGuildInfo("player")
    local infoTextContent = ""
    if not guildName then
        infoTextContent = string.format( "|cff69ccf0Spielerinformationen:|r\n" .. "  Name: %s%s\n" .. "  Level: %d\n" .. "  Klasse: %s\n\n" .. "Nicht in einer Gilde.", playerName or "Unbekannt", playerRealm and (" - " .. playerRealm) or "", playerLevel or 0, playerClassLocalized or "Unbekannt" )
    else
        local totalGuildMembers, onlineGuildMembers = GetNumGuildMembers(); totalGuildMembers = totalGuildMembers or 0; onlineGuildMembers = onlineGuildMembers or 0
        local totalLevelSum = 0; local membersCountedForAverageLevel = 0
        if totalGuildMembers > 0 then
            for i = 1, totalGuildMembers do
                local nameRoster, _, _, levelRoster, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
                if nameRoster and levelRoster and levelRoster > 0 then totalLevelSum = totalLevelSum + levelRoster; membersCountedForAverageLevel = membersCountedForAverageLevel + 1 end
            end
        end
        local averageLevelText = "N/A"; if membersCountedForAverageLevel > 0 then averageLevelText = string.format("%d", math.floor(totalLevelSum / membersCountedForAverageLevel)) else if totalGuildMembers > 0 then averageLevelText = "0 (Leveldaten fehlen)" else averageLevelText = "N/A (Keine Mitglieder)" end end
        infoTextContent = string.format( "|cff69ccf0Spielerinformationen:|r\n" .. "  Name: %s%s\n" .. "  Level: %d\n" .. "  Klasse: %s\n" .. "  Gildenrang: %s\n\n" .. "|cff69ccf0Gildeninformationen:|r\n" .. "  Gildenname: %s\n" .. "  Mitglieder (Gesamt): %d\n" .. "  Mitglieder (Online): %d\n" .. "  Durchschnittslevel (Gilde): %s", playerName or "Unbekannt", playerRealm and (" - " .. playerRealm) or "", playerLevel or 0, playerClassLocalized or "Unbekannt", guildRankName or "Unbekannt", guildName, totalGuildMembers, onlineGuildMembers, averageLevelText )
    end
    self.guildInfoFrame.infoText:SetText(infoTextContent)
end

function SchlingelInc:UpdateGuildStats()
    local statisticsTabFrame = self.guildStatsFrame
    if not statisticsTabFrame or not statisticsTabFrame.classText or not statisticsTabFrame.levelText or
       not statisticsTabFrame.rankText or not statisticsTabFrame.mainScrollChild or
       not statisticsTabFrame.leftColumn or not statisticsTabFrame.rightColumn then
        return
    end
    local totalGuildMembersClassic, _ = GetNumGuildMembers(); totalGuildMembersClassic = totalGuildMembersClassic or 0
    if totalGuildMembersClassic == 0 then
        statisticsTabFrame.classText:SetText("|cffffff00Klassenverteilung:|r\nKeine Mitglieder."); statisticsTabFrame.levelText:SetText("|cffffff00Level-Verteilung:|r\nKeine Mitglieder."); statisticsTabFrame.rankText:SetText("|cffffff00Rang-Verteilung:|r\nKeine Mitglieder.")
        local minContentHeight = statisticsTabFrame.classText:GetFontHeight() + 5; statisticsTabFrame.leftColumn:SetHeight(minContentHeight); statisticsTabFrame.rightColumn:SetHeight(minContentHeight * 2 + 15)
        statisticsTabFrame.mainScrollChild:SetHeight(math.max(statisticsTabFrame.leftColumn:GetHeight(), statisticsTabFrame.rightColumn:GetHeight()) + 20)
        return
    end
    local classDistribution = {}; local levelBrackets = { {minLevel=1,maxLevel=10,count=0,label="1-10"}, {minLevel=11,maxLevel=20,count=0,label="11-20"}, {minLevel=21,maxLevel=30,count=0,label="21-30"}, {minLevel=31,maxLevel=40,count=0,label="31-40"}, {minLevel=41,maxLevel=50,count=0,label="41-50"}, {minLevel=51,maxLevel=60,count=0,label="51-60"} }
    local rankDistribution = {}; local classLevelSums = {}
    for i = 1, totalGuildMembersClassic do
        local name, rankName, _, level, classDisplayName, _, _, _, _, _, classToken, _, _, _ = GetGuildRosterInfo(i)
        if name then
            if classToken and classToken ~= "" then
                if not classDistribution[classToken] then local localizedDisplayName = classDisplayName; if not localizedDisplayName or localizedDisplayName == "" then localizedDisplayName = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken end; classDistribution[classToken]={count = 0, localizedName = localizedDisplayName}; classLevelSums[classToken]={totalLevel = 0, memberCount = 0} end
                classDistribution[classToken].count = classDistribution[classToken].count + 1; if level and level>0 then classLevelSums[classToken].totalLevel = classLevelSums[classToken].totalLevel + level; classLevelSums[classToken].memberCount = classLevelSums[classToken].memberCount + 1 end
            end
            if level and level > 0 then for _, bracket in ipairs(levelBrackets)do if level >= bracket.minLevel and level <= bracket.maxLevel then bracket.count = bracket.count + 1; break end end end
            if rankName and rankName ~= ""then rankDistribution[rankName] = (rankDistribution[rankName] or 0) + 1 end
        end
    end
    local sortedClasses = {}; for token, data in pairs(classDistribution) do local avgL = 0; if classLevelSums[token] and classLevelSums[token].memberCount > 0 then avgL = math.floor(classLevelSums[token].totalLevel / classLevelSums[token].memberCount) end; table.insert(sortedClasses, {classToken = token, localizedName = data.localizedName, count = data.count, averageLevel = avgL}) end
    table.sort(sortedClasses, function(a,b) return a.count > b.count end)
    local classDistributionText = "|cffffff00Klassenverteilung:|r\n"; if #sortedClasses == 0 then classDistributionText = classDistributionText .. "Konnte Klassen nicht ermitteln.\n" else for _, classEntry in ipairs(sortedClasses) do local classColor=(RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEntry.classToken])or{r=1,g=1,b=1}; local colorHexString=string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255); local percentageOfTotal=(classEntry.count / totalGuildMembersClassic) * 100; classDistributionText=classDistributionText..string.format("%s%s|r: %d (|cffffcc00%.1f%%|r, Ø Lvl %d)\n",colorHexString,classEntry.localizedName,classEntry.count,percentageOfTotal,classEntry.averageLevel) end end
    statisticsTabFrame.classText:SetText(classDistributionText); local leftHeight = statisticsTabFrame.classText:GetStringHeight() + 15; statisticsTabFrame.leftColumn:SetHeight(math.max(50, leftHeight))
    local rightColumnText = ""; rightColumnText = rightColumnText .. "|cffffff00Level-Verteilung:|r\n"; local hasLevelData = false; for _, bracket in ipairs(levelBrackets) do if bracket.count > 0 then hasLevelData = true end; rightColumnText = rightColumnText .. string.format("Level %s: %d\n", bracket.label, bracket.count) end; if not hasLevelData then rightColumnText = rightColumnText .. "Keine Leveldaten verfügbar.\n" end
    statisticsTabFrame.levelText:SetText(rightColumnText)
    local sortedRanks = {}; local hasRankData = false; for rankName, count in pairs(rankDistribution) do table.insert(sortedRanks, { name = rankName, count = count }); hasRankData = true end; table.sort(sortedRanks, function(a,b) return a.count > b.count end)
    local rankDistributionText = "\n|cffffff00Rang-Verteilung:|r\n"; if not hasRankData then rankDistributionText = rankDistributionText .. "Keine Rangdaten verfügbar.\n" else for _, rankData in ipairs(sortedRanks) do rankDistributionText = rankDistributionText .. string.format("%s: %d\n", rankData.name, rankData.count) end end
    statisticsTabFrame.rankText:SetText(rankDistributionText); local rightHeight = statisticsTabFrame.levelText:GetStringHeight() + statisticsTabFrame.rankText:GetStringHeight() + 30; statisticsTabFrame.rightColumn:SetHeight(math.max(50, rightHeight))
    local totalRequiredHeight = math.max(leftHeight, rightHeight) + 20; statisticsTabFrame.mainScrollChild:SetHeight(math.max(statisticsTabFrame.mainScrollChild:GetParent():GetHeight(), totalRequiredHeight)) 
end

-- Aktualisiert den "Inaktiv"-Tab (Tab 4)
function SchlingelInc:UpdateInactivityTab()
    local inactivityTab = self.inactivityTabFrame
    if not inactivityTab or not inactivityTab.scrollChild or not inactivityTab.inactiveListUIElements then
        return -- Sicherstellen, dass die UI-Elemente existieren
    end

    local scrollChild = inactivityTab.scrollChild
    local uiElements = inactivityTab.inactiveListUIElements
    local scrollFrame = inactivityTab.scrollFrame

    -- Alte Elemente entfernen
    for _, elementGroup in ipairs(uiElements) do
        if elementGroup.rowFrame then elementGroup.rowFrame:Hide(); elementGroup.rowFrame:SetParent(nil) end
    end
    wipe(uiElements)

    local totalGuildMembersClassic, _ = GetNumGuildMembers()
    totalGuildMembersClassic = totalGuildMembersClassic or 0

    local inactiveMembersList = {}

    if totalGuildMembersClassic > 0 then
        for i = 1, totalGuildMembersClassic do
            -- Classic Era GetGuildRosterInfo (14 return values)
            local name, rankName, _, level, _, _, publicNote, _, isOnline, _, _, _, _, _ = GetGuildRosterInfo(i)
            
            if name and not isOnline then -- Nur offline Mitglieder betrachten
                local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
                local isConsideredInactive = false
                local displayOfflineDuration = "Unbekannt" -- Fallback
                local totalDaysForSorting = 0 

                yearsOffline = yearsOffline or 0
                monthsOffline = monthsOffline or 0
                daysOffline = daysOffline or 0
                hoursOffline = hoursOffline or 0

                totalDaysForSorting = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

                -- Prüfen, ob die Inaktivitätsschwelle erreicht ist
                if yearsOffline > 0 then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d J", yearsOffline)
                elseif monthsOffline > 0 then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d M", monthsOffline)
                elseif daysOffline >= INACTIVE_DAYS_THRESHOLD then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d T", daysOffline)
                elseif INACTIVE_DAYS_THRESHOLD == 0 then -- Spezialfall: Auch kürzlich offline auflisten, wenn Threshold 0 ist
                     isConsideredInactive = true
                     if daysOffline > 0 then displayOfflineDuration = string.format("%d T", daysOffline)
                     elseif hoursOffline > 0 then displayOfflineDuration = string.format("%d Std", hoursOffline)
                     else displayOfflineDuration = "<1 Std" end -- Wenn alle 0 sind
                end
                
                if isConsideredInactive then
                     table.insert(inactiveMembersList, {
                         name = name, 
                         level = level or 0, 
                         rank = rankName or "Unbekannt",
                         note = publicNote or "",
                         displayDuration = displayOfflineDuration,
                         sortableOfflineDays = totalDaysForSorting
                     })
                end
            end
        end
    end

    -- Inaktive Mitglieder sortieren: längste Offline-Zeit zuerst, dann höchstes Level
    table.sort(inactiveMembersList, function(a, b) 
        if a.sortableOfflineDays == b.sortableOfflineDays then 
            return (a.level or 0) > (b.level or 0) 
        end 
        return a.sortableOfflineDays > b.sortableOfflineDays 
    end)

    -- UI für inaktive Mitglieder erstellen
    local yOffset = -25 -- Start unterhalb der Header
    local rowHeight = 20
    local colWidths = { name = 150, level = 40, rank = 120, duration = 80, kick = 80 } -- Breiten angepasst
    local xOffsets = { name = 5, level = 160, rank = 210, duration = 340, kick = 430 } -- Kick-Button Position angepasst

    if #inactiveMembersList > 0 then
        for i, memberData in ipairs(inactiveMembersList) do
            local rowFrame = CreateFrame("Frame", nil, scrollChild)
            rowFrame:SetSize(scrollChild:GetWidth(), rowHeight)
            rowFrame:SetPoint("TOPLEFT", 0, yOffset)
            
            self.UIHelpers:CreateStyledText(rowFrame, memberData.name, FONT_NORMAL, "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.name, 0, colWidths.name, nil, "LEFT", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.level, FONT_NORMAL, "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.level, 0, colWidths.level, nil, "CENTER", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.rank, FONT_NORMAL, "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.rank, 0, colWidths.rank, nil, "LEFT", "MIDDLE")
            self.UIHelpers:CreateStyledText(rowFrame, memberData.displayDuration, FONT_NORMAL, "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.duration, 0, colWidths.duration, nil, "LEFT", "MIDDLE")
            
            -- Kick-Button hinzufügen
            local kickButton = self.UIHelpers:CreateStyledButton(rowFrame, "Entfernen", colWidths.kick, rowHeight - 2, "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.kick, 0, "UIPanelButtonTemplate")
            kickButton:SetScript("OnClick", function() StaticPopup_Show("CONFIRM_GUILD_KICK", memberData.name, nil, { memberName = memberData.name }) end)
            
            table.insert(uiElements, { rowFrame = rowFrame })
            yOffset = yOffset - rowHeight
        end
        scrollChild:SetHeight(math.max(1, (#inactiveMembersList * rowHeight) + 30)) -- Höhe anpassen + Puffer
    else
        local noInactiveText = self.UIHelpers:CreateStyledText(scrollChild, "Keine inaktiven Mitglieder (> ".. INACTIVE_DAYS_THRESHOLD .." T) gefunden.", FONT_NORMAL, "TOP", scrollChild, "TOP", 0, yOffset, scrollChild:GetWidth() - 10, nil, "CENTER")
        table.insert(uiElements, { rowFrame = noInactiveText }) -- rowFrame ist hier der Text selbst
        scrollChild:SetHeight(noInactiveText:GetStringHeight() + 30)
    end

    scrollFrame:SetVerticalScroll(0)
end

--------------------------------------------------------------------------------
-- Funktion zum Umschalten der Sichtbarkeit des Offi-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:ToggleOffiWindow()
    if not self.OffiWindow then self:CreateOffiWindow() end
    if not self.OffiWindow then print(ADDON_PREFIX .. ": OffiWindow konnte nicht erstellt/gefunden werden!"); return end
    if self.OffiWindow:IsShown() then self.OffiWindow:Hide() else
        self.OffiWindow:Show()
        -- Alle Tabs aktualisieren
        if self.UpdateGuildInfo then self:UpdateGuildInfo() end
        if self.UpdateGuildStats then self:UpdateGuildStats() end
        if self.UpdateInactivityTab then self:UpdateInactivityTab() end -- Inaktiv-Tab aktualisieren
        
        if self.GuildRecruitment and self.GuildRecruitment.GetPendingRequests and self.OffiWindow.UpdateRecruitmentTabData then
            self.OffiWindow:UpdateRecruitmentTabData(self.GuildRecruitment.GetPendingRequests())
        end
    end
end

--------------------------------------------------------------------------------
-- Bestätigungsdialog für Gilden-Kick
--------------------------------------------------------------------------------
StaticPopupDialogs["CONFIRM_GUILD_KICK"] = {
    text = "Möchtest du %s wirklich aus der Gilde entfernen?", button1 = ACCEPT, button2 = CANCEL,
    OnAccept = function(selfDialog, data)
        if data and data.memberName then GuildUninvite(data.memberName)
            if SchlingelInc and SchlingelInc.Print then SchlingelInc:Print(data.memberName .. " wurde aus der Gilde entfernt.") end
            if SchlingelInc then C_Timer.After(0.7, function() 
                if SchlingelInc.OffiWindow and SchlingelInc.OffiWindow:IsShown() then
                    -- Alle relevanten Tabs nach Kick aktualisieren
                    if SchlingelInc.UpdateGuildInfo then SchlingelInc:UpdateGuildInfo() end
                    if SchlingelInc.UpdateGuildStats then SchlingelInc:UpdateGuildStats() end
                    if SchlingelInc.UpdateInactivityTab then SchlingelInc:UpdateInactivityTab() end
                end
            end) end
        end
    end,
    OnCancel = function(selfDialog, data) end, timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
}