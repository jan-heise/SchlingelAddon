-- Variable zum Speichern der letzten Nachricht
LastChatMessage = ""

-- Variable zum Speichern des letzten Gegners
LastAttackSource = ""

-- Initialisiere CharacterDeaths um einen Nil Verweis zu vermeiden
CharacterDeaths = CharacterDeaths or 0

local DeathFrame = CreateFrame("Frame")
DeathFrame:RegisterEvent("PLAYER_DEAD")
DeathFrame:RegisterEvent("PLAYER_UNGHOST")

-- Event-Handler
DeathFrame:SetScript("OnEvent", function(self, event, ...)
	-- Event für den Tod.
	if event == "PLAYER_DEAD" then
		-- Wenn der DeathCount noch nicht gesetzt wurde, setzen wir ihn auf 1.
		if CharacterDeaths == nil then
			CharacterDeaths = 1
			return -- Abbruch des Eventhandlers
		end
		-- Vorbereiten der genutzten Variablen für die GildenNachricht
		local name = UnitName("player")
		local _, rank = GetGuildInfo("player")
		local class = UnitClass("player")
		local level = UnitLevel("player")
		local sex = UnitSex("player") -- 2 = male, 3 = female
		local zone, mapID
		if IsInInstance() then
			zone = GetInstanceInfo()
		else
			mapID = C_Map.GetBestMapForUnit("player")
			zone = C_Map.GetMapInfo(mapID).name
		end

		local pronoun = "der"
		if sex == 3 then
			pronoun = "die"
		end

		-- Formatiert die Broadcast Nachricht
		local messageFormat = "%s %s %s ist mit Level %s in %s gestorben. Schande!"
		local messageFormatWithRank = "Ewiger Schlingel %s, %s %s ist mit Level %s in %s gestorben. Schande!"
		if (rank ~= nil and rank == "EwigerSchlingel") then
			messageFormat = messageFormatWithRank
		end
		local messageString = messageFormat:format(name, pronoun, class, level, zone)

		if LastAttackSource and LastAttackSource ~= "" then
			messageString = string.format("%s Gestorben an %s", messageString, LastAttackSource)
			Last_Attack_Source = nil
		end

		-- Letzte Worte
		if LastChatMessage and LastChatMessage ~= "" then
			messageString = string.format('%s. Die letzten Worte: "%s"', messageString, LastChatMessage)
		end

		local popupMessageFormat = "SCHLINGEL_DEATH:%s:%s:%s:%s"
		local popupMessageString = popupMessageFormat:format(name, class, level, zone)

		-- Send broadcast text messages to guild
		if not SchlingelInc:IsInBattleground() and not SchlingelInc:IsInRaid() then
			SendChatMessage(messageString, "GUILD")
			C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, popupMessageString, "GUILD")
			CharacterDeaths = CharacterDeaths + 1
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
	CharacterDeaths = inputValue
	SchlingelInc:Print("Tod-Counter wurde auf " .. CharacterDeaths .. " gesetzt.")
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
	local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, _, amount =
		CombatLogGetCurrentEventInfo()

	if destGUID == UnitGUID("player") then
		if event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
			-- Speichere letzte Angriffsquelle
			LastAttackSource = sourceName or "Unbekannt"
		end
	end
end)

local PopupTracker = CreateFrame("Frame")
PopupTracker:RegisterEvent("CHAT_MSG_ADDON")
PopupTracker:SetScript("OnEvent", function(self, event, prefix, msg, sender, ...)
	if (event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix and msg:find("SCHLINGEL_DEATH")) then
		local name, class, level, zone = msg:match("^SCHLINGEL_DEATH:([^:]+):([^:]+):([^:]+):([^:]+)$")
		if name and class and level and zone then
			local messageFormat = "%s der %s ist mit Level %s in %s gestorben."
			local messageString = messageFormat:format(name, class, level, zone)
			-- Zeige die Nachricht im zentralen Frame an
			SchlingelInc.DeathAnnouncement:ShowDeathMessage(messageString)
			-- Speichere den Tod im Log
			SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
			local cause = LastAttackSource or "Unbekannt"
			table.insert(SchlingelInc.DeathLogData, {
				name = name,
				class = class,
				level = tonumber(level),
				zone = zone,
				cause = cause
			})
			SchlingelInc:UpdateMiniDeathLog()
		end
	end
end)

-- -- Slash-Befehl definieren zu Deugzwecken
-- SLASH_DEATHFRAME1 = '/deathframe'
-- SlashCmdList["DEATHFRAME"] = function()
-- 	SchlingelInc.DeathAnnouncement:ShowDeathMessage("Pudidev ist mit Level 100 in Mordor gestorben!")
-- 			SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
-- 			table.insert(SchlingelInc.DeathLogData, {
-- 			name = "Pudidev",
-- 			class = "Krieger",
-- 			level = math.random(60),
-- 			zone = "Durotar",
-- 			cause = "Eber"
-- 			})
-- 			SchlingelInc:UpdateMiniDeathLog()
-- end
