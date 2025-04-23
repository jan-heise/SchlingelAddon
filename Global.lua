-- Globale Tabelle für das Addon
SchlingelInc = {}

-- Addon-Name
SchlingelInc.name = "Schlingel Inc"

-- Discord Link
SchlingelInc.discordLink = "https://discord.gg/KXkyUZW"

-- Chat-Nachrichten-Prefix
SchlingelInc.prefix = "SchlingelInc"

-- ColorCode für den Chat-Text
SchlingelInc.colorCode = "|cFFF48CBA"

-- Version aus der TOC-Datei
SchlingelInc.version = GetAddOnMetadata("SchlingelInc", "Version") or "Unbekannt"

SchlingelInc.allowedGuilds = {
    "Schlingel Inc",
    "Schlingel Twink"
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")

-- Print-Funktion
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[Schlingel Inc]|r " .. message)
end

-- Überprüfen, ob ein Spieler in der Gilde ist
--[[
    usage:
    local isInGuild = SchlingelInc:IsPlayerInGuild(GetGuildInfo("NPC"))
--]]
function SchlingelInc:IsPlayerInGuild(guildName)
    if not guildName then
        return false
    end

    for _, allowedGuild in ipairs(SchlingelInc.allowedGuilds) do
        if guildName == allowedGuild then
            return true
        end
    end
    return false
end

function SchlingelInc:IsGroupInGuild()
    -- Tabelle, um Antworten zu speichern
    local responses = {}
    local allInGuild = true

    -- Nachricht an die Raid-Gruppe senden, um die Gildennamen anzufordern
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "GUILD_NAME_REQUEST", "RAID")

    -- Warte 2 Sekunden, um Antworten zu sammeln
    C_Timer.After(2, function()
        local identifiers = {
            "party1",
            "party2",
            "party3",
            "party4",
        }

        -- Überprüfe die Gildennamen der Gruppenmitglieder
        for _, id in ipairs(identifiers) do
            local party_member = UnitName(id)

            if party_member and UnitIsConnected(id) then
                -- Verwende die Antwort oder hole den Gildennamen direkt
                local guildName = responses[party_member] or GetGuildInfo(id)
                if not SchlingelInc:IsPlayerInGuild(guildName) then
                    allInGuild = false
                end
            end
        end

        -- Wenn ein Spieler nicht in einer erlaubten Gilde ist, verlasse die Gruppe
        if not allInGuild then
            SchlingelInc:Print("Gruppen mit Spielern außerhalb der Gilde sind verboten!")
            LeaveParty()
        end
    end)

    -- Registriere den Event-Listener für Addon-Nachrichten
    frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
            -- Überprüfe, ob die Nachricht eine GILD_NAME_RESPONSE ist
            local guildName = message:match("^GUILD_NAME_RESPONSE:(.+)$")
            if guildName then
                responses[sender] = guildName
            end
        end
    end)

    return true
end

-- Event-Listener für eingehende GILD_NAME_REQUEST-Nachrichten
frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        if message == "GUILD_NAME_REQUEST" then
            -- Hole den Gildennamen des Spielers
            local guildName = GetGuildInfo("player")
            if guildName then
                -- Sende den Gildennamen als Antwort zurück
                C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "GUILD_NAME_RESPONSE:" .. guildName, "RAID")
            end
        end
    end
end)

-- Version Check Hilfsfunktion
function SchlingelInc:CheckAddonVersion()
    local highestSeenVersion = SchlingelInc.version

    -- Frame to handle version events
    local versionFrame = CreateFrame("Frame")
    versionFrame:RegisterEvent("CHAT_MSG_ADDON")
    C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

    -- Listen for version messages
    versionFrame:SetScript("OnEvent", function(_, event, msgPrefix, message, _, sender)
        if event == "CHAT_MSG_ADDON" and msgPrefix == SchlingelInc.prefix then
            local receivedVersion = message:match("^VERSION:(.+)$")
            if receivedVersion then
                if SchlingelInc:CompareVersions(receivedVersion, highestSeenVersion) > 0 then
                    highestSeenVersion = receivedVersion
                    SchlingelInc:Print("Eine neuere Addon-Version wurde entdeckt: " .. highestSeenVersion .. ". Bitte aktualisiere dein Addon!")
                end
            end
        end
    end)

    -- Send own version
    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end

end

-- Hilfsfunktion zum Versionsabgleich
function SchlingelInc:CompareVersions(v1, v2)
    local function parse(v)
        local major, minor, patch = string.match(v, "(%d+)%.(%d+)%.?(%d*)")
        return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
    end

    local a1, a2, a3 = parse(v1)
    local b1, b2, b3 = parse(v2)

    if a1 ~= b1 then return a1 - b1 end
    if a2 ~= b2 then return a2 - b2 end
    return a3 - b3
end
