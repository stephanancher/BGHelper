-- BGHelper.lua
-- Simple Battleground callout helper for Turtle WoW

local frame = CreateFrame("Frame", "BGHelperFrame", UIParent)
frame:SetWidth(132)
frame:SetHeight(132)
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
local selectedLocationButton = nil
local selectedLocationLabel = nil

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

local function SelectLocation(label, button)
    if selectedLocationButton == button then
        return
    end

    if selectedLocationButton then
        selectedLocationButton:UnlockHighlight()
    end

    selectedLocationLabel = label
    selectedLocationButton = button
    selectedLocationButton:LockHighlight()

    UpdateTitle()
end

local function ClearLocation()
    if selectedLocationButton then
        selectedLocationButton:UnlockHighlight()
    end

    selectedLocationLabel = nil
    selectedLocationButton = nil
    UpdateTitle()
end

local function SendSelectedCall(locationName)
    if not selectedCall then
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Choose 1-5, ALOT, or SAFE first."
        )
    elseif selectedCall == "SAFE" then
        SendChatMessage(locationName .. " is safe!", "BATTLEGROUND")
    else
        SendChatMessage(
            locationName .. " needs help " .. selectedCall .. "!",
            "BATTLEGROUND"
        )
    end
end

---------------------------------------------------------
-- LOCATION BUTTONS
---------------------------------------------------------
local locations = {
    {
        name = "Stables", label = "Stables",
        x = -30, y = -25, mapX = 0.39, mapY = 0.28
    },
    {
        name = "Gold Mine", label = "Mine",
        x = 30, y = -25, mapX = 0.60, mapY = 0.28
    },
    {
        name = "Lumber Mill", label = "Lumber",
        x = -30, y = -46, mapX = 0.39, mapY = 0.58
    },
    {
        name = "Blacksmith", label = "Smith",
        x = 30, y = -46, mapX = 0.48, mapY = 0.44
    },
    {
        name = "Farm", label = "Farm",
        x = -30, y = -67, mapX = 0.60, mapY = 0.61
    },
}

local function IsArathiBasin()
    return GetZoneText() == "Arathi Basin"
        or GetRealZoneText() == "Arathi Basin"
end

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
        SelectLocation(location.label, location.button)
    end

    return location
end

for _, loc in ipairs(locations) do
    -- Copy the value for the click handler (important on older Lua clients).
    local locationName = loc.name
    local locationLabel = loc.label
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    local locationButton = btn
    btn:SetWidth(56)
    btn:SetHeight(18)
    btn:SetPoint("TOP", frame, "TOP", loc.x, loc.y)
    btn:SetText(loc.label)
    loc.button = btn

    btn:SetScript("OnClick", function()
        UpdateCurrentLocation()
        SelectLocation(locationLabel, locationButton)
        SendSelectedCall(locationName)
    end)
end

---------------------------------------------------------
-- NUMBER BUTTONS (1–5)
---------------------------------------------------------
-- Keep the nearest Arathi Basin base selected while the helper is visible.
local nextLocationUpdate = 0
local advertiseFrame = CreateFrame("Frame")
local advertiseAt = nil
local advertisedInCurrentBattleground = false

local function IsAdvertEnabled()
    return not BGHelperDB or BGHelperDB.advertiseEnabled ~= false
end

local function IsInBattleground()
    for i = 1, 3 do
        if GetBattlefieldStatus(i) == "active" then
            return true
        end
    end

    return false
end

local function ScheduleBattlegroundAdvert()
    if IsAdvertEnabled()
        and not advertisedInCurrentBattleground
        and not advertiseAt then
        -- Give the battleground chat channel a moment to become available.
        advertiseAt = GetTime() + 3
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "BGHelper" then
        BGHelperDB = BGHelperDB or {}

        if BGHelperDB.advertiseEnabled == nil then
            BGHelperDB.advertiseEnabled = true
        end

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
        ScheduleBattlegroundAdvert()
    else
        advertiseAt = nil
        advertisedInCurrentBattleground = false
    end

    if IsArathiBasin() then
        frame:Show()
        SetMapToCurrentZone()
        nextLocationUpdate = 0

        local location = GetNearestLocation(false)
        if location then
            SelectLocation(location.label, location.button)
        end
    else
        frame:Hide()
        ClearLocation()
    end
end)

advertiseFrame:SetScript("OnUpdate", function()
    if not advertiseAt or GetTime() < advertiseAt then
        return
    end

    if IsAdvertEnabled() and IsInBattleground() then
        SendChatMessage(
            "Hi all! I'm using BG Helper for quick, clear base callouts. "
            .. "Get it here: https://github.com/stephanancher/BGHelper",
            "BATTLEGROUND"
        )
        advertisedInCurrentBattleground = true
    end

    advertiseAt = nil
end)

frame:SetScript("OnShow", function()
    if IsArathiBasin() then
        SetMapToCurrentZone()
        nextLocationUpdate = 0

        local location = GetNearestLocation(false)
        if location then
            SelectLocation(location.label, location.button)
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
        SelectLocation(location.label, location.button)
    end
end)

local numbers = {1, 2, 3, 4, 5}

for i, num in ipairs(numbers) do
    -- Copy the value for the click handler (important on older Lua clients).
    local amount = num
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetWidth(21)
    btn:SetHeight(18)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 9 + (i-1)*23, -88)
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
aLotBtn:SetPoint("TOP", frame, "TOP", -30, -109)
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
callBtn:SetPoint("TOP", frame, "TOP", 30, -109)
callBtn:SetText("CALL")

callBtn:SetScript("OnClick", function()
    local location = UpdateCurrentLocation()
    if not location then
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Automatic location only works inside Arathi Basin."
        )
        return
    end

    SelectLocation(location.label, location.button)

    if selectedCall then
        SendSelectedCall(location.name)
    else
        SendChatMessage(location.name .. " needs help!", "BATTLEGROUND")
    end
end)

---------------------------------------------------------
-- SAFE BUTTON
---------------------------------------------------------
local safeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
safeBtn:SetWidth(52)
safeBtn:SetHeight(18)
safeBtn:SetPoint("TOP", frame, "TOP", 30, -67)
safeBtn:SetText("SAFE")

safeBtn:SetScript("OnClick", function()
    UpdateCurrentLocation()
    SelectCall("SAFE", safeBtn)
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
    elseif msg == "announce"
        or msg == "announce toggle"
        or msg == "advert"
        or msg == "advert toggle" then
        BGHelperDB = BGHelperDB or {}
        BGHelperDB.advertiseEnabled = not IsAdvertEnabled()

        if not BGHelperDB.advertiseEnabled then
            advertiseAt = nil
        end

        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Join announcement "
            .. (BGHelperDB.advertiseEnabled and "enabled." or "disabled.")
        )
    elseif msg == "announce on" or msg == "advert on" then
        BGHelperDB = BGHelperDB or {}
        BGHelperDB.advertiseEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Join announcement enabled."
        )
    elseif msg == "announce off" or msg == "advert off" then
        BGHelperDB = BGHelperDB or {}
        BGHelperDB.advertiseEnabled = false
        advertiseAt = nil
        DEFAULT_CHAT_FRAME:AddMessage(
            "BG Helper: Join announcement disabled."
        )
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
            "BG Helper: /bgh [show | hide | toggle | announce on/off | debug]"
        )
    end
end
