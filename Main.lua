-- Initialisierung des Addons
function SchlingelInc:OnLoad()
    -- Initialisierung der Regeln
    SchlingelInc.Rules:Initialize()

    SchlingelInc:CheckAddonVersion()
    SchlingelInc:CreatePvPWarningFrame()
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
end

-- Event-Handler registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "SchlingelInc" then
        SchlingelInc:OnLoad()
    end
end)
