function SchlingelInc:CreateOffiWindow()
    if SchlingelInc.OffiWindow then return end

    local OffiFrame = CreateFrame("Frame", "SchlingelIncOffiFrame", UIParent, "BackdropTemplate")
    OffiFrame:SetSize(600, 450)
    OffiFrame:SetPoint("RIGHT", -50, 25)
    OffiFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    OffiFrame:SetMovable(true)
    OffiFrame:EnableMouse(true)
    OffiFrame:RegisterForDrag("LeftButton")
    OffiFrame:SetScript("OnDragStart", OffiFrame.StartMoving)
    OffiFrame:SetScript("OnDragStop", OffiFrame.StopMovingOrSizing)
    OffiFrame:Hide()

    -- Schließen-Button
    local closeButton = CreateFrame("Button", nil, OffiFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    -- Titel
    local title = OffiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Schlingel Inc - Offi Interface")

    -- Tabs
    local tabs = {}
    local frames = {}

    local function SelectTab(index)
        for i, tab in ipairs(tabs) do
            if i == index then
                PanelTemplates_SelectTab(tab)
                frames[i]:Show()
            else
                PanelTemplates_DeselectTab(tab)
                frames[i]:Hide()
            end
        end
    end

    local function CreateTab(index, name)
        local tab = CreateFrame("Button", "SchlingelIncOffiTab"..index, OffiFrame, "OptionsFrameTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(name)
        tab:SetPoint("BOTTOMLEFT", OffiFrame, "BOTTOMLEFT", 20 + (index - 1) * 130, 10)
        PanelTemplates_TabResize(tab, 0)
        tab:SetScript("OnClick", function() SelectTab(index) end)
        PanelTemplates_DeselectTab(tab)
        tabs[index] = tab
        return tab
    end

    -- Tab 1: Gildeninfos
    local guildInfoFrame = CreateFrame("Frame", nil, OffiFrame)
    guildInfoFrame:SetSize(580, 320)
    guildInfoFrame:SetPoint("TOP", 0, -80)

    local infoText = guildInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("CENTER", guildInfoFrame, "CENTER", 0, 0)
    infoText:SetJustifyH("CENTER")
    infoText:SetJustifyV("MIDDLE")
    infoText:SetSize(560, 600)
    infoText:SetText("Lade Gildeninfos ...")
    guildInfoFrame.infoText = infoText

    -- Tab 2: Gildenanfragen
    local recruitmentFrame = CreateFrame("Frame", nil, OffiFrame)
    recruitmentFrame:SetSize(580, 320)
    recruitmentFrame:SetPoint("TOP", 0, -80)

    recruitmentFrame.title = recruitmentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recruitmentFrame.title:SetPoint("TOPLEFT", 10, -10)
    recruitmentFrame.title:SetText("Gildenanfragen")

    recruitmentFrame.scrollFrame = CreateFrame("ScrollFrame", nil, recruitmentFrame, "UIPanelScrollFrameTemplate")
    recruitmentFrame.scrollFrame:SetSize(560, 260)
    recruitmentFrame.scrollFrame:SetPoint("TOPLEFT", 10, -30)

    recruitmentFrame.content = CreateFrame("Frame", nil, recruitmentFrame.scrollFrame)
    recruitmentFrame.scrollFrame:SetScrollChild(recruitmentFrame.content)
    recruitmentFrame.content:SetSize(560, 280)

    recruitmentFrame.content.text = recruitmentFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recruitmentFrame.content.text:SetPoint("TOPLEFT", 5, -5)
    recruitmentFrame.content.text:SetJustifyH("LEFT")
    recruitmentFrame.content.text:SetText("Keine Anfragen empfangen.")

    -- Tab 3: Gildenstatistik
    local statsFrame = CreateFrame("Frame", nil, OffiFrame)
    statsFrame:SetSize(580, 320)
    statsFrame:SetPoint("TOP", 0, -80)

    statsFrame.title = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsFrame.title:SetPoint("TOPLEFT", 10, -10)
    statsFrame.title:SetText("Gildenstatistiken")

    statsFrame.text = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsFrame.text:SetPoint("TOPLEFT", 10, -30)
    statsFrame.text:SetJustifyH("LEFT")
    statsFrame.text:SetSize(560, 280)
    statsFrame.text:SetText("Berechne Statistik...")

    -- Tabs erstellen
    CreateTab(1, "Gildeninfo")
    CreateTab(2, "Anfragen")
    CreateTab(3, "Statistik")

    frames[1] = guildInfoFrame
    frames[2] = recruitmentFrame
    frames[3] = statsFrame

    SelectTab(1)

    -- Datenzugriff speichern
    SchlingelInc.OffiWindow = OffiFrame
    SchlingelInc.GuildRecruitment.requestUI = recruitmentFrame
    SchlingelInc.guildInfoFrame = guildInfoFrame
    SchlingelInc.guildStatsFrame = statsFrame
    SchlingelInc:UpdateGuildInfo()
end

function SchlingelInc:UpdateGuildInfo()
    if not self.guildInfoFrame then return end

    local playerName, playerRealm = UnitName("player")
    local level = UnitLevel("player")
    local classDisplayName, classFileName = UnitClass("player")
    local guildName, guildRankName = GetGuildInfo("player")
    local memberCount = GetNumGuildMembers()

    local text = string.format("Name: %s - %s\nLevel: %d\nKlasse: %s\n\nGilde: %s\nMitglieder: %d\nRang: %s",
    playerName, 
    playerRealm or "", 
    level or 0, 
    classDisplayName or "Unbekannt", 
    guildName or "Keine", 
    memberCount or 0, 
    guildRankName or "Unbekannt")
self.guildInfoFrame.infoText:SetText(text)


end

function SchlingelInc:UpdateGuildStats()
    if not self.guildStatsFrame then return end

    local numMembers = GetNumGuildMembers()
    local classCounts = {}

    for i = 1, numMembers do
        local name, _, _, _, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
        if class then
            classCounts[class] = (classCounts[class] or 0) + 1
        end
    end

    -- Sortieren nach Anzahl absteigend
    local sorted = {}
    for class, count in pairs(classCounts) do
        table.insert(sorted, { class = class, count = count })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    local text = "Mitglieder pro Klasse:\n"
    for _, entry in ipairs(sorted) do
        local color = RAID_CLASS_COLORS[entry.class] or { r = 1, g = 1, b = 1 }
        local hex = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
        text = text .. string.format("%s%s|r: %d\n", hex, entry.class, entry.count)
    end

    self.guildStatsFrame.text:SetText(text)
end

function SchlingelInc:ToggleOffiWindow()
    self:CreateOffiWindow()
    if self.OffiWindow:IsShown() then
        self.OffiWindow:Hide()
    else
        self.OffiWindow:Show()
        self:UpdateGuildInfo()
        self:UpdateGuildStats()
        self.GuildRecruitment:UpdateRequestUI()
    end
end
