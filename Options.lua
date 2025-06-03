local category = Settings.RegisterVerticalLayoutCategory("Schlingel Inc")

local function OnSettingChanged(setting, value)
    -- This callback will be invoked whenever a setting is modified.
    local key = setting:GetVariable()
    print("Setting changed:", key, value)
end

for _, setting in ipairs(SchlingelOptionsDB) do
    local name = setting.label
    local variable = "SchlingelOptions_" .. setting.variable -- Eindeutiger Variablenname
    local variableKey = setting.variable
    local variableTbl = SchlingelOptionsDB
    local defaultValue = setting.value

    -- Register the setting with the Settings API.
    local settingObj = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name,
        defaultValue, setting.value)

    -- Set a callback for when the setting changes.
    settingObj:SetValueChangedCallback(OnSettingChanged)

    -- Create a checkbox for the setting.
    Settings.CreateCheckbox(category, settingObj, setting.description)
end

Settings.RegisterAddOnCategory(category)
