-- Подсветка цветов #RRGGBB, #RRGGBBAA, rgb(), rgba() в редакторе Far Manager
-- started 2026-03-13
-- Пример   #111827    #57B0C8    #95adde    #E34646    #E3464666    #BED5C0
--  rgb(255,255,204)
--  rgb(200,100,50)
--  rgb(50,100,200)

local F = far.Flags
local bit = bit64 or bit
local colorFlags = F.ECF_TABMARKFIRST + F.ECF_TABMARKCURRENT + F.ECF_AUTODELETE


local function get_contrast_text_color(bg)
   -- bg уже в формате 0xAARRGGBB
   local r = bit.band(bit.rshift(bg, 16), 0xFF)
   local g = bit.band(bit.rshift(bg, 8), 0xFF)
   local b = bit.band(bg, 0xFF)

   -- яркость по формуле YIQ / BT.601 
   local brightness = (r * 299 + g * 587 + b * 114) / 1000 -- 0..255

   if brightness > 130 then
      return 0xFF000000 -- чёрный текст
   else
      return 0xFFFFFFFF -- белый текст
   end
end

local function make_color(r,g,b,a)
   a = a or 0xFF
   return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r
   --    color = b * 65536 + g * 256 + r + 0xFF000000
end

function DoWork(EditorId, l1, l2)
   for line = l1, l2 do
      local text = editor.GetString(nil, line, 3)

      -- HEX
      local pos = 1
      while true do
         -- Ищем # + 6 или 8 шестнадцатеричных символов
         local s, e, hex = text:find("#(%x%x%x%x%x%x%x?%x?)", pos)
         if not s then
            break
         end

         local len = #hex
         if len ~= 6 and len ~= 8 then
            pos = e + 1
            goto continue_loop
         end

         local r = tonumber(hex:sub(1, 2), 16)
         local g = tonumber(hex:sub(3, 4), 16)
         local b = tonumber(hex:sub(5, 6), 16)
         local a = 0xFF -- по умолчанию непрозрачный

         if len == 8 then -- #RRGGBBAA
            a = tonumber(hex:sub(7, 8), 16)
         end

         local color = make_color(r,g,b,a)

         editor.AddColor(EditorId, line, s - 1, e + 1, colorFlags, {
            Flags = 0,
            ForegroundColor = get_contrast_text_color(color),
            BackgroundColor = color,
         }, 100)
         pos = e + 1

         ::continue_loop::
      end

      -------------------------------------------------------
      -- rgb(...) / rgba(...)
      pos = 1

      while true do
         local s, e, r, g, b, a = text:find("rgba?%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*([%d%.]*)%s*%)", pos)

         if not s then
            break
         end

         r = tonumber(r)
         g = tonumber(g)
         b = tonumber(b)

         local alpha = 0xFF

         if a ~= "" then
            local af = tonumber(a)

            if af then
               if af <= 1 then
                  alpha = math.floor(af * 255)
               else
                  alpha = math.floor(af)
               end
            end
         end

         local color = make_color(r, g, b, alpha)

         editor.AddColor(EditorId, line, s, e, colorFlags, {
            Flags = 0,
            ForegroundColor = get_contrast_text_color(color),
            BackgroundColor = color,
         }, 100)

         pos = e + 1
      end
   end -- цикл по строкам
end


Event {
  description="Highlight css colors";
  group="EditorEvent";
  action=function(EditorId, Event, Param)
    if Event==F.EE_REDRAW then
      local Info = editor.GetInfo(EditorId)
      local l1 = Info.TopScreenLine
      local l2 = math.min(l1+Info.WindowSizeY-1, Info.TotalLines)
      DoWork(EditorId, l1, l2)
    end
  end
}




