class LSModPawn extends AOCPawn;

var int GeneratedNumber;
var bool bGeneratedNumber;

var bool bCanRegenerateAmmo;
var bool bIsRegeneratingAmmo;
var class<AOCRangeWeapon> RegeneratingWeaponClass;
var AOCRangeWeapon RegeneratingWeapon;

var class <LSModFamilyInfoCustom> FamilyInfoCustom;

var bool bCanJetUp;
////////////////////////

simulated function PostBeginPlay()
{

	super.PostBeginPlay();
	
	BeginRegen();

}

simulated function StartAmmoRegen()
{
	if(	bIsRegeneratingAmmo == true)
	{
		return;
	}
	SetTimer( 2.0f, true, 'RegenAmmo' );
	bIsRegeneratingAmmo = true;
}
	
simulated function RegenAmmo()	
{
	if( Role == ROLE_Authority || bIsBot)
	{
		AOCInventoryManager(InvManager).GiveUserAmmo(1, RegeneratingWeaponClass);
	}
	ILSModRangeWeapon(RegeneratingWeapon).Client_bLoaded();
	`logalways("bHasAMMO=="@AOCWeaponAttachment(CurrentWeaponAttachment).bHasAmmo);
	`logalways("bWeaponHasAmmoLeft=="@bWeaponHasAmmoLeft);
}

simulated event Tick( float DeltaTime )
{

	if (bCanRegenerateAmmo == true && bIsRegeneratingAmmo == false)
	{
	BeginRegen();

	}
	
	super.Tick( DeltaTime);
}

function BeginRegen()
{
	local AOCRangeWeapon W;
		

		ForEach InvManager.InventoryActors( class'AOCRangeWeapon', W )
		{
			`logalways("Iterating ILSModRangeWeapon(W)="@ILSModRangeWeapon(W));
			if ((ILSModRangeWeapon(W) != none) && ILSModRangeWeapon(W).HasAmmoRegen() == true)
			{
				bCanRegenerateAmmo = true;

				RegeneratingWeaponClass = W.Class;
				RegeneratingWeapon = W;

				StartAmmoRegen();
				
				`logalways("ILSModRangeWeapon(W)="@ILSModRangeWeapon(W));
				`logalways("bCanRegenerateAmmo="@bCanRegenerateAmmo)	;	
				`logalways("RegeneratingWeapon="@RegeneratingWeapon);
			}
		}
}

/////////////////////////////////////////////////////////DISABLE_RANGED_FLINCH///////////////////////////////////////////////////////

reliable server function AttackOtherPawn(HitInfo Info, string DamageString, optional bool bCheckParryOnly = false, optional bool bBoxParrySuccess, optional bool bHitShield = false, optional SwingTypeImpactSound LastHit = ESWINGSOUND_Slash, optional bool bQuickKick = false)
{
	local bool bParry;
	local float ActualDamage;
	local bool bSameTeam;
	local bool bFlinch;
	local IAOCAIListener AIList;
	local int i;
	local float Resistance;
	local float GenericDamage;
	local float HitForceMag;
	local PlayerReplicationInfo PRI;
	local bool bOnFire;
	local bool bPassiveBlock;
	local AOCWeaponAttachment HitActorWeaponAttachment;
	local class<AOCWeapon> UsedWeapon;

	if (PlayerReplicationInfo == none)
		PRI = Info.PRI;
	else
		PRI = PlayerReplicationInfo;

	if (!PerformAttackSSSC(Info) && WorldInfo.NetMode != NM_Standalone)
	{
		`logalways("SSSC Failure Notice By:"@PRI.PlayerName);
		`logalways( self@"performed an illegal move directed at"@Info.HitActor$".");
		`logalways("Attack Information:");
		`logalways("My Location:"@Location$"; Hit Location"@Info.HitLocation);
		`logalways("Attack Type:"@Info.AttackType@Info.DamageType);
		`logalways("Hit Damage:"@Info.HitDamage);
		`logalways("Hit Component:"@Info.HitComp);
		`logalways("Hit Bone:"@Info.BoneName);
		`logalways("Current Weapon State:"@Weapon.GetStateName());
		return;
	}

	if (Info.UsedWeapon == 0)
	{
		UsedWeapon = PrimaryWeapon;
	}
	else if (Info.UsedWeapon == 1)
	{
		UsedWeapon = SecondaryWeapon;
	}
	else
	{
		UsedWeapon = TertiaryWeapon;
	}

	HitActorWeaponAttachment = AOCWeaponAttachment(Info.HitActor.CurrentWeaponAttachment);

	bSameTeam = IsOnSameTeam(self, Info.HitActor);

	bParry = false;
	bFlinch = false;

	//if(AOCPlayerController(Info.HitActor.Controller).bBoxParrySystem)
	//{
		bParry = bBoxParrySuccess && (Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && class<AOCDmgType_Generic>(Info.DamageType) == none 
			&& Info.DamageType != class'AOCDmgType_SiegeWeapon';

		// Check if fists...fists can only blocks fists
		if (AOCWeapon_Fists(Info.HitActor.Weapon) != none && class<AOCDmgType_Fists>(Info.DamageType) == none)
			bParry = false;

		if(bParry)
		{
			DetectSuccessfulParry(Info, i, bCheckParryOnly, 0);
		}
	//}
	//else
	//{
	//	// check if the other pawn is parrying or active shielding
	//	if (!Info.HitActor.bPlayedDeath && (Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && class<AOCDmgType_Generic>(Info.DamageType) != none)
	//	{
	//		bParry = ParryDetectionBonusAngles(Info, bCheckParryOnly);
	//	}
	//}

	if (Info.DamageType.default.bIsProjectile)
		AOCPRI(PlayerReplicationInfo).NumHits += 1;
	
	bPassiveBlock = false;
	if ( bHitShield && Info.DamageType.default.bIsProjectile)
	{
		// Check for passive shield block
		bParry = true;
		Info.HitDamage = 0.0f;
		bPassiveBlock = !Info.HitActor.StateVariables.bIsActiveShielding;
	}

	if (bCheckParryOnly)
		return;
	`logalways("SUCCESSFUL ATTACK OTHER PAWN HERE");
	// Play hit sound
	AOCWeaponAttachment(CurrentWeaponAttachment).LastSwingType = LastHit;
	if(!bParry)
	{
		Info.HitActor.OnActionFailed(EACT_Block);
		Info.HitSound = AOCWeaponAttachment(CurrentWeaponAttachment).PlayHitPawnSound(Info.HitActor);
	}
	else        
		Info.HitSound = AOCWeaponAttachment(CurrentWeaponAttachment).PlayHitPawnSound(Info.HitActor, true);
	
	if (AOCMeleeWeapon(Info.Instigator.Weapon) != none)
	{
		AOCMeleeWeapon(Info.Instigator.Weapon).bHitPawn = true;
	}

	// Less damage for quick kick
	if (bQuickKick)
	{
		Info.HitDamage = 3;
	}

	ActualDamage = Info.HitDamage;
	GenericDamage = Info.HitDamage * Info.DamageType.default.DamageType[EDMG_Generic];
	ActualDamage -= GenericDamage; //Generic damage is unaffected by resistances etc.

	//Backstab damage for melee damage
	if (!CheckOtherPawnFacingMe(Info.HitActor) && !Info.DamageType.default.bIsProjectile)
		ActualDamage *= PawnFamily.default.fBackstabModifier;

	// Vanguard Aggression
	ActualDamage *= PawnFamily.default.fComboAggressionBonus ** Info.HitCombo;
	
	// make the other pawn take damage, the push back should be handled here too
	//Damage = HitDamage * LocationModifier * Resistances
	if (Info.UsedWeapon == 0 && AOCWeapon_Crossbow(Weapon) != none && Info.DamageType.default.bIsProjectile)
	{
		ActualDamage *= Info.HitActor.PawnFamily.default.CrossbowLocationModifiers[GetBoneLocation(Info.BoneName)];
	}
	else
	{
		ActualDamage *= (Info.DamageType.default.bIsProjectile ? Info.HitActor.PawnFamily.default.ProjectileLocationModifiers[GetBoneLocation(Info.BoneName)] : 
			Info.HitActor.PawnFamily.default.LocationModifiers[GetBoneLocation(Info.BoneName)]);
	}
		                                                           
	Resistance = 0;
	
	for( i = 0; i < ArrayCount(Info.DamageType.default.DamageType); i++)
	{
		Resistance += Info.DamageType.default.DamageType[i] * Info.HitActor.PawnFamily.default.DamageResistances[i];
	}
	
	ActualDamage *= Resistance;

	if (PawnFamily.default.FamilyFaction == Info.HitActor.PawnFamily.default.FamilyFaction)
		ActualDamage *= AOCGame(WorldInfo.Game).fTeamDamagePercent;
		
	ActualDamage += GenericDamage;
		
	//Damage calculations should be done now; round it to nearest whole number
	ActualDamage = float(Round(ActualDamage));

	`logalways("ATTACK OTHER PAWN"@ActualDamage);
	// Successful parry but stamina got too low!
	if (bParry && !bPassiveBlock && Info.HitActor.Stamina <= 0)
	{
		bFlinch = true;
		AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, true, AOCWeapon(Weapon).bTwoHander); 
	}
	// if the other pawn is currently attacking, we just conducted a counter-attack
	if (Info.AttackType == Attack_Shove && !bParry && !Info.HitActor.StateVariables.bIsSprintAttack)
	{
		// kick should activate flinch and take away 10 stamina
		if (!bSameTeam)
		{
			bFlinch = true;
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location),true, Info.HitActor.StateVariables.bIsActiveShielding && !bQuickKick, false);
		}
		Info.HitActor.ConsumeStamina(10);
		if (Info.HitActor.StateVariables.bIsActiveShielding && Info.HitActor.Stamina <= 0)
		{
			Info.HitActor.ConsumeStamina(-30.f);
		}
	}
	else if (Info.AttackType == Attack_Sprint && !bSameTeam)
	{
		bFlinch = true;
		AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, false, AOCWeapon(Weapon).bTwoHander); // sprint attack should daze
	}
	else if ((Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && !bSameTeam && !bParry)
	{
		bFlinch = true;
		AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), class<AOCDmgType_Generic>(Info.DamageType) != none
			, class<AOCDmgType_Generic>(Info.DamageType) != none, AOCWeapon(Weapon).bTwoHander);
	}
	else if ((Info.HitActor.Weapon.IsInState('Deflect') ||
		Info.HitActor.Weapon.IsInState('Feint') || (Info.HitActor.Weapon.IsInState('Windup') && AOCRangeWeapon(Info.HitActor.Weapon) == none) || Info.HitActor.Weapon.IsInState('Active') || Info.HitActor.Weapon.IsInState('Flinch')
		|| Info.HitActor.Weapon.IsInState('Transition') || Info.HitActor.StateVariables.bIsManualJumpDodge || (Info.HitActor.Weapon.IsInState('Recovery') && AOCWeapon(Info.HitActor.Weapon).GetFlinchAnimLength(true) >= WeaponAnimationTimeLeft()) ) 
		&& !bParry && !bSameTeam &&	!Info.HitActor.StateVariables.bIsSprintAttack && (LSModWeapon_Crossbow2(Weapon) == none))  ////disable proj flinch here
	{
		AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), false, false, AOCWeapon(Weapon).bTwoHander);
	}
	else if (AOCWeapon_JavelinThrow(Info.HitActor.Weapon) != none && Info.HitActor.Weapon.IsInState('WeaponEquipping'))
	{
		AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), false, false, AOCWeapon(Weapon).bTwoHander);
	}
	else if (!bParry && !bSameTeam) // cause the other pawn to play the hit animation
	{
		AOCWeapon(Info.HitActor.Weapon).ActivateHitAnim(Info.HitActor.GetHitDirection(Location, false, true), bSameTeam);
	}

	// GOD MODE - TODO: REMOVE
	if (Info.HitActor.bInfiniteHealth)
		ActualDamage = 0.0f;

	if (ActualDamage > 0.0f)
	{
		Info.HitActor.SetHitDebuff();
		LastAttackedBy = Info.Instigator;
		PauseHealthRegeneration();
		Info.HitActor.PauseHealthRegeneration();
		Info.HitActor.DisableSprint(true);	
		Info.HitActor.StartSprintRecovery();

		// play a PING sound if we hit a player when shooting
		if (Info.DamageType.default.bIsProjectile)
			PlayRangedHitSound();

		// Play sounds for everyone
		if (Info.HitActor.Health - ActualDamage > 0.0f)
			Info.HitActor.PlayHitSounds(ActualDamage, bFlinch);
		
		//PlayPitcherHitSound(ActualDamage, Info.HitActor.Location);
		if (AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).PC_SuccessfulHit();

		// Add to assist list if not in it already
		if (Info.HitActor.ContributingDamagers.Find(AOCPRI(PlayerReplicationInfo)) == INDEX_NONE && !bSameTeam)
			Info.HitActor.ContributingDamagers.AddItem(AOCPRI(PlayerReplicationInfo));

		Info.HitActor.LastPawnToHurtYou = Controller;

		//do not set the timer to clear the last pawn to attack value on a duel map...we want players to receive the kill even if the other player
		//  commits suicide by receiving falling damage or trap damage
		if( AOCDuel(WorldInfo.Game) == none || CDWDuel(WorldInfo.Game) == none )
			Info.HitActor.SetTimer(10.f, false, 'ClearLastPawnToAttack');

		if (Info.DamageType.default.bIsProjectile)
		{
			Info.HitActor.StruckByProjectile(self, UsedWeapon);
		}
	}

	
	// Notify Pawn that we hit
	if (AOCMeleeWeapon(Weapon) != none && Info.HitActor.Health - ActualDamage > 0.0f && Info.AttackType != Attack_Shove && Info.AttackType != Attack_Sprint && !bParry)
		AOCMeleeWeapon(Weapon).NotifyHitPawn();

	// pass attack info to be replicated to the clients
	Info.bParry = bParry;
	Info.DamageString = DamageString;
	if (Info.BoneName == 'b_Neck' && !Info.DamageType.default.bIsProjectile && Info.DamageType.default.bCanDecap && Info.AttackType != Attack_Stab)
		Info.DamageString $= "3";
	else if ((Info.BoneName == 'b_Neck' || Info.BoneName == 'b_Head') && Info.DamageType.default.bIsProjectile)
	{
		Info.DamageString $= "4";

		if ( AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).NotifyAchievementHeadshot();
	}
	else if ((Info.BoneName == 'b_spine_A' || Info.BoneName == 'b_spine_B' || Info.BoneName == 'b_spine_C' || Info.BoneName == 'b_spine_D') && Info.DamageType.default.bIsProjectile)
	{
		if ( AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).NotifyCupidProgress();
	}
	Info.HitActor.ReplicatedHitInfo = Info;
	Info.HitDamage = ActualDamage;

	Info.HitForce *= int(PawnState != ESTATE_PUSH && PawnState != ESTATE_BATTERING);
	//`log("DAMAGE FORCE:"@Info.HitForce);
	Info.HitForce *= int(!bFlinch);
	HitForceMag = VSize( Info.HitForce );
	Info.HitForce.Z = 0.f;
	Info.HitForce = Normal(Info.HitForce) * HitForceMag;

	// Stat Tracking For Damage
	// TODO: Also sort by weapon
	if (PRI != none)
	{
		if (!bSameTeam)
		{
			AOCPRI(PRI).EnemyDamageDealt += ActualDamage;
		}
		else
		{
			if (Info.HitActor.PawnInfo.myFamily.default.ClassReference != ECLASS_Peasant)
			{
				AOCPRI(PRI).TeamDamageDealt += ActualDamage;
				AOCPlayerController(Controller).TeamDamageDealt += ActualDamage;
			}
		}
		
		AOCPRI(PRI).bForceNetUpdate = TRUE;
	}

	if (Info.HitActor.PlayerReplicationInfo != none)
	{
		AOCPRI(Info.HitActor.PlayerReplicationInfo).DamageTaken += ActualDamage;
		AOCPRI(Info.HitActor.PlayerReplicationInfo).bForceNetUpdate = TRUE;
	}

	`logalways("ATTACK OTHER PAWN"@Controller@CurrentSiegeWeapon.Controller);
	bOnFire = Info.HitActor.bIsBurning;
	
	Info.HitActor.TakeDamage(ActualDamage, Controller != none ? Controller : CurrentSiegeWeapon.Controller, Info.HitLocation, Info.HitForce, Info.DamageType);

	if ((Info.HitActor == none || Info.HitActor.Health <= 0) && WorldInfo.NetMode == NM_DedicatedServer)
	{
		// Make sure this wasn't a team kill
		if (AOCPlayerController(Controller).StatWrapper != none
			&& !bSameTeam
			&& Info.UsedWeapon < 2)
		{
			AOCPlayerController(Controller).StatWrapper.IncrementKillStats(
				Info.UsedWeapon == 0 ? PrimaryWeapon : SecondaryWeapon, 
				PawnFamily,
				Info.HitActor.PawnFamily,
				class<AOCWeapon>(HitActorWeaponAttachment.WeaponClass)
			);
		}

		// Do another check for a headshot here
		if (Info.BoneName == 'b_Neck' && !Info.DamageType.default.bIsProjectile && Info.DamageType.default.bCanDecap && Info.AttackType != Attack_Stab)
		{
			// Award rotiserie chef achievement on client
			if (AOCPlayerController(Controller) != none && bOnFire)
			{
				AOCPlayerController(Controller).UnlockRotisserieChef();
			}

			// Notify decap
			AOCPlayerController(Controller).NotifyAchievementDecap();
		}

		// Check if fists
		if (class<AOCDmgType_Fists>(Info.DamageType) != none)
		{
			if (AOCPlayerController(Controller) != none)
			{
				AOCPlayerController(Controller).NotifyFistofFuryProgress();
			}
		}

		Info.HitActor.ReplicatedHitInfo.bWasKilled = true;
	}

	foreach AICombatInterests(AIList)
	{
		AIList.NotifyPawnPerformSuccessfulAttack(self);
	}
	
	foreach Info.HitActor.AICombatInterests(AIList)
	{
		if (!bParry)
			AIList.NotifyPawnReceiveHit(Info.HitActor,self);
		else
			AIList.NotifyPawnSuccessBlock(Info.HitActor, self);
	}

	// manually do the replication if we're on the standalone
	if (WorldInfo.NetMode == NM_Standalone)
	{
		Info.HitActor.HandlePawnGetHit();
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////FROM_CDW//////////////////////////////////////////////////


simulated function bool DetectSuccessfulParry(out HitInfo Info, out int bParry, bool bCheckParryOnly, int ParryLR)
{
	local int StaminaDamage;
	
	local ILSModMeleeWeapon ILSMeleeWeapon;
	
	local class <LSModProjectile> LSProjClass;
	
	LSProjClass = class <LSModProjectile> (Info.ProjType);
	ILSMeleeWeapon = ILSModMeleeWeapon((Info.HitActor).weapon);
	
	`logalways("PROJTYPE=="@Info.ProjType);
	
	`logalways("LSModPROJECTILE_EXISTS=="@LSProjClass);
	
	`logalways("DETECT:"@Info.DamageType@Info.HitActor.StateVariables.bIsActiveShielding@Info.HitComp@Info.HitActor.ShieldMesh@Info.HitActor.Mesh);
	if (LSProjClass == none && (Info.DamageType.default.bIsProjectile && (!Info.HitActor.StateVariables.bIsActiveShielding || Info.HitComp != Info.HitActor.ShieldMesh || Info.HitComp != Info.HitActor.BackShieldMesh)))          /////////////////modified
		return false;
	
	if (LSProjClass != none && !LSProjClass.default.bCanBeParried && (Info.DamageType.default.bIsProjectile && (!Info.HitActor.StateVariables.bIsActiveShielding || Info.HitComp != Info.HitActor.ShieldMesh || Info.HitComp != Info.HitActor.BackShieldMesh)))	
		return false;
		
	bParry = 1;
	StaminaDamage = 0;
	
	// make the weapon [and thus the pawn] go into a deflect state
	if ( !Info.DamageType.default.bIsProjectile )
	{
		AOCWeapon(Weapon).ActivateDeflect(Info.HitActor.StateVariables.bIsParrying);
		AOCWeaponAttachment( CurrentWeaponAttachment ).PlayParriedSound();
		
		DisableSprint(true);
		StartSprintRecovery();
	}	
	
	// opponent has a successful parry
	AOCWeapon(Info.HitActor.Weapon).NotifySuccessfulParry(Info.AttackType, ParryLR);
	
	if(Info.HitActor.StateVariables.bIsActiveShielding)
	{
		AOCWeaponAttachment( Info.HitActor.CurrentWeaponAttachment ).PlayParrySound(true);
		
		// do a stamina loss only if it's a melee attack
		if (!Info.DamageType.default.bIsProjectile)
		{
			StaminaDamage = Info.HitActor.ShieldClass.NewShield.static.CalculateParryDamage(Info.HitDamage);
		
			if (!Info.HitActor.HasEnoughStamina(StaminaDamage))
			{
				StaminaDamage = Info.HitActor.Stamina; 
				Info.HitActor.ConsumeStamina(StaminaDamage);
				// Regain 30 stamina
				Info.HitActor.ConsumeStamina(-30.f);
				AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, true, AOCWeapon(Weapon).bTwoHander);
				Info.HitDamage = 0.0f;
				
				AOCGame(WorldInfo.Game).DisplayDebugDamage(Info.HitActor, self, EDAM_Stamina, StaminaDamage);
				return true;
			}
			
			Info.HitActor.ConsumeStamina(StaminaDamage);
		}
		
		//Parry means health damage is completely negated
		Info.HitDamage = 0.0f;
		
		AOCGame(WorldInfo.Game).DisplayDebugDamage(Info.HitActor, self, EDAM_Stamina, StaminaDamage);
		
		// flinch if it's a kick
		if (Info.AttackType == Attack_Shove)
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, true, false);
	}
	else if(Info.HitActor.StateVariables.bIsParrying)
	{
		AOCWeaponAttachment( Info.HitActor.CurrentWeaponAttachment ).PlayParrySound(false);
		
		StaminaDamage = AOCWeapon(Info.HitActor.Weapon).CalculateParryDamage(AOCWeapon(Info.Instigator.Weapon), Info.AttackType);
			
		if (!Info.HitActor.HasEnoughStamina(StaminaDamage))
		{
			StaminaDamage = Info.HitActor.Stamina;
			Info.HitActor.ConsumeStamina(StaminaDamage);
			// Regain 30 stamina
			Info.HitActor.ConsumeStamina(-30.f);
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, true, AOCWeapon(Weapon).bTwoHander);
			Info.HitDamage = 0.0f;
			return true;
		}
		`logalways("ILSMeleeWeapon=="@ILSMeleeWeapon);
		if(LSProjClass != none && (LSProjClass.default.bCanBeReflected == true) && (ILSMeleeWeapon != none) && (ILSMeleeWeapon.CanReflectProjectiles() == true))
		{
			`logalways("REFLECTING=="@Info.ProjType);
			ILSMeleeWeapon.FireReflected( LSProjClass);          ///////////////////////////Projectile Reflecting
		}
		
		AOCGame(WorldInfo.Game).DisplayDebugDamage(Info.HitActor, self, EDAM_Stamina, StaminaDamage);
		
		Info.HitActor.ConsumeStamina(StaminaDamage);
		
		//Parry means health damage is completely negated
		Info.HitDamage = 0.0f;
	}

	return true;

}

simulated function bool CanPickUpThrownWeapon(class <AOCWeapon> WeaponClass)
{
	local AOCWeapon Weap;
	Weap = AOCInventoryManager(InvManager).GetWeapon(WeaponClass);
	if (Weap != none)
	{
		if (ILSModRangeWeapon(WeaponClass).CanThrowWeapon() && Weap.AmmoCount != Weap.MaxAmmoCount)
		{
			return true;
		}
	}
	return false;
}

reliable client function ClientPickUpThrownWeapon(class <AOCWeapon> WeaponClass, bool bDualWield, bool bLoaded)
{
/*	local AOCWeapon Weap;
	Weap = AOCInventoryManager(InvManager).GetWeapon(WeaponClass);

	if (WeaponClass.default.bCanThrowWeapon)
	{
		if (bDualWield)
		{
			PickUpDualWeapon();
		}

		if (AOCRangeWeapon(Weap) != none)
		{
			AOCRangeWeapon(Weap).bLoaded = bLoaded;
		}

		Weap.bWeaponThrown = false;
		Weap.bCanSwitchToWeapon = true;
	}	*/
}



reliable server function PickUpThrownWeapon(class <AOCWeapon> WeaponClass, int StickyId)
{
/*	local AOCWeapon WeaponPickUp;
	local AOCWeapon ShieldWeapon;
	local bool bLoaded;
	local bool bPickUpDual;

	WeaponPickUp = AOCInventoryManager(InvManager).GetWeapon(WeaponClass);
	if (WeaponPickUp != none)
	{
		if (WeaponClass.default.bCanThrowWeapon)
		{
			if (CanPickUpThrownWeapon(WeaponClass))
			{
				// Handle thrown shields
				if (class<AOCWeapon_Shield>(WeaponClass) != None)
				{
					ForEach InvManager.InventoryActors( class'AOCWeapon', ShieldWeapon )
					{
						if (ShieldWeapon.bHaveShield)
						{
							ShieldWeapon.AllowedShieldClass = class'CDWWeapon_VikingShield'.default.Shield;
						}
					}

					// Attach shield to back
					WeaponPickUp.bWeaponThrown = false;
					AttachShieldToBack(true);
					HandleReplicatedInventoryAttachment();
				}

				WeaponPickUp.bWeaponThrown = false;
				WeaponPickUp.bCanSwitchToWeapon = true;
				WeaponPickUp.AddAmmo(1);

				// handle dual wield
				if (AOCMeleeWeapon(WeaponPickUp).bCanDualWield && HasAmmoForDualWield())
				{
					PickUpDualWeapon();
					bPickUpDual = true;
				}
				
				if (CDWWeapon_Pistole(WeaponPickUp) != none)
				{
					CDWWeapon_Pistole(WeaponPickUp).AmmoCount = CDWWeapon_Pistole(WeaponPickUp).PreviousAmmoCount;
					CDWWeapon_Pistole(WeaponPickUp).bLoaded = CDWWeapon_Pistole(WeaponPickUp).bPreviousLoaded;
				}

				bLoaded = AOCRangeWeapon(WeaponPickUp).bLoaded;
		
				AOCPlayerController(Controller).NotifyPickupWeapon(WeaponClass);

				if (WorldInfo.NetMode == NM_DedicatedServer)
				{
					ClientPickUpThrownWeapon(WeaponClass, bPickUpDual, bLoaded);
				}

				KillStickyProjectile = StickyId;
			}
		}
	}*/
}


/////////////////////////////////////////////VVVVVVV//////////////////Setting_pawn_stats_from_custom_FamilyInfo////////VVVVVVV//////////////////////////////////

simulated function AOCSetCharacterClassFromInfo(AOCFamilyInfo Info)
{
	local float TempMaxFallSpeed;
	super.AOCSetCharacterClassFromInfo( Info );
	

	TempMaxFallSpeed = FamilyInfoCustom.static.GetCustomClassFloatStatus( PawnFamily.default.ClassReference , "MaxFallSpeed" );

	if (TempMaxFallSpeed !=0.0)
		MaxFallSpeed = TempMaxFallSpeed;
		
//	bCanJetUp = FamilyInfoCustom.static.GetCustomClassBoolStatus( PawnFamily.default.ClassReference , "bCanJetUp" );				/////////TEMP_DISABLED
}


/////////////////////////////////////////////////////////////////////_V__JETPACK_/_LEVITATION_FUNCTIONS_V_/////////////////////////////////////////////////////////////////////
/*
simulated function JetUp()
{
	if( Stamina > 15.0 && !bIsCrouching && (Physics == PHYS_Falling))
	{
		Velocity.Z += 800;
		ConsumeStamina( 15.0 );

	}
}


function bool DoJump( bool bUpdating )
{
	if(bCanJetUp)
	{
	JetUp();
	}
	
	super.DoJump(bUpdating);

}

*/


////////////////////////////////////////////////////FIxing_proj_reflection////////////////////////////////////////////////////////VVVVVVVVVVVVVVVVVVVVVVVVV
function bool PerformAttackSSSC(HitInfo Info)
{
	local float UsablePingTime;
	local int LowerBoundIndx;
	local float MinimumProximityDistance;
	local float MaximumProximityThreshold;
	local Vector TmpVect1, TmpVect2;
	local bool bFindToss;
	local PlayerReplicationInfo PRI;
	local Vector AttackVect, DefenderVect, AttackVectNullZ, DefenderVectNullZ;
	local Rotator AttackerRot, DefenderRot;
	local float fAngleCheck, UpperTimeStamp;
	local Vector UpperBound;
	local Rotator UpperBoundRot;
	local float ProjSpeed;

	if (Info.Instigator.PlayerReplicationInfo == none)
		PRI = Info.PRI;
	else
		PRI = Info.Instigator.PlayerReplicationInfo;

	// Ping time needed to see which SSSC elements can actually potentially be used
	UsablePingTime = GetSSSCPingTolerance(PRI.Ping);
	MinimumProximityDistance = 100000.f;

	// Melee Damage Check
	if (!Info.DamageType.default.bIsProjectile && class<AOCDmgType_SiegeWeapon>(Info.DamageType) == none)
	{
		LowerBoundIndx = GetLowerBoundSSSCIndex(WorldInfo.TimeSeconds, UsablePingTime);

		if (LowerBoundIndx == -1)
			return true;

		// Proximity Check
		// Make sure distance is less than: Weapon Length * 1.5f + Collision Cylinder Radius. 1.5f is meant to give the player some leniency.
		// Grab player location
		// Then do the proximity check on that distance
		MinimumProximityDistance = FMin(VSize(Location - Info.HitActor.Mesh.GetBoneLocation(Info.BoneName) ), VSize(Location-Info.HitActor.Location));
		
		// Calculate maximum allowed distance
		CurrentWeaponAttachment.Mesh.GetSocketWorldLocationAndRotation('TraceStart', TmpVect1);
		if (AOCWeaponAttachment(CurrentWeaponAttachment).WeaponNumTracers == 1)
			CurrentWeaponAttachment.Mesh.GetSocketWorldLocationAndRotation('TraceEnd', TmpVect2);
		else
			CurrentWeaponAttachment.Mesh.GetSocketWorldLocationAndRotation(name("TraceEnd"$string(AOCWeaponAttachment(CurrentWeaponAttachment).WeaponNumTracers-1)), TmpVect2);
		MaximumProximityThreshold = VSize(TmpVect1 - TmpVect2) * 1.5f + CylinderComponent.CollisionRadius * 1.5f + 30.f + GroundSpeed * UsablePingTime * 2.f;
		MaximumProximityThreshold *= 1.4f; // This is pretty generous. Shouldn't cause too many issues...atleast they won't hit across the map

		if (MinimumProximityDistance > MaximumProximityThreshold)
		{
			return false;
		}

		// Damage Check
		// Make sure the damage value passed in matches the damage value stored on the server
		if (AOCWeaponAttachment(CurrentWeaponAttachment).AttackTypeInfo[Info.AttackType].fBaseDamage < Info.HitDamage)
		{
			return false;
		}
	}
	// Range Damage Check
	else if (Info.DamageType.default.bIsProjectile)
	{
		// First get attackers initial position and rotation at the time of release
		LowerBoundIndx = GetLowerBoundSSSCIndex(WorldInfo.TimeSeconds - Info.TimeVar, UsablePingTime);
		if (LowerBoundIndx == -1)
			return true;
		AttackerRot = SSSCMemoryInfo[LowerBoundIndx].Rotation;
		AttackVect = SSSCMemoryInfo[LowerBoundIndx].Position;
		if (LowerBoundIndx + 1 >= SSSCMemoryInfo.Length)
		{
			UpperBound = Location;
			UpperBoundRot = Rotation;
			UpperTimeStamp = WorldInfo.TimeSeconds;
		}
		else
		{
			UpperBound = SSSCMemoryInfo[LowerBoundIndx+1].Position;
			UpperBoundRot = SSSCMemoryInfo[LowerBoundIndx+1].Rotation;
			UpperTimeStamp = SSSCMemoryInfo[LowerBoundIndx+1].TimeStamp;
		}
		AttackVect = SSSC_CalcInterpVector(AttackVect, UPperBound, SSSCMemoryInfo[LowerBoundIndx].TimeStamp, UpperTimeStamp, WorldInfo.TimeSeconds - Info.TimeVar - UsablePingTime);
		AttackerRot = SSSC_CalcInterpRotator(AttackerRot, UpperBoundRot, SSSCMemoryInfo[LowerBoundIndx].TimeStamp, UpperTimeStamp, WorldInfo.TimeSeconds - Info.TimeVar - UsablePingTime);
		AttackVectNullZ = AttackVect;
		AttackVectNullZ.Z = 0.f;

		// Then get the person getting hit's position and rotation
		LowerBoundIndx = Info.HitActor.GetLowerBoundSSSCIndex(WorldInfo.TimeSeconds, Info.HitActor.GetSSSCPingTolerance(Info.HitActor.PlayerReplicationInfo.Ping));
		DefenderRot = Info.HitActor.SSSCMemoryInfo[LowerBoundIndx].Rotation;
		DefenderVect = Info.HitActor.SSSCMemoryInfo[LowerBoundIndx].Position + Normal(Vector(DefenderRot)) * 36.f;
		if (LowerBoundIndx + 1 >= Info.HitActor.SSSCMemoryInfo.Length)
		{
			UpperBound = Info.HitActor.Location;
			UpperBoundRot = Info.HitActor.Rotation;
			UpperTimeStamp = WorldInfo.TimeSeconds;
		}
		else
		{
			UpperBound = Info.HitActor.SSSCMemoryInfo[LowerBoundIndx+1].Position;
			UpperBoundRot = Info.HitActor.SSSCMemoryInfo[LowerBoundIndx+1].Rotation;
			UpperTimeStamp = Info.HitActor.SSSCMemoryInfo[LowerBoundIndx+1].TimeStamp;
		}
		DefenderVect = Info.HitActor.SSSC_CalcInterpVector(DefenderVect, UPperBound, Info.HitActor.SSSCMemoryInfo[LowerBoundIndx].TimeStamp, UpperTimeStamp, WorldInfo.TimeSeconds - Info.HitActor.GetSSSCPingTolerance(Info.HitActor.PlayerReplicationInfo.Ping));
		DefenderRot = Info.HitActor.SSSC_CalcInterpRotator(DefenderRot, UpperBoundRot, Info.HitActor.SSSCMemoryInfo[LowerBoundIndx].TimeStamp, UpperTimeStamp, WorldInfo.TimeSeconds - Info.HitActor.GetSSSCPingTolerance(Info.HitActor.PlayerReplicationInfo.Ping));
		DefenderVectNullZ = DefenderVect;
		DefenderVectNullZ.Z = 0.f;
		if (LowerBoundIndx == -1)
			return true;

		if (Weapon == none || AOCRangeWeapon(Weapon) == none) 
			ProjSpeed = 7000.f;
		if(ILSModMeleeWeapon(Weapon) != none)
		{
			`logalways("REFLECTING");
//			ProjSpeed = ILSModMeleeWeapon(Weapon).ConfigProjectileBaseDamage[ILSModMeleeWeapon(Weapon).GetProjectileType()].MaxSpeed;
			ProjSpeed = 7000.f;
		}
		if(AOCRangeWeapon(Weapon) != none)
		{
			ProjSpeed = AOCRangeWeapon(Weapon).ConfigProjectileBaseDamage[AOCRangeWeapon(Weapon).GetProjectileType()].MaxSpeed;
		}

		bFindToss = SuggestTossVelocity(TmpVect1, DefenderVect, AttackVect, ProjSpeed, 0.f);

		if (bFindToss)
			return true; // Miraculoously SuggestTossVeloctiy worked...lucky guy Haha.
		else
		{
			// First we should definitely be facing the other player based on AttackerRot and DefenderVect-AttackVect
			fAngleCheck = ACos(Normal(Vector(AttackerRot)) dot Normal(DefenderVectNullZ-AttackVectNullZ));
			if (fAngleCheck > SSSC_MAX_VIEW_DIFFERENCE_RADS)
			{
				return false;
			}

			// Check with toss velocity
			TmpVect1.Z = 0.f;
			fAngleCheck = ACos(Normal(Vector(AttackerRot)) dot Normal(TmpVect1));
			if (fAngleCheck > SSSC_MAX_VIEW_DIFFERENCE_RADS)
			{
				return false;
			}

		}
	}
	return true;
}


//////////////////////////////////////////WEAPON_TRAILS/////////////////////////////////////////////////////////

simulated function HandlePawnAnim(bool bReplicated, optional AnimationInfo ClientAnimInfo)
{
	super.HandlePawnAnim(bReplicated, ClientAnimInfo);
	//I'm going to use the attach arrow bool to activate/deactivate the PS
	if (AnimationToPlay != '' && AnimationToPlay != 'None')
	{
		if (ILSModWeaponAttachment(CurrentWeaponAttachment) !=none)
		{
			if (ClientAnimInfo.bAttachArrow == 1)
				ILSModWeaponAttachment(CurrentWeaponAttachment).StartRibbons();
			else
				ILSModWeaponAttachment(CurrentWeaponAttachment).KillRibbons();
		}
	}
}


defaultproperties
{
 GeneratedNumber = 2
 bGeneratedNumber = false

 FamilyInfoCustom = class 'LSModFamilyInfoCustom'
 
 	Begin Object Name=OwnerSkeletalMeshComponent
		bForceUpdateAttachmentsInTick=true
	End Object
 
  	Begin Object Name=WPawnSkeletalMeshComponent
		bForceUpdateAttachmentsInTick=true
	End Object
 
 bCanJetUp = false
}