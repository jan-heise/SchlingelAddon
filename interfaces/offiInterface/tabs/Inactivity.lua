SchlingelInc.Tabs = SchlingelInc.Tabs or {}

-- Definiere das Modul für den Inactivity Tab
SchlingelInc.Tabs.Inactivity = {
    Frame = nil,           -- Hauptframe des Tabs
    scrollFrame = nil,     -- ScrollFrame für die Liste
    scrollChild = nil,     -- Inhalt des ScrollFrames
    columnHeaders = nil,   -- Frame für Spaltenüberschriften
    inactiveListUIElements = {}, -- Tabelle zum Speichern der UI-Elemente für jede Mitgliederzeile.
}

--------------------------------------------------------------------------------
-- Erstellt den Inhalt für den "Inaktiv"-Tab (Tab 4)
-- Diese Funktion ist verantwortlich für das Layout und die Grundstruktur
-- des "Inaktiv"-Tabs.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Inactivity:CreateUI(parentFrame)
    -- Zugriffe auf Konstanten über SchlingelInc Tabelle
    local tabFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "InactivityTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Titeltext, der den Schwellenwert für Inaktivität anzeigt. Zugriffe auf Konstanten über SchlingelInc
    local titleText = string.format("Inaktive Mitglieder (> %d Tage)", SchlingelInc.INACTIVE_DAYS_THRESHOLD)
    -- Zugriffe auf UIHelpers über SchlingelInc
    SchlingelInc.UIHelpers:CreateStyledText(tabFrame, titleText, SchlingelInc.FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    -- ScrollFrame für die Liste der inaktiven Mitglieder. Zugriffe auf Konstanten über SchlingelInc
    local scrollFrame = CreateFrame("ScrollFrame", SchlingelInc.ADDON_PREFIX .. "InactivityScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 350) -- Höhe ggf. anpassen.
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    self.scrollFrame = scrollFrame -- Referenz im Modul speichern

    -- Inhalt des ScrollFrames. Zugriffe auf Konstanten über SchlingelInc
    local scrollChild = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "InactivityScrollChild", scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10) -- Etwas schmaler für Scrollbalken.
    scrollChild:SetHeight(1) -- Höhe wird dynamisch angepasst.
    self.scrollChild = scrollChild -- Referenz im Modul speichern

    -- Spaltenüberschriften.
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChild)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5)
    columnHeadersFrame:SetSize(550, 20)
    self.columnHeaders = columnHeadersFrame -- Referenz im Modul speichern

    -- Zugriffe auf UIHelpers über SchlingelInc
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", 0, 0, 150, nil, "LEFT")
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 160, 0, 40, nil, "CENTER")
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Rang", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 210, 0, 120, nil, "LEFT")
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Offline Seit", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "LEFT", columnHeadersFrame, "LEFT", 340, 0, 80, nil, "LEFT") -- Breite angepasst

    self.inactiveListUIElements = {} -- Tabelle zum Speichern der UI-Elemente für die Liste im Modul.
    self.Frame = tabFrame -- Referenz auf den Tab-Frame im Modul speichern.
    return tabFrame
end

--------------------------------------------------------------------------------
-- Funktion zum Aktualisieren des "Inaktiv"-Tabs
-- Listet Gildenmitglieder auf, die länger als INACTIVE_DAYS_THRESHOLD offline sind.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Inactivity:UpdateData()
    -- Überprüfe, ob die benötigten UI-Elemente im Modul gespeichert sind
    if not self.Frame or not self.scrollChild or not self.inactiveListUIElements or not self.scrollFrame then
        SchlingelInc:Print("Inactivity UpdateData: UI Elemente nicht gefunden.")
        return -- Sicherstellen, dass die UI-Elemente existieren.
    end

    -- Lokale Referenzen für klareren Code innerhalb der Funktion
    local scrollChild = self.scrollChild
    local uiElements = self.inactiveListUIElements
    local scrollFrame = self.scrollFrame

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
                elseif daysOffline >= SchlingelInc.INACTIVE_DAYS_THRESHOLD then
                    isConsideredInactive = true
                    displayOfflineDuration = string.format("%d T", daysOffline)
                elseif SchlingelInc.INACTIVE_DAYS_THRESHOLD == 0 then -- Spezialfall: Alle Offline-Mitglieder auflisten, wenn Threshold 0 ist.
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

            -- Zugriffe auf UIHelpers über SchlingelInc
            local nameText = memberData.name
            if SchlingelInc and SchlingelInc.RemoveRealmFromName then
                nameText = SchlingelInc:RemoveRealmFromName(memberData.name)
            end
            SchlingelInc.UIHelpers:CreateStyledText(rowFrame, nameText, SchlingelInc.FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.name, 0, colWidths.name, nil, "LEFT", "MIDDLE")
            SchlingelInc.UIHelpers:CreateStyledText(rowFrame, memberData.level, SchlingelInc.FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.level, 0, colWidths.level, nil, "CENTER", "MIDDLE")
            SchlingelInc.UIHelpers:CreateStyledText(rowFrame, memberData.rank, SchlingelInc.FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.rank, 0, colWidths.rank, nil, "LEFT", "MIDDLE")
            SchlingelInc.UIHelpers:CreateStyledText(rowFrame, memberData.displayDuration, SchlingelInc.FONT_NORMAL,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.duration, 0, colWidths.duration, nil, "LEFT", "MIDDLE")

            -- Kick-Button hinzufügen.
            if CanGuildRemove("player") then
                -- Zugriffe auf UIHelpers über SchlingelInc
                local kickButton = SchlingelInc.UIHelpers:CreateStyledButton(rowFrame, "Entfernen", colWidths.kick, rowHeight - 2,
                "TOPLEFT", rowFrame, "TOPLEFT", xOffsets.kick, 0, "UIPanelButtonTemplate")
            kickButton:SetScript("OnClick", function()
                -- Zeigt einen Bestätigungsdialog vor dem Entfernen.
                StaticPopup_Show("CONFIRM_GUILD_KICK", memberData.name, nil, { memberName = memberData.name })
            end)
            end

            table.insert(uiElements, { rowFrame = rowFrame }) -- Fügt den Frame der Zeile zur UI-Elemente-Liste hinzu.
            yOffset = yOffset - rowHeight -- Nächste Zeile weiter unten.
        end
        -- Passt die Höhe des scrollbaren Inhalts an.
        scrollChild:SetHeight(math.max(1, (#inactiveMembersList * rowHeight) + 30)) -- + Puffer.
    else
        -- Nachricht, wenn keine inaktiven Mitglieder gefunden wurden.
        local noInactiveText = SchlingelInc.UIHelpers:CreateStyledText(scrollChild,
            "Keine inaktiven Mitglieder (> ".. SchlingelInc.INACTIVE_DAYS_THRESHOLD .." T) gefunden.", SchlingelInc.FONT_NORMAL,
            "TOP", scrollChild, "TOP", 0, yOffset, scrollChild:GetWidth() - 10, nil, "CENTER")
        table.insert(uiElements, { rowFrame = noInactiveText }) -- Hier ist rowFrame der Text selbst.
        scrollChild:SetHeight(noInactiveText:GetStringHeight() + 30)
    end

    scrollFrame:SetVerticalScroll(0) -- Scrollt nach ganz oben.
end

-- Event-Handler: Gildenliste aktualisiert
-- Ruft die UpdateData Funktion dieses Moduls auf
local InactivityEventsFrame = CreateFrame("Frame")
InactivityEventsFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
InactivityEventsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        -- Rufe die UpdateData Funktion des Inactivity Moduls auf
        if SchlingelInc.Tabs.Inactivity and SchlingelInc.Tabs.Inactivity.UpdateData then
            SchlingelInc.Tabs.Inactivity:UpdateData()
        end
    end
end)