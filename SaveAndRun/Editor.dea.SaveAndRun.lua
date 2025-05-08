----------------------------
-- SaveAndRun     2025-05-02
----------------------------
local ICONV = "C:\\Program Files\\Git\\usr\\bin\\iconv.exe"
local CONFIG = ".SaveAndRun.toml"
local KEY_RUN = "ShiftEnter"
local KEY_FORMAT = "CtrlD"
local KEY_LINTING = "AltEnter"
local TEMP = win.GetEnv("TEMP") .. "\\"
local file1 = TEMP .. "sr.stdout.txt"
local file2 = TEMP .. "sr.stderr.txt"

local function convertFileToTable(filename, fromEncoding, lines)
   local cmd = '"' .. ICONV .. '" -f ' .. fromEncoding .. " -t UTF-8 " .. filename
   local handle = io.popen(cmd)
   local content = handle:read("*all")
   handle:close()
   for line in content:gmatch("[^\r\n]+") do
      table.insert(lines, line)
   end
   return lines
end

local function readFileToTable(filename, lines)
   lines = lines or {}
   local file = io.open(filename, "r")
   if not file then
      far.Message("Error: Unable to open the file " .. filename, "Error", nil, "w")
      return lines
   end

   for line in file:lines() do
      table.insert(lines, line)
   end

   file:close()
   return lines
end

local function readConfig(fileName)
   -- Определяем расширение файла
   local ext = fileName:match("%.([^%.]+)$") or ""
   ext = ext:lower()

   -- Получаем директорию редактируемого файла
   local dir = fileName:match("^(.*[\\/])") or ""
   local configFile = dir .. CONFIG

   local configContent = nil
   local f = io.open(configFile, "r")
   if f then
      configContent = f:read("*all")
      f:close()
   else
      -- Если конфиг не найден, проверяем директорию скрипта (начинается с @)
      local scriptDir = debug.getinfo(1).source:sub(2):match("^(.*[\\/])") or ""

      configFile = scriptDir .. CONFIG
      f = io.open(configFile, "r")
      if f then
         configContent = f:read("*all")
         f:close()
      end
   end

   -- Формируем команду по умолчанию
   local command = 'python "' .. fileName .. '"'
   local pattern = "line (%d+)"
   local encoding = ""
   local format = ""
   local formatpattern = ""
   local linting = ""
   local lintingformat = ""

   if configContent then
      -- Ищем секцию [ext] и ключ run
      local section = "%[" .. ext .. "%]"
      local inSection = false
      for line in configContent:gmatch("[^\r\n]+") do
         line = line:match("^%s*(.-)%s*$") -- Убираем пробелы
         if line:match("^%[") then
            inSection = line:match(section) ~= nil
         elseif inSection and line:match("^run%s*=") then
            local runCmd = line:match("^run%s*=%s*(.-)%s*$")
            if runCmd then
               -- Заменяем $file на имя файла
               command = runCmd:gsub("%$file", '"' .. fileName .. '"')
            end
         elseif inSection and line:match("^pattern%s*=%s*(.-)%s*$") then
            pattern = line:match("^pattern%s*=%s*(.-)%s*$")
         elseif inSection and line:match("^encoding%s*=%s*(.-)%s*$") then
            encoding = line:match("^encoding%s*=%s*(.-)%s*$")
         elseif inSection and line:match("^format%s*=") then
            local runFmt = line:match("^format%s*=%s*(.-)%s*$")
            if runFmt then
               -- Заменяем $file на имя файла
               format = runFmt:gsub("%$file", '"' .. fileName .. '"')
            end
         elseif inSection and line:match("^formatpattern%s*=") then
            formatpattern = line:match("^formatpattern%s*=%s*(.-)%s*$")
         elseif inSection and line:match("^linting%s*=") then
            local runLnt = line:match("^linting%s*=%s*(.-)%s*$")
            if runLnt then
               -- Заменяем $file на имя файла
               linting = runLnt:gsub("%$file", '"' .. fileName .. '"')
            end
         elseif inSection and line:match("^lintingpattern%s*=") then
            lintingpattern = line:match("^lintingpattern%s*=%s*(.-)%s*$")
         end
      end
   end
   return command, encoding, pattern, format, formatpattern, linting, lintingformat
end

local function showResult(lines, pattern)
   -- Создаем элементы меню
   local menuItems = {}
   local errorNo = 0
   for i, line in ipairs(lines) do
      table.insert(menuItems, { text = "  " .. line, LineNumber = nil })
      -- Ищем в строке паттерн с номером строки и столбца
      local lineNum, colNum = line:match(pattern)
      if lineNum then
         errorNo = errorNo + 1
         menuItems[i].LineNumber = tonumber(lineNum)
         menuItems[i].ColNumber = tonumber(colNum)
         menuItems[i].text = "&" .. tostring(errorNo) .. " " .. line

         if errorNo == 1 then -- выбор первой строки приводит к переходу на первую ошибку
            menuItems[1].LineNumber = tonumber(lineNum)
            menuItems[1].ColNumber = tonumber(colNum)
         end
      end
   end

   if not menuItems or #menuItems == 0 then
      return
   end

   -- Показываем меню
   local menuProps = {
      Title = "Script Output",
      Bottom = "Enter: Go to line, Esc: Close",
      Flags = { FMENU_WRAPMODE = true },
   }
   local item, pos = far.Menu(menuProps, menuItems)

   -- Обрабатываем выбор пользователя
   if item and item.LineNumber then
      -- Переходим к указанной строке в редакторе
      editor.SetPosition(nil, item.LineNumber, item.ColNumber)
      editor.Redraw()
   end
end

local function runCommand(command, encoding, pattern)
   local exitCode = win.system("cmd /c chcp 65001 >nul && " .. command .. ' 2> "' .. file2 .. '" > "' .. file1 .. '"')

   local lines = {}
   if exitCode ~= 0 then
      local msg = "Exit code: " .. exitCode
      table.insert(lines, msg)
   end

   if encoding ~= "" then -- если задана кодировка, конвертируем выходные файлы
      lines = convertFileToTable(file1, encoding, lines)
      lines = convertFileToTable(file2, encoding, lines)
   else -- иначе просто их читаем
      lines = readFileToTable(file1, lines)
      lines = readFileToTable(file2, lines)
   end
   showResult(lines, pattern)
end

local function runFormat(format, pattern)
   local exitCode = win.system("cmd /c chcp 65001 >nul && " .. format .. ' 2> "' .. file2 .. '" > "' .. file1 .. '"')

   local lines = {}
   if exitCode ~= 0 then -- не смог
      local msg = "Exit code: " .. exitCode
      table.insert(lines, msg)
      lines = readFileToTable(file1, lines)
      lines = readFileToTable(file2, lines)

      showResult(lines, pattern)
   else
      -- перезагрузить файл, если все ok
      local F = far.Flags
      local f = editor.GetInfo(-1).FileName

      editor.Quit(-1)
      editor.Editor(f, _, _, _, _, _, bit64.bor(F.EF_NONMODAL, F.EF_IMMEDIATERETURN, F.EF_OPENMODE_USEEXISTING), -1, -1)
   end
end

local function SaveAndRun(act)
   -- Получаем информацию о текущем редакторе
   local info = editor.GetInfo()
   if not info then
      far.Message("No file open in editor", "Error", nil, "w")
      return
   end

   -- Получаем полное имя файла в редакторе
   local fileName = editor.GetFileName()
   if not fileName then
      far.Message("File not saved. Please save the file first.", "Error", nil, "w")
      return
   end

   -- Сохраняем файл
   if not editor.SaveFile() then
      far.Message("Failed to save file: " .. fileName, "Error", nil, "w")
      return
   end

   local command, encoding, pattern, format, formatpattern, linting, lintingformat = readConfig(fileName)

   if act == 1 then
      runCommand(command, encoding, pattern)
   elseif act == 3 then
      runCommand(linting, encoding, lintingpattern)
   else
      runFormat(format, formatpattern)
   end
end

Macro {
   area = "Editor",
   key = KEY_RUN,
   description = "Save and Run with config",
   action = function()
      SaveAndRun(1)
   end,
}

Macro {
   area = "Editor",
   key = KEY_FORMAT,
   description = "Save and Run: Format",
   action = function()
      SaveAndRun(2)
   end,
}

Macro {
   area = "Editor",
   key = KEY_LINTING,
   description = "Save and Run: Linting",
   action = function()
      SaveAndRun(3)
   end,
}

