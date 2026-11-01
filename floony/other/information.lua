require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // INFORMATION // --             |
------------------------------------/
-- Macros that only SHOW things:
--   Chart Information      note and event counts
--   Density / Progress     how full the chart is, and how many notes per second
--   Progress Length        how much of the song is charted (from the start, or a section)
--   Generate Post Format   a ready-to-paste forum post
--   Chart Category Check   tells you if the chart is Standard, Special or NotARCAEA (Perfect for ACC - ArcCreate Charting Contest)

-- Every macro in this file is kept out of "Repeat Last Macro" and "Pin Last Macro",
local function infoMacro(parent, id, name, icon, func)
    MacroNewNOCMD(parent, id, name, icon, func, true)
end

--------------------------------------------------------------------------------
-- SMALL HELPERS
--------------------------------------------------------------------------------

-- Turns milliseconds into m:ss, for example 83000 becomes 1:23.
function formatTime(milliseconds)
    local totalSeconds = math.floor(math.max(0, milliseconds) / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format('%d:%02d', minutes, seconds)
end

-- Remembers which timing groups are 'noInput' (fake notes). Looking a group up for every single
-- note would be very slow on a big chart, so each group is only looked up once.
local function makeNoInputCheck()
    local cache = {}
    return function(tg)
        local known = cache[tg]
        if known == nil then
            known = (Event.getTimingGroup(tg).noInput == true)
            cache[tg] = known
        end
        return known
    end
end

--------------------------------------------------------------------------------
-- CHART INFORMATION
--------------------------------------------------------------------------------

-- How many playable notes placed in 'noInput' timing groups (fake notes).
local function countFakeNotes()
    local total = 0
    for i = 1, Context.timingGroupCount - 1 do
        local group = Event.getTimingGroup(i)
        if group.noInput == true then
            local found = Event.query(
                EventSelectionConstraint.create().ofTimingGroup(group.num).judgeable()
            ).result
            for _, list in pairs(found) do
                total = total + #list
            end
        end
    end
    return total
end

infoMacro('floony', 'chartinfo', 'Chart Information', 'e97a',
    function()
        local all = Event.query(EventSelectionConstraint.create().any())

        -- Count every kind of event. Arcs are split into solid arcs and traces.
        local count = { arc = 0, trace = 0, hold = 0, tap = 0, arctap = 0,
                        timing = 0, camera = 0, scenecontrol = 0 }

        for kind, list in pairs(all.result) do
            if kind == 'arc' then
                for _, note in ipairs(list) do
                    if note.is('solidArc') then
                        count.arc = count.arc + 1
                    elseif note.is('voidArc') then
                        count.trace = count.trace + 1
                    end
                end
            else
                count[kind] = #list
            end
        end

        local groups = Context.timingGroupCount - 1   -- the base group is not counted
        local fake = countFakeNotes()

        local totalNotes = count.arc + count.trace + count.hold + count.tap + count.arctap
        local totalEvents = count.timing + count.camera + count.scenecontrol + groups

        local lines = {
            'Chart info displayed (Hover to view statistics)',
            '',
            '[]--Stats---------------------------------------------[]',
            'Song Length: ' .. formatTime(Context.songLength) .. ' | Current Combo: ' .. Context.maxCombo,
            '',
            '[]--Elements---------------------------------------------[]',
            'Tap: ' .. count.tap .. ' | Hold: ' .. count.hold .. ' | SkyTap: ' .. count.arctap ..
                ' | Arc: ' .. count.arc .. ' | Trace: ' .. count.trace,
        }

        if fake > 0 then
            lines[#lines + 1] = '<color=#FF5733>Fake Notes: </color>' .. fake
        end

        lines[#lines + 1] = '<color=#FFD73B>Total Notes: </color>' .. totalNotes
        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Timing: ' .. count.timing ..
            ' | Timing Group: ' .. (groups == 0 and '0 (Base)' or groups) ..
            ' | Scenecontrol: ' .. count.scenecontrol .. ' | Camera: ' .. count.camera
        lines[#lines + 1] = '<color=#FFD73B>Total Event: </color>' .. totalEvents
        lines[#lines + 1] = ''
        lines[#lines + 1] = '[]--Summaries---------------------------------------------[]'
        lines[#lines + 1] = '<color=#C3FF3E>Total Notes + Total Event: </color>' .. (totalNotes + totalEvents)
        lines[#lines + 1] = ''

        notify(table.concat(lines, '\n'))
    end
)

--------------------------------------------------------------------------------
-- DENSITY / PROGRESS
-- Draws heatmap-like 2D vertical histogram bar (▂ ▃ ▄ ▅ ▆ ▇ █) along the song.
--   Events bar : timing, camera and scenecontrol events
--   Notes bar  : playable notes (arcs and holds count once for every combo tick)
--------------------------------------------------------------------------------

local HEIGHT_BLOCKS = { '▂', '▃', '▄', '▅', '▆', '▇', '█' }

-- Theme Gradient Palettes
local THEMES = {
    emerald = {
        name  = 'Emerald (Green-Yellow-Red)',
        empty = '#373737',
        low   = '#139A43',
        mid   = '#F2E863',
        high  = '#EB5757',
    },
    arccreate = {
        name  = 'ArcCreate (Cyan-Magenta)',
        empty = '#2E3540',
        low   = '#40D3FB',
        mid   = '#A0AEFE',
        high  = '#FF8AFE',
    },
    arcaoid = {
        name  = 'Arcaoid (Purple-Amber)',
        empty = '#33273A',
        low   = '#6615B9',
        mid   = '#873672',
        high  = '#A8572B',
    },
    cyan = {
        name  = 'Cyber Cyan (Ice Gradient)',
        empty = '#2D373C',
        low   = '#2896C8',
        mid   = '#50DCF0',
        high  = '#DCFFFF',
    },
    gold = {
        name  = 'Solar Gold (Amber Gradient)',
        empty = '#3C372D',
        low   = '#B47828',
        mid   = '#F0B432',
        high  = '#FFF096',
    },
    violet = {
        name  = 'Eternal Violet (Purple-Pink)',
        empty = '#372D3C',
        low   = '#6E3CB4',
        mid   = '#B45ADC',
        high  = '#F0A0FF',
    },
    crimson = {
        name  = 'Beyond Crimson (Red Gradient)',
        empty = '#3A2828',
        low   = '#801C20',
        mid   = '#D03030',
        high  = '#FF7070',
    },
    mono = {
        name  = 'Monochrome (Slate)',
        empty = '#303030',
        low   = '#707070',
        mid   = '#B0B0B0',
        high  = '#FFFFFF',
    },
}

local THEME_KEYS = { 'emerald', 'arccreate', 'arcaoid', 'cyan', 'gold', 'violet', 'crimson', 'mono' }

if registerSettings then
    registerSettings('Density / Progress',
        { progressTheme = 'emerald' },
        function(S)
            local key = S.progressTheme
            local themeName = THEMES[key] and THEMES[key].name or tostring(key)
            return {
                'Color Theme: ' .. string.richcolor(themeName, Colors.enable or '#40D3FB'),
            }
        end)
end

local BAR_SLOTS = 41   -- how many blocks the bar has

-- Safe clamp helper using standard Lua math functions
local function clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, val))
end

-- Parses hex string "#RRGGBB" or "RRGGBB" into { r, g, b }
local function hexToRgb(hex)
    hex = tostring(hex):gsub('#', '')
    if #hex < 6 then return { 0, 0, 0 } end
    return {
        tonumber(hex:sub(1, 2), 16) or 0,
        tonumber(hex:sub(3, 4), 16) or 0,
        tonumber(hex:sub(5, 6), 16) or 0,
    }
end

-- Linearly interpolates between two RGB color tables
local function lerpColor(c1, c2, t)
    return {
        math.floor(c1[1] + (c2[1] - c1[1]) * t + 0.5),
        math.floor(c1[2] + (c2[2] - c1[2]) * t + 0.5),
        math.floor(c1[3] + (c2[3] - c1[3]) * t + 0.5),
    }
end

-- Multi-stop gradient color lookup (empty -> low -> mid -> high)
local function getGradientColor(theme, amount)
    if amount <= 0 then
        return hexToRgb(theme.empty)
    end

    local low  = hexToRgb(theme.low)
    local mid  = hexToRgb(theme.mid)
    local high = hexToRgb(theme.high)

    if amount <= 0.5 then
        return lerpColor(low, mid, amount / 0.5)
    else
        return lerpColor(mid, high, (amount - 0.5) / 0.5)
    end
end

-- Splits the song into `count` equal slots and counts the events in each slot.
local function allocate(events, count, length, counter)
    if length <= 0 then return nil, 0 end

    local slots = {}
    for i = 1, count do slots[i] = 0 end

    local slotLength = length / count
    local busiest = 0

    for _, event in ipairs(events.resultCombined) do
        counter(event, function(timing)
            local index = math.floor(timing / slotLength) + 1
            if index > 0 and index <= count then
                slots[index] = slots[index] + 1
                if slots[index] > busiest then busiest = slots[index] end
            end
        end)
    end

    if busiest == 0 then return nil, 0 end

    for i = 1, count do slots[i] = slots[i] / busiest end
    return slots, busiest
end

-- Turns scaled slot values into a 2D height histogram with gradient colors
local function barToText(slots, themeKey)
    local theme = THEMES[themeKey] or THEMES.emerald
    local blocks = {}

    for i, amount in ipairs(slots) do
        local col = getGradientColor(theme, amount)
        local char
        if amount <= 0 then
            char = HEIGHT_BLOCKS[1]
        else
            local idx = clamp(math.floor(amount * (#HEIGHT_BLOCKS - 1)) + 2, 2, #HEIGHT_BLOCKS)
            char = HEIGHT_BLOCKS[idx]
        end
        blocks[i] = string.format('<color=#%02X%02X%02X>%s</color>', col[1], col[2], col[3], char)
    end

    return '[' .. table.concat(blocks, '') .. ']'
end

-- Turns a dropdown menu choice into its index
local function choiceIndex(value, options)
    local numVal = tonumber(value)
    if numVal ~= nil then
        local i = numVal + 1
        if i > #options then i = numVal end
        return math.max(1, math.min(i, #options))
    end
    for i, o in ipairs(options) do
        if o == value then return i end
    end
    return 1
end

-- The time labels shown above a bar (0:00, 25%, 50%, 75%, end).
local function timelineText(lengthMs)
    local gap = string.rep(' ', 36)
    return string.format('%s%s<size=70%%>|%s|%s|%s|%s|%s|</size>%s%s',
        '0:00', gap,
        formatTime(lengthMs * 0.25), gap,
        formatTime(lengthMs * 0.50), gap,
        formatTime(lengthMs * 0.75), gap,
        formatTime(lengthMs))
end

-- The headline: how complete the chart looks, from the share of filled slots.
local function progressText(percentage)
    local note = "<size=70%%>(Don't forget to polish the chart)</size>"

    if percentage >= 100 then
        return string.format('<color=#4CFC6B><b>%d%% <size=90%%>- Completed!</b></size></color> ' .. note, percentage)
    elseif percentage >= 97 then
        return string.format('<color=#2AA13C><b>%d%% <size=90%%>- Technically Completed</b></size></color> ' .. note, percentage)
    elseif percentage >= 90 then
        return string.format('<color=#F4D35E><b>%d%% <size=90%%>- Almost Finished</b></size></color> <size=70%%>(Or it is finished?)</size>', percentage)
    elseif percentage >= 75 then
        return string.format('<b>%d%% <size=90%%>- It would be a shame if this ended up in WIP hell.</size></b>', percentage)
    elseif percentage >= 50 then
        return string.format('<b>%d%% <size=90%%>- Halfway there!</size></b>', percentage)
    end
    return string.format('<b>%d%%</b>', percentage)
end

infoMacro('floony', 'floony.progress', 'Density / Progress', 'e9e6',
    function()
        local all = Event.query(EventSelectionConstraint.create().any())
        local length = Context.songLength
        local isNoInput = makeNoInputCheck()

        -- Read active theme directly from FloonySettings
        local storeTheme = FloonyStore and FloonyStore.getString and FloonyStore.getString('floony.progress.theme', '')
        local currentThemeKey = (storeTheme ~= '' and storeTheme) or (FloonySettings and FloonySettings.progressTheme) or 'emerald'
        
        -- Playable notes (fake notes in 'noInput' groups and traces do not count).
        local totalNotes = 0
        for _, e in ipairs(all.resultCombined) do
            if not isNoInput(e.timingGroup) then
                if e.is('tap') or e.is('arctap') or e.is('hold') or (e.is('arc') and not e.isVoid) then
                    totalNotes = totalNotes + 1
                end
            end
        end

        -- Events bar
        local eventBar = allocate(all, BAR_SLOTS, length, function(e, add)
            if e.is('timing') or e.is('camera') or e.is('scenecontrol') then
                add(e.timing)
            end
        end)

        -- Notes bar
        local noteBar, busiest = allocate(all, BAR_SLOTS, length, function(e, add)
            if isNoInput(e.timingGroup) then return end

            if e.is('tap') or e.is('arctap') then
                add(e.timing)
            elseif e.is('hold') or (e.is('arc') and not e.isVoid) then
                local bpm = math.abs(Context.bpmAt(e.timing, e.timingGroup))
                local duration = e.endTiming - e.timing
                if bpm ~= 0 and duration > 0 then
                    local base = (bpm >= 255) and 60000 or 30000
                    local tickGap = base / bpm / Context.timingPointDensityFactor
                    local ticks = math.floor(duration / tickGap)

                    if ticks <= 1 then
                        add(e.timing + duration / 2)
                    else
                        for i = 0, ticks - 1 do add(e.timing + tickGap * i) end
                    end
                end
            end
        end)

        local filled = 0
        if noteBar then
            for i = 1, #noteBar do
                if noteBar[i] > 0 then filled = filled + 1 end
            end
        end
        local percentage = math.floor((filled / BAR_SLOTS) * 100)

        local slotSeconds = (length / BAR_SLOTS) / 1000
        local peakNps = (noteBar and slotSeconds > 0) and string.format('%.2f', busiest / slotSeconds) or '0.00'
        local avgNps = (length > 0) and string.format('%.2f', totalNotes / (length / 1000)) or '0.00'

        local timeline = timelineText(length)
        local empty = '<color=#F25F5C>[Chart the song first, then come back]</color>'

        local themeOptions = {}
        for _, k in ipairs(THEME_KEYS) do
            if THEMES[k] then
                themeOptions[#themeOptions + 1] = THEMES[k].name
            end
        end

        local activeThemeName = THEMES[currentThemeKey].name

        local themeOptions = { THEMES[currentThemeKey].name }
        local orderedKeys  = { currentThemeKey }

        for _, k in ipairs(THEME_KEYS) do
            if k ~= currentThemeKey and THEMES[k] then
                themeOptions[#themeOptions + 1] = THEMES[k].name
                orderedKeys[#orderedKeys + 1]   = k
            end
        end
        
        local r = Request.dialogRaw('Chart Progress & Density',
            DialogField.create('Prog')
                .description(string.format('<size=115%%>Chart Progress: %s</size>', progressText(percentage))),

            DialogField.create('Density')
                .description('<b>- Events Density:</b> <size=70%>(Timing / Camera / Scenecontrol)</size>'),
            DialogField.create('AllocE')
                .description('<color=#888888>' .. timeline .. '</color>\n' .. (eventBar and barToText(eventBar, currentThemeKey) or empty)),

            DialogField.create('Notes')
                .description('<b>- Notes Density:</b> <size=70%>(Playable Notes)</size>'),
            DialogField.create('AllocC')
                .description('<color=#888888>' .. timeline .. '</color>\n' .. (noteBar and barToText(noteBar, currentThemeKey) or empty)),

            DialogField.create('Stats')
                .description(string.format(
                    '\n<size=70%%>NPS (Notes per Second) Stats</size>\nPeak NPS: <b>%s</b>\nAverage NPS: <b>%s</b>',
                    peakNps, avgNps)),

            DialogField.create('theme')
                .setLabel('Color Theme')
                .setTooltip('Select gradient color palette for density bars.')
                -- .defaultTo(themeOptions[1])
                .dropdownMenu(table.unpack(themeOptions))
        )
        if not r then return end

        local choice = choiceIndex(r['theme'], themeOptions)
        local selectedKey = orderedKeys[choice]
        if selectedKey and THEMES[selectedKey] then
            if FloonySettings then FloonySettings.progressTheme = selectedKey end
            if FloonyStore and FloonyStore.setString then FloonyStore.setString('floony.progress.theme', selectedKey) end
            if saveSettings then saveSettings() end
        end
    end
)

--------------------------------------------------------------------------------
-- PROGRESS LENGTH
-- How much of the song is charted.
--------------------------------------------------------------------------------
local PROGRESS = 'floony.proglength'
FolderNew('floony', PROGRESS, 'e41c', '[Progress Length]')

-- Shows how far the notes between tStart and tEnd reach into the song.
local function showProgress(tStart, tEnd)
    local songLength = Context.songLength
    if not tEnd or tEnd <= tStart or songLength <= 0 then
        dialogNotify('Invalid time range! Ensure endTiming greater than the startTiming.')
        return
    end

    local notes = table.icollapse(
        Event.query(CustomConstraints.timeRange(tStart, tEnd)),
        'arc', 'tap', 'hold', 'arctap')

    -- The furthest point any note reaches (long notes count until their end).
    local furthest = 0
    for _, note in ipairs(notes) do
        local reach = note.is('long') and note.endTiming or note.timing
        furthest = math.max(furthest, reach)
    end

    local percentage = math.min(100, (furthest / songLength) * 100)

    -- Past 97% the progress turns green.
    local progress = string.format('Progress: %.2f%%', percentage)
    if percentage >= 97 then
        progress = '<color=#53DD6C>' .. progress .. '</color>'
    end

    dialogNotify(string.format('Charted Length: %s of %s | %s\n<size=85%%>Selected Duration: %s</size>',
        formatTime(furthest), formatTime(songLength), progress, formatTime(tEnd - tStart)))
end

-- From Beginning: pick the last charted time, and the range is 0 to that time.
infoMacro(PROGRESS, 'beginning', 'From Beginning', 'e089',
    function()
        local tEnd = Request.time('Please select the last charted timing')
        showProgress(0, tEnd)
    end
)

-- Segment: how much of the song a time range covers.
infoMacro(PROGRESS, 'segment', 'Segment', 'e94b',
    function()
        local tStart, tEnd = Request.timeRange()
        local songLength = Context.songLength

        if not tStart or tStart < 0 or not tEnd or tEnd <= tStart or songLength <= 0 then
            dialogNotify('Invalid time range! Ensure endTiming greater than the startTiming.')
            return
        end

        local duration = tEnd - tStart
        dialogNotify(string.format('Duration: %s to %s (%s of %s) | Covers: %.2f%% of Song',
            formatTime(tStart), formatTime(tEnd), formatTime(duration), formatTime(songLength),
            (duration / songLength) * 100))
    end
)

--------------------------------------------------------------------------------
-- GENERATE POST FORMAT
-- Fills in a forum post with the song info and your answers, then copies it to the clipboard.
--------------------------------------------------------------------------------

-- Empty answers become 'N/A'.
local function orNA(value)
    if value == nil or value == '' then return 'N/A' end
    return tostring(value)
end

infoMacro('floony', 'genforum', 'Generate Post Format', 'e0bf',
    function()
        local r = Request.dialogRaw('Chart Post Format Addition',
            DialogField.create('illustrator')
                .setLabel('Illustrator')
                .setTooltip('Enter the illustrator name (leave blank for N/A)')
                .textField(FieldConstraint.create().any()),
            DialogField.create('chartConstantFuture')
                .setLabel('Chart Constant (FTR)')
                .setTooltip('Enter the chart constant for Future difficulty (leave blank for N/A)')
                .textField(FieldConstraint.create().any()),
            DialogField.create('chartViewFuture')
                .setLabel('Chart View (FTR)')
                .setTooltip('Enter the URL for Future difficulty (leave blank for N/A)')
                .textField(FieldConstraint.create().any()),
            DialogField.create('chartDescription')
                .setLabel('Chart Description')
                .setTooltip('Enter a chart description (leave blank for N/A)')
                .textField(FieldConstraint.create().any())
        )

        if not r then
            notify('Operation canceled.')
            return
        end

        local post = table.concat({
            'Song: ' .. orNA(Context.title),
            'Composer: ' .. orNA(Context.composer),
            'Illustrator: ' .. orNA(r['illustrator']),
            '',
            'Difficulty: Future ?',
            'Charter: ' .. orNA(Context.charter),
            'Alias: ' .. orNA(Context.alias),
            'Chart Constant: ' .. orNA(r['chartConstantFuture']),
            'Chart View: ' .. orNA(r['chartViewFuture']),
            '',
            'Chart Description:',
            orNA(r['chartDescription']),
        }, '\n')

        Context.systemClipboard = post
        notify('Chart Post Format generated and copied to the clipboard!')
    end
)

--------------------------------------------------------------------------------
-- CHART CATEGORY CHECK (For ACC Purposes)
-- Reads the whole chart and tells you which category it fits:
--   STANDARD       The vanilla experience, ranging from the standard and familiar styles featured in Future and Eternal charts, or the freeform and experimental nature of Beyond charts.
--   SPECIAL        Middle ground between the Standard & NotARCAEA
--   NotARCAEA      Specifically made for charters who want to show off the things that the fanmade charting community is capable of
-- It lists what is wrong, and can select the problem notes for you so you can fix them.
-- (The line counting is taken from linecount.lua.)
--------------------------------------------------------------------------------

-- THE RULES. Change these if the rules change.
local RULES = {
    bounds = { xMin = -0.5, xMax = 1.5, yMin = 0, yMax = 1.5 },         -- Normal Boundaries
    specialBounds = { xMin = -1.0, xMax = 2.0, yMin = 0, yMax = 1.61 }, -- Special Boundaries (6K)

    standardLinesPerMinute = 1000,   -- Standard files are limited in size
    defaultArcTapWidth = 1,          -- the normal width of an ArcTap

    -- Scenecontrol types that are allowed.
    standardScenecontrol = { hidegroup = true },
    specialScenecontrol = {
        hidegroup = true, enwidenlanes = true, enwidencamera = true,
        trackdisplay = true, groupalpha = true,
    },
}

local MAX_SHOWN = 8   -- most problems listed per category (the rest is summarized)

-- Timing group properties. Standard only allows 'noinput' and 'arcresolution', so a group that
-- changes any of these from the normal value is a problem for Standard.
local GROUP_PROPERTIES = {
    'noClip', 'noHeightIndicator', 'noShadow', 'noHead', 'noArcCap', 'noConnection',
    'fadingHolds', 'sloppyJudgement', 'earlyJudgement', 'ignoreMirror', 'autoplay',
    'dropRate', 'angleX', 'angleY',
    'judgementSizeX', 'judgementSizeY',
    'judgementOffsetX', 'judgementOffsetY', 'judgementOffsetZ',
    'side', 'file',
}

-- Arc colors: 0 = blue, 1 = red, 2 = green, 3 = yellow (the default colors).
-- Anything higher is a custom color. Standard only allows blue and red.
local ARC_COLOR_PROBLEMS = {
    [2] = { 'arc_green',  'Green arcs' },
    [3] = { 'arc_yellow', 'Yellow arcs' },
}
local CUSTOM_ARC_COLOR = { 'arc_custom', 'Custom-colored arcs (color 4 or higher)' }

-- Standard allowed difficulties and hex colors
local STANDARD_DIFFICULTIES = {
    { name = 'Future',  color = '482B54' },
    { name = 'Beyond',  color = '7C1C30' },
    { name = 'Eternal', color = '433455' },
}

local OTHER_DIFFICULTIES = {
    { name = 'Past',    color = '3A6B78' },
    { name = 'Present', color = '566947' },
}

-- Turns a dropdown answer into its position in `options` (1 = first).
local function choiceIndex(value, options)
    if type(value) == 'number' then
        local i = value + 1
        if i > #options then i = value end
        return math.max(1, math.min(i, #options))
    end
    for i, o in ipairs(options) do
        if o == value then return i end
    end
    return 1
end

-- A list of problems. The same kind of problem is counted together ('12 arcs outside...').
local function newProblemList()
    local list, byKey = {}, {}
    return {
        list = list,
        add = function(key, text, event)
            local problem = byKey[key]
            if not problem then
                problem = { text = text, count = 0, events = {} }
                byKey[key] = problem
                list[#list + 1] = problem
            end
            problem.count = problem.count + 1
            if event then problem.events[#problem.events + 1] = event end
        end,
    }
end

-- True when an arc is inside the screen boundary.
local function insideBounds(x, y, bounds)
    local b = bounds or RULES.bounds
    local margin = 0.0001   -- tiny allowance for rounding
    return x >= b.xMin - margin and x <= b.xMax + margin
       and y >= b.yMin - margin and y <= b.yMax + margin
end

-- A sfx is 'custom' when it is not empty and not 'none'.
local function hasCustomSfx(sfx)
    return sfx ~= nil and sfx ~= '' and string.lower(tostring(sfx)) ~= 'none'
end

-- True when two property values are the same (empty, false and nil all count as 'not set').
local function sameValue(a, b)
    if a == b then return true end
    if type(a) == 'number' and type(b) == 'number' then return math.abs(a - b) < 0.000001 end
    local function blank(v) return v == nil or v == false or v == '' end
    return blank(a) and blank(b)
end

-- The names of the timing group properties that are not normal (Standard does not allow them).
-- `normal` is a fresh, untouched timing group, used to know what 'normal' is.
local function abnormalProperties(group, normal)
    local found = {}

    for _, property in ipairs(GROUP_PROPERTIES) do
        -- Without a fresh group to compare to, only on/off properties can be checked.
        local comparable = normal or type(group[property]) == 'boolean'
        if comparable then
            local expected = normal and normal[property] or nil
            if not sameValue(group[property], expected) then
                found[#found + 1] = property
            end
        end
    end

    if group.judgementMaps and next(group.judgementMaps) ~= nil then
        found[#found + 1] = 'judgementMaps'
    end

    return found
end

-- The number of lines the .aff file would have (taken from linecount.lua, thanks beane):
-- 2 header lines, 2 lines per timing group, and one line per event (ArcTaps are inside their arc's line).
local function countAffLines()
    local withoutArcTaps = EventSelectionConstraint.create().custom(function(event)
        return not event.is('arctap')
    end)

    local headerLines = 2
    local groupLines = (Context.timingGroupCount - 1) * 2
    local eventLines = #Event.query(withoutArcTaps.any()).resultCombined

    return headerLines + groupLines + eventLines
end

-- Goes through the whole chart. Returns two problem lists: one for Standard, one for Special.
-- A problem that breaks both categories is added to both.
local function checkChart()
    local standard, special = newProblemList(), newProblemList()
    local function both(key, text, event)
        standard.add(key, text, event)
        special.add(key, text, event)
    end

    local all = Event.query(EventSelectionConstraint.create().any()).result
    local isNoInput = makeNoInputCheck()

    -- Special boundary exemption check: exempts notes in noinput OR autoplay groups
    local function isSpecialBypass(groupIndex)
        if isNoInput(groupIndex) then return true end
        if groupIndex and groupIndex > 0 then
            local group = Event.getTimingGroup(groupIndex)
            if group and group.autoplay == true then return true end
        end
        return false
    end

    -- TAPS AND HOLDS: Standard (lanes 1-4), Special (lanes 0-5 for 6K).
    local function checkLane(note, name)
        local lane = note.lane
        local decimal = (name == 'Tap') and note.isDecimal
        local isInteger = lane ~= nil and lane == math.floor(lane) and not decimal

        local validStandard = isInteger and lane >= 1 and lane <= 4
        local validSpecial  = isInteger and lane >= 0 and lane <= 5

        if not validStandard then
            standard.add('lane' .. name, name .. 's outside lanes 1-4', note)
        end
        if not validSpecial then
            if not isSpecialBypass(note.timingGroup) then
                special.add('lane' .. name, name .. 's outside 6K lanes 0-5 (not in a noinput/autoplay group)', note)
            end
        end
    end

    for _, tap in ipairs(all.tap or {}) do checkLane(tap, 'Tap') end
    for _, hold in ipairs(all.hold or {}) do checkLane(hold, 'Hold') end
    
    -- ARCS AND TRACES
    for _, arc in ipairs(all.arc or {}) do
        local fake = isSpecialBypass(arc.timingGroup)

        if not arc.isVoid then
            -- Color: Standard only allows blue (0) and red (1).
            if arc.color ~= 0 and arc.color ~= 1 then
                local problem = ARC_COLOR_PROBLEMS[arc.color] or CUSTOM_ARC_COLOR
                standard.add(problem[1], problem[2], arc)
            end

            -- Boundary Checks
            local startStdOut = not insideBounds(arc.startX, arc.startY, RULES.bounds)
            local endStdOut   = not insideBounds(arc.endX, arc.endY, RULES.bounds)

            if startStdOut or endStdOut then
                standard.add('arcbounds', 'Arcs starting or ending outside Standard boundary (-0.5 to 1.5)', arc)
            end

            if not fake then
                local startSpcOut = not insideBounds(arc.startX, arc.startY, RULES.specialBounds)
                local endSpcOut   = not insideBounds(arc.endX, arc.endY, RULES.specialBounds)
                if startSpcOut or endSpcOut then
                    special.add('arcbounds', 'Arcs outside Special boundary (-1 to 2, y: 0 to 1.61) (not in a noinput/autoplay group)', arc)
                end
            end
        end

        if hasCustomSfx(arc.sfx) then
            standard.add('sfx', 'Arcs or traces with a custom sfx', arc)
        end
    end

    -- ARCTAPS
    for _, arctap in ipairs(all.arctap or {}) do
        local arc = arctap.arc
        if arc then
            local pos
            -- 0ms parent arcs produce NaN with positionAt; fall back directly to the arc's coordinates
            if arc.timing == arc.endTiming then
                pos = { x = arc.startX, y = arc.startY }
            else
                pos = arc.positionAt(arctap.timing, true)
            end

            -- Safety check for NaN or nil values
            if not pos or pos.x ~= pos.x or pos.y ~= pos.y then
                pos = { x = arc.startX, y = arc.startY }
            end

            if not insideBounds(pos.x, pos.y, RULES.bounds) then
                standard.add('taps_out', 'ArcTaps outside Standard boundary', arctap)
            end
            if not isSpecialBypass(arctap.timingGroup) and not insideBounds(pos.x, pos.y, RULES.specialBounds) then
                special.add('taps_out', 'ArcTaps outside Special boundary (-1 to 2, y: 0 to 1.61) (not in a noinput/autoplay group)', arctap)
            end
        end

        if arctap.width and math.abs(arctap.width - RULES.defaultArcTapWidth) > 0.001 then
            standard.add('taps_width', 'ArcTaps with a custom width', arctap)
        end
    end

    -- CAMERA: not allowed in either category.
    for _, camera in ipairs(all.camera or {}) do
        both('camera', 'Camera events (NotARCAEA only)', camera)
    end

    -- SCENECONTROL: only some types are allowed.
    for _, sc in ipairs(all.scenecontrol or {}) do
        local kind = string.lower(tostring(sc.type))
        if not RULES.specialScenecontrol[kind] then
            both('sc_' .. kind, 'Scenecontrol "' .. kind .. '" (NotARCAEA only)', sc)
        elseif not RULES.standardScenecontrol[kind] then
            standard.add('sc_' .. kind, 'Scenecontrol "' .. kind .. '" (only allowed in Special)', sc)
        end
    end

    -- TIMING GROUPS: Standard only allows 'noinput' and 'arcresolution'.
    local okFresh, fresh = pcall(Event.createTimingGroup, '')
    local normal = okFresh and fresh or nil

    for i = 1, Context.timingGroupCount - 1 do
        local group = Event.getTimingGroup(i)
        local abnormal = abnormalProperties(group, normal)
        if #abnormal > 0 then
            local name = (group.name and group.name ~= '') and (' (' .. group.name .. ')') or ''
            standard.add('group' .. i,
                string.format('Timing group %d%s uses properties not allowed in Standard: %s',
                    i, name, table.concat(abnormal, ', ')))
        end
    end

    -- FILE SIZE: Standard is limited in lines per minute.
    local lines = countAffLines()
    local limit = 0
    if Context.songLength > 0 then
        limit = math.floor(Context.songLength / 60000 * RULES.standardLinesPerMinute)
        if lines > limit then
            standard.add('lines', string.format('The file is over the line limit (%d lines, limit is %d)', lines, limit))
        end
    end

    return standard, special, { lines = lines, limit = limit }
end

-- The text of one category in the dialog: its problems, or 'no problems'.
local function problemsText(problems)
    if #problems.list == 0 then
        return string.richcolor('No problems found.', Colors.enable)
    end

    local lines = {}
    for i, problem in ipairs(problems.list) do
        if i > MAX_SHOWN then
            lines[#lines + 1] = string.format('...and %d more kind(s) of problem', #problems.list - MAX_SHOWN)
            break
        end
        local count = (problem.count > 1) and (' (x' .. problem.count .. ')') or ''
        lines[#lines + 1] = '- ' .. problem.text .. count
    end
    return table.concat(lines, '\n')
end

-- Reads the chart's difficulty and says if it is one of the three Standard difficulties.
local function checkDifficulty()
    local name = string.trim(tostring(Context.difficulty or ''))
    local colorText = tostring(Context.difficultyColor or '')

    local color = colorText:match('#?(%x%x%x%x%x%x)')
    local r, g, b = colorText:match('RGBA%(([%d%.]+), ([%d%.]+), ([%d%.]+)')
    if r then
        color = string.format('%02X%02X%02X',
            math.floor(tonumber(r) * 255 + 0.5), math.floor(tonumber(g) * 255 + 0.5), math.floor(tonumber(b) * 255 + 0.5))
    end
    color = color and string.upper(color) or ''

    local normName = name:lower()
    local byName, byColor
    local isStandardName, isStandardColor = false, false

    -- Check Standard difficulties (Future / Beyond / Eternal)
    for _, difficulty in ipairs(STANDARD_DIFFICULTIES) do
        if normName:find(difficulty.name:lower()) then
            byName = difficulty.name
            isStandardName = true
        end
        if color == difficulty.color then
            byColor = difficulty.name
            isStandardColor = true
        end
    end

    if not byName or not byColor then
        for _, difficulty in ipairs(OTHER_DIFFICULTIES) do
            if not byName and normName:find(difficulty.name:lower()) then
                byName = difficulty.name
            end
            if not byColor and color == difficulty.color then
                byColor = difficulty.name
            end
        end
    end

    local official = (isStandardName and isStandardColor and byName == byColor) and byName or nil

    return {
        name = (name ~= '') and name or 'unknown',
        color = color,
        official = official,
        byName = byName,
        byColor = byColor,
        isStandardName = isStandardName,
        isStandardColor = isStandardColor,
    }
end

local SELECT_OPTIONS = { 'Do not select anything', 'Select the Standard problems', 'Select the Special problems' }

-- Colors every letter with the next color of the rainbow (red -> orange -> yellow -> green -> blue -> purple).
local RAINBOW_PASTEL = 0.5   -- how much white is mixed in: 0 = strong colors, 1 = pure white
local function rainbowText(text)
    local letters = {}
    local count = #text

    for i = 1, count do
        local position = (i - 1) / count * 6        -- where we are on the color wheel (0 to 6)
        local step = math.floor(position)           -- which of the 6 color stretches
        local fraction = position - step            -- how far into that stretch

        local r, g, b
        if step == 0 then r, g, b = 1, fraction, 0
        elseif step == 1 then r, g, b = 1 - fraction, 1, 0
        elseif step == 2 then r, g, b = 0, 1, fraction
        elseif step == 3 then r, g, b = 0, 1 - fraction, 1
        elseif step == 4 then r, g, b = fraction, 0, 1
        else r, g, b = 1, 0, 1 - fraction end

        r = r + (1 - r) * RAINBOW_PASTEL
        g = g + (1 - g) * RAINBOW_PASTEL
        b = b + (1 - b) * RAINBOW_PASTEL
        
        letters[i] = string.format('<color=#%02X%02X%02X>%s</color>',
            math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5),
            text:sub(i, i))
    end

    return table.concat(letters)
end

infoMacro('floony', 'categorycheck', 'Chart Category Check', 'f1c2',
    function()
        local standard, special, size = checkChart()

        -- The verdict.
        local verdict, detail
        if #standard.list == 0 then
            verdict = string.richcolor('STANDARD', Colors.enable)
            detail = 'Follows every Standard rule.'
        elseif #special.list == 0 then
            verdict = string.richcolor('SPECIAL', Colors.yellow)
            detail = 'Breaks a Standard rule, but follows every Special rule.'
        else
            verdict = rainbowText('NotARCAEA')
            detail = 'Breaks the rules of both categories. Go wild with it!\n' ..
                     '<size=80%>The only restriction: it must be importable into ArcCreate (Android / iOS), ' ..
                     'play correctly in the Editor and Player, and render properly with Export.</size>'
        end

        -- The line count (from linecount.lua).
        local minutes = Context.songLength / 60000
        local average = (minutes > 0) and math.floor(size.lines / minutes) or 0
        local lineText = string.format('%d | Standard limit: %d | Avg. Lines per minute: %d',
            size.lines, size.limit, average)

        -- Difficulty
        local difficulty = checkDifficulty()
        local colorPreview = (difficulty.color ~= '') 
            and string.format('<color=#%s>■</color> #%s', difficulty.color, difficulty.color) 
            or 'Not set'
        local difficultyText = string.format('Difficulty: <b>%s</b> | Color: %s', difficulty.name, colorPreview)

        local isStandard = (#standard.list == 0)
        local isSpecial  = (#special.list == 0)

        if isStandard then
            if difficulty.official then
                -- Standard difficulty match (Future, Beyond, Eternal)
                difficultyText = difficultyText .. '\n' .. string.richcolor(
                    string.format('✓ Valid Standard Difficulty (%s).', difficulty.official),
                    Colors.enable
                )
            elseif difficulty.isStandardName and difficulty.isStandardColor and difficulty.byName ~= difficulty.byColor then
                -- Mismatch between two Standard difficulties (e.g. Future name with Eternal color)
                difficultyText = difficultyText .. '\n' .. string.richcolor(
                    string.format('⚠ Mismatch Warning: Name indicates "%s", but difficulty color matches %s.', difficulty.byName, difficulty.byColor),
                    Colors.yellow
                )
            else
                -- Past, Present, custom difficulty names, or custom hex colors
                difficultyText = difficultyText .. '\n' .. string.richcolor(
                    '⚠ Standard Notice: Standard only allows Future, Eternal, or Beyond. If submitted to Standard, this chart\'s difficulty will be adjusted to one of those three.',
                    Colors.yellow
                )
            end
        else
            -- Suppress Standard warnings if standard rules are broken
            difficultyText = difficultyText .. '\n' .. string.richcolor(
                '✓ Special & NotARCAEA Notice: Fully accepts ANY difficulty (Past, Present, or custom names/colors).',
                Colors.enable
            )
        end

        local boundsNotice
        if isStandard then
            boundsNotice = string.format(
                'Boundary used: Standard (x: %s to %s | y: %s to %s)',
                RULES.bounds.xMin, RULES.bounds.xMax, RULES.bounds.yMin, RULES.bounds.yMax
            )
        elseif isSpecial then
            boundsNotice = string.format(
                'Boundaries:\n' ..
                '• Standard: x: %s to %s | y: %s to %s\n' ..
                '• Special: x: %s to %s | y: %s to %s\n' ..
                '<color=#F4D35E>Note: Standard boundaries still apply if you don\'t use <b>enwidencamera</b> or <b>enwidenlanes</b>.</color>',
                RULES.bounds.xMin, RULES.bounds.xMax, RULES.bounds.yMin, RULES.bounds.yMax,
                RULES.specialBounds.xMin, RULES.specialBounds.xMax, RULES.specialBounds.yMin, RULES.specialBounds.yMax
            )
        else
            boundsNotice = 'Boundary used: <b>' .. rainbowText('Anywhere') .. '</b> ' .. rainbowText('(as long as they can hit it)')
        end
        
        local noteDescription = string.format(
            '<size=70%%>%s\n' ..
            'Cannot be checked here: video backgrounds, include / fragment commands, scenecontrol folder, and changed trace colors.</size>\n\n',
            boundsNotice
        )
        
        local r = Request.dialogRaw('Chart Category Check',
            DialogField.create('verdict')
                .description(string.format('<size=130%%><b>Verdict: %s</b></size>\n%s', verdict, detail)),

            DialogField.create('lines')
                .description(string.richcolor('<size=80%>' .. Context.chartPath .. ' lines: ' .. lineText .. '</size>', '#98FF98')),

            DialogField.create('difficulty')
                .description('<size=80%>' .. difficultyText .. '</size>'),
                
            DialogField.create('standard')
                .description('<b>Standard</b>\n' .. problemsText(standard)),

            DialogField.create('special')
                .description('<b>Special</b>\n' .. problemsText(special)),

            DialogField.create('note')
                .description(noteDescription),

            DialogField.create('select')
                .setLabel('After closing')
                .setTooltip('Select the notes that break the rules, so you can find and fix them.')
                .dropdownMenu(table.unpack(SELECT_OPTIONS))
        )
        if not r then return end

        local choice = choiceIndex(r['select'], SELECT_OPTIONS)
        if choice == 1 then return end

        local problems = (choice == 2) and standard or special
        local picked, seen = {}, {}
        for _, problem in ipairs(problems.list) do
            for _, event in ipairs(problem.events) do
                if not seen[event] then
                    seen[event] = true
                    picked[#picked + 1] = event
                end
            end
        end

        if #picked == 0 then
            notifyWarn('There are no notes to select (the problems are about timing groups or the line count).')
            return
        end

        local ok = pcall(Event.setSelection, picked)
        if ok then
            notify(string.format('Selected %d problem note(s).', #picked))
        else
            notifyWarn('Could not select the problem notes.')
        end
    end
)