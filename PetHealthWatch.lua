-- 1. Setup Defaults
PHW_Defaults = {
    threshPct = 50,
    threshVal = 500,
    isPercent = true,
    posX = 0,
    posY = -100,
    manaCost = 480,
    deadMemory = false
}

local isTriggered = false
local isChanneling = false
local channelStart = 0
local channelDuration = 5
local mendCastIntent = 0 
local PHW_ManaTable = { 50, 90, 155, 225, 300, 385, 480 } 

-- 2. Create the Flash Frame
local flash = CreateFrame("Frame", "PHW_FlashFrame", UIParent)
flash:SetAllPoints(UIParent)
flash:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
flash:SetFrameStrata("BACKGROUND")
flash:SetAlpha(0.3) 
flash:Hide()

-- 3. Create the Mend Button
local frame = CreateFrame("Button", "PHW_MendButton", UIParent)
frame:SetWidth(60); frame:SetHeight(60)
frame:SetMovable(true); frame:EnableMouse(true)
frame:SetFrameStrata("MEDIUM")
frame:RegisterForDrag("LeftButton")
frame:SetPoint("CENTER", 0, -100)
frame:Hide()

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints(frame)

local timerText = frame:CreateFontString(nil, "OVERLAY")
timerText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
timerText:SetPoint("BOTTOM", frame, "BOTTOM", 0, -18)

-- 4. Unified Logic Frame
local logicFrame = CreateFrame("Frame", "PHW_LogicFrame", UIParent)
logicFrame:SetScript("OnUpdate", function()
    if not PHW_Config or not PHW_Config.manaCost then return end
    
    local elapsed = arg1 or 0
    local exists = UnitExists("pet")
    local isDead = UnitIsDead("pet")
    local hp = UnitHealth("pet")
    
    -- State Memory Logic
    if exists then
        if not isDead and hp > 0 then
            PHW_Config.deadMemory = false
        else
            PHW_Config.deadMemory = true
        end
    end

    -- Dynamic UI Logic
    if PHW_Config.deadMemory then
        if exists then
            frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastSoothe")
            timerText:SetText("REVIVE PET")
        else
            frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
            timerText:SetText("CALL DEAD PET")
        end
        timerText:SetTextColor(1, 0, 0)
        flash:SetBackdropColor(1, 0, 0, 0.6)
    elseif isTriggered then
        frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_MendPet")
        local curMana = UnitMana("player")
        if (curMana < PHW_Config.manaCost) then
            timerText:SetText(curMana .. " / " .. PHW_Config.manaCost)
            timerText:SetTextColor(0.5, 0.5, 1)
            flash:SetBackdropColor(0, 0, 1, 0.4)
        elseif not exists or not (CheckInteractDistance("pet", 4)) then
            timerText:SetText("OUT OF RANGE")
            timerText:SetTextColor(1, 0.3, 0.3)
            flash:SetBackdropColor(1, 0, 0, 0.4)
        else
            timerText:SetText("HEAL PET")
            timerText:SetTextColor(1, 1, 0)
            flash:SetBackdropColor(1, 1, 0, 0.4)
        end
    end

    -- Channeling Text
    if isChanneling then
        local timeLeft = channelDuration - (GetTime() - channelStart)
        if timeLeft > 0 then
            timerText:SetTextColor(1, 1, 1)
            timerText:SetText("MENDING: " .. string.format("%.1f", timeLeft))
        else
            isChanneling = false
        end
    end

    -- Visibility Controller
    if (PHW_Config.deadMemory or isTriggered or isChanneling) then
        if not frame:IsVisible() then frame:Show() end
        if (PHW_Config.deadMemory or isTriggered) and not isChanneling then 
            flash:Show() 
            local curAlpha = flash:GetAlpha() or 0.3
            local dir = flash.alphaDir or 1
            curAlpha = curAlpha + (elapsed * 2.0 * dir)
            if curAlpha < 0.1 then curAlpha = 0.1; flash.alphaDir = 1 end
            if curAlpha > 0.6 then curAlpha = 0.6; flash.alphaDir = -1 end
            flash:SetAlpha(curAlpha)
        else 
            flash:Hide() 
        end
    else
        if frame:IsVisible() then frame:Hide() end
        flash:Hide()
    end
end)

-- 5. Helper Functions
local function PHW_PrintStatus()
    if not PHW_Config then return end
    local mode = PHW_Config.isPercent and "%" or " HP"
    local currentVal = PHW_Config.isPercent and PHW_Config.threshPct or PHW_Config.threshVal
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00PHW:|r Alert at |cff00ff00" .. currentVal .. mode .. "|r (" .. PHW_Config.manaCost .. " Mana)")
end

local function PHW_ScanMana()
    local i = 1; local highestRank = 0
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == "Mend Pet" then
            local _, _, rankNum = string.find(spellRank or "", "(%d+)")
            local rNum = tonumber(rankNum)
            if rNum and rNum > highestRank then highestRank = rNum end
        end
        i = i + 1
    end
    if PHW_Config then
        PHW_Config.manaCost = (highestRank > 0) and (PHW_ManaTable[highestRank] or 480) or 480
    end
end

-- 6. Interaction
frame:SetScript("OnClick", function() 
    if not PHW_Config then return end
    if PHW_Config.deadMemory then
        if UnitExists("pet") then
            CastSpellByName("Revive Pet")
        else
            CastSpellByName("Call Pet")
        end
    else
        mendCastIntent = GetTime() 
        CastSpellByName("Mend Pet") 
    end
end)

frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing()
    local _, _, _, x, y = this:GetPoint()
    if PHW_Config then PHW_Config.posX = x; PHW_Config.posY = y end
end)

-- 7. Event Handling
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("SPELLCAST_CHANNEL_START")
frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")

frame:SetScript("OnEvent", function()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end

    if event == "ADDON_LOADED" and arg1 == "PetHealthWatch" then
        if not PHW_Config then PHW_Config = {} end
        for k, v in pairs(PHW_Defaults) do
            if PHW_Config[k] == nil then PHW_Config[k] = v end
        end
        this:ClearAllPoints()
        this:SetPoint("CENTER", UIParent, "CENTER", PHW_Config.posX, PHW_Config.posY)
    end

    if event == "PLAYER_ENTERING_WORLD" then
        PHW_ScanMana()
    end

    if event == "SPELLCAST_CHANNEL_START" then
        if (GetTime() - mendCastIntent) < 0.5 then
            isChanneling = true; channelStart = GetTime()
        end
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        isChanneling = false
    end

    if not UnitExists("pet") or UnitIsDead("pet") then 
        isTriggered = false 
        return 
    end
    
    local cur, max = UnitHealth("pet"), UnitHealthMax("pet")
    if max == 0 then return end
    
    local val = PHW_Config.isPercent and (cur/max)*100 or cur
    local thresh = PHW_Config.isPercent and PHW_Config.threshPct or PHW_Config.threshVal
    
    if val <= thresh and not isTriggered and cur > 0 then
        isTriggered = true
        PlaySoundFile("Interface\\AddOns\\PetHealthWatch\\PetNeedsHealing.mp3")
    elseif isTriggered and val > (thresh + (PHW_Config.isPercent and 5 or 100)) then
        isTriggered = false
    end
end)

-- 8. Slash Commands
SLASH_PHW1 = "/phw"
SlashCmdList["PHW"] = function(msg)
    local _, _, cmd, arg = string.find(msg, "(%a+)%s*(.*)")
    if cmd == "set" and tonumber(arg) then
        if PHW_Config.isPercent then PHW_Config.threshPct = tonumber(arg) else PHW_Config.threshVal = tonumber(arg) end
        PHW_PrintStatus()
    elseif cmd == "toggle" then
        PHW_Config.isPercent = not PHW_Config.isPercent
        PHW_PrintStatus()
    elseif cmd == "test" then
        isTriggered = not isTriggered
        DEFAULT_CHAT_FRAME:AddMessage("PHW: Testing health alert display.")
    elseif cmd == "clear" then
        if PHW_Config then PHW_Config.deadMemory = false end
        DEFAULT_CHAT_FRAME:AddMessage("PHW: Death memory cleared.")
    elseif cmd == "reset" then
        PHW_MendButton:ClearAllPoints()
        PHW_MendButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        DEFAULT_CHAT_FRAME:AddMessage("PHW: Button position reset.")
    else
        -- Help Menu
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00PetHealthWatch Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/phw set #|r - Set alert threshold (e.g. 40)")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/phw toggle|r - Switch between % and raw HP")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/phw test|r - Toggle the alert display for testing")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/phw clear|r - Force clear death memory")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/phw reset|r - Reset button to center screen")
        PHW_PrintStatus()
    end
end