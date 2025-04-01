local _G = _G
local sword_and_board_achievement = CreateFrame("Frame")
_G.achievements.SwordAndBoard = sword_and_board_achievement

-- General info
sword_and_board_achievement.name = "SwordAndBoard"
sword_and_board_achievement.title = "Sword & Board"
sword_and_board_achievement.class = "Warrior"
sword_and_board_achievement.pts = 10
sword_and_board_achievement.icon_path = "Interface\\AddOns\\HardcoreUnlocked\\Media\\icon_sword_and_board.blp"
sword_and_board_achievement.description =
	"Complete the Hardcore challenge without at any point wielding a two-handed melee weapon or dual wielding (Fishing Pole is acceptable). If your race starts with a two-handed weapon, unequip it upon logging in."

-- Registers
function sword_and_board_achievement:Register(fail_function_executor)
	sword_and_board_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	sword_and_board_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	sword_and_board_achievement.fail_function_executor = fail_function_executor
end

function sword_and_board_achievement:Unregister()
	sword_and_board_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	sword_and_board_achievement:UnregisterEvent("PLAYER_LEVEL_UP")
end

-- Register Definitions
sword_and_board_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if arg[1] == 16 then -- Mainhand
			if item_type == "Weapon" then
				if
					item_subtype == "Two-Handed Axes"
					or item_subtype == "Two-Handed Maces"
					or item_subtype == "Two-Handed Swords"
					or item_subtype == "Polearms"
					or item_subtype == "Staves"
					--or item_subtype == "Fishing Poles"
				then
					local time_elapsed = 0 -- seconds
					C_Timer.NewTicker(1, function(self)
						time_elapsed = time_elapsed + 1
						Hardcore:Print(
							"<Sword and Board>: Unequip non sword or shield item, "
								.. item_name
								.. ", or your achievement will fail in "
								.. 60 - time_elapsed
								.. " seconds."
						)
						if IsEquippedItem(item_id) == false then
							Hardcore:Print(
								"<Sword and Board>: You unequipped " .. item_name .. ". No further action needed."
							)
							self:Cancel()
							return
						end
						if time_elapsed > 60 then
							Hardcore:Print("Equipped " .. item_name .. ".")
							sword_and_board_achievement.fail_function_executor.Fail(sword_and_board_achievement.name)
							self:Cancel()
						end
					end)
				end
			end
		elseif arg[1] == 17 then -- Offhand
			if item_type == "Weapon" then
				Hardcore:Print("Equipped " .. item_name .. ".")
				sword_and_board_achievement.fail_function_executor.Fail(sword_and_board_achievement.name)
			end
		end
	end
end)
