script_author("legacy.")
script_version("1.46")

local fa = require('fAwesome6_solid')
local imgui = require 'mimgui'
local encoding = require 'encoding'
local json = require('json')
local lfs = require("lfs")

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local configDir = getWorkingDirectory() .. '\\config'
local settingsPath = configDir .. '\\setinfo.json'
local settings = {}

local renderWindow = imgui.new.bool(false) -- âñåãäà false ïðè ñòàðòå

local function loadSettings()
    local file = io.open(settingsPath, "r")
    if file then
        local ok, data = pcall(json.decode, file:read("*a"))
        file:close()
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveSettings()
    if not lfs.attributes(configDir) then lfs.mkdir(configDir) end
    local file = io.open(settingsPath, "w+")
    if file then
        file:write(json.encode(settings))
        file:close()
    end
end

settings = loadSettings()
local windowSize = { w = settings.windowSize and settings.windowSize.w or 385,
                     h = settings.windowSize and settings.windowSize.h or 385 }

local use_autodoor = settings.use_autodoor
if use_autodoor == nil then use_autodoor = true end
local use_autodoor_bool = imgui.new.bool(use_autodoor)

local autoClickEnabled = settings.autoClickEnabled
if autoClickEnabled == nil then autoClickEnabled = false end
local autoClickEnabled_bool = imgui.new.bool(autoClickEnabled)

local autoCaptchaEnabled = settings.autoCaptchaEnabled
if autoCaptchaEnabled == nil then autoCaptchaEnabled = true end
local autoCaptchaEnabled_bool = imgui.new.bool(autoCaptchaEnabled)

local function applyTheme()
    local style = imgui.GetStyle()
    local clr = style.Colors
    style.WindowRounding, style.ChildRounding, style.FrameRounding = 0, 0, 5
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ItemSpacing = imgui.ImVec2(10, 10)
    clr[imgui.Col.Text] = imgui.ImVec4(0.85, 0.86, 0.88, 1)
    clr[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.08, 0.10, 1)
    clr[imgui.Col.ChildBg] = clr[imgui.Col.WindowBg]
    clr[imgui.Col.Button] = imgui.ImVec4(0.10, 0.15, 0.18, 1)
    clr[imgui.Col.ButtonHovered] = imgui.ImVec4(0.15, 0.20, 0.23, 1)
    clr[imgui.Col.ButtonActive] = clr[imgui.Col.ButtonHovered]
    clr[imgui.Col.TitleBg] = clr[imgui.Col.WindowBg]
    clr[imgui.Col.TitleBgActive] = clr[imgui.Col.WindowBg]
    clr[imgui.Col.TitleBgCollapsed] = clr[imgui.Col.WindowBg]
end

imgui.OnInitialize(function()
    fa.Init(14)
    applyTheme()
    imgui.GetIO().IniFilename = nil
end)

local function getInitialWindowPos()
    if settings.windowPos then
        return imgui.ImVec2(settings.windowPos.x, settings.windowPos.y)
    else
        local sx, sy = getScreenResolution()
        return imgui.ImVec2((sx - windowSize.w) / 2, (sy - windowSize.h) / 2)
    end
end

imgui.OnFrame(function() return renderWindow[0] end, function()
    local pos_x, pos_y = getInitialWindowPos().x, getInitialWindowPos().y
    imgui.SetNextWindowPos(imgui.ImVec2(pos_x, pos_y), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(windowSize.w, windowSize.h), imgui.Cond.FirstUseEver)

    if imgui.Begin(string.format("%s Insurance Helper by -legacy.%s", fa.EYE, "1.46"), renderWindow) then
        local pos, size = imgui.GetWindowPos(), imgui.GetWindowSize()
        settings.windowPos = {x = pos.x, y = pos.y}
        settings.windowSize = {w = size.x, h = size.y}

        if imgui.Checkbox("AutoDoor", use_autodoor_bool) then
            use_autodoor = use_autodoor_bool[0]
            settings.use_autodoor = use_autodoor
            saveSettings()
        end
        if imgui.Checkbox("AutoClick", autoClickEnabled_bool) then
            autoClickEnabled = autoClickEnabled_bool[0]
            settings.autoClickEnabled = autoClickEnabled
            saveSettings()
        end
        if imgui.Checkbox("AutoCaptcha", autoCaptchaEnabled_bool) then
            autoCaptchaEnabled = autoCaptchaEnabled_bool[0]
            settings.autoCaptchaEnabled = autoCaptchaEnabled
            saveSettings()
        end

        imgui.End()
    end
end)

function sendKeyH()
    if isCharInAnyCar(PLAYER_PED) then
        setGameKeyState(18, 255)
    else
        sendClickKeySync(192)
    end
end

function sendClickKeySync(key)
    local data = allocateMemory(68)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    sampStorePlayerOnfootData(myId, data)
    local weaponId = getCurrentCharWeapon(PLAYER_PED)
    setStructElement(data, 36, 1, weaponId + tonumber(key), true)
    sampSendOnfootData(data)
    freeMemory(data)
end

local function isDoorModel(model)
    local doors = {1495,3089,1561,19938,1557,1808,19857,19302,2634,19303}
    for _, v in ipairs(doors) do if v == model then return true end end
    return false
end

local function isBarrierModel(model)
    local barriers = {968,975,1374,19912,988,19313,11327,980}
    for _, v in ipairs(barriers) do if v == model then return true end end
    return false
end

function AutoDoor()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for key, hObj in pairs(getAllObjects()) do
        if doesObjectExist(hObj) then
            local objModel = getObjectModel(hObj)
            local _, ox, oy, oz = getObjectCoordinates(hObj)
            local objHeading = getObjectHeading(hObj)
            local distance = getDistanceBetweenCoords3d(px, py, pz, ox, oy, oz)

            if isDoorModel(objModel) then
                if (objHeading % 90) < 1.75 or (objHeading % 90) > 85 then
                    if distance <= 3 then sendKeyH() return end
                end
            elseif isBarrierModel(objModel) then
                local maxDist = isCharInAnyCar(PLAYER_PED) and 12 or 5
                if distance < maxDist then sendKeyH() return end
            end
        end
    end
end

function sendCustomPacket(text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function onReceivePacket(id, bs)
    if id ~= 220 then return end

    raknetBitStreamIgnoreBits(bs, 8)
    if raknetBitStreamReadInt8(bs) ~= 17 then return end
    raknetBitStreamIgnoreBits(bs, 32)

    local length = raknetBitStreamReadInt16(bs)
    local encoded = raknetBitStreamReadInt8(bs)
    local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

    if autoCaptchaEnabled then
        if str:find([[window%.executeEvent%('event%.setActiveView', `%["FindGame"%]`%);]]) then
            lua_thread.create(function()
                for i = 1, 5 do
                    sendCustomPacket('findGame.Success')
                end
                sendCustomPacket('findGame.finish')
            end)
            return false
        end

        local countKeys = tonumber(str:match('"miniGameKeysCount":(%d+)'))
        if countKeys then
            lua_thread.create(function()
                for i = 1, countKeys do
                    sendCustomPacket('miniGame.DebugKeyID|74|74|true')
                end
                sendCustomPacket('miniGame.keyReaction.finish|' .. countKeys)
            end)
            return false
        end
    end

    if autoClickEnabled then
        if str:find("Clicker",1,true) or str:find("event.clicker.setProgress",1,true) then
            lua_thread.create(function()
                local clickCmd = "clickMinigame"
                for i = 1, 20 do
                    sendCustomPacket(clickCmd)
                end
            end)
        end
    end
end

function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage("{00FF00}[GT]{FFFFFF} Ñêðèïò çàãðóæåí. Äëÿ àêòèâàöèè èñïîëüçóéòå {00FF00}/gs",0xFFFFFF)

    sampRegisterChatCommand('gs',function()
        renderWindow[0] = not renderWindow[0]  -- îòêðûòèå/çàêðûòèå îêíà òîëüêî êîìàíäîé
    end)

    while true do
        wait(111)
        if use_autodoor and not sampIsChatInputActive() and not sampIsDialogActive() 
        and not isSampfuncsConsoleActive() and not sampIsCursorActive() then
            pcall(AutoDoor)
        end
    end
end

require("samp.events").onServerMessage = function(color,text)
    if use_autodoor then
        if (text:find("Ó âàñ íåò êëþ÷åé îò äàííîãî øëàãáàóìà") or text:find("Ó âàñ íåò êëþ÷åé îò ýòîãî øëàãáàóìà!") or text:find("Ó âàñ íåò êëþ÷åé îò ýòîé äâåðè!") or text:find("Ó âàñ íåò êëþ÷åé îò äàííîé äâåðè") or text:find("Ó Âàñ íåò äîñòóïà.")) then
            return false
        end
    end
end


