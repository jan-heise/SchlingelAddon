local _G = _G
local no_way_out_achievement = CreateFrame("Frame")
_G.achievements.NoWayOut = no_way_out_achievement

local blacklist_spells_named = {
	"Divine Shield",
	"Hand of Freedom",
	"Hand of Protection",
	"Hand of Protection",
	"Divine Protection",
	"Blessing of Protection",
	"Blessing of Freedom",
}

-- General info
no_way_out_achievement.name = "NoWayOut"
no_way_out_achievement.title = "No Way Out"
no_way_out_achievement.pts = 10
no_way_out_achievement.class = "Paladin"
no_way_out_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_no_way_out.blp"
no_way_out_achievement.description =
	"Complete the Hardcore challenge without at any point using an immunity spell. Divine Shield, Divine Protection, Blessing/Hand of Protection, and Blessing/Hand of Freedom are not allowed."

-- Registers
function no_way_out_achievement:Register(fail_function_executor)
	no_way_out_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	no_way_out_achievement.fail_function_executor = fail_function_executor
end

function no_way_out_achievement:Unregister()
	no_way_out_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
no_way_out_achievement:SetScript("OnEvent", function(self, event, ...)
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
				no_way_out_achievement.fail_function_executor.Fail(no_way_out_achievement.name)
			end
		end
	end
end)
