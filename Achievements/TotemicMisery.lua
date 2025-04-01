local _G = _G
local totemic_misery_achievement = CreateFrame("Frame")
_G.achievements.TotemicMisery = totemic_misery_achievement

local blacklist_spells_named = {
	"Windfury Totem",
	"Tremor Totem",
	"Grace of Air Totem",
	"Mana Spring Totem",
	"Tranquil Air Totem",
	"Grounding Totem",
	"Stoneskin Totem",
	"Healing Stream Totem",
	"Poison Cleansing Totem",
	"Strength of Earth Totem",
	"Flametongue Totem",
	"Earthbind Totem",
	"Fire Nova Totem",
	"Magma Totem",
	"Frost Resistance Totem",
	"Windwall Totem",
	"Searing Totem",
	"Stoneclaw Totem",
	"Disease Cleansing Totem",
	"Nature Resistance Totem",
	"Fire Resistance Totem",
	"Nature Resistance Totem",
}

-- General info
totemic_misery_achievement.name = "TotemicMisery"
totemic_misery_achievement.title = "Totemic Misery"
totemic_misery_achievement.class = "Shaman"
totemic_misery_achievement.pts = 10
totemic_misery_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_totemic_misery.blp"
totemic_misery_achievement.description = "Complete the Hardcore challenge without at any point summoning a Totem."

-- Registers
function totemic_misery_achievement:Register(fail_function_executor)
	totemic_misery_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	totemic_misery_achievement.fail_function_executor = fail_function_executor
end

function totemic_misery_achievement:Unregister()
	totemic_misery_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
totemic_misery_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		for i, blacklist_spell_named in ipairs(blacklist_spells_named) do
			local spell_name = GetSpellInfo(spell_id)
			if spell_name == blacklist_spell_named then
				Hardcore:Print("Casted totem spell." .. blacklist_spell_named)
				totemic_misery_achievement.fail_function_executor.Fail(totemic_misery_achievement.name)
			end
		end
	end
end)
