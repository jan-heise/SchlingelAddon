local _G = _G
local cyromancer_achievement = CreateFrame("Frame")
_G.achievements.Cyromancer = cyromancer_achievement

-- General info
cyromancer_achievement.name = "Cyromancer"
cyromancer_achievement.title = "Cyromancer"
cyromancer_achievement.class = "Mage"
cyromancer_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_cyromancer.blp"
cyromancer_achievement.bl_text = "Starting Achievement"
cyromancer_achievement.pts = 10
cyromancer_achievement.description =
	"Complete the Hardcore challenge using only abilities within the “Frost” (and “General”) tab of your spellbook. No spells outside of those listed under “Frost” or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are not in the “Frost” tab of your spellbook are not allowed to be used."

-- Registers
function cyromancer_achievement:Register(fail_function_executor)
	cyromancer_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	cyromancer_achievement:RegisterEvent("SPELLS_CHANGED")
	cyromancer_achievement:GatherBlackList()
	cyromancer_achievement.fail_function_executor = fail_function_executor
end

function cyromancer_achievement:Unregister()
	cyromancer_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	cyromancer_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function cyromancer_achievement:GatherBlackList()
	cyromancer_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Fire" or name == "Arcane" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(cyromancer_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
cyromancer_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		cyromancer_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(cyromancer_achievement.blacklist) do
			if spell_name == blacklist_spell then
				cyromancer_achievement.fail_function_executor.Fail(cyromancer_achievement.name)
				return
			end
		end
	end
end)
