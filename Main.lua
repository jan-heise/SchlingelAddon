function SchlingelInc:OnLoad()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    --DEBUG: SlashCommands nicht nach Production pushen
    --SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:InitMinimapIcon()

    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
end

-- Event-Handler für globale Events wie Login, Time Played etc.
local eventHandlerFrame = CreateFrame("Frame", "SchlingelIncGlobalEventHandler")
eventHandlerFrame:RegisterEvent("ADDON_LOADED")
eventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandlerFrame:RegisterEvent("TIME_PLAYED_MSG")
eventHandlerFrame:RegisterEvent("PLAYER_LEVEL_UP")

-- Event-Handler-Skript
eventHandlerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ... 
        if addonName == SchlingelInc.name then
            SchlingelInc:OnLoad()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        SchlingelInc:CheckDependencies()
        SchlingelInc:CheckAddonVersion()

        if not SchlingelInc.initialPlayTimeRequested then
            RequestTimePlayed()
            SchlingelInc.initialPlayTimeRequested = true
        end

        if CharacterDeaths == nil then
             SchlingelInc:Print(
                 "Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
        end

    elseif event == "TIME_PLAYED_MSG" then
        local totalTimeSeconds, levelTimeSeconds = ...

        SchlingelInc.GameTimeTotal = totalTimeSeconds or 0
        SchlingelInc.GameTimePerLevel = levelTimeSeconds or 0

        if SchlingelInc.infoWindow and SchlingelInc.infoWindow:IsShown() then
            local charTabIndex = 1
            if SchlingelInc.infoWindow.tabContentFrames and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex] and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:IsShown() and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex].Update then
                SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:Update(SchlingelInc.infoWindow.tabContentFrames[charTabIndex])
            end
        end

    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        SchlingelInc.CharacterPlaytimeLevel = 0
        RequestTimePlayed()
        SchlingelInc:Print(string.format("Level %d erreicht! Spielzeit auf Level zurückgesetzt und neu angefordert.", newLevel)) -- Debug
    end
end)