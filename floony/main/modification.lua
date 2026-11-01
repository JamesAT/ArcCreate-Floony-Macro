require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // MODIFY ELEMENTS // --         |
------------------------------------/
-- Macros that change notes are already placed (mostly arcs):

local ROOT = 'floony.modification'
FolderNew('floony', ROOT, 'e429', '- Modify Elements -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - MODIFY
--------------------------------------------------------------------------------

local function isOneOf(arc, list)
    for _, other in ipairs(list) do
        if sameArc(arc, other) then return true end
    end
    return false
end
 
-- Moves a point along one axis ('x' or 'y') by `amount`.
local function movePoint(p, axis, amount)
    if axis == 'x' then return xy(p.x + amount, p.y) end
    return xy(p.x, p.y + amount)
end
 
local function axisValue(p, axis)
    return axis == 'x' and p.x or p.y
end

--------------------------------------------------------------------------------
-- ALIGN & DISTRIBUTE
--------------------------------------------------------------------------------
local ALIGN = 'floony.align'
FolderNew(ROOT, ALIGN, 'e234', '[Align & Distribute]')

-- Align: lines up the selected arcs either left, middle, or right
local function alignMacro(axis)
    local name = axis:upper()
    local options = (axis == 'x')
        and { 'Left (Min X)', 'Center', 'Right (Max X)' }
        or  { 'Bottom (Min Y)', 'Center', 'Top (Max Y)' }

    return function(cmd)
        local arcs = getSelectedArcs(2, 'Select at least 2 arcs to align.')
        if not arcs then return false end

        local req = DialogInput.withTitle('Align Arcs (' .. name .. ')').requestInput({
            DialogField.create('mode')
                .setLabel('Align To')
                .setTooltip('Which edge (or the center) the selected arcs line up on.')
                .dropdownMenu(table.unpack(options))
        })
        coroutine.yield()
        if not req or not req.result then return false end

        local mode = choiceIndex(req.result['mode'], options)  -- 1 = low edge, 2 = center, 3 = high edge

        -- Find the lowest and highest coordinate of the whole selection.
        local lo, hi = math.huge, -math.huge
        for _, arc in ipairs(arcs) do
            local a, b = axisValue(arc.startXY, axis), axisValue(arc.endXY, axis)
            lo = math.min(lo, a, b)
            hi = math.max(hi, a, b)
        end
        local target = (mode == 1 and lo) or (mode == 3 and hi) or (lo + hi) / 2

        -- Move each arc so its own low edge / center / high edge lands on the target.
        for _, arc in ipairs(arcs) do
            local a, b = axisValue(arc.startXY, axis), axisValue(arc.endXY, axis)
            local own = (mode == 1 and math.min(a, b)) or (mode == 3 and math.max(a, b)) or (a + b) / 2
            local shift = target - own

            arc.startXY = movePoint(arc.startXY, axis, shift)
            arc.endXY   = movePoint(arc.endXY, axis, shift)
            cmd.add(arc.save())
        end

        cmd.setName(string.format('Align %d arc(s) %s (%s)', #arcs, name, options[mode]))
        notify(string.format('Aligned %d arc(s): %s.', #arcs, options[mode]))
    end
end

-- Distribute: the first and last arc stay put; the ones between get even spacing.
-- kind is 'x', 'y' (by start position) or 'time' (by start time).
local function distributeMacro(kind)
    local words = { x = 'horizontally', y = 'vertically', time = 'in time' }

    local function read(arc)
        if kind == 'time' then return arc.timing end
        return axisValue(arc.startXY, kind)
    end

    return function(cmd)
        local arcs = getSelectedArcs(3, 'Select at least 3 arcs to distribute.')
        if not arcs then return false end

        table.sort(arcs, function(a, b) return read(a) < read(b) end)

        local first, last = read(arcs[1]), read(arcs[#arcs])
        local step = (last - first) / (#arcs - 1)

        for i = 2, #arcs - 1 do
            local arc = arcs[i]
            local wanted = first + (i - 1) * step

            if kind == 'time' then
                local shift = math.round(wanted) - arc.timing   -- whole milliseconds only
                arc.timing    = arc.timing + shift
                arc.endTiming = arc.endTiming + shift
            else
                local shift = wanted - read(arc)
                arc.startXY = movePoint(arc.startXY, kind, shift)
                arc.endXY   = movePoint(arc.endXY, kind, shift)
            end
            cmd.add(arc.save())
        end

        cmd.setName(string.format('Distribute %d arc(s) %s', #arcs, words[kind]))
        notify(string.format('Spread %d arc(s) evenly %s.', #arcs, words[kind]))
    end
end

MacroNew(ALIGN, 'floony.align_x', 'Align X (Horizontal)', 'e00f', alignMacro('x'))
MacroNew(ALIGN, 'floony.align_y', 'Align Y (Vertical)',   'e015', alignMacro('y'))

MacroNew(ALIGN, 'floony.dist_x', 'Distribute Horizontally (X)',     'e014', distributeMacro('x'))
MacroNew(ALIGN, 'floony.dist_y', 'Distribute Vertically (Y)',       'e076', distributeMacro('y'))
MacroNew(ALIGN, 'floony.dist_t', 'Distribute Chronologically (Time)', 'e192', distributeMacro('time'))

--------------------------------------------------------------------------------
-- SNAP ARC
-- Moves the start or end of arcs onto the path of another arc.
--------------------------------------------------------------------------------
local SNAP = 'floony.snaparc'

-- bug fix for executing macro while selecting arc: it would consider the selected arc as a target
local function requestArcFresh(message)
    pcall(Event.setSelection, {})
    return Request.arc(message)
end

-- Uses the selected arcs; if nothing is selected it asks for one.
local function arcsToSnap()
    local arcs = table.icollapse(
        Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')
    if #arcs == 0 then
        local one = Request.arc('Select arc to be snapped')
        if one then arcs = { one } end
    end
    return arcs
end

-- Start / End: snap one end of the arcs onto ONE target arc.
local function snapToTarget(mode)
    local label = (mode == 'start') and 'Start' or 'End'

    return function(cmd)
        local arcs = arcsToSnap()
        if #arcs == 0 then return false end

        local target = requestArcFresh('Select target arc to snap to')
        if not target then return false end

        local count = 0
        for _, arc in ipairs(arcs) do
            if not sameArc(arc, target) then
                if mode == 'start' then
                    arc.startXY = target.positionAt(arc.timing)
                else
                    arc.endXY = target.positionAt(arc.endTiming)
                end
                cmd.add(arc.save())
                count = count + 1
            end
        end

        if count == 0 then
            notifyWarn('Nothing to snap (an arc cannot snap to itself).')
            return false
        end

        cmd.setName(string.format('Snap %d arc(s) (%s)', count, label))
        notify(string.format('Snapped the %s of %d arc(s).', label:lower(), count))
    end
end

-- Wave: the selected arcs (in time order) bounce between 2 or 3 target arcs.
-- Each arc starts on one target and ends on the next one in the pattern.
local function snapWave(cmd)
    local arcs = table.icollapse(
        Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')
    if #arcs == 0 then
        notifyWarn('Select at least one arc to snap in a wave.')
        return false
    end
    table.sort(arcs, function(a, b) return a.timing < b.timing end)

    local patterns = { '3 Targets: Wave Cycle', '2 Targets: Alternate (T1 <-> T2)' }
    local anchors  = { 'Left (Target 1)', 'Middle (Target 2)', 'Right (Target 3)' }

    local req = DialogInput.withTitle('Wave Snap Options').requestInput({
        DialogField.create('pattern')
            .setLabel('Wave Pattern')
            .setTooltip('How many target arcs, and how the wave moves between them.')
            .dropdownMenu(table.unpack(patterns)),
        DialogField.create('anchor')
            .setLabel('Start Anchor')
            .setTooltip('Which target the first arc starts on.')
            .dropdownMenu(table.unpack(anchors))
    })
    coroutine.yield()
    if not req or not req.result then return false end

    local twoTargets = choiceIndex(req.result['pattern'], patterns) == 2
    local anchor     = choiceIndex(req.result['anchor'], anchors)

    -- `cycle` is the order the wave visits the targets. `targets` are the arcs we snap TO.
    local targets, cycle = {}, {}
    if twoTargets then
        local t1 = requestArcFresh('Select Target Arc 1 (Lower / Left)')
        local t2 = requestArcFresh('Select Target Arc 2 (Upper / Right)')
        if not (t1 and t2) then return false end
        targets, cycle = { t1, t2 }, { t1, t2 }
        anchor = (anchor == 1) and 1 or 2          -- 2 targets: start on T1 or on T2
    else
        local left   = requestArcFresh('Select Target 1 (Left Arc)')
        local middle = requestArcFresh('Select Target 2 (Middle Arc)')
        local right  = requestArcFresh('Select Target 3 (Right Arc)')
        if not (left and middle and right) then return false end
        targets, cycle = { left, middle, right }, { left, middle, right, middle }
    end

    -- Start the cycle at the chosen anchor.
    local seq = {}
    for i = 1, #cycle do seq[i] = cycle[(i + anchor - 2) % #cycle + 1] end

    local count = 0
    for _, arc in ipairs(arcs) do
        if not isOneOf(arc, targets) then
            local from = seq[count % #seq + 1]
            local to   = seq[(count + 1) % #seq + 1]
            arc.startXY = from.positionAt(arc.timing)
            arc.endXY   = to.positionAt(arc.endTiming)
            cmd.add(arc.save())
            count = count + 1
        end
    end

    if count == 0 then
        notifyWarn('No arcs were snapped.')
        return false
    end

    cmd.setName(string.format('Wave Snap %d arc(s)', count))
    notify(string.format('Wave-snapped %d arc(s).', count))
end

FolderNew(ROOT, SNAP, 'e39e', '[Snap Arc]')
MacroNew(SNAP, 'start', 'Start', 'f1e6', snapToTarget('start'))
MacroNew(SNAP, 'end',   'End',   'f1df', snapToTarget('end'))
MacroNew(SNAP, 'wave',  'Wave (Multi-Target)', 'e8d4', snapWave)

--------------------------------------------------------------------------------
-- ARC CONNECT
-- Joins the selected arcs, one after another, with a small connecting arc in the gaps.
--------------------------------------------------------------------------------
MacroNew(ROOT, 'connect', 'Arc Connect', 'e157',
    function(cmd)
        local arcs = getSelectedArcs(2, 'Select at least two arcs or traces.')
        if not arcs then return false end

        table.sort(arcs, function(a, b) return a.timing < b.timing end)

        -- Check first: the arcs must follow each other without overlapping.
        for i = 1, #arcs - 1 do
            if arcs[i].endTiming > arcs[i + 1].timing then
                notifyWarn('The arcs must be in time order and must not overlap.')
                return false
            end
        end

        local made = 0
        for i = 1, #arcs - 1 do
            local a, b = arcs[i], arcs[i + 1]

            local alreadyJoined = a.endTiming == b.timing and a.endX == b.startX and a.endY == b.startY
            if not alreadyJoined then
                cmd.add(Event.arc(a.endTiming, a.endXY, b.timing, b.startXY,
                    a.isVoid, a.color, 's', a.timingGroup).save())
                made = made + 1
            end
        end

        if made == 0 then
            notifyWarn('The selected arcs are already connected.')
            return false
        end

        cmd.setName(string.format('Connect %d arcs', #arcs))
    end
)

--------------------------------------------------------------------------------
-- CUT ON TIMING (thanks rech)
-- Cuts the selected arcs in two at a time you click. ArcTaps stay on.
--------------------------------------------------------------------------------
MacroNew(ROOT, 'cutontiming', 'Cut on Timing', 'e14e',
    function(cmd)
        local selected = getSelectedArcs(1, 'Select at least one arc or trace.')
        if not selected then return false end

        local cutAt = Request.time('Select the time to cut at')

        -- Only arcs that actually pass through that time can be cut.
        local targets = table.iselect(selected, function(_, a)
            return cutAt > a.timing and cutAt < a.endTiming
        end)
        if #targets == 0 then
            notifyWarn('That time is outside every selected arc.')
            return false
        end
        if #targets < #selected then
            notify(string.format('%d arc(s) skipped: the time is outside their range.', #selected - #targets))
        end

        local oldSelection = Event.getCurrentSelection()

        for _, arc in ipairs(targets) do
            local cutPos = arc.positionAt(cutAt)

            local first = Event.arc(arc.timing, arc.startXY, cutAt, cutPos,
                arc.isVoid, arc.color, arc.type, arc.timingGroup, arc.sfx, arc.arcResolutionMultiplier)
            local second = Event.arc(cutAt, cutPos, arc.endTiming, arc.endXY,
                arc.isVoid, arc.color, arc.type, arc.timingGroup, arc.sfx, arc.arcResolutionMultiplier)

            cmd.add(arc.delete())
            cmd.add(first.save())
            cmd.add(second.save())

            -- Find the ArcTaps that sit on this arc.
            Event.setSelection({ arc })
            local found = Event.query(
                EventSelectionConstraint.create().arctap().custom(
                    function(tap)
                        return tap.is('arctap') and arc.instanceEquals(tap.arc)
                    end, ''))

            -- Move each one to the half it belongs to.
            for _, tap in ipairs((found and found.resultCombined) or {}) do
                cmd.add(tap.delete())
                local moved = tap.copy()
                moved.arc = (tap.timing <= cutAt) and first or second
                cmd.add(moved.save())
            end
        end

        Event.setSelection(oldSelection.resultCombined)
        cmd.setName(string.format('Cut %d arc(s) at %dms', #targets, cutAt))
    end
)

--------------------------------------------------------------------------------
-- CYCLE COLORS
-- Gives the selected arcs the next color in the cycle, one after another.
--------------------------------------------------------------------------------
MacroNew(ROOT, 'cyclecol', 'Cycle Colors', 'e419',
    function(cmd)
        local arcs = getSelectedArcs(2, 'Select at least 2 arcs to cycle colors.')
        if not arcs then return false end

        cmd.setName(string.format('Cycle Colors (%d arcs)', #arcs))
        cycleColors(arcs, cmd)
    end
)

--------------------------------------------------------------------------------
-- SHIFT ARC POSITION
-- Moves the selected arcs by a set amount. Pick a step size folder, then a direction.
--------------------------------------------------------------------------------
local SHIFT = 'floony.shiftarcpos'


local function shiftArcs(arcs, dx, dy, cmd)
    for _, arc in ipairs(arcs) do
        arc.startXY = xy(arc.startXY.x + dx, arc.startXY.y + dy)
        arc.endXY   = xy(arc.endXY.x + dx,   arc.endXY.y + dy)
        cmd.add(arc.save())
    end
    cmd.setName(string.format('Shift %d arc(s) (X %s, Y %s)', #arcs, tostring(dx), tostring(dy)))
end

local function shiftMacro(dx, dy)
    return function(cmd)
        local arcs = getSelectedArcs(1, 'No arcs selected.')
        if not arcs then return false end
        shiftArcs(arcs, dx, dy, cmd)
    end
end

-- Smallest to largest: the menu shows them in this order.
local STEPS = {
    { size = 0.01,  name = 'Fine-Tune' },
    { size = 0.05,  name = 'Smallest' },
    { size = 0.125, name = 'Small' },
    { size = 0.25,  name = 'Moderate' },
    { size = 0.5,   name = 'Medium', icon = 'eb56' },
    { size = 1,     name = 'Large' },
}

FolderNew(ROOT, SHIFT, 'e074', '[Shift ArcPos]')
for _, step in ipairs(STEPS) do
    local folder = SHIFT .. '.' .. step.name:lower()
    FolderNew(SHIFT, folder, step.icon or 'e5da', step.name)

    MacroNew(folder, folder .. '.xneg', 'X -' .. step.size, 'e5cb', shiftMacro(-step.size, 0))
    MacroNew(folder, folder .. '.xpos', 'X +' .. step.size, 'e5cc', shiftMacro(step.size, 0))
    MacroNew(folder, folder .. '.ypos', 'Y +' .. step.size, 'e5ce', shiftMacro(0, step.size))
    MacroNew(folder, folder .. '.yneg', 'Y -' .. step.size, 'e5cf', shiftMacro(0, -step.size))
end

-- Custom: type your own X / Y amount (the last values are remembered).
registerSettings('Shift ArcPos (Custom)', { lastShiftX = 0, lastShiftY = 0 },
    function(S) return { string.format('Last values: X %s, Y %s', tostring(S.lastShiftX), tostring(S.lastShiftY)) } end)
    
MacroNew(SHIFT, 'custom', 'Custom', 'e429',
    function(cmd)
        local arcs = getSelectedArcs(1, 'No arcs selected.')
        if not arcs then return false end

        local S = FloonySettings

        local req = DialogInput.withTitle('Shift Arcs').requestInput({
            DialogField.create('shiftX')
                .setLabel('X')
                .defaultTo(tostring(S.lastShiftX))
                .textField(FieldConstraint.create().float()),
            DialogField.create('shiftY')
                .setLabel('Y')
                .defaultTo(tostring(S.lastShiftY))
                .textField(FieldConstraint.create().float()),
            DialogField.create('note')
                .description('Negative (-) = Left / Down\nPositive (+) = Right / Up')
        })
        coroutine.yield()
        if not req or not req.result then return false end

        local dx = tonumber(req.result['shiftX']) or 0
        local dy = tonumber(req.result['shiftY']) or 0
        if dx == 0 and dy == 0 then
            notifyWarn('Nothing to shift (X and Y are both 0).')
            return false
        end

        S.lastShiftX, S.lastShiftY = dx, dy
        saveSettings()
        shiftArcs(arcs, dx, dy, cmd)
    end
)

--------------------------------------------------------------------------------
-- MIRROR ABOUT
-- Flips the selected notes left <-> right around the track centre or around one lane.
-- Lane centres on the arc X axis: lane 1 = -0.25, 2 = 0.25, 3 = 0.75, 4 = 1.25.
-- The track centre is between lanes 2 and 3 (lane 2.5, x = 0.5).
--------------------------------------------------------------------------------
local MIRROR = 'floony.mirrorabout'

local MIRROR_TARGETS = {
    { id = 'floony.mirrorabout.centre', lane = 2.5, x = 0.5,   name = 'Track Centre' },
    { id = 'floony.mirrorabout.lane1',  lane = 1,   x = -0.25, name = 'Lane 1' },
    { id = 'floony.mirrorabout.lane2',  lane = 2,   x = 0.25,  name = 'Lane 2' },
    { id = 'floony.mirrorabout.lane3',  lane = 3,   x = 0.75,  name = 'Lane 3' },
    { id = 'floony.mirrorabout.lane4',  lane = 4,   x = 1.25,  name = 'Lane 4' },
}

local function mirrorMacro(target)
    return function(cmd)
        local floorNotes = table.icollapse(
            Event.getCurrentSelection(EventSelectionConstraint.create().floor()), 'tap', 'hold')
        local arcs = table.icollapse(
            Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

        if #floorNotes == 0 and #arcs == 0 then
            notifyWarn('No notes selected.')
            return false
        end

        -- Check first: a mirrored tap/hold must stay on lanes 1-4, or nothing is changed at all.
        for _, note in ipairs(floorNotes) do
            local newLane = 2 * target.lane - note.lane
            if newLane < 1 or newLane > 4 then
                notifyWarn(string.format('Cannot mirror about %s: a note on lane %d would land on lane %d.',
                    target.name, note.lane, newLane))
                return false
            end
        end

        for _, note in ipairs(floorNotes) do
            note.lane = 2 * target.lane - note.lane
            cmd.add(note.save())
        end

        -- ArcTaps follow their arc, so only the arcs need to be moved.
        for _, arc in ipairs(arcs) do
            arc.startXY = xy(2 * target.x - arc.startXY.x, arc.startXY.y)
            arc.endXY   = xy(2 * target.x - arc.endXY.x,   arc.endXY.y)
            cmd.add(arc.save())
        end

        cmd.setName(string.format('Mirror %d note(s) about %s', #floorNotes + #arcs, target.name))
    end
end

FolderNew(ROOT, MIRROR, 'e8d4', '[Mirror About]')
for _, target in ipairs(MIRROR_TARGETS) do
    MacroNew(MIRROR, target.id, target.name, 'e5da', mirrorMacro(target))
end

--------------------------------------------------------------------------------
-- CURVE TRACES
-- Turns a selected 1ms trace (a shape piece) into a smooth curve made of small straight pieces,
-- following the easing the trace had (si, so, b, sisi, ...).
--------------------------------------------------------------------------------
local function easeIn(v)  return v * v end
local function easeOut(v) return 1 - (1 - v) * (1 - v) end
local function bend(v)    return v < 0.5 and 2 * v * v or 1 - 2 * (1 - v) * (1 - v) end

-- For an easing name, how far along the curve we are (x and y) at time t (0 to 1).
local EASING = {
    s    = function(t) return t, t end,
    si   = function(t) return t, easeIn(t) end,
    so   = function(t) return t, easeOut(t) end,
    b    = function(t) return t, bend(t) end,
    sisi = function(t) return easeIn(t),  easeIn(t) end,
    soso = function(t) return easeOut(t), easeOut(t) end,
    siso = function(t) return easeIn(t),  easeOut(t) end,
    sosi = function(t) return easeOut(t), easeIn(t) end,
}

MacroNew(ROOT, 'curvetrace1ms', 'Curve Traces', 'f8d3',
    function(cmd)
        local arcs = getSelectedArcs(1, 'Select at least one 1ms trace or shape piece.')
        if not arcs then return false end

        -- One piece per beat division (never fewer than 2).
        local pieces = math.max(2, math.round(Context.beatlineDensity or 4))
        local made = 0

        for _, arc in ipairs(arcs) do
            local from, to = arc.startXY, arc.endXY
            local ease = EASING[arc.type or 's'] or EASING.s
            local last = from

            for i = 1, pieces do
                local ex, ey = ease(i / pieces)
                local here = xy(math.lerp(from.x, to.x, ex), math.lerp(from.y, to.y, ey))

                cmd.add(Event.arc(arc.timing, last, arc.endTiming, here,
                    arc.isVoid, arc.color, 's', arc.timingGroup).save())
                made = made + 1
                last = here
            end

            cmd.add(arc.delete())
        end

        cmd.setName(string.format('Curved %d trace(s) into %d pieces.', #arcs, made))
    end
)
