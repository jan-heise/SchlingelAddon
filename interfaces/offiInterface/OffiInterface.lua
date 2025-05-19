-- Stellt sicher, dass die Haupt-Addon-Tabelle existiert.
-- Wenn SchlingelInc noch nicht existiert, wird eine neue, leere Tabelle erstellt.
SchlingelInc = SchlingelInc or {}
-- Erstelle Namespace für Tab-Module
-- Andere Tab-Dateien (z.B. Tabs/GuildInfo.lua) hängen sich hier an.
SchlingelInc.Tabs = SchlingelInc.Tabs or {}

--------------------------------------------------------------------------------
-- Konstanten für das Addon-Interface
-- Diese Konstanten dienen dazu, feste Werte im Code leichter anpassbar
-- und lesbarer zu machen. Sie sind hier definiert, da sie übergreifend
-- für verschiedene UI-Elemente und Tabs verwendet werden.
--------------------------------------------------------------------------------
local ADDON_PREFIX = SchlingelInc.name or "SchlingelInc" -- Basis-Präfix für UI-Elemente, um Namenskollisionen zu vermeiden.
local OFFIFRAME_NAME = ADDON_PREFIX .. "OffiFrame" -- Name des Hauptfensters des Addons.
local TAB_BUTTON_NAME_PREFIX = ADDON_PREFIX .. "OffiTab" -- Präfix für die Namen der Tab-Buttons.

-- Schriftarten-Konstanten
-- Definiert verschiedene Schriftarten, die im Addon verwendet werden.
local FONT_HIGHLIGHT_LARGE = "GameFontHighlightLarge" -- Große hervorgehobene Schrift.
local FONT_NORMAL = "GameFontNormal" -- Standard-Schrift.
local FONT_HIGHLIGHT_SMALL = "GameFontHighlightSmall" -- Kleine hervorgehobene Schrift.

-- Standard-Backdrop-Einstellungen für Frames
-- Ein Backdrop ist der Hintergrund und Rahmen eines UI-Fensters.
local BACKDROP_SETTINGS = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Textur für den Hintergrund.
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Textur für den Rand.
    tile = true, -- Ob die Texturen gekachelt werden sollen.
    tileSize = 32, -- Größe der Kacheln.
    edgeSize = 32, -- Dicke des Randes.
    insets = { left = 11, right = 12, top = 12, bottom = 11 } -- Innenabstände.
}

-- Konstanten für die Inaktivitätsprüfung (kann auch in Inactivity.lua verschoben werden)
local INACTIVE_DAYS_THRESHOLD = 10 -- Anzahl der Tage, ab denen ein Mitglied als inaktiv gilt.

-- Füge die globalen Konstanten zum SchlingelInc-Tabelle hinzu, damit Module darauf zugreifen können
SchlingelInc.ADDON_PREFIX = ADDON_PREFIX
SchlingelInc.OFFIFRAME_NAME = OFFIFRAME_NAME -- Kann auch nützlich sein
SchlingelInc.TAB_BUTTON_NAME_PREFIX = TAB_BUTTON_NAME_PREFIX -- Kann auch nützlich sein
SchlingelInc.FONT_HIGHLIGHT_LARGE = FONT_HIGHLIGHT_LARGE
SchlingelInc.FONT_NORMAL = FONT_NORMAL
SchlingelInc.FONT_HIGHLIGHT_SMALL = FONT_HIGHLIGHT_SMALL
SchlingelInc.BACKDROP_SETTINGS = BACKDROP_SETTINGS
SchlingelInc.INACTIVE_DAYS_THRESHOLD = INACTIVE_DAYS_THRESHOLD -- Auch diese zugänglich machen

--------------------------------------------------------------------------------
-- Hauptfunktion zur Erstellung des Offi-Fensters
-- Diese Funktion baut das gesamte Offi-Fenster mit seinen Tabs und
-- grundlegenden Funktionen zusammen. Sie ruft die CreateUI-Funktionen
-- der einzelnen Tab-Module auf.
--------------------------------------------------------------------------------
function SchlingelInc:CreateOffiWindow()
    -- Verhindert, dass das Fenster mehrfach erstellt wird.
    if self.OffiWindow then
        return
    end

    -- Erstellt den Hauptframe des Offi-Fensters. Nutze Konstante aus SchlingelInc
    local offiWindowFrame = CreateFrame("Frame", SchlingelInc.OFFIFRAME_NAME, UIParent, "BackdropTemplate")
    offiWindowFrame:SetSize(600, 500)
    offiWindowFrame:SetPoint("RIGHT", -50, 25)
    -- Nutze die Konstante aus SchlingelInc
    offiWindowFrame:SetBackdrop(SchlingelInc.BACKDROP_SETTINGS)
    offiWindowFrame:SetMovable(true) -- Fenster kann verschoben werden.
    offiWindowFrame:EnableMouse(true) -- Mausinteraktionen aktivieren.
    offiWindowFrame:RegisterForDrag("LeftButton") -- Registriert das Ziehen mit der linken Maustaste.
    offiWindowFrame:SetScript("OnDragStart", offiWindowFrame.StartMoving) -- Funktion beim Start des Ziehens.
    offiWindowFrame:SetScript("OnDragStop", offiWindowFrame.StopMovingOrSizing) -- Funktion beim Ende des Ziehens.
    offiWindowFrame:Hide() -- Standardmäßig ausgeblendet.

    -- Schließen-Button oben rechts. Zugriffe auf UIHelpers über SchlingelInc
    SchlingelInc.UIHelpers:CreateStyledButton(offiWindowFrame, nil, 22, 22,
        "TOPRIGHT", offiWindowFrame, "TOPRIGHT", -5, -5, "UIPanelCloseButton",
        function() offiWindowFrame:Hide() end)

    -- Fenstertitel. Zugriffe auf UIHelpers über SchlingelInc und Konstante
    SchlingelInc.UIHelpers:CreateStyledText(offiWindowFrame, "Schlingel Inc - Offi Interface", SchlingelInc.FONT_HIGHLIGHT_LARGE,
        "TOP", offiWindowFrame, "TOP", 0, -20)

    -- Container für den Inhalt der Tabs.
    -- Nutze Konstante aus SchlingelInc
    local tabContentContainer = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "OffiTabContentContainer", offiWindowFrame)
    tabContentContainer:SetPoint("TOPLEFT", offiWindowFrame, "TOPLEFT", 10, -50)
    tabContentContainer:SetPoint("BOTTOMRIGHT", offiWindowFrame, "BOTTOMRIGHT", -10, 10)

    local tabButtons = {} -- Tabelle für die Tab-Buttons.
    local tabContentFrames = {} -- Tabelle für die Inhaltsframes der Tabs.

    -- Funktion zum Auswählen eines Tabs.
    -- Zeigt den Inhalt des gewählten Tabs an und blendet die anderen aus.
    -- Ruft die UpdateData Methode des jeweiligen Moduls auf.
    local function SelectTab(tabIndex)
        -- Lokale Referenz auf die Tabs für schnellere Zugriffe
        local Tabs = SchlingelInc.Tabs

        for index, button in ipairs(tabButtons) do
            -- Sicherstellen, dass sowohl Button als auch Inhaltsframe existieren
            if button and tabContentFrames[index] then
                if index == tabIndex then
                    PanelTemplates_SelectTab(button) -- Visuelle Hervorhebung des aktiven Tabs.
                    tabContentFrames[index]:Show()
                    -- Trigger UpdateData für den ausgewählten Tab, falls vorhanden
                    -- Annahme: Jedes Tab-Modul hat eine UpdateData Methode
                    if button.tabModuleName and Tabs[button.tabModuleName] and Tabs[button.tabModuleName].UpdateData then
                         -- Spezielle Daten für Recruitment übergeben, andere brauchen ggf. keine
                         if button.tabModuleName == "Recruitment" and SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.GetPendingRequests then
                             Tabs[button.tabModuleName]:UpdateData(SchlingelInc.GuildRecruitment.GetPendingRequests())
                         else
                            Tabs[button.tabModuleName]:UpdateData() -- Standardaufruf ohne Argumente
                         end
                    end
                else
                    PanelTemplates_DeselectTab(button) -- Entfernt Hervorhebung.
                    tabContentFrames[index]:Hide()
                end
            end
        end
    end

    -- Hilfsfunktion zum Erstellen eines Tab-Buttons.
    -- Speichert den Modulnamen im Button für SelectTab
    local function CreateTabButton(tabIndex, buttonText, tabModuleName)
        local buttonWidth = 125
        local buttonSpacing = 10
        local startX = 15

        -- Nutze Konstante aus SchlingelInc
        local button = CreateFrame("Button", SchlingelInc.TAB_BUTTON_NAME_PREFIX .. tabIndex, offiWindowFrame, "OptionsFrameTabButtonTemplate")
        button:SetID(tabIndex)
        button:SetText(buttonText)
        button:SetPoint("BOTTOMLEFT", offiWindowFrame, "BOTTOMLEFT", startX + (tabIndex - 1) * (buttonWidth + buttonSpacing), 10)
        button:SetWidth(buttonWidth)
        button:GetFontString():SetPoint("CENTER", 0, 2) -- Textposition im Button anpassen.
        button.tabModuleName = tabModuleName -- Speichere den Modulnamen
        button:SetScript("OnClick", function() SelectTab(tabIndex) end)

        PanelTemplates_DeselectTab(button) -- Standardmäßig nicht ausgewählt.
        table.insert(tabButtons, button) -- Füge zur Liste hinzu (Indices entsprechen der Reihenfolge)
        return button
    end

    -- Erstellt die Tab-Buttons. Die Reihenfolge hier definiert die Tab-Indexe (1, 2, 3, 4).
    -- Gibt den Modulnamen mit, der für CreateUI und UpdateData verwendet wird.
    CreateTabButton(1, "Gildeninfo", "GuildInfo")
    CreateTabButton(2, "Anfragen", "Recruitment")
    CreateTabButton(3, "Statistik", "Stats")
    CreateTabButton(4, "Inaktiv", "Inactivity")

    -- Erstellt die Inhaltsframes für jeden Tab und speichert sie.
    -- Rufe die CreateUI Methode des jeweiligen Moduls auf.
    local tabModules = {
        [1] = "GuildInfo",
        [2] = "Recruitment",
        [3] = "Stats",
        [4] = "Inactivity",
    }

    for index, moduleName in ipairs(tabModules) do
        if SchlingelInc.Tabs[moduleName] and SchlingelInc.Tabs[moduleName].CreateUI then
             tabContentFrames[index] = SchlingelInc.Tabs[moduleName]:CreateUI(tabContentContainer)
        else
            SchlingelInc:Print("Fehler: Tab Modul '" .. moduleName .. "' nicht geladen oder CreateUI fehlt!")
            -- Optional: Einen leeren Frame als Platzhalter erstellen, um Fehler zu vermeiden
             tabContentFrames[index] = CreateFrame("Frame", nil, tabContentContainer)
             tabContentFrames[index]:SetAllPoints(true)
             tabContentFrames[index]:Hide()
        end
    end

    self.OffiWindow = offiWindowFrame -- Speichert den Hauptframe des Fensters.

    -- Wählt den ersten Tab standardmäßig aus, nachdem alle Tabs erstellt wurden.
    -- Dies triggert auch das erste Laden der Daten für Tab 1 über SelectTab.
    SelectTab(1)
end

--------------------------------------------------------------------------------
-- Funktion zum Umschalten der Sichtbarkeit des Offi-Fensters
--------------------------------------------------------------------------------
function SchlingelInc:ToggleOffiWindow()
    -- Erstellt das Fenster, falls es noch nicht existiert.
    if not self.OffiWindow then
        self:CreateOffiWindow()
    end
    if not self.OffiWindow then
        SchlingelInc:Print(SchlingelInc.ADDON_PREFIX .. ": OffiWindow konnte nicht erstellt/gefunden werden!") -- Nutze Konstante aus SchlingelInc
        return
    end

    if self.OffiWindow:IsShown() then
        self.OffiWindow:Hide() -- Fenster ausblenden, wenn es sichtbar ist.
    else
        self.OffiWindow:Show() -- Fenster anzeigen, wenn es ausgeblendet ist.

        -- Lokale Referenz auf die Tabs für schnellere Zugriffe
        local Tabs = SchlingelInc.Tabs

        -- Alle Tabs beim Anzeigen aktualisieren.
        -- Rufe die UpdateData Methode jedes Moduls auf, falls vorhanden
        if Tabs.GuildInfo and Tabs.GuildInfo.UpdateData then
            Tabs.GuildInfo:UpdateData()
        end
        -- Recruitment braucht ggf. Daten vom GuildRecruitment Modul
        if Tabs.Recruitment and Tabs.Recruitment.UpdateData and SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.GetPendingRequests then
             Tabs.Recruitment:UpdateData(SchlingelInc.GuildRecruitment.GetPendingRequests())
        elseif Tabs.Recruitment and Tabs.Recruitment.UpdateData then -- Fallback, falls GuildRecruitment fehlt
             Tabs.Recruitment:UpdateData({}) -- Leere Liste übergeben oder ohne Argumente, je nach Modul-Logik
        end
        if Tabs.Stats and Tabs.Stats.UpdateData then
            Tabs.Stats:UpdateData()
        end
        if Tabs.Inactivity and Tabs.Inactivity.UpdateData then
            Tabs.Inactivity:UpdateData()
        end
    end
end

--------------------------------------------------------------------------------
-- Bestätigungsdialog für Gilden-Kick
-- Definiert einen Standard-Dialog, der vor dem Entfernen eines Mitglieds
-- aus der Gilde angezeigt wird. Bleibt vorerst hier, kann aber in Dialogs.lua verschoben werden.
--------------------------------------------------------------------------------
StaticPopupDialogs["CONFIRM_GUILD_KICK"] = {
    text = "Möchtest du %s wirklich aus der Gilde entfernen?", -- %s wird durch den Spielernamen ersetzt.
    button1 = ACCEPT, -- "Akzeptieren"
    button2 = CANCEL, -- "Abbrechen"
    OnAccept = function(selfDialog, data)
        -- Wird ausgeführt, wenn "Akzeptieren" geklickt wird.
        if data and data.memberName then
            C_GuildInfo.Uninvite(data.memberName) -- Entfernt das Mitglied aus der Gilde.
            if SchlingelInc and SchlingelInc.Print then
                SchlingelInc:Print(data.memberName .. " wurde aus der Gilde entfernt.")
            end
            -- Kurze Verzögerung, um sicherzustellen, dass die Gildenliste serverseitig aktualisiert wurde,
            -- bevor die UI neu geladen wird.
            if SchlingelInc then
                C_Timer.After(0.7, function()
                    if SchlingelInc.OffiWindow and SchlingelInc.OffiWindow:IsShown() then
                         -- Lokale Referenz auf die Tabs
                        local Tabs = SchlingelInc.Tabs
                        -- Aktualisiert alle relevanten Tabs nach dem Kick.
                        -- Rufe die UpdateData Methode der Module auf
                        if Tabs.GuildInfo and Tabs.GuildInfo.UpdateData then
                             Tabs.GuildInfo:UpdateData()
                        end
                         if Tabs.Recruitment and Tabs.Recruitment.UpdateData and SchlingelInc.GuildRecruitment and SchlingelInc.GuildRecruitment.GetPendingRequests then
                             Tabs.Recruitment:UpdateData(SchlingelInc.GuildRecruitment.GetPendingRequests())
                        elseif Tabs.Recruitment and Tabs.Recruitment.UpdateData then -- Fallback
                             Tabs.Recruitment:UpdateData({})
                        end
                        if Tabs.Stats and Tabs.Stats.UpdateData then
                            Tabs.Stats:UpdateData()
                        end
                        if Tabs.Inactivity and Tabs.Inactivity.UpdateData then
                            Tabs.Inactivity:UpdateData()
                        end
                    end
                end)
            end
        end
    end,
    OnCancel = function(selfDialog, data)
        -- Wird ausgeführt, wenn "Abbrechen" geklickt wird (tut nichts).
    end,
    timeout = 0, -- Kein automatisches Schließen.
    whileDead = 1, -- Kann auch angezeigt werden, wenn der Spieler tot ist.
    hideOnEscape = 1, -- Schließt bei Drücken von Escape.
    preferredIndex = 3, -- Standard-Popup-Index.
}