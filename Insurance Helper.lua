script_name("vc - tools")
script_author("legacy")
script_version("2.5")

local imgui = require 'mimgui'
local fa = require 'fAwesome6_solid'
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local activeTab = imgui.new.int(1)
local clickerActive = imgui.new.bool(false)
local konvert = imgui.new.bool(false)
local officeActive = imgui.new.bool(false)
local tdClickerActive = imgui.new.bool(false)
local tdClickDelay = imgui.new.int(300)
local td = {94, 95, 96, 97}
local zpsk = imgui.new.int(0)

function formatNumber(num)
    local formatted = tostring(num)
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function applyTheme()
    local bg = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    local childBg = imgui.ImVec4(0.07, 0.09, 0.11, 1)
    local button = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    local buttonHover = imgui.ImVec4(0.18, 0.22, 0.26, 1)
    local frame = imgui.ImVec4(0.10, 0.14, 0.18, 1)
    local text = imgui.ImVec4(0.85, 0.86, 0.88, 1)

    local style = imgui.GetStyle()
    local clr = style.Colors
    style.WindowRounding = 0
    style.ChildRounding = 4
    style.FrameRounding = 4
    style.WindowBorderSize = 0
    style.FrameBorderSize = 0
    style.ItemSpacing = imgui.ImVec2(10, 12)

    clr[imgui.Col.Text] = text
    clr[imgui.Col.WindowBg] = bg
    clr[imgui.Col.ChildBg] = childBg
    clr[imgui.Col.TitleBg] = bg
    clr[imgui.Col.TitleBgActive] = bg
    clr[imgui.Col.TitleBgCollapsed] = bg
    clr[imgui.Col.Button] = button
    clr[imgui.Col.ButtonHovered] = buttonHover
    clr[imgui.Col.ButtonActive] = buttonHover
    clr[imgui.Col.FrameBg] = frame
    clr[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    clr[imgui.Col.FrameBgActive] = imgui.ImVec4(0.14, 0.18, 0.22, 1)
    clr[imgui.Col.Separator] = imgui.ImVec4(0.15, 0.18, 0.21, 1)
end

local function sendCustomPacket(text)
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
    if konvert[0] then
        if id ~= 220 then return end
        raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) ~= 17 then return end
        raknetBitStreamIgnoreBits(bs, 32)
        local length = raknetBitStreamReadInt16(bs)
        local encoded = raknetBitStreamReadInt8(bs)
        local str = (encoded ~= 0)
            and raknetBitStreamDecodeString(bs, length + encoded)
            or raknetBitStreamReadString(bs, length)

        if str:find([[window%.executeEvent%('event%.setActiveView', `%["FindGame"%]`%);]]) then
            for i = 1, 5 do sendCustomPacket('findGame.Success') end
            sendCustomPacket('findGame.finish')
            return false
        end

        local countKeys = tonumber(str:match('"miniGameKeysCount":(%d+)'))
        if countKeys then
            for i = 1, countKeys do
                wait(0)
                sendCustomPacket('miniGame.DebugKeyID|74|74|true')
            end
            sendCustomPacket('miniGame.keyReaction.finish|' .. countKeys)
            return false
        end
    end
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    fa.Init(16)
    applyTheme()
end)

local tabs = {
    { icon = fa.HOUSE, name = u8" Главная" },
    { icon = fa.SCREWDRIVER_WRENCH, name = u8" Инструменты" },
    { icon = fa.GEAR, name = u8" Настройки" },
    { icon = fa.CIRCLE_DOLLAR_TO_SLOT, name = u8"Заработок" }
}

local function drawSidebar()
    imgui.BeginChild("Sidebar", imgui.ImVec2(140, -1), true)
    local buttonColor = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    for i, tab in ipairs(tabs) do
        imgui.PushStyleColor(imgui.Col.Button, buttonColor)
        if imgui.Button(tab.icon .. tab.name, imgui.ImVec2(120, 40)) then
            activeTab[0] = i
        end
        imgui.PopStyleColor()
    end
    imgui.EndChild()
end

local function drawContent()
    imgui.SameLine()
    imgui.BeginChild("Content", imgui.ImVec2(0, -1), true)

    local tab = activeTab[0]

    if tab == 1 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.CIRCLE_INFO .. u8" Информация")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 5))
        imgui.Text(u8"Добро пожаловать в vc-tools!")
        imgui.Dummy(imgui.ImVec2(0, 10))
        imgui.BulletText(u8"Версия: 2.5")
        imgui.BulletText(u8"Автор: legacy")
        imgui.BulletText(u8"Команда: /vc")

    elseif tab == 2 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.SCREWDRIVER_WRENCH .. u8" Инструменты")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 10))

        imgui.Checkbox(u8"Автокликер", clickerActive)
        imgui.Checkbox(u8"Конверт", konvert)
        imgui.Checkbox(u8"Office автозаполнение", officeActive)
        imgui.Checkbox(u8"Автокликер текстдров", tdClickerActive)

        if tdClickerActive[0] then
            imgui.SliderInt(u8"Задержка (мс)", tdClickDelay, 1, 3000)
        end

    elseif tab == 3 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.GEAR .. u8" Настройки")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 5))
        imgui.Text(u8"Настройки пока пусты.")

    elseif tab == 4 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.CIRCLE_DOLLAR_TO_SLOT .. u8" Заработок")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 5))

        imgui.Text(u8"Общая заработанная сумма: ")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "$" .. formatNumber(zpsk[0]))
    end

    imgui.EndChild()
end

imgui.OnFrame(function() return renderWindow[0] end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(600, 440), imgui.Cond.FirstUseEver)
    if imgui.Begin(u8"vc-tools", renderWindow, imgui.WindowFlags.NoResize) then
        drawSidebar()
        drawContent()
        imgui.End()
    end
end)

function sampev.onShowTextDraw(id)
    if not tdClickerActive[0] then return end
    for _, td_id in ipairs(td) do
        if id == td_id then
            lua_thread.create(function()
                for _, click_id in ipairs(td) do
                    wait(tdClickDelay[0])
                    sampSendClickTextdraw(click_id)
                end
            end)
            break
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if officeActive[0] then
        if title:find('{BFBBBA}Заполнение документа') then
            if text:find('{ffffff}Введите ник клиента') or text:find('{ffffff}Укажите тип имущества') or text:find('{ffffff}Укажите номер заявки') then
                local data = text:match('{ffff00}(.+)')
                if data then
                    sampSendDialogResponse(id, 1, nil, data)
                    return false
                end
            end
        end
    end
end

function sampev.onServerMessage(color, text)
    local salary = text:match("Ваша зарплата:%s*%$([%d%.,]+)")
    if salary then
        salary = salary:gsub("[,%.]", "")
        zpsk[0] = zpsk[0] + tonumber(salary)
    end
end

function main()
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage("{00FFFF}[vc-tools] {FFFFFF}Скрипт загружен. Команда: {00FFFF}/vc", -1)

    sampRegisterChatCommand("vc", function()
        renderWindow[0] = not renderWindow[0]
    end)

    while true do
        wait(0)
        if clickerActive[0] then
            local command = "clickMinigame"
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt8(bs, 220)
            raknetBitStreamWriteInt8(bs, 18)
            raknetBitStreamWriteInt16(bs, #command)
            raknetBitStreamWriteString(bs, command)
            raknetBitStreamWriteInt32(bs, 0)
            raknetSendBitStream(bs)
            raknetDeleteBitStream(bs)
        end
    end
end