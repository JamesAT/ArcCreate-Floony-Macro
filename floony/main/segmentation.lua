require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // ARCS SEGMENTATION // --       |
------------------------------------/
-- Two groups of macros:
--   [Split]    cuts ONE arc into many small pieces (Normal, Chunky, Rice...).
--   [Generate] combines TWO arcs into zig-zags, waves and lines.

local ROOT  = 'floony.segmentation'
local SPLIT = 'floony.segmentation.split'
local GEN   = 'segmentation.generate'   -- no 'floony.' in front on purpose: it is the old id

FolderNew('floony', ROOT, 'e1a0', '- Arcs Segmentation -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - SEGMENTATION
--------------------------------------------------------------------------------

-- Moves a point down by 0.01. This tiny nudge is what makes the height line show up.
-- Points on the ground (y = 0) have no height line, so they are left alone.
local function nudgeDown(p)
    if p.y > 0 then return p + xy(0, -0.01) end
    return p
end
 
-- How many pieces one arc is cut into.
local function sliceCount(arc)
    local length = arc.endTiming - arc.timing
    if length <= 0 then return 0 end
    local step = arcSliceLength(arc)
    if not step or step <= 0 then return 1 end
    return math.ceil(length / step)
end
 
-- Returns true when the macro should NOT go on: the job is big and the user said no
-- (confirmBigJob asks first when a job is big, and refuses when it is far too big).
-- `perSlice` is how many events the macro makes for each piece (use the highest it can be).
local function tooBig(arcs, perSlice)
    local total = 0
    for _, arc in ipairs(arcs) do
        total = total + sliceCount(arc) * perSlice
    end
    return not confirmBigJob(total, 'events')
end
 
-- Counts the ArcTaps that sit on the given arcs.
-- Splitting deletes the original arc, and its ArcTaps are not copied to the new pieces.
local function countArcTapsOn(arcs)
    local ok, count = pcall(function()
        local first, last = math.huge, -math.huge
        for _, a in ipairs(arcs) do
            first = math.min(first, a.timing)
            last = math.max(last, a.endTiming)
        end
 
        local taps = table.icollapse(Event.query(CustomConstraints.timeRange(first, last)), 'arctap')
        local n = 0
        for _, tap in ipairs(taps) do
            for _, a in ipairs(arcs) do
                if sameArc(tap.arc, a) then
                    n = n + 1
                    break
                end
            end
        end
        return n
    end)
    return ok and count or 0
end
 
-- A straight piece/slice of arc that copies the look of `arc` (void, color, timing group, sfx, resolution).
local function piece(arc, t1, p1, t2, p2)
    return Event.arc(t1, p1, t2, p2,
        arc.isVoid, arc.color, 's', arc.timingGroup, arc.sfx, arc.arcResolutionMultiplier)
end

--------------------------------------------------------------------------------
-- SETTINGS
-- The values live in FloonySettings, so every module sees the same ones:
--   forceHeightLines : nudge pieces by 0.01 so height lines show up
--   stasis           : 1 = Off, 2 = hide every 2nd piece, 3 = make every 2nd piece a trace
--   riceMultiplier   : length of "Rice" pieces compared to a full piece (0.01 to 1.0)
--   forceSEasing     : force all generated arcs to use straight (s) easing
--------------------------------------------------------------------------------
local ON_OFF = { 'Off', 'On' }
local STASIS_OPTIONS = { 'Off', 'Hide every 2nd segment', 'Make every 2nd segment a trace' }

if registerSettings then
    registerSettings('Segmentation',
        { forceHeightLines = false, stasis = 1, riceMultiplier = 0.5, forceSEasing = false },
        function(S)
            return {
                'Force height lines: ' .. string.richcolor(S.forceHeightLines and 'On' or 'Off', Colors.status(S.forceHeightLines)),
                'Stasis mode: ' .. (STASIS_OPTIONS[S.stasis] or STASIS_OPTIONS[1]),
                string.format('Rice multiplier: %.2f', S.riceMultiplier),
                'Force S Easing: ' .. string.richcolor(S.forceSEasing and 'On' or 'Off', Colors.status(S.forceSEasing)),
            }
        end)
end

local function statusText()
    local S = FloonySettings
    return string.format(
        '<b>Current Settings:</b>\nForce Height Lines: %s\nStasis Mode: %s\nRice Multiplier: %.2f\nForce S Easing: %s',
        string.richcolor(S.forceHeightLines and 'On' or 'Off', Colors.status(S.forceHeightLines)),
        STASIS_OPTIONS[S.stasis] or STASIS_OPTIONS[1],
        S.riceMultiplier,
        string.richcolor(S.forceSEasing and 'On' or 'Off', Colors.status(S.forceSEasing))
    )
end

local function updateSettings()
    local S = FloonySettings

    -- Dynamically place currently active choices at first option
    local forceOptions  = S.forceHeightLines and { 'On', 'Off' } or { 'Off', 'On' }
    local forcesOptions = S.forceSEasing and { 'On', 'Off' } or { 'Off', 'On' }

    local currentStasis = S.stasis or 1
    local stasisOptions = { STASIS_OPTIONS[currentStasis] or STASIS_OPTIONS[1] }
    local stasisKeys    = { currentStasis }

    for idx, name in ipairs(STASIS_OPTIONS) do
        if idx ~= currentStasis then
            stasisOptions[#stasisOptions + 1] = name
            stasisKeys[#stasisKeys + 1]       = idx
        end
    end

    local r = Request.dialogRaw('Segmentation Settings',
        DialogField.create('force')
            .setLabel('Force\nHeight Lines')
            .setTooltip('Forces height lines to show up on split arcs using tiny height offsets.')
            .defaultTo(forceOptions[1])
            .dropdownMenu(table.unpack(forceOptions)),

        DialogField.create('stasis')
            .setLabel('Stasis Mode')
            .setTooltip('Off | Hide every 2nd piece | Turn every 2nd piece into a trace.')
            .defaultTo(stasisOptions[1])
            .dropdownMenu(table.unpack(stasisOptions)),

        DialogField.create('ricemult')
            .setLabel('Rice Multiplier')
            .setTooltip('Length of rice pieces compared to a full piece (0.01 to 1.0).')
            .defaultTo(tostring(S.riceMultiplier))
            .textField(FieldConstraint.create().float().greater(0).lEqual(1)),

        DialogField.create('forces')
            .setLabel('Force S Easing')
            .setTooltip('Forces all generated arcs to use straight (s) easing.')
            .defaultTo(forcesOptions[1])
            .dropdownMenu(table.unpack(forcesOptions)),

        DialogField.create('info')
            .description(statusText())
    )
    if not r then return end

    local forceChoice  = forceOptions[choiceIndex(r['force'], forceOptions)]
    local stasisChoice = choiceIndex(r['stasis'], stasisOptions)
    local forcesChoice = forcesOptions[choiceIndex(r['forces'], forcesOptions)]

    S.forceHeightLines = (forceChoice == 'On')
    S.stasis           = stasisKeys[stasisChoice] or 1
    S.riceMultiplier   = math.clamp(tonumber(r['ricemult']) or S.riceMultiplier, 0.01, 1)
    S.forceSEasing     = (forcesChoice == 'On')
    
    saveSettings()

    notify(statusText())
end

--------------------------------------------------------------------------------
-- SPLIT: cutting ONE arc into many pieces
--------------------------------------------------------------------------------
-- Every split style is a small function:  makePieces(arc, s, e, spos, epos) -> list of arcs
--   s / e       = start and end time of this piece of the arc
--   spos / epos = where the arc is at those times

-- Writes the pieces of one arc into `cmd`. Returns how many pieces were written.
local function writePieces(arc, makePieces, alwaysNudge, cmd)
    local S = FloonySettings
    local nudge = S.forceHeightLines or alwaysNudge
    local written = 0
    local index = 1   -- counts every piece it make (used for "every 2nd")

    for s, e in bestDivisions(arc.timing, arc.endTiming, arcSliceLength(arc)) do
        local pieces = makePieces(arc, s, e, arc.positionAt(s), arc.positionAt(e))

        for _, p in ipairs(pieces) do
            local isEverySecond = (index % 2 == 0)

            -- Height lines: nudge the start of every 2nd piece and the end of the others.
            if nudge then
                if isEverySecond then
                    p.startXY = nudgeDown(p.startXY)
                else
                    p.endXY = nudgeDown(p.endXY)
                end
            end

            -- Stasis: hide every 2nd piece, or turn it into a trace.
            if isEverySecond and S.stasis > 1 then
                if S.stasis == 3 then
                    p.isVoid = true
                    cmd.add(p.save())
                    written = written + 1
                end
                -- stasis 2: the piece is skipped on purpose
            else
                cmd.add(p.save())
                written = written + 1
            end

            index = index + 1
        end
    end

    return written
end

-- Builds the macro function for one split style.
local function splitMacro(label, makePieces, alwaysNudge)
    return function(cmd)
        local arcs = getSelectedArcs(1, 'Please select at least one arc to split.')
        if not arcs then return false end

        -- An arc with no length cannot be cut. Skip it so it is not deleted for nothing.
        local usable = table.iselect(arcs, function(_, a) return a.endTiming > a.timing end)
        if #usable == 0 then
            notifyWarn('The selected arcs have no length, so there is nothing to split.')
            return false
        end
        if #usable < #arcs then
            notify(string.format('%d arc(s) skipped because they have no length.', #arcs - #usable))
        end

        if tooBig(usable, 2) then return false end

        local arcTapCount = countArcTapsOn(usable)

        local total = 0
        for _, arc in ipairs(usable) do
            local written = writePieces(arc, makePieces, alwaysNudge, cmd)
            if written > 0 then
                total = total + written
                cmd.add(arc.delete())   -- the pieces replace the original
            end
        end

        if total == 0 then
            notifyWarn('Nothing was created, so the arcs were kept.')
            return false
        end

        cmd.setName(string.format('Split %d arc(s) (%s)', #usable, label))
        notify(string.format('Split %d arc(s) into %d segment(s).', #usable, total))

        if arcTapCount > 0 then
            notifyWarn(string.format(
                '%d ArcTap(s) were on the split arc(s). They are not copied to the new segments.', arcTapCount))
        end
    end
end

-- The menu order of this list is the order shown in the game menu (Normal first: it is the most used).
FolderNew(ROOT, SPLIT, 'f184', '[Split]')

local SPLIT_STYLES = {
    -- Normal: plain straight pieces.
    { id = 'split_normal', name = 'Normal', icon = 'f108',
      make = function(arc, s, e, spos, epos)
          return { piece(arc, s, spos, e, epos) }
      end },

    -- Amygdata: like Normal, but always nudged so height indicator show.
    { id = 'split_amygdata', name = 'Amygdata', icon = 'e260', nudge = true,
      make = function(arc, s, e, spos, epos)
          return { piece(arc, s, spos, e, epos) }
      end },

    -- Chunky: each piece moves in the first half and then stays still in the second half.
    { id = 'split_chunky', name = 'Chunky', icon = 'eba4',
      make = function(arc, s, e, spos, epos)
          local mid = math.round(math.lerp(s, e, 0.5))
          return {
              piece(arc, s, spos, mid, epos),
              piece(arc, mid, epos, e, epos),
          }
      end },

    -- Rice: a short piece that stays still at the start of each step (see Rice Multiplier).
    { id = 'split_rice', name = 'Rice', icon = 'e5d3',
      make = function(arc, s, e, spos, epos)
          local mid = math.round(math.lerp(s, e, FloonySettings.riceMultiplier))
          return { piece(arc, s, spos, mid, spos) }
      end },

    -- Staircase: stays still for the whole step, then jumps up (or down) in zero time.
    { id = 'split_stair', name = 'Staircase', icon = 'ebaa',
      make = function(arc, s, e, spos, epos)
          return {
              piece(arc, s, spos, e, spos),
              piece(arc, e, spos, e, epos),
          }
      end },

    -- Point: a single 0ms point at the start of every step.
    { id = 'split_point', name = 'Point (0ms)', icon = 'e837',
      make = function(arc, s, e, spos, epos)
          return { piece(arc, s, spos, s, spos) }
      end },
}

for _, style in ipairs(SPLIT_STYLES) do
    MacroNew(SPLIT, style.id, style.name, style.icon, splitMacro(style.name, style.make, style.nudge))
end

--------------------------------------------------------------------------------
-- GENERATE: combining TWO arcs
-- The first arc ("dominant") sets the timing, color and type. The second arc ("target") is where
-- the new pieces reach out to. Both original arcs are replaced.
--------------------------------------------------------------------------------

-- Checks that the two arcs can be combined. Warns and returns false if not.
local function validateArcs(a, b)
    if not a or not b then
        notifyWarn('Two arcs are required.')
        return false
    end

    if sameArc(a, b) then
        notifyWarn('Both arcs cannot be identical.')
        return false
    end

    if a.timing ~= b.timing or a.endTiming ~= b.endTiming then
        notifyWarn('Both arcs must start and end at the exact same time.')
        return false
    end

    if a.color ~= b.color or a.isVoid ~= b.isVoid or a.timingGroup ~= b.timingGroup then
        notifyWarn('Both arcs must have matching colors, void states, and timing groups.')
        return false
    end

    local sameStart = (a.startX == b.startX and a.startY == b.startY)
    local sameEnd = (a.endX == b.endX and a.endY == b.endY)
    if sameStart and sameEnd and a.type == b.type then
        notifyWarn('Both arcs are identical (same start, end and easing).')
        return false
    end

    return true
end

-- Where the "middle" point of each step goes, for ran and nar.
local MIDDLE = {
    ran = function(s, e) return e end,                         -- Ran/Sawtooth: at the end
    nar = function(s, e) return s end,                         -- Reverse Ran: at the start
}

local function generator(kind, label)
    return function(cmd)
        local arcA = Request.arc('Select dominant arc')
        local arcB = Request.arc('Select target arc')
        if not validateArcs(arcA, arcB) then return false end
        if tooBig({ arcA }, 2) then return false end

        local S = FloonySettings

        -- A new piece that copies the look of the dominant arc (or forces 's' if enabled).
        local function make(t1, p1, t2, p2)
            local easing = S.forceSEasing and 's' or arcA.type
            return Event.arc(t1, p1, t2, p2, arcA.isVoid, arcA.color, easing,
                arcA.timingGroup, arcA.sfx, arcA.arcResolutionMultiplier)
        end

        local waveUp = true   -- Alternates direction for Square Wave & Zig-Zag

        for s, e in bestDivisions(arcA.timing, arcA.endTiming, arcSliceLength(arcA)) do
            local aStart, aEnd = arcA.positionAt(s), arcA.positionAt(e)
            local bStart, bEnd = arcB.positionAt(s), arcB.positionAt(e)

            if kind == 'brr' then
                -- Zig-Zag: strictly follows beatlines by alternating A->B and B->A per step
                if waveUp then
                    cmd.add(make(s, aStart, e, bEnd).save())
                else
                    cmd.add(make(s, bStart, e, aEnd).save())
                end
                waveUp = not waveUp

            elseif kind == 'wave' then
                -- Jump to the other arc, then follow it for the whole step.
                if waveUp then
                    cmd.add(make(s, aStart, s, bStart).save())
                    cmd.add(make(s, bStart, e, bEnd).save())
                else
                    cmd.add(make(s, bStart, s, aStart).save())
                    cmd.add(make(s, aStart, e, aEnd).save())
                end
                waveUp = not waveUp

            elseif kind == 'line' then
                -- Only a connecting line between the two arcs at the start of every step.
                cmd.add(make(s, aStart, s, bStart).save())

            else
                -- Ran and Reverse Ran: go out to the target arc, then come back.
                local mid = MIDDLE[kind](s, e)
                local midPos = arcB.positionAt(mid)

                -- Height indicator: avoid the same height twice in a row.
                if S.forceHeightLines and midPos.y > 0 and (aStart.y == midPos.y or midPos.y == aEnd.y) then
                    aEnd = nudgeDown(aEnd)
                end

                cmd.add(make(s, aStart, mid, midPos).save())
                cmd.add(make(mid, midPos, e, aEnd).save())
            end
        end

        cmd.add(arcA.delete())
        cmd.add(arcB.delete())
        cmd.setName('Generate ' .. label)
    end
end

FolderNew(ROOT, GEN, 'ef3c', '[Generate]')

local GENERATORS = {
    { id = 'brr',  name = 'Zig-Zag',      icon = 'e922' },
    { id = 'ran',  name = 'Ran/Sawtooth', icon = 'e3e7' },
    { id = 'nar',  name = 'Reverse Ran',  icon = 'e3e6' },
    { id = 'wave', name = 'Square Wave',  icon = 'eba7' },
    { id = 'line', name = 'Line',         icon = 'e152' },
}

for _, g in ipairs(GENERATORS) do
    MacroNew(GEN, g.id, g.name, g.icon, generator(g.id, g.name))
end

--------------------------------------------------------------------------------
-- SETTINGS MACRO (registered last = shown last; not registered by "Repeat Last Macro")
--------------------------------------------------------------------------------
MacroNewNOCMD(ROOT, 'floony.settings', 'Settings', 'e8b8', updateSettings, true)