local _G = _G
local not_so_deadly_achievement = CreateFrame("Frame")
_G.achievements.NotSoDeadly = not_so_deadly_achievement

local blacklist_spells_named = {
	"Instant Poison",
	"Blinding Powder",
	"Deadly Poison",
	"Crippling Poison",
	"Mind-numbing Poison",
	"Wound Poison",
}

-- General info
not_so_deadly_achievement.name = "NotSoDeadly"
not_so_deadly_achievement.pts = 10
not_so_deadly_achievement.title = "Not So Deadly"
not_so_deadly_achievement.class = "Rogue"
not_so_deadly_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_not_so_deadly.blp"
not_so_deadly_achievement.description =
	"Complete the Hardcore challenge without at any point using Poisons. Sharpening stones, weapon oils, enchants, and other weapon enhancements are allowed. (Era only note: Create Blinding Powder is a Poisons ability and as such not allowed. Blinding Powder acquired through other means e.g. Pick Pocket can be used."

-- Registers
function not_so_deadly_achievement:Register(fail_function_executor)
	not_so_deadly_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	not_so_deadly_achievement.fail_function_executor = fail_function_executor
end

function not_so_deadly_achievement:Unregister()
	not_so_deadly_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
not_so_deadly_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		for i, blacklist_spell_named in ipairs(blacklist_spells_named) do
			local spell_name = GetSpellInfo(spell_id)
			if spell_name == blacklist_spell_named then
				Hardcore:Print("Casted poison spell." .. blacklist_spell_named)
				not_so_deadly_achievement.fail_function_executor.Fail(not_so_deadly_achievement.name)
			end
		end
	end
end)
