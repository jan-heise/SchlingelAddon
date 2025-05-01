-- Variable zum Speichern der letzten Nachricht
LastChatMessage = ""

-- Variable zum Speichern des letzten Gegners
LastAttackSource = ""

if not CharacterDeaths then
    CharacterDeaths = 0
end

local DeathFrame = CreateFrame("Frame")
DeathFrame:RegisterEvent("PLAYER_DEAD")
DeathFrame:RegisterEvent("PLAYER_UNGHOST")

-- Event-Handler
DeathFrame:SetScript("OnEvent", function(self, event, ...)

	-- Event für den Tod.
	if event == "PLAYER_DEAD" then
		-- Vorbereiten der genutzten Variablen für die GildenNachricht
		local name = UnitName("player")
		local _, rank = GetGuildInfo("player")
		local class = UnitClass("player")
		local level = UnitLevel("player")
		local zone, mapID
		if IsInInstance() then
			zone = GetInstanceInfo()
		else
			mapID = C_Map.GetBestMapForUnit("player")
			zone = C_Map.GetMapInfo(mapID).name
		end

		-- Formatiert die Broadcast Nachricht
		local messageFormat = "%s der %s ist mit Level %s in %s gestorben. Schande!"
		local messageFormatWithRank = "Ewiger Schlingel %s, der %s ist mit Level %s in %s gestorben. Schande!"
		if (rank ~= nil and rank == "EwigerSchlingel") then
			messageFormat = messageFormatWithRank
		end
		local messageString = messageFormat:format(name, class, level, zone)

		if LastAttackSource and LastAttackSource ~= "" then
			messageString = string.format("%s Gestorben an %s", messageString, LastAttackSource)
			Last_Attack_Source = nil
		end

		-- Letzte Worte
		if LastChatMessage and LastChatMessage ~= "" then
			messageString = string.format('%s. Die letzten Worte: "%s"', messageString, LastChatMessage)
		end

		-- Send broadcast text messages to guild and greenwall
		SendChatMessage(messageString, "GUILD")

		CharacterDeaths = CharacterDeaths + 1

	-- Event für den revive. Ist aktuell allgemein, sollte also zB auch beim rez triggern.
	else if event == "PLAYER_UNGHOST" then
		local name = UnitName("player")
		SendChatMessage(name .. " wurde wiederbelebt!", "GUILD")
	end
	end
end)

-- Slash-Befehl definieren
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
    local inputValue = tonumber(msg)

    -- Kommt keine Zahl vom User, gibt es eine Fehlermeldung plus Anleitung.
    if not inputValue then
        SchlingelInc:Print("Ungültiger Input. Benutze: /deathset <Zahl>")
        return
    end

    -- -- Eine einmalige Zuweisung soll verhindern, dass der Wert nach der initialen Zuweisung noch geändert werden kann. Zum Debuggen einfach auskommentieren.
    if CharacterDeaths ~= 0 then
        SchlingelInc:Print("Tod-Counter ist bereits gesetzt auf: " .. CharacterDeaths)
        return
    end

    CharacterDeaths = inputValue
    SchlingelInc:Print("Tod-Counter wurde initial auf " .. CharacterDeaths .. " gesetzt.")
end


-- ChatFrame und ChatHandler für letzte Worte
local ChatTrackerFrame = CreateFrame("Frame")

-- Relevante Chat-Events registrieren
ChatTrackerFrame:RegisterEvent("CHAT_MSG_SAY")
ChatTrackerFrame:RegisterEvent("CHAT_MSG_GUILD")
ChatTrackerFrame:RegisterEvent("CHAT_MSG_PARTY")
ChatTrackerFrame:RegisterEvent("CHAT_MSG_RAID")

-- Eigener Spielername (inkl. Realm bei Bedarf)
local playerName = UnitName("player")

ChatTrackerFrame:SetScript("OnEvent", function(self, event, msg, sender, ...)
    -- Nur speichern, wenn der Sender der eigene Spieler ist
    if sender == playerName or sender:match("^" .. playerName .. "%-") then
        LastChatMessage = msg
    end
end)



-- CombatFrame für den letzten Angreifer
local CombatLogFrame = CreateFrame("Frame")
CombatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

CombatLogFrame:SetScript("OnEvent", function()
    local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, _, amount = CombatLogGetCurrentEventInfo()

    if destGUID == UnitGUID("player") then
        if event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
            -- Speichere letzte Angriffsquelle
            LastAttackSource = sourceName or "Unbekannt"
        end
    end
end)
