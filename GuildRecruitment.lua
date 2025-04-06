local addonPrefix = "HardcoreAddon"

local function HandleAddonMessage(table, event, prefix, message, channel, sender)
    local playerName, playerLevel = string.match(message, "^GUILD_REQUEST:([^:]+):(%d+)$")
    if playerName and playerLevel then
        print(string.format("[Schlingel] Gildenbeitrittsanfrage von %s (Level %s) empfangen!", playerName, playerLevel))

        -- Beispiel: Nachricht im Gilden-Addon-Channel weiterleiten
        local forwardMessage = string.format("INVITE_REQUEST:%s:%s", playerName, playerLevel)
        C_ChatInfo.SendAddonMessage(addonPrefix, forwardMessage, "GUILD")
        print(forwardMessage)
        return
    end
end

-- Event-Handler für Addon-Nachrichten registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(table, event, prefix, message, channel, sender)
    HandleAddonMessage(table, event, prefix, message, channel, sender)
end)