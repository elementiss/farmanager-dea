-- ---------------------------------------------------------------------------------
-- Создание резервной копии файла при сохранении файла в редакторе
-- 2025-04-26
-- Выполняется ротация файлов таким образом, что последняя резервная
-- копия имеет номер 1, предпоследняя копия имеет номер 2 и т.д.
-- Можно задать ограничения, для каких типов файлов делать копии
-- ---------------------------------------------------------------------------------

local Settings = {
   Enable = true, -- делать ли резервные копии
   Format = "%s.%d.bak", -- шаблон имени файла, '%d' - счетчик
   -- для отключения ротации уберите счетчик из шаблона
   Folder = "",
   -- Folder = "C:\\TEMP\\Backup", -- где делать копии - в общей папке
   -- Folder = ".\\Backup", -- относительный путь
   -- Folder = "", -- в текущей папке
   MaxBackups = 5,  -- максимальное число копий одного файла
   filemasks = "*.*", -- для каких файлов делать копии, например, "*.html,*.lua"
}

local S = Settings
local F = far.Flags

local function DoBackup(Id)
   local FullName = editor.GetInfo(Id).FileName
   if not win.GetFileAttr(FullName) then
      return
   end
   local _, _, Path, Name = FullName:find("(.+\\)([^\\]+)")
   if S.Folder ~= "" then
      win.CreateDir(S.Folder, "t") -- Flag 't': If the target directory already exists, the function returns true
      Path = S.Folder .. "\\"
   end

   local NewName
   if S.Format:find("%d", 1, true) then -- true = plain text - есть номер в шаблоне имени файла, выполняем ротацию
      -- Собираем существующие резервные копии
      local backups = {}
      for i = 1, S.MaxBackups do
         local fname = Path .. S.Format:format(Name, i)
         if win.GetFileAttr(fname) then
            backups[#backups + 1] = { num = i, name = fname }
         end
      end

      -- Сортируем по номеру
      table.sort(backups, function(a, b)
         return a.num < b.num
      end)

      -- Удаляем самую старую копию, если достигнут лимит
      if #backups >= S.MaxBackups then
         win.DeleteFile(backups[#backups].name)
         table.remove(backups)
      end

      -- Сдвигаем номера существующих копий (увеличиваем на 1)
      for i = #backups, 1, -1 do
         local oldName = backups[i].name
         local newName = Path .. S.Format:format(Name, backups[i].num + 1)
         win.MoveFile(oldName, newName)
      end

      -- Новая копия всегда получает номер 1
      NewName = Path .. S.Format:format(Name, 1)
   else
      NewName = Path .. S.Format:format(Name)
   end

   local Ok, Err = win.CopyFile(FullName, NewName)

   -- были ошибки - выводим сообщение
   if Ok == nil then
      msgbox(NewName, Err)
   end
end

Event {
   group = "EditorEvent",
   description = "Создание резервной копии в редакторе при сохранении",
   filemask = S.filemasks,
   condition = function(Id, Event, Param)
      if S.Enable then
         if Event == F.EE_SAVE then
            local EdInf = editor.GetInfo(Id)
            return (EdInf.CurState == F.ECSTATE_MODIFIED or EdInf.CodePage ~= Param.CodePage)
               and EdInf.FileName:upper() == Param.FileName:upper()
         end
      end
   end,
   action = function(Id)
      return DoBackup(Id)
   end,
}
