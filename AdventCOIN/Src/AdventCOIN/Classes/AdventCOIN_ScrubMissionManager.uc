class AdventCOIN_ScrubMissionManager extends Object config(AdventCOIN);

struct AdventCOIN_InclusionPatch
{
  var name ListID;
  var array<name> TemplateName;
};

struct AdventCOIN_Replacement
{
  var name TemplateName;
  var array<name> ReplaceWith;
};

var config array<name> TemplateNamesToRemove;
var config array<AdventCOIN_InclusionPatch> InclusionExclusionPatches;
var config array<AdventCOIN_Replacement> AdventReplacements;


static function ScrubInclusionExclusionLists ()
{
  local InclusionExclusionList IEList;
  local AdventCOIN_InclusionPatch Patch;
  local XComTacticalMissionManager MissionManager;
  local int Ix, WalkIx, PatchIx;

  MissionManager = `TACTICALMISSIONMGR;

  foreach MissionManager.InclusionExclusionLists(IEList, Ix)
  {
    `log("ADVENTCOIN :: Scrubbing List - " @ IEList.ListID);
    for (WalkIx = IEList.TemplateName.Length - 1; WalkIx > -1; WalkIx--)
    {
      if (default.TemplateNamesToRemove.Find(IEList.TemplateName[WalkIx]) != INDEX_NONE)
      {
        `log("- removing" @ IEList.TemplateName[WalkIx]);
        MissionManager.InclusionExclusionLists[Ix].TemplateName.Remove(WalkIx, 1);
      }
    }

    PatchIx = default.InclusionExclusionPatches.Find('ListID', IEList.ListID);

    if (PatchIx != INDEX_NONE)
    {
      Patch = default.InclusionExclusionPatches[PatchIx];

      for (WalkIx = 0; WalkIx < Patch.TemplateName.Length; WalkIx++)
      {
        `log("- patching with" @ Patch.TemplateName[WalkIx]);
        MissionManager.InclusionExclusionLists[Ix].TemplateName.AddItem(Patch.TemplateName[WalkIx]);
      }
    }
  }
}

static function ReplaceConfigurableEncounterSpawns ()
{
  local ConfigurableEncounter Encounter;
  local AdventCOIN_Replacement Replacement;
  local XComTacticalMissionManager MissionManager;
  local int Ix, WalkIx, ReplacementIx;
  local name OrigName, NewName;

  MissionManager = `TACTICALMISSIONMGR;

  `log("ADVENTCOIN :: Reworking ConfigurableEncounters");
  foreach MissionManager.ConfigurableEncounters(Encounter, Ix)
  {
    for (WalkIx = Encounter.ForceSpawnTemplateNames.Length - 1; WalkIx > -1; WalkIx--)
    {
      OrigName = Encounter.ForceSpawnTemplateNames[WalkIx];
      ReplacementIx = default.AdventReplacements.Find('TemplateName', OrigName);

      if (ReplacementIx != INDEX_NONE)
      {
        Replacement = default.AdventReplacements[ReplacementIx];
        NewName = Replacement.ReplaceWith[Rand(Replacement.ReplaceWith.Length)];

        `log("- " @ Encounter.EncounterID @ ": replacing" @ OrigName @ "with" @ NewName);
        MissionManager.ConfigurableEncounters[Ix].ForceSpawnTemplateNames[WalkIx] = NewName;
      }
    }
  }
}
