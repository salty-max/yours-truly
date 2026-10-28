-- The panel beside the mail window, the inbox's own look with our content in
-- it (28 October 2026, the user's call): the window's grey stone,
-- the kit's panel under the title, the inbox's parchment inside it (file
-- 530419, cropped to its paper; the reader's stationery, Interface\Stationery\
-- StationeryTest1 and 2, where the game has not that file), the game's text
-- face. Shown when a mailbox opens and a letter waits there for this character
-- (never empty), hidden when it closes.
--
-- The list, as the inbox lists mail: a row for each (the seal in a slot, the
-- writer, the place it was written), a page of seven, Prev and Next at the
-- foot with "Open all" between them (it breaks every seal at once). A click
-- on a row breaks that seal (the game's page sound) and the letter opens in
-- the panel, in the mail's own face (MailTextFontNormal, dark brown),
-- scrolling over the paper as the game's reader does, the chain it answers
-- and its zone's count under it; Back returns to the list. The panel is as
-- big as the mail window beside it (the longest letters scroll).
--
-- The backlog (letters earned before the addon, Core: ns.backlog) is in the
-- list too, all of it at the first mailbox: no bundle, rows and the one
-- button (the user's call, 28 October 2026). Fresh letters wait for the next
-- mailbox.
--
-- Docked to the mail window: beside the open letter (OpenMailFrame) when one
-- is open, else where that would stand (beside the inbox). A mailbox addon
-- that hides the game's mail window: the panel stands on its own instead,
-- movable, where the player last left it. No other addon's code is touched.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local W, H = 384, 512 -- (the mail window's own size, read again when the panel is built)
local PAPER = { "Interface\\Stationery\\StationeryTest1", "Interface\\Stationery\\StationeryTest2" }
local PARCHMENT = 530419 -- (the inbox's list paper)
local INK = { 0.18, 0.12, 0.06 }
local FADED = { 0.40, 0.30, 0.20 }
local MARGIN = 8 -- (the window's frame, as the kit's panels stand in it)
local EDGE = MARGIN + 3 -- (and the panel's own border)
local SHEET_W, TEXT_W
local BAR = 36 -- (the sheet's foot: a button, a line, over the paper)

local panel, current, page = nil, nil, 1
local ROW_H, PER = 44, 7
ns.panelParts = {} -- (for the tests)

-- What the panel holds: each letter waiting at the mailbox.
local queue = ns.waiting

-- The mail's own face for a letter's words where the client has it, else the books'
-- display face; plain: the game's own text face, as the inbox's words are.
local function ink(parent, size, colour, plain)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  if size == 15 and MailTextFontNormal and not plain then
    fs:SetFontObject(MailTextFontNormal)
  else
    fs:SetFont(plain and K.BODY_FONT or K.TITLE_FONT, size, "")
  end
  fs:SetTextColor(unpack(colour or INK))
  fs:SetShadowOffset(0, 0)
  fs:SetJustifyH("LEFT")
  fs:SetSpacing(3)
  return fs
end

-- The window's title: the addon's name over the list, "A letter" over a letter.
local function title(text)
  if panel.SetTitle then
    panel:SetTitle(text)
  elseif type(panel.TitleText) == "table" and panel.TitleText.SetText then
    panel.TitleText:SetText(text)
  end
end

-- ── where it stands ──────────────────────────────────────────────────────────
local function dock()
  panel:ClearAllPoints()
  -- (a mailbox addon may hide the game's window without closing it: parented
  -- to a hidden frame, or made transparent)
  if MailFrame and MailFrame:IsVisible() and (MailFrame:GetAlpha() or 1) > 0 then
    panel.docked = true
    local beside = (OpenMailFrame and OpenMailFrame:IsShown() and OpenMailFrame) or InboxFrame or MailFrame
    -- (the old art stops short of its frame's right edge: against the art)
    -- (the inbox's frame is the mail window's own, whole: its insets are MailFrame's)
    local src = beside == InboxFrame and MailFrame or beside
    local right = src.GetHitRectInsets and select(2, src:GetHitRectInsets()) or 0
    panel:SetPoint("TOPLEFT", beside, "TOPRIGHT", -(right or 0), 0)
  else
    panel.docked = false
    local x, y = ns.option("panelX"), ns.option("panelY")
    if x and y then
      panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
      panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
  end
end

-- ── the panel ────────────────────────────────────────────────────────────────
local show, list

local function build()
  -- as big as the mail window it stands beside
  if MailFrame and MailFrame.GetWidth and MailFrame:GetWidth() > 200 then
    W, H = MailFrame:GetWidth(), MailFrame:GetHeight()
    -- (the old art doesn't fill the frame: its hit rect is the window you see)
    if MailFrame.GetHitRectInsets then
      local l, r, t, b = MailFrame:GetHitRectInsets()
      W, H = W - (l or 0) - (r or 0), H - (t or 0) - (b or 0)
    end
    W, H = math.floor(W + 0.5), math.floor(H + 0.5)
  end
  SHEET_W = W - 2 * EDGE
  PER = math.min(7, math.max(1, math.floor((H - 58 - MARGIN - 6 - BAR - 8) / ROW_H)))
  TEXT_W = SHEET_W - 18 - 44
  local window = K.gameWindow("YoursTrulyPanel", L["A letter"], ns.ICON)
  panel = window or K.dialog("YoursTrulyPanel", L["A letter"])
  -- the body the mail window's own grey stone (the kit darkens it: the inbox
  -- beside is not dark), read off the game's window where it can be
  if window and type(window.Bg) == "table" and window.Bg.SetTexture then
    local mail = MailFrame and type(MailFrame.Bg) == "table" and MailFrame.Bg
    local atlas = mail and mail.GetAtlas and mail:GetAtlas()
    local stone = mail and mail.GetTexture and mail:GetTexture()
    if atlas and window.Bg.SetAtlas then
      window.Bg:SetAtlas(atlas)
    else
      window.Bg:SetTexture(stone or "Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
    end
  end
  panel:SetSize(W, H)
  panel:SetToplevel(true)
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self)
    if not self.docked then self:StartMoving() end
  end)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not self.docked then
      ns.setOption("panelX", math.floor(self:GetLeft() + 0.5))
      ns.setOption("panelY", math.floor(self:GetTop() + 0.5))
    end
  end)
  table.insert(UISpecialFrames, "YoursTrulyPanel")
  panel:Hide()

  -- the paper, in the kit's panel as the mail window's own inbox has its list
  -- (dark window, the panel's border, the paper inside it)
  local frame = K.panel(panel)
  frame:SetPoint("TOPLEFT", MARGIN, -58)
  frame:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)
  local sheet = CreateFrame("Frame", nil, frame)
  sheet:SetPoint("TOPLEFT", 3, -3)
  sheet:SetPoint("BOTTOMRIGHT", -3, 3)
  -- the inbox's own parchment (a file of the game, 530419: the paper fills
  -- 320 by 356 of its 512 square, stretched over the box as the inbox does),
  -- the reader's stationery where the game's isn't that file
  local bg = InboxFrameBg
  local inbox = bg and ((bg.GetTextureFileID and bg:GetTextureFileID()) or (bg.GetTexture and bg:GetTexture()))
  if inbox == PARCHMENT then
    local art = sheet:CreateTexture(nil, "BACKGROUND")
    art:SetTexture(PARCHMENT)
    art:SetTexCoord(0, 320 / 512, 0, 356 / 512)
    art:SetAllPoints()
  else
    local left = sheet:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(PAPER[1])
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(math.floor(SHEET_W * 252 / 302 + 0.5))
    local right = sheet:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(PAPER[2])
    right:SetTexCoord(0, 50 / 64, 0, 1)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
  end

  -- the letter, scrolling over it
  local scroll = K.scrollArea(sheet, TEXT_W, "YoursTrulyPanelScroll")
  scroll:SetPoint("TOPLEFT", 18, -14)
  scroll:SetPoint("BOTTOMRIGHT", -44, BAR + 4)
  scroll.thumb:SetColorTexture(INK[1], INK[2], INK[3], 0.35)
  local c = scroll.child
  local place = ink(c, 15)
  place:SetWidth(TEXT_W)
  place:SetJustifyH("RIGHT")
  local main = ink(c, 15)
  main:SetWidth(TEXT_W)
  local signoff = ink(c, 15)
  signoff:SetWidth(TEXT_W)
  signoff:SetJustifyH("RIGHT")
  local ps = ink(c, 15)
  ps:SetWidth(TEXT_W)
  local footer = ink(c, 11, FADED, true)
  footer:SetWidth(TEXT_W)

  -- the list, as the inbox has it: a row for each, a page of them, a pager
  -- and the button to open all at its foot
  local rows = {}
  for i = 1, PER do
    local row = CreateFrame("Button", nil, sheet)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 8, -(8 + (i - 1) * ROW_H))
    row:SetPoint("TOPRIGHT", -8, -(8 + (i - 1) * ROW_H))
    local light = row:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(1, 1, 1, 0.12)
    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(INK[1], INK[2], INK[3], 0.3)
    -- (the inbox's own slot where the game names it: its empty slot, 64 wide
    -- on a button of 37, gold as an unread one is; else a flat brown square)
    local slot = row:CreateTexture(nil, "BORDER")
    local own = MailItem1ButtonSlot and MailItem1ButtonSlot.GetTexture and MailItem1ButtonSlot:GetTexture()
    if own then
      slot:SetTexture(own)
      slot:SetSize(62, 62)
      slot:SetVertexColor(1, 0.82, 0)
    else
      slot:SetColorTexture(0.28, 0.13, 0.03, 0.9)
      slot:SetSize(36, 36)
    end
    slot:SetPoint("CENTER", row, "LEFT", 20, 0)
    local seal = row:CreateTexture(nil, "ARTWORK")
    seal:SetTexture(ns.SEAL)
    seal:SetSize(30, 30)
    seal:SetPoint("CENTER", row, "LEFT", 20, 0)
    row.name = ink(row, 14, nil, true)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 48, -5)
    row.name:SetWidth(SHEET_W - 90)
    row.sub = ink(row, 11, FADED, true)
    row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.sub:SetWidth(SHEET_W - 90)
    row.name:SetMaxLines(1)
    row.sub:SetMaxLines(1)
    row:SetScript("OnClick", function(self)
      if self.id then ns.openInPanel(self.id) end
    end)
    row:Hide()
    rows[i] = row
  end

  local GOLD = { 1, 0.82, 0 }
  local function arrow(text, art, side)
    local b = CreateFrame("Button", nil, sheet)
    b:SetSize(28, 28)
    b:SetPoint("BOTTOM" .. side, side == "LEFT" and 10 or -10, 8)
    b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Down")
    b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local fs = ink(b, 13, GOLD, true)
    fs:SetShadowOffset(1, -1)
    fs:SetText(text)
    if side == "LEFT" then
      fs:SetPoint("LEFT", b, "RIGHT", 4, 0)
    else
      fs:SetPoint("RIGHT", b, "LEFT", -4, 0)
    end
    return b
  end
  local prev = arrow(L["Prev"], "PrevPage", "LEFT")
  local nextPage = arrow(L["Next"], "NextPage", "RIGHT")
  prev:SetScript("OnClick", function()
    page = page - 1
    list()
  end)
  nextPage:SetScript("OnClick", function()
    page = page + 1
    list()
  end)
  local openAll = K.button(sheet, L["Open all"], 110)
  openAll:SetPoint("BOTTOM", 0, 10)
  openAll:SetScript("OnClick", function()
    for _, id in ipairs(ns.waiting()) do
      ns.read(id)
    end
    list()
  end)
  -- the letter open: back to the list
  local back = K.button(sheet, L["Back"], 90)
  back:SetPoint("BOTTOMLEFT", 12, 10)
  back:SetScript("OnClick", function() list() end)
  back:Hide()

  -- (the mail window shown late, a letter opened beside it: the panel moves)
  for _, f in ipairs({ MailFrame, OpenMailFrame }) do
    if f and f.HookScript then
      f:HookScript("OnShow", function()
        if panel:IsShown() then dock() end
      end)
      f:HookScript("OnHide", function()
        if panel:IsShown() then dock() end
      end)
    end
  end

  local P = ns.panelParts
  P.panel, P.scroll, P.place, P.main, P.signoff, P.ps, P.footer = panel, scroll, place, main, signoff, ps, footer
  P.rows, P.prev, P.next, P.openAll, P.back = rows, prev, nextPage, openAll, back
  P.sheet, P.frame = sheet, frame
end

-- The list: each letter waiting, a page at a time.
-- Nothing left to list: the panel closes.
list = function()
  local P = ns.panelParts
  current = nil
  local q = queue()
  if #q == 0 then return panel:Hide() end
  local pages = math.ceil(#q / PER)
  page = math.max(1, math.min(page, pages))
  title("Yours Truly")
  P.scroll:Hide()
  P.back:Hide()
  for i, row in ipairs(P.rows) do
    local id = q[(page - 1) * PER + i]
    row.id = id
    row:SetShown(id ~= nil)
    if id then
      row.name:SetText(ns.writer(id))
      row.sub:SetText(ns.place(id))
    end
  end
  P.prev:SetShown(pages > 1)
  P.next:SetShown(pages > 1)
  P.prev:SetEnabled(page > 1)
  P.next:SetEnabled(page < pages)
  P.openAll:Show()
  P.openAll:SetEnabled(#ns.waiting() > 0)
end

-- A letter opened from its row: the seal broken (the game's page sound) and
-- its words in the panel.
function ns.openInPanel(id)
  if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
  ns.read(id)
  show(id)
end

-- A letter in the panel, its words.
show = function(id)
  local P = ns.panelParts
  current = id
  local y = 0
  local function lay(fs, text, gap)
    fs:ClearAllPoints()
    if not text or text == "" then
      fs:Hide()
      return
    end
    fs:SetText(text)
    fs:SetPoint("TOPLEFT", P.scroll.child, "TOPLEFT", 0, -y)
    fs:Show()
    y = y + fs:GetStringHeight() + gap
  end
  title(L["A letter"])
  for _, row in ipairs(P.rows) do
    row:Hide()
  end
  P.prev:Hide()
  P.next:Hide()
  P.openAll:Hide()
  P.back:Show()
  P.scroll:Show()
  local t = ns.letter(id)
  if not t then return end
  lay(P.place, ns.place(id), 14)
  lay(P.main, t.greeting .. "\n\n" .. table.concat(t.body, "\n\n"), 14)
  lay(P.signoff, t.signoff, 16)
  lay(P.ps, table.concat(t.ps, "\n\n"), 16)
  -- (either may be missing: a language without the quest's name, a zone's
  -- count before it has written)
  local under = {}
  for _, part in ipairs({ ns.chain(id) or false, ns.zoneLine(id) or false }) do
    if part then table.insert(under, part) end
  end
  lay(P.footer, table.concat(under, "  -  "), 4)
  P.scroll.child:SetHeight(y + 8)
  P.scroll:ScrollTo(0)
end

-- At a mailbox: the list of what waits there.
function ns.showPanel()
  local q = queue()
  if #q == 0 then return end
  if not panel then build() end
  dock()
  page = 1
  list()
  panel:Show()
end

function ns.hidePanel()
  if panel then panel:Hide() end
end

-- (the letter the panel shows: for the tests)
function ns.panelLetter() return panel and panel:IsShown() and (current or "list") or nil end
