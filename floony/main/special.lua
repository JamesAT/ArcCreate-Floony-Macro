require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // SPECIAL ELEMENTS // --        |
------------------------------------/
-- Bigger, more creative macros:
--   Link / Unlink ArcTaps        Notes to Trace / Shadow        Timing Stash
--   Tap to Hidegroup             Hold to Groupalpha             Flashing SC
--   Duration grabber             Note Trails                    Camera tools
--   Spiral Trace                 Auto-Quantize                  Offset by BPM
--   Copy Timing Group            Stream Placement               

local SPECIAL = 'floony.special'
FolderNew('floony', SPECIAL, 'f0ec', '- Special Elements -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - SPECIAL
--------------------------------------------------------------------------------

-- The selected notes of the given kinds as one list (all four kinds when none are given).
local function selectedNotes(...)
    local kinds = { ... }
    if #kinds == 0 then kinds = { 'arc', 'tap', 'hold', 'arctap' } end
    return table.icollapse(
        Event.getCurrentSelection(EventSelectionConstraint.create().any()),
        table.unpack(kinds))
end

-- The selected long notes (arcs, traces and holds) as one list.
local function selectedLongNotes()
    return table.icollapse(
        Event.getCurrentSelection(EventSelectionConstraint.create().long()), 'arc', 'hold')
end

-- The timing group a note belongs to (an ArcTap uses its arc's group when it has none).
local function groupOf(note)
    return note.timingGroup or (note.arc and note.arc.timingGroup) or Context.currentTimingGroup
end

-- Scenecontrol values: 0 has to be sent as the text '0', other numbers as numbers.
-- Returns nil when the text is not a number.
local function scValue(text)
    if text == '0' then return '0' end
    return tonumber(text)
end

-- Puts the chosen option on top of a dropdown list, so it is the one shown first.
-- Basically defaultTo for Dropdown
-- TODO: change this to global ones
local function defaultFirst(options, chosen)
    local list = {}
    for _, option in ipairs(options) do
        if option == chosen then
            table.insert(list, 1, option)
        else
            list[#list + 1] = option
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- LINK / UNLINK ARCTAPS
-- Depending on what is selected:
--   2 or more ArcTaps -> they get linked by one continuous trace line
--   1 ArcTap          -> it is moved onto its own tiny point trace (unlinked)
--   arcs              -> every ArcTap on them gets its own point trace, and the arcs are removed
--------------------------------------------------------------------------------

-- Where an ArcTap sits on its arc (safe when the arc has no length/0ms).
local function arcTapPosition(arctap)
    local arc = arctap.arc
    if not arc then return xy(0, 0) end

    local fallback = arc.startXY or xy(arc.startX or 0, arc.startY or 0)
    local duration = (arc.endTiming or arc.timing) - arc.timing
    if math.abs(duration) < 0.001 then return fallback end

    local pos = arc.positionAt(arctap.timing, true)
    -- (pos ~= pos is the way to check for 'not a number')
    if not pos or pos.x ~= pos.x or pos.y ~= pos.y then return fallback end
    return pos
end

-- Deletes the tiny (0-1ms) trace an ArcTap was sitting on.
local function removeTinyParent(cmd, arctap, removed)
    local parent = arctap.arc
    if not parent or not parent.isVoid then return end
    if math.abs((parent.endTiming or parent.timing) - parent.timing) > 1 then return end

    for _, done in ipairs(removed) do
        if sameNote(done, parent) then return end
    end
    removed[#removed + 1] = parent
    cmd.add(parent.delete())
end

-- All ArcTaps that placed on the given arcs.
local function getAttachedArcTaps(arcs)
    local found = {}
    local seen = {}

    for _, arc in ipairs(arcs) do
        local query = Event.query(
            EventSelectionConstraint.create()
                .fromTiming(arc.timing)
                .toTiming(arc.endTiming)
                .arcTap()
        )
        for _, arctap in ipairs(query.arctap or {}) do
            if sameNote(arctap.arc, arc) and not seen[arctap] then
                seen[arctap] = true
                found[#found + 1] = arctap
            end
        end
    end

    return found
end

-- Moves one ArcTap onto its own 0ms trace and deletes the old ArcTap.
local function extractToPointTrace(cmd, arctap)
    local pos = arcTapPosition(arctap)
    local color = (arctap.arc and arctap.arc.color) or 0

    local trace = Event.arc(arctap.timing, pos, arctap.timing, pos, true, color, 's', groupOf(arctap))
    cmd.add(trace.save())
    cmd.add(Event.arcTap(arctap.timing, trace, 1).save())
    cmd.add(arctap.delete())
end

MacroNew(SPECIAL, 'floony.arctap_linker', 'Link / Unlink ArcTaps', 'e3bc',
    function(cmd)
        local arcs = selectedNotes('arc')
        local arctaps = selectedNotes('arctap')

        -- MODE 1: two or more ArcTaps -> link them with one trace line.
        if #arctaps >= 2 then
            sortByTime(arctaps)
            local removed = {}

            for _, arctap in ipairs(arctaps) do
                removeTinyParent(cmd, arctap, removed)
            end

            -- One trace piece between every two neighbours.
            local pieces = {}
            for i = 1, #arctaps - 1 do
                local a, b = arctaps[i], arctaps[i + 1]
                if b.timing > a.timing then
                    local trace = Event.arc(a.timing, arcTapPosition(a), b.timing, arcTapPosition(b),
                        true, 0, 's', groupOf(a))
                    cmd.add(trace.save())
                    pieces[#pieces + 1] = { trace = trace, from = a, to = b }
                end
            end

            -- Put the ArcTaps on the new pieces (each on the start of its piece, the last also on the end).
            for i, piece in ipairs(pieces) do
                cmd.add(Event.arcTap(piece.from.timing, piece.trace, 1).save())
                cmd.add(piece.from.delete())

                if i == #pieces then
                    cmd.add(Event.arcTap(piece.to.timing, piece.trace, 1).save())
                    cmd.add(piece.to.delete())
                end
            end

            cmd.setName(string.format('Link %d ArcTaps into Trace', #arctaps))
            return
        end

        -- MODE 2: one ArcTap -> unlink it onto its own point trace.
        if #arctaps == 1 then
            removeTinyParent(cmd, arctaps[1], {})
            extractToPointTrace(cmd, arctaps[1])

            cmd.setName('Unlink ArcTap to Point Trace')
            notify('Unlinked ArcTap onto isolated point trace.')
            return
        end

        -- MODE 3: arcs -> unlink every ArcTap on them, then remove those arcs.
        if #arcs > 0 then
            local attached = getAttachedArcTaps(arcs)
            if #attached == 0 then
                notifyWarn('No ArcTaps found on selected arc(s).')
                return false
            end

            for _, arctap in ipairs(attached) do
                extractToPointTrace(cmd, arctap)
            end
            for _, arc in ipairs(arcs) do
                cmd.add(arc.delete())
            end

            cmd.setName(string.format('Unlink %d ArcTap(s) & Remove Arc(s)', #attached))
            return
        end

        notifyWarn('Select arc(s) containing ArcTaps or select ArcTaps directly.')
        return false
    end
)

--------------------------------------------------------------------------------
-- NOTES TO TRACE
-- Draws the outline of notes with traces, so they look like fake notes.
--   Tap -> tap outline | Hold -> hold outline | Arc -> arc outline | ArcTap -> SkyTap box (optional)
--------------------------------------------------------------------------------

-- The outline of a floor note (tap or hold) from time t1 to t2, between the lane edges a and b.
local function addFloorTrace(cmd, t1, t2, a, b, tg, isHold)
    local function line(startTime, endTime, startLane, endLane)
        cmd.add(Event.arc(startTime, xy(startLane, -0.2), endTime, xy(endLane, -0.2),
            true, 0, 's', tg).save())
    end

    line(t1, t2, a, a)   -- left side
    line(t1, t2, b, b)   -- right side
    line(t1, t1, a, b)   -- start edge
    line(t2, t2, a, b)   -- end edge

    if isHold then
        local middle = (a + b) / 2
        line(t1, t2, middle, middle)   -- a line down the middle of a hold
    end
end

-- The outline of an arc: a box that follows the arc, with caps at the start and the end.
local function addArcTrace(cmd, arc)
    local function line(t1, t2, x1, y1, x2, y2)
        cmd.add(Event.arc(t1, xy(x1, y1), t2, xy(x2, y2), true, 0, arc.type, arc.timingGroup).save())
    end

    local t1, t2 = arc.timing, arc.endTiming
    local sx, sy = arc.startXY.x, arc.startXY.y
    local ex, ey = arc.endXY.x, arc.endXY.y

    -- A line from the arc down to the floor at its start.
    line(t1, t1, sx, sy - 0.15, sx, -0.2)

    -- The three sides along the arc: top, left and right.
    line(t1, t2, sx, sy + 0.1, ex, ey + 0.1)
    line(t1, t2, sx - 0.1, sy - 0.07, ex - 0.1, ey - 0.07)
    line(t1, t2, sx + 0.1, sy - 0.07, ex + 0.1, ey - 0.07)

    -- Start cap and end cap (a small diamond each).
    local function cap(t, x, y)
        line(t, t, x, y + 0.1, x + 0.1, y - 0.07)
        line(t, t, x + 0.1, y - 0.07, x, y - 0.15)
        line(t, t, x, y - 0.15, x - 0.1, y - 0.07)
        line(t, t, x - 0.1, y - 0.07, x, y + 0.1)
    end
    cap(t1, sx, sy)
    cap(t2, ex, ey)
end

-- The outline of an ArcTap (the box shape) at time `time` and position `place`.
local function addSkyTapTrace(cmd, time, place, tg)
    local SKYTAP_LENGTH = 10   -- ms the box lasts

    -- A flat line that does not last any time.
    local function flat(t, x1, y1, x2, y2)
        cmd.add(Event.arc(t, xy(x1, y1), t, xy(x2, y2), true, 0, 's', tg).save())
    end
    -- A dot that lasts SKYTAP_LENGTH ms.
    local function corner(x, y)
        cmd.add(Event.arc(time, xy(x, y), time + SKYTAP_LENGTH, xy(x, y), true, 0, 's', tg).save())
    end

    local left, right = place.x - 0.23, place.x + 0.23
    local top, bottom = place.y, place.y - 0.16

    for _, t in ipairs { time, time + SKYTAP_LENGTH } do
        flat(t, left, top, right, top)
        flat(t, left, bottom, right, bottom)
        flat(t, right, top, right, bottom)
        flat(t, left, top, left, bottom)
    end

    corner(left, top)
    corner(right, top)
    corner(left, bottom)
    corner(right, bottom)
end

local TRACE = 'floony.convert2trace'
FolderNew(SPECIAL, TRACE, 'e028', '[Notes to Trace]')

local TAP_TRACE_DEPTH = 15   -- how long (ms) the outline of a tap is

-- The settings of this macro.
if registerSettings then
    registerSettings('Notes to Trace',
        { traceIncludeArcTaps = false, traceKeepOriginals = false },
        function(S)
            return {
                'Include ArcTaps (SkyTap): ' .. string.richcolor(S.traceIncludeArcTaps and 'On' or 'Off', Colors.status(S.traceIncludeArcTaps)),
                'Keep original notes: ' .. string.richcolor(S.traceKeepOriginals and 'On' or 'Off', Colors.status(S.traceKeepOriginals)),
            }
        end)
end

MacroNew(TRACE, 'notes2trace', 'Convert Selected', 'e5da',
    function(cmd)
        local S = FloonySettings

        local taps = selectedNotes('tap')
        local holds = selectedNotes('hold')
        local arcs = selectedNotes('arc')
        local arctaps = selectedNotes('arctap')

        if #taps + #holds + #arcs + #arctaps == 0 then
            notifyWarn('Select taps, holds, arcs or ArcTaps to convert.')
            return false
        end

        local done = { tap = 0, hold = 0, arc = 0, arctap = 0 }
        local skippedTraces, skippedArcTaps = 0, 0

        -- The original note is deleted, unless 'Keep original notes' is on.
        local function removeOriginal(note)
            if not S.traceKeepOriginals then cmd.add(note.delete()) end
        end

        -- A lane's left and right edge on the floor.
        local function laneEdges(lane)
            return lane / 2 - 0.975, lane / 2 - 0.525
        end

        for _, tap in ipairs(taps) do
            local a, b = laneEdges(tap.lane)
            addFloorTrace(cmd, tap.timing, tap.timing + TAP_TRACE_DEPTH, a, b, tap.timingGroup, false)
            removeOriginal(tap)
            done.tap = done.tap + 1
        end

        for _, hold in ipairs(holds) do
            local a, b = laneEdges(hold.lane)
            addFloorTrace(cmd, hold.timing, hold.endTiming, a, b, hold.timingGroup, true)
            removeOriginal(hold)
            done.hold = done.hold + 1
        end

        for _, arc in ipairs(arcs) do
            if arc.isVoid then
                skippedTraces = skippedTraces + 1
            else
                addArcTrace(cmd, arc)
                removeOriginal(arc)
                done.arc = done.arc + 1
            end
        end

        for _, arctap in ipairs(arctaps) do
            local parent = S.traceIncludeArcTaps and arctap.arc or nil
            if parent then
                addSkyTapTrace(cmd, arctap.timing, parent.positionAt(arctap.timing, true), arctap.timingGroup)
                removeOriginal(arctap)
                done.arctap = done.arctap + 1
            else
                skippedArcTaps = skippedArcTaps + 1
            end
        end

        local total = done.tap + done.hold + done.arc + done.arctap
        if total == 0 then
            if skippedArcTaps > 0 then
                notifyWarn(string.format(
                    '%d ArcTap(s) selected, but ArcTap conversion is off. Turn on "Include ArcTaps" in Notes to Trace > Settings.',
                    skippedArcTaps))
            else
                notifyWarn('The selected arcs are already traces.')
            end
            return false
        end

        -- A short report of what happened.
        local parts = {}
        for _, kind in ipairs { 'tap', 'hold', 'arc', 'arctap' } do
            if done[kind] > 0 then parts[#parts + 1] = done[kind] .. ' ' .. kind .. '(s)' end
        end
        local msg = 'Converted ' .. table.concat(parts, ', ') .. ' to trace.'
        if skippedTraces > 0 then msg = msg .. string.format(' Skipped %d trace(s).', skippedTraces) end
        if skippedArcTaps > 0 then msg = msg .. string.format(' Skipped %d ArcTap(s) (option off).', skippedArcTaps) end

        cmd.setName(string.format('Notes to Trace (%d note(s))', total))
        notify(msg)
    end
)

-- SkyTap box at a clicked time and position.
MacroNew(TRACE, 'voidskytap', 'SkyTap', 'e5da',
    function(cmd)
        local time, place = Request.timeAndPosition()
        addSkyTapTrace(cmd, time, place, Context.currentTimingGroup)
    end
)

-- SkyTap box on a chosen trace, at a clicked time.
MacroNew(TRACE, 'voidskytap_ontrace', 'SkyTap (On Trace)', 'e5da',
    function(cmd)
        local arc = Request.arc('Select a Trace')
        if not arc then return false end
        if not arc.isVoid then
            notifyWarn('The arc must be a trace.')
            return false
        end

        local time = Request.time('Select timing')
        addSkyTapTrace(cmd, time, arc.positionAt(time), Context.currentTimingGroup)
    end
)

-- Settings.
MacroNewNOCMD(TRACE, 'notes2trace_settings', 'Settings', 'e8b8',
    function()
        local S = FloonySettings

        local arcTapsOptions = S.traceIncludeArcTaps and { 'On', 'Off' } or { 'Off', 'On' }
        local keepOptions    = S.traceKeepOriginals and { 'On', 'Off' } or { 'Off', 'On' }

        local r = Request.dialogRaw('Notes to Trace - Settings',
            DialogField.create('arctaps')
                .setLabel('Include ArcTaps\n(SkyTap)')
                .setTooltip('Also convert selected ArcTaps into SkyTap-shaped traces.')
                -- .defaultTo(arcTapsOptions[1])
                .dropdownMenu(table.unpack(arcTapsOptions)),
            DialogField.create('keep')
                .setLabel('Keep original\nnotes')
                .setTooltip('Do not delete the notes that were converted.')
                -- .defaultTo(keepOptions[1])
                .dropdownMenu(table.unpack(keepOptions))
        )
        if not r then return end

        local arcTapsChoice = arcTapsOptions[choiceIndex(r['arctaps'], arcTapsOptions)]
        local keepChoice    = keepOptions[choiceIndex(r['keep'], keepOptions)]

        S.traceIncludeArcTaps = (arcTapsChoice == 'On')
        S.traceKeepOriginals  = (keepChoice == 'On')
        saveSettings()

        notify(string.format('Notes to Trace: ArcTaps %s, keep originals %s.',
            S.traceIncludeArcTaps and 'on' or 'off', S.traceKeepOriginals and 'on' or 'off'))
    end,
    true
)

--------------------------------------------------------------------------------
-- NOTES TO SHADOW
-- Copies notes very high up (y = 100) into a hidden timing group, so they work as 'shadows'.
-- The group is called $floony.shadow and is reused every time.
--------------------------------------------------------------------------------
MacroNew(SPECIAL, 'floony.convert2shadow', 'Notes to Shadow', 'e427',
    function(cmd)
        local notes = selectedNotes()
        if #notes == 0 then
            notifyWarn('Please select at least one note.')
            return false
        end

        local group = findGroupByName('$floony.shadow')
        if not group then
            group = Event.createTimingGroup('name="$floony.shadow", noinput,noheightindicator')
            cmd.add(group.save())
        end

        local HIGH = 100   -- far above the screen

        -- Adds an arc into the shadow group.
        local function addShadow(t1, startXY, t2, endXY, isVoid, color, arcType)
            cmd.add(Event.arc(t1, startXY, t2, endXY, isVoid, color, arcType)
                .save().withTimingGroup(group))
        end

        for _, note in ipairs(notes) do
            if note.is('hold') then
                -- Two thin arcs (blue and red) side by side.
                local center = note.lane / 2 - 0.75
                addShadow(note.timing, xy(center - 0.12, HIGH), note.endTiming, xy(center - 0.12, HIGH), false, 0, 's')
                addShadow(note.timing, xy(center + 0.12, HIGH), note.endTiming, xy(center + 0.12, HIGH), false, 1, 's')

            elseif note.is('tap') then
                addShadow(note.timing, xy(note.lane / 2 - 0.63, HIGH), note.timing, xy(note.lane / 2 - 1.08, HIGH),
                    false, 0, 's')

            elseif note.is('arc') then
                addShadow(note.timing, xy(note.startX, HIGH), note.endTiming, xy(note.endX, HIGH),
                    note.isVoid, note.color, note.type)
            end
        end

        -- ArcTaps: if traces are selected, use the ArcTaps on those traces. Otherwise use the selected ArcTaps.
        local traces = table.iselect(selectedNotes('arc'), function(_, a) return a.isVoid end)
        local arctaps = (#traces > 0) and getAttachedArcTaps(traces) or {}
        if #arctaps == 0 then
            arctaps = selectedNotes('arctap')
        end

        local skipped = 0
        for _, arctap in ipairs(arctaps) do
            local arc = arctap.arc
            if arc then
                -- Safe 0ms parent arc handling
                local x = (arc.timing == arc.endTiming) and arc.startX or arc.positionAt(arctap.timing, true).x
                addShadow(arctap.timing, xy(x - 0.15, HIGH), arctap.timing, xy(x + 0.35, HIGH),
                    false, arc.color, arc.type)
            else
                skipped = skipped + 1
            end
        end

        -- Remove selected notes
        local toDelete = {}
        for _, note in ipairs(notes) do
            toDelete[note] = true
        end
        for _, arctap in ipairs(arctaps) do
            toDelete[arctap] = true
        end

        for event in pairs(toDelete) do
            cmd.add(event.delete())
        end

        if skipped > 0 then
            notifyWarn(string.format('%d ArcTap(s) skipped: they have no arc.', skipped))
        end
        cmd.setName(string.format('Notes to Shadow (%d note(s))', #notes))
    end
)

--------------------------------------------------------------------------------
-- STASHES (Timing Stash and Camera Stash)
-- Save some events now and paste them later at another time.
-- Every stash you make becomes its own macro in the folder. (Stashes last until the macros
-- are reloaded.)
--------------------------------------------------------------------------------

-- Camera events can be mirrored left <-> right: flip x and the two sideways rotations.
local function mirrorCamera(ev)
    ev.x = -ev.x
    ev.rx = -ev.rx
    ev.rz = -ev.rz
end

-- Builds one stash folder.
--   createId : id of the 'Create' macro
--   queryKey : the kind of event to stash ('timing' or 'camera')
--   noun     : what to call them in messages
--   canMirror: show a Mirror option (camera only)
local function buildStashFolder(folderId, createId, queryKey, noun, canMirror)
    local count = 0   -- how many stashes were made (used to give each macro a unique id)

    MacroNewNOCMD(folderId, createId, 'Create', 'e145',
        function()
            local tStart, tEnd = Request.timeRange()
            local found = table.icollapse(
                Event.query(CustomConstraints.timeRange(tStart, tEnd)), queryKey)

            if #found == 0 then
                notifyWarn('No ' .. noun .. ' detected.')
                return
            end

            local fields = {
                DialogField.create('info')
                    .description(tostring(#found) .. ' ' .. noun .. ' detected!'),
                DialogField.create('name')
                    .setLabel('Name')
                    .setHint('Enter a name for the stash')
                    .setTooltip("Your stash name will be included in the newly created macro's name"),
            }
            if canMirror then
                fields[#fields + 1] = DialogField.create('mirror')
                    .setLabel('Mirror')
                    .setTooltip('Mirror the camera events when pasting')
                    .checkbox()
            end

            local r = Request.dialogRaw(noun:gsub('^%l', string.upper) .. ' Stash Name', table.unpack(fields))
            if not r then return end

            count = count + 1
            local name = r['name']
            if not name or name == '' then name = 'Stash ' .. count end
            local mirror = canMirror and isOn(r['mirror'])

            -- Keep our own copies, so the stash still works if the originals are changed or deleted.
            local events, first = {}, math.huge
            for _, ev in ipairs(found) do
                events[#events + 1] = ev.copy()
                first = math.min(first, ev.timing)
            end

            local title = 'Stash ' .. count .. ': ' .. name
            if mirror then title = title .. ' (M)' end

            MacroNew(folderId, folderId .. '.stash.' .. count, title, 'ea50',
                function(cmd)
                    local at = Request.time('Select where to paste your stash')

                    for _, saved in ipairs(events) do
                        local ev = saved.copy()
                        ev.timing = at + (saved.timing - first)
                        if mirror then mirrorCamera(ev) end
                        cmd.add(ev.save())
                    end

                    cmd.setName('Pasting Stash ' .. name)
                end
            )

            dialogNotify("Stored as '" .. name .. "'. It is now a macro in this folder.")
        end
    )
end

FolderNew(SPECIAL, 'floony.timingstash', 'ec09', 'Timing Stash')
buildStashFolder('floony.timingstash', 'stashcreate', 'timing', 'timing events', false)

--------------------------------------------------------------------------------
-- TAP TO HIDEGROUP
-- Turns the selected taps into hidegroup scenecontrols that alternate between hide and unhide.
--------------------------------------------------------------------------------
local TAP2SC = 'floony.taptosc'
FolderNew(SPECIAL, TAP2SC, 'f1d1', '[Tap to Hidegroup]')

local function tapToHidegroup(hideFirst)
    return function(cmd)
        local taps = sortByTime(selectedNotes('tap'))
        if #taps < 2 then
            notifyWarn('Please select at least 2 tap notes.')
            return false
        end

        local tg = Context.currentTimingGroup
        for index, tap in ipairs(taps) do
            -- Odd taps are the 'first' kind, even taps the other kind.
            local isFirstKind = (index % 2 == 1)
            local hide = (isFirstKind == hideFirst)

            cmd.add(Event.scenecontrol(tap.timing, 'hidegroup', tg, '0', hide and 1 or '0').save())
            cmd.add(tap.delete())
        end
    end
end

MacroNew(TAP2SC, 'hide', '1 > 0... (Hide First)', 'e3f1', tapToHidegroup(true))
MacroNew(TAP2SC, 'unhide', '0 > 1... (Unhide First)', 'e3f2', tapToHidegroup(false))

--------------------------------------------------------------------------------
-- HOLD TO GROUPALPHA
-- Turns long notes into groupalpha scenecontrols (the long note is deleted).
--------------------------------------------------------------------------------
local ALPHA = 'floony.holdtoalpha'
FolderNew(SPECIAL, ALPHA, 'e919', '[Hold to Groupalpha]')

-- Normal: fades to one alpha value over the length of the long note.
MacroNew(ALPHA, 'alphanormal', 'Normal', 'e145',
    function(cmd)
        local notes = selectedLongNotes()
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local r = Request.dialogRaw('Hold to Group Alpha',
            DialogField.create('alphaTo')
                .setLabel('Alpha')
                .setTooltip('Where should alpha be set next?')
                .textField(FieldConstraint.create().float())
        )
        if not r then return false end

        local alphaTo = scValue(r['alphaTo'])
        if alphaTo == nil then
            notifyWarn('Please type a number for the alpha.')
            return false
        end

        local tg = Context.currentTimingGroup
        for _, note in ipairs(notes) do
            cmd.add(Event.scenecontrol(note.timing, 'groupalpha', tg, note.endTiming - note.timing, alphaTo).save())
            cmd.add(note.delete())
        end
    end
)

-- Flash: jumps to the first alpha at once, then fades to the second over the rest of the note.
local lastFlash = {}   -- remembered until the macros are reloaded

MacroNew(ALPHA, 'alphaflash', 'Flash', 'e3e7',
    function(cmd)
        local notes = selectedLongNotes()
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local r = Request.dialogRaw('Hold to Group Alpha',
            DialogFields.default(
                DialogField.create('alphaInitial')
                    .setLabel('Initial Alpha')
                    .setTooltip('Starting alpha value.'),
                lastFlash.initial)
                .textField(FieldConstraint.create().float()),
            DialogFields.default(
                DialogField.create('alphaEnd')
                    .setLabel('End Alpha')
                    .setTooltip('Final alpha value.'),
                lastFlash.final)
                .textField(FieldConstraint.create().float())
        )
        if not r then return false end

        local initial, final = scValue(r['alphaInitial']), scValue(r['alphaEnd'])
        if initial == nil or final == nil then
            notifyWarn('Please type numbers for both alpha values.')
            return false
        end
        lastFlash.initial, lastFlash.final = r['alphaInitial'], r['alphaEnd']

        local tg = Context.currentTimingGroup
        local used = 0
        for _, note in ipairs(notes) do
            local duration = note.endTiming - note.timing
            if duration > 1 then
                cmd.add(Event.scenecontrol(note.timing, 'groupalpha', tg, 1, initial).save())
                cmd.add(Event.scenecontrol(note.timing + 1, 'groupalpha', tg, duration - 1, final).save())
                cmd.add(note.delete())
                used = used + 1
            end
        end

        if used == 0 then
            notifyWarn('The long notes are too short (they need to be longer than 1ms).')
            return false
        end
    end
)

--------------------------------------------------------------------------------
-- FLASHING SC
-- Turns long notes into a flashing scenecontrol of any type you type in.
--------------------------------------------------------------------------------
local lastSC = { type = '', start = '0', finish = '0.0001' }

MacroNew(SPECIAL, 'flashingsc', 'Flashing SC', 'e3e7',
    function(cmd)
        local notes = selectedLongNotes()
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local r = Request.dialogRaw('Flashing Scenecontrol',
            DialogField.create('prerequisite')
                .description('Make sure the following Scenecontrol format are: \nscenecontrol(timing,type,duration,start/end);'),
            DialogField.create('type')
                .setLabel('Type')
                .setTooltip('The name of the Scenecontrol')
                .defaultTo(lastSC.type)
                .textField(FieldConstraint.create().any()),
            DialogField.create('startNum')
                .setLabel('Start Value')
                .setTooltip('Starting Flash')
                .defaultTo(lastSC.start)
                .textField(FieldConstraint.create().any()),
            DialogField.create('endNum')
                .setLabel('End Value')
                .setTooltip('Value at the End')
                .defaultTo(lastSC.finish)
                .textField(FieldConstraint.create().any()),
            DialogField.create('duration')
                .description('Duration are based of the selected Long Notes')
        )
        if not r then return false end

        local scType = r['type']
        local startValue, endValue = scValue(r['startNum']), scValue(r['endNum'])

        if not scType or scType == '' then
            notifyWarn('Please type the name of the Scenecontrol.')
            return false
        end
        if startValue == nil or endValue == nil then
            notifyWarn('Start and End must be numbers.')
            return false
        end
        lastSC.type, lastSC.start, lastSC.finish = scType, r['startNum'], r['endNum']

        local used = 0
        for _, note in ipairs(notes) do
            local duration = note.endTiming - note.timing - 1
            if duration > 0 then
                cmd.add(Event.scenecontrol(note.timing, scType, note.timingGroup, 1, startValue).save())
                cmd.add(Event.scenecontrol(note.timing + 1, scType, note.timingGroup, duration, endValue).save())
                cmd.add(note.delete())
                used = used + 1
            end
        end

        if used == 0 then
            notifyWarn('The long notes are too short (they need to be longer than 1ms).')
            return false
        end
    end
)

--------------------------------------------------------------------------------
-- TIMING DURATION (copies a duration to the clipboard)
--------------------------------------------------------------------------------
MacroNewNOCMD(SPECIAL, 'durationhold', 'Timing Duration', 'e51d',
    function()
        local tStart, tEnd = Request.timeRange()
        local duration = tEnd - tStart
        Context.systemClipboard = tostring(duration)
        notify('Copied duration: ' .. tostring(duration))
    end
)

--------------------------------------------------------------------------------
-- NOTE TRAILS
-- Makes faded copies of the selected notes, each one a bit later and more see-through.
-- Every trail goes in its own hidden timing group ($floony.trail.1, $floony.trail.2...)
-- with a groupalpha, and those groups are reused every time.
--------------------------------------------------------------------------------
local MIN_TRAILS, MAX_TRAILS = 2, 20   -- limits, so nobody types 1000 by accident
 
MacroNew(SPECIAL, 'floony.notetrails', 'Note Trails', 'e3a3',
    function(cmd)
        local notes = selectedNotes()
        if #notes == 0 then
            notifyWarn('Please select notes first.')
            return false
        end
 
        local r = Request.dialogRaw('Note Trails (' .. #notes .. ' notes)',
            DialogField.create('trailCount')
                .setLabel('Number of Trails')
                .setTooltip('Total number of copies (' .. MIN_TRAILS .. '-' .. MAX_TRAILS .. ')')
                .defaultTo('5')
                .textField(FieldConstraint.create().integer()),
            DialogField.create('trailDistance')
                .setLabel('Distance (ms)')
                .setTooltip('Time gap between each trail copy')
                .defaultTo('25')
                .textField(FieldConstraint.create().integer())
        )
        if not r then return false end
 
        local trailCount = math.clamp(math.floor(num(r, 'trailCount', 5)), MIN_TRAILS, MAX_TRAILS)
        local distance = num(r, 'trailDistance', 25)
 
        for trailIndex = 1, trailCount - 1 do
            local offset = distance * trailIndex
            local alpha = (1.0 - (trailIndex / trailCount)) * 255   -- later trails are more see-through
 
            -- The group of this trail (made once, then reused).
            local groupName = '$floony.trail.' .. trailIndex
            local group = findGroupByName(groupName)
            if not group then
                group = Event.createTimingGroup('name="' .. groupName .. '", noinput')
                cmd.add(group.save())
            end
 
            cmd.add(Event.scenecontrol(0.0, 'groupalpha,0', 0.0, alpha + 0.0).save().withTimingGroup(group))
 
            -- Copy the notes, moved later by `offset`.
            local arcCopies = {}   -- { from = original arc, to = its copy }, for the ArcTaps below
            for _, note in ipairs(notes) do
                if note.is('arc') or note.is('trace') then
                    local copy = note.copy()
                    copy.timing = note.timing + offset
                    copy.endTiming = note.endTiming + offset
                    cmd.add(copy.save().withTimingGroup(group))
                    arcCopies[#arcCopies + 1] = { from = note, to = copy }
 
                elseif note.is('tap') or note.is('hold') then
                    local copy = note.copy()
                    copy.timing = note.timing + offset
                    if note.is('hold') then copy.endTiming = note.endTiming + offset end
                    cmd.add(copy.save().withTimingGroup(group))
                end
            end
 
            -- ArcTaps go on the copy of their arc. (Skipped when their arc was not selected.)
            for _, note in ipairs(notes) do
                if note.is('arctap') and note.arc then
                    for _, pair in ipairs(arcCopies) do
                        if sameNote(pair.from, note.arc) then
                            cmd.add(Event.arctap(note.timing + offset, pair.to, note.width or 1).save().withTimingGroup(group))
                            break
                        end
                    end
                end
            end
        end
 
        cmd.setName('Note Trails (' .. (trailCount - 1) .. ')')
        notify('Created ' .. (trailCount - 1) .. ' trail(s).')
    end
)

--------------------------------------------------------------------------------
-- CAMERA
--------------------------------------------------------------------------------
local CAMERA = 'floony.camera'
FolderNew(SPECIAL, CAMERA, 'e439', '[Camera]')

-- The camera events of the current timing group inside a time range.
local function cameraEventsIn(tStart, tEnd, tg)
    local found = Event.query(
        EventSelectionConstraint.create().camera()
            .fromTiming(tStart).toTiming(tEnd).ofTimingGroup(tg))
    return found.camera or {}
end

-- Blank: turns each selected long note into an empty camera event of the same length.
MacroNew(CAMERA, 'cam_blank', 'Blank', 'e145',
    function(cmd)
        local notes = selectedLongNotes()
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local tg = Context.currentTimingGroup
        for _, note in ipairs(notes) do
            cmd.add(Event.camera(note.timing, 0, 0, 0, 0, 0, 0, 'l', note.endTiming - note.timing, tg).save())
            cmd.add(note.delete())
        end
    end
)

-- Repeat: copies the camera events of a time range based on repeat count.
MacroNew(CAMERA, 'cam_repeat', 'Repeat', 'e040',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local events = cameraEventsIn(tStart, tEnd, Context.currentTimingGroup)

        if #events == 0 then
            notifyWarn('No camera events detected.')
            return false
        end

        local r = Request.dialogRaw('Repeat',
            DialogField.create('cameraCount')
                .description(tostring(#events) .. ' camera events detected!'),
            DialogField.create('repeat')
                .setLabel('Count')
                .setTooltip('How many times should the selected camera events be repeated?')
                .defaultTo('1')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('mirror')
                .setLabel('Mirror')
                .setTooltip('Mirror the camera events')
                .checkbox(),
            DialogField.create('alternate')
                .setLabel('Alternate')
                .setTooltip('Alternate between original and mirrored camera events')
                .checkbox()
        )
        if not r then return false end

        local times = math.max(1, math.floor(num(r, 'repeat', 1)))
        local mirror, alternate = isOn(r['mirror']), isOn(r['alternate'])

        if not confirmBigJob(times * #events, 'camera events') then return false end
        
        for i = 1, times do
            -- Mirrored every time, or (with Alternate) only on every odd repeat.
            local flip = mirror or (alternate and i % 2 == 1)

            for _, event in ipairs(events) do
                local ev = event.copy()
                ev.timing = event.timing + i * (tEnd - tStart)
                if flip then mirrorCamera(ev) end
                cmd.add(ev.save())
            end
        end

        cmd.setName(string.format('Repeat camera x%d', times))
    end
)

-- Prerequisite for Bounce and Flick Camera
local POSITION_OPTIONS = {
    'None',
    'Xposition (Left [+] / Right [-])',
    'Yposition (Down [+] / Up [-])',
    'Zposition (Forward [+] / Backward [-])',
}
local ROTATION_OPTIONS = {
    'None',
    'Xrotation (Right [+] / Left [-])',
    'Yrotation (Down [+] / Up [-])',
    'Zrotation (Right [+] / Left [-])',
}
local ENABLE_DISABLE = { 'Disabled', 'Enabled' }

local POSITION_MOVES = {
    [2] = function(v) return v, 0, 0, 0, 0, 0 end,
    [3] = function(v) return 0, v, v, 0, 0, 0 end,
    [4] = function(v) return 0, 0, v, 0, 0, 0 end,
}
local ROTATION_MOVES = {
    [2] = function(v) return 0, 0, 0, v / 15, 0, 0 end,
    [3] = function(v) return 0, 0, 0, 0, v / 15, 0 end,
    [4] = function(v) return 0, 0, 0, 0, 0, v / 15 end,
}

local function addCameraMove(cmd, t, move, v, easing, duration, tg)
    local x, y, z, rx, ry, rz = move(v)
    cmd.add(Event.camera(t, x, y, z, rx, ry, rz, easing, duration, tg).save())
end

local function eachChosenMove(posIndex, rotIndex, fn)
    if POSITION_MOVES[posIndex] then fn(POSITION_MOVES[posIndex]) end
    if ROTATION_MOVES[rotIndex] then fn(ROTATION_MOVES[rotIndex]) end
end

--------------------------------------------------------------------------------
-- REGISTER SETTINGS: BOUNCE & FLICK
--------------------------------------------------------------------------------
registerSettings('Bounce Camera', {
    bounce_intensity = 1,
    bounce_pos = 'None',
    bounce_rot = 'None',
    bounce_alternate = false,
    bounce_reversed = false,
}, function(S)
    return {
        string.format('Intensity: %g', S.bounce_intensity or 1),
        string.format('Position: %s', S.bounce_pos or 'None'),
        string.format('Rotation: %s', S.bounce_rot or 'None'),
        'Alternating: ' .. string.richcolor(S.bounce_alternate and 'Enabled' or 'Disabled', Colors.status(S.bounce_alternate)),
        'Inverse Ease: ' .. string.richcolor(S.bounce_reversed and 'Enabled' or 'Disabled', Colors.status(S.bounce_reversed)),
    }
end)

registerSettings('Flick Camera', {
    flick_intensity = 1,
    flick_pos = 'None',
    flick_rot = 'None',
    flick_easing = 'qo',
    flick_alternate = false,
}, function(S)
    return {
        string.format('Intensity: %g', S.flick_intensity or 1),
        string.format('Position: %s', S.flick_pos or 'None'),
        string.format('Rotation: %s', S.flick_rot or 'None'),
        string.format('Easing: %s', S.flick_easing or 'qo'),
        'Alternating: ' .. string.richcolor(S.flick_alternate and 'Enabled' or 'Disabled', Colors.status(S.flick_alternate)),
    }
end)

--------------------------------------------------------------------------------
-- BOUNCE CAMERA MACRO
--------------------------------------------------------------------------------
MacroNew(CAMERA, 'cam_bounce', 'Bounce', 'e7d0',
    function(cmd)
        local notes = sortByTime(selectedLongNotes())
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local posList = defaultFirst(POSITION_OPTIONS, FloonySettings.bounce_pos)
        local rotList = defaultFirst(ROTATION_OPTIONS, FloonySettings.bounce_rot)
        local altList = defaultFirst(ENABLE_DISABLE, FloonySettings.bounce_alternate and 'Enabled' or 'Disabled')
        local revList = defaultFirst(ENABLE_DISABLE, FloonySettings.bounce_reversed and 'Enabled' or 'Disabled')

        local r = Request.dialogRaw('Bouncing Camera',
            DialogField.create('hintPos')
                .description('You can use negative intensity for Counter Position'),
            DialogField.create('intensity')
                .setLabel('intensity')
                .setTooltip('How strong the Bounce should be?')
                .defaultTo(tostring(FloonySettings.bounce_intensity))
                .textField(FieldConstraint.create().float()),
            DialogField.create('dir_pos')
                .setLabel('Bounce to (Position)')
                .setTooltip('At which Position should the camera goes?')
                .dropdownMenu(table.unpack(posList)),
            DialogField.create('dir_rot')
                .setLabel('Bounce to (Rotation)')
                .setTooltip('At which Rotation should the camera goes?')
                .dropdownMenu(table.unpack(rotList)),
            DialogField.create('alternate')
                .setLabel('Alternating')
                .setTooltip('Whether the Camera alternates back and forth.')
                .dropdownMenu(table.unpack(altList)),
            DialogField.create('reversed')
                .setLabel('Inverse Ease')
                .setTooltip('Whether the Easing is inverted (qo, qi into qi, qo).')
                .dropdownMenu(table.unpack(revList))
        )
        if not r then return false end

        -- Process dropdown choices
        local posChoice = posList[choiceIndex(r['dir_pos'], posList)]
        local rotChoice = rotList[choiceIndex(r['dir_rot'], rotList)]
        local altChoice = altList[choiceIndex(r['alternate'], altList)]
        local revChoice = revList[choiceIndex(r['reversed'], revList)]

        -- Store persistent boolean & string settings
        FloonySettings.bounce_intensity = num(r, 'intensity', FloonySettings.bounce_intensity)
        FloonySettings.bounce_pos = posChoice
        FloonySettings.bounce_rot = rotChoice
        FloonySettings.bounce_alternate = (altChoice == 'Enabled')
        FloonySettings.bounce_reversed = (revChoice == 'Enabled')

        if saveSettings then saveSettings() end

        local posIndex = choiceIndex(posChoice, POSITION_OPTIONS)
        local rotIndex = choiceIndex(rotChoice, ROTATION_OPTIONS)

        if posIndex == 1 and rotIndex == 1 then
            notifyWarn('Specify at least one direction / Position')
            return false
        end

        local strength = FloonySettings.bounce_intensity * 50
        local out, back = 'qo', 'qi'
        if FloonySettings.bounce_reversed then out, back = 'qi', 'qo' end
        local alternate = FloonySettings.bounce_alternate
        local tg = Context.currentTimingGroup

        for index, note in ipairs(notes) do
            local v = strength
            if alternate and index % 2 == 0 then v = -v end

            local half = (note.endTiming - note.timing) / 2
            eachChosenMove(posIndex, rotIndex, function(move)
                addCameraMove(cmd, note.timing, move, v, out, half, tg)
                addCameraMove(cmd, note.timing + half, move, -v, back, half, tg)
            end)
            cmd.add(note.delete())
        end
        cmd.setName('Bounce Camera')
    end
)

--------------------------------------------------------------------------------
-- FLICK CAMERA MACRO
--------------------------------------------------------------------------------
local FLICK_EASINGS = { 'qo', 'l', 'qi', 's' }

MacroNew(CAMERA, 'cam_flick', 'Flick/Flash', 'e3e7',
    function(cmd)
        local notes = sortByTime(selectedLongNotes())
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end

        local posList = defaultFirst(POSITION_OPTIONS, FloonySettings.flick_pos)
        local rotList = defaultFirst(ROTATION_OPTIONS, FloonySettings.flick_rot)
        local easingList = defaultFirst(FLICK_EASINGS, FloonySettings.flick_easing)
        local altList = defaultFirst(ENABLE_DISABLE, FloonySettings.flick_alternate and 'Enabled' or 'Disabled')

        local r = Request.dialogRaw('Flicking Camera',
            DialogField.create('hintPos')
                .description('You can use negative intensity for Counter Position'),
            DialogField.create('intensity')
                .setLabel('intensity')
                .setTooltip('How strong the Flick should be?')
                .defaultTo(tostring(FloonySettings.flick_intensity))
                .textField(FieldConstraint.create().float()),
            DialogField.create('dir_pos')
                .setLabel('Flick to (Position)')
                .setTooltip('At which Position should the camera goes?')
                .dropdownMenu(table.unpack(posList)),
            DialogField.create('dir_rot')
                .setLabel('Flick to (Rotation)')
                .setTooltip('At which Rotation should the camera goes?')
                .dropdownMenu(table.unpack(rotList)),
            DialogField.create('easing')
                .setLabel('Easing')
                .setTooltip('The easing to use')
                .dropdownMenu(table.unpack(easingList)),
            DialogField.create('alternate')
                .setLabel('Alternating')
                .setTooltip('Whether the Camera alternates back and forth.')
                .dropdownMenu(table.unpack(altList))
        )
        if not r then return false end

        -- Process dropdown choices
        local posChoice = posList[choiceIndex(r['dir_pos'], posList)]
        local rotChoice = rotList[choiceIndex(r['dir_rot'], rotList)]
        local easingChoice = easingList[choiceIndex(r['easing'], easingList)]
        local altChoice = altList[choiceIndex(r['alternate'], altList)]

        -- Store persistent boolean & string settings
        FloonySettings.flick_intensity = num(r, 'intensity', FloonySettings.flick_intensity)
        FloonySettings.flick_pos = posChoice
        FloonySettings.flick_rot = rotChoice
        FloonySettings.flick_easing = easingChoice
        FloonySettings.flick_alternate = (altChoice == 'Enabled')

        if saveSettings then saveSettings() end

        local posIndex = choiceIndex(posChoice, POSITION_OPTIONS)
        local rotIndex = choiceIndex(rotChoice, ROTATION_OPTIONS)

        if posIndex == 1 and rotIndex == 1 then
            notifyWarn('Specify at least one direction / Position')
            return false
        end

        local strength = FloonySettings.flick_intensity * 50
        local alternate = FloonySettings.flick_alternate
        local tg = Context.currentTimingGroup

        for index, note in ipairs(notes) do
            local v = strength
            if alternate and index % 2 == 0 then v = -v end

            local duration = math.max(1, note.endTiming - note.timing - 1)
            eachChosenMove(posIndex, rotIndex, function(move)
                addCameraMove(cmd, note.timing, move, v, 'l', 1, tg)                  -- jump out
                addCameraMove(cmd, note.timing + 1, move, -v, easingChoice, duration, tg)  -- ease back
            end)
            cmd.add(note.delete())
        end
        cmd.setName('Flick Camera')
    end
)

-- Arc to Camera: each arc becomes a camera move. The arc's color decides what moves:
--   blue = x and y | red = z and sideways tilt | green = rx and ry
-- A trace also resets the camera first.
local ARC_TO_CAMERA_EASING = { si = 'qo', sisi = 'qo', so = 'qi', soso = 'qi', b = 's' }

MacroNew(CAMERA, 'arc2cam', 'Arc to Camera', 'e41e',
    function(cmd)
        local arcs = selectedNotes('arc')
        if #arcs == 0 then
            notifyWarn('Select at least one arc.')
            return false
        end

        local tg = Context.currentTimingGroup

        for _, arc in ipairs(arcs) do
            local duration = arc.endTiming - arc.timing
            local dx, dy = arc.endX - arc.startX, arc.endY - arc.startY
            local easing = ARC_TO_CAMERA_EASING[arc.type] or 'l'

            if arc.isVoid then
                cmd.add(Event.camera(arc.timing, 0, 0, 0, 0, 0, 0, 'reset', 0, tg).save())
            end

            if arc.color == 0 then          -- blue
                cmd.add(Event.camera(arc.timing, dx * 850, dy * 450, 0, 0, 0, 0, easing, duration, tg).save())
            elseif arc.color == 1 then      -- red
                cmd.add(Event.camera(arc.timing, 0, 0, dy * 200, 0, 0, dx * 180 / 4, easing, duration, tg).save())
            else                            -- green
                cmd.add(Event.camera(arc.timing, 0, 0, 0, dx * 180 / 4, dy * 360 / 12, 0, easing, duration, tg).save())
            end

            cmd.add(arc.delete())
        end
    end
)

-- Camera to Arc: the opposite. Camera moves become arcs (blue, red and green, like above).
local CAMERA_TO_ARC_TYPE = { qo = 'si', qi = 'so', s = 'b' }

MacroNew(CAMERA, 'cam2arc', 'Camera to Arc', 'e41f',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local cameras = cameraEventsIn(tStart, tEnd, tg)

        if #cameras == 0 then
            notifyWarn('No camera events detected.')
            return false
        end

        local r = Request.dialogRaw('Camera to Arc Options',
            DialogField.create('cameraCount')
                .description(tostring(#cameras) .. ' camera events detected!'),
            DialogField.create('keepCamera')
                .setLabel('Keep Camera')
                .setTooltip('Keep camera events after conversion')
                .checkbox()
        )
        if not r then return false end
        local keepCamera = isOn(r['keepCamera'])

        sortByTime(cameras)

        -- Where each color's arc currently is, so the next arc continues from there.
        local position = { [0] = xy(0.5, 0), [1] = xy(0.5, 0), [2] = xy(0.5, 0) }
        local home = xy(0.5, 0)

        -- Adds one arc from the color's current position, moved by (dx, dy).
        local function addMove(cam, color, endTime, arcType, dx, dy)
            local from = position[color]
            local to = xy(from.x + dx, from.y + dy)
            cmd.add(Event.arc(cam.timing, from, endTime, to, false, color, arcType, tg).save())
            position[color] = to
        end

        for _, cam in ipairs(cameras) do
            local endTime = cam.timing + cam.duration
            local arcType = CAMERA_TO_ARC_TYPE[cam.type] or 's'
            local made = false

            if cam.type == 'reset' then
                cmd.add(Event.arc(cam.timing, home, endTime, home, false, 0, arcType, tg).save())
                made = true
            else
                if cam.x ~= 0 or cam.y ~= 0 then       -- blue
                    addMove(cam, 0, endTime, arcType, cam.x / 850, cam.y / 450)
                    made = true
                end
                if cam.z ~= 0 or cam.rz ~= 0 then      -- red
                    addMove(cam, 1, endTime, arcType, cam.rz / 45, cam.z / 200)
                    made = true
                end
                if cam.rx ~= 0 or cam.ry ~= 0 then     -- green
                    addMove(cam, 2, endTime, arcType, cam.rx / 45, cam.ry / 30)
                    made = true
                end
            end

            -- A camera event that moves nothing still becomes a still blue arc, so the time is kept.
            if not made then
                cmd.add(Event.arc(cam.timing, home, endTime, home, false, 0, arcType, tg).save())
            end

            if not keepCamera then
                cmd.add(cam.delete())
            end
        end
    end
)

FolderNew(CAMERA, 'floony.camerastash', 'e1a1', 'Camera Stash')
buildStashFolder('floony.camerastash', 'cam_stashcreate', 'camera', 'camera events', true)

--------------------------------------------------------------------------------
-- SPIRAL TRACE
-- Draws a spiral of traces (like the intro of Arghena). The spiral lives in a hidden timing
-- group ($floony.spiral) whose BPM changes, so it seems to move toward or away from you.
--------------------------------------------------------------------------------
MacroNew(SPECIAL, 'floony.spiraltrace', 'Spiral Trace', 'e577',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local center = Request.position(tEnd, 'Select the center of the spiral')
        local duration = tEnd - tStart

        if duration <= 0 then
            notifyWarn('The time range has no length.')
            return false
        end

        local baseBpm = Context.baseBpm

        local r = Request.dialogRaw('Spiral Trace',
            DialogField.create('division')
                .setLabel('Division')
                .setTooltip('How many timings should be created?')
                .defaultTo(tostring(math.floor(Context.beatlineDensity * 2)))
                .textField(FieldConstraint.create().integer().gEqual(2)),
            DialogField.create('startBpm')
                .setLabel('Start BPM')
                .setTooltip('The BPM at the start of the timing')
                .defaultTo(tostring(baseBpm / 2))
                .textField(FieldConstraint.create().any()),
            DialogField.create('endBpm')
                .setLabel('End BPM')
                .setTooltip('The BPM at the end of the timing')
                .defaultTo(tostring(baseBpm / 2 + baseBpm * 1.5))
                .textField(FieldConstraint.create().any()),
            DialogField.create('tracegen')
                .setLabel('Trace Count')
                .setTooltip('How many traces are generated? (1 - 360)')
                .defaultTo('8')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('outwardTrue')
                .setLabel('Outward')
                .setTooltip('Make the spiral expand outward')
                .checkbox()
        )
        if not r then return false end

        local divisor  = math.max(2, math.floor(num(r, 'division', Context.beatlineDensity * 2)))
        local startBpm = expr(r, 'startBpm', baseBpm / 2)
        local endBpm   = expr(r, 'endBpm', baseBpm / 2 + baseBpm * 1.5)
        local traces   = math.clamp(math.floor(num(r, 'tracegen', 8)), 1, 360)
        local outward  = isOn(r['outwardTrue'])

        -- How long one step of the spiral is, and a safety check on how many events that makes.
        local step = 60000 / baseBpm / divisor
        local estimate = math.ceil(duration / step) * traces
        if not confirmBigJob(estimate, 'traces') then return false end

        -- The hidden group: reuse a $floony.spiral group that has no timing events in the way,
        -- or make a new one.
        local group = nil
        for i = 1, Context.timingGroupCount - 1 do
            local candidate = Event.getTimingGroup(i)
            if candidate.name == '$floony.spiral' then
                local inTheWay = Event.query(
                    EventSelectionConstraint.create().timing()
                        .fromTiming(tStart - 1).toTiming(tEnd).ofTimingGroup(candidate.num)
                ).timing
                if #inTheWay == 0 then
                    group = candidate
                    break
                end
            end
        end
        if not group then
            group = Event.createTimingGroup('name="$floony.spiral"')
            cmd.add(group.save())
        end

        -- The BPM changes that make the spiral move.
        local bpmStep = duration / (divisor - 1)
        for index = 0, divisor - 1 do
            local t = math.floor(tStart + bpmStep * index)
            local bpm = math.lerp(startBpm, endBpm, index / (divisor - 1))
            cmd.add(Event.timing(t, bpm, 999, Context.currentTimingGroup).save().withTimingGroup(group))
        end

        -- A point on the spiral: `angle` degrees around the center, `offset` away from it.
        local function spiralPoint(angle, offset)
            local rad = math.rad(angle)
            return offset * math.sin(rad) + center.x, offset * 1.888 * math.cos(rad) + center.y
        end

        -- One trace piece. Parts below the floor (y < -0.22) are cut off.
        local FLOOR = -0.22
        local function addPiece(t1, t2, angle1, angle2, offset1, offset2)
            local x1, y1 = spiralPoint(angle1, offset1)
            local x2, y2 = spiralPoint(angle2, offset2)

            if y1 < FLOOR and y2 < FLOOR then return end   -- completely below the floor

            if not (y1 > FLOOR and y2 > FLOOR) then
                -- It crosses the floor: shorten it so it ends exactly on the floor.
                local p = (FLOOR - y1) / (y2 - y1)
                if y1 < y2 then
                    t1 = math.lerp(t1, t2, p)
                    x1 = math.lerp(x1, x2, p)
                    y1 = math.lerp(y1, y2, p)
                else
                    t2 = math.lerp(t1, t2, p)
                    x2 = math.lerp(x1, x2, p)
                    y2 = math.lerp(y1, y2, p)
                end
            end

            cmd.add(Event.arc(math.floor(t1), xy(x1, y1), math.floor(t2), xy(x2, y2), true, 0, 's', 0)
                .save().withTimingGroup(group))
        end

        local angleStep = 360 / traces
        local t = 0
        while t < duration do
            local nextT = math.min(t + step, duration)
            local p = math.floor(t) / duration
            local np = math.floor(nextT) / duration

            local offset1, offset2
            if outward then
                offset1, offset2 = math.lerp(4, -0.1, 1 - p), math.lerp(4, -0.1, 1 - np)
            else
                offset1, offset2 = math.lerp(-0.1, 4, 1 - p), math.lerp(-0.1, 4, 1 - np)
            end

            for i = 0, traces - 1 do
                local delta = i * angleStep
                addPiece(math.floor(t) + tStart, math.floor(nextT) + tStart,
                    360 * p + delta, 360 * np + delta, offset1, offset2)
            end

            t = t + step
        end

        cmd.setName('Spiral Trace')
    end
)

--------------------------------------------------------------------------------
-- AUTO-QUANTIZE
-- Moves the notes of a time range onto the nearest beat line.
--------------------------------------------------------------------------------
local quantizeWarned = false

MacroNew(SPECIAL, 'autoquantize', 'Auto-Quantize', 'e863',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local notes = table.icollapse(
            Event.query(CustomConstraints.timeRange(tStart, tEnd)), 'arc', 'tap', 'hold', 'arctap')

        if #notes == 0 then
            notifyWarn('No notes found in the selected time range.')
            return false
        end

        if not quantizeWarned then
            dialogNotifyCustom('WARNING',
                'Notes snap to the beat lines of their own timing group.\nCheck the result where the BPM changes.\nProceed?')
            quantizeWarned = true
        end

        -- One beat grid per timing group, built the first time it is needed.
        local grids = {}
        local function snap(tg, t)
            local grid = grids[tg]
            if not grid then
                grid = BeatGrid.new(tg)
                grids[tg] = grid
            end
            return grid:snapMs(t)
        end

        -- First the arcs, taps and holds. For arcs we remember their new time range,
        -- so their ArcTaps can be kept inside it afterwards.
        local arcRanges = {}   -- { arc = the arc, first = new start, last = new end }

        for _, event in ipairs(notes) do
            if not event.is('arctap') then
                local tg = event.timingGroup or 0
                local newStart = snap(tg, event.timing)
                event.timing = newStart

                if event.is 'long' then
                    local newEnd = snap(tg, event.endTiming)
                    if newEnd < newStart then newEnd = newStart end
                    event.endTiming = newEnd

                    if event.is 'arc' then
                        arcRanges[#arcRanges + 1] = { arc = event, first = newStart, last = newEnd }
                    end
                end
                cmd.add(event.save())
            end
        end

        -- Then the ArcTaps.
        for _, tap in ipairs(notes) do
            if tap.is('arctap') then
                local newTime = snap(groupOf(tap), tap.timing)

                local parent = tap.arc
                if parent then
                    local first, last = parent.timing, parent.endTiming
                    for _, range in ipairs(arcRanges) do
                        if sameNote(range.arc, parent) then
                            first, last = range.first, range.last
                            break
                        end
                    end
                    newTime = math.max(first, math.min(last, newTime))
                end

                tap.timing = newTime
                cmd.add(tap.save())
            end
        end

        cmd.setName(string.format('Auto-Quantize (%d notes)', #notes))
    end
)

--------------------------------------------------------------------------------
-- OFFSET BY BPM
-- Stretches or squeezes the selected notes in time, as if the BPM changed to a target BPM.
-- The first selected note stays where it is.
-- Every note keeps its place in BEATS. The beats are counted with the real BPM of the note's
-- timing group (so BPM changes inside the selection are handled), then laid out again at the target BPM.
-- If you change 'Original BPM' by hand, a simple ratio (original / target) is used instead.
--------------------------------------------------------------------------------
MacroNew(SPECIAL, 'floony.offsetbpm', 'Offset by BPM', 'ebe7',
    function(cmd)
        local notes = selectedNotes()
        if #notes == 0 then
            notifyWarn('Please select at least one note.')
            return false
        end

        -- The first note of the selection is the anchor that stays still.
        local firstNote = notes[1]
        for _, note in ipairs(notes) do
            if note.timing < firstNote.timing then firstNote = note end
        end
        local anchor = firstNote.timing

        local detected = Context.bpmAt(anchor, groupOf(firstNote))
        if not detected or detected <= 0 then
            detected = Context.baseBpm or 120
        end

        local r = Request.dialogRaw('Offset by BPM',
            DialogField.create('info')
                .description('Rescales selected note timings relative to the start of selection (' .. math.floor(anchor) .. 'ms).\n' ..
                             'Leave Original BPM as it is to follow the real BPM (also where it changes).'),
            DialogField.create('oribpm')
                .setLabel('Original BPM')
                .setTooltip('The starting BPM for this section. Change it only to use a simple ratio instead.')
                .defaultTo(tostring(detected))
                .textField(FieldConstraint.create().float().greater(0)),
            DialogField.create('targetbpm')
                .setLabel('Target BPM')
                .setTooltip('The desired BPM to convert this section to')
                .defaultTo(tostring(detected))
                .textField(FieldConstraint.create().float().greater(0))
        )
        if not r then return false end

        local originalBpm, targetBpm = tonumber(r['oribpm']), tonumber(r['targetbpm'])
        if not originalBpm or originalBpm <= 0 then
            notifyWarn('Please enter a valid positive Original BPM.')
            return false
        end
        if not targetBpm or targetBpm <= 0 then
            notifyWarn('Please enter a valid positive Target BPM.')
            return false
        end

        local followRealBpm = math.abs(originalBpm - detected) < 0.0001
        local ratio = originalBpm / targetBpm

        local grids = {}
        local function newTime(tg, t)
            if not followRealBpm then
                return math.round(anchor + (t - anchor) * ratio)
            end
            local grid = grids[tg]
            if not grid then
                grid = BeatGrid.new(tg)
                grids[tg] = grid
            end
            return math.round(anchor + grid:beatsBetween(anchor, t) * 60000 / targetBpm)
        end

        for _, note in ipairs(notes) do
            local tg = groupOf(note)
            note.timing = newTime(tg, note.timing)
            if note.is 'long' then
                note.endTiming = newTime(tg, note.endTiming)
            end
            cmd.add(note.save())
        end

        cmd.setName(string.format('Offset by BPM (%s to %s)', tostring(originalBpm), tostring(targetBpm)))
        notify(string.format('Rescaled %d notes (%s -> %s BPM).', #notes, tostring(originalBpm), tostring(targetBpm)))
    end
)


--------------------------------------------------------------------------------
-- COPY TIMING GROUP
-- Makes a new timing group with the same timing events as the current one.
--------------------------------------------------------------------------------
MacroNew(SPECIAL, 'copytg', 'Copy Timing Group', 'e14d',
    function(cmd)
        local events = Event.query(
            EventSelectionConstraint.create().ofTimingGroup(Context.currentTimingGroup).timing()
        ).timing or {}

        if #events == 0 then
            notifyWarn('The current timing group has no timing events.')
            return false
        end
        sortByTime(events)

        local group = Event.createTimingGroup('')
        cmd.add(group.save())

        -- The first event is the group's own starting event, so it is not copied (same as before).
        for i = 2, #events do
            local e = events[i]
            cmd.add(Event.timing(e.timing, e.bpm, e.divisor).save().withTimingGroup(group))
        end

        cmd.setName('Duplicate Timing Group')
    end
)

--------------------------------------------------------------------------------
-- STREAM PLACEMENT
-- Draws a 1ms colored arc at every selected tap/hold/ArcTap, alternating blue and red,
-- to show which hand plays it (blue = left, red = right). The arcs go into a timing group
-- called Stream_TEMP, which is reused.
--------------------------------------------------------------------------------
local PLACEMENT = 'floony.placement'
FolderNew(SPECIAL, PLACEMENT, 'ebb9', '[Stream Placement]')

local placementWarned = false

local function placementMacro(startColor)
    return function(cmd)
        local notes = selectedNotes('tap', 'hold', 'arctap')
        if #notes < 2 then
            notifyWarn('Please select at least two notes.')
            return false
        end

        if not placementWarned then
            dialogNotifyCustom('WARNING', 'Placement cues will be generated in a "Stream_TEMP" timing group.\nProceed?')
            placementWarned = true
        end

        local group = findGroupByName('Stream_TEMP')
        if not group then
            group = Event.createTimingGroup('name="Stream_TEMP"')
            cmd.add(group.save())
        end

        local color = startColor
        for _, note in ipairs(sortByTime(notes)) do
            local position
            if note.is('arctap') then
                position = note.arc.positionAt(note.timing)
            else
                position = xy(note.lane / 2 - 0.75, 0)   -- the middle of the lane, on the ground
            end

            cmd.add(Event.arc(note.timing, position, note.timing, position, false, color, 's', note.timingGroup)
                .save().withTimingGroup(group))

            color = 1 - color   -- the other hand next
        end
    end
end

MacroNew(PLACEMENT, 'bluefirst', 'Left Hand First', 'eb59', placementMacro(0))
MacroNew(PLACEMENT, 'redfirst', 'Right Hand First', 'eb52', placementMacro(1))

--------------------------------------------------------------------------------
-- HELP
-- One line per macro. To list a new macro here, add one line to HELP or CAMERA_HELP.
--------------------------------------------------------------------------------

-- { id, name, what it does }
local HELP = {
    { 'floony.arctap_linker', 'Link / Unlink ArcTaps', 'Select 2+ ArcTaps to link them with a trace. Select 1 ArcTap, or arcs with ArcTaps, to unlink them onto their own point traces.' },
    { 'floony.convert2trace', 'Notes to Trace', 'Convert the selected taps, holds and arcs into traces in one go (ArcTaps too, if enabled in its Settings)' },
    { 'floony.convert2shadow', 'Notes to Shadow', "Convert notes into shadow notes (will generate a new tg with 'noinput' property)" },
    { 'floony.timingstash', 'Timing Stash', 'Save Timing for further use' },
    { 'floony.taptosc', 'Tap to Hidegroup', 'Convert Tap into Hidegroup (Alternating)' },
    { 'floony.holdtoalpha', 'Hold to Groupalpha', 'Convert Hold into Groupalpha (Normal, Flash)' },
    { 'flashingsc', 'Flashing SC', 'Convert Long Notes into Flashing / Pulsing Scenecontrol' },
    { 'floony.notetrails', 'Note Trails', 'Make faded copies of the selected notes, each one a bit later' },
    { 'durationhold', 'Timing Duration', 'Copy the length of a time range (in ms) to the clipboard' },
    { 'floony.spiraltrace', 'Spiral Trace', 'Make a spiral trace, as seen on Arghena Intro' },
    { 'autoquantize', 'Auto-Quantize', 'Corrects the note placement on the beatline (Not always accurate)' },
    { 'floony.offsetbpm', 'Offset by BPM', 'Offset the selected notes by BPM (Not fully accurate)' },
    { 'copytg', 'Copy Timing Group', 'Generate a new timing group containing all timing events from Selected Group' },
    { 'floony.placement', 'Stream Placement', 'Generate 1ms colored arcs to indicate finger placement (Blue=Left Red=Right)' },
}

local CAMERA_HELP = {
    { 'cam_blank', 'Blank', 'Create a Blank Camera' },
    { 'cam_repeat', 'Repeat', 'Repeat the selected Camera (Alternate, Mirror option available)' },
    { 'cam_bounce', 'Bounce', 'Create a Camera(s) that gives the impression of bouncing (Using the middle timing point)' },
    { 'cam_flick', 'Flick/Flash', 'Create a Camera(s) that gives the impression of flicking' },
    { 'arc2cam', 'Arc to Camera', 'Convert Arc(s) into Camera(s)\nHint:\n'
        .. '<color=#19A0EBD9>Blue arc</color>: x, y -> transverse, bottomzoom\n'
        .. '<color=#F0699BD9>Red arc</color>: x, y -> angle, linezoom\n'
        .. '<color=#28C81ED9>Green arc</color>: x, y -> steadyangle, topzoom\n' },
    { 'cam2arc', 'Camera to Arc', 'Convert Camera(s) back into Arcs' },
    { 'floony.camerastash', 'Camera Stash', 'Stashes the camera(s) events for Future uses (Mirror option available)' },
}

-- One entry of the help text: name, id and a description.
local function helpEntry(id, name, text)
    return string.format(' - <b>%s</b> <size=8>(%s)</size>\n%s', name, id, text)
end

MacroNewNOCMD(SPECIAL, 'spinfo', 'Help', 'e8fd',
    function()
        local fields = {}

        for i, entry in ipairs(HELP) do
            fields[#fields + 1] = DialogField.create('help' .. i)
                .description(helpEntry(entry[1], entry[2], entry[3]))
        end

        fields[#fields + 1] = DialogField.create('border').description('\n')

        -- The camera heading is shifted to the right so it looks centered.
        local padding = string.rep(' ', 25 - #'Camera Category')
        fields[#fields + 1] = DialogField.create('camera')
            .description(string.format('%s<size=15><b>%s</b></size> <size=8>(%s)</size>',
                padding, 'Camera Category', CAMERA))

        for i, entry in ipairs(CAMERA_HELP) do
            fields[#fields + 1] = DialogField.create('camhelp' .. i)
                .description(helpEntry(entry[1], entry[2], entry[3]))
        end

        Request.dialogRaw('Help - Special', table.unpack(fields))
    end,
    true
)