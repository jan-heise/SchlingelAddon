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
    -- lade alle Namen von Spielern aus der Gilde in eine Tabelle wenn diese online sind
    local guildMembers = {}
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if online then
            table.insert(guildMembers, SchlingelInc:RemoveRealmFromName(name))
        end
    end

    -- Prüfe ob die Namen in der Gruppe mit den Gildenmitgliedern übereinstimmen
    for i = 1, GetNumGroupMembers() do
        local name = UnitName("party" .. i) or UnitName("raid" .. i)
        if name then
            -- prüfe ob der Name in der guildMembers Tabelle ist
            for _, guildMember in ipairs(guildMembers) do
                if guildMember ~= SchlingelInc:RemoveRealmFromName(name) then
                    SchlingelInc:Print("Gruppen mit Spielern außerhalb der Gilde sind verboten!")
                    LeaveParty()
                    break
                end
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
    frame:RegisterEvent("RAID_ROSTER_UPDATE")  -- Event für Raidmitglieder aktualisieren
    frame:RegisterEvent("CHAT_MSG_ADDON")      -- Event für Chatnachrichten

    frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
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
        elseif event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
            --print(message) --debug
        end
    end)
end
