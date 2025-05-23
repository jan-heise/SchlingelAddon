local SchlingelInc = ...

-- Frame für das Optionsmenü erstellen
local panel = CreateFrame("Frame", "SchlingelIncOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "Schlingel Inc"

-- Titel hinzufügen
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Schlingel Inc Einstellungen")

-- Toggle PVP Warning
-- Checkbox hinzufügen
local checkboxPvpWarning = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkboxPvpWarning:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkboxPvpWarning.text = _G[checkboxPvpWarning:GetName() .. "PVP Warnung"]
checkboxPvpWarning.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkboxPvpWarning:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.pvpWarning = isChecked
end)

-- Toggle PVP Warning Sound
-- Checkbox hinzufügen
local checkboxPvpWarningSound = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkboxPvpWarningSound:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkboxPvpWarningSound.text = _G[checkboxPvpWarningSound:GetName() .. "PVP Warnung Ton"]
checkboxPvpWarningSound.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkboxPvpWarningSound:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.pvpWarningSound = isChecked
end)

-- Toggle Death Announcement
-- Checkbox hinzufügen
local checkboxDeathAnnouncement = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkboxDeathAnnouncement:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkboxDeathAnnouncement.text = _G[checkboxDeathAnnouncement:GetName() .. "PVP Warnung"]
checkboxDeathAnnouncement.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkboxDeathAnnouncement:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.deathAnnouncement = isChecked
end)

-- Toggle Death Announcement Sound
-- Checkbox hinzufügen
local checkboxDeathAnnouncementSound = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkboxDeathAnnouncementSound:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkboxDeathAnnouncementSound.text = _G[checkboxDeathAnnouncementSound:GetName() .. "PVP Warnung Ton"]
checkboxDeathAnnouncementSound.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkboxDeathAnnouncementSound:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.deathAnnouncementSound = isChecked
end)

-- Toggle Version print in chat
-- Checkbox hinzufügen
local checkboxVersionPrint = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkboxVersionPrint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkboxVersionPrint.text = _G[checkboxVersionPrint:GetName() .. "PVP Warnung Ton"]
checkboxVersionPrint.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkboxVersionPrint:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.versionPrint = isChecked
end)

-- Optionen in das Interface-Menü einfügen
InterfaceOptions_AddCategory(panel)