class LSModProj_ThrownDagger extends LSModProjectile;

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'WP_throw_knife.ThrowingKnife_3rdP'
		Scale=1.0
		Rotation=(Pitch=0,Yaw=0,Roll=16384)
	End Object

	ProjExplosionTemplate=none
	ProjFlightTemplate=ParticleSystem'CHV_Particles_01.Particles.P_ArrowTrail'

//	speed=3000.0
//	MaxSpeed=4000.0
	TerminalVelocity=4000
//	Damage=30.0
	MomentumTransfer=500
	LifeSpan=10.0
	bCollideWorld=true
	bBounce=false
	Physics=PHYS_Falling
	CheckRadius=36.0
//	CustomGravityScaling=0.5

	AmbientSound=SoundCue'A_Projectile_Flight.Flight_dagger'
	ImpactSounds= {(
		Light=SoundCue'A_Impacts_Missile.dagger_Light',
		Medium=SoundCue'A_Impacts_Missile.dagger_Medium',
		Heavy=SoundCue'A_Impacts_Missile.dagger_Heavy',
		Stone=SoundCue'A_Phys_Mat_Impacts.knife_Stone',
		Dirt=SoundCue'A_Phys_Mat_Impacts.knife_Dirt',
		Wood=SoundCue'A_Phys_Mat_Impacts.knife_Wood',
		Gravel=SoundCue'A_Phys_Mat_Impacts.knife_Stone',
		Foliage=SoundCue'A_Phys_Mat_Impacts.knife_Dirt',
		Sand=SoundCue'A_Phys_Mat_Impacts.knife_Dirt',
		Water=SoundCue'A_Phys_Mat_Impacts.knife_water',
		ShallowWater=SoundCue'A_Phys_Mat_Impacts.knife_water',
		Metal=SoundCue'A_Phys_Mat_Impacts.knife_Stone',
		Snow=SoundCue'A_Phys_Mat_Impacts.knife_Dirt',
		Ice=SoundCue'A_Phys_Mat_Impacts.knife_Stone',
		Mud=SoundCue'A_Phys_Mat_Impacts.knife_Dirt',
		Tile=SoundCue'A_Phys_Mat_Impacts.knife_Stone')
	}
	ProjBlockedSound=SoundCue'A_Phys_Mat_Impacts.Knife_Wood'

	bNetTemporary=False
	bWaitForEffects=false
	
	YawRate = 0.0f
	PitchRate = -150000.0f
	RollRate = 0.0f
	fProjectileAttachCompensation=2.0f

	ProjCamPosModX=-60
	ProjCamPosModZ=25
	
	bCanBeParried=true 									//////////////////FROM_CDW
	
	bCanBeReflected = true
	
	////////////////////////////////////////////
	Damage=15
	Speed=2500.0
	MaxSpeed=3000.0
	Drag=0.000005
	CustomGravityScaling = 0.90
	PitchCorrection=200
	////////////////////////////////////////////////
}
