-- Stellt sicher, dass die Haupt-Addon-Tabelle und die UIHelpers existieren
SchlingelInc = SchlingelInc or {}
SchlingelInc.UIHelpers = SchlingelInc.UIHelpers or {}

local ADDON_NAME = SchlingelInc.name or "SchlingelInc"
local SCHLINGEL_INTERFACE_FRAME_NAME = ADDON_NAME .. "SchlingelInterfaceFrame"
local TAB_BUTTON_NAME_PREFIX = ADDON_NAME .. "SchlingelInterfaceTab"

local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"
local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL = "GameFontNormalSmall"

local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

local Rulestext = {
    "Die Nutzung des Briefkastens ist verboten!",
    "Die Nutzung des Auktionshauses ist verboten!",
    "Gruppen mit Spielern außerhalb der Gilden sind verboten!",
    "Handeln mit Spielern außerhalb der Gilden ist verboten!"
}

-- Helper function to format seconds into d/h/m string (Wiederhergestellt)
local function FormatSeconds(totalSeconds)
    if totalSeconds and totalSeconds > 0 then
        local d = math.floor(totalSeconds/86400)
        local h = math.floor((totalSeconds%86400)/3600)
        local m = math.floor((totalSeconds%3600)/60)
        return string.format("%dd %dh %dm", d, h, m)
    elseif totalSeconds == 0 then
         return "0d 0h 0m" -- Zeigt 0 explizit an
    else
        return "Lade..." -- Zeigt "Lade..." an, wenn Daten nil sind (noch nicht empfangen)
    end
end


--------------------------------------------------------------------------------
-- Tab Content Creation Functions
--------------------------------------------------------------------------------

-- Tab 1: Charakter
function SchlingelInc:_CreateCharacterTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "CharacterTabSI", parentFrame)
    tabFrame:SetAllPoints(true)

    local contentFrame = CreateFrame("Frame", nil, tabFrame)
    contentFrame:SetPoint("TOPLEFT", 20, -20)
    contentFrame:SetPoint("BOTTOMRIGHT", -20, 20)

    local xCol1 = 0
    local xCol2 = contentFrame:GetWidth() * 0.55
    local lineHeight = 22
    local currentY_Col1 = 0
    local currentY_Col2 = 0

    -- Column 1
    tabFrame.playerNameText = self.UIHelpers:CreateStyledText(contentFrame, "Name: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.levelText = self.UIHelpers:CreateStyledText(contentFrame, "Level: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.classText = self.UIHelpers:CreateStyledText(contentFrame, "Klasse: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.raceText = self.UIHelpers:CreateStyledText(contentFrame, "Rasse: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.zoneText = self.UIHelpers:CreateStyledText(contentFrame, "Zone: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)
    currentY_Col1 = currentY_Col1 - lineHeight
    tabFrame.deathCountText = self.UIHelpers:CreateStyledText(contentFrame, "Tode: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, currentY_Col1)

    -- Column 2
    tabFrame.moneyText = self.UIHelpers:CreateStyledText(contentFrame, "Geld: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    tabFrame.xpText = self.UIHelpers:CreateStyledText(contentFrame, "XP: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    -- Spielzeit-Felder initial mit "Lade..." erstellen
    tabFrame.timePlayedTotalText = self.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Gesamt): Lade...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)
    currentY_Col2 = currentY_Col2 - lineHeight
    tabFrame.timePlayedLevelText = self.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Level): Lade...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)

    -- Guild Info Section
    local guildYStart = math.min(currentY_Col1, currentY_Col2) - (lineHeight * 2)
    tabFrame.guildNameText = self.UIHelpers:CreateStyledText(contentFrame, "Gilde: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, guildYStart)
    guildYStart = guildYStart - lineHeight
    tabFrame.guildRankText = self.UIHelpers:CreateStyledText(contentFrame, "Gildenrang: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, guildYStart)
    guildYStart = guildYStart - lineHeight
    tabFrame.guildMembersText = self.UIHelpers:CreateStyledText(contentFrame, "Mitglieder: ...", FONT_NORMAL, "TOPLEFT", contentFrame, "TOPLEFT", xCol1, guildYStart)

    tabFrame.Update = function(selfTab)
        xCol2 = contentFrame:GetWidth() * 0.55
        selfTab.moneyText:ClearAllPoints(); selfTab.moneyText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, 0)
        local currentY_Col2_Update = 0 - lineHeight
        selfTab.xpText:ClearAllPoints(); selfTab.xpText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)
        currentY_Col2_Update = currentY_Col2_Update - lineHeight
        selfTab.timePlayedTotalText:ClearAllPoints(); selfTab.timePlayedTotalText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)
        currentY_Col2_Update = currentY_Col2_Update - lineHeight
        selfTab.timePlayedLevelText:ClearAllPoints(); selfTab.timePlayedLevelText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

        local pName = UnitName("player") or "Unbekannt"; local pLevel = UnitLevel("player") or 0
        local pClassLoc, pClassToken = UnitClass("player"); pClassLoc = pClassLoc or "Unbekannt"
        local pRaceLoc, _ = UnitRace("player"); pRaceLoc = pRaceLoc or "Unbekannt"
        local currentZone = GetZoneText() or "Unbekannt"; local pMoney = GetMoneyString(GetMoney(), true) or "0c"
        selfTab.playerNameText:SetText("Name: " .. pName); selfTab.levelText:SetText("Level: " .. pLevel)
        local classColor = pClassToken and RAID_CLASS_COLORS[pClassToken]
        if classColor then selfTab.classText:SetText(string.format("Klasse: |cff%02x%02x%02x%s|r", classColor.r*255, classColor.g*255, classColor.b*255, pClassLoc))
        else selfTab.classText:SetText("Klasse: " .. pClassLoc) end
        selfTab.raceText:SetText("Rasse: " .. pRaceLoc); selfTab.zoneText:SetText("Zone: " .. currentZone)
        selfTab.moneyText:SetText("Geld: " .. pMoney)
        local deaths = CharacterDeaths or 0; selfTab.deathCountText:SetText("Tode: " .. deaths)
        local currentXP, maxXP, restXP = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
        if pLevel == MAX_PLAYER_LEVEL then selfTab.xpText:SetText("XP: Max Level")
        else local xpString = string.format("XP: %s / %s", currentXP, maxXP); if restXP and restXP > 0 then xpString = xpString .. string.format(" (|cff80c0ff+%.0f Erholt|r)", restXP) end; selfTab.xpText:SetText(xpString) end

        -- ** Liest die globalen Spielzeit-Variablen (in Sekunden) und formatiert sie **
        local timePlayedTotalSeconds = SchlingelInc.GameTimeTotal
        local timePlayedLevelSeconds = SchlingelInc.GameTimePerLevel

        -- Verwendet die FormatSeconds Hilfsfunktion
        selfTab.timePlayedTotalText:SetText("Spielzeit (Gesamt): " .. FormatSeconds(timePlayedTotalSeconds))
        selfTab.timePlayedLevelText:SetText("Spielzeit (Level): " .. FormatSeconds(timePlayedLevelSeconds))
        -- ** Ende Spielzeit-Logik **

        local gName, gRank = GetGuildInfo("player")
        if gName then local numTotal, numOnline = GetNumGuildMembers(); selfTab.guildNameText:SetText("Gilde: " .. gName); selfTab.guildRankText:SetText("Gildenrang: " .. (gRank or "Unbekannt")); selfTab.guildMembersText:SetText(string.format("Mitglieder: %d (%d Online)", numTotal or 0, numOnline or 0)); selfTab.guildNameText:Show(); selfTab.guildRankText:Show(); selfTab.guildMembersText:Show()
        else selfTab.guildNameText:SetText("Gilde: Nicht in einer Gilde"); selfTab.guildRankText:Hide(); selfTab.guildMembersText:Hide() end
    end
    return tabFrame
end

-- Tab 2: Info / Übersicht
function SchlingelInc:_CreateInfoTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "InfoTabSI", parentFrame)
    tabFrame:SetAllPoints(true)

    local currentY = -20
    local leftPadding = 20
    local contentWidth = parentFrame:GetWidth() - (leftPadding * 2)
    local textBlockSpacing = -20 -- Etwas mehr Abstand

    tabFrame.motdLabel = self.UIHelpers:CreateStyledText(tabFrame, "Gilden-MOTD:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", leftPadding, currentY)
    currentY = currentY - tabFrame.motdLabel:GetHeight() - 7 -- Mehr Abstand
    tabFrame.motdTextDisplay = self.UIHelpers:CreateStyledText(tabFrame, "Lade MOTD...", FONT_SMALL, "TOPLEFT", tabFrame, "TOPLEFT", leftPadding, currentY, contentWidth, 100, "LEFT", "TOP")
    currentY = currentY - 100 + textBlockSpacing

    tabFrame.rulesLabel = self.UIHelpers:CreateStyledText(tabFrame, "Regeln der Gilden:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", leftPadding, currentY)
    currentY = currentY - tabFrame.rulesLabel:GetHeight() - 7 -- Mehr Abstand
    local ruleTextContent = ""
    for i, value in ipairs(Rulestext) do
        ruleTextContent = ruleTextContent .. "• " .. value
        if i < #Rulestext then ruleTextContent = ruleTextContent .. "\n\n" else ruleTextContent = ruleTextContent .. "\n" end
    end
    tabFrame.rulesTextDisplay = self.UIHelpers:CreateStyledText(tabFrame, ruleTextContent, FONT_SMALL, "TOPLEFT", tabFrame, "TOPLEFT", leftPadding, currentY, contentWidth, 150, "LEFT", "TOP")

    tabFrame.Update = function(selfTab)
        local guildMOTD = GetGuildRosterMOTD()
        if guildMOTD and guildMOTD ~= "" then
            selfTab.motdTextDisplay:SetText(guildMOTD)
        else
            selfTab.motdTextDisplay:SetText("Keine Gilden-MOTD festgelegt.")
        end
        -- Dynamische Höhenanpassung (optional)
        --[[
        if selfTab.motdTextDisplay.GetStringHeight then
             local neededHeight = selfTab.motdTextDisplay:GetStringHeight()
             local currentHeight = selfTab.motdTextDisplay:GetHeight()
             if neededHeight > currentHeight then selfTab.motdTextDisplay:SetHeight(neededHeight) end
        end
        if selfTab.rulesTextDisplay.GetStringHeight then
            local neededHeight = selfTab.rulesTextDisplay:GetStringHeight()
            local currentHeight = selfTab.rulesTextDisplay:GetHeight()
            if neededHeight > currentHeight then selfTab.rulesTextDisplay:SetHeight(neededHeight) end
        end
        --]]
    end
    return tabFrame
end

-- Tab 3: Community / Kanäle & Gilde
function SchlingelInc:_CreateCommunityTabContent_SchlingelInterface(parentFrame)
    local tabFrame = CreateFrame("Frame", ADDON_NAME .. "CommunityTabSI", parentFrame)
    tabFrame:SetAllPoints(true)
    local buttonWidth, buttonHeight, buttonSpacingY = 220, 30, 10
    local col1X = (parentFrame:GetWidth() - (buttonWidth * 2 + 40)) / 2
    local col2X = col1X + buttonWidth + 40
    local currentY_Labels = -20
    local currentY_Buttons = currentY_Labels - 30

    -- Column 1: Guild Join
    self.UIHelpers:CreateStyledText(tabFrame, "Gildenbeitritt:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", col1X, currentY_Labels);
    local currentY_Col1_Buttons = currentY_Buttons
    local joinMainGuildBtnFunc = function() if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.SendGuildRequest then SchlingelInc.GuildRecruitment:SendGuildRequest("Schlingel Inc") else SchlingelInc:Print(ADDON_NAME .. ": Fehler - GuildRecruitment Modul nicht gefunden.") end end
    self.UIHelpers:CreateStyledButton(tabFrame, "Schlingel Inc beitreten", buttonWidth, buttonHeight, "TOPLEFT", tabFrame, "TOPLEFT", col1X, currentY_Col1_Buttons, "UIPanelButtonTemplate", joinMainGuildBtnFunc);
    currentY_Col1_Buttons = currentY_Col1_Buttons - buttonHeight - buttonSpacingY
    local joinTwinkGuildBtnFunc = function() if SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.SendGuildRequest then SchlingelInc.GuildRecruitment:SendGuildRequest("Schlingel IInc") else SchlingelInc:Print(ADDON_NAME .. ": Fehler - GuildRecruitment Modul nicht gefunden.") end end
    self.UIHelpers:CreateStyledButton(tabFrame, "Schlingel IInc beitreten", buttonWidth, buttonHeight, "TOPLEFT", tabFrame, "TOPLEFT", col1X, currentY_Col1_Buttons, "UIPanelButtonTemplate", joinTwinkGuildBtnFunc);

    -- Column 2: Chat Channels
    self.UIHelpers:CreateStyledText(tabFrame, "Chatkanäle:", FONT_NORMAL, "TOPLEFT", tabFrame, "TOPLEFT", col2X, currentY_Labels);
    local currentY_Col2_Buttons = currentY_Buttons
    local leaveChannelsBtnFunc = function()
        local channelsToLeave = { "Allgemein", "General", "Handel", "Trade", "LokaleVerteidigung", "LocalDefense", "SucheNachGruppe", "LookingForGroup", "WeltVerteidigung", "WorldDefense" }
        local channelsLeft = {}; for i = 1, GetNumChannels() do local _, name = GetChannelName(i); if name then for _, unwanted in ipairs(channelsToLeave) do if string.find(string.lower(name), string.lower(unwanted)) then table.insert(channelsLeft, name); break end end end end
        for _, channelName in ipairs(channelsLeft) do LeaveChannelByName(channelName); SchlingelInc:Print(ADDON_NAME .. ": Verlasse Kanal '" .. channelName .. "'") end
    end
    self.UIHelpers:CreateStyledButton(tabFrame, "Globale Kanäle verlassen", buttonWidth, buttonHeight, "TOPLEFT", tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", leaveChannelsBtnFunc);
    currentY_Col2_Buttons = currentY_Col2_Buttons - buttonHeight - buttonSpacingY
    local joinChannelsBtnFunc = function() local cID = ChatFrame1 and ChatFrame1:GetID(); if not cID then SchlingelInc:Print(ADDON_NAME..": Konnte ChatFrame1 ID nicht ermitteln."); return end; JoinChannelByName("SchlingelTrade", nil, cID); JoinChannelByName("SchlingelGroup", nil, cID); SchlingelInc:Print(ADDON_NAME .. ": Versuche Schlingel-Chats beizutreten.") end
    self.UIHelpers:CreateStyledButton(tabFrame, "Schlingel-Chats beitreten", buttonWidth, buttonHeight, "TOPLEFT", tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", joinChannelsBtnFunc);


    local infoY = math.min(currentY_Col1_Buttons, currentY_Col2_Buttons) - buttonHeight - (buttonSpacingY * 2)
    local infoWidth = (buttonWidth * 2) + 30 -- Span both columns

    tabFrame.discordText = self.UIHelpers:CreateStyledText(tabFrame, "Discord: ...", FONT_NORMAL,
                                   "TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY,
                                   infoWidth, nil, "CENTER")
    infoY = infoY - 25 -- Mehr Space zwischen Discord und Version

    tabFrame.versionText = self.UIHelpers:CreateStyledText(tabFrame, "Version: ...", FONT_NORMAL,
                                   "TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY,
                                   infoWidth, nil, "CENTER")


    tabFrame.Update = function(selfTab)
        selfTab.discordText:SetText("Discord: " .. (SchlingelInc.discordLink or "N/A"))
        selfTab.versionText:SetText("Version: " .. (SchlingelInc.version or "N/A"))
    end
    return tabFrame
end

--------------------------------------------------------------------------------
-- Hauptfunktion zur Erstellung des SchlingelInterface-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:CreateInfoWindow()
    if self.infoWindow then self.infoWindow:Show(); return end
    local mainFrame = CreateFrame("Frame", SCHLINGEL_INTERFACE_FRAME_NAME, UIParent, "BackdropTemplate")
    mainFrame:SetSize(600, 420)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetBackdrop(BACKDROP_SETTINGS)
    mainFrame:SetMovable(true); mainFrame:EnableMouse(true); mainFrame:RegisterForDrag("LeftButton"); mainFrame:SetScript("OnDragStart", mainFrame.StartMoving); mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("MEDIUM"); mainFrame:Hide()
    self.UIHelpers:CreateStyledText(mainFrame, "Schlingel Inc Interface", FONT_HIGHLIGHT_LARGE, "TOP", mainFrame, "TOP", 0, -15)
    self.UIHelpers:CreateStyledButton(mainFrame, nil, 22, 22, "TOPRIGHT", mainFrame, "TOPRIGHT", -7, -7, "UIPanelCloseButton", function() mainFrame:Hide() end)
    local tabContentContainer = CreateFrame("Frame", ADDON_NAME .. "SITabContentContainer", mainFrame)
    tabContentContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -50)
    tabContentContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 45)
    local tabButtons = {}; mainFrame.tabContentFrames = {}
    mainFrame.selectedTab = 1

    local function SelectTab(tabIndex)
        mainFrame.selectedTab = tabIndex
        for index, button in ipairs(tabButtons) do
            local contentFrame = mainFrame.tabContentFrames[index]
            if contentFrame then
                if index == tabIndex then
                    PanelTemplates_SelectTab(button)
                    contentFrame:Show()
                    if contentFrame.Update then contentFrame:Update(contentFrame) end
                else
                    PanelTemplates_DeselectTab(button)
                    contentFrame:Hide()
                end
            end
        end
    end

    local tabDefinitions = {
        { name = "Charakter", CreateFunc = self._CreateCharacterTabContent_SchlingelInterface },
        { name = "Info",      CreateFunc = self._CreateInfoTabContent_SchlingelInterface },
        { name = "Community", CreateFunc = self._CreateCommunityTabContent_SchlingelInterface }
    }
    local tabButtonWidth, tabButtonSpacing, initialXOffsetForTabs = 130, 5, 20
    for i, tabDef in ipairs(tabDefinitions) do
        local button = CreateFrame("Button", TAB_BUTTON_NAME_PREFIX .. i, mainFrame, "OptionsFrameTabButtonTemplate")
        button:SetID(i); button:SetText(tabDef.name); button:SetWidth(tabButtonWidth); button:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", initialXOffsetForTabs + (i-1)*(tabButtonWidth + tabButtonSpacing), 12)
        button:GetFontString():SetPoint("CENTER", 0, 1); button:SetScript("OnClick", function() SelectTab(i) end); PanelTemplates_DeselectTab(button); tabButtons[i] = button
        if tabDef.CreateFunc then local newTab = tabDef.CreateFunc(self, tabContentContainer); if newTab then newTab:Hide(); mainFrame.tabContentFrames[i] = newTab end end
    end
    self.infoWindow = mainFrame
    if #tabButtons > 0 then SelectTab(1) end
    mainFrame:Show()
end

function SchlingelInc:ToggleInfoWindow()
    if not self.infoWindow then self:CreateInfoWindow()
    elseif self.infoWindow:IsShown() then
        self.infoWindow:Hide()
    else
        self.infoWindow:Show()
        local activeTabIndex = self.infoWindow.selectedTab or 1
        local activeTabFrame = self.infoWindow.tabContentFrames and self.infoWindow.tabContentFrames[activeTabIndex]
        if activeTabFrame and activeTabFrame:IsShown() and activeTabFrame.Update then
            activeTabFrame:Update(activeTabFrame)
        end
    end
end

local function RegisterSchlingelInterfaceEvents()
    local eventFrameSI = CreateFrame("Frame", "SchlingelInterfaceEventFrame")
    eventFrameSI:RegisterEvent("PLAYER_LEVEL_UP"); eventFrameSI:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrameSI:RegisterEvent("PLAYER_MONEY"); eventFrameSI:RegisterEvent("GUILD_ROSTER_UPDATE")
    eventFrameSI:RegisterEvent("PLAYER_XP_UPDATE"); eventFrameSI:RegisterEvent("VARIABLES_LOADED")

    eventFrameSI:SetScript("OnEvent", function(selfFrame, event, ...)
        if SchlingelInc and SchlingelInc.infoWindow and SchlingelInc.infoWindow:IsShown() then
             local activeTabIndex = SchlingelInc.infoWindow.selectedTab or 1
             local tabToUpdate = SchlingelInc.infoWindow.tabContentFrames and SchlingelInc.infoWindow.tabContentFrames[activeTabIndex]

            if tabToUpdate and tabToUpdate:IsShown() and tabToUpdate.Update then
                 tabToUpdate:Update(tabToUpdate)
            end
        end
    end)
end
RegisterSchlingelInterfaceEvents()