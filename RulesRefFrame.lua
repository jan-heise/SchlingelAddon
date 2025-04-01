local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

local PaneBackdrop = {
	bgFile = "Interface\\Artifacts\\ArtifactUIWarrior",
	edgeFile = "Interface\\Glues\\COMMON\\TextPanel-Border",
	tile = true,
	tileSize = 400,
	edgeSize = 24,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

frame:SetParent(UIParent)
frame:SetSize(200, 150)
frame:SetPoint("BOTTOM", 0, 150)
frame:SetBackdrop(PaneBackdrop)
frame:SetBackdropColor(0.4, 0.4, 0.4, 1)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
frame:Hide()

_G["HCURulesRefFrame"] = frame
tinsert(UISpecialFrames, "HCURulesRefFrame")

function HCU_showRulesRefFrame(player_name, rules)
	if frame.title == nil then
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.title:SetPoint("TOP", 0, -5)
		frame.title:SetTextColor(1, 1, 1, 1)
		frame.title:SetFont("Fonts\\blei00d.TTF", 16, "")
	end

	if frame.desc == nil then
		frame.desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.desc:SetPoint("TOP", 0, -25)
		frame.desc:SetTextColor(0.8, 0.8, 0.8, 1)
		frame.desc:SetFont("Fonts\\blei00d.TTF", 12, "")
	end
	frame.title:SetText(player_name .. "'s Ruleset")
	local desc = ""

	local idx = 1
	desc = desc .. idx .. ". " .. "Death=Delete" .. "\n"
	for id, _ in pairs(rules) do
		idx = idx + 1
		desc = desc .. idx .. ". " .. HCU_rules[id].name .. "\n"
	end
	frame.desc:SetText(desc)
	frame:SetHeight(frame.desc:GetHeight() + frame.title:GetHeight() + 25)

	frame:Show()

	if frame.exit_button == nil then
		frame.exit_button = CreateFrame("Button", nil, frame)
		frame.exit_button:SetPoint("TOPRIGHT", 0, 0)
		frame.exit_button:SetWidth(25)
		frame.exit_button:SetHeight(25)
		frame.exit_button:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up.PNG")
		frame.exit_button:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up.PNG")
		frame.exit_button:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down.PNG")
	end

	frame.exit_button:SetScript("OnClick", function()
		frame:Hide()
	end)
end
