-- Überprüft das aktuelle Ziel des Spielers auf PvP-Relevanz.
function SchlingelInc:CheckTargetPvP()
    local unit = "target"                        -- Das Ziel des Spielers.
    if not UnitExists(unit) then return end      -- Kein Ziel vorhanden.
    if not UnitIsPVP(unit) then return end       -- Ziel ist nicht PvP-markiert.

    local targetFaction = UnitFactionGroup(unit) -- Fraktion des Ziels.
    -- Warnung bei feindlichen Allianz-NPCs, die PvP-markiert sind.
    if targetFaction == "Alliance" and UnitIsPVP(unit) and not UnitIsPlayer(unit) then
        local name = UnitName(unit) or "Unbekannt"
        SchlingelInc:ShowPvPWarning(name .. " (Allianz-NPC)")
        return
    end

    -- Warnung bei feindlichen Spielern, die PvP-markiert sind.
    if UnitIsPlayer(unit) and UnitIsPVP(unit) then
        local name = UnitName(unit)
        local now = GetTime() -- Aktuelle Spielzeit.
        -- Holt die Zeit der letzten Warnung für diesen Spieler, Standard 0.
        local lastAlert = SchlingelInc.lastPvPAlert and SchlingelInc.lastPvPAlert[name] or 0
        if not SchlingelInc.lastPvPAlert then SchlingelInc.lastPvPAlert = {} end -- Sicherstellen, dass Tabelle existiert.

        -- Nur warnen, wenn die letzte Warnung für diesen Spieler mehr als 10 Sekunden her ist.
        if (now - lastAlert) > 10 then
            SchlingelInc.lastPvPAlert[name] = now -- Aktualisiert den Zeitpunkt der letzten Warnung.
            SchlingelInc:ShowPvPWarning(name .. " ist PvP-aktiv!")
        end
    end
end

-- Zeigt ein PvP-Warnfenster an.
function SchlingelInc:ShowPvPWarning(text)
    -- Erstellt das Warnfenster, falls es noch nicht existiert.
    if not SchlingelInc.pvpWarningFrame then SchlingelInc:CreatePvPWarningFrame() end
    -- Bricht ab, wenn das Frame immer noch nicht existiert (Sicherheitsprüfung).
    if not SchlingelInc.pvpWarningFrame then return end

    SchlingelInc.pvpWarningText:SetText("Obacht Schlingel!") -- Setzt den Haupttitel der Warnung.
    SchlingelInc.pvpWarningName:SetText(text)                -- Setzt den spezifischen Warntext (z.B. Spielername).
    SchlingelInc.pvpWarningFrame:SetAlpha(1)                 -- Macht das Fenster vollständig sichtbar.
    SchlingelInc.pvpWarningFrame:Show()                      -- Zeigt das Fenster an.
    SchlingelInc:RumbleFrame(SchlingelInc.pvpWarningFrame)   -- Startet den "Rumble"-Effekt.

    PlaySound(8174)                                          -- Horde-Flagge aufgenommen

    -- Blendet das Fenster nach 1 Sekunde langsam aus.
    C_Timer.After(1, function()
        if SchlingelInc.pvpWarningFrame then
            UIFrameFadeOut(SchlingelInc.pvpWarningFrame, 1, 1, 0) -- Fade-Out über 1 Sekunde.
            -- Versteckt das Frame komplett nach dem Ausblenden.
            C_Timer.After(1, function()
                if SchlingelInc.pvpWarningFrame then SchlingelInc.pvpWarningFrame:Hide() end
            end)
        end
    end)
end

-- Erstellt das UI-Frame für die PvP-Warnung, falls es noch nicht existiert.
function SchlingelInc:CreatePvPWarningFrame()
    -- Bricht ab, wenn das Frame bereits existiert und ein gültiges Frame-Objekt ist.
    if SchlingelInc.pvpWarningFrame and SchlingelInc.pvpWarningFrame:IsObjectType("Frame") then return end

    local pvpFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    pvpFrame:SetSize(320, 110)
    pvpFrame:ClearAllPoints()
    pvpFrame:SetPoint("CENTER")
    pvpFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    pvpFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1)             -- Randfarbe (rosa).
    pvpFrame:SetBackdropColor(0, 0, 0, 0.30)                      -- Hintergrundfarbe (leicht transparent schwarz).
    pvpFrame:SetMovable(true)                                     -- Erlaubt das Verschieben des Fensters.
    pvpFrame:EnableMouse(true)                                    -- Aktiviert Mauseingaben für das Fenster.
    pvpFrame:RegisterForDrag("LeftButton")                        -- Registriert Linksklick zum Ziehen.
    pvpFrame:SetScript("OnDragStart", pvpFrame.StartMoving)       -- Funktion bei Beginn des Ziehens.
    pvpFrame:SetScript("OnDragStop", pvpFrame.StopMovingOrSizing) -- Funktion bei Ende des Ziehens.
    pvpFrame:Hide()                                               -- Standardmäßig versteckt.

    -- Erstellt den Text für den Titel.
    local text = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    text:ClearAllPoints()
    text:SetPoint("TOP", pvpFrame, "TOP", 0, -20)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Erstellt den Text für den Namen/die spezifische Warnung.
    local nameText = pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    nameText:ClearAllPoints()
    nameText:SetPoint("BOTTOM", pvpFrame, "BOTTOM", 0, 25)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    nameText:SetTextColor(1, 0.82, 0) -- Goldene Farbe.

    -- Speichert die Referenzen zum Frame und den Textfeldern global im Addon.
    SchlingelInc.pvpWarningFrame = pvpFrame
    SchlingelInc.pvpWarningText = text
    SchlingelInc.pvpWarningName = nameText
end

-- Lässt ein UI-Frame für kurze Zeit "zittern" (Rumble-Effekt).
function SchlingelInc:RumbleFrame(frame)
    if not frame then return end                         -- Bricht ab, wenn kein Frame übergeben wurde.

    local rumbleTime = 0.3                               -- Gesamtdauer des Zitterns in Sekunden.
    local interval = 0.03                                -- Intervall zwischen den Bewegungen in Sekunden.
    local totalTicks = math.floor(rumbleTime / interval) -- Gesamtzahl der Bewegungen.
    local tick = 0                                       -- Zähler für aktuelle Bewegung.

    -- Startet einen Timer, der wiederholt ausgeführt wird.
    C_Timer.NewTicker(interval, function(ticker)
        -- Bricht ab, wenn das Frame ungültig wird oder nicht mehr sichtbar ist.
        if not frame:IsObjectType("Frame") or not frame:IsShown() then
            ticker:Cancel()
            return
        end

        tick = tick + 1
        local offsetX = math.random(-4, 4)                             -- Zufälliger X-Versatz.
        local offsetY = math.random(-4, 4)                             -- Zufälliger Y-Versatz.
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY) -- Bewegt das Frame.

        -- Wenn alle Bewegungen ausgeführt wurden:
        if tick >= totalTicks then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Setzt das Frame auf die ursprüngliche Mittelposition zurück.
            ticker:Cancel()                                    -- Stoppt den Timer.
        end
    end, totalTicks)                                           -- Der Timer stoppt automatisch nach 'totalTicks' Ausführungen.
end
