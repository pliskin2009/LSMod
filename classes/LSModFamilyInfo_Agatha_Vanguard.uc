/**
* Copyright 2010-2013, Torn Banner Studios, All rights reserved
*
* Original Author: Michael Bao
*
* Agathian Vanguard
*/

class LSModFamilyInfo_Agatha_Vanguard extends AOCFamilyInfo_Agatha_Vanguard;
	



DefaultProperties
{
	NewPrimaryWeapons.Empty;
	NewPrimaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewSecondaryWeapons.Empty;
	NewSecondaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewSecondaryWeapons(0)=(CWeapon=class'LSModWeapon_1HLSMod',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewTertiaryWeapons.Empty;	
	NewTertiaryWeapons(0)=(CWeapon=class'LSModWeapon_ThrowingAxe')
	NewTertiaryWeapons(1)=(CWeapon=class'LSModWeapon_ThrowingKnife')
	NewTertiaryWeapons(2)=(CWeapon=class'AOCWeapon_SmokePot')
	

}
