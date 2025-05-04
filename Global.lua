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
    "Schlingel IInc"
}

function SchlingelInc:IsGuildAllowed(guildName)
    for _, allowedGuild in ipairs(SchlingelInc.allowedGuilds) do
        if guildName == allowedGuild then
            return true
        end
    end
    return false
end

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

-- Check if Player is in Battleground
function SchlingelInc:IsInBattleground()
    local isInBattleground = false
    local level = UnitLevel("player")
    local isInAllowedBattleground = false
    for i = 1, GetMaxBattlefieldID() do
        local battleFieldStatus = GetBattlefieldStatus(i)
        if battleFieldStatus == "active" then
            isInBattleground = true
        end
    end
    if isInBattleground and level >= 55 then
        isInAllowedBattleground = true
    end
    return isInAllowedBattleground
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
    if not SchlingelInc:IsInBattleground() then
        SchlingelInc:CheckTargetPvP()
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

-- Hook into the SendChatMessage function
local originalSendChatMessage = SendChatMessage
function SendChatMessage(msg, chatType, language, channel)
    -- Check if the message is being sent to the guild
    if chatType == "GUILD" then
        -- Send the addon version via the hidden addon communications channel
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end

    -- Call the original SendChatMessage function
    originalSendChatMessage(msg, chatType, language, channel)
end

-- Table to store versions of guild members
SchlingelInc.guildMemberVersions = {}

-- Frame to handle addon messages
local addonMessageFrame = CreateFrame("Frame")
addonMessageFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

addonMessageFrame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        -- Check if the message contains version information
        local receivedVersion = message:match("^VERSION:(.+)$")
        if receivedVersion then
            -- Store the version for the sender
            SchlingelInc.guildMemberVersions[sender] = receivedVersion
        end
    end
end)

-- Frame to listen for guild chat messages
local guildChatFrame = CreateFrame("Frame")
guildChatFrame:RegisterEvent("CHAT_MSG_GUILD")

-- Add a filter to modify guild messages
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(self, event, msg, sender, ...)
    if not CanGuildInvite() then return end
    -- Get the sender's version from the stored data
    local version = SchlingelInc.guildMemberVersions[sender] or nil

    local modifiedMessage = msg
    if version ~= nil then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end

    -- Return the modified message
    return false, modifiedMessage, sender, ...
end)

-- Hilfsfunction um Tabellen auszugeben
function SchlingelInc:PrintFormattedTable(tbl, indent)
    -- Default indentation level is 0
    indent = indent or 0
    local indentation = string.rep("  ", indent)
    local output = "{\n"

    for key, value in pairs(tbl) do
        -- Check the type of the value
        if type(value) == "table" then
            -- Print the key and recursively print the nested table
            output = output ..
                indentation ..
                "  " .. tostring(key) .. " = " .. SchlingelInc:PrintFormattedTable(value, indent + 1) .. ",\n"
        elseif type(value) == "string" then
            -- Add quotes around string values
            output = output .. indentation .. "  " .. tostring(key) .. " = \"" .. tostring(value) .. "\",\n"
        else
            -- Print other types as is
            output = output .. indentation .. "  " .. tostring(key) .. " = " .. tostring(value) .. ",\n"
        end
    end

    output = output .. indentation .. "}"
    return output
end

-- Hilfsfunktion um den Realm-Namen aus dem Spielernamen zu entfernen
function SchlingelInc:RemoveRealmFromName(fullName)
    -- Find the position of the hyphen in the name
    local dashPosition = string.find(fullName, "-")

    if dashPosition then
        -- Extract the part of the string before the hyphen
        return string.sub(fullName, 1, dashPosition - 1)
    else
        -- If there's no hyphen, return the original name
        return fullName
    end
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
            SchlingelInc.pvpWarningName:SetText(name .. " ist PvP geflagged!")
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

-- Ab hier MiniMap Icon

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

-- Datenobjekt für das Minimap Icon
local minimapLDB = LDB:NewDataObject("SchlingelInc", {
    type = "data source",
    text = "Schlingel Inc",
    icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga",

    OnClick = function(_, button)
        if button == "LeftButton" then
            SchlingelInc:ToggleInfoWindow()
        end
        if button == "RightButton" then
            SchlingelInc:ToggleOffiWindow()
        end
    end,

    OnEnter = function(SchlingelInc)
        GameTooltip:SetOwner(SchlingelInc, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Schlingel Inc", 1, 0.7, 0.9)
        GameTooltip:AddLine("Version: " .. (GetAddOnMetadata("SchlingelInc", "Version") or "Unbekannt"), 1, 1, 1)
        GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1)
        GameTooltip:Show()
    end,

    OnLeave = function()
        GameTooltip:Hide()
    end
})

-- Initialisierung des Minimap Icons
function SchlingelInc:InitMinimapIcon()
    if not DBIcon or not minimapLDB then
        return
    end

    -- Stelle sicher, dass das Icon nur einmal registriert wird
    if not SchlingelInc.minimapRegistered then
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false }

        DBIcon:Register("SchlingelInc", minimapLDB, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true
    end
end
