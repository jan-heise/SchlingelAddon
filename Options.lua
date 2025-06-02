SchlingelOptions = {}
local defaultSettings = {
    {
        label = "PVP Warnung",
        description = "Aktiviert die PVP Warnung",
        variable = "pvp_alert",
        value = true,
    },
    {
        label = "PVP Warnung Ton",
        description = "Aktiviert den Ton für die PVP Warnung",
        variable = "pvp_alert_sound",
        value = true,
    },
    {
        label = "Todesmeldungen",
        description = "Aktiviert die Todesmeldungen",
        variable = "deathmessages",
        value = true,
    },
    {
        label = "Todesmeldungen Ton",
        description = "Aktiviert den Ton für die Todesmeldungen",
        variable = "deathmessages_sound",
        value = true,
    },
    {
        label = "Todeslog",
        description = "Aktiviert den Todeslog",
        variable = "deathlog",
        value = false,
    },
}

local category = Settings.RegisterVerticalLayoutCategory("Schlingel Inc")

local function OnSettingChanged(setting, value)
    -- This callback will be invoked whenever a setting is modified.
    print("Setting changed:", setting:GetVariable(), value)
end

for _, setting in ipairs(defaultSettings) do
    local name = setting.label
    local variable = "SchlingelOptionsDB_" .. setting.variable -- eindeutiger Variablenname!
    local variableKey = setting.variable
    local variableTbl = SchlingelOptions
    local defaultValue = setting.value

    -- Register the setting with the Settings API.
    local settingObj = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name,
        defaultValue)

    -- Set a callback for when the setting changes.
    settingObj:SetValueChangedCallback(OnSettingChanged)

    -- Create a checkbox for the setting.
    Settings.CreateCheckbox(category, settingObj, setting.description)
end

Settings.RegisterAddOnCategory(category)
