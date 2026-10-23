-- The welcome (the kit's, Kit.lua): once per character, a few seconds after
-- its first login (out of combat; /yourstruly welcome shows it again), laid
-- out as the book's window: on the left what Yours Truly is; on the right this
-- character's choices (Settings.lua: the minimap button), then another
-- character's to take, chosen among this game's or brought by a code
-- (/yourstruly export there). Closing it, however, is enough to have seen it.
local _, ns = ...
local K = ns.kit
local L = K.L

local W = K.welcome({
  name = "YoursTrulyWelcome",
  title = L["Welcome to Yours Truly"],
  art = ns.ICON,
  logo = ns.ICON,
  heading = "Yours Truly",
  tagline = L["Letters from the people you helped."],
  intro = function()
    return L["Some quest chains change someone's life. When you finish one, the person it changed may write to you, in their own voice, about what happened and what came after."]
      .. "\n\n"
      .. L["Their letter waits at the next mailbox you open, sealed. Nothing tells you it is coming. Keep every letter in the book."]
  end,
  profiles = ns.profiles,
  choices = function()
    return {
      {
        text = L["The letters by the minimap"],
        hint = L["Click it to open the book, or drag it around the minimap."],
        get = function() return not ns.option("minimapHidden") end,
        set = function(v) ns.setOption("minimapHidden", not v) end,
      },
    }
  end,
  footnote = L["Change it any time: /yourstruly settings, or a right-click on the minimap button. /yourstruly opens the book."],
  open = { text = L["Open the book"], click = function() ns.toggle() end },
  exportHint = L["Copy it (Ctrl+C), then on another character: Use a code, or /yourstruly import CODE."],
  importHint = L["Paste the code (/yourstruly export on the other character), then press Enter."],
  refused = L["That isn't a Yours Truly settings code."],
})

ns.welcome = W -- (its frame, rows, picker and code: for the tests)
function ns.showWelcome(mode) W:Show(mode) end

K.welcomeOnce(W, ns.profiles, function() return ns.book() ~= nil end)
