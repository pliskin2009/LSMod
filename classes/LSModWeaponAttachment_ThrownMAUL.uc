/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
* 
* Original Author: Michael Bao
* 
* The Weapon Attachment for the Thrown Axe.
*/
class LSModWeaponAttachment_ThrownMAUL extends AOCWeaponAttachment_ThrownAxe;

DefaultProperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'WP_hbl_Maul.WEP_Maul'
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		Animations=none
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	Begin Object Name=SkeletalMeshComponent2
		SkeletalMesh=SkeletalMesh'WP_hbl_Maul.WEP_Maul'
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		Animations=none
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	WeaponID=EWEP_ThrownAxe
	WeaponSocket=wep1hpoint
	WeaponClass=class'AOCWeapon_ThrowingAxe'

	WeaponStaticMesh=StaticMesh'WP_hbl_Maul.SM_Maul'
	WeaponStaticMeshScale=1

	AttackTypeInfo(0)=(fBaseDamage=20.0, fForce=22500, cDamageType="AOC.AOCDmgType_Generic", iWorldHitLenience=6)
	AttackTypeInfo(1)=(fBaseDamage=20.0, fForce=22500, cDamageType="AOC.AOCDmgType_Generic", iWorldHitLenience=6)
	AttackTypeInfo(2)=(fBaseDamage=20.0, fForce=22500, cDamageType="AOC.AOCDmgType_Generic", iWorldHitLenience=6)
	AttackTypeInfo(3)=(fBaseDamage=20.0, fForce=22500, cDamageType="AOC.AOCDmgType_Generic", iWorldHitLenience=6)
	AttackTypeInfo(4)=(fBaseDamage=1.0, fForce=22500, cDamageType="AOC.AOCDmgType_Generic", iWorldHitLenience=6)
	AttackTypeInfo(5)=(fBaseDamage=5.0, fForce=45500.0, cDamageType="AOC.AOCDmgType_Shove", iWorldHitLenience=12)
}
