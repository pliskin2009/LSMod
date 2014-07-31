/**
 * Copyright 2010-2012 Torn Banner Studios. All Rights Reserved.
 * 
 * Author: Michael Bao
 * 
 * Inventory attachment for the Longsword.
 */
class LSModInventoryattachment_LightSaber extends AOCInventoryAttachment_Longsword;

DefaultProperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'WP_LSMod.WEP_LIGHTSABER_OFF'
	End Object

	StaticMeshSpawn=StaticMesh'WP_LSMod.SM_LIGHTSABER_Lightsaber'

	CarryType=ECARRY_LARGE
	CarryLocation=ELOC_HOLD
	CarrySocketName=Lootcarry
}
