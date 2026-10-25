-- Yours Truly as a book: the family's window (portrait, title bar), its tabs
-- (Letters, Achievements: each a file of its own, *Book.lua, registered with
-- ns.addTab), and what every tab is made of (ns.ui): the kit's look in Yours
-- Truly's theme, its list on the left and page on the right. /yourstruly, the
-- minimap button and a letter's banner open it.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

-- ── look ─────────────────────────────────────────────────────────────────────
-- The kit's (Kit.lua), in Yours Truly's theme: the red of the wax on the
-- game's sealed letter, and a letter's ink the warm brown of its paper.
K.theme({
  accent = { 0.90, 0.60, 0.48 },
  ring = { 0.62, 0.32, 0.26 },
  bar = { 0.76, 0.34, 0.28 },
  aside = { 0.93, 0.85, 0.72 },
  tint = { 1.00, 0.95, 0.92 },
  shade = { 0.03, 0.015, 0.01, 0.55 },
  highlight = { 1.00, 0.86, 0.82 },
})
local T = K.T

-- ── the window ───────────────────────────────────────────────────────────────
-- The kit's book (K.book): the window, its two panels, the search, the tabs;
-- each tab a file of its own, registered with ns.addTab.
local TAB = { letters = 1, milestones = 2 }
ns.TAB = TAB
local B = K.book({
  name = "YoursTrulyFrame",
  title = "Yours Truly",
  art = ns.ICON,
  titles = { L["Letters"], L["Achievements"] },
  first = TAB.letters,
  search = "YoursTrulySearch",
  settle = 0.3,
})
ns.kitBook = B -- (for the tests)
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
