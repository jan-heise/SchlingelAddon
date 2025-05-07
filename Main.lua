-- Initialisierung des Addons
function SchlingelInc:OnLoad()
    -- Initialisierung der Regeln
    SchlingelInc.Rules:Initialize()
    -- Initialisierung der Gildenanfragen
    SchlingelInc.GuildRecruitment:InitializeSlashCommands()
    -- Initialisierung der LevelUps
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc:CheckAddonVersion()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:InitMinimapIcon()

    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
    if CharacterDeaths == nil then
        SchlingelInc:Print(
            "Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
    end
    SchlingelInc:CheckDependencies()
end

-- Event-Handler registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- So haben wir einen OnEvent Listener. Doppelte überschreiben sich gegenseitig.
frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "SchlingelInc" then
        SchlingelInc:OnLoad()
    end
end)
