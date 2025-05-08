function SchlingelInc:OnLoad()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:InitMinimapIcon()

    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " grundlegend geladen.")
end

-- Event-Handler für globale Events wie Login, Time Played etc.
local eventHandlerFrame = CreateFrame("Frame", "SchlingelIncGlobalEventHandler")
eventHandlerFrame:RegisterEvent("ADDON_LOADED")
eventHandlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandlerFrame:RegisterEvent("TIME_PLAYED_MSG")
eventHandlerFrame:RegisterEvent("PLAYER_LEVEL_UP")

-- Event-Handler-Skript
eventHandlerFrame:SetScript("OnEvent", function(self, event, ...) -- Use varargs (...)
    -- Capture arguments based on the specific event
    if event == "ADDON_LOADED" then
        local addonName = ... -- First argument for ADDON_LOADED is addon name
        if addonName == SchlingelInc.name then
            SchlingelInc:OnLoad() -- Call your specific load function
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        SchlingelInc:Print("Willkommen, Schlingel! Version " .. SchlingelInc.version)
        SchlingelInc:CheckDependencies()
        SchlingelInc:CheckAddonVersion()

        -- Initial Playtime Request
        if not SchlingelInc.initialPlayTimeRequested then
            RequestTimePlayed()
            SchlingelInc.initialPlayTimeRequested = true
            -- SchlingelInc:Print("Spielzeit initial angefordert.") -- Debug
        end

         -- Death Counter Check
        if CharacterDeaths == nil then
             SchlingelInc:Print(
                 "Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
        end

    elseif event == "TIME_PLAYED_MSG" then
        local totalTimeSeconds, levelTimeSeconds = ... -- arg1 and arg2 are total/level time in SECONDS

        -- SchlingelInc:Print(string.format("TIME_PLAYED_MSG Received: TotalSec=%s, LevelSec=%s", tostring(totalTimeSeconds), tostring(levelTimeSeconds))) -- Debug line

        -- Store the values
        SchlingelInc.GameTimeTotal = totalTimeSeconds or 0
        SchlingelInc.GameTimePerLevel = levelTimeSeconds or 0

        -- *** ADDED: Explicitly trigger UI update if visible ***
        if SchlingelInc.infoWindow and SchlingelInc.infoWindow:IsShown() then
            local charTabIndex = 1 -- Charakter is Tab 1
            if SchlingelInc.infoWindow.tabContentFrames and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex] and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:IsShown() and
               SchlingelInc.infoWindow.tabContentFrames[charTabIndex].Update then
                -- Directly call the Update function of the visible character tab
                SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:Update(SchlingelInc.infoWindow.tabContentFrames[charTabIndex])
                -- SchlingelInc:Print("Charakter Tab Update explicitly called after TIME_PLAYED_MSG.") -- Debug
            end
        end
        
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        -- Reset time at level when leveling up
        SchlingelInc.CharacterPlaytimeLevel = 0
        -- Request new time immediately
        RequestTimePlayed()
        SchlingelInc:Print(string.format("Level %d erreicht! Spielzeit auf Level zurückgesetzt und neu angefordert.", newLevel)) -- Debug
    end
end)