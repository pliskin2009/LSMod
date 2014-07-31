class LSModProjectile extends AOCProjectile
	dependson(AOCPawn)
	abstract;



struct ProjectileHit
{
	var bool bIsValid;
	var bool bHitShield;
	var float fDistance;
	var Actor Other;
	var Vector HitLocation;
	var Vector HitNormal;
	var TraceHitInfo TraceInfo;
};





/** Owner Pawn */
//var repnotify AOCPawn OwnerPawn;

/** Weapon Tracer Variables */
var int     NumTracers;
var bool    bUseLongTracers;
var vector  LongTraceStart;
var vector  LongTraceEnd;


/** Array of all pawns whose parry boxes we've hit */
var array<AOCPawn> ParryPawns;

// Air resistance
var float DistanceTravelled;



var bool bSpawnDroppedWeapon;


// Can this projectile be parried?
var bool bCanBeParried;

var Rotator InitialRotation;

var string WeaponFontSymbol;

/////////////////////////////////////////////////
var bool bCanBeReflected;
var bool bIsReflected;

var float PitchCorrection;
//////////////////////////////////////////////////

// Here we want to spawn a static mesh of ourselves
simulated function SpawnStickyAlternate();

simulated function AOCDroppedWeapon DWSpawnStickyAlternate(vector HitLocation)                 ////////////////////LSMod____FIX_THIS_LATER!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
{
	local AOCDroppedWeapon Act;

	if (bSpawnDroppedWeapon)
	{
		if (bCanPickupProj)
		{
			Act = Spawn(class'LSModBouncedProjectile',self, , HitLocation);
			LSModBouncedProjectile(Act).CorrespondingWeapon = LaunchingWeapon;
			LSModBouncedProjectile(Act).StickyId = RepBaseInfo.StickyId;
		}
		else
		{
			Act = Spawn(class'AOCDroppedWeapon',self, , HitLocation);
		}

		Act.SetMeshAndInitialize( Mesh.StaticMesh, 1.f );
		bSpawnDroppedWeapon = false;
	}

	return Act;
}

simulated function AOCInit( Rotator Direction)
{

	if(AOCRangeWeapon(Instigator.Weapon) != none && AOCRangeWeapon(Instigator.Weapon).projectilespeed != 0 )
		speed = AOCRangeWeapon(Instigator.Weapon).projectilespeed;

	if(AOCRangeWeapon(Instigator.Weapon) != none && AOCRangeWeapon(Instigator.Weapon).fGravitySetting != -1.0f )
		CustomGravityScaling = AOCRangeWeapon(Instigator.Weapon).fGravitySetting;

	if(AOCRangeWeapon(Instigator.Weapon) != none && AOCRangeWeapon(Instigator.Weapon).Drag != -1.0f )
		Drag = AOCRangeWeapon(Instigator.Weapon).Drag;

	if(AOCRangeWeapon(Instigator.Weapon) != none && AOCRangeWeapon(Instigator.Weapon).TraceRadius != -1.0f )
		TraceRadius = AOCRangeWeapon(Instigator.Weapon).TraceRadius;

	OwnerFaction = OwnerPawn.GetAOCTeam();

	SetRotation(Direction);
	NewRotation = Direction;

	RepSpeed = Speed;
	RepMaxSpeed = MaxSpeed;
	NewGravity = CustomGravityScaling;
	Velocity = Speed * Vector(Direction);
	Velocity.Z += TossZ;
	Acceleration = AccelRate * Normal(Velocity);

	PrevLocation = Location;

	bInit=true;
	SetupExtraTracerLocations(PreviousTraceLoc, Location);
	StartFlightTime = WorldInfo.TimeSeconds;
}

simulated function swapArrowCamAmbientSound()
{
	local AudioComponent audComp;

	if (bEnableArrowCamAmbientSoundSwap)
	{
		foreach AllOwnedComponents(class'AudioComponent', audComp)
		{
			if (audComp.SoundCue == AmbientSound)
			{
				audComp.Stop();
				audComp.DetachFromAny();
				AmbientComponent = CreateAudioComponent(SoundCue'A_Projectile_Flight.Flight_Arrow_Cam', true, true);
				break;
			}
		}
	}
}

simulated function SetupExtraTracerLocations(out vector NewLoc[5], vector InputLocation)
{
	local Vector GlobalUp, LocalUp;
	local Vector GlobalRight, LocalRight;

	if (bUseLongTracers)
	{
		SetupLongTracerLocations(NewLoc, InputLocation);
		return;
	}

	GlobalUp = Vect(0.0f, 0.0f, 1.0f);
	GlobalRight = Vect(0.0f, 1.0f, 0.0f);

	LocalUp = Normal(GlobalUp >> Rotation) * TraceRadius;
	LocalRight = Normal(GlobalRight >> Rotation) * TraceRadius;

	NewLoc[0] = InputLocation + LocalUp;
	NewLoc[1] = InputLocation + LocalRight;
	NewLoc[2] = InputLocation - LocalUp;
	NewLoc[3] = InputLocation - LocalRight;
	NewLoc[4] = InputLocation;
}

simulated function SetupLongTracerLocations(out vector NewLoc[5], vector InputLocation)
{
	local Vector TraceStart, TraceEnd;
	local int i;
	
	`logalways("DRAWING_LONGTRACERS");

	TraceStart = InputLocation + (LongTraceStart >> Rotation);
	TraceEnd = InputLocation + (LongTraceEnd >> Rotation);

	for (i = 0; i < NumTracers; i++)
	{
		NewLoc[i] = TraceStart + (i / float(NumTracers - 1)) * (TraceEnd - TraceStart);
	}
}


simulated function ClientAOCInitialize()
{

}

/*function PassImmediateShutdownToServer(ProjectileBaseInfo BaseInfo, vector HitLocation, vector HitNormal, optional bool bForce)
{
	if(bForce || !bHasAlreadySentServerShutdown)
	{
		ThisController.S_ImmediateProjectileShutdown(ProjIdent, BaseInfo);
		bHasAlreadySentServerShutdown = true;
	}
}*/

function PassImmediateShutdownToServerNoInfo(optional bool bForce)
{
	if(bForce || !bHasAlreadySentServerShutdown)
	{
		ThisController.S_ImmediateProjectileShutdownNoInfo(ProjIdent);
		bHasAlreadySentServerShutdown = true;
	}
}



/*function ReceiveShutdownForce(ProjectileBaseInfo BaseInfo)
{
	local SoundCue Sound;

	if(BaseInfo.Other != none || BaseInfo.bHitWorld)
	{
		RepBaseInfo = BaseInfo;
		bNetDirty = true;
		Shutdown();
	}
	else
	{
		//got a forced shutdown without any base info. Tear us right the hell off, and let the clients do any resulting attaches themselves.
		bTearOff = true;
		LifeSpan = 1.0f;
	}

	// Play impact sound if there was one
	if (BaseInfo.ImpactSound != 'None')
	{
		Sound = none;
		switch(BaseInfo.ImpactSound)
		{
			case 'Stone':
				Sound = ImpactSounds.Stone;
				break;
			case 'Dirt':
				Sound = ImpactSounds.Dirt;
				break;
			case 'Gravel':
				Sound = ImpactSounds.Gravel;
				break;
			case 'Foliage':
				Sound = ImpactSounds.Foliage;
				break;
			case 'Sand':
				Sound = ImpactSounds.Sand;
				break;
			case 'Metal':
				Sound = ImpactSounds.Metal;
				break;
			case 'Snow':
				Sound = ImpactSounds.Snow;
				break;
			case 'Wood':
				Sound = ImpactSounds.Wood;
				break;
			case 'Ice':
				Sound = ImpactSounds.Ice;
				break;
			case 'Mud':
				Sound = ImpactSounds.Mud;
				break;
			case 'Tile':
				Sound = ImpactSounds.Tile;
				break;
			case 'Water':
				Sound = ImpactSounds.Water;
				break;
		}
		if (Sound != none)
		{
			PlaySound(Sound, false,, false, BaseInfo.Location);
		}
	}
}*/

function ReceiveShutdownForceLocation(vector HitLocation, vector HitNormal, int Comp, Actor HitActor)
{
}

simulated event ReplicatedEvent(name VarName)
{	
	if (VarName == 'NewRotation')
	{
		SetRotation(NewRotation);
	}
	else if (VarName == 'RepRotationRate')
	{       
		SetRotation(RepRotationRate);
	}   
	else if (VarName == 'RepSpeed' || VarName == 'RepMaxSpeed')
	{
		Speed = RepSpeed;
		MaxSpeed = RepMaxSpeed;
	}
	else if (VarName == 'NewGravity')
	{
		CustomGravityScaling = NewGravity;
	}
	else if (VarName == 'bInit')
	{
		ClientAOCInitialize();
	}
	else if(VarName == 'RepBaseInfo')
	{
		//Attach to whatever we attach to attach to	
		`logalways(self@"RepBaseInfo"@RepBaseInfo.bHitWorld@RepBaseInfo.Other@Role);
		
		if(((Role != ROLE_Authority || WorldInfo.NetMode == NM_Standalone) && 
			(!OwnerPawn.IsLocallyControlled() || OwnerPawn.bIsBot)) && 
			StickyMesh == none)
		{

			if (bSpawnSticky)
			{
				`logalways(self@"RepBaseInfo"@RepBaseInfo.Other@RepBaseInfo.Bone@RepBaseInfo.Location@RepBaseInfo.Rotation);
				StickyMesh = spawn( class'AOCStickyProjectile', self , , RepBaseInfo.Location, RepBaseInfo.Rotation);	

				StickyMesh.SetStaticMesh( Mesh.StaticMesh );
				StickyMesh.CorrespondingWeapon = LaunchingWeapon;
				StickyMesh.bCanPickup = bCanPickupProj;
				StickyMesh.SetCollision(bCanPickupProj);
				StickyMesh.StickyId = RepBaseInfo.StickyId;
				StickyMesh.HandleBaseInfo(RepBaseInfo);

				if (AOCPawn(RepBaseInfo.Other) != none)
				{
					AOCPawn(RepBaseInfo.Other).AddSticky(StickyMesh, RepBaseInfo.Bone);
					if(RepBaseInfo.bHitShield)
					{
						AOCPawn(RepBaseInfo.Other).AddShieldSticky(StickyMesh);
					}
				}
			}
			else
				DWSpawnStickyAlternate(RepBaseInfo.Location);
			
		}
		
		Shutdown();
	}
}

simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{
	local KActorFromStatic NewKActor;
	local StaticMeshComponent HitStaticMesh;
	local Vector HitLocation, HitNormal2;
	local TraceHitInfo HitInfo;
	local Actor HitActor;
	local name ImpactSoundName;
	
	if(bHasShutdown)
	{
		return;
	}

	// do a trace first to see if we hit an actor in the process
	if ((Role == ROLE_Authority) || OwnerPawn.bIsBot)
	{
		PerformProjectileTracers(ImpactSoundName);
	}
	
	Super(Actor).HitWall(HitNormal, Wall, WallComp);

	if ((Role == ROLE_Authority /*&& OwnerPawn.IsLocallyControlled()*/) || OwnerPawn.bIsBot)
	{
		`logalways("ATTACH TO WORLD"@Wall);

		AttachToWorld(Location, Wall, ImpactSoundName);

		if ( Wall.bWorldGeometry )
		{
			HitStaticMesh = StaticMeshComponent(WallComp);
			if ( (HitStaticMesh != None) && HitStaticMesh.CanBecomeDynamic() )
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitStaticMesh);
				if ( NewKActor != None )
				{
					Wall = NewKActor;
				}
			}
		}
		ImpactedActor = Wall;
		if (!Wall.bStatic && (DamageRadius == 0))
		{
			Wall.TakeDamage( Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), MyDamageType,, self);
		}

		// do a trace to get physical material

		HitActor = AOCTrace( HitLocation, HitNormal2, PrevLocation, Location + Normal(Location-PrevLocation) * 5.0f, true,, HitInfo);
		ImpactedTrace = HitInfo;
		`logalways("HIT ACTOR WALL"@HitActor);
		PlayImpactSound(HitActor, HitInfo, HitLocation);
		DisableProjCam();

		//HitActor = AOCTrace( HitLocation, HitNormal2, PrevLocation, Location + Normal(Location-PrevLocation) * 5.0f, true,, HitInfo);
		
		Explode(Location, HitNormal);
		ImpactedActor = None;
	}
}

simulated function name PlayImpactSound(Actor Other, TraceHitInfo HitInfoTrace, vector HitLoc)
{
	local name SoundName;
	local UTPhysicalMaterialProperty PhysicalProperty;
	local ARMORTYPE armorType;
	
	// We hit a player or bot
	if (AOCPawn(Other) != none)
	{
		// Hit player's shield, use 2 cue block sound sysem.
		if (bHitShield)
		{
			ImpactSound = AOCPawn(Other).ShieldClass.NewShield.default.BlockSound;
			PlaySound(ProjBlockedSound, false,, false, Location);
		}
		else
		{
			armorType = AOCPawn(Other).PawnInfo.myFamily.default.PawnArmorType;

			if (armorType == ARMORTYPE_HEAVY)
				ImpactSound = ImpactSounds.Heavy;
			else if (armorType == ARMORTYPE_MEDIUM)
				ImpactSound =  ImpactSounds.Medium;
			else if (armorType == ARMORTYPE_LIGHT)
				ImpactSound = ImpactSounds.Light;
		}
	}
	// Hit something else in the world
	else 
	{
		if (AOCWaterVolume(Other) != None)
		{
			AOCWaterVolume(Other).PlayEntrySplash(self);
			ImpactSound = ImpactSounds.Water;
			SoundName = 'Water';
		}
		else if (HitInfoTrace.PhysMaterial != None)
		{
			PhysicalProperty = UTPhysicalMaterialProperty(HitInfoTrace.PhysMaterial.GetPhysicalMaterialProperty(class'UTPhysicalMaterialProperty'));
			if (PhysicalProperty != None)
			{
				SoundName = PhysicalProperty.MaterialType;

				Switch (PhysicalProperty.MaterialType)
				{
					case 'Stone':
						ImpactSound = ImpactSounds.Stone;
						break;
					case 'Dirt':
						ImpactSound = ImpactSounds.Dirt;
						break;
					case 'Gravel':
						ImpactSound = ImpactSounds.Gravel;
						break;
					case 'Foliage':
						ImpactSound = ImpactSounds.Foliage;
						break;
					case 'Sand':
						ImpactSound = ImpactSounds.Sand;
						break;
					case 'Metal':
						ImpactSound = ImpactSounds.Metal;
						break;
					case 'Snow':
						ImpactSound = ImpactSounds.Snow;
						break;
					case 'Wood':
						ImpactSound = ImpactSounds.Wood;
						break;
					case 'Ice':
						ImpactSound = ImpactSounds.Ice;
						break;
					case 'Mud':
						ImpactSound = ImpactSounds.Mud;
						break;
					case 'Tile':
						ImpactSound = ImpactSounds.Tile;
						break;
					default:
						ImpactSound = ImpactSounds.Stone;
						break;
				}	
			}
			else
			{
				ImpactSound = ImpactSounds.Stone;
				SoundName = 'Stone';
			}
		}
		else
		{
			ImpactSound = ImpactSounds.Stone;
			SoundName = 'Stone';
		}
	}

	if (bLimitImpactSound && WorldInfo.TimeSeconds - LastImpactSoundTime < 2.f)
		return 'None';
	LastImpactSoundTime = WorldInfo.TimeSeconds;
	// Play the sound
	`logalways("IMPACT SOUND:"@ImpactSound);

	PlaySound(ImpactSound, false,, false, HitLoc);
	return SoundName;
}

simulated function AttackDeadPawn(AOCPawn Pawn, TraceHitInfo TraceInfo, Vector HitLocation, Vector HitNormal)
{
	local HitInfo Info;
	`logalways("HIT DEAD PAWN"@Pawn);
	
	if(OwnerPawn.Role != ROLE_Authority && ThisController != none)
	{
		ThisController.S_ImmediateProjectileShutdownNoInfo(ProjIdent); //ragdoll location will NOT match between clients
	}	
	
	Info.AttackType = Attack_Slash;
	Info.BoneName = TraceInfo.BoneName;
	Info.bParry = false;
	Info.DamageType = class'AOCDmgType_PierceProj';
	Info.HitActor = Pawn;
	Info.HitDamage = Damage;
	Info.HitForce = vect(1.0f, 0.0f, 0.0f);
	Info.HitLocation = HitLocation;
	Info.Instigator = OwnerPawn;
	PlayImpactSound(Pawn, TraceInfo, HitLocation);
	OwnerPawn.AttackDeadPawn(Info, Pawn.iUniquePawnID);
	
	AttachToComponent(Pawn, TraceInfo.HitComponent, HitLocation, HitNormal);
	ShutDown();
}

simulated event Tick( float DeltaTime)
{
	local name ImpactSoundName;

	// Calculate drag
	if (!( Normal(Velocity) Dot Vect(0.0f, 0.0f, -1.0f) >= 0.7f ))  // If it's not moving down
	{
		Velocity -= Velocity * Drag * DeltaTime * DRAG_SCALE;
	}

	if (Role < ROLE_Authority && OwnerPawn.IsLocallyControlled() && !OwnerPawn.bIsBot)
	{
		ShutDown();
		return;
	}
	if(bHasShutdown)
	{
		return;
	}
	
	super(UTProjectile).Tick( DeltaTime );
	
	if ((Role == ROLE_Authority) || OwnerPawn.bIsBot)
	{
		PerformProjectileTracers(ImpactSoundName);
	}

	TimeElapsed+=DeltaTime;
	DistanceTravelled += VSize(Location-PrevLocation);
	MovementDirection=Normal(Location-PrevLocation);
	PrevLocation = Location;
	RotateProjectile(YawRate, PitchRate, RollRate);
	bFirstTick = false;
}

simulated function PerformProjectileTracers(out name ImpactSoundName)
{
	local Vector CurTraceLocs[5];
	local Vector HitLocation, HitNormal;
	local Actor HitActor;
	local TraceHitInfo HitInfo;
	local int i;
	local vector PrevLoc, CurLoc;
	local ProjectileHit FoundHit;
	local float fDistance;

	FoundHit.bIsValid = false;

	for (i = 0; i < NumTracers; i++)
	{
		SetupExtraTracerLocations(CurTraceLocs, Location);
		PrevLoc = PreviousTraceLoc[i];
		CurLoc = CurTraceLocs[i];

		if(AOCPawn(Instigator) != none && ILSModPlayerController(OwnerPawn.Controller).DrawWeaponTracers())         //////////////Creante an interface in Player Controller
		{
			AOCWeaponAttachment(AOCPawn(Instigator).CurrentWeaponAttachment).DrawServerDebugLineOnClient( PrevLoc,CurLoc, PlayerController(Instigator.Controller), 255, 0, 0);
		}

		foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CurLoc, PrevLoc,, HitInfo, TRACEFLAG_BULLET)
		{
			if( HitActor != none && AOCPawn(HitActor) != none && HitInfo.HitComponent == AOCPawn(HitActor).ParryComponent )
			{
				if(bCanBeParried && ParryPawns.Find(HitActor) == INDEX_NONE)
				{				
					ParryPawns.AddItem(AOCPawn(HitActor));
					
				}
				continue;
			}
			
			if( HitActor != none && WorldInfo(HitActor) == none && AOCPawn(HitActor) != OwnerPawn && HitActors.Find(HitActor) == INDEX_NONE )
			{
				fDistance = VSize(HitLocation - PrevLoc);
				if (FoundHit.bIsValid && fDistance > FoundHit.fDistance)
				{
					continue;
				}

				FoundHit.fDistance = fDistance;
				FoundHit.bIsValid = true;
				FoundHit.HitLocation = HitLocation;
				FoundHit.HitNormal = HitNormal;
				FoundHit.Other = HitActor;
				FoundHit.TraceInfo = HitInfo;
			}
		}
	}

	if (FoundHit.bIsValid)
	{
		if (AOCPawn(FoundHit.Other) != none && !AOCPawn(FoundHit.Other).bPlayedDeath)
		{
			ImpactedActor = FoundHit.Other;
			ImpactedTrace = FoundHit.TraceInfo;
			AOCProcessTouch(FoundHit.Other, FoundHit.HitLocation, FoundHit.HitNormal, FoundHit.TraceInfo);
			HitActors.AddItem(FoundHit.Other);
					
			AttachToComponent( FoundHit.Other, FoundHit.TraceInfo.HitComponent, FoundHit.HitLocation, FoundHit.HitNormal );
					
			Shutdown();
			ImpactedActor = None;

			bShouldAttach = true;
				
			//return;
		}
		else if (AOCPawn(FoundHit.Other) != none && AOCPawn(FoundHit.Other).bPlayedDeath && Role == ROLE_Authority)
		{
			AttackDeadPawn(AOCPawn(FoundHit.Other), FoundHit.TraceInfo, FoundHit.HitLocation, FoundHit.HitNormal);
			ImpactSoundName = PlayImpactSound(FoundHit.Other, FoundHit.TraceInfo, FoundHit.HitLocation);
			Shutdown();
			HitActors.AddItem(FoundHit.Other);
			//return;
		}
		else if (IAOCActor(FoundHit.Other) != none)
		{
			ImpactSoundName = PlayImpactSound(FoundHit.Other, FoundHit.TraceInfo, FoundHit.HitLocation);
				
			// Hit a custom actor
			AttachToWorld(FoundHit.HitLocation, FoundHit.Other);
			Shutdown();
			HitActors.AddItem(FoundHit.Other);

			//return;
		}
	}

	for (i = 0; i < NumTracers; i++)
		PreviousTraceLoc[i] = CurTraceLocs[i];
}

simulated function RotateProjectile(float Yaw, float Pitch, float Roll)
{
	RotationRate.Pitch = Pitch;
	RotationRate.Roll = Roll;
	RotationRate.Yaw = Yaw;

	if (Yaw == 0.f && Pitch == 0.f && Roll == 0.f && !bFirstTick)
		SetRotation(Rotator(MovementDirection));

	RepRotationRate = Rotation;
	//NewRotation = Rotation;
}

simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
}

simulated function AttachToComponent( Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal )
{
	local SkeletalMeshComponent OtherSkelComp;
	local name BestBone;
	local Vector BestHitLocation, BoneLocation;
	local ProjectileBaseInfo BaseInfo;
	//local int TheComp;
	
	if(StickyMesh != none)
	{
		return;
	}

	OtherSkelComp = SkeletalMeshComponent( OtherComp );
	`logalways("ATTACH TO COMPONENT:"@OtherComp@OtherSkelComp);

	`logalways(self@"PERFROM ACTUAL ATTACH TO COMPONENT"@Role);
	if (OtherSkelComp != none )
	{
		FindNearestBone( OtherSkelComp, HitLocation, BestBone, BoneLocation);
		projectilecomp.SetLightEnvironment( OtherComp.LightEnvironment );
		BestHitLocation = HitLocation - Normal(HitLocation - PrevLocation) * fProjectileAttachCompensation;
		
		BaseInfo.Other = Other;
		BaseInfo.Bone = BestBone;
		BaseInfo.Location = BestHitLocation;
		BaseInfo.Rotation = Rotator(Location-PrevLocation) + InitialRotation;
		RepBaseInfo.StickyId = OwnerPawn.GetStickyId(Self);
		
		if (AOCPawn(Other) != none)
		{
			AOCPawn(Other).AddDeathListener(StickyMesh);
			`logalways("HIT SHIELD:"@OtherSkelComp == AOCPawn(Other).ShieldMesh@OtherSkelComp@AOCPawn(Other).ShieldMesh@AOCPawn(Other).BackShieldMesh);
			BaseInfo.bHitShield = OtherSkelComp == AOCPawn(Other).ShieldMesh || OtherSkelComp == AOCPawn(Other).BackShieldMesh;
			BaseInfo.bUseAbsPos = false;
			BaseInfo.Location = BestHitLocation - BoneLocation;

			bHitShield = BaseInfo.bHitShield;   // Used for impact sounds
		}
		
		RepBaseInfo = BaseInfo;

		if (OwnerPawn.Role != ROLE_Authority && ThisController != none)
		{
			if(Role == ROLE_Authority)
			{
				/*
				TheComp = -1;
				if (AOCPawn(Other) != none)
				{
					if (OtherComp == AOCPawn(Other).Mesh)
						TheComp = 0;
					else if (OtherComp == AOCPawn(Other).ShieldMesh)
						TheComp = 1;
					else if (OtherComp == AOCPawn(Other).BackShieldMesh)
						TheComp = 2;
				}
				*/

				PassImmediateShutdownToServer(BaseInfo, HitLocation, HitNormal);
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
		
		if( WorldInfo.GetDetailMode() != DM_Low || bCanPickupProj)
		{
			if (bSpawnSticky)
			{
				StickyMesh = spawn( class'AOCStickyProjectile', self , , BestHitLocation, BaseInfo.Rotation);
			
				StickyMesh.SetStaticMesh( Mesh.StaticMesh );
				StickyMesh.CorrespondingWeapon = LaunchingWeapon;
				StickyMesh.bCanPickup = bCanPickupProj;
				StickyMesh.SetCollision(bCanPickupProj);
				StickyMesh.StickyId = RepBaseInfo.StickyId;
				StickyMesh.HandleBaseInfo(RepBaseInfo);
						
				if (AOCPawn(Other) != none)
				{
					AOCPawn(Other).AddDeathListener(StickyMesh);
					AOCPawn(Other).AddSticky(StickyMesh, RepBaseInfo.Bone);
					if(BaseInfo.bHitShield)
					{
						AOCPawn(Other).AddShieldSticky(StickyMesh);
					}
				}
			}
			else
				DWSpawnStickyAlternate(BestHitLocation);
		}
		
		Shutdown();
	}
	else
		AttachToWorld(HitLocation, Other);
}

static function bool FindNearestBone( SkeletalMeshComponent OtherComp, vector InitialHitLocation, out name BestBone, out vector BestHitLocation)
{
	local int i, dist, BestDist;
	local vector BoneLoc;
	local name BoneName;

	BestHitLocation = InitialHitLocation;
	if (OtherComp.PhysicsAsset != none)
	{
		for (i=0;i<OtherComp.PhysicsAsset.BodySetup.Length;i++)
		{
			BoneName = OtherComp.PhysicsAsset.BodySetup[i].BoneName;
			//`logalways("CHECK BONE:"@BoneName@OtherComp.MatchRefBone(BoneName)@INDEX_NONE);
			// If name is not empty and bone exists in this mesh
			if ( BoneName != '' && OtherComp.MatchRefBone(BoneName) != INDEX_NONE)
			{
				BoneLoc = OtherComp.GetBoneLocation(BoneName);
				Dist = VSize(InitialHitLocation - BoneLoc);
				if ( i==0 || Dist < BestDist )
				{
					BestDist = Dist;
					BestBone = OtherComp.PhysicsAsset.BodySetup[i].BoneName;
					BestHitLocation = BoneLoc;
				}
			}
		}

		if (BestBone != '')
		{
			return true;
		}
	}
	return false;
}

simulated function SuccessHitPawn(AOCPawn P, name BoneName);

simulated function AOCProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal, TraceHitInfo TraceInfo)
{
	local HitInfo Info;
	local class<AOCWeapon> Weap;
	local bool bParried;
	local string DamageString;

	`logalways("PROCESS TOUCH"@Role);
	if( Role < ROLE_Authority )
		return;

	bDamagedSomething=true;

	if (DamageRadius > 0.0)
	{
		Explode( HitLocation, HitNormal );
	}
	else if (AOCPawn(Other) == none)
	{
		Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
		Shutdown();
	}
	else if (AOCPawn(Other) == OwnerPawn)
	{
		return;
	}
	else
	{
		Info.AttackType = Attack_Slash;
		Info.BoneName = TraceInfo.BoneName;
		Info.bParry = false;
		Info.DamageType = class<AOCDamageType>(MyDamageType);
		Info.HitActor = AOCPawn(Other);
		Info.HitDamage = Damage;
		Info.HitForce = vect(0.0f, 0.0f, 0.0f);
		Info.HitLocation = HitLocation;
		Info.Instigator = OwnerPawn;
		Info.HitCombo = 0;
		Info.TimeVar = WorldInfo.TimeSeconds - StartFlightTime;
		
		Info.ProjType = Class;                                                        /////////////////////FROM_NORMAL_AOCPROJECTILE
		
		Info.UsedWeapon = CurrentAssociatedWeapon;

		if (OwnerPawn.Role < ROLE_Authority || WorldInfo.NetMode == NM_Standalone)
		{
			if (TraceInfo.HitComponent == AOCPawn(Other).Mesh || TraceInfo.HitComponent == AOCPawn(Other).ShieldMesh || TraceInfo.HitComponent == AOCPawn(Other).BackShieldMesh)
			{
				bParried = ParryPawns.Find(Other) != INDEX_NONE;
				if (bParried && AOCPawn(Other).StateVariables.bIsParrying)
				{
					bSpawnSticky = false;
				}

				if (CurrentAssociatedWeapon == 0)
					Weap = OwnerPawn.PrimaryWeapon;
				else if (CurrentAssociatedWeapon == 1)
					Weap = OwnerPawn.SecondaryWeapon;
				else
					Weap = OwnerPawn.TertiaryWeapon;
				
				DamageString = Weap.default.WeaponFontSymbol;
				if (WeaponFontSymbol != "")
				{
					DamageString = WeaponFontSymbol;
				}

				OwnerPawn.AttackOtherPawn(Info, DamageString,, bParried, TraceInfo.HitComponent == AOCPawn(Other).ShieldMesh || TraceInfo.HitComponent == AOCPawn(Other).BackShieldMesh);
			}
		}

		SuccessHitPawn(AOCPawn(Other), TraceInfo.BoneName);
		//`logalways("SUCCESSFULLY HIT A PAWN SHUTDOWN");
		Shutdown();
	}
}

simulated function AttachToWorld(vector HitLoc, optional Actor HitActor = none, optional name ImpactSoundName = 'None')
{
	local ProjectileBaseInfo BaseInfo;
	local vector NewLoc;
	
	`logalways("AttachToWorld "@bHasShutdown);
	
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
	
	//`logalways("ATTACH TO WORLD"@NewLoc@HitLoc@HitActor@GetScriptTrace());
	if(WorldInfo.GetDetailMode() != DM_Low || bCanPickupProj)
	{
		if (bSpawnSticky)
		{
			StickyMesh = spawn( class'AOCStickyProjectile', self , , NewLoc, BaseInfo.Rotation );

			StickyMesh.SetStaticMesh( Mesh.StaticMesh );
			StickyMesh.SetRotation(BaseInfo.Rotation);
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

simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local Rotator proj_rot;
	proj_rot.Yaw = Rotation.Yaw;

	out_CamLoc = location + (vector(proj_rot) * ProjCamPosModX) + (ProjCamPosModZ * vect(0,0,1));
	out_CamRot = proj_rot;
	return true;
}



simulated function DisableProjCam()
{
	// Deactivate projectile camera
	if (InstigatorController == none)
		return;
	AOCPlayerController(InstigatorController).bCanSwapToProjCam = false;

	if (Role < ROLE_Authority)
	{
		s_DisableProjCam();
	}
}

unreliable server function s_DisableProjCam()
{
	if (InstigatorController == none)
		return;
	AOCPlayerController(InstigatorController).bCanSwapToProjCam = false;

	NetPriority = 2.5f;
}

//trace, ignoring things that ought to be ignored (right now, player parry volumes)
simulated function Actor AOCTrace
(
	out vector					HitLocation,
	out vector					HitNormal,
	vector						TraceEnd,
	optional vector				TraceStart,
	optional bool				bTraceActors,
	optional vector				Extent,
	optional out TraceHitInfo	HitInfo,
	optional int				ExtraTraceFlags
)
{
	local Actor HitActor;
	
	foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, TraceStart, TraceEnd, Extent, HitInfo, ExtraTraceFlags)
	{
		if( HitActor != none && AOCPawn(HitActor) != none && HitInfo.HitComponent == AOCPawn(HitActor).ParryComponent )
		{
			continue;
		}
		else if (AOCPawn(HitActor) == OwnerPawn)
		{
			continue;
		}
		else
		{
			return HitActor;	
		}
	}
	return none;
}

// Get particle explosion relevant to what we hit
simulated function ParticleSystem GetRelevantParticleExplosion()
{
	local ParticleSystem Sys;
	local UTPhysicalMaterialProperty PhysicalProperty;
	if (!bOverrideDefaultExplosionDeffect)
		return ProjExplosionTemplate;
	else
	{
		if (AOCWaterVolume(ImpactedActor) != None)
		{
			AOCWaterVolume(ImpactedActor).PlayEntrySplash(self);
			Sys = PhysBasedParticleExplosions.Water;
		}
		else if (ImpactedTrace.PhysMaterial != None)
		{
			PhysicalProperty = UTPhysicalMaterialProperty(ImpactedTrace.PhysMaterial.GetPhysicalMaterialProperty(class'UTPhysicalMaterialProperty'));
			if (PhysicalProperty != None)
			{
				Switch (PhysicalProperty.MaterialType)
				{
					case 'Stone':
						Sys = PhysBasedParticleExplosions.Stone;
						break;
					case 'Dirt':
						Sys = PhysBasedParticleExplosions.Dirt;
						break;
					case 'Gravel':
						Sys = PhysBasedParticleExplosions.Gravel;
						break;
					case 'Foliage':
						Sys = PhysBasedParticleExplosions.Foliage;
						break;
					case 'Sand':
						Sys = PhysBasedParticleExplosions.Sand;
						break;
					case 'Metal':
						Sys = PhysBasedParticleExplosions.Metal;
						break;
					case 'Snow':
						Sys = PhysBasedParticleExplosions.Snow;
						break;
					case 'Wood':
						Sys = PhysBasedParticleExplosions.Wood;
						break;
					case 'Ice':
						Sys = PhysBasedParticleExplosions.Ice;
						break;
					case 'Mud':
						Sys = PhysBasedParticleExplosions.Mud;
						break;
					case 'Tile':
						Sys = PhysBasedParticleExplosions.Tile;
						break;
					default:
						Sys = PhysBasedParticleExplosions.Stone;
						break;
				}	
			}
			else
				Sys = ProjExplosionTemplate;
		}
		else
			Sys = ProjExplosionTemplate;

	}

	return Sys;
}

/**
 * Spawn Explosion Effects
 */
simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local vector LightLoc, LightHitLocation, LightHitNormal;
	local vector Direction;
	local ParticleSystemComponent ProjExplosion;
	local Actor EffectAttachActor;
	local MaterialInstanceTimeVarying MITV_Decal;
	local ParticleSystem PartSys;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (ProjectileLight != None)
		{
			DetachComponent(ProjectileLight);
			ProjectileLight = None;
		}
		PartSys = GetRelevantParticleExplosion();
		if (PartSys != None && EffectIsRelevant(Location, false, MaxEffectDistance))
		{
			EffectAttachActor = (bAttachExplosionToVehicles || (UTVehicle(ImpactedActor) == None)) ? ImpactedActor : None;
			if (!bAdvanceExplosionEffect)
			{
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(PartSys, HitLocation, rotator(HitNormal), EffectAttachActor);
			}
			else
			{
				Direction = normal(Velocity - 2.0 * HitNormal * (Velocity dot HitNormal)) * Vect(1,1,0);
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(PartSys, HitLocation, rotator(Direction), EffectAttachActor);
				ProjExplosion.SetVectorParameter('Velocity',Direction);
				ProjExplosion.SetVectorParameter('HitNormal',HitNormal);
			}
			SetExplosionEffectParameters(ProjExplosion);

			if ( !WorldInfo.bDropDetail && ((ExplosionLightClass != None) || (ExplosionDecal != none)) && ShouldSpawnExplosionLight(HitLocation, HitNormal) )
			{
				if ( ExplosionLightClass != None )
				{
					if (Trace(LightHitLocation, LightHitNormal, HitLocation + (0.25 * ExplosionLightClass.default.TimeShift[0].Radius * HitNormal), HitLocation, false) == None)
					{
						LightLoc = HitLocation + (0.25 * ExplosionLightClass.default.TimeShift[0].Radius * (vect(1,0,0) >> ProjExplosion.Rotation));
					}
					else
					{
						LightLoc = HitLocation + (0.5 * VSize(HitLocation - LightHitLocation) * (vect(1,0,0) >> ProjExplosion.Rotation));
					}

					UDKEmitterPool(WorldInfo.MyEmitterPool).SpawnExplosionLight(ExplosionLightClass, LightLoc, EffectAttachActor);
				}

				// this code is mostly duplicated in:  UTGib, UTProjectile, UTVehicle, UTWeaponAttachment be aware when updating
				if (ExplosionDecal != None && Pawn(ImpactedActor) == None )
				{
					if( MaterialInstanceTimeVarying(ExplosionDecal) != none )
					{
						// hack, since they don't show up on terrain anyway
						if ( Terrain(ImpactedActor) == None )
						{
						MITV_Decal = new(self) class'MaterialInstanceTimeVarying';
						MITV_Decal.SetParent( ExplosionDecal );

						WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 10.0, FALSE );
						//here we need to see if we are an MITV and then set the burn out times to occur
						MITV_Decal.SetScalarStartTime( DecalDissolveParamName, DurationOfDecal );
					}
					}
					else
					{
						WorldInfo.MyDecalManager.SpawnDecal( ExplosionDecal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 10.0, true );
					}
				}
			}
		}

		if (ExplosionSound != None && !bSuppressSounds)
		{
			PlaySound(ExplosionSound, true);
		}

		bSuppressExplosionFX = true; // so we don't get called again
	}
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		LightEnvironment=none
		bCastDynamicShadow=false
		CastShadow=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		MaxDrawDistance=4000
		bUseAsOccluder=FALSE
		bAcceptsDynamicDecals=FALSE
		CollideActors=false
		BlockActors=false
		AlwaysCheckCollision=false
		BlockRigidBody=false
		Scale=1.5
	End Object
	Mesh=StaticMeshComponent0
	Components.add(StaticMeshComponent0)
	projectilecomp=StaticMeshComponent0

	bImportantAmbientSound=true
	DamageRadius= 0.0
	CustomGravityScaling=0.5f
	MyDamageType=class'AOCDmgType_PierceProj'
	ProjType = EPROJ_Default
	YawRate = 0.0f
	PitchRate = 100000.0f
	RollRate = 0.0f
	//NewRotation = Rotator(Vect(0.0f, 0.0f,0.0f))
	//RepRotationRate = Rotator(Vect(0.0f, 0.0f,0.0f))
	RepSpeed = 0.0f
	RepMaxSpeed = 0.0f
	fProjectileAttachCompensation=15.0f
	NewGravity=-1.0f
	bInit= false
	//MovementDirection=Vect(0.0f,0.0f,0.0f)

	ImpactSounds= {(
		)}

	bAlwaysTick=true
	bCanPickupProj=true
	Drag = 0.0f
	TraceRadius = 0.0f
	TimeElapsed=0.0f
	DistanceTravelled=0.0f
	bFirstTick=true
	bHasTipComp=false
	
	bUseLongTracers=false
	NumTracers=5

	bNetTemporary=False
	bWaitForEffects=false

	ProjCamPosModX=-80
	ProjCamPosModZ=35
	bOverrideDefaultExplosionDeffect=false
	//RemoteRole=ROLE_Authority
	bDamagedSomething = false
	bHasShutdown = false
	ProjIdent=-1
	bEnableArrowCamAmbientSoundSwap=false
	bSpawnSticky=true
	bSpawnDroppedWeapon=false
	LastImpactSoundTime=0.f
	bLimitImpactSound=false
	bCanBeParried=false

	InitialRotation=(Pitch=0,Yaw=0,Roll=-16384)

	WeaponFontSymbol=""
	
	
	bCanBeReflected = false   //////////REFLECTION
	bIsReflected = false
}

