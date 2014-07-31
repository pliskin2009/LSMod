/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
* 
* Original Author: Michael Bao
* 
* The weapon class to contain information for the Longsword
*/
class LSModweapon_LightSaber extends AOCMeleeWeapon
	dependson(AOCProjectile)
	dependson(LSModPawn)
	implements(ILSModMeleeWeapon);
	
var array< class<AOCWeaponAttachment> > PAttachs;

var Projectile SpawnedProjectile;

/////////Reflected_Proj_Var////////////
struct SProjDamageInfo
{
	var() bool bInfiniteAmmo;
	var() float MinDamage;
	var() float Damage;
	var() float InitialSpeed;
	var() float MaxSpeed;
	var() float InitialGravityScale;
	var() float Drag;
	var() float AmmoCount;
	var() float PitchCorrection;
	var() float MinimumFireTime;
	
	structdefaultproperties
	{
		bInfiniteAmmo=false
	}
};

var array<SProjDamageInfo>   ConfigProjectileBaseDamage;

var bool bCanReflectProjectiles;


var bool bHasInformedPawnAboutProjectileCam;

var float fLastProjectileSpawnTime;

/////////////////////////////////////////////////



simulated function AttachWeaponTo( SkeletalMeshComponent MeshCpnt, optional Name SocketName )
{
	local UTPawn UTP;

	UTP = UTPawn(Instigator);
	
	if(AOCFFA(WorldInfo.Game) == none)  //&& AOCDuel(WorldInfo.Game) ==none
	{
		if(LSModPawn(UTP).PawnInfo.myFamily.default.FamilyFaction == EFAC_AGATHA)
		{
			if(LSModPawn(UTP).bGeneratedNumber!=true)
			{
				LSModPawn(UTP).bGeneratedNumber=true;
				LSModPawn(UTP).GeneratedNumber=Rand(2);
			}
			AttachmentClass = PAttachs[LSModPawn(UTP).GeneratedNumber];
	
	
		}
		if(LSModPawn(UTP).PawnInfo.myFamily.default.FamilyFaction == EFAC_MASON)
		{
		LSModPawn(UTP).bGeneratedNumber=true;
		AttachmentClass = PAttachs[2];
		}
	}
	
	
	
	if(AOCFFA(WorldInfo.Game) != none)   //|| AOCDuel(WorldInfo.Game) !=none
	{
		if(LSModPawn(UTP).bGeneratedNumber!=true)
		{
			LSModPawn(UTP).bGeneratedNumber=true;
			LSModPawn(UTP).GeneratedNumber=Rand(3);
		}
		AttachmentClass = PAttachs[LSModPawn(UTP).GeneratedNumber];
	}
	`logalways(LSModPawn(UTP).PawnInfo.myFamily.default.FamilyFaction);
	
	super.AttachWeaponTo(MeshCpnt, SocketName);
}



//////////////////////////////////////////////

//////////////////////////////////////PROJECTILE_REFLECTION_FUNCTIONS_VVVVVVVVVVVV

reliable client function  FireReflected(class <LSModProjectile> ReflectedProjectileClass)
{
	local rotator Aim;
   	local Vector RealStartLoc;

		if (!AOCOwner.bIsBot)
			AOCOwner.OwnerMesh.GetSocketWorldLocationAndRotation(AOCOwner.CameraSocket, RealStartLoc, Aim);
		else
		{
			AOCOwner.Mesh.GetSocketWorldLocationAndRotation(AOCOwner.CameraSocket, RealStartLoc, Aim);
			Aim = AOCAICombatController(AOCOwner.Controller).GetAim(RealStartLoc);
		}

		if (!AOCOwner.IsFirstPerson() && !AOCOwner.bIsBot)
		{
			Aim = CalcThirdPersonAim(RealStartLoc, Aim);
		}


		SpawnReflectedProjectile( RealStartLoc, Aim.Pitch, Aim.Yaw, Aim.Roll, ReflectedProjectileClass );
		`logalways("CLIENT_RealStartLoc"@RealStartLoc);
		
		if (WorldInfo.NetMode != NM_Standalone && !AOCOwner.bIsBot)
		{
			Server_ReflectSpawnProjectile(RealStartLoc, Aim.Pitch, Aim.Yaw, Aim.Roll , ReflectedProjectileClass);
		}
		else
		{
			SpawnedProjectile.RemoteRole = ROLE_None; //It's MINE (client-side projectile)
		}

		enableProjCam();
		//Aim = GetAdjustedAim( RealStartLoc );			// get fire aim direction

		AOCOwner.OnActionInitiated(EACT_RangedWeaponFired);

}


reliable server function Server_ReflectSpawnProjectile(Vector RealStartLoc, float Pitch, float Yaw, float Roll, class <LSModProjectile> ReflectedProjectileClass)
{
	`logalways("SERVER_RealStartLoc"@RealStartLoc);
	SpawnReflectedProjectile(RealStartLoc, Pitch, Yaw, Roll , ReflectedProjectileClass);
}

simulated function SpawnReflectedProjectile( Vector RealStartLoc, float Pitch, float Yaw, float Roll , class <LSModProjectile> ReflectedProjectileClass)
{
	local Rotator Aim;
	local EProjType Type;
		
	fLastProjectileSpawnTime = Worldinfo.TimeSeconds;

	Type = ReflectedProjectileClass.default.ProjType;
	Aim.Pitch = Pitch + ReflectedProjectileClass.default.PitchCorrection;
	Aim.Yaw = Yaw;
	Aim.Roll = Roll;
	SpawnedProjectile = Spawn(ReflectedProjectileClass,,, RealStartLoc, Aim);
	if(AOCOwner != none)
	{
		SpawnedProjectile.RealityID = AOCOwner.RealityID;
	}
	
	`logalways("Spawned"@SpawnedProjectile@"for"@self);
	
	if (AOCPlayerController(AOCOwner.Controller) != none)
	{
		AOCProjectile(SpawnedProjectile).ProjIdent = ++AOCPlayerController(AOCOwner.Controller).ProjectileNumber;
		AOCPlayerController(AOCOwner.Controller).SpawnedProjectile.AddItem(AOCProjectile(SpawnedProjectile));
	}
	if ( SpawnedProjectile != None )
	{
	
		LSModProjectile(SpawnedProjectile).bIsReflected = true;   ////////////////////////////////THIS_IS_A_REFLECTED_PROJ
		
		// Give the projectiles properties based on weapon
		AOCProjectile(SpawnedProjectile).Damage = (ReflectedProjectileClass.default.Damage * 3);
		AOCProjectile(SpawnedProjectile).Speed = ReflectedProjectileClass.default.Speed;
		AOCProjectile(SpawnedProjectile).MaxSpeed = ReflectedProjectileClass.default.MaxSpeed;
		AOCProjectile(SpawnedProjectile).TerminalVelocity = ReflectedProjectileClass.default.MaxSpeed;
		AOCProjectile(SpawnedProjectile).CustomGravityScaling = ReflectedProjectileClass.default.CustomGravityScaling;
		AOCProjectile(SpawnedProjectile).Drag = ReflectedProjectileClass.default.Drag;
		
		if (AOCOwner.bIsBot) //TEMP: Bots can't handle drag at the moment, so, uh, turn it off
			AOCProjectile(SpawnedProjectile).Drag = 0;

		AOCProjectile(SpawnedProjectile).PrevLocation = RealStartLoc;
		AOCProjectile(SpawnedProjectile).OwnerPawn = AOCOwner;
		AOCProjectile(SpawnedProjectile).LaunchingWeapon = self.Class;
		if (self.Class == AOCOwner.PrimaryWeapon || self.Class == AOCOwner.AlternatePrimaryWeapon)
			AOCProjectile(SpawnedProjectile).CurrentAssociatedWeapon = 0;
		else if (self.Class == AOCOwner.TertiaryWeapon)
			AOCProjectile(SpawnedProjectile).CurrentAssociatedWeapon = 2;
		AOCProjectile(SpawnedProjectile).AOCInit(Aim);

		if (AOCPlayerController(AOCOwner.Controller) != none)
			AOCProjectile(SpawnedProjectile).ThisController = AOCPlayerController(AOCOwner.Controller);
	}
}

simulated function EProjType GetReflectedProjectileType()
{
//	return class<AOCProjectile>(WeaponProjectiles[0]).default.ProjType;
}

simulated function class<Projectile> GetReflectedProjectileClass()
{
//	return WeaponProjectiles[0];
}

simulated function WeaponCalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot)
{
	local float out_CamFOV;
	if (AOCPlayerController(AOCPawn(Owner).Controller).bCanSwapToProjCam &&
				AOCPlayerController(AOCPawn(Owner).Controller).bAltFireButtonPressed && SpawnedProjectile != none)
	{
		if(!bHasInformedPawnAboutProjectileCam)
		{
			AOCPawn(Owner).OnActionSucceeded(EACT_ProjectileCam);
			bHasInformedPawnAboutProjectileCam = true;
			c_swapProjectileSound();
		}
		SpawnedProjectile.CalcCamera(fDeltaTime, out_CamLoc, out_CamRot, out_CamFOV);
	}
}


simulated function rotator CalcThirdPersonAim(vector RealStartLoc, rotator Aim)
{
	local Vector CameraLoc;
	local Rotator CameraAim;
	local float CameraFOV;
	local Vector TargetLoc;
	local Vector HitLoc;
	local Vector HitNormal;

	// ray trace along the camera sight to find target location
	AOCOwner.CalcThirdPersonCam(1.0f, CameraLoc, CameraAim, CameraFOV);

	CameraLoc = CameraLoc + (Vect(1,0,0) >> CameraAim) * 130.0f;
	TargetLoc = CameraLoc + (Vect(1,0,0) >> CameraAim) * 10000.0f;

	if( Trace(HitLoc, HitNormal, TargetLoc, CameraLoc, true) != None )
	{
		// Adjust slightly for close objects
		if (VSize(HitLoc - RealStartLoc) < 200.0f)
		{
			HitLoc = HitLoc + Normal(HitLoc - CameraLoc) * 50.0f;
		}

		TargetLoc = HitLoc;
	}

	return Rotator(TargetLoc - RealStartLoc);
}

simulated function enableProjCam()
{
	AOCPlayerController(AOCOwner.Controller).bCanSwapToProjCam = true;
	bHasInformedPawnAboutProjectileCam = false;

	if (Role < ROLE_Authority)
	{
		s_enableProjCam();
	}
}

unreliable server function s_enableProjCam()
{
	AOCPlayerController(AOCOwner.Controller).bCanSwapToProjCam = true;
	
	bHasInformedPawnAboutProjectileCam = false;

	// Update net priority of the projectile (this should avoid camera choppiness)
	SpawnedProjectile.NetPriority = 3.0f;
}

unreliable client function c_swapProjectileSound()
{
	AOCProjectile(SpawnedProjectile).swapArrowCamAmbientSound();
}



function bool CanReflectProjectiles()
{
	return bCanReflectProjectiles;
}


DefaultProperties
{
	bCanDodge=false
	
	PAttachs(0)=class'LSModWeaponattachment_LightSaber_BLUE'
	PAttachs(1)=class'LSModWeaponattachment_LightSaber_GREEN'
	PAttachs(2)=class'LSModWeaponattachment_LightSaber_RED'

	Begin Object class=AnimNodeSequence Name=MeshSequenceA
		bCauseActorAnimEnd=true
	End Object

	bTwoHander=true
	EncircleRadius=25.0f
	EffectiveDistance=200.0f

	ImpactSounds(ESWINGSOUND_Slash)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}

	ImpactSounds(ESWINGSOUND_SlashCombo)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}

	ImpactSounds(ESWINGSOUND_Stab)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}

	ImpactSounds(ESWINGSOUND_StabCombo)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}


	ImpactSounds(ESWINGSOUND_Overhead)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}


	ImpactSounds(ESWINGSOUND_OverheadCombo)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}


	ImpactSounds(ESWINGSOUND_Sprint)={(
		light=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK',
		medium=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITMEDIUM',
		heavy=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITSTRONG',
		wood=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		dirt=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2',
		metal=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWALL1',
		stone=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERHITWEAK2')}

	ImpactSounds(ESWINGSOUND_Shove)={(
		light=SoundCue'A_Impacts_Melee.Light_Kick_Small',
		medium=SoundCue'A_Impacts_Melee.Medium_Kick_Small',
		heavy=SoundCue'A_Impacts_Melee.Heavy_Kick_Small',
		wood=SoundCue'A_Phys_Mat_Impacts.Kick_Wood',
		dirt=SoundCue'A_Phys_Mat_Impacts.Kick_Dirt',
		metal=SoundCue'A_Phys_Mat_Impacts.Kick_Metal',
		stone=SoundCue'A_Phys_Mat_Impacts.Kick_Stone')}

	ImpactSounds(ESWINGSOUND_ShoveCombo)={(
		light=SoundCue'A_Impacts_Melee.Light_Kick_Small',
		medium=SoundCue'A_Impacts_Melee.Medium_Kick_Small',
		heavy=SoundCue'A_Impacts_Melee.Heavy_Kick_Small',
		wood=SoundCue'A_Phys_Mat_Impacts.Kick_Wood',
		dirt=SoundCue'A_Phys_Mat_Impacts.Kick_Dirt',
		metal=SoundCue'A_Phys_Mat_Impacts.Kick_Metal',
		stone=SoundCue'A_Phys_Mat_Impacts.Kick_Stone')}

	ParriedSound=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERPARRIED'
	ParrySound=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERPARRY'

	ImpactBloodTemplates(0)=ParticleSystem'CHV_Particles_01.Player.Impact.P_1HSwordHit'
	ImpactBloodTemplates(1)=ParticleSystem'CHV_Particles_01.Player.Impact.P_1HSwordHit'
	ImpactBloodTemplates(2)=ParticleSystem'CHV_Particles_01.Player.Impact.P_1HSwordHit'

	BloodSprayTemplates(0)=ParticleSystem'CHV_Particles_01.Player.P_OnWeaponBlood'
	BloodSprayTemplates(1)=ParticleSystem'CHV_Particles_01.Player.P_OnWeaponBlood'
	BloodSprayTemplates(2)=ParticleSystem'CHV_Particles_01.Player.P_OnWeaponBlood'


	AttachmentClass=none
	
	InventoryAttachmentClass=class'LSModInventoryattachment_LightSaber'
	AllowedShieldClass=none
	CurrentWeaponType=EWEP_Longsword
	CurrentShieldType=ESHIELD_None
	bHaveShield=false
	WeaponIdentifier="longsword"

	CurrentGenWeaponType=EWT_2handsword

	/* 
	 * Formerly in UDKNewWeapon.ini - [AOC.AOCWeapon_Longsword]
	 */
	iFeintStaminaCost=15
	FeintTime=0.2
	TertiaryFeintTime=0.4
	fParryNegation=17
	ParryDrain(0)=24
	ParryDrain(1)=26
	ParryDrain(2)=22
	WeaponFontSymbol="v"
	WeaponLargePortrait="SWF.weapon_select_longsword"
	WeaponSmallPortrait="SWF.weapon_select_longsword"
	WeaponReach=100
	HorizontalRotateSpeed=55000.0
	VerticalRotateSpeed=55000.0
	AttackHorizRotateSpeed=55000.0
	SprintAttackHorizRotateSpeed=20000.0
	SprintAttackVerticalRotateSpeed=20000.0
	WindupAnimations(0)=(AnimationName=3p_longsword_slash01downtoup,ComboAnimation=3p_longsword_slash011downtoup,AlternateAnimation=3p_longsword_slash011altdowntoup,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.475,fBlendInTime=0.10,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0)
	WindupAnimations(1)=(AnimationName=3p_longsword_slash02downtoup,ComboAnimation=3p_longsword_slash021downtoup,AlternateAnimation=3p_longsword_slash021altdowntoup,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.475,fBlendInTime=0.10,fBlendOutTime=0.00,bLastAnimation=false)
	WindupAnimations(2)=(AnimationName=3p_longsword_stabdowntoup,ComboAnimation=,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.55,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	WindupAnimations(3)=(AnimationName=3p_longsword_sattackdowntoup_new,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Footsteps.Vanguard_Dirt_Jump',bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.65,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false,bUseAltBoneBranch=true,bUseRMM=true)
	WindupAnimations(4)=(AnimationName=3p_longsword_parryib,ComboAnimation=,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERAIRPARRY',bFullBody=False,bCombo=False,bLoop=False,bForce=false,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false,bUseAltNode=true)
	WindupAnimations(5)=(AnimationName=3p_longsword_shovestart,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.3,fBlendInTime=0.05,fBlendOutTime=0.00,bLastAnimation=false,bUseAltNode=true,bUseAltBoneBranch=true)
	WindupAnimations(6)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	WindupAnimations(7)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	WindupAnimations(8)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.6,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	WindupAnimations(9)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.6,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations.empty;
	ReleaseAnimations(0)=(AnimationName=3p_longsword_slash01release,ComboAnimation=3p_longsword_slash011release,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERSWING2',bFullBody=true,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.45,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false,bAttachArrow=1)
	ReleaseAnimations(1)=(AnimationName=3p_longsword_slash02release,ComboAnimation=3p_longsword_slash021release,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERSWING2',bFullBody=true,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.45,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false,bAttachArrow=1)
	ReleaseAnimations(2)=(AnimationName=3p_longsword_stabrelease,ComboAnimation=3p_longsword_stabrelease,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERSWING3',bFullBody=true,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false,bAttachArrow=1)
	ReleaseAnimations(3)=(AnimationName=3p_longsword_sattackrelease,ComboAnimation=,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERSPRINT',bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.7,fBlendInTime=0.1,fBlendOutTime=0.1,bLastAnimation=false,bUseAltBoneBranch=true,bAttachArrow=1)
	ReleaseAnimations(4)=(AnimationName=3p_longsword_parryup,ComboAnimation=,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERAIRPARRY',bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,bUseAltNode=true)
	ReleaseAnimations(5)=(AnimationName=3p_longsword_shoverelease_new,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.3,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false,bUseAltNode=true,bUseAltBoneBranch=true,bUseRMM=true)
	ReleaseAnimations(6)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false)
	ReleaseAnimations(7)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.0,bLastAnimation=false)
	ReleaseAnimations(8)=(AnimationName=3p_longsword_equipup,ComboAnimation=,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERDRAW',bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.55,fBlendInTime=0.00,fBlendOutTime=0.01,bLastAnimation=false)
	ReleaseAnimations(9)=(AnimationName=3p_longsword_equipdown,ComboAnimation=,AssociatedSoundCue=SoundCue'LSMod_Wep_Lightsaber.SoundFX.CUE_SABERSHEATH',bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.01,bLastAnimation=false)
	RecoveryAnimations(0)=(AnimationName=3p_longsword_slash01recover,ComboAnimation=3p_longsword_slash011recover,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.7,fBlendInTime=0.10,fBlendOutTime=0.2,bLastAnimation=true)
	RecoveryAnimations(1)=(AnimationName=3p_longsword_slash02recover,ComboAnimation=3p_longsword_slash021recover,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.7,fBlendInTime=0.10,fBlendOutTime=0.2,bLastAnimation=true)
	RecoveryAnimations(2)=(AnimationName=3p_longsword_stabrecover,ComboAnimation=3p_longsword_stabrecover,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.7,fBlendInTime=0.10,fBlendOutTime=0.1,bLastAnimation=true)
	RecoveryAnimations(3)=(AnimationName=3p_longsword_sattackrecover,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true,bUseAltBoneBranch=true)
	RecoveryAnimations(4)=(AnimationName=3p_longsword_parryrecover,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true,bUseAltNode=true)
	RecoveryAnimations(5)=(AnimationName=3p_longsword_shoverecover,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.10,fBlendOutTime=0.0,bLastAnimation=true,bUseAltNode=true,bUseAltBoneBranch=true)
	RecoveryAnimations(6)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true)
	RecoveryAnimations(7)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true)
	RecoveryAnimations(8)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true)
	RecoveryAnimations(9)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=true)
	StateAnimations(0)=(AnimationName=3p_longsword_parried,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.8,fBlendInTime=0.00,fBlendOutTime=0.08,bLastAnimation=true)
	StateAnimations(1)=(AnimationName=3p_longsword_dazed,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.2,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=true)
	StateAnimations(2)=(AnimationName=3p_longsword_hitFR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=true)
	StateAnimations(3)=(AnimationName=3p_longsword_hitBL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=true)
	StateAnimations(4)=(AnimationName=3p_longsword_hitFL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.2,fBlendInTime=0.10,fBlendOutTime=0.08,bLastAnimation=false)
	BattleCryAnim=(AnimationName=3p_longsword_battlecry,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	TransitionAnimations(0)=(AnimationName=3p_longsword_slash011downtoup,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(1)=(AnimationName=3p_longsword_slash02toslash01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(2)=(AnimationName=3p_longsword_slash011toslash01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(3)=(AnimationName=3p_longsword_slash021toslash011,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(4)=(AnimationName=3p_longsword_stabtoslash01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(5)=(AnimationName=3p_longsword_slash01toslash02,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(6)=(AnimationName=3p_longsword_slash021downtoup,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(7)=(AnimationName=3p_longsword_slash011toslash021,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(8)=(AnimationName=3p_longsword_slash021toslash02,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(9)=(AnimationName=3p_longsword_stabtoslash02,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(10)=(AnimationName=3p_longsword_slash01tostab,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(11)=(AnimationName=3p_longsword_slash011tostab,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(12)=(AnimationName=3p_longsword_slash02tostab,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(13)=(AnimationName=3p_longsword_slash021tostab,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.625,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(14)=(AnimationName=THIS_LINE_IS_UNUSED,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.8,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false)
	TransitionAnimations(15)=(AnimationName=3p_longsword_slash01toparry,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.125,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	TransitionAnimations(16)=(AnimationName=3p_longsword_slash011toparry,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.125,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	TransitionAnimations(17)=(AnimationName=3p_longsword_slash02toparry,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.125,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	TransitionAnimations(18)=(AnimationName=3p_longsword_slash021toparry,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.125,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	TransitionAnimations(19)=(AnimationName=3p_longsword_stabtoparry,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.125,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	OtherParryAnimations(0)=(AnimationName=3p_longsword_parried,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.2,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	OtherParryAnimations(1)=(AnimationName=3p_longsword_parried,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.2,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	ShieldIdleAnim=(AnimationName=3p_buckler_parryupidle,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=true,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=false)
	TurnInfo(0)=(AnimationName=3p_longsword_turnL,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=true,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bLowerBody=true)
	TurnInfo(1)=(AnimationName=3p_longsword_turnR,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=true,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false))
	DazedAnimations(0)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(1)=(AnimationName=3p_longsword_dazedL01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(2)=(AnimationName=3p_longsword_dazedF01,AlternateAnimation=3p_longsword_parrydazed,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(3)=(AnimationName=3p_longsword_dazedR01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(4)=(AnimationName=3p_longsword_dazedBL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(5)=(AnimationName=3p_longsword_dazedBR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(6)=(AnimationName=3p_longsword_dazedFL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(7)=(AnimationName=3p_longsword_dazedFR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DirHitAnimation(0)=(AnimationName=ADD_3p_longsword_hitFL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(1)=(AnimationName=ADD_3p_longsword_hitFR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(2)=(AnimationName=ADD_3p_longsword_hitBL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(3)=(AnimationName=ADD_3p_longsword_hitBR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirParryHitAnimations(0)=(AnimationName=3p_longsword_parryhitL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.3,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	DirParryHitAnimations(1)=(AnimationName=3p_longsword_parryhitR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.3,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	DirParryHitAnimations(2)=(AnimationName=3p_longsword_parryhitH,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.3,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	DirParryHitAnimations(3)=(AnimationName=3p_longsword_parryhitS,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.3,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true,bUseAltNode=true)
	AlternateRecoveryAnimations(0)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(1)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(2)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(3)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(4)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(5)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(6)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(7)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(8)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	AlternateRecoveryAnimations(9)=(AnimationName=3p_longsword_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	//Executions:
	//0 - Front
	//1 - Back
	//2 - Front (attacker has shield equipped)
	//3 - Back (attacker has shield equipped)
	ExecuterAnimations(0)=(AnimationName=3p_longsword_executorF,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuterAnimations(1)=(AnimationName=3p_longsword_executorB,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuterAnimations(2)=(AnimationName=3p_longsword_executorF,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuterAnimations(3)=(AnimationName=3p_longsword_executorB,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuteeAnimations(0)=(AnimationName=3p_death_2hswordFdeath,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuteeAnimations(1)=(AnimationName=3p_death_2hswordBdeath,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuteeAnimations(2)=(AnimationName=3p_death_2hswordFdeath,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)
	ExecuteeAnimations(3)=(AnimationName=3p_death_2hswordBdeath,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.0,fBlendOutTime=0.00,bLastAnimation=false,fShieldAnimLength=0.0,bUseSlotSystem=True)

	
	//////////////////////////////////////////Proj_Reflection_VVVVVVV
	
	bCanReflectProjectiles = true
	
	bHasInformedPawnAboutProjectileCam = false
}
