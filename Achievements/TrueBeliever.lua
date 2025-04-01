local _G = _G
local true_believer_achievement = CreateFrame("Frame")
_G.achievements.TrueBeliever = true_believer_achievement

-- General info
true_believer_achievement.name = "TrueBeliever"
true_believer_achievement.title = "True Believer"
true_believer_achievement.class = "Priest"
true_believer_achievement.pts = 10
true_believer_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_true_believer.blp"
true_believer_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability within the “Shadow Magic” tab of your spellbook. Only spells listed under “Holy”, “Discipline”, or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are in the “Shadow Magic” tab of your spellbook are not allowed to be used."

-- Registers
function true_believer_achievement:Register(fail_function_executor)
	true_believer_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	true_believer_achievement:RegisterEvent("SPELLS_CHANGED")
	true_believer_achievement:GatherBlackList()
	true_believer_achievement.fail_function_executor = fail_function_executor
end

function true_believer_achievement:Unregister()
	true_believer_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	true_believer_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function true_believer_achievement:GatherBlackList()
	true_believer_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Shadow Magic" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(true_believer_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
true_believer_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		true_believer_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(true_believer_achievement.blacklist) do
			if spell_name == blacklist_spell then
				true_believer_achievement.fail_function_executor.Fail(true_believer_achievement.name)
				return
			end
		end
	end
end)
