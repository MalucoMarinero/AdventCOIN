class AdventCOIN_ScrubMissionManager extends Object config(AdventCOIN);

struct AdventCOIN_AIJobInfo_Addition
{
	var name JobName;						// Name of this job.
	var name NewCharacterName;				// The name of the new character type being added
	var name BeforeUnit;					// Put the NewCharacter Before this unit, if possible
	var name AfterUnit;						// Put the NewCharacter After this unit, if possible
	var int DefaultPosition;				// Default index to insert at if cannot find based on name
};

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
var config array<AdventCOIN_AIJobInfo_Addition> JobListingAdditions; // Definition of qualifications for each job for this new character


static function UpdateAIJobs()
{
	local X2AIJobManager JobMgr;
	local X2CharacterTemplateManager CharacterMgr;
	local X2CharacterTemplate CharTemplate;
	local AdventCOIN_AIJobInfo_Addition Addition;
	local int AdditionIndex, JobIdx;
	local AIJobInfo JobInfo;
	local name MyName;

	//retrieve Managers
	JobMgr = `AIJOBMGR;
	CharacterMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	//for debugging, to verify that the AIJobManager is alive and has data
	foreach JobMgr.JobListings(JobInfo)
	{
	}

	foreach default.JobListingAdditions(Addition)
	{
		MyName = Addition.NewCharacterName;
		CharTemplate = CharacterMgr.FindCharacterTemplate(MyName);
		if(CharTemplate == none)
		{
			`REDSCREEN("UpdateAIJobs : Invalid character template = " $ MyName);
			continue;
		}

		//JobInfo = JobMgr.GetJobListing(Addition.JobName);
		JobIdx = JobMgr.JobListings.Find('JobName', Addition.JobName);

		if(JobMgr.JobListings[JobIdx].JobName == '') 
		{
			`REDSCREEN("UpdateAIJobs : Invalid job name = " $ Addition.JobName);
			continue;
		}		

		if(Addition.BeforeUnit != '')
		{
			AdditionIndex = JobMgr.JobListings[JobIdx].ValidChar.Find(Addition.BeforeUnit);
			if(AdditionIndex != INDEX_NONE)
			{
				JobMgr.JobListings[JobIdx].ValidChar.InsertItem(AdditionIndex, MyName);
				continue;
			}
		}

		if(Addition.AfterUnit != '')
		{
			AdditionIndex = JobMgr.JobListings[JobIdx].ValidChar.Find(Addition.AfterUnit);
			if(AdditionIndex != INDEX_NONE)
			{
				JobMgr.JobListings[JobIdx].ValidChar.InsertItem(AdditionIndex+1, MyName);
				continue;
			}
		}
		//default to default index value
		AdditionIndex = Addition.DefaultPosition;
		if(AdditionIndex >= JobMgr.JobListings[JobIdx].ValidChar.Length)
		{
			JobMgr.JobListings[JobIdx].ValidChar.AddItem(MyName);
		}
		else
		{
			AdditionIndex = Max(0, AdditionIndex);
			JobMgr.JobListings[JobIdx].ValidChar.InsertItem(AdditionIndex, MyName);
		}
	}
}


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
