-- Initialisierung des Addons
function SchlingelInc:OnLoad()
    -- Initialisierung der Regeln
    SchlingelInc.Rules:Initialize()
    -- Initialisierung der LevelUps
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc:CheckAddonVersion()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
end

-- Event-Handler registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "SchlingelInc" then
        SchlingelInc:OnLoad()
    elseif event == "PLAYER_LOGIN" then
        SchlingelInc:InitMinimapIcon()
    end
end)