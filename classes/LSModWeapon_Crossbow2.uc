/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
* 
* Original Author: Michael Bao
* 
* Crossbow.
*/
class LSModWeapon_Crossbow2 extends AOCRangeWeapon
	dependson(AOCPawn)
	implements(ILSModRangeWeapon);

/** Whether or not we're currently aiming so we can get out of it if necessary */
var bool bAiming;
var bool bGoBackToHold;


var bool bCanThrowWeapon;     ///////////////////////////////////From_ILSModRangeWeapon

simulated function Fire()
{
	super.Fire();
	MakeNoise(1.0);
}


/////

simulated state WeaponEquipping
{
	simulated function ActivateReload()
	{
	}

	reliable server function ServerActivateReload()
	{
	}
	
	simulated function ActivatePawnAmmoRegen()
	{
	LSModPawn(AOCowner).BeginRegen();
	}
	
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		
		if(HasAmmoRegen())
		{
		ActivatePawnAmmoRegen();
		}
	}
}

simulated state WeaponPuttingDown
{
	simulated function ActivateReload()
	{
	}

	reliable server function ServerActivateReload()
	{
	}
}

////





function int AddAmmo( int Amount )
{
	local int ret;
	ret =  super(AOCWeapon).AddAmmo(Amount);
	if (WorldInfo.NetMode == NM_STANDALONE)
		NotifyAmmoConsume();

	if (ret == 0)
	{
//		bLoaded = false;
		AOCWepAttachment.bHasAmmo = false;
		AOCowner.bWeaponHasAmmoLeft = false;
		`logalways(AOCWepAttachment.bHasAmmo);
	}
	else if (Amount > 0)
	{
		AOCPlayerController(AOCOwner.Controller).NotifyPickupAmmo(Amount);
		`logalways(ret);
//		bLoaded = true;
		AOCWepAttachment.bHasAmmo = true;
		AOCOWner.bWeaponHasAmmoLeft = true;
	}

	return ret;
}



simulated function ForceOutOfReloadSwitch()
{
}

simulated state Flinch
{
	/** When finished with flinch go to the next state */
	simulated function OnStateAnimationEnd()
	{
		GotoState('Active');
	}
}


simulated state Active
{
	/** Go into proper state for firing - Changed so that we notify other clients about starting an attack.
	 *  This function called on both server and client.
	 */
	simulated function BeginFire(byte FireModeNum)
	{
		if (FireModeNum == Attack_Shove)
			AOCOwner.PlaySound(AOCOwner.GenericCantDoSound, true);
		else if (bLoaded || (FireModeNum == Attack_Overhead))
			super.BeginFire(FireModeNum);
	}

	simulated event BeginState(Name PreviousStateName)
	{
		local AnimationInfo Info;
		`logalways(" ACTIVE_STATE");
		//`log("BEGIN STATE ACTIVE");
		// cache weapon references to make sure these variables are set for the rest of the states
		CacheWeaponReferences();
		AOCPlayerController(AOCOwner.Controller).ResumeForwardSpawnTimer();
		bCanExecute = true;
		AOCOwner.ManualReset();
		AOCOwner.bUseSprintLeanAnims = bUseSprintLeanAnims;
		AOCOwner.bUseRunStartStopAnims = bUseStartStopAnims;
		AOCOwner.bUseTurnAnimations = bUseTurnAnimations;
		AOCOwner.bUseCombatWalk = bUseCombatWalk;

		if (AOCOwner.bIsBot && AOCAICombatController(AOCOwner.Controller) != none)
			AOCOwner.StateVariables.bCanMove = true;

		// let user sprint, parry, get shield, combo, etc.
		////`log("UPDATE USER ABILITIES");
		AOCOwner.StateVariables.bCanDodge = true;
		AOCOwner.StateVariables.bCanJump = true;
		AOCOwner.StateVariables.bIsAttacking = false;
		AOCOwner.StateVariables.bCanAttack = true;
		AOCOwner.StateVariables.bIsActiveShielding = false;
		AOCOwner.bSwitchingWeapons = false;

		bGenericHit = false;
		
		AOCOwner.StateVariables.bCanSprint = true;

		AOCOwner.StateVariables.bCanParry = true;
		AOCOwner.StateVariables.bIsParrying = false;
		AOCOwner.AirControl = AOCOwner.DefaultAirControl;

		if( AOCBot(AOCOwner.Controller) != none )
			AOCBot(AOCOwner.Controller).WeaponBackToActive();

		// just in case
		if (AOCPlayerController(AOCOwner.Controller) != none)
			AOCPlayerController(AOCOwner.Controller).bAcceptPlayerInput = true;

		AOCOwner.bAltIsAttacking = false;

		AOCOwner.HandleDelayedFlinch();
	
		if (Role < ROLE_Authority || WorldInfo.NetMode == NM_STANDALONE)
		{
			AOCBaseHUD(AOCPlayerController(AOCOwner.Controller).myHUD).TurnOffCrosshair();
			AOCBaseHUD(AOCPlayerController(AOCOwner.Controller).myHUD).TurnOnRangeCrosshair(PreviousStateName == 'WeaponEquipping');
			AOCBaseHUD(AOCPlayerController(AOCOwner.Controller).myHUD).ShowAmmoCount(true);
			AOCBaseHUD(AOCPlayerController(AOCOwner.Controller).myHUD).UpdateAmmoCount(AmmoCount, MaxAmmoCount);
		}

		if (bPlayOnWeapon)
		{
			Info.Animationname = 'STOP';
			AOCOwner.PlayWeaponAnimation(Info);
		}		
		bAiming=false;
		AOCOwner.ResetFOV();
	}
}

simulated state Ironsightwindup
{
	simulated function ActivateHitAnim(EDirection Direction, bool bSameTeam)
	{
		CancelRangedAttack();
		super.ActivateHitAnim(Direction, bSameTeam);
	}

	/** Play Windup animation */
	simulated function PlayStateAnimation()
	{
		AOCOwner.ReplicateCompressedAnimation(WindupAnimations[CurrentFireMode], EWST_Windup, CurrentFireMode);
	}

	/** When finished with windup go to the next state */
	simulated function OnStateAnimationEnd()
	{
		GotoState('Hold');
	}

	/** Play appropriate attack animation */
	simulated event BeginState(Name PreviousStateName)
	{
		`logalways(" I_S_WINDUP_STATE");
		CurrentAnimations = WindupAnimations;

		AOCOwner.ToggleSprint(false);
		
		CurrentFireMode = Attack_Slash;
		// change state variables here
		//AOCOwner.StateVariables.bCanJump = false;
		AOCOwner.StateVariables.bIsAttacking = true;
		AOCOwner.StateVariables.bCanSprint = false;
		// make sure user loses stamina if he attacks after he spawns
		AOCOwner.bSprintConsumeStamina = true;
	
		bAiming = true;

		PlayStateAnimation();
	}

	/** Cancel windup */
	simulated function BeginFire(byte FireModeNum)
	{
		if (EAttack(FireModeNum) == Attack_Parry)
		{
			CurrentFireMode = Attack_Slash;
			bAiming = false;
			bRetIdle = true;
			GotoState('Recovery');
		}
	}
}

simulated state Hold
{

	simulated event Tick(float DeltaTime)
	{
		TestbLoaded();
		super.Tick(DeltaTime);		
	}

	simulated event BeginState(Name PreviousStateName)
	{
		CurrentFireMode = Attack_Slash;
		PlayStateAnimation();
		//ZoomIn();

//		if (AmmoCount == 0)
//			SwitchWeaponNoAmmo();
	

	}
	
	simulated function BeginFire(byte FireModeNum)
	{
		if (EAttack(FireModeNum) == Attack_Overhead || EAttack(FireModeNum) == Attack_Parry)
		{
			CurrentFireMode = Attack_Slash;
			bAiming = false;
			CompleteState(true);
		}
	}
	
	simulated function PlayStateAnimation()
	{
		AOCOwner.ReplicateCompressedAnimation(HoldAnimations[CurrentFireMode], EWST_Hold, CurrentFireMode);
	}
	
	simulated function ReleaseWeapon()
	{
	}

	simulated function EndFire(byte FireModeNum)
	{
		if (bLoaded && EAttack(FireModeNum) == Attack_Slash && AmmoCount > 0)
		{
			`logalways("END FIRE");
			`logalways("bAiming =="@bAiming);
			super.EndFire(FireModeNum);
		}
//		else if (!bLoaded && EAttack(FireModeNum) == Attack_Slash)
//		{
//			CurrentFireMode = Attack_Slash;                                                             Don't go to IDLE if 0 ammo
//			bAiming = false;
//			CompleteState(true);
//		}
	}
	simulated event EndState(Name NextStateName)
	{
		// TODO: Stop all animation
		// zoom out just in case
		//ZoomOut();
		AOCOwner.StateVariables.bIsAttacking = false;
		AOCOwner.RemoveDebuff(EDEBF_ANIMATION);

		super.EndState(NextStateName);
	}

	simulated function ZoomOut()
	{
		`logalways("ZOOM OUT:"@PlayerController(AOCOwner.Controller).DefaultFOV);
		if (PlayerController(AOCOwner.Controller) != none)
			PlayerController(AOCOwner.Controller).DesiredFOV = PlayerController(AOCOwner.Controller).DefaultFOV;
	}

	simulated function ZoomIn()
	{
		`logalways("ZOOM IN");
		if (PlayerController(AOCOwner.Controller) != none && bLoaded)
		{
			if (PlayerController(AOCOwner.Controller).DesiredFOV == PlayerController(AOCOwner.Controller).DefaultFOV)
				PlayerController(AOCOwner.Controller).DesiredFOV *= 70.0f/95.f;
			`logalways("NEW FOV"@PlayerController(AOCOwner.Controller).DesiredFOV);
			AOCOwner.OnActionSucceeded(EACT_Focus);
		}
		else
		{
			CurrentFireMode = Attack_Slash;
			bAiming = false;
			CompleteState(true);
		}
	}
}

simulated state Windup
{

	
	/** When finished with windup go to the next state */
	simulated function OnStateAnimationEnd()
	{
		GotoState('Release');
	}

	/** Play appropriate reload animation animation
	 *  No reload animation
	 */
	simulated event BeginState(Name PreviousStateName)
	{
		`logalways("?????WINDUP_STATE?????");
		OnStateAnimationEnd();
	}
}

simulated state Release
{
	/** Play appropriate attack animation */
	simulated event BeginState(Name PreviousStateName)
	{
		`logalways("RELEASE_STATE");
		if (bAiming)
		{
			ReleaseProjectileTime = WorldInfo.TimeSeconds;
			AOCWepAttachment.bHasAmmo = false;
			AOCOwner.bWeaponHasAmmoLeft = false;
			super.BeginState(PreviousStateName);
			
		}
		else
			GotoState(PreviousStateName);
	}

	/** When finished with release go to the next state */
	simulated function OnStateAnimationEnd()
	{
		GotoState('Hold');
	}
}





simulated state Recovery
{
	/** Skip state and go straight to reload */
	simulated event BeginState(Name PreviousStateName)
	{
			if (!bRetIdle)
		{
			`logalways(" GO TO RELOAD "@bRetIdle@bRetIdleOriginal);
			bRetIdle = bRetIdleOriginal;
			GotoState('Reload');
		}
		else
		{
			bRetIdle = bRetIdleOriginal;
			super.BeginState(PreviousStateName);
		}
	}

	/** Play recovery animation */
	simulated function PlayStateAnimation()
	{
		local AnimationInfo Info; // custom AnimationInfo to pass
		Info = RecoveryAnimations[CurrentFireMode];
		//Info.fBlendOutTime = GetRealAnimLength(Info) - 0.05f;
		AOCOwner.ReplicateCompressedAnimation(Info, EWST_Recovery, CurrentFireMode);
	}
}



reliable client function Client_bLoaded()
{
	`logalways("Client_bLoaded");
	if(Role < ROLE_Authority || AOCOwner.bIsBot)
	{
		bloaded = true;
	}
}



simulated function bool HasAmmoRegen()
{
	return true;
}

simulated function TestbLoaded()
{

	if(AmmoCount > 0)
	{
		bloaded = true;
		AOCWepAttachment.bHasAmmo = true;
		AOCOwner.bWeaponHasAmmoLeft = true;
	}
}

///////////////////////////////////From_ILSModRangeWeapon///////////////////////////////////////

function bool CanThrowWeapon()
{
	return bCanThrowWeapon;
}

///////////////////////////////////From_ILSModRangeWeapon///////////////////////////////////////

////////////////////////////////////

function bool CanReflectProjectiles();
simulated function ReflectProjectile( class <LSModProjectile> ProjectileClass ) ;

/////////////////////////////////////////

DefaultProperties
{
	CurrentWeaponType = EWEP_Crossbow
	// set maximum ammo
	AmmoCount=15
	MaxAmmoCount=15
	AIRange=5000
	bRetIdle=true;
	bRetIdleOriginal=true
	AttachmentClass=class'LSModWeaponAttachment_Crossbow'
	InventoryAttachmentClass=class'AOCInventoryAttachment_Crossbow'
	PermanentAttachmentClass(0)=class'AOCInventoryAttachment_CrossbowQuiverAgatha'
	PermanentAttachmentClass(1)=class'AOCInventoryAttachment_CrossbowQuiverMason'
	bHaveShield=false
	WeaponIdleAnim(0)=3p_crossbow_idle01
	WeaponIdleAnim(1)=3p_crossbow_idle02

	CurrentGenWeaponType=EWT_Crossbow
	WeaponIdentifier="crossbow"

	bHold(0)=0

	FiringStatesArray(0)=IronSightWindup
	FiringStatesArray(1)=IronSightWindup

	bCanAttackWhileSprint=false
	bAiming=false
	bLoaded=true

	ProjectileSpawnLocation=ProjCrossbowPoint
	StrafeModify=0.75f
	bCanDodge=false

	WeaponProjectiles(0)=class'LSModProj_BlasterBolt'
	
	fSpread = 3500.0f
	bGoBackToHold=false
	
	fReasonableRefireRate=0.0f

	
	bCanThrowWeapon = false   ///////////////////////////////////From_ILSModRangeWeapon

	/* 
	 * Formerly in UDKNewWeapon.ini - [AOC.AOCWeapon_Crossbow]
	 */
	ConfigProjectileBaseDamage[0]=(Damage=0,InitialSpeed=0,MaxSpeed=0,AmmoCount=0,InitialGravityScale=0,Drag=0,PitchCorrection=0.0)
	ConfigProjectileBaseDamage[1]=(Damage=0,InitialSpeed=0,MaxSpeed=0,AmmoCount=0,InitialGravityScale=0,Drag=0,PitchCorrection=0.0)
	ConfigProjectileBaseDamage[2]=(Damage=0,InitialSpeed=0,MaxSpeed=0,AmmoCount=0,InitialGravityScale=0,Drag=0,PitchCorrection=0.0)
	ConfigProjectileBaseDamage[3]=(Damage=15,InitialSpeed=1600.0,MaxSpeed=2000.0,AmmoCount=3,InitialGravityScale=0.0001,Drag=0.0000001,PitchCorrection=0)
	ConfigProjectileBaseDamage[4]=(Damage=0,InitialSpeed=0,MaxSpeed=0,AmmoCount=0,InitialGravityScale=0,Drag=0.000001,PitchCorrection=60.0)
	ConfigProjectileBaseDamage[5]=(Damage=0,InitialSpeed=0,MaxSpeed=0,AmmoCount=0,InitialGravityScale=0,Drag=0.000001,PitchCorrection=60.0)
	iFeintStaminaCost=0
	WeaponFontSymbol="+"
	WeaponReach=100
	WeaponLargePortrait="SWF.weapon_select_crossbow"
	WeaponSmallPortrait="SWF.weapon_select_crossbow"
	HorizontalRotateSpeed=75000.0
	VerticalRotateSpeed=65000.0
	AttackHorizRotateSpeed=40000.0
	SprintAttackHorizRotateSpeed=20000.0
	SprintAttackVerticalRotateSpeed=20000.0
	BattleCryAnim=(AnimationName=3p_crossbow_battlecry,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	WindupAnimations(0)=(AnimationName=3p_crossbow_aim,ComboAnimation=,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false,bUseAltNode=true)
	ReleaseAnimations(0)=(AnimationName=3p_crossbow_aimrelease,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.crossbow_Attack_01',bFullBody=False,bCombo=False,bLoop=False,bForce=false,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false,bPlayOnWeapon=true,bUseAltNode=true,bAttachArrow=1)
	ReleaseAnimations(1)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.crossbow_Attack_01',bFullBody=False,bCombo=False,bLoop=False,bForce=false,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(2)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.Broadsword_Attack_03',bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.0,fAnimationLength=0.653,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(3)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.broadsword_sprint_attack',bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(4)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.broadsword_sprint_attack',bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(5)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=True,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(6)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(7)=(AnimationName=,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false)
	ReleaseAnimations(8)=(AnimationName=3p_crossbow_equipup,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.longbow_draw',bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.01,bLastAnimation=false)
	ReleaseAnimations(9)=(AnimationName=3p_crossbow_equipdown,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.longbow_sheath',bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.01,bLastAnimation=false)
	ReloadAnimations[0]=(AnimationName=3p_crossbow_reload,ComboAnimation=,AssociatedSoundCue=SoundCue'A_Combat_Locomotion.crossbow_Reload',bFullBody=true,bCombo=false,bLoop=false,bForce=false,fModifiedMovement=0.0,fAnimationLength=3,fBlendInTime=0.1,fBlendOutTime=0.20,bLastAnimation=true,bPlayOnWeapon=true,bAttachArrow=1)
	RecoveryAnimations(0)=(AnimationName=3p_crossbow_aimrecover,ComboAnimation=,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=False,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.5,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=false,bUseAltNode=true)
	HoldAnimations[0]=(AnimationName=3p_crossbow_aimidle,ComboAnimation=,AssociatedSoundCue=,bFullBody=False,bCombo=False,bLoop=True,bForce=false,UniqueShieldSound=none,fModifiedMovement=0.75,fAnimationLength=0.0,fBlendInTime=0.10,fBlendOutTime=0.10,bLastAnimation=false,bPlayOnWeapon=false,bUseAltNode=true)
	StateAnimations(0)=(AnimationName=3p_crossbow_Fhit01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.8,fBlendInTime=0.00,fBlendOutTime=0.08,bLastAnimation=true)
	StateAnimations(1)=(AnimationName=3p_crossbow_Fhit01,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.2,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	StateAnimations(2)=(AnimationName=3p_crossbow_Fhit01,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	StateAnimations(3)=(AnimationName=3p_crossbow_Fhit01,ComboAnimation=,AssociatedSoundCue=,bFullBody=true,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.9,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	StateAnimations(4)=(AnimationName=3p_crossbow_Fhit01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.08,bLastAnimation=false)
	TurnInfo(0)=(AnimationName=3p_crossbow_turnL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=true,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=false,bLowerBody=true)
	TurnInfo(1)=(AnimationName=3p_crossbow_turnR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=true,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.0,fBlendInTime=0.00,fBlendOutTime=0.0,bLastAnimation=false)
	DazedAnimations(0)=(AnimationName=3p_crossbow_dazedB01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(1)=(AnimationName=3p_crossbow_dazedR01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(2)=(AnimationName=3p_crossbow_dazedF01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(3)=(AnimationName=3p_crossbow_dazedL01,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(4)=(AnimationName=3p_crossbow_dazedBL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(5)=(AnimationName=3p_crossbow_dazedBR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(6)=(AnimationName=3p_crossbow_dazedFL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DazedAnimations(7)=(AnimationName=3p_crossbow_dazedFR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=1.1,fBlendInTime=0.00,fBlendOutTime=0.00,bLastAnimation=true)
	DirHitAnimation(0)=(AnimationName=ADD_3p_crossbow_hitFL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(1)=(AnimationName=ADD_3p_crossbow_hitFR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(2)=(AnimationName=ADD_3p_crossbow_hitBL,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	DirHitAnimation(3)=(AnimationName=ADD_3p_crossbow_hitBR,ComboAnimation=,AssociatedSoundCue=,bFullBody=false,bCombo=false,bLoop=false,bForce=false,UniqueShieldSound=none,fModifiedMovement=1.0,fAnimationLength=0.4,fBlendInTime=0.00,fBlendOutTime=0.1,bLastAnimation=false,bUseSlotSystem=true)
	// Range Weapon ConfigProjectileBaseDamage Info
	// 0 - Bodkin
	// 1 - Broadhead
	// 2 - Fire
	// 3 - Steel
	// 4 - Javelin
	// 5 - Default
	// NOTE: Javelin sprint damage bonus found in DefaultWeapon.ini
	// The ones that aren't used shouldn't need to be set but I do it just to be safe.
}
