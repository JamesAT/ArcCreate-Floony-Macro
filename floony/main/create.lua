require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // CREATE ELEMENTS // --         |
------------------------------------/
-- Macros that make NEW notes: SkyTap tools, arc beams, arc copies and "Events Repeat".

local ROOT = 'floony.element'
FolderNew('floony', ROOT, 'e145', '- Create Elements -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - CREATE
--------------------------------------------------------------------------------

-- A SkyTap has to sit on a trace. This is a 1ms trace that stays still at `pos`.
local function stillTrace(t, pos, tg)
    return Event.arc(t, pos, t + 1, pos, true, 0, 's', tg)
end
 
-- Adds a "floating" SkyTap (a still trace + an ArcTap on it). Returns the trace.
local function addFreeSkyTap(cmd, t, pos, tg)
    local trace = stillTrace(t, pos, tg)
    cmd.add(trace.save())
    cmd.add(Event.arctap(t, trace, 1).save())
    return trace
end

--------------------------------------------------------------------------------
-- SKYTAP CHAIN
-- Puts an ArcTap on a trace at every beat division (1/beatline density of a beat).
--------------------------------------------------------------------------------
MacroNew(ROOT, 'skytapchain', 'SkyTap Chain', 'e178',
    function(cmd)
        local arc = Request.arc('Select a Void Arc / Trace')
        if not arc then
            notifyWarn('No trace selected.')
            return false
        end
        if not arc.isVoid then
            notifyWarn('The arc must be a trace (void arc).')
            return false
        end

        local start, finish = arc.timing, arc.endTiming
        local step = arcSliceLength(arc)

        -- How many ArcTaps fit on the trace (the last one must still be a full step from the end).
        local count = math.floor((finish - start) / step + 0.0001)
        if count < 1 then
            notifyWarn('The trace is too short for even one ArcTap.')
            return false
        end

        for i = 0, count - 1 do
            local t = math.round(start + i * step)
            cmd.add(Event.arctap(t, arc, 1).save())
        end

        cmd.setName(string.format('SkyTap Chain (%d)', count))
    end
)

--------------------------------------------------------------------------------
-- STURDY TRACE
-- Stacks extra copies of the selected traces on top of each other so they look bolder.
--------------------------------------------------------------------------------
local STURDY_COPIES = 3   -- how many traces each original becomes (change this number if you want more)

MacroNew(ROOT, 'sturdytrace', 'Sturdy Trace', 'e8fe',
    function(cmd)
        local arcs = getSelectedArcs(1, 'Select at least one trace.')
        if not arcs then return false end

        -- Check everything first, so nothing is half-changed.
        for _, arc in ipairs(arcs) do
            if not arc.isVoid then
                notifyWarn('Every selected arc must be a trace (void arc).')
                return false
            end
        end

        for _, arc in ipairs(arcs) do
            for _ = 1, STURDY_COPIES do
                cmd.add(arc.copy().save())
            end
            cmd.add(arc.delete())  -- the copies replace the original
        end

        cmd.setName(string.format('Sturdy Trace (%d)', #arcs))
    end
)

--------------------------------------------------------------------------------
-- BEATLINE / TIMING
-- Adds a timing event at the chosen time.
--------------------------------------------------------------------------------
MacroNew(ROOT, 'beatline', 'Beatline / Timing', 'eba9',
    function(cmd)
        local t = Request.time('Select where to add the timing')
        local tg = Context.currentTimingGroup
        cmd.add(Event.timing(t, Context.bpmAt(t, tg), Context.divisorAt(t, tg), tg).save())
    end
)

--------------------------------------------------------------------------------
-- FREE SKYTAP (a SkyTap that is not attached to any real arc)
--------------------------------------------------------------------------------
local FREE = 'floony.floatskytap'
FolderNew(ROOT, FREE, 'e5d6', '[Free SkyTap]')

-- Create: click a time, click a position, done.
MacroNew(FREE, 'create', 'Create', 'e145',
    function(cmd)
        local t, pos = Request.timeAndPosition()
        addFreeSkyTap(cmd, t, pos, Context.currentTimingGroup)
    end
)

-- Sturdy: same, plus a few traces dropping straight down so the SkyTap is easy to see.
local STURDY_LINES = 4

MacroNew(FREE, 'sturdy', 'Sturdy', 'e8fe',
    function(cmd)
        local t, pos = Request.timeAndPosition()
        local tg = Context.currentTimingGroup

        addFreeSkyTap(cmd, t, pos, tg)

        for _ = 1, STURDY_LINES do
            cmd.add(Event.arc(t, pos, t, xy(pos.x, -0.2), true, 0, 's', tg).save())
        end
    end
)

-- Snap to Arc: same as Create, plus a thin trace joining the SkyTap to a chosen arc.
MacroNew(FREE, 'snap2arc', 'Snap to Arc', 'e39e',
    function(cmd)
        local t, pos = Request.timeAndPosition()
        local target = Request.arc('Select arc to snap to')
        if not target then return false end

        local tg = Context.currentTimingGroup
        addFreeSkyTap(cmd, t, pos, tg)

        local snapped = target.positionAt(t)
        cmd.add(Event.arc(t, pos, t, snapped, true, 0, 's', tg).save())
    end
)

-- Delete: removes a chosen ArcTap and its 1ms trace (only if that trace is a free-SkyTap trace).
MacroNew(FREE, 'delete', 'Delete', 'e872',
    function(cmd)
        local arctap = Request.note(EventSelectionConstraint.create().arctap()).arctap[1]
        if not arctap then return false end

        cmd.add(arctap.delete())

        local parent = arctap.arc
        -- Only remove the trace when it is a tiny one; a long trace may carry other ArcTaps.
        if parent and parent.isVoid and (parent.endTiming - parent.timing) <= 1 then
            cmd.add(parent.delete())
        else
            notify('The ArcTap was deleted. Its trace was kept because it is not a free SkyTap trace.')
        end
    end
)

--------------------------------------------------------------------------------
-- APPEARING SKYTAP
-- A SkyTap that "appears" at the end: its notes live in a hidden timing group whose BPM
-- speeds up from nothing, so the SkyTap seems to fly in.
--------------------------------------------------------------------------------
local APPEAR_NAME  = '$floony.appear'   -- name of the helper timing group
local APPEAR_STEPS = 8                  -- how many BPM changes are used (more = smoother)
local APPEAR_FROM  = 0                  -- starting speed, as a multiple of the current BPM
local APPEAR_TO    = 2                  -- ending speed, as a multiple of the current BPM
                                        -- (swap the two numbers to make it fly OUT instead)
                                        -- TODO: make this a setting

-- Find a helper group that has no timing events in the way, or nil if none is free.
local function findFreeAppearGroup(tStart, tEnd)
    for i = 1, Context.timingGroupCount - 1 do
        local group = Event.getTimingGroup(i)
        if group.name == APPEAR_NAME then
            local inTheWay = Event.query(
                EventSelectionConstraint.create()
                    .timing()
                    .fromTiming(tStart - 1)
                    .toTiming(tEnd)
                    .ofTimingGroup(group.num)
            ).timing
            if #inTheWay == 0 then return group end
        end
    end
    return nil
end

MacroNew(ROOT, 'skytap_appear', 'Appearing SkyTap', 'f0fb',
    function(cmd)
        local tStart = Request.time('Select start time')
        local pos = Request.position(tStart, 'Select position')
        local tEnd = Request.time('Select end time')

        if tEnd <= tStart then
            notifyWarn('The end time must be after the start time.')
            return false
        end

        local currentBpm = Context.bpmAt(tStart, Context.currentTimingGroup)

        -- Reuse a free helper group, or make a new one.
        local group = findFreeAppearGroup(tStart, tEnd)
        if not group then
            group = Event.createTimingGroup('name="' .. APPEAR_NAME .. '"')
            cmd.add(group.save())
        end

        -- Everything below goes into the helper group.
        local function inGroup(c) return c.withTimingGroup(group) end

        -- Freeze the notes' speed at the start, then ramp the BPM up step by step.
        cmd.add(inGroup(Event.timing(tStart, 999999, 999).save()))
        for i = 0, APPEAR_STEPS - 1 do
            local t = math.floor(tStart + (tEnd - tStart) * i / APPEAR_STEPS + 1)
            local bpm = math.lerp(currentBpm * APPEAR_FROM, currentBpm * APPEAR_TO, i / APPEAR_STEPS)
            cmd.add(inGroup(Event.timing(t, bpm, 999).save()))
        end

        -- The SkyTap itself, at the end time.
        local trace = Event.arc(tEnd, pos, tEnd + 1, pos, true, 0, 's')
        cmd.add(inGroup(trace.save()))
        cmd.add(inGroup(Event.arctap(tEnd, trace, 1).save()))

        -- Back to normal speed from the end time on.
        cmd.add(inGroup(Event.timing(tEnd, currentBpm, Context.beatlineDensity).save()))

        cmd.setName('Appearing SkyTap')
    end
)

--------------------------------------------------------------------------------
-- ARC BEAM
-- A super thin, super tall arc at one spot: a "beam" going up, down, or through the position.
--------------------------------------------------------------------------------
local function beamMacro(goDown, throughMiddle)
    return function(cmd)
        local t, pos = Request.timeAndPosition()

        local y = goDown and -100 or 100
        if throughMiddle then y = pos.y - 0.01 end

        cmd.add(Event.arc(
            t, xy(pos.x, y),
            t, xy(pos.x + 0.01, y),
            false, Context.currentArcColor, 's', Context.currentTimingGroup
        ).save())
    end
end

local BEAM = 'floony.arcline'
FolderNew(ROOT, BEAM, 'e015', '[Arc Beam]')
MacroNew(BEAM, 'above',  'Above',  'e5ce', beamMacro(false, false))
MacroNew(BEAM, 'middle', 'Middle', 'f108', beamMacro(false, true))
MacroNew(BEAM, 'below',  'Below',  'e5cf', beamMacro(true, false))

--------------------------------------------------------------------------------
-- ARC REPLICATION
-- Copies the selected arcs/traces in a direction. The count and spacing are remembered.
--------------------------------------------------------------------------------
local COPY = 'floony.copyarc'
local COUNT_KEY, SPACING_KEY = 'floony.copyarc.count', 'floony.copyarc.spacing'

local function copyCount()   return math.floor(tonumber(FloonyStore.get(COUNT_KEY, 10)) or 10) end
local function copySpacing() return tonumber(FloonyStore.get(SPACING_KEY, 0.2)) or 0.2 end

local function replicationSettings()
    local req = DialogInput.withTitle('Arc Replication Settings').requestInput({
        DialogField.create('count')
            .setLabel('Intensity')
            .setTooltip('How many arcs in total? (Including the original)')
            .defaultTo(tostring(copyCount()))
            .textField(FieldConstraint.create().integer().gEqual(1)),

        DialogField.create('spacing')
            .setLabel('Spacing')
            .setTooltip('Distance between each copy.')
            .defaultTo(tostring(copySpacing()))
            .textField(FieldConstraint.create().float())
    })
    coroutine.yield()

    local r = req.result
    if not r then return end
    FloonyStore.set(COUNT_KEY, math.max(1, math.floor(tonumber(r['count']) or copyCount())))
    FloonyStore.set(SPACING_KEY, tonumber(r['spacing']) or copySpacing())
    notify(string.format('Replication: %d arcs, spacing %s.', copyCount(), tostring(copySpacing())))
end

-- dx / dy say which way to copy: (0, 1) = up, (-1, 0) = left, and so on.
local function copyMacro(dx, dy)
    return function(cmd)
        local arcs = getSelectedArcs(1, 'Select at least one arc or trace.')
        if not arcs then return false end

        local count, spacing = copyCount(), copySpacing()
        if not confirmBigJob(#arcs * (count - 1), 'arcs') then return false end
        
        for _, arc in ipairs(arcs) do
            for i = 1, count - 1 do
                local n = arc.copy()
                n.startXY = xy(n.startX + dx * spacing * i, n.startY + dy * spacing * i)
                n.endXY   = xy(n.endX   + dx * spacing * i, n.endY   + dy * spacing * i)
                cmd.add(n.save())
            end
        end

        cmd.setName(string.format('Replicate %d arc(s) x%d', #arcs, count))
    end
end

FolderNew(ROOT, COPY, 'e3bb', '[Arc Replication]')
MacroNew(COPY, 'up',    'Upward',   'e5ce', copyMacro(0, 1))
MacroNew(COPY, 'down',  'Downward', 'e5cf', copyMacro(0, -1))
MacroNew(COPY, 'left',  'Left',     'e5cb', copyMacro(-1, 0))
MacroNew(COPY, 'right', 'Right',    'e5cc', copyMacro(1, 0))
MacroNew(COPY, 'setting', 'Settings', 'e8b8', replicationSettings)

--------------------------------------------------------------------------------
-- EVENTS REPEAT
-- Pick a time range, then copy everything inside it:
--   Count = 1  -> paste ONE copy somewhere else (you pick where it starts)
--   Count > 1  -> paste that many copies right after each other
--------------------------------------------------------------------------------

-- Find the new copy that was made from `original` (ArcTaps need this to find their new arc).
local function findCopyOf(original, pairs_)
    for _, p in ipairs(pairs_) do
        if p.from.instanceEquals(original) then return p.to end
    end
    return nil
end

MacroNew(ROOT, 'floony.repeat', 'Events Repeat', 'e040',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local length = tEnd - tStart

        -- Highlight what is inside the range, so you can see what will be copied.
        local inRange = table.icollapse(
            Event.query(CustomConstraints.timeRange(tStart, tEnd).ofTimingGroup(tg)),
            'arc', 'tap', 'hold', 'arctap')
        Event.setSelection(inRange)

        local req = DialogInput.withTitle('Repeat').requestInput({
            DialogField.create('repeat')
                .setLabel('Count')
                .setTooltip('How many copies? Use 1 to paste a single copy at a time you choose.')
                .defaultTo('1')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('onlyTiming')
                .setLabel('Only Timing')
                .setTooltip('Copy only the timing events.')
                .checkbox(),
            DialogField.create('allTG')
                .setLabel('All TG')
                .setTooltip('Include every timing group in the range, not just the current one.')
                .checkbox()
        })
        coroutine.yield()

        local r = req.result
        if not r then return false end

        local count      = math.max(1, math.floor(tonumber(r['repeat']) or 1))
        local onlyTiming = isOn(r['onlyTiming'])
        local allTG      = isOn(r['allTG'])

        -- How far each copy is moved in time.
        local pasteAt = nil
        if count == 1 then pasteAt = Request.time('Select the time to paste at') end
        local function offsetFor(i)
            if count == 1 then return pasteAt - tStart end
            return i * length
        end

        local constraint = CustomConstraints.timeRange(tStart, tEnd)
        if not allTG then constraint = constraint.ofTimingGroup(tg) end
        local found = Event.query(constraint)

        -- Keep only the events of the groups we care about.
        local function wanted(list)
            return table.iselect(list or {}, function(_, ev) return allTG or ev.timingGroup == tg end)
        end

        -- A plain copy that is moved in time (works for taps, holds, arcs, timing events...).
        local function movedCopy(ev, offset)
            local c = ev.copy()
            c.timing = ev.timing + offset
            if c.is 'long' then c.endTiming = ev.endTiming + offset end
            return c
        end

        if onlyTiming then
            local timings = wanted(found.timing)
            if not confirmBigJob(count * #timings, 'timing events') then return false end
            for i = 1, count do
                for _, ev in ipairs(timings) do
                    cmd.add(movedCopy(ev, offsetFor(i)).save())
                end
            end
            cmd.setName('Repeat timing events x' .. count)
            return
        end

        local arcs   = wanted(found.arc)
        local arctaps = wanted(found.arctap)
        local others = table.ijoin(table.ijoin(wanted(found.tap), wanted(found.hold)),
                                   table.ijoin(wanted(found.timing), wanted(found.scenecontrol)))

        local perRepeat = #arcs + #arctaps + #others
        if not confirmBigJob(count * perRepeat, 'events') then return false end
        
        for i = 1, count do
            local offset = offsetFor(i)
            local madeArcs = {}   -- { from = original arc, to = new arc }

            for _, arc in ipairs(arcs) do
                local c = movedCopy(arc, offset)
                madeArcs[#madeArcs + 1] = { from = arc, to = c }
                cmd.add(c.save())
            end

            -- ArcTaps go on the NEW copy of their arc. (Skipped if their arc was not copied.)
            for _, tap in ipairs(arctaps) do
                local newArc = tap.arc and findCopyOf(tap.arc, madeArcs)
                if newArc then
                    local c = tap.copy()
                    c.arc = newArc
                    c.timing = tap.timing + offset
                    cmd.add(c.save())
                end
            end

            for _, ev in ipairs(others) do
                cmd.add(movedCopy(ev, offset).save())
            end
        end

        cmd.setName(string.format('Repeat events x%d', count))
    end
)