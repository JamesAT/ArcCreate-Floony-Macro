require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // SELECTION // --               |
------------------------------------/
-- Macros that only change WHAT IS SELECTED (they never change the chart):
-- Filter Select, Select All, Select Full Arc, Range Select (Group / Area / Random) and Invert.

local ROOT = 'floony.selection'
FolderNew('floony', ROOT, 'ef52', '- Selection -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - SELECTION
--------------------------------------------------------------------------------

-- The notes (arcs, taps, holds, ArcTaps) of the current selection, as one list.
local function currentSelection()
    return table.icollapse(
        Event.getCurrentSelection(EventSelectionConstraint.create().any()),
        'arc', 'tap', 'hold', 'arctap')
end

-- Notes that are in the given timing group (a note without a group counts as group 0).
local function inTimingGroup(notes, tg)
    return table.iselect(notes, function(_, ev) return (ev.timingGroup or 0) == tg end)
end

--------------------------------------------------------------------------------
-- FILTER SELECT
-- The user writes a condition (like: arc and length > 500). Every note in a time range is
-- tested with it, and the ones where it is true get selected.
--------------------------------------------------------------------------------

-- The names the user can use inside a filter. The ORDER matters: it is the order of the
-- values handed to the filter in filterSelect() below.
local FILTER_ARGS = 'tap, arctap, hold, trace, arc, time, endtime, length, color, easing, pos, endpos, timinggroup, arctapcount, lane'

local MAX_FILTER_TRIES = 3   -- how many times the dialog reopens after a broken filter

-- Turns the typed text into a real function. Returns the function, or false if the text is broken.
-- (This one is global on purpose: other modules may use it.)
---@param filter string
---@return (fun(...):boolean)|boolean
function parseFilter(filter)
    local chunk, err = safeLoad('return function(' .. FILTER_ARGS .. ') return ' .. filter .. ' end', 'input')

    local filterFunc = nil
    if chunk then
        local ok, result = pcall(chunk)
        if ok and type(result) == 'function' then
            filterFunc = result
        else
            err = tostring(result)
        end
    end

    -- Test run with made-up values, so typos (like 'lenght') are caught NOW,
    -- not once for every note.
    if filterFunc then
        local ok, testErr = pcall(filterFunc,
            false, false, false, false, false,   -- tap, arctap, hold, trace, arc
            0, 0, 0,                             -- time, endtime, length
            0, 's',                              -- color, easing
            xy(0, 0), xy(0, 0),                  -- pos, endpos
            0, 0, 1)                             -- timinggroup, arctapcount, lane
        if not ok then
            filterFunc = nil
            err = tostring(testErr)
        end
    end

    if not filterFunc then
        dialogNotify('An error occurred while compiling the given code: ' .. tostring(err) ..
                     '\nOriginal code: ' .. filter)
        return false
    end

    return filterFunc
end

-- Selects, inside a time range picked by the user, every note for which `filterFunc` is true.
function filterSelect(filterFunc)
    local notes = Request.eventsInRange(nil)

    local arctapCount = arctapCounts(notes)
    local matches = {}
    local errors, firstError = 0, nil

    for _, event in ipairs(notes) do
        local endTiming = event.timing
        if event.is 'long' then
            endTiming = event.endTiming
        end

        -- Only arcs have a color, easing and positions. Only taps and holds have a lane.
        local color, easing, pos, endpos, lane
        if event.is 'arc' then
            color = event.color
            easing = event.type
            pos = event.startXY
            endpos = event.endXY
        end
        if event.is 'tap' or event.is 'hold' then
            lane = event.lane
        end

        -- pcall: one note that cannot be tested must not stop the whole selection.
        local ok, isMatch = pcall(filterFunc,
            event.is 'tap',                       -- tap
            event.is 'arctap',                    -- arctap
            event.is 'hold',                      -- hold
            event.is 'arc' and event.isVoid,      -- trace
            event.is 'arc' and not event.isVoid,  -- arc
            event.timing,                         -- time
            endTiming,                            -- endtime
            endTiming - event.timing,             -- length
            color,                                -- color
            easing,                               -- easing
            pos,                                  -- pos
            endpos,                               -- endpos
            event.timingGroup,                    -- timinggroup
            arctapCount[event] or 0,              -- arctapcount
            lane                                  -- lane
        )

        if not ok then
            errors = errors + 1
            firstError = firstError or tostring(isMatch)
        elseif isMatch then
            matches[#matches + 1] = event
        end
    end

    if #matches == 0 then
        if errors > 0 then
            notifyWarn(string.format('The filter raised an error on %d event(s): %s', errors, firstError))
        else
            notifyWarn('No events matched the specified filter criteria.')
        end
        return
    end

    Event.setSelection(matches)
    local msg = string.format('Selected %d event(s).', #matches)
    if errors > 0 then
        msg = msg .. string.format(' (%d event(s) could not be evaluated)', errors)
    end
    notify(msg)
end

-- The presets in the dropdown: { name, filter }. The first one is the "type your own" entry.
local FILTER_PRESETS = {
    { 'Custom Expression',           '' },
    { 'Traces > 500ms',              'trace and length > 500' },
    { 'Outer Lanes (1 & 4)',         '(tap or hold) and (lane == 1 or lane == 4)' },
    { 'Inner Lanes (2 & 3)',         '(tap or hold) and (lane == 2 or lane == 3)' },
    { 'Solid Arcs (Non-Void)',       'arc' },
    { 'Traces (Void Arcs)',          'trace' },
    { 'ArcTaps Only',                'arctap' },
    { 'Arcs With ArcTaps',           'arc and arctapcount > 0' },
    { 'Short Arcs/Traces (< 100ms)', '(arc or trace) and length < 100' },
    { 'Zero-Duration Events (0ms)',  'length == 0' },
    { 'Blue Arcs (Color 0)',         '(arc or trace) and color == ' .. ArcColors.blue },
    { 'Red Arcs (Color 1)',          '(arc or trace) and color == ' .. ArcColors.red },
    { 'Green Arcs (Color 2)',        '(arc or trace) and color == ' .. ArcColors.green },
}

local PRESET_NAMES = table.imap(FILTER_PRESETS, function(_, p) return p[1] end)

local lastCustomFilter = 'true'   -- remembered until the macros are reloaded

-- Filter Select: pick a preset or type your own condition.
MacroNewNOCMD(ROOT, 'filtersel', 'Filter Select', 'ef4f',
    function()
        local filterFunc = nil

        -- The dialog reopens after a broken filter, but only a few times.
        for _ = 1, MAX_FILTER_TRIES do
            local variables = (FILTER_ARGS:gsub(', timinggroup', ',\ntiminggroup'))

            local r = Request.dialogRaw('Filter Select',
                DialogField.create('preset')
                    .setLabel('Preset')
                    .setTooltip('Choose a pre-configured filter preset or select "Custom Expression"')
                    .dropdownMenu(table.unpack(PRESET_NAMES)),

                DialogField.create('customFilter')
                    .setLabel('Cust. Expression')
                    .setTooltip('Used when "Custom Expression" preset is selected')
                    .defaultTo(lastCustomFilter)
                    .textField(FieldConstraint.create().any()),

                DialogField.create('explanation')
                    .description('<b>Available Custom Variables:</b>\n' .. variables)
            )
            if not r then return end   -- the user closed the dialog

            local choice = choiceIndex(r['preset'], PRESET_NAMES)
            local expression

            if choice == 1 then
                expression = r['customFilter']
                if not expression or expression == '' then expression = 'true' end
                lastCustomFilter = expression
            else
                expression = FILTER_PRESETS[choice][2]
            end

            filterFunc = parseFilter(expression)
            if filterFunc then break end
        end

        if not filterFunc then return end
        filterSelect(filterFunc)
    end
)

--------------------------------------------------------------------------------
-- SELECT ALL
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'selectall', 'Select All', 'e162',
    function()
        local found = Event.query(EventSelectionConstraint.create().any())
        local notes = table.icollapse(found, 'arc', 'hold', 'tap', 'arctap')
        Event.setSelection(notes)
        notify(string.format('Selected %d event(s).', #notes))
    end
)

--------------------------------------------------------------------------------
-- SELECT FULL ARC
-- Pick the start of a chain of connected arcs and the whole chain gets selected.
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'fullarc', 'Select Full Arc', 'f1ce',
    function()
        local first = Request.arc('Select the start of the arc series you want to select.')
        if not first then
            notifyWarn('No arc was selected.')
            return
        end

        local chain = getFullArc(first)
        Event.setSelection(chain)
        notify(string.format('Selected %d connected arc(s).', #chain))
    end
)

--------------------------------------------------------------------------------
-- RANGE SELECT GROUP
-- Selects every note in the current timing group, inside a time range.
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'selecttg', 'Range Select Group', 'e8d9',
    function()
        local notes = Request.eventsInRange(nil)
        local tg = Context.currentTimingGroup

        local picked = inTimingGroup(notes, tg)
        if #picked == 0 then
            notifyWarn('No notes selected in Timing Group ' .. tg)
            return
        end

        Event.setSelection(picked)
        notify(string.format('Selected %d event(s) in Timing Group %s.', #picked, tostring(tg)))
    end
)

--------------------------------------------------------------------------------
-- RANGE SELECT AREA
-- Selects the arcs that START inside a box (X/Y) during a time range.
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'selectarea_arcs', 'Range Select Area', 'ef52',
    function()
        local tStart = Request.time('Select start time')
        local tg = Context.currentTimingGroup

        local cornerA = Request.position(tStart, 'Select X/Y Min Position')
        local cornerB = Request.position(tStart, 'Select X/Y Max Position')

        local tEnd = Request.time('Select end time')

        -- The clicks can be in any order, so sort them into low and high.
        local tLow, tHigh = math.min(tStart, tEnd), math.max(tStart, tEnd)
        local xLow, xHigh = math.min(cornerA.x, cornerB.x), math.max(cornerA.x, cornerB.x)
        local yLow, yHigh = math.min(cornerA.y, cornerB.y), math.max(cornerA.y, cornerB.y)

        local arcs = table.icollapse(Event.query(CustomConstraints.timeRange(tLow, tHigh)), 'arc')

        local picked = table.iselect(arcs, function(_, arc)
            if arc.startX == nil or (arc.timingGroup or 0) ~= tg then return false end
            return arc.startX >= xLow and arc.startX <= xHigh
               and arc.startY >= yLow and arc.startY <= yHigh
        end)

        if #picked == 0 then
            notifyWarn('No arcs found in TG ' .. tostring(tg) .. ' within those coordinates.')
            return
        end

        Event.setSelection(picked)
        notify(string.format('Selected %d arc(s).', #picked))
    end
)

--------------------------------------------------------------------------------
-- RANGE SELECT RANDOM
-- Keeps a percentage of the notes at random. Works on the current selection if there is one,
-- otherwise on a time range you pick.
--------------------------------------------------------------------------------
registerSettings('Range Select Random', { randomKeep = 50, randomRun = 0 },
    function(S) return { string.format('Keep: %s%%', tostring(S.randomKeep)) } end)
    
MacroNewNOCMD(ROOT, 'selectrandom', 'Range Select Random', 'e043',
    function()
        local S = FloonySettings
        local tg = Context.currentTimingGroup

        local notes = currentSelection()
        local tStart, tEnd

        if #notes == 0 then
            notes, tStart, tEnd = Request.eventsInRange(nil)
        end

        if #notes == 0 then
            notifyWarn('No notes selected or found in range.')
            return
        end

        -- Prefer the current timing group. If it has no notes, use all of them.
        local candidates = inTimingGroup(notes, tg)
        if #candidates == 0 then
            candidates = notes
        end

        local r = Request.dialogRaw('Random Select',
            DialogField.create('prob')
                .setLabel('Keep (%)')
                .setTooltip('Percentage (1 - 100) of notes to keep.')
                .defaultTo(tostring(S.randomKeep or 50))
                .textField(FieldConstraint.create().float().greater(0).lEqual(100)),

            DialogField.create('reseed')
                .setLabel('Different\nevery run')
                .setTooltip('Off: the same selection gives the same result. On: a new random result every run.')
                .checkbox()
        )
        if not r then return end

        S.randomKeep = math.clamp(tonumber(r['prob']) or S.randomKeep or 50, 1, 100)
        saveSettings()
        local keepRatio = S.randomKeep / 100

        -- The "seed" decides the random order. The same seed gives the same result.
        local seedBase = (tStart and tEnd) and math.floor((tStart + tEnd) * 1000) or (#candidates * 1337)
        local seed = (seedBase + #candidates * 997 * 7919) % 2147483647
        if isOn(r['reseed']) then
            S.randomRun = (S.randomRun or 0) + 1
            seed = (seed + S.randomRun * 104729) % 2147483647
        end
        math.randomseed(seed)
        for _ = 1, 5 do math.random() end   -- the first few numbers are not very random, so skip them

        -- Shuffle a copy of the list, then keep the first part of it.
        local shuffled = table.copy(candidates)
        for i = #shuffled, 2, -1 do
            local j = math.random(1, i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end

        local keepCount = math.clamp(math.round(#candidates * keepRatio), 1, #candidates)
        local picked = {}
        for i = 1, keepCount do
            picked[i] = shuffled[i]
        end

        -- Give the other macros normal random numbers back (the fixed seed above would leak into them).
        pcall(function() math.randomseed(os.time()) end)

        Event.setSelection(picked)
        notify(string.format('Selected %d of %d event(s).', #picked, #candidates))
    end
)

--------------------------------------------------------------------------------
-- INVERT SELECTION (inside a time range)
-- Selects everything in the range that is NOT selected right now.
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'invertsel', 'Invert Selection (Range)', 'e891',
    function()
        local inRange = Request.eventsInRange(nil, 'Select start time (invert)', 'Select end time (invert)')
        local selected = currentSelection()

        -- Group the selected notes by time, so each note is only compared with the few that
        -- share its time (much faster than comparing with every selected note).
        local byTime = {}
        for _, note in ipairs(selected) do
            local list = byTime[note.timing]
            if not list then
                list = {}
                byTime[note.timing] = list
            end
            list[#list + 1] = note
        end

        local function isSelected(ev)
            for _, note in ipairs(byTime[ev.timing] or {}) do
                if note.instanceEquals(ev) then return true end
            end
            return false
        end

        local picked = table.iselect(inRange, function(_, ev) return not isSelected(ev) end)

        if #picked == 0 then
            notifyWarn('Nothing left to select after inverting.')
            return
        end

        Event.setSelection(picked)
        notify(string.format('Selected %d event(s).', #picked))
    end
)