local _G = _G
local pyromancer_achievement = CreateFrame("Frame")
_G.achievements.Pyromancer = pyromancer_achievement

-- General info
pyromancer_achievement.name = "Pyromancer"
pyromancer_achievement.title = "Pyromancer"
pyromancer_achievement.class = "Mage"
pyromancer_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_pyromancer.blp"
pyromancer_achievement.pts = 10
pyromancer_achievement.description =
	"Complete the Hardcore challenge using only abilities within the “Fire” (and “General”) tab of your spellbook. No spells outside of those listed under “Fire” or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are not in the “Fire” tab of your spellbook are not allowed to be used."

-- Registers
function pyromancer_achievement:Register(fail_function_executor)
	pyromancer_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	pyromancer_achievement:RegisterEvent("SPELLS_CHANGED")
	pyromancer_achievement:GatherBlackList()
	pyromancer_achievement.fail_function_executor = fail_function_executor
end

function pyromancer_achievement:Unregister()
	pyromancer_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	pyromancer_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function pyromancer_achievement:GatherBlackList()
	pyromancer_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Arcane" or name == "Frost" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(pyromancer_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
pyromancer_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		pyromancer_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(pyromancer_achievement.blacklist) do
			if spell_name == blacklist_spell then
				pyromancer_achievement.fail_function_executor.Fail(pyromancer_achievement.name)
				return
			end
		end
	end
end)
