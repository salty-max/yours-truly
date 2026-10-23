-- The achievements ("achievements" to the player, as the family's other
-- books): light, on the letters read. Counts (the first seal broken, five,
-- ten, twenty-five, every letter this character can receive), places
-- (letters from eight zones, from every starting zone that writes to this
-- character, from each of its side's three capitals), and writers: every
-- neutral one's, and a few writers' own, named for their letter (Nathanos
-- Blightcaller's Hate Mail, Gazlowe's Still Owed...). One the letters don't
-- reach yet (as twenty-five and the capitals were, before the first wave's
-- last letters) stays unlisted until a wave brings it. Each character earns its
-- own, and each remembers when and at what level:
--   YoursTrulyChar.milestones[id] = { at, level, retro }
-- Earned as the game's own achievements are: its fanfare, a banner among its
-- alerts (the kit's), a line in chat. Those already deserved when the book
-- first looks (the login) are recorded quietly. One a character can't earn
-- (another side's writer, a game without the letter) isn't listed.
local _, ns = ...
local K, L, D = ns.kit, ns.kit.L, ns.data

local list = {}
ns.milestones = list
ns.milestoneById = {}
local function add(group, id, title, text, progress, visible)
  local m = { group = group, id = id, title = title, text = text, progress = progress, visible = visible }
  table.insert(list, m)
  ns.milestoneById[id] = m
end

local function read(id)
  local r = ns.record(id)
  return r and r.read and 1 or 0
end
-- (the letters this character may receive, those of no side's)
local function count(which)
  local done, all = 0, 0
  for _, id in ipairs(ns.letters()) do
    if not which or which(id) then
      all = all + 1
      done = done + read(id)
    end
  end
  return done, all
end
local function neutral(id) return D.letters[id].side == "N" end
-- The zones (the count's: the place's top area) among those letters that
-- `which` keeps: how many in all, how many with a letter read.
local function zones(which)
  local all, done = {}, {}
  for _, id in ipairs(ns.letters()) do
    local z = D.letters[id].zone
    if not which or which(z) then
      all[z] = true
      if read(id) == 1 then done[z] = true end
    end
  end
  local n, d = 0, 0
  for z in pairs(all) do
    n = n + 1
    if done[z] then d = d + 1 end
  end
  return d, n
end
-- The starting zones (Elwynn Forest, Dun Morogh, Teldrassil, Durotar,
-- Mulgore, Tirisfal Glades, Forever's Zephras Isle), and each side's
-- capitals (Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff,
-- the Undercity), by area id.
local STARTING = { [12] = true, [1] = true, [141] = true, [14] = true, [215] = true, [85] = true, [16593] = true }
local CAPITALS =
  { A = { [1519] = true, [1537] = true, [1657] = true }, H = { [1637] = true, [1638] = true, [1497] = true } }
local function starting(z) return STARTING[z] end
local function capital(z) return CAPITALS[ns.side()][z] end
-- (npc: a writer's id, or several: the first of them this character can hear from)
local function writerLetter(npc)
  for _, id in ipairs(ns.letters()) do
    local w = D.letters[id].npc
    if w == npc then return id end
    if type(npc) == "table" then
      for _, n in ipairs(npc) do
        if n == w then return id end
      end
    end
  end
end

-- ── the letters read ─────────────────────────────────────────────────────────
add(
  "letters",
  "first-seal",
  L["The First Seal"],
  L["Break the seal of your first letter."],
  function() return math.min(ns.readCount(), 1), 1 end
)
add(
  "letters",
  "five",
  L["A Full Satchel"],
  L["Read five letters."],
  function() return math.min(ns.readCount(), 5), 5 end,
  function() return #ns.letters() >= 5 end
)
for _, n in ipairs({
  { "ten", 10, L["A Bundle of Letters"], L["Read ten letters."] },
  { "twenty-five", 25, L["A Drawer Full"], L["Read twenty-five letters."] },
}) do
  add(
    "letters",
    n[1],
    n[3],
    n[4],
    function() return math.min(ns.readCount(), n[2]), n[2] end,
    function() return #ns.letters() >= n[2] end
  )
end
add("letters", "every", L["Every Last One"], L["Read every letter you can receive."], function() return count() end)

-- ── the places ───────────────────────────────────────────────────────────────
local FAR = 8
add("places", "far-and-wide", L["Far and Wide"], L["Read letters from eight different zones."], function()
  local done = zones()
  return math.min(done, FAR), FAR
end, function()
  local _, all = zones()
  return all >= FAR
end)
add(
  "places",
  "where-it-began",
  L["Where It All Began"],
  L["Read a letter from every starting zone that writes to you."],
  function() return zones(starting) end,
  function()
    local _, all = zones(starting)
    return all > 1
  end
)
add(
  "places",
  "capitals",
  L["Letters from the Capitals"],
  L["Read a letter from each of your side's three capitals."],
  function()
    local done = zones(capital)
    return done, 3
  end,
  function()
    local _, all = zones(capital)
    return all >= 3
  end
)

-- ── the writers ──────────────────────────────────────────────────────────────
add(
  "writers",
  "neutral",
  L["Neutral Ground"],
  L["Read a letter from every writer who takes no side."],
  function() return count(neutral) end,
  function()
    local _, all = count(neutral)
    return all > 1
  end
)
-- (each where its writer's letter reaches: Nathanos, Neeru and Samsa write
-- to the Horde, Hinderweir, Remtravel and Gaxim to the Alliance, Gazlowe to
-- both, and Janice Felstone's parcel to each side its own: Ol' Emma's letter
-- to the Alliance, Jeremiah Payson's to the Horde)
for _, w in ipairs({
  { "hate-mail", 11878, L["Hate Mail"] }, -- (Nathanos Blightcaller)
  { "still-owed", 3391, L["Still Owed"] }, -- (Gazlowe)
  { "still-standing", 1093, L["Still Standing"] }, -- (Chief Engineer Hinderweir VII)
  { "brush", 2917, L["Where Is My Brush?"] }, -- (Prospector Remtravel)
  { "handle-with-care", 4077, L["Handle with Care"] }, -- (Gaxim Rustfizzle)
  { "double-agent", 3216, L["Double Agent"] }, -- (Neeru Fireblade)
  { "precious-skulls", 2418, L["Precious Skulls"] }, -- (Deathguard Samsa)
  { "better-late", { 3520, 8403 }, L["Better Late Than Never"] }, -- (the Felstone parcel: Ol' Emma, Jeremiah Payson)
}) do
  add("writers", w[1], w[3], function()
    local id = writerLetter(w[2])
    return L["Read %s's letter."]:format(id and ns.writer(id) or "")
  end, function()
    local id = writerLetter(w[2])
    return id and read(id) or 0, 1
  end, function() return writerLetter(w[2]) ~= nil end)
end

-- ── earning ──────────────────────────────────────────────────────────────────
function ns.earnedMilestone(id)
  local c = ns.book()
  return c and c.milestones and c.milestones[id]
end
-- Listed: earned, or one this character can earn.
function ns.milestoneVisible(m) return ns.earnedMilestone(m.id) ~= nil or not m.visible or m.visible() end
-- An achievement's line, as this reader's book words it.
function ns.milestoneText(m) return type(m.text) == "function" and m.text() or m.text end
-- Earned, and listed.
function ns.milestoneCount()
  local n, shown = 0, 0
  for _, m in ipairs(list) do
    if ns.earnedMilestone(m.id) then n = n + 1 end
    if ns.milestoneVisible(m) then shown = shown + 1 end
  end
  return n, shown
end

-- The fanfare of the game's achievements (a client without it: none).
local FANFARE = 12891
local function fanfare() pcall(PlaySound, FANFARE, "Master") end

local GROUP_ICONS = {
  letters = "Interface\\Icons\\INV_Letter_03",
  places = "Interface\\Icons\\INV_Misc_Map_01",
  writers = "Interface\\Icons\\INV_Letter_09",
}
ns.milestoneIcons = GROUP_ICONS

local banners
local function announce(m)
  print(ns.PREFIX .. L["Achievement earned: %s."]:format("|cffffd100[" .. m.title .. "]|r"))
  fanfare()
  banners = banners or K.banners({ name = "YoursTrulyBanner", art = ns.ICON })
  banners:show({
    picture = K.icon(GROUP_ICONS[m.group] or ns.ICON),
    kicker = L["Yours Truly achievement"],
    title = m.title,
    tip = ns.milestoneText(m),
    click = function()
      if ns.openMilestones then ns.openMilestones(m.id) end
    end,
  })
end

-- quiet: record without a word (reached before the book looked: the login).
function ns.checkMilestones(quiet)
  local c = ns.book()
  if not c then return end
  c.milestones = c.milestones or {}
  local earned = false
  for _, m in ipairs(list) do
    if not c.milestones[m.id] and ns.milestoneVisible(m) then
      local done, need = m.progress()
      if need > 0 and done >= need then
        c.milestones[m.id] = { at = time(), level = UnitLevel("player"), retro = quiet or nil }
        earned = true
        if not quiet then announce(m) end
      end
    end
  end
  if earned and ns.onChange then ns.onChange() end
  return earned
end
