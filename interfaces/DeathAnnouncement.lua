SchlingelInc.DeathAnnouncement = {}

-- Frame für die zentrale Bildschirmnachricht
local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent, "BackdropTemplate")
DeathMessageFrame:SetSize(400, 150)
DeathMessageFrame:SetPoint("CENTER", UIParent, "TOP", 0, -200)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")  -- sehr hohe Schicht
DeathMessageFrame:SetFrameLevel(1000)                  -- sehr hoher Level innerhalb der Schicht
DeathMessageFrame:Hide()
DeathMessageFrame:SetAlpha(1)

-- Moderner Tooltip-Style-Hintergrund
DeathMessageFrame:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DeathMessageFrame:SetBackdropColor(0, 0, 0, 0.85)

-- Icon oben zentriert
local icon = DeathMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(48, 48)
icon:SetPoint("TOP", DeathMessageFrame, "TOP", 0, -12)
icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")

-- Header "Schande!" zentriert unter dem Icon
local header = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
header:SetPoint("TOP", icon, "BOTTOM", 0, -8)
header:SetText("Schande!")
header:SetTextColor(1, 0.2, 0.2, 1)
header:SetShadowColor(0, 0, 0, 1)
header:SetShadowOffset(1, -1)

-- Nachricht unter dem Header, zentriert, volle Breite
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
DeathMessageFrame.text:SetPoint("TOP", header, "BOTTOM", 0, -8)
DeathMessageFrame.text:SetWidth(360)
DeathMessageFrame.text:SetJustifyH("CENTER")
DeathMessageFrame.text:SetJustifyV("TOP")
DeathMessageFrame.text:SetTextColor(1, 0.1, 0.1, 1)
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(1, -1)
DeathMessageFrame.text:SetText("")

function SchlingelInc.DeathAnnouncement:ShowDeathMessage(message)
    DeathMessageFrame.text:SetText(message)

    -- Sofort volle Sichtbarkeit & Frame zeigen
    DeathMessageFrame:SetAlpha(1)
    DeathMessageFrame:Show()

    -- Sound abspielen
    PlaySound(8192) -- Horde-Flagge zurückgebracht
    -- Nachricht nach 3 Sekunden ausblenden mit Fade-Out
    C_Timer.After(3, function()
        UIFrameFadeOut(DeathMessageFrame, 1, 1, 0) --Dauer, StartAlpha, EndAlpha
        C_Timer.After(1, function()
            DeathMessageFrame:Hide()
        end)
    end)
end
