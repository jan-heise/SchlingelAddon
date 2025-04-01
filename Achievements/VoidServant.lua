local _G = _G
local void_servant_achievement = CreateFrame("Frame")
_G.achievements.VoidServant = void_servant_achievement

-- General info
void_servant_achievement.name = "VoidServant"
void_servant_achievement.title = "Void Servant"
void_servant_achievement.pts = 10
void_servant_achievement.class = "Priest"
void_servant_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_void_servant.blp"
void_servant_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability within the “Holy” tab of your spellbook. Only spells listed under “Shadow Magic”, “Discipline”, or “General” are allowed. You are allowed to put points into all talent trees, but active abilities thus unlocked that are in the “Holy” tab of your spellbook are not allowed to be used."

-- Registers
function void_servant_achievement:Register(fail_function_executor)
	void_servant_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	void_servant_achievement:RegisterEvent("SPELLS_CHANGED")
	void_servant_achievement:GatherBlackList()
	void_servant_achievement.fail_function_executor = fail_function_executor
end

function void_servant_achievement:Unregister()
	void_servant_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	void_servant_achievement:UnregisterEvent("SPELLS_CHANGED")
end

function void_servant_achievement:GatherBlackList()
	void_servant_achievement.blacklist = {}
	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Holy" then
			for j = offset + 1, offset + numSlots do
				local spell_name = GetSpellInfo(j, "")
				table.insert(void_servant_achievement.blacklist, spell_name)
			end
		end
	end
end

-- Register Definitions
void_servant_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		void_servant_achievement:GatherBlackList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		for i, blacklist_spell in ipairs(void_servant_achievement.blacklist) do
			if spell_name == blacklist_spell then
				void_servant_achievement.fail_function_executor.Fail(void_servant_achievement.name)
				return
			end
		end
	end
end)
