local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL = "GameFontNormalSmall"

-- Standard-Hintergrundeinstellungen für Frames
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

function SchlingelInc:CreateMiniInviteLog()
    if self.MiniInviteLogFrame then return end

    local frame = CreateFrame("Frame", "MiniInviteLog", UIParent, "BackdropTemplate")
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

    local title = self.UIHelpers:CreateStyledText(frame, "Gildenanfragen (Klick für Details)", FONT_NORMAL, "TOP", frame, "TOP", 0, -15)
    title:SetTextColor(1, 0.85, 0.1)

    local headers = { "Name", "Level", "Zone" }
    local columnWidths = { 120, 50, 120 }
    local topPadding = -35
    local rowHeight = 18

    for i, text in ipairs(headers) do
        local xOffset = 25
        for j = 1, i - 1 do xOffset = xOffset + columnWidths[j] + 10 end
        local header = self.UIHelpers:CreateStyledText(frame, text, FONT_NORMAL, "TOPLEFT", frame, "TOPLEFT", xOffset, topPadding)
        header:SetTextColor(1, 0.8, 0.1)
    end

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
        SchlingelInc:ShowStandaloneInviteLog()
    end)

    self.MiniInviteLogFrame = frame
    frame:Hide()
end


function SchlingelInc:UpdateMiniInviteLog()
    if not self.MiniInviteLogFrame then self:CreateMiniInviteLog() end
    local frame = self.MiniInviteLogFrame
    local data = SchlingelInc.GuildRecruitment:GetPendingRequests() or {}

    for i, row in ipairs(frame.rows) do
        local entry = data[#data - i + 1]
        if entry then
            row[1]:SetText(entry.name or "?")
            row[2]:SetText(entry.level or "?")
            row[3]:SetText(entry.zone or "?")

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
end


-- Funktion zum Anzeigen/Verstecken des Info-Fensters
function SchlingelInc:ToggleInviteFrame()
    if not self.MiniInviteLogFrame then
        self:CreateMiniInviteLog() -- Erstellt das Fenster, falls es noch nicht existiert
        self:UpdateMiniInviteLog()
        self.MiniInviteLogFrame:Show()
    elseif self.MiniInviteLogFrame:IsShown() then
        self.MiniInviteLogFrame:Hide()
    else
        self:UpdateMiniInviteLog()
        self.MiniInviteLogFrame:Show()
    end
end

function SchlingelInc:ShowStandaloneInviteLog()
    if self.StandaloneInviteLogFrame then
        self.StandaloneInviteLogFrame:Show()
        self.StandaloneInviteLogFrame.Update()
        return
    end

    local frame = CreateFrame("Frame", "StandaloneInviteLogFrame", UIParent, "BackdropTemplate")
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

    local headers = { "Name", "Level", "Zone", "Gold", "Aktion" }
    local columnWidths = { 120, 50, 120, 80, 80 }
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
        for j = 1, #headers - 1 do
            local cell = self.UIHelpers:CreateStyledText(content, "", FONT_SMALL, "TOPLEFT", content, "TOPLEFT", xOffset, yOffset)
            table.insert(row, cell)
            xOffset = xOffset + columnWidths[j] + 10
        end

        -- Buttons
        local acceptBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        acceptBtn:SetSize(20, 20)
        acceptBtn:SetText("+")
        acceptBtn:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset, yOffset)
        acceptBtn:SetScript("OnClick", function(self)
            local name = self.playerName
            SchlingelInc.GuildRecruitment:HandleAcceptRequest(name)
        end)

        local declineBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        declineBtn:SetSize(20, 20)
        declineBtn:SetText("X")
        declineBtn:SetPoint("LEFT", acceptBtn, "RIGHT", 5, 0)
        declineBtn:SetScript("OnClick", function(self)
            local name = self.playerName
            SchlingelInc.GuildRecruitment:HandleDeclineRequest(name)
        end)

        table.insert(row, { acceptBtn, declineBtn })
        table.insert(frame.rows, row)
    end

    frame.Update = function()
        local data = SchlingelInc.GuildRecruitment:GetPendingRequests() or {}
        for i, row in ipairs(frame.rows) do
            local entry = data[#data - i + 1]
            if entry then
                row[1]:SetText(entry.name or "?")
                row[2]:SetText(entry.level or "?")
                row[3]:SetText(entry.zone or "?")
                row[4]:SetText(entry.money or "?")

                row[5][1]:Show()
                row[5][2]:Show()
                row[5][1].playerName = entry.name
                row[5][2].playerName = entry.name
            else
                for j = 1, 4 do row[j]:SetText(""); row[j]:Hide() end
                row[5][1]:Hide()
                row[5][2]:Hide()
            end
        end
        content:SetHeight(math.max(#data * rowHeight, 200))
    end

    frame:Show()
    frame.Update()
    self.StandaloneInviteLogFrame = frame
end
