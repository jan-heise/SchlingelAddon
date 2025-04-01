local _G = _G
local not_so_talented_achievement = CreateFrame("Frame")
_G.achievements.NotSoTalented = not_so_talented_achievement

-- General info
not_so_talented_achievement.name = "NotSoTalented"
not_so_talented_achievement.title = "Not So Talented"
not_so_talented_achievement.class = "All"
not_so_talented_achievement.pts = 50
not_so_talented_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_not_so_talented.blp"
not_so_talented_achievement.description =
	"Complete the Hardcore challenge without at any point applying a talent point. No talents are allowed."

-- Registers
function not_so_talented_achievement:Register(fail_function_executor)
	not_so_talented_achievement:RegisterEvent("CHARACTER_POINTS_CHANGED")
	not_so_talented_achievement.fail_function_executor = fail_function_executor

	-- Talent frame might not exist before calling this function
	ToggleTalentFrame()
	if _G["PlayerTalentFrame"] then
		_G["PlayerTalentFrame"]:SetScript("OnShow", function(self)
			Hardcore:Print("Hiding talent frame for Not So Talented.")
			ToggleTalentFrame()
		end)
	end
end

function not_so_talented_achievement:Unregister()
	not_so_talented_achievement:UnregisterEvent("CHARACTER_POINTS_CHANGED")
	not_so_talented_achievement.fail_function_executor = nil
end

-- Register Definitions
not_so_talented_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "CHARACTER_POINTS_CHANGED" then
		if arg[1] == -1 then -- -1 indicates point used
			not_so_talented_achievement.fail_function_executor.Fail(not_so_talented_achievement.name)
		end
	end
end)
