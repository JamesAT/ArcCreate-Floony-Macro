require 'floony.lib.macroUtil'
require 'floony.lib.utils'

FolderNew('floony', 'floony.manual', 'ea19', '- Manual (WIP) -')

-- formatText: converts lightweight markdown-like tokens to in-game rich text
local function formatText(text)
    -- Replace **text** with <b>text</b> - BOLD
    text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    -- Replace ~~text~~ with <s>text</s> - STRIKETHROUGH
    text = text:gsub("%~%~(.-)%~%~", "<s>%1</s>")
    -- Replace `text` with <u>text</u> - UNDERLINE
    text = text:gsub("`([^`]+)`", "<u>%1</u>")
    -- Replace _text_ with <i>text</i> - ITALICS
    text = text:gsub("%_([^%_]+)%_", "<i>%1</i>")
    -- Replace *text* with <size=75%>text</size> - SMALL TEXT
    text = text:gsub("%*(.-)%*", "<size=75%%>%1</size>")
    -- Replace #text# with <size=115%>text</size> - BIG TEXT
    text = text:gsub("#(.-)#", "<size=115%%>%1</size>")
    return text
end

local function addManual(id, title, body)
    MacroNewNOCMD(
        "floony.manual", "floony.manual." .. id:gsub("%s+", ""), title, "e5df",
        function()
            local bodyField = DialogField.create("Content")
                .description(formatText(body))
            DialogInput.withTitle("Floony Manual - " .. title)
                .requestInput({bodyField})
            coroutine.yield()
        end
    )
end

addManual(
    "1", "Arcs Segmentation",
[[<size=95%>
_OVERVIEW:_
This macro select and splits arcs into segmented patterns.
Use **Generate** macros by picking two arcs (dominant + target).
Use **Split** macros by selecting one or more arcs in the editor.

_GLOBAL SETTINGS:_
- **Force Lines:** Forces segmented arcs to use height lines even if tiny.
- **Type (Stasis/Rice):** 1 = Disabled | 2 = Stasis (no trace) | 3 = Stasis + Trace
- **Multiplier (Rice):** Shortens segments when using Rice split (0 < x <= 1).

Generate Macros (Run any macro in Generate → then pick two arcs):
    • **Zig-Zag (brr):** Alternates segments between arcA and arcB, using the midpoint for each slice (creates zig-zag path).
    • **Ran (ran):** Uses arcB's end position for each slice (random-ish toward target end).
    • **Reverse Ran (nar):** Uses arcB's start position for each slice (reverse of Ran).
    • **Square Wave (wave):** Creates alternating square-wave style pieces between A and B.
    • **Line (line):** For each slice, create a straight short arc from arcA to arcB at slice start (simple connection).

Generate Usage Steps:
1. Run a Generate macro (e.g., Zig-Zag).
2. When prompted, select **Dominant arc** (arc A) and **Target arc** (arc B).
3. The generator will split the arc duration into beatline-based slices and build segments according to the chosen type.
Notes: arcs A and B must share: start timing, end timing, color, timing group, and void status.

Split Macros (Run any macro in Split → then pick a single arc):
    • **Normal:** Split arc into meaningful slices; each slice becomes a single arc segment.
    • **Amygdata:** Same as Normal, but generates a vertical line per slice (refer to Amygdata).
    • **Chunky:** Split each slice into two arcs (a midpoint split) creating chunked segments.
    • **Rice:** Convert arc into many very short segments; the **Multiplier** shortens each slice (recommended 0.3 - 0.7).
    • **Staircase:** Split into stacked arcs that jump vertically (start → start then end → end).
    • **Point (0ms):** Replace each slice with a 0ms point arc (instant points).

Split Usage Steps:
1. Select one or more arcs in the editor.
2. Run the desired Split macro under Segmentation → Split.
3. The macro will replace the selected arcs with the segmented output.

IMPORTANT BEHAVIOR & DETAILS:
- **Selection & validation:** Generate macros requires two arcs selected through prompts; the script checks that both arcs have identical start/end timings, same color, same timing group, and same voidness. If they overlap identically (same start/end XY and type), it refuses.
- **Slice size:** Slices are created using beatLength / beatlineDensity unless a custom spliceTime is provided.
- **Force Lines:** When enabled, very small vertical changes are nudged to create visible height lines.
- **Stasis options:** When 'Type' = 2 or 3, every second segment may become a 'stasis' (either deleted or converted to a void trace) depending on trace setting.
- **Alternating offset:** The generator/split logic offsets alternating segments slightly (0.01) to avoid perfect overlap when Force Lines or special flags are active.

_TIPS:_
- Use Zig-Zag (brr) for fast alternating motion between two arcs.
- Use Chunky for blocky, stepped motion.
- Use Rice + small Multiplier for dense point-like segmentation.
- If segments overlap badly with following notes, adjust beatlineDensity or reduce Multiplier.

_EXAMPLE WORKFLOW:_
1. Select two long arcs that share time ranges.
2. Run Segmentation → Zig-Zag and choose those arcs.
3. If you want smaller pieces, run Settings and lower Rice Multiplier or change density.
</size>










]]
)

addManual(
"2.1", "Arc Rain",
[[
<size=95%>
_OVERVIEW:_
This macros spawn repeated short arcs (mimicking rain) across a selected time range. There are two main modes:
    • **Normal** = spawns vertical/stationary rain traces using random positions inside a selected rectangular area.
    • **Tunnel** = spawns short arcs that travel slightly (X/Y offsets) to form a tunnel-like effect (refer to Callima karma).

_GLOBAL SETTINGS:_
**Default Length**: minimum arc duration in beats (persisted per-session).
**Default Intensity**: number of traces spawned per rain slice (persisted per-session).
**Position memory**: The macros remember last used X/Y corners and ask whether to reuse them.

NORMAL - dialog fields:
    • **Intensity** = Number of traces per slice.
    • **(Min) Length** = Minimum duration (in ms) for each rain arc.
    • **Range Length** = Optional randomness added to length (final length ∈ [min, min + range]).
    • **Add Arctaps** = Toggle to place an arctap near the start of each trace.

TUNNEL - dialog fields:
    • **Intensity** = Number of traces per slice.
    • **Length** = How long each rain arc lasts relative to the slice (in ms).
    • **Ypos intensity** = Scale amount applied to random Y offset (how far arcs jump vertically).
    • **Xpos intensity** = X-axis extension multiplier used with random X offset.
    • **Direction** = "Both", "Left [<--]" or "Right [-->]" to bias end positions.

USAGE STEPS:
1. Run **Arc Rain → Normal** or **Arc Rain → Tunnel**.
2. Select a **start time**.
3. When prompted, pick four positions: X min, X max, Y min, Y max (defines spawn area).
<size=65%>If positions were previously set, you'll be asked whether to reuse them.</size>
4. Select an **end time**.
5. Fill the dialog fields (Intensity, Length, etc.) and confirm.
The macro will iterate from start → end using beatline slices and spawn arcs each step.

_IMPORTANT BEHAVIOR & DETAILS:_
**Position validation:** The macro validates all four positions and aborts with a notification if invalid.
**Timing slices:** Slices are computed from Context.beatLengthAt(tStart) / Context.beatlineDensity (one beatline slice by default).
**Randomization:** Positions and lengths use math.randomf inside the chosen rectangle and length range.
**Arctaps:** If enabled, an Event.arctap is added at (timing + 1) relative to the arc.
**Persistence:** Default length/intensity are updated to the last-used values for convenience.
Tunnel mode computes an **endPosition** for each arc by applying small random X and Y offsets (X biased by Direction).

_TIPS:_
Use a small **Range Length** for subtle variation; larger ranges produce more organic spread.
For dense point-like rain, use Normal with **Length ≈ 0.3–0.7** and high intensity.
For a left/right tunnel sweep, set Direction to Left or Right and increase Xpos intensity.
If rain overlaps problematically with nearby notes, reduce intensity or increase slice density.

_EXAMPLE WORKFLOW (Tunnel):_
1. Place start/end timings over a phrase.
2. Run **Arc Rain → Tunnel**, pick rectangle spanning the playfield edges.
3. Set Intensity = 2, Length = 0.5, Ypos = 0.6, Xpos = 1.2, Direction = Right.
4. Confirm = watch a tunnel of short moving arcs appear across the range.

</size>






]]
)

addManual(
"2.2", "Timing Tools",
[[
<size=95%>
_OVERVIEW:_
Collection of timing-effect macros to produce tempo / stutter / easing gimmicks:
    • **Gradual** = smooth BPM interpolation using easing functions.
    • **Bounce** = BPM that eases from initial → mid → initial (bouncy curve).
    • **Glitch** = segmented high/negative BPM stutters for glitch effects.

_GLOBAL SETTINGS / DEFAULTS:_
**Division**: number of segments per selected time range (defaults to Context.beatlineDensity or last used).
**Start / End BPM**: expressions are allowed (evaluated via evaluateMathExpression).
**Easing**: many presets supported (linear, quad in/out, cubic, quart, quint, expo, elastic, etc.).
**Glitch segments**: default: Context.beatlineDensity × 4; glitch BPM defaults to current BPM; rangeBPM default is large.

GRADUAL:
    • Creates **division** timing points evenly from tStart to tEnd.
    • BPM at each point is interpolated via chosen easing between Start BPM and End BPM.
    • Final timing at tEnd restores beatlineDensity with End BPM.

DIALOG FIELDS (Gradual / Bounce):
    • **Division** = how many intermediate timings.
    • **Start BPM** / **End BPM** = numeric or math expression.
    • **Easing** = choose from many easing presets (l, qi, qo, qio, ci, co, cio, qrti, ... elio).

BOUNCE:
    • Splits the division in half; first half eases initial → mid, second half eases mid→initial.
    • Useful for a tempo "swell" that returns to the original pace.
    • Final timing at tEnd restores Initial BPM and normal beatlineDensity.

GLITCH:
    • Splits range into **segments** (user-defined).
    • For each segment it inserts two timings:
        - At segment start: bpm = ±rangebpm (alternating sign) with short divisor.
        - At segment start + 1ms: bpm = glitchbpm (briefly).
    • Ends by restoring the original BPM at tEnd.
    • The macro uses a fast, aggressive BPM alternation = recommended for short ranges.

USAGE STEPS:
1. Select a time range (tStart, tEnd).
2. Run the desired timing macro (Gradual / Bounce / Glitch).
3. Fill dialog values (division, BPM expressions, easing) and confirm.
4. Inspect and, if needed, adjust timings manually.

_IMPORTANT BEHAVIOR & DETAILS:_
**Expression support:** BPM fields accept arithmetic expressions (e.g. 120 / 2) evaluated by evaluateMathExpression = useful for dynamic BPMs.
**Easing functions:** Many easing curves are available; choose ones like **exi/exo** for exponential ramps or **elio/elo** for elastic feel.
**Glitch caution:** Glitch inserts extreme BPMs (often negative or extremely large). Use only in short bursts and test audio/visual feedback.
**Division edge-cases:** Very high divisions create many timing events; keep performance in mind.

_TIPS:_
For musical-feeling accelerando, use Gradual with division ≈ beatlineDensity and a smooth easing (l or qio).
For attention-grabbing hits, use Bounce with a strong midBpm (can be negative for fast forward motion).
Use Glitch only on short ranges; preview often = high absolute BPMs can behave unexpectedly.

_EXAMPLE WORKFLOW (Gradual):_
1. Select start bars, and end bars where you want a tempo ramp.
2. Run Gradual, set Division = 16, Start BPM = 120, End BPM = 160, Easing = qio.
3. Confirm = timings will be created that smoothly change the pace across the selected bars.

</size>






]]
)

--[[
addManual(
"2.25", "Pause / Sudden / Teleport",
[[
<size=95%>
OVERVIEW:
Utility macros for timing-based gimmicks that manipulate timing points relative to long notes:
• <b>Pause (PauseHold)</b> — replace a selected long note with a Pause (stop BPM) and restore timing after hold ends.
• <b>Sudden</b> — insert an ultra-short hidden/visible timing right before or after a chosen timing.
• <b>Teleport</b> — create a 'teleport' effect by suddenly changing timing based on selected long notes (arc/hold), then restore.

PAUSE / STOP BPM SETTINGS:

<b>sbpm</b> — stop BPM value used for pauses (default 0.01).

Use <b>Set stop BPM</b> macro to change sbpm (persistent).

PAUSEHOLD — Behavior:
• Select a long note (arc or hold) when running any Pause preset (Normal/Half/Double).
• The macro:
- Inserts a timing at the hold start with BPM = sbpm (extreme slow - pause).
- Inserts a timing before the end that restores a higher BPM (end BPM * bpmMul) so audio resumes smoothly.
- Deletes the selected hold (the hold becomes a timing pause effect).
• Presets: Normal (1×), Half (0.5×), Double (2×) — these multiply the BPM used to restore.

SUDDEN — Behavior:
• <b>Timing - 1 (Hidden)</b>: place a very large BPM at (timing - 1) to hide the next beat visually, then restore at timing.
• <b>Timing + 1 (Visible)</b>: place a very large BPM at timing to push the visual, then restore at timing + 1.
• Use TrackInput.requestTiming() to choose the reference timing.

TELEPORT — Behavior & Dialog:
• Requires at least one selected long note (arc/hold).
• Dialog fields:
- <b>Multiplier</b> — how strong the teleport is (in beatlines).
- <b>Teleport From</b> — "start" or "end" (select whether teleport originates at start-time or end-time of the hold).
• Persistence: multiplier and startPoint are saved via Persistent.setString.
• For each selected hold:
- The macro may clamp hold.endTiming if it would overlap the next hold (tolerance protection).
- If <b>startPoint = "end"</b>:
- Insert a stop-like timing at hold.timing (e.g., 0.01).
- Insert a high BPM at hold.endTiming - 1 to "snap" the playhead (scaled using multiplier).
- Optionally restore a normal timing at hold.endTiming if space permits.
- If <b>startPoint = "start"</b>:
- Insert a high BPM at hold.timing and restore at hold.timing + 1.
• Finally the macro deletes the original long notes (they are converted into the teleport timing edits).

USAGE STEPS:

To edit stop BPM: Run <b>Pause → Set stop BPM</b> and enter desired sbpm (or leave blank for 0.01).

For Pause presets: select a long note then run Pause → [Normal/Half/Double].

For Sudden: run the desired Sudden macro and pick a reference timing.

For Teleport:
a. Select one or more long notes (arc/hold).
b. Run Teleport macro, tune Multiplier and Teleport From.
c. Confirm — teleports are applied and original notes are removed.

IMPORTANT BEHAVIOR & DETAILS:

<b>Tolerances:</b> Teleport uses a millisecond tolerance to prevent timing overlap between consecutive holds.

<b>Hold removal:</b> Pause and Teleport delete the original hold(s) after inserting timings; keep backups if unsure.

<b>sbpm note:</b> Very small sbpm values (≈0.01) emulate a hold/pause visually but are not literal "stop" events — they work by extreme slowdown timing.

<b>Safety:</b> Teleport multiplies beatline-derived values; excessively large multipliers can produce extreme BPMs — preview before finalizing.

TIPS:
Use Pause → Half for subtle slowdowns that still feel musical.
Use Teleport with small multipliers first (e.g., 0.5–2) and test playback to find a sweet spot.
Keep a copy of the original long notes (or the chart) before running destructive conversions.

EXAMPLE WORKFLOW (Teleport):
Select a chain of arcs/holds across a phrase.
Run Teleport, set Multiplier = 1.2, Teleport From = end.
Confirm — each hold becomes a short pause + jump that "teleports" the playhead near the hold end.

</size>






)
]]--