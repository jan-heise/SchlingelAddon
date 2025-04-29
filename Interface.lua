function SchlingelInc:CreateInfoWindow()
    if SchlingelInc.infoWindow then return end

    local InfoFrame = CreateFrame("Frame", "SchlingelIncInfoFrame", UIParent, "BackdropTemplate")
    InfoFrame:SetSize(400, 250)
    InfoFrame:SetPoint("CENTER")
    InfoFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    InfoFrame:SetMovable(true)
    InfoFrame:EnableMouse(true)
    InfoFrame:RegisterForDrag("LeftButton")
    InfoFrame:SetScript("OnDragStart", InfoFrame.StartMoving)
    InfoFrame:SetScript("OnDragStop", InfoFrame.StopMovingOrSizing)
    InfoFrame:Hide()

    -- Überschrift
    local title = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Schlingel Inc – Info")

    -- Regeltexte
    local ruleText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ruleText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 110, -75)
    ruleText:SetText(
        "• Regeln der Gilde:\n\n1. Mailbox verboten\n2. Auktionshaus verboten.\n3. Gruppenpflicht mit Gilde\n4. Handeln nur mit Gilde")

    -- Discord Link
    local discordText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    discordText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 110, -175)
    discordText:SetText("• Discord: \n  " .. SchlingelInc.discordLink)

    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", InfoFrame, "TOPRIGHT", -10, -10)

    -- Button zum Verlassen der Kanäle (looped)
    local leaveChannelsBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelButtonTemplate")
    leaveChannelsBtn:SetSize(200, 30)
    leaveChannelsBtn:SetPoint("BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 100, 10)
    leaveChannelsBtn:SetText("Verlasse Alle Kanäle")
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

    -- Schalte die Fenster für beide Sprachen
    local function SetButtonTextLanguage()
        if GetLocale() == "deDE" then
            leaveChannelsBtn:SetText("Verlasse Alle Kanäle")
        else
            leaveChannelsBtn:SetText("Leave All Channels")
        end
    end

    SetButtonTextLanguage()

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
