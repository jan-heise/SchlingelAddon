-- Initialisierung des Addons
function SchlingelInc:OnLoad()
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
