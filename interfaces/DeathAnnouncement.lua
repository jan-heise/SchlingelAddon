SchlingelInc.DeathAnnouncement = {}

-- Frame für die Nachricht unten rechts
local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent, "BackdropTemplate")
DeathMessageFrame:SetSize(300, 75)
DeathMessageFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 100)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
DeathMessageFrame:SetFrameLevel(1000)
DeathMessageFrame:Hide()
DeathMessageFrame:SetAlpha(0)

-- Hintergrund
DeathMessageFrame:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DeathMessageFrame:SetBackdropColor(0, 0, 0, 0.8)

-- Icon
local icon = DeathMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(32, 32)
icon:SetPoint("TOPLEFT", DeathMessageFrame, "TOPLEFT", 10, -10)
icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")

-- Header
local header = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
header:SetText("Schande!")
header:SetTextColor(1, 0.2, 0.2, 1)

-- Text
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
DeathMessageFrame.text:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
DeathMessageFrame.text:SetPoint("RIGHT", DeathMessageFrame, -10, 0)
DeathMessageFrame.text:SetJustifyH("LEFT")
DeathMessageFrame.text:SetJustifyV("TOP")
DeathMessageFrame.text:SetTextColor(1, 0.1, 0.1, 1)
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(1, -1)
DeathMessageFrame.text:SetText("")

-- Animation vorbereiten
local animGroup = DeathMessageFrame:CreateAnimationGroup()
local moveUp = animGroup:CreateAnimation("Translation")
moveUp:SetDuration(0.6)
moveUp:SetOffset(0, 50)
moveUp:SetSmoothing("OUT")

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(3)
fadeOut:SetDuration(1)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

-- Nach Animation Frame verstecken
animGroup:SetScript("OnFinished", function()
    DeathMessageFrame:Hide()
end)

-- Nachricht anzeigen
function SchlingelInc.DeathAnnouncement:ShowDeathMessage(message)
    if SchlingelOptionsDB["deathmessages"] == false then
        --SchlingelInc:Print("Skip DeathAnnouncement")
        return
    end
    DeathMessageFrame.text:SetText(message)
    DeathMessageFrame:SetAlpha(0)
    DeathMessageFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 100)
    DeathMessageFrame:Show()
    animGroup:Stop()
    animGroup:Play()

    if SchlingelOptionsDB["deathmessages_sound"] == true then
        PlaySound(8192) -- Horde-Flagge zurückgebracht
    -- else
    --     SchlingelInc:Print("Skip DeathSound")
    end
end
