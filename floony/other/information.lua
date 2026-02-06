require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // INFORMATION // --             |
------------------------------------/
-- // MS TO X:XX // --
function formatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- // CHART DETAILS // --
MacroNewNOCMD(
    "floony", "chartinfo", 
    "Chart Information", "e97a",
    function()
        local allNotes = Event.query(EventSelectionConstraint.create().any())
        local combo = Context.maxCombo
        local note = Context.noteCount
        local timinggroup = Context.timingGroupCount - 1
        local songlength = formatTime(Context.songLength)
        local count = {
            arc = 0, trace = 0, hold = 0, tap = 0, arctap = 0, fake = 0,
            timing = 0, camera = 0, scenecontrol = 0,
            totalnotes = 0, totalevents = 0, summary = 0
        }
        
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.noInput == true then
                local fakeGroupNotes = Event.query(EventSelectionConstraint.create().ofTimingGroup(group.num).judgeable()).result
                
                for _, Fakenotes in pairs(fakeGroupNotes) do
                    count.fake = count.fake + #Fakenotes
                end
            end
        end
        local function conditionalFakeNotes()
            if count.fake > 0 then
                return "\n<color=#FF5733>Fake Notes: </color>" .. count.fake
            else
                return ""
            end
        end

        for eventType, notes in pairs(allNotes.result) do
            if eventType == "arc" then
                for _, note in ipairs(notes) do
                    if note.is("solidArc") then
                        count.arc = count.arc + 1
                    elseif note.is("voidArc") then
                        count.trace = count.trace + 1
                    end
                end
            else
                count[eventType] = #notes
            end
        end
        
        count.totalnotes = count.arc + count.trace + count.hold + count.tap + count.arctap
        count.totalevents = count.timing + count.camera + count.scenecontrol + timinggroup
        count.summary = count.totalnotes + count.totalevents

        if timinggroup == 0 then
            timinggroup = "0 (Base)"
        end
        
        --[[ currently broken as it's only picked the Accent
        function sideDivider()
        if Context.side == "light" then
            return "\n<color=#1e97d4>[]--Stats---------------------------------------------[]</color>"
        elseif Context.side == "conflict" then
            return "\n<color=#7f4dbd>[]--Stats---------------------------------------------[]</color>"       
        elseif Context.side == "colorless" then
            return "\n<color=#ddd7de>[]--Stats---------------------------------------------[]</color>"
        end end
        ]]--

                notify(
                    "Chart info displayed (Hover to view statistics)\n" ..
                    "\n" ..
                    "[]--Stats---------------------------------------------[]" ..
                    "\nSong Length: " .. songlength ..
                    " | Current Combo: " .. combo ..
                    "\n" ..
                    "\n[]--Elements---------------------------------------------[]" ..
                    "\n" ..
                    "Tap: " .. count.tap ..
                    " | Hold: " .. count.hold ..
                    " | SkyTap: " .. count.arctap ..
                    " | Arc: " .. count.arc ..
                    " | Trace: " .. count.trace ..
                    conditionalFakeNotes() ..
                    "\n<color=#FFD73B>Total Notes: </color>" .. count.totalnotes ..
                    "\n" ..
                    "\nTiming: " .. count.timing ..
                    " | Timing Group: " .. timinggroup  ..
                    " | Scenecontrol: " .. count.scenecontrol ..
                    " | Camera: " .. count.camera ..
                    "\n<color=#FFD73B>Total Event: </color>" .. count.totalevents ..
                    "\n" ..
                    "\n[]--Summaries---------------------------------------------[]" ..
                    -- sideDivider() ..
                    "\n<color=#C3FF3E>Total Notes + Total Event: </color>" .. count.summary ..
                    "\n" ..
                    "\n"
                ) end

    
        --[[ // Using Dialog Display
        local dialogContent = {
            DialogField.create("notescount")
                .description(
                    "[]--Stats---------------------------------------------[]" ..
                    "\nSong Length: " .. songlength ..
                    " | Current Combo: " .. combo ..
                    "\n" ..
                    "\n[]--Elements---------------------------------------------[]" ..
                    "\n" ..
                    "Tap: " .. count.tap ..
                    " | Hold: " .. count.hold ..
                    " | SkyTap: " .. count.arctap ..
                    " | Arc: " .. count.arc ..
                    " | Trace: " .. count.trace ..
                    -- "\n<color=#FF5733>Fake Notes: </color>" .. count.fake ..
                    "\n<color=#FFD73B>Total Notes: </color>" .. count.totalnotes ..
                    "\n" ..
                    "\nTiming: " .. count.timing ..
                    " | Timing Group: " .. timinggroup  ..
                    " | Scenecontrol: " .. count.scenecontrol ..
                    " | Camera: " .. count.camera ..
                    "\n<color=#FFD73B>Total Event: </color>" .. count.totalevents ..
                    "\n" ..
                    "\n[]--Summaries---------------------------------------------[]" ..
                    -- sideDivider() ..
                    "\n<color=#C3FF3E>Total Notes + Total Event: </color>" .. count.summary
                )
        }

        -- Display dialog
        DialogInput.withTitle("Chart Information").requestInput(dialogContent)
    end
    ]]--
)

--[[----------------------------------------------------]]--

-- // HEATMAP, PROGRESS, and something // --
    -- / Select your color!
local default = { 99, 183, 204 } -- aka Blue
local red = { 123, 13, 30 }
local green = { 19, 154, 67 }
local yellow = { 242, 232, 99 }
local custom = { r, g, b }

local colorPicked = green

local min_color = { 65, 65, 65 }
local max_color = colorPicked

    -- / Function
local function allocate(events, count, length, counter)
    local tbl = {}
    for i = 1, count do tbl[i] = 0 end

    local max = 0
    local slot_length = length / count
    for _, e in ipairs(events.resultCombined) do
        counter(e, function(timing)
            local slot = math.floor(timing / slot_length)
            if slot > 0 and slot <= #tbl then
                tbl[slot] = tbl[slot] + 1
                if tbl[slot] > max then max = tbl[slot] end
            end
        end)
    end

    if max == 0 then
        return nil
    end
    
    --[[
    for i = 1, #tbl do
        tbl[i] = tbl[i] / i
        if tbl[i] > max then max = tbl[i] end
    end
    ]]--
    
    for i = 1, #tbl do
        tbl[i] = tbl[i] / max
    end
    return tbl
end

local function allocation_to_str(allocation)
    local t = {}
    for i = 1, #allocation do
        local num = allocation[i]
        local r = min_color[1] + (max_color[1] - min_color[1]) * num
        local g = min_color[2] + (max_color[2] - min_color[2]) * num
        local b = min_color[3] + (max_color[3] - min_color[3]) * num
        t[i] = string.format("<color=#%02x%02x%02x>■</color>", r, g, b)
    end
    return "[" .. table.concat(t, "") .. "<color=#ffffff>]</color>"
end

local function allocation_to_percentage(allocation)
    local filled_count = 0
    for i = 1, #allocation do
        if allocation[i] > 0 then
            filled_count = filled_count + 1
        end
    end
    local percentage = (filled_count / #allocation) * 100

    if percentage > 97 then
        return string.format("<color=#53DD6C>%d%% *Technically Completed</color>", math.floor(percentage))
    elseif percentage > 90 then
        return string.format("<color=#F4D35E>%d%%</color>", math.floor(percentage))
    else
        return string.format("%d%%", math.floor(percentage))
    end
end


local function generateSpaces(count)
    return string.rep(" ", count)
end

    -- / Macro
MacroNew(
    'floony', 'floony.progress',
    'Density / Progress', 'e9e6',
    function(cmd)
        local tap = Event.query(EventSelectionConstraint.create().tap()).tap
        local hold = Event.query(EventSelectionConstraint.create().hold()).hold
        local arc = Event.query(EventSelectionConstraint.create().solidArc()).arc
        local trace = Event.query(EventSelectionConstraint.create().voidArc()).arc
        local arctap = Event.query(EventSelectionConstraint.create().arctap()).arctap
        local timing = Event.query(EventSelectionConstraint.create().timing()).timing
        local camera = Event.query(EventSelectionConstraint.create().camera()).camera
        local sc = Event.query(EventSelectionConstraint.create().scenecontrol()).scenecontrol

        local all = Event.query(EventSelectionConstraint.create().any())
        local length = Context.songLength
        local char_count = 42
        
        local by_count = allocate(all, char_count, length, function(e, adder)
            adder(e.timing)
        end)

        local by_combo = allocate(all, char_count, length, function(e, adder)
            if not Event.getTimingGroup(e.timingGroup).noInput then
                if e.is("tap") or e.is("arctap") then adder(e.timing) end
                if e.is("arc") or e.is("hold") then
                    local bpm = Context.bpmAt(e.timing, e.timingGroup)
                    local dur = e.endTiming - e.timing
                    if bpm ~= 0 and dur > 0 then
                        bpm = math.abs(bpm)
                        local x = 30000
                        if bpm >= 255 then x = 60000 end
                        local increment = x / bpm / Context.timingPointDensityFactor
                        if math.floor(dur / increment) <= 1 then
                            adder(e.timing + dur / 2)
                        else
                            local first = e.timing + increment
                            local count = math.floor(dur / increment) - 1
                            for i = 0, count - 1 do
                                adder(first + count * i)
                            end
                        end
                    end
                end
            end
        end)

        local by_percentage = allocate(all, char_count, length, function(e, adder)
            adder(e.timing)
        end)

        if not by_percentage then
            dialogNotify("<color=#F25F5C><b>Warning:</b></color>\nYou need to have at least 1% progression, please check again soon.")
            return false
        end
        
        local dialog = DialogInput.withTitle("Chart Progress / Density Heat Map")
            .requestInput({
                DialogField.create("Density").description("<b>- Event Density:</b>"),
                DialogField.create("AllocationE").description("<color=#808080>0:00" .. generateSpaces(155 - #formatTime(Context.songLength)) .. formatTime(Context.songLength) .. "</color>"
                .."\n" .. allocation_to_str(by_count)),
                
                DialogField.create("Notes Density").description("<b>- Notes Density:</b>"),
                DialogField.create("AllocationC").description("<color=#808080>0:00" .. generateSpaces(155 - #formatTime(Context.songLength)) .. formatTime(Context.songLength) .. "</color>"
                .."\n" .. allocation_to_str(by_combo)),
                
                DialogField.create("Percentage").description("- Percentage of Completion: " .. allocation_to_percentage(by_percentage)),
            })

end)

-- // PROGRESS LENGTH - LAST CHARTED // --

FolderNew('floony', 'floony.proglength', 'e41c', '[Progress Length]')

local function calculateProgress(tStart, tEnd)
    if not tEnd or tEnd <= 0 then
        dialogNotify("Invalid time range! Ensure endTiming greater than the startTiming.")
        return
    end

    local notes = Event.query(
        CustomConstraints.timeRange(tStart, tEnd)
    )
    notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')

    local songLength = Context.songLength

    local furthestTiming = 0
    for _, note in ipairs(notes) do
        local endTiming = note.is("long") and note.endTiming or note.timing
        furthestTiming = math.max(furthestTiming, endTiming)
    end

    local chartedPercentage = (furthestTiming / songLength) * 100
    if chartedPercentage > 100 then
        chartedPercentage = 100
    end

    local selectedDuration = tEnd - tStart

    local message
    if chartedPercentage >= 97 then
        message = string.format(
            "Charted Length: %s of %s | <color=#53DD6C>Progress: %.2f%%</color>\n" ..
            "<size=85%%>Selected Duration: %s</size>",
            formatTime(furthestTiming),
            formatTime(songLength),
            chartedPercentage,
            formatTime(selectedDuration)
        )
    else
        message = string.format(
            "Charted Length: %s of %s | Progress: %.2f%%\n" ..
            "<size=85%%>Selected Duration: %s</size>",
            formatTime(furthestTiming),
            formatTime(songLength),
            chartedPercentage,            
            formatTime(selectedDuration)
        )
    end
    
    dialogNotify(message)
end



-- Macro for calculating progress from the beginning
MacroNew(
    'floony.proglength', 'beginning',
    'From Beginning', 'e089',
    function(cmd)
        local tStart = 0
        local tEnd = Request.time('Please select the last charted timing')
        calculateProgress(tStart, tEnd)
    end
)

-- Macro for calculating progress within a specific section
MacroNew(
    'floony.proglength', 'segment',
    'Segment', 'e94b',
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        if not tStart or tStart <= 0 or not tEnd or tEnd <= tStart then
            dialogNotify("Invalid time range! Ensure endTiming greater than the startTiming.")
            return
        end

        local songLength = Context.songLength

        local sectionDuration = tEnd - tStart
        local percentageOfSong = (sectionDuration / songLength) * 100

        local message = string.format(
            "Duration: %s to %s (%s of %s) | Covers: %.2f%% of Song",
            formatTime(tStart),
            formatTime(tEnd),
            formatTime(sectionDuration),
            formatTime(songLength),
            percentageOfSong
        )

        dialogNotify(message)
    end
)

-- // GENERATE FORUM CHART FORMAT // --
MacroNewNOCMD(
    "floony", "genforum", 
    "Generate Post Format", "e0bf",
    function()
        local dialogFields = {
            DialogField.create("illustrator")
                .setLabel("Illustrator")
                .setTooltip("Enter the illustrator name (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartConstantFuture")
                .setLabel("Chart Constant (Future)")
                .setTooltip("Enter the chart constant for Future difficulty (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartViewFuture")
                .setLabel("Chart View (Future)")
                .setTooltip("Enter the URL for Future difficulty (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartDescription")
                .setLabel("Chart Description")
                .setTooltip("Enter a chart description (leave blank for N/A)")
                .textField(FieldConstraint.create().any())
        }
        
        local dialogResult = DialogInput.withTitle("Chart Post Format Addition")
            .requestInput(dialogFields)
            
        if not dialogResult then
            notify("Operation canceled.")
            return
        end
        coroutine.yield()
        local illustrator = (dialogResult.illustrator and dialogResult.illustrator ~= "") and dialogResult.illustrator or "N/A"
        local chartConstantFuture = (dialogResult.chartConstantFuture and dialogResult.chartConstantFuture ~= "") and dialogResult.chartConstantFuture or "N/A"
        local chartViewFuture = (dialogResult.chartViewFuture and dialogResult.chartViewFuture ~= "") and dialogResult.chartViewFuture or "N/A"
        local chartDescription = (dialogResult.chartDescription and dialogResult.chartDescription ~= "") and dialogResult.chartDescription or "N/A"
        
        local songTitle = Context.title or "N/A"
        local composer = Context.composer or "N/A"
        local charter = Context.charter or "N/A"
        local alias = Context.alias or "N/A"
        
        local info = "Song: " .. songTitle .. "\n" ..
                     "Composer: " .. composer .. "\n" ..
                     "Illustrator: " .. illustrator .. "\n\n" ..
                     "Difficulty: Future ?\n" ..
                     "Charter: " .. charter .. "\n" ..
                     "Alias: " .. alias .. "\n" ..
                     "Chart Constant: " .. chartConstantFuture .. "\n" ..
                     "Chart View: " .. chartViewFuture .. "\n\n" ..
                     "Chart Description:\n" .. chartDescription
        
        -- Copy the generated info to the system clipboard
        Context.systemClipboard = info
        
        notify("Chart Post Format generated and copied to the clipboard!")
    end
)


--[[ In WIP hell
MacroNewNOCMD(
    'floony', 'verification',
    'Is this legal?', 'f1c2',
    function()
        -- Query all note events
        local notes = Event.query(EventSelectionConstraint.create().any())

        -- Collapse to simplify note types for processing
        notes = table.icollapse(notes, 'hold', 'tap')

        local invalidNotes = {}

        for _, note in ipairs(notes) do
            -- Check for invalid lanes
            if note.is 'tap' or note.is 'hold' then
                if note.lane < 1 or note.lane > 4 then
                    table.insert(invalidNotes, note)
                end
            end
        end

        -- Query and filter for 'illegal' scenecontrol events
        local sceneGroup = Event.query(EventSelectionConstraint.create().scenecontrol()).scenecontrol
        local groupIllegalEvents = {}

        local illegalTypes = {'groupalpha', 'trackdisplay', 'enwidenlanes', 'enwidencamera'}
        for _, scEvent in ipairs(sceneGroup) do
            if table.contains(illegalTypes, scEvent.type) then
                table.insert(groupIllegalEvents, scEvent)
            end
        end

        local message = ""

        if #invalidNotes > 0 then
            message = message .. "<b>- Invalid Notes Detected:</b>\n\n"
            for _, note in ipairs(invalidNotes) do
                message = message .. string.format(
                    "Note at Timing: %d, Lane: %d, Timing Group: %d\n",
                    note.timing, note.lane, note.timingGroup
                )
            end
            message = message .. "\n"  -- Add space after invalid notes section
        end

        if #groupIllegalEvents > 0 then
            message = message .. "<b>- Illegal Scenecontrol Events Detected:</b>\n\n"
            for _, scEvent in ipairs(groupIllegalEvents) do
                message = message .. string.format(
                    "Scenecontrol at Timing: %d, Type: %s, Timing Group: %d\n",
                    scEvent.timing, scEvent.type, scEvent.timingGroup
                )
            end
        end

        if #invalidNotes > 0 or #groupIllegalEvents > 0 then
            local dialog = DialogInput.withTitle("Verification Notification")
                .requestInput({
                    DialogField.create("Issues Found").description(message),
                })

            Event.setSelection(invalidNotes)
        else
            notify("No illegal stuff found. You're good to go!")
        end
    end
)
]]--