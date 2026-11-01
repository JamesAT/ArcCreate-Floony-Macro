--Color.lua
--Named colors (hex) for rich text, plus named arc color ids.

---@alias Color string

---@type table<string, Color>
Colors = Colors or {}

Colors.white = '#FFFFFF'
Colors.black = '#000000'

Colors.red = '#FF0000'
Colors.green = '#00FF00'
Colors.blue = '#0000FF'
Colors.yellow = '#FFFF00'
Colors.magenta = '#FF00FF'
Colors.cyan = '#00FFFF'
Colors.orange = '#FF8000'
Colors.purple = '#7F00FF'
Colors.brown = '#996633'

Colors.gray = '#777777'
Colors.dark_gray = '#555555'
Colors.light_gray = '#AAAAAA'

Colors.dark_red = '#800000'
Colors.dark_green = '#008000'
Colors.dark_blue = '#000080'
Colors.dark_yellow = '#808000'
Colors.dark_magenta = '#800080'
Colors.dark_cyan = '#008080'
Colors.dark_orange = '#804000'
Colors.dark_purple = '#400080'
Colors.dark_brown = '#663300'

Colors.desaturated_red = '#FF8080'
Colors.desaturated_green = '#80FF80'
Colors.desaturated_blue = '#8080FF'
Colors.desaturated_yellow = '#FFFF80'
Colors.desaturated_magenta = '#FF80FF'
Colors.desaturated_cyan = '#80FFFF'
Colors.desaturated_orange = '#FFBF80'
Colors.desaturated_purple = '#BF80FF'
Colors.desaturated_brown = '#CC9966'

Colors.disable = '#FF7070'
Colors.enable = '#20AA20'

--- Pick the "on" or "off" status color.
---@param on boolean
---@return Color
function Colors.status(on)
    return on and Colors.enable or Colors.disable
end

-- Arc color ids as used by the chart (0 = blue, 1 = red, 2 = green).
ArcColors = ArcColors or { blue = 0, red = 1, green = 2 }

-- The order used by "Cycle Colors". Kept exactly as it was before.
ArcColorCycle = ArcColorCycle or { 6, 8, 3, 7, 2, 0, 5, 1 }