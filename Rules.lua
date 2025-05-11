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
    local groupGuilds = {}
    local guildName = GetGuildInfo("player")
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "SCHLINGEL_GUILD:" .. guildName, "RAID")

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix then
            local _, _, guildName = string.find(message, "SCHLINGEL_GUILD:(.+)")
            if guildName and guildName ~= "" then
                groupGuilds[SchlingelInc:RemoveRealmFromName(sender)] = guildName
            end
        end
    end)

    C_Timer.After(2, function()
        if GetNumGroupMembers() ~= #groupGuilds then
            SchlingelInc:Print("Gruppen mit Spielern außerhalb der Gilden sind verboten!")
            LeaveParty() -- Command to leave the group
        else
            for _, guildName in pairs(groupGuilds) do
                if not SchlingelInc:IsGuildAllowed(guildName) then
                    SchlingelInc:Print("Gruppen mit Spielern außerhalb der Gilden sind verboten!")
                    LeaveParty() -- Command to leave the group
                end
            end
        end
        frame:UnregisterEvent("CHAT_MSG_ADDON")
    end)
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
