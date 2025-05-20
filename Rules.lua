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
function SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers(player)
    local tradePartner, _ = UnitName("NPC") -- Name des Handelspartners
    if tradePartner then
        local isInGuild = SchlingelInc:IsGuildAllowed(GetGuildInfo("NPC"))
        if not isInGuild then
            SchlingelInc:Print("Handeln mit Spielern außerhalb der Gilde ist verboten!")
            CancelTrade() -- Schließt das Handelsfenster sofort
        end
    end
end

-- Regel: Gruppen mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
    C_GuildInfo.GuildRoster()
    local guildMembers = {}
    local numTotalGuildMembers = GetNumGuildMembers()
    for i = 1, numTotalGuildMembers do
        local name, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
        if name then
            table.insert(guildMembers, SchlingelInc:RemoveRealmFromName(name))
        end
    end

    local numGroupMembers = GetNumGroupMembers()
    for i = 1, numGroupMembers do
        local memberName = UnitName("party" .. i) or UnitName("raid" .. i)
        if memberName then
            local isInGuild = tContains(guildMembers, SchlingelInc:RemoveRealmFromName(memberName))
            if not isInGuild then
                SchlingelInc:Print("Gruppierung mit Spielern außerhalb der Gilde ist verboten!")
                LeaveParty()     -- Verlasse die Gruppe
            end
        end
    end
end

-- Initialisierung der Regeln
function SchlingelInc.Rules:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MAIL_SHOW")           -- Event für Briefkasten öffnen
    frame:RegisterEvent("AUCTION_HOUSE_SHOW")  -- Event für Auktionshaus öffnen
    frame:RegisterEvent("TRADE_SHOW")          -- Event für Handelsfenster öffnen
    frame:RegisterEvent("GROUP_ROSTER_UPDATE") -- Event für Gruppenitglieder aktualisieren
    frame:RegisterEvent("RAID_ROSTER_UPDATE")  -- Event für Raidmitglieder aktualisieren

    frame:SetScript("OnEvent", function(_, event, prefix, playerName)
        if event == "MAIL_SHOW" then
            self:ProhibitMailboxUsage()
        elseif event == "AUCTION_HOUSE_SHOW" then
            self:ProhibitAuctionhouseUsage()
        elseif event == "TRADE_SHOW" then
            self:ProhibitTradeWithNonGuildMembers()
        elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
            if not SchlingelInc:IsInBattleground() then
                self:ProhibitGroupingWithNonGuildMembers()
            end
        end
    end)
end
