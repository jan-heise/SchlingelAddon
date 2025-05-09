-- Globale Tabelle für das Addon
SchlingelInc = {}

-- Addon-Name
SchlingelInc.name = "SchlingelInc"

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

-- Liste der für das OffiInterface zugelassenen Rollen
SchlingelInc.AllowedRanks = { 
    "Lootwichtel", 
    "Oberlootwichtel"
}

-- Initialisierung von Spielzeit-Variablen (derzeit nicht weiter verwendet im Snippet).
SchlingelInc.GameTimeTotal = 0
SchlingelInc.GameTimePerLevel = 0

-- Global um zu chekcen ob man den OffiFrame sehen darf.
SchlingelInc.isAllowed = false

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
    -- Definition eines Popup-Dialogs für die Warnung, falls GreenWall fehlt.
    StaticPopupDialogs["SCHLINGEL_GREENWALL_MISSING"] = {
        text = "Du hast Greenwall nicht aktiv.\nBitte aktiviere oder installiere es!",
        button1 = "OK",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- Startet eine Überprüfung nach 30 Sekunden.
    C_Timer.After(30, function()
        local numAddons = GetNumAddOns()
        local greenwall_found = false

        -- Durchläuft alle installierten Addons.
        for i = 1, numAddons do
            local name, _, _, enabled = GetAddOnInfo(i)
            -- Prüft auf veraltete Addons ("HardcoreUnlocked" oder "SchlingelAddon").
            if (name == "HardcoreUnlocked" and IsAddOnLoaded("HardcoreUnlocked")) or (name == "SchlingelAddon" and IsAddOnLoaded("SchlingelAddon")) then
                SchlingelInc:Print(
                    "|cffff0000Warnung: Du hast das veraltete Addon aktiv. Bitte entferne es, da es zu Problemen mit SchlingelInc führt!|r")
                StaticPopup_Show("SCHLINGEL_HARDCOREUNLOCKED_WARNING") -- Zeigt das Popup an.
            end

            -- Prüft, ob GreenWall geladen und aktiv ist.
            if name == "GreenWall" and IsAddOnLoaded("GreenWall") then
                greenwall_found = true
            end
        end

        -- Startet eine weitere Überprüfung nach 5 Sekunden (nach der ersten Prüfung).
        C_Timer.After(5, function()
            -- Wenn GreenWall nicht gefunden wurde, wird eine Warnung angezeigt.
            if not greenwall_found then
                SchlingelInc:Print(
                    "|cffff0000Warnung: Du hast Greenwall nicht aktiv. Bitte aktiviere oder installiere es!|r")
                StaticPopup_Show("SCHLINGEL_GREENWALL_MISSING") -- Zeigt das Popup an.
            end
        end)
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

    -- Nur relevant, wenn Spieler in einem Schlachtfeld UND Level 55 oder höher ist.
    if isInBattleground and level >= 55 then
        isInAllowedBattleground = true
    end
    return isInAllowedBattleground
end

-- Überprüft, ob ein GEGEBENER Gildenname zu den erlaubten Gilden gehört.
-- Hinweis: Diese Funktion ist in ihrer Implementierung identisch zu IsGuildAllowed.
-- Sie wird nützlich, wenn man explizit prüfen will, ob der Gildenname des Spielers erlaubt ist.
function SchlingelInc:IsPlayerInGuild(guildName)
    if not guildName then
        return false -- Kein Gildenname angegeben.
    end
    for _, allowedGuild in ipairs(SchlingelInc.allowedGuilds) do
        if guildName == allowedGuild then
            return true -- Gildenname ist in der Liste der erlaubten Gilden.
        end
    end
    return false -- Gildenname nicht in der Liste.
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
    local highestSeenVersion = SchlingelInc.version -- Startet mit der eigenen Version als höchster bekannter.
    local versionFrame = CreateFrame("Frame")
    versionFrame:RegisterEvent("CHAT_MSG_ADDON") -- Lauscht auf Addon-Nachrichten.
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
    local a1, a2, a3 = parse(v1) -- Parsed v1.
    local b1, b2, b3 = parse(v2) -- Parsed v2.

    if a1 ~= b1 then return a1 - b1 end -- Vergleiche Major-Version.
    if a2 ~= b2 then return a2 - b2 end -- Vergleiche Minor-Version.
    return a3 - b3 -- Vergleiche Patch-Version.
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
    local modifiedMessage = msg -- Standardmäßig die Originalnachricht.

    -- Wenn eine Version für den Sender bekannt ist, füge sie der Nachricht hinzu.
    if version ~= nil then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end
    -- 'false' bedeutet, die Nachricht wird nicht unterdrückt, sondern weiterverarbeitet (mit ggf. modifizierter Nachricht).
    return false, modifiedMessage, sender, ...
end)

-- Gibt eine Tabelle formatiert (mit Einrückungen) als String zurück. Nützlich für Debugging.
function SchlingelInc:PrintFormattedTable(tbl, indent)
    indent = indent or 0 -- Standard-Einrückung ist 0.
    local indentation = string.rep("  ", indent) -- Erzeugt den Einrückungsstring.
    local output = "{\n"
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- Rekursiver Aufruf für verschachtelte Tabellen.
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

-- Entfernt den Realm-Namen von einem vollständigen Spielernamen (z.B. "Spieler-Realm" -> "Spieler").
function SchlingelInc:RemoveRealmFromName(fullName)
    local dashPosition = string.find(fullName, "-") -- Findet die Position des Bindestrichs.
    if dashPosition then
        return string.sub(fullName, 1, dashPosition - 1) -- Gibt den Teil vor dem Bindestrich zurück.
    else
        return fullName -- Kein Bindestrich gefunden, gibt den vollen Namen zurück.
    end
end

-- Überprüft das aktuelle Ziel des Spielers auf PvP-Relevanz.
function SchlingelInc:CheckTargetPvP()
    local unit = "target" -- Das Ziel des Spielers.
    if not UnitExists(unit) then return end -- Kein Ziel vorhanden.
    if not UnitIsPVP(unit) then return end -- Ziel ist nicht PvP-markiert.

    local targetFaction = UnitFactionGroup(unit) -- Fraktion des Ziels.
    -- Warnung bei feindlichen Allianz-NPCs, die PvP-markiert sind.
    if targetFaction == "Alliance" and UnitIsPVP(unit) and not UnitIsPlayer(unit) then
        local name = UnitName(unit) or "Unbekannt"
        SchlingelInc:ShowPvPWarning(name .. " (Allianz-NPC)")
        return
    end

    -- Warnung bei feindlichen Spielern, die PvP-markiert sind.
    if UnitIsPlayer(unit) and UnitIsPVP(unit) then
        local name = UnitName(unit)
        local now = GetTime() -- Aktuelle Spielzeit.
        -- Holt die Zeit der letzten Warnung für diesen Spieler, Standard 0.
        local lastAlert = SchlingelInc.lastPvPAlert and SchlingelInc.lastPvPAlert[name] or 0
        if not SchlingelInc.lastPvPAlert then SchlingelInc.lastPvPAlert = {} end -- Sicherstellen, dass Tabelle existiert.

        -- Nur warnen, wenn die letzte Warnung für diesen Spieler mehr als 10 Sekunden her ist.
        if (now - lastAlert) > 10 then
            SchlingelInc.lastPvPAlert[name] = now -- Aktualisiert den Zeitpunkt der letzten Warnung.
            SchlingelInc:ShowPvPWarning(name .. " ist PvP-aktiv!")
        end
    end
end

-- Zeigt ein PvP-Warnfenster an.
function SchlingelInc:ShowPvPWarning(text)
    -- Erstellt das Warnfenster, falls es noch nicht existiert.
    if not SchlingelInc.pvpWarningFrame then SchlingelInc:CreatePvPWarningFrame() end
    -- Bricht ab, wenn das Frame immer noch nicht existiert (Sicherheitsprüfung).
    if not SchlingelInc.pvpWarningFrame then return end

    SchlingelInc.pvpWarningText:SetText("Obacht Schlingel!") -- Setzt den Haupttitel der Warnung.
    SchlingelInc.pvpWarningName:SetText(text) -- Setzt den spezifischen Warntext (z.B. Spielername).
    SchlingelInc.pvpWarningFrame:SetAlpha(1) -- Macht das Fenster vollständig sichtbar.
    SchlingelInc.pvpWarningFrame:Show() -- Zeigt das Fenster an.
    SchlingelInc:RumbleFrame(SchlingelInc.pvpWarningFrame) -- Startet den "Rumble"-Effekt.

    -- Blendet das Fenster nach 1 Sekunde langsam aus.
    C_Timer.After(1, function()
        if SchlingelInc.pvpWarningFrame then
            UIFrameFadeOut(SchlingelInc.pvpWarningFrame, 1, 1, 0) -- Fade-Out über 1 Sekunde.
            -- Versteckt das Frame komplett nach dem Ausblenden.
            C_Timer.After(1, function()
                if SchlingelInc.pvpWarningFrame then SchlingelInc.pvpWarningFrame:Hide() end
            end)
        end
    end)
end

-- Erstellt das UI-Frame für die PvP-Warnung, falls es noch nicht existiert.
function SchlingelInc:CreatePvPWarningFrame()
    -- Bricht ab, wenn das Frame bereits existiert und ein gültiges Frame-Objekt ist.
    if SchlingelInc.pvpWarningFrame and SchlingelInc.pvpWarningFrame:IsObjectType("Frame") then return end

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
    pvpFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1) -- Randfarbe (rosa).
    pvpFrame:SetBackdropColor(0, 0, 0, 0.30) -- Hintergrundfarbe (leicht transparent schwarz).
    pvpFrame:SetMovable(true) -- Erlaubt das Verschieben des Fensters.
    pvpFrame:EnableMouse(true) -- Aktiviert Mauseingaben für das Fenster.
    pvpFrame:RegisterForDrag("LeftButton") -- Registriert Linksklick zum Ziehen.
    pvpFrame:SetScript("OnDragStart", pvpFrame.StartMoving) -- Funktion bei Beginn des Ziehens.
    pvpFrame:SetScript("OnDragStop", pvpFrame.StopMovingOrSizing) -- Funktion bei Ende des Ziehens.
    pvpFrame:Hide() -- Standardmäßig versteckt.

    -- Erstellt den Text für den Titel.
    local text = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    text:SetPoint("TOP", pvpFrame, "TOP", 0, -20)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Erstellt den Text für den Namen/die spezifische Warnung.
    local nameText = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    nameText:SetPoint("BOTTOM", pvpFrame, "BOTTOM", 0, 25)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    nameText:SetTextColor(1, 0.82, 0) -- Goldene Farbe.

    -- Speichert die Referenzen zum Frame und den Textfeldern global im Addon.
    SchlingelInc.pvpWarningFrame = pvpFrame
    SchlingelInc.pvpWarningText = text
    SchlingelInc.pvpWarningName = nameText
end

-- Lässt ein UI-Frame für kurze Zeit "zittern" (Rumble-Effekt).
function SchlingelInc:RumbleFrame(frame)
    if not frame then return end -- Bricht ab, wenn kein Frame übergeben wurde.

    local rumbleTime = 0.3 -- Gesamtdauer des Zitterns in Sekunden.
    local interval = 0.03 -- Intervall zwischen den Bewegungen in Sekunden.
    local totalTicks = math.floor(rumbleTime / interval) -- Gesamtzahl der Bewegungen.
    local tick = 0 -- Zähler für aktuelle Bewegung.

    -- Startet einen Timer, der wiederholt ausgeführt wird.
    C_Timer.NewTicker(interval, function(ticker)
        -- Bricht ab, wenn das Frame ungültig wird oder nicht mehr sichtbar ist.
        if not frame:IsObjectType("Frame") or not frame:IsShown() then
            ticker:Cancel()
            return
        end

        tick = tick + 1
        local offsetX = math.random(-4, 4) -- Zufälliger X-Versatz.
        local offsetY = math.random(-4, 4) -- Zufälliger Y-Versatz.
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY) -- Bewegt das Frame.

        -- Wenn alle Bewegungen ausgeführt wurden:
        if tick >= totalTicks then
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Setzt das Frame auf die ursprüngliche Mittelposition zurück.
            ticker:Cancel() -- Stoppt den Timer.
        end
    end, totalTicks) -- Der Timer stoppt automatisch nach 'totalTicks' Ausführungen.
end

-- Ab hier MiniMap Icon
-- Lädt benötigte Bibliotheken für das Minimap-Icon. 'true' unterdrückt Fehler, falls nicht gefunden.
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Datenobjekt für das Minimap Icon (OnClick wird später gesetzt, falls benötigt).
if LDB then -- Fährt nur fort, wenn LibDataBroker verfügbar ist.
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, {
        type = "launcher", -- Typ des LDB-Objekts: Startet eine UI oder Funktion.
        label = SchlingelInc.name, -- Text neben dem Icon (oft nur im LDB Display Addon sichtbar).
        icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga", -- Pfad zum Icon.
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if SchlingelInc.ToggleInfoWindow then
                    SchlingelInc:ToggleInfoWindow()
                else
                    SchlingelInc:Print(SchlingelInc.name .. ": ToggleInfoWindow ist nicht verfügbar.")
                end
            elseif button == "RightButton" then
                    if SchlingelInc.isAllowed then
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
        OnEnter = function(selfFrame) -- Wird ausgeführt, wenn die Maus über das Icon fährt.
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT") -- Positioniert den Tooltip rechts vom Icon.
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9) -- Addon-Name im Tooltip.
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unbekannt"), 1, 1, 1) -- Version im Tooltip.
            GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1) -- Hinweis für Linksklick.
            if SchlingelInc.isAllowed then
                GameTooltip:AddLine("Rechtsklick: Offi-Fenster", 0.8, 0.8, 0.8) -- Hinweis für Rechtsklick.
            end
            GameTooltip:Show() -- Zeigt den Tooltip an.
        end,
        OnLeave = function() -- Wird ausgeführt, wenn die Maus das Icon verlässt.
            GameTooltip:Hide() -- Versteckt den Tooltip.
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

function SchlingelInc:CheckForOffieRights()
    -- Prüfe nach Gildenrolle, die das Interface sehen darf
    local _, rankName = GetGuildInfo("player")
    SchlingelInc.isAllowed = false
    for _, rank in ipairs(SchlingelInc.AllowedRanks) do
        if rank == rankName then
            SchlingelInc.isAllowed = true
            break
        end
    end
end