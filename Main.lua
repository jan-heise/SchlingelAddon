-- SchlingelInc:OnLoad() Funktion - wird ausgeführt, wenn das Addon selbst geladen wird.
function SchlingelInc:OnLoad()
    -- Initialisiert Kernmodule des Addons.
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()

    -- Slash-Befehle für Gildenrekrutierung (derzeit für Produktion auskommentiert).
    --SchlingelInc.GuildRecruitment:InitializeSlashCommands()

    -- Erstellt und initialisiert den PvP-Warn-Frame.
    SchlingelInc:CreatePvPWarningFrame()

    -- Initialisiert die Minimap-Icon-Funktionalität.
    SchlingelInc:InitMinimapIcon()

    -- Initialisiert die Gildenmitglieder.
    SchlingelInc:UpdateGuildMembers()

    -- Gibt eine Bestätigungsnachricht aus, dass das Addon geladen wurde, inklusive Version.
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
end

-- --- Event-Handler, die separate Frames verwenden ---

-- 1. ADDON_LOADED Event-Handler
-- Dieser Frame lauscht auf das ADDON_LOADED Event, um die Hauptinitialisierung unseres Addons auszulösen.
local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    -- Überprüft, ob das geladene Addon 'SchlingelInc' selbst ist.
    if addonName == SchlingelInc.name then
        SchlingelInc:OnLoad() -- Ruft die Haupt-OnLoad-Funktion auf.
    end
end)

-- 2. PLAYER_ENTERING_WORLD Event-Handler
-- Dieser Frame lauscht auf PLAYER_ENTERING_WORLD, um Überprüfungen durchzuführen,
-- die erfordern, dass der Spieler sich in der Spielwelt befindet.
local playerEnteringWorldFrame = CreateFrame("Frame", "SchlingelIncPlayerEnteringWorldFrame")
playerEnteringWorldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerEnteringWorldFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    -- Überprüft auf benötigte Addon-Abhängigkeiten (z.B. GreenWall, alte Versionen).
    SchlingelInc:CheckDependencies()

    -- Überprüft die Addon-Version mit anderen Gildenmitgliedern.
    SchlingelInc:CheckAddonVersion()

    -- Fordert die Gesamtspielzeit des Spielers an, falls dies noch nicht geschehen ist (erster Login).
    if not SchlingelInc.initialPlayTimeRequested then
        RequestTimePlayed()
        SchlingelInc.initialPlayTimeRequested = true
    end

    -- Informiert den Spieler über die Initialisierung des DeathCounters, falls 'CharacterDeaths' nicht definiert ist.
    if CharacterDeaths == nil then
        SchlingelInc:Print(
            "Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
    end
end)

-- 3. TIME_PLAYED_MSG Event-Handler
-- Dieser Frame lauscht auf TIME_PLAYED_MSG, um Spielzeitstatistiken zu aktualisieren.
local timePlayedFrame = CreateFrame("Frame", "SchlingelIncTimePlayedFrame")
timePlayedFrame:RegisterEvent("TIME_PLAYED_MSG")
timePlayedFrame:SetScript("OnEvent", function(self, event, totalTimeSeconds, levelTimeSeconds)
    -- Aktualisiert globale Spielzeitvariablen.
    SchlingelInc.GameTimeTotal = totalTimeSeconds or 0
    SchlingelInc.GameTimePerLevel = levelTimeSeconds or 0

    -- Wenn das Info-Fenster geöffnet ist und den Charakter-Tab anzeigt, aktualisiere dessen Anzeige.
    local charTabIndex = 1
    if SchlingelInc.infoWindow and SchlingelInc.infoWindow:IsShown() then
        if SchlingelInc.infoWindow.tabContentFrames and
            SchlingelInc.infoWindow.tabContentFrames[charTabIndex] and
            SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:IsShown() and
            SchlingelInc.infoWindow.tabContentFrames[charTabIndex].Update then
            -- Ruft die Update-Funktion des entsprechenden Tab-Inhaltsframes auf.
            SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:Update(SchlingelInc.infoWindow.tabContentFrames
                [charTabIndex])
        end
    end
end)

-- 4. PLAYER_LEVEL_UP Event-Handler
-- Dieser Frame lauscht auf PLAYER_LEVEL_UP, um die level-spezifische Spielzeit zurückzusetzen
-- und die Gesamtspielzeit erneut anzufordern.
local playerLevelUpFrame = CreateFrame("Frame", "SchlingelIncPlayerLevelUpFrame")
playerLevelUpFrame:RegisterEvent("PLAYER_LEVEL_UP")
playerLevelUpFrame:SetScript("OnEvent",
    function(self, event, newLevel, ...) -- '...' fängt weitere Argumente ab, falls vorhanden.
        -- Setzt die Spielzeit-Verfolgung für das neue Level zurück.
        SchlingelInc.CharacterPlaytimeLevel = 0

        -- Fordert aktualisierte Spielzeitdaten nach dem Levelaufstieg an.
        RequestTimePlayed()
    end)

-- 5. GUILD_ROSTER_UPDATE Event-Handler
-- Dieser Frame lauscht auf GUILD_ROSTER_UPDATE, um die Gildenmitglieder zu aktualisieren.
local guildRosterUpdateFrame = CreateFrame("Frame", "SchlingelIncGuildRosterUpdateFrame")
guildRosterUpdateFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
guildRosterUpdateFrame:SetScript("OnEvent", function(self, event)
    -- Aktualisiert die Gildenmitgliederliste.
    SchlingelInc:UpdateGuildMembers()
end)
