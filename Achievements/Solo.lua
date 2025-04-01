local _G = _G
local solo_rules = CreateFrame("Frame")
_G.extra_rules.Solo = solo_rules

-- General info
solo_rules.name = "Solo"
solo_rules.title = "Solo"
solo_rules.class = "All"
solo_rules.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_default.blp"
solo_rules.description = ""

-- Registers
function solo_rules:Register(fail_function_executor, _hardcore_character) end

function solo_rules:Unregister() end

-- Register Definitions
solo_rules:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
end)
