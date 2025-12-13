script_name("Insurance Helper")
script_author("legacy.")
script_version("1.00")

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

local cfg_path = getWorkingDirectory() .. "\\config\\insurance.cfg"
local records, total = {}, 0
local function loadConfig()
    local total = 0
    local records = {}
    if doesFileExist(cfg_path) then
        local f = io.open(cfg_path, "r")
        if f then
            for line in f:lines() do
                local day, money = line:match("(%d+%.%d+%.%d+)%s*=%s*(%d+)")
                if day and money then
                    table.insert(records, { date = day, money = tonumber(money) })
                    total = total + tonumber(money)
                end
            end
            f:close()
        end
    end
    return records, total
end

local function saveConfig(records)
    local f = io.open(cfg_path, "w+")
    if f then
        for _, record in ipairs(records) do
            f:write(record.date .. " = " .. record.money .. "\n")
        end
        f:close()
    end
end

local function formatNumber(num)
    return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):gsub(",$", ""):reverse()
end

function imgui.CenterTable(text)
    local colWidth = imgui.GetColumnWidth()
    local colHeight = imgui.GetContentRegionAvail().y
    local textSize = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(imgui.GetCursorPosX() + (colWidth - textSize.x) * 0.5)
    local curY = imgui.GetCursorPosY()
    imgui.SetCursorPosY(curY + (colHeight - textSize.y) * 0.05)
    imgui.Text(text)
end

local function applyTheme()
    local bg = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    local childBg = imgui.ImVec4(0.07, 0.09, 0.11, 1)
    local button = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    local buttonHover = imgui.ImVec4(0.18, 0.22, 0.26, 1)
    local frame = imgui.ImVec4(0.10, 0.14, 0.18, 1)
    local text = imgui.ImVec4(0.85, 0.86, 0.88, 1)
    local scrollbar = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    local scrollbarHover = imgui.ImVec4(0.18, 0.22, 0.26, 1)

    local style = imgui.GetStyle()
    local clr = style.Colors
    style.WindowRounding = 0
    style.ChildRounding = 4
    style.FrameRounding = 4
    style.WindowBorderSize = 0
    style.FrameBorderSize = 0
    style.ItemSpacing = imgui.ImVec2(10, 12)
    style.ScrollbarRounding = 0
    style.ScrollbarSize = 13

    clr[imgui.Col.Text] = text
    clr[imgui.Col.WindowBg] = bg
    clr[imgui.Col.ChildBg] = childBg
    clr[imgui.Col.TitleBg] = bg
    clr[imgui.Col.TitleBgActive] = bg
    clr[imgui.Col.Button] = button
    clr[imgui.Col.ButtonHovered] = buttonHover
    clr[imgui.Col.ButtonActive] = buttonHover
    clr[imgui.Col.FrameBg] = frame
    clr[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    clr[imgui.Col.FrameBgActive] = imgui.ImVec4(0.14, 0.18, 0.22, 1)
    clr[imgui.Col.Separator] = imgui.ImVec4(0.15, 0.18, 0.21, 1)
    clr[imgui.Col.ScrollbarBg] = bg
    clr[imgui.Col.ScrollbarGrab] = scrollbar
    clr[imgui.Col.ScrollbarGrabHovered] = scrollbarHover
    clr[imgui.Col.ScrollbarGrabActive] = scrollbarHover
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    fa.Init(16)
    applyTheme()
    records, total = loadConfig()
end)

local tabs = {
    { icon = fa.HOUSE, name = u8" Главная" },
    { icon = fa.SCREWDRIVER_WRENCH, name = u8" Инструменты" },
    { icon = fa.CIRCLE_DOLLAR_TO_SLOT, name = u8" Заработок" }
}

local function drawSidebar()
    imgui.BeginChild("Sidebar", imgui.ImVec2(140, -1), true)
    for i, tab in ipairs(tabs) do
        if imgui.Button(tab.icon .. tab.name, imgui.ImVec2(120, 40)) then
            activeTab[0] = i
        end
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
        imgui.Text(u8"Добро пожаловать в Insurance - Helper!")
        imgui.Text(u8"Скрипт предназначен для помощи в Insurance Helper.")
        imgui.Dummy(imgui.ImVec2(0, 10))
        imgui.BulletText(u8"Версия: 1.00.")
        imgui.BulletText(u8"Автор: legacy.")
        imgui.BulletText(u8"Команда: /ins")

    elseif tab == 2 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.SCREWDRIVER_WRENCH .. u8" Инструменты")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 10))
        imgui.Checkbox(u8"Автокликер", clickerActive)
        imgui.Checkbox(u8"Конверт", konvert)
        imgui.Checkbox(u8"Автозаполнение информации в диалоге", officeActive)
        imgui.Checkbox(u8"Автокликер тд", tdClickerActive)
        if tdClickerActive[0] then
            imgui.SliderInt(u8"Задержка (мс)", tdClickDelay, 1, 3000)
        end

    elseif tab == 3 then
        imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.CIRCLE_DOLLAR_TO_SLOT .. u8" Заработок")
        imgui.Separator()
        imgui.Dummy(imgui.ImVec2(0, 5))

        imgui.Text(u8"Общий заработок:")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "$ " .. formatNumber(total))
        imgui.Dummy(imgui.ImVec2(0, 10))

        imgui.BeginChild("Table", imgui.ImVec2(0, -1), true)
        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.Columns(2, "Columns", true)
        imgui.SetColumnWidth(0, 200)
        imgui.CenterTable(u8"День"); imgui.NextColumn()
        imgui.CenterTable(u8"Заработок"); imgui.NextColumn()
        imgui.Separator()

        for i, record in ipairs(records) do
            imgui.Text(record.date); imgui.NextColumn()
            imgui.Text("$ " .. formatNumber(record.money)); imgui.NextColumn()
            if i ~= #records then imgui.Separator() end
        end

        imgui.Columns(1)
        imgui.EndChild()
    end
    imgui.EndChild()
end

imgui.OnFrame(function() return renderWindow[0] end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(600, 440), imgui.Cond.FirstUseEver)
    if imgui.Begin(u8"Insurance - Helper", renderWindow, imgui.WindowFlags.NoResize) then
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
    local summa = text:match("Ваша зарплата:%s*%$([%d%.,]+)")
    if summa then
        summa = summa:gsub("[,%.]", "")
        local money = tonumber(summa)
        local today = os.date("%d.%m.%Y")
        local found = false
        for _, record in ipairs(records) do
            if record.date == today then
                record.money = record.money + money
                found = true
                break
            end
        end
        if not found then
            table.insert(records, { date = today, money = money })
        end
        total = 0
        for _, record in ipairs(records) do total = total + record.money end
        saveConfig(records)
    end
end

function main()
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage("{00FFFF}[Insurance Helper] {FFFFFF}загружен. Команда: {00FFFF}/ins", -1)
    sampRegisterChatCommand("ins", function()
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