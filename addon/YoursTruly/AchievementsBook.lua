-- The Achievements tab, over both panels: the kit's board (the figures on
-- top: all earned, and each group's; then one row per achievement under its
-- group's heading and how many of it are earned: its group's picture, its
-- ring gold once earned, the title, what it asks, when it was earned or how
-- far along it is). Achievements: Achievements.lua.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
ns.milestoneRows = {} -- (for the tests)

local GROUPS = {
  { "letters", L["Letters read"], ns.milestoneIcons.letters, "all" },
  { "places", L["Places"], ns.milestoneIcons.places, "all" },
  { "writers", L["Correspondents"], ns.milestoneIcons.writers, "all" },
}

-- (the kit's tab: K.deedsTab, its board over both panels and the count)
local tab = K.deedsTab(
  ns.deeds,
  { name = "YoursTrulyMilestones", groups = GROUPS, rows = ns.milestoneRows, n = ns.TAB.milestones }
)
ns.addTab(ns.TAB.milestones, tab.tab)

-- Open the book at the achievements, one of them picked out.
function ns.openMilestones(id)
  tab:pick(id)
  ns.openTab(ns.TAB.milestones)
end
