local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL = "GameFontNormalSmall"
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"

-- Standard-Hintergrundeinstellungen für Frames
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

function SchlingelInc:CreateMiniDeathLog()
    if self.MiniDeathLogFrame then return end

    local frame = CreateFrame("Frame", "MiniDeathLog", UIParent, "BackdropTemplate")
    frame:SetSize(360, 200)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 40, 60)
    frame:SetBackdrop(BACKDROP_SETTINGS)
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("MEDIUM")

    local title = self.UIHelpers:CreateStyledText(frame, "Letzte Tode (Klick für Details)", FONT_NORMAL, "TOP", frame, "TOP", 0, -15)
    title:SetTextColor(1, 0.85, 0.1)

    local headers = { "Name", "Klasse", "Level" }
    local columnWidths = { 120, 100, 60 }
    local topPadding = -35
    local rowHeight = 18

    -- Tabellen-Header
    for i, text in ipairs(headers) do
        local xOffset = 25
        for j = 1, i - 1 do xOffset = xOffset + columnWidths[j] + 10 end
        local header = self.UIHelpers:CreateStyledText(frame, text, FONT_NORMAL, "TOPLEFT", frame, "TOPLEFT", xOffset, topPadding)
        header:SetTextColor(1, 0.8, 0.1)
    end

    -- Zeilen vorbereiten
    frame.rows = {}
    for i = 1, 6 do
        local row = {}
        local yOffset = topPadding - 20 - ((i - 1) * rowHeight)
        local xOffset = 25
        for j = 1, #headers do
            local cell = self.UIHelpers:CreateStyledText(frame, "", FONT_SMALL, "TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
            table.insert(row, cell)
            xOffset = xOffset + columnWidths[j] + 10
        end
        table.insert(frame.rows, row)
    end

    frame:SetScript("OnMouseUp", function()
        SchlingelInc:ShowStandaloneDeathLog()
    end)

    self.MiniDeathLogFrame = frame
    frame:Hide()
end

function SchlingelInc:UpdateMiniDeathLog()
    if not self.MiniDeathLogFrame then self:CreateMiniDeathLog() end
    local frame = self.MiniDeathLogFrame
    local data = self.DeathLogData or {}

    local localizedToToken = {}
    for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do localizedToToken[name] = token end
    for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do localizedToToken[name] = token end

    for i, row in ipairs(frame.rows) do
        local entry = data[#data - i + 1]
        if entry then
            local classToken = localizedToToken[entry.class]
            local color = classToken and RAID_CLASS_COLORS[classToken]
            row[1]:SetText(entry.name or "?")
            row[2]:SetText(color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, entry.class) or entry.class)
            row[3]:SetText(entry.level or "?")

            for _, cell in ipairs(row) do
                cell:Show()
                if i % 2 == 0 then
                    cell:SetTextColor(0.9, 0.9, 0.9)
                else
                    cell:SetTextColor(0.8, 0.8, 0.8)
                end
            end
        else
            for _, cell in ipairs(row) do cell:SetText(""); cell:Hide() end
        end
    end
    frame:Show()
end

-- Funktion zum Anzeigen/Verstecken des Info-Fensters
function SchlingelInc:ToggleDeathLogWindow()
    if not self.MiniDeathLogFrame then
        self:CreateMiniDeathLog() -- Erstellt das Fenster, falls es noch nicht existiert
        self:UpdateMiniDeathLog()
    elseif self.MiniDeathLogFrame:IsShown() then
        self.MiniDeathLogFrame:Hide()
    else
        self:UpdateMiniDeathLog()
    end
end

function SchlingelInc:ShowStandaloneDeathLog()
    if self.StandaloneDeathLogFrame then
        self.StandaloneDeathLogFrame:Show()
        self.StandaloneDeathLogFrame.Update()
        return
    end

    local frame = CreateFrame("Frame", "StandaloneDeathLog", UIParent, "BackdropTemplate")
    frame:SetSize(600, 420)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(BACKDROP_SETTINGS)
    frame:SetBackdropColor(0, 0, 0, 0.85)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() frame:Hide() end)

    local headers = { "Name", "Klasse", "Level", "Zone", "Todesursache" }
    local columnWidths = { 120, 80, 40, 110, 180 }
    local topPadding = -25
    local rowHeight = 20

    for i, text in ipairs(headers) do
        local xOffset = 25
        for j = 1, i - 1 do xOffset = xOffset + columnWidths[j] + 10 end
        local header = self.UIHelpers:CreateStyledText(frame, text, FONT_NORMAL, "TOPLEFT", frame, "TOPLEFT", xOffset, topPadding)
        header:SetTextColor(1, 0.8, 0.1)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    frame.rows = {}

    for i = 1, 100 do
        local row = {}
        local yOffset = -((i - 1) * rowHeight) -15
        local xOffset = 20
        for j = 1, #headers do
            local cell = self.UIHelpers:CreateStyledText(content, "", FONT_SMALL, "TOPLEFT", content, "TOPLEFT", xOffset, yOffset)
            table.insert(row, cell)
            xOffset = xOffset + columnWidths[j] + 10
        end
        table.insert(frame.rows, row)
    end

    frame.Update = function()
        local data = SchlingelInc.DeathLogData or {}
        local localizedToToken = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do localizedToToken[name] = token end
        for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do localizedToToken[name] = token end

        for i, row in ipairs(frame.rows) do
            local entry = data[#data - i + 1]
            if entry then
                local classToken = localizedToToken[entry.class]
                local color = classToken and RAID_CLASS_COLORS[classToken]
                row[1]:SetText(entry.name or "?")
                row[2]:SetText(color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, entry.class) or entry.class)
                row[3]:SetText(entry.level or "?")
                row[4]:SetText(entry.zone or "?")
                row[5]:SetText(entry.cause or "?")

                for _, cell in ipairs(row) do
                    cell:Show()
                    if i % 2 == 0 then
                        cell:SetTextColor(0.95, 0.95, 0.95)
                    else
                        cell:SetTextColor(0.85, 0.85, 0.85)
                    end
                end
            else
                for _, cell in ipairs(row) do cell:SetText(""); cell:Hide() end
            end
        end
        content:SetHeight(math.max(#data * rowHeight, 200))
    end

    frame:Show()
    frame.Update()
    self.StandaloneDeathLogFrame = frame
end
