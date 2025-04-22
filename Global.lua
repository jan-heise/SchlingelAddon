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

-- Print-Funktion
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[Schlingel Inc]|r " .. message)
end
