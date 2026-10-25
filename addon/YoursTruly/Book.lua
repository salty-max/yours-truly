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
local book
local TAB = { letters = 1, milestones = 2 }
ns.TAB = TAB
local tabs, TITLES = {}, { L["Letters"], L["Achievements"] }
function ns.addTab(n, tab) tabs[n] = tab end

function ns.refresh()
  local tab = book and tabs[book.selectedTab]
  if tab and tab.built then tab.refresh() end
end

function ns.showTab(n)
  if not book then return end
  book.selectedTab = n
  if PanelTemplates_SetTab then PanelTemplates_SetTab(book, n) end
  local tab = tabs[n]
  if not tab.built then
    tab.build(book)
    tab.built = true
  end
  -- (a tab over both panels, the achievements' board: the list, the sheet and
  -- the search put away)
  book.left:SetShown(not tab.whole)
  book.sheet:SetShown(not tab.whole)
  book.search:SetShown(not tab.whole)
  for _, t in ipairs(tabs) do
    if t.built then t.show(n) end
  end
  ns.refresh()
end

local function build()
  local window = K.gameWindow("YoursTrulyFrame", "Yours Truly", ns.ICON)
  book = window or K.dialog("YoursTrulyFrame", "Yours Truly")
  K.movable(book, 780, 560)
  local edge = window and 8 or 14
  book.count = K.label(book, K.BODY_FONT, 11, T.gold)
  book.count:SetPoint("TOPLEFT", 64, -36)
  book.left = K.panel(book, true)
  book.left:SetPoint("TOPLEFT", edge, -58)
  book.left:SetPoint("BOTTOMLEFT", edge, edge)
  book.left:SetWidth(244)
  book.sheet = K.panel(book)
  book.sheet:SetPoint("TOPLEFT", book.left, "TOPRIGHT", 4, 32)
  book.sheet:SetPoint("BOTTOMRIGHT", -edge, edge)
  book.search = CreateFrame("EditBox", "YoursTrulySearch", book, "SearchBoxTemplate")
  book.search:SetHeight(20)
  book.search:SetPoint("TOPLEFT", book.left, "TOPLEFT", 18, -10)
  book.search:SetPoint("TOPRIGHT", book.left, "TOPRIGHT", -12, -10)
  book.search:HookScript("OnTextChanged", function() ns.refresh() end)
  book.selectedTab = TAB.letters
  book:SetScript("OnShow", function() ns.showTab(book.selectedTab) end)
  K.tabs(book, TITLES, function(n) ns.showTab(n) end)
end

local function window()
  if not book then build() end
  return book
end

function ns.toggle() window():SetShown(not book:IsShown()) end

function ns.openTab(n)
  window()
  book.selectedTab = n
  if book:IsShown() then
    ns.showTab(n)
  else
    book:Show()
  end
end

-- What changes while the book is open shows at once (a moment later: a
-- mailbox's letters come together).
local pending = false
ns.onChange = function()
  if not (book and book:IsShown()) or pending then return end
  pending = true
  C_Timer.After(0.3, function()
    pending = false
    ns.refresh()
  end)
end

-- ── the parts every tab is made of ───────────────────────────────────────────
local function query() return ns.kit.query(book.search) end

ns.ui = {
  T = T,
  query = query,
  day = K.day,
  icon = K.icon,
  newList = K.list,
  newPage = function(parent, name) return K.page(parent, name, { labelWidth = 110, pairs = {} }) end,
}
