function SchlingelInc:CreateOffiWindow()
    if SchlingelInc.OffiWindow then return end

    local OffiFrame = CreateFrame("Frame", "SchlingelIncOffiFrame", UIParent, "BackdropTemplate")
    OffiFrame:SetSize(500, 350)
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


    -- Ab hier Textfelder

    -- Überschrift
    local title = OffiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Schlingel Inc")

    SchlingelInc.OffiWindow = OffiFrame
end

-- Öffnet/Schließt das Info-Fenster
function SchlingelInc:ToggleOffiWindow()
    SchlingelInc:CreateOffiWindow()
    if SchlingelInc.OffiWindow:IsShown() then
        SchlingelInc.OffiWindow:Hide()
    else
        SchlingelInc.OffiWindow:Show()
    end
end