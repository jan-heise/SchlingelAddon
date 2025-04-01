local _G = _G
local thunderstruck_achievement = CreateFrame("Frame")
_G.achievements.Thunderstruck = thunderstruck_achievement

local whitelist = {
	[18205] = 1, -- Black Malice
	[16375] = 1, -- Faintly glowing skull
}

local temporary_disable = false

-- General info
thunderstruck_achievement.name = "Thunderstruck"
thunderstruck_achievement.title = "Thunderstruck"
thunderstruck_achievement.class = "Shaman"
thunderstruck_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_thunderstruck.blp"
thunderstruck_achievement.pts = 10
thunderstruck_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability that deals damage other than Nature. Spells, weapon enhancements, or totems that deal Fire or Frost damage are not allowed. All items and consumables that deal damage other than Nature are allowed."

-- Registers
function thunderstruck_achievement:Register(fail_function_executor)
	thunderstruck_achievement:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	thunderstruck_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	thunderstruck_achievement.fail_function_executor = fail_function_executor
end

function thunderstruck_achievement:Unregister()
	thunderstruck_achievement:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	thunderstruck_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
thunderstruck_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		-- 2: subevent index, 5: source_name, 14: spell school
		if not (combat_log_payload[5] == nil) then
			if combat_log_payload[5] == UnitName("player") then
				if string.find(combat_log_payload[2], "SPELL_DAMAGE") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[14] ~= 8 then
						thunderstruck_achievement.fail_function_executor.Fail(thunderstruck_achievement.name)
					end
				end
			end
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if whitelist[arg[3]] then
			temporary_disable = true
			C_Timer.After(10.0, function()
				temporary_disable = false
			end)
		end
	end
end)
