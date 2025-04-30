-- Initialisierung des Addons
function SchlingelInc:OnLoad()
    -- Initialisierung der Regeln
    SchlingelInc.Rules:Initialize()
    -- Initialisierung der LevelUps
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc:CheckAddonVersion()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:InitMinimapIcon()
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
    if CharacterDeaths == 0 then
        SchlingelInc:Print("Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
    end
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