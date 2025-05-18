SchlingelInc.Tabs = SchlingelInc.Tabs or {}

SchlingelInc.Tabs.GuildInfo = {
    Frame = nil, -- Speichert eine Referenz auf den UI Frame des Tabs
    InfoText = nil, -- Speichert eine Referenz auf das Textfeld innerhalb des Tabs
}

--------------------------------------------------------------------------------
-- Erstellung der Inhalte für den "Gildeninfo"-Tab (Tab 1)
-- Diese Funktion ist verantwortlich für das Layout und die Grundstruktur
-- des "Gildeninfo"-Tabs.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.GuildInfo:CreateUI(parentFrame)
    -- Das Modul selbst (self) wird über den Doppelpunkt-Aufruf übergeben
    -- Zugriffe auf Konstanten über SchlingelInc Tabelle
    local tabFrame = CreateFrame("Frame", SchlingelInc.ADDON_PREFIX .. "GuildInfoTabFrame", parentFrame)
    tabFrame:SetAllPoints(true) -- Füllt den gesamten parentFrame aus.

    -- Erstellt ein Textfeld für die Gildeninformationen.
    -- UIHelper wird als global verfügbar angenommen.
    -- Zugriffe auf UIHelpers und Konstanten über SchlingelInc Tabelle
    local infoText = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Lade Gildeninfos ...", SchlingelInc.FONT_NORMAL,
        "TOPLEFT", tabFrame, "TOPLEFT", 10, -25, 560, 480, "LEFT", "TOP")

    -- Speichert Referenzen auf den Tab-Frame und das Textfeld im Modul selbst (self)
    self.Frame = tabFrame
    self.InfoText = infoText

    -- Rückgabe des erstellten Frames
    return tabFrame
end

--------------------------------------------------------------------------------
-- Funktion zum Aktualisieren des "Gildeninfo"-Tabs
-- Lädt und zeigt Spieler- und Gildeninformationen an.
--------------------------------------------------------------------------------
function SchlingelInc.Tabs.GuildInfo:UpdateData()
    -- Überprüfe, ob die benötigten UI-Elemente existieren (via self)
    if not self.Frame or not self.InfoText then
        return -- Abbruch, wenn das Textfeld nicht existiert.
    end

    local playerName, playerRealm = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerClassLocalized, _ = UnitClass("player")
    local guildName, guildRankName, _, _ = GetGuildInfo("player")

    local infoTextContent = ""

    if not guildName then
        -- Spieler ist in keiner Gilde.
        infoTextContent = string.format(
            "|cff69ccf0Spielerinformationen:|r\n" ..
            "  Name: %s%s\n" ..
            "  Level: %d\n" ..
            "  Klasse: %s\n\n" ..
            "Nicht in einer Gilde.",
            playerName or "Unbekannt",
            playerRealm and (" - " .. playerRealm) or "",
            playerLevel or 0,
            playerClassLocalized or "Unbekannt"
        )
    else
        -- Spieler ist in einer Gilde.
        local totalGuildMembers, onlineGuildMembers = GetNumGuildMembers()
        totalGuildMembers = totalGuildMembers or 0
        onlineGuildMembers = onlineGuildMembers or 0

        local totalLevelSum = 0
        local membersCountedForAverageLevel = 0
        if totalGuildMembers > 0 then
            for i = 1, totalGuildMembers do
                -- Beachte: GetGuildRosterInfo Rückgabewerte sind spezifisch für Classic Era
                local nameRoster, _, _, levelRoster, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
                if nameRoster and levelRoster and levelRoster > 0 then
                    totalLevelSum = totalLevelSum + levelRoster
                    membersCountedForAverageLevel = membersCountedForAverageLevel + 1
                end
            end
        end

        local averageLevelText = "N/A"
        if membersCountedForAverageLevel > 0 then
            averageLevelText = string.format("%d", math.floor(totalLevelSum / membersCountedForAverageLevel))
        elseif totalGuildMembers > 0 then
            averageLevelText = "0 (Leveldaten fehlen)" -- Sollte nicht passieren, wenn totalGuildMembers > 0 und Schleife läuft, aber als Fallback.
        else
            averageLevelText = "N/A (Keine Mitglieder)" -- Wenn totalGuildMembers 0 ist.
        end

        infoTextContent = string.format(
            "|cff69ccf0Spielerinformationen:|r\n" ..
            "  Name: %s%s\n" ..
            "  Level: %d\n" ..
            "  Klasse: %s\n" ..
            "  Gildenrang: %s\n\n" ..
            "|cff69ccf0Gildeninformationen:|r\n" ..
            "  Gildenname: %s\n" ..
            "  Mitglieder (Gesamt): %d\n" ..
            "  Mitglieder (Online): %d\n" ..
            "  Durchschnittslevel (Gilde): %s",
            playerName or "Unbekannt",
            playerRealm and (" - " .. playerRealm) or "",
            playerLevel or 0,
            playerClassLocalized or "Unbekannt",
            guildRankName or "Unbekannt",
            guildName or "Unbekannt", -- Fallback
            totalGuildMembers,
            onlineGuildMembers,
            averageLevelText
        )
    end

    -- Setze den Text des Info-Textfeldes (via self)
    self.InfoText:SetText(infoTextContent)
end

-- Event-Handler: Gildenliste aktualisiert
local GuildInfoEventsFrame = CreateFrame("Frame")
GuildInfoEventsFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
GuildInfoEventsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        if SchlingelInc.Tabs.GuildInfo and SchlingelInc.Tabs.GuildInfo.UpdateData then
            SchlingelInc.Tabs.GuildInfo:UpdateData()
        end
    end
end)