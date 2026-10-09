-- ============================================================================
-- Smoky Plum Night — Hyprland config (Lua)
-- ----------------------------------------------------------------------------
-- Hand-translated from hyprland.conf on 2026-07-14.
--
-- Since Hyprland 0.55 the config language is LUA, and hyprlang (.conf) is
-- deprecated. Hyprland loads THIS file (hyprland.lua) if it exists, otherwise
-- it falls back to hyprland.conf. Both files still live in this directory, so
-- to roll back instantly:  mv hyprland.lua hyprland.lua.wip && hyprctl reload
--
-- How Lua config works (the 30-second version):
--   * Everything is exposed on a global table called `hl`.
--   * `hl.config{...}` sets variables. Config sections (general, decoration,
--     input, ...) are just nested Lua TABLES. You can call hl.config as many
--     times as you like; the tables merge.
--   * `hl.bind("SUPER + Q", <dispatcher>)` registers a keybind. Dispatchers
--     live under `hl.dsp.*` and are values you PASS to hl.bind (they don't run
--     immediately).
--   * `..` is Lua's string-concatenation operator. `for` loops and functions
--     are real language features — we use them below to kill repetition.
--   * Colours preserved verbatim from the Smoky Plum token export.
-- ============================================================================


---------------------
---- MY PROGRAMS ----
---------------------
-- `$mod = SUPER` in .conf becomes an ordinary Lua local. Same for the command
-- shortcuts — they're just strings we reuse below.
local mod           = "SUPER"
local terminal      = "alacritty"
local launcher      = "rofi -show drun"
local browser       = "firefox"
local editor        = "code"
local fileManager   = "dolphin"
local steam         = "steam"
local screenshotCmd = "~/.local/bin/hypr-screenshot"

-- Two little helpers so the ~20 quickshell/screenshot binds below stay DRY.
-- Each RETURNS a dispatcher (hl.dsp.exec_cmd(...)) for hl.bind to use.
-- .conf equivalent was: exec, qs ipc -p ~/Projects/quickshell call shell <fn>
local function qs(fn)
    return hl.dsp.exec_cmd("qs ipc -p ~/Projects/quickshell call shell " .. fn)
end
local function shot(mode)
    return hl.dsp.exec_cmd(screenshotCmd .. " " .. mode)
end

-- Wrapper around hl.bind that ALSO attaches a description.
-- Why: under a Lua config, `hyprctl binds -j` reports every bind with
-- dispatcher "__lua" and a numeric arg — the real action name is gone. The
-- quickshell cheatsheet reads that JSON, so we hand it a description instead.
-- Convention: "[Category] Action". The "[Category]" prefix tells the cheatsheet
-- which section to file the bind under (Apps / Shell / Capture / Windows /
-- Workspaces / Media & hardware); the rest is the label it shows.
-- `extra` is an optional flags table (e.g. { mouse = true }).
local function bind(keys, dispatcher, description, extra)
    local flags = extra or {}
    flags.description = description
    hl.bind(keys, dispatcher, flags)
end

-- Detect which machine we're on, so ONE hyprland.lua can serve several hosts.
-- The Lua sandbox gives us io.popen, so we just ask the system its hostname.
-- (Wrapped in pcall so a weird environment can't crash config load.)
local function hostname()
    local ok, name = pcall(function()
        local p = io.popen("hostname")
        local v = p:read("l")
        p:close()
        return v
    end)
    return (ok and name) or ""
end
local HOST = hostname()

-- Raise-or-launch: if a window of this class already exists, jump to its
-- workspace; otherwise run launchCmd. hl.get_windows() reads live window state.
local function raiseOrLaunch(class, launchCmd)
    for _, w in ipairs(hl.get_windows()) do
        local ok, c = pcall(function() return w.class end)
        if ok and c == class then
            local wok, ws = pcall(function() return w.workspace end)
            if wok and ws then
                hl.dispatch(hl.dsp.focus({ workspace = ws.id }))
                return
            end
        end
    end
    hl.exec_cmd(launchCmd)
end

-- Throw the focused window to the other monitor (verified: move accepts monitor).
local function throwToOtherMonitor()
    local mons = hl.get_monitors()
    if #mons < 2 then return end
    local active = hl.get_active_monitor()
    for _, m in ipairs(mons) do
        if m.name ~= active.name then
            hl.dispatch(hl.dsp.window.move({ monitor = m.name }))
            return
        end
    end
end

-- The normal look, in one place. The LOOK AND FEEL block below reads these, and
-- so does applyLook() when it restores from Zen or game mode. Keeping a single
-- copy is the point: when the two lists were written out separately, toggling
-- Zen off "restored" whatever was hard-coded in the toggle, not what you'd
-- actually configured. Change a number here and both paths follow.
local look = {
    gaps_in      = 5,
    gaps_out     = 8,
    border_size  = 1,
    rounding     = 6,
    dim_strength = 0.15,
}

-- Two things strip visual furniture: Zen mode (manual, SUPER+Z) and game mode
-- (automatic, in EVENT AUTOMATIONS below). They overlap — quitting a game while
-- Zen is on must NOT bring the gaps back — so neither writes config directly.
-- Each flips a flag here, and applyLook() recomputes the union.
local mode = { zen = false, game = false }

local function applyLook()
    local flat  = mode.zen or mode.game   -- geometry: gaps, borders, rounding
    local quiet = mode.game               -- effects that cost GPU time per frame

    hl.config({
        general = {
            gaps_in     = flat and 0 or look.gaps_in,
            gaps_out    = flat and 0 or look.gaps_out,
            border_size = flat and 0 or look.border_size,
        },
        decoration = {
            rounding     = flat and 0 or look.rounding,
            dim_inactive = not quiet,
            blur   = { enabled = not quiet },
            shadow = { enabled = not quiet },
        },
        animations = { enabled = not quiet },
    })
end

-- Zen / focus mode: toggle a clean, distraction-free look on and off.
local function toggleZen()
    mode.zen = not mode.zen
    applyLook()
end


-------------------------------
---- MONITORS & WORKSPACES ----
-------------------------------
-- Per-host display + workspace layout. To support a new machine, add a key to
-- `layouts` with its hostname; `default` is the fallback (e.g. a laptop with a
-- single internal panel). Each layout lists monitors and which display the
-- primary (1-9) and secondary (10) workspaces live on.
local layouts = {
    ["cachyos-x8664"] = {
        monitors = {
            -- The PG248Q is a 180Hz panel; it had been pinned to 60Hz since the
            -- original .conf. Exact rate from `hyprctl monitors all`.
            -- The PG248Q sits to the right of the ultrawide in portrait
            -- (transform 1 = rotated 90°, so it is 1080 wide x 1920 tall).
            -- Bottom edges are aligned: the ultrawide drops 1920-1440 = 480px,
            -- which keeps every coordinate positive (no negative y for XWayland).
            { output = "DP-2", mode = "5120x1440@119.97", position = "0x480",  scale = 1 },
            { output = "DP-1", mode = "1920x1080@179.98", position = "5120x0", scale = 1, transform = 1 },
        },
        primary   = "DP-2",  -- workspaces 1-9
        secondary = "DP-1",  -- workspace 10
    },

    -- Fallback for any other machine: use whatever single display is present.
    default = {
        monitors = {
            { output = "", mode = "preferred", position = "auto", scale = 1 },
        },
        primary   = "",  -- empty = don't pin workspaces to a named monitor
        secondary = "",
    },
}

local layout = layouts[HOST] or layouts.default

-- Apply this host's monitors...
for _, m in ipairs(layout.monitors) do
    hl.monitor(m)
end
-- ...plus a catch-all so a hot-plugged/unknown display still lights up.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspaces 1-9 on the primary display (ws1 is its default); 10 on secondary.
-- When a layout leaves primary/secondary empty (single-monitor hosts) we simply
-- don't pin the workspace to a named output.
for i = 1, 10 do
    local rule = { workspace = tostring(i) }
    local mon = (i <= 9) and layout.primary or layout.secondary
    if mon ~= "" then
        rule.monitor = mon
    end
    if i == 1 or (i == 10 and layout.secondary ~= "") then
        rule.default = true  -- ws1 always default; ws10 default only on multi-monitor
    end
    hl.workspace_rule(rule)
end


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- .conf: env = KEY,VAL   ->  hl.env("KEY", "VAL")
hl.env("XCURSOR_SIZE",                "24")
hl.env("HYPRCURSOR_SIZE",             "24")
hl.env("QT_QPA_PLATFORM",             "wayland;xcb")
hl.env("GDK_BACKEND",                 "wayland,x11,*")
hl.env("SDL_VIDEODRIVER",             "wayland")
hl.env("MOZ_ENABLE_WAYLAND",          "1")
hl.env("LIBVA_DRIVER_NAME",           "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME",   "nvidia")
hl.env("NVD_BACKEND",                 "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT","auto")
hl.env("QS_ICON_THEME",               "Tela-purple-dark")
hl.env("QT_QPA_PLATFORMTHEME",        "qt6ct")

-- .conf: envd = KEY,VAL  (the "d" = also push to the D-Bus activation env).
-- In Lua that's the optional 3rd argument `true`.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)
hl.env("XDG_SESSION_DESKTOP", "Hyprland", true)
hl.env("XDG_SESSION_TYPE",    "wayland",  true)


-------------------
---- AUTOSTART ----
-------------------
-- .conf: exec-once = ...  ->  run once, on Hyprland startup.
-- We hook the "hyprland.start" event and call hl.exec_cmd for each.
-- (Note: inside here it's hl.exec_cmd — a direct run. In keybinds it's
--  hl.dsp.exec_cmd — a dispatcher. Same idea, different context.)
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    -- hl.exec_cmd("hyprpaper")  -- replaced by quickshell wallpaper domain
    hl.exec_cmd("hypridle")
    hl.exec_cmd("qs -n -p ~/Projects/quickshell")
    -- Wayland hands the clipboard out from the SOURCE app, so copying then
    -- closing the app loses the entry. This daemon keeps a copy alive.
    -- "regular" not "both" on purpose: including the primary selection means
    -- every mouse drag-select gets persisted, which fights middle-click paste.
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Whole blocks (input/general/decoration/...) become nested tables passed to
-- hl.config. Booleans are Lua true/false; numbers are unquoted.
hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,          -- -1.0 .. 1.0; 0 = no modification
        repeat_delay = 250,        -- ms held before a key starts repeating (default 600)
        repeat_rate  = 40,         -- repeats per second once it does (default 25)
        numlock_by_default = true,
        touchpad = {
            natural_scroll = true,
        },
    },

    cursor = {
        no_hardware_cursors = false,
        inactive_timeout    = 3,     -- seconds of stillness before the cursor hides
        hide_on_key_press   = true,  -- ...and hide it the moment you start typing
        -- Focus may move to a new window; the POINTER may not be dragged along.
        --
        -- Default is false, i.e. Hyprland warps the cursor to whatever gains
        -- focus. Paired with focus_on_activate below, opening a handful of Steam
        -- game pages teleported the pointer onto each one as it appeared — and
        -- since follow_mouse = 1 routes scroll to whatever is UNDER the cursor,
        -- the scroll you were in the middle of ended up on the new window.
        --
        -- Deliberately not solved by turning focus_on_activate off: raising the
        -- window is the useful half and was asked for by name (see its comment).
        -- The teleport is the part that was never wanted.
        --
        -- Known cost, accepted: after a keyboard focus move (SUPER+h/j/k/l) the
        -- pointer no longer follows, so it is left hovering the OLD window and
        -- follow_mouse will hand focus back the moment the mouse is nudged.
        no_warps            = true,
    },

    general = {
        gaps_in     = look.gaps_in,      -- these four live in the `look` table at
        gaps_out    = look.gaps_out,     -- the top of the file so Zen/game mode
        border_size = look.border_size,  -- restore to the same values
        -- col.active_border = rgba(ff4a74ff) rgba(e9ddffff) 45deg
        -- A gradient becomes { colors = { ... }, angle = N }.
        col = {
            active_border   = { colors = { "rgba(ff4a74ff)", "rgba(e9ddffff)" }, angle = 45 },
            inactive_border = "rgba(31263ccc)",
        },
        resize_on_border = true,
        layout           = "dwindle",
        -- Master switch only: nothing tears until a window also carries the
        -- `immediate` rule (see the game-tearing rule under WINDOW RULES).
        allow_tearing    = true,
        snap = {
            enabled = true,   -- floating windows snap to screen edges and to each other
        },
    },

    decoration = {
        rounding         = look.rounding,
        active_opacity   = 1.0,
        inactive_opacity = 0.96,
        -- Finding the focused window on a 5120px-wide panel is a real problem;
        -- opacity alone wasn't enough of a cue. Game mode turns this back off.
        dim_inactive     = true,
        dim_strength     = look.dim_strength,
        shadow = {
            enabled      = true,
            range        = 14,
            render_power = 2,
            color        = "rgba(00000080)",  -- if this errors on reload, use 0x80000000
        },
        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            vibrancy = 0.1,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        -- A link clicked in Discord/Slack actually raises Firefox instead of
        -- loading silently on whatever workspace it was left on.
        focus_on_activate       = true,
        -- Adaptive sync. 0 = off, 1 = always, 2 = fullscreen only. The C49RG9 is
        -- a FreeSync panel, but leaving VRR on across the desktop is the classic
        -- source of brightness flicker on NVIDIA — so: fullscreen only.
        vrr                     = 2,
    },

    binds = {
        workspace_back_and_forth    = true,  -- SUPER+3 twice returns to the previous workspace
        movefocus_cycles_fullscreen = true,  -- directional focus can leave a fullscreen window
    },

    render = {
        -- Hand a lone fullscreen window straight to the display, skipping
        -- compositing. 0 = off, 1 = on, 2 = only for windows advertising the
        -- "game" content type. If a game ever renders black or glitches in
        -- fullscreen, this is the first thing to set back to 0.
        direct_scanout = 1,
    },

    ecosystem = {
        no_update_news = true,   -- no post-update changelog popup
    },
})

-- Animation curves + timelines.
-- .conf: bezier = smooth, 0.22, 1, 0.36, 1
--   -> the 4 numbers are two control points {x1,y1},{x2,y2}.
hl.curve("smooth", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })

-- .conf: animation = NAME, ONOFF, SPEED, CURVE[, STYLE]
--   -> leaf = NAME, enabled = ONOFF, speed = SPEED, bezier = CURVE, style = STYLE
hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "smooth", style = "popin 86%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "smooth", style = "popin 86%" })
hl.animation({ leaf = "border",     enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smooth", style = "slidefade 10%" })


-----------------------------
---- WINDOW / LAYER RULES ----
-----------------------------
-- .conf used several `windowrule = match:class ^(x)$, <field>` lines per app.
-- In Lua one hl.window_rule call carries the match AND all its fields together.
hl.window_rule({ name = "pavucontrol",  match = { class = "^(pavucontrol)$" },
                 float = true, size = "540 480", center = true })
hl.window_rule({ name = "nm-editor",    match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "blueman",      match = { class = "^(blueman-manager)$" },      float = true })
hl.window_rule({ name = "polkit-kde",   match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ name = "portal-gtk",   match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true })
hl.window_rule({ name = "file-dialogs", match = { title = "^(Open File|Save File|Save As|Choose Files|Open Folder)(.*)$" }, float = true })
hl.window_rule({ name = "file-roller",  match = { class = "^(file-roller)$" }, float = true })
-- Picture-in-Picture: float + pin + fixed size + parked bottom-right.
hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" },
                 float = true, pin = true, size = "25% 25%", move = "73% 73%" })
-- .conf: opacity 0.95 0.88  -> "<active> <inactive>"
hl.window_rule({ name = "alacritty-opacity", match = { class = "^(Alacritty)$" }, opacity = "0.95 0.88" })

-- Games opt in to tearing (general.allow_tearing above is only the master
-- switch), which drops a frame of latency in fullscreen. Steam launches every
-- title in the library as steam_app_<id>, so one pattern covers all of them.
-- NOTE: this match is a REGEX. The game-mode automation at the bottom of the
-- file matches the same apps with LUA PATTERNS (%d rather than [0-9]). Adding a
-- game means editing both — they can't share a string.
hl.window_rule({ name = "game-tearing",
                 match = { class = "^(steam_app_[0-9]+|gamescope)$" }, immediate = true })

-- Keep hypridle's hands off the session while something is genuinely in use.
-- hypridle's timers key off INPUT, and neither a gamepad nor a movie you're
-- watching counts as input — which is how a 15-minute cutscene or a controller-
-- only session ended up at the lock screen mid-play.
--
-- Two rules, and the order matters: later rules win, so the game rule below
-- overrides the catch-all for game windows.
--   * everything, while fullscreen — covers fullscreen video and fullscreen
--     games without keeping the screen awake for an idle desktop.
--   * games, while focused — borderless-windowed games often never set the
--     fullscreen state, so the rule above would miss them. "focus" rather than
--     "always" on purpose: a game left running overnight shouldn't hold the
--     display on once you've alt-tabbed away from it.
hl.window_rule({ name = "idle-fullscreen", match = { class = ".*" },
                 idle_inhibit = "fullscreen" })
hl.window_rule({ name = "idle-games",      match = { class = "^(steam_app_[0-9]+|gamescope)$" },
                 idle_inhibit = "focus" })

-- .conf: layerrule = match:namespace ^(x)$, blur yes
hl.layer_rule({ name = "blur-quickshell", match = { namespace = "^(quickshell)$" }, blur = true })
hl.layer_rule({ name = "blur-rofi",       match = { namespace = "^(rofi)$" },       blur = true })


---------------------
---- KEYBINDINGS ----
---------------------
-- We use the bind() helper (top of file): bind(keys, dispatcher, description).
-- The "[Category] Action" description powers the quickshell cheatsheet.

-- Apps / launchers
bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal),     "[Apps] Terminal")
bind(mod .. " + D",      hl.dsp.exec_cmd(launcher),     "[Apps] App launcher")
bind(mod .. " + B", function() raiseOrLaunch("firefox", browser) end,     "[Apps] Browser (raise or launch)")
bind(mod .. " + C", function() raiseOrLaunch("Code", editor) end,         "[Apps] Editor (raise or launch)")
bind(mod .. " + E", function() raiseOrLaunch("dolphin", fileManager) end, "[Apps] Files (raise or launch)")
bind(mod .. " + U", function() raiseOrLaunch("steam", steam) end,        "[Apps] Steam (raise or launch)")

-- Quickshell surfaces (via the qs() helper defined at the top)
bind(mod .. " + SPACE",            qs("toggleLauncher"),          "[Shell] Launcher")
bind(mod .. " + Tab",              qs("toggleOverview"),          "[Shell] Overview (all windows)")
-- The Ambient canvas absorbed the control center, the dashboard, and the
-- standalone media + calendar popups. A and W were both kept as doors into the
-- station so either muscle memory still worked; Dylan settled on W (2026-07-25),
-- so the A door was retired. Super+A then launched Steam (2026-08-03) but lasted
-- a day: A is strafe-left, so a stray Super mid-fight raised Steam over the game
-- (2026-08-04). Steam moved to Super+U — a right-hand key, unreachable while the
-- left hand is on WASD. Anything bound to the WASD cluster has this hazard; keep
-- new app binds on the right half. Period opens the quiet clock depth.
-- Super+A and Super+comma are both free — media lives in the station now.
bind(mod .. " + N",                qs("toggleNotifications"),     "[Shell] Notifications")
bind(mod .. " + period",           qs("toggleAmbient"),           "[Shell] Ambient (zen clock)")
bind(mod .. " + slash",            qs("toggleCheatsheet"),        "[Shell] Keybind cheatsheet")
-- Super+W was the station door until 2026-09-06 and is now the CONTEXT PANEL.
-- The station was never actually opened through it: the bar's Wi-Fi and
-- Bluetooth pills reach it via `stationSection`, and the agents pill falls back
-- to it, so it was being used as a control drawer other things route INTO and
-- never as a page anyone summoned. Its six panes are each answered more cheaply
-- elsewhere — the island for media, the bar pills for the toggles, Settings for
-- the vitals — which is why a deliberate press never had a question to answer.
--
-- The context panel had the opposite defect: built, labelled in the cheatsheet,
-- and bound to nothing, so the one surface scoped to the app you are actually
-- IN could not be reached at all.
--
-- It also inverts the WASD hazard the note above records rather than inheriting
-- it. W is strafe-forward, so a stray Super mid-fight used to throw a
-- full-output smoke takeover across both monitors; it now raises an undimmed
-- panel about the game itself, which is the case the archetype was carved out
-- for (patterns/context-panels.md cites the PS5 Control Center by name).
--
-- The station keeps every door it was actually using: the two bar pills, the
-- `toggleStation` IPC, and Super+period then Space.
bind(mod .. " + W",                qs("toggleContext"),           "[Shell] Context (focused app)")
bind(mod .. " + I",                qs("toggleSettings"),          "[Shell] Shell settings")
-- Edit layout mode sits beside Shell settings because it is the other
-- configuration mode. It lived on Super+L until 2026-07-27, where it was the
-- ONLY double-bound chord in 89 — it collided with the vim focus set's
-- "[Windows] Focus right", and which one actually fired was never established.
-- Dylan moved it here (/make-decision); every other L slot was taken too
-- (SHIFT = move window right, CTRL = lock, ALT = grow width), so the key had
-- to change, not the modifier.
bind(mod .. " + SHIFT + I",        qs("toggleEditMode"),          "[Shell] Edit layout mode")
-- Storage sits on SHIFT+D against the "[Apps] App launcher" on plain D, the
-- same shape every other shell surface here uses (SHIFT+I, SHIFT+N, SHIFT+V,
-- SHIFT+W all shift a related plain chord). D is in the WASD cluster the note
-- above warns about, but that warning is about APP binds raising a window over
-- a game on a stray Super — this needs Super+SHIFT together, and it opens an
-- overlay that Esc closes rather than raising another window.
--
-- No separate filelight bind: the surface opens it on `f`, from the header
-- button, and on a right-click of any row, and all three hand it the directory
-- you had drilled to. A global chord could only ever start it at $HOME, which
-- is the one place you already have an answer for.
bind(mod .. " + SHIFT + D",        qs("toggleStorage"),           "[Shell] Storage (where the disk went)")
bind(mod .. " + SHIFT + N",        qs("toggleDnd"),               "[Shell] Do not disturb")
bind(mod .. " + SHIFT + V",        qs("toggleClipboard"),         "[Shell] Clipboard history")
bind(mod .. " + SHIFT + W",        qs("toggleWallpapers"),        "[Shell] Wallpaper & theme")
bind(mod .. " + CTRL + W",         qs("cycleWallpaper"),          "[Shell] Next wallpaper")
bind(mod .. " + CTRL + L",         qs("lock"),                    "[Shell] Lock screen")
bind(mod .. " + CTRL + Escape",    qs("powerMenu"),               "[Shell] Power menu")
-- Games on P for Play, not G for Games: SHIFT+G is the component gallery, and
-- the surface this opens is the one you reach for far more often than a game
-- window group (plain G), so it takes the free chord rather than displacing an
-- existing one. Reads the Steam library off disk — no Steam window involved.
bind(mod .. " + SHIFT + P",        qs("toggleGames"),             "[Shell] Steam library")
bind(mod .. " + SHIFT + G",        hl.dsp.exec_cmd("~/Projects/quickshell/gallery/run.sh"), "[Shell] Component gallery")
-- Eyedropper: pick any pixel on screen, hex lands on the clipboard (and so in
-- cliphist / SUPER+SHIFT+V). Next to SUPER+C on purpose — C for colour.
-- --format=hex (equals form, as hyprpicker's own help writes it), -l for
-- lowercase to match the Smoky Plum token style, -n to confirm the pick since
-- autocopy is otherwise silent.
bind(mod .. " + SHIFT + C",        hl.dsp.exec_cmd("hyprpicker -a -n -l --format=hex"), "[Shell] Colour picker (hex → clipboard)")

-- Screen capture / recording
bind(mod .. " + CTRL + S",         qs("recordRegion"),            "[Capture] Record region")
-- Screen-record has no region select: the shell's takeover surfaces (the games
-- console, Ambient) already cover the whole output, so slurp would only crop
-- them. Records the FOCUSED monitor, so the other one stays out of the file.
bind(mod .. " + SHIFT + R",        qs("recordScreen"),            "[Capture] Record screen")
bind(mod .. " + CTRL + SHIFT + S", qs("recordStop"),              "[Capture] Stop recording")
bind("PRINT",                      hl.dsp.exec_cmd("spectacle --new-instance --region"), "[Capture] Screenshot region (Spectacle)")
bind(mod .. " + PRINT",            shot("region-save"),           "[Capture] Screenshot region → save")
bind(mod .. " + SHIFT + PRINT",    shot("region-copy"),           "[Capture] Screenshot region → copy")
bind(mod .. " + CTRL + PRINT",     shot("full-save"),             "[Capture] Screenshot screen → save")
bind(mod .. " + ALT + PRINT",      shot("full-copy"),             "[Capture] Screenshot screen → copy")
bind(mod .. " + S",                shot("region-copy"),           "[Capture] Screenshot region → copy")
-- Grab a region and open it in satty to arrow/blur/crop before it goes anywhere.
-- Sits on ALT+S so the whole capture family stays on S: plain = copy,
-- SHIFT = save, CTRL = record, ALT = annotate.
bind(mod .. " + ALT + S",          shot("region-annotate"),       "[Capture] Screenshot region → annotate")
bind(mod .. " + SHIFT + S",        shot("full-save"),             "[Capture] Screenshot screen → save")

-- Window management
bind(mod .. " + SHIFT + Q", hl.dsp.window.close(),                                          "[Windows] Close window")
bind(mod .. " + SHIFT + E", hl.dsp.exit(),                                                  "[Windows] Exit Hyprland")
bind(mod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "[Windows] Fullscreen")
bind(mod .. " + M",         hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), "[Windows] Maximize")
bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }),                     "[Windows] Toggle floating")
bind(mod .. " + G",         hl.dsp.group.toggle(),                                          "[Windows] Toggle group")
bind(mod .. " + P",         hl.dsp.window.pseudo(),                                         "[Windows] Pseudo-tile")
bind(mod .. " + T",         hl.dsp.layout("togglesplit"),                                   "[Windows] Toggle split")

-- Special (scratchpad) workspace
bind(mod .. " + grave",         hl.dsp.workspace.toggle_special("magic"),         "[Workspaces] Toggle scratchpad")
bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }), "[Workspaces] Send to scratchpad")

-- Resize the active window by pixels (ALT + h/l/k/j)
bind(mod .. " + ALT + H", hl.dsp.window.resize({ x = -40, y = 0 }), "[Windows] Shrink width")
bind(mod .. " + ALT + L", hl.dsp.window.resize({ x =  40, y = 0 }), "[Windows] Grow width")
bind(mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -40 }), "[Windows] Shrink height")
bind(mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y =  40 }), "[Windows] Grow height")

-- Alt+Tab, and the reason it has to exist HERE rather than be left to the app.
--
-- There was no Alt+Tab bind at all, so the key went straight through to whatever
-- was focused. That is fine on a desktop and useless in a fullscreen game: some
-- handle the key, some swallow it, and "can I get out of this game" became a
-- property of the game rather than of the machine. A Hyprland bind is taken by
-- the compositor before the client ever sees the key, so this works in exclusive
-- fullscreen and works identically in every title.
--
-- `last` and not `window.cycle_next()`: cycle_next walks the windows of the
-- CURRENT workspace, and the thing being alt-tabbed to is usually on the other
-- monitor (the video you left running while the game took the main screen).
-- `focus{ last = true }` is the global last-focused window and crosses monitors
-- and workspaces — verified toggling between a game-side window on DP-2/ws1 and
-- Firefox on DP-1/ws10.
--
-- The valid keys for hl.dsp.focus are direction, monitor, window, urgent_or_last
-- and last; the dispatcher enumerates them in its error, which is how these were
-- found. It DOES validate, unlike hyprctl's dpms dispatch — but confirm any new
-- one against `hyprctl activewindow` rather than the "ok" it prints.
--
-- Cost, accepted: games no longer receive Alt+Tab themselves. That is the point.
bind("ALT + Tab", hl.dsp.focus({ last = true }), "[Windows] Last window (Alt+Tab)")

-- Move focus (arrows + hjkl) and move window (SHIFT + arrows/hjkl).
-- A table of {key, direction} records + a loop replaces 16 near-identical lines.
local dirBinds = {
    { key = "left",  dir = "left"  }, { key = "H", dir = "left"  },
    { key = "right", dir = "right" }, { key = "L", dir = "right" },
    { key = "up",    dir = "up"    }, { key = "K", dir = "up"    },
    { key = "down",  dir = "down"  }, { key = "J", dir = "down"  },
}
for _, b in ipairs(dirBinds) do
    bind(mod .. " + " .. b.key,         hl.dsp.focus({ direction = b.dir }),       "[Windows] Focus " .. b.dir)
    bind(mod .. " + SHIFT + " .. b.key, hl.dsp.window.move({ direction = b.dir }), "[Windows] Move window " .. b.dir)
end

-- Workspaces: SUPER + 1..0 switches, SUPER + SHIFT + 1..0 moves the window.
-- `i % 10` maps workspace 10 onto the "0" key.
for i = 1, 10 do
    local key = i % 10
    bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       "[Workspaces] Switch to " .. i)
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "[Workspaces] Send window to " .. i)
end

-- Media / volume keys (no modifier). These match the old .conf exactly (plain
-- binds). If you want them to work while the screen is locked and to repeat
-- while held, pass a flags table:  { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "[Media & hardware] Volume up")
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      "[Media & hardware] Volume down")
bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     "[Media & hardware] Mute")
bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),                           "[Media & hardware] Play / pause")
bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),                                 "[Media & hardware] Next track")
bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),                             "[Media & hardware] Previous track")

-- Mouse binds: SUPER + LMB drags a window, SUPER + RMB resizes it.
-- .conf `bindm` becomes a normal bind with the { mouse = true } flag (passed as
-- the 4th arg to our bind() helper).
bind(mod .. " + mouse:272", hl.dsp.window.drag(),   "[Windows] Drag to move",   { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "[Windows] Drag to resize", { mouse = true })






-------------------------
---- EVENT AUTOMATIONS ----
-------------------------
-- Lua lets us REACT to compositor events with hl.on(event, callback) — things
-- hyprlang couldn't do without a separate socket2 listener script. Each handler
-- gets the relevant object (a window/monitor) as its argument.
-- Inside handlers: run a command with hl.exec_cmd (direct); fire a dispatcher
-- immediately with hl.dispatch(<hl.dsp....>).

-- Small helper: call a quickshell shell IPC function from within a handler.
local function qsRun(fn)
    hl.exec_cmd("qs ipc -p ~/Projects/quickshell call shell " .. fn)
end

-- 1) Do-not-disturb, requested by more than one automation.
--    quickshell only exposes toggleDnd — there's no setDnd(bool) — so we track
--    who currently wants silence and whether WE were the one who turned it on,
--    and only send a toggle when that answer actually changes. A plain per-
--    automation boolean isn't enough: starting a recording mid-game would send a
--    second toggle and turn DND back OFF exactly when you wanted it most.
--    Assumption: DND is off when the first request arrives.
--    (A future setDnd(bool) IPC would make this exact.)
local dndWanted   = { share = false, game = false }
local dndHeldByUs = false

local function requestDnd(who, want)
    dndWanted[who] = want and true or false
    local anyone = dndWanted.share or dndWanted.game
    if anyone and not dndHeldByUs then
        dndHeldByUs = true
        qsRun("toggleDnd")
    elseif (not anyone) and dndHeldByUs then
        dndHeldByUs = false
        qsRun("toggleDnd")
    end
end

-- Auto-DND while screen-sharing / recording, restored afterward.
hl.on("screenshare.state", function(active)
    requestDnd("share", active)
end)

-- 2) Notify when a monitor is plugged in or unplugged.
hl.on("monitor.added", function(m)
    hl.exec_cmd("notify-send -a Hyprland 'Monitor connected' '" .. tostring(m.name) .. "'")
end)
hl.on("monitor.removed", function(m)
    hl.exec_cmd("notify-send -a Hyprland 'Monitor disconnected' '" .. tostring(m.name) .. "'")
end)

-- 3) Auto-place specific apps on a workspace when they open.
--    Keyed by window CLASS exactly as Hyprland reports it — find a window's
--    class with:  hyprctl clients | grep class
--    (Left empty so nothing moves unexpectedly; uncomment / add your own.)
local appWorkspace = {
    -- ["Spotify"]  = 9,
    -- ["discord"]  = 8,
    -- ["obsidian"] = 4,
}
hl.on("window.open", function(w)
    local ok, class = pcall(function() return w.class end)
    if not ok then return end
    local ws = appWorkspace[class]
    if ws then
        -- A newly opened window is the active one, so moving "active" moves it.
        hl.dispatch(hl.dsp.window.move({ workspace = ws }))
    end
end)

-- 4) Startup app layout: launch apps onto set workspaces at login.
--    The "[workspace N silent]" prefix places the window without switching to it.
--    (Empty by default so logins don't surprise-launch apps; add your own.)
local startupLayout = {
    -- { ws = 1, cmd = browser },
    -- { ws = 2, cmd = terminal },
    -- { ws = 4, cmd = editor },
}
hl.on("hyprland.start", function()
    for _, app in ipairs(startupLayout) do
        hl.exec_cmd("[workspace " .. app.ws .. " silent] " .. app.cmd)
    end
end)


-- 5) Automatic game mode.
--    While ANY game window is open: no gaps, borders, rounding, blur, shadows,
--    inactive-dimming or animations, and notifications are silenced. All of it
--    comes back when the last game window closes. Nothing to press — this is
--    Zen mode (SUPER+Z) applying itself, plus the per-frame effects.
--
--    These are LUA patterns (%d), not the regex the game-tearing window rule
--    uses ([0-9]). Add a game in both places or it gets one half of the
--    treatment: find its class with `hyprctl clients | grep class`.
local gameClasses = {
    "^steam_app_%d+$",   -- every Steam title launches under this class
    "^gamescope$",
}

local function isGame(class)
    if type(class) ~= "string" then return false end
    for _, pattern in ipairs(gameClasses) do
        if class:match(pattern) then return true end
    end
    return false
end

-- Proton titles sometimes report an empty class before settling, so fall back to
-- the class the window was mapped with.
local function windowClass(w)
    local ok, class = pcall(function() return w.class end)
    if ok and type(class) == "string" and class ~= "" then return class end
    local initialOk, initial = pcall(function() return w.initial_class end)
    if initialOk then return initial end
    return nil
end

-- Open game windows keyed by stable_id, so a window counted once stays counted
-- once — both window.close and window.destroy fire for a closing window, and a
-- plain counter would decrement twice and drop out of game mode with a second
-- game still running.
local openGames = {}

local function applyGameMode()
    local on = next(openGames) ~= nil
    if on == mode.game then return end   -- unchanged; don't churn the config
    mode.game = on
    applyLook()
    requestDnd("game", on)
end

-- Rebuild from live compositor state — authoritative, and self-healing if an
-- event is ever missed.
local function rescanGames()
    openGames = {}
    for _, w in ipairs(hl.get_windows()) do
        local idOk, id = pcall(function() return w.stable_id end)
        if idOk and id and isGame(windowClass(w)) then
            openGames[id] = true
        end
    end
end

hl.on("window.open", function()
    rescanGames()
    applyGameMode()
end)

-- On the way out, rescan first (the closing window may still be listed), then
-- drop it explicitly. Removal is idempotent, so the second event is harmless.
local function onWindowGone(w)
    rescanGames()
    local idOk, id = pcall(function() return w.stable_id end)
    if idOk and id then openGames[id] = nil end
    applyGameMode()
end

hl.on("window.close",   onWindowGone)
hl.on("window.destroy", onWindowGone)


-------------------
---- POWER KEYS ----
-------------------
-- Lua-function keybinds: arbitrary logic runs on the keypress (not a fixed
-- dispatcher). These use the helpers defined near the top of the file.
bind(mod .. " + O", function() throwToOtherMonitor() end, "[Windows] Throw to other monitor")
bind(mod .. " + Z", function() toggleZen() end,           "[Windows] Zen mode toggle")
