-- BGHelper.lua
-- Simple Battleground callout helper for Turtle WoW

local frame = CreateFrame("Frame", "BGHelperFrame", UIParent)
frame:SetWidth(132)
frame:SetHeight(90)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:Hide()

-- Backdrop compatible with Vanilla/Turtle WoW
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

---------------------------------------------------------
-- MAKE FRAME MOVABLE (Vanilla-safe)
---------------------------------------------------------
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function()
    BGHelperFrame:StartMoving()
end)

frame:SetScript("OnDragStop", function()
    BGHelperFrame:StopMovingOrSizing()

    local point, _, relativePoint, x, y = frame:GetPoint()
    BGHelperDB = BGHelperDB or {}
    BGHelperDB.point = point
    BGHelperDB.relativePoint = relativePoint
    BGHelperDB.x = x
    BGHelperDB.y = y
end)

---------------------------------------------------------
-- TITLE
---------------------------------------------------------
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", 0, -7)
frame.title:SetText("BG Helper")

-- Track the call selected for the next location button.
local selectedCall = nil
local selectedButton = nil
local selectedLocationLabel = nil

local funnyCallTexts = {
    "the locals are getting rowdy!",
    "surprise PvP inspection in progress!",
    "unwanted visitors, and they forgot the snacks!",
    "tactical panic is now underway!",
    "the odds look terrible, but morale is immaculate!",
    "reinforcements requested; emotional support also accepted!",
    "the enemy team is hosting an uninvited party!",
    "red names everywhere - please send adults!",
    "the population just increased aggressively!",
    "situation under control... narrator: it was not!",
}
local lastFunnyCallIndex = nil

local funnySafeTexts = {
    "a huge battle was fought, but we are SAFE!",
    "the dust has settled and somehow we are SAFE!",
    "the danger has been bonked away - we are SAFE!",
    "the enemy tried their best; it was adorable. We are SAFE!",
    "crisis cancelled, snacks resumed - we are SAFE!",
    "the red names have vanished and we are SAFE!",
    "the floor is messy, but the base is SAFE!",
    "we survived the plot twist and we are SAFE!",
    "the panic button may now be released - we are SAFE!",
    "victory achieved with minimal dignity - we are SAFE!",
}
local lastFunnySafeIndex = nil

local function GetRandomFunnyCall()
    local callIndex = math.random(table.getn(funnyCallTexts))

    -- Avoid getting the same joke twice in a row.
    if table.getn(funnyCallTexts) > 1 and callIndex == lastFunnyCallIndex then
        callIndex = math.mod(callIndex, table.getn(funnyCallTexts)) + 1
    end

    lastFunnyCallIndex = callIndex
    return funnyCallTexts[callIndex]
end

local function GetRandomFunnySafe()
    local safeIndex = math.random(table.getn(funnySafeTexts))

    -- Avoid getting the same safe message twice in a row.
    if table.getn(funnySafeTexts) > 1 and safeIndex == lastFunnySafeIndex then
        safeIndex = math.mod(safeIndex, table.getn(funnySafeTexts)) + 1
    end

    lastFunnySafeIndex = safeIndex
    return funnySafeTexts[safeIndex]
end

local function UpdateTitle()
    if selectedLocationLabel and selectedCall then
        frame.title:SetText(selectedLocationLabel .. ": " .. selectedCall)
    elseif selectedLocationLabel then
        frame.title:SetText(selectedLocationLabel)
    elseif selectedCall then
        frame.title:SetText("Call: " .. selectedCall)
    else
        frame.title:SetText("BG Helper")
    end
end

local function SelectCall(call, button)
    if selectedButton then
        selectedButton:UnlockHighlight()
    end

    selectedCall = call
    selectedButton = button
    selectedButton:LockHighlight()

    UpdateTitle()
end

local function SelectLocation(label)
    if selectedLocationLabel == label then
        return
    end

    selectedLocationLabel = label
    UpdateTitle()
end

local function ClearLocation()
    selectedLocationLabel = nil
    UpdateTitle()
end

local callCooldownUntil = nil

local function CanSendCallout()
    local now = GetTime()

    if callCooldownUntil then
        if now < callCooldownUntil then
            DEFAULT_CHAT_FRAME:AddMessage(
                "BG Helper: Slow down! Callouts ready in "
                .. math.ceil(callCooldownUntil - now) .. "s."
            )
            return false
        end

        callCooldownUntil = nil
    end

    -- Every successful call pauses further CALL and SAFE messages for 3 seconds.
    callCooldownUntil = now + 3
    return true
end

local function SendSelectedCall(locationName)
    if not selectedCall then
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Choose 1-5, ALOT, or SAFE first."
        )
        return
    end

    if not CanSendCallout() then
        return
    end

    if selectedCall == "SAFE" then
        SendChatMessage(
            locationName .. ", " .. GetRandomFunnySafe(),
            "BATTLEGROUND"
        )
    else
        SendChatMessage(
            locationName .. ", " .. selectedCall .. " - "
            .. GetRandomFunnyCall(),
            "BATTLEGROUND"
        )
    end
end

---------------------------------------------------------
-- LOCATION DATA
---------------------------------------------------------
local locations = {
    {
        name = "Stables", label = "Stables",
        mapX = 0.39, mapY = 0.28
    },
    {
        name = "Gold Mine", label = "Mine",
        mapX = 0.60, mapY = 0.28
    },
    {
        name = "Lumber Mill", label = "Lumber",
        mapX = 0.39, mapY = 0.58
    },
    {
        name = "Blacksmith", label = "Smith",
        mapX = 0.48, mapY = 0.44
    },
    {
        name = "Farm", label = "Farm",
        mapX = 0.60, mapY = 0.61
    },
}

local function IsArathiBasin()
    return GetZoneText() == "Arathi Basin"
        or GetRealZoneText() == "Arathi Basin"
end

---------------------------------------------------------
-- ARATHI BASIN CAPTURE TIMERS
---------------------------------------------------------
local CAPTURE_DURATION = 60
local captureTimers = {}

-- The timer panel follows the main window when it is dragged.
local timerFrame = CreateFrame("Frame", nil, frame)
timerFrame:SetWidth(170)
timerFrame:SetPoint("TOP", frame, "BOTTOM", 0, -2)
timerFrame:Hide()

local timerBars = {}

for i = 1, table.getn(locations) do
    local bar = CreateFrame("StatusBar", nil, timerFrame)
    bar:SetWidth(160)
    bar:SetHeight(16)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, CAPTURE_DURATION)
    bar:SetValue(0)
    bar:SetPoint("TOP", timerFrame, "TOP", 0, -5 - ((i - 1) * 19))
    bar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    bar:SetBackdropColor(0, 0, 0, 0.85)

    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints(bar)
    bar.background:SetTexture(0.08, 0.08, 0.08, 0.9)

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetTextColor(1, 1, 1)
    bar:EnableMouse(true)
    bar:SetScript("OnMouseUp", function()
        if arg1 ~= "LeftButton" or not this.locationName then
            return
        end

        local timer = captureTimers[this.locationName]
        if not timer then
            return
        end

        local inBattleground = false
        for battlefieldIndex = 1, 3 do
            if GetBattlefieldStatus(battlefieldIndex) == "active" then
                inBattleground = true
                break
            end
        end

        if not inBattleground then
            DEFAULT_CHAT_FRAME:AddMessage(
                "BG Helper: Timer announcements only work in a battleground."
            )
            return
        end

        if CanSendCallout() then
            local remaining = math.ceil(timer.endsAt - GetTime())
            SendChatMessage(
                this.locationName .. " has " .. remaining .. "s left.",
                "BATTLEGROUND"
            )
        end
    end)
    bar:Hide()

    timerBars[i] = bar
end

local function UpdateCaptureTimerLayout()
    local shownBars = 0

    -- Use location order so simultaneous timers do not jump around.
    for _, location in ipairs(locations) do
        local timer = captureTimers[location.name]
        if timer then
            shownBars = shownBars + 1
            local bar = timerBars[shownBars]
            local remaining = math.ceil(timer.endsAt - GetTime())

            bar.locationName = location.name
            bar.remainingSeconds = remaining
            bar.text:SetText(location.name .. " - " .. remaining .. "s")
            bar:SetValue(GetTime() - timer.startedAt)
            if timer.faction == "Alliance" then
                bar:SetStatusBarColor(0.1, 0.35, 1)
            else
                bar:SetStatusBarColor(0.85, 0.05, 0.05)
            end
            bar:Show()
        end
    end

    for i = shownBars + 1, table.getn(timerBars) do
        timerBars[i].locationName = nil
        timerBars[i].remainingSeconds = nil
        timerBars[i]:Hide()
    end

    if shownBars > 0 then
        timerFrame:SetHeight(10 + (shownBars * 19))
        timerFrame:Show()
    else
        timerFrame:Hide()
    end
end

local function RemoveCaptureTimer(locationName)
    if captureTimers[locationName] then
        captureTimers[locationName] = nil
        UpdateCaptureTimerLayout()
    end
end

local function ClearCaptureTimers()
    captureTimers = {}
    UpdateCaptureTimerLayout()
end

local function StartCaptureTimer(locationName, faction)
    local now = GetTime()
    captureTimers[locationName] = {
        faction = faction,
        startedAt = now,
        endsAt = now + CAPTURE_DURATION,
    }
    UpdateCaptureTimerLayout()
end

local function FindLocationInMessage(message)
    local lowerMessage = string.lower(message or "")

    for _, location in ipairs(locations) do
        if string.find(
            lowerMessage,
            string.lower(location.name),
            1,
            true
        ) then
            return location
        end
    end

    return nil
end

local function IsAssaultMessage(message)
    local lowerMessage = string.lower(message or "")
    return string.find(lowerMessage, "assault", 1, true)
        or string.find(lowerMessage, "claims", 1, true)
        or string.find(lowerMessage, "claiming", 1, true)
end

local function IsCaptureFinishedMessage(message)
    local lowerMessage = string.lower(message or "")
    return string.find(lowerMessage, "has taken", 1, true)
        or string.find(lowerMessage, "defended", 1, true)
        or string.find(lowerMessage, "captured", 1, true)
        or string.find(lowerMessage, "now controls", 1, true)
end

local captureEventFrame = CreateFrame("Frame")
captureEventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
captureEventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
captureEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
captureEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

captureEventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        if not IsArathiBasin() then
            ClearCaptureTimers()
        end
        return
    end

    if not IsArathiBasin() then
        return
    end

    local location = FindLocationInMessage(arg1)
    if not location then
        return
    end

    -- A defense or completed capture makes the point safe and ends its bar.
    if IsCaptureFinishedMessage(arg1) then
        RemoveCaptureTimer(location.name)
    elseif IsAssaultMessage(arg1) then
        local faction = "Horde"
        if event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" then
            faction = "Alliance"
        end
        StartCaptureTimer(location.name, faction)
    end
end)

timerFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    local layoutChanged = false

    for i = 1, table.getn(timerBars) do
        local bar = timerBars[i]
        if bar:IsShown() and bar.locationName then
            local timer = captureTimers[bar.locationName]
            if timer then
                if now >= timer.endsAt then
                    captureTimers[bar.locationName] = nil
                    layoutChanged = true
                else
                    -- Fill from empty to full during the one-minute capture.
                    bar:SetValue(now - timer.startedAt)
                    local remaining = math.ceil(timer.endsAt - now)
                    if remaining ~= bar.remainingSeconds then
                        bar.remainingSeconds = remaining
                        bar.text:SetText(
                            bar.locationName .. " - " .. remaining .. "s"
                        )
                    end
                end
            end
        end
    end

    if layoutChanged then
        UpdateCaptureTimerLayout()
    end
end)

local function GetNearestLocation(refreshMap)
    if not IsArathiBasin() then
        return nil
    end

    if refreshMap then
        SetMapToCurrentZone()
    end
    local playerX, playerY = GetPlayerMapPosition("player")
    if not playerX or not playerY or (playerX == 0 and playerY == 0) then
        return nil
    end

    local nearest = nil
    local nearestDistance = nil

    for _, loc in ipairs(locations) do
        local deltaX = playerX - loc.mapX
        local deltaY = playerY - loc.mapY
        local distance = deltaX * deltaX + deltaY * deltaY

        if not nearestDistance or distance < nearestDistance then
            nearest = loc
            nearestDistance = distance
        end
    end

    return nearest
end

local function UpdateCurrentLocation()
    local location = GetNearestLocation(true)
    if location then
        SelectLocation(location.label)
    end

    return location
end

---------------------------------------------------------
-- NUMBER BUTTONS (1–5)
---------------------------------------------------------
-- Keep the nearest Arathi Basin base selected while the helper is visible.
local nextLocationUpdate = 0

local welcomeTexts = {
    "Hello, team! Your hero has arrived... say hello to %s!",
    "Good news, everyone: %s remembered to queue!",
    "Welcome to the battleground! %s will be supervising the chaos.",
    "The dream team is complete now that %s is here!",
    "Hello, brave fighters! Please direct all complaints to %s.",
    "Attention, team: %s has volunteered to carry us!",
    "Welcome aboard! %s brought courage, snacks, and questionable tactics.",
    "The gates may open now; %s has finally arrived!",
    "Hello, legends! Today's emotional support player is %s.",
    "Great news: %s read at least half of the strategy!",
    "Welcome, team! If anything goes wrong, we blame %s.",
    "Heroes assemble! %s has entered the chat.",
    "Hello, friends! %s says this will definitely go according to plan.",
    "The enemy has no idea that we brought %s!",
    "Welcome to the show! Tonight's main character is %s.",
    "Team morale increased by 3 because %s joined!",
    "Hello, champions! %s has promised not to fight on the road.",
    "We can win this! %s saw it happen in a dream.",
    "Welcome, everyone! Protect %s; they know where the snacks are.",
    "The battleground is ready and %s is already looking suspicious!",
}
local lastWelcomeIndex = nil
local addonDownloadLink = "https://github.com/OctoAddons/BGHelper"
local welcomeFrame = CreateFrame("Frame")
local welcomeAt = nil
local welcomeAttempts = 0
local welcomedInCurrentBattleground = false

local function IsInBattleground()
    for i = 1, 3 do
        if GetBattlefieldStatus(i) == "active" then
            return true
        end
    end

    return false
end

local function GetRandomRaidMemberName()
    local raidNames = {}

    for i = 1, GetNumRaidMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            table.insert(raidNames, name)
        end
    end

    if table.getn(raidNames) == 0 then
        return nil
    end

    return raidNames[math.random(table.getn(raidNames))]
end

local function ScheduleBattlegroundWelcome()
    if not welcomedInCurrentBattleground and not welcomeAt then
        welcomeAttempts = 0
        -- Allow time for battleground chat and the raid roster to load.
        welcomeAt = GetTime() + 3
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "BGHelper" then
        BGHelperDB = BGHelperDB or {}

        if BGHelperDB.point then
            frame:ClearAllPoints()
            frame:SetPoint(
                BGHelperDB.point,
                UIParent,
                BGHelperDB.relativePoint,
                BGHelperDB.x,
                BGHelperDB.y
            )
        end

        frame:UnregisterEvent("ADDON_LOADED")
        return
    end

    if IsInBattleground() then
        ScheduleBattlegroundWelcome()
    else
        welcomeAt = nil
        welcomeAttempts = 0
        welcomedInCurrentBattleground = false
    end

    if IsArathiBasin() then
        frame:Show()
        SetMapToCurrentZone()
        nextLocationUpdate = 0

        local location = GetNearestLocation(false)
        if location then
            SelectLocation(location.label)
        end
    else
        frame:Hide()
        ClearLocation()
    end
end)

welcomeFrame:SetScript("OnUpdate", function()
    if not welcomeAt or GetTime() < welcomeAt then
        return
    end

    if not IsInBattleground() then
        welcomeAt = nil
        return
    end

    local raidName = GetRandomRaidMemberName()
    if not raidName and welcomeAttempts < 10 then
        welcomeAttempts = welcomeAttempts + 1
        welcomeAt = GetTime() + 1
        return
    end

    if raidName then
        local welcomeIndex = math.random(table.getn(welcomeTexts))
        if table.getn(welcomeTexts) > 1
            and welcomeIndex == lastWelcomeIndex then
            welcomeIndex = math.mod(
                welcomeIndex,
                table.getn(welcomeTexts)
            ) + 1
        end

        lastWelcomeIndex = welcomeIndex
        SendChatMessage(
            string.format(welcomeTexts[welcomeIndex], raidName)
            .. " Get BG Helper: " .. addonDownloadLink,
            "BATTLEGROUND"
        )
        welcomedInCurrentBattleground = true
    end

    welcomeAt = nil
end)

frame:SetScript("OnShow", function()
    if IsArathiBasin() then
        SetMapToCurrentZone()
        nextLocationUpdate = 0

        local location = GetNearestLocation(false)
        if location then
            SelectLocation(location.label)
        end
    end
end)

frame:SetScript("OnUpdate", function()
    local now = GetTime()

    if now < nextLocationUpdate then
        return
    end

    nextLocationUpdate = now + 0.75

    local location = GetNearestLocation(false)
    if location then
        SelectLocation(location.label)
    end
end)

local numbers = {1, 2, 3, 4, 5}

for i, num in ipairs(numbers) do
    -- Copy the value for the click handler (important on older Lua clients).
    local amount = num
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetWidth(21)
    btn:SetHeight(18)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 9 + (i-1)*23, -25)
    btn:SetText(amount)

    btn:SetScript("OnClick", function()
        UpdateCurrentLocation()
        SelectCall(amount, btn)
    end)
end

---------------------------------------------------------
-- A LOT BUTTON
---------------------------------------------------------
local aLotBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
aLotBtn:SetWidth(52)
aLotBtn:SetHeight(18)
aLotBtn:SetPoint("TOP", frame, "TOP", 0, -46)
aLotBtn:SetText("ALOT")

aLotBtn:SetScript("OnClick", function()
    UpdateCurrentLocation()
    SelectCall("ALOT", aLotBtn)
end)

---------------------------------------------------------
-- AUTOMATIC LOCATION CALLOUT
---------------------------------------------------------
local callBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
callBtn:SetWidth(52)
callBtn:SetHeight(18)
callBtn:SetPoint("TOP", frame, "TOP", 30, -67)
callBtn:SetText("CALL")

callBtn:SetScript("OnClick", function()
    local location = UpdateCurrentLocation()
    if not location then
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Automatic location only works inside Arathi Basin."
        )
        return
    end

    SelectLocation(location.label)

    SendSelectedCall(location.name)
end)

---------------------------------------------------------
-- SAFE BUTTON
---------------------------------------------------------
local safeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
safeBtn:SetWidth(52)
safeBtn:SetHeight(18)
safeBtn:SetPoint("TOP", frame, "TOP", -30, -67)
safeBtn:SetText("SAFE")

safeBtn:SetScript("OnClick", function()
    local location = UpdateCurrentLocation()
    if not location then
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Automatic location only works inside Arathi Basin."
        )
        return
    end

    SelectLocation(location.label)
    SelectCall("SAFE", safeBtn)
    RemoveCaptureTimer(location.name)
    SendSelectedCall(location.name)
end)

---------------------------------------------------------
-- Slash
---------------------------------------------------------
SLASH_BGHELPER1 = "/bgh"
SLASH_BGHELPER2 = "/bghelper"

SlashCmdList["BGHELPER"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "show" then
        frame:Show()
    elseif msg == "hide" then
        frame:Hide()
    elseif msg == "" or msg == "toggle" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    elseif msg == "test" or msg == "test on" then
        ClearCaptureTimers()
        frame:Show()
        StartCaptureTimer("Stables", "Alliance")
        StartCaptureTimer("Farm", "Horde")
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Test timers started. Use /bgh test off to remove them."
        )
    elseif msg == "test off" then
        ClearCaptureTimers()
        DEFAULT_CHAT_FRAME:AddMessage("BG Helper: Test timers stopped.")
    elseif msg == "debug" then
        SetMapToCurrentZone()
        local playerX, playerY = GetPlayerMapPosition("player")
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: zone=" .. tostring(GetZoneText())
            .. ", realZone=" .. tostring(GetRealZoneText())
            .. ", position=" .. tostring(playerX) .. "," .. tostring(playerY)
        )
    else
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: /bgh [show | hide | toggle | test | test off | debug]"
        )
    end
end
