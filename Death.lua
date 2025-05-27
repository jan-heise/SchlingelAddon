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
		if not SchlingelInc:IsInBattleground() then
			SendChatMessage(messageString, "GUILD")
			C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, popupMessageString, "GUILD")
		end

		-- Wenn der DeathCount noch nicht gesetzt wurde, setzen wir ihn auf 1.
		if CharacterDeaths == nil then
			CharacterDeaths = 1
			return -- Abbruch des Eventhandlers
		end

		if not SchlingelInc:IsInBattleground() then
			CharacterDeaths = CharacterDeaths + 1
		end

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
local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent, "BackdropTemplate")
DeathMessageFrame:SetSize(400, 150)
DeathMessageFrame:SetPoint("CENTER", UIParent, "TOP", 0, -200)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")  -- sehr hohe Schicht
DeathMessageFrame:SetFrameLevel(1000)                  -- sehr hoher Level innerhalb der Schicht
DeathMessageFrame:Hide()
DeathMessageFrame:SetAlpha(1)

-- Moderner Tooltip-Style-Hintergrund
DeathMessageFrame:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DeathMessageFrame:SetBackdropColor(0, 0, 0, 0.85)

-- Icon oben zentriert
local icon = DeathMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(48, 48)
icon:SetPoint("TOP", DeathMessageFrame, "TOP", 0, -12)
icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")

-- Header "Schande!" zentriert unter dem Icon
local header = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
header:SetPoint("TOP", icon, "BOTTOM", 0, -8)
header:SetText("Schande!")
header:SetTextColor(1, 0.2, 0.2, 1)
header:SetShadowColor(0, 0, 0, 1)
header:SetShadowOffset(1, -1)

-- Nachricht unter dem Header, zentriert, volle Breite
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
DeathMessageFrame.text:SetPoint("TOP", header, "BOTTOM", 0, -8)
DeathMessageFrame.text:SetWidth(360)
DeathMessageFrame.text:SetJustifyH("CENTER")
DeathMessageFrame.text:SetJustifyV("TOP")
DeathMessageFrame.text:SetTextColor(1, 0.1, 0.1, 1)
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(1, -1)
DeathMessageFrame.text:SetText("")

-- Funktion zum Anzeigen der Nachricht
local function ShowDeathMessage(message)
	DeathMessageFrame.text:SetText(message)
	DeathMessageFrame:Show()


	PlaySound(8192) -- Horde-Flagge zurückgebracht

	-- Nachricht nach 5 Sekunden ausblenden
	C_Timer.After(3, function()
		UIFrameFadeOut(DeathMessageFrame, 1, 1, 0) -- Dauer, StartAlpha, EndAlpha
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
