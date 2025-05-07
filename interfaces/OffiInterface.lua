function SchlingelInc:CreateOffiWindow()
    -- Verhindert das mehrfache Erstellen des Fensters, falls es bereits existiert.
    if SchlingelInc.OffiWindow then return end

    -- Erstellt den Hauptframe für das Offi-Fenster.
    -- "SchlingelIncOffiFrame" ist der eindeutige Name des Frames.
    -- UIParent ist der übergeordnete Frame (Standard-UI).
    -- "BackdropTemplate" ist eine Vorlage für den Hintergrund und Rand.
    local OffiFrame = CreateFrame("Frame", "SchlingelIncOffiFrame", UIParent, "BackdropTemplate")
    OffiFrame:SetSize(600, 450) -- Breite und Höhe des Fensters.
    OffiFrame:SetPoint("RIGHT", -50, 25) -- Positioniert das Fenster rechts mit etwas Abstand.

    -- Definiert den Hintergrund und den Rand des Fensters.
    OffiFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Textur für den Hintergrund.
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",   -- Textur für den Rand.
        tile = true, tileSize = 32, -- Kachelung für die Texturen.
        edgeSize = 32,              -- Größe des Randes.
        insets = { left = 11, right = 12, top = 12, bottom = 11 } -- Innenabstände für den Inhalt.
    })
    OffiFrame:SetMovable(true)   -- Erlaubt das Verschieben des Fensters.
    OffiFrame:EnableMouse(true)  -- Aktiviert Mausinteraktionen für den Frame.
    OffiFrame:RegisterForDrag("LeftButton") -- Registriert die linke Maustaste zum Ziehen.
    OffiFrame:SetScript("OnDragStart", OffiFrame.StartMoving)    -- Startet das Verschieben beim Ziehen.
    OffiFrame:SetScript("OnDragStop", OffiFrame.StopMovingOrSizing) -- Stoppt das Verschieben.
    OffiFrame:Hide() -- Versteckt das Fenster standardmäßig.

    -- Erstellt den Schließen-Button oben rechts im Fenster.
    local closeButton = CreateFrame("Button", nil, OffiFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5) -- Positioniert den Button.
    closeButton:SetScript("OnClick", function() OffiFrame:Hide() end) -- Versteckt das Fenster beim Klick.

    -- Erstellt den Titeltext des Fensters.
    local title = OffiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20) -- Positioniert den Titel oben zentriert.
    title:SetText("Schlingel Inc - Offi Interface") -- Setzt den Text des Titels.

    -- Tab-Verwaltung: Speichert die Tab-Buttons und die zugehörigen Inhaltsframes.
    local tabs = {}
    local frames = {}

    -- Funktion zum Auswählen eines Tabs.
    -- Hebt den gewählten Tab hervor und zeigt dessen Inhalt, versteckt andere.
    local function SelectTab(index)
        for i, tab in ipairs(tabs) do
            if i == index then
                PanelTemplates_SelectTab(tab) -- Blizzard API zum Hervorheben des Tabs.
                frames[i]:Show()              -- Zeigt den Inhalt des gewählten Tabs.
            else
                PanelTemplates_DeselectTab(tab) -- Blizzard API zum Normalisieren des Tabs.
                frames[i]:Hide()                -- Versteckt den Inhalt anderer Tabs.
            end
        end
    end

    -- Funktion zum Erstellen eines neuen Tab-Buttons.
    local function CreateTab(index, name)
        -- Erstellt einen Button basierend auf einer Blizzard-Vorlage.
        local tab = CreateFrame("Button", "SchlingelIncOffiTab"..index, OffiFrame, "OptionsFrameTabButtonTemplate")
        tab:SetID(index) -- Eindeutige ID für den Tab.
        tab:SetText(name) -- Text auf dem Tab-Button.
        -- Positioniert den Tab unten links, versetzt für jeden weiteren Tab.
        tab:SetPoint("BOTTOMLEFT", OffiFrame, "BOTTOMLEFT", 20 + (index - 1) * 130, 10)
        PanelTemplates_TabResize(tab, 0) -- Passt die Größe des Tabs an den Text an.
        tab:SetScript("OnClick", function() SelectTab(index) end) -- Wählt den Tab beim Klick aus.
        PanelTemplates_DeselectTab(tab) -- Stellt sicher, dass der Tab anfangs nicht ausgewählt ist.
        tabs[index] = tab -- Speichert den Tab-Button.
        return tab
    end

    -- Tab 1: Gildeninformationen
    local guildInfoFrame = CreateFrame("Frame", nil, OffiFrame) -- Frame für den Inhalt von Tab 1.
    guildInfoFrame:SetSize(580, 320) -- Größe des Inhaltsframes.
    guildInfoFrame:SetPoint("TOP", 0, -80) -- Positioniert den Inhaltsframe unterhalb des Titels.

    -- Textfeld für die Gildeninformationen.
    local infoText = guildInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("CENTER", guildInfoFrame, "CENTER", 0, 0) -- Zentriert den Text.
    infoText:SetJustifyH("CENTER") -- Horizontale Ausrichtung: Zentriert.
    infoText:SetJustifyV("MIDDLE") -- Vertikale Ausrichtung: Mittig.
    infoText:SetSize(560, 300)     -- Größe des Textfeldes.
    infoText:SetText("Lade Gildeninfos ...") -- Platzhaltertext.
    guildInfoFrame.infoText = infoText -- Speichert das Textfeld im Frame für späteren Zugriff.

    -- Tab 2: Gildenanfragen (Recruitment)
    local recruitmentFrame = CreateFrame("Frame", nil, OffiFrame) -- Frame für den Inhalt von Tab 2.
    recruitmentFrame:SetSize(580, 320)
    recruitmentFrame:SetPoint("TOP", 0, -80)
    OffiFrame.recruitmentFrame = recruitmentFrame -- Macht den Frame über OffiFrame zugänglich.

    -- Titel für den Anfragen-Tab.
    recruitmentFrame.title = recruitmentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recruitmentFrame.title:SetPoint("TOPLEFT", 10, -10)
    recruitmentFrame.title:SetText("Gildenanfragen")

    -- ScrollFrame für die Liste der Anfragen, falls diese länger als der sichtbare Bereich wird.
    recruitmentFrame.scrollFrame = CreateFrame("ScrollFrame", nil, recruitmentFrame, "UIPanelScrollFrameTemplate")
    recruitmentFrame.scrollFrame:SetSize(560, 260)
    recruitmentFrame.scrollFrame:SetPoint("TOPLEFT", 10, -30)

    -- Inhaltsframe innerhalb des ScrollFrames, der die tatsächlichen Anfragen-Elemente enthält.
    recruitmentFrame.content = CreateFrame("Frame", nil, recruitmentFrame.scrollFrame)
    recruitmentFrame.scrollFrame:SetScrollChild(recruitmentFrame.content) -- Verknüpft den Content mit dem ScrollFrame.
    recruitmentFrame.content:SetSize(560, 1) -- Höhe wird dynamisch angepasst.

    -- Frame für die Spaltenüberschriften der Anfragenliste.
    recruitmentFrame.columnHeaders = CreateFrame("Frame", nil, recruitmentFrame.content)
    recruitmentFrame.columnHeaders:SetPoint("TOPLEFT", 5, -5)
    recruitmentFrame.columnHeaders:SetSize(550, 20)

    -- Spaltenüberschriften (Name, Level, Ort, Gold).
    local nameHeader = recruitmentFrame.columnHeaders:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameHeader:SetPoint("TOPLEFT", 0, 0); nameHeader:SetText("Name"); nameHeader:SetWidth(100)

    local levelHeader = recruitmentFrame.columnHeaders:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelHeader:SetPoint("LEFT", nameHeader, "RIGHT", 10, 0); levelHeader:SetText("Level"); levelHeader:SetWidth(40); levelHeader:SetJustifyH("CENTER")

    local zoneHeader = recruitmentFrame.columnHeaders:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    zoneHeader:SetPoint("LEFT", levelHeader, "RIGHT", 10, 0); zoneHeader:SetText("Ort"); zoneHeader:SetWidth(120)

    local goldHeader = recruitmentFrame.columnHeaders:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldHeader:SetPoint("LEFT", zoneHeader, "RIGHT", 10, 0); goldHeader:SetText("Gold"); goldHeader:SetWidth(70); goldHeader:SetJustifyH("RIGHT")

    -- Tabelle zum Speichern der UI-Elemente jeder einzelnen Anfrage (Zeilen, Buttons etc.).
    recruitmentFrame.requestsUIElements = {}

    -- Tab 3: Gildenstatistik
    local statsFrame = CreateFrame("Frame", nil, OffiFrame) -- Frame für den Inhalt von Tab 3.
    statsFrame:SetSize(580, 320)
    statsFrame:SetPoint("TOP", 0, -80)

    -- Titel für den Statistik-Tab.
    statsFrame.title = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsFrame.title:SetPoint("TOPLEFT", 10, -10)
    statsFrame.title:SetText("Gildenstatistiken")

    -- Textfeld für die Anzeige der Statistiken.
    statsFrame.text = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsFrame.text:SetPoint("TOPLEFT", 10, -30)
    statsFrame.text:SetJustifyH("LEFT")
    statsFrame.text:SetSize(560, 280)
    statsFrame.text:SetText("Berechne Statistik...")
    SchlingelInc.guildStatsFrame = statsFrame -- Speichert den Frame für späteren Zugriff.

    -- Erstellt die Tab-Buttons.
    CreateTab(1, "Gildeninfo")
    CreateTab(2, "Anfragen")
    CreateTab(3, "Statistik")

    -- Weist den Tab-Indizes die entsprechenden Inhaltsframes zu.
    frames[1] = guildInfoFrame
    frames[2] = recruitmentFrame
    frames[3] = statsFrame

    SelectTab(1) -- Wählt den ersten Tab standardmäßig aus.

    -- Speichert Referenzen auf wichtige Frames und Elemente im Haupt-Addon-Table.
    SchlingelInc.OffiWindow = OffiFrame
    SchlingelInc.guildInfoFrame = guildInfoFrame
    -- SchlingelInc.guildStatsFrame wurde bereits oben zugewiesen.

    -- Funktion zum Aktualisieren der Anzeige im Anfragen-Tab.
    -- `inviteRequestsData` ist eine Tabelle mit den Daten der Gildenanfragen.
    function OffiFrame:UpdateRecruitmentTabData(inviteRequestsData)
        -- Sicherheitsabfrage, falls der recruitmentFrame noch nicht existiert.
        if not self.recruitmentFrame then return end
        local uiContent = self.recruitmentFrame.content
        local uiElements = self.recruitmentFrame.requestsUIElements
        local scrollFrame = self.recruitmentFrame.scrollFrame

        -- Entfernt alle zuvor erstellten UI-Elemente für Anfragen, um die Liste neu zu zeichnen.
        for _, elementGroup in ipairs(uiElements) do
            if elementGroup.frame then elementGroup.frame:Hide(); elementGroup.frame:SetParent(nil) end
            if elementGroup.noRequestsText then elementGroup.noRequestsText:Hide(); elementGroup.noRequestsText:SetParent(nil) end
        end
        wipe(uiElements) -- Leert die Tabelle der UI-Elemente.

        local yOffset = -25 -- Vertikaler Abstand vom oberen Rand des Inhalts (unter den Spaltenüberschriften).
        local entryHeight = 22 -- Höhe jeder Zeile für eine Anfrage (inkl. Buttons).

        if inviteRequestsData and #inviteRequestsData > 0 then
            -- Durchläuft alle Anfragen und erstellt für jede eine Zeile mit Informationen und Buttons.
            for i, request in ipairs(inviteRequestsData) do
                -- Frame für die aktuelle Zeile/Anfrage.
                local requestElement = CreateFrame("Frame", nil, uiContent)
                requestElement:SetPoint("TOPLEFT", 5, yOffset - (i - 1) * entryHeight)
                requestElement:SetSize(550, entryHeight - 2) -- Höhe angepasst an Text, Buttons überlagern etwas.

                local currentElementsGroup = { frame = requestElement }
                table.insert(uiElements, currentElementsGroup) -- Speichert die UI-Elemente dieser Zeile.

                -- Textfelder für Name, Level, Ort, Gold.
                local nameText = requestElement:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameText:SetPoint("TOPLEFT", 0, 0); nameText:SetText(request.name); nameText:SetWidth(100)

                local levelText = requestElement:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                levelText:SetPoint("LEFT", nameText, "RIGHT", 10, 0); levelText:SetText(request.level); levelText:SetWidth(40); levelText:SetJustifyH("CENTER")

                local zoneText = requestElement:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                zoneText:SetPoint("LEFT", levelText, "RIGHT", 10, 0); zoneText:SetText(request.zone); zoneText:SetWidth(120)

                local goldText = requestElement:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                goldText:SetPoint("LEFT", zoneText, "RIGHT", 10, 0); goldText:SetText(request.money); goldText:SetWidth(70); goldText:SetJustifyH("RIGHT")

                -- Button "Annehmen".
                local acceptButton = CreateFrame("Button", nil, requestElement, "UIPanelButtonTemplate")
                acceptButton:SetText("Annehmen"); acceptButton:SetSize(75, entryHeight)
                acceptButton:SetPoint("LEFT", goldText, "RIGHT", 15, 0)
                acceptButton:SetScript("OnClick", function()
                    if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleAcceptRequest then
                        SchlingelInc.GuildRecruitment:HandleAcceptRequest(request.name)
                    else
                        SchlingelInc:Print("Fehler: HandleAcceptRequest nicht gefunden.")
                    end
                end)
                currentElementsGroup.acceptButton = acceptButton

                -- Button "Ablehnen".
                local declineButton = CreateFrame("Button", nil, requestElement, "UIPanelButtonTemplate")
                declineButton:SetText("Ablehnen"); declineButton:SetSize(75, entryHeight)
                declineButton:SetPoint("LEFT", acceptButton, "RIGHT", 5, 0)
                declineButton:SetScript("OnClick", function()
                     if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleDeclineRequest then
                        SchlingelInc.GuildRecruitment:HandleDeclineRequest(request.name)
                    else
                        SchlingelInc:Print("Fehler: HandleDeclineRequest nicht gefunden.")
                    end
                end)
                currentElementsGroup.declineButton = declineButton
            end
            -- Passt die Höhe des Scroll-Inhalts dynamisch an die Anzahl der Anfragen an.
            uiContent:SetHeight(20 + (#inviteRequestsData * entryHeight) + 5) -- 20 für Spaltenüberschriften, 5 für unteren Puffer.
        else
            -- Zeigt eine Nachricht an, wenn keine Anfragen vorhanden sind.
            local noRequestsText = uiContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noRequestsText:SetPoint("TOPLEFT", 5, yOffset)
            noRequestsText:SetText("Keine Anfragen empfangen.")
            noRequestsText:SetWidth(550)
            table.insert(uiElements, { noRequestsText = noRequestsText }) -- Speichert das Textfeld zum späteren Entfernen.
            uiContent:SetHeight(20 + entryHeight + 5) -- Höhe für Überschriften und die Nachricht.
        end
        scrollFrame:SetVerticalScroll(0) -- Setzt den Scrollbalken an den Anfang.
    end
end

-- Funktion zum Aktualisieren der Gildeninformationen im Tab 1.
function SchlingelInc:UpdateGuildInfo()
    if not self.guildInfoFrame or not self.guildInfoFrame.infoText then return end

    local playerName, playerRealm = UnitName("player")
    local level = UnitLevel("player")
    local classDisplayName, _ = UnitClass("player")
    local guildName, guildRankName = GetGuildInfo("player")
    local memberCount = GetNumGuildMembers()

    local text = string.format("Name: %s%s\nLevel: %d\nKlasse: %s\n\nGilde: %s\nMitglieder: %d\nRang: %s",
    playerName or "Unbekannt",
    playerRealm and (" - " .. playerRealm) or "",
    level or 0,
    classDisplayName or "Unbekannt",
    guildName or "Keine",
    memberCount,
    guildRankName or "Unbekannt")
    self.guildInfoFrame.infoText:SetText(text)
end

-- Funktion zum Aktualisieren der Gildenstatistik im Tab 3.
function SchlingelInc:UpdateGuildStats()
    if not self.guildStatsFrame or not self.guildStatsFrame.text then return end

    local numMembers = GetNumGuildMembers()
    if numMembers == 0 then
        self.guildStatsFrame.text:SetText("Keine Mitglieder in der Gilde.")
        return
    end

    -- `classCounts` speichert: { ["Deutscher Klassenname"] = { count = X, classToken = "ENGLISCHER_KEY" }, ... }
    local classCounts = {}
    for i = 1, numMembers do
        -- `classToken` ist der englische technische Name (z.B. "WARRIOR").
        -- `localizedClassName` ist der lokalisierte (deutsche) Name (z.B. "Krieger").
        local _, _, _, _, classToken, _, _, _, _, _, localizedClassName = GetGuildRosterInfo(i)

        -- Nutze den deutschen Namen für die Zählung und Anzeige.
        -- Falls der deutsche Name nicht verfügbar ist (sehr unwahrscheinlich im deutschen Client),
        -- wird der englische `classToken` als Fallback verwendet.
        local nameToUse = localizedClassName or classToken

        if nameToUse then
            if not classCounts[nameToUse] then
                -- Initialisiere den Eintrag für diese Klasse. Speichere auch den `classToken` für die Farbe.
                classCounts[nameToUse] = { count = 0, classTokenForColor = classToken }
            end
            classCounts[nameToUse].count = classCounts[nameToUse].count + 1
        end
    end

    -- Sortiert die Klassen nach der Anzahl der Mitglieder absteigend.
    local sorted = {}
    for classNameKey, data in pairs(classCounts) do
        table.insert(sorted, {
            display = classNameKey, -- Der deutsche Name für die Anzeige.
            count = data.count,
            classFile = data.classTokenForColor -- Der englische Token für die Farbe.
        })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    local text = "Mitglieder pro Klasse:\n"
    if #sorted == 0 then
        text = text .. "Konnte Klassen nicht ermitteln."
    else
        for _, entry in ipairs(sorted) do
            -- Versuche, die Farbe anhand des englischen `classFile` (Token) zu bekommen.
            local color = RAID_CLASS_COLORS[entry.classFile]

            -- Falls der `classFile` nicht direkt im `RAID_CLASS_COLORS` ist (z.B. weil `localizedClassName`
            -- als `classFile` gespeichert wurde, weil `classToken` nil war),
            -- versuche, den englischen Key über die Lokalisierungstabellen zu finden.
            if not color then
                if LOCALIZED_CLASS_NAMES_MALE then
                    for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                        if v == entry.display then -- Vergleiche mit dem angezeigten deutschen Namen
                            color = RAID_CLASS_COLORS[k]
                            break
                        end
                    end
                end
                if not color and LOCALIZED_CLASS_NAMES_FEMALE then
                     for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
                        if v == entry.display then
                            color = RAID_CLASS_COLORS[k]
                            break
                        end
                    end
                end
            end
            -- Standardfarbe, falls keine spezifische Klassenfarbe gefunden wurde.
            color = color or { r = 1, g = 1, b = 1 }

            local hex = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
            text = text .. string.format("%s%s|r: %d\n", hex, entry.display, entry.count)
        end
    end
    self.guildStatsFrame.text:SetText(text)
end

-- Funktion zum Umschalten der Sichtbarkeit des Offi-Fensters.
function SchlingelInc:ToggleOffiWindow()
    -- Erstellt das Fenster, falls es noch nicht existiert.
    if not self.OffiWindow then
        self:CreateOffiWindow()
    end

    if self.OffiWindow:IsShown() then
        self.OffiWindow:Hide()
    else
        self.OffiWindow:Show()
        -- Aktualisiert die Daten in den Tabs, wenn das Fenster angezeigt wird.
        self:UpdateGuildInfo()
        self:UpdateGuildStats()
        -- Aktualisiert die Anfragenliste.
        if self.GuildRecruitment and self.GuildRecruitment.GetPendingRequests then
            local requests = self.GuildRecruitment.GetPendingRequests()
            if self.OffiWindow.UpdateRecruitmentTabData then
                self.OffiWindow:UpdateRecruitmentTabData(requests)
            end
        end
    end
end