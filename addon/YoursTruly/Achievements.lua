-- The achievements ("achievements" to the player, as the family's other
-- books): a few, light, on the letters read. The first seal broken, five
-- letters, every letter this character's side can receive, every neutral
-- writer's, and two writers' own: Nathanos Blightcaller's (Hate Mail) and
-- Gazlowe's (Still Owed). Each character earns its own, and each remembers
-- when and at what level:
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
local function writerLetter(npc)
  for _, id in ipairs(ns.letters()) do
    if D.letters[id].npc == npc then return id end
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
add("letters", "every", L["Every Last One"], L["Read every letter you can receive."], function() return count() end)

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
local NATHANOS, GAZLOWE = 11878, 3391
for _, w in ipairs({
  { "hate-mail", NATHANOS, L["Hate Mail"] },
  { "still-owed", GAZLOWE, L["Still Owed"] },
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
