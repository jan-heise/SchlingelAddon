local _G = _G
local vagrant_achievement = CreateFrame("Frame")
_G.achievements.Vagrant = vagrant_achievement

-- General info
vagrant_achievement.name = "Vagrant"
vagrant_achievement.title = "Vagrant"
vagrant_achievement.pts = 10
vagrant_achievement.class = "All"
vagrant_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_vagrant.blp"
vagrant_achievement.description =
	"Complete the Hardcore challenge without at any point using the Bank or a Hearthstone. No item can be stored in your character’s bank account."

-- Registers
function vagrant_achievement:Register(fail_function_executor)
	vagrant_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	vagrant_achievement:RegisterEvent("BANKFRAME_OPENED")
	vagrant_achievement.fail_function_executor = fail_function_executor
end

function vagrant_achievement:Unregister()
	vagrant_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	vagrant_achievement:UnregisterEvent("BANKFRAME_OPENED")
end

-- Register Definitions
vagrant_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		if spell_name == "Hearthstone" then
			Hardcore:Print("Casted hearth spell.")
			vagrant_achievement.fail_function_executor.Fail(vagrant_achievement.name)
		end
	elseif event == "BANKFRAME_OPENED" then
		Hardcore:Print("Used bank.")
		vagrant_achievement.fail_function_executor.Fail(vagrant_achievement.name)
	end
end)
