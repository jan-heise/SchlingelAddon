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

-- Regel: Handeln mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers()
    local tradePartner = UnitName("NPC") -- Name des Handelspartners
    if tradePartner then
        local isInGuild = SchlingelInc:IsPlayerInGuild(GetGuildInfo("NPC"))
        if not isInGuild then
            SchlingelInc:Print("Handeln mit Spielern außerhalb der Gilde ist verboten!")
            CancelTrade() -- Schließt das Handelsfenster sofort
        end
    end
end

-- Regel: Gruppen mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
    local identifiers = {
        "party1",
        "party2",
        "party3",
        "party4",
    }

    for _, id in ipairs(identifiers) do
        local party_member = UnitName(id)

        if party_member == nil then
            -- Spieler existiert nicht, weiter zur nächsten ID
        elseif UnitIsConnected(id) == false then
            -- Spieler ist offline, weiter zur nächsten ID
        else
            -- Überprüfe, ob der Spieler in einer erlaubten Gilde ist
            local isInGuild = SchlingelInc:IsPlayerInGuild(GetGuildInfo(id))
            if not isInGuild then
                -- Wenn ein Spieler nicht in der Gilde ist, starte die asynchrone Gruppenprüfung
                SchlingelInc:IsGroupInGuild()
                return -- Beende die Schleife, da die Gruppenprüfung gestartet wurde
            end
        end
    end
end

-- Initialisierung der Regeln
function SchlingelInc.Rules:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MAIL_SHOW")           -- Event für Briefkasten öffnen
    frame:RegisterEvent("AUCTION_HOUSE_SHOW")  -- Event für Auktionshaus öffnen
    frame:RegisterEvent("TRADE_SHOW")          -- Event für Handel öffnen
    frame:RegisterEvent("GROUP_ROSTER_UPDATE") -- Event für Handel öffnen

    frame:SetScript("OnEvent", function(_, event)
        if event == "MAIL_SHOW" then
            self:ProhibitMailboxUsage()
        elseif event == "AUCTION_HOUSE_SHOW" then
            self:ProhibitAuctionhouseUsage()
        elseif event == "TRADE_SHOW" then
            self:ProhibitTradeWithNonGuildMembers()
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:ProhibitGroupingWithNonGuildMembers()
        end
    end)
end
