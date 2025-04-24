-- Erstellt ein einfaches Info-Fenster mit Texten
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

    -- Inhaltstext
    local infoText = InfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", InfoFrame, "TOPLEFT", 110, -75)
    infoText:SetText(
        "• Regeln der Gilde:\n\n1. Mailbox verboten\n2. Auktionshaus verboten.\n3. Gruppenpflicht mit Gilde\n4. Handeln nur mit Gilde"
        .. "\n\n• Discord: \n  " .. SchlingelInc.discordLink
)
    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, InfoFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", InfoFrame, "TOPRIGHT", -10, -10)

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
