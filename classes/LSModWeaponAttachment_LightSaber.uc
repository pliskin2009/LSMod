/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
* 
* Original Author: Michael Bao
* 
* The weapon that is replicated to all clients: Longsword
*/
class LSModWeaponattachment_LightSaber extends AOCWeaponAttachment_Longsword
implements (ILSModWeaponAttachment);

//var linearcolor linearLaserColor;
var linearcolor LaserColor;
var color cLaserColor;
var() PointLightComponent MyLight;

simulated function PostBeginPlay()
{
	local AOCPlayerController PC;
	
	super.PostBeginPlay();
	PC = AOCPlayerController(WorldInfo.GetALocalPlayerController());

	if(ILSModPlayerController(PC) != None && ILSModPlayerController(PC).TurnedLightsOn())
	{
	
    Mesh.AttachComponentToSocket(MyLight, 'light');
	SetLightColor();
	}
	

}

simulated function SetLightColor()
{
	cLaserColor = LinearColorToColor(LaserColor);
	MyLight.SetLightProperties (, cLaserColor);

}
///////////////////////////////////////////

simulated function SetSkin(Material NewMaterial)
{
	super.SetSkin(NewMaterial);
	
	MIC = Mesh.CreateAndSetMaterialInstanceConstant(1);
	MIC.SetVectorParameterValue( 'BladeColor', LaserColor);
	if (AOCOwner.IsLocallyControlled())
		OverlayMIC = OverlayMesh.CreateAndSetMaterialInstanceConstant(1);
		OverlayMIC.SetVectorParameterValue( 'BladeColor', LaserColor);
		
	
}

function Color LinearColorToColor(LinearColor LinCol)
{
	local Color col;
	col.A = LinCol.A * 255.0f;
	col.R = LinCol.R * 255.0f;
	col.G = LinCol.G * 255.0f;
	col.B = LinCol.B * 255.0f;
	return col;
}

////////////////////////////////////////

simulated function AttachTo(UTPawn OwnerPawn)
{
	super.AttachTo(OwnerPawn);
	CreateRibbons();
}

simulated function CreateRibbons()
{
	if (WeaponPSSocket != '' && WeaponPS != none)
	{
		cLaserColor = LinearColorToColor(LaserColor);
		
		WeaponPSComp = new(self) class'UTParticleSystemComponent';
		WeaponPSComp.bAutoActivate = false;
		WeaponPSComp.SetOwnerNoSee(true);
		WeaponPSComp.SetTemplate(WeaponPS);
		WeaponPSComp.bUpdateComponentInTick = true;
		WeaponPSComp.SetTickGroup(TG_PostUpdateWork);
		WeaponPSComp.SetColorParameter('TrailColor', cLaserColor);
		Mesh.AttachComponentToSocket(WeaponPSComp, WeaponPSSocket);


		if ( ((AOCOwner.IsLocallyControlled() && !AOCOwner.bIsBot) || AOCOwner.bIsBeingFPObserved) && !AOCPlayerController(AOCOwner.Controller).bBehindView)
		{
			AttachOverlayEffect();
		}
		else
		{
			WeaponPSComp.SetOwnerNoSee(false);
		}
	}
}


simulated function AttachOverlayEffect()
{
	if (OverlayWeaponPSComp == none)
	{
		OverlayWeaponPSComp = new(self) class'UTParticleSystemComponent';
		OverlayWeaponPSComp.bAutoActivate = false;
		OverlayWeaponPSComp.SetOwnerNoSee(false);
		OverlayWeaponPSComp.SetTemplate(WeaponPS);
		WeaponPSComp.bUpdateComponentInTick = true;
		WeaponPSComp.SetTickGroup(TG_PostUpdateWork);
		OverlayMesh.AttachComponentToSocket(OverlayWeaponPSComp, WeaponPSSocket);
	}
}


simulated function ChangeOverlayMeshVisibility(bool bVis)
{
	super.ChangeOverlayMeshVisibility(bVis);

//	OverlayWeaponPSComp.SetHidden(bVis);
	WeaponPSComp.SetOwnerNoSee(!bVis);
}

simulated function ForceAttachOverlay()
{
	super.ForceAttachOverlay();

	AttachOverlayEffect();
}

//called from the Pawn Class
function StartRibbons()
{
    WeaponPSComp.ActivateSystem();
//	OverlayWeaponPSComp.ActivateSystem();
}


function KillRibbons()
{
    WeaponPSComp.DeactivateSystem();
//	OverlayWeaponPSComp.DeactivateSystem();
}


simulated function AttachArrow()
{
}

simulated function DetachArrow()
{
}

////////////////////////////////////////////////////////////////////////////

simulated function TestTracerSegment(vector startPos, vector prevStartPos, vector vSegment, ETracerType TracerType, int iSegment)
{		
	local Actor hitActor;
	local vector hitPos, hitNormal;
	local TraceHitInfo hitInfo;

	local int iWidth;
	local vector vWidth;

	local vector hitDir;
	
	local float TimeReleased;
	local AOCMeleeWeapon OwnerWeapon;
	
	
	OwnerWeapon = AOCMeleeWeapon(Pawn(Owner).Weapon);
//	ReleasePercent = (WorldInfo.TimeSeconds - OwnerWeapon.TimeStartRelease) / OwnerWeapon.TimeLeftInRelease;
	TimeReleased= WorldInfo.TimeSeconds - OwnerWeapon.TimeStartRelease;
	
	hitDir = Normal(startPos - prevStartPos);

	// Simulate some sort of weapon width
	vWidth = Normal(vSegment cross hitDir) * WeaponWidth;

	if(TimeReleased <= 0.1)
		TracerType = ETracerType_ParryImmediately;
	
	// Perform tracers
	for (iWidth = -1; iWidth <= 1; iWidth++)
	{
		DrawDebugTracerSegment(startPos + vWidth * iWidth, prevStartPos + vWidth * iWidth, TracerType);

		//if (t == 0) continue;
		hitActor = Trace(hitPos, hitNormal, startPos + vWidth * iWidth, prevStartPos + vWidth * iWidth, true,, hitInfo, TRACEFLAG_BULLET);
		if (hitActor != none )
		{
			Hit(hitActor, hitPos, hitNormal, hitInfo, AttackTypeInfo[CurrentAttack].fForce * hitDir, iSegment, TracerType);
		}
	}
}

/////////////////////////////////

DefaultProperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'WP_LSMod.WEP_LIGHTSABER_BLUE'
		bForceUpdateAttachmentsInTick=true
		TickGroup=TG_PreAsyncWork
		//Translation=(Z=1)
		//Rotation=(Roll=-400)
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	Begin Object Name=SkeletalMeshComponent2
		SkeletalMesh=SkeletalMesh'WP_LSMod.WEP_LIGHTSABER_BLUE'
		bForceUpdateAttachmentsInTick=true
		TickGroup=TG_PreAsyncWork
		//Translation=(Z=1)
		//Rotation=(Roll=-400)
		Scale=1.0
		bUpdateSkelWhenNotRendered=true
		bForceRefPose=0
		bIgnoreControllersWhenNotRendered=false
		bOverrideAttachmentOwnerVisibility=false
	End Object

	WeaponID=EWEP_Longsword
	WeaponClass=class'LSModWeapon_LightSaber'
	WeaponSocket=wep2hpoint
	
	bUseAlternativeKick=true

	WeaponPSSocket=Light

	WeaponPS=ParticleSystem'LSMod_Wep_Lightsaber.Particles.LightsaberRibbon'
	
	WeaponStaticMesh=StaticMesh'WP_LSMod.SM_LIGHTSABER_Lightsaber'
	WeaponStaticMeshScale=1

	AttackTypeInfo(0)=(fBaseDamage=75.0, fForce=30000, cDamageType="AOC.AOCDmgType_Swing", iWorldHitLenience=6)
	AttackTypeInfo(1)=(fBaseDamage=82.0, fForce=30000, cDamageType="AOC.AOCDmgType_Swing", iWorldHitLenience=6)
	AttackTypeInfo(2)=(fBaseDamage=61.0, fForce=30000, cDamageType="AOC.AOCDmgType_Pierce", iWorldHitLenience=6)
	AttackTypeInfo(3)=(fBaseDamage=100.0, fForce=22500, cDamageType="AOC.AOCDmgType_Swing", iWorldHitLenience=6)
	AttackTypeInfo(4)=(fBaseDamage=0.0, fForce=32500, cDamageType="AOC.AOCDmgType_Swing", iWorldHitLenience=6)
	AttackTypeInfo(5)=(fBaseDamage=5.0, fForce=45500.0, cDamageType="AOC.AOCDmgType_Shove", iWorldHitLenience=12)
}
