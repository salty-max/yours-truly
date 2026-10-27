-- The Letters tab: every letter delivered to this character, newest first,
-- each row its seal (the logo's red wax until it is broken, then the game's
-- open letter), its writer, its place and
-- its first line; the page the letter itself (the kit's voice, signed, its
-- P.S. under the name), then the chain it answers, when it came, and its zone's
-- count ("Westfall: 1 of 2"). A letter delivered and left sealed (the mailbox
-- closed on it) waits here for its seal to be broken. Letters still in the
-- post are never shown: they arrive at a mailbox, unannounced.
local _, ns = ...
local L, ui = ns.kit.L, ns.ui
local T = ui.T
local book, list, page
local current
local rows = {}
ns.letterRows = rows -- (for the tests)

local function style(row, kind)
  if kind == "letter" then
    row.text:ClearAllPoints()
    row.text:SetPoint("TOPLEFT", 4, -3)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetFont(ns.kit.BODY_FONT, 13, "")
    row.text:SetTextColor(unpack(T.text))
    row.count:ClearAllPoints()
    row.count:SetPoint("TOPLEFT", 22, -20)
    row.count:SetPoint("RIGHT", -4, 0)
    row.count:SetJustifyH("LEFT")
    row.count:SetFont(ns.kit.BODY_FONT, 10, "")
    row.count:SetTextColor(unpack(T.soft))
    if not row.line then
      row.line = ns.kit.label(row, ns.kit.BODY_FONT, 10, T.soft)
      row.line:SetWordWrap(false)
    end
    row.line:ClearAllPoints()
    row.line:SetPoint("TOPLEFT", 22, -33)
    row.line:SetPoint("RIGHT", -4, 0)
    row.line:Show()
    return 48
  end
  if row.line then row.line:Hide() end
  return ns.kit.listStyle(row, kind)
end

local function seal(id)
  local r = ns.record(id)
  return r and r.read and ns.ICON_READ or ns.SEAL
end
local function firstLine(id)
  local r = ns.record(id)
  if not (r and r.read) then return L["Sealed"] end
  local t = ns.letter(id)
  return t and t.body[1] or ""
end

local function refreshList(received)
  local q = ui.query()
  list:begin()
  local shown = 0
  for _, id in ipairs(received) do
    local name, place = ns.writer(id), ns.place(id)
    if ns.kit.finds(name, q) or ns.kit.finds(place, q) then
      local row = list:add("letter", ("|T%s:16:16:0:0|t %s"):format(seal(id), name), place)
      row.line:SetText(firstLine(id))
      row:SetScript("OnClick", function()
        current = id
        ns.refresh()
      end)
      if current == id then list:pick(row) end
      shown = shown + 1
    end
  end
  if shown == 0 then list:add("note", #received == 0 and L["No letter yet."] or L["No letter matches."]) end
  list:finish()
end

local function showLetter(id)
  local r = ns.record(id)
  page:start(ns.writer(id), ns.place(id), function(p) p.tex:SetTexture(seal(id)) end)
  if not r.read then
    page:paragraph(L["The seal is unbroken."], T.soft)
    page:buttons({
      {
        L["Break the seal"],
        function()
          if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
          ns.read(id)
          ns.refresh()
        end,
      },
    })
  else
    local t = ns.letter(id)
    if t then
      local paragraphs = { { t.greeting .. "\n\n" .. table.concat(t.body, "\n\n"), voice = true, sign = t.signoff } }
      if #t.ps > 0 then table.insert(paragraphs, table.concat(t.ps, "\n\n")) end
      page:text(paragraphs)
    end
  end
  page:row(L["In reply to"], ns.chain(id))
  page:row(L["Received"], ui.day(r.delivered))
  page:row(L["The zone"], ns.zoneLine(id))
end

local function showNone()
  page:start(L["Letters"], "", function(p) p.tex:SetTexture(ns.ICON) end)
  page:paragraph(
    L["When you finish a quest chain that changed someone's life, they may write to you. Their letter waits at the next mailbox you open."],
    T.soft
  )
end

local function refresh()
  local received = ns.received()
  book.count:SetText(ns.kit.plural(#received, "%d letter received", "%d letters received"):format(#received))
  if current and not (ns.record(current) and ns.record(current).delivered) then current = nil end
  current = current or received[1]
  refreshList(received)
  if current then
    showLetter(current)
  else
    showNone()
  end
  page:finish()
end

ns.addTab(ns.TAB.letters, {
  build = function(b)
    book = b
    list = ui.newList(book.left, style, rows, true)
    page = ui.newPage(book.sheet, "YoursTrulyLetterPage")
  end,
  show = function(n)
    local here = n == ns.TAB.letters
    list:SetShown(here)
    page:SetShown(here)
  end,
  refresh = refresh,
})

-- A letter in the book (none: the newest).
function ns.openLetter(id)
  current = id
  ns.openTab(ns.TAB.letters)
end
