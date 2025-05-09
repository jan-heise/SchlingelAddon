local UIHelpers = {}

function UIHelpers:CreateStyledText(parent, text, font, point, relativeTo, relativePoint, x, y, width, height, justifyH, justifyV)
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetPoint(point, relativeTo or parent, relativePoint or point, x or 0, y or 0)
    if text then fs:SetText(text) end
    if width and height then fs:SetSize(width, height) end
    if justifyH then fs:SetJustifyH(justifyH) end
    if justifyV then fs:SetJustifyV(justifyV) end
    return fs
end

function UIHelpers:CreateStyledButton(parent, text, width, height, point, relativeTo, relativePoint, x, y, template, onClickFunc)
    local btn = CreateFrame("Button", nil, parent, template or "UIPanelButtonTemplate")
    if text then btn:SetText(text) end
    btn:SetSize(width, height)
    btn:SetPoint(point, relativeTo or parent, relativePoint or point, x or 0, y or 0)
    if onClickFunc then btn:SetScript("OnClick", onClickFunc) end
    return btn
end

-- (Weitere Helper für Frames etc. könnten hier folgen)
SchlingelInc.UIHelpers = UIHelpers