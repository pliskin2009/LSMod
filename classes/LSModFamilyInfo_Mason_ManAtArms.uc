class LSModFamilyInfo_Mason_ManAtArms extends AOCFamilyInfo_Mason_ManAtArms;
	
var float MaxFallSpeed;


DefaultProperties
{
	NewPrimaryWeapons.Empty;
	NewPrimaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewPrimaryWeapons(1)=(CWeapon=class'LSModWeapon_DOUBLE_LSMod',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewSecondaryWeapons.Empty;
	NewSecondaryWeapons(0)=(CWeapon=class'LSModweapon_LightSaber',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
//	NewSecondaryWeapons(0)=(CWeapon=class'LSModWeapon_1HLSMod_SMALL',CheckLimitExpGroup=EEXP_BASTARD,UnlockExpLevel=0.f)
	NewTertiaryWeapons.Empty;	
	NewTertiaryWeapons(0)=(CWeapon=class'LSModWeapon_ThrowingKnife')
	NewTertiaryWeapons(1)=(CWeapon=class'AOCWeapon_OilPot')
	
	MaxFallSpeed = 1400.0
//	bCanSprintAttack= true
}
