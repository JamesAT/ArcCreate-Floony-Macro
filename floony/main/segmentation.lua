require "floony.lib.macroUtil"
require "floony.lib.utils"

------------------------------------\
-- // ARCS MANIPULATION // --       |
------------------------------------/
addFolderWithIcon("floony", "floony.segmentation", "e1a0", "- Arcs Segmentation -")

-----------------------------
--- /// SETTINGS /// ---
-----------------------------
    -- Defaults
local forceHeightLines = false
local stasisArcs = false
local stasisTrace = false
local stasisOption = 1
local riceMultiplier = 0.5

    -- // SETTINGS // --
local function aestheticBoolean(value)
    if value then
        return "<color=#20AA20>True</color>"
    else
        return "<color=#FF7070>False</color>"
    end
end

function updateSettings(self)
    local dialogRequest = DialogInput.withTitle("Segmentation Setting").requestInput(
        {
            DialogField.create("force")
                .setLabel("Force Lines")
                .setTooltip("Force segmented arcs to have height lines, regardless of their real height.\n(This applies to ALL segmentation)")
                .checkbox(),
                
            DialogField.create("stasisDesc")
                .description("<b>Stasis / Rice config</b>"),
                
            DialogField.create("stasis")
                .setLabel("Type")
                .defaultTo(stasisOption)
                .setTooltip("1 = Disable | 2 = None | 3 = Add Trace")
                .textField(FieldConstraint.create().integer().gEqual(1).lEqual(3)),
                
            DialogField.create("ricemult")
                .setLabel("Multiplier")
                .setTooltip("How much to shorten each segment when converting an arc to rice arcs.")
                .defaultTo(riceMultiplier)
                .textField(FieldConstraint.create().float().greater(0).lEqual(1)),

            DialogField.create("currentState")
                .description(
                    "Force lines = " .. aestheticBoolean(forceHeightLines) ..
                    "\nStasis arc = " .. aestheticBoolean(stasisArcs) .. " | With Trace = " .. aestheticBoolean(stasisTrace) ..
                    "\nRice Multiplier = " .. riceMultiplier
                )
        }
    )
    coroutine.yield()
    forceHeightLines = dialogRequest.result["force"]
    riceMultiplier = dialogRequest.result["ricemult"]
    stasisOption = dialogRequest.result["stasis"]
    
    if stasisOption == "2" then
        stasisArcs = true
        stasisTrace = false
    elseif stasisOption == "3" then
        stasisArcs = true
        stasisTrace = true
    else
        stasisArcs = false
        stasisTrace = false
    end
end

-- // ARCS SEGMENTATION FUNCTIONS // --

function arcGenerator(typ, spliceTime)
    return function(cmd)
        local arcA = Request.arc("Select dominant arc")
        local arcB = Request.arc("Select target arc")
        
            if arcA.isVoid and arcB.isVoid then
                -- Proceed to generate without checking the errors.
            else
                if arcA.timing ~= arcB.timing then
                    notify("Both arcs must start at the same time.")
                    return false
                end
                if arcA.endTiming ~= arcB.endTiming then
                    notify("Both arcs must end at the same time.")
                    return false
                end
                if arcA.color ~= arcB.color then
                    notify("Both arcs must have the same color.")
                    return false
                end
                if arcA.isVoid ~= arcB.isVoid then
                    notify("Both arcs must be void or not.")
                    return false
                end
                if arcA.timingGroup ~= arcB.timingGroup then
                    notify("Both arcs must be in the same timing group.")
                    return false
                end
                if arcA.startXY == arcB.startXY and arcA.endXY == arcB.endXY and arcA.type == arcB.type then
                    notify("Both arcs must not overlaps.")
                    return false
                end
            end

        -- Programming --
        local flag = true
        local spliceTimeLocal = spliceTime
        if spliceTimeLocal == nil then
            spliceTimeLocal = Context.beatLengthAt(arcA.timing, arcA.timingGroup) / Context.beatlineDensity
        end
        
        for timing, endTiming in bestDivisions(arcA.timing, arcA.endTiming, spliceTimeLocal) do
            local midTiming = 0

            if typ == "brr" then
                midTiming = (timing + endTiming) / 2
            elseif typ == "ran" then
                midTiming = endTiming
            elseif typ == "nar" then
                midTiming = timing
            end

            local startpos = arcA.positionAt(timing)
            local midpos = arcB.positionAt(midTiming)
            local endpos = arcA.positionAt(endTiming)

            if startpos.y == midpos.y or midpos.y == endpos.y then
                if midpos.y <= 0 then
                    midpos.y = midpos.y
                elseif forceHeightLines then
                    endpos.y = endpos.y - 0.01
                end
            end
            
            if typ == "wave" then
                if flag then
                    cmd.add(
                        Event.arc(timing, arcA.positionAt(timing), timing, arcB.positionAt(timing), arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                    )
                    cmd.add(
                        Event.arc(timing, arcB.positionAt(timing), endTiming, arcB.positionAt(endTiming), arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                    )
                else
                    cmd.add(
                        Event.arc(timing, arcB.positionAt(timing), timing, arcA.positionAt(timing), arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                    )
                    cmd.add(
                        Event.arc(timing, arcA.positionAt(timing), endTiming, arcA.positionAt(endTiming), arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                    )
                end
                flag = not flag
            elseif typ == "line" then
                cmd.add(
                    Event.arc(timing, arcA.positionAt(timing), timing, arcB.positionAt(timing), arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                )
            else
                cmd.add(
                    Event.arc(timing, startpos, midTiming, midpos, arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                )
                cmd.add(
                    Event.arc(midTiming, midpos, endTiming, endpos, arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup).save()
                )
            end
        end

        cmd.add(arcA.delete())
        cmd.add(arcB.delete())
    end
end

---@param arc LuaArc
---@param get_segments fun(arc: LuaArc, s: number, e: number, spos: XY, epos: XY): LuaArc[]
---@return LuaChartCommand cmd, LuaArc[] arcs
local function arc_split(arc, get_segments, amyg)
    local options = {}
    local spliceTime = Context.beatLengthAt(arc.timing, arc.timingGroup) / Context.beatlineDensity

    for timing, endTiming in bestDivisions(arc.timing, arc.endTiming, spliceTime) do
        local basestartpos = arc.positionAt(timing)
        local baseendpos = arc.positionAt(endTiming)

        for _, x in ipairs(get_segments(arc, timing, endTiming, basestartpos, baseendpos)) do
            table.insert(options, x)
        end
    end

    local commands = Command.create("Arc split edit")

    for i, o in ipairs(options) do
        if i % 2 == 0 and (forceHeightLines or amyg) then
            o.startXY = o.startXY + xy(0, -0.01)
        elseif forceHeightLines or amyg then
            o.endXY = o.endXY + xy(0, -0.01)
        else
            o.endXY = o.endXY + xy(0, 0)
        end

        if i % 2 == 0 then
            if stasisArcs and stasisTrace then
                o.isVoid = true
                commands.add(o.save())
            elseif stasisArcs then
                commands.add(o.delete())
            else
                commands.add(o.save())
            end
        else
            commands.add(o.save())
        end
    end

    return commands, options
end


---@param get_segments fun(arc: LuaArc, s: number, e: number, spos: XY, epos: XY): LuaArc[]
---@return fun(cmd: Command)
local function arc_split_command(get_segments, amyg)
    return function(cmd)
        local arc = Request.arc("Select an arc to modify")
        local cmd2, _ = arc_split(arc, get_segments, amyg)
        cmd.add(cmd2)
        cmd.add(arc.delete())
    end
end

-- MACRO
FolderNew("floony.segmentation", "segmentation.generate", "ef3c", "[Generate]")
    MacroNew("segmentation.generate", "brr", "Zig-Zag", "e922", arcGenerator("brr"))
    MacroNew("segmentation.generate", "ran", "Ran", "e3e7", arcGenerator("ran"))
    MacroNew("segmentation.generate", "nar", "Reverse Ran", "e3e6", arcGenerator("nar"))
    MacroNew("segmentation.generate", "wave", "Square Wave", "eba7", arcGenerator("wave"))
    MacroNew("segmentation.generate", "line", "Line", "e152", arcGenerator("line"))
    
FolderNew("floony.segmentation", "floony.segmentation.split", "f184", "[Split]")
-- arc = Event.arc / s = Start Timing / e = End Timing / spos = Start Pos / epos = End Pos
MacroNew(
    "floony.segmentation.split", "split_normal",
    "Normal", "f108",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_amygdata",
    "Amygdata", "e260",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end, true
    )
)

MacroNew(
    "floony.segmentation.split", "split_chunky",
    "Chunky", "eba4",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {
                Event.arc(s, spos, math.lerp(s, e, 0.5), epos, arc.isVoid, arc.color, "s", arc.timingGroup),
                Event.arc(math.lerp(s, e, 0.5), epos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)
            }
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_rice",
    "Rice", "e5d3",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, math.lerp(s, e, riceMultiplier), spos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_stair",
    "Staircase", "ebaa",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {
                Event.arc(s, spos, e, spos, arc.isVoid, arc.color, "s", arc.timingGroup),
                Event.arc(e, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)
            }
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_point",
    "Point (0ms)", "e837",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, s, spos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew("floony.segmentation", "floony.settings", "Settings", "e8b8", updateSettings)
