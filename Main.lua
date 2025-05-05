StaticPopupDialogs["SCHLINGEL_HARDCOREUNLOCKED_WARNING"] = {
    text = "Du hast das veraltete Addon aktiv.\nBitte entferne es, da es zu Problemen mit SchlingelInc führt!",
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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
    -- Prüfung auf Hardcore Unlocked bzw Schlingel Addon
    local numAddons = GetNumAddOns()
    for i = 1, numAddons do
        local name, _, _, enabled = GetAddOnInfo(i)
        if name == "HardcoreUnlocked" or "SchlingelAddon" and enabled == 1 then
            SchlingelInc:Print(
            "|cffff0000Warnung: Du hast das veraltete Addon aktiv. Bitte entferne es, da es zu Problemen mit SchlingelInc führt!|r")
            StaticPopup_Show("SCHLINGEL_HARDCOREUNLOCKED_WARNING")
            break
        end
    end
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
    if CharacterDeaths == nil then
        SchlingelInc:Print(
        "Keine Tode gefunden.\nBitte initialisiere deinen DeathCounter einmal mit /deathset <Zahl>. Danke für deine Ehrlichkeit! :)")
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
