local _G = _G
local i_can_see_you_achievement = CreateFrame("Frame")
_G.achievements.ICanSeeYou = i_can_see_you_achievement

local blacklist_spells = {
	1784, -- Stealth R1
	1785, -- Stealth R2
	1786, -- Stealth R3
	1787, -- Stealth R4
	20580, -- Shadowmeld
	1856, -- Vanish R1
	1857, -- Vanish R2
}

-- General info
i_can_see_you_achievement.name = "ICanSeeYou"
i_can_see_you_achievement.title = "I Can See You"
i_can_see_you_achievement.class = "Rogue"
i_can_see_you_achievement.bl_text = "Starting Achievement"
i_can_see_you_achievement.pts = 10
i_can_see_you_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_i_can_see_you.blp"
i_can_see_you_achievement.description =
	"Complete the Hardcore challenge without at any point using Stealth, Shadowmeld or Vanish. Invisibility potions are allowed."

-- Registers
function i_can_see_you_achievement:Register(fail_function_executor)
	i_can_see_you_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	i_can_see_you_achievement.fail_function_executor = fail_function_executor
end

function i_can_see_you_achievement:Unregister()
	i_can_see_you_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
i_can_see_you_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit == "player" then
			for i, blacklist_spell in ipairs(blacklist_spells) do
				if spell_id == blacklist_spell then
					Hardcore:Print("Casted stealth spell.")
					i_can_see_you_achievement.fail_function_executor.Fail(i_can_see_you_achievement.name)
				end
			end
		end
	end
end)
