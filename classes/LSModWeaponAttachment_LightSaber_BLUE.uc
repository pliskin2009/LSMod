/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
* 
* Original Author: Michael Bao
* 
* The weapon that is replicated to all clients: Longsword
*/
class LSModWeaponattachment_LightSaber_BLUE extends LSModWeaponattachment_LightSaber;

DefaultProperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'LSMod_Wep_Lightsaber.Meshes.Vader_saber'
		//Translation=(Z=1)
		//Rotation=(Roll=-400)
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	Begin Object Name=SkeletalMeshComponent2
		SkeletalMesh=SkeletalMesh'LSMod_Wep_Lightsaber.Meshes.Vader_saber'
		//Translation=(Z=1)
		//Rotation=(Roll=-400)
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	WeaponID=EWEP_Longsword
	WeaponClass=class'LSModweapon_LightSaber'
	WeaponSocket=wep2hpoint
	
	bUseAlternativeKick=true

	WeaponStaticMesh=StaticMesh'WP_LSMod.SM_LIGHTSABER_Lightsaber'
	WeaponStaticMeshScale=1

`include(LSMod/Include/BLUESABERDefProp.uci)

}
