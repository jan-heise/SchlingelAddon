--[[
Copyright 2020 Sean Kennedy
The Hardcore AddOn is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Hardcore.

The Hardcore AddOn is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Hardcore AddOn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Hardcore AddOn. If not, see <http://www.gnu.org/licenses/>.
--]]

--[[ Const variables ]]
--
-- ERR_CHAT_PLAYER_NOT_FOUND_S = nil -- Disables warning when pinging non-hc player -- This clashes with other addons
StaticPopupDialogs["CHAT_CHANNEL_PASSWORD"] = nil
--CHAT_WRONG_PASSWORD_NOTICE = nil
local hardcore_modern_menu_state = _G.hardcore_modern_menu_state
local DEATH_ALERT_COOLDOWN = 1800
local GRIEF_WARNING_OFF = 0
local GRIEF_WARNING_SAME_FACTION = 1
local GRIEF_WARNING_ENEMY_FACTION = 2
local GRIEF_WARNING_BOTH_FACTIONS = 3
local CLASSES = {
	-- Classic:
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[6] = "Death Knight", -- new Death Knight ID
	[7] = "Shaman",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}

local CLASS_DICT = {
	["Warrior"] = 1,
	["Paladin"] = 1,
	["Hunter"] = 1,
	["Rogue"] = 1,
	["Priest"] = 1,
	["Death Knight"] = 1,
	["Shaman"] = 1,
	["Mage"] = 1,
	["Warlock"] = 1,
	["Druid"] = 1,
}

--[[ Global saved variables ]]
--
HardcoreUnlocked_Settings = {
	level_list = {},
	notify = true,
	debug_log = {},
	monitor = false,
	filter_f_in_chat = false,
	show_version_in_chat = false,
	alert_frame_x_offset = 0,
	alert_frame_y_offset = -150,
	alert_frame_scale = 0.7,
	show_minimap_mailbox_icon = false,
	sacrifice = {},
	hardcore_player_name = "",
	use_alternative_menu = false,
	ignore_xguild_chat = false,
	ignore_xguild_alerts = false,
	global_custom_pronoun = false,
}

--[[ Character saved variables ]]
--
HardcoreUnlocked_Character = {
	guid = "",
	grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS,
	achievements = {},
	passive_achievements = {},
	party_mode = "Solo",
	team = {},
	first_recorded = -1,
	game_version = "",
	hardcore_player_name = "",
	custom_pronoun = false,
	whitelist = {},
}

Backup_Character_Data = {}

--[[ Local variables ]]
--
_G.hc_online_player_ranks = {}
local speedrun_levels = {
	[10] = 1,
	[15] = 1,
	[20] = 1,
	[30] = 1,
	[40] = 1,
	[45] = 1,
	[50] = 1,
	[60] = 1,
}
local last_received_xguild_chat = ""
local debug = false
local dc_recovery_info = nil
local received_recover_time_ack = nil
local expecting_achievement_appeal = false
local loaded_inspect_frame = false
local pulses = {}
local alert_msg_time = {
	PULSE = {},
	ADD = {},
	DEAD = {},
}
local monitor_msg_throttle = {
	PULSE = {},
	ADD = {},
	DEAD = {},
}
local applied_guild_rules = false
local guild_player_first_ping_time = {}
local online_pulsing = {}
local guild_versions = {}
local guild_versions_status = {}
local guild_online = {}
local guild_highest_version = "0.0.0"
local guild_roster_loading = false

local bubble_hearth_vars = {
	spell_id = 8690,
	bubble_name = "Divine Shield",
	light_of_elune_name = "Light of Elune",
}

-- Ranks
local hc_id2rank = {
	["1"] = "officer",
}

local hc_rank2id = {
	["officer"] = "1",
}

-- addon communication
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon"
local COMM_PULSE_FREQUENCY = 10
local COMM_PULSE_CHECK_FREQUENCY = COMM_PULSE_FREQUENCY * 2
local COMM_UPDATE_BREAK = 4
local COMM_DELAY = 5
local COMM_BATCH_SIZE = 4
local COMM_COMMAND_DELIM = "$"
local COMM_FIELD_DELIM = "|"
local COMM_SUBFIELD_DELIM = "~"
local COMM_RECORD_DELIM = "^"
local COMM_COMMANDS = {
	"PULSE",                  -- 1
	"ADD",                    -- 2 depreciated, we can only handle receiving
	"DEAD",                   -- 3 new death command
	"CHARACTER_INFO",         -- 4  new death command
	"REQUEST_CHARACTER_INFO", -- 5 new death command
	"SACRIFICE",              -- 6 new sacrifice command
	"REQUEST_PCT",            -- 7 request a party change token
	"APPLY_PCT",              -- 8 request a party change
	"SEND_ACHIEVEMENT_APPEAL", -- 9 send appeal for achievement
	"XGUILD_DEAD_RELAY",      -- 10 Send death message a player in another guild to relay
	"XGUILD_DEAD",            -- 11 Send death message to other guild
	"XGUILD_CHAT_RELAY",      -- 12 Send chat message a player in another guild to relay
	"XGUILD_CHAT",            -- 13 Send chat message to other guild
	"NOTIFY_RANKING",         -- 14
	"DTPULSE",                -- 15 dungeon tracker active pulse; if this changes, also change in Dungeons.lua / DTSendPulse!
	"REQUEST_RECOVERY_TIME",  -- 16 Used to request recovery segments if detected DC
	"REQUEST_RECOVERY_TIME_ACK", -- 17 Recovery request ack
}
local COMM_SPAM_THRESHOLD = { -- msgs received within durations (s) are flagged as spam
	PULSE = 3,
	ADD = 180,
	DEAD = 180,
}
local DEPRECATED_COMMANDS = {
	UPDATE = 1,
	SYNC = 1,
}

-- stuff
hc_recent_level_up = nil -- KEEP GLOBAL
hc_guild_rank_index = nil
local recent_death_alert_sender = {}
local PLAYER_NAME, _ = nil, nil
local PLAYER_GUID = nil
local PLAYER_FACTION = nil
local GENDER_GREETING = { "guildmate", "brother", "sister" }
local GENDER_POSSESSIVE_PRONOUN = { "Their", "His", "Her" }
local recent_levelup = nil
local recent_msg = {}
local Last_Attack_Source = nil
DeathLog_Last_Attack_Source = nil
local PICTURE_DELAY = 0.65
local HIDE_RTP_CHAT_MSG_BUFFER = 0     -- number of messages in queue
local HIDE_RTP_CHAT_MSG_BUFFER_MAX = 2 -- number of maximum messages to wait for
local STARTED_BUBBLE_HEARTH_INFO = nil
local RECEIVED_FIRST_PLAYED_TIME_MSG = false
local PLAYED_TIME_GAP_THRESH = 600         -- seconds
local PLAYED_TIME_PERC_THRESH = 98         -- [0, 100] (2 minutes every 2 hours)
local PLAYED_TIME_MIN_PLAYED_THRESH = 7200 -- seconds (2 hours)
local TIME_TRACK_PULSE = 1
local TIME_PLAYED_PULSE = 60
local COLOR_RED = "|c00ff0000"
local COLOR_GREEN = "|c0000ff00"
local COLOR_YELLOW = "|c00ffff00"
local STRING_ADDON_STATUS_SUBTITLE = "Guild Addon Status"
local STRING_ADDON_STATUS_SUBTITLE_LOADING = "Guild Addon Status (Loading)"
local THROTTLE_DURATION = 5
local DETECT_OFFLINE_DURATION = 120 -- [s] If a pulse hasn't been received in this duration; assume the player is offline
local SACRIFICE_LEVEL_MIN = 55
local SACRIFICE_LEVEL_MAX = 58
local MOD_CHAR_NAMES = {
	["Knic"] = 1,
	["Kknic"] = 1,
	["Semigalle"] = 1,
	["Semidruu"] = 1,
	["Letmefixit"] = 1,
	["Unarchiver"] = 1,
}

-- automagic exemptions for known griefs below level 40
local authorized_resurrection = nil
local GRIEFING_MOBS = {
	["Anvilrage Overseer"] = 1,
	["Infernal"] = 1,
	["Teremus the Devourer"] = 1,
	["Volchan"] = 1,
	["Twilight Fire Guard"] = 1,
	["Hakkari Oracle"] = 1,
	["Searing Ghoul"] = 1,
	["Dessecus"] = 1,
}

-- frame display
local display = "Rules"
local displaylist = HardcoreUnlocked_Settings.level_list
local icon = nil

-- available alert frame/icon styles
local MEDIA_DIR = "Interface\\AddOns\\HardcoreUnlocked\\Media\\"
local ALERT_STYLES = {
	logo = {
		frame = Hardcore_Alert_Frame, -- frame object
		text = Hardcore_Alert_Text, -- text layer
		icon = Hardcore_Alert_Icon, -- icon layer
		file = "logo-emblem.blp", -- string
		delay = COMM_DELAY,     -- int seconds
		alertSound = 8959,
	},
	death = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-death.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	hc_green = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-green.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	hc_red = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	spirithealer = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-spirithealer.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	bubble = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 8,
		alertSound = 8959,
	},
	hc_enabled = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 10,
		alertSound = nil,
	},
	hc_pvp_warning = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "hc-pvp-alert.blp",
		delay = 10,
		alertSound = 8192,
	},
	videre_warning = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 10,
		alertSound = 8959,
	},
	hc_sample = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 30,
		alertSound = 8959,
	},
}
Hardcore_Alert_Frame:SetScale(0.7)

-- the big frame object for our addon
local Hardcore = CreateFrame("Frame", "Hardcore", nil, "BackdropTemplate")
Hardcore.ALERT_STYLES = ALERT_STYLES

function FailureFunction(achievement_name)
	local max_level = 60
	if
		(HardcoreUnlocked_Character.game_version ~= "")
		and (HardcoreUnlocked_Character.game_version ~= "Era")
		and (HardcoreUnlocked_Character.game_version ~= "SoM")
	then
		max_level = 80
	end
	if UnitLevel("player") == max_level then
		return
	end

	for i, v in ipairs(HardcoreUnlocked_Character.achievements) do
		if v == achievement_name then
			table.remove(HardcoreUnlocked_Character.achievements, i)
			_G.achievements[achievement_name]:Unregister()
			Hardcore:Print("Failed " .. _G.achievements[achievement_name].title)
			PlaySoundFile("Interface\\AddOns\\HardcoreUnlocked\\Media\\achievement_failure.ogg")
			if _G.achievements[achievement_name].alert_on_fail ~= nil then
				local level = UnitLevel("player")
				local mapID
				local deathData = string.format("%s%s%s", level, COMM_FIELD_DELIM, mapID and mapID or "")
				local commMessage = COMM_COMMANDS[3] .. COMM_COMMAND_DELIM .. deathData

				local messageString = UnitName("player") .. " has failed " .. _G.achievements[achievement_name].title
				SendChatMessage(messageString, "GUILD")
				if CTL then
					CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
				end
			end
		end
	end
end

local failure_function_executor = { Fail = FailureFunction }

function SuccessFunction(achievement_name)
	if _G.passive_achievements[achievement_name] == nil then
		return
	end
	for _, v in ipairs(HardcoreUnlocked_Character.passive_achievements) do
		if v == achievement_name then
			return
		end
	end
	table.insert(HardcoreUnlocked_Character.passive_achievements, achievement_name)

	Hardcore:ShowPassiveAchievementFrame(
		_G.passive_achievements[achievement_name].icon_path,
		"Achieved " .. _G.passive_achievements[achievement_name].title .. "!",
		5.0
	)

	Hardcore:Print(
		"Achieved "
		.. _G.passive_achievements[achievement_name].title
		.. "! Make sure to /reload when convenient to save your progress."
	)
end

local success_function_executor = { Succeed = SuccessFunction }

--[[ Command line handler ]]
--

local function djb2(str)
	local hash = 5381
	for i = 1, #str do
		hash = hash * 33 + str:byte(i)
	end
	return hash
end

local function GetCode(ach_num)
	local str = UnitName("player"):sub(1, 5) .. UnitLevel("player") .. ach_num
	return djb2(str)
end

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "levels" then
		Hardcore:Levels()
	elseif cmd == "alllevels" then
		Hardcore:Levels(true)
	elseif cmd == "hide" then
		-- they can click the hide button, dont really need a command for this
	elseif cmd == "debug" then
		debug = not debug
		Hardcore:Print("Debugging set to " .. tostring(debug))
		-- expand the mobs to allow for anti-grief testing in elwynn
		GRIEFING_MOBS = {
			["Anvilrage Overseer"] = 1,
			["Infernal"] = 1,
			["Teremus the Devourer"] = 1,
			["Volchan"] = 1,
			["Twilight Fire Guard"] = 1,
			["Hakkari Oracle"] = 1,
			["Forest Spider"] = 1,
			["Mangy Wolf"] = 1,
			["Searing Ghoul"] = 1,
		}
	elseif cmd == "alerts" then
		Hardcore_Toggle_Alerts()
		if HardcoreUnlocked_Settings.notify then
			Hardcore:Print("Alerts enabled.")
		else
			Hardcore:Print("Alerts disabled.")
		end
	elseif cmd == "monitor" then
		HardcoreUnlocked_Settings.monitor = not HardcoreUnlocked_Settings.monitor
		if HardcoreUnlocked_Settings.monitor then
			Hardcore:Monitor("Monitoring malicious users enabled.")
		else
			Hardcore:Print("Monitoring malicious users disabled.")
		end
	elseif cmd == "quitachievement" then
		local achievement_to_quit = ""
		for substring in args:gmatch("%S+") do
			achievement_to_quit = substring
		end
		if _G.achievements ~= nil and _G.achievements[achievement_to_quit] ~= nil then
			for i, achievement in ipairs(HardcoreUnlocked_Character.achievements) do
				if achievement == achievement_to_quit then
					Hardcore:Print("Successfuly quit " .. achievement .. ".")
					failure_function_executor.Fail(achievement)
				end
			end
		end
	elseif cmd == "wl" then
		local wl_acc = ""
		for substring in args:gmatch("%S+") do
			wl_acc = substring
		end
		HCU_whitelist(HardcoreUnlocked_Character, wl_acc)
	elseif cmd == "dk" then
		-- sacrifice your current lvl 55 char to allow for making DK
		local dk_convert_option = ""
		for substring in args:gmatch("%S+") do
			dk_convert_option = substring
		end
		Hardcore:DKConvert(dk_convert_option)
	elseif cmd == "griefalert" then
		local grief_alert_option = ""
		for substring in args:gmatch("%S+") do
			grief_alert_option = substring
		end
		Hardcore:SetGriefAlertCondition(grief_alert_option)
	elseif cmd == "pronoun" then
		local pronoun_option = ""
		for substring in args:gmatch("%S+") do
			pronoun_option = substring
		end
		Hardcore:SetPronoun(pronoun_option)
	elseif cmd == "gpronoun" then
		local gpronoun_option = ""
		for substring in args:gmatch("%S+") do
			gpronoun_option = substring
		end
		Hardcore:SetGlobalPronoun(gpronoun_option)
		-- Alert debug code
	elseif cmd == "alert" and debug == true then
		local head, tail = "", {}
		for substring in args:gmatch("%S+") do
			if head == "" then
				head = substring
			else
				table.insert(tail, substring)
			end
		end

		local style, message = head, table.concat(tail, " ")
		local styleConfig
		if ALERT_STYLES[style] then
			styleConfig = ALERT_STYLES[style]
		else
			styleConfig = ALERT_STYLES.hc_red
		end

		Hardcore:ShowAlertFrame(styleConfig, message)
	elseif cmd == "ExpectAchievementAppeal" then
		Hardcore:Print("Allowing a hc mod to appeal achievements.")
		expecting_achievement_appeal = true
		C_Timer.After(60.0, function() -- one minute to receive achievement appeal
			expecting_achievement_appeal = false
			Hardcore:Print("No longer allowing a hc mod to appeal achievements.")
		end)
	elseif cmd == "AppealAchievement" then
		if MOD_CHAR_NAMES[UnitName("player")] == nil then
			return
		end -- character must be moderator
		local target = nil
		local achievement_to_appeal = nil
		for substring in args:gmatch("%S+") do
			if target == nil then
				target = substring
			elseif achievement == nil then
				achievement_to_appeal = substring
				break
			end
		end
		if target == nil then
			Hardcore:Print("Wrong syntax: target is nil")
			return
		end

		if achievement_to_appeal == nil then
			Hardcore:Print("Wrong syntax: achievement is nil")
			return
		end

		if _G.achievements[achievement_to_appeal] == nil then
			Hardcore:Print("Wrong syntax: achievement isn't found for " .. achievement_to_appeal)
			return
		end

		if CTL then
			local commMessage = COMM_COMMANDS[9] .. COMM_COMMAND_DELIM .. achievement_to_appeal
			Hardcore:Print("Appealing " .. achievement_to_appeal .. " for " .. target)
			CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "WHISPER", target)
		end
	elseif cmd == "AppealAchievementCode" then
		local code = nil
		local ach_num = nil
		for substring in args:gmatch("%S+") do
			if code == nil then
				code = substring
			else
				ach_num = substring
			end
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end

		if _G.achievements[_G.id_a[ach_num]] == nil then
			Hardcore:Print("Wrong syntax: achievement isn't found for " .. ach_num)
			return
		end

		if tostring(GetCode(ach_num)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			for i, v in ipairs(HardcoreUnlocked_Character.achievements) do
				if v == _G.id_a[ach_num] then
					return
				end
			end

			local function OnOkayClick()
				table.insert(HardcoreUnlocked_Character.achievements, _G.achievements[_G.id_a[ach_num]].name)
				_G.achievements[_G.id_a[ach_num]]:Register(failure_function_executor, HardcoreUnlocked_Character)
				Hardcore:Print("Appealed " .. _G.achievements[_G.id_a[ach_num]].name .. " challenge!")
				StaticPopup_Hide("ConfirmAchievementAppeal")
			end

			local function OnCancelClick()
				Hardcore:Print("Opting out of Appeal for Achievement: " .. _G.achievements[_G.id_a[ach_num]].name)
				StaticPopup_Hide("ConfirmAchievementAppeal")
			end

			local text = "You have requested to appeal the achievement '"
				.. _G.achievements[_G.id_a[ach_num]].title
				.. "'."

			if ach_num == "47" then -- Insane in the Membrane
				text = text .. "  This achievement will flag you for PvP, and you may be killed."
			end

			text = text .. "  Do you want to proceed?"

			StaticPopupDialogs["ConfirmAchievementAppeal"] = {
				text = text,
				button1 = OKAY,
				button2 = CANCEL,
				OnAccept = OnOkayClick,
				OnCancel = OnCancelClick,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
			}

			local dialog = StaticPopup_Show("ConfirmAchievementAppeal")
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(ach_num) .. " " .. code)
		end
	elseif cmd == "AppealDungeonCode" then
		-- DungeonTrackerHandleAppealCode(args)
	elseif cmd == "ImportFromHC" then
		if Hardcore_Character then
			local current_passive_achievements = {}
			for _, v in ipairs(HardcoreUnlocked_Character.passive_achievements) do
				current_passive_achievements[v] = 1
			end
			if Hardcore_Character.passive_achievements then
				for _, v in ipairs(Hardcore_Character.passive_achievements) do
					if current_passive_achievements[v] == nil then
						table.insert(HardcoreUnlocked_Character.passive_achievements, v)
					end
				end
			end

			local current_achievements = {}
			for _, v in ipairs(HardcoreUnlocked_Character.achievements) do
				current_achievements[v] = 1
			end
			if Hardcore_Character.achievements then
				for _, v in ipairs(Hardcore_Character.achievements) do
					if current_achievements[v] == nil then
						table.insert(HardcoreUnlocked_Character.achievements, v)
					end
				end
			end

			if HardcoreUnlocked_Character.first_recorded == nil or HardcoreUnlocked_Character.first_recorded == -1 then
				if Hardcore_Character.first_recorded then
					HardcoreUnlocked_Character.first_recorded = Hardcore_Character.first_recorded
				end
			end
			Hardcore:Print("Import complete. Make sure to turn off the Hardcore addon and reload.")
		else
			Hardcore:Print(
				"Did not detect the Hardcore Addon.  The Hardcore addon needs to be running if you want to import character data. Once character data is imported, you should turn off the Hardcore addon."
			)
		end
	elseif cmd == "AppealPassiveAchievementCode" then
		local code = nil
		local ach_num = nil
		for substring in args:gmatch("%S+") do
			if code == nil then
				code = substring
			else
				ach_num = substring
			end
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end

		if _G.passive_achievements[_G.id_pa[ach_num]] == nil then
			Hardcore:Print("Wrong syntax: achievement isn't found for " .. ach_num)
			return
		end

		if tostring(GetCode(ach_num)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			for i, v in ipairs(HardcoreUnlocked_Character.passive_achievements) do
				if v == _G.id_pa[ach_num] then
					return
				end
			end
			table.insert(
				HardcoreUnlocked_Character.passive_achievements,
				_G.passive_achievements[_G.id_pa[ach_num]].name
			)
			Hardcore:Print("Appealed " .. _G.passive_achievements[_G.id_pa[ach_num]].name .. " challenge!")
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(ach_num) .. " " .. code)
		end
	elseif cmd == "RemovePassiveAchievementCode" then
		local code = nil
		local ach_num = nil
		for substring in args:gmatch("%S+") do
			if code == nil then
				code = substring
			else
				ach_num = substring
			end
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end

		if _G.passive_achievements[_G.id_pa[ach_num]] == nil then
			Hardcore:Print("Wrong syntax: achievement isn't found for " .. ach_num)
			return
		end

		if tostring(GetCode(ach_num)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			for i, v in ipairs(HardcoreUnlocked_Character.passive_achievements) do
				if v == _G.id_pa[ach_num] then
					table.remove(HardcoreUnlocked_Character.passive_achievements, i)
					Hardcore:Print(
						"Successfully removed " .. _G.passive_achievements[_G.id_pa[ach_num]].name .. " challenge."
					)
					return
				end
			end
			Hardcore:Print(
				"Player has not achieved " .. _G.passive_achievements[_G.id_pa[ach_num]].name .. " challenge."
			)
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(ach_num) .. " " .. code)
		end
	elseif cmd == "SetRank" then
		local code = nil
		local ach_num = nil
		local rank = nil
		local iters = 0
		for substring in args:gmatch("%S+") do
			if iters == 0 then
				code = substring
			elseif iters == 1 then
				ach_num = substring
			elseif iters == 2 then
				rank = substring
			end
			iters = iters + 1
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end
		if rank == nil then
			Hardcore:Print("Wrong syntax: Missing third argument")
			return
		end

		if tostring(GetCode(-1)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			HardcoreUnlocked_Settings.rank_type = rank
			Hardcore:Print("Set rank to " .. rank)
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(-1) .. " " .. code)
		end
	elseif cmd == "AppealTradePartners" then
		local code = nil
		local ach_num = nil
		local iters = 0
		for substring in args:gmatch("%S+") do
			if iters == 0 then
				code = substring
			elseif iters == 1 then
				ach_num = substring
			end
			iters = iters + 1
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end

		if tostring(GetCode(-1)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			HardcoreUnlocked_Character.trade_partners = {}
			Hardcore:Print("Appealed Trade partners")
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(-1) .. " " .. code)
		end
	elseif cmd == "AppealDuoTrio" then
		local code = nil
		local ach_num = nil
		local iters = 0
		for substring in args:gmatch("%S+") do
			if iters == 0 then
				code = substring
			elseif iters == 1 then
				ach_num = substring
			end
			iters = iters + 1
		end
		if code == nil then
			Hardcore:Print("Wrong syntax: Missing first argument")
			return
		end
		if ach_num == nil or _G.ach then
			Hardcore:Print("Wrong syntax: Missing second argument")
			return
		end

		if tostring(GetCode(-1)):sub(1, 10) == tostring(tonumber(code)):sub(1, 10) then
			if HardcoreUnlocked_Character.party_mode == "Failed Duo" then
				HardcoreUnlocked_Character.party_mode = "Duo"
				Hardcore:Print("Appealed Duo status")
			end
			if HardcoreUnlocked_Character.party_mode == "Failed Trio" then
				HardcoreUnlocked_Character.party_mode = "Trio"
				Hardcore:Print("Appealed Trio status")
			end
		else
			Hardcore:Print("Incorrect code. Double check with a moderator." .. GetCode(-1) .. " " .. code)
		end
	else
		-- If not handled above, display some sort of help message
		Hardcore:Print("|cff00ff00Syntax:|r/hardcore [command] [options]")
		Hardcore:Print("|cff00ff00Commands:|r show hide levels alllevels alerts monitor griefalert dk")
	end
end

SLASH_HARDCOREUNLOCKED1, SLASH_HARDCOREUNLOCKED2, SLASH_HARDCOREUNLOCKED3 = "/hardcore", "/hc", "/hcu"
SlashCmdList["HARDCOREUNLOCKED"] = SlashHandler

local saved_variable_meta = {
	{ key = "guid",                      initial_data = UnitGUID("player") },
	{ key = "time_tracked",              initial_data = 0 },
	{ key = "time_played",               initial_data = 0 },
	{ key = "accumulated_time_diff",     initial_data = 0 },
	{ key = "tracked_played_percentage", initial_data = 0 },
	{ key = "deaths",                    initial_data = {} },
	{ key = "bubble_hearth_incidents",   initial_data = {} },
	{ key = "dt",                        initial_data = {} },
	{ key = "played_time_gap_warnings",  initial_data = {} },
	{ key = "trade_partners",            initial_data = {} },
	{ key = "grief_warning_conditions",  initial_data = GRIEF_WARNING_BOTH_FACTIONS },
	{ key = "achievements",              initial_data = {} },
	{ key = "passive_achievements",      initial_data = {} },
	{ key = "party_mode",                initial_data = "Solo" },
	{ key = "team",                      initial_data = {} },
	{ key = "first_recorded",            initial_data = -1 },
	{ key = "grief_warning_conditions",  initial_data = GRIEF_WARNING_BOTH_FACTIONS },
	{ key = "sacrificed_at",             initial_data = "" },
	{ key = "converted_successfully",    initial_data = false },
	{ key = "converted_time",            initial_data = "" },
	{ key = "game_version",              initial_data = "" },
	{ key = "hardcore_player_name",      initial_data = "" },
}

local settings_saved_variable_meta = {
	["level_list"] = {},
	["notify"] = true,
	["debug_log"] = {},
	["monitor"] = false,
	["filter_f_in_chat"] = false,
	["show_version_in_chat"] = false,
	["alert_frame_x_offset"] = 0,
	["alert_frame_y_offset"] = -150,
	["alert_frame_scale"] = 0.7,
	["show_minimap_mailbox_icon"] = false,
	["sacrifice"] = {},
	["hardcore_player_name"] = "",
	["use_alternative_menu"] = false,
	["ignore_xguild_chat"] = false,
	["ignore_xguild_alerts"] = false,
}

--[[ Post-utility functions]]
--

function Hardcore:InitializeSavedVariables()
	if HardcoreUnlocked_Character == nil then
		HardcoreUnlocked_Character = {}
	end

	for i, v in ipairs(saved_variable_meta) do
		if HardcoreUnlocked_Character[v.key] == nil then
			HardcoreUnlocked_Character[v.key] = v.initial_data
		end
	end
end

function Hardcore:ForceResetSavedVariables()
	for i, v in ipairs(saved_variable_meta) do
		HardcoreUnlocked_Character[v.key] = v.initial_data
	end
	HardcoreUnlocked_Character.dungeon_kill_targets = nil
	HardcoreUnlocked_Character.dungeon_kill_targets_solo = nil
	HardcoreUnlocked_Character.kill_list_dict = nil
end

function Hardcore:InitializeSettingsSavedVariables()
	if HardcoreUnlocked_Settings == nil then
		HardcoreUnlocked_Settings = {}
	end

	for k, v in pairs(settings_saved_variable_meta) do
		HardcoreUnlocked_Settings[k] = HardcoreUnlocked_Settings[k] or v
	end

	if HardcoreUnlocked_Settings["alert_frame_scale"] <= 0 then
		HardcoreUnlocked_Settings["alert_frame_scale"] = settings_saved_variable_meta["alert_frame_scale"]
	end
end

--[[ Startup ]]
--

function Hardcore:Startup()
	-- the entry point of our addon
	-- called inside loading screen before player sees world, some api functions are not available yet.

	-- event handling helper
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)
	-- actually start loading the addon once player ui is loading
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGIN")
end

--[[ Events ]]
--

function Hardcore:PLAYER_LOGIN()
	Hardcore:HandleLegacyDeaths()
	HardcoreUnlocked_Character.hardcore_player_name = HardcoreUnlocked_Settings.hardcore_player_name or ""

	_G.hardcore_disable_greenwall = HardcoreUnlocked_Settings.ignore_xguild_chat
	-- Show the first menu screen.  Requires short delay
	if UnitLevel("player") < 2 then
		C_Timer.After(1.0, function()
			HardcoreUnlocked_Character.first_recorded = GetServerTime()
		end)
	end
	-- HardcoreUnlocked_Character.rules = { [1] = 1, [2] = 1 }
	if HardcoreUnlocked_Character.rules == nil then
		HardcoreUnlocked_Character.rules = {}
	end
	HCU_enableRules(HardcoreUnlocked_Character)
	-- print(table.concat(HCU_decodeRules(HCU_encodeRules(HardcoreUnlocked_Character.rules))))

	-- cache player data
	_, class, _ = UnitClass("player")
	PLAYER_NAME, _ = UnitName("player")
	PLAYER_GUID = UnitGUID("player")
	PLAYER_FACTION, _ = UnitFactionGroup("player")
	local PLAYER_LEVEL = UnitLevel("player")

	-- Register achievements
	if HardcoreUnlocked_Character.achievements == nil then
		HardcoreUnlocked_Character.achievements = {}
	end

	if HardcoreUnlocked_Character.passive_achievements == nil then
		HardcoreUnlocked_Character.passive_achievements = {}
	end

	-- Adds HC character tab functionality
	hooksecurefunc("CharacterFrameTab_OnClick", function(self, button)
		local name = self:GetName()
		if name == "CharacterFrameTab6" then
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["PaperDollFrame"] ~= nil then
				_G["PaperDollFrame"]:Hide()
			end
			if _G["PetPaperDollFrame"] ~= nil then
				_G["PetPaperDollFrame"]:Hide()
			end
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["SkillFrame"] ~= nil then
				_G["SkillFrame"]:Hide()
			end
			if _G["ReputationFrame"] ~= nil then
				_G["ReputationFrame"]:Hide()
			end
			if _G["TokenFrame"] ~= nil then
				_G["TokenFrame"]:Hide()
			end
			ShowCharacterHC(HardcoreUnlocked_Character)
		elseif
			(name == "InspectFrameTab3" and _G["HardcoreBuildLabel"] ~= "WotLK")
			or (name == "InspectFrameTab4" and _G["HardcoreBuildLabel"] == "WotLK")
		then -- 3: era, 4:wotlk
			return
		else
			HideCharacterHC()
		end
	end)

	hooksecurefunc("CharacterFrame_ShowSubFrame", function(self, frameName)
		if name ~= "CharacterFrameTab6" then
			HideCharacterHC()
		end
	end)

	-- fires on first loading
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")
	self:RegisterEvent("QUEST_ACCEPTED") -- For Videre Elixir quest.
	self:RegisterEvent("QUEST_TURNED_IN") -- For Videre Elixir quest.
	self:RegisterEvent("CHAT_MSG_PARTY")
	self:RegisterEvent("CHAT_MSG_SAY")
	self:RegisterEvent("CHAT_MSG_GUILD")

	-- For inspecting other player's status
	self:RegisterEvent("INSPECT_READY")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	-- For dungeon tracking targetting of door npcs
	--self:RegisterEvent("ADDON_ACTION_FORBIDDEN")

	Hardcore:InitializeSavedVariables()
	Hardcore:InitializeSettingsSavedVariables()

	Hardcore:ApplyAlertFrameSettings()

	-- different guid means new character with the same name
	if HardcoreUnlocked_Character.guid ~= PLAYER_GUID then
		Hardcore:ForceResetSavedVariables()
	end

	local any_acheivement_registered = false
	for i, v in ipairs(HardcoreUnlocked_Character.achievements) do
		if _G.achievements[v] ~= nil then
			_G.achievements[v]:Register(failure_function_executor, HardcoreUnlocked_Character)
			any_acheivement_registered = true
		end
	end
	for i, v in pairs(_G.passive_achievements) do
		v:Register(success_function_executor, HardcoreUnlocked_Character)
	end
	if any_acheivement_registered then
		Hardcore:Print(
			'You currently have active Hardcore achievements!  You may quit an achievement at any time using the quitachievement command using Pascal case format (e.g. "/hardcore quitachievement TunnelVision")'
		)
	end

	if HardcoreUnlocked_Character.party_mode ~= nil then
		if _G.extra_rules[HardcoreUnlocked_Character.party_mode] ~= nil then
			_G.extra_rules[HardcoreUnlocked_Character.party_mode]:Register(
				failure_function_executor,
				HardcoreUnlocked_Character,
				HardcoreUnlocked_Settings
			)
		end
	end

	-- cache player name
	PLAYER_NAME, _ = UnitName("player")
	PLAYERGUID = UnitGUID("player")

	-- minimap button
	Hardcore:initMinimapButton()

	-- initiate pulse heartbeat
	Hardcore:InitiatePulse()

	-- initiate pulse heartbeat check
	Hardcore:InitiatePulseCheck()

	-- initiate pulse played time
	Hardcore:InitiatePulsePlayed()

	-- check players version against highest version
	local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()
	Hardcore:CheckVersionsAndUpdate(FULL_PLAYER_NAME, GetAddOnMetadata("HardcoreUnlocked", "Version"))

	-- reset debug log; To view debug log, log out and see saved variables before logging back in
	HardcoreUnlocked_Settings.debug_log = {}

	local isInGuild, _, guild_rank_index = GetGuildInfo("player")
	if isInGuild then
		hc_guild_rank_index = guild_rank_index
	end

	local function inSOM()
		for i = 1, 40 do
			local buff_name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
			if buff_name == nil then
				return false
			end
			if buff_name == "Adventure Awaits" or buff_name == "Soul of Iron" then
				return true
			end
		end
		return true
	end

	if HardcoreUnlocked_Character.game_version == "" or HardcoreUnlocked_Character.game_version == "Era" then
		if _G["HardcoreBuildLabel"] == nil then
			-- pass
		elseif _G["HardcoreBuildLabel"] == "Classic" then
			C_Timer.After(5.0, function()
				if inSOM() then
					HardcoreUnlocked_Character.game_version = "SoM"
				else
					HardcoreUnlocked_Character.game_version = "Era"
				end
			end)
		else
			HardcoreUnlocked_Character.game_version = _G["HardcoreBuildLabel"]
		end
	end
end

local function GiveVidereWarning()
	Hardcore:Print("|cFFFF0000WARNING:|r drinking the Videre Elixir will kill you. You cannot appeal this death.")
	Hardcore:ShowAlertFrame(
		ALERT_STYLES.videre_warning,
		"WARNING: drinking the Videre Elixir will kill you. You cannot appeal this death."
	)
end

local function GiveQuestPvpWarning(text_to_display)
	Hardcore:Print("|cFFFF0000WARNING:|r PVP Flag Warning!")
	Hardcore:ShowAlertFrame(ALERT_STYLES.videre_warning, "WARNING: You will be PVP flagged when " .. text_to_display)
end

function Hardcore:QUEST_ACCEPTED(_, questID)
	if questID == 3912 then
		GiveVidereWarning()
	end
	if questID == 7843 then --The Final Message to the Wildhammer
		GiveQuestPvpWarning("the spear is placed. PvP deaths are not appealable.")
	end
	if questID == 1266 then --The Missing Diplomat (quest before flag quest 1324)
		GiveQuestPvpWarning(
			"the next quest in the chain is accepted from Private Hendel. PvP deaths are not appealable."
		)
	end
end

local function RequestHCDataIfValid(unit_id)
	if UnitIsPlayer(unit_id) then
		if UnitIsFriend("player", unit_id) then
			if
				other_hardcore_character_cache[UnitName(unit_id)] == nil
				or time() - other_hardcore_character_cache[UnitName(unit_id)].last_received > 60 * 60 -- 1hr
			then
				if UnitAffectingCombat("player") == false and UnitAffectingCombat(unit_id) == false then
					Hardcore:RequestCharacterData(UnitName(unit_id))
				end
			end
		end
	end
end

function Hardcore:UPDATE_MOUSEOVER_UNIT()
	RequestHCDataIfValid("mouseover")
end

function Hardcore:UNIT_TARGET()
	RequestHCDataIfValid("target")
end

function Hardcore:QUEST_TURNED_IN(questID)
	if questID == 4041 then
		GiveVidereWarning()
	end
end

function Hardcore:INSPECT_READY(...)
	if InspectFrame == nil then
		return
	end
	if loaded_inspect_frame == false then
		loaded_inspect_frame = true
		local ITabName = "HC"
		local ITabID = InspectFrame.numTabs + 1
		local ITab =
			CreateFrame("Button", "$parentTab" .. ITabID, InspectFrame, "CharacterFrameTabButtonTemplate", ITabName)
		PanelTemplates_SetNumTabs(InspectFrame, ITabID)
		PanelTemplates_SetTab(InspectFrame, 1)

		ITab:SetPoint("LEFT", "$parentTab" .. (ITabID - 1), "RIGHT", -16, 0)
		ITab:SetText(ITabName)
	end

	if _G["InspectHonorFrame"] ~= nil then
		hooksecurefunc(_G["InspectHonorFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectPaperDollFrame"] ~= nil then
		hooksecurefunc(_G["InspectPaperDollFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectPVPFrame"] ~= nil then
		hooksecurefunc(_G["InspectPVPFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectTalentFrame"] ~= nil then
		hooksecurefunc(_G["InspectTalentFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	hooksecurefunc("CharacterFrameTab_OnClick", function(self)
		local name = self:GetName()
		if
			(name ~= "InspectFrameTab3" and _G["HardcoreBuildLabel"] ~= "WotLK")
			or (name ~= "InspectFrameTab4" and _G["HardcoreBuildLabel"] == "WotLK")
		then -- 3:era, 4:wotlk
			return
		end
		if _G["HardcoreBuildLabel"] == "WotLK" then
			PanelTemplates_SetTab(InspectFrame, 4)
		else
			PanelTemplates_SetTab(InspectFrame, 3)
		end
		if _G["InspectPaperDollFrame"] ~= nil then
			_G["InspectPaperDollFrame"]:Hide()
		end
		if _G["InspectHonorFrame"] ~= nil then
			_G["InspectHonorFrame"]:Hide()
		end
		if _G["InspectPVPFrame"] ~= nil then
			_G["InspectPVPFrame"]:Hide()
		end
		if _G["InspectTalentFrame"] ~= nil then
			_G["InspectTalentFrame"]:Hide()
		end

		target_name = UnitName("target")
		if other_hardcore_character_cache[target_name] ~= nil then
			ShowInspectHC(
				other_hardcore_character_cache[target_name],
				target_name,
				other_hardcore_character_cache[target_name].version
			)
		else
			local _default_hardcore_character = {
				achievements = {},
				passive_achievements = {},
				party_mode = "Solo",
				team = {},
				first_recorded = -1,
				version = "?",
			}
			ShowInspectHC(_default_hardcore_character, target_name, _default_hardcore_character.version)
		end
	end)

	hooksecurefunc(InspectFrame, "Hide", function(self, button)
		HideInspectHC()
	end)
end

function Hardcore:PLAYER_ENTERING_WORLD()
	-- cache player name
	PLAYER_NAME, _ = UnitName("player")
	Hardcore:Monitor("Monitoring malicious users enabled.")

	-- initialize addon communication
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_NAME) then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_NAME)
	end

	if Hardcore_Character ~= nil then
		Hardcore:Print(
			"Detected that both Hardcore and Hardcore Unlocked are being run. If you are trying to import Hardcore character data to Hardcore Unlocked, use the command /hcu ImportFromHC"
		)
	end
	C_Timer.After(1.0, function()
		deathlogApplySettings(HardcoreUnlocked_Settings)
	end)

	C_Timer.After(5.0, function()
		deathlogJoinChannel()
	end)
end

function Hardcore:PLAYER_ALIVE()
	if #HardcoreUnlocked_Character.deaths == 0 then
		return
	end

	if HardcoreUnlocked_Character.deaths[#HardcoreUnlocked_Character.deaths].player_alive_trigger == nil then
		HardcoreUnlocked_Character.deaths[#HardcoreUnlocked_Character.deaths].player_alive_trigger =
			date("%m/%d/%y %H:%M:%S")
	end
end

function Hardcore:PLAYER_DEAD()
	local isInBattlefield = false
	for i = 1, GetMaxBattlefieldID() do
		local battleFieldStatus = GetBattlefieldStatus(i)
		if battleFieldStatus == "active" then
			isInBattlefield = true
			break
		end
	end
	if isInBattlefield then
		return
	end
	-- Screenshot
	-- C_Timer.After(PICTURE_DELAY, function()
	-- 	Screenshot()
	-- end)

	-- Prepare various strings for use in the conditions below
	local playerGreet = GENDER_GREETING[UnitSex("player")]
	local pronoun = HardcoreUnlocked_Character.custom_pronoun or HardcoreUnlocked_Settings.global_custom_pronoun
	if pronoun == "Their" then
		playerGreet = GENDER_GREETING[1]
	elseif pronoun == "His" then
		playerGreet = GENDER_GREETING[2]
	elseif pronoun == "Her" then
		playerGreet = GENDER_GREETING[3]
	end
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
	local messageFormat = "%s ist mit Level %d in %s gestorben. Schande!"
	local messageFormatWithRank = "Ewiger Schlingel %s ist mit Level %d in %s gestorben. Schande!"

	-- Update deaths
	if
		#HardcoreUnlocked_Character.deaths == 0
		or (
			#HardcoreUnlocked_Character.deaths > 0
			and HardcoreUnlocked_Character.deaths[#HardcoreUnlocked_Character.deaths].player_alive_trigger ~= nil
		)
	then
		table.insert(HardcoreUnlocked_Character.deaths, {
			player_dead_trigger = date("%m/%d/%y %H:%M:%S"),
			player_alive_trigger = nil,
		})
	end

	if hc_self_block_flag then
		return
	end

	-- Send broadcast alert messages to guild and greenwall
	if (rank ~= nil and rank == "EwigerSchlingel") then
		messageFormat = messageFormatWithRank
	end
	local messageString = messageFormat:format(name, level, zone)
	if not (Last_Attack_Source == nil) then
		messageString = string.format("%s Gestorben an %s", messageString, Last_Attack_Source)
		Last_Attack_Source = nil
	end

	-- last words
	if not (recent_msg["text"] == nil) then
		local playerPronoun = HardcoreUnlocked_Character.custom_pronoun
			or HardcoreUnlocked_Settings.global_custom_pronoun
			or GENDER_POSSESSIVE_PRONOUN[UnitSex("player")]
		messageString = string.format('%s. Die letzten Worte: "%s"', messageString, recent_msg["text"])
	end

	-- Send broadcast text messages to guild and greenwall
	selfDeathAlert(DeathLog_Last_Attack_Source)
	selfDeathAlertLastWords(recent_msg["text"])

	SendChatMessage(messageString, "GUILD")
	Hardcore:Print(messageString)

	-- Send addon alert notice
	local deathData = string.format("%s%s%s", level, COMM_FIELD_DELIM, mapID and mapID or "")
	local commMessage = COMM_COMMANDS[3] .. COMM_COMMAND_DELIM .. deathData
	if CTL then
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:PLAYER_TARGET_CHANGED()
	if UnitGUID("target") ~= PLAYER_GUID and UnitIsPVP("target") then
		if HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_BOTH_FACTIONS then
			local faction, _ = UnitFactionGroup("target")
			if
				faction ~= nil
				and (faction ~= PLAYER_FACTION or (faction == PLAYER_FACTION and UnitPlayerControlled("target")))
			then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
			local faction, _ = UnitFactionGroup("target")
			if faction ~= nil and faction ~= PLAYER_FACTION then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
			local faction, _ = UnitFactionGroup("target")
			if faction ~= nil and faction == PLAYER_FACTION and UnitPlayerControlled("target") then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		end
	end
end

function Hardcore:PLAYER_UNGHOST()
	if UnitIsDeadOrGhost("player") == 1 then
		return
	end -- prevent message on ghost login or zone

	local isInBattlefield = false
	for i = 1, GetMaxBattlefieldID() do
		local battleFieldStatus = GetBattlefieldStatus(i)
		if battleFieldStatus == "active" then
			isInBattlefield = true
			break
		end
	end
	if isInBattlefield then
		return
	end

	if hc_self_block_flag then
		return
	end
	local playerName, _ = UnitName("player")

	local message = playerName .. " wurde wiederbelebt!"

	-- check if resurrection is authorized
	if authorized_resurrection then
		message = playerName .. " has resurrected after dying to malicious activity."

		-- reset the authorization
		authorized_resurrection = nil
	else
		-- not authorized, use alert behaviour
		Hardcore:ShowAlertFrame(ALERT_STYLES.spirithealer, message)
	end

	-- broadcast to guild and greenwall
	SendChatMessage(message, "GUILD", nil, nil)
end

function Hardcore:PLAYER_LEVEL_UP(...)
	-- store the recent level up to use in TIME_PLAYED_MSG
	local level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots, strengthDelta, agilityDelta, staminaDelta, intellectDelta =
		...
	recent_levelup = level
	hc_recent_level_up = 1

	-- just in case... make sure recent level up gets reset after 3 secs
	C_Timer.After(3, function()
		recent_levelup = nil
		hc_recent_level_up = nil
	end)

	-- get time played, see TIME_PLAYED_MSG
	RequestTimePlayed()

	-- take screenshot (got this idea from DingPics addon)
	-- wait a bit so the yellow animation appears
	-- C_Timer.After(PICTURE_DELAY, function()
	-- Screenshot()
	-- end)

	-- send a message to the guild if the player's level is divisible by 10
	local landmarkLevel = (level % 10) == 0 or level == 45 or level == 55
	if landmarkLevel then
		local playerName = UnitName("player")
		local localizedClass = UnitClass("player")

		local messageFormat = "%s the %s has reached level %s!"
		local messageString = string.format(messageFormat, playerName, localizedClass, level)
		SendChatMessage(messageString, "GUILD", nil, nil)
	end
end

function Hardcore:TIME_PLAYED_MSG(...)
	RECEIVED_FIRST_PLAYED_TIME_MSG = true

	if recent_levelup ~= nil then
		-- cache this to make sure it doesn't disapeer
		local recent = recent_levelup
		-- nil this to ensure it's not called twice
		recent_levelup = nil

		-- make sure list is initialized
		if HardcoreUnlocked_Settings.level_list == nil then
			HardcoreUnlocked_Settings.level_list = {}
		end

		-- info for level up record
		local totalTimePlayed, timePlayedThisLevel = ...
		local playerName, _ = UnitName("player")

		local function CalculateAdjustedTime(_timeplayed, _irl_time)
			local adjusted_time = _timeplayed
			if _irl_time / 86400 > 30 then
				adjusted_time = adjusted_time + (_irl_time - (86400 * 30)) * 13.5 / 86400 * 60
			end
			return adjusted_time
		end

		-- create the record
		local mylevelup = {}
		mylevelup["level"] = recent
		mylevelup["playedtime"] = totalTimePlayed
		mylevelup["realm"] = GetRealmName()
		mylevelup["player"] = playerName
		mylevelup["localtime"] = date()
		if HardcoreUnlocked_Character.first_recorded then
			mylevelup["adjustedtime"] =
				CalculateAdjustedTime(totalTimePlayed, GetServerTime() - HardcoreUnlocked_Character.first_recorded)
			if speedrun_levels[recent] then
				HardcoreUnlocked_Character["adjusted_time" .. tostring(recent)] = mylevelup["adjustedtime"]
			end
		end

		-- clear existing records if someone deleted / remade character
		-- since this is level 2, this must be a brand new character
		if recent == 2 then
			for i, v in ipairs(HardcoreUnlocked_Settings.level_list) do
				-- find previous records with same name / realm and rename them so we don't misidentify them
				if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] then
					-- copy the record and rename it
					local renamed = v
					renamed["player"] = renamed["player"] .. "-old"
					HardcoreUnlocked_Settings.level_list[i] = renamed
				end
			end
		end

		-- if we found previous level, show the last level time
		for i, v in ipairs(HardcoreUnlocked_Settings.level_list) do
			-- find last level up
			if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] and v["level"] == recent - 1 then
				-- show message to user with calculated time between levels
				Hardcore:Print(
					"Level "
					.. (recent - 1)
					.. "-"
					.. recent
					.. " time played: "
					.. SecondsToTime(totalTimePlayed - v["playedtime"])
				)
			end
		end

		-- store level record
		table.insert(HardcoreUnlocked_Settings.level_list, mylevelup)
	end
end

local Cached_ChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
ChatFrame_DisplayTimePlayed = function(...)
	if HIDE_RTP_CHAT_MSG_BUFFER > 0 then
		HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER - 1
		return
	end
	return Cached_ChatFrame_DisplayTimePlayed(...)
end

function Hardcore:RequestTimePlayed()
	HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER + 1
	if HIDE_RTP_CHAT_MSG_BUFFER > HIDE_RTP_CHAT_MSG_BUFFER_MAX then
		HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER_MAX
	end
	RequestTimePlayed()
end

-- player name, level, zone, attack_source, class
local function receiveDeathMsg(data, sender, command)
	if recent_death_alert_sender[sender] ~= nil then
		return
	end
	recent_death_alert_sender[sender] = 1

	C_Timer.After(DEATH_ALERT_COOLDOWN, function()
		recent_death_alert_sender[sender] = nil
	end)

	if
		HardcoreUnlocked_Settings.ignore_xguild_alerts ~= nil
		and HardcoreUnlocked_Settings.ignore_xguild_alerts == true
	then
		return
	end
	if HardcoreUnlocked_Settings.notify then
		local other_player_name = ""
		local level = 0
		local zone = ""
		local attack_source = ""
		local class = ""
		if data then
			other_player_name, level, zone, attack_source, class = string.split("^", data)
		else
			return -- Failed to parse
		end
		local alert_msg = other_player_name .. " the " .. class .. " has died at level " .. level .. "."

		local min_level = tonumber(HardcoreUnlocked_Settings.minimum_show_death_alert_lvl) or 0
		if tonumber(level) < tonumber(min_level) then
			return
		end
		if UnitInRaid("player") == nil then
			Hardcore:ShowAlertFrame(ALERT_STYLES.death, alert_msg)
			return
		end
	end
end

function Hardcore:CHAT_MSG_ADDON(prefix, datastr, scope, sender)
	-- Ignore messages that are not ours
	if COMM_NAME == prefix then
		-- Get the command
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)
		if command == COMM_COMMANDS[16] then -- Received request for recovery time
			if CTL and isInGuild and guild_player_first_ping_time[sender] ~= nil and pulses[sender] ~= nil then
				local commMessage = COMM_COMMANDS[17]
					.. COMM_COMMAND_DELIM
					.. tostring(guild_player_first_ping_time[sender])
					.. COMM_COMMAND_DELIM
					.. tostring(pulses[sender])
				CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "WHISPER", sender)
			end
			return
		end
		if command == COMM_COMMANDS[17] then -- Received recovery time ack
			-- The strategy here is to store as many responses as possible and recover based on the best one
			if CTL and isInGuild then
				local _, response_start_time_str, response_end_time_str = string.split(COMM_COMMAND_DELIM, datastr)
				local response_start_time = tonumber(response_start_time_str)
				local response_end_time = tonumber(response_end_time_str)
				local current_time = time()
				-- Don't add response if it seems invalid
				if
					response_start_time == nil
					or response_start_time > current_time
					or response_end_time
					or response_end_time > current_time() == nil
				then
					return
				end

				local entry = {
					start_time = response_start_time,
					end_time = response_end_time,
				}
				table.insert(dc_recovery_info.responses, entry)
			end
			return
		end

		if command == COMM_COMMANDS[10] then -- Received request for guild members
			local other_player_name = ""
			local level = 0
			local zone = ""
			local attack_source = ""
			local class = ""
			if data then
				other_player_name, level, zone, attack_source, class = string.split("^", data)
				if other_player_name and other_player_name ~= sender then
					return
				end
				if level == nil or tonumber(level) == nil or tonumber(level) < 1 or tonumber(level) > 80 then
					return
				end
				if class == nil or CLASS_DICT[class] == nil then
					return
				end

				local commMessage = COMM_COMMANDS[11] .. COMM_COMMAND_DELIM .. data
				CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
				return
			end
		end
		if command == COMM_COMMANDS[11] then -- Received request for guild members
			-- receiveDeathMsg(data, sender, command) -- Disable greenwall
			return
		end
		if command == COMM_COMMANDS[12] then -- Send guild chat to other guilds
			-- Disabled for the time being
			-- local commMessage = COMM_COMMANDS[13] .. COMM_COMMAND_DELIM .. data
			-- CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
			return
		end
		if command == COMM_COMMANDS[13] then -- Send guild chat from another guild to this guild
			return
		end
		if command == COMM_COMMANDS[7] then -- Received request for party change
			local name, _ = string.split("-", sender)
			local party_change_token_secret = string.split(COMM_FIELD_DELIM, data)
			party_change_token_handler:ReceiveRequestPartyChangeToken(
				HardcoreUnlocked_Settings,
				HardcoreUnlocked_Character,
				party_change_token_secret,
				name
			)
			return
		end
		if command == COMM_COMMANDS[8] then -- Received request for party change
			local name, _ = string.split("-", sender)
			local party_change_token_secret = string.split(COMM_FIELD_DELIM, data)
			party_change_token_handler:ReceiveApplyPartyChangeToken(
				HardcoreUnlocked_Settings,
				HardcoreUnlocked_Character,
				party_change_token_secret,
				name
			)
			return
		end
		if command == COMM_COMMANDS[5] then -- Received request for hc character data
			local name, _ = string.split("-", sender)
			Hardcore:SendCharacterData(name)
			return
		end
		if command == COMM_COMMANDS[14] then
			local name, _ = string.split("-", sender)
			if hc_id2rank[data] then
				_G.hc_online_player_ranks[name] = hc_id2rank[data]
				return
			end
		end
		if command == COMM_COMMANDS[4] then -- Received hc character data
			local name, _ = string.split("-", sender)
			local version_str, creation_time, achievements_str, _, party_mode_str, _, _, team_str, hc_tag, passive_achievements_str, ruleset_code =
				string.split(COMM_FIELD_DELIM, data)
			local achievements_l = { string.split(COMM_SUBFIELD_DELIM, achievements_str) }
			other_achievements_ds = {}
			for i, id in ipairs(achievements_l) do
				if _G.id_a[id] ~= nil then
					table.insert(other_achievements_ds, _G.id_a[id])
				end
			end

			other_passive_achievements_ds = {}
			if passive_achievements_str then
				local passive_achievements_l = { string.split(COMM_SUBFIELD_DELIM, passive_achievements_str) }
				for i, id in ipairs(passive_achievements_l) do
					if _G.id_pa[id] ~= nil then
						table.insert(other_passive_achievements_ds, _G.id_pa[id])
					end
				end
			end

			local other_rules = {}
			if ruleset_code and HCU_decodeRules(ruleset_code) then
				for _, v in ipairs(HCU_decodeRules(ruleset_code)) do
					other_rules[v] = 1
				end
			end

			local team_l = { string.split(COMM_SUBFIELD_DELIM, team_str) }
			other_hardcore_character_cache[name] = {
				first_recorded = creation_time,
				achievements = other_achievements_ds,
				passive_achievements = other_passive_achievements_ds,
				party_mode = party_mode_str,
				version = version_str,
				team = team_l,
				last_received = time(),
				hardcore_player_name = hc_tag,
				rules = other_rules,
			}
			hardcore_modern_menu_state.changeset[string.split("-", name)] = 1
			return
		end
		if command == COMM_COMMANDS[9] then -- Appeal achievement
			local name, _ = string.split("-", sender)
			if MOD_CHAR_NAMES[name] == nil then -- received appeal from non-mod character
				return
			end
			if expecting_achievement_appeal == false then
				Hardcore:Print(
					'Received unexpected achievement appeal.  If you are expecting an achievement appeal type "/hardcore ExpectAchievementAppeal"'
				)
				return
			end
			local achievement_to_appeal = _G.achievements[string.split(COMM_FIELD_DELIM, data)]
			if achievement_to_appeal ~= nil then
				table.insert(HardcoreUnlocked_Character.achievements, achievement_to_appeal.name)
				achievement_to_appeal:Register(failure_function_executor, HardcoreUnlocked_Character)
				Hardcore:Print("Appealed " .. achievement_to_appeal.name .. " challenge!")
			end
			return
		end
		if command == COMM_COMMANDS[15] then
			-- DungeonTrackerReceivePulse(data, sender)
			return
		end
		if DEPRECATED_COMMANDS[command] or alert_msg_time[command] == nil then
			return
		end
		if
			alert_msg_time[command][sender]
			and (time() - alert_msg_time[command][sender] < COMM_SPAM_THRESHOLD[command])
		then
			local debug_info = { command, data, sender }
			table.insert(HardcoreUnlocked_Settings.debug_log, debug_info)
			alert_msg_time[command][sender] = time()
			-- Display that someone is trying to send spam messages; notifies mods to look at saved_vars and remove player from guild
			if
				monitor_msg_throttle[command][sender] == nil
				or (time() - monitor_msg_throttle[command][sender] > THROTTLE_DURATION)
			then
				Hardcore:Monitor("|cffFF0000Received spam from " .. sender .. ", using the " .. command .. " command.")
				monitor_msg_throttle[command][sender] = time()
			end
			return
		end
		alert_msg_time[command][sender] = time()

		-- Determine what command was sent
		-- COMM_COMMANDS[2] is deprecated, but its backwards compatible so we still can handle
		if command == COMM_COMMANDS[2] or command == COMM_COMMANDS[3] or command == COMM_COMMANDS[6] then
			Hardcore:Add(data, sender, command)
		elseif command == COMM_COMMANDS[1] then
			Hardcore:ReceivePulse(data, sender)
		else
			-- Hardcore:Debug("Unknown command :"..command)
		end
	end
end

function Hardcore:COMBAT_LOG_EVENT_UNFILTERED(...)
	-- local time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
	local _, ev, _, _, source_name, _, _, target_guid, _, _, _, environmental_type, _, _, _, _, _ =
		CombatLogGetCurrentEventInfo()

	if not (source_name == PLAYER_NAME) then
		if not (source_name == nil) then
			if string.find(ev, "DAMAGE") ~= nil then
				Last_Attack_Source = source_name
				DeathLog_Last_Attack_Source = source_name
			end
		end
	end
	if ev == "ENVIRONMENTAL_DAMAGE" then
		if target_guid == UnitGUID("player") then
			if environmental_type == "Drowning" then
				DeathLog_Last_Attack_Source = -2
			elseif environmental_type == "Falling" then
				DeathLog_Last_Attack_Source = -3
			elseif environmental_type == "Fatigue" then
				DeathLog_Last_Attack_Source = -4
			elseif environmental_type == "Fire" then
				DeathLog_Last_Attack_Source = -5
			elseif environmental_type == "Lava" then
				DeathLog_Last_Attack_Source = -6
			elseif environmental_type == "Slime" then
				DeathLog_Last_Attack_Source = -7
			end
		end
	end
end

function Hardcore:CHAT_MSG_SAY(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 0
	end

	local arg = { ... }
	if
		HardcoreUnlocked_Settings.rank_type
		and HardcoreUnlocked_Settings.rank_type == "officer"
		and arg[5] == UnitName("player")
	then
		local commMessage = COMM_COMMANDS[14] .. COMM_COMMAND_DELIM .. hc_rank2id[HardcoreUnlocked_Settings.rank_type]
		CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:CHAT_MSG_GUILD(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 2
	end

	local arg = { ... }
	if
		HardcoreUnlocked_Settings.rank_type
		and HardcoreUnlocked_Settings.rank_type == "officer"
		and arg[5] == UnitName("player")
	then
		local commMessage = COMM_COMMANDS[14] .. COMM_COMMAND_DELIM .. hc_rank2id[HardcoreUnlocked_Settings.rank_type]
		CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:CHAT_MSG_PARTY(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 1
	end
end

function Hardcore:SetRecentMsg(...)
	local text, sn, LN, CN, p2, sF, zcI, cI, cB, unu, lI, senderGUID = ...
	if PLAYERGUID == nil then
		PLAYERGUID = UnitGUID("player")
	end

	if senderGUID == PLAYERGUID then
		recent_msg["text"] = text
		return true
	end
	return false
end

function Hardcore:GUILD_ROSTER_UPDATE(...)
	guild_roster_loading = false
	if applied_guild_rules == false then
		local txt = GetGuildInfoText() -- .. "HCU{huE`W}" -- for debug only
		if txt then
			local guild_rules = string.match(txt, "HCU{(.*)}")
			if guild_rules then
				HCU_applyFromCode(HardcoreUnlocked_Character, guild_rules)
				applied_guild_rules = true
				local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
				Hardcore:Print("Applying guild rules for: " .. guildName)
				HCU_enableRules(HardcoreUnlocked_Character)
			end
		end
	end

	-- Create a new dictionary of just online people every time roster is updated
	guild_online = {}
	hardcore_modern_menu_state.guild_online = {}

	-- Hardcore:Debug('guild roster update')
	local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	for i = 1, numOnline, 1 do
		local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
			GetGuildRosterInfo(i)

		-- name is nil after a gquit, so nil check here
		if name then
			guild_online[name] = {
				name = name,
				level = level,
				classDisplayName = classDisplayName,
			}
			hardcore_modern_menu_state.guild_online[name] = {
				name = name,
				level = level,
				classDisplayName = classDisplayName,
			}
			hardcore_modern_menu_state.changeset[(string.split("-", name))] = 1
		end
	end

	Hardcore:UpdateGuildRosterRows()
	if display == "AddonStatus" then
		Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE)
	end
end

--[[ Utility Methods ]]
--
function Hardcore:Notify(msg)
	-- print("|cffed9121Hardcore Notification: " .. (msg or "") .. "|r")
	-- Disable greenwall
end

function Hardcore:Print(msg)
	print("|cffed9121Hardcore|r: " .. (msg or ""))
end

function Hardcore:FakeGuildMsg(msg)
	-- print("|cff00FF00" .. msg .. "|r ")
	-- Disable greenwall
end

function Hardcore:Debug(msg)
	if true == debug then
		print("|cfffd9122HCDebug|r: " .. (msg or ""))
	end
end

function Hardcore:Monitor(msg)
	if true == HardcoreUnlocked_Settings.monitor then
		print("|cff00ffffHCMonitor|r: " .. (msg or ""))
	end
end

function Hardcore:ApplyAlertFrameSettings()
	Hardcore_Alert_Frame:SetScale(HardcoreUnlocked_Settings.alert_frame_scale)
	Hardcore_Alert_Frame:SetPoint(
		"TOP",
		"UIParent",
		"TOP",
		HardcoreUnlocked_Settings.alert_frame_x_offset / HardcoreUnlocked_Settings.alert_frame_scale,
		HardcoreUnlocked_Settings.alert_frame_y_offset / HardcoreUnlocked_Settings.alert_frame_scale
	)
end

-- Alert UI
function Hardcore:ShowAlertFrame(styleConfig, message)
	-- message is any text accepted by FontString:SetText(message)

	message = message or ""

	local data = styleConfig or ALERT_STYLES["hc_red"]
	local frame, text, icon, file, delay, alertSound =
		data.frame, data.text, data.icon, data.file, data.delay, data.alertSound

	filename = MEDIA_DIR .. file
	icon:SetTexture(filename)
	text:SetText(message)

	frame:Show()

	if alertSound then
		PlaySound(alertSound)
	end

	-- HACK:
	-- There's a bug here where a sequence of overlapping notifications share one 'hide' timer
	-- There should be a step here that unbinds all-but-the-last notification's Hide() callback
	C_Timer.After(delay, function()
		frame:Hide()
	end)
end

-- Exported version of ShowAlertFrame with HC_red style (used in DungeonTracker, ALERT_STYLES is local)
function Hardcore:ShowRedAlertFrame(message)
	Hardcore:ShowAlertFrame(ALERT_STYLES.hc_red, message)
end

function Hardcore:ShowPassiveAchievementFrame(icon_path, message, delay)
	-- message is any text accepted by FontString:SetText(message)

	achievement_alert_handler:SetIcon(icon_path)
	achievement_alert_handler:SetMsg(message)
	achievement_alert_handler:ShowTimed(delay)
	PlaySoundFile("Interface\\AddOns\\HardcoreUnlocked\\Media\\achievement_sound.ogg")

	if alertSound then
		PlaySound(alertSound)
	end
end

function Hardcore:Add(data, sender, command)
	-- Display the death locally if alerts are not toggled off.
	if HardcoreUnlocked_Settings.notify then
		local level = 0
		local mapID
		if data then
			level, mapID = string.split(COMM_FIELD_DELIM, data)
			level = tonumber(level)
			mapID = tonumber(mapID)
		end
		if type(level) == "number" then
			for i = 1, GetNumGuildMembers() do
				local name, _, _, guildLevel, _, zone, _, _, _, _, class = GetGuildRosterInfo(i)
				if name == sender then
					if recent_death_alert_sender[sender] ~= nil then
						return
					end
					recent_death_alert_sender[sender] = 1
					C_Timer.After(DEATH_ALERT_COOLDOWN, function()
						recent_death_alert_sender[sender] = nil
					end)
					if mapID then
						local mapData = C_Map.GetMapInfo(mapID) -- In case some idiot sends an invalid map ID, it won't cause mass lua errors.
						zone = mapData and mapData.name or
							zone              -- If player is in an instance, will have to get zone from guild roster.
					end
					local min_level = tonumber(HardcoreUnlocked_Settings.minimum_show_death_alert_lvl) or 0
					if level < tonumber(min_level) then
						return
					end
					level = level > 0 and level < 61 and level or
						guildLevel -- If player is using an older version of the addon, will have to get level from guild roster.
					local messageFormat = "%s the %s%s|r has died at level %d in %s"
					local messageString = messageFormat:format(
						name:gsub("%-.*", ""),
						"|c" .. RAID_CLASS_COLORS[class].colorStr,
						class,
						level,
						zone
					)

					-- If player is in a raid, then only show alerts for other players in the same raid
					if UnitInRaid("player") == nil or UnitInRaid(name:gsub("%-.*", "")) then
						Hardcore:ShowAlertFrame(ALERT_STYLES.death, messageString)
					end
				end
			end
		end
	end
end

function Hardcore:TriggerDeathAlert(msg)
	Hardcore:ShowAlertFrame(ALERT_STYLES.death, msg)
end

function Hardcore:GetValue(row, value)
	local playerid, name, classname, level, mapid, tod = string.split(COMM_FIELD_DELIM, row)
	if "playerid" == value then
		return playerid
	elseif "class" == value then
		return classname
	elseif "name" == value then
		return name
	elseif "level" == value then
		return level
	elseif "zone" == value then
		return mapid
	elseif "tod" == value then
		return tod
	else
		-- Default to returning everything
		return playerid, name, classname, level, mapid, tod
	end

	return nil
end

function Hardcore:GetClassColorText(classname)
	if "Druid" == classname then
		return "|c00ff7d0a"
	elseif "Hunter" == classname then
		return "|c00a9d271"
	elseif "Mage" == classname then
		return "|c0040c7eb"
	elseif "Paladin" == classname then
		return "|c00f58cba"
	elseif "Priest" == classname then
		return "|c00ffffff"
	elseif "Rogue" == classname then
		return "|c00fff569"
	elseif "Shaman" == classname then
		return "|c000070de"
	elseif "Warlock" == classname then
		return "|c008787ed"
	elseif "Warrior" == classname then
		return "|c00c79c6e"
	elseif "Death Knight" == classname then
		return "|c00C41E3A"
	end

	Hardcore:Debug("ERROR: classname not found")
	return "|c00c41f3b" -- Red
end

--[[ UI Methods ]]
--

-- switch between displays
function Hardcore:SwitchDisplay(displayparam)
	if displayparam ~= nil then
		display = displayparam
	end
end

function Hardcore_SortByLevel(pipe1, pipe2)
	return pipe1.level < pipe2.level
end

-- Toggles death alerts on or off.
function Hardcore_Toggle_Alerts()
	HardcoreUnlocked_Settings.notify = not HardcoreUnlocked_Settings.notify
end

----------------------------------------------------------------------
-- Minimap button (no reload required)
----------------------------------------------------------------------

function Hardcore:initMinimapButton()
	-- Minimap button click function
	local function MiniBtnClickFunc(arg1)
		-- Prevent options panel from showing if Blizzard options panel is showing
		if
			(InterfaceOptionsFrame ~= nil and InterfaceOptionsFrame:IsShown())
			or (VideoOptionsFrame ~= nil and VideoOptionsFrame:IsShown())
			or ChatConfigFrame:IsShown()
		then
			return
		end
		-- Prevent options panel from showing if Blizzard Store is showing
		if StoreFrame and StoreFrame:GetAttribute("isshown") then
			return
		end
		-- Left button down
		if arg1 == "LeftButton" then
			-- Control key
			if IsControlKeyDown() and not IsShiftKeyDown() then
				Hardcore:ToggleMinimapIcon()
				return
			end

			-- Shift key and control key
			if IsShiftKeyDown() and IsControlKeyDown() then
				return
			end

			if hardcore_modern_menu == nil then
			else
				if hardcore_modern_menu:IsShown() then
					hardcore_modern_menu:Hide() -- destructs
					hardcore_modern_menu = nil
				end
			end
		end
	end

	-- Create minimap button using LibDBIcon
	local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("HardcoreUnlocked", {
		type = "data source",
		text = "HardcoreUnlocked",
		icon = "Interface\\AddOns\\HardcoreUnlocked\\Media\\logo-emblem.blp",
		OnClick = function(self, btn)
			MiniBtnClickFunc(btn)
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Hardcore (" .. GetAddOnMetadata("HardcoreUnlocked", "Version") .. ")")
			tooltip:AddLine("|cFFCFCFCFclick|r show window")
			tooltip:AddLine("|cFFCFCFCFctrl click|r toggle minimap button")
		end,
	})

	icon = LibStub("LibDBIcon-1.0", true)
	icon:Register("HardcoreUnlocked", miniButton, HardcoreUnlocked_Settings)

	-- -- Function to toggle LibDBIcon
	-- function SetLibDBIconFunc()
	-- 	if HardcoreUnlocked_Settings["hide"] == nil or HardcoreUnlocked_Settings["hide"] == true then
	-- 		HardcoreUnlocked_Settings["hide"] = false
	-- 		icon:Show("Hardcore")
	-- 	else
	-- 		HardcoreUnlocked_Settings["hide"] = true
	-- 		icon:Hide("Hardcore")
	-- 	end
	-- end

	if HardcoreUnlocked_Settings["hide"] == false then
		icon:Show("HardcoreUnlocked")
	end

	-- -- Set LibDBIcon when option is clicked and on startup
	-- SetLibDBIconFunc()
end

function Hardcore:ToggleMinimapIcon()
	if icon then
		if HardcoreUnlocked_Settings["hide"] == nil or HardcoreUnlocked_Settings["hide"] == true then
			HardcoreUnlocked_Settings["hide"] = false
			icon:Show("Hardcore")
		else
			HardcoreUnlocked_Settings["hide"] = true
			icon:Hide("Hardcore")
		end
	end
end

local ATTRIBUTE_SEPARATOR = "_"
--[[ Timers ]]
--
function Hardcore:InitiatePulse()
	-- Set send pulses ticker
	C_Timer.NewTicker(COMM_PULSE_FREQUENCY, function()
		local isInGuild, _, guild_rank_index = GetGuildInfo("player")
		if CTL and isInGuild then
			-- Send along the version we're using
			local version = GetAddOnMetadata("HardcoreUnlocked", "Version")
			local commMessage = COMM_COMMANDS[1] .. COMM_COMMAND_DELIM .. version
			CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
			hc_guild_rank_index = guild_rank_index
		end
	end)
end

function Hardcore:RequestCharacterData(dest)
	if CTL then
		local commMessage = COMM_COMMANDS[5] .. COMM_COMMAND_DELIM .. ""
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "WHISPER", dest)
	end
end

function Hardcore:SendCharacterData(dest)
	if CTL then
		local commMessage = COMM_COMMANDS[4] .. COMM_COMMAND_DELIM
		commMessage = commMessage .. GetAddOnMetadata("HardcoreUnlocked", "Version") .. COMM_FIELD_DELIM -- Add Version
		if HardcoreUnlocked_Character.first_recorded ~= nil and HardcoreUnlocked_Character.first_recorded ~= -1 then
			commMessage = commMessage ..
				HardcoreUnlocked_Character.first_recorded ..
				COMM_FIELD_DELIM -- Add creation time
		else
			commMessage = commMessage ..
				"-1" .. COMM_FIELD_DELIM -- Add unknown creation time
		end

		for i, v in ipairs(HardcoreUnlocked_Character.achievements) do
			commMessage = commMessage .. _G.a_id[v] .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM .. COMM_FIELD_DELIM

		if HardcoreUnlocked_Character.party_mode ~= nil then
			commMessage = commMessage ..
				HardcoreUnlocked_Character.party_mode ..
				COMM_FIELD_DELIM                           -- Add unknown creation time
		else
			commMessage = commMessage .. "?" .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM
		commMessage = commMessage .. COMM_FIELD_DELIM

		for i, v in ipairs(HardcoreUnlocked_Character.team) do
			commMessage = commMessage .. v .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM

		commMessage = commMessage ..
			(HardcoreUnlocked_Character.hardcore_player_name or "") ..
			COMM_FIELD_DELIM -- Add Version

		for i, v in ipairs(HardcoreUnlocked_Character.passive_achievements) do
			commMessage = commMessage .. _G.pa_id[v] .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM .. HCU_encodeRules(HardcoreUnlocked_Character.rules)

		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "WHISPER", dest)
	end
end

function Hardcore:InitiatePulseCheck()
	C_Timer.NewTicker(COMM_PULSE_CHECK_FREQUENCY, function()
		-- Hardcore:Debug('Checking pulses now')
		online_pulsing = {}

		for player, status in pairs(guild_online) do
			local pulsetime = pulses[player]

			if not pulsetime or ((time() - pulsetime) > COMM_PULSE_CHECK_FREQUENCY) then
				online_pulsing[player] = false
			else
				online_pulsing[player] = true
			end
		end

		hardcore_modern_menu_state.online_pulsing = online_pulsing
	end)
end

function Hardcore:InitiatePulsePlayed()
	--init time played
	Hardcore:RequestTimePlayed()

	--time accumulator
	C_Timer.NewTicker(TIME_TRACK_PULSE, function()
		HardcoreUnlocked_Character.time_tracked = HardcoreUnlocked_Character.time_tracked + TIME_TRACK_PULSE
		if RECEIVED_FIRST_PLAYED_TIME_MSG == true then
			HardcoreUnlocked_Character.accumulated_time_diff = HardcoreUnlocked_Character.time_played
				- HardcoreUnlocked_Character.time_tracked
		end
	end)

	--played time tracking
	C_Timer.NewTicker(TIME_PLAYED_PULSE, function()
		Hardcore:RequestTimePlayed()
	end)
end

function Hardcore:ReceivePulse(data, sender)
	local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()

	if sender == FULL_PLAYER_NAME then
		return
	end

	-- Hardcore:Debug('Received pulse from: '..sender..'. data: '..data)

	Hardcore:CheckVersionsAndUpdate(sender, data)

	-- Set my versions
	local version = GetAddOnMetadata("HardcoreUnlocked", "Version")
	if version ~= guild_highest_version then
		guild_versions_status[FULL_PLAYER_NAME] = "outdated"
	end

	local current_os_time = time()
	if guild_player_first_ping_time[sender] == nil or current_os_time - pulses[sender] > DETECT_OFFLINE_DURATION then
		guild_player_first_ping_time[sender] = current_os_time
	end

	pulses[sender] = time()
end

function Hardcore:CheckVersionsAndUpdate(playername, versionstring)
	if guild_highest_version == nil then
		guild_highest_version = GetAddOnMetadata("HardcoreUnlocked", "Version")
	end

	-- Hardcore:Debug('Comparing: data: '..versionstring.. ' to guild_highest_version: '..guild_highest_version)
	if versionstring ~= guild_highest_version then
		local greaterVersion = Hardcore_GetGreaterVersion(versionstring, guild_highest_version)
		-- Hardcore:Debug('higest is: '..greaterVersion)

		-- if received pulse is newer version, update the local, highest version
		if guild_highest_version ~= greaterVersion then
			-- Hardcore:Debug('setting higestversion to: '..greaterVersion)

			guild_highest_version = greaterVersion
			-- invalidate status table
			guild_versions_status = {}
			guild_versions_status[playername] = "updated"
		else -- if received pulse is older version, set sender to outdated
			-- Hardcore:Debug('setting sender to: outdated')
			guild_versions_status[playername] = "outdated"
		end
	else -- if received pulse has same version, set to updated
		guild_versions_status[playername] = "updated"
	end

	guild_versions[playername] = versionstring
	hardcore_modern_menu_state.guild_versions[playername] = versionstring
	hardcore_modern_menu_state.guild_versions_status[playername] = guild_versions_status[playername]
	hardcore_modern_menu_state.changeset[(string.split("-", playername))] = 1
end

function Hardcore:UpdateGuildRosterRows()
	if display == "AddonStatus" then
		local f = {}
		for name, playerData in pairs(guild_online) do
			table.insert(f, playerData)
		end
		table.sort(f, Hardcore_SortByLevel)
		displaylist = f

		Hardcore_Deathlist_ScrollBar_Update()
	end
end

function Hardcore:FetchGuildRoster()
	guild_roster_loading = true
	local num_ellipsis = 4

	-- Request a new roster update when we show the addonstatus list
	SetGuildRosterShowOffline(false)
	requestGuildRoster = C_Timer.NewTicker(2, function()
		if guild_roster_loading then
			if display == "AddonStatus" then
				Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE_LOADING)
			end
			GuildRoster()
		else
			requestGuildRoster:Cancel()
		end
	end)
end

function Hardcore:HandleLegacyDeaths()
	if type(HardcoreUnlocked_Character.deaths) == "number" then
		local deathcount = HardcoreUnlocked_Character.deaths
		HardcoreUnlocked_Character.deaths = {}
		for i = 1, deathcount do
			table.insert(HardcoreUnlocked_Character.deaths, {
				player_dead_trigger = date("%m/%d/%y %H:%M:%S"),
				player_alive_trigger = date("%m/%d/%y %H:%M:%S"),
			})
		end
	end
end

function Hardcore:ApplyAlertFrameSettings()
	local scale = HardcoreUnlocked_Settings.alert_frame_scale or 0.7
	local x_offset = HardcoreUnlocked_Settings.alert_frame_x_offset or 0
	local y_offset = HardcoreUnlocked_Settings.alert_frame_y_offset or 0
	Hardcore_Alert_Frame:SetScale(scale)
	Hardcore_Alert_Frame:SetPoint("TOP", "UIParent", "TOP", x_offset / scale, y_offset / scale)
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(frame, event, message, sender, ...)
	if
		hc_mute_inguild
		and guild_online[sender]
		and guild_online[sender]["level"]
		and tonumber(hc_mute_inguild) >= guild_online[sender]["level"]
	then
		return
	end

	if HardcoreUnlocked_Settings.filter_f_in_chat then
		if message == "f" or message == "F" then
			return true, message, sender, ...
		end
	end
	if HardcoreUnlocked_Settings.show_version_in_chat then
		if guild_versions[sender] then
			message = "|cfffd9122[" .. guild_versions[sender] .. "]|r " .. message
		end
	end

	return false, message, sender, ... -- don't hide this message
	-- note that you must return *all* of the values that were passed to your filter, even ones you didn't change
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(frame, event, message, sender, ...)
	if message:match("No player named") and message:match("is currently playing") then
		return true, nil, sender, ...
	end
	return false, message, sender, ... -- don't hide this message
end)

function Hardcore:SetGriefAlertCondition(grief_alert_option)
	if grief_alert_option == "off" then
		HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_OFF
		Hardcore:Print("Grief alert set to off.")
	elseif grief_alert_option == "horde" then
		if PLAYER_FACTION == "Horde" then
			HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_SAME_FACTION
			Hardcore:Print("Grief alert set to same faction.")
		else
			HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_ENEMY_FACTION
			Hardcore:Print("Grief alert set to enemy faction.")
		end
	elseif grief_alert_option == "alliance" then
		if PLAYER_FACTION == "Alliance" then
			HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_SAME_FACTION
			Hardcore:Print("Grief alert set to same faction.")
		else
			HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_ENEMY_FACTION
			Hardcore:Print("Grief alert set to enemy faction.")
		end
	elseif grief_alert_option == "both" then
		HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS
		Hardcore:Print("Grief alert set to both factions.")
	else
		local grief_alert_setting_msg = ""
		if HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_OFF then
			grief_alert_setting_msg = "off"
		elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
			if PLAYER_FACTION == "Alliance" then
				grief_alert_setting_msg = "same faction (alliance)"
			else
				grief_alert_setting_msg = "same faction (horde)"
			end
		elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
			if PLAYER_FACTION == "Alliance" then
				grief_alert_setting_msg = "enemy faction (horde)"
			else
				grief_alert_setting_msg = "enemy faction (alliance)"
			end
		elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_BOTH_FACTIONS then
			grief_alert_setting_msg = "both factions"
		end
		Hardcore:Print("Grief alert is currently set to: " .. grief_alert_setting_msg)
		Hardcore:Print("|cff00ff00Grief alert options:|r off horde alliance both")
	end
end

function Hardcore:SetPronoun(pronoun_option)
	if pronoun_option == "off" then
		HardcoreUnlocked_Character.custom_pronoun = false
		Hardcore:Print("Custom pronoun set to off.")
	elseif pronoun_option == "her" then
		HardcoreUnlocked_Character.custom_pronoun = "Her"
		Hardcore:Print("Custom pronoun set to 'Her'.")
	elseif pronoun_option == "his" then
		HardcoreUnlocked_Character.custom_pronoun = "His"
		Hardcore:Print("Custom pronoun set to 'His'.")
	elseif pronoun_option == "their" then
		HardcoreUnlocked_Character.custom_pronoun = "Their"
		Hardcore:Print("Custom pronoun set to 'Their'.")
	else
		local custom_pronoun_msg = HardcoreUnlocked_Character.custom_pronoun or "off"
		Hardcore:Print("Custom pronoun for last words currently set to: " .. custom_pronoun_msg)
		Hardcore:Print("|cff00ff00Custom pronoun options:|r off her his their")
	end
end

function Hardcore:SetGlobalPronoun(gpronoun_option)
	if gpronoun_option == "off" then
		HardcoreUnlocked_Settings.global_custom_pronoun = false
		Hardcore:Print("Global custom pronoun set to off.")
	elseif gpronoun_option == "her" then
		HardcoreUnlocked_Settings.global_custom_pronoun = "Her"
		Hardcore:Print("Global custom pronoun set to 'Her'.")
	elseif gpronoun_option == "his" then
		HardcoreUnlocked_Settings.global_custom_pronoun = "His"
		Hardcore:Print("Global custom pronoun set to 'His'.")
	elseif gpronoun_option == "their" then
		HardcoreUnlocked_Settings.global_custom_pronoun = "Their"
		Hardcore:Print("Global custom pronoun set to 'Their'.")
	else
		local custom_pronoun_msg = HardcoreUnlocked_Settings.global_custom_pronoun or "off"
		Hardcore:Print("Global custom pronoun for last words currently set to: " .. custom_pronoun_msg)
		Hardcore:Print("|cff00ff00Global custom pronoun options:|r off her his their")
	end
end

local options = {
	name = "Hardcore",
	handler = Hardcore,
	type = "group",
	args = {
		alert_options_header = {
			type = "group",
			name = "Alerts",
			order = 1,
			inline = true,
			args = {
				show_death_log = {
					type = "toggle",
					name = "Show death log",
					desc = "Show death log",
					get = function()
						if
							HardcoreUnlocked_Settings.death_log_show == nil
							or HardcoreUnlocked_Settings.death_log_show == true
						then
							return true
						else
							return false
						end
					end,
					set = function()
						if HardcoreUnlocked_Settings.death_log_show == nil then
							HardcoreUnlocked_Settings.death_log_show = true
						end
						HardcoreUnlocked_Settings.death_log_show = not HardcoreUnlocked_Settings.death_log_show
						deathlogApplySettings(HardcoreUnlocked_Settings)
					end,
					order = 1,
				},
				death_log_types = {
					type = "select",
					name = "Death log entries",
					desc = "Type of death alerts.",
					values = {
						guild_only = "guild only",
						faction_wide = "faction wide",
					},
					get = function()
						if HardcoreUnlocked_Settings.death_log_types == nil then
							HardcoreUnlocked_Settings.death_log_types = "faction_wide"
						end
						return HardcoreUnlocked_Settings.death_log_types
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.death_log_types = value
					end,
					order = 2,
				},
				max_entries = {
					type = "range",
					name = "Max entries to record",
					desc = "Specifies how many entries to keep recorded.",
					min = 0,
					max = 100000,
					get = function()
						if HardcoreUnlocked_Settings.deathlog_max_entries == nil then
							HardcoreUnlocked_Settings.deathlog_max_entries = 0
						end
						return HardcoreUnlocked_Settings.deathlog_max_entries
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.deathlog_max_entries = value
					end,
					order = 4,
				},
				death_alerts = {
					type = "select",
					name = "Death alerts",
					desc = "Type of death alerts.",
					values = {
						off = "off",
						guild_only = "guild only",
						faction_wide = "faction wide",
					},
					get = function()
						if HardcoreUnlocked_Settings.notify then
							if HardcoreUnlocked_Settings.alert_subset then
								return HardcoreUnlocked_Settings.alert_subset
							end
							return "faction_wide"
						end
						return "off"
					end,
					set = function(info, value)
						if value == off then
							HardcoreUnlocked_Settings.notify = false
							return
						end
						HardcoreUnlocked_Settings.alert_subset = value
						HardcoreUnlocked_Settings.notify = true
					end,
					order = 2,
				},
				grief_alerts = {
					type = "select",
					name = "Grief alerts",
					desc = "Type of grief alerts.",
					values = {
						off = "off",
						alliance = "alliance",
						horde = "horde",
						both = "both",
					},
					get = function(info)
						if HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_OFF then
							return "off"
						elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
							if PLAYER_FACTION == "Alliance" then
								return "alliance"
							else
								return "horde"
							end
						elseif HardcoreUnlocked_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
							if PLAYER_FACTION == "Horde" then
								return "alliance"
							else
								return "horde"
							end
						else
							return "both"
						end
					end,
					set = function(info, value)
						Hardcore:SetGriefAlertCondition(value)
					end,
					order = 3,
				},
				minimum_alert_level = {
					type = "input",
					name = "Minimum Alert Level",
					desc = "Minimum Alert Level",
					get = function()
						return HardcoreUnlocked_Settings.minimum_show_death_alert_lvl or "0"
					end,
					set = function(info, val)
						HardcoreUnlocked_Settings.minimum_show_death_alert_lvl = val
					end,
					order = 3,
				},
				reset_death_log_pos = {
					type = "execute",
					name = "Reset death log pos.",
					desc = "Reset the death log pos.",
					func = function(info, value)
						hardcore_settings["death_log_pos"] = { ["x"] = 0, ["y"] = 0 }
						deathlogApplySettings(HardcoreUnlocked_Settings)
					end,
					order = 5,
				},
			},
		},
		alert_pos_group = {
			type = "group",
			name = "Alert position and scale",
			inline = true,
			order = 4,
			args = {
				alerts_x_pos = {
					type = "range",
					name = "X-offset",
					desc = "Modify alert frame's x-offset.",
					min = -100,
					max = 100,
					get = function()
						return HardcoreUnlocked_Settings.alert_frame_x_offset / 10
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.alert_frame_x_offset = value * 10
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alerts_y_pos = {
					type = "range",
					name = "Y-offset",
					desc = "Modify alert frame's y-offset.",
					min = -100,
					max = 100,
					get = function()
						return HardcoreUnlocked_Settings.alert_frame_y_offset / 10
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.alert_frame_y_offset = value * 10
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alerts_scale = {
					type = "range",
					name = "Scale",
					desc = "Modify alert frame's scale.",
					min = 0.1,
					max = 2,
					get = function()
						return HardcoreUnlocked_Settings.alert_frame_scale
					end,
					set = function(info, value)
						if value < 0.1 then
							value = 0.1
						end
						HardcoreUnlocked_Settings.alert_frame_scale = value
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alert_sample = {
					type = "execute",
					name = "show",
					desc = "Show sample alert.",
					func = function(info, value)
						Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_sample, "Sample alert frame text.")
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 5,
				},
			},
		},
		achievement_alert_pos_group = {
			type = "group",
			name = "Achievement alert position and scale",
			inline = true,
			order = 5,
			args = {
				alerts_x_pos = {
					type = "range",
					name = "X-offset",
					desc = "Modify achievement alert frame's x-offset.",
					min = -100,
					max = 100,
					get = function()
						local _x_offset = HardcoreUnlocked_Settings.achievement_alert_frame_x_offset or 0
						return _x_offset / 10
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.achievement_alert_frame_x_offset = value * 10
						local _x_offset = HardcoreUnlocked_Settings.achievement_alert_frame_x_offset or 0
						local _y_offset = HardcoreUnlocked_Settings.achievement_alert_frame_y_offset or 0
						local _scale = HardcoreUnlocked_Settings.achievement_alert_frame_scale or 1
						achievement_alert_handler:ApplySettings(_x_offset, _y_offset, _scale)
					end,
					order = 4,
				},
				alerts_y_pos = {
					type = "range",
					name = "Y-offset",
					desc = "Modify achievement alert frame's y-offset.",
					min = -100,
					max = 100,
					get = function()
						local _y_offset = HardcoreUnlocked_Settings.achievement_alert_frame_y_offset or 0
						return _y_offset / 10
					end,
					set = function(info, value)
						HardcoreUnlocked_Settings.achievement_alert_frame_y_offset = value * 10
						local _x_offset = HardcoreUnlocked_Settings.achievement_alert_frame_x_offset or 0
						local _y_offset = HardcoreUnlocked_Settings.achievement_alert_frame_y_offset or 0
						local _scale = HardcoreUnlocked_Settings.achievement_alert_frame_scale or 1
						achievement_alert_handler:ApplySettings(_x_offset, _y_offset, _scale)
					end,
					order = 4,
				},
				alerts_scale = {
					type = "range",
					name = "Scale",
					desc = "Modify achievement alert frame's scale.",
					min = 0.1,
					max = 2,
					disabled = true,
					get = function()
						return HardcoreUnlocked_Settings.achievement_alert_frame_scale or 1.0
					end,
					set = function(info, value)
						if value < 0.1 then
							value = 0.1
						end
						HardcoreUnlocked_Settings.achievement_alert_frame_scale = value
						local _x_offset = HardcoreUnlocked_Settings.achievement_alert_frame_x_offset or 0
						local _y_offset = HardcoreUnlocked_Settings.achievement_alert_frame_y_offset or 0
						local _scale = HardcoreUnlocked_Settings.achievement_alert_frame_scale or 1
						achievement_alert_handler:ApplySettings(_x_offset, _y_offset, _scale)
					end,
					order = 4,
				},
				alert_sample = {
					type = "execute",
					name = "show",
					desc = "Show sample achievement alert.",
					func = function(info, value)
						local _x_offset = HardcoreUnlocked_Settings.achievement_alert_frame_x_offset or 0
						local _y_offset = HardcoreUnlocked_Settings.achievement_alert_frame_y_offset or 0
						local _scale = HardcoreUnlocked_Settings.achievement_alert_frame_scale or 1
						achievement_alert_handler:ApplySettings(_x_offset, _y_offset, _scale)
						Hardcore:ShowPassiveAchievementFrame(
							_G.passive_achievements["MasterHerbalism"].icon_path,
							_G.passive_achievements["MasterHerbalism"].title,
							25.0
						)
					end,
					order = 5,
				},
			},
		},
		chat_filter_header = {
			type = "group",
			name = "Chat filters",
			order = 6,
			inline = true,
			args = {
				f_in_chat_filter = {
					type = "toggle",
					name = "Filter F in chat",
					desc = "Remove Fs in chat.",
					get = function()
						return HardcoreUnlocked_Settings.filter_f_in_chat
					end,
					set = function()
						HardcoreUnlocked_Settings.filter_f_in_chat = not HardcoreUnlocked_Settings.filter_f_in_chat
					end,
					order = 7,
				},
				version_in_chat_filter = {
					type = "toggle",
					name = "HC versions in chat",
					desc = "Show player versions in chat.",
					get = function()
						return HardcoreUnlocked_Settings.show_version_in_chat
					end,
					set = function()
						HardcoreUnlocked_Settings.show_version_in_chat =
							not HardcoreUnlocked_Settings.show_version_in_chat
					end,
					order = 8,
				},
			},
		},
		miscellaneous_header = {
			type = "group",
			name = "Miscellaneous",
			order = 9,
			inline = true,
			args = {
				show_minimap_icon = {
					type = "toggle",
					name = "Show minimap mail icon",
					desc = "Show minimap mail icon",
					get = function()
						return HardcoreUnlocked_Settings.show_minimap_mailbox_icon
					end,
					set = function()
						HardcoreUnlocked_Settings.show_minimap_mailbox_icon =
							not HardcoreUnlocked_Settings.show_minimap_mailbox_icon
						if HardcoreUnlocked_Settings.show_minimap_mailbox_icon == true then
							MiniMapMailIcon:Show()
							MiniMapMailBorder:Show()
						else
							MiniMapMailIcon:Hide()
							MiniMapMailBorder:Hide()
						end
					end,
					order = 10,
				},
				use_alternative_menu = {
					type = "toggle",
					name = "Use old menu",
					desc = "Use old menu.  This feature replaces the menu that shows with /hardcore show.",
					get = function()
						return HardcoreUnlocked_Settings.use_alternative_menu
					end,
					set = function()
						HardcoreUnlocked_Settings.use_alternative_menu =
							not HardcoreUnlocked_Settings.use_alternative_menu
					end,
					order = 12,
				},
				show_minimap_icon_option = {
					type = "toggle",
					name = "Show minimap icon",
					desc = "Show minimap icon",
					get = function()
						return not HardcoreUnlocked_Settings.hide
					end,
					set = function()
						Hardcore:ToggleMinimapIcon()
					end,
					order = 13,
				},
			},
		},
		cross_guild_header = {
			type = "group",
			name = "Cross-Guild",
			order = 14,
			inline = true,
			args = {
				ignore_xguild_chat = {
					width = "full",
					type = "toggle",
					name = "Ignore cross-guild chat [Requires reload]",
					desc = "Ignore cross-guild chat [Requires reload]",
					get = function()
						return HardcoreUnlocked_Settings.ignore_xguild_chat
					end,
					set = function()
						HardcoreUnlocked_Settings.ignore_xguild_chat = not HardcoreUnlocked_Settings.ignore_xguild_chat
					end,
					order = 15,
				},
				ignore_xguild_alerts = {
					type = "toggle",
					name = "Ignore cross-guild alerts",
					desc = "Ignore cross-guild alerts",
					get = function()
						return HardcoreUnlocked_Settings.ignore_xguild_alerts
					end,
					set = function()
						HardcoreUnlocked_Settings.ignore_xguild_alerts =
							not HardcoreUnlocked_Settings.ignore_xguild_alerts
					end,
					order = 17,
				},
			},
		},
		apply_defaults = {
			type = "execute",
			name = "Defaults",
			desc = "Change back to default configuration.",
			func = function()
				HardcoreUnlocked_Settings.show_version_in_chat = false
				HardcoreUnlocked_Settings.filter_f_in_chat = false
				HardcoreUnlocked_Settings.notify = true
				HardcoreUnlocked_Character.grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS
				HardcoreUnlocked_Settings.alert_frame_x_offset = 0
				HardcoreUnlocked_Settings.alert_frame_y_offset = -150
				HardcoreUnlocked_Settings.alert_frame_scale = 0.7
				HardcoreUnlocked_Settings.achievement_alert_frame_x_offset = nil
				HardcoreUnlocked_Settings.achievement_alert_frame_y_offset = nil
				HardcoreUnlocked_Settings.achievement_alert_frame_scale = nil
				HardcoreUnlocked_Settings.show_minimap_mailbox_icon = false
				HardcoreUnlocked_Settings.ignore_xguild_alerts = false
				HardcoreUnlocked_Settings.ignore_xguild_chat = false
				Hardcore:ApplyAlertFrameSettings()
			end,
			order = 20,
		},
	},
}
local f = CreateFrame("frame")
local function HyperlinkHandler(...)
	local _, linkType = ...
	local _, myIdentifier, sender, rules = strsplit(":", linkType)

	if myIdentifier == "myAddonName" then
		if HCU_decodeRules(rules) == nil then
			return
		end
		-- Do whatever you want.
		local name, _ = string.split("-", sender)
		local ruleset = {}

		for _, v in ipairs(HCU_decodeRules(rules)) do
			ruleset[v] = 1
		end
		HCU_showRulesRefFrame(name, ruleset)
	end
end

hooksecurefunc(ItemRefTooltip, "SetHyperlink", HyperlinkHandler)

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(frame, event, message, sender, ...)
	local rules = string.match(message, "HCU{(.*)}")
	if rules then
		message = message:gsub(
			"HCU{" .. rules .. "}",
			"|c0000FFFF|Hitem:myAddonName:" .. sender .. ":" .. rules .. "|h[HC Ruleset]|h|r"
		)
	end
	local sixty_name, sixty_class = string.match(message, "(%w+) the (%w+) has reached level 60!")
	if sixty_name and sixty_class then
		HCU_showLegendaryFrame(sixty_name, sixty_class)
	end
	return false, message, sender, ... -- don't hide this message
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(frame, event, message, sender, ...)
	local rules = string.match(message, "HCU{(.*)}")
	if rules then
		message = message:gsub(
			"HCU{" .. rules .. "}",
			"|c0000FFFF|Hitem:myAddonName:" .. sender .. ":" .. rules .. "|h[HC Ruleset]|h|r"
		)
	end
	return false, message, sender, ... -- don't hide this message
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(frame, event, message, sender, ...)
	local rules = string.match(message, "HCU{(.*)}")
	if rules then
		message = message:gsub(
			"HCU{" .. rules .. "}",
			"|c0000FFFF|Hitem:myAddonName:" .. sender .. ":" .. rules .. "|h[HC Ruleset]|h|r"
		)
	end
	return false, message, sender, ... -- don't hide this message
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", function(frame, event, message, sender, ...)
	local rules = string.match(message, "HCU{(.*)}")
	if rules then
		message = message:gsub(
			"HCU{" .. rules .. "}",
			"|c0000FFFF|Hitem:myAddonName:" .. sender .. ":" .. rules .. "|h[HC Ruleset]|h|r"
		)
	end
	return false, message, sender, ... -- don't hide this message
end)

LibStub("AceConfig-3.0"):RegisterOptionsTable("Hardcore Unlocked", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Hardcore Unlocked", "Hardcore Unlocked")

reorderPassiveAchievements()
--[[ Start Addon ]]
--
Hardcore:Startup()
