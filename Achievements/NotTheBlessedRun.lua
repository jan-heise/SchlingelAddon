local _G = _G
local not_the_blessed_run_achievement = CreateFrame("Frame")
_G.achievements.NotTheBlessedRun = not_the_blessed_run_achievement

local blacklist_spells_named = {
	"Hand of Freedom",
	"Hand of Salvation",
	"Hand of Protection",
	"Hand of Sacrifice",
	"Blessing of Kings",
	"Blessing of Salvation",
	"Blessing of Wisdom",
	"Blessing of Might",
	"Blessing of Freedom",
	"Blessing of Sacrifice",
	"Blessing of Protection",
	"Blessing of Sanctuary",
	"Greater Blessing of Kings",
	"Greater Blessing of Salvation",
	"Greater Blessing of Wisdom",
	"Greater Blessing of Might",
	"Greater Blessing of Freedom",
	"Greater Blessing of Sacrifice",
	"Greater Blessing of Protection",
	"Greater Blessing of Sanctuary",
	"Concentration Aura",
	"Devotion Aura",
	"Fire Resistance Aura",
	"Shadow Resistance Aura",
	"Frost Resistance Aura",
	"Retribution Aura",
	"Crusader Aura",
}

-- General info
not_the_blessed_run_achievement.name = "NotTheBlessedRun"
not_the_blessed_run_achievement.title = "Not the Blessed Run"
not_the_blessed_run_achievement.class = "Paladin"
not_the_blessed_run_achievement.pts = 10
not_the_blessed_run_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_not_the_blessed_run.blp"
not_the_blessed_run_achievement.description =
	"Complete the Hardcore challenge without at any point using a Blessing/Hand, or Aura spell. Hand of Reckoning is ALLOWED to be used."

-- Registers
function not_the_blessed_run_achievement:Register(fail_function_executor)
	not_the_blessed_run_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	not_the_blessed_run_achievement.fail_function_executor = fail_function_executor
end

function not_the_blessed_run_achievement:Unregister()
	not_the_blessed_run_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
not_the_blessed_run_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		for i, blacklist_spell_named in ipairs(blacklist_spells_named) do
			local spell_name = GetSpellInfo(spell_id)
			if spell_name == blacklist_spell_named then
				Hardcore:Print("Casted aura or blessing spell." .. blacklist_spell_named)
				not_the_blessed_run_achievement.fail_function_executor.Fail(not_the_blessed_run_achievement.name)
			end
		end
	end
end)
