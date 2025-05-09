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
SchlingelInc.GameTimeTotal, SchlingelInc.GameTimePerLevel = 0, 0

function SchlingelInc:CheckDependencies()
    StaticPopupDialogs["SCHLINGEL_HARDCOREUNLOCKED_WARNING"] = {
        text = "Du hast das veraltete Addon aktiv.\nBitte entferne es, da es zu Problemen mit SchlingelInc führt!",
        button1 = "OK",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopupDialogs["SCHLINGEL_GREENWALL_MISSING"] = {
        text = "Du hast Greenwall nicht aktiv.\nBitte aktiviere oder installiere es!",
        button1 = "OK",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    C_Timer.After(30, function()
        local numAddons = GetNumAddOns()
        local greenwall_found = false
        for i = 1, numAddons do
            local name, _, _, enabled = GetAddOnInfo(i)
            if (name == "HardcoreUnlocked" and IsAddOnLoaded("HardcoreUnlocked")) or (name == "SchlingelAddon" and IsAddOnLoaded("SchlingelAddon")) then
                SchlingelInc:Print(
                    "|cffff0000Warnung: Du hast das veraltete Addon aktiv. Bitte entferne es, da es zu Problemen mit SchlingelInc führt!|r")
                StaticPopup_Show("SCHLINGEL_HARDCOREUNLOCKED_WARNING")
            end

            if name == "GreenWall" and IsAddOnLoaded("GreenWall") then
                greenwall_found = true
            end
        end

        C_Timer.After(5, function()
            if not greenwall_found then
                SchlingelInc:Print(
                    "|cffff0000Warnung: Du hast Greenwall nicht aktiv. Bitte aktiviere oder installiere es!|r")
                StaticPopup_Show("SCHLINGEL_GREENWALL_MISSING")
            end
        end)
    end)
end

function SchlingelInc:IsGuildAllowed(guildName)
    for _, allowedGuild in ipairs(SchlingelInc.allowedGuilds) do
        if guildName == allowedGuild then
            return true
        end
    end
    return false
end

SchlingelInc.lastPvPAlert = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")

local pvpFrame = CreateFrame("Frame")
pvpFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

function SchlingelInc:IsInBattleground()
    local isInBattleground = false
    local level = UnitLevel("player")
    local isInAllowedBattleground = false
    for i = 1, GetMaxBattlefieldID() do
        local battleFieldStatus = GetBattlefieldStatus(i)
        if battleFieldStatus == "active" then
            isInBattleground = true
            break -- No need to check further if already found in one active BG
        end
    end
    if isInBattleground and level >= 55 then -- Assuming 55 is a specific rule for your server/addon
        isInAllowedBattleground = true
    end
    return isInAllowedBattleground
end

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

frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        if message == "GUILD_NAME_REQUEST" then
            local guildName = GetGuildInfo("player")
            if guildName then
                C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "GUILD_NAME_RESPONSE:" .. guildName, "RAID")
            end
        end
    end
end)

pvpFrame:SetScript("OnEvent", function()
    if not SchlingelInc:IsInBattleground() then
        SchlingelInc:CheckTargetPvP()
    end
end)

function SchlingelInc:CheckAddonVersion()
    local highestSeenVersion = SchlingelInc.version
    local versionFrame = CreateFrame("Frame")
    versionFrame:RegisterEvent("CHAT_MSG_ADDON")
    C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

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

    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end
end

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

local originalSendChatMessage = SendChatMessage
function SendChatMessage(msg, chatType, language, channel)
    if chatType == "GUILD" then
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end
    originalSendChatMessage(msg, chatType, language, channel)
end

SchlingelInc.guildMemberVersions = {}

local addonMessageFrame = CreateFrame("Frame")
addonMessageFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

addonMessageFrame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        local receivedVersion = message:match("^VERSION:(.+)$")
        if receivedVersion then
            SchlingelInc.guildMemberVersions[sender] = receivedVersion
        end
    end
end)

local guildChatFrame = CreateFrame("Frame")
guildChatFrame:RegisterEvent("CHAT_MSG_GUILD")

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(self, event, msg, sender, ...)
    if not CanGuildInvite() then return false, msg, sender, ... end -- Pass original if not officer
    local version = SchlingelInc.guildMemberVersions[sender] or nil
    local modifiedMessage = msg
    if version ~= nil then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end
    return false, modifiedMessage, sender, ...
end)

function SchlingelInc:PrintFormattedTable(tbl, indent)
    indent = indent or 0
    local indentation = string.rep("  ", indent)
    local output = "{\n"
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            output = output .. indentation .. "  " .. tostring(key) .. " = " .. SchlingelInc:PrintFormattedTable(value, indent + 1) .. ",\n"
        elseif type(value) == "string" then
            output = output .. indentation .. "  " .. tostring(key) .. " = \"" .. tostring(value) .. "\",\n"
        else
            output = output .. indentation .. "  " .. tostring(key) .. " = " .. tostring(value) .. ",\n"
        end
    end
    output = output .. indentation .. "}"
    return output
end

function SchlingelInc:RemoveRealmFromName(fullName)
    local dashPosition = string.find(fullName, "-")
    if dashPosition then
        return string.sub(fullName, 1, dashPosition - 1)
    else
        return fullName
    end
end

function SchlingelInc:CheckTargetPvP()
    local unit = "target"
    if not UnitExists(unit) then return end
    if not UnitIsPVP(unit) then return end
    local targetFaction = UnitFactionGroup(unit)
    if targetFaction == "Alliance" and UnitIsPVP(unit) and not UnitIsPlayer(unit) then
        local name = UnitName(unit) or "Unbekannt"
        SchlingelInc:ShowPvPWarning(name .. " (Allianz-NPC)")
        return
    end
    if UnitIsPlayer(unit) and UnitIsPVP(unit) then
        local name = UnitName(unit)
        local now = GetTime()
        local lastAlert = SchlingelInc.lastPvPAlert and SchlingelInc.lastPvPAlert[name] or 0
        if not SchlingelInc.lastPvPAlert then SchlingelInc.lastPvPAlert = {} end
        if (now - lastAlert) > 10 then
            SchlingelInc.lastPvPAlert[name] = now
            SchlingelInc:ShowPvPWarning(name .. " ist PvP-aktiv!")
        end
    end
end

function SchlingelInc:ShowPvPWarning(text)
    if not SchlingelInc.pvpWarningFrame then SchlingelInc:CreatePvPWarningFrame() end -- Ensure frame exists
    if not SchlingelInc.pvpWarningFrame then return end -- Still no frame, abort

    SchlingelInc.pvpWarningText:SetText("Obacht Schlingel!")
    SchlingelInc.pvpWarningName:SetText(text)
    SchlingelInc.pvpWarningFrame:SetAlpha(1)
    SchlingelInc.pvpWarningFrame:Show()
    SchlingelInc:RumbleFrame(SchlingelInc.pvpWarningFrame)
    C_Timer.After(1, function()
        if SchlingelInc.pvpWarningFrame then -- Check again in case it was destroyed
            UIFrameFadeOut(SchlingelInc.pvpWarningFrame, 1, 1, 0)
            C_Timer.After(1, function() if SchlingelInc.pvpWarningFrame then SchlingelInc.pvpWarningFrame:Hide() end end)
        end
    end)
end

function SchlingelInc:CreatePvPWarningFrame()
    if SchlingelInc.pvpWarningFrame and SchlingelInc.pvpWarningFrame:IsObjectType("Frame") then return end -- Already created
    local pvpFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    pvpFrame:SetSize(320, 110); pvpFrame:SetPoint("CENTER")
    pvpFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    pvpFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1); pvpFrame:SetBackdropColor(0, 0, 0, 0.30)
    pvpFrame:SetMovable(true); pvpFrame:EnableMouse(true); pvpFrame:RegisterForDrag("LeftButton"); pvpFrame:SetScript("OnDragStart", pvpFrame.StartMoving); pvpFrame:SetScript("OnDragStop", pvpFrame.StopMovingOrSizing)
    pvpFrame:Hide()
    local text = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge"); text:SetPoint("TOP", pvpFrame, "TOP", 0, -20); text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    local nameText = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); nameText:SetPoint("BOTTOM", pvpFrame, "BOTTOM", 0, 25); nameText:SetFont("Fonts\\FRIZQT__.TTF", 14); nameText:SetTextColor(1, 0.82, 0)
    SchlingelInc.pvpWarningFrame = pvpFrame; SchlingelInc.pvpWarningText = text; SchlingelInc.pvpWarningName = nameText
end

function SchlingelInc:RumbleFrame(frame)
    if not frame then return end
    local rumbleTime = 0.3; local interval = 0.03; local totalTicks = math.floor(rumbleTime / interval); local tick = 0
    C_Timer.NewTicker(interval, function(ticker) -- Added ticker argument to stop it
        if not frame:IsObjectType("Frame") or not frame:IsShown() then ticker:Cancel(); return end -- Stop if frame is gone
        tick = tick + 1
        local offsetX = math.random(-4, 4); local offsetY = math.random(-4, 4)
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
        if tick >= totalTicks then frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0); ticker:Cancel() end
    end, totalTicks) -- Provide max iterations to auto-cancel
end

-- Ab hier MiniMap Icon
local LDB = LibStub("LibDataBroker-1.1", true) -- Add true to suppress errors if not found
local DBIcon = LibStub("LibDBIcon-1.0", true) -- Add true

-- Datenobjekt für das Minimap Icon (OnClick wird später gesetzt)
if LDB then -- Proceed only if LDB is available
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, { -- Store it on SchlingelInc
        type = "launcher", -- Changed from "data source" to "launcher" as it launches UIs
        label = SchlingelInc.name, -- Use label instead of text for launchers
        icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga",
        -- OnClick = function... (REMOVED FROM HERE)
        OnEnter = function(selfFrame) -- LDB passes the frame the mouse is over
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9) -- Use SchlingelInc.name
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unbekannt"), 1, 1, 1)
            GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1)
            GameTooltip:AddLine("Rechtsklick: Offi-Fenster", 0.8, 0.8, 0.8) -- Added Right-click info
            GameTooltip:Show()
        end,
        OnLeave = function()
            GameTooltip:Hide()
        end
    })
else
    SchlingelInc:Print("LibDataBroker-1.1 nicht gefunden. Minimap-Icon wird nicht erstellt.")
end

-- Initialisierung des Minimap Icons
function SchlingelInc:InitMinimapIcon()
    if not DBIcon or not SchlingelInc.minimapDataObject then -- Check for SchlingelInc.minimapDataObject
        SchlingelInc:Print("LibDBIcon-1.0 oder LDB-Datenobjekt nicht gefunden. Minimap-Icon wird nicht initialisiert.")
        return
    end

    if not SchlingelInc.minimapRegistered then
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false }
        DBIcon:Register(SchlingelInc.name, SchlingelInc.minimapDataObject, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true
        SchlingelInc:Print("Minimap-Icon registriert.")
    end
end