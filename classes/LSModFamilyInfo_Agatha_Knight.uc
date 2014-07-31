class LSModFamilyInfo_Agatha_Knight extends AOCFamilyInfo_Agatha_Knight;
	
var float MaxFallSpeed;



DefaultProperties
{


	NewPrimaryWeapons.Empty;
	NewPrimaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewSecondaryWeapons.Empty;
	NewSecondaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewSecondaryWeapons(0)=(CWeapon=class'LSModWeapon_1HLSMod',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewTertiaryWeapons.Empty;	
	NewTertiaryWeapons(0)=(CWeapon=class'LSModWeapon_ThrowingAxe',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewTertiaryWeapons(1)=(CWeapon=class'LSModWeapon_ThrowingMAUL',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	
	MaxFallSpeed = 1400.0
}