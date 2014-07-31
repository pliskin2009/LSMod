/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
*
* Original Author: Tim Liszak
*
* Thrown projectile/weapon that bounces off something.  It can be picked up.
* (AOCDroppedWeapon can be used if it doesn't need to be picked up)
* 
*/


class LSModBouncedProjectile extends AOCDroppedWeapon;

var class<AOCWeapon> CorrespondingWeapon; // the type of weapon that this projectile came from
var int StickyId;

singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local LSModPawn Pawn;
	if (LSModPawn(Other) != none)
	{
		Pawn = LSModPawn(Other);
		if (ILSModRangeWeapon(CorrespondingWeapon).CanThrowWeapon())
		{
			if (Pawn.CanPickUpThrownWeapon(CorrespondingWeapon))
			{
				Pawn.PickUpThrownWeapon(CorrespondingWeapon, StickyId);
				Destroy();
			}
		}
	}
}
	
DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
        CollideActors=true
		Scale=1.5
	end object

    bCollideActors=true
}
