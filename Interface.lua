-- global für die Regel texte im Interface
Rulestext = {
    "Die Nutzung des Briefkastens ist verboten!",
    "Die Nutzung des Auktionshauses ist verboten!",
    "Gruppen mit Spielern außerhalb der Gilden sind verboten!",
    "Handeln mit Spielern außerhalb der Gilden ist verboten!"
}

function SchlingelInc:CreateInfoWindow()
    if SchlingelInc.infoWindow then return end

    local InfoFrame = CreateFrame("Frame", "SchlingelIncInfoFrame", UIParent, "BackdropTemplate")
    InfoFrame:SetSize(500, 350)
    InfoFrame:SetPoint("RIGHT", -50, 25)
    InfoFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    InfoFrame:SetMovable(true)
    InfoFrame:EnableMouse(true)
    InfoFrame:RegisterForDrag("LeftButton")
    InfoFrame:SetScript("OnDragStart", InfoFrame.StartMoving)
    InfoFrame:SetScript("OnDragStop", InfoFrame.StopMovingOrSizing)
    InfoFrame:Hide()


    -- Ab hier Textfelder

    -- Überschrift
    local title = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Schlingel Inc")

    -- Regeltexte
    local ruleText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ruleText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 25, -50)
    ruleText:SetText("Regeln der Gilden:\n\n\n")
    for index, value in ipairs(Rulestext) do
        ruleText:SetText(ruleText:GetText() .. value .. "\n\n")
    end
    ruleText:SetJustifyH("LEFT")

    -- Discord Link
    local discordText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    discordText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 25, -200)
    discordText:SetText("Discord: " .. SchlingelInc.discordLink)
    discordText:SetJustifyH("LEFT")

    -- Version Text
    local versionText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 25, -225)
    versionText:SetText("Version: " .. SchlingelInc.version)
    versionText:SetJustifyH("LEFT")


    -- Ab hier Button Code.

    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", InfoFrame, "TOPRIGHT", -10, -10)

    -- Button zum Verlassen der Kanäle (looped)
    local leaveChannelsBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelButtonTemplate")
    leaveChannelsBtn:SetSize(200, 30)
    leaveChannelsBtn:SetPoint("BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 25, 60)

    leaveChannelsBtn:SetText("Verlasse alle globalen Kanäle")
    leaveChannelsBtn:SetScript("OnClick", function()
        local channelsToLeave = {
            "Allgemein", "General",
            "Handel", "Trade",
            "LokaleVerteidigung", "LocalDefense",
            "SucheNachGruppe", "LookingForGroup",
            "WeltVerteidigung", "WorldDefense"
        }

        for i = 1, 10 do
            local id, name = GetChannelName(i)
            if name then
                for _, unwanted in ipairs(channelsToLeave) do
                    if string.find(name:lower(), unwanted:lower()) then
                        LeaveChannelByName(name)
                        SchlingelInc:Print("Schlingel Inc: Verlasse Kanal '" .. name .. "'")
                        break
                    end
                end
            end
        end
    end)

    -- Button zum Beitreten der Schlingel Chats
    local joinChanelsBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelButtonTemplate")
    joinChanelsBtn:SetSize(200, 30)
    joinChanelsBtn:SetPoint("BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 25, 25)
    joinChanelsBtn:SetText("Schlingelchats beitreten")
    joinChanelsBtn:SetScript("OnClick", function()
        local channel_type, channel_name = JoinChannelByName("SchlingelTrade", nil, ChatFrame1:GetID(), nil);
        local channel_type, channel_name = JoinChannelByName("SchlingelGroup", nil, ChatFrame1:GetID(), nil);
        SchlingelInc:Print("Schlingelchats beigetreten")
    end)

    -- Button zum Anfragen der Main Gilde
    local joinMainGuildBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelButtonTemplate")
    joinMainGuildBtn:SetSize(200, 30)
    joinMainGuildBtn:SetPoint("BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 275, 60)
    joinMainGuildBtn:SetText("Schlingel Inc beitreten")
    joinMainGuildBtn:SetScript("OnClick", function()
        SchlingelInc.GuildRecruitment:SendGuildRequest("Schlingel Inc")
    end)

    -- Button zum Anfragen der Twink Gilde
    local joinTwinkGuildBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelButtonTemplate")
    joinTwinkGuildBtn:SetSize(200, 30)
    joinTwinkGuildBtn:SetPoint("BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 275, 25)
    joinTwinkGuildBtn:SetText("Schlingel IInc beitreten")
    joinTwinkGuildBtn:SetScript("OnClick", function()
        SchlingelInc.GuildRecruitment:SendGuildRequest("Schlingel IInc")
    end)

    SchlingelInc.infoWindow = InfoFrame
end

-- Öffnet/Schließt das Info-Fenster
function SchlingelInc:ToggleInfoWindow()
    SchlingelInc:CreateInfoWindow()
    if SchlingelInc.infoWindow:IsShown() then
        SchlingelInc.infoWindow:Hide()
    else
        SchlingelInc.infoWindow:Show()
    end
end
