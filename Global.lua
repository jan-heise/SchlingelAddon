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
    "Schlingel Inc II"
}

-- Tabelle für PvP-Alert Timestamps
SchlingelInc.lastPvPAlert = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")

-- Frame für die PvP Interaktion
local pvpFrame = CreateFrame("Frame")
pvpFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

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

-- Event beim Zielwechsel abgreifen und PvP Helfer Funktion rufen
pvpFrame:SetScript("OnEvent", function()
    SchlingelInc:CheckTargetPvP()
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
                    SchlingelInc:Print("Eine neuere Addon-Version wurde entdeckt: " ..
                        highestSeenVersion .. ". Bitte aktualisiere dein Addon!")
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

-- Überprüfe ob das Ziel ein PvP Flag hat
function SchlingelInc:CheckTargetPvP()
    local unit = "target"

    if not UnitExists(unit) then return end

    -- Fraktionscheck: Bei NPCs eigener Fraktion ignorieren. Zu Debugzwecken den Fraktionscheck auskommentieren.
    local targetFaction = UnitFactionGroup(unit)
    local playerFaction = UnitFactionGroup("player")
    if targetFaction and playerFaction and targetFaction == playerFaction and not UnitIsPlayer(unit) then
        --SchlingelInc:Print("DEBUG: Horde NPC erkannt.") | Für Debugging wieder einschalten.
        return
    end

    if UnitIsPVP(unit) then
        local name = UnitName(unit)
        local now = GetTime()
        local lastAlert = SchlingelInc.lastPvPAlert and SchlingelInc.lastPvPAlert[name] or 0

        if not SchlingelInc.lastPvPAlert then
            SchlingelInc.lastPvPAlert = {}
        end

        if (now - lastAlert) > 10 then
            SchlingelInc.lastPvPAlert[name] = now

            -- Popup generierung und zeigen
            SchlingelInc.pvpWarningText:SetText("Obacht Schlingel!")
            SchlingelInc.pvpWarningName:SetText(name .. " ist PvP-aktiv!")
            SchlingelInc.pvpWarningFrame:SetAlpha(1)
            SchlingelInc.pvpWarningFrame:Show()
            SchlingelInc:RumbleFrame(SchlingelInc.pvpWarningFrame)

            -- Fade out nach 1 Sekunde
            C_Timer.After(1, function()
                UIFrameFadeOut(SchlingelInc.pvpWarningFrame, 1, 1, 0)
                C_Timer.After(1, function() SchlingelInc.pvpWarningFrame:Hide() end)
            end)
        end
    end
end

-- Pop Up für die PvP Warnung
function SchlingelInc:CreatePvPWarningFrame()
    if SchlingelInc.pvpWarningFrame then return end

    local pvpFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    pvpFrame:SetSize(320, 110)
    pvpFrame:SetPoint("CENTER")
    pvpFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    pvpFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1) -- Schlingel-Farbe (rosa)
    pvpFrame:SetBackdropColor(0, 0, 0, 0.30)          -- Transparenter Hintergrund

    pvpFrame:SetMovable(true)
    pvpFrame:EnableMouse(true)
    pvpFrame:RegisterForDrag("LeftButton")
    pvpFrame:SetScript("OnDragStart", pvpFrame.StartMoving)
    pvpFrame:SetScript("OnDragStop", pvpFrame.StopMovingOrSizing)
    pvpFrame:Hide()

    -- Haupttext
    local text = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    text:SetPoint("TOP", pvpFrame, "TOP", 0, -20)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Zielname
    local nameText = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    nameText:SetPoint("BOTTOM", pvpFrame, "BOTTOM", 0, 25)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    nameText:SetTextColor(1, 0.82, 0) -- Gelblicher Farbton für Namen

    -- Speichern
    SchlingelInc.pvpWarningFrame = pvpFrame
    SchlingelInc.pvpWarningText = text
    SchlingelInc.pvpWarningName = nameText
end

-- Kurze Rumble-Animation beim Erscheinen
function SchlingelInc:RumbleFrame(frame)
    if not frame then return end

    local rumbleTime = 0.3
    local interval = 0.03
    local totalTicks = math.floor(rumbleTime / interval)
    local tick = 0

    C_Timer.NewTicker(interval, function()
        if not frame:IsShown() then
            return
        end

        tick = tick + 1
        local offsetX = math.random(-4, 4)
        local offsetY = math.random(-4, 4)
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)

        if tick >= totalTicks then
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end)
end
