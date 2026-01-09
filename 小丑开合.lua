local CONFIG = {
    LIBRARY_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua",
    THEME_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua",
    SCRIPT_NAME = "小丑开合 💕"
}

local function safeLoad(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    
    if success then
        return result
    else
        warn("加载失败: " .. url)
        return nil
    end
end

-- 先加载必要的库
local Library = safeLoad(CONFIG.LIBRARY_URL)

if not Library then
    game.Players.LocalPlayer:Kick("无法加载必要库文件，请检查网络连接~")
    return
end

-- 创建全局任务管理器
local TaskManager = {
    activeTasks = {}
}

function TaskManager:StartTask(name, func)
    if self.activeTasks[name] then
        self:CancelTask(name)
    end
    
    self.activeTasks[name] = task.spawn(func)
end

function TaskManager:CancelTask(name)
    if self.activeTasks[name] then
        task.cancel(self.activeTasks[name])
        self.activeTasks[name] = nil
        return true
    end
    return false
end

function TaskManager:CancelAll()
    for name, _ in pairs(self.activeTasks) do
        self:CancelTask(name)
    end
end

-- 全局模式配置
local Modes = {
    Normal = {
        start = 1,
        endAt = 10,
        prefix = "",
        delay = 2.5,
        running = false
    },
    Devil = {
        start = 1,
        endAt = 10,
        prefix = "",
        speed = 1,
        charInterval = 1.2,
        running = false
    },
    PinyinEnglish = {
        start = 1,
        endAt = 10,
        prefix = "",
        delay = 2.5,
        separator = "-",
        uppercase = true,
        running = false
    },
    English = {
        start = 1,
        endAt = 10,
        prefix = "",
        delay = 2.5,
        uppercase = true,
        running = false
    },
    EnglishDevil = {
        start = 1,
        endAt = 10,
        prefix = "",
        speed = 1,
        uppercase = true,
        running = false
    }
}

-- 创建主窗口
local Window
local MainTabs

-- 数字转换器
local NumberConverter = {}

NumberConverter.PinyinDigits = {
    [0] = "LING", [1] = "YI", [2] = "ER", [3] = "SAN", [4] = "SI",
    [5] = "WU", [6] = "LIU", [7] = "QI", [8] = "BA", [9] = "JIU",
    [10] = "SHI", [100] = "BAI", [1000] = "QIAN"
}

NumberConverter.EnglishDigits = {
    [0] = "zero", [1] = "one", [2] = "two", [3] = "three", [4] = "four",
    [5] = "five", [6] = "six", [7] = "seven", [8] = "eight", [9] = "nine",
    [10] = "ten", [11] = "eleven", [12] = "twelve", [13] = "thirteen",
    [14] = "fourteen", [15] = "fifteen", [16] = "sixteen", [17] = "seventeen",
    [18] = "eighteen", [19] = "nineteen", [20] = "twenty", [30] = "thirty",
    [40] = "forty", [50] = "fifty", [60] = "sixty", [70] = "seventy",
    [80] = "eighty", [90] = "ninety", [100] = "hundred", [1000] = "thousand"
}

function NumberConverter.ToPinyin(num)
    if num < 0 or num > 9999 then
        return "SHUZITAIDA"
    end
    
    if num <= 10 then
        return NumberConverter.PinyinDigits[num]
    end
    
    if num < 100 then
        local tens = math.floor(num / 10)
        local ones = num % 10
        
        -- 如果是10的倍数（20, 30, 40...）
        if ones == 0 then
            if tens == 1 then
                return "SHI"  -- 10单独处理
            else
                -- 20, 30, 40... 格式：ER SHI
                return NumberConverter.PinyinDigits[tens] .. "SHI"
            end
        else
            -- 不是10的倍数，去掉"十"
            -- 例如：11 -> YI YI，而不是 YI SHI YI
            -- 例如：23 -> ER SAN，而不是 ER SHI SAN
            if tens == 1 then
                -- 11-19：YI YI, YI ER, YI SAN...
                return "YI" .. NumberConverter.PinyinDigits[ones]
            else
                -- 21-29, 31-39...：ER YI, ER ER, SAN YI...
                return NumberConverter.PinyinDigits[tens] .. NumberConverter.PinyinDigits[ones]
            end
        end
    end
    
    -- 处理100以上的数字
    local result = ""
    local thousands = math.floor(num / 1000)
    local hundreds = math.floor((num % 1000) / 100)
    local tens = math.floor((num % 100) / 10)
    local ones = num % 10
    
    -- 千位
    if thousands > 0 then
        result = result .. NumberConverter.PinyinDigits[thousands] .. "QIAN"
    end
    
    -- 百位
    if hundreds > 0 then
        result = result .. NumberConverter.PinyinDigits[hundreds] .. "BAI"
    end
    
    -- 十位
    if tens > 0 then
        -- 判断是否是10的倍数（整十数）
        local isMultipleOfTen = (ones == 0)
        
        if isMultipleOfTen then
            -- 整十数：加上SHI
            if tens == 1 then
                result = result .. "YISHI"
            else
                result = result .. NumberConverter.PinyinDigits[tens] .. "SHI"
            end
        else
            -- 不是整十数：去掉SHI
            if tens == 1 then
                result = result .. "YI"
            else
                result = result .. NumberConverter.PinyinDigits[tens]
            end
        end
    end
    
    -- 个位
    if ones > 0 then
        result = result .. NumberConverter.PinyinDigits[ones]
    end
    
    return result
end

function NumberConverter.ToEnglish(num, uppercase)
    if num < 0 or num > 9999 then
        return ""
    end
    
    if num <= 20 then
        local result = NumberConverter.EnglishDigits[num]
        return uppercase and string.upper(result) or result
    end
    
    if num < 100 then
        local tens = math.floor(num / 10) * 10
        local ones = num % 10
        
        local result = NumberConverter.EnglishDigits[tens]
        if ones > 0 then
            result = result .. "-" .. NumberConverter.EnglishDigits[ones]
        end
        
        return uppercase and string.upper(result) or result
    end
    
    local result = ""
    local thousands = math.floor(num / 1000)
    local hundreds = math.floor((num % 1000) / 100)
    local remainder = num % 100
    
    if thousands > 0 then
        result = result .. NumberConverter.EnglishDigits[thousands] .. " " .. NumberConverter.EnglishDigits[1000]
        if hundreds > 0 or remainder > 0 then
            result = result .. " "
        end
    end
    
    if hundreds > 0 then
        result = result .. NumberConverter.EnglishDigits[hundreds] .. " " .. NumberConverter.EnglishDigits[100]
        if remainder > 0 then
            result = result .. " "
        end
    end
    
    if remainder > 0 then
        if remainder <= 20 then
            result = result .. NumberConverter.EnglishDigits[remainder]
        else
            local tens = math.floor(remainder / 10) * 10
            local ones = remainder % 10
            
            result = result .. NumberConverter.EnglishDigits[tens]
            if ones > 0 then
                result = result .. "-" .. NumberConverter.EnglishDigits[ones]
            end
        end
    end
    
    return uppercase and string.upper(result) or result
end

-- 核心功能函数
local function safeSendMessage(message)
    local success, err = pcall(function()
        if game:GetService("TextChatService") then
            local textChat = game:GetService("TextChatService")
            if textChat.TextChannels and textChat.TextChannels.RBXGeneral then
                textChat.TextChannels.RBXGeneral:SendAsync(message)
            else
                game.Players:Chat(message)
            end
        else
            game.Players:Chat(message)
        end
    end)
    
    if not success then
        warn("发送消息失败: " .. tostring(err))
    end
end

local function performJump()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function jumpAndSend(message)
    performJump()
    task.wait(0.2)
    safeSendMessage(message)
end

-- 执行函数
local function executeNormalMode()
    local config = Modes.Normal
    TaskManager:StartTask("normal", function()
        for i = config.start, config.endAt do
            jumpAndSend(NumberConverter.ToPinyin(i) .. config.prefix)
            task.wait(config.delay)
        end
        jumpAndSend("DONE")
        Library:Notify("开合跳完成啦~", 3)
        Modes.Normal.running = false
    end)
end

local function executeDevilMode()
    local config = Modes.Devil
    TaskManager:StartTask("devil", function()
        for i = config.start, config.endAt do
            local originalPinyin = NumberConverter.ToPinyin(i)
            
            if i >= 10 and i <= 99 then
                local isMultipleOfTen = (i % 10 == 0)
                
                if isMultipleOfTen then
                    if i == 10 then
                        local pinyinForTen = "SHI"
                        
                        for j = 1, #pinyinForTen do
                            local char = string.sub(pinyinForTen, j, j)
                            jumpAndSend(char)
                            task.wait(0.3 * config.speed)
                            task.wait(config.charInterval)
                        end
                        
                        jumpAndSend(pinyinForTen .. config.prefix)
                        task.wait(0.8 * config.speed)
                        task.wait(1.5 * config.speed)
                    else
                        for j = 1, #originalPinyin do
                            local char = string.sub(originalPinyin, j, j)
                            jumpAndSend(char)
                            task.wait(0.3 * config.speed)
                            task.wait(config.charInterval)
                        end
                        
                        jumpAndSend(originalPinyin .. config.prefix)
                        task.wait(0.8 * config.speed)
                        task.wait(1.5 * config.speed)
                    end
                else
                    -- 对于非10的倍数，直接使用修改后的拼音（已经去掉了SHI）
                    local pinyinWithoutShi = originalPinyin
                    
                    for j = 1, #pinyinWithoutShi do
                        local char = string.sub(pinyinWithoutShi, j, j)
                        jumpAndSend(char)
                        task.wait(0.3 * config.speed)
                        task.wait(config.charInterval)
                    end
                    
                    jumpAndSend(pinyinWithoutShi .. config.prefix)
                    task.wait(0.8 * config.speed)
                    task.wait(1.5 * config.speed)
                end
            else
                for j = 1, #originalPinyin do
                    local char = string.sub(originalPinyin, j, j)
                    jumpAndSend(char)
                    task.wait(0.3 * config.speed)
                    task.wait(config.charInterval)
                end
                
                jumpAndSend(originalPinyin .. config.prefix)
                task.wait(0.8 * config.speed)
                task.wait(1.5 * config.speed)
            end
        end
        
        jumpAndSend("DONE")
        Library:Notify("魔鬼跳完成啦~", 3)
        Modes.Devil.running = false
    end)
end

local function executePinyinEnglishMode()
    local config = Modes.PinyinEnglish
    TaskManager:StartTask("pinyin_english", function()
        for i = config.start, config.endAt do
            local pinyin = NumberConverter.ToPinyin(i)
            local english = NumberConverter.ToEnglish(i, config.uppercase)
            jumpAndSend(pinyin .. config.separator .. english .. config.prefix)
            task.wait(config.delay)
        end
        jumpAndSend("DONE")
        Library:Notify("拼音+英文完成啦~", 3)
        Modes.PinyinEnglish.running = false
    end)
end

local function executeEnglishMode()
    local config = Modes.English
    TaskManager:StartTask("english", function()
        for i = config.start, config.endAt do
            local english = NumberConverter.ToEnglish(i, config.uppercase)
            jumpAndSend(english .. config.prefix)
            task.wait(config.delay)
        end
        jumpAndSend("DONE")
        Library:Notify("英文跳完成啦~", 3)
        Modes.English.running = false
    end)
end

local function executeEnglishDevilMode()
    local config = Modes.EnglishDevil
    TaskManager:StartTask("english_devil", function()
        for i = config.start, config.endAt do
            local english = NumberConverter.ToEnglish(i, config.uppercase)
            
            for j = 1, #english do
                local char = string.sub(english, j, j)
                if char ~= " " and char ~= "-" then
                    jumpAndSend(char)
                    task.wait(0.3 * config.speed)
                end
            end
            
            jumpAndSend(english .. config.prefix)
            task.wait(0.8 * config.speed)
            task.wait(1.5 * config.speed)
        end
        
        jumpAndSend("DONE")
        Library:Notify("英文魔鬼跳完成啦~", 3)
        Modes.EnglishDevil.running = false
    end)
end

-- 创建主界面
Window = Library:CreateWindow({
    Title = CONFIG.SCRIPT_NAME,
    Footer = "版本 1.0 | 永久免费 | 作者: CLOWN 💖 | 本脚本完全免费 ⭕️💵的都没有妈",
    Icon = 6026566958,
    NotifySide = "Right",
    AutoShow = true,
    Size = UDim2.new(0, 420, 0, 580) -- 优化窗口大小，更舒适
})

-- 创建标签页
MainTabs = {
    Main = Window:AddTab("🌸 普通开合跳"),
    Devil = Window:AddTab("😈 魔鬼开合跳"),
    PinyinEnglish = Window:AddTab("🌐 拼音+英文"),
    English = Window:AddTab("🇬🇧 英文开合跳"),
    EnglishDevil = Window:AddTab("👻 英文魔鬼跳"),
    Settings = Window:AddTab("⚙️ 脚本设置")
}

-- 开合跳设置
local normalGroup = MainTabs.Main:AddLeftGroupbox("🌸 基础设置")

normalGroup:AddInput("normal_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 ✨",
    Callback = function(value)
        Modes.Normal.prefix = value
    end
})

normalGroup:AddInput("normal_start", {
    Text = "起始数字",
    Default = "1",
    Numeric = true,
    Placeholder = "最小: 1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.Normal.start = num
        end
    end
})

normalGroup:AddInput("normal_end", {
    Text = "结束数字",
    Default = "10",
    Numeric = true,
    Placeholder = "最大: 9999",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.Normal.endAt = num
        end
    end
})

normalGroup:AddSlider("normal_delay", {
    Text = "动作间隔(s)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        Modes.Normal.delay = value
    end
})

-- 按钮美化：增加换行和间距
normalGroup:AddButton({
    Text = "▶️ 开始",
    Func = function()
        if not Modes.Normal.running then
            Modes.Normal.running = true
            executeNormalMode()
        end
    end
})

normalGroup:AddButton({
    Text = "⏹️ 停止",
    Func = function()
        if TaskManager:CancelTask("normal") then
            Modes.Normal.running = false
            Library:Notify("已停止~", 2)
        end
    end
})

-- 魔鬼跳设置
local devilGroup = MainTabs.Devil:AddLeftGroupbox("😈 魔鬼模式设置")

devilGroup:AddInput("devil_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 😈",
    Callback = function(value)
        Modes.Devil.prefix = value
    end
})

devilGroup:AddInput("devil_start", {
    Text = "起始数字",
    Default = "1",
    Numeric = true,
    Placeholder = "最小: 1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.Devil.start = num
        end
    end
})

devilGroup:AddInput("devil_end", {
    Text = "结束数字",
    Default = "10",
    Numeric = true,
    Placeholder = "最大: 9999",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.Devil.endAt = num
        end
    end
})

devilGroup:AddSlider("devil_speed", {
    Text = "执行速度",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Callback = function(value)
        Modes.Devil.speed = value
    end
})

devilGroup:AddSlider("devil_interval", {
    Text = "字母间隔(s)",
    Default = 1.2,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Callback = function(value)
        Modes.Devil.charInterval = value
    end
})

devilGroup:AddButton({
    Text = "▶️ 开始",
    Func = function()
        if not Modes.Devil.running then
            Modes.Devil.running = true
            executeDevilMode()
        end
    end
})

devilGroup:AddButton({
    Text = "⏹️ 停止",
    Func = function()
        if TaskManager:CancelTask("devil") then
            Modes.Devil.running = false
            Library:Notify("已停止魔鬼模式~", 2)
        end
    end
})

-- 拼音+英文设置
local comboGroup = MainTabs.PinyinEnglish:AddLeftGroupbox("🌐 双语模式设置")

comboGroup:AddInput("combo_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 🌐",
    Callback = function(value)
        Modes.PinyinEnglish.prefix = value
    end
})

comboGroup:AddInput("combo_separator", {
    Text = "拼音英文分隔符",
    Default = "-",
    Placeholder = "例如: - 或 |",
    Callback = function(value)
        Modes.PinyinEnglish.separator = value
    end
})

comboGroup:AddInput("combo_start", {
    Text = "起始数字",
    Default = "1",
    Numeric = true,
    Placeholder = "最小: 1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.PinyinEnglish.start = num
        end
    end
})

comboGroup:AddInput("combo_end", {
    Text = "结束数字",
    Default = "10",
    Numeric = true,
    Placeholder = "最大: 9999",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.PinyinEnglish.endAt = num
        end
    end
})

comboGroup:AddSlider("combo_delay", {
    Text = "动作间隔(s)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        Modes.PinyinEnglish.delay = value
    end
})

comboGroup:AddToggle("combo_uppercase", {
    Text = "英文大写显示",
    Default = true,
    Callback = function(value)
        Modes.PinyinEnglish.uppercase = value
    end
})

comboGroup:AddButton({
    Text = "▶️ 开始",
    Func = function()
        if not Modes.PinyinEnglish.running then
            Modes.PinyinEnglish.running = true
            executePinyinEnglishMode()
        end
    end
})

comboGroup:AddButton({
    Text = "⏹️ 停止",
    Func = function()
        if TaskManager:CancelTask("pinyin_english") then
            Modes.PinyinEnglish.running = false
            Library:Notify("已停止双语模式~", 2)
        end
    end
})

-- 英文开合跳设置
local englishGroup = MainTabs.English:AddLeftGroupbox("🇬🇧 英文模式设置")

englishGroup:AddInput("english_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 🇬🇧",
    Callback = function(value)
        Modes.English.prefix = value
    end
})

englishGroup:AddInput("english_start", {
    Text = "起始数字",
    Default = "1",
    Numeric = true,
    Placeholder = "最小: 1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.English.start = num
        end
    end
})

englishGroup:AddInput("english_end", {
    Text = "结束数字",
    Default = "10",
    Numeric = true,
    Placeholder = "最大: 9999",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.English.endAt = num
        end
    end
})

englishGroup:AddSlider("english_delay", {
    Text = "动作间隔(s)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        Modes.English.delay = value
    end
})

englishGroup:AddToggle("english_uppercase", {
    Text = "英文大写显示",
    Default = true,
    Callback = function(value)
        Modes.English.uppercase = value
    end
})

englishGroup:AddButton({
    Text = "▶️ 开始",
    Func = function()
        if not Modes.English.running then
            Modes.English.running = true
            executeEnglishMode()
        end
    end
})

englishGroup:AddButton({
    Text = "⏹️ 停止",
    Func = function()
        if TaskManager:CancelTask("english") then
            Modes.English.running = false
            Library:Notify("已停止英文模式~", 2)
        end
    end
})

-- 英文魔鬼跳设置
local englishDevilGroup = MainTabs.EnglishDevil:AddLeftGroupbox("👻 英文魔鬼设置")

englishDevilGroup:AddInput("english_devil_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 👻",
    Callback = function(value)
        Modes.EnglishDevil.prefix = value
    end
})

englishDevilGroup:AddInput("english_devil_start", {
    Text = "起始数字",
    Default = "1",
    Numeric = true,
    Placeholder = "最小: 1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.EnglishDevil.start = num
        end
    end
})

englishDevilGroup:AddInput("english_devil_end", {
    Text = "结束数字",
    Default = "10",
    Numeric = true,
    Placeholder = "最大: 9999",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 then
            Modes.EnglishDevil.endAt = num
        结束
    结束
})

englishdevigroup:add slider("英语魔鬼速度", {
文本="执行速度",
默认值=1,
最小值=0.5,
最大=3,
舍入=1,
回拨=功能(值)
模式。速度=价值
    结束
})

englishdevigroup:add toggle("英语_魔鬼_大写", {
文本="英文大写显示",
默认值=真实的,
回拨=功能(值)
模式。EnglishDevil.uppercase =值
    结束
})

englishdevigroup:add button({
文本="▶️ 开始",
Func =功能()
        如果 不模式。英语魔鬼.跑步然后
模式。EnglishDevil.running =真实的
executeEnglishDevilMode()
        结束
    end
})

englishDevilGroup:AddButton({
    Text = "⏹️ 停止",
    Func = function()
        if TaskManager:CancelTask("english_devil") then
            Modes.EnglishDevil.running = false
            Library:Notify("已停止英文魔鬼模式~", 2)
        end
    end
})

-- 脚本设置
local settingsGroup = MainTabs.Settings:AddLeftGroupbox("⚙️ 脚本信息")

settingsGroup:AddLabel("📌 脚本名称: " .. CONFIG.SCRIPT_NAME)
settingsGroup:AddLabel("📌 版本号: 1.0")
settingsGroup:AddLabel("📌 作者: CLOWN")
settingsGroup:AddLabel("📌 状态: ✅ 永久免费")
settingsGroup:AddLabel("📌 公告: 本脚本完全免费 ⭕️💵的都没有妈")

settingsGroup:AddDivider()

settingsGroup:AddButton({
    Text = "🛑 紧急停止所有任务",
    Func = function()
        TaskManager:CancelAll()
        for mode, _ in pairs(Modes) do
            if type(Modes[mode]) == "table" then
错误的
            结束
        结束
库:通知("所有任务都停止啦~", 3)
    结束
})

设置组:添加按钮({
文本="🗑️ 卸载脚本",
Func =功能()
TaskManager:CancelAll()
        如果图书馆。倾销然后
图书馆。卸载()
        埃尔塞夫图书馆。破坏然后
图书馆。销毁()
        结束
    结束
})

-- 应用主题管理器
当地的ThemeManager =安全负载(配置。主题_网址)
如果主题管理器然后
ThemeManager:SetLibrary(库)
主题管理器:applytob(MainTabs。设置)
结束

-- 初始化完成提示
库:通知("💕 小丑开合脚本加载成功啦！", 3)

-- 设置默认选中的标签页
窗口:选择选项卡(1)


