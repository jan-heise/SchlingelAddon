SchlingelInc.Tabs = SchlingelInc.Tabs or {}

-- Definiere das Modul für den Stats Tab
SchlingelInc.Tabs.Stats = {
    Frame = nil,           -- Hauptframe des Tabs
    mainScrollChild = nil, -- Inhalt des Haupt-ScrollFrames
    leftColumn = nil,      -- Linke Spalte für Statistiken
    rightColumn = nil,     -- Rechte Spalte für Statistiken
    classText = nil,       -- Textfeld für Klassenverteilung
    levelText = nil,       -- Textfeld für Levelverteilung
    rankText = nil,        -- Textfeld für Rangverteilung
}

--------------------------------------------------------------------------------
-- Erstellt den Inhalt für den "Statistik"-Tab (Tab 3)
-- Diese Funktion ist verantwortlich für das Layout und die Grundstruktur
-- des "Statistik"-Tabs.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Stats:CreateUI(parentFrame)
    -- Zugriffe auf Konstanten über SchlingelInc Tabelle
    local tabFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "StatsTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Titel für den Tab. Zugriffe auf UIHelpers über SchlingelInc
    local title = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Gildenstatistiken - Verteilungen", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)
    -- self.title = title -- Referenz speichern, falls nötig

    -- Haupt-ScrollFrame für den Statistik-Tab. Zugriffe auf Konstanten über SchlingelInc
    local mainStatsScrollFrame = CreateFrame("ScrollFrame", SchlingelInc.ADDON_PREFIX .. "StatsMainScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    mainStatsScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 10, -45)
    mainStatsScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -10, 10)
    -- self.mainStatsScrollFrame = mainStatsScrollFrame -- Referenz speichern, falls nötig

    -- Inhalt des ScrollFrames. Zugriffe auf Konstanten über SchlingelInc
    local mainScrollChild = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "StatsMainScrollChild", mainStatsScrollFrame)
    mainScrollChild:SetWidth(mainStatsScrollFrame:GetWidth() - 20) -- Etwas schmaler für Scrollbalken.
    mainScrollChild:SetHeight(1) -- Höhe wird dynamisch angepasst.
    mainStatsScrollFrame:SetScrollChild(mainScrollChild)
    self.mainScrollChild = mainScrollChild -- Referenz im Modul speichern

    local availableWidth = mainScrollChild:GetWidth()
    local columnWidth = (availableWidth / 2) - 10 -- Breite für jede der beiden Spalten.

    -- Linke Spalte für Statistiken. Zugriffe auf Konstanten über SchlingelInc
    local leftColumnFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "StatsLeftColumn", mainScrollChild)
    leftColumnFrame:SetPoint("TOPLEFT", 0, -10)
    leftColumnFrame:SetWidth(columnWidth)
    leftColumnFrame:SetHeight(1) -- Höhe wird dynamisch angepasst.
    self.leftColumn = leftColumnFrame -- Referenz im Modul speichern

    -- Zugriffe auf UIHelpers über SchlingelInc
    local classText = SchlingelInc.UIHelpers:CreateStyledText(leftColumnFrame, "Lade Klassenverteilung...", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", leftColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
    self.classText = classText -- Referenz im Modul speichern

    -- Rechte Spalte für Statistiken. Zugriffe auf Konstanten über SchlingelInc
    local rightColumnFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "StatsRightColumn", mainScrollChild)
    rightColumnFrame:SetPoint("TOPLEFT", leftColumnFrame, "TOPRIGHT", 15, 0) -- Rechts neben der linken Spalte.
    rightColumnFrame:SetWidth(columnWidth)
    rightColumnFrame:SetHeight(1) -- Höhe wird dynamisch angepasst.
    self.rightColumn = rightColumnFrame -- Referenz im Modul speichern

    -- Zugriffe auf UIHelpers über SchlingelInc
    local levelText = SchlingelInc.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Levelverteilung...", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", rightColumnFrame, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
    self.levelText = levelText -- Referenz im Modul speichern

    -- Zugriffe auf UIHelpers über SchlingelInc
    local rankText = SchlingelInc.UIHelpers:CreateStyledText(rightColumnFrame, "Lade Rangverteilung...", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", levelText, "BOTTOMLEFT", 0, -15, columnWidth, nil, "LEFT") -- Unterhalb des Level-Textes.
    self.rankText = rankText -- Referenz im Modul speichern

    self.Frame = tabFrame -- Speichert eine Referenz auf den Tab-Frame im Modul.
    return tabFrame
end

--------------------------------------------------------------------------------
-- Funktion zum Aktualisieren des "Statistik"-Tabs
-- Sammelt Daten über Klassen-, Level- und Rangverteilung in der Gilde.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Stats:UpdateData()
    -- Überprüfe, ob die benötigten UI-Elemente im Modul gespeichert sind
    if not self.Frame or not self.classText or
       not self.levelText or not self.rankText or
       not self.mainScrollChild or not self.leftColumn or
       not self.rightColumn then
        return -- Abbruch, wenn wichtige UI-Elemente fehlen.
    end

    -- Lokale Referenzen für klareren Code innerhalb der Funktion
    local statisticsTabFrame = self.Frame
    local mainScrollChild = self.mainScrollChild
    local leftColumn = self.leftColumn
    local rightColumn = self.rightColumn
    local classText = self.classText
    local levelText = self.levelText
    local rankText = self.rankText

    local totalGuildMembersClassic, _ = GetNumGuildMembers()
    totalGuildMembersClassic = totalGuildMembersClassic or 0

    if totalGuildMembersClassic == 0 then
        -- Keine Mitglieder, zeige entsprechende Nachrichten.
        classText:SetText("|cffffff00Klassenverteilung:|r\nKeine Mitglieder.")
        levelText:SetText("|cffffff00Level-Verteilung:|r\nKeine Mitglieder.")
        rankText:SetText("|cffffff00Rang-Verteilung:|r\nKeine Mitglieder.")

        local minContentHeight = classText:GetStringHeight() + 5
        leftColumn:SetHeight(minContentHeight)
        rightColumn:SetHeight(minContentHeight * 2 + 15) -- Genug Platz für Level- und Rangtext.
        mainScrollChild:SetHeight(math.max(leftColumn:GetHeight(), rightColumn:GetHeight()) + 20)
        return
    end

    local classDistribution = {} -- Verteilung der Klassen.
    local levelBrackets = { -- Vordefinierte Level-Bereiche.
        {minLevel=1, maxLevel=10, count=0, label="1-10"},
        {minLevel=11, maxLevel=20, count=0, label="11-20"},
        {minLevel=21, maxLevel=30, count=0, label="21-30"},
        {minLevel=31, maxLevel=40, count=0, label="31-40"},
        {minLevel=41, maxLevel=50, count=0, label="41-50"},
        {minLevel=51, maxLevel=59, count=0, label="51-59"},
        {minLevel=60, maxLevel=60, count=0, label="60"}
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
            local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEntry.classToken]) or {r=1,g=1,b=1}
            local colorHexString = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
            local percentageOfTotal = (classEntry.count / totalGuildMembersClassic) * 100
            classDistributionText = classDistributionText .. string.format("%s%s|r: %d (|cffffcc00%.1f%%|r, Ø Lvl %d)\n",
                colorHexString, classEntry.localizedName, classEntry.count, percentageOfTotal, classEntry.averageLevel)
        end
    end
    classText:SetText(classDistributionText)
    local leftHeight = classText:GetStringHeight() + 15
    leftColumn:SetHeight(math.max(50, leftHeight))

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
    levelText:SetText(rightColumnText)

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
    rankText:SetText(rankDistributionText)
    local rightHeight = levelText:GetStringHeight() + rankText:GetStringHeight() + 30
    rightColumn:SetHeight(math.max(50, rightHeight))

    -- Passt die Höhe des Scroll-Containers an den größten Inhalt an.
    local totalRequiredHeight = math.max(leftHeight, rightHeight) + 20
    mainScrollChild:SetHeight(math.max(mainScrollChild:GetParent():GetHeight(), totalRequiredHeight))
end

-- Event-Handler: Gildenliste aktualisiert
local StatsEventsFrame = CreateFrame("Frame")
StatsEventsFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
StatsEventsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        -- Rufe die UpdateData Funktion des Stats Moduls auf
        if SchlingelInc.Tabs.Stats and SchlingelInc.Tabs.Stats.UpdateData then
            SchlingelInc.Tabs.Stats:UpdateData()
        end
    end
end)