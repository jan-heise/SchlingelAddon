-- Globale Tabelle für alle Achievements
SchlingelInc.Achievements = {}

-- Tabelle für gespeicherte Erfolge
SchlingelInc.Achievements.completedAchievements = {}

function SchlingelInc.Achievements:AnnounceToGuild(achievement)
    local name = SchlingelInc:RemoveRealmFromName(UnitName("player"))
    local msg = string.format("%s hat den Erfolg '%s' erspielt!", name, achievement)
    print(msg) --debug
    -- SendChatMessage(msg, "GUILD")
end

-- Funktion, um Erfolge zu prüfen
function SchlingelInc.Achievements:CheckAchievements()
    for _, achievement in ipairs(self.achievements) do
        if not self.completedAchievements[achievement.name] and achievement.condition() then
            self.completedAchievements[achievement.name] = true -- Erfolg als abgeschlossen markieren
            self:AnnounceToGuild(achievement.name)
        end
    end
end

-- Initialisierung der Achievements
function SchlingelInc.Achievements:Initialize()
    -- Initialisiert die Achievements-Tabelle
    SchlingelInc.Achievements.achievements = {
        {
            name = "Erster Tod",
            description = "Stirb das erste Mal",
            condition = function()
                return CharacterDeaths >= 1
            end
        },
    }

    -- Lade gespeicherte Erfolge
    if not SavedAchievements then
        SavedAchievements = {}
    end
    self.completedAchievements = SavedAchievements

    SchlingelInc:Print("Achievements initialisiert")

    local eventFrameSI = CreateFrame("Frame", "SchlingelInterfaceEventFrame")
    eventFrameSI:RegisterEvent("VARIABLES_LOADED") -- Wichtig für CharacterDeaths
    eventFrameSI:RegisterEvent("PLAYER_DEAD")
    eventFrameSI:SetScript("OnEvent", function(selfFrame, event, ...)
        SchlingelInc.Achievements:CheckAchievements()
    end)
end
