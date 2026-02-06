require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // CREATE ELEMENTS // --         |
------------------------------------/
FolderNew("floony", "floony.element", "e145", "- Create Elements -")

-- // ARCTAPS CHAIN // -- 
MacroNew(
    'floony.element', 'skytapchain',
    'SkyTap Chain', 'e178',
    function (cmd) 

    local arc = Request.arc('Select a Void Arc / Trace')

    if not arc then
        dialogNotify("No Trace selected.")
        return false
    end
    
    if arc.isVoid == false then
        notify('Arc must be Void / Trace.')
        return false
    end
    
    local tStart, tEnd = arc.timing, arc.endTiming
    local interval = Context.beatLengthAt(arc.timing, arc.timingGroup) / Context.beatlineDensity

    for timing = tStart, tEnd - interval, interval do
        local arctapEvent = Event.arctap(timing, arc).save()
        cmd.add(arctapEvent)
    end

end
)

-- // STURDY TRACE // --
MacroNew(
    'floony.element', 'sturdytrace',
    "Sturdy Trace", 'e8fe',
    function(cmd)
        local arcNotes = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

        if #arcNotes == 0 then
            notify("Please select at least one trace.")
            return false
        end

        for _, arc in ipairs(arcNotes) do
            if arc.isVoid == false then
                notify('Arc must be Void / Trace.')
                return false
            end

            for i = 1, 3 do -- Edit this for the number of traces to be generated. (not i = 1) (3 = Three traces were generated)
                local newArc = arc.copy()
                cmd.add(newArc.save())
            end
            cmd.add(arc.delete())
        end
    end
)

-- // ADD BEATLINE // --
MacroNew(
    'floony.element', 'beatline',
    "Beatline / Timing", 'eba9',
    function(cmd)
        local request = TrackInput.requestTiming()
        coroutine.yield()
        local timing = request.result["timing"]
        local tg = Context.currentTimingGroup
        cmd.add(Event.timing(timing, Context.bpmAt(timing, tg), Context.divisorAt(timing, tg), tg).save())
    end
)

-----------------------------
--- /// FLOATING SKYTAP /// ---
-----------------------------
FolderNew("floony.element", "floony.floatskytap", "e5d6", "[Free SkyTap]")

-- // CREATE SKYTAP // --
MacroNew(
    'floony.floatskytap', 'create', 
    'Create', 'e145', 
        function (cmd)
        -- Parameters --
        local t, pos = Request.timeAndPosition()
        
        -- Programming --
        local arc = Event.arc(
            t,
            pos,
            t + 1,
            pos,
            true,
            0,
            's',
            Context.currentTimingGroup
        )
        
        cmd.add(arc.save())
        cmd.add(
            Event.arctap(
                t,
                arc
            ).save()
        )
end)

-- // STURDY SKYTAP (Make the trace look very noticeable) // --
MacroNew(
    'floony.floatskytap', 'sturdy',
    'Sturdy', 'e8fe',
    function (cmd)
    -- Parameters --
    local t, pos = Request.timeAndPosition()

    -- Programming --
    local arc = Event.arc(
        t,
        pos,
        t + 1,
        pos,
        true,
        0,
        's',
        Context.currentTimingGroup
    )

    cmd.add(arc.save())
    cmd.add(
        Event.arctap(
            t,
            arc
        ).save()
    )

    for i=0, 3 do
        cmd.add(
            Event.arc(
                t,
                pos,
                t,
                xy(pos.x, -0.2),
                true,
                0,
                's',
                Context.currentTimingGroup
            ).save()
        )
    end
end)

-- // SNAP SKYTAP TO ARC // --
MacroNew(
    'floony.floatskytap', 'snap2arc', 
    'Snap to Arc', 'e39e', 
    function (cmd)
    -- Parameters --
    local t, pos = Request.timeAndPosition()
    local arc = Request.arc('Select arc to snap to')

    -- Programming --
    local arcParent = Event.arc(
        t,
        pos,
        t + 1,
        pos,
        true,
        0,
        's',
        Context.currentTimingGroup
    )

    cmd.add(arcParent.save())
    cmd.add(
        Event.arctap(
            t,
            arcParent
        ).save()
    )

    local snappedPos = arc.positionAt(t)
    local arcConnect = Event.arc(
        t,
        pos,
        t,
        snappedPos,
        true,
        0,
        's',
        Context.currentTimingGroup
    )
    cmd.add(arcConnect.save())
end)

-- // DELETE SKYTAP // --
MacroNew(
    'floony.floatskytap', 'delete', 
    'Delete', 'e872',
    function (cmd)
    -- Parameters --
    local arctap = Request.note(EventSelectionConstraint.create().arctap()).arctap[1]
    local arc = Event.query(CustomConstraints.timeRange(arctap.timing, arctap.timing + 1)).arc
    arc = table.iselect(arc, function(_, a) return a.is 'trace' end)[1]

    -- Programming --
    cmd.add(arctap.delete())
    cmd.add(arc.delete())
end)

--[[--------------------------------------------------------------------]]--

-- // APPEARING SKYTAP // --
-- (Can be customized) --
    -- / Scrapped Function
--[[
local function detectTimingGroupName(name, command) -- I don't want to make my own function so I grab a snippet of this code by 0th, thanks <3
    for i = 1, Context.timingGroupCount - 1, 1 do
        local group = Event.getTimingGroup(i)
        if group.name == name then return group end
    end

    local tg = Event.createTimingGroup('name="'..name..'"') 
    command.add(tg.save())
    return tg
end
]]--

    -- / Function
local function detectTimingGroupName(name)
    for i = 1, Context.timingGroupCount - 1 do
        local group = Event.getTimingGroup(i)
        if group.name == name then
            return group
        end
    end
    return nil
end

    -- / Macro
MacroNewNOCMD(
    "floony.element", "skytap_appear", 
    "Appearing SkyTap", "f0fb",
    function()
        local tStart = Request.time('Select start time')
        local pos = Request.position(tStart, 'Select position')
        local tEnd = Request.time('Select end time')
        coroutine.yield()

        if tEnd < tStart then 
            notify("Start time must not be greater than end time.")
            return false 
        end

        local batchCommand = Command.create("Macro Appearing SkyTap (floony.element)")
        
        local currentBpm = Context.bpmAt(tStart, Context.currentTimingGroup)
        local timingGroup = nil

        -- Check all timing groups for one without interfering timings
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == "$floony.appear" then
                local interferingTimings = Event.query(
                    EventSelectionConstraint.create()
                        .timing()
                        .fromTiming(tStart - 1)
                        .toTiming(tEnd)
                        .ofTimingGroup(group.num)
                ).timing
                
                if #interferingTimings == 0 then
                    timingGroup = group
                    break
                end
            end
        end

        -- Create a new tg if all tg has interfering timings
        if not timingGroup then
            timingGroup = Event.createTimingGroup('name="$floony.appear"')
            batchCommand.add(timingGroup.save())
        end
        
        -- idk if this is ever used
        local interferingTimings = Event.query(
            EventSelectionConstraint.create()
                .timing()
                .fromTiming(tStart - 1)
                .toTiming(tEnd)
                .ofTimingGroup(timingGroup.num)
            ).timing
        
        for i = 1, #interferingTimings do
            batchCommand.add(interferingTimings[i].delete())
        end
        --[]
        
        local easingFunctions = {
            l = function(x) return x end,
            qi = function(x) return x * x end,
            qo = function(x) return 1 - (1 - x) * (1 - x) end
        }
        local effect = easingFunctions['l'] -- Adjust the easing here

        batchCommand.add(Event.timing(tStart, 999999, 999).save().withTimingGroup(timingGroup))

        local division = 8 -- Adjust number of timings here
        local easing = "in" -- Adjust the "actual" easing here
        for index = 0, division - 1 do
            local timing = tStart + (tEnd - tStart) * index / division + 1
            local bpm
            if easing == "out" then
                bpm = math.lerp(currentBpm * 2, 0.01, effect(index / division))
            elseif easing == "in" then
                bpm = math.lerp(0, currentBpm * 2, effect(index / division))
            end
            batchCommand.add(Event.timing(timing, bpm, 999).save().withTimingGroup(timingGroup))
        end

        local arc = Event.arc(tEnd, pos, tEnd + 1, pos, true, 0, 's')
        batchCommand.add(arc.save().withTimingGroup(timingGroup))
        batchCommand.add(Event.arctap(tEnd, arc).save().withTimingGroup(timingGroup))

        batchCommand.add(Event.timing(tEnd, currentBpm, Context.beatlineDensity).save().withTimingGroup(timingGroup))
        batchCommand.commit()
    end
)

-- // ARC BEAM // --
    -- / Function
function arclineGenerator(inversed, mid) return function(cmd)
        
    -- Parameters --
    local t, pos = Request.timeAndPosition()
    
    local y = 100
    if inversed then
        y = -y
    end

    if mid then
        y = pos.y-0.01
    end

    -- Programming --
    cmd.add(
        Event.arc(
            t,
            xy(pos.x, y),
            t,
            xy(pos.x+0.01, y),
            false,
            Context.currentArcColor,
            's',
            Context.currentTimingGroup
        ).save()
    )

end end

    -- / Folder & Macro
FolderNew('floony.element', 'floony.arcline', 'e015', '[Arc Beam]')
MacroNew('floony.arcline', 'above', 'Above', 'e5ce', arclineGenerator(false))
MacroNew('floony.arcline', 'middle', 'Middle', 'f108', arclineGenerator(false, true))
MacroNew('floony.arcline', 'below', 'Below', 'e5cf', arclineGenerator(true))

-- // DUPLICATE ARCS // --
    -- / Defaults
local intensity = 10
local spacing = 0.2

    -- / Function
function updateSettings(self)
    local dialogRequest = DialogInput.withTitle("Arc Replication Setting").requestInput(
        {
            DialogField.create("intensity")
                .setLabel("Intensity")
                .setTooltip("How many replicated arcs will be created? (Including the first)")
                .defaultTo(intensity)
                .textField(FieldConstraint.create().integer()),

            DialogField.create("spacing")
                .setLabel("Spacing")
                .setTooltip("Spacing between arcs.")
                .defaultTo(spacing)
                .textField(FieldConstraint.create().float())
        }
    )

    coroutine.yield()
    intensity = dialogRequest.result["intensity"]
    spacing = dialogRequest.result["spacing"]
end

function CopyAlongDirection(dx, dy)
    return function(cmd)
        local arcNotes = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().long()), 'arc')

        if #arcNotes == 0 then
            notify("Please select arc or trace notes.")
            return false
        end

    for _, arcs in ipairs(arcNotes) do
        for i = 1, intensity - 1 do
            local n = arcs.copy()
            n.startXY = xy(n.startX + dx * spacing * i, n.startY + dy * spacing * i)
            n.endXY = xy(n.endX + dx * spacing * i, n.endY + dy * spacing * i)
            cmd.add(n.save())
            end
        end
    end
end

    -- / Folder & Macro
FolderNew('floony.element', 'floony.copyarc', 'e3bb', '[Arc Replication]')

MacroNew('floony.copyarc', 'up', 'Upward', 'e5ce', CopyAlongDirection(0, 1))
MacroNew('floony.copyarc', 'down', 'Downward', 'e5cf', CopyAlongDirection(0, -1))
MacroNew('floony.copyarc', 'left', 'Left', 'e5cb', CopyAlongDirection(-1, 0))
MacroNew('floony.copyarc', 'right', 'Right', 'e5cc', CopyAlongDirection(1, 0))
MacroNew("floony.copyarc", "setting", "Settings", "e8b8", updateSettings)

-- // REPEAT RANGE SELECT // --
MacroNew(
    'floony.element', 'floony.repeat',
    'Events Repeat', 'e040',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup
        local duration = tEnd - tStart

        local selection = Event.query(CustomConstraints.timeRange(tStart, tEnd).ofTimingGroup(tg))
        selection = table.icollapse(selection, 'arc', 'tap', 'hold', 'arctap')
        Event.setSelection(selection)

        local dialogRequest = DialogInput.withTitle("Repeat").requestInput({
            DialogField.create('repeat')
                .setLabel('Count')
                .setTooltip('How many times to repeat the events? (1 = for custom start timing)')
                .defaultTo("1")
                .textField(FieldConstraint.create().integer()),
            DialogField.create('onlyTiming')
                .setLabel('Only Timing')
                .setTooltip('Repeat only timing events.')
                .checkbox(),
            DialogField.create('allTG')
                .setLabel('All TG')
                .setTooltip('Include all timing groups in the selected range.')
                .checkbox()
        })

        coroutine.yield()

        local rep = tonumber(dialogRequest.result['repeat']) or 1
        local onlyTiming = dialogRequest.result['onlyTiming']
        local allTG = dialogRequest.result['allTG']

        local repeatStart = tStart
        if rep == 1 then
            repeatStart = Request.time("Select timing where you want to repeat it")
        end

        local baseConstraint = CustomConstraints.timeRange(tStart, tEnd)
        if not allTG then baseConstraint = baseConstraint.ofTimingGroup(tg) end

        local function getOffset(i, evTiming)
            if rep == 1 then
                return repeatStart + (evTiming - tStart) - evTiming
            else
                return (i) * duration
            end
        end

        if onlyTiming then
            for i = 1, rep do
                for _, ev in ipairs(Event.query(baseConstraint).timing) do
                    if allTG or ev.timingGroup == tg then
                        local offset = getOffset(i, ev.timing)
                        local copy = ev.copy()
                        copy.timing = ev.timing + offset
                        cmd.add(copy.save())
                    end
                end
            end
            return
        end

        local events = Event.query(baseConstraint)
        events = table.icollapse(events, 'arc', 'tap', 'hold', 'timing', 'arctap', 'scenecontrol')

        local filtered, arcMap = {}, {}

        for _, ev in ipairs(events) do
            if allTG or ev.timingGroup == tg then
                table.insert(filtered, ev)
            end
        end

        for i = 1, rep do
            local offsetCache = {}

            for _, ev in ipairs(filtered) do
                local offset = offsetCache[ev.timing]
                if not offset then
                    offset = getOffset(i, ev.timing)
                    offsetCache[ev.timing] = offset
                end

                if ev.is 'arc' then
                    local arc = Event.arc(
                        ev.timing + offset, ev.startX, ev.startY,
                        ev.endTiming + offset, ev.endX, ev.endY,
                        ev.isTrace, ev.color, ev.type,
                        ev.timingGroup, ev.sfx
                    )
                    arcMap[ev] = arc
                    cmd.add(arc.save())

                elseif ev.is 'arctap' then
                    local refArc = ev.arc
                    if arcMap[refArc] or (allTG and refArc) then
                        cmd.add(Event.arcTap(ev.timing + offset, arcMap[refArc] or refArc).save())
                    end

                else
                    local copy = ev.copy()
                    copy.timing = ev.timing + offset
                    if copy.is 'long' then
                        copy.endTiming = copy.endTiming + offset
                    end
                    cmd.add(copy.save())
                end
            end
        end
    end
)

-- // SCRAPPED MACRO // --
--[[ // okay I'm not going to work on this
addFolderWithIcon('floony.element', 'floony.notestash', 'e1a1', 'Stashes')
storedStashes = {}
local stashCount = 0

addCommandMacroWithIcon('floony.notestash', 'floony.notestash.stashcreate', 'Create', 'e145', function(cmd)
    local tStart, tEnd = Request.timeRange()
    local noteEvents = table.icollapse(Event.query(CustomConstraints.timeRange(tStart, tEnd)), 'arc', 'arctap', 'hold', 'tap', 'timing')
    
    stashCount = stashCount + 1
    
    coroutine.yield()
    local dialogNameRequest = DialogInput.withTitle("Stash creation").requestInput({
        DialogField.create("name")
            .setLabel("Name")
            .setHint("Enter a name for stash")
            .setTooltip("Your stash name will be included in the newly created macro's name")
    })

    coroutine.yield()
    local name = dialogNameRequest.result["name"]
    storedStashes[name] = noteEvents
    dialogNotify("Notes events stored as '" .. name .. "' for later use.")

    local macroTitle = 'Stash ' .. stashCount .. ': ' .. name

    addMacroWithIcon('floony.notestash', 'floony.stashes.' .. stashCount, macroTitle, 'ea50', function()
        local stash = storedStashes[name]

        local timingRequest = TrackInput.requestTiming("Select where to paste your stash")
        coroutine.yield()
        local timing = timingRequest.result["timing"]

        local batchCommand = Command.create("Pasting stash " .. name)

        for i, event in ipairs(stash) do    
            local ev = event.copy()
            local origin = stash[1].timing
            local displace = timing - origin    
            ev.timing = displace + event.timing

            if ev.is('long') then
                ev.endTiming = displace + ev.endTiming
            end

            batchCommand.add(ev.save())
            
            -- TODO: fix this (man i hate handling with arctap akjdhuiqwh)
            if ev.is('arc') then
            local arc = ev
                for _, arctap in ipairs(stash) do
                    if arctap.arc == event then
                        local arctapCopy = arctap.copy()
                        arctapCopy.arc = ev
                        arctapCopy.timing = displace + arctap.timing
                        batchCommand.add(arctapCopy.save())
                    end
                end
            end
        end

        batchCommand.commit()
    end)
end)
]]--