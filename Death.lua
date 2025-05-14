-- Variable zum Speichern der letzten Nachricht
LastChatMessage = ""

-- Variable zum Speichern des letzten Gegners
LastAttackSource = ""

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

		local popupMessageFormat = "SCHLINGEL_DEATH:%s:%s:%s:%s"
		local popupMessageString = popupMessageFormat:format(name, class, level, zone)

		-- Send broadcast text messages to guild
		if not SchlingelInc:IsInBattleground() then
			SendChatMessage(messageString, "GUILD")
			C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, popupMessageString, "GUILD")
		end

		-- Wenn der DeathCount noch nicht gesetzt wurde, setzen wir ihn auf 1.
		if CharacterDeaths == nil then
			CharacterDeaths = 1
			return -- Abbruch des Eventhandlers
		end

		CharacterDeaths = CharacterDeaths + 1

		-- Event für den revive. Ist aktuell allgemein, sollte also zB auch beim rez triggern.
	else
		if event == "PLAYER_UNGHOST" then
			local name = UnitName("player")
			if not SchlingelInc:IsInBattleground() then
				SendChatMessage(name .. " wurde wiederbelebt!", "GUILD")
			end
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

	if CharacterDeaths >= 0 and inputValue == 0 then
		SchlingelInc:Print("Ein nachträgliches ändern auf 0 ist nicht erlaubt! SCHANDE!")
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

-- Frame für die zentrale Bildschirmnachricht
local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent)
DeathMessageFrame:SetSize(400, 100)                              -- Breite und Höhe des Frames
DeathMessageFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 400) -- Position in der Mitte des Bildschirms
DeathMessageFrame:Hide()                                         -- Standardmäßig versteckt

-- Hintergrund und Text
-- DeathMessageFrame.bg = DeathMessageFrame:CreateTexture(nil, "BACKGROUND")
-- DeathMessageFrame.bg:SetAllPoints(true)
-- DeathMessageFrame.bg:SetColorTexture(0, 0, 0, 0.5) -- Halbtransparenter schwarzer Hintergrund

DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
DeathMessageFrame.text:SetPoint("CENTER", DeathMessageFrame, "CENTER")
DeathMessageFrame.text:SetTextColor(1, 1, 1, 1) -- Weiße Schrift
DeathMessageFrame.text:SetText("")              -- Standardmäßig leer

-- Funktion zum Anzeigen der Nachricht
local function ShowDeathMessage(message)
	DeathMessageFrame.text:SetText(message)
	DeathMessageFrame:Show()


	PlaySound(8192) -- Horde-Flagge zurückgebracht

	-- Nachricht nach 5 Sekunden ausblenden
	C_Timer.After(5, function()
		DeathMessageFrame:Hide()
	end)
end

local PopupTracker = CreateFrame("Frame")
PopupTracker:RegisterEvent("CHAT_MSG_ADDON")
PopupTracker:SetScript("OnEvent", function(self, event, prefix, msg, sender, ...)
	if (event == "CHAT_MSG_ADDON" and prefix == SchlingelInc.prefix and msg:find("SCHLINGEL_DEATH")) then
		local name, class, level, zone = msg:match("^SCHLINGEL_DEATH:([^:]+):([^:]+):([^:]+):([^:]+)$")
		if name and class and level and zone then
			local messageFormat = "%s der %s ist mit Level %s in %s gestorben. Schande!"
			local messageString = messageFormat:format(name, class, level, zone)
			-- Zeige die Nachricht im zentralen Frame an
			ShowDeathMessage(messageString)
		end
	end
end)
