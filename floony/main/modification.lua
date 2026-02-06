require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // MODIFY ELEMENTS // --         | (mostly arcs apparently)
------------------------------------/
FolderNew('floony', 'floony.modification', 'e429', '- Modify Elements -')

-- // SNAP ARC // --
    -- / Function
function snapToArc(snapend) return function(cmd)
    local tosnap = Request.arc('Select arc to be snapped')
    local snapto = Request.arc('Select arc to snap to')

    local position = snapto.positionAt(snapend and tosnap.endTiming or tosnap.timing)

    if snapend then
        tosnap.endXY = position
    else
        tosnap.startXY = position
    end

    cmd.add(tosnap.save())
end end

    -- / Folder & Macro
FolderNew('floony.modification', 'floony.snaparc', 'e39e', '[Snap Arc]')
MacroNew('floony.snaparc', 'start', 'Start', 'f1e6', snapToArc(false))
MacroNew('floony.snaparc', 'end', 'End', 'f1df', snapToArc(true))
MacroNew("floony.snaparc", "both", "Both", "e8d4",
    function (cmd)
        local tosnapEnd = Request.arc('Select the first arc to be snapped')
        local tosnapStart = Request.arc('Select the second arc to be snapped')
        local snapto = Request.arc('Select the arc to snap to')

        local position = snapto.positionAt(tosnapEnd.endTiming or tosnapStart.timing)

        tosnapEnd.endXY = position
        tosnapStart.startXY = position

        cmd.add(tosnapEnd.save())
        cmd.add(tosnapStart.save())
    end
)

-- // MIRROR LANE // --
    -- / Function
function mirrorAbout(lane, x, cmd)
    local function mirrorX(posX, refX)
        return 2 * refX - posX
    end

    local function mirrorLane(laneValue, refLane)
        return 2 * refLane - laneValue
    end

    local flr = Event.getCurrentSelection(EventSelectionConstraint.create().floor())
    flr = table.icollapse(flr, 'tap', 'hold')
    
    local sky = Event.getCurrentSelection(EventSelectionConstraint.create().sky())
    sky = table.icollapse(sky, 'arc', 'arctap')

    if #flr == 0 and #sky == 0 then
        notifyWarn("No notes selected.")
        return false
    end
    
    local cmd = Command.create("Macro Mirror About (floony.mirrorabout)")
    
    for _, value in ipairs(flr) do
        value.lane = mirrorLane(value.lane, lane)
        cmd.add(value.save())
    end

    for _, value in ipairs(sky) do
        value.startXY = xy(mirrorX(value.startXY.x, x), value.startXY.y)
        value.endXY   = xy(mirrorX(value.endXY.x, x),   value.endXY.y)
        cmd.add(value.save())
    end

    cmd.commit()
end

local lanes = {
    { lane = 1, x = -0.25, name = 'Lane 1' },
    { lane = 2, x = 0.25, name = 'Lane 2' },
    { lane = 3, x = 0.75, name = 'Lane 3' },
}

    -- / Macro
FolderNew('floony.modification', 'floony.mirrorabout', 'e8d4', '[Mirror About]')

for _, laneInfo in ipairs(lanes) do
    local commandName = 'floony.mirrorabout.lane' .. laneInfo.lane
    local folderName = 'floony.mirrorabout'
    local iconName = 'e5da'

    MacroNewNOCMD(folderName, commandName, laneInfo.name, iconName, function(cmd) mirrorAbout(laneInfo.lane, laneInfo.x, cmd) end)
end

-- // SHIFT ARC POSITION // --
    -- / Function
function ShiftPos(x, y, cmd)
    local arc = Event.getCurrentSelection(EventSelectionConstraint.create().arc())
    arc = table.icollapse(arc, 'arc')
    
    if #arc == 0 then
        notifyWarn("No arcs selected.")
        return false
    end
    
    local cmd = Command.create("Macro Shift ArcPos (floony.shiftarcpos)")
    
    for _, value in ipairs(arc) do
        value.startXY = xy(x + value.startXY.x, y + value.startXY.y)
        value.endXY   = xy(x + value.endXY.x, y + value.endXY.y)
        cmd.add(value.save())
    end
    cmd.commit()
end

local shiftValues = {
    { x = 0.01, y = 0.01, name = 'Fine-Tune' },
    { x = 0.05, y = 0.05, name = 'Smallest' },
    { x = 0.125, y = 0.125, name = 'Small' },
    { x = 0.25, y = 0.25, name = 'Moderate' },
    { x = 0.5, y = 0.5, name = 'Medium', icon = 'eb56' },
    { x = 1, y = 1, name = 'Large' },
}

    -- / Macro
FolderNew('floony.modification', 'floony.shiftarcpos', 'e074', '[Shift ArcPos]')
for _, shift in ipairs(shiftValues) do
    local folderName = 'floony.shiftarcpos.' .. shift.name:lower()
    addFolderWithIcon('floony.shiftarcpos', folderName, shift.icon or 'e5da', shift.name)
    
    MacroNewNOCMD(folderName, folderName .. '.xneg', 'X -' .. shift.x, 'e5cb', function() ShiftPos(-shift.x, 0, cmd) end)
    MacroNewNOCMD(folderName, folderName .. '.xpos', 'X +' .. shift.x, 'e5cc', function() ShiftPos(shift.x, 0, cmd) end)
    MacroNewNOCMD(folderName, folderName .. '.ypos', 'Y +' .. shift.y, 'e5ce', function() ShiftPos(0, shift.y, cmd) end)
    MacroNewNOCMD(folderName, folderName .. '.yneg', 'Y -' .. shift.y, 'e5cf', function() ShiftPos(0, -shift.y, cmd) end)
end

    -- / Macro (Custom Position)
MacroNew(
    "floony.shiftarcpos", "custom",
    "Custom", "e429",
    function (cmd)
        local arc = Event.getCurrentSelection(EventSelectionConstraint.create().arc())
        arc = table.icollapse(arc, 'arc')

        if #arc == 0 then
            notifyWarn("No arcs selected.")
            return false
        end
    
        local dialogRequest = DialogInput.withTitle("Shift Arcs").requestInput({
            DialogField.create("shiftX")
            .setLabel("X")
            .defaultTo("0")
            .textField(FieldConstraint.create().float()),
            
            DialogField.create("shiftY")
            .setLabel("Y")
            .defaultTo("0")
            .textField(FieldConstraint.create().float()),
            
            DialogField.create("ShiftDescription")
            .description("Negative (-) = Left / Down\nPositive (+) = Right / Up")
        })
        
        coroutine.yield()
        local x = tonumber(dialogRequest.result["shiftX"])
        local y = tonumber(dialogRequest.result["shiftY"])
        
        for _, value in ipairs(arc) do
            value.startXY = xy(x + value.startXY.x, y + value.startXY.y)
            value.endXY   = xy(x + value.endXY.x, y + value.endXY.y)
            cmd.add(value.save())
        end
    end
)

-- // CONNECT ARC // --
MacroNew(
    "floony.modification", "connect", 
    "Arc Connect", "e157",
    function(cmd)
        local selectedArcs = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

        if #selectedArcs < 2 then
            notify("Please select at least two arcs or traces")
            return false
        end

        table.sort(selectedArcs, function(a, b) return a.timing < b.timing end)

        for i = 1, #selectedArcs - 1 do
            local arc1, arc2 = selectedArcs[i], selectedArcs[i + 1]

            if arc1.endTiming > arc2.timing then
                notify("Arcs must be in chronological order and must not overlap.")
                return false
            end

            local connect = Event.arc(
                arc1.endTiming,
                arc1.endXY,
                arc2.timing,
                arc2.startXY,
                arc1.isVoid,
                arc1.color,
                's',
                arc1.timingGroup
            )

            cmd.add(connect.save())
        end
    end
)

-- // CUT ARC ON TIMING (thanks rech) // --
MacroNew(
    "floony.modification", "cutontiming", 
    "Cut on Timing", "e14e",
    function(cmd)
        local selectedArcs = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

        if #selectedArcs == 0 then
            notify("Please select at least one arc or trace.")
            return false
        end

        local cutTiming = Request.time("Select timing")

        for _, arc in ipairs(selectedArcs) do
            if cutTiming <= arc.timing or cutTiming >= arc.endTiming then
                notify("The selected timing is outside the valid range of the arc!")
                return false
            end

            cmd.add(arc.delete())

            local cutPos = arc.positionAt(cutTiming)

            local arc1 = Event.arc(
                arc.timing, arc.startXY,
                cutTiming, cutPos,
                arc.isTrace, arc.color,
                arc.type, arc.timingGroup,
                arc.sfx
            )
            cmd.add(arc1.save())

            local arc2 = Event.arc(
                cutTiming, cutPos,
                arc.endTiming, arc.endXY,
                arc.isTrace, arc.color,
                arc.type, arc.timingGroup,
                arc.sfx
            )
            cmd.add(arc2.save())

            local oldSelection = Event.getCurrentSelection()

            Event.setSelection({ arc })

            -- Query all ArcTaps related to the current arc
            local arcTapQueryResult = Event.query(
                EventSelectionConstraint.create().arctap().custom(
                    function(arctap)
                        if not arctap.is("arctap") then return false end
                        local parentArc = arctap.arc
                        return arc.instanceEquals(parentArc)
                    end, ""
                )
            )

            Event.setSelection(oldSelection.resultCombined)

            if arcTapQueryResult and arcTapQueryResult.resultCombined then
                for _, arctap in ipairs(arcTapQueryResult.resultCombined) do
                    cmd.add(arctap.delete())
                    arctap = arctap.copy()

                    if arctap.timing <= cutTiming then
                        arctap.arc = arc1
                    else
                        arctap.arc = arc2
                    end

                    cmd.add(arctap.save())
                end
            end
        end
    end
)

MacroNew(
    "floony.modification", "SplitnSnap",
    "Split & Snap Start Arcs", "e918",
    function(cmd)
        -- Collect segments (timing, positions, etc) for a single arc
        local function collect_segments(arc)
            local segments = {}
            local t_start = arc.timing
            local t_end = arc.endTiming
            local step = Context.beatLengthAt(t_start) / Context.beatlineDensity

            local t = t_start
            while t < t_end do
                local t_next = math.min(t + step, t_end)
                if math.abs(t_next - t) <= 1 then break end

                table.insert(segments, {
                    startPos = arc.positionAt(t),
                    endPos = arc.positionAt(t_next),
                    isVoid = arc.isVoid,
                    color = arc.color,
                    timingGroup = arc.timingGroup
                })

                t = t_next
            end

            return segments
        end

        -- Grab selected arcs
        local rawSel = Event.getCurrentSelection(EventSelectionConstraint.create().arc())
        local selectedArcs = table.icollapse(rawSel, "arc")

        if #selectedArcs == 0 then
            notify("Please select at least one arc or trace to Segment and Snap.")
            return false
        end

        -- Find the first arc’s startTiming for snapping all arcs
        local firstTiming = selectedArcs[1].timing

        -- Gather all new arcs and queue deletion of originals
        local allSegments = {}
        for _, arc in ipairs(selectedArcs) do
            for _, seg in ipairs(collect_segments(arc)) do
                seg.targetTiming = firstTiming
                table.insert(allSegments, seg)
            end

            cmd.add(arc.delete())
        end

        -- Create zero-length “snapped” arcs at the first arc’s startTiming
        for _, seg in ipairs(allSegments) do
            local snapped = Event.arc(
                seg.targetTiming,
                seg.startPos,
                seg.targetTiming,
                seg.endPos,
                seg.isVoid,
                seg.color,
                's',
                seg.timingGroup
            )
            cmd.add(snapped.save())
        end
    end
)

--[[
-- // CURVED ARCS START-TIMING SNAPPING // --
MacroNew(
    "floony.modification", "snaptrace", 
    "Snap to Start Timing", "e917",
    function(cmd)
        local selectedArcs = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

        if #selectedArcs < 2 then
            notify("Please select at least two or more arcs. (Hover for tips)\n" ..
            "\n" .. "This macro aligns all selected arcs or traces to the start timing. It works best if the arcs are already split.")
            return false
        end

        local baseArc = selectedArcs[1]
        for i = 2, #selectedArcs do
            local arcAfter = selectedArcs[i]
            local offset = Event.arc(
                baseArc.timing,
                arcAfter.startXY,
                baseArc.timing,
                arcAfter.endXY,
                baseArc.isVoid,
                baseArc.color,
                's',
                baseArc.timingGroup
            )
            cmd.add(offset.save())
            cmd.add(arcAfter.delete())
        end
        
        baseArc.timing = selectedArcs[1].timing
        baseArc.endTiming = selectedArcs[1].timing
        cmd.add(baseArc.save())
    end
)
]]--

-- // CYCLE ARC COLOR // --
MacroNew(
    'floony.modification', 'cyclecol',
    'Cycle Colors', 'e419',
    function (cmd)
        local arcSel = Event.getCurrentSelection(EventSelectionConstraint.create().arc()).arc

        if #arcSel < 2 then
            notify('Please select exactly / more than 2 arcs for color cycling.')
            return false
        end

        cycleColors(arcSel, cmd)
    end
)