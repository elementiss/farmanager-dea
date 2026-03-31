-- Подсветка цветов #RRGGBB, #RRGGBBAA, rgb(), rgba() и именованных цветов в редакторе Far Manager
-- https://forum.farmanager.com/viewtopic.php?t=13910
-- author: phidel
-- started 2026-03-13
-- current 2026-03-31
-- Примеры   #111827    #57B0C8    #95adde    #E34646    #E3464666    #BED5C0
--  rgb(255,255,204), rgb(200,100,50), rgba(200,100,50,0.5)

---- Настройки
local Settings = {
  NamedColors=true;  -- раскрашивать именованные цвета
  RespectPascalAA=false; -- учитывать непрозрачность в паскале (false потому что ничего не видно)
}

local F = far.Flags
local bit = bit64 or bit
local colorFlags = F.ECF_TABMARKFIRST + F.ECF_TABMARKCURRENT + F.ECF_AUTODELETE

-- Таблица стандартных цветов CSS
local css_color_hex = {
  aliceblue="F0F8FF", antiquewhite="FAEBD7", aqua="00FFFF", aquamarine="7FFFD4", azure="F0FFFF",
  beige="F5F5DC", bisque="FFE4C4", black="000000", blanchedalmond="FFEBCD", blue="0000FF",
  blueviolet="8A2BE2", brown="A52A2A", burlywood="DEB887", cadetblue="5F9EA0", chartreuse="7FFF00",
  chocolate="D2691E", coral="FF7F50", cornflowerblue="6495ED", cornsilk="FFF8DC", crimson="DC143C",
  cyan="00FFFF", darkblue="00008B", darkcyan="008B8B", darkgoldenrod="B8860B", darkgray="A9A9A9",
  darkgreen="006400", darkgrey="A9A9A9", darkkhaki="BDB76B", darkmagenta="8B008B", darkolivegreen="556B2F",
  darkorange="FF8C00", darkorchid="9932CC", darkred="8B0000", darksalmon="E9967A", darkseagreen="8FBC8F",
  darkslateblue="483D8B", darkslategray="2F4F4F", darkslategrey = "2F4F4F", darkturquoise="00CED1",
  darkviolet="9400D3", deeppink="FF1493", deepskyblue="00BFFF", dimgray="696969", dimgrey = "696969",
  dodgerblue="1E90FF", firebrick="B22222", floralwhite="FFFAF0", forestgreen="228B22", fuchsia="FF00FF",
  gainsboro="DCDCDC", ghostwhite="F8F8FF", gold="FFD700", goldenrod="DAA520", gray="808080",
  green="008000", greenyellow="ADFF2F", grey="808080", honeydew="F0FFF0", hotpink="FF69B4",
  indianred="CD5C5C", indigo="4B0082", ivory="FFFFF0", khaki="F0E68C", lavender="E6E6FA",
  lavenderblush="FFF0F5", lawngreen="7CFC00", lemonchiffon="FFFACD", lightblue="ADD8E6",
  lightcoral="F08080", lightcyan="E0FFFF", lightgoldenrodyellow="FAFAD2", lightgray="D3D3D3",
  lightgreen="90EE90", lightgrey="D3D3D3", lightpink="FFB6C1", lightsalmon="FFA07A",
  lightseagreen="20B2AA", lightskyblue="87CEFA", lightslategray="778899", lightslategrey = "778899",
  lightsteelblue="B0C4DE", lightyellow="FFFFE0", lime="00FF00", limegreen="32CD32", linen="FAF0E6",
  magenta="FF00FF", maroon="800000", mediumaquamarine="66CDAA", mediumblue="0000CD",
  mediumorchid="BA55D3", mediumpurple="9370DB", mediumseagreen="3CB371", mediumslateblue="7B68EE",
  mediumspringgreen="00FA9A", mediumturquoise="48D1CC", mediumvioletred="C71585", midnightblue="191970",
  mintcream="F5FFFA", mistyrose="FFE4E1", moccasin="FFE4B5", navajowhite="FFDEAD", navy="000080",
  oldlace="FDF5E6", olive="808000", olivedrab="6B8E23", orange="FFA500", orangered="FF4500",
  orchid="DA70D6", palegoldenrod="EEE8AA", palegreen="98FB98", paleturquoise="AFEEEE",
  palevioletred="DB7093", papayawhip="FFEFD5", peachpuff="FFDAB9", peru="CD853F", pink="FFC0CB",
  plum="DDA0DD", powderblue="B0E0E6", purple="800080", rebeccapurple="663399", red="FF0000",
  rosybrown="BC8F8F", royalblue="4169E1", saddlebrown="8B4513", salmon="FA8072", sandybrown="F4A460",
  seagreen="2E8B57", seashell="FFF5EE", sienna="A0522D", silver="C0C0C0", skyblue="87CEEB",
  slateblue="6A5ACD", slategray="708090", slategrey = "708090", snow="FFFAFA", springgreen="00FF7F",
  steelblue="4682B4", tan="D2B48C", teal="008080", thistle="D8BFD8", tomato="FF6347",
  turquoise="40E0D0", violet="EE82EE", wheat="F5DEB3", white="FFFFFF", whitesmoke="F5F5F5",
  yellow="FFFF00", yellowgreen="9ACD32"
}

local function IsGPLFile(EditorId)
   local info = editor.GetInfo(EditorId)
   if not info then return false end
    
   local filename = info.FileName:lower()
   return filename:match("%.gpl$") ~= nil
end


-- Преобразуем HEX строки в числа 0xAARRGGBB
local css_color_map = {}
for name, hex in pairs(css_color_hex) do
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  css_color_map[name] = (0xFF * 0x1000000) + (b * 0x10000) + (g * 0x100) + r
end

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

-- Подсветка RGB-значений в файлах .gpl (GIMP Palette)
-- Раскрашивает только "r g b" в начале строки цветовой записи
local function ProcessGpl(EditorId, l1, l2)
    for line = l1, l2 do
        local str = editor.GetString(EditorId, line, 3)  -- 3 = ESTR_GETSTRING
        if not str or str == "" then goto continue_gpl end
        
        -- Ищем строки, которые начинаются с трёх целых чисел 0-255
        -- Формат: r g b [название цвета...]
        -- r, g, b могут быть разделены одним или несколькими пробелами/табами
        
        local s, e, r, g, b = str:find("^%s*(%d+)%s+(%d+)%s+(%d+)", 1)
        
        if s then
            r = tonumber(r)
            g = tonumber(g)
            b = tonumber(b)
            
            -- Проверяем, что значения в допустимом диапазоне
            if r and g and b and r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
                local color = make_color(r, g, b)
                
                -- e указывает на конец третьего числа
                editor.AddColor(EditorId, line, s, e, colorFlags, {
                    Flags = 0,
                    ForegroundColor = get_contrast_text_color(color),
                    BackgroundColor = color,
                }, 100)
            end
        end
        
        ::continue_gpl::
    end
end

function DoWork(EditorId, l1, l2)
   for line = l1, l2 do
      local text = editor.GetString(EditorId, line, 3)
      if not text then goto continue_line end

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

      -- pascal  $BBGGRR
      pos = 1
      while true do
         -- Ищем $ + 6 или 8 шестнадцатеричных символов
         local s, e, hex = text:find("$(%x%x%x%x%x%x%x?%x?)", pos)
         if not s then
            break
         end

         local len = #hex
         if len ~= 6 and len ~= 8 then
            pos = e + 1
            goto continue_loop2
         end

         local b, g, r
         local a = 0xFF -- по умолчанию непрозрачный
         
         if len == 8 then -- $FFBBGGRR
           if Settings.RespectPascalAA then
              a = tonumber(hex:sub(1, 2), 16)
           end
           b = tonumber(hex:sub(3, 4), 16)
           g = tonumber(hex:sub(5, 6), 16)
           r = tonumber(hex:sub(7, 8), 16)
         else
           b = tonumber(hex:sub(1, 2), 16)
           g = tonumber(hex:sub(3, 4), 16)
           r = tonumber(hex:sub(5, 6), 16)
         end

         local color = make_color(r,g,b,a)

         editor.AddColor(EditorId, line, s - 1, e + 1, colorFlags, {
            Flags = 0,
            ForegroundColor = get_contrast_text_color(color),
            BackgroundColor = color,
         }, 100)
         pos = e + 1

         ::continue_loop2::
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

      -------------------------------------------------------
      -- Именованные цвета (green, red, navy...)
      if not Settings.NamedColors then goto continue_line end

      pos = 1
      while true do
        -- Ищем слова
--         local s, e, word = text:find("%f[%w](%a+)%f[%W]", pos)
         local s, e, word = text:find("%f[%a%d_-](%a+)%f[^%a%d_-]", pos)
        if not s then
          break
        end

        local lowerWord = word:lower()
        local color = css_color_map[lowerWord]

        if color then
          editor.AddColor(EditorId, line, s, e, colorFlags, {
            Flags = 0,
            ForegroundColor = get_contrast_text_color(color),
            BackgroundColor = color,
          }, 100)
        end

        pos = e + 1
      end

      ::continue_line::
   end -- цикл по строкам
end


Event {
  description="Highlight css/gpl colors";
  group="EditorEvent";
  action=function(EditorId, Event, Param)
    if Event==F.EE_REDRAW then
      local Info = editor.GetInfo(EditorId)
      if Info then
        local l1 = Info.TopScreenLine
        local l2 = math.min(l1 + Info.WindowSizeY - 1, Info.TotalLines)

        if IsGPLFile(EditorId) then
           ProcessGpl(EditorId, l1, l2)
        else
           DoWork(EditorId, l1, l2)
        end
      end
    end
  end
}

