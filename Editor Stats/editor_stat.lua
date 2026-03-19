-- 2026-02-13

local function pad(s)
   return mf.strpad(s, 5, " ", 1) .. '  '
end

Macro {
   description = "Count selected lines and current line length",
   area = "Editor",
   key = "CtrlShiftS",
   flags = "",

   action = function()
      local info = editor.GetInfo()
      local totalLines = 0
      local totalChars = 0
      local totalCharsTrimmed = 0
      local totalWords = 0
      local totalBytes = 0

      local sel = editor.GetSelection()

      if sel and sel.BlockType ~= 0 then
         totalLines = sel.EndLine - sel.StartLine + 1

         for lineNum = sel.StartLine, sel.EndLine do
            local line = editor.GetString(nil, lineNum)
            if line then
               local text = line.StringText

               local startPos = 1
               local endPos = text:len()

               if lineNum == sel.StartLine then
                  startPos = sel.StartPos  -- sel.StartPos from 1
               end

               if lineNum == sel.EndLine then
                  endPos = sel.EndPos -- sel.EndPos from 0
               end

               if startPos <= endPos then
                  local part = text:sub(startPos, endPos)
                  totalChars = totalChars + part:len()
                  totalBytes = totalBytes + #part

                  part = mf.trim(part)
                  totalCharsTrimmed = totalCharsTrimmed + part:len()

                  for _ in part:gmatch("%S+") do
                     totalWords = totalWords + 1
                  end
               end
               if (lineNum == sel.EndLine) and (endPos == 0) then -- skip last empty selection
                  totalLines = totalLines - 1
               end
            end
         end
      end

      local line = editor.GetString(nil, info.CurLine)
      local lineLength = line and line.StringLength or 0
      local lineLengthBytes = line and #line.StringText or 0
      local lineLengthTrimmed = line and mf.trim(line.StringText):len() or 0

      local extra = ""
      if sel then
         extra = extra
               .. "\n"
               .. "Выделение:                    \n"
               .. "     строк ..................."
               .. pad(totalLines)
               .. "\n"

         if sel.BlockType == 1 or totalLines == 1 then -- потоковый (для вертикального надо считать по-другому)
            extra = extra
               .. "     слов ...................."
               .. pad(totalWords)
               .. "\n"
               .. "     байтов .................."
               .. pad(totalBytes)
               .. "\n"
               .. "     символов ................"
               .. pad(totalChars)
               .. "\n"
               .. "     без конечных пробелов ..."
               .. pad(totalCharsTrimmed)
               .. "\n"
         end
      end

      far.Message(
         extra
            .. "\n"
            .. "Длина текущей строки:         \n"
            .. "     байтов .................."
            .. pad(lineLengthBytes)
            .. "\n"
            .. "     символов ................"
            .. pad(lineLength)
            .. "\n"
            .. "     без конечных пробелов ..."
            .. pad(lineLengthTrimmed)
            .. "\n",
         "Статистика",
         ";OK"
      )
   end,
}

