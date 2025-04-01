local addonPrefix = "HardcoreAddon"

local function HandleAddonMessage(prefix, message, _, sender)
    if prefix == addonPrefix and message == "VERSION_REQUEST" then
        -- Eigene Addon-Version definieren
        local addonVersion = GetAddOnMetadata("HardcoreUnlocked", "Version") or "Unbekannt"

        -- Antwort an den Anfragenden senden
        C_ChatInfo.SendAddonMessage(addonPrefix, "VERSION_RESPONSE:" .. addonVersion, "WHISPER", sender)
        -- print("📢 Versionsantwort gesendet an " .. sender .. ": " .. addonVersion) -- debugging
    end
end

-- Event-Handler für Addon-Nachrichten registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    HandleAddonMessage(prefix, message, _, sender)
end)