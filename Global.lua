-- Globale Tabelle für das Addon
SchlingelInc = {}

-- Addon-Name
SchlingelInc.name = "SchlingelInc"

-- Gildenmitglieder
SchlingelInc.guildMembers = {}

-- Discord Link
SchlingelInc.discordLink = "https://discord.gg/KXkyUZW"

-- Chat-Nachrichten-Prefix
-- Dieser Prefix wird verwendet, um Addon-interne Nachrichten zu identifizieren.
SchlingelInc.prefix = "SchlingelInc"

-- ColorCode für den Chat-Text
-- Bestimmt die Farbe, in der Addon-Nachrichten im Chat angezeigt werden.
SchlingelInc.colorCode = "|cFFF48CBA"

-- Version aus der TOC-Datei
-- Lädt die Version des Addons aus der .toc-Datei. Falls nicht vorhanden, wird "Unbekannt" verwendet.
SchlingelInc.version = GetAddOnMetadata("SchlingelInc", "Version") or "Unbekannt"

-- Liste der Gilden, für die bestimmte Addon-Funktionen aktiv sind.
SchlingelInc.allowedGuilds = {
    "Schlingel Inc",
    "Schlingel IInc"
}

-- Initialisierung von Spielzeit-Variablen (derzeit nicht weiter verwendet im Snippet).
SchlingelInc.GameTimeTotal = 0
SchlingelInc.GameTimePerLevel = 0

function SchlingelInc:CountTable(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function SchlingelInc:UpdateGuildMembers()
    -- lade alle Namen von Spielern aus der Gilde in eine Tabelle wenn diese online sind
    local guild_members = {}
    C_GuildInfo.GuildRoster()
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            -- Falls der Name einen Realm enthält (z.B. "Spielername-Realm"), nur den Spielernamen extrahieren
            local simple_name = strsplit("-", name)
            guild_members[simple_name] = true
        end
    end

    SchlingelInc.guildMembers = guild_members
    local found = false
    for _, guildMember in ipairs(SchlingelInc.guildMembers) do
        print(guildMember) -- debug
        if guildMember == SchlingelInc:RemoveRealmFromName(UnitName("player")) then
            print("found") -- debug
            found = true
            break
        end
    end
    print("GuildRoster updated") -- debug
end

-- Überprüft Abhängigkeiten und warnt bei Problemen.
function SchlingelInc:CheckDependencies()
    -- Definition eines Popup-Dialogs für die Warnung vor veralteten Addons.
    StaticPopupDialogs["SCHLINGEL_HARDCOREUNLOCKED_WARNING"] = {
        text = "Du hast das veraltete Addon aktiv.\nBitte entferne es, da es zu Problemen mit SchlingelInc führt!",
        button1 = "OK",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- Startet eine Überprüfung nach 30 Sekunden.
    C_Timer.After(30, function()
        local numAddons = GetNumAddOns()

        -- Durchläuft alle installierten Addons.
        for i = 1, numAddons do
            local name, _, _, enabled = GetAddOnInfo(i)
            -- Prüft auf veraltete Addons ("HardcoreUnlocked" oder "SchlingelAddon").
            if (name == "HardcoreUnlocked" and IsAddOnLoaded("HardcoreUnlocked")) or (name == "SchlingelAddon" and IsAddOnLoaded("SchlingelAddon")) then
                SchlingelInc:Print(
                    "|cffff0000Warnung: Du hast das veraltete Addon aktiv. Bitte entferne es, da es zu Problemen mit SchlingelInc führt!|r")
                StaticPopup_Show("SCHLINGEL_HARDCOREUNLOCKED_WARNING") -- Zeigt das Popup an.
            end
        end
    end)
end

-- Überprüft, ob ein Gildenname in der Liste der erlaubten Gilden ist.
function SchlingelInc:IsGuildAllowed(guildName)
    for _, allowedGuild in ipairs(SchlingelInc.allowedGuilds) do
        if guildName == allowedGuild then
            return true -- Gilde ist erlaubt.
        end
    end
    return false -- Gilde ist nicht erlaubt.
end

-- Speichert den Zeitpunkt der letzten PvP-Warnung für jeden Spieler.
SchlingelInc.lastPvPAlert = {}

-- Erstellt einen unsichtbaren Frame, um auf CHAT_MSG_ADDON Events zu lauschen.
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON") -- Registriert das Event für Addon-Nachrichten.

-- Erstellt einen unsichtbaren Frame, um auf PLAYER_TARGET_CHANGED Events zu lauschen.
local pvpFrame = CreateFrame("Frame")
pvpFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Registriert das Event für Zielwechsel.

-- Gibt eine formatierte Nachricht im Chat aus.
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

-- Überprüft, ob sich der Spieler in einem relevanten Schlachtfeld befindet.
function SchlingelInc:IsInBattleground()
    local isInBattleground = false
    local level = UnitLevel("player")
    local isInAllowedBattleground = false

    -- Durchläuft alle möglichen Schlachtfeld-IDs.
    for i = 1, GetMaxBattlefieldID() do
        local battleFieldStatus = GetBattlefieldStatus(i)
        if battleFieldStatus == "active" then
            isInBattleground = true -- Spieler ist in irgendeinem Schlachtfeld.
            break
        end
    end

    -- Nur relevant, wenn Spieler in einem Schlachtfeld UND Level 60 oder höher ist.
    if isInBattleground and level >= 60 then
        isInAllowedBattleground = true
    end
    return isInAllowedBattleground
end

-- Event-Handler für den 'frame' (lauscht auf CHAT_MSG_ADDON).
frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
    -- Verarbeitet nur Addon-Nachrichten mit dem korrekten Prefix.
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        -- Wenn eine Anfrage nach dem Gildennamen kommt ("GUILD_NAME_REQUEST").
        if message == "GUILD_NAME_REQUEST" then
            local guildName = GetGuildInfo("player") -- Holt den Gildennamen des Spielers.
            if guildName then
                -- Sendet den Gildennamen als Antwort im RAID-Channel (als Addon-Nachricht).
                C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "GUILD_NAME_RESPONSE:" .. guildName, "RAID")
            end
        end
    end
end)

-- Event-Handler für den 'pvpFrame' (lauscht auf PLAYER_TARGET_CHANGED).
pvpFrame:SetScript("OnEvent", function()
    -- Führt die PvP-Zielüberprüfung nur aus, wenn der Spieler NICHT in einem Schlachtfeld ist.
    if not SchlingelInc:IsInBattleground() then
        SchlingelInc:CheckTargetPvP()
    end
end)

-- Überprüft die Addon-Versionen anderer Spieler in der Gilde.
function SchlingelInc:CheckAddonVersion()
    local highestSeenVersion = SchlingelInc
        .version                                               -- Startet mit der eigenen Version als höchster bekannter.
    local versionFrame = CreateFrame("Frame")
    versionFrame:RegisterEvent("CHAT_MSG_ADDON")               -- Lauscht auf Addon-Nachrichten.
    C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix) -- Registriert den Prefix für eingehende Nachrichten.

    versionFrame:SetScript("OnEvent", function(_, event, msgPrefix, message, _, sender)
        if event == "CHAT_MSG_ADDON" and msgPrefix == SchlingelInc.prefix then
            -- Extrahiert die Versionsnummer aus der Nachricht (Format: "VERSION:1.2.3").
            local receivedVersion = message:match("^VERSION:(.+)$")
            if receivedVersion then
                -- Vergleicht die empfangene Version mit der bisher höchsten gesehenen Version.
                if SchlingelInc:CompareVersions(receivedVersion, highestSeenVersion) > 0 then
                    highestSeenVersion = receivedVersion -- Aktualisiert die höchste gesehene Version.
                    SchlingelInc:Print("Eine neuere Addon-Version wurde entdeckt: " ..
                        highestSeenVersion .. ". Bitte aktualisiere dein Addon!")
                end
            end
        end
    end)

    -- Wenn der Spieler in einer Gilde ist, sendet er seine eigene Version an die Gilde.
    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end
end

-- Vergleicht zwei Versionsnummern (z.B. "1.2.3" mit "1.3.0").
-- Gibt >0 zurück, wenn v1 > v2; <0 wenn v1 < v2; 0 wenn v1 == v2.
function SchlingelInc:CompareVersions(v1, v2)
    -- Hilfsfunktion, um einen Versionsstring in Major, Minor, Patch Zahlen zu zerlegen.
    local function parse(v)
        local major, minor, patch = string.match(v, "(%d+)%.(%d+)%.?(%d*)")
        return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
    end
    local a1, a2, a3 = parse(v1)        -- Parsed v1.
    local b1, b2, b3 = parse(v2)        -- Parsed v2.

    if a1 ~= b1 then return a1 - b1 end -- Vergleiche Major-Version.
    if a2 ~= b2 then return a2 - b2 end -- Vergleiche Minor-Version.
    return a3 - b3                      -- Vergleiche Patch-Version.
end

-- Speichert die originale SendChatMessage Funktion, um sie später aufrufen zu können.
local originalSendChatMessage = SendChatMessage
-- Überschreibt die globale SendChatMessage Funktion (Hooking).
function SendChatMessage(msg, chatType, language, channel)
    -- Wenn eine Nachricht in den Gildenchat gesendet wird...
    if chatType == "GUILD" then
        -- ...sende zusätzlich die eigene Addon-Version als Addon-Nachricht an die Gilde.
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
    end
    -- Ruft die ursprüngliche SendChatMessage Funktion auf, damit die Nachricht normal gesendet wird.
    originalSendChatMessage(msg, chatType, language, channel)
end

-- Speichert die Addon-Versionen von Gildenmitgliedern (Sendername -> Version).
SchlingelInc.guildMemberVersions = {}

-- Erstellt einen Frame, um Addon-Nachrichten zu empfangen (speziell für Versionen).
local addonMessageFrame = CreateFrame("Frame")
addonMessageFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix) -- Wichtig, um Nachrichten zu empfangen.

-- Event-Handler für 'addonMessageFrame'.
addonMessageFrame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
        -- Extrahiert die Version aus der Nachricht.
        local receivedVersion = message:match("^VERSION:(.+)$")
        if receivedVersion then
            -- Speichert die Version des Senders.
            SchlingelInc.guildMemberVersions[sender] = receivedVersion
        end
    end
end)

-- Erstellt einen Frame, um Gilden-Chat-Nachrichten abzufangen (obwohl nicht direkt verwendet, da ChatFrame_AddMessageEventFilter genutzt wird).
local guildChatFrame = CreateFrame("Frame")
guildChatFrame:RegisterEvent("CHAT_MSG_GUILD") -- Registriert das Event für Gilden-Chat.

-- Fügt einen Filter für Gilden-Chat-Nachrichten hinzu.
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(self, event, msg, sender, ...)
    -- Funktion wird nur ausgeführt, wenn der Spieler Gildenmitglieder einladen darf (eine Art Berechtigungsprüfung).
    if not CanGuildInvite() then
        return false, msg, sender, ... -- Nachricht unverändert durchlassen.
    end

    local version = SchlingelInc.guildMemberVersions[sender] or nil -- Holt die gespeicherte Version des Senders.
    local modifiedMessage = msg                                     -- Standardmäßig die Originalnachricht.

    -- Wenn eine Version für den Sender bekannt ist, füge sie der Nachricht hinzu.
    if version ~= nil then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end
    -- 'false' bedeutet, die Nachricht wird nicht unterdrückt, sondern weiterverarbeitet (mit ggf. modifizierter Nachricht).
    return false, modifiedMessage, sender, ...
end)

-- Gibt eine Tabelle formatiert (mit Einrückungen) als String zurück. Nützlich für Debugging.
function SchlingelInc:PrintFormattedTable(tbl, indent)
    indent = indent or 0                         -- Standard-Einrückung ist 0.
    local indentation = string.rep("  ", indent) -- Erzeugt den Einrückungsstring.
    local output = "{\n"
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- Rekursiver Aufruf für verschachtelte Tabellen.
            output = output ..
                indentation ..
                "  " .. tostring(key) .. " = " .. SchlingelInc:PrintFormattedTable(value, indent + 1) .. ",\n"
        elseif type(value) == "string" then
            output = output .. indentation .. "  " .. tostring(key) .. " = \"" .. tostring(value) .. "\",\n"
        else
            output = output .. indentation .. "  " .. tostring(key) .. " = " .. tostring(value) .. ",\n"
        end
    end
    output = output .. indentation .. "}"
    return output
end

-- Entfernt den Realm-Namen von einem vollständigen Spielernamen (z.B. "Spieler-Realm" -> "Spieler").
function SchlingelInc:RemoveRealmFromName(fullName)
    local dashPosition = string.find(fullName, "-")      -- Findet die Position des Bindestrichs.
    if dashPosition then
        return string.sub(fullName, 1, dashPosition - 1) -- Gibt den Teil vor dem Bindestrich zurück.
    else
        return fullName                                  -- Kein Bindestrich gefunden, gibt den vollen Namen zurück.
    end
end

-- Ab hier MiniMap Icon
-- Lädt benötigte Bibliotheken für das Minimap-Icon. 'true' unterdrückt Fehler, falls nicht gefunden.
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Datenobjekt für das Minimap Icon (OnClick wird später gesetzt, falls benötigt).
if LDB then                                                                -- Fährt nur fort, wenn LibDataBroker verfügbar ist.
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, {
        type = "launcher",                                                 -- Typ des LDB-Objekts: Startet eine UI oder Funktion.
        label = SchlingelInc.name,                                         -- Text neben dem Icon (oft nur im LDB Display Addon sichtbar).
        icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga", -- Pfad zum Icon.
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if SchlingelInc.ToggleInfoWindow then
                    SchlingelInc:ToggleInfoWindow()
                else
                    SchlingelInc:Print(SchlingelInc.name .. ": ToggleInfoWindow ist nicht verfügbar.")
                end
            elseif button == "RightButton" then
                if CanGuildInvite() then
                    if SchlingelInc.ToggleOffiWindow then
                        SchlingelInc:ToggleOffiWindow()
                    else
                        SchlingelInc:Print(SchlingelInc.name .. ": ToggleOffiWindow ist nicht verfügbar.")
                    end
                else
                    return
                end
            end
        end,

        -- OnClick = function... (WURDE HIER ENTFERNT, kann später hinzugefügt werden)
        OnEnter = function(selfFrame)                                                          -- Wird ausgeführt, wenn die Maus über das Icon fährt.
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")                                    -- Positioniert den Tooltip rechts vom Icon.
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9)                                -- Addon-Name im Tooltip.
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unbekannt"), 1, 1, 1) -- Version im Tooltip.
            GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1)                          -- Hinweis für Linksklick.
            if CanGuildInvite() then
                GameTooltip:AddLine("Rechtsklick: Offi-Fenster", 0.8, 0.8, 0.8)                -- Hinweis für Rechtsklick.
            end
            GameTooltip:Show()                                                                 -- Zeigt den Tooltip an.
        end,
        OnLeave = function()                                                                   -- Wird ausgeführt, wenn die Maus das Icon verlässt.
            GameTooltip:Hide()                                                                 -- Versteckt den Tooltip.
        end
    })
else
    -- Gibt eine Meldung aus, falls LibDataBroker nicht gefunden wurde.
    SchlingelInc:Print("LibDataBroker-1.1 nicht gefunden. Minimap-Icon wird nicht erstellt.")
end

-- Initialisierung des Minimap Icons.
function SchlingelInc:InitMinimapIcon()
    -- Bricht ab, falls LibDBIcon oder das LDB Datenobjekt nicht vorhanden sind.
    if not DBIcon or not SchlingelInc.minimapDataObject then
        SchlingelInc:Print("LibDBIcon-1.0 oder LDB-Datenobjekt nicht gefunden. Minimap-Icon wird nicht initialisiert.")
        return
    end

    -- Registriert das Icon nur einmal.
    if not SchlingelInc.minimapRegistered then
        -- Initialisiert die Datenbank für Minimap-Einstellungen, falls nicht vorhanden.
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false } -- Standardmäßig nicht versteckt.

        -- Registriert das Icon bei LibDBIcon.
        DBIcon:Register(SchlingelInc.name, SchlingelInc.minimapDataObject, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true -- Markiert das Icon als registriert.
        SchlingelInc:Print("Minimap-Icon registriert.")
    end
end
