class LSModProj_ThrownMAUL extends LSModProjectile;

simulated function AttachToWorld(vector HitLoc, optional Actor HitActor = none, optional name ImpactSoundName = 'None')
{
	local ProjectileBaseInfo BaseInfo;
	local vector NewLoc;
	
	
	if(StickyMesh != none)
	{
		return;
	}
	
	NewLoc = HitLoc - Normal(HitLoc - PrevLocation) * fProjectileAttachCompensation;
	BaseInfo.Other = HitActor;
	BaseInfo.Location = NewLoc;
	BaseInfo.Rotation = Rotator(Location-PrevLocation) + InitialRotation;
	BaseInfo.bHitWorld = true;
	BaseInfo.ImpactSound = ImpactSoundName;
	BaseInfo.StickyId = OwnerPawn.GetStickyId(Self);

	RepBaseInfo = BaseInfo;	
	
	if (OwnerPawn.Role != ROLE_Authority && ThisController != none)
	{
		if(Role == ROLE_Authority)
		{
			ThisController.S_ImmediateProjectileShutdown(ProjIdent, BaseInfo);
		}
		else if(OwnerPawn.IsLocallyControlled())
		{
			return; //don't attach, the local projectile will do the attaching!	
		}
	}
	
	if(Worldinfo.NetMode == NM_DedicatedServer)
	{
		bNetDirty = true;
		Shutdown();
		return;
	}
	
	//`log("ATTACH TO WORLD"@NewLoc@HitLoc@HitActor@GetScriptTrace());
	if(WorldInfo.GetDetailMode() != DM_Low || bCanPickupProj)
	{
		if (bSpawnSticky)
		{
			StickyMesh = spawn( class'AOCStickyProjectile', self , , NewLoc, BaseInfo.Rotation );
			StickyMesh.SetStaticMesh( Mesh.StaticMesh );
			StickyMesh.SetRotation(Rotator(Location-PrevLocation));
			StickyMesh.CorrespondingWeapon = LaunchingWeapon;
			StickyMesh.bCanPickup = bCanPickupProj;
			StickyMesh.SetCollision(bCanPickupProj);
			StickyMesh.Faction = OwnerFaction;
			StickyMesh.SetBase(none);
			StickyMesh.SetHardAttach( true );
			StickyMesh.SetBase( HitActor);
			StickYMesh.SetPhysics( PHYS_None );
			StickyMesh.StartDestructionTimer(true);
			StickyMesh.StickyId = RepBaseInfo.StickyId;

			if(AOCStaticMeshActor_PaviseShield(HitActor) != none)
			{
				AOCStaticMeshActor_PaviseShield(HitActor).AttachedStickies.AddItem(StickyMesh);
			}
		}
		else
			DWSpawnStickyAlternate(NewLoc);
	}
	
	Shutdown();
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'WP_hbl_Maul.SM_Maul'
		Scale=1.0
		Rotation=(Pitch=0,Yaw=0,Roll=16384)
	End Object

	ProjExplosionTemplate=none
	ProjFlightTemplate=ParticleSystem'CHV_Particles_01.Particles.P_ArrowTrail'

	speed=3000.0
	MaxSpeed=6000.0
	TerminalVelocity=6000
	Damage=150.0f
	MomentumTransfer=500
	LifeSpan=10.0
	bCollideWorld=true
	bBounce=false
	Physics=PHYS_Falling
	CheckRadius=36.0
	CustomGravityScaling=1.0

	MyDamageType=class'AOCDmgType_PierceBluntProj'
	
	AmbientSound=SoundCue'A_Projectile_Flight.Flight_Axe'
	ImpactSounds= {(
		Light=SoundCue'A_Impacts_Missile.Ballista_Light',
		Medium=SoundCue'A_Impacts_Missile.Ballista_Medium',
		Heavy=SoundCue'A_Impacts_Missile.Ballista_Heavy',
		Stone=SoundCue'A_Phys_Mat_Impacts.Ballista_Stone',
		Dirt=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Wood=SoundCue'A_Phys_Mat_Impacts.Ballista_Wood',
		Gravel=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Foliage=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Sand=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Water=SoundCue'A_Phys_Mat_Impacts.Ballista_water',
		ShallowWater=SoundCue'A_Phys_Mat_Impacts.Ballista_water',
		Metal=SoundCue'A_Phys_Mat_Impacts.Ballista_Metal',
		Snow=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Ice=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Mud=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt',
		Tile=SoundCue'A_Phys_Mat_Impacts.Ballista_Dirt')
	}
	ProjBlockedSound=SoundCue'A_Phys_Mat_Impacts.Ballista_Wood'

	bNetTemporary=False
	bWaitForEffects=false
	
	YawRate = 0.0f
	PitchRate = -200000.0f
	RollRate = 0.0f
//	fProjectileAttachCompensation=2.0f
	fProjectileAttachCompensation=80.0f
	
	bOverrideDefaultExplosionDeffect=true
	PhysBasedParticleExplosions={(
		Stone=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Dirt=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Gravel=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Foliage=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Sand=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Water=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_water',
		Metal=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Snow=ParticleSystem'CHV_EnvironmentParticles.Snow.P_LargeImpact_Snow',
		Wood=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Ice=ParticleSystem'CHV_EnvironmentParticles.Snow.P_LargeImpact_Snow',
		Mud=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world',
		Tile=ParticleSystem'CHV_EnvironmentParticles.blist.P_BallistaImpact_world')
	}
	
	
	bCanBeParried=true 									//////////////////FROM_CDW
	bUseLongTracers=true
	
}
