//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_AdventCOIN.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_AdventCOIN extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
  `log("AdventCOIN :: PresentAndCorrect");

  class'AdventCOIN_ScrubMissionManager'.static.ScrubInclusionExclusionLists();
  class'AdventCOIN_ScrubMissionManager'.static.ReplaceConfigurableEncounterSpawns();
}
