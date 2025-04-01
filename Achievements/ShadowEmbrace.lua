local _G = _G
local shadow_embrace_achievement = CreateFrame("Frame")
_G.achievements.ShadowEmbrace = shadow_embrace_achievement

-- General info
shadow_embrace_achievement.name = "ShadowEmbrace"
shadow_embrace_achievement.title = "Shadow Embrace"
shadow_embrace_achievement.class = "Warlock"
shadow_embrace_achievement.pts = 10
shadow_embrace_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_shadow_embrace.blp"
shadow_embrace_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability that deals damage other than Shadow. Spells and Demon abilities that deal Fire damage are not allowed. All items and consumables that deal damage other than Shadow are allowed."

-- Registers
function shadow_embrace_achievement:Register(fail_function_executor)
	shadow_embrace_achievement:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	shadow_embrace_achievement.fail_function_executor = fail_function_executor
end

function shadow_embrace_achievement:Unregister()
	shadow_embrace_achievement:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Register Definitions
shadow_embrace_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		-- 2: subevent index, 5: source_name, 14: spell school
		if not (combat_log_payload[5] == nil) then
			if combat_log_payload[5] == UnitName("player") then
				if string.find(combat_log_payload[2], "SPELL_DAMAGE") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[14] ~= 32 then
						shadow_embrace_achievement.fail_function_executor.Fail(shadow_embrace_achievement.name)
					end
				end
			end
		end
	end
end)
