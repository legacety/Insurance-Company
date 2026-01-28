local fa = require 'fAwesome6_solid'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local acef = require 'arizona-events'
local sampev = require 'samp.events'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local activeTab = 1

local Clicker  = imgui.new.bool(true)
local Konvert  = imgui.new.bool(true)
local Office = imgui.new.bool(true)
local TextDraw = imgui.new.bool(true)
local td = {94, 95, 96, 97}
local TdClickDelay = imgui.new.int(300)

local tabs = { 
    {name = u8"Главная", icon = fa.HOUSE}, 
    {name = u8"Функции СК", icon = fa.SCREWDRIVER_WRENCH}, 
    {name = u8"Заработок с СК", icon = fa.CIRCLE_DOLLAR_TO_SLOT} 
}

local function applyTheme()
    local style = imgui.GetStyle()
    local clr = style.Colors
    style.WindowRounding = 0
    style.ChildRounding = 4
    style.FrameRounding = 4
    style.WindowBorderSize = 0
    style.FrameBorderSize = 0
    style.ItemSpacing = imgui.ImVec2(10, 12)
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)

    clr[imgui.Col.Text]          = imgui.ImVec4(0.85, 0.86, 0.88, 1)
    clr[imgui.Col.WindowBg]      = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    clr[imgui.Col.ChildBg]       = imgui.ImVec4(0.07, 0.09, 0.11, 1)
    clr[imgui.Col.TitleBg]       = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    clr[imgui.Col.TitleBgActive] = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    clr[imgui.Col.Button]        = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    clr[imgui.Col.ButtonHovered] = imgui.ImVec4(0.18, 0.22, 0.26, 1)
    clr[imgui.Col.ButtonActive]  = imgui.ImVec4(0.18, 0.22, 0.26, 1)
    clr[imgui.Col.FrameBg]       = imgui.ImVec4(0.10, 0.14, 0.18, 1)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    applyTheme()
    fa.Init(13)
end)

imgui.OnFrame(function() return renderWindow[0] end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(550, 450), imgui.Cond.FirstUseEver)
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin(u8"SetVc Tools", renderWindow, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoCollapse) then
        imgui.BeginChild("LeftMenu", imgui.ImVec2(150, -1), true)
        for i, tab in ipairs(tabs) do
            if imgui.Button(tab.icon .. "  " .. tab.name, imgui.ImVec2(-1, 35)) then
                activeTab = i
            end
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("MainContent", imgui.ImVec2(-1, -1), true)
        if activeTab == 1 then
            imgui.Text(u8"Добро пожаловать на главную вкладку")
            imgui.Text(u8"Автор: legacy")
            imgui.Text(u8"Версия 1.0")
elseif activeTab == 2 then
    imgui.Text(u8"Настройки панели управления")
    imgui.Checkbox(u8"Включить кликер", Clicker)
    imgui.Checkbox(u8"Включить конвертер", Konvert)
    imgui.Checkbox(u8"Включить автозаполнение документов", Office)
imgui.Checkbox(u8"Включить клик по текстдрайвам", TextDraw)

if TextDraw[0] then
    imgui.Separator()
    imgui.Text(u8"Настройка клика по TextDraw")
    imgui.SliderInt(u8"Задержка (мс)", TdClickDelay, 1, 500)
end
        elseif activeTab == 3 then
            imgui.Text(u8"Информация о скрипте")
        end
        imgui.EndChild()
        imgui.End()
    end
end)

function sampev.onShowTextDraw(id)
    if not TextDraw[0] then return end
    for _, td_id in ipairs(td) do
        if id == td_id then
            lua_thread.create(function()
                for _, click_id in ipairs(td) do
                    wait(TdClickDelay[0])
                    sampSendClickTextdraw(click_id)
                end
            end)
            break
        end
    end
end


function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not Office[0] then return end
    if title:find('{BFBBBA}Заполнение документа') then
        sampSendDialogResponse(id, 1, nil, text:match('{ffff00}(.+)'))
        return false
    end
end

function acef.onArizonaDisplay(packet)
    if Clicker[0] and packet.text:find("window.executeEvent%('event.clicker.setProgress', `%[%d+%]`%);") then
        lua_thread.create(function()
            for i = 1, 4 do
                acef.send("onArizonaSend", { server_id = 0, text = "clickMinigame" })
                wait(69)
            end
        end)
    end

    if Konvert[0] and packet.text:find([[window%.executeEvent%('event%.setActiveView', `%["FindGame"%]`%);]]) then
        for i = 1, 5 do
            acef.send("onArizonaSend", { server_id = 0, text = "findGame.Success" })
        end
        acef.send("onArizonaSend", { server_id = 0, text = "findGame.finish" })
        return false
    end
end

function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage("{00FFFF}[SetVc Tools] {FFFFFF}Загружен. Активация {00FFFF}/vc", 0xFFFFFF)
    sampRegisterChatCommand("vc", function()
        renderWindow[0] = not renderWindow[0]
    end)
    wait(-1)
end
