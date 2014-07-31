/**
* Copyright 2010-2012, Torn Banner Studios, All rights reserved
*
* Original Author: Eric "wcire" Williams
*
* Spawnable KActor
* 
* ***********************************************************************************
* Description:  Spawned from AOCWeapon (Before CurrentWeaponAttachmentClass is 
* cleared) as a weapon is detached from a pawn on death.  
*/


class LSModDroppedWeapon extends KActorSpawnable;

var Vector MeshScale;
var StaticMesh WeaponStaticMesh;
var bool bInitialized;

event Tick(float DeltaTime)
{
	if(!bInitialized && WeaponStaticMesh != none)
	{
		bInitialized = true;

		SetStaticMesh(WeaponStaticMesh, , , MeshScale);
		SetPhysicalCollisionProperties();

		reset();
		Initialize();

		TossWeapon();		
		bTearOff = true;
	}
	
	super.Tick(DeltaTime);
}

simulated function SetMeshAndInitialize(StaticMesh myWeaponStaticMesh, float Scale)
{
	// 1.5 Scaling included for character scale
	MeshScale = 1.5 * Scale * vect(1,1,1);
	self.WeaponStaticMesh = myWeaponStaticMesh;
	bInitialized = false;
}

simulated function TossWeapon()
{
	local Vector TossVector;

	TossVector.X = 90 * ( FRand() - FRand() );
	TossVector.Y = 90 * ( FRand() - FRand() );
	TossVector.Z = 90 * ( FRand() - FRand() );
	CollisionComponent.SetRBAngularVelocity(TossVector);

	TossVector.X = 200 * ( FRand() - FRand() );
	TossVector.Y = 200 * ( FRand() - FRand() );
	TossVector.Z = 140 * FRand();
	CollisionComponent.SetRBLinearVelocity(TossVector);

}

event ApplyImpulse( Vector ImpulseDir, float ImpulseMag, Vector HitLocation, optional TraceHitInfo HitInfo, optional class<DamageType> DamageType )
{
}

simulated event ShutDown()
{
	//ScriptTrace();
	super.ShutDown();
}

simulated event Attach(Actor Other)
{
	//ScriptTrace();
	super.Attach(Other);
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		Scale=1
		bNotifyRigidBodyCollision=false
        HiddenGame=false 


        CollideActors=false
        BlockActors=false
        AlwaysCheckCollision=true
        ScriptRigidBodyCollisionThreshold=0.001
		RBChannel=RBCC_NOTHING
		RBCollideWithChannels=(default=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,Pawn=FALSE,DeadPawn=FALSE)
	end object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	components.add(StaticMeshComponent0)
	
	bWakeOnLevelStart=true

	bCollideWorld=true
    bCollideActors=false
	bNoEncroachCheck=false
	bBlocksTeleport=false
	bBlocksNavigation=false
	bPawnCanBaseOn=false
	bSafeBaseIfAsleep=false
	bNeedsRBStateReplication=true
	//bCanTeleport=false
	bTearOff = true //never ever has to exist on the server

	LifeSpan = 30
	
	TickGroup=TG_PostAsyncWork
	bInitialized = false
}