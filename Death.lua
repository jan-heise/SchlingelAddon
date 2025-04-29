if not CharacterDeaths then
    CharacterDeaths = 0
end

local DeathFrame = CreateFrame("Frame")
DeathFrame:RegisterEvent("PLAYER_DEAD")

-- Event-Handler
DeathFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_DEAD" then
        CharacterDeaths = CharacterDeaths + 1
        SchlingelInc:Print("Du bist gestorben. Tode insgesamt: " .. CharacterDeaths)
    end
end)

-- Slash-Befehl definieren
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
    local inputValue = tonumber(msg)

    -- Kommt keine Zahl vom User, git es eine Fehlermeldung plus Anleitung.
    if not inputValue then
        SchlingelInc:Print("Ungültiger Input. Benutze: /deathset <Zahl>")
        return
    end

    -- Eine einmalige Zuweisung soll verhindern, dass der Wert nach der initialen Zuweisung noch geändert werden kann.
    if CharacterDeaths ~= nil then
        SchlingelInc:Print("Tod-Counter ist bereits gesetzt auf: " .. CharacterDeaths)
        return
    end

    CharacterDeaths = inputValue
    SchlingelInc:Print("Tod-Counter wurde initial auf " .. CharacterDeaths .. " gesetzt.")
end
