local _G = _G
local lone_wolf_achievement = CreateFrame("Frame")
_G.achievements.LoneWolf = lone_wolf_achievement

-- General info
lone_wolf_achievement.name = "LoneWolf"
lone_wolf_achievement.title = "Lone Wolf"
lone_wolf_achievement.class = "Hunter"
lone_wolf_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_lone_wolf.blp"
lone_wolf_achievement.pts = 10
lone_wolf_achievement.description =
	"Complete the Hardcore challenge without at any point taming a Hunter pet. Items and quests that make you spawn companions are allowed."

-- Registers
function lone_wolf_achievement:Register(fail_function_executor)
	lone_wolf_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	lone_wolf_achievement.fail_function_executor = fail_function_executor
end

function lone_wolf_achievement:Unregister()
	lone_wolf_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
lone_wolf_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit == "player" and spell_id == 1515 then
			Hardcore:Print("Casted tame beast.")
			lone_wolf_achievement.fail_function_executor.Fail(lone_wolf_achievement.name)
		end
	end
end)
