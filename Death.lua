if not CharacterDeaths then
    CharacterDeaths = 0
end

local DeathFrame = CreateFrame("Frame")
DeathFrame:RegisterEvent("PLAYER_DEAD")

-- Event-Handler
DeathFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_DEAD" then
        
	-- Vorbereiten der genutzten Variablen für die GildenNachricht
	local name = UnitName("player")
	local _, rank = GetGuildInfo("player")
	local _, _, classID = UnitClass("player")
	local class = CLASSES[classID]
	local level = UnitLevel("player")
	local zone, mapID
	if IsInInstance() then
		zone = GetInstanceInfo()
	else
		mapID = C_Map.GetBestMapForUnit("player")
		zone = C_Map.GetMapInfo(mapID).name
	end

	-- Formatiert die Broadcast Nachricht
    local messageFormat = "%s ist mit Level %d in %s gestorben. Schande!"
	local messageFormatWithRank = "Ewiger Schlingel %s ist mit Level %d in %s gestorben. Schande!"
	if (rank ~= nil and rank == "EwigerSchlingel") then
		messageFormat = messageFormatWithRank
	end
	local messageString = messageFormat:format(name, level, zone)
	if not (Last_Attack_Source == nil) then
		messageString = string.format("%s Gestorben an %s", messageString, Last_Attack_Source)
		Last_Attack_Source = nil
	end

	-- Letzte Worte
	if not (recent_msg["text"] == nil) then
		messageString = string.format('%s. Die letzten Worte: "%s"', messageString, recent_msg["text"])
	end

	-- -- Send broadcast text messages to guild and greenwall
	-- selfDeathAlert(DeathLog_Last_Attack_Source)
	-- selfDeathAlertLastWords(recent_msg["text"])

	-- SendChatMessage(messageString, "GUILD")

    CharacterDeaths = CharacterDeaths + 1
	SchlingelInc:Print(messageString)
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

    -- Eine einmalige Zuweisung soll verhindern, dass der Wert nach der initialen Zuweisung noch geändert werden kann.
    if CharacterDeaths ~= nil then
        SchlingelInc:Print("Tod-Counter ist bereits gesetzt auf: " .. CharacterDeaths)
        return
    end

    CharacterDeaths = inputValue
    SchlingelInc:Print("Tod-Counter wurde initial auf " .. CharacterDeaths .. " gesetzt.")
end