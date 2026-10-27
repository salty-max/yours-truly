-- Yours Truly as a book: the family's window (portrait, title bar), its tabs
-- (Letters, Achievements: each a file of its own, *Book.lua, registered with
-- ns.addTab), and what every tab is made of (ns.ui): the kit's look in Yours
-- Truly's theme, its list on the left and page on the right. /yourstruly, the
-- minimap button and a letter's banner open it.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

-- ── look ─────────────────────────────────────────────────────────────────────
-- The kit's (Kit.lua), its theme (Yours Truly's: the wax's red) set first thing in Core.lua.
local T = K.T

-- ── the window ───────────────────────────────────────────────────────────────
-- The kit's book (K.book): the window, its two panels, the search, the tabs;
-- each tab a file of its own, registered with ns.addTab.
local TAB = { letters = 1, milestones = 2 }
ns.TAB = TAB
local B = K.book({
  name = "YoursTrulyFrame",
  title = "Yours Truly",
  -- (where it was left, kept with the account's settings)
  place = function()
    YoursTrulySettings = YoursTrulySettings or {}
    return K.place(YoursTrulySettings, "book")
  end,
  art = ns.ICON,
  titles = { L["Letters"], L["Achievements"] },
  first = TAB.letters,
  search = "YoursTrulySearch",
  settle = 0.3,
})
function ns.addTab(n, tab) B:add(n, tab) end
function ns.refresh() B:refresh() end
function ns.showTab(n) B:show(n) end
function ns.toggle() B:toggle() end
function ns.openTab(n) B:open(n) end

-- What changes while the book is open shows at once (a moment later: a
-- mailbox's letters come together).
ns.onChange = function() B:changed() end

-- ── the parts every tab is made of ───────────────────────────────────────────
local function query() return ns.kit.query(B.frame.search) end

ns.ui = {
  T = T,
  query = query,
  day = K.day,
  icon = K.icon,
  newList = K.list,
  newPage = function(parent, name) return K.page(parent, name, { labelWidth = 110, pairs = {} }) end,
}
