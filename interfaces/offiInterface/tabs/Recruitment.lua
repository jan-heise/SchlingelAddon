SchlingelInc.Tabs = SchlingelInc.Tabs or {}

-- Definiere das Modul für den Recruitment Tab
SchlingelInc.Tabs.Recruitment = {
    Frame = nil, -- Speichert eine Referenz auf den UI Frame des Tabs
    ScrollFrame = nil, -- Speichert eine Referenz auf den ScrollFrame
    Content = nil, -- Speichert eine Referenz auf den gescrollten Inhalt Frame
    requestsUIElements = {}, -- Tabelle zum Speichern der UI-Elemente für jede Anfragezeile.
}

--------------------------------------------------------------------------------
-- Erstellt den Inhalt für den "Anfragen"-Tab (Tab 2)
-- Diese Funktion ist verantwortlich für das Layout und die Grundstruktur
-- des "Anfragen"-Tabs.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Recruitment:CreateUI(parentFrame)
    -- Zugriffe auf Konstanten über SchlingelInc Tabelle
    local tabFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "RecruitmentTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    -- Titel für den Tab. Zugriffe auf UIHelpers über SchlingelInc Tabelle
    SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Gildenanfragen", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

    -- ScrollFrame für die Liste der Anfragen. Zugriffe auf Konstanten über SchlingelInc Tabelle
    local scrollFrame = CreateFrame("ScrollFrame", SchlingelInc.ADDON_PREFIX .. "RecruitmentScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 380)
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    -- Speichere Referenz im Modul
    self.ScrollFrame = scrollFrame

    -- Inhalt des ScrollFrames (dieser Frame wird tatsächlich gescrollt). Zugriffe auf Konstanten über SchlingelInc Tabelle
    local scrollChildContent = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "RecruitmentScrollContent", scrollFrame)
    scrollFrame:SetScrollChild(scrollChildContent)
    scrollChildContent:SetSize(560, 1) -- Höhe wird dynamisch angepasst.
    -- Speichere Referenz im Modul
    self.Content = scrollChildContent

    -- Frame für die Spaltenüberschriften.
    local columnHeadersFrame = CreateFrame("Frame", nil, scrollChildContent)
    columnHeadersFrame:SetPoint("TOPLEFT", 5, -5)
    columnHeadersFrame:SetSize(550, 20)

    -- Definition der Spaltenpositionen und -breiten.
    local columnPositions = {
        name = { xOffset = 0, width = 100, justification = "LEFT" },
        level = { xOffset = 110, width = 40, justification = "CENTER" },
        zone = { xOffset = 160, width = 120, justification = "LEFT" },
        gold = { xOffset = 290, width = 70, justification = "RIGHT" }
    }

    -- Erstellen der Texte für die Spaltenüberschriften. Zugriffe auf UIHelpers über SchlingelInc Tabelle und Konstanten
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Name", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Level", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Ort", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    SchlingelInc.UIHelpers:CreateStyledText(columnHeadersFrame, "Gold", SchlingelInc.FONT_HIGHLIGHT_SMALL,
        "TOPLEFT", columnHeadersFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)

    -- Speichere Referenzen auf den Tab-Frame und die UI-Elemente-Liste im Modul
    self.Frame = tabFrame
    -- requestsUIElements bleibt eine Tabelle im Modul

    -- Rückgabe des erstellten Frames
    return tabFrame
end

--------------------------------------------------------------------------------
-- Hilfsfunktion zum Erstellen einer UI-Zeile für eine Gildenanfrage
-- Diese Funktion wurde vom Hauptfile in dieses Modul verschoben.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Recruitment:CreateRequestRowUI(parentFrame, requestData, yPositionOffset, rowHeight)
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

    -- Erstellen der Textfelder für Name, Level, Ort und Gold. Zugriffe auf UIHelpers über SchlingelInc Tabelle und Konstanten
    SchlingelInc.UIHelpers:CreateStyledText(requestRowFrame, requestData.name, SchlingelInc.FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.name.xOffset, 0, columnPositions.name.width, nil, columnPositions.name.justification)
    SchlingelInc.UIHelpers:CreateStyledText(requestRowFrame, requestData.level, SchlingelInc.FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.level.xOffset, 0, columnPositions.level.width, nil, columnPositions.level.justification)
    SchlingelInc.UIHelpers:CreateStyledText(requestRowFrame, requestData.zone, SchlingelInc.FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.zone.xOffset, 0, columnPositions.zone.width, nil, columnPositions.zone.justification)
    SchlingelInc.UIHelpers:CreateStyledText(requestRowFrame, requestData.money, SchlingelInc.FONT_NORMAL,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.gold.xOffset, 0, columnPositions.gold.width, nil, columnPositions.gold.justification)

    -- Funktion, die beim Klick auf "Annehmen" ausgeführt wird.
    local function onAcceptClick()
        -- Annahme: SchlingelInc.GuildRecruitment existiert an anderer Stelle
        if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleAcceptRequest then
            SchlingelInc.GuildRecruitment:HandleAcceptRequest(requestData.name)
        else
            SchlingelInc:Print("Fehler: GuildRecruitment oder HandleAcceptRequest nicht gefunden.")
        end
    end
    -- Zugriffe auf UIHelpers über SchlingelInc
    uiElementsGroup.acceptButton = SchlingelInc.UIHelpers:CreateStyledButton(requestRowFrame, "Annehmen", 75, rowHeight,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.acceptButtonStart, 0, "UIPanelButtonTemplate", onAcceptClick)

    -- Funktion, die beim Klick auf "Ablehnen" ausgeführt wird.
    local function onDeclineClick()
        -- Annahme: SchlingelInc.GuildRecruitment existiert an anderer Stelle
        if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleDeclineRequest then
            SchlingelInc.GuildRecruitment:HandleDeclineRequest(requestData.name)
        else
            SchlingelInc:Print("Fehler: GuildRecruitment oder HandleDeclineRequest nicht gefunden.")
        end
    end
    -- Zugriffe auf UIHelpers über SchlingelInc
    uiElementsGroup.declineButton = SchlingelInc.UIHelpers:CreateStyledButton(requestRowFrame, "Ablehnen", 75, rowHeight,
        "TOPLEFT", requestRowFrame, "TOPLEFT", columnPositions.declineButtonStart, 0, "UIPanelButtonTemplate", onDeclineClick)

    return uiElementsGroup
end


--------------------------------------------------------------------------------
-- Funktion zum Aktualisieren der Daten im "Anfragen"-Tab.
-- Diese Funktion wurde vom OffiWindowFrame in dieses Modul verschoben.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.Recruitment:UpdateData(inviteRequestsData)
    -- Überprüfe, ob die benötigten UI-Elemente im Modul gespeichert sind
    if not self.Frame or not self.Content or not self.ScrollFrame then
        return -- Abbruch, wenn benötigte UI-Elemente nicht existieren.
    end

    local uiContentFrame = self.Content
    local uiElementsTable = self.requestsUIElements -- Zugriff über self
    local scrollFrame = self.ScrollFrame -- Zugriff über self

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
            -- Rufe die Hilfsfunktion dieses Moduls auf (via self)
            local newRowElements = self:CreateRequestRowUI(uiContentFrame, requestItemData, currentYPosition, entryRowHeight)
            table.insert(uiElementsTable, newRowElements) -- Füge zur Liste im Modul hinzu
        end
        -- Passt die Höhe des scrollbaren Inhalts an.
        uiContentFrame:SetHeight(math.max(1, 20 + (#inviteRequestsData * entryRowHeight) + 5))
    else
        -- Zeigt eine Nachricht an, wenn keine Anfragen vorhanden sind.
        -- Zugriffe auf UIHelpers über SchlingelInc Tabelle und Konstanten
        local noRequestsFontString = SchlingelInc.UIHelpers:CreateStyledText(uiContentFrame, "Keine Gildenanfragen vorhanden.", SchlingelInc.FONT_NORMAL,
            "TOPLEFT", uiContentFrame, "TOPLEFT", 5, yPositionOffsetBase, 550)
        table.insert(uiElementsTable, { noRequestsText = noRequestsFontString }) -- Füge zur Liste im Modul hinzu
        uiContentFrame:SetHeight(math.max(1, 20 + entryRowHeight + 5))
    end
    scrollFrame:SetVerticalScroll(0) -- Scrollt nach ganz oben.
end


-- Event-Handler: GuildInviteRequest
local RecruitmentEventsFrame = CreateFrame("Frame")
RecruitmentEventsFrame:RegisterEvent("GUILD_INVITE_REQUEST")

RecruitmentEventsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_INVITE_REQUEST" or event == "GUILD_MEMBERSHIP_CHANGED" then
        -- Stelle sicher, dass das Modul und die UpdateData Methode existieren
        if SchlingelInc.Tabs.Recruitment and SchlingelInc.Tabs.Recruitment.UpdateData then
             -- Annahme: SchlingelInc.GuildRecruitment.GetPendingRequests() liefert die aktuellen Daten
             if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.GetPendingRequests then
                 SchlingelInc.Tabs.Recruitment:UpdateData(SchlingelInc.GuildRecruitment.GetPendingRequests())
             else
                 -- Ggf. hier trotzdem UpdateData aufrufen mit nil oder leere Tabelle, um die Liste zu leeren
                 SchlingelInc.Tabs.Recruitment:UpdateData({})
             end
        end
    end
end)