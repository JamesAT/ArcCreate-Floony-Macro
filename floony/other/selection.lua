require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // SELECTION // --               |
------------------------------------/
FolderNew('floony', 'floony.selection', 'ef52', '- Selection -')

-- // FILTER FUNCTION // --
---@param filter string
---@return fun(a:any):boolean
function parseFilter(filter)
    local filterFunc, err = load(
        'return function(tap, arctap, hold, trace, arc, time, endtime, length, color, easing, pos, endpos, timinggroup, arctapcount, lane) return '
        ..filter..' end',
        'input', nil,
        {['math'] = math}
    )

    if err then
        dialogNotify('An error occurred while compiling the given code: '..err..'\nOriginal code: '..filter)
        return false
    end

    ---@cast filterFunc fun():(fun(v:any):boolean)

    return filterFunc()
end

function filterSelect(filterFunc)
    
    local tStart, tEnd = Request.timeRange()
    local notes = Event.query(CustomConstraints.timeRange(tStart, tEnd))

    notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')

    local arctapc = arctapCounts(notes)
    local newSelection = {}

    for _, event in ipairs(notes) do

        local endTiming = event.timing
        if event.is 'long' then
            endTiming = event.endTiming
        end

        local color = nil
        local type = nil
        local pos = nil
        local endpos = nil
        local lane = nil
        if event.is 'arc' then
            color = event.color
            type = event.type
            pos = event.startXY
            endpos = event.endXY
        end
        if event.is 'tap' or event.is 'hold' then
            lane = event.lane
        end

        if filterFunc(
            event.is 'tap', --tap
            event.is 'arctap', --arctap
            event.is 'hold', --hold
            event.is 'arc' and event.isVoid, --trace
            event.is 'arc' and not event.isVoid, --arc
            event.timing, --timing
            endTiming, --endtime
            endTiming - event.timing, --length
            color, --color
            type, --easing
            pos, --pos
            endpos, --endpos
            event.timingGroup, --timinggroup
            arctapc[event] or 0, --arctapcount
            lane
        ) then
            table.insert(newSelection, event)
        end

    end

    Event.setSelection(newSelection)

end

-- // MACROS // --
    -- / Filter select / --
MacroNew(
    'floony.selection', 'filtersel',
    "Filter Select", 'ef4f',
    function()

        -- Parameters --
        local filterVal = 'true'
        local shouldRetry = true
        local filterFunc = nil

        while shouldRetry do

    local dialogRequest = DialogInput.withTitle("Filter").requestInput({
            DialogField.create('filterselect')
                .setLabel('Filter')
                .defaultTo(filterVal)
                .textField(FieldConstraint.create().any()),
            
            DialogField.create("explanation")
            .description('The provided filter must be a lua expression. The following variables are defined for use: \ntap, arctap, hold, trace, arc, time, endtime, length, color, easing, pos, endpos, \ntiminggroup, arctapcount.')
            })
    
            coroutine.yield()
            local filter = dialogRequest.result['filterselect']
            filterVal = filter

            filterFunc = parseFilter(filterVal)
            if filterFunc then shouldRetry = false end
            
        end
        -- Programming --
        filterSelect(filterFunc)

    end
)

    -- / Select All / --
MacroNew(
    'floony.selection', 'selectall',
    'Select All', 'e162',
    function()

        local notes = Event.query(EventSelectionConstraint.create().any())
        notes = table.icollapse(notes, 'arc', 'hold', 'tap', 'arctap')
        Event.setSelection(notes)

    end
)

    -- / Range Select Current Selected Group / --
MacroNewNOCMD(
    'floony.selection', 'selecttg',
    'Range Select Group', 'e8d9',
    function ()
        local tStart, tEnd = Request.timeRange()
        local TG = Context.currentTimingGroup

        local notes = Event.query(
            CustomConstraints.timeRange(tStart, tEnd)
        )
        notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')

        local newSel = {}
        for _, ev in ipairs(notes) do
            local evTG = ev.timingGroup
            if evTG == TG then
                table.insert(newSel, ev)
            end
        end

        if #newSel == 0 then
            notifyWarn("No notes selected in Timing Group " .. TG)
        else
            Event.setSelection(newSel)
        end
    end
)

    -- / Range Select Random / --
MacroNewNOCMD(
    'floony.selection', 'selectrandom',
    'Range Select Random', 'e043',
    function ()
        local tStart, tEnd = Request.timeRange()
        local TG = Context.currentTimingGroup

        local notes = Event.query(
            CustomConstraints.timeRange(tStart, tEnd)
        )
        notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')
        
        if #notes == 0 then
            notifyWarn("No notes found in the selected time range.")
            return
        end

        -- Filter: Only keep notes that belong to the current Timing Group
        local candidates = {}
        for _, ev in ipairs(notes) do
            local evTG = ev.timingGroup or 0
            if evTG == TG then
                table.insert(candidates, ev)
            end
        end

        if #candidates == 0 then
            notifyWarn("No notes found in Timing Group " .. TG .. " within this range.")
            return
        end

        -- Probability to keep each event (0.0 .. 1.0).
        local keepProb = 0.5

        local seedBase = math.floor((tStart + tEnd) * 1000)
        local seed = (seedBase + #candidates * 997 * 7919) % 2147483647
        math.randomseed(seed)
        for i = 1, 5 do math.random() end

        local newSel = {}
        for _, ev in ipairs(candidates) do
            if math.random() < keepProb then
                table.insert(newSel, ev)
            end
        end

        if #newSel == 0 and #candidates > 0 then
            table.insert(newSel, candidates[math.random(1, #candidates)])
        end

        Event.setSelection(newSel)
    end
)


    -- / Range Select Area / --
MacroNewNOCMD(
    'floony.selection', 'selectarea_arcs',
    'Range Select Area', 'ef52',
    function ()
        local tStart = Request.time("Select start time")
        local TG = Context.currentTimingGroup

        local posMin = Request.position(tStart, "Select X/Y Min Position")
        local posMax = Request.position(tStart, "Select X/Y Max Position")

        local xMin, xMax = posMin.x, posMax.x
        local yMin, yMax = posMin.y, posMax.y
        
        coroutine.yield()

        local tEnd = Request.time("Select end time")
        
        coroutine.yield()
        
        local notes = Event.query(
            CustomConstraints.timeRange(tStart, tEnd)
        )
        notes = table.icollapse(notes, 'arc')

        local newSel = {}
        
        local lowX, highX = math.min(xMin, xMax), math.max(xMin, xMax)
        local lowY, highY = math.min(yMin, yMax), math.max(yMin, yMax)

        for _, ev in ipairs(notes) do
            if ev.startX ~= nil then 
                local evTG = ev.timingGroup or 0
                
                if evTG == TG then
                    local ex = ev.startX
                    local ey = ev.startY

                    if ex >= lowX and ex <= highX and ey >= lowY and ey <= highY then
                        table.insert(newSel, ev)
                    end
                end
            end
        end

        if #newSel == 0 then
            notifyWarn("No arcs found in TG " .. TG .. " within those coordinates.")
        else
            Event.setSelection(newSel)
            -- notify("Selected " .. #newSel .. " arcs.")
        end
    end
)

    -- / Select Full Arc / --
MacroNew(
    'floony.selection', 'fullarc',
    'Select Full Arc', 'f1ce',
    function (macro)

        local n = Request.arc('Select the start of the arc series you want to select.')
        Event.setSelection(getFullArc(n))

    end
)