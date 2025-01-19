require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // SPECIAL ELEMENTS // --        | (My absolute favorites :heart_eyes:)
------------------------------------/
FolderNew('floony', 'floony.special', 'f0ec', '- Special Elements -')

--------------------------------------
--- ///  FAKE NOTES -- TRACES  /// --- i wonder if i should change the methods of the execution, hmmm...
--------------------------------------
    -- / FLOOR / --
function floornote(t1, t2, a, b, tg, isHold)
    local cmd = Command.create("")

    local function addArc(startTiming, endTiming, startLane, endLane)
        cmd.add(
            Event.arc(
                startTiming,
                xy(startLane, -0.2),
                endTiming,
                xy(endLane, -0.2),
                true,
                0,
                's',
                tg
            ).save()
        )
    end

    addArc(t1, t2, a, a)
    addArc(t1, t2, b, b)
    addArc(t1, t1, a, b)
    addArc(t2, t2, a, b)

    if isHold then
        addArc(t1, t2, (a + b) / 2, (a + b) / 2)
    end

    cmd.commit()
end

    -- / ARC / --
function arctotraceGen(arc)
    local cmd = Command.create("")
    local function addArc(startTiming, endTiming, startX, startY, endX, endY)
        cmd.add(
            Event.arc(
                startTiming,
                xy(startX, startY),
                endTiming,
                xy(endX, endY),
                true,
                0,
                arc.type,
                arc.timingGroup
            ).save()
        )
    end
    
    -- Vertical Line
    local function addVerticalLine()
        addArc(arc.timing, arc.timing, arc.startXY.x, arc.startXY.y - 0.15, arc.startXY.x, -0.2)
    end
    
    -- Top
    addArc(arc.timing, arc.endTiming, arc.startXY.x, arc.startXY.y + 0.1, arc.endXY.x, arc.endXY.y + 0.1)
    --[[ Bottom
    addArc(arc.timing, arc.endTiming, arc.startXY.x, arc.startXY.y - 0.15, arc.endXY.x, arc.endXY.y - 0.15)
    ]]--
    -- Left
    addArc(arc.timing, arc.endTiming, arc.startXY.x - 0.1, arc.startXY.y - 0.07, arc.endXY.x - 0.1, arc.endXY.y - 0.07)
    -- Right
    addArc(arc.timing, arc.endTiming, arc.startXY.x + 0.1, arc.startXY.y - 0.07, arc.endXY.x + 0.1, arc.endXY.y - 0.07)
    
    -- Face Cap
    addArc(arc.timing, arc.timing, arc.startXY.x, arc.startXY.y + 0.1, arc.startXY.x + 0.1, arc.startXY.y - 0.07) -- Right Top
    addArc(arc.timing, arc.timing, arc.startXY.x + 0.1, arc.startXY.y - 0.07, arc.startXY.x, arc.startXY.y - 0.15) -- Right Bottom
    addArc(arc.timing, arc.timing, arc.startXY.x, arc.startXY.y - 0.15, arc.startXY.x - 0.1, arc.startXY.y - 0.07) -- Left Bottom
    addArc(arc.timing, arc.timing, arc.startXY.x - 0.1, arc.startXY.y - 0.07, arc.startXY.x + 0, arc.startXY.y + 0.1) -- Left Top
    
    -- End Cap
    addArc(arc.endTiming, arc.endTiming, arc.endXY.x, arc.endXY.y + 0.1, arc.endXY.x + 0.1, arc.endXY.y - 0.07)
    addArc(arc.endTiming, arc.endTiming, arc.endXY.x + 0.1, arc.endXY.y - 0.07, arc.endXY.x, arc.endXY.y - 0.15)
    addArc(arc.endTiming, arc.endTiming, arc.endXY.x, arc.endXY.y - 0.15, arc.endXY.x - 0.1, arc.endXY.y - 0.07)
    addArc(arc.endTiming, arc.endTiming, arc.endXY.x - 0.1, arc.endXY.y - 0.07, arc.endXY.x + 0, arc.endXY.y + 0.1)
    
    addVerticalLine()
    
    cmd.commit()
end

    -- // MACRO // --
FolderNew("floony.special", "floony.convert2trace", "e028", "[Notes to Trace]")

MacroNew(
    'floony.convert2trace', 'voidtap',
    'Tap', 'e5da',
    function (cmd)
    
	local tap = Request.tap("Select a Tap")
	
	local depth = 15
	
	floornote(tap.timing, tap.timing+depth, tap.lane/2-0.975, tap.lane/2-0.525, tap.timingGroup, false)
    cmd.add(tap.delete())
end
)

MacroNew(
    'floony.convert2trace', 'voidhold',
    'Hold', 'e5da',
    function (cmd)
    
	local hold = Request.hold("Select a Hold")
	
	floornote(hold.timing, hold.endTiming, hold.lane/2-0.975, hold.lane/2-0.525, hold.timingGroup, true)
    cmd.add(hold.delete())
end
)

MacroNew(
    'floony.convert2trace', 'voidarc',
    'Arc', 'e5da',
    function (cmd)
    
	local arc = Request.arc("Select an Arc")
	
    if (arc.isVoid == true) then
            notify("The arc must not be trace.")
        return false
    end
    
    arctotraceGen(arc)
    cmd.add(arc.delete())
end
)

    -- // MACRO (SKYTAP) // --
MacroNew(
    'floony.convert2trace', 'voidskytap',
    'SkyTap', 'e5da',
    function (cmd)

        local time, place = Request.timeAndPosition()

        local function addTrace(startX, startY, endX, endY)
            cmd.add(
                Event.arc(
                    time, xy(startX, startY),
                    time + 10, xy(endX, endY),
                    true, 0, 's', Context.currentTimingGroup
                ).save()
            )
        end
        
        local function addTrace0ms(t, startX, startY, endX, endY)
            cmd.add(
                Event.arc(
                    t, xy(startX, startY),
                    t, xy(endX, endY),
                    true, 0, 's', Context.currentTimingGroup
                ).save()
            )
        end

        for _, t in ipairs {time, time + 10} do
            addTrace0ms(t, place.x - 0.23, place.y, place.x + 0.23, place.y)
            addTrace0ms(t, place.x - 0.23, place.y - 0.16, place.x + 0.23, place.y - 0.16)
            addTrace0ms(t, place.x + 0.23, place.y, place.x + 0.23, place.y - 0.16)
            addTrace0ms(t, place.x - 0.23, place.y, place.x - 0.23, place.y - 0.16)
        end

        addTrace(place.x - 0.23, place.y, place.x - 0.23, place.y)
        addTrace(place.x + 0.23, place.y, place.x + 0.23, place.y)
        addTrace(place.x - 0.23, place.y - 0.16, place.x - 0.23, place.y - 0.16)
        addTrace(place.x + 0.23, place.y - 0.16, place.x + 0.23, place.y - 0.16)

    end
)

function createArctapArc(cmd, time, place, offsetX, offsetY)
    cmd.add(
        Event.arc(
            time, xy(place.x + offsetX, place.y + offsetY),
            time, xy(place.x - offsetX, place.y + offsetY),
            true, 0, 's'
        ).save()
    )
end

function createArctapTrace(cmd, arc, time)
    if not arc.isVoid then
        notify("The arc must be a trace.")
        return false
    end

    for _, t in ipairs {time, time + 10} do
        local place = arc.positionAt(t)
        createArctapArc(cmd, t, place, 0.23, 0)
        createArctapArc(cmd, t, place, 0.23, -0.16)
        createArctapArc(cmd, t, place, -0.23, 0)
        createArctapArc(cmd, t, place, -0.23, -0.16)
    end
end

    -- // MACRO (SKYTAP) 2 // --
MacroNew(
    'floony.convert2trace', 'voidskytap_ontrace',
    'SkyTap (On Trace)', 'e5da',
    function (cmd)

        local arc = Request.arc("Select a Trace")
	
        if (arc.isVoid == false) then
            notify("The arc must be trace.")
            return false
        end
        
        local time = Request.time("Select timing")
        local place = arc.positionAt(time)
        
        local function addTrace(startX, startY, endX, endY)
            cmd.add(
                Event.arc(
                    time, xy(startX, startY),
                    time + 10, xy(endX, endY),
                    true, 0, 's', Context.currentTimingGroup
                ).save()
            )
        end
        
        local function addTrace0ms(t, startX, startY, endX, endY)
            cmd.add(
                Event.arc(
                    t, xy(startX, startY),
                    t, xy(endX, endY),
                    true, 0, 's', Context.currentTimingGroup
                ).save()
            )
        end

        for _, t in ipairs {time, time + 10} do
            addTrace0ms(t, place.x - 0.23, place.y, place.x + 0.23, place.y)
            addTrace0ms(t, place.x - 0.23, place.y - 0.16, place.x + 0.23, place.y - 0.16)
            addTrace0ms(t, place.x + 0.23, place.y, place.x + 0.23, place.y - 0.16)
            addTrace0ms(t, place.x - 0.23, place.y, place.x - 0.23, place.y - 0.16)
        end

        addTrace(place.x - 0.23, place.y, place.x - 0.23, place.y)
        addTrace(place.x + 0.23, place.y, place.x + 0.23, place.y)
        addTrace(place.x - 0.23, place.y - 0.16, place.x - 0.23, place.y - 0.16)
        addTrace(place.x + 0.23, place.y - 0.16, place.x + 0.23, place.y - 0.16)

    end
)

--[[--------------------------------------------------------------------]]--

-- // FAKE NOTES - SHADOW // --

--- // Function for ARCTAP (why do I need this? i mean thanks tho, imrich)
---@return table
function GetSkyNotesFromSelectedTraces()
    -- Get all the selected traces
    local onlyTraces = EventSelectionConstraint.create().trace()
    local traceSelections = Event.getCurrentSelection(onlyTraces)

    -- If no traces are selected, just return an empty table
    if #traceSelections.resultCombined == 0 then
        return {}
    end

    -- Initialize table for all unique arctaps
    local totalArcTaps = {}
    local existingArctaps = {}

    -- Iterate through the selected traces and gather arctaps for each trace
    for _, trace in ipairs(traceSelections.arc) do
        -- Get arctaps within the trace's timing range
        local onlyArcTaps = EventSelectionConstraint.create()
            .fromTiming(trace.timing)
            .toTiming(trace.endTiming)
            .arcTap()
        local arcTapSelection = Event.query(onlyArcTaps)

        -- Filter out arctaps that are not part of the current trace
        for _, arctap in ipairs(arcTapSelection.arctap) do
            if arctap.arc.instanceEquals(trace) then
                -- Check for duplicates before adding
                if not existingArctaps[arctap] then
                    table.insert(totalArcTaps, arctap)
                    existingArctaps[arctap] = true
                end
            end
        end
    end

    return totalArcTaps
end

-- // Main Macro
MacroNew(
    'floony.special', 'floony.convert2shadow',
    "Notes to Shadow", "e427",
    function(cmd)
        local selectedNotes = Event.getCurrentSelection(EventSelectionConstraint.create().any())
        selectedNotes = table.icollapse(selectedNotes, 'arc', 'tap', 'hold', 'arctap')

        if #selectedNotes == 0 then
            notify("Please select at least one note.")
            return false
        end

        -- Check if the timing group already exists, so it won't overload
        local timingGroup = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == "$floony.shadow" then
                timingGroup = group
                break
            end
        end

        -- Create a new timing group if it does not exist
        if not timingGroup then
            timingGroup = Event.createTimingGroup('name="$floony.shadow", noinput,noheightindicator')
            cmd.add(timingGroup.save())
        end
        
        local absurdlyHighY = 100
        
        -- Iterate through all selected notes
        for _, note in ipairs(selectedNotes) do
            -- // HOLD
            if note.is('hold') then
                local lane = note.lane

                local startXY1 = xy((lane / 2 - 0.75) - 0.12, absurdlyHighY)
                local endXY1 = startXY1

                local startXY2 = xy((lane / 2 - 0.75) + 0.12, absurdlyHighY)
                local endXY2 = startXY2

                -- First Arc
                cmd.add(
                    Event.arc(
                        note.timing, startXY1, note.endTiming, endXY1,
                        false, 0, 's'
                    ).save().withTimingGroup(timingGroup)
                )

                -- Second Arc
                cmd.add(
                    Event.arc(
                        note.timing, startXY2, note.endTiming, endXY2,
                        false, 1, 's'
                    ).save().withTimingGroup(timingGroup)
                )
            end

            -- // TAP
            if note.is('tap') then
                local lane = note.lane

                local startXY = xy((lane / 2 - 0.63), absurdlyHighY)
                local endXY = xy((lane / 2 - 1.08), absurdlyHighY)

                cmd.add(
                    Event.arc(
                        note.timing, startXY, note.timing, endXY,
                        false, 0, 's'
                    ).save().withTimingGroup(timingGroup)
                )
            end

            -- // ARC
            if note.is('arc') then
                local startXY = xy(note.startX, absurdlyHighY)
                local endXY = xy(note.endX, absurdlyHighY)

                cmd.add(
                    Event.arc(
                        note.timing, startXY, note.endTiming, endXY,
                        note.isVoid, note.color, note.type
                    ).save().withTimingGroup(timingGroup)
                )
            end
        end
        
        -- // ARCTAP - only if traces are selected or if there are any arctaps in the selection and i hate this
        local arctaps = GetSkyNotesFromSelectedTraces()
        if #arctaps == 0 then
            for _, note in ipairs(selectedNotes) do
                if note.is('arctap') then
                    table.insert(arctaps, note)
                end
            end
        end

        for _, arctap in ipairs(arctaps) do
            local arc = arctap.arc
            if not arc then
                notify("No arc associated with this arctap.")
                return
            end

            local position = arc.positionAt(arctap.timing, true)
            
            local startXY = xy(position.x - 0.15, absurdlyHighY)
            local endXY = xy(position.x + 0.35, absurdlyHighY)
                
            cmd.add(
                Event.arc(
                    arctap.timing, startXY, arctap.timing, endXY,
                    false, arc.color, arc.type
                ).save().withTimingGroup(timingGroup)
            )
        end
    end
)


--[[--------------------------------------------------------------------]]--

-- // STASH TIMING // --
    -- / I just copy paste this from camera stash and modify it to only pick timing, oop
FolderNew('floony.special', 'floony.timingstash', 'ec09', 'Timing Stash')
storedTimings = {}
local stashCount = 0

    -- / Macro
MacroNew(
    'floony.timingstash', 'stashcreate', 
    'Create', 'e145',
    function(cmd)
    local tStart, tEnd = Request.timeRange()
    local timingEvents = table.icollapse(Event.query(CustomConstraints.timeRange(tStart, tEnd)), 'timing')

    if #timingEvents == 0 then
        notify("No timing events detected.")
        return false
    end

    coroutine.yield()

    stashCount = stashCount + 1

    local dialogNameRequest = DialogInput.withTitle("Timing Stash Name").requestInput({
        DialogField.create('timingCount')
            .description(tostring(#timingEvents) .. ' timing events detected!'),
        DialogField.create("name")
            .setLabel("Name")
            .setHint("Enter a name for the timing stash")
            .setTooltip("Your stash name will be included in the newly created macro's name"),
    })

    coroutine.yield()
    local name = dialogNameRequest.result["name"]
    storedTimings[name] = timingEvents
    dialogNotify("Timing events stored as '" .. name .. "' for later use.")

    local macroTitle = 'Stash ' .. stashCount .. ': ' .. name

    MacroNewNOCMD('floony.timingstash', 'floony.stashes.' .. stashCount, macroTitle, 'ea50', function()
        local stash = storedTimings[name]

        local timingRequest = TrackInput.requestTiming("Select where to paste your stash")
        coroutine.yield()
        local timing = timingRequest.result["timing"]
        local batchCommand = Command.create("Pasting Stash " .. name)

        for i, event in ipairs(stash) do
            local ev = event.copy()
            local origin = stash[1].timing
            local displace = timing - origin
            ev.timing = displace + event.timing

            batchCommand.add(ev.save())
        end

        batchCommand.commit()
    end)
end)

-- // SCRAPPED MACRO // --
--[[
addFolderWithIcon('floony.special', 'floony.ptrnswitch', 'e8d4', 'Pattern Switcher')

addCommandMacroWithIcon('floony.ptrnswitch', 'floony.ptrnswitch.create', 'New', 'e145', function(cmd)
storedTimings = {}
local stashCount = 0

        local requestNotes = EventSelectionInput.requestEvents(EventSelectionConstraint.create().any(),
            "Select Notes. For selecting many notes, cancel the macro and select most of the notes beforehand.")
        coroutine.yield()

    if #requestNotes == 0 then
        dialogNotify("No notes selected.")
        return
    end

    coroutine.yield()

    stashCount = stashCount + 1

    local dialogNameRequest = DialogInput.withTitle("Pattern Name").requestInput({
        DialogField.create("name")
            .setLabel("Name")
            .setHint("Enter a name for the pattern")
            .setTooltip("If left empty, it will defaulted to 'Pattern 1'"),
    })

    coroutine.yield()
    local name = dialogNameRequest.result["name"]
    storedTimings[name] = notesEvents
    dialogNotify("Pattern stored as '" .. name)

    local macroTitle = 'Pattern ' .. stashCount .. ': ' .. name

    addMacroWithIcon('floony.timingstash', 'floony.stashes.' .. stashCount, macroTitle, 'ea50', function()
        local stash = storedTimings[name]

        local timingRequest = TrackInput.requestTiming("Select where to paste your stash")
        coroutine.yield()
        local timing = timingRequest.result["timing"]
        local batchCommand = Command.create("Pasting Stash " .. name)

        for i, event in ipairs(stash) do
            local ev = event.copy()
            local origin = stash[1].timing
            local displace = timing - origin
            ev.timing = displace + event.timing

            batchCommand.add(ev.save())
        end

        batchCommand.commit()
    end)
end)
]]--

-- // TAP TO HIDEGROUP // --
    -- / Folder
FolderNew('floony.special', 'floony.taptosc', 'f1d1', '[Tap to Hidegroup]')

    -- / Macro (Hide)
MacroNew(
    'floony.taptosc', 'hide',
    '1 > 0... (Hide First)', 'e3f1',
    function(cmd)
        local tapnotes = Event.getCurrentSelection(EventSelectionConstraint.create().tap()).tap

        if #tapnotes < 2 then
            notify('Please select exactly / more than 2 tap notes.')
            return false
        end

        for index, tapnote in ipairs(tapnotes) do
            local args = (index % 2 == 0) and '0' or 1
            cmd.add(Event.scenecontrol(tapnote.timing, 'hidegroup', Context.currentTimingGroup, '0', args).save())
            cmd.add(tapnote.delete())
        end
    
    end
)

    -- / Macro (Unhide)
MacroNew(
    'floony.taptosc', 'unhide',
    '0 > 1... (Unhide First)', 'e3f2',
    function(cmd)
        local tapnotes = Event.getCurrentSelection(EventSelectionConstraint.create().tap()).tap

        if #tapnotes < 2 then
            notify('Please select exactly / more than 2 tap notes.')
            return false
        end

        for index, tapnote in ipairs(tapnotes) do
            local args = (index % 2 == 0) and 1 or '0'
            cmd.add(Event.scenecontrol(tapnote.timing, 'hidegroup', Context.currentTimingGroup, '0', args).save())
            cmd.add(tapnote.delete())
        end
    
    end
)

-- // HOLD TO GROUPALPHA // --
    -- / Folder
FolderNew('floony.special', 'floony.holdtoalpha', 'e919', '[Hold to Groupalpha]')

    -- / Macro (Normal)
MacroNew(
    'floony.holdtoalpha', 'alphanormal',
    'Normal', 'e145',
    function(cmd)
        local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
        longNotes = table.icollapse(longNotes, 'arc', 'hold')

        if #longNotes == 0 then
            notifyWarn("Select at least one long note.")
            return false
        end

        local dialogFields = {
            DialogField.create("alphaTo")
                .setLabel("Alpha")
                .setTooltip("Where should alpha be set next?")
                .textField(FieldConstraint.create().float())
        }

        local dialogRequest = DialogInput.withTitle("Hold to Group Alpha").requestInput(dialogFields)
        coroutine.yield()

        local alphaToInput = dialogRequest.result["alphaTo"]
        local alphaTo = (alphaToInput == "0") and "0" or tonumber(alphaToInput)

        for _, holdnote in ipairs(longNotes) do
            local duration = holdnote.endTiming - holdnote.timing
            cmd.add(Event.scenecontrol(holdnote.timing, 'groupalpha', Context.currentTimingGroup, duration, alphaTo).save())
            cmd.add(holdnote.delete())
        end
    end
)

    -- / Macro (Flicker)
local alphaInitial = nil
local alphaEnd = nil
MacroNew(
    'floony.holdtoalpha', 'alphaflick',
    'Flick', 'e3e7',
    function(cmd)
        local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
        longNotes = table.icollapse(longNotes, 'arc', 'hold')
        
            if #longNotes == 0 then
                notifyWarn("Select at least one long note.")
                return false
            end
        
        local dialogFields = {
            DialogField.create("alphaInitial")
                .setLabel("Initial Alpha")
                .setTooltip("Starting alpha value.")
                .defaultTo(alphaInitial)
                .textField(FieldConstraint.create().float()),
                
            DialogField.create("alphaEnd")
                .setLabel("End Alpha")
                .setTooltip("Final alpha value.")
                .defaultTo(alphaEnd)
                .textField(FieldConstraint.create().float())
        }

        local dialogRequest = DialogInput.withTitle("Hold to Group Alpha").requestInput(dialogFields)
        coroutine.yield()
        
        alphaInitial = dialogRequest.result["alphaInitial"] == "0" and "0" or tonumber(dialogRequest.result["alphaInitial"])
        alphaEnd = dialogRequest.result["alphaEnd"] == "0" and "0" or tonumber(dialogRequest.result["alphaEnd"])

        for _, holdnote in ipairs(longNotes) do
            local duration = (holdnote.endTiming - holdnote.timing)
            cmd.add(Event.scenecontrol(holdnote.timing, 'groupalpha', Context.currentTimingGroup, 1, alphaInitial).save())
            cmd.add(Event.scenecontrol(holdnote.timing + 1, 'groupalpha', Context.currentTimingGroup, duration - 1, alphaEnd).save())
            cmd.add(holdnote.delete())
        end
    end
)

-- // FLICKER SCENECONTROL // --
local scType = ""
local startArgsNum = 0
local endArgsNum = 0.0001
MacroNew(
    'floony.special', 'flashingsc',
    'Flashing SC', 'e3e7',
    function(cmd)
    
    local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
    longNotes = table.icollapse(longNotes, 'arc', 'hold')

        if #longNotes == 0 then
            notifyWarn("Select at least one long note.")
            return false
        end
        
        local dialogRequest = DialogInput.withTitle('Flashing Scenecontrol').requestInput({
            DialogField.create("prerequisite")
                .description('Make sure the following Scenecontrol format are: \nscenecontrol(timing,type,duration,start/end);'),
                
            DialogField.create("type")
                .setLabel("Type")
                .defaultTo(scType)
                .setTooltip('The name of the Scenecontrol')
                .textField(FieldConstraint.create().any()),
            
            DialogField.create("startNum")
                .setLabel("Start Value")
                .defaultTo(startArgsNum)
                .setTooltip('Starting Flash')
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("endNum")
                .setLabel("End Value")
                .defaultTo(endArgsNum)
                .setTooltip('Value at the End')
                .textField(FieldConstraint.create().any()),

            DialogField.create("duration")
                .description('Duration are based of the selected Long Notes')                
        })
        
        coroutine.yield()
        scType = dialogRequest.result["type"]
        startArgsNum = tonumber(dialogRequest.result["startNum"])
        endArgsNum = tonumber(dialogRequest.result["endNum"])
        
    for _, hold in ipairs(longNotes) do
        local tg = hold.timingGroup
        local duration = hold.endTiming - hold.timing - 1
        
        if startArgsNum or endArgsNum ~= 0 then
            cmd.add(Event.scenecontrol(hold.timing, scType, tg, 1, startArgsNum).save())
            cmd.add(Event.scenecontrol(hold.timing + 1, scType, tg, duration, endArgsNum).save())
            
            cmd.add(hold.delete())
        else
            dialogNotify("The value cannot be 0.\nWorkaround: Use 0.0001")
        end
    end
end
)

-----------------------------
--- /// CAMERA FOLDER /// ---
-----------------------------
FolderNew('floony.special', 'floony.camera', 'e439', '[Camera]')

-- // ADD CAMERA // --
MacroNew(
    'floony.camera', 'cam_blank',
    'Blank', 'e145',
    function(cmd)
    
        local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
        longNotes = table.icollapse(longNotes, 'arc', 'hold')
        
        if #longNotes == 0 then
            notifyWarn("Select at least one long note.")
            return false
        end
            
        for _, hold in ipairs(longNotes) do
            local duration = (hold.endTiming - hold.timing)
            cmd.add(Event.camera(hold.timing, 0, 0, 0, 0, 0, 0, 'l', duration, Context.currentTimingGroup).save())
            cmd.add(hold.delete())
        end
    end
)

-- // CAMERA REPEAT // --
MacroNew(
    'floony.camera', 'cam_repeat',
    'Repeat', 'e040',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local TimingGroup = Context.currentTimingGroup
        local cameraEvents = Event.query(EventSelectionConstraint.camera().fromTiming(tStart).toTiming(tEnd).ofTimingGroup(TimingGroup)).camera
        local cameraCount = #cameraEvents
        
        if #cameraEvents == 0 then
            notify("No camera events detected.")
            return false
        end
        
        local dialogRequest = DialogInput.withTitle("Repeat").requestInput({
            DialogField.create('cameraCount')
                .description(tostring(cameraCount) .. ' camera events detected!'),        
            DialogField.create('repeat')
                .setLabel('Count')
                .setTooltip('How many times should the selected camera events be repeated?')
                .textField(FieldConstraint.create().integer()),
            DialogField.create('mirror')
                .setLabel('Mirror')
                .setTooltip('Mirror the camera events')
                .checkbox(),
            DialogField.create('alternate')
                .setLabel('Alternate')
                .setTooltip('Alternate between original and mirrored camera events')
                .checkbox()
        })
        
        coroutine.yield()
        local rep = tonumber(dialogRequest.result['repeat'])
        local mirrorCamera = dialogRequest.result['mirror']        
        local alternate = dialogRequest.result['alternate']        

        for i = 1, rep do
            for _, event in ipairs(cameraEvents) do
                local ev = event.copy()
                ev.timing = event.timing + i * (tEnd - tStart)
                if mirrorCamera or alternate and i % 2 == 1 then
                    ev.x = -ev.x
                    -- ev.y = -ev.y
                    -- ev.z = -ev.z
                    ev.rx = -ev.rx
                    -- ev.ry = -ev.ry
                    ev.rz = -ev.rz
                end
            cmd.add(ev.save())
            end
        end
    end
)

-- // BOUNCING CAMERA // --
local intensity = 1
MacroNew(
    'floony.camera', 'cam_bounce',
    'Bounce', 'e7d0',
    function(cmd)
    
    local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
    longNotes = table.icollapse(longNotes, 'arc', 'hold')

        if #longNotes == 0 then
            notifyWarn("Select at least one long note.")
            return false
        end
    
        local dialogRequest = DialogInput.withTitle('Bouncing Camera').requestInput({
            DialogField.create("hintPos")
                .description('You can use negative intensity for Counter Position'),
            DialogField.create("intensity")
                .setLabel("intensity")
                .defaultTo(intensity)
                .setTooltip('How strong the Bounce should be?')
                .textField(FieldConstraint.create().float()),
            DialogField.create("dir_pos")
                .setLabel("Bounce to (Position)")
                .setTooltip('At which Position should the camera goes?')
                .dropdownMenu('None', 'Xposition (Left [+] / Right [-])', 'Yposition (Down [+] / Up [-])', 'Zposition (Forward [+] / Backward [-])'),
            DialogField.create("dir_rot")
                .setLabel("Bounce to (Rotation)")
                .setTooltip('At which Rotation should the camera goes?')
                .dropdownMenu('None', 'Xrotation (Right [+] / Left [-])', 'Yrotation (Down [+] / Up [-])', 'Zrotation (Right [+] / Left [-])'),
            DialogField.create("alternate")
                .setLabel("Alternating")
                .setTooltip('Whether the Camera alternating back and forth?')
                .checkbox(),
            DialogField.create("reversed")
                .setLabel("Inverse Ease")
                .setTooltip('Whether the Easing inverted (qo, qi into qi, qo)?')
                .checkbox()
        })
        
        coroutine.yield()
        intensity = tonumber(dialogRequest.result["intensity"])
        local dir_pos = (dialogRequest.result["dir_pos"])
        local dir_rot = (dialogRequest.result["dir_rot"])
        local alternate = dialogRequest.result['alternate']
        local reversed = dialogRequest.result['reversed']
        
        local bounceHeight = intensity * 50
        
        if dir_pos == 'None' and dir_rot == 'None' then
            notify("Specify at least one direction / Position")
        return false
    end
    
    for _, hold in ipairs(longNotes) do
        local tg = hold.timingGroup
        local duration = (hold.endTiming - hold.timing) / 2
        
        if alternate == true then
            local altMultiplier = 1
            for index, _ in ipairs(longNotes) do
                if index % 2 == 0 then
                    altMultiplier = altMultiplier * -1
                end
            end
            bounceHeight = bounceHeight * altMultiplier
        end        
        
        local easing1 = 'qo'
        local easing2 = 'qi'
            
        if reversed == true then
            easing1 = 'qi'
            easing2 = 'qo'
        else
            easing1 = 'qo'
            easing2 = 'qi'
        end
        
        -- Position
        if string.find(dir_pos, 'Yposition') then
        cmd.add(Event.camera(hold.timing, 0, bounceHeight, bounceHeight, 0, 0, 0, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, 0, -bounceHeight, -bounceHeight, 0, 0, 0, easing2, duration, Context.currentTimingGroup).save())
        end

        if string.find(dir_pos, 'Xposition') then
        cmd.add(Event.camera(hold.timing, bounceHeight, 0, 0, 0, 0, 0, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, -bounceHeight, 0, 0, 0, 0, 0, easing2, duration, Context.currentTimingGroup).save())
        end
        
        if string.find(dir_pos, 'Zposition') then
        cmd.add(Event.camera(hold.timing, 0, 0, bounceHeight, 0, 0, 0, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, 0, 0, -bounceHeight, 0, 0, 0, easing2, duration, Context.currentTimingGroup).save())
        end
        
        -- Rotation
        if string.find(dir_rot, 'Xrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, bounceHeight / 15, 0, 0, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, 0, 0, 0, -bounceHeight / 15, 0, 0, easing2, duration, Context.currentTimingGroup).save())
        end       

        if string.find(dir_rot, 'Yrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, 0, bounceHeight / 15, 0, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, 0, 0, 0, 0, -bounceHeight / 15, 0, easing2, duration, Context.currentTimingGroup).save())
        end     

        if string.find(dir_rot, 'Zrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, 0, 0, bounceHeight / 15, easing1, duration, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + duration, 0, 0, 0, 0, 0, -bounceHeight / 15, easing2, duration, Context.currentTimingGroup).save())
        end
        
        cmd.add(hold.delete())
    end
end
)

-- // FLICKER CAMERA // --
MacroNew(
    'floony.camera', 'cam_flick',
    'Flick', 'e3e7',
    function(cmd)
    
    local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
    longNotes = table.icollapse(longNotes, 'arc', 'hold')

        if #longNotes == 0 then
            notifyWarn("Select at least one long note.")
            return false
        end
        
        local dialogRequest = DialogInput.withTitle('Flicking Camera').requestInput({
            DialogField.create("hintPos")
                .description('You can use negative intensity for Counter Position'),
            DialogField.create("intensity")
                .setLabel("intensity")
                .defaultTo(intensity)
                .setTooltip('How strong the Flick should be?')
                .textField(FieldConstraint.create().float()),
            DialogField.create("dir_pos")
                .setLabel("Flick to (Position)")
                .setTooltip('At which Position should the camera goes?')
                .dropdownMenu('None', 'Xposition (Left [+] / Right [-])', 'Yposition (Down [+] / Up [-])', 'Zposition (Forward [+] / Backward [-])'),
            DialogField.create("dir_rot")
                .setLabel("Flick to (Rotation)")
                .setTooltip('At which Rotation should the camera goes?')
                .dropdownMenu('None', 'Xrotation (Right [+] / Left [-])', 'Yrotation (Down [+] / Up [-])', 'Zrotation (Right [+] / Left [-])'),
            DialogField.create("easing")
                .setLabel("Easing")
                .setTooltip('The easing to use')
                .dropdownMenu('qo', 'l', 'qi', 's'),
            DialogField.create("alternate")
                .setLabel("Alternating")
                .setTooltip('Whether the Camera alternating back and forth?')
                .checkbox()
        })
        
        coroutine.yield()
        intensity = tonumber(dialogRequest.result["intensity"])
        local alternate = dialogRequest.result['alternate']
        local dir_pos = (dialogRequest.result["dir_pos"])
        local dir_rot = (dialogRequest.result["dir_rot"])
        local easing = (dialogRequest.result["easing"])
        
        local flashHeight = intensity * 50
        
        if dir_pos == 'None' and dir_rot == 'None' then
            notify("Specify at least one direction / Position")
        return false
    end
    
    for _, hold in ipairs(longNotes) do
        local tg = hold.timingGroup
        local duration = hold.endTiming - hold.timing - 1
        
        if alternate == true then
            local altMultiplier = 1
            for index, _ in ipairs(longNotes) do
                if index % 2 == 0 then
                    altMultiplier = altMultiplier * -1
                end
            end
            flashHeight = flashHeight * altMultiplier
        end
        
        -- Position
        if string.find(dir_pos, 'Yposition') then
        cmd.add(Event.camera(hold.timing, 0, flashHeight, flashHeight, 0, 0, 0, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, 0, -flashHeight, -flashHeight, 0, 0, 0, easing, duration, Context.currentTimingGroup).save())
        end

        if string.find(dir_pos, 'Xposition') then
        cmd.add(Event.camera(hold.timing, flashHeight, 0, 0, 0, 0, 0, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, -flashHeight, 0, 0, 0, 0, 0, easing, duration, Context.currentTimingGroup).save())
        end
        
        if string.find(dir_pos, 'Zposition') then
        cmd.add(Event.camera(hold.timing, 0, 0, flashHeight, 0, 0, 0, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, 0, 0, -flashHeight, 0, 0, 0, easing, duration, Context.currentTimingGroup).save())
        end
        
        -- Rotation
        if string.find(dir_rot, 'Xrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, flashHeight / 15, 0, 0, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, 0, 0, 0, -flashHeight / 15, 0, 0, easing, duration, Context.currentTimingGroup).save())
        end

        if string.find(dir_rot, 'Yrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, 0, flashHeight / 15, 0, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, 0, 0, 0, 0, -flashHeight / 15, 0, easing, duration, Context.currentTimingGroup).save())
        end
        
        if string.find(dir_rot, 'Zrotation') then
        cmd.add(Event.camera(hold.timing, 0, 0, 0, 0, 0, flashHeight / 15, 'l', 1, Context.currentTimingGroup).save())
        cmd.add(Event.camera(hold.timing + 1, 0, 0, 0, 0, 0, -flashHeight / 15, easing, duration, Context.currentTimingGroup).save())
        end
        
        cmd.add(hold.delete())
    end
end
)

-- // ARC(S) TO CAMERA // --
-- How do I got this in first try-
MacroNew(
    'floony.camera', 'arc2cam',
    'Arc to Camera', 'e41e',
    function(cmd)
    
        local arcNotes = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().long()), 'arc')

        if #arcNotes == 0 then
            notifyWarn("Select at least one arc.")
            return false
        end
        
    for _, arcs in ipairs(arcNotes) do
        local duration = arcs.endTiming - arcs.timing
        local dx, dy = arcs.endX - arcs.startX, arcs.endY - arcs.startY
        
        local easing = 'l'
        if arcs.type == 'si' or arcs.type == 'sisi' then
            easing = "qo"
        elseif arcs.type == 'so' or arcs.type == 'soso' then
            easing = "qi"
        elseif arcs.type == 'b' then
            easing = "s"
        end
            
        if arcs.isVoid then
        cmd.add(Event.camera(arcs.timing, 0, 0, 0, 0, 0, 0, 'reset', 0, Context.currentTimingGroup).save())
        end
        
        if arcs.color == 0 then
        cmd.add(Event.camera(arcs.timing, dx * 850, dy * 450, 0, 0, 0, 0, easing, duration, Context.currentTimingGroup).save())
        elseif arcs.color == 1 then
        cmd.add(Event.camera(arcs.timing, 0, 0, dy * 200, 0, 0, dx * 180 / 4, easing, duration, Context.currentTimingGroup).save())
        else
        cmd.add(Event.camera(arcs.timing, 0, 0, 0, dx * 180 / 4, dy * 360 / 12, 0, easing, duration, Context.currentTimingGroup).save())
        end
        
        cmd.add(arcs.delete())
    end
end
)

-- // CAMERA STASH // --
FolderNew('floony.camera', 'floony.camerastash', 'e1a1', 'Camera Stash')
storedCameras = {}
local stashCount = 0

MacroNew(
    'floony.camerastash', 'cam_stashcreate', 
    'Create', 'e145', 
    function(cmd)
    local tStart, tEnd = Request.timeRange()
    local cameraEvents = table.icollapse(Event.query(CustomConstraints.timeRange(tStart, tEnd)), 'camera')
    
    if #cameraEvents == 0 then
        notify("No camera events detected.")
        return false
    end
    
    coroutine.yield()

    stashCount = stashCount + 1

    local dialogNameRequest = DialogInput.withTitle("Camera Stash Name").requestInput({
        DialogField.create('cameraCount')
            .description(tostring(#cameraEvents) .. ' camera events detected!'),
        DialogField.create("name")
            .setLabel("Name")
            .setHint("Enter a name for the camera stash")
            .setTooltip("Your stash name will be included in the newly created macro's name"),
        DialogField.create("mirror")
            .setLabel("Mirror")
            .setTooltip("Mirror the camera events")
            .checkbox()
    })

    coroutine.yield()
    local name = dialogNameRequest.result["name"]
    local mirror = dialogNameRequest.result["mirror"]
    storedCameras[name] = cameraEvents
    dialogNotify("Camera events stored as '" .. name .. "' for later use.")

    local macroTitle = 'Stash '..stashCount..': '..name
    if mirror then
        macroTitle = macroTitle..' (M)'
    end

    MacroNewNOCMD('floony.camerastash', 'floony.stashes.'..stashCount, macroTitle, 'ea50', function()
        local stash = storedCameras[name]

        local timingRequest = TrackInput.requestTiming("Select where to paste your stash")
        coroutine.yield()
        local timing = timingRequest.result["timing"]
        local batchCommand = Command.create("Pasting Stash "..name)
        
        for i, event in ipairs(stash) do    
            local ev = event.copy()
            local origin = stash[1].timing
            local displace = timing - origin    
            ev.timing = displace + event.timing

            if mirror then
                    ev.x = -ev.x
                    -- ev.y = -ev.y
                    -- ev.z = -ev.z
                    ev.rx = -ev.rx
                    -- ev.ry = -ev.ry
                    ev.rz = -ev.rz
            end

            batchCommand.add(ev.save())
        end

        batchCommand.commit()
    end)
end)

--[[--------------------------------------------------------------------]]--

-- // QUANTIZE // --
local firstExecute = nil
MacroNew(
    'floony.special', 'autoquantize',
    'Auto-Quantize', 'e863',
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local notes = Event.query(CustomConstraints.timeRange(tStart, tEnd))
        notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')

        if #notes == 0 then
            notify('No notes found in the selected time range.')
            return
        end
        
        local tg = notes[1].timingGroup
        local bpm = Context.bpmAt(tStart, tg)
        local div = Context.beatlineDensity
        local miliPerMinute = 60000
        local beatline = miliPerMinute / (bpm * div)
        
        if not firstExecute then
        dialogNotifyCustom('WARNING', 'Further adjustments may be needed after executing this macro.\nProceed?')
        
        firstExecute = true
        end
        
        for _, event in ipairs(notes) do
            local timing = event.timing
            local quantizedTiming = math.floor(timing / beatline + 0.5) * beatline
            local timingDiff = quantizedTiming - timing

            event.timing = quantizedTiming
            if event.is 'long' then
            local endTiming = event.endTiming + timingDiff
            local quantizedEndTiming = math.floor(endTiming / beatline + 0.5) * beatline
            event.endTiming = quantizedEndTiming
        end
            cmd.add(event.save())
        end
    end
)

-- // SPIRAL TRACE // --
MacroNew(
    'floony.special', 'floony.spiraltrace',
    "Spiral Trace", "e577",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local pos = Request.position(tEnd)
        local DURATION = tEnd - tStart

        local dialogFields = {
            DialogField.create("division")
                .setLabel("Division")
                .setTooltip("How many timings should be created?")
                .textField(FieldConstraint.create().integer().gEqual(1))
                .defaultTo(Context.beatlineDensity * 2),

            DialogField.create("startBpm")
                .setLabel("Start BPM")
                .setTooltip("The BPM at the start of the timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(Context.baseBpm / 2),

            DialogField.create("endBpm")
                .setLabel("End BPM")
                .setTooltip("The BPM at the end of the timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(Context.baseBpm / 2 + (Context.baseBpm * 1.5)),           

            DialogField.create("tracegen")
                .setLabel("Trace Count")
                .setTooltip("How many traces are generated?")
                .textField(FieldConstraint.create().integer())
                .defaultTo(8),

            DialogField.create("outwardTrue")
                .setLabel("Outward")
                .setTooltip("Make the spiral expand outward")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Spiral Trace").requestInput(dialogFields)
        coroutine.yield()
        
        local BPM = Context.baseBpm
        local DIVISOR = tonumber(dialogRequest.result["division"])
        local STEP = 60000 / BPM / DIVISOR
        local TRACE = dialogRequest.result["tracegen"]
        
        local timingGroup = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == "$floony.spiral" then
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

        if not timingGroup then
            timingGroup = Event.createTimingGroup('name="$floony.spiral"')
            cmd.add(timingGroup.save())
        end

        local function lerp(a, b, t)
            return (1 - t) * a + t * b
        end

        local function addTimingChanges(tStart, tEnd, startBpm, endBpm, cmd, divisor)
            local stepSize = (tEnd - tStart) / (divisor - 1)
            for index = 0, divisor - 1 do
                local timing = tStart + stepSize * index
                local bpm = lerp(startBpm, endBpm, index / (divisor - 1))
                cmd.add(Event.timing(timing, bpm, 999, Context.currentTimingGroup).save().withTimingGroup(timingGroup))
            end
        end

        local startBpm = tonumber(dialogRequest.result["startBpm"])
        local endBpm = tonumber(dialogRequest.result["endBpm"])
        addTimingChanges(tStart, tEnd, startBpm, endBpm, cmd, DIVISOR)

        local function floorDiv(a, b)
            return math.floor(a / b)
        end

        local function getPosition(angle, offset)
            local rad = math.rad(angle)
            local cos = math.cos(rad)
            local sin = math.sin(rad)
            return lerp(0, offset, sin) + pos.x, lerp(0, offset * 1.888, cos) + pos.y -- X,Y
        end

        local function getSegment(t1, t2, angle1, angle2, offset1, offset2, cmd)
            local x1, y1 = getPosition(angle1, offset1)
            local x2, y2 = getPosition(angle2, offset2)
            local yThreshold = -0.22
            if y1 < yThreshold and y2 < yThreshold then return end
            if y1 > yThreshold and y2 > yThreshold then
                cmd.add(Event.arc(t1, x1, y1, t2, x2, y2, true, 0, 's', 0, false).save().withTimingGroup(timingGroup))
                return
            end

            local whole = y2 - y1
            local part = yThreshold - y1
            local p = part / whole
            if y1 < y2 then
                t1 = lerp(t1, t2, p)
                x1 = lerp(x1, x2, p)
                y1 = lerp(y1, y2, p)
            else
                t2 = lerp(t1, t2, p)
                x2 = lerp(x1, x2, p)
                y2 = lerp(y1, y2, p)
            end

            cmd.add(Event.arc(t1, x1, y1, t2, x2, y2, true, 0, 's', 0, false).save().withTimingGroup(timingGroup))
        end

        local tfloat = 0
        while tfloat < DURATION do
            local nextfloat = tfloat + STEP
            local t = math.floor(tfloat)
            local p = t / DURATION
            local np = math.floor(nextfloat) / DURATION
            
            local offset1, offset2
            if dialogRequest.result["outwardTrue"] then
                offset1 = lerp(4, -0.1, (1 - p))
                offset2 = lerp(4, -0.1, (1 - np))
            else
                offset1 = lerp(-0.1, 4, (1 - p))
                offset2 = lerp(-0.1, 4, (1 - np))
            end
            
            for deltaAngle = 0, 360 - floorDiv(360, TRACE), floorDiv(360, TRACE) do
                local angle1 = 360 * p + deltaAngle
                local angle2 = 360 * np + deltaAngle
                getSegment(t + tStart, math.floor(nextfloat) + tStart, angle1, angle2, offset1, offset2, cmd)
            end

            tfloat = nextfloat
        end
    end
)

-- // OFFSET BPM // --
MacroNew(
    "floony.special", "floony.offsetbpm", 
    "Offset by BPM", "ebe7",
    function(cmd)
        local selectedNotes = Event.getCurrentSelection(EventSelectionConstraint.create().any())
        selectedNotes = table.icollapse(selectedNotes, 'arc', 'tap', 'hold', 'arctap')
    
        if #selectedNotes == 0 then
            notify('Please select any notes.')
            return false
        end
        
        local dialogRequest = DialogInput.withTitle('Offset by BPM').requestInput({
            DialogField.create('Warning')
            .description("This may not be fully accurate, so adjust it further by using Auto-Quantize."),
            DialogField.create("oribpm")
                .setLabel("Original BPM")
                .setTooltip("What is the original BPM for this section?")
                .textField(FieldConstraint.create().float())
        })
        
        coroutine.yield()
        local originalBPM = tonumber(dialogRequest.result["oribpm"])
        if not originalBPM or originalBPM <= 0 then
            notify("Please enter a valid positive BPM value.")
            return false
        end
        local currentBPM = Context.baseBpm

        local originalMsPerBeat = 60000 / originalBPM
        local currentMsPerBeat = 60000 / currentBPM
        local msOffset = (currentMsPerBeat - originalMsPerBeat) * (Context.songLength / 60000)
        
        for _, note in ipairs(selectedNotes) do
            note.timing = note.timing + msOffset * (note.timing / Context.songLength)
            if note.is 'long' then
                note.endTiming = note.endTiming + msOffset * (note.endTiming / Context.songLength)
            end
            cmd.add(note.save())
        end
    end
)

-- // COPY "TIMING" GROUP // --
MacroNewNOCMD(
    "floony.special", "copytg", 
    "Copy Timing Group", "e14d",
    function()
        
        local timingEvents = Event.query(EventSelectionConstraint.create().ofTimingGroup(Context.currentTimingGroup).timing()).timing
        local tg = Event.createTimingGroup("")
        local batchCommand = Command.create("Duplicate Timing Group")
        batchCommand.add(tg.save())

        for i = 2, #timingEvents do
            local event = timingEvents[i]
            local newEvent = Event.timing(event.timing, event.bpm, event.divisor)
            batchCommand.add(newEvent.save().withTimingGroup(tg))
        end
        
        batchCommand.commit()
        
    end
)

-- // STREAM PLACEMENT (aaaaaaaaa) // --
FolderNew('floony.special', 'floony.placement', 'ebb9', '[Stream Placement]')

local firstExecute = nil

    -- / Function
local function createArcsForNotes(cmd, selectedJudgeable, color)
    local tgHand = Event.createTimingGroup('name="Stream_TEMP"')
    cmd.add(tgHand.save())
    
    for _, note in ipairs(selectedJudgeable) do
        local position = nil
        if note.is('arctap') then
            position = note.arc.positionAt(note.timing)
        elseif note.is('tap') or note.is('hold') then
            local lane = note.lane
            position = xy(lane / 2 - 0.75, 0)
        end
        
        if position then
            cmd.add(
                Event.arc(
                    note.timing, position, note.timing, position,
                    false, color, 's', note.timingGroup
                ).save().withTimingGroup(tgHand)
            )
        end
        color = 1 - color
    end
end

    -- / Macro
MacroNew(
    'floony.placement', 'bluefirst',
    "Left Hand First", "eb59",
    function (cmd)
        
        local selectedJudgeable = table.icollapse(
            Event.getCurrentSelection(EventSelectionConstraint.create().any()), 
            'tap', 'hold', 'arctap'
        )
        
        if #selectedJudgeable < 2 then
            notify("Please select at least two tap, hold, or arctap notes.")
            return false
        end

        if not firstExecute then
            dialogNotifyCustom('WARNING', 'This macro has an issue with selecting both taps and arctaps, so additional adjustments may be required.\nProceed?')
            firstExecute = true
        end

        createArcsForNotes(cmd, selectedJudgeable, 0)
    end
)

MacroNew(
    'floony.placement', 'redfirst',
    "Right Hand First", "eb52",
    function (cmd)
        
        local selectedJudgeable = table.icollapse(
            Event.getCurrentSelection(EventSelectionConstraint.create().any()), 
            'tap', 'hold', 'arctap'
        )
        
        if #selectedJudgeable < 2 then
            notify("Please select at least two tap, hold, or arctap notes.")
            return false
        end

        if not firstExecute then
            dialogNotifyCustom('WARNING', 'This macro has an issue with selecting both taps and arctaps, so additional adjustments may be required.\nProceed?')
            firstExecute = true
        end

        createArcsForNotes(cmd, selectedJudgeable, 1)
    end
)

-- // INSTRUCTION // --
    -- / Function
function generateDialogField(id, name, desc)
    return string.format(" - <b>%s</b> <size=8>(%s)</size>\n%s", name, id, desc)
end

function generateCategoryField(id, name)
    local padding = string.rep(" ", math.floor((25 - #name)))
    return string.format("%s<size=15><b>%s</b></size> <size=8>(%s)</size>", padding, name, id)
end

    -- / Macro
MacroNew(
    'floony.special', 'spinfo',
    'Help', 'e8fd',
    function(cmd)
        local dialogContent = {
            DialogField.create("notes2trace")
                .description(generateDialogField("floony.convert2trace", "Notes to Trace", "Convert Notes into Traces / Void")),
            DialogField.create("notes2shadow")
                .description(generateDialogField("floony.convert2shadow", "Notes to Shadow", "Convert notes into shadow notes (will generate a new tg with 'noinput' property)")),
            DialogField.create("timingstash")
                .description(generateDialogField("floony.timingstash", "Timing Stash", "Save Timing for further use")),
            DialogField.create("tap2sc")
                .description(generateDialogField("floony.taptosc", "Tap to Hidegroup", "Convert Tap into Hidegroup (Alternating)")),
            DialogField.create("hold2alpha")
                .description(generateDialogField("floony.holdtoalpha", "Hold to Groupalpha", "Convert Hold into Groupalpha (Normal, Flick)")),
            DialogField.create("flashsc")
                .description(generateDialogField("floony.flashsc", "Flashing SC", "Convert Long Notes into Flashing / Pulsing Scenecontrol")),
            DialogField.create("autoquantize")
                .description(generateDialogField("floony.autoquantize", "Auto-Quantize", "Corrects the note placement on the beatline (Not always accurate)")),            
            DialogField.create("spiraltrace")
                .description(generateDialogField("floony.spiraltrace", "Spiral Trace", "Make a spiral trace, as seen on Arghena Intro")),
            DialogField.create("offsetbpm")
                .description(generateDialogField("floony.offsetbpm", "Offset by BPM", "Offset the selected notes by BPM (Not fully accurate)")),
            DialogField.create("duptg")
                .description(generateDialogField("floony.duptg", "Copy Timing Group", "Generate a new timing group containing all timing events from Selected Group")),
            DialogField.create("placement")
                .description(generateDialogField("floony.placement", "Stream Placement", "Generate 0ms arcs to indicate finger placement but may be inaccurate with taps and skynotes.")),

            DialogField.create("border")
                .description("\n"),
                
            DialogField.create("cam")
                .description(generateCategoryField("floony.camera", "Camera Category")),
            DialogField.create("cam1")
                .description(generateDialogField("floony.camera.blank", "Blank", "Create a Blank Camera")),
            DialogField.create("cam2")
                .description(generateDialogField("floony.camera.repeat", "Repeat", "Repeat the selected Camera (Alternate, Mirror option available)")),
            DialogField.create("cam3")
                .description(generateDialogField("floony.camera.bounce", "Bounce", "Create a Camera(s) that gives the impression of bouncing (Using the middle timing point)")),
            DialogField.create("cam4")
                .description(generateDialogField("floony.camera.flick", "Flick", "Create a Camera(s) that gives the impression of flicking")),           
            DialogField.create("cam5")
                .description(generateDialogField("floony.camera.arc2cam", "Arc to Camera", "Convert Arc(s) into Camera(s)\nHint:\n"
                .."<color=#19A0EBD9>Blue arc</color>: x, y -> transverse, bottomzoom\n"
                .."<color=#F0699BD9>Red arc</color>: x, y -> angle, linezoom\n"
                .."<color=#28C81ED9>Green arc</color>: x, y -> steadyangle, topzoom\n"
                )),
            DialogField.create("cam6")
                .description(generateDialogField("floony.camera.camerastash", "Camera Stash", "Stashes the camera(s) events for Future uses (Mirror option available)")),           
        }

        DialogInput.withTitle("Help - Special").requestInput(dialogContent)
    end
)

