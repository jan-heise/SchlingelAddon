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
        -- Prüfen, ob der Erfolg bereits abgeschlossen ist
        if not self.completedAchievements[achievement.name] and achievement.condition() then
            -- Erfolg als abgeschlossen markieren
            self.completedAchievements[achievement.name] = true
            SavedAchievements[achievement.name] = true                                            -- Direkt in SavedAchievements speichern
            self.savedAchievementPoints = (self.savedAchievementPoints or 0) + achievement.points -- Punkte hinzufügen
            AchievementPoints = self.savedAchievementPoints                                       -- Korrektur hier
            self:AnnounceToGuild(achievement.name)
        end
    end
end

-- Initialisierung der Achievements
function SchlingelInc.Achievements:Initialize()
    -- Initialisiert die Achievements-Tabelle
    SchlingelInc.Achievements.achievements = {
        {
            name = "Stufe 10",
            description = "Erreiche Stufe 10",
            points = 10,
            condition = function()
                return UnitLevel("player") >= 10
            end
        },
        {
            name = "Stufe 20",
            description = "Erreiche Stufe 20",
            points = 10,
            condition = function()
                return UnitLevel("player") >= 20
            end
        },
        {
            name = "Stufe 30",
            description = "Erreiche Stufe 30",
            points = 10,
            condition = function()
                return UnitLevel("player") >= 30
            end
        },
        {
            name = "Stufe 40",
            description = "Erreiche Stufe 40",
            points = 10,
            condition = function()
                return UnitLevel("player") >= 40
            end
        },
        {
            name = "Stufe 50",
            description = "Erreiche Stufe 50",
            points = 10,
            condition = function()
                return UnitLevel("player") >= 50
            end
        },
        {
            name = "Stufe 60",
            description = "Erreiche Stufe 60",
            points = 30,
            condition = function()
                return UnitLevel("player") >= 60
            end
        },
        {
            name = "Erster Tod",
            description = "Stirb das erste Mal",
            points = 10,
            condition = function()
                return CharacterDeaths >= 1
            end
        },
        {
            name = "10 Tode",
            description = "Stirb das 10. Mal",
            points = 10,
            condition = function()
                return CharacterDeaths >= 10
            end
        },
        {
            name = "50 Tode",
            description = "Stirb das 50. Mal",
            points = 20,
            condition = function()
                return CharacterDeaths >= 50
            end
        },
        {
            name = "100 Tode",
            description = "Stirb das 100. Mal",
            points = 30,
            condition = function()
                return CharacterDeaths >= 100
            end
        },
    }

    -- Lade gespeicherte Erfolge
    if not SavedAchievements then
        SavedAchievements = {}
    end
    if not AchievementPoints then
        AchievementPoints = 0
    end
    self.completedAchievements = SavedAchievements
    self.savedAchievementPoints = AchievementPoints

    SchlingelInc:Print("Achievements initialisiert")

    local eventFrameSI = CreateFrame("Frame", "SchlingelInterfaceEventFrame")
    eventFrameSI:RegisterEvent("VARIABLES_LOADED") -- Wichtig für CharacterDeaths
    eventFrameSI:RegisterEvent("PLAYER_DEAD")
    eventFrameSI:SetScript("OnEvent", function(selfFrame, event, ...)
        SchlingelInc.Achievements:CheckAchievements()
    end)
end

-- Slash-Befehl definieren
local _, _, _, channel = SchlingelInc:ParseVersion(SchlingelInc.version)
if channel == "dev" then
    SLASH_SCHLINGELRESET1 = '/schlingelreset'
    SlashCmdList["SCHLINGELRESET"] = function()
        for k, v in pairs(SavedAchievements) do
            SavedAchievements[k] = nil -- Setzt den Wert auf true statt nil
        end
        AchievementPoints = 0
        SchlingelInc:Print("Achievmentdata resetted")
    end
end
