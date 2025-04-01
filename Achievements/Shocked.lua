local _G = _G
local shocked_achievement = CreateFrame("Frame")
_G.achievements.Shocked = shocked_achievement

-- General info
shocked_achievement.name = "Shocked"
shocked_achievement.title = "Shocked"
shocked_achievement.class = "Shaman"
shocked_achievement.pts = 10
shocked_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_shocked.blp"
shocked_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability with a cast time. Only instant spells are allowed. If Nature’s Swiftness makes a spell instant, that spell is allowed to be cast. All items with a cast time (e.g. Hearthstones) are allowed."

-- Registers
function shocked_achievement:Register(fail_function_executor)
	shocked_achievement:RegisterEvent("UNIT_SPELLCAST_START")
	shocked_achievement:GatherBlackList()
	shocked_achievement.fail_function_executor = fail_function_executor
end

function shocked_achievement:Unregister()
	shocked_achievement:UnregisterEvent("UNIT_SPELLCAST_START")
end

function shocked_achievement:GatherBlackList()
	shocked_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		for j = offset + 1, offset + numSlots do
			local spell_name = GetSpellInfo(j, "")
			table.insert(shocked_achievement.blacklist, spell_name)
		end
	end
end

-- Register Definitions
shocked_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_START" then
		spell, _, _, start_time, end_time, _, _, _, _ = UnitCastingInfo("player")
		if end_time - start_time > 0.1 then
			for i, blacklist_spell in ipairs(shocked_achievement.blacklist) do
				if spell == blacklist_spell then
					shocked_achievement.fail_function_executor.Fail(shocked_achievement.name)
					return
				end
			end
		end
	end
end)
