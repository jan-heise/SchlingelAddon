local _G = _G
local insane_in_the_membrane_achievement = CreateFrame("Frame")
_G.achievements.InsaneInTheMembrane = insane_in_the_membrane_achievement

-- General info
insane_in_the_membrane_achievement.name = "InsaneInTheMembrane"
insane_in_the_membrane_achievement.title = "Insane In The Membrane"
insane_in_the_membrane_achievement.pts = 25
insane_in_the_membrane_achievement.class = "All"
insane_in_the_membrane_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_insane_in_the_membrane.blp"
insane_in_the_membrane_achievement.description =
	"Complete the Hardcore challenge while flagged for PvP for the entire run.  This achievement can be done on any server. Dying to enemy players counts as a death."

-- Registers
function insane_in_the_membrane_achievement:Register(fail_function_executor)
	insane_in_the_membrane_achievement.timer_handle = C_Timer.NewTicker(1.0, function()
		if UnitIsPVP("player") == false then
			Hardcore:Print("Turning on PVP flag for Insane in the Membrane.")
			SetPVP(1)
		end
	end)
	insane_in_the_membrane_achievement.fail_function_executor = fail_function_executor
end

function insane_in_the_membrane_achievement:Unregister()
	insane_in_the_membrane_achievement.timer_handle:Cancel()
end

-- Register Definitions
insane_in_the_membrane_achievement:SetScript("OnEvent", function(self, event, ...) end)
