local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

-- Datenobjekt für das Minimap Icon
local minimapLDB = LDB:NewDataObject("SchlingelInc", {
    type = "data source",
    text = "Schlingel Inc",
    icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga",

    OnClick = function(_, button)
        if button == "LeftButton" then
            SchlingelInc:ToggleInfoWindow()
        end
    end,

    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Schlingel Inc", 1, 0.7, 0.9)
        GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1)
        GameTooltip:Show()
    end,

    OnLeave = function()
        GameTooltip:Hide()
    end
})

-- Initialisierung des Minimap Icons
function SchlingelInc:InitMinimapIcon()
    if not DBIcon or not minimapLDB then
        self:Print("MiniMap Icon konnte nicht erstellt werden.")
        return
    end

    -- Stelle sicher, dass das Icon nur einmal registriert wird
    if not self.minimapRegistered then
        self.db = self.db or {}
        self.db.minimap = self.db.minimap or { hide = false }

        DBIcon:Register("SchlingelInc", minimapLDB, self.db.minimap)
        self.minimapRegistered = true
    end
end

-- Erstellt ein einfaches Info-Fenster mit Texten
function SchlingelInc:CreateInfoWindow()
    if self.infoWindow then return end

    local f = CreateFrame("Frame", "SchlingelIncInfoFrame", UIParent, "BackdropTemplate")
    f:SetSize(400, 250)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Überschrift
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Schlingel Inc – Info")

    -- Inhaltstext
    local content = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    content:SetPoint("TOPLEFT", 20, -60)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    content:SetText("• Regeln der Gilde:\n  - Kein PvP mit Allianz\n  - Gruppenpflicht mit Gilde\n\n• Discord:\n  " .. SchlingelInc.discordLink)

    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

    self.infoWindow = f
end

-- Öffnet/Schließt das Info-Fenster
function SchlingelInc:ToggleInfoWindow()
    self:CreateInfoWindow()
    if self.infoWindow:IsShown() then
        self.infoWindow:Hide()
    else
        self.infoWindow:Show()
    end
end
