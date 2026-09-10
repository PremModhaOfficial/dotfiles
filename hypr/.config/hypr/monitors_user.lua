-- monitors_user.lua: HDR10 toggle for the internal Samsung OLED (eDP-1).
--
-- The EDID advertises SMPTE ST2084 (HDR10), 616-nit peak, 0.005-nit black and
-- BT.2020 colorimetry. Hyprland leaves all of that dormant until a monitor's
-- cm is switched to "hdredid", so this file is the on/off switch: it reads
-- "hdrMode" from ~/.config/ryoku/shell.json (the same flat-JSON pattern
-- decoration.lua uses for screenShader and lowPowerMode) and only re-speaks
-- eDP-1 when the flag is true. The paired keybind flips hdrMode and screenShader
-- together -- HDR on means the IMAX grade gets out of the way, because the real
-- thing replaces the emulation.
--
-- sdrbrightness/sdrsaturation shape how normal SDR apps look while the output
-- is in PQ: 2.0 restores roughly the SDR white level, 1.1 keeps SDR colors from
-- reading flat. Tune to taste; they only apply inside HDR mode.
--
-- HDR10+ (per-scene dynamic metadata) is not advertised by the panel's EDID and
-- no Linux compositor consumes it yet -- what you get is HDR10 baseline, which
-- is the real thing.

local home = os.getenv("HOME")

local function shell_flag(key)
  local f = io.open(home .. "/.config/ryoku/shell.json", "r")
  if not f then return false end
  local s = f:read("*a")
  f:close()
  return s:match('"' .. key .. '"%s*:%s*true') ~= nil
end

if shell_flag("hdrMode") then
  hl.monitor({
    output        = "eDP-1",
    mode          = "1920x1080@60.00",
    position      = "0x0",
    scale         = 1,
    cm            = "hdredid",
    bitdepth      = 10,
    sdrbrightness = 2.0,
    sdrsaturation = 1.1,
  })
end
