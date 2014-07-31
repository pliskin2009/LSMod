/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
*
* Original Author: Richard Pragnell
*
* Rock projectile for AOCSWPCatapult.
*/

class LSModProj_Grenade3 extends AOCProjectile;


simulated event Tick( float DeltaTime)
{
	// Skip AOCProjectile Tick
	super(UTProjectile).Tick(DeltaTime);
}

simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{
	// Skip AOCProjectile HitWall
	super(UTProjectile).HitWall(HitNormal, Wall, WallComp);
}

//* Reimplemened enabling projectile explosion to damage InterpActors */
simulated function bool HurtRadius( float DamageAmount,
								    float InDamageRadius,
									class<DamageType> DamageType,
									float Momentum,
									vector HurtOrigin,
									optional actor IgnoredActor,
									optional Controller InstigatedByController = Instigator != None ? Instigator.Controller : None,
									optional bool bDoFullDamage
									)
{
	local bool bCausedDamage;
	local Actor	Victim;
	local TraceHitInfo HitInfo;
	local StaticMeshComponent HitComponent;
	local KActorFromStatic NewKActor;
	local bool bCountHit;
	bCountHit = false;

	// Prevent HurtRadius() from being reentrant.
	if (bHurtEntry)
		return false;

	bHurtEntry = true;
	bCausedDamage = false;
	if (InstigatedByController == None)
	{
		InstigatedByController = InstigatorController;
	}

	// if ImpactedActor is set, we actually want to give it full damage, and then let him be ignored by super.HurtRadius()
	if ((ImpactedActor != None) && (ImpactedActor != self))
	{
		if (IAOCActor(ImpactedActor) == none)
		{
			if (AOCPawn(ImpactedActor)!= none)
			{
				AOCPawn(ImpactedActor).ReplicatedHitInfo.HitLocation = ImpactedActor.Location;
				AOCPawn(ImpactedActor).ReplicatedHitInfo.DamageType = class<AOCDamageType>(MyDamageType);
				AOCPawn(ImpactedActor).ReplicatedHitInfo.BoneName = 'b_spine_C';
				AOCPawn(ImpactedActor).ReplicatedHitInfo.DamageString = "I";

				if (!bCountHit)
				{
					bCountHit = true;
					AOCPRI(Instigator.PlayerReplicationInfo).NumHits += 1;
				}
			}
			ImpactedActor.TakeRadiusDamage(InstigatedByController, DamageAmount, InDamageRadius, MyDamageType, Momentum, HurtOrigin, true, self);
		}
		else
		{
			IAOCActor(ImpactedActor).AOCTakeDamage(DamageAmount, HurtOrigin, Vect(0.f, 0.f, 0.f), OwnerPawn, MyDamageType);
		}
		bCausedDamage = ImpactedActor.bProjTarget;
	}

	foreach VisibleCollidingActors(class'Actor', Victim, DamageRadius, HurtOrigin, true,,false,, HitInfo)
	{
		if (Victim.bWorldGeometry)
		{
			// check if it can become dynamic
			// @TODO note that if using StaticMeshCollectionActor (e.g. on Consoles), only one component is returned.  Would need to do additional octree radius check to find more components, if desired
			HitComponent = StaticMeshComponent(HitInfo.HitComponent);
			if ((HitComponent != None) && HitComponent.CanBecomeDynamic())
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitComponent);
				if (NewKActor != None)
				{
					Victim = NewKActor;
				}
			}
		}
		// bit haxy here, need InterpActors to recieve damage
		if ((Victim != self) && (Victim != ImpactedActor) && (Victim.bCanBeDamaged || Victim.bProjTarget || InterpActor(Victim) != none))
		{			
			if (AOCPawn(Victim)!= none)
			{
				AOCPawn(Victim).ReplicatedHitInfo.HitLocation = Victim.Location;
				AOCPawn(Victim).ReplicatedHitInfo.DamageType = class<AOCDamageType>(MyDamageType);
				AOCPawn(Victim).ReplicatedHitInfo.BoneName = 'b_spine_C';
				AOCPawn(Victim).ReplicatedHitInfo.DamageString = "I";

				if (!bCountHit)
				{
					bCountHit = true;
					AOCPRI(Instigator.PlayerReplicationInfo).NumHits += 1;
				}
			}
			Victim.TakeRadiusDamage(InstigatedByController, DamageAmount, DamageRadius, DamageType, Momentum, HurtOrigin, bDoFullDamage, self);
			bCausedDamage = bCausedDamage || Victim.bProjTarget;
			
			if (AOCPawn(Victim) != none)
			{
				// Place HurtOrigin a little below the actual impact postion so players get blasted upwards
				AOCPawn(Victim).Mesh.AddRadialImpulse(HurtOrigin - (vect(0,0,1) * 75), DamageRadius, 600.0, RIF_Linear, false);
			}
		}
		else if (IAOCActor(Victim) != none)
		{
			IAOCActor(Victim).AOCTakeDamage(DamageAmount, HurtOrigin, Vect(0.f, 0.f, 0.f), OwnerPawn, MyDamageType);
		}
	}
	bHurtEntry = false;

	return bCausedDamage;
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		bCastDynamicShadow=false;
		CastShadow=false;
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		MaxDrawDistance=4000
		//bUpdateSkelWhenNotRendered=false
		bAcceptsDynamicDecals=false
		StaticMesh=StaticMesh'WP_throw_Pots.SM_smoke_pot'
	End Object
	Components.add(StaticMeshComponent0)
	Mesh=StaticMeshComponent0
			
	ProjExplosionTemplate=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world'
	ProjFlightTemplate=ParticleSystem'AOC_SiegeWeapon.Effects.P_Catapult_RockTrail'
	
	ExplosionDecal=DecalMaterial'CHV_DecalGen.MD_burn_scorch_mark'
	DecalWidth=256.0
	DecalHeight=256.0

	AmbientSound=SoundCue'A_Projectile_Flight.Flight_Oilpot'
	ExplosionSound=SoundCue'A_Impacts_Missile.catapult_impact'
	//ImpactSound=SoundCue'A_Weapon_BioRifle.Weapon.A_BioRifle_FireImpactFizzle_Cue'  See if Buckley wants this

	MyDamageType=class'AOCDmgType_CatapultRock'

	speed=1550.0
	MaxSpeed=1650.0
	Damage=30.0
	DamageRadius=250.0
	MomentumTransfer=200000.0
	LifeSpan=30.0
	RotationRate=(Pitch=50000)
	bCollideWorld=true
	CheckRadius=42.0
	MaxEffectDistance=4000.0
	Physics = Phys_Falling

	bAttachExplosionToVehicles=false

	bCanPickupProj=false

	//bBounce=false  Could be fun to test this
	bOverrideDefaultExplosionDeffect=true
	PhysBasedParticleExplosions={(
		Stone=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Dirt=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Gravel=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Foliage=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Sand=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Water=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_water',
		Metal=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Snow=ParticleSystem'CHV_EnvironmentParticles.Snow.P_LargeImpact_Snow',
		Wood=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Ice=ParticleSystem'CHV_EnvironmentParticles.Snow.P_LargeImpact_Snow',
		Mud=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world',
		Tile=ParticleSystem'CHV_EnvironmentParticles.cat.P_CatapultImpact_world')
	}
	
}
