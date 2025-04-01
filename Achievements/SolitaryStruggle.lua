local _G = _G
local solitary_struggle_achievement = CreateFrame("Frame")
_G.achievements.SolitaryStruggle = solitary_struggle_achievement

-- General info
solitary_struggle_achievement.name = "SolitaryStruggle"
solitary_struggle_achievement.title = "Solitary Struggle"
solitary_struggle_achievement.pts = 25
solitary_struggle_achievement.class = "All"
solitary_struggle_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_solitary_struggle.blp"
solitary_struggle_achievement.description =
	"Complete the Hardcore challenge without at any point joining a group for a dungeon. Entering a dungeon alone is allowed."

-- Registers
function solitary_struggle_achievement:Register(fail_function_executor)
	solitary_struggle_achievement:RegisterEvent("GROUP_ROSTER_UPDATE")
	solitary_struggle_achievement.fail_function_executor = fail_function_executor
end

function solitary_struggle_achievement:Unregister()
	solitary_struggle_achievement:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

-- Register Definitions
solitary_struggle_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "GROUP_ROSTER_UPDATE" then
		if GetNumGroupMembers() > 1 then
			solitary_struggle_achievement.fail_function_executor.Fail(solitary_struggle_achievement.name)
		end
	end
end)
