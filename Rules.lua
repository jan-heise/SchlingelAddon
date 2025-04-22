-- Globale Tabelle für Regeln
SchlingelInc.Rules = {}

-- Regel: Briefkasten-Nutzung verbieten
function SchlingelInc.Rules.ProhibitMailboxUsage()
    SchlingelInc:Print("Die Nutzung des Briefkastens ist verboten!")
    CloseMail() -- Schließt den Briefkasten
end

-- Regel: Auktionshaus-Nutzung verbieten
function SchlingelInc.Rules.ProhibitAuctionhouseUsage()
    SchlingelInc:Print("Die Nutzung des Auktionshauses ist verboten!")
    CloseAuctionHouse() -- Schließt das Auktionshaus
end

-- Initialisierung der Regeln
function SchlingelInc.Rules:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MAIL_SHOW")          -- Event für Briefkasten öffnen
    frame:RegisterEvent("AUCTION_HOUSE_SHOW") -- Event für Auktionshaus öffnen

    frame:SetScript("OnEvent", function(_, event)
        if event == "MAIL_SHOW" then
            SchlingelInc.Rules.ProhibitMailboxUsage()
        elseif event == "AUCTION_HOUSE_SHOW" then
            SchlingelInc.Rules.ProhibitAuctionhouseUsage()
        end
    end)
end
