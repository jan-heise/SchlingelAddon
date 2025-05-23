local SchlingelInc = ...

-- Frame für das Optionsmenü erstellen
local panel = CreateFrame("Frame", "SchlingelIncOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "Schlingel Inc"

-- Titel hinzufügen
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Schlingel Inc Einstellungen")

-- Checkbox hinzufügen
local checkbox = CreateFrame("CheckButton", "SchlingelIncCheckbox", panel, "UICheckButtonTemplate")
checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
checkbox.text = _G[checkbox:GetName() .. "Options Text"]
checkbox.text:SetText("Option aktivieren")

-- Checkbox-Verhalten definieren
checkbox:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    SchlingelOptionsDB.enableOption = isChecked
end)

-- Optionen in das Interface-Menü einfügen
InterfaceOptions_AddCategory(panel)