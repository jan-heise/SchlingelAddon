local _G = _G
local arcanist_achievement = CreateFrame("Frame")
_G.achievements.Arcanist = arcanist_achievement

-- General info
arcanist_achievement.name = "Arcanist"
arcanist_achievement.title = "Arcanist"
arcanist_achievement.class = "Mage"
arcanist_achievement.pts = 10
arcanist_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_arcanist.blp"
arcanist_achievement.bl_text = "Starting Achievement"
arcanist_achievement.description =
	"Complete the Hardcore challenge using only abilities within the “Arcane” (and “General”) tab of your spellbook. No spells outside of those listed under “Arcane” or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are not in the “Arcane” tab of your spellbook are not allowed to be used."

local whitelist = {
	["133"] = 1,
}

-- Registers
function arcanist_achievement:Register(fail_function_executor)
	arcanist_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	arcanist_achievement:RegisterEvent("SPELLS_CHANGED")
	arcanist_achievement:GatherBlackList()
	arcanist_achievement.fail_function_executor = fail_function_executor
end

function arcanist_achievement:Unregister()
	arcanist_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	arcanist_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function arcanist_achievement:GatherBlackList()
	arcanist_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Fire" or name == "Frost" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(arcanist_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
arcanist_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		arcanist_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		if whitelist[spell_id] then
			return
		end
		for i, blacklist_spell in ipairs(arcanist_achievement.blacklist) do
			if spell_name == blacklist_spell then
				arcanist_achievement.fail_function_executor.Fail(arcanist_achievement.name)
				return
			end
		end
	end
end)
