local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.DruidOfTheClawQuest = _achievement

-- General info
_achievement.name = "DruidOfTheClawQuest"
_achievement.title = "Deep in the Ban'ethil Barrow Den"
_achievement.class = "All"
_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_druid_of_the_claw_quest.blp"
_achievement.level_cap = 9
_achievement.quest_num = 2561
_achievement.quest_name = "Druid of the Claw"
_achievement.zone = "Teldrassil"
_achievement.kill_target = "Rageclaw"
_achievement.faction = "Alliance"
_achievement.bl_text = "Teldrassil Quest"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
	_achievement.quest_name,
	_achievement.zone,
	_achievement.level_cap,
	"Alliance"
)
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement:RegisterEvent("QUEST_TURNED_IN")
	_achievement.succeed_function_executor = succeed_function_executor
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("QUEST_TURNED_IN")
end

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	HCCommonPassiveAchievementBasicQuestCheck(_achievement, event, arg)
end)
