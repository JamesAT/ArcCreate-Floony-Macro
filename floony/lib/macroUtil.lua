--MacroUtil.lua
--Shared helpers for registering macros, asking the user for input and handling arcs.
--Version: 2.0 (consolidated registration, fixed requests, shared settings)

require 'floony.lib.color'
require 'floony.lib.utils'

------------------------------------------------------------------
-- Persistent storage
------------------------------------------------------------------
FloonyStore = FloonyStore or { memory = {} }

---@param key string
---@param default string?
---@return string
function FloonyStore.getString(key, default)
    default = default or ''
    if Persistent and Persistent.getString then
        local ok, value = pcall(Persistent.getString, key, default)
        if ok and type(value) == 'string' and value ~= '' then
            return value
        end
    end
    local v = FloonyStore.memory[key]
    if type(v) == 'string' and v ~= '' then return v end
    return default
end

---@param key string
---@param value string
---@return boolean
function FloonyStore.setString(key, value)
    local strVal = tostring(value or '')
    FloonyStore.memory[key] = strVal
    if Persistent and Persistent.setString then
        return (pcall(Persistent.setString, key, strVal))
    end
    return false
end

---@param key string
---@param default any
---@return any
function FloonyStore.get(key, default)
    if Persistent then
        if Persistent.get then
            local ok, value = pcall(Persistent.get, key, default)
            if ok and value ~= nil then return value end
        elseif Persistent.getString then
            local ok, value = pcall(Persistent.getString, key, '')
            if ok and type(value) == 'string' and value ~= '' then return value end
        end
    end
    local v = FloonyStore.memory[key]
    if v ~= nil then return v end
    return default
end

---@param key string
---@param value any
---@return boolean saved @true when written to Persistent
function FloonyStore.set(key, value)
    FloonyStore.memory[key] = value
    if Persistent then
        if Persistent.set then
            return (pcall(Persistent.set, key, value))
        elseif Persistent.setString then
            return (pcall(Persistent.setString, key, tostring(value)))
        end
    end
    return false
end

------------------------------------------------------------------
-- Shared state
------------------------------------------------------------------

Floony = Floony or {}
Floony.version = Floony.version
Floony.lastRun = nil          -- { id, name, run } of the last recorded macro (for "Repeat Last Macro")
Floony.loadErrors = Floony.loadErrors or {}  -- filled by floony.lua when a module fails to load
Floony.modules = Floony.modules or {}        -- filled by floony.lua with the modules that did load
Floony.macros = {}            -- id -> { id, name, parent, icon, run }   (every registered macro)
Floony.folders = {}           -- id -> { id, name, parent, icon }        (every registered folder)

--- Settings shared between modules. They are saved with `Persistent`, so they are still there
--- after reloading the macros: call saveSettings() after changing one.
local SETTING_DEFAULTS = {
    forceHeightLines = false,
    stasis = 1,                 -- 1: Off, 2: Hide Alternating, 3: Convert Alternating to Trace
    riceMultiplier = 0.5,
    lastShiftX = 0,
    lastShiftY = 0,
    randomKeep = 50,            -- % kept by "Range Select Random"
    randomRun = 0,
    traceIncludeArcTaps = false, -- Notes to Trace: also convert selected ArcTaps (SkyTap)
    traceKeepOriginals = false,  -- Notes to Trace: keep the original notes
}

------------------------------------------------------------------
-- Settings Serialization (String-based for Persistent storage)
------------------------------------------------------------------

local SETTINGS_STORE_KEY = 'floony.settings'

--- Converts a key-value settings table into tab-separated text lines (key\ttype\tvalue)
local function serializeSettings(tbl)
    local lines = {}
    for k, v in pairs(tbl) do
        local t = type(v)
        if t == 'boolean' or t == 'number' or t == 'string' then
            lines[#lines + 1] = k .. '\t' .. t .. '\t' .. tostring(v)
        end
    end
    return table.concat(lines, '\n')
end

--- Parses tab-separated text lines back into typed values
local function deserializeSettings(str)
    local res = {}
    if type(str) == 'string' and str ~= '' then
        for line in str:gmatch('[^\r\n]+') do
            local k, t, v = line:match('^([^\t]+)\t([^\t]+)\t?(.*)$')
            if k and t then
                if t == 'boolean' then
                    res[k] = (v == 'true')
                elseif t == 'number' then
                    res[k] = tonumber(v)
                elseif t == 'string' then
                    res[k] = v
                end
            end
        end
    end
    return res
end

local function loadSavedSettings()
    local str = FloonyStore.getString(SETTINGS_STORE_KEY, '')
    return deserializeSettings(str)
end

------------------------------------------------------------------
-- Settings Initialization & Methods
------------------------------------------------------------------

FloonySettings = FloonySettings or {}

-- Initialize defaults
for k, v in pairs(SETTING_DEFAULTS) do
    FloonySettings[k] = v
end

-- Overlay saved persistent values
do
    local saved = loadSavedSettings()
    for k, v in pairs(saved) do
        if SETTING_DEFAULTS[k] ~= nil and type(v) == type(SETTING_DEFAULTS[k]) then
            FloonySettings[k] = v
        end
    end
end

--- Save current settings to disk so they survive a reload.
function saveSettings()
    local copy = {}
    for k in pairs(SETTING_DEFAULTS) do
        copy[k] = FloonySettings[k]
    end
    FloonyStore.setString(SETTINGS_STORE_KEY, serializeSettings(copy))
end

--- Put every setting back to its default value (and save to disk).
function resetSettings()
    for k, v in pairs(SETTING_DEFAULTS) do
        FloonySettings[k] = v
    end
    saveSettings()
end

-- Every module can declare its own settings here, so macroUtil.lua and summary.lua
-- never need to be edited again when a setting is added.
Floony.settingSections = {}

--- Declare a group of settings.
---@param title string                       @heading shown in Settings Summary
---@param defaults table<string, any>        @{ key = defaultValue }. The default's type is the setting's type.
---@param describe (fun(S: table): string[])? @returns the lines to show; if left out, every key is listed
function registerSettings(title, defaults, describe)
    local saved = loadSavedSettings()

    for key, value in pairs(defaults) do
        -- 1. Store fallback default if key is new
        if SETTING_DEFAULTS[key] == nil then
            SETTING_DEFAULTS[key] = value
        end

        -- 2. Restore saved persistent value if available and type matches
        if saved[key] ~= nil and type(saved[key]) == type(SETTING_DEFAULTS[key]) then
            FloonySettings[key] = saved[key]
        elseif FloonySettings[key] == nil then
            FloonySettings[key] = SETTING_DEFAULTS[key]
        end
    end

    Floony.settingSections[#Floony.settingSections + 1] =
        { title = title, defaults = defaults, describe = describe }
end

------------------------------------------------------------------
-- Commands
------------------------------------------------------------------

--- A command that is only really created when it is committed. This allows:
---  - naming it after what it did (cmd.setName('Split 3 arcs')), so the undo history is readable,
---  - skipping the commit when nothing was added (no empty undo entries).
---@param name string
---@return table
local function newCommand(name)
    local cmdName = name
    local items = {}
    local group = nil
    local committed = false
    local proxy = {}

    function proxy.add(c)
        items[#items + 1] = c
        return proxy
    end

    function proxy.withTimingGroup(g)
        group = g
        return proxy
    end

    --- Name shown in the undo / redo history.
    function proxy.setName(n)
        if type(n) == 'string' and n ~= '' then cmdName = n end
        return proxy
    end

    function proxy.count()
        return #items
    end

    function proxy.commit()
        if committed or #items == 0 then return end
        committed = true
        local real = Command.create(cmdName)
        if group then real.withTimingGroup(group) end
        for _, c in ipairs(items) do real.add(c) end
        real.commit()
    end

    return proxy
end

------------------------------------------------------------------
-- Registration
------------------------------------------------------------------

local function register(parent, id, displayname, icon, runner, noRecord)
    local builder = Macro.new(id)
    if parent then builder = builder.withParent(parent) end
    if icon then builder = builder.withIcon(icon) end

    local definition = function()
        if not noRecord then
            Floony.lastRun = Floony.macros[id]
        end
        if FloonyUsage then FloonyUsage.count(id) end
        return runner()
    end

    Floony.macros[id] = { id = id, name = displayname, parent = parent, icon = icon, run = definition }

    builder
        .withName(displayname)
        .withDefinition(definition)
        .add()
end

--- Register a macro whose function receives a command. The command is committed when the function
--- does not return `false` (and only if something was added to it). Inside the function you can call
--- `cmd.setName('...')` to give the undo entry a descriptive name.
---@param parent string?
---@param id string
---@param displayname string
---@param icon string?
---@param func fun(cmd: table): boolean?
---@param noRecord boolean? @when true, "Repeat Last Macro" will not pick this macro up
function MacroNew(parent, id, displayname, icon, func, noRecord)
    local cmd_name = 'Floony: ' .. tostring(displayname):gsub('<[^>]+>', '')
    register(parent, id, displayname, icon, function()
        local cmd = newCommand(cmd_name)
        if func(cmd) ~= false then
            cmd.commit()
        end
    end, noRecord)
end

--- Register a macro that manages its own commands (or does not change the chart at all).
---@param parent string?
---@param id string
---@param displayname string
---@param icon string?
---@param func fun()
---@param noRecord boolean? @when true, "Repeat Last Macro" will not pick this macro up
function MacroNewNOCMD(parent, id, displayname, icon, func, noRecord)
    register(parent, id, displayname, icon, function()
        return func()
    end, noRecord)
end

--- Register a folder.
---@param parent string?
---@param id string
---@param icon string?
---@param displayname string
function FolderNew(parent, id, icon, displayname)
    local builder = Folder.new(id)
    if parent then builder = builder.withParent(parent) end
    if icon then builder = builder.withIcon(icon) end
    Floony.folders[id] = { id = id, name = displayname, parent = parent, icon = icon }
    builder.withName(displayname).add()
end

-- Backwards compatible names (older modules still call these). They now go through MacroNew.

---@param parent string?
---@param id string
---@param displayname string
---@param func fun(cmd: table)
function addCommandMacro(parent, id, displayname, func)
    MacroNew(parent, id, displayname, nil, func)
end

---@param parent string?
---@param id string
---@param displayname string
---@param icon string
---@param func fun(cmd: table)
function addCommandMacroWithIcon(parent, id, displayname, icon, func)
    MacroNew(parent, id, displayname, icon, func)
end

------------------------------------------------------------------
-- Requests
------------------------------------------------------------------
-- All requests must be made inside of a macro. If they are not, errors will be thrown.
Request = {}

--- Request that the user select a note that meets the given constraint.
---@param constraint EventSelectionConstraint
---@param notif string?
---@return Events
function Request.note(constraint, notif)

    local req = EventSelectionInput.requestSingleEvent(constraint)

    if notif then
        notify(notif)
    end

    coroutine.yield()
    return req.result

end

--- Request that the user select an arc.
---@param notif string?
---@return LuaArc
function Request.arc(notif)
    return Request.note(EventSelectionConstraint.create().arc(), notif).arc[1]
end

--- Request that the user select a hold.
---@param notif string?
---@return LuaHold
function Request.hold(notif)
    return Request.note(EventSelectionConstraint.create().hold(), notif).hold[1]
end

--- Request that the user select a tap.
---@param notif string?
---@return LuaTap
function Request.tap(notif)
    return Request.note(EventSelectionConstraint.create().tap(), notif).tap[1]
end

--- Request that the user select a time.
---@param notif string?
---@return integer
function Request.time(notif)

    local req = TrackInput.requestTiming(notif or 'Select timing')

    coroutine.yield()
    return req.result.timing

end

--- Request that the user select a lane (1-4).
---@param notif string?
---@return integer
function Request.lane(notif)

    local req = TrackInput.requestLane(notif or 'Select lane')

    coroutine.yield()
    return req.result.lane

end

--- Request that the user select a time range. The returned values will be done so that the first value is the start time and the second value is the end time, regardless of selection order.
---@param notifA string? @The notification to display when selecting the first time.
---@param notifB string? @The notification to display when selecting the second time.
---@return integer, integer
function Request.timeRange(notifA, notifB)

    local a = Request.time(notifA or 'Select start time')
    local b = Request.time(notifB or 'Select end time')
    return math.min(a, b), math.max(a, b)

end

--- Request that the user select a position on the screen from the given time.
---@param t number
---@param notif string?
---@return XY
function Request.position(t, notif)

    ---@type MacroRequest
    local req = nil

    if notif then
        req = TrackInput.requestPosition(t, notif)
    else
        req = TrackInput.requestPosition(t)
    end

    coroutine.yield()
    return xy(req.result.x, req.result.y)

end

--- Request that the user select a time and then a position on the screen at that time.
---@param tnotif string?
---@param pnotif string?
---@return number, XY
function Request.timeAndPosition(tnotif, pnotif)

    local t = Request.time(tnotif)
    local pos = Request.position(t, pnotif)

    return t, pos

end

--- Request a time range, then return every event of the given kinds inside it.
---@param kinds string[]? @default { 'arc', 'tap', 'hold', 'arctap' }
---@param notifA string?
---@param notifB string?
---@return LuaChartEvent[] events, integer tStart, integer tEnd
function Request.eventsInRange(kinds, notifA, notifB)

    local tStart, tEnd = Request.timeRange(notifA, notifB)
    local found = Event.query(CustomConstraints.timeRange(tStart, tEnd))
    local list = table.icollapse(found, table.unpack(kinds or { 'arc', 'tap', 'hold', 'arctap' }))
    return list, tStart, tEnd

end

--- Request that the user input items into a dialog, then return the raw result.
---@param title string
---@param ... DialogField
---@return table
function Request.dialogRaw(title, ...)

    local req = DialogInput.withTitle(title).requestInput({ ... })

    coroutine.yield()

    return req.result

end

--- Request that the user input items into a dialog, then return one value per field, in order.
--- Numeric fields are converted with tonumber; fields without a value return nil in their slot.
---@param title string
---@param ... DialogField
---@return ...
function Request.dialog(title, ...)

    local fields = { ... }
    local res = Request.dialogRaw(title, ...)

    local ret = {}
    for i, f in ipairs(fields) do

        local val = res[f.key]

        local desc = ''
        if f.fieldConstraint then
            local ok, d = pcall(function() return f.fieldConstraint.getConstraintDescription() end)
            if ok and type(d) == 'string' then desc = d end
        end

        if val ~= nil and (string.match(desc, 'number') or string.match(desc, 'integer') or string.match(desc, 'decimal')) then
            ret[i] = tonumber(val)
        else
            ret[i] = val
        end

    end

    return table.unpack(ret, 1, #fields)

end

------------------------------------------------------------------
-- Custom constraints
------------------------------------------------------------------
CustomConstraints = {}

---Set constraint to accept all notes between the given times
---@param tStart number
---@param tEnd number
---@return EventSelectionConstraint
function CustomConstraints.timeRange(tStart, tEnd)

    return EventSelectionConstraint.create().custom(
        function(ev)
            if ev.is 'long' then
                ---@cast ev LuaArc|LuaHold
                return ev.timing >= tStart and ev.endTiming <= tEnd
            else
                return ev.timing >= tStart and ev.timing <= tEnd
            end
        end,
        'Event must be within time range of ' .. tostring(tStart) .. 'ms to ' .. tostring(tEnd) .. 'ms'
    )

end

------------------------------------------------------------------
-- Dialog fields
------------------------------------------------------------------
local _saved_fields = {}

DialogFields = {}

---@param field DialogField
---@param value any
function DialogFields.save(field, value)
    _saved_fields[field.key] = value
end

---@param field DialogField
function DialogFields.defaultToSaved(field)
    if _saved_fields[field.key] == nil then return end
    DialogFields.default(field, _saved_fields[field.key])
end

--- Set a field's default value without ever raising an error (some field types are picky).
--- Do NOT use this on checkbox fields: ArcCreate's checkbox crashes when it has a default.
---@param field DialogField
---@param value any
---@return DialogField
function DialogFields.default(field, value)
    if value ~= nil then
        pcall(function() field.defaultTo(value) end)
    end
    return field
end

------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------

local function insideMacro()
    local co, isMain = coroutine.running()
    return co ~= nil and isMain ~= true
end

---Notify the user of some content with a dialog (or a toast notification if a dialog cannot be created; when called from outside a macro).
---@param content string
---@param title string? @default 'Notification'
function dialogNotify(content, title)

    if insideMacro() then

        DialogInput.withTitle(title or 'Notification')
            .requestInput {
                DialogField.create('unnamed')
                    .description(content)
            }

        coroutine.yield()

    else

        notify(content)

    end

end

---Notify the user of some content with a customized title dialog (or a toast notification if a dialog cannot be created; when called from outside a macro).
---@param title string
---@param content string
function dialogNotifyCustom(title, content)
    dialogNotify(content, title)
end

------------------------------------------------------------------
-- Selection helpers
------------------------------------------------------------------

--- Get the currently selected arcs/traces. Warns and returns nil when fewer than `min` are selected.
---@param min integer? @default 1
---@param msg string? @warning shown when there are too few
---@return LuaArc[]?
function getSelectedArcs(min, msg)

    min = min or 1
    local arcs = table.icollapse(Event.getCurrentSelection(EventSelectionConstraint.create().arc()), 'arc')

    if #arcs < min then
        notifyWarn(msg or (min <= 1 and 'No arcs selected.' or ('Please select at least ' .. min .. ' arcs.')))
        return nil
    end

    return arcs

end

------------------------------------------------------------------
-- Arcs
------------------------------------------------------------------

--- Cycle the colors of the given arcs, starting from the first arc's color.
---@param arcs LuaArc[]
---@param cmd table
function cycleColors(arcs, cmd)
    local start = table.find(ArcColorCycle, arcs[1].color) or 1
    for i, event in ipairs(arcs) do
        event.color = ArcColorCycle[(i + start - 2) % #ArcColorCycle + 1]
        cmd.add(event.save())
    end
end

--- Get every arc connected after the given arc (end of one == start of the next, same timing group).
---@param arc LuaArc
---@return LuaArc[]
function getFullArc(arc)

    local chain = { arc }
    local current = arc

    local function inChain(v)
        for _, c in ipairs(chain) do
            if c.instanceEquals(v) then return true end
        end
        return false
    end

    -- the cap protects against pathological charts (e.g. arcs forming a loop)
    for _ = 1, 4096 do

        local cur = current
        local nextArcs = Event.query(EventSelectionConstraint.create().custom(function(v)
            return v.is 'arc'
                and math.abs(v.timing - cur.endTiming) <= 1
                and v.startX == cur.endX
                and v.startY == cur.endY
                and v.timingGroup == cur.timingGroup
                and not inChain(v)
        end)).arc

        if not nextArcs[1] then break end

        current = nextArcs[1]
        chain[#chain + 1] = current

    end

    return chain

end

--- Length of one segment, derived from the beat length and the beatline density.
---@param arc LuaArc
---@return number
function arcSliceLength(arc)
    return Context.beatLengthAt(arc.timing, arc.timingGroup) / Context.beatlineDensity
end

--- Split an arc into segments (the old arc is deleted).
---@param arc LuaArc
---@param cmd table
---@param output LuaArc[]? @receives the new arcs
---@param rice boolean? @create zero-length "rice" points instead of segments
function arcSplit(arc, cmd, output, rice)

    output = output or {}
    rice = rice or false

    local spliceTime = arcSliceLength(arc)

    local i = 0
    local lastend = nil
    for timing, endTiming in bestDivisions(arc.timing, arc.endTiming, spliceTime) do
        local startpos = lastend or arc.positionAt(timing)
        local endpos = arc.positionAt(endTiming)

        if startpos.y == endpos.y and i % 2 == 0 then
            if endpos.y > 0 and FloonySettings.forceHeightLines then
                endpos.y = endpos.y - 0.01
            end
        end

        if rice then
            startpos = arc.positionAt(timing)
            endpos = startpos
            timing = math.floor(timing + (endTiming - timing) / 2)
        end

        local a = Event.arc(timing, startpos, endTiming, endpos, arc.isVoid, arc.color, 's', arc.timingGroup)

        cmd.add(a.save())
        output[#output + 1] = a

        i = i + 1
        lastend = endpos
    end

    cmd.add(arc.delete())
end

------------------------------------------------------------------
-- Small helpers shared by every module
------------------------------------------------------------------

--- Turns a dropdown answer into its position in `options` (1 = first).
--- A dropdown can answer with the text or with a number, so both are handled.
---@param value string|number
---@param options string[]
---@return integer
function choiceIndex(value, options)
    if type(value) == 'number' then
        local i = value + 1
        if i > #options then i = value end
        return math.max(1, math.min(i, #options))
    end
    for i, o in ipairs(options) do
        if o == value then return i end
    end
    return 1
end

--- Checkbox results can come back as true or as the text 'true'.
---@param v any
---@return boolean
function isOn(v)
    return v == true or tostring(v) == 'true'
end

--- A number typed in a dialog (result[key]), or `fallback` when it is not a number.
---@param result table
---@param key string
---@param fallback number
---@return number
function num(result, key, fallback)
    return tonumber(result[key]) or fallback
end

--- A math expression typed in a dialog (like '120*2'), or `fallback` when it is not valid.
---@param result table
---@param key string
---@param fallback number
---@return number
function expr(result, key, fallback)
    return evaluateMathExpression(result[key]) or fallback
end

--- True when two notes are the very same note in the chart.
--- (ArcCreate can give a new Lua object for the same note, so `==` is not enough.)
---@param a table?
---@param b table?
---@return boolean
function sameNote(a, b)
    if not a or not b then return false end
    if a.instanceEquals then return a.instanceEquals(b) end
    return a == b
end
sameArc = sameNote   -- the same function, for code that talks about arcs

--- Finds an existing timing group by its name, or nil.
---@param name string
---@return table?
function findGroupByName(name)
    for i = 1, Context.timingGroupCount - 1 do
        local group = Event.getTimingGroup(i)
        if group.name == name then return group end
    end
    return nil
end

--- Sorts a list of notes by time (a selection has no guaranteed order). Gives the list back.
---@param list table[]
---@return table[]
function sortByTime(list)
    table.sort(list, function(a, b) return a.timing < b.timing end)
    return list
end

------------------------------------------------------------------
-- Ask before big jobs
------------------------------------------------------------------
local BIG_JOB_ASK = 3000      -- above this many events, the user is asked first
local BIG_JOB_MAX = 100000    -- above this, the job is refused (it would freeze the editor)

--- Call this BEFORE a macro creates a lot of events. Returns true when the macro may go on.
--- Small jobs go through without any question. Big jobs ask 'Continue?' (default: No).
--- Very big jobs are refused.
---@param count number @about how many events will be created
---@param what string? @what they are, for the message ('events', 'arcs', 'traces'...)
---@return boolean
function confirmBigJob(count, what)
    what = what or 'events'
    count = math.floor(count)

    if count <= BIG_JOB_ASK then return true end

    if count > BIG_JOB_MAX then
        notifyWarn(string.format(
            'This would create about %d %s, which is too many (the limit is %d). Use a smaller range or fewer notes.',
            count, what, BIG_JOB_MAX))
        return false
    end

    local options = { 'No, cancel', 'Yes, continue' }
    local r = Request.dialogRaw('Big job',
        DialogField.create('info')
            .description(string.format(
                'This will create about <b>%d</b> %s.\nThat can make ArcCreate slow for a moment.', count, what)),
        DialogField.create('go')
            .setLabel('Continue?')
            .defaultTo(options[1])
            .dropdownMenu(table.unpack(options))
    )
    if not r then return false end

    return choiceIndex(r['go'], options) == 2
end

------------------------------------------------------------------
-- Usage counter (used by Favorites > Most Used)
-- Counts how many times each macro was run. Saved with FloonyStore, so it survives reloads.
------------------------------------------------------------------
FloonyUsage = {}

local USAGE_KEY = 'floony.usage'
local usageCache = nil   -- id -> number of runs

local function loadUsage()
    if usageCache then return usageCache end

    usageCache = {}
    local text = FloonyStore.getString(USAGE_KEY, '')
    for line in text:gmatch('[^\r\n]+') do
        local id, count = line:match('^(.-)\t(%d+)$')
        if id and id ~= '' then usageCache[id] = tonumber(count) end
    end
    return usageCache
end

local function saveUsage()
    local lines = {}
    for id, count in pairs(usageCache) do
        lines[#lines + 1] = id .. '\t' .. count
    end
    table.sort(lines)
    FloonyStore.setString(USAGE_KEY, table.concat(lines, '\n'))
end

--- Adds one run to a macro. (The Favorites shortcuts and Repeat Last Macro are not counted:
--- the macro they run is counted instead.)
---@param id string
function FloonyUsage.count(id)
    if id:find('^floony%.fav') or id == 'floony.repeatlast' then return end

    local usage = loadUsage()
    usage[id] = (usage[id] or 0) + 1
    saveUsage()
end

--- The most used macros that still exist: { { id = ..., count = ... }, ... }, most used first.
---@param amount integer
---@return table[]
function FloonyUsage.top(amount)
    local list = {}
    for id, count in pairs(loadUsage()) do
        if Floony.macros[id] then
            list[#list + 1] = { id = id, count = count }
        end
    end

    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.id < b.id
    end)

    local result = {}
    for i = 1, math.min(amount, #list) do result[i] = list[i] end
    return result
end

--- How many macros have been counted.
---@return integer
function FloonyUsage.size()
    local n = 0
    for _ in pairs(loadUsage()) do n = n + 1 end
    return n
end

--- Forget all counts.
function FloonyUsage.reset()
    usageCache = {}
    saveUsage()
end

------------------------------------------------------------------
-- Beat grid
-- Finds the real beat lines of a timing group, built from its timing events.
--
-- How the beat lines work: every timing event starts a NEW grid. From that event on, a line
-- is drawn every (60000 / BPM / density) milliseconds, until the next timing event takes over.
-- So the lines are NOT simply 'multiples of the beat length counted from time 0': with a
-- BPM change in the middle of the song, the lines after the change start at the change.
--
--   local grid = BeatGrid.new(0)        -- timing group 0 (the base group)
--   grid:snap(1234.5)                   -- the nearest beat line (can have decimals)
--   grid:snapMs(1234.5)                 -- the same, rounded to whole milliseconds
--   grid:stepAt(1234)                   -- the distance between two lines at that time
--   grid:beatsBetween(1000, 5000)       -- how many beats fit between two times (follows BPM changes)
------------------------------------------------------------------
BeatGrid = {}
BeatGrid.__index = BeatGrid

local MIN_GRID_BPM = 1   -- below this the track hardly moves (a 'stop'), so there is no grid to snap to

--- Builds the grid of one timing group.
---@param tg number? @timing group (default 0, the base group)
---@param density number? @lines per beat (default: the beatline density of the editor)
---@return table
function BeatGrid.new(tg, density)
    tg = tg or 0

    local found = Event.query(EventSelectionConstraint.create().timing().ofTimingGroup(tg)).timing or {}

    local points = {}
    for _, e in ipairs(found) do
        points[#points + 1] = { t = e.timing, bpm = e.bpm }
    end
    table.sort(points, function(a, b) return a.t < b.t end)

    -- Two timing events at the same time: the last one counts.
    local unique = {}
    for _, p in ipairs(points) do
        if #unique > 0 and unique[#unique].t == p.t then
            unique[#unique] = p
        else
            unique[#unique + 1] = p
        end
    end

    -- A group without any timing event (should not happen) falls back to the BPM at time 0.
    if #unique == 0 then
        unique[1] = { t = 0, bpm = Context.bpmAt(0, tg) or Context.baseBpm or 120 }
    end

    return setmetatable({
        tg = tg,
        density = density or Context.beatlineDensity,
        points = unique,
    }, BeatGrid)
end

--- The position (in the list of timing events) of the timing event that rules at time t.
--- Before the first timing event, the first one is used.
function BeatGrid:segmentAt(t)
    local points = self.points
    local low, high, found = 1, #points, 1

    while low <= high do
        local middle = math.floor((low + high) / 2)
        if points[middle].t <= t then
            found = middle
            low = middle + 1
        else
            high = middle - 1
        end
    end
    return found
end

--- The distance between two beat lines inside timing event number `index`, or nil when the
--- BPM is (almost) zero.
function BeatGrid:stepOf(index)
    local bpm = math.abs(self.points[index].bpm or 0)
    if bpm < MIN_GRID_BPM then return nil end
    return 60000 / bpm / self.density
end

--- The distance between two beat lines at time t, or nil when the track is standing still.
function BeatGrid:stepAt(t)
    return self:stepOf(self:segmentAt(t))
end

--- The nearest beat line to time t (a number with decimals, not rounded).
--- Where the track is standing still, t is given back unchanged.
function BeatGrid:snap(t)
    local index = self:segmentAt(t)
    local step = self:stepOf(index)
    if not step then return t end

    local start = self.points[index].t
    local snapped = start + math.floor((t - start) / step + 0.5) * step

    -- The lines of this timing event stop where the next timing event starts. The next one
    -- begins a new grid right there, so its start is a beat line too.
    local nextPoint = self.points[index + 1]
    if nextPoint then
        if snapped >= nextPoint.t or math.abs(t - nextPoint.t) < math.abs(t - snapped) then
            snapped = nextPoint.t
        end
    end

    return snapped
end

--- The nearest beat line to time t, rounded to whole milliseconds.
function BeatGrid:snapMs(t)
    return math.floor(self:snap(t) + 0.5)
end

--- How many beats fit between two times, counted with the real BPM (BPM changes included).
--- A negative number when b is before a. Where the BPM is a 'stop', no beats pass.
function BeatGrid:beatsBetween(a, b)
    if a == b then return 0 end
    if b < a then return -self:beatsBetween(b, a) end

    local total = 0
    local points = self.points

    for i = 1, #points do
        -- The first timing event also rules everything before it.
        local segmentStart = (i == 1) and -math.huge or points[i].t
        local segmentEnd = points[i + 1] and points[i + 1].t or math.huge

        local low = math.max(a, segmentStart)
        local high = math.min(b, segmentEnd)
        if high > low then
            total = total + (high - low) * math.abs(points[i].bpm or 0) / 60000
        end
    end

    return total
end