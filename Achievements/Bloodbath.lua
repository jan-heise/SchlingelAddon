local _G = _G
local bloodbath_achievement = CreateFrame("Frame")
_G.achievements.Bloodbath = bloodbath_achievement

-- General info
bloodbath_achievement.name = "Bloodbath"
bloodbath_achievement.title = "Bloodbath"
bloodbath_achievement.class = "All"
bloodbath_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_bloodbath.blp"
bloodbath_achievement.bl_text = "Starting Achievement"
bloodbath_achievement.pts = 50
bloodbath_achievement.description =
	"Complete the Hardcore challenge without at any point completing a quest. No exceptions."
local class_eng, _, _ = UnitClass("player")
if class_eng == "Hunter" then
	bloodbath_achievement.forces = {
		"LoneWolf",
	}
elseif class_eng == "Warrior" then
	bloodbath_achievement.forces = {
		"TiedHands",
	}
elseif class_eng == "Shaman" then
	bloodbath_achievement.forces = {
		"TotemicMisery",
	}
end

-- Registers
function bloodbath_achievement:Register(fail_function_executor)
	bloodbath_achievement:RegisterEvent("QUEST_TURNED_IN")
	bloodbath_achievement.fail_function_executor = fail_function_executor
end

function bloodbath_achievement:Unregister()
	bloodbath_achievement:UnregisterEvent("QUEST_TURNED_IN")
end

-- Register Definitions
bloodbath_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "QUEST_TURNED_IN" then
		bloodbath_achievement.fail_function_executor.Fail(bloodbath_achievement.name)
	end
end)
