local _menu_width = 900
local _inner_menu_width = 800
local _menu_height = 600
local AceGUI = LibStub("AceGUI-3.0")

hardcore_modern_menu = nil
_G.hardcore_modern_menu_state = {}
hardcore_modern_menu_state.guild_online = {}
hardcore_modern_menu_state.guild_versions = {}
hardcore_modern_menu_state.guild_versions_status = {}
hardcore_modern_menu_state.online_pulsing = {}
hardcore_modern_menu_state.levels_sort_state = "date"
hardcore_modern_menu_state.accountability_sort_state = "v"
hardcore_modern_menu_state.levels_page = 1
hardcore_modern_menu_state.total_levels = 1
hardcore_modern_menu_state.levels_max_page = 1
hardcore_modern_menu_state.changeset = {}
hardcore_modern_menu_state.entry_tbl = {}

local function RequestHCData(target_name)
	if
		other_hardcore_character_cache[target_name] == nil
		or time() - other_hardcore_character_cache[target_name].last_received > 30
	then
		Hardcore:RequestCharacterData(target_name)
	end
end

local date_to_num = {
	["Jan"] = 1,
	["Feb"] = 2,
	["Mar"] = 3,
	["Apr"] = 4,
	["May"] = 5,
	["Jun"] = 6,
	["Jul"] = 7,
	["Aug"] = 8,
	["Sep"] = 9,
	["Oct"] = 10,
	["Nov"] = 11,
	["Dec"] = 12,
}
local function convertToStamp(date_str)
	local pattern = "(%d+) (%d+):(%d+):(%d+) (%d+)"
	local pattern2 = " (%a+)"
	local runday, runhour, runminute, runseconds, runyear = date_str:match(pattern)
	local runmonth = date_str:match(pattern2)
	return time({
		year = runyear,
		month = date_to_num[runmonth],
		day = runday,
		hour = runhour,
		min = runminute,
		sec = runseconds,
	})
end

local sort_functions = {
	["Alph"] = function(t, a, b)
		return a < b
	end,
	["rAlph"] = function(t, a, b)
		return b < a
	end,
	["lvl"] = function(t, a, b)
		return t[a]["level"] > t[b]["level"]
	end,
	["rlvl"] = function(t, a, b)
		return t[b]["level"] > t[a]["level"]
	end,
	["v"] = function(t, a, b)
		return (hardcore_modern_menu_state.guild_versions[a] or "0")
			< (hardcore_modern_menu_state.guild_versions[b] or "0")
	end,
	["rv"] = function(t, a, b)
		return (hardcore_modern_menu_state.guild_versions[a] or "0")
			> (hardcore_modern_menu_state.guild_versions[b] or "0")
	end,
	["date"] = function(t, a, b)
		local t1 = convertToStamp(t[a]["localtime"])
		local t2 = convertToStamp(t[b]["localtime"])
		return t1 > t2
	end,
	["rdate"] = function(t, a, b)
		local t1 = convertToStamp(t[a]["localtime"])
		local t2 = convertToStamp(t[b]["localtime"])
		return t1 < t2
	end,
	["simpledate"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = ""
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = ""
		else
			t1 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end

		local t2 = ""
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = ""
		else
			t2 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end
		return t1 > t2
	end,
	["rsimpledate"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = ""
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = ""
		else
			t1 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end

		local t2 = ""
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = ""
		else
			t2 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end
		return t1 < t2
	end,
	["pt"] = function(t, a, b)
		return t[b]["playedtime"] > t[a]["playedtime"]
	end,
	["rpt"] = function(t, a, b)
		return t[b]["playedtime"] < t[a]["playedtime"]
	end,
	["achievements"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = 0
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = 0
		else
			t1 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end

		local t2 = 0
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = 0
		else
			t2 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end
		return t1 > t2
	end,
	["rachievements"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = 0
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = 0
		else
			t1 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end

		local t2 = 0
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = 0
		else
			t2 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end
		return t1 < t2
	end,
	["mode"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end
		return t1 > t2
	end,
	["rmode"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end
		return t1 < t2
	end,
	["hctag"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end
		return t1 > t2
	end,
	["rhctag"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end
		return t1 < t2
	end,
}

-- sort function from stack overflow
local function spairs(t, order)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	if order then
		table.sort(keys, function(a, b)
			return order(t, a, b)
		end)
	else
		table.sort(keys)
	end

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end
local function CreateHeadingLabel(title, frame)
	local label = AceGUI:Create("Label")
	label:SetWidth(500)
	label:SetText(title)
	label:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
	frame:AddChild(label)
end
local function CreateDescriptionLabel(text, frame)
	local label = AceGUI:Create("Label")
	label:SetWidth(900)
	label:SetText(text)
	label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	frame:AddChild(label)
end

local rule_pool_frame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
rule_pool_frame.rule_frame = {}
local function DrawGeneralTab(container)
	local rule_container = AceGUI:Create("SimpleGroup")
	rule_container:SetFullWidth(true)
	rule_container:SetFullHeight(true)
	rule_container:SetLayout("Fill")
	container:AddChild(rule_container)

	local txt = GetGuildInfoText() --.. "HCU{huE`W}" -- for debug only
	local guild_ruleset_guild = nil
	if txt then
		local guild_rules = string.match(txt, "HCU{(.*)}")
		if guild_rules then
			HCU_applyFromCode(HardcoreUnlocked_Character, guild_rules)
			local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
			-- Hardcore:Print("Applying guild rules for: " .. guildName)
			-- HCU_enableRules(HardcoreUnlocked_Character)
			guild_ruleset_guild = guildName
		end
	end

	local function refreshShownRules()
		if rule_pool_frame.current_rules_display and rule_pool_frame.current_rules_display.rules then
			local msg = ""
			local idx = 1
			msg = msg .. idx .. ". " .. "Death=Delete" .. "\n"
			for id, _ in pairs(HardcoreUnlocked_Character.rules) do
				idx = idx + 1
				msg = msg .. idx .. ". " .. HCU_rules[id].name .. "\n"
			end
			rule_pool_frame.current_rules_display.rules:SetText(msg)

			if HardcoreUnlocked_Character.rules == nil then
				HardcoreUnlocked_Character.rules = {}
			end
			local encoded = HCU_encodeRules(HardcoreUnlocked_Character.rules)
			rule_pool_frame.current_rules_display.code:SetText("Rule Code: " .. encoded)

			rule_pool_frame.copy_paste_code:SetText("HCU{" .. encoded .. "}")
		end
	end

	local function createRuleFrame(rule_id)
		local frame = CreateFrame("frame")
		frame:SetParent(rule_pool_frame)
		frame:SetWidth(224 * 3 / 4)
		frame:SetHeight(56 * 3 / 4)
		frame:SetPoint("TOPLEFT", rule_pool_frame, "TOPLEFT", 0, 0)
		frame:Show()

		local tex = frame:CreateTexture(nil, "OVERLAY")
		tex:SetDrawLayer("OVERLAY", 7)
		tex:SetTexture("Interface\\LootFrame\\LootToastAtlas")
		tex:SetTexCoord(0.55, 0.82, 0.4, 0.67)
		tex:SetAllPoints()
		tex:Show()

		frame.glow = frame:CreateTexture(nil, "OVERLAY")
		frame.glow:SetDrawLayer("OVERLAY", 7)
		frame.glow:SetTexture("Interface\\LootFrame\\LootToastAtlas")
		frame.glow:SetTexCoord(0., 0.275, 0., 0.4)
		frame.glow:SetVertexColor(0.5, 1, 0.5, 0.5)
		frame.glow:SetAllPoints()
		frame.glow:SetBlendMode("ADD")
		frame.glow:Hide()

		frame.icon = frame:CreateTexture(nil, "OVERLAY")
		frame.icon:SetDrawLayer("OVERLAY", 6)
		frame.icon:SetTexture("Interface\\" .. HCU_rules[rule_id].icon)
		frame.icon:SetPoint("LEFT", 20, 0)
		frame.icon:SetWidth(frame:GetHeight() * 0.6)
		frame.icon:SetHeight(frame:GetHeight() * 0.6)
		frame.icon:Show()

		local font = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		font:SetFont("FONTS\\FRIZQT__.ttf", 11, "")
		font:SetWidth(frame:GetWidth() - 50)
		font:SetTextColor(1, 1, 1, 1)
		font:SetPoint("TOP", 20, -14)
		font:SetJustifyH("CENTER")
		font:SetText(HCU_rules[rule_id].name)
		font:Show()

		local desription = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		desription:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
		desription:SetWidth(frame:GetWidth() - 50)
		desription:SetTextColor(0.7, 0.7, 0.7, 1)
		if #HCU_rules[rule_id].description > 30 then
			desription:SetPoint("TOP", 30, -27)
		else
			desription:SetPoint("TOP", 30, -35)
		end
		desription:SetJustifyH("LEFT")
		desription:SetText(HCU_rules[rule_id].description)
		desription:Hide()

		frame:EnableMouse(true)
		frame:SetScript("OnMouseDown", function()
			if HardcoreUnlocked_Character.rules[rule_id] == nil then
				HardcoreUnlocked_Character.rules[rule_id] = 1
			else
				HardcoreUnlocked_Character.rules[rule_id] = nil
			end

			if HardcoreUnlocked_Character.rules[rule_id] then
				rule_pool_frame.rule_frame[rule_id].icon:SetDesaturated(nil)

				frame.glow:Show()
			else
				rule_pool_frame.rule_frame[rule_id].icon:SetDesaturated(1)
				frame.glow:Hide()
			end
			HCU_disableRules(HardcoreUnlocked_Character)
			HCU_enableRules(HardcoreUnlocked_Character)
			refreshShownRules()
		end)

		frame:SetScript("OnEnter", function(widget)
			GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
			GameTooltip:AddLine(HCU_rules[rule_id].name)
			GameTooltip:AddLine(HCU_rules[rule_id].description, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function(widget)
			GameTooltip:Hide()
		end)
		return frame
	end

	for i = 1, #HCU_rule_ids do
		if rule_pool_frame.rule_frame[i] == nil then
			rule_pool_frame.rule_frame[i] = createRuleFrame(i)
		end
		rule_pool_frame.rule_frame[i]:SetPoint(
			"TOPLEFT",
			rule_pool_frame,
			"TOPLEFT",
			((i + 1) % 3) * 175 + 25,
			math.floor((i - 1) / 3) * -50 - 200
		)
		if HardcoreUnlocked_Character.rules[i] then
			rule_pool_frame.rule_frame[i].icon:SetDesaturated(nil)
			rule_pool_frame.rule_frame[i].glow:Show()
		else
			rule_pool_frame.rule_frame[i].icon:SetDesaturated(1)
			rule_pool_frame.rule_frame[i].glow:Hide()
		end
	end

	rule_pool_frame:SetWidth(container.frame:GetWidth())
	rule_pool_frame:SetHeight(container.frame:GetHeight())
	rule_pool_frame:SetParent(rule_container.frame)

	rule_pool_frame:SetAllPoints(container.border)
	rule_pool_frame:Show()

	if rule_pool_frame.current_rules_display == nil then
		rule_pool_frame.current_rules_display = rule_pool_frame:CreateTexture(nil, "OVERLAY")
		rule_pool_frame.current_rules_display.font = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		rule_pool_frame.current_rules_display.code = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		rule_pool_frame.current_rules_display.rules = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		rule_pool_frame.title = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		rule_pool_frame.desc = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end
	rule_pool_frame.current_rules_display:SetDrawLayer("OVERLAY", 7)
	rule_pool_frame.current_rules_display:SetTexture("Interface\\Store\\Services")
	rule_pool_frame.current_rules_display:SetTexCoord(0.05, 0.45, 0.08, 0.79)
	rule_pool_frame.current_rules_display:SetWidth(250)
	rule_pool_frame.current_rules_display:SetHeight(450)
	rule_pool_frame.current_rules_display:SetPoint("RIGHT", -20, 0)
	rule_pool_frame.current_rules_display:Show()

	rule_pool_frame.current_rules_display.font:SetFont(
		"Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf",
		20,
		""
	)
	rule_pool_frame.current_rules_display.font:SetWidth(rule_pool_frame.current_rules_display:GetWidth() - 15)
	rule_pool_frame.current_rules_display.font:SetTextColor(1, 1, 1, 1)
	rule_pool_frame.current_rules_display.font:SetPoint("TOP", rule_pool_frame.current_rules_display, "TOP", 0, -30)
	rule_pool_frame.current_rules_display.font:SetJustifyH("CENTER")
	if guild_ruleset_guild then
		rule_pool_frame.current_rules_display.font:SetText(guild_ruleset_guild .. "'s Rules")
	else
		rule_pool_frame.current_rules_display.font:SetText(UnitName("player") .. "'s Rules")
	end
	rule_pool_frame.current_rules_display.font:Show()

	rule_pool_frame.current_rules_display.rules:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	rule_pool_frame.current_rules_display.rules:SetWidth(rule_pool_frame.current_rules_display:GetWidth() - 15)
	rule_pool_frame.current_rules_display.rules:SetTextColor(0.8, 0.8, 0.8, 1)
	rule_pool_frame.current_rules_display.rules:SetPoint("TOP", rule_pool_frame.current_rules_display, "TOP", 50, -100)
	rule_pool_frame.current_rules_display.rules:SetJustifyH("LEFT")
	rule_pool_frame.current_rules_display.rules:Show()

	rule_pool_frame.current_rules_display.code:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
	rule_pool_frame.current_rules_display.code:SetWidth(rule_pool_frame.current_rules_display:GetWidth() - 15)
	rule_pool_frame.current_rules_display.code:SetTextColor(0.6, 0.6, 0.6, 1)
	rule_pool_frame.current_rules_display.code:SetPoint(
		"BOTTOM",
		rule_pool_frame.current_rules_display,
		"BOTTOM",
		0,
		30
	)
	rule_pool_frame.current_rules_display.code:SetJustifyH("CENTER")
	rule_pool_frame.current_rules_display.code:SetText(
		"Rule Code: " .. HCU_encodeRules(HardcoreUnlocked_Character.rules)
	)
	rule_pool_frame.current_rules_display.code:Show()

	-- Title
	rule_pool_frame.title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 24, "")
	rule_pool_frame.title:SetWidth(rule_pool_frame.current_rules_display:GetWidth() - 15)
	rule_pool_frame.title:SetTextColor(1, 1, 1, 1)
	rule_pool_frame.title:SetPoint("TOPLEFT", rule_pool_frame, "TOPLEFT", 160, -10)
	rule_pool_frame.title:SetJustifyH("CENTER")
	rule_pool_frame.title:SetText("Hardcore Unlocked")
	rule_pool_frame.title:Show()

	-- Description
	rule_pool_frame.desc:SetFont("Interface\\FONTS\blei00d.ttf", 12, "")
	rule_pool_frame.desc:SetWidth(550)
	rule_pool_frame.desc:SetTextColor(1, 1, 1, 1)
	rule_pool_frame.desc:SetPoint("TOPLEFT", rule_pool_frame, "TOPLEFT", 25, -40)
	rule_pool_frame.desc:SetJustifyH("CENTER")
	rule_pool_frame.desc:SetText(
		"Welcome to Hardcore Unlocked! This is a cut-down version of the original Hardcore addon aiming to improve performance and user experience by removing heavy security features and letting the player choose their own ruleset.  Additionally, joining a guild that uses this addon will enforce that guilds ruleset.  |c00ffff00Officers|r: To enforce a ruleset, copy and paste the 'Officer code' at the bottom of this page into the guild information.\n\n|c00ffff00**READ**|r This addon will not verify you for the website leaderboard\nPlayers using the original Hardcore addon might not group with you.\nGuilds using the original Hardcore addon might not accept you into their guild if they exclusively use the original Hardcore addon."
	)
	rule_pool_frame.desc:Show()

	if rule_pool_frame.rules_heading == nil then
		rule_pool_frame.rules_heading = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		rule_pool_frame.rules_heading:SetText("Rules Selection")
		rule_pool_frame.rules_heading:SetFont("Fonts\\blei00d.TTF", 18, "")
		rule_pool_frame.rules_heading:SetJustifyV("TOP")
		rule_pool_frame.rules_heading:SetJustifyH("CENTER")
		rule_pool_frame.rules_heading:SetTextColor(0.9, 0.9, 0.9)
		rule_pool_frame.rules_heading:SetPoint("TOP", rule_pool_frame.title, "TOP", 0, -170)
		rule_pool_frame.rules_heading:Show()
	end

	if rule_pool_frame.rules_heading_left == nil then
		rule_pool_frame.rules_heading_left = rule_pool_frame:CreateTexture(nil, "BACKGROUND")
		rule_pool_frame.rules_heading_left:SetHeight(8)
		rule_pool_frame.rules_heading_left:SetPoint("LEFT", rule_pool_frame.rules_heading, "LEFT", -60, 0)
		rule_pool_frame.rules_heading_left:SetPoint("RIGHT", rule_pool_frame.rules_heading, "LEFT", -5, 0)
		rule_pool_frame.rules_heading_left:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
		rule_pool_frame.rules_heading_left:SetTexCoord(0.81, 0.94, 0.5, 1)
	end

	if rule_pool_frame.rules_heading_right == nil then
		rule_pool_frame.rules_heading_right = rule_pool_frame:CreateTexture(nil, "BACKGROUND")
		rule_pool_frame.rules_heading_right:SetHeight(8)
		rule_pool_frame.rules_heading_right:SetPoint("RIGHT", rule_pool_frame.rules_heading, "RIGHT", 60, 0)
		rule_pool_frame.rules_heading_right:SetPoint("LEFT", rule_pool_frame.rules_heading, "RIGHT", 5, 0)
		rule_pool_frame.rules_heading_right:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
		rule_pool_frame.rules_heading_right:SetTexCoord(0.81, 0.94, 0.5, 1)
	end

	if rule_pool_frame.copy_paste_code == nil then
		rule_pool_frame.copy_paste_code = CreateFrame("EditBox", nil, rule_pool_frame, "InputBoxTemplate")
	end
	if rule_pool_frame.copy_paste_code.text == nil then
		rule_pool_frame.copy_paste_code.text = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end

	rule_pool_frame.copy_paste_code:SetPoint("TOP", rule_pool_frame.rules_heading, "BOTTOM", 0, -270)
	rule_pool_frame.copy_paste_code:SetPoint("BOTTOM", rule_pool_frame.rules_heading, "BOTTOM", 0, -300)
	rule_pool_frame.copy_paste_code:SetWidth(120)
	rule_pool_frame.copy_paste_code:SetFont("Fonts\\blei00d.TTF", 14, "")
	rule_pool_frame.copy_paste_code:SetMovable(false)
	rule_pool_frame.copy_paste_code:SetBlinkSpeed(1)
	rule_pool_frame.copy_paste_code:SetAutoFocus(false)
	rule_pool_frame.copy_paste_code:SetMultiLine(false)
	rule_pool_frame.copy_paste_code:SetMaxLetters(20)
	rule_pool_frame.copy_paste_code:SetText("")
	rule_pool_frame.copy_paste_code.text:SetPoint("LEFT", rule_pool_frame.copy_paste_code, "LEFT", 0, 15)
	rule_pool_frame.copy_paste_code.text:SetFont("Fonts\\blei00d.TTF", 12, "")
	rule_pool_frame.copy_paste_code.text:SetTextColor(255 / 255, 215 / 255, 0)
	rule_pool_frame.copy_paste_code.text:SetText("Officer Code")
	rule_pool_frame.copy_paste_code.text:Show()

	if rule_pool_frame.whitelist_code == nil then
		rule_pool_frame.whitelist_code = CreateFrame("EditBox", nil, rule_pool_frame, "InputBoxTemplate")
	end
	if rule_pool_frame.whitelist_code.text == nil then
		rule_pool_frame.whitelist_code.text = rule_pool_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end

	rule_pool_frame.whitelist_code:SetPoint("TOP", rule_pool_frame.rules_heading, "BOTTOM", 200, -270)
	rule_pool_frame.whitelist_code:SetPoint("BOTTOM", rule_pool_frame.rules_heading, "BOTTOM", 200, -300)
	rule_pool_frame.whitelist_code:SetWidth(220)
	rule_pool_frame.whitelist_code:SetFont("Fonts\\blei00d.TTF", 14, "")
	rule_pool_frame.whitelist_code:SetMovable(false)
	rule_pool_frame.whitelist_code:SetBlinkSpeed(1)
	rule_pool_frame.whitelist_code:SetAutoFocus(false)
	rule_pool_frame.whitelist_code:SetMultiLine(false)
	rule_pool_frame.whitelist_code:SetMaxLetters(60)
	rule_pool_frame.whitelist_code:SetText(HCU_whitelist_temp or "")
	rule_pool_frame.whitelist_code.text:SetPoint("LEFT", rule_pool_frame.whitelist_code, "LEFT", 0, 15)
	rule_pool_frame.whitelist_code.text:SetFont("Fonts\\blei00d.TTF", 12, "")
	rule_pool_frame.whitelist_code.text:SetTextColor(255 / 255, 215 / 255, 0)
	rule_pool_frame.whitelist_code.text:SetText("Whitelist Code")
	if HCU_whitelist_temp == nil or HCU_whitelist_temp == "" then
		rule_pool_frame.whitelist_code.text:Hide()
		rule_pool_frame.whitelist_code:Hide()
	else
		rule_pool_frame.whitelist_code.text:Show()
		rule_pool_frame.whitelist_code:Show()
	end

	refreshShownRules()

	rule_container.frame:HookScript("OnHide", function()
		rule_pool_frame:Hide()
	end)
end

local function DrawLevelsTab(container, _hardcore_settings)
	local function DrawNameColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("List")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].player .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
	end

	local function DrawLevelColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].level .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
	end

	local function DrawPlayedColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			if _level_list[_player_list[i]].playedtime ~= nil then
				name_str = name_str .. SecondsToTime(_level_list[_player_list[i]].playedtime) .. "\n"
			else
				name_str = name_str .. "\n"
			end
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
	end

	local function DrawDateColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].localtime .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_frame:SetHeight(490)
	scroll_container:AddChild(scroll_frame)

	local row_header = AceGUI:Create("SimpleGroup")
	row_header:SetLayout("Flow")
	row_header:SetFullWidth(true)
	scroll_frame:AddChild(row_header)

	local name_label = AceGUI:Create("InteractiveLabel")
	name_label:SetWidth(150)
	name_label:SetText("|c00FFFF00Name|r")
	name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	row_header:AddChild(name_label)

	name_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "Alph" then
			hardcore_modern_menu_state.levels_sort_state = "Alph"
		else
			hardcore_modern_menu_state.levels_sort_state = "rAlph"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local level_label = AceGUI:Create("InteractiveLabel")
	level_label:SetWidth(50)
	level_label:SetText("|c00FFFF00Lvl|r")
	level_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	row_header:AddChild(level_label)

	level_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "lvl" then
			hardcore_modern_menu_state.levels_sort_state = "lvl"
		else
			hardcore_modern_menu_state.levels_sort_state = "rlvl"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local played_time_label = AceGUI:Create("InteractiveLabel")
	played_time_label:SetWidth(200)
	played_time_label:SetText("|c00FFFF00Played Time|r")
	played_time_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	row_header:AddChild(played_time_label)

	played_time_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "pt" then
			hardcore_modern_menu_state.levels_sort_state = "pt"
		else
			hardcore_modern_menu_state.levels_sort_state = "rpt"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local date_label = AceGUI:Create("InteractiveLabel")
	date_label:SetWidth(200)
	date_label:SetText("|c00FFFF00Date|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	row_header:AddChild(date_label)

	date_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "date" then
			hardcore_modern_menu_state.levels_sort_state = "date"
		else
			hardcore_modern_menu_state.levels_sort_state = "rdate"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local sorted_player_idx = {}
	local max_lines = 500
	hardcore_modern_menu.total_levels = #_hardcore_settings.level_list
	hardcore_modern_menu.max_pages = hardcore_modern_menu.total_levels / max_lines
	for i, v in spairs(_hardcore_settings.level_list, sort_functions[hardcore_modern_menu_state.levels_sort_state]) do
		table.insert(sorted_player_idx, i)
	end

	local start = (hardcore_modern_menu_state.levels_page - 1) * max_lines + 1
	DrawNameColumn(scroll_frame, HardcoreUnlocked_Settings.level_list, sorted_player_idx, 150, start, max_lines)
	DrawLevelColumn(scroll_frame, HardcoreUnlocked_Settings.level_list, sorted_player_idx, 50, start, max_lines)
	DrawPlayedColumn(scroll_frame, HardcoreUnlocked_Settings.level_list, sorted_player_idx, 200, start, max_lines)
	DrawDateColumn(scroll_frame, HardcoreUnlocked_Settings.level_list, sorted_player_idx, 200, start, max_lines)

	local entry = AceGUI:Create("SimpleGroup")
	entry:SetLayout("Flow")
	entry:SetWidth(10)
	scroll_frame:AddChild(entry)

	local button_container = AceGUI:Create("SimpleGroup")
	button_container:SetWidth(_inner_menu_width)
	button_container:SetHeight(100)
	button_container:SetLayout("Flow")
	scroll_container:AddChild(button_container)

	local left_page_button = AceGUI:Create("Button")
	left_page_button:SetText("<")
	left_page_button:SetWidth(50)
	button_container:AddChild(left_page_button)
	left_page_button:SetCallback("OnClick", function()
		if hardcore_modern_menu_state.levels_page > 1 then
			container:ReleaseChildren()
			hardcore_modern_menu_state.levels_page = hardcore_modern_menu_state.levels_page - 1
			DrawLevelsTab(container, _hardcore_settings)
		end
	end)

	local date_label = AceGUI:Create("Label")
	date_label:SetWidth(100)
	date_label:SetText("|c00FFFF00Page " .. hardcore_modern_menu_state.levels_page .. "|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	button_container:AddChild(date_label)

	local date_label = AceGUI:Create("HardcoreClassTitleLabel")
	date_label:SetWidth(490)
	date_label:SetText("|c00FFFF00You've Leveled up " .. #_hardcore_settings.level_list .. " Times!|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	button_container:AddChild(date_label)

	local date_label = AceGUI:Create("HardcoreClassTitleLabel")
	date_label:SetWidth(100)
	date_label:SetText("")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	button_container:AddChild(date_label)

	local right_page_button = AceGUI:Create("Button")
	right_page_button:SetText(">")
	right_page_button:SetWidth(50)
	button_container:AddChild(right_page_button)
	right_page_button:SetCallback("OnClick", function()
		if hardcore_modern_menu_state.levels_page <= hardcore_modern_menu_state.levels_max_page + 1 then
			container:ReleaseChildren()
			hardcore_modern_menu_state.levels_page = hardcore_modern_menu_state.levels_page + 1
			DrawLevelsTab(container, _hardcore_settings)
		end
	end)
end

local function GetSpacelessRealmName()
	local name = GetRealmName()
	return string.gsub(name, "%s+", "")
end

local subtitle_data = {
	{
		"Name",
		100,
		function(_player_name_short, _player_name_long)
			return _player_name_short or ""
		end,
	},
	{
		"Lvl",
		30,
		function(_player_name_short, _player_name_long)
			if hardcore_modern_menu_state.guild_online[_player_name_long] == nil then
				return ""
			end
			return hardcore_modern_menu_state.guild_online[_player_name_long].level or ""
		end,
	},
	{
		"Version",
		90,
		function(_player_name_short, _player_name_long)
			local version_text
			if
				(
					hardcore_modern_menu_state.online_pulsing[_player_name_long]
					and hardcore_modern_menu_state.guild_online[_player_name_long]
				) or _player_name_short == UnitName("player")
			then
				if _player_name_short == UnitName("player") then
					version_text = GetAddOnMetadata("HardcoreUnlocked", "Version")
				else
					version_text = hardcore_modern_menu_state.guild_versions[_player_name_long]
				end

				if hardcore_modern_menu_state.guild_versions_status[_player_name_long] == "updated" then
					version_text = "|c0000ff00" .. version_text .. "|r"
				else
					version_text = "|c00ffff00" .. version_text .. "|r"
				end
			else
				version_text = "|c00ff0000Not detected|r"
			end
			return version_text or ""
		end,
	},
	{
		"Started",
		60,
		function(_player_name_short, _player_name_long)
			if other_hardcore_character_cache[_player_name_short] == nil then
				return ""
			end
			return date("%m/%d/%y", other_hardcore_character_cache[_player_name_short].first_recorded or 0)
		end,
	},
	{
		"Achievements",
		120,
		function(_player_name_short, _player_name_long)
			if other_hardcore_character_cache[_player_name_short] == nil then
				return ""
			end
			if
				other_hardcore_character_cache[_player_name_short].achievements == nil
				or #other_hardcore_character_cache[_player_name_short].achievements > 0
				or #other_hardcore_character_cache[_player_name_short].passive_achievements > 0
			then
				local inline_text = ""
				for i, achievement_name in ipairs(other_hardcore_character_cache[_player_name_short].achievements) do
					if _G.achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				for i, achievement_name in
					ipairs(other_hardcore_character_cache[_player_name_short].passive_achievements)
				do
					if _G.passive_achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.passive_achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				return inline_text
			else
				return ""
			end
		end,
	},
}

local font_container = CreateFrame("Frame")
font_container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
font_container:Show()
local row_entry = {}
local font_strings = {} -- idx/columns
local header_strings = {} -- columns
local row_backgrounds = {} --idx
local max_rows = 48 --idx
local row_height = 10
local guild_member_Width = 850

for idx, v in ipairs(subtitle_data) do
	header_strings[v[1]] = font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if idx == 1 then
		header_strings[v[1]]:SetPoint("TOPLEFT", font_container, "TOPLEFT", 0, 2)
	else
		header_strings[v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
	end
	last_font_string = header_strings[v[1]]
	header_strings[v[1]]:SetJustifyH("LEFT")
	header_strings[v[1]]:SetWordWrap(false)

	if idx + 1 <= #subtitle_data then
		header_strings[v[1]]:SetWidth(v[2])
	end
	header_strings[v[1]]:SetTextColor(0.7, 0.7, 0.7)
	header_strings[v[1]]:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	header_strings[v[1]]:SetText(v[1])
end

for i = 1, max_rows do
	font_strings[i] = {}
	local last_font_string = nil
	for idx, v in ipairs(subtitle_data) do
		font_strings[i][v[1]] = font_container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if idx == 1 then
			font_strings[i][v[1]]:SetPoint("TOPLEFT", font_container, "TOPLEFT", 0, -i * row_height)
		else
			font_strings[i][v[1]]:SetPoint("LEFT", last_font_string, "RIGHT", 0, 0)
		end
		last_font_string = font_strings[i][v[1]]
		font_strings[i][v[1]]:SetJustifyH("LEFT")
		font_strings[i][v[1]]:SetWordWrap(false)

		if idx + 1 <= #subtitle_data then
			font_strings[i][v[1]]:SetWidth(v[2])
		end
		font_strings[i][v[1]]:SetTextColor(1, 1, 1)
		font_strings[i][v[1]]:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	end

	row_backgrounds[i] = font_container:CreateTexture(nil, "OVERLAY")
	row_backgrounds[i]:SetDrawLayer("OVERLAY", 2)
	row_backgrounds[i]:SetVertexColor(0.5, 0.5, 0.5, (i % 2) / 10)
	row_backgrounds[i]:SetHeight(row_height)
	row_backgrounds[i]:SetWidth(guild_member_Width)
	row_backgrounds[i]:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	row_backgrounds[i]:SetPoint("TOPLEFT", font_container, "TOPLEFT", 0, -i * row_height)
end

local function clearGuildMemberData()
	for i, v in ipairs(font_strings) do
		for _, col in ipairs(subtitle_data) do
			v[col[1]]:SetText("")
		end
	end
end

local function setGuildMemberData()
	local rows_used = 1
	for i = 1, GetNumGuildMembers() do
		if rows_used > max_rows then
			break
		end
		local player_name_long, _, _, _, _, _, _, _, online, _, _ = GetGuildRosterInfo(i)
		if online then
			local player_name_short = string.split("-", player_name_long)
			for _, col in ipairs(subtitle_data) do
				font_strings[rows_used][col[1]]:SetText(col[3](player_name_short, player_name_long))
			end
			rows_used = rows_used + 1
		end
	end
end

local function DrawAccountabilityTab(container)
	local function updateLabelData(_label_tbls, player_name_short)
		if other_hardcore_character_cache[player_name_short] ~= nil then
			_label_tbls["party_mode_label"]:SetText(other_hardcore_character_cache[player_name_short].party_mode)
			_label_tbls["first_recorded_label"]:SetText(
				date("%m/%d/%y", other_hardcore_character_cache[player_name_short].first_recorded or 0)
			)

			if
				other_hardcore_character_cache[player_name_short].achievements == nil
				or #other_hardcore_character_cache[player_name_short].achievements > 0
				or #other_hardcore_character_cache[player_name_short].passive_achievements > 0
			then
				local inline_text = ""
				for i, achievement_name in ipairs(other_hardcore_character_cache[player_name_short].achievements) do
					if _G.achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				for i, achievement_name in
					ipairs(other_hardcore_character_cache[player_name_short].passive_achievements)
				do
					if _G.passive_achievements[achievement_name] then
						inline_text = inline_text
							.. "|T"
							.. _G.passive_achievements[achievement_name].icon_path
							.. ":16:16:0:0:64:64:4:60:4:60|t"
					end
				end
				_label_tbls["achievement_label"]:SetText(inline_text)
				_label_tbls["achievement_label"]:SetCallback("OnEnter", function(widget)
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine("achievements")
					for i, achievement_name in ipairs(other_hardcore_character_cache[player_name_short].achievements) do
						if _G.achievements[achievement_name] then
							GameTooltip:AddLine(_G.achievements[achievement_name].title)
						end
					end
					for i, achievement_name in
						ipairs(other_hardcore_character_cache[player_name_short].passive_achievements)
					do
						if _G.passive_achievements[achievement_name] then
							GameTooltip:AddLine(_G.passive_achievements[achievement_name].title)
						end
					end
					GameTooltip:Show()
				end)
				_label_tbls["achievement_label"]:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
			else
				_label_tbls["achievement_label"]:SetText("")
			end
			_label_tbls["hc_tag_label"]:SetText(
				other_hardcore_character_cache[player_name_short].hardcore_player_name or ""
			)
		end

		local player_name_long = player_name_short .. "-" .. GetSpacelessRealmName()
		if hardcore_modern_menu_state.guild_online[player_name_long] ~= nil then
			local version_text
			if
				(
					hardcore_modern_menu_state.online_pulsing[player_name_long]
					and hardcore_modern_menu_state.guild_online[player_name_long]
				) or player_name_short == UnitName("player")
			then
				if player_name_short == UnitName("player") then
					version_text = GetAddOnMetadata("HardcoreUnlocked", "Version")
				else
					version_text = hardcore_modern_menu_state.guild_versions[player_name_long]
				end

				if hardcore_modern_menu_state.guild_versions_status[player_name_long] == "updated" then
					version_text = "|c0000ff00" .. version_text .. "|r"
				else
					version_text = "|c00ffff00" .. version_text .. "|r"
				end
			else
				version_text = "|c00ff0000Not detected|r"
			end
			_label_tbls["version_label"]:SetText(version_text)

			_label_tbls["level_label"]:SetText(hardcore_modern_menu_state.guild_online[player_name_long].level)
		end
	end
	local function addEntry(_scroll_frame, player_name_short, _self_name)
		--local _player_name = player_name_short .. "-" .. GetSpacelessRealmName()
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetFullWidth(true)
		_scroll_frame:AddChild(entry)

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(110)
		name_label:SetText(player_name_short)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(name_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short] = {}

		local level_label = AceGUI:Create("Label")
		level_label:SetWidth(50)
		level_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(level_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["level_label"] = level_label

		local version_label = AceGUI:Create("Label")
		version_label:SetWidth(80)
		version_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(version_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["version_label"] = version_label

		local party_mode_label = AceGUI:Create("Label")
		party_mode_label:SetWidth(75)
		party_mode_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(party_mode_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["party_mode_label"] = party_mode_label

		local first_recorded_label = AceGUI:Create("Label")
		first_recorded_label:SetWidth(85)
		first_recorded_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(first_recorded_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["first_recorded_label"] = first_recorded_label

		local achievement_label = AceGUI:Create("InteractiveLabel")
		achievement_label:SetWidth(320)
		achievement_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(achievement_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["achievement_label"] = achievement_label

		local hc_tag_label = AceGUI:Create("Label")
		hc_tag_label:SetWidth(75)
		hc_tag_label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		entry:AddChild(hc_tag_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["hc_tag_label"] = hc_tag_label

		updateLabelData(hardcore_modern_menu_state.entry_tbl[player_name_short], player_name_short) -- , _player_name)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("List")
	scroll_container:AddChild(scroll_frame)
	font_container:SetParent(scroll_container.frame)
	font_container:SetPoint("TOPLEFT", scroll_container.frame, "TOPLEFT")
	font_container:SetHeight(400)
	font_container:SetWidth(200)
	local function inspectAll()
		for _player_name, _ in
			spairs(
				hardcore_modern_menu_state.guild_online,
				sort_functions[hardcore_modern_menu_state.accountability_sort_state]
			)
		do
			local player_name_short = string.split("-", _player_name)
			if other_hardcore_character_cache[player_name_short] == nil then
				RequestHCData(player_name_short)
			end
		end
	end
	inspectAll()
	setGuildMemberData()

	if font_container.inspect_all_button == nil then
		font_container.inspect_all_button = CreateFrame("Button", nil, font_container)
		font_container.inspect_all_button:SetPoint("TOPLEFT", font_container, "TOPLEFT", 0, -495)
		font_container.inspect_all_button:SetWidth(125)
		font_container.inspect_all_button:SetHeight(40)
		font_container.inspect_all_button:SetNormalTexture("Interface/Buttons/UI-DialogBox-Button-Up.PNG")
		font_container.inspect_all_button:SetHighlightTexture("Interface/Buttons/UI-DialogBox-Button-Highlight.PNG")
		font_container.inspect_all_button:SetPushedTexture("Interface/Buttons/UI-DialogBox-Button-Down.PNG")
		font_container.inspect_all_button.text =
			font_container.inspect_all_button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		font_container.inspect_all_button.text:SetFont(
			"Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf",
			14,
			""
		)
		font_container.inspect_all_button.text:SetWidth(125)
		font_container.inspect_all_button.text:SetTextColor(1, 1, 1, 1)
		font_container.inspect_all_button.text:SetPoint("CENTER", font_container.inspect_all_button, "CENTER", 0, 5)
		font_container.inspect_all_button.text:SetJustifyH("CENTER")
		font_container.inspect_all_button.text:SetText("Inspect All")
	end

	font_container.inspect_all_button:SetScript("OnClick", function()
		inspectAll()
	end)

	hardcore_modern_menu_state.ticker_handler = C_Timer.NewTicker(1, function()
		setGuildMemberData()
	end)

	font_container:Show()
	scroll_container.frame:HookScript("OnHide", function()
		font_container:Hide()
	end)
end

local function DrawAchievementsTab(container)
	local function addEntry(_scroll_frame, _player_name, _self_name) end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)

	local achievements_container_second_row = AceGUI:Create("SimpleGroup")
	achievements_container_second_row:SetRelativeWidth(1.0)
	achievements_container_second_row:SetHeight(50)
	achievements_container_second_row:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container_second_row)
	local function DrawClassContainer(class_container, class, size)
		local c = 0
		for k, v in pairs(_G.achievements) do
			if v.class == class then
				c = c + 1
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(size)
				achievement_icon:SetHeight(size)
				achievement_icon:SetImage(v.icon_path)
				achievement_icon:SetImageSize(size, size)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				SetAchievementTooltip(achievement_icon, achievement, _player_name)
				class_container:AddChild(achievement_icon)
			end
		end

		local achievement_icon = AceGUI:Create("Icon")
		achievement_icon:SetWidth(1)
		achievement_icon:SetHeight(10)
		class_container:AddChild(achievement_icon)
	end

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("General Achievements")
	achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
	achievements_container:AddChild(achievements_title)
	DrawClassContainer(achievements_container, "All", 50)

	local function DrawClassContainer2(container, class, size)
		local class_contianer = AceGUI:Create("SimpleGroup")
		class_contianer:SetWidth(120)
		class_contianer:SetHeight(50)
		class_contianer:SetLayout("Flow")
		container:AddChild(class_contianer)

		local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
		achievements_title:SetRelativeWidth(1.0)
		achievements_title:SetHeight(40)
		achievements_title:SetText(class)
		achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
		class_contianer:AddChild(achievements_title)
		DrawClassContainer(class_contianer, class, size)
	end

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(200)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("\n\n\n\n")
	achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
	scroll_container:AddChild(achievements_title)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	DrawClassContainer2(achievements_container, "Warrior", 36)
	DrawClassContainer2(achievements_container, "Hunter", 36)
	DrawClassContainer2(achievements_container, "Warlock", 36)
	DrawClassContainer2(achievements_container, "Mage", 36)
	DrawClassContainer2(achievements_container, "Druid", 36)
	DrawClassContainer2(achievements_container, "Paladin", 36)
	DrawClassContainer2(achievements_container, "Priest", 36)
	DrawClassContainer2(achievements_container, "Shaman", 36)
	DrawClassContainer2(achievements_container, "Rogue", 36)
end

local function DrawPassiveAchievementsTab(container)
	local function DrawClassContainer(class_container, class, size)
		local c = 0
		for k, v in pairs(_G.passive_achievements) do
			if v.class == class then
				c = c + 1
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(size)
				achievement_icon:SetHeight(size)
				achievement_icon:SetImage(v.icon_path)
				achievement_icon:SetImageSize(size, size)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				achievement_icon:SetCallback("OnEnter", function(widget)
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine(v.title)
					GameTooltip:AddLine(v.description, 1, 1, 1, true)
					GameTooltip:Show()
				end)
				achievement_icon:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
				class_container:AddChild(achievement_icon)
			end
		end

		local achievement_icon = AceGUI:Create("Icon")
		achievement_icon:SetWidth(1)
		achievement_icon:SetHeight(10)
		class_container:AddChild(achievement_icon)
	end

	local function addEntry(_scroll_frame, _player_name, _self_name) end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)

	local achievements_container_second_row = AceGUI:Create("SimpleGroup")
	achievements_container_second_row:SetRelativeWidth(1.0)
	achievements_container_second_row:SetHeight(50)
	achievements_container_second_row:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container_second_row)

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("Passive Achievements")
	achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
	achievements_container:AddChild(achievements_title)
	DrawClassContainer(achievements_container, "All", 50)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(200)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("Alliance Only Achievements")
	achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
	scroll_container:AddChild(achievements_title)

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("Horde Only Achievements")
	achievements_title:SetFont("Interface\\AddOns\\HardcoreUnlocked\\Media\\BreatheFire.ttf", 16, "")
	scroll_container:AddChild(achievements_title)
end

local guild_roster_handler = CreateFrame("Frame")
guild_roster_handler:RegisterEvent("GUILD_ROSTER_UPDATE")

-- Register Definitions
guild_roster_handler:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "GUILD_ROSTER_UPDATE" then
		-- Create a new dictionary of just online people every time roster is updated
		hardcore_modern_menu_state.guild_online = {}
		local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		for i = 1, numOnline, 1 do
			local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
				GetGuildRosterInfo(i)

			-- name is nil after a gquit, so nil check here
			if name then
				hardcore_modern_menu_state.guild_online[name] = {
					name = name,
					level = level,
					classDisplayName = classDisplayName,
				}
			end
		end
	end
end)
