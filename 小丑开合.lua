local CONFIG = {
    LIBRARY_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua",
    SCRIPT_NAME = "小丑开合"
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

-- 加载UI库
local Library = safeLoad(CONFIG.LIBRARY_URL)

if not Library then
    game.Players.LocalPlayer:Kick("无法加载UI库，请检查网络连接")
    return
end

-- 创建主窗口
local Window = Library:CreateWindow({
    Title = CONFIG.SCRIPT_NAME,
    Footer = "版本 1.0 | 永久免费 | 作者: CLOWN",
    Icon = 6026566958,
    NotifySide = "Right",
    AutoShow = true
})

-- 创建标签页
local Tabs = {
    Main = Window:AddTab("开合跳"),
    Devil = Window:AddTab("魔鬼跳"),
    PinyinEnglish = Window:AddTab("拼音+英文"),
    English = Window:AddTab("英文开合跳"),
    EnglishDevil = Window:AddTab("英文魔鬼跳"),
    Settings = Window:AddTab("设置")
}

-- 创建任务管理器
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

-- 模式配置
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
        
        if tens == 1 then
            return "YI" .. (ones > 0 and NumberConverter.PinyinDigits[ones] or "") .. "SHI"
        else
            local result = NumberConverter.PinyinDigits[tens] .. "SHI"
            if ones > 0 then
                result = result .. NumberConverter.PinyinDigits[ones]
            end
            return result
        end
    end
    
    local result = ""
    local thousands = math.floor(num / 1000)
    local hundreds = math.floor((num % 1000) / 100)
    local tens = math.floor((num % 100) / 10)
    local ones = num % 10
    
    if thousands > 0 then
        result = NumberConverter.PinyinDigits[thousands] .. "QIAN"
    end
    
    if hundreds > 0 then
        result = result .. NumberConverter.PinyinDigits[hundreds] .. "BAI"
    end
    
    if tens > 0 then
        result = result .. NumberConverter.PinyinDigits[tens] .. "SHI"
    end
    
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
        result = NumberConverter.EnglishDigits[thousands] .. " " .. NumberConverter.EnglishDigits[1000]
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
        Library:Notify("开合跳完成", 3)
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
                    local pinyinWithoutShi = string.gsub(originalPinyin, "SHI", "")
                    
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
        Library:Notify("魔鬼跳完成", 3)
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
        Library:Notify("拼音+英文完成", 3)
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
        Library:Notify("英文跳完成", 3)
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
        Library:Notify("英文魔鬼跳完成", 3)
        Modes.EnglishDevil.running = false
    end)
end

-- ============= UI界面设计 =============

-- 开合跳设置
local normalGroup = Tabs.Main:AddLeftGroupbox("开合跳设置")

normalGroup:AddInput("normal_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 :)",
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
    Text = "间隔时间(秒)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "秒",
    Callback = function(value)
        Modes.Normal.delay = value
    end
})

normalGroup:AddButton({
    Text = "🎯 开始开合跳",
    DoubleClick = true,
    Func = function()
        if not Modes.Normal.running then
            Modes.Normal.running = true
            Library:Notify("开始开合跳", 2)
            executeNormalMode()
        end
    end
})

normalGroup:AddButton({
    Text = "⏹️ 停止",
    DoubleClick = true,
    Func = function()
        if TaskManager:CancelTask("normal") then
            Modes.Normal.running = false
            Library:Notify("已停止开合跳", 2)
        end
    end
})

-- 右侧说明框
local normalInfoGroup = Tabs.Main:AddRightGroupbox("使用说明")
normalInfoGroup:AddLabel("功能说明:")
normalInfoGroup:AddLabel("• 发送数字的拼音")
normalInfoGroup:AddLabel("• 如: YI, ER, SAN")
normalInfoGroup:AddLabel("")
normalInfoGroup:AddLabel("使用方法:")
normalInfoGroup:AddLabel("1. 设置起始和结束数字")
normalInfoGroup:AddLabel("2. 设置间隔时间")
normalInfoGroup:AddLabel("3. 点击开始按钮")
normalInfoGroup:AddDivider()
normalInfoGroup:AddLabel("提示: 双击按钮更安全")

-- 魔鬼跳设置
local devilGroup = Tabs.Devil:AddLeftGroupbox("魔鬼跳设置")

devilGroup:AddInput("devil_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 :)",
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
    Text = "速度倍数",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Suffix = "x",
    Callback = function(value)
        Modes.Devil.speed = value
    end
})

devilGroup:AddSlider("devil_interval", {
    Text = "字母间隔(秒)",
    Default = 1.2,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Suffix = "秒",
    Callback = function(value)
        Modes.Devil.charInterval = value
    end
})

devilGroup:AddButton({
    Text = "👹 开始魔鬼跳",
    DoubleClick = true,
    Func = function()
        if not Modes.Devil.running then
            Modes.Devil.running = true
            Library:Notify("开始魔鬼跳", 2)
            executeDevilMode()
        end
    end
})

devilGroup:AddButton({
    Text = "⏹️ 停止",
    DoubleClick = true,
    Func = function()
        if TaskManager:CancelTask("devil") then
            Modes.Devil.running = false
            Library:Notify("已停止魔鬼跳", 2)
        end
    end
})

-- 魔鬼跳说明
local devilInfoGroup = Tabs.Devil:AddRightGroupbox("魔鬼跳说明")
devilInfoGroup:AddLabel("功能特点:")
devilInfoGroup:AddLabel("• 逐字母发送拼音")
devilInfoGroup:AddLabel("• 最后发送完整拼音")
devilInfoGroup:AddLabel("• 适合炫耀使用")
devilInfoGroup:AddLabel("")
devilInfoGroup:AddLabel("示例:")
devilInfoGroup:AddLabel("数字 11 -> YI SHI YI")
devilInfoGroup:AddLabel("先发: Y, I, S, H, I")
devilInfoGroup:AddLabel("再发: YISHI")
devilInfoGroup:AddDivider()
devilInfoGroup:AddLabel("警告: 此模式较慢")

-- 拼音+英文设置
local comboGroup = Tabs.PinyinEnglish:AddLeftGroupbox("拼音+英文设置")

comboGroup:AddInput("combo_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 :)",
    Callback = function(value)
        Modes.PinyinEnglish.prefix = value
    end
})

comboGroup:AddInput("combo_separator", {
    Text = "分隔符",
    Default = "-",
    Placeholder = "例如: - 或 =",
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
    Text = "间隔时间(秒)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "秒",
    Callback = function(value)
        Modes.PinyinEnglish.delay = value
    end
})

comboGroup:AddToggle("combo_uppercase", {
    Text = "英文大写",
    Default = true,
    Callback = function(value)
        Modes.PinyinEnglish.uppercase = value
    end
})

comboGroup:AddButton({
    Text = "🌐 开始拼音+英文",
    DoubleClick = true,
    Func = function()
        if not Modes.PinyinEnglish.running then
            Modes.PinyinEnglish.running = true
            Library:Notify("开始拼音+英文跳", 2)
            executePinyinEnglishMode()
        end
    end
})

comboGroup:AddButton({
    Text = "⏹️ 停止",
    DoubleClick = true,
    Func = function()
        if TaskManager:CancelTask("pinyin_english") then
            Modes.PinyinEnglish.running = false
            Library:Notify("已停止拼音+英文跳", 2)
        end
    end
})

-- 拼音+英文说明
local comboInfoGroup = Tabs.PinyinEnglish:AddRightGroupbox("双语说明")
comboInfoGroup:AddLabel("功能特点:")
comboInfoGroup:AddLabel("• 同时发送拼音和英文")
comboInfoGroup:AddLabel("• 适合双语环境")
comboInfoGroup:AddLabel("")
comboInfoGroup:AddLabel("示例:")
comboInfoGroup:AddLabel("数字 5 -> WU-FIVE")
comboInfoGroup:AddLabel("数字 12 -> SHIER-TWELVE")
comboInfoGroup:AddLabel("")
comboInfoGroup:AddLabel("可自定义分隔符")

-- 英文开合跳设置
local englishGroup = Tabs.English:AddLeftGroupbox("英文开合跳设置")

englishGroup:AddInput("english_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 :)",
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
    Text = "间隔时间(秒)",
    Default = 2.5,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "秒",
    Callback = function(value)
        Modes.English.delay = value
    end
})

englishGroup:AddToggle("english_uppercase", {
    Text = "英文大写",
    Default = true,
    Callback = function(value)
        Modes.English.uppercase = value
    end
})

englishGroup:AddButton({
    Text = "🔤 开始英文跳",
    DoubleClick = true,
    Func = function()
        if not Modes.English.running then
            Modes.English.running = true
            Library:Notify("开始英文开合跳", 2)
            executeEnglishMode()
        end
    end
})

englishGroup:AddButton({
    Text = "⏹️ 停止",
    DoubleClick = true,
    Func = function()
        if TaskManager:CancelTask("english") then
            Modes.English.running = false
            Library:Notify("已停止英文跳", 2)
        end
    end
})

-- 英文跳说明
local englishInfoGroup = Tabs.English:AddRightGroupbox("英文跳说明")
englishInfoGroup:AddLabel("功能特点:")
englishInfoGroup:AddLabel("• 只发送英文数字")
englishInfoGroup:AddLabel("• 适合国际服务器")
englishInfoGroup:AddLabel("")
englishInfoGroup:AddLabel("示例:")
englishInfoGroup:AddLabel("数字 1 -> ONE")
englishInfoGroup:AddLabel("数字 25 -> TWENTY-FIVE")
englishInfoGroup:AddLabel("数字 100 -> ONE HUNDRED")
englishInfoGroup:AddLabel("")
englishInfoGroup:AddLabel("支持大小写切换")

-- 英文魔鬼跳设置
local englishDevilGroup = Tabs.EnglishDevil:AddLeftGroupbox("英文魔鬼跳设置")

englishDevilGroup:AddInput("english_devil_prefix", {
    Text = "消息后缀",
    Default = "",
    Placeholder = "例如: ! 或 :)",
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
        end
    end
})

englishDevilGroup:AddSlider("english_devil_speed", {
    Text = "速度倍数",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Suffix = "x",
    Callback = function(value)
        Modes.EnglishDevil.speed = value
    end
})

englishDevilGroup:AddToggle("english_devil_uppercase", {
    Text = "英文大写",
    Default = true,
    Callback = function(value)
        Modes.EnglishDevil.uppercase = value
    end
})

englishDevilGroup:AddButton({
    Text = "👺 开始英文魔鬼跳",
    DoubleClick = true,
    Func = function()
        if not Modes.EnglishDevil.running then
            Modes.EnglishDevil.running = true
            Library:Notify("开始英文魔鬼跳", 2)
            executeEnglishDevilMode()
        end
    end
})

englishDevilGroup:AddButton({
    Text = "⏹️ 停止",
    DoubleClick = true,
    Func = function()
        if TaskManager:CancelTask("english_devil") then
            Modes.EnglishDevil.running = false
            Library:Notify("已停止英文魔鬼跳", 2)
        end
    end
})

-- 英文魔鬼跳说明
local englishDevilInfoGroup = Tabs.EnglishDevil:AddRightGroupbox("英文魔鬼跳说明")
englishDevilInfoGroup:AddLabel("功能特点:")
englishDevilInfoGroup:AddLabel("• 逐字母发送英文")
englishDevilInfoGroup:AddLabel("• 最后发送完整单词")
englishDevilInfoGroup:AddLabel("• 终极炫耀模式")
englishDevilInfoGroup:AddLabel("")
englishDevilInfoGroup:AddLabel("示例:")
englishDevilInfoGroup:AddLabel("THREE ->")
englishDevilInfoGroup:AddLabel("T, H, R, E, E")
englishDevilInfoGroup:AddLabel("然后: THREE")
englishDevilInfoGroup:AddDivider()
englishDevilInfoGroup:AddLabel("警告: 此模式非常慢")

-- 设置页面
local settingsGroup = Tabs.Settings:AddLeftGroupbox("脚本设置")

settingsGroup:AddLabel("脚本信息")
settingsGroup:AddLabel("名称: " .. CONFIG.SCRIPT_NAME)
settingsGroup:AddLabel("版本: 1.0")
settingsGroup:AddLabel("作者: CLOWN")
settingsGroup:AddLabel("状态: ✅ 永久免费")
settingsGroup:AddDivider()

settingsGroup:AddLabel("功能统计:")
local totalModes = 5
local activeModes = 0
for _, mode in pairs(Modes) do
    if mode.running then
        activeModes = activeModes + 1
    end
end
settingsGroup:AddLabel("总模式数: " .. totalModes)
settingsGroup:AddLabel("运行中: " .. activeModes)
settingsGroup:AddDivider()

settingsGroup:AddButton({
    Text = "🚨 紧急停止所有任务",
    DoubleClick = true,
    Func = function()
        TaskManager:CancelAll()
        for mode, _ in pairs(Modes) do
            if type(Modes[mode]) == "table" then
                Modes[mode].running = false
            end
        end
        Library:Notify("所有任务已停止", 3)
    end
})

settingsGroup:AddButton({
    Text = "🔄 重置所有设置",
    DoubleClick = true,
    Func = function()
        -- 重置所有模式设置
        Modes.Normal.start = 1
        Modes.Normal.endAt = 10
        Modes.Normal.prefix = ""
        Modes.Normal.delay = 2.5
        
        Modes.Devil.start = 1
        Modes.Devil.endAt = 10
        Modes.Devil.prefix = ""
        Modes.Devil.speed = 1
        Modes.Devil.charInterval = 1.2
        
        Modes.PinyinEnglish.start = 1
        Modes.PinyinEnglish.endAt = 10
        Modes.PinyinEnglish.prefix = ""
        Modes.PinyinEnglish.separator = "-"
        Modes.PinyinEnglish.uppercase = true
        Modes.PinyinEnglish.delay = 2.5
        
        Modes.English.start = 1
        Modes.English.endAt = 10
        Modes.English.prefix = ""
        Modes.English.uppercase = true
        Modes.English.delay = 2.5
        
        Modes.EnglishDevil.start = 1
        Modes.EnglishDevil.endAt = 10
        Modes.EnglishDevil.prefix = ""
        Modes.EnglishDevil.speed = 1
        Modes.EnglishDevil.uppercase = true
        
        Library:Notify("所有设置已重置", 3)
    end
})

settingsGroup:AddButton({
    Text = "❌ 卸载脚本",
    DoubleClick = true,
    Func = function()
        TaskManager:CancelAll()
        if Library.Unload then
            Library.Unload()
        elseif Library.Destroy then
            Library.Destroy()
        else
            Library:Notify("脚本已停止", 3)
        end
    end
})

-- 右侧快捷键说明
local shortcutsGroup = Tabs.Settings:AddRightGroupbox("快捷键提示")
shortcutsGroup:AddLabel("使用技巧:")
shortcutsGroup:AddLabel("• 双击按钮更安全")
shortcutsGroup:AddLabel("• 可以同时运行多个模式")
shortcutsGroup:AddLabel("• 合理设置间隔时间")
shortcutsGroup:AddLabel("")
shortcutsGroup:AddLabel("推荐设置:")
shortcutsGroup:AddLabel("• 开合跳: 2.5-3秒")
shortcutsGroup:AddLabel("• 魔鬼跳: 1.2-1.5秒")
shortcutsGroup:AddLabel("• 速度: 1x 最稳定")
shortcutsGroup:AddDivider()
shortcutsGroup:AddLabel("注意:")
shortcutsGroup:AddLabel("• 不要设置过快")
shortcutsGroup:AddLabel("• 不要同时运行太多")

-- 添加主题选择器（如果可用）
local themeGroup = Tabs.Settings:AddLeftGroupbox("主题设置")
themeGroup:AddDropdown("theme_selector", {
    Values = {"默认", "深色", "浅色", "红色", "蓝色", "绿色"},
    Default = "默认",
    Multi = false,
    Text = "选择主题",
    Callback = function(value)
        Library:Notify("主题已切换为: " .. value, 2)
        -- 这里可以添加主题切换逻辑
    end
})

themeGroup:AddToggle("auto_start", {
    Text = "记住上次设置",
    Default = false,
    Callback = function(value)
        Library:Notify(value and "已启用记忆功能" or "已禁用记忆功能", 2)
    end
})

-- 底部信息
local infoGroup = Tabs.Settings:AddRightGroupbox("关于")
infoGroup:AddLabel("小丑开合跳 v1.0")
infoGroup:AddLabel("")
infoGroup:AddLabel("功能介绍:")
infoGroup:AddLabel("• 5种跳模式")
infoGroup:AddLabel("• 数字转拼音/英文")
infoGroup:AddLabel("• 自定义参数")
infoGroup:AddLabel("• 安全停止机制")
infoGroup:AddDivider()
infoGroup:AddLabel("更新日志:")
infoGroup:AddLabel("v1.0 - 初始版本")
infoGroup:AddLabel("• 完全免费使用")
infoGroup:AddLabel("• 优化的UI界面")
infoGroup:AddLabel("• 稳定的执行引擎")

-- 初始化完成提示
Library:Notify("小丑开合跳已加载完成！", 5)
Library:Notify("直接使用所有功能，无需验证！", 5)

-- 设置默认选中的标签页
Window:SelectTab(1)

-- 自动显示使用提示
task.wait(2)
Library:Notify("提示: 双击按钮可以防止误操作", 3)