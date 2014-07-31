class LSModFamilyInfo_Agatha_Archer extends AOCFamilyInfo_Agatha_Archer;
	
var float MaxFallSpeed;


DefaultProperties
{
	fBackstabModifier=1.0

	NewPrimaryWeapons.Empty;
	NewPrimaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewPrimaryWeapons(0)=(CWeapon=class'LSModWeapon_Crossbow2',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewSecondaryWeapons.Empty;
	NewSecondaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewSecondaryWeapons(0)=(CWeapon=class'LSModWeapon_1HLSMod_SMALL',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewTertiaryWeapons.Empty;
	NewTertiaryWeapons(0)=(CWeapon=class'LSModWeapon_Grenade',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	
	MaxFallSpeed = 805.0
}