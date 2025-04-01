local _G = _G
local unrestored_achievement = CreateFrame("Frame")
_G.achievements.Unrestored = unrestored_achievement

-- General info
unrestored_achievement.name = "Unrestored"
unrestored_achievement.title = "Unrestored"
unrestored_achievement.pts = 10
unrestored_achievement.class = "Druid"
unrestored_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_unrestored.blp"
unrestored_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability within the “Restoration” tab of your spellbook. Only spells listed under “Feral Combat”, “Balance”, or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are in the “Restoration” tab of your spellbook are not allowed to be used."

-- Registers
function unrestored_achievement:Register(fail_function_executor)
	unrestored_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	unrestored_achievement:RegisterEvent("SPELLS_CHANGED")
	unrestored_achievement:GatherBlackList()
	unrestored_achievement.fail_function_executor = fail_function_executor
end

function unrestored_achievement:Unregister()
	unrestored_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	unrestored_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function unrestored_achievement:GatherBlackList()
	unrestored_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Restoration" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(unrestored_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
unrestored_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		unrestored_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(unrestored_achievement.blacklist) do
			if spell_name == blacklist_spell then
				unrestored_achievement.fail_function_executor.Fail(unrestored_achievement.name)
				return
			end
		end
	end
end)
