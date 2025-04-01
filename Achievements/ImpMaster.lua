local _G = _G
local imp_master_achievement = CreateFrame("Frame")
_G.achievements.ImpMaster = imp_master_achievement

local blacklist_spells = {
	"Summon Succcubus",
	"Summon Voidwalker",
	"Summon Felhunter",
}

-- General info
imp_master_achievement.name = "ImpMaster"
imp_master_achievement.title = "Imp Master"
imp_master_achievement.class = "Warlock"
imp_master_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_imp_master.blp"
imp_master_achievement.bl_text = "Starting Achievement"
imp_master_achievement.pts = 10
imp_master_achievement.description =
	"Complete the Hardcore challenge without at any point summoning a demon other than the Imp."

-- Registers
function imp_master_achievement:Register(fail_function_executor)
	imp_master_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	imp_master_achievement.fail_function_executor = fail_function_executor
end

function imp_master_achievement:Unregister()
	imp_master_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
imp_master_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(blacklist_spells) do
			if spell_name == blacklist_spell then
				imp_master_achievement.fail_function_executor.Fail(imp_master_achievement.name)
				return
			end
		end
	end
end)
