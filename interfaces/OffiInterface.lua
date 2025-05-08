--------------------------------------------------------------------------------
-- Globale oder Addon-weite Konstanten
--------------------------------------------------------------------------------
local ADDON_NAME = SchlingelInc.name
local OFFIFRAME_NAME = ADDON_NAME .. "OffiFrame"
local TAB_BUTTON_NAME_PREFIX = ADDON_NAME .. "OffiTab"

local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"
local FONT_NORMAL = "GameFontNormal"
local FONT_HIGHLIGHT_SMALL = "GameFontHighlightSmall"

local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

--------------------------------------------------------------------------------
-- Erstellung der einzelnen Tab-Inhalte
--------------------------------------------------------------------------------

function SchlingelInc:_CreateGuildInfoTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "GuildInfoTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    local infoText = self.UIHelpers:CreateStyledText(tabFrame, "Lade Gildeninfos ...", FONT_NORMAL,
                                                     "CENTER", tabFrame, "CENTER", 0, 0,
                                                     560, 300, "CENTER", "MIDDLE")
    tabFrame.infoText = infoText
    self.guildInfoFrame = tabFrame -- Für UpdateGuildInfo
    return tabFrame
end

function SchlingelInc:_CreateRecruitmentTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "RecruitmentTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    self.UIHelpers:CreateStyledText(tabFrame, "Gildenanfragen", FONT_NORMAL,
                                   "TOPLEFT", tabFrame, "TOPLEFT", 10, -10)

    local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME .. "RecruitmentScrollFrame", tabFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(560, 260)
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    tabFrame.scrollFrame = scrollFrame

    local content = CreateFrame("Frame", ADDON_NAME .. "RecruitmentScrollContent", scrollFrame)
    scrollFrame:SetScrollChild(content)
    content:SetSize(560, 1) -- Höhe wird dynamisch
    tabFrame.content = content

    local headers = CreateFrame("Frame", nil, content)
    headers:SetPoint("TOPLEFT", 5, -5) -- Ursprünglicher Ankerpunkt für den Header-Container
    headers:SetSize(550, 20)
    tabFrame.columnHeaders = headers

    -- Definieren wir Spaltenpositionen und -breiten einmal
    local colPositions = {
        name = { x = 0,   width = 100, justify = "LEFT" },
        level= { x = 110, width = 40,  justify = "CENTER" }, -- 100 + 10 (Abstand)
        zone = { x = 160, width = 120, justify = "LEFT" },   -- 110 + 40 + 10
        gold = { x = 290, width = 70,  justify = "RIGHT" },  -- 160 + 120 + 10
        -- Die Buttons kommen danach
    }

    self.UIHelpers:CreateStyledText(headers, "Name", FONT_HIGHLIGHT_SMALL, "TOPLEFT", headers, "TOPLEFT", colPositions.name.x, 0, colPositions.name.width, nil, colPositions.name.justify)
    self.UIHelpers:CreateStyledText(headers, "Level", FONT_HIGHLIGHT_SMALL, "TOPLEFT", headers, "TOPLEFT", colPositions.level.x, 0, colPositions.level.width, nil, colPositions.level.justify)
    self.UIHelpers:CreateStyledText(headers, "Ort", FONT_HIGHLIGHT_SMALL, "TOPLEFT", headers, "TOPLEFT", colPositions.zone.x, 0, colPositions.zone.width, nil, colPositions.zone.justify)
    self.UIHelpers:CreateStyledText(headers, "Gold", FONT_HIGHLIGHT_SMALL, "TOPLEFT", headers, "TOPLEFT", colPositions.gold.x, 0, colPositions.gold.width, nil, colPositions.gold.justify)

    tabFrame.requestsUIElements = {}
    return tabFrame
end

function SchlingelInc:_CreateStatsTabContent(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "StatsTabFrame", parentFrame)
    tabFrame:SetAllPoints(true)

    self.UIHelpers:CreateStyledText(tabFrame, "Gildenstatistiken", FONT_NORMAL,
                                   "TOPLEFT", tabFrame, "TOPLEFT", 10, -10)
    local statsText = self.UIHelpers:CreateStyledText(tabFrame, "Berechne Statistik...", FONT_NORMAL,
                                                     "TOPLEFT", tabFrame, "TOPLEFT", 10, -30,
                                                     560, 280, "LEFT")
    tabFrame.text = statsText
    self.guildStatsFrame = tabFrame -- Für UpdateGuildStats
    return tabFrame
end

--------------------------------------------------------------------------------
-- Helper für Recruitment Tab Zeilen
--------------------------------------------------------------------------------
function SchlingelInc:_CreateRequestRowUI(parent, requestData, yOffset, entryHeight)
    local requestElement = CreateFrame("Frame", nil, parent)
    requestElement:SetPoint("TOPLEFT", 5, yOffset) -- Der Parent ist uiContent, also ist 5 OK
    requestElement:SetSize(550, entryHeight - 2)

    local elementsGroup = { frame = requestElement }

    -- Dieselben Spaltenpositionen wie bei den Headern verwenden
    local colPositions = {
        name = { x = 0,   width = 100, justify = "LEFT" },
        level= { x = 110, width = 40,  justify = "CENTER" },
        zone = { x = 160, width = 120, justify = "LEFT" },
        gold = { x = 290, width = 70,  justify = "RIGHT" },
        -- Button-Startposition (relativ zum Gold-Text Ende oder feste Position)
        acceptButtonStart = 375, -- 290 + 70 + 15 (Abstand)
        declineButtonStart = 455 -- 375 + 75 + 5
    }

    -- Positioniere alle Texte relativ zu `requestElement` mit den definierten x-Offsets
    self.UIHelpers:CreateStyledText(requestElement, requestData.name, FONT_NORMAL, "TOPLEFT", requestElement, "TOPLEFT", colPositions.name.x, 0, colPositions.name.width, nil, colPositions.name.justify)
    self.UIHelpers:CreateStyledText(requestElement, requestData.level, FONT_NORMAL, "TOPLEFT", requestElement, "TOPLEFT", colPositions.level.x, 0, colPositions.level.width, nil, colPositions.level.justify)
    self.UIHelpers:CreateStyledText(requestElement, requestData.zone, FONT_NORMAL, "TOPLEFT", requestElement, "TOPLEFT", colPositions.zone.x, 0, colPositions.zone.width, nil, colPositions.zone.justify)
    local goldText = self.UIHelpers:CreateStyledText(requestElement, requestData.money, FONT_NORMAL, "TOPLEFT", requestElement, "TOPLEFT", colPositions.gold.x, 0, colPositions.gold.width, nil, colPositions.gold.justify)
    -- Wichtig: goldText wird hier nur erstellt, aber nicht mehr als Anker für Buttons verwendet, um Fehlerfortpflanzung zu vermeiden

    elementsGroup.acceptButton = self.UIHelpers:CreateStyledButton(requestElement, "Annehmen", 75, entryHeight,
        "TOPLEFT", requestElement, "TOPLEFT", colPositions.acceptButtonStart, 0, -- Y-Offset 0 für Buttons auf gleicher Höhe
        "UIPanelButtonTemplate",
        function()
            if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleAcceptRequest then
                SchlingelInc.GuildRecruitment:HandleAcceptRequest(requestData.name)
            else
                SchlingelInc:Print("Fehler: HandleAcceptRequest nicht gefunden.")
            end
        end)

    elementsGroup.declineButton = self.UIHelpers:CreateStyledButton(requestElement, "Ablehnen", 75, entryHeight,
        "TOPLEFT", requestElement, "TOPLEFT", colPositions.declineButtonStart, 0,
        "UIPanelButtonTemplate",
        function()
            if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.HandleDeclineRequest then
                SchlingelInc.GuildRecruitment:HandleDeclineRequest(requestData.name)
            else
                SchlingelInc:Print("Fehler: HandleDeclineRequest nicht gefunden.")
            end
        end)
    return elementsGroup
end

--------------------------------------------------------------------------------
-- Hauptfenster-Erstellung
--------------------------------------------------------------------------------
function SchlingelInc:CreateOffiWindow()
    if self.OffiWindow then return end

    local OffiFrame = CreateFrame("Frame", OFFIFRAME_NAME, UIParent, "BackdropTemplate")
    OffiFrame:SetSize(600, 450)
    OffiFrame:SetPoint("RIGHT", -50, 25)
    OffiFrame:SetBackdrop(BACKDROP_SETTINGS)
    OffiFrame:SetMovable(true)
    OffiFrame:EnableMouse(true)
    OffiFrame:RegisterForDrag("LeftButton")
    OffiFrame:SetScript("OnDragStart", OffiFrame.StartMoving)
    OffiFrame:SetScript("OnDragStop", OffiFrame.StopMovingOrSizing)
    OffiFrame:Hide()

    self.UIHelpers:CreateStyledButton(OffiFrame, nil, 22, 22, "TOPRIGHT", OffiFrame, "TOPRIGHT", -5, -5, "UIPanelCloseButton", function() OffiFrame:Hide() end)
    self.UIHelpers:CreateStyledText(OffiFrame, "Schlingel Inc - Offi Interface", FONT_HIGHLIGHT_LARGE, "TOP", OffiFrame, "TOP", 0, -20)

    -- Container für Tab-Inhalte
    local tabContentContainer = CreateFrame("Frame", OFFIFRAME_NAME .. "TabContentContainer", OffiFrame)
    tabContentContainer:SetPoint("TOPLEFT", OffiFrame, "TOPLEFT", 10, -50) -- Platz für Titel
    tabContentContainer:SetPoint("BOTTOMRIGHT", OffiFrame, "BOTTOMRIGHT", -10, 40) -- Platz für Tab-Buttons

    -- Tab-Verwaltung
    local tabs = {}
    local tabContentFrames = {} -- Speichert die von _Create...TabContent zurückgegebenen Frames

    local function SelectTab(index)
        for i, tabButton in ipairs(tabs) do
            if tabContentFrames[i] then -- Stelle sicher, dass der Frame existiert
                if i == index then
                    PanelTemplates_SelectTab(tabButton)
                    tabContentFrames[i]:Show()
                else
                    PanelTemplates_DeselectTab(tabButton)
                    tabContentFrames[i]:Hide()
                end
            end
        end
    end

    local function CreateTabButton(index, name)
        local tabButton = CreateFrame("Button", TAB_BUTTON_NAME_PREFIX .. index, OffiFrame, "OptionsFrameTabButtonTemplate")
        tabButton:SetID(index)
        tabButton:SetText(name)
        tabButton:SetPoint("BOTTOMLEFT", OffiFrame, "BOTTOMLEFT", 20 + (index - 1) * 130, 10)
        PanelTemplates_TabResize(tabButton, 0)
        tabButton:SetScript("OnClick", function() SelectTab(index) end)
        PanelTemplates_DeselectTab(tabButton)
        tabs[index] = tabButton
        return tabButton
    end

    -- Erstelle Tab-Buttons
    CreateTabButton(1, "Gildeninfo")
    CreateTabButton(2, "Anfragen")
    CreateTabButton(3, "Statistik")

    -- Erstelle und verknüpfe Tab-Inhalte
    tabContentFrames[1] = self:_CreateGuildInfoTabContent(tabContentContainer)
    tabContentFrames[2] = self:_CreateRecruitmentTabContent(tabContentContainer)
    tabContentFrames[3] = self:_CreateStatsTabContent(tabContentContainer)

    -- Speichere die Referenz auf den recruitmentFrame des OffiWindows
    -- tabContentFrames[2] ist der von _CreateRecruitmentTabContent zurückgegebene Frame
    OffiFrame.recruitmentFrame = tabContentFrames[2]


    SelectTab(1) -- Standard-Tab

    self.OffiWindow = OffiFrame

    -- --- UpdateRecruitmentTabData Methode für OffiFrame ---
    function OffiFrame:UpdateRecruitmentTabData(inviteRequestsData)
        if not self.recruitmentFrame or not self.recruitmentFrame.content then return end
        local uiContent = self.recruitmentFrame.content
        local uiElements = self.recruitmentFrame.requestsUIElements -- Ist am recruitmentFrame gespeichert
        local scrollFrame = self.recruitmentFrame.scrollFrame

        for _, elementGroup in ipairs(uiElements) do
            if elementGroup.frame then elementGroup.frame:Hide(); elementGroup.frame:SetParent(nil) end
            if elementGroup.noRequestsText then elementGroup.noRequestsText:Hide(); elementGroup.noRequestsText:SetParent(nil) end
        end
        wipe(uiElements)

        local yOffsetBase = -25 -- Unter Spaltenüberschriften
        local entryHeight = 22

        if inviteRequestsData and #inviteRequestsData > 0 then
            for i, request in ipairs(inviteRequestsData) do
                local currentYOffset = yOffsetBase - (i - 1) * entryHeight
                -- Ruft die Helper-Methode von SchlingelInc auf
                local newElementsGroup = SchlingelInc:_CreateRequestRowUI(uiContent, request, currentYOffset, entryHeight)
                table.insert(uiElements, newElementsGroup)
            end
            uiContent:SetHeight(math.max(1, 20 + (#inviteRequestsData * entryHeight) + 5)) -- Höhe für Headers + Entries + Padding
        else
            local noRequestsText = SchlingelInc.UIHelpers:CreateStyledText(uiContent, "Keine Anfragen empfangen.", FONT_NORMAL,
                                                                        "TOPLEFT", uiContent, "TOPLEFT", 5, yOffsetBase, 550)
            table.insert(uiElements, { noRequestsText = noRequestsText })
            uiContent:SetHeight(math.max(1, 20 + entryHeight + 5)) -- Höhe für Headers + Nachricht + Padding
        end
        scrollFrame:SetVerticalScroll(0)
    end
end

--------------------------------------------------------------------------------
-- Update Funktionen für Tab Inhalte
--------------------------------------------------------------------------------
function SchlingelInc:UpdateGuildInfo()
    if not self.guildInfoFrame or not self.guildInfoFrame.infoText then
        return
    end

    local playerName, playerRealm = UnitName("player")
    local level = UnitLevel("player")
    local classDisplayName, _ = UnitClass("player")
    local guildName, guildRankName, _, _ = GetGuildInfo("player") -- Korrigierte Argumente für GetGuildInfo
    local memberCount = GetNumGuildMembers(false) -- false für offline Mitglieder nicht zählen

    local text = string.format("Name: %s%s\nLevel: %d\nKlasse: %s\n\nGilde: %s\nMitglieder (Online): %d\nRang: %s",
        playerName or "Unbekannt",
        playerRealm and (" - " .. playerRealm) or "",
        level or 0,
        classDisplayName or "Unbekannt",
        guildName or "Keine",
        memberCount or 0, -- Sicherstellen, dass memberCount nicht nil ist
        guildRankName or "Unbekannt")
    self.guildInfoFrame.infoText:SetText(text)
end

function SchlingelInc:UpdateGuildStats()
    if not self.guildStatsFrame or not self.guildStatsFrame.text then
        return
    end

    local numMembers = GetNumGuildMembers(true) -- true, um auch Offline-Mitglieder zu zählen
    if numMembers == 0 then
        self.guildStatsFrame.text:SetText("Keine Mitglieder in der Gilde.")
        return
    end

    local classCounts = {}
    for i = 1, numMembers do
        -- GetGuildRosterInfo gibt zurück: name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile
        local _, _, _, _, _, _, _, _, _, _, classToken, _, _, _ = GetGuildRosterInfo(i) -- classToken ist der englische Key
        local localizedClassName = LOCALIZED_CLASS_NAMES_MALE[classToken] or LOCALIZED_CLASS_NAMES_FEMALE[classToken] or classToken

        if localizedClassName then -- Nutze lokalisierten Namen oder Fallback auf classToken
            if not classCounts[localizedClassName] then
                classCounts[localizedClassName] = { count = 0, classTokenForColor = classToken }
            end
            classCounts[localizedClassName].count = classCounts[localizedClassName].count + 1
        end
    end

    local sorted = {}
    for classNameKey, data in pairs(classCounts) do
        table.insert(sorted, {
            display = classNameKey,
            count = data.count,
            classFile = data.classTokenForColor
        })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    local text = "Mitglieder pro Klasse:\n"
    if #sorted == 0 then
        text = text .. "Konnte Klassen nicht ermitteln."
    else
        for _, entry in ipairs(sorted) do
            local color = RAID_CLASS_COLORS[entry.classFile]
            if not color then -- Fallback, falls classFile nicht direkt passt (sollte durch classTokenForColor aber passen)
                if LOCALIZED_CLASS_NAMES_MALE then
                    for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do if v == entry.display then color = RAID_CLASS_COLORS[k]; break; end end
                end
                if not color and LOCALIZED_CLASS_NAMES_FEMALE then
                    for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do if v == entry.display then color = RAID_CLASS_COLORS[k]; break; end end
                end
            end
            color = color or { r = 1, g = 1, b = 1 } -- Standard Weiß

            local hex = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
            text = text .. string.format("%s%s|r: %d\n", hex, entry.display, entry.count)
        end
    end
    self.guildStatsFrame.text:SetText(text)
end

--------------------------------------------------------------------------------
-- Sichtbarkeit des Fensters umschalten
--------------------------------------------------------------------------------
function SchlingelInc:ToggleOffiWindow()
    if not self.OffiWindow then
        self:CreateOffiWindow()
        if not self.OffiWindow then 
            print(ADDON_NAME .. ": OffiWindow konnte nicht erstellt werden!")
            return
        end
    end

    if self.OffiWindow:IsShown() then
        self.OffiWindow:Hide()
    else
        self.OffiWindow:Show()
        self:UpdateGuildInfo()
        self:UpdateGuildStats()
        if self.GuildRecruitment and self.GuildRecruitment.GetPendingRequests and self.OffiWindow.UpdateRecruitmentTabData then
            local requests = self.GuildRecruitment.GetPendingRequests()
            self.OffiWindow:UpdateRecruitmentTabData(requests)
        end
    end
end