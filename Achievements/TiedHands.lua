local _G = _G
local tied_hands_achievement = CreateFrame("Frame")
_G.achievements.TiedHands = tied_hands_achievement

local blacklist_spells_named = {
	"Berserker Stance",
	"Defensive Stance",
}

-- General info
tied_hands_achievement.name = "TiedHands"
tied_hands_achievement.title = "Tied Hands"
tied_hands_achievement.class = "Warrior"
tied_hands_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_tied_hands.blp"
tied_hands_achievement.pts = 10
tied_hands_achievement.description =
	"Complete the Hardcore challenge without at any point using a stance other than Battle Stance. Switching to Defensive Stance or Berserker Stance is not allowed."

-- Registers
function tied_hands_achievement:Register(fail_function_executor)
	tied_hands_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	tied_hands_achievement.fail_function_executor = fail_function_executor
end

function tied_hands_achievement:Unregister()
	tied_hands_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
tied_hands_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		for i, blacklist_spell_named in ipairs(blacklist_spells_named) do
			local spell_name = GetSpellInfo(spell_id)
			if spell_name == blacklist_spell_named then
				Hardcore:Print("Casted disallowed stance " .. blacklist_spell_named)
				tied_hands_achievement.fail_function_executor.Fail(tied_hands_achievement.name)
			end
		end
	end
end)
