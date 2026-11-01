require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // EFFECTS / GIMMICK // --       |
------------------------------------/

local ROOT = 'floony.effect'
FolderNew('floony', ROOT, 'e65f', '- Effects / Gimmick -')

--------------------------------------------------------------------------------
-- SMALL HELPERS - EFFECT
--------------------------------------------------------------------------------

-- Adds a timing event. A divisor of 999 hides the beatlines.
local function addTiming(cmd, t, bpm, tg, divisor)
    cmd.add(Event.timing(math.floor(t), bpm, divisor or 999, tg).save())
end

-- True when a timing event already sits at time t in this timing group.
-- An existing timing event has priority: the macros do not add a second one on top of it.
local function timingExistsAt(tg, t)
    local found = Event.query(
        EventSelectionConstraint.create().timing()
            .fromTiming(t - 1).toTiming(t + 1).ofTimingGroup(tg)
    ).timing or {}

    for _, e in ipairs(found) do
        if math.abs(e.timing - t) < 0.5 then return true end
    end
    return false
end

-- Adds the timing event that puts normal speed (and normal beatlines) back at the end of a gimmick.
-- If a timing event already sits at that time, it is kept and nothing is added.
local function addRestore(cmd, t, bpm, tg)
    if timingExistsAt(tg, math.floor(t)) then return end
    addTiming(cmd, t, bpm, tg, Context.beatlineDensity)
end

-- Calls fn(t) at tStart, tStart + step, tStart + 2*step ... while a full step still fits before tEnd.
local function eachStep(tStart, tEnd, step, fn)
    local t = tStart
    while t <= tEnd - step do
        fn(t)
        t = t + step
    end
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
-- EASING CURVES (used to shape how a value changes over time)
--------------------------------------------------------------------------------
local c4 = 2 * math.pi / 3
local c5 = 2 * math.pi / 4.5

local EASINGS = {
    l     = function(x) return x end,
    qi    = function(x) return x * x end,
    qo    = function(x) return 1 - (1 - x) * (1 - x) end,
    qio   = function(x) return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 / 2 end,
    ci    = function(x) return x * x * x end,
    co    = function(x) return 1 - (1 - x) ^ 3 end,
    cio   = function(x) return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 / 2 end,
    qrti  = function(x) return x * x * x * x end,
    qrto  = function(x) return 1 - (1 - x) ^ 4 end,
    qrtio = function(x) return x < 0.5 and 8 * x * x * x * x or 1 - (-2 * x + 2) ^ 4 / 2 end,
    qnti  = function(x) return x * x * x * x * x end,
    qnto  = function(x) return 1 - (1 - x) ^ 5 end,
    qntio = function(x) return x < 0.5 and 16 * x * x * x * x * x or 1 - (-2 * x + 2) ^ 5 / 2 end,
    exi   = function(x) return x == 0 and 0 or 2 ^ (10 * x - 10) end,
    exo   = function(x) return x == 1 and 1 or 1 - 2 ^ (-10 * x) end,
    exio  = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end
        return x < 0.5 and 2 ^ (20 * x - 10) / 2 or (2 - 2 ^ (-20 * x + 10)) / 2
    end,
    eli   = function(x) return x == 0 and 0 or (x == 1 and 1 or -2 ^ (10 * x - 10) * math.sin((x * 10 - 10.75) * c4)) end,
    elo   = function(x) return x == 0 and 0 or (x == 1 and 1 or 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * c4) + 1) end,
    elio  = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end
        if x < 0.5 then return -(2 ^ (20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2 end
        return 2 ^ (-20 * x + 10) * math.sin((20 * x - 11.125) * c5) / 2 + 1
    end,
}

-- The order shown in dropdown menus.
local EASING_NAMES = { 'l', 'qi', 'qo', 'qio', 'ci', 'co', 'cio', 'qrti', 'qrto', 'qrtio',
                       'qnti', 'qnto', 'qntio', 'exi', 'exo', 'exio', 'eli', 'elo', 'elio' }

--------------------------------------------------------------------------------
-- TUNNEL / DEPTH SPIRAL
-- Draws rings of traces (like a tunnel) that get bigger over time and slowly twist.
--------------------------------------------------------------------------------
MacroNew(ROOT, 'tunnel_spiral', 'Tunnel / Depth Spiral', 'eba7',
    function(cmd)
        local tStart = Request.time('Select start timing')
        local center = Request.position(tStart, 'Select tunnel center position')
        local tEnd = Request.time('Select end timing')

        if tEnd <= tStart then
            notifyWarn('The end time must be after the start time.')
            return false
        end

        local r = Request.dialogRaw('Tunnel / Depth Spiral',
            DialogField.create('rings')
                .setLabel('Ring Count')
                .setTooltip('Number of depth rings along the spiral.')
                .defaultTo('6')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('sides')
                .setLabel('Sides per Ring')
                .setTooltip('Number of corners (3 = triangle, 4 = square, 8+ = round).')
                .defaultTo('8')
                .textField(FieldConstraint.create().integer().gEqual(3)),
            DialogField.create('startRadius')
                .setLabel('Inner Radius')
                .setTooltip('Radius of the smallest ring.')
                .defaultTo('0.1')
                .textField(FieldConstraint.create().float()),
            DialogField.create('endRadius')
                .setLabel('Outer Radius')
                .setTooltip('Radius of the largest ring.')
                .defaultTo('1.2')
                .textField(FieldConstraint.create().float()),
            DialogField.create('rotation')
                .setLabel('Total Twist (Degrees)')
                .setTooltip('How much the tunnel twists from the first ring to the last.')
                .defaultTo('180')
                .textField(FieldConstraint.create().float())
        )
        if not r then return false end

        local rings   = math.floor(num(r, 'rings', 6))
        local sides   = math.floor(num(r, 'sides', 8))
        local rInner  = num(r, 'startRadius', 0.1)
        local rOuter  = num(r, 'endRadius', 1.2)
        local twist   = num(r, 'rotation', 180)

        local tg = Context.currentTimingGroup
        if not confirmBigJob(rings * sides * 2, 'traces') then return false end
        local ringTime = (tEnd - tStart) / rings   -- time between two rings

        -- A point on a ring: `radius` away from the center, `angle` radians around.
        local function ringPoint(radius, angle)
            return xy(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle))
        end

        for ring = 1, rings do
            local ratio     = ring / rings
            local nextRatio = math.min(1.0, (ring + 1) / rings)

            local radius     = math.lerp(rInner, rOuter, ratio)
            local nextRadius = math.lerp(rInner, rOuter, nextRatio)
            local turn       = math.rad(twist * ratio)
            local nextTurn   = math.rad(twist * nextRatio)

            local t1 = tStart + math.floor((ring - 1) * ringTime)
            local t2 = tStart + math.floor(ring * ringTime)

            for side = 0, sides - 1 do
                local a1 = (side / sides) * 2 * math.pi + turn
                local a2 = ((side + 1) / sides) * 2 * math.pi + turn
                local p1, p2 = ringPoint(radius, a1), ringPoint(radius, a2)

                -- The edge of this ring (all at one moment, so it is a flat shape).
                cmd.add(Event.arc(t1, p1, t1, p2, true, 0, 's', tg).save())

                -- A line from this ring's corner to the same corner on the next ring.
                if ring < rings then
                    local aNext = (side / sides) * 2 * math.pi + nextTurn
                    cmd.add(Event.arc(t1, p1, t2, ringPoint(nextRadius, aNext), true, 0, 's', tg).save())
                end
            end
        end

        cmd.setName(string.format('Tunnel (%d rings)', rings))
    end
)

--------------------------------------------------------------------------------
-- ARC RAIN
-- Fills a time range and an area with small traces that appear at random spots.
--   Seed    : the same seed gives the same rain again. Leave it empty for a new rain every time
--             (the seed that was used is shown at the end, so you can type it in later).
--             A word works as a seed too.
--   Spacing : traces that exist at the same time keep at least this distance from each other.
--             0 = no limit.
--------------------------------------------------------------------------------
local RAIN = 'floony.arcrain'
FolderNew(ROOT, RAIN, 'e3ea', '[Arc Rain]')
 
-- Remembered between runs (until the macros are reloaded).
local rain = { length = 1, intensity = 1, y = 1, x = 0.2, spacing = 0, seed = '', runs = 0,
               corner1 = nil, corner2 = nil }
 
-- A small random number generator of our own. It gives the same numbers for the same seed,
-- and it does not touch the random numbers of other macros.
local function newRandom(seed)
    local state = math.floor(math.abs(seed)) % 2147483646 + 1   -- a number from 1 to 2147483646
    return function()
        state = (state * 48271) % 2147483647
        return state / 2147483647                                 -- a number between 0 and 1
    end
end
 
-- Turns the typed seed (a number or any word) into a number. Gives nil when it is empty.
local function seedFromText(text)
    text = string.trim(tostring(text or ''))
    if text == '' then return nil end
 
    local number = tonumber(text)
    if number then return math.floor(math.abs(number)) end
 
    local hash = 7
    for i = 1, #text do
        hash = (hash * 31 + text:byte(i)) % 2147483646
    end
    return hash
end
 
-- A new seed for when none was typed.
local function newSeed()
    rain.runs = rain.runs + 1
    local ok, now = pcall(os.time)
    return ((ok and now or 0) + rain.runs * 7919) % 2147483646 + 1
end
 
-- Removes the traces that are already over at time t from the list of active traces.
local function pruneActive(active, t)
    local keep = 1
    for i = 1, #active do
        if active[i].last > t then
            active[keep] = active[i]
            keep = keep + 1
        end
    end
    for i = keep, #active do active[i] = nil end
end
 
-- Picks a random spot in the area that is at least `spacing` away from every trace
-- that is still active. Gives nil when no free spot was found (after 20 tries).
local function freeSpot(area, rng, active, spacing)
    for _ = 1, 20 do
        local spot = xy(math.lerp(area.xMin, area.xMax, rng()), math.lerp(area.yMin, area.yMax, rng()))
 
        local free = true
        if spacing > 0 then
            for _, other in ipairs(active) do
                local dx, dy = spot.x - other.pos.x, spot.y - other.pos.y
                if dx * dx + dy * dy < spacing * spacing then
                    free = false
                    break
                end
            end
        end
 
        if free then return spot end
    end
    return nil
end
 
-- The seed and spacing fields, shared by both rain macros.
local function seedField()
    return DialogFields.default(
        DialogField.create('seed')
            .setLabel('Seed')
            .setTooltip('The same seed gives the same rain. Leave empty for a new rain every time.'),
        rain.seed ~= '' and rain.seed or nil)
        .textField(FieldConstraint.create().any())
end
 
local function spacingField()
    return DialogField.create('spacing')
        .setLabel('Min Spacing')
        .setTooltip('Traces that exist at the same time stay at least this far apart. 0 = no limit.')
        .defaultTo(tostring(rain.spacing))
        .textField(FieldConstraint.create().float().gEqual(0))
end
 
-- The text at the end: which seed was used, and how many traces had no room.
local function rainReport(label, seed, skipped)
    local text = string.format('%s done (seed %d).', label, seed)
    if skipped > 0 then
        text = text .. string.format(' %d trace(s) skipped: no free spot.', skipped)
    end
    notify(text)
end
 
-- Asks for the start time, the rain area (the last area can be reused) and the end time.
-- Returns tStart, tEnd and the area, or nil when something is wrong.
local function askRainSetup()
    local tStart = Request.time('Select start time')
 
    if rain.corner1 and rain.corner2 then
        local r = Request.dialogRaw('Reuse Area',
            DialogField.create('usePrev')
                .setLabel('Use Previous Area?')
                .setTooltip('Reuse the two corners you picked last time?')
                .dropdownMenu('Yes', 'No')
        )
        if r and choiceIndex(r['usePrev'], { 'Yes', 'No' }) == 2 then
            rain.corner1, rain.corner2 = nil, nil
        end
    end
 
    if not (rain.corner1 and rain.corner2) then
        rain.corner1 = Request.position(tStart, 'Select First Corner (Min X/Y)')
        rain.corner2 = Request.position(tStart, 'Select Opposite Corner (Max X/Y)')
    end
 
    local tEnd = Request.time('Select end time')
    if tEnd <= tStart then
        notifyWarn('The end time must be after the start time.')
        return nil
    end
 
    local a, b = rain.corner1, rain.corner2
    local area = {
        xMin = math.min(a.x, b.x), xMax = math.max(a.x, b.x),
        yMin = math.min(a.y, b.y), yMax = math.max(a.y, b.y),
    }
    return tStart, tEnd, area
end
 
-- Normal: each trace stays in one spot for a while (optionally with an ArcTap on it).
MacroNew(RAIN, 'rain_normal', 'Normal', 'e5da',
    function(cmd)
        local tStart, tEnd, area = askRainSetup()
        if not tStart then return false end
 
        local r = Request.dialogRaw('Arc Rain Normal',
            DialogField.create('intensity')
                .setLabel('Intensity')
                .setTooltip('How many traces appear at every step.')
                .defaultTo(tostring(rain.intensity))
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('lmul')
                .setLabel('Min Length (Beats)')
                .setTooltip('Length of each trace, in beats.')
                .defaultTo(tostring(rain.length))
                .textField(FieldConstraint.create().float().gEqual(0)),
            DialogField.create('rangelength')
                .setLabel('Random Length Offset')
                .setTooltip('Adds a random extra length, up to this many beats.')
                .defaultTo('0')
                .textField(FieldConstraint.create().float().gEqual(0)),
            spacingField(),
            seedField(),
            DialogField.create('arctap')
                .setLabel('Add ArcTaps')
                .setTooltip('Puts an ArcTap at the start of every trace.')
                .checkbox()
        )
        if not r then return false end
 
        local length    = tonumber(r['lmul'])
        local intensity = tonumber(r['intensity'])
        local extra     = num(r, 'rangelength', 0)
        if not (length and intensity) then
            notifyWarn('Please type valid numbers.')
            return false
        end
        local spacing = math.max(0, num(r, 'spacing', 0))
        local seedText = r['seed'] or ''
        rain.length, rain.intensity, rain.spacing, rain.seed = length, intensity, spacing, seedText
 
        local withArcTaps = isOn(r['arctap'])
        local tg = Context.currentTimingGroup
        local beat = Context.beatLengthAt(tStart, tg)
        local step = beat / Context.beatlineDensity
 
        local estimate = math.floor((tEnd - tStart) / step) * intensity
        if not confirmBigJob(estimate, 'traces') then return false end
 
        local seed = seedFromText(seedText) or newSeed()
        local rng = newRandom(seed)
        local active, skipped = {}, 0
 
        eachStep(tStart, tEnd, step, function(t)
            pruneActive(active, t)
 
            for _ = 1, intensity do
                local beats = (extra > 0) and math.lerp(length, length + extra, rng()) or length
                local arcStart = math.floor(t)
                local arcEnd = math.floor(arcStart + beats * beat)
 
                local pos = freeSpot(area, rng, active, spacing)
                if pos then
                    local trace = Event.arc(arcStart, pos, arcEnd, pos, true, 0, 's', tg)
                    cmd.add(trace.save())
                    active[#active + 1] = { pos = pos, last = arcEnd }
 
                    if withArcTaps then
                        local tapTime = (arcEnd > arcStart) and math.min(arcStart + 1, arcEnd) or arcStart
                        cmd.add(Event.arctap(tapTime, trace, 1).save())
                    end
                else
                    skipped = skipped + 1
                end
            end
        end)
 
        rainReport('Arc Rain', seed, skipped)
    end
)
 
-- Tunnel: each trace starts in a random spot and drifts away (similar to Callima Karma).
MacroNew(RAIN, 'rain_tunnel', 'Tunnel', 'e5da',
    function(cmd)
        local tStart, tEnd, area = askRainSetup()
        if not tStart then return false end
 
        local directions = { 'Both', 'Left', 'Right' }
 
        local r = Request.dialogRaw('Arc Rain Tunnel',
            DialogField.create('intensity')
                .setLabel('Intensity')
                .setTooltip('How many traces appear at every step.')
                .defaultTo(tostring(rain.intensity))
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('lmul')
                .setLabel('Length Multiplier')
                .setTooltip('How long each trace lasts, compared to the step between traces.')
                .defaultTo(tostring(rain.length))
                .textField(FieldConstraint.create().float()),
            DialogField.create('factory')
                .setLabel('Y-Axis Shift')
                .setTooltip('How far a trace can drift up or down.')
                .defaultTo(tostring(rain.y))
                .textField(FieldConstraint.create().float()),
            DialogField.create('factorx')
                .setLabel('X-Axis Shift')
                .setTooltip('How far a trace can drift sideways.')
                .defaultTo(tostring(rain.x))
                .textField(FieldConstraint.create().float()),
            DialogField.create('endpos')
                .setLabel('Horizontal Direction')
                .setTooltip('Which way the traces drift sideways.')
                .dropdownMenu(table.unpack(directions)),
            spacingField(),
            seedField()
        )
        if not r then return false end
 
        local length    = tonumber(r['lmul'])
        local intensity = tonumber(r['intensity'])
        if not (length and intensity) then
            notifyWarn('Please type valid numbers.')
            return false
        end
        local driftY = num(r, 'factory', 1.0)
        local driftX = math.abs(num(r, 'factorx', 0.2))
        local direction = choiceIndex(r['endpos'], directions)   -- 1 both, 2 left, 3 right
        local spacing = math.max(0, num(r, 'spacing', 0))
        local seedText = r['seed'] or ''
 
        rain.length, rain.intensity, rain.y, rain.x = length, intensity, driftY, driftX
        rain.spacing, rain.seed = spacing, seedText
 
        local tg = Context.currentTimingGroup
        local step = Context.beatLengthAt(tStart, tg) / Context.beatlineDensity
        local duration = step * length
 
        local estimate = math.floor((tEnd - tStart) / step) * intensity
        if not confirmBigJob(estimate, 'traces') then return false end
 
        local seed = seedFromText(seedText) or newSeed()
        local rng = newRandom(seed)
        local active, skipped = {}, 0
 
        eachStep(tStart, tEnd, step, function(t)
            pruneActive(active, t)
 
            for _ = 1, intensity do
                local pos = freeSpot(area, rng, active, spacing)
                if pos then
                    local shiftX
                    if direction == 2 then shiftX = -driftX
                    elseif direction == 3 then shiftX = driftX
                    else shiftX = math.lerp(-driftX, driftX, rng()) end
 
                    local shiftY = math.lerp(-1, 1, rng()) * driftY
                    local arcEnd = math.floor(t + duration)
 
                    cmd.add(Event.arc(math.floor(t), pos, arcEnd, pos + xy(shiftX, shiftY), true, 0, 's', tg).save())
                    active[#active + 1] = { pos = pos, last = arcEnd }
                else
                    skipped = skipped + 1
                end
            end
        end)
 
        rainReport('Arc Rain Tunnel', seed, skipped)
    end
)

--------------------------------------------------------------------------------
-- TIMING GIMMICKS
--------------------------------------------------------------------------------
local TIMING = 'floony.timing'
FolderNew(ROOT, TIMING, 'e8b5', '[Timing]')

--------------------------------------------------------------------------------
-- GRADUAL
-- The BPM changes smoothly from one value to another over a time range.
--------------------------------------------------------------------------------
local lastGradual = {}
local ENDING_OPTIONS = { 'Stay at End BPM', 'Back to normal BPM' }

MacroNew(TIMING, 'gradual', 'Gradual', 'e6df',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpmHere = Context.bpmAt(tStart, tg)
        local bpmBase = Context.baseBpm

        -- The BPM the chart has at the end time (read now, before anything is added).
        local normalBpm = Context.bpmAt(tEnd, tg)

        local title = 'Gradual Timing / Base BPM: ' .. tostring(bpmBase)
        if bpmBase ~= bpmHere then
            title = title .. ' / Current BPM: ' .. tostring(bpmHere)
        end

        -- The options used last time go on top.
        local endingList = defaultFirst(ENDING_OPTIONS, lastGradual.ending)
        local easingList = defaultFirst(EASING_NAMES, lastGradual.easing)

        local r = Request.dialogRaw(title,
            DialogField.create('division')
                .setLabel('Division Count')
                .setTooltip('How many timing events to place. More = smoother.')
                .defaultTo(tostring(math.floor(tonumber(lastGradual.division) or Context.beatlineDensity)))
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('startBpm')
                .setLabel('Start BPM')
                .setTooltip('The BPM at the start. You can type math, like 120*2.')
                .defaultTo(lastGradual.startBpm or tostring(bpmHere))
                .textField(FieldConstraint.create().any()),
            DialogField.create('endBpm')
                .setLabel('End BPM')
                .setTooltip('The BPM at the end. You can type math, like 120*2.')
                .defaultTo(lastGradual.endBpm or tostring(bpmHere * 2))
                .textField(FieldConstraint.create().any()),
            DialogField.create('ending')
                .setLabel('At the End')
                .setTooltip('What the BPM does after the gradual part. "Back to normal" puts the BPM the chart had before at the end time.')
                .dropdownMenu(table.unpack(endingList)),
            DialogField.create('easing')
                .setLabel('Easing Curve')
                .setTooltip('The shape of the change.')
                .dropdownMenu(table.unpack(easingList))
        )
        if not r then return false end

        -- Remember choices mapped back through the reordered lists
        local ending = endingList[choiceIndex(r['ending'], endingList)]
        local easingName = easingList[choiceIndex(r['easing'], easingList)]

        lastGradual.division = r['division']
        lastGradual.startBpm = r['startBpm']
        lastGradual.endBpm = r['endBpm']
        lastGradual.ending = ending
        lastGradual.easing = easingName

        local startBpm = evaluateMathExpression(r['startBpm'])
        local endBpm = evaluateMathExpression(r['endBpm'])
        if not (startBpm and endBpm) then
            notifyWarn('Invalid BPM. Type a number or a simple math expression.')
            return false
        end

        local division = math.max(1, math.floor(num(r, 'division', Context.beatlineDensity)))
        local ease = EASINGS[easingName] or EASINGS.l
        local backToNormal = (ending == ENDING_OPTIONS[2])

        for i = 0, division - 1 do
            local t = tStart + (tEnd - tStart) * (i / division)
            addTiming(cmd, t, math.lerp(startBpm, endBpm, ease(i / division)), tg)
        end

        addRestore(cmd, tEnd, backToNormal and normalBpm or endBpm, tg)
        cmd.setName('Gradual')
    end
)

--------------------------------------------------------------------------------
-- GRADUAL (ADVANCED / SUDDEN)
-- Gradual BPM change that starts with a SUDDEN spike, and can start with a glitchy shake:
--   1. at the start: the normal BPM of that moment
--   2. 1ms later: the sudden spike (a huge BPM for 1ms, so the notes ahead appear suddenly)
--   3. then the gradual BPM change from Start BPM to End BPM
--      (the first few steps can be GLITCHY: the BPM flips +/- on every step, then goes back to normal)
--   4. at the end: stay at the End BPM, or go back to the normal BPM the chart had before
--------------------------------------------------------------------------------
local lastAdvanced = {}   -- remembered until the macros are reloaded

local ENDING_OPTIONS = { 'Stay at End BPM', 'Back to normal BPM' }

MacroNew(TIMING, 'gradual_sudden', 'Gradual (Sudden)', 'e4fb',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpmHere = Context.bpmAt(tStart, tg)

        -- The BPM the chart has at the end time (read now, before anything is added).
        local normalBpm = Context.bpmAt(tEnd, tg)

        -- The option you used last time goes on top.
        local endingList = defaultFirst(ENDING_OPTIONS, lastAdvanced.ending)
        local easingList = defaultFirst(EASING_NAMES, lastAdvanced.easing)

        local r = Request.dialogRaw('Gradual (Advanced/Sudden) / Current BPM: ' .. tostring(bpmHere),
            DialogField.create('division')
                .setLabel('Division Count')
                .setTooltip('How many timing events the gradual part is made of. More = smoother.')
                .defaultTo(tostring(math.floor(tonumber(lastAdvanced.division) or Context.beatlineDensity * 2)))
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('startBpm')
                .setLabel('Start BPM')
                .setTooltip('The BPM at the start of the gradual part. You can type math, like 120*2.')
                .defaultTo(lastAdvanced.startBpm or tostring(bpmHere))
                .textField(FieldConstraint.create().any()),
            DialogField.create('endBpm')
                .setLabel('End BPM')
                .setTooltip('The BPM at the end. You can type math, like 120*2.')
                .defaultTo(lastAdvanced.endBpm or tostring(bpmHere * 2))
                .textField(FieldConstraint.create().any()),
            DialogField.create('ending')
                .setLabel('At the End')
                .setTooltip('What the BPM does after the gradual part. "Back to normal" puts the BPM the chart had before (for example 112) at the end time.')
                .dropdownMenu(table.unpack(endingList)),
            DialogField.create('easing')
                .setLabel('Easing Curve')
                .setTooltip('The shape of the gradual change.')
                .dropdownMenu(table.unpack(easingList)),
            DialogField.create('sudden')
                .setLabel('Sudden BPM')
                .setTooltip('The huge BPM of the 1ms spike that makes the notes appear suddenly. 0 = no spike.')
                .defaultTo(lastAdvanced.sudden or '6161616')
                .textField(FieldConstraint.create().any()),
            DialogField.create('glitchSteps')
                .setLabel('Glitch Steps')
                .setTooltip('The first steps of the gradual part flip between + and - BPM. 0 = no glitch.')
                .defaultTo(lastAdvanced.glitchSteps or '0')
                .textField(FieldConstraint.create().integer().gEqual(0)),
            DialogField.create('glitchStrength')
                .setLabel('Glitch Strength')
                .setTooltip('How strong the glitch BPM is, compared to the gradual BPM at that moment.')
                .defaultTo(lastAdvanced.glitchStrength or '3')
                .textField(FieldConstraint.create().float().greater(0)),
            DialogField.create('fadeGlitch')
                .setLabel('Fade Glitch Out')
                .setTooltip('The glitch gets weaker step by step, so it hands over smoothly to the normal gradual movement.')
                .checkbox()
        )
        if not r then return false end

        local ending = endingList[choiceIndex(r['ending'], endingList)]
        local easingName = easingList[choiceIndex(r['easing'], easingList)]

        lastAdvanced.division = r['division']
        lastAdvanced.startBpm = r['startBpm']
        lastAdvanced.endBpm = r['endBpm']
        lastAdvanced.sudden = r['sudden']
        lastAdvanced.glitchSteps = r['glitchSteps']
        lastAdvanced.glitchStrength = r['glitchStrength']
        lastAdvanced.ending = ending
        lastAdvanced.easing = easingName

        local startBpm = expr(r, 'startBpm', nil)
        local endBpm = expr(r, 'endBpm', nil)
        if not (startBpm and endBpm) then
            notifyWarn('Invalid BPM. Type a number or a simple math expression.')
            return false
        end

        -- An empty Sudden BPM counts as 0 (no spike).
        local suddenText = string.trim(tostring(r['sudden'] or ''))
        local suddenBpm = (suddenText == '') and 0 or evaluateMathExpression(suddenText)
        if suddenBpm == false then
            notifyWarn('Invalid Sudden BPM. Type a number, or 0 for no spike.')
            return false
        end

        local division = math.max(1, math.floor(num(r, 'division', Context.beatlineDensity * 2)))
        local ease = EASINGS[easingName] or EASINGS.l
        local glitchSteps = math.clamp(math.floor(num(r, 'glitchSteps', 0)), 0, division)
        local glitchStrength = num(r, 'glitchStrength', 3)
        local fade = isOn(r['fadeGlitch'])
        local backToNormal = (ending == ENDING_OPTIONS[2])

        -- 1) The normal BPM first, then 2) the sudden spike 1ms later.
        local gradualStart = tStart
        if suddenBpm ~= 0 then
            if not timingExistsAt(tg, tStart) then
                addTiming(cmd, tStart, bpmHere, tg)
            end
            addTiming(cmd, tStart + 1, suddenBpm, tg)
            gradualStart = tStart + 2   -- the gradual part continues right after the spike
        end

        local stepMs = (tEnd - gradualStart) / division
        if stepMs < 1 then
            notifyWarn('Too many divisions for this time range. Lower the division count.')
            return false
        end

        -- 3) The gradual part. The first `glitchSteps` steps flip between + and - BPM.
        for i = 0, division - 1 do
            local progress = i / division
            local bpm = math.lerp(startBpm, endBpm, ease(progress))

            if i < glitchSteps then
                local sign = (i % 2 == 0) and 1 or -1
                local strength = glitchStrength
                if fade and glitchSteps > 1 then
                    strength = math.lerp(glitchStrength, 1, i / (glitchSteps - 1))   -- weaker every step
                end
                bpm = sign * bpm * strength
            end

            addTiming(cmd, gradualStart + stepMs * i, bpm, tg)
        end

        -- 4) The last timing event: stay at the End BPM, or go back to the normal BPM.
        addRestore(cmd, tEnd, backToNormal and normalBpm or endBpm, tg)
        cmd.setName('Gradual (Advanced/Sudden)')
    end
)

--------------------------------------------------------------------------------
-- GLITCH TIMING (GRADUAL & CLASSIC STATIC)
-- Creates BPM spikes across a selected time range.
--------------------------------------------------------------------------------
local GLITCH_DIVISOR = 4 -- Default beatline divisor for timing events

local GLITCH_STYLES = {
    'Ascending (weak to strong)',
    'Descending (strong to weak)',
}

local GLITCH_DIRECTIONS = {
    'Alternate (+ / -)',     -- Default: spikes cancel out (shakes in place)
    'Always forward (+)',    -- Spikes stack up: long notes stretch forward
    'Always backward (-)',   -- Spikes stack up: long notes stretch backward
}

local GLITCH_CURVES = {
    { 'Even (linear)',         'l' },
    { 'Slow start (ease in)',  'qi' },
    { 'Fast start (ease out)', 'qo' },
    { 'Smooth (ease in-out)',  'qio' },
}

MacroNew(TIMING, 'glitch', 'Glitch', 'ec1c', function(cmd)
    local tStart, tEnd = Request.timeRange()
    local tg = Context.currentTimingGroup
    local bpm = Context.bpmAt(tStart, tg)

    local curveNames = table.imap(GLITCH_CURVES, function(_, c) return c[1] end)

    local r = Request.dialogRaw('Glitch Timing',
        DialogField.create('segments')
            .setLabel('Glitch Count')
            .setTooltip('How many glitch spikes to place.')
            .defaultTo(tostring(math.floor(Context.beatlineDensity * 4)))
            .textField(FieldConstraint.create().integer().gEqual(2)),

        DialogField.create('base')
            .setLabel('Base BPM')
            .setTooltip('Normal BPM between glitches.')
            .defaultTo(tostring(bpm))
            .textField(FieldConstraint.create().any()),

        DialogField.create('strong')
            .setLabel('Spike BPM')
            .setTooltip('Spike intensity. Accepts math, e.g. 120*64.')
            .defaultTo(tostring(bpm * 64))
            .textField(FieldConstraint.create().any()),

        DialogField.create('weak')
            .setLabel('Weakest Spike BPM')
            .setTooltip('Smallest glitch spike (Gradual mode only).')
            .defaultTo(tostring(bpm * 2))
            .textField(FieldConstraint.create().any()),

        DialogField.create('classic')
            .setLabel('Classic Glitch\n(Static)')
            .setTooltip('When ticked, all spikes use Spike BPM (ignores Weak BPM, Style, and Curve).')
            .checkbox(),

        DialogField.create('style')
            .setLabel('Style')
            .setTooltip('Gradual growth style (Gradual mode only).')
            .dropdownMenu(table.unpack(GLITCH_STYLES)),

        DialogField.create('direction')
            .setLabel('Direction')
            .setTooltip('Alternate cancels out. Forward/Backward stacks spikes.')
            .dropdownMenu(table.unpack(GLITCH_DIRECTIONS)),

        DialogField.create('curve')
            .setLabel('Growth Curve')
            .setTooltip('Growth easing curve (Gradual mode only).')
            .dropdownMenu(table.unpack(curveNames))
    )

    if not r then return false end

    -- Safe dropdown selection index helper
    local function getIndex(val, list)
        if type(val) == 'number' then return val + 1 end
        for i, item in ipairs(list) do
            if item == val then return i end
        end
        return 1
    end

    -- Safe math parser helper
    local function parseNum(val, default)
        return evaluateMathExpression(val) or default
    end

    local isClassic = (r['classic'] == true or tostring(r['classic']) == 'true')
    local count     = math.max(2, math.floor(parseNum(r['segments'], Context.beatlineDensity * 4)))
    local baseBpm   = parseNum(r['base'], bpm)
    local strong    = math.abs(parseNum(r['strong'], bpm * 64))
    local weak      = math.abs(parseNum(r['weak'], bpm * 2))
    local isDesc    = getIndex(r['style'], GLITCH_STYLES) == 2
    local dirIdx    = getIndex(r['direction'], GLITCH_DIRECTIONS)
    local curveIdx  = getIndex(r['curve'], curveNames)
    local easeFunc  = EASINGS[GLITCH_CURVES[curveIdx][2]] or EASINGS.l

    local step = (tEnd - tStart) / count
    if step < 3 then
        notifyWarn('Time range too short for this many glitches. Lower the Glitch Count.')
        return false
    end

    local startSize = isDesc and strong or weak
    local endSize   = isDesc and weak or strong

    -- Generate glitch spikes
    for i = 0, count - 1 do
        local size = strong
        if not isClassic then
            local progress = easeFunc(i / (count - 1))
            size = math.lerp(startSize, endSize, progress)
        end

        local sign = 1
        if dirIdx == 1 then
            sign = (i % 2 == 0) and 1 or -1 -- Alternate (+ / -)
        elseif dirIdx == 3 then
            sign = -1                       -- Always backward (-)
        end

        local t = math.floor(tStart + step * i)

        if i == 0 then
            cmd.add(Event.timing(t, baseBpm, GLITCH_DIVISOR, tg).save())
        end
        cmd.add(Event.timing(t + 1, sign * size, GLITCH_DIVISOR, tg).save())
        cmd.add(Event.timing(t + 2, baseBpm, GLITCH_DIVISOR, tg).save())
    end

    -- Reset back to initial track BPM at range end
    cmd.add(Event.timing(tEnd, bpm, Context.beatlineDensity, tg).save())

    local modeLabel = isClassic and 'classic' or (isDesc and 'descending' or 'ascending')
    cmd.setName(string.format('Glitch (%d spikes, %s)', count, modeLabel))
end)

--------------------------------------------------------------------------------
-- PAUSE
-- Turns a long note into a pause: the track freezes while the note lasts, then continues.
--------------------------------------------------------------------------------
local PAUSE = 'floony.pauseHold'
FolderNew(TIMING, PAUSE, 'e034', '[Pause]')

local stopBpm = 0.01   -- the (almost) zero BPM used while paused

local function stopBpmSetting()
    local r = Request.dialogRaw('Pause Settings',
        DialogField.create('stopbpm')
            .setLabel('Stop BPM Value')
            .setTooltip('BPM used while paused. The default is 0.01.')
            .defaultTo(tostring(stopBpm))
            .textField(FieldConstraint.create().any())
    )
    if not r then return end

    local value = evaluateMathExpression(r['stopbpm'] or '')
    stopBpm = value or 0.01
    notify('Pause stop BPM set to ' .. tostring(stopBpm))
end

-- speed = how fast the track runs again after the pause (1 = normal, 0.5 = half, 2 = double).
local function pauseMacro(speed)
    return function(cmd)
        local picked = Request.note(EventSelectionConstraint.create().long(), 'Select a long note')
        local note = picked and ((picked.hold or {})[1] or (picked.arc or {})[1])
        if not note then return false end

        local tg = note.timingGroup
        local t0, t1 = note.timing, note.endTiming
        local bpmAfter = Context.bpmAt(t1, tg)

        addTiming(cmd, t0, stopBpm, tg)                                            -- freeze
        addTiming(cmd, t1 - 1, bpmAfter * speed, tg, Context.divisorAt(t0, tg))    -- play again
        cmd.add(note.delete())
    end
end

local PAUSE_PRESETS = {
    { name = 'Normal', speed = 1.0, icon = 'e037' },
    { name = 'Half',   speed = 0.5, icon = 'e020' },
    { name = 'Double', speed = 2.0, icon = 'e01f' },
}

for _, p in ipairs(PAUSE_PRESETS) do
    MacroNew(PAUSE, PAUSE .. '.' .. p.name:lower(), p.name, p.icon, pauseMacro(p.speed))
end
MacroNewNOCMD(PAUSE, 'floony.pauseHoldSet', 'Set stop BPM', 'e9e4', stopBpmSetting, true)

--------------------------------------------------------------------------------
-- SUDDEN TIMING
-- Makes notes jump into view at the very last moment (or hides them just before).
--------------------------------------------------------------------------------
local SUDDEN = 'floony.suddentiming'
FolderNew(TIMING, SUDDEN, 'ea0b', '[Sudden]')

-- Hidden: the notes are sent far away until 1ms before the chosen time.
MacroNew(SUDDEN, 'suddenbefore', 'Timing - 1 (Hidden)', 'e5d9',
    function(cmd)
        local t = Request.time()
        local tg = Context.currentTimingGroup
        addTiming(cmd, t - 1, 999999, tg)
        addTiming(cmd, t, Context.bpmAt(t, tg), tg, Context.divisorAt(t, tg))
    end
)

-- Visible: the notes are far away until 1ms after the chosen time.
MacroNew(SUDDEN, 'suddenafter', 'Timing + 1 (Visible)', 'e5da',
    function(cmd)
        local t = Request.time()
        local tg = Context.currentTimingGroup
        addTiming(cmd, t, 999999, tg)
        addTiming(cmd, t + 1, Context.bpmAt(t, tg), tg, Context.divisorAt(t, tg))
    end
)

--------------------------------------------------------------------------------
-- TELEPORT
-- Replaces each selected long note with timing events that make the track jump.
--------------------------------------------------------------------------------
local TELEPORT_GAP = 17   -- ms: notes closer than this to the next one are treated as touching
local TRIGGER_OPTIONS = { 'End', 'Start' }

-- Setting for 'Settings Summary'
registerSettings('Teleport Gimmick', {
    teleport_multiplier = 1,
    teleport_trigger = 'End',
}, function(S)
    return {
        string.format('Distance Multiplier: %g', S.teleport_multiplier or 1),
        string.format('Trigger Point: %s', S.teleport_trigger or 'End'),
    }
end)

MacroNew(TIMING, 'timingteleport', 'Teleport', 'ebaa',
    function(cmd)
        local notes = table.icollapse(
            Event.getCurrentSelection(EventSelectionConstraint.create().long()), 'arc', 'hold')
        if #notes == 0 then
            notifyWarn('Select at least one long note.')
            return false
        end
        table.sort(notes, function(a, b) return a.timing < b.timing end)

        local currentTrigger = FloonySettings.teleport_trigger or 'End'
        local currentMultiplier = FloonySettings.teleport_multiplier or 1

        -- Reorder dropdown options so the saved choice stays on top
        local triggersList = defaultFirst(TRIGGER_OPTIONS, currentTrigger)

        local r = Request.dialogRaw('Teleportation Gimmick',
            DialogField.create('multiplier')
                .setLabel('Distance Multiplier')
                .setTooltip('How far the track jumps, in beatlines.')
                .defaultTo(tostring(currentMultiplier))
                .textField(FieldConstraint.create().float()),
            DialogField.create('startpoint')
                .setLabel('Teleport Trigger Point')
                .setTooltip('Jump at the start or at the end of each long note.')
                .dropdownMenu(table.unpack(triggersList))
        )
        if not r then return false end

        -- Save chosen values back to persistent FloonySettings
        FloonySettings.teleport_multiplier = num(r, 'multiplier', currentMultiplier)
        FloonySettings.teleport_trigger = triggersList[choiceIndex(r['startpoint'], triggersList)]
        
        if saveSettings then saveSettings() end

        local tg = Context.currentTimingGroup
        local isEndTrigger = (string.lower(FloonySettings.teleport_trigger) == 'end')

        for i, note in ipairs(notes) do
            local bpm = Context.bpmAt(note.timing, tg)
            local bpmEnd = Context.bpmAt(note.endTiming, tg)
            local divisor = Context.divisorAt(note.timing, tg)
            local beatline = 60000 / (bpm * Context.beatlineDensity)
            local jumpBpm = bpm * (beatline * FloonySettings.teleport_multiplier)

            local nextNote = notes[i + 1]

            -- Do not run into the next note.
            local noteEnd = note.endTiming
            if nextNote and noteEnd > nextNote.timing - TELEPORT_GAP then
                noteEnd = nextNote.timing
            end

            if isEndTrigger then
                addTiming(cmd, note.timing, 0.01, tg)
                addTiming(cmd, noteEnd - 1, jumpBpm, tg)

                -- Restore the normal BPM, unless the next note starts right away.
                if not nextNote or noteEnd + TELEPORT_GAP < nextNote.timing then
                    addTiming(cmd, noteEnd, bpmEnd, tg, divisor)
                end
            else
                addTiming(cmd, note.timing, jumpBpm, tg)
                addTiming(cmd, note.timing + 1, bpmEnd, tg, divisor)
            end

            cmd.add(note.delete())
        end

        cmd.setName('Teleport')
    end
)

--------------------------------------------------------------------------------
-- ADVANCED TIMING (newer macros)
--------------------------------------------------------------------------------
local ADV = 'floony.timing_adv'
FolderNew(TIMING, ADV, 'ea5d', '[Advanced Timing]')

-- 1. WAVE SPEED OSCILLATION: the speed swings up and down like a sine wave.
MacroNew(ADV, 'wobble_wave', 'Wave Speed Oscillation', 'e176',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local baseBpm = Context.bpmAt(tStart, tg)

        local directions = { 'Fast First (Peak)', 'Slow First (Trough)' }

        local r = Request.dialogRaw('Wave Speed Oscillation',
            DialogField.create('cycles')
                .setLabel('Wave Cycles')
                .setTooltip('How many full up-and-down waves over the time range.')
                .defaultTo('2')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('amplitude')
                .setLabel('Speed Shift Range (BPM)')
                .setTooltip('How far the BPM swings above and below the normal BPM.')
                .defaultTo(tostring(baseBpm * 0.5))
                .textField(FieldConstraint.create().any()),
            DialogField.create('direction')
                .setLabel('Initial Wave Direction')
                .setTooltip('Start by speeding up, or by slowing down.')
                .dropdownMenu(table.unpack(directions)),
            DialogField.create('stepsPerCycle')
                .setLabel('Steps per Cycle')
                .setTooltip('Timing events per wave. More = smoother.')
                .defaultTo('16')
                .textField(FieldConstraint.create().integer().gEqual(4))
        )
        if not r then return false end

        local cycles = math.max(1, math.floor(num(r, 'cycles', 2)))
        local amplitude = expr(r, 'amplitude', baseBpm * 0.5)
        local fastFirst = choiceIndex(r['direction'], directions) == 1
        local perCycle = math.max(4, math.floor(num(r, 'stepsPerCycle', 16)))

        local total = cycles * perCycle
        local stepMs = (tEnd - tStart) / total
        local phase = fastFirst and 0 or math.pi

        for i = 0, total - 1 do
            local angle = (i / total) * cycles * 2 * math.pi + phase
            addTiming(cmd, tStart + i * stepMs, baseBpm + math.sin(angle) * amplitude, tg)
        end
        addRestore(cmd, tEnd, baseBpm, tg)
    end
)

-- 2. RHYTHMIC FREEZE PULSE: the track freezes for part of every step, then catches up quickly.
MacroNew(ADV, 'rhythmic_freeze', 'Rhythmic Freeze Pulse', 'e034',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tStart, tg)
        local beatMs = 60000 / bpm

        local r = Request.dialogRaw('Rhythmic Freeze Pulse',
            DialogField.create('divisor')
                .setLabel('Beat Subdivision')
                .setTooltip('How often it pulses (1 = every beat, 2 = every half beat, 4 = every quarter beat).')
                .defaultTo('4')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('freezeRatio')
                .setLabel('Freeze Time Ratio')
                .setTooltip('Part of each step spent frozen (0.1 = short stutter, 0.5 = half the step).')
                .defaultTo('0.5')
                .textField(FieldConstraint.create().float().greater(0).less(1))
        )
        if not r then return false end

        local stepMs = beatMs / math.max(1, math.floor(num(r, 'divisor', 4)))
        local ratio = num(r, 'freezeRatio', 0.5)

        eachStep(tStart, tEnd, stepMs, function(t)
            local freezeMs = math.floor(stepMs * ratio)
            local activeMs = math.max(1, stepMs - freezeMs)

            addTiming(cmd, t, 0.01, tg)                                      -- frozen
            addTiming(cmd, t + freezeMs, bpm * (stepMs / activeMs), tg)      -- catch up
        end)
        addRestore(cmd, tEnd, bpm, tg)
    end
)

-- 3. HEARTBEAT SPEED SURGE: short bursts of speed, then a stop, over and over.
MacroNew(ADV, 'pulse_timing', 'Heartbeat Speed Surge', 'e034',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tStart, tg)
        local beatMs = 60000 / bpm

        local r = Request.dialogRaw('Heartbeat Speed Surge',
            DialogField.create('division')
                .setLabel('Pulse Rate')
                .setTooltip('Surges per beat (2 = every half beat, 4 = every quarter beat).')
                .defaultTo('2')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('burstRatio')
                .setLabel('Surge Active Ratio')
                .setTooltip('Part of each pulse spent moving fast (0.1 to 0.4 works well).')
                .defaultTo('0.25')
                .textField(FieldConstraint.create().float().greater(0).less(1)),
            DialogField.create('burstBpm')
                .setLabel('Surge Peak BPM')
                .setTooltip('The BPM during the fast part.')
                .defaultTo(tostring(bpm * 4))
                .textField(FieldConstraint.create().any())
        )
        if not r then return false end

        local stepMs = beatMs / math.max(1, math.floor(num(r, 'division', 2)))
        local ratio = num(r, 'burstRatio', 0.25)
        local burstBpm = expr(r, 'burstBpm', bpm * 4)

        eachStep(tStart, tEnd, stepMs, function(t)
            addTiming(cmd, t, burstBpm, tg)                  -- fast
            addTiming(cmd, t + stepMs * ratio, 0.01, tg)     -- stop
        end)
        addRestore(cmd, tEnd, bpm, tg)
    end
)

-- 4. DECAYING RUBBER-BAND SWING: the track swings forward and back, a bit less every time.
MacroNew(ADV, 'pendulum_swing', 'Decaying Rubber-Band Swing', 'e7d0',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tStart, tg)

        local r = Request.dialogRaw('Decaying Rubber-Band Swing',
            DialogField.create('swings')
                .setLabel('Swing Cycles')
                .setTooltip('Back-and-forth swings across the time range.')
                .defaultTo('4')
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create('maxPeak')
                .setLabel('Initial Peak BPM')
                .setTooltip('How strong the first swing is.')
                .defaultTo(tostring(bpm * 6))
                .textField(FieldConstraint.create().any()),
            DialogField.create('decay')
                .setLabel('Damping Decay Rate')
                .setTooltip('How much weaker each swing gets (0.5 = half as strong every time).')
                .defaultTo('0.5')
                .textField(FieldConstraint.create().float().greater(0).less(1))
        )
        if not r then return false end

        local swings = math.max(1, math.floor(num(r, 'swings', 4)))
        local peak = expr(r, 'maxPeak', bpm * 6)
        local decay = num(r, 'decay', 0.5)

        local halfSwings = swings * 2
        local stepMs = (tEnd - tStart) / halfSwings

        for i = 0, halfSwings - 1 do
            local sign = (i % 2 == 0) and 1 or -1      -- forward, back, forward, back...
            addTiming(cmd, tStart + i * stepMs, sign * peak, tg)
            peak = peak * decay
        end
        addRestore(cmd, tEnd, bpm, tg)
    end
)

-- 5. 3-POINT EVENT HORIZON WELL: the track slows down to a stop, then shoots forward.
MacroNew(ADV, 'gravity_well', '3-Point Event Horizon Well', 'eba7',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tStop = Request.time('Select the freeze point (inside the range)')
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tStart, tg)

        if tStop <= tStart or tStop >= tEnd then
            notifyWarn('The freeze point must be inside the start and end time range.')
            return false
        end

        local r = Request.dialogRaw('3-Point Event Horizon Well',
            DialogField.create('slowSteps')
                .setLabel('Slowdown Steps')
                .setTooltip('How many steps the slowdown is made of.')
                .defaultTo('12')
                .textField(FieldConstraint.create().integer().gEqual(4)),
            DialogField.create('slingshotBpm')
                .setLabel('Post-Horizon Slingshot BPM')
                .setTooltip('The fast burst right after the freeze.')
                .defaultTo(tostring(bpm * 8))
                .textField(FieldConstraint.create().any())
        )
        if not r then return false end

        local steps = math.max(4, math.floor(num(r, 'slowSteps', 12)))
        local slingshot = expr(r, 'slingshotBpm', bpm * 8)
        local stepMs = (tStop - tStart) / steps

        -- Slow down, step by step, until the freeze point.
        for i = 0, steps - 1 do
            local left = 1 - (i / steps)
            addTiming(cmd, tStart + i * stepMs, math.max(0.01, bpm * left ^ 2), tg)
        end

        addTiming(cmd, tStop, 0.01, tg)            -- frozen
        addTiming(cmd, tStop + 5, slingshot, tg)   -- burst forward
        addRestore(cmd, tEnd, bpm, tg)
    end
)

-- 6. GLITCH REWIND ECHO: the section plays several times, with a quick rewind between passes.
MacroNew(ADV, 'temporal_echo', 'Glitch Rewind Echo', 'ec1c',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tStart, tg)

        local r = Request.dialogRaw('Glitch Rewind Echo',
            DialogField.create('passes')
                .setLabel('Echo Passes')
                .setTooltip('How many times the section plays.')
                .defaultTo('3')
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(5)),
            DialogField.create('rewindSpeed')
                .setLabel('Rewind Speed Multiplier')
                .setTooltip('How fast the track rewinds between passes.')
                .defaultTo('3.0')
                .textField(FieldConstraint.create().float().greater(0))
        )
        if not r then return false end

        local passes = math.max(2, math.floor(num(r, 'passes', 3)))
        local rewindBpm = -bpm * num(r, 'rewindSpeed', 3.0)
        local sliceMs = (tEnd - tStart) / passes

        for p = 0, passes - 1 do
            local passStart = tStart + p * sliceMs
            addTiming(cmd, passStart, bpm * 1.5, tg)                  -- play forward
            addTiming(cmd, passStart + sliceMs * 0.8, rewindBpm, tg)  -- rewind
        end
        addRestore(cmd, tEnd, bpm, tg)
    end
)

-- 7. RECORD SCRATCH IMPACT SNAP: a quick rewind jerk right before a chosen moment.
MacroNew(ADV, 'double_take', 'Record Scratch Impact Snap', 'e870',
    function(cmd)
        local tImpact = Request.time('Select scratch impact point')
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tImpact, tg)

        local r = Request.dialogRaw('Record Scratch Impact Snap',
            DialogField.create('rewindMs')
                .setLabel('Rewind Duration (ms)')
                .setTooltip('How long the backward jerk lasts.')
                .defaultTo('80')
                .textField(FieldConstraint.create().integer().gEqual(20)),
            DialogField.create('rewindBpm')
                .setLabel('Rewind Speed (Negative BPM)')
                .setTooltip('The negative BPM used for the backward jerk.')
                .defaultTo(tostring(-bpm * 3))
                .textField(FieldConstraint.create().any())
        )
        if not r then return false end

        local rewindMs = num(r, 'rewindMs', 80)
        local rewindBpm = expr(r, 'rewindBpm', -bpm * 3)

        local tStart = tImpact - rewindMs * 2
        addTiming(cmd, tStart, bpm * 2, tg)                       -- speed up
        addTiming(cmd, tStart + rewindMs, rewindBpm, tg)          -- jerk backward
        addTiming(cmd, tImpact - 10, bpm * 4, tg)                 -- rush to the impact
        addRestore(cmd, tImpact, bpm, tg)
    end
)

-- 8. IMPACT FREEZE SNAP: the track freezes, then snaps forward right on the impact.
MacroNew(ADV, 'stasis_pop', 'Impact Freeze Snap', 'e034',
    function(cmd)
        local tImpact = Request.time('Select impact note timing')
        local tg = Context.currentTimingGroup
        local bpm = Context.bpmAt(tImpact, tg)

        local r = Request.dialogRaw('Impact Freeze Snap',
            DialogField.create('freezeBeats')
                .setLabel('Freeze Duration (Beats)')
                .setTooltip('How many beats the track freezes before the snap.')
                .defaultTo('0.5')
                .textField(FieldConstraint.create().float().greater(0))
        )
        if not r then return false end

        local freezeMs = num(r, 'freezeBeats', 0.5) * (60000 / bpm)

        addTiming(cmd, tImpact - freezeMs, 0.01, tg)                  -- freeze
        addTiming(cmd, tImpact - 2, bpm * (freezeMs / 2), tg)         -- snap forward
        addRestore(cmd, tImpact, bpm, tg)
    end
)
