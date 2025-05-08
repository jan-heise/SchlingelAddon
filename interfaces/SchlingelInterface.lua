-- Stellt sicher, dass die Haupt-Addon-Tabelle und die UIHelpers existieren
SchlingelInc = SchlingelInc or {}
SchlingelInc.UIHelpers = SchlingelInc.UIHelpers or {} -- (Die UIHelpers-Definitionen sollten vorher geladen sein)

local ADDON_NAME = SchlingelInc.name
local INFOFRAME_NAME = ADDON_NAME .. "InfoFrame"

-- Font-Konstanten
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge"
local FONT_NORMAL = "GameFontNormal"

-- Backdrop-Einstellungen 
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
}


-- Global für die Regeltexte im Interface (unverändert)
Rulestext = {
    "Die Nutzung des Briefkastens ist verboten!",
    "Die Nutzung des Auktionshauses ist verboten!",
    "Gruppen mit Spielern außerhalb der Gilden sind verboten!",
    "Handeln mit Spielern außerhalb der Gilden ist verboten!"
}

function SchlingelInc:CreateInfoWindow()
    if self.infoWindow then return end

    local InfoFrame = CreateFrame("Frame", INFOFRAME_NAME, UIParent, "BackdropTemplate")
    InfoFrame:SetSize(500, 350)
    InfoFrame:SetPoint("RIGHT", -50, 25)
    InfoFrame:SetBackdrop(BACKDROP_SETTINGS)
    InfoFrame:SetMovable(true)
    InfoFrame:EnableMouse(true)
    InfoFrame:RegisterForDrag("LeftButton")
    InfoFrame:SetScript("OnDragStart", InfoFrame.StartMoving)
    InfoFrame:SetScript("OnDragStop", InfoFrame.StopMovingOrSizing)
    InfoFrame:Hide()

    -- Überschrift
    self.UIHelpers:CreateStyledText(InfoFrame, "Schlingel Inc", FONT_HIGHLIGHT_LARGE,
                                   "TOP", InfoFrame, "TOP", 0, -20)

    -- Regeltexte
    local ruleTextContent = "Regeln der Gilden:\n\n" -- Start des Textes
    for _, value in ipairs(Rulestext) do
        ruleTextContent = ruleTextContent .. value .. "\n\n"
    end
    -- Hinweis: Die Breite und Höhe für Regeltexte muss ggf. angepasst werden, um alles anzuzeigen oder Scrolling nötig zu machen
    self.UIHelpers:CreateStyledText(InfoFrame, ruleTextContent, FONT_NORMAL,
                                   "TOPLEFT", InfoFrame, "TOPLEFT", 25, -50,
                                   450, 140, "LEFT")

    -- Discord Link
    self.UIHelpers:CreateStyledText(InfoFrame, "Discord: " .. (self.discordLink or "N/A"), FONT_NORMAL,
                                   "TOPLEFT", InfoFrame, "TOPLEFT", 25, -200,
                                   nil, nil, "LEFT")

    -- Version Text
    self.UIHelpers:CreateStyledText(InfoFrame, "Version: " .. (self.version or "N/A"), FONT_NORMAL,
                                   "TOPLEFT", InfoFrame, "TOPLEFT", 25, -225,
                                   nil, nil, "LEFT") 


    -- Schließen-Button
    self.UIHelpers:CreateStyledButton(InfoFrame, nil, 22, 22, -- Standardgröße für CloseButton
                                     "TOPRIGHT", InfoFrame, "TOPRIGHT", -5, -5,
                                     "UIPanelCloseButton", function() InfoFrame:Hide() end)


    -- Button zum Verlassen der Kanäle
    local leaveChannelsBtnFunc = function()
        local channelsToLeave = {
            "Allgemein", "General",
            "Handel", "Trade",
            "LokaleVerteidigung", "LocalDefense",
            "SucheNachGruppe", "LookingForGroup",
            "WeltVerteidigung", "WorldDefense"
        }
        for i = 1, GetNumChannels() do -- GetNumChannels ist besser als feste Nummer
            local _, name = GetChannelName(i)
            if name then
                for _, unwanted in ipairs(channelsToLeave) do
                    -- :lower() auf nil vermeiden
                    if name and unwanted and string.find(string.lower(name), string.lower(unwanted)) then
                        LeaveChannelByName(name)
                        self:Print("Schlingel Inc: Verlasse Kanal '" .. name .. "'")
                        break -- Den inneren Loop verlassen, da der Kanal verlassen wurde
                    end
                end
            end
        end
    end
    self.UIHelpers:CreateStyledButton(InfoFrame, "Verlasse alle globalen Kanäle", 200, 30,
                                     "BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 25, 60,
                                     "UIPanelButtonTemplate", leaveChannelsBtnFunc)

    -- Button zum Beitreten der Schlingel Chats
    local joinChannelsBtnFunc = function()
        JoinChannelByName("SchlingelTrade", nil, ChatFrame1:GetID()) -- Passwort nil, letztes Argument nicht nötig
        JoinChannelByName("SchlingelGroup", nil, ChatFrame1:GetID())
        self:Print("Schlingelchats beigetreten")
    end
    self.UIHelpers:CreateStyledButton(InfoFrame, "Schlingelchats beitreten", 200, 30,
                                     "BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 25, 25,
                                     "UIPanelButtonTemplate", joinChannelsBtnFunc)

    -- Button zum Anfragen der Main Gilde
    local joinMainGuildBtnFunc = function()
        if self.GuildRecruitment and self.GuildRecruitment.SendGuildRequest then
            self.GuildRecruitment:SendGuildRequest("Schlingel Inc")
        else
            self:Print("Fehler: GuildRecruitment Modul nicht gefunden.")
        end
    end
    self.UIHelpers:CreateStyledButton(InfoFrame, "Schlingel Inc beitreten", 200, 30,
                                     "BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 275, 60,
                                     "UIPanelButtonTemplate", joinMainGuildBtnFunc)

    -- Button zum Anfragen der Twink Gilde
    local joinTwinkGuildBtnFunc = function()
        if self.GuildRecruitment and self.GuildRecruitment.SendGuildRequest then
            self.GuildRecruitment:SendGuildRequest("Schlingel IInc")
        else
            self:Print("Fehler: GuildRecruitment Modul nicht gefunden.")
        end
    end
    self.UIHelpers:CreateStyledButton(InfoFrame, "Schlingel IInc beitreten", 200, 30,
                                     "BOTTOMLEFT", InfoFrame, "BOTTOMLEFT", 275, 25,
                                     "UIPanelButtonTemplate", joinTwinkGuildBtnFunc)

    self.infoWindow = InfoFrame
end

-- Öffnet/Schließt das Info-Fenster
function SchlingelInc:ToggleInfoWindow()
    if not self.infoWindow then -- Erstelle Fenster nur, wenn es nicht existiert
        self:CreateInfoWindow()
        if not self.infoWindow then
            print(ADDON_NAME .. ": InfoWindow konnte nicht erstellt werden!")
            return
        end
    end

    if self.infoWindow:IsShown() then
        self.infoWindow:Hide()
    else
        self.infoWindow:Show()
    end
end