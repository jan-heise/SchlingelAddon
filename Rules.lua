-- Globale Tabelle für Regeln
SchlingelInc.Rules = {}

-- Regel: Briefkasten-Nutzung verbieten
function SchlingelInc.Rules.ProhibitMailboxUsage()
    SchlingelInc:Print("Die Nutzung des Briefkastens ist verboten!")
    CloseMail() -- Schließt den Briefkasten
end

-- Initialisierung der Regeln
function SchlingelInc.Rules:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MAIL_SHOW") -- Event für Briefkasten öffnen

    frame:SetScript("OnEvent", function(_, event)
        if event == "MAIL_SHOW" then
            SchlingelInc.Rules.ProhibitMailboxUsage()
        end
    end)
end
