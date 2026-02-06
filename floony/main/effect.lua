require "floony.lib.macroUtil"
require "floony.lib.utils"

------------------------------------\
-- // EFFECTS / GIMMICK // --       |
------------------------------------/
FolderNew("floony", "floony.effect", "e65f", "- Effects / Gimmick -")

-----------------------------
--- /// ARC RAIN FOLDER /// ---
-----------------------------
FolderNew("floony.effect", "floony.arcrain", "e3ea", "[Arc Rain]")

-- // NORMAL // --
    -- / Defaults
local pos1, pos2 = nil, nil
local defaultLength = 1
local defaultRange = 0
local defaultIntensity = 1

    -- / Macro
MacroNew(
    "floony.arcrain", "rain_normal", 
    "Normal", "e5da",
    function(cmd)
        local tStart = Request.time("Select start time")

        local function requestPositions()
            pos1 = Request.position(tStart, "Select First Corner (Min X/Y)")
            pos2 = Request.position(tStart, "Select Opposite Corner (Max X/Y)")

            if not (pos1 and pos2) then
                dialogNotify("Invalid input. Please select valid positions.")
                return false
            end
            return true
        end

        if not (pos1 and pos2) then
            if not requestPositions() then return end
        else
            local confirmUsePrevious = DialogInput.withTitle("WARNING").requestInput({
                DialogField.create("prepos")
                    .setLabel("Previous position")
                    .setTooltip("Would you like to use the previous positions?")
                    .dropdownMenu("Yes", "No")
            })
            coroutine.yield()
            
            if confirmUsePrevious.result["prepos"] == "No" then
                if not requestPositions() then return end
            end
        end
        
        local xMin = math.min(pos1.x, pos2.x)
        local xMax = math.max(pos1.x, pos2.x)
        local yMin = math.min(pos1.y, pos2.y)
        local yMax = math.max(pos1.y, pos2.y)

        local tEnd = Request.time("Select end time")
        coroutine.yield()
        if tEnd < tStart then 
            dialogNotify("Start Timing must not be greater than End Timing.")
            return false 
        end
        
        local dialogFields = {
            DialogField.create("intensity")
                .setLabel("Intensity")
                .setTooltip("Number of traces created simultaneously")
                .defaultTo(defaultIntensity)
                .textField(FieldConstraint.create().integer().gEqual(1)),        
            DialogField.create("lmul")
                .setLabel("(Min) Length")
                .setTooltip("Duration of each rain arc (in beats)")
                .defaultTo(defaultLength)
                .textField(FieldConstraint.create().float().gEqual(0)),
            DialogField.create("rangelength")
                .setLabel("Range Length")
                .defaultTo(defaultRange)
                .setTooltip("Adds randomness to the arc duration.\nThe final length will be between the minimum length and (minimum + this value).")
                .textField(FieldConstraint.create().float().gEqual(0)),
            DialogField.create("arctap")
                .setLabel("Add Arctaps")
                .setTooltip("Whether to add arctaps at the beginning of the trace")
                .checkbox()
        }
        
        local dialogRequest = DialogInput.withTitle("Arc Rain").requestInput(dialogFields)
        coroutine.yield()
        
        local lmulVal = tonumber(dialogRequest.result["lmul"])
        local rangeVal = tonumber(dialogRequest.result["rangelength"]) or 0
        local intensityVal = tonumber(dialogRequest.result["intensity"])
        
        if not (lmulVal and intensityVal) then
            dialogNotify("Invalid input. Please provide valid values.")
            return
        end
        
        defaultLength, defaultIntensity = dialogRequest.result["lmul"], dialogRequest.result["intensity"]
        
        local beatDuration = Context.beatLengthAt(tStart, Context.currentTimingGroup)
        local rainInterval = beatDuration / Context.beatlineDensity
        
        for timing = tStart, tEnd - rainInterval, rainInterval do
            for i = 1, intensityVal do
                local lengthBeats = lmulVal
                if rangeVal > 0 then
                    lengthBeats = math.randomf(lmulVal, lmulVal + rangeVal)
                end
                
                local arcStart = math.floor(timing)
                local arcEnd = math.floor(arcStart + (lengthBeats * beatDuration))
                
                local position = xy(math.randomf(xMin, xMax), math.randomf(yMin, yMax))
                local arcEvent = Event.arc(arcStart, position, arcEnd, position, true, 0, "s", Context.currentTimingGroup)
                cmd.add(arcEvent.save())
        
                if dialogRequest.result["arctap"] then
                    local tapTime = arcStart
                    if arcEnd > arcStart then
                        tapTime = math.min(arcStart + 1, arcEnd)
                    end
                    
                    local arctapEvent = Event.arctap(tapTime, arcEvent)
                    cmd.add(arctapEvent.save())
                end
            end
        end
    end
)

-- // RAIN TUNNEL (similar to callima karma) // --
    -- / Defaults
local pos1, pos2 = nil, nil
local defaultLength = 0
local defaultIntensity = 1
local defaultY = 1
local defaultX = 0.2

    -- / Macro
MacroNew(
    "floony.arcrain", "rain_tunnel", 
    "Tunnel", "e5da",
    function(cmd)
        local tStart = Request.time("Select start time")

        local function requestPositions()
            pos1 = Request.position(tStart, "Select First Corner (Min X/Y)")
            pos2 = Request.position(tStart, "Select Opposite Corner (Max X/Y)")

            if not (pos1 and pos2) then
                dialogNotify("Invalid input. Please select valid positions.")
                return false
            end
            return true
        end

        if not (pos1 and pos2) then
            if not requestPositions() then return end
        else
            local confirmUsePrevious = DialogInput.withTitle("WARNING").requestInput({
                DialogField.create("prepos")
                    .setLabel("Previous position")
                    .setTooltip("Would you like to use the previous positions?")
                    .dropdownMenu("Yes", "No")
            })
            coroutine.yield()

            if confirmUsePrevious.result["prepos"] == "No" then
                if not requestPositions() then return end
            end
        end

        local xMin = math.min(pos1.x, pos2.x)
        local xMax = math.max(pos1.x, pos2.x)
        local yMin = math.min(pos1.y, pos2.y)
        local yMax = math.max(pos1.y, pos2.y)

        local tEnd = Request.time("Select end time")
        coroutine.yield()
        if tEnd < tStart then 
            dialogNotify("Start Timing must not be greater than End Timing.")
            return false 
        end

        local dialogFields = {
            DialogField.create("intensity")
                .setLabel("Intensity")
                .setTooltip("Number of traces created simultaneously")
                .defaultTo(defaultIntensity)
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create("lmul")
                .setLabel("Length")
                .setTooltip("How much of the time until the next rain arc should a given rain arc last for?")
                .defaultTo(defaultLength)
                .textField(FieldConstraint.create().float()),
            DialogField.create("factory")
                .setLabel("Ypos intensity")
                .setTooltip("How long will the arc extend along the Y-axis?")
                .defaultTo(defaultY)
                .textField(FieldConstraint.create().float()),
            DialogField.create("factorx")
                .setLabel("Xpos intensity")
                .setTooltip("How much will the arc shift horizontally? (Left = Negative, Right = Positive)")
                .defaultTo(defaultX)
                .textField(FieldConstraint.create().float()),
            DialogField.create("endpos")
                .setLabel("Direction")
                .setTooltip("Set the Trace to have a different ending position")
                .dropdownMenu("Both", "Left [<--]", "Right [-->]")
        }

        local dialogRequest = DialogInput.withTitle("Arc Rain").requestInput(dialogFields)
        coroutine.yield()

        local lmulVal = tonumber(dialogRequest.result["lmul"])
        local intensityVal = tonumber(dialogRequest.result["intensity"])
        local factoryVal = tonumber(dialogRequest.result["factory"])
        local factorxVal = tonumber(dialogRequest.result["factorx"])
        local endDirection = dialogRequest.result["endpos"]

        if not (lmulVal and intensityVal) then
            dialogNotify("Invalid input. Please provide valid values.")
            return
        end

        defaultLength, defaultIntensity = dialogRequest.result["lmul"], dialogRequest.result["intensity"]

        local rainTime = Context.beatLengthAt(tStart, Context.currentTimingGroup) / Context.beatlineDensity
        local rainLength = rainTime * lmulVal

        for timing = tStart, tEnd - rainTime, rainTime do
            for i = 1, intensityVal do
                local position = xy(math.randomf(xMin, xMax), math.randomf(yMin, yMax))

                local randY = math.randomf(-1, 1) * factoryVal
                
                local shiftX = 0
                local magnitudeX = math.abs(factorxVal)

                if endDirection == "Left [<--]" then
                    shiftX = -magnitudeX
                elseif endDirection == "Right [-->]" then
                    shiftX = magnitudeX
                elseif endDirection == "Both" then
                    shiftX = math.randomf(-magnitudeX, magnitudeX)
                end

                local endPosition = position + xy(shiftX, randY)
                local arcEvent = Event.arc(timing, position, timing + rainLength, endPosition, true, 0, "s", Context.currentTimingGroup)
                cmd.add(arcEvent.save())
            end
        end
    end
)

--[[--------------------------------------------------------------------]]--

-----------------------------
--- /// TIMING FOLDER /// ---
-----------------------------
FolderNew("floony.effect", "floony.timing", "e8b5", "[Timing]")

-- // GRADUAL TIMING (my personal favorite) // --
    -- / Defaults
local division = nil
local startBpm = nil
local endBpm = nil
    -- / Macro
MacroNew(
    "floony.timing", "gradual", 
    "Gradual", "e6df",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local bpmInd = Context.bpmAt(tStart, Context.currentTimingGroup)
        local bpmBase = Context.baseBpm

        local dialogFields = {
            DialogField.create("division")
                .setLabel("Division")
                .setTooltip("How many timings should be created?")
                .textField(FieldConstraint.create().integer().gEqual(1))
                .defaultTo(division or Context.beatlineDensity),

            DialogField.create("startBpm")
                .setLabel("Start BPM")
                .setTooltip("The BPM at the start of the timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(startBpm),

            DialogField.create("endBpm")
                .setLabel("End BPM")
                .setTooltip("The BPM at the end of the timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(endBpm),

            DialogField.create("easing")
                .setLabel("Easing")
                .setTooltip("The easing to use")
                .dropdownMenu("l", "qi", "qo", "qio", "ci", "co", "cio", "qrti", "qrto", "qrtio", "qnti", "qnto", "qntio", "exi", "exo", "exio", "eli", "elo", "elio")
        }

        local bpmTitle = "Smooth Timing / Base BPM: " .. tostring(bpmBase)
        if bpmBase ~= bpmInd then
            bpmTitle = bpmTitle .. " / Current BPM: " .. tostring(bpmInd)
        end

        local dialogRequest = DialogInput.withTitle(bpmTitle).requestInput(dialogFields)
        coroutine.yield()

        local startBpmVal = evaluateMathExpression(dialogRequest.result["startBpm"])
        local endBpmVal = evaluateMathExpression(dialogRequest.result["endBpm"])
        local c4 = 2 * math.pi / 3
        local c5 = 2 * math.pi / 4.5

        if not startBpmVal or not endBpmVal then
            dialogNotify("Invalid BPM expression")
            return
        end
        
        division = dialogRequest.result["division"]
        startBpm = dialogRequest.result["startBpm"]
        endBpm = dialogRequest.result["endBpm"]
        local division = tonumber(dialogRequest.result["division"])

        local easingFunctions = {
            l = function(x) return x end,
            qi = function(x) return x * x end,
            qo = function(x) return 1 - (1 - x) * (1 - x) end,
            qio = function(x) return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 / 2 end,
            ci = function(x) return x * x * x end,
            co = function(x) return 1 - (1 - x) ^ 3 end,
            cio = function(x) return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 / 2 end,
            qrti = function(x) return x * x * x * x end,
            qrto = function(x) return 1 - (1 - x) ^ 4 end,
            qrtio = function(x) return x < 0.5 and 8 * x * x * x * x or 1 - (-2 * x + 2) ^ 4 / 2 end,
            qnti = function(x) return x * x * x * x * x end,
            qnto = function(x) return 1 - (1 - x) ^ 5 end,
            qntio = function(x) return x < 0.5 and 16 * x * x * x * x * x or 1 - (-2 * x + 2) ^ 5 / 2 end,
            exi = function(x) return x == 0 and 0 or 2 ^ (10 * x - 10) end,
            exo = function(x) return x == 1 and 1 or 1 - 2 ^ (-10 * x) end,
            exio = function(x) return x == 0 and 0 or (x == 1 and 1 or (x < 0.5 and 2 ^ (20 * x - 10) / 2 or (2 - 2 ^ (-20 * x + 10)) / 2)) end,
            eli = function(x) return x == 0 and 0 or (x == 1 and 1 or -2 ^ (10 * x - 10) * math.sin((x * 10 - 10.75) * c4)) end,
            elo = function(x) return x == 0 and 0 or (x == 1 and 1 or 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * c4) + 1) end,
            elio = function(x) return x == 0 and 0 or (x == 1 and 1 or (x < 0.5 and -(2 ^ (20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2 or 2 ^ (-20 * x + 10) * math.sin((20 * x - 11.125) * c5) / 2 + 1)) end
        }
        local effect = easingFunctions[dialogRequest.result["easing"]]

        for index = 0, division - 1 do
            local timing = tStart + (tEnd - tStart) * index / division
            local bpm = math.lerp(startBpmVal, endBpmVal, effect(index / division))
            cmd.add(Event.timing(timing, bpm, 999, Context.currentTimingGroup).save())
        end

        cmd.add(Event.timing(tEnd, endBpmVal, Context.beatlineDensity, Context.currentTimingGroup).save())
    end
)

-- // BOUNCE TIMING // --
    -- / Defaults
local division = nil
local initialBpm = nil
local midBpm = nil
    -- / Macro
MacroNew(
    "floony.timing", "floony.bouncetiming", 
    "Bounce", "e7d0",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local bpmInd = Context.bpmAt(tStart, Context.currentTimingGroup)
        local bpmBase = Context.baseBpm
        local beatline = 60000 / (bpmInd * Context.beatlineDensity)

        local dialogFields = {
            DialogField.create("division")
                .setLabel("Division")
                .setTooltip("How many timings should be created?")
                .textField(FieldConstraint.create().integer())
                .defaultTo(division or Context.beatlineDensity),
            DialogField.create("initialBpm")
                .setLabel("Start / End BPM")
                .setTooltip("The BPM at the initial and end timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(initialBpm or bpmInd),
            DialogField.create("midBpm")
                .setLabel("Middle BPM")
                .setTooltip("The BPM on the middle timing")
                .textField(FieldConstraint.create().any())
                .defaultTo(midBpm or -beatline),
            DialogField.create("easing")
                .setLabel("Easing")
                .setTooltip("The easing to use")
                .dropdownMenu("l", "qi", "qo", "qio", "ci", "co", "cio", "qrti", "qrto", "qrtio", "qnti", "qnto", "qntio", "exi", "exo", "exio", "eli", "elo", "elio")
        }

        local bpmTitle = "Bouncing Timing / Base BPM: " .. tostring(bpmBase)
        if bpmBase ~= bpmInd then
            bpmTitle = bpmTitle .. " / Current BPM: " .. tostring(bpmInd)
        end
        
        local dialogRequest = DialogInput.withTitle(bpmTitle).requestInput(dialogFields)
        coroutine.yield()
        
        division = dialogRequest.result["division"]
        initialBpm = dialogRequest.result["initialBpm"]
        midBpm = dialogRequest.result["midBpm"]
        local c4 = 2 * math.pi / 3
        local c5 = 2 * math.pi / 4.5

        local division = tonumber(dialogRequest.result["division"])
        local midBpmVal = evaluateMathExpression(dialogRequest.result["midBpm"])
        local initialBpmVal = evaluateMathExpression(dialogRequest.result["initialBpm"])

        if not midBpmVal or not initialBpmVal then
            dialogNotify("Invalid BPM expression")
            return
        end

        local easingFunctions = {
            l = function(x) return x end,
            qi = function(x) return x * x end,
            qo = function(x) return 1 - (1 - x) * (1 - x) end,
            qio = function(x) return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 / 2 end,
            ci = function(x) return x * x * x end,
            co = function(x) return 1 - (1 - x) ^ 3 end,
            cio = function(x) return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 / 2 end,
            qrti = function(x) return x * x * x * x end,
            qrto = function(x) return 1 - (1 - x) ^ 4 end,
            qrtio = function(x) return x < 0.5 and 8 * x * x * x * x or 1 - (-2 * x + 2) ^ 4 / 2 end,
            qnti = function(x) return x * x * x * x * x end,
            qnto = function(x) return 1 - (1 - x) ^ 5 end,
            qntio = function(x) return x < 0.5 and 16 * x * x * x * x * x or 1 - (-2 * x + 2) ^ 5 / 2 end,
            exi = function(x) return x == 0 and 0 or 2 ^ (10 * x - 10) end,
            exo = function(x) return x == 1 and 1 or 1 - 2 ^ (-10 * x) end,
            exio = function(x) return x == 0 and 0 or (x == 1 and 1 or (x < 0.5 and 2 ^ (20 * x - 10) / 2 or (2 - 2 ^ (-20 * x + 10)) / 2)) end,
            eli = function(x) return x == 0 and 0 or (x == 1 and 1 or -2 ^ (10 * x - 10) * math.sin((x * 10 - 10.75) * c4)) end,
            elo = function(x) return x == 0 and 0 or (x == 1 and 1 or 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * c4) + 1) end,
            elio = function(x) return x == 0 and 0 or (x == 1 and 1 or (x < 0.5 and -(2 ^ (20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2 or 2 ^ (-20 * x + 10) * math.sin((20 * x - 11.125) * c5) / 2 + 1)) end
        }
        local effect = easingFunctions[dialogRequest.result["easing"]]

        for index = 0, division - 1 do
            local timing = tStart + (tEnd - tStart) * index / division
            local bpm

            if index < division / 2 then
                bpm = math.lerp(initialBpmVal, midBpmVal, effect(index / (division / 2)))
            else
                bpm = math.lerp(midBpmVal, initialBpmVal, effect((index - division / 2) / (division / 2)))
            end

            cmd.add(Event.timing(timing, bpm, 999, Context.currentTimingGroup).save())
        end

        cmd.add(Event.timing(tEnd, initialBpmVal, Context.beatlineDensity, Context.currentTimingGroup).save())
    end
)

-- // GLITCH // --
    -- / Defaults
local segments = Context.beatlineDensity * 4
local glitchbpm = nil
local rangebpm = nil
    -- / Macro (New methods)
MacroNew(
    "floony.timing", "glitch", 
    "Glitch", "ec1c",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local currentBpm = Context.bpmAt(tStart, Context.currentTimingGroup)

        local dialogFields = {
            DialogField.create("segments")
                .setLabel("Segments")
                .setTooltip("How many timings should be created?")
                .defaultTo(segments)
                .textField(FieldConstraint.create().integer()),
            DialogField.create("glitchbpm")
                .setLabel("Initial BPM")
                .setTooltip("The Initial BPM of the glitch")
                .defaultTo(glitchbpm or currentBpm)
                .textField(FieldConstraint.create().any()),
            DialogField.create("rangebpm")
                .setLabel("BPM Range")
                .setTooltip("The Range of the glitch")
                .defaultTo(rangebpm or currentBpm * (8^2))
                .textField(FieldConstraint.create().any()),
            DialogField.create("tip")
                .description("<size=65%>Tip: A larger value is recommended.</size>")
        }

        local dialogRequest = DialogInput.withTitle("Glitch Timing").requestInput(dialogFields)
        coroutine.yield()

        segments = tonumber(dialogRequest.result["segments"])
        glitchbpm = evaluateMathExpression(dialogRequest.result["glitchbpm"])
        rangebpm = evaluateMathExpression(dialogRequest.result["rangebpm"])

        local step = (tEnd - tStart) / segments

        for index = 0, segments - 1 do
            local timing = math.floor(tStart + step * index)
            local bpm = (index % 2 == 0) and rangebpm or -rangebpm
            cmd.add(Event.timing(timing, bpm, 4.00, Context.currentTimingGroup).save())
            cmd.add(Event.timing(timing + 1, glitchbpm, 4.00, Context.currentTimingGroup).save())
        end

        cmd.add(Event.timing(tEnd, currentBpm, 4.00, Context.currentTimingGroup).save())
    end
)

--[[ // Old methods
MacroNew(
    "floony.timing", "glitch", 
    "Glitch", "ec1c",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local currentBpm = Context.bpmAt(tStart, Context.currentTimingGroup)

        local dialogFields = {
            DialogField.create("division")
                .setLabel("Division")
                .setTooltip("How many timings should be created?")
                .defaultTo(Context.beatlineDensity * 4)
                .textField(FieldConstraint.create().integer()),
            DialogField.create("firstbpm")
                .setLabel("First BPM")
                .setTooltip("The First BPM of the glitch")
                .defaultTo(-currentBpm * 6)
                .textField(FieldConstraint.create().any()),
            DialogField.create("secondbpm")
                .setLabel("Second BPM")
                .setTooltip("The Second BPM of the glitch")
                .defaultTo(currentBpm * 8)
                .textField(FieldConstraint.create().any()),
            DialogField.create("random")
                .setLabel("Randomness")
                .setTooltip("The Intensity of Randomness Glitch")
                .defaultTo(0)
                .textField(FieldConstraint.create().float()),
            DialogField.create("tip")
                .description("<size=65%>Tip: It's recommended to set the first BPM value as negative and lower than second BPM value for forward movement and vice versa.</size>")
        }

        local dialogRequest = DialogInput.withTitle("Glitch Timing").requestInput(dialogFields)
        coroutine.yield()
        
        local division = tonumber(dialogRequest.result["division"])
        local randomness = tonumber(dialogRequest.result["random"])
        local firstBpm = evaluateMathExpression(dialogRequest.result["firstbpm"])
        local secondBpm = evaluateMathExpression(dialogRequest.result["secondbpm"])
        
        for index = 0, division - 1 do
            local timing = tStart + (tEnd - tStart) * index / division
            local isEvenIndex = index % 2 == 0
            local randomFactor = math.random() * (randomness * 64) * (isEvenIndex and 1 or -1)
            local interpolatedBpm = isEvenIndex and firstBpm + randomFactor or secondBpm + randomFactor

            cmd.add(Event.timing(timing, interpolatedBpm, 999, Context.currentTimingGroup).save())
        end

        cmd.add(Event.timing(tEnd, currentBpm, Context.beatlineDensity, Context.currentTimingGroup).save())
    end
)
--]]


-- // PAUSE // --
    -- / STOP BPM SETTINGS
local sbpm = 0.01
function StopBPMSetting(self)
    
    local settingTitle = "Pause Hold Setting / Base BPM: " .. tostring(Context.baseBpm)
    local dialogRequest = DialogInput.withTitle(settingTitle).requestInput(
        {
            DialogField.create("stopbpm")
                .setLabel("Set Stop BPM")
                .setTooltip("If left blank, 0.01 will be used.")
                .defaultTo(sbpm)
                .textField(FieldConstraint.create().any())
        }
    )
    coroutine.yield()

    local input = dialogRequest.result["stopbpm"]
    if input == "" or input == nil then
        sbpm = 0.01
    else
        sbpm = evaluateMathExpression(input)
    end
    
    notify("The stop BPM value has been successfully updated to " .. sbpm)
end

    -- / FUNCTION
---@param cmd LuaChartCommand
function pauseHold(bpmMul, cmd)
    local hold =
        table.collapse(Request.note(EventSelectionConstraint.create().long(), "Select a long note"), "arc", "hold")[1]

    local tg, timing, endTiming = hold.timingGroup, hold.timing, hold.endTiming
    local bpm, ebpm = Context.bpmAt(timing, tg), Context.bpmAt(endTiming, tg)

    cmd.add(Event.timing(timing, sbpm, 999, tg).save())
    cmd.add(Event.timing(endTiming - 1, ebpm * bpmMul, Context.divisorAt(timing, tg), tg).save())
    cmd.add(hold.delete())
end
    -- / Folder & Macro & Setting
FolderNew("floony.timing", "floony.pauseHold", "e034", "[Pause]")

local pauseHoldPresets = {
    {name = "Normal", bpmMul = 1, icon = "e037"},
    {name = "Half", bpmMul = 0.5, icon = "e020"},
    {name = "Double", bpmMul = 2, icon = "e01f"}
}

for _, preset in ipairs(pauseHoldPresets) do
    MacroNew(
        "floony.pauseHold",
        "floony.pauseHold." .. preset.name:lower(),
        preset.name, preset.icon,
        function(cmd)
            pauseHold(preset.bpmMul, cmd)
        end
    )
end

MacroNewNOCMD("floony.pauseHold", "floony.pauseHoldSet", "Set stop BPM", "e9e4", StopBPMSetting)

-- // SUDDEN // --
    -- / Folder
FolderNew("floony.timing", "floony.suddentiming", "ea0b", "[Sudden]")
    -- / Macro
MacroNew(
    "floony.suddentiming", "suddenbefore", 
    "Timing - 1 (Hidden)", "e5d9",
    function(cmd)
        local request = TrackInput.requestTiming()
        coroutine.yield()
        local timing = request.result["timing"]
        local tg = Context.currentTimingGroup

        cmd.add(Event.timing(timing - 1, 999999, 999, tg).save())
        cmd.add(Event.timing(timing, Context.bpmAt(timing, tg), Context.divisorAt(timing, tg), tg).save())
    end
)

MacroNew(
    "floony.suddentiming", "suddenafter",
    "Timing + 1 (Visible)", "e5da",
    function(cmd)
        local request = TrackInput.requestTiming()
        coroutine.yield()
        local timing = request.result["timing"]
        local tg = Context.currentTimingGroup

        cmd.add(Event.timing(timing, 999999, 999, tg).save())
        cmd.add(Event.timing(timing + 1, Context.bpmAt(timing, tg), Context.divisorAt(timing, tg), tg).save())
    end
)

-- // TELEPORT // --
    -- / Defaults
local multiplier = Persistent.getString("floony.timingteleport.multiplier", 1)
local startPoint = Persistent.getString("floony.timingteleport.startPoint", "end")
    -- / Macro
MacroNew(
    "floony.timing", "timingteleport",
    "Teleport", "ebaa",
    function(cmd, self)
        local longNotes = Event.getCurrentSelection(EventSelectionConstraint.create().long())
        longNotes = table.icollapse(longNotes, "arc", "hold")
        
        if #longNotes == 0 then
            notifyWarn("Please select at least one long note.")
            return false
        end

        local dialogFields = {
            DialogField.create("Instruction")
                .description("Create a 'teleport' effect on long notes (arc or hold) by suddenly changing the timing based on selected long notes."),
            DialogField.create("multiplier")
                .setLabel("Multiplier")
                .defaultTo(multiplier)
                .setTooltip("How strong the teleportation is? (in Beatline)")
                .textField(FieldConstraint.create().float()),
            DialogField.create("startpoint")
                .setLabel("Teleport From")
                .defaultTo(startPoint)
                .setTooltip('Should the teleportation begin at the "<u>start</u>" or "<u>end</u>"\n<size=65%>It is based on Hold Timing or End Timing</size>') -- I could use Dropdown if the defaultTo are working.
                .textField(FieldConstraint.create().any())
        }

        local dialogRequest = DialogInput.withTitle("Teleportation Gimmick").requestInput(dialogFields)
        coroutine.yield()

        multiplier = tonumber(dialogRequest.result["multiplier"])
        startPoint = dialogRequest.result["startpoint"]
        
        Persistent.setString("floony.timingteleport.multiplier", multiplier)
        Persistent.setString("floony.timingteleport.startPoint", startPoint)
        Persistent.save()
        
        local lastNoteIndex = #longNotes
        local tolerance = 17 -- in milliseconds

        for i, hold in ipairs(longNotes) do
            local tg = Context.currentTimingGroup
            local bpm = Context.bpmAt(hold.timing, tg)
            local ebpm = Context.bpmAt(hold.endTiming, tg)
            local div = Context.divisorAt(hold.timing, tg)
            local beatline = 60000 / (bpm * Context.beatlineDensity)

            -- Adjust for overshoot
            if i < lastNoteIndex then
                local nextHold = longNotes[i + 1]
                if hold.endTiming > nextHold.timing - tolerance then
                    hold.endTiming = nextHold.timing
                end
            end

            if startPoint == "end" then
                cmd.add(Event.timing(hold.timing, 0.01, 999, tg).save())
                cmd.add(Event.timing(hold.endTiming - 1, bpm * (beatline * multiplier), 999, tg).save())

                if i == lastNoteIndex or (i < lastNoteIndex and hold.endTiming + tolerance < longNotes[i + 1].timing) then
                    cmd.add(Event.timing(hold.endTiming, ebpm, div, tg).save())
                end
            elseif startPoint == "start" then
                cmd.add(Event.timing(hold.timing, bpm * (beatline * multiplier), 999, tg).save())
                cmd.add(Event.timing(hold.timing + 1, ebpm, div, tg).save())
            else
                notify("Invalid starting point!")
                return false
            end

            cmd.add(hold.delete())
        end
    end
)