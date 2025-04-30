SchlingelInc.LevelUps = {}
-- Initialisierung für LevelUp-Events und der Abhandlung
SchlingelInc.LevelUps.Milestones = {
    10, 
    20,
    30,
    40,
    45,
    50,
    55,
    60,
}

function SchlingelInc.LevelUps:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LEVEL_UP") -- Registriere Event für Level-Up
    frame:SetScript("OnEvent", function(_, event, level)
        if event == "PLAYER_LEVEL_UP" then
            for _, lvl in pairs(SchlingelInc.LevelUps.Milestones) do
                if level == lvl then
                    local player = UnitName("player")
                    local Message = player .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!"
                    SendChatMessage(Message, "GUILD")
                end
            end
        end
    end)
end
