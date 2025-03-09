class SaiyanGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var SkeletalMeshComponent mHairMesh;
var GGCrosshairActor mCrosshairActor;

var bool lPressed;
var bool aPressed;
var bool zPressed;
var bool ePressed;
var bool mUseMemeSounds;
//hover
var bool mIsHovering;
//Ki blast
var bool mIsShooting;
var float mKiBlastShootSpeed;
var bool mKiBlastLeftSide;
var SoundCue mKiBlastSound;
var SoundCue mKiBlastMemeSound;
//Kamehameha
var bool mIsCharging;
var float mKamehamehaChargeTime;
var SoundCue mKamehamehaSound;
var SoundCue mKamehamehaMemeSound;
var SoundCue mChargeSound;
var AudioComponent mChargeAC;
var AudioComponent mKamehamehaAC;
var ParticleSystemComponent mChargeParticle;
var SoundCue mKamehamehaBeamSound;
var bool mIsBeamActive;
var float mBeamTime;
var vector mLockedLocation;
var rotator mLockedRotation;
var float mBeamLength;
var float mBeamRadius;
var float mBeamForce;
var ParticleSystemComponent mBeamRay;
var float mBeamDamageFrequency;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		mHairMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( mHairMesh, 'hairSocket' );

		gMe.MaxMultiJump+=4;
		gMe.JumpZ+=500;

		gMe.mesh.AttachComponent(mChargeParticle, 'Root');
		mChargeParticle.SetHidden(true);

		gMe.mesh.AttachComponent(mBeamRay, 'Root');
	}
}

function DetachFromPlayer()
{
	mCrosshairActor.DestroyCrosshair();
	super.DetachFromPlayer();
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			StartShooting();
		}
		if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey ))|| newKey == 'XboxTypeS_LeftTrigger')
		{
			StartCharging();
		}
		if(localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ))
		{
			mIsHovering=true;
		}

		if(newKey == 'L' || newKey == 'XboxTypeS_LeftShoulder')
		{
			lPressed=true;
		}
		else if((newKey == 'A' || newKey == 'XboxTypeS_LeftTrigger') && lPressed)
		{
			aPressed=true;
		}
		else if((newKey == 'Z' || newKey == 'XboxTypeS_RightTrigger') && aPressed)
		{
			zPressed=true;
		}
		else if((newKey == 'E' || newKey == 'XboxTypeS_RightShoulder') && zPressed)
		{
			ePressed=true;
		}
		else if((newKey == 'R' || newKey == 'XboxTypeS_A') && ePressed)
		{
			mUseMemeSounds= !mUseMemeSounds;
			myMut.WorldInfo.Game.Broadcast(myMut, "Meme sounds " $ (mUseMemeSounds?"enabled":"disabled"));
		}
		else
		{
			lPressed=false;
			aPressed=false;
			zPressed=false;
			ePressed=false;
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			StopShooting();
		}
		if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey ))|| newKey == 'XboxTypeS_LeftTrigger')
		{
			StopCharging(false);
		}
		if(localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ))
		{
			mIsHovering=false;
		}
	}
}

function StartShooting()
{
	if(mIsCharging
	|| mIsBeamActive)
		return;

	mIsShooting=true;
	if(!gMe.IsTimerActive(nameof(ShootKiBlast), self))
	{
		ShootKiBlast();
	}
}

function StopShooting()
{
	mIsShooting=false;
}

function ShootKiBlast()
{
	local vector pos, left;
	local rotator rot;
	local KiBlast kb;

	if(gMe.mIsRagdoll
	|| !mIsShooting)
		return;
	//Shoot the blast
	rot = gMe.Rotation;
	left = Normal(vector(rot) cross vect(0, 0, 1));
	if(mKiBlastLeftSide)
		left = -left;
	pos = GetShootLocation();
	pos = pos + (left * gMe.GetCollisionRadius());

	gMe.PlaySound(mUseMemeSounds?mKiBlastMemeSound:mKiBlastSound);
	kb = gMe.Spawn(class'KiBlast', gMe,, pos, rot,, true);
	kb.mTargetLoc=mCrosshairActor.Location;

	//Prepare next blast
	mKiBlastLeftSide = !mKiBlastLeftSide;
	gMe.SetTimer(mKiBlastShootSpeed, false, nameof(ShootKiBlast), self);
}

function StartCharging()
{
	if(gMe.mIsRagdoll
	|| mIsBeamActive)
		return;

	if( mChargeAC == none || mChargeAC.IsPendingKill() )
	{
		mChargeAC = gMe.CreateAudioComponent( mChargeSound, false );
		mChargeAC.AdjustVolume(0.1f, 0.25f);
	}
	if( mChargeAC.IsPlaying() )
	{
		mChargeAC.Stop();
	}
	mChargeAC.Play();

	if( mKamehamehaAC != none && mKamehamehaAC.IsPlaying() )
	{
		mKamehamehaAC.Stop();
	}
	mKamehamehaAC = gMe.CreateAudioComponent( (mUseMemeSounds?mKamehamehaMemeSound:mKamehamehaSound), false );
	mKamehamehaAC.AdjustVolume(0.1f, 2.f);
	mKamehamehaAC.bAutoDestroy=true;
	mKamehamehaAC.Play();

	mChargeParticle.SetHidden(false);
	//No ki blast when chargin or shootink Kamehameha
	StopShooting();

	//Stop air movement
	if(gMe.Physics == PHYS_Falling)
	{
		gMe.Velocity=vect(0, 0, 0);
	}

	gMe.SetTimer(mKamehamehaChargeTime, false, nameof(ChargeReady), self);
	mIsCharging=true;
}

function ChargeReady()
{
	StopCharging(true);
}

function StopCharging(bool shoot)
{
	if(mIsBeamActive
	|| !mIsCharging)
		return;

	if( mChargeAC.IsPlaying() )
	{
		mChargeAC.Stop();
	}
	if(gMe.IsTimerActive(nameof(ChargeReady), self))
	{
		gMe.ClearTimer(NameOf(ChargeReady), self);
	}
	mChargeParticle.SetHidden(true);
	//if Kamehameha is ready
	if(shoot)
	{
		ShootKamehameha();
	}
	//else charge was cancelled
	else
	{
		mKamehamehaAC.Stop();
	}

	mIsCharging=false;
}

function ShootKamehameha()
{
	local int i;
	local vector StartLocation, EndLocation;

	StartLocation = GetShootLocation();
	EndLocation=StartLocation + (Normal(mCrosshairActor.Location - StartLocation) * mBeamLength);

	mBeamRay.SetVectorParameter( 'BeamEnd', EndLocation );
	mBeamRay.SetVectorParameter( 'beamStart', StartLocation );

	for( i = 0; i < 6; i++ )
	{
		mBeamRay.SetBeamSourcePoint( i, StartLocation, 0 );
		mBeamRay.SetBeamTargetPoint( i, EndLocation, 0 );
	}

	mBeamRay.ActivateSystem();

	mIsBeamActive=true;
	mLockedLocation=gMe.Location;
	mLockedRotation=gMe.Rotation;
	gMe.SetTimer(mBeamTime, false, nameof(EndBeam), self);

	DoBeamDamages();
}

function DoBeamDamages()
{
	if(!mIsBeamActive)
		return;

	FindNearbyActorsOfClass(class'GGPawn');
	FindNearbyActorsOfClass(class'GGKactor');
	FindNearbyActorsOfClass(class'GGSVehicle');
	FindNearbyActorsOfClass(class'GGApexDestructibleActor');

	gMe.SetTimer(mBeamDamageFrequency, false, nameof(DoBeamDamages), self);
}

function FindNearbyActorsOfClass(class<Actor> actorClass)
{
	local Actor act;
	local vector center, dist;

	dist = Normal(mCrosshairActor.Location - GetShootLocation()) * mBeamLength;
	center = GetShootLocation() + (dist/2.f);
	//gMe.DrawDebugSphere( center, mBeamLength/2.f, 10, 255, 255, 255, true);
	foreach gMe.CollidingActors(actorClass, act, mBeamLength/2.f, center)
	{
		if(!shouldIgnoreActor(act))
		{
			HitTarget(act);
		}
	}
}

function bool shouldIgnoreActor(Actor act)
{
	//WorldInfo.Game.Broadcast(self, "shouldIgnoreActor=" $ act);
	return (
	act == none
	|| act == gMe
	|| act.Owner == gMe);
}

function HitTarget(optional Actor target=none)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local GGKactor kActor;
	local GGSVehicle vehicle;
	local float mass;
	local vector direction, newVelocity;
	local int damage;

	direction = GetDirectionFromBeam(target);
	if(VSize(direction) == 0.f)//Not in beam, forget this actor
		return;

	gpawn = GGPawn(target);
	mmoEnemy = GGNPCMMOEnemy(target);
	zombieEnemy = GGNpcZombieGameModeAbstract(target);
	kActor = GGKActor(target);
	vehicle = GGSVehicle(target);
	if(gpawn != none)
	{
		mass=50.f;
		if(!gpawn.mIsRagdoll)
		{
			gpawn.SetRagdoll(true);
		}
		newVelocity = gpawn.mesh.GetRBLinearVelocity() + (direction * mBeamForce);
		gpawn.Mesh.SetRBLinearVelocity(newVelocity);
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			damage = int(RandRange(10, 30));
			damage *= 3;
			mmoEnemy.TakeDamageFrom(damage, gMe, class'GGDamageTypeExplosiveActor');
		}
		else
		{
			gpawn.TakeDamage( 0.f, gMe.Controller, gpawn.Location, vect(0, 0, 0), class'GGDamageType',, gMe);
		}
		//Damage zombies
		if(zombieEnemy != none)
		{
			damage = int(RandRange(10, 30));
			damage *= 3;
			zombieEnemy.TakeDamage(damage, gMe.Controller, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode' );
		}
	}
	if(kActor != none)
	{
		mass=kActor.StaticMeshComponent.BodyInstance.GetBodyMass();
		//WorldInfo.Game.Broadcast(self, "Mass : " $ mass);
		kActor.TakeDamage(10000000, none, target.Location, direction * mass * mBeamForce, class'GGDamageTypeAbility',, gMe);
	}
	else if(vehicle != none)
	{
		mass=vehicle.Mass;
		vehicle.AddForce(direction * mass * mBeamForce);
	}
	else if(GGApexDestructibleActor(target) != none)
	{
		target.TakeDamage(10000000, gMe.Controller, target.Location, direction * mass * mBeamForce, class'GGDamageTypeAbility',, gMe);
	}
}

function vector GetDirectionFromBeam(Actor act)
{
	local vector A, B, P, Q, distToBeam, distToEnd;

	A=GetShootLocation();
	B=mCrosshairActor.Location;
	P=GetLocation(act);
	Q = A + Normal( B - A ) * ((( B - A ) dot ( P - A )) / VSize( A - B ));

	distToEnd=B-A;
	distToBeam=P-Q;
	//gMe.DrawDebugSphere( Q, mBeamRadius, 10, 200, 200, 200, true);
	//if out of beam
	if(VSize(distToBeam) > mBeamRadius + GetCollisionSize(act))
		return vect(0, 0, 0);

	return Normal(Normal(distToEnd) + Normal(distToBeam));
}

function vector GetLocation(Actor act)
{
	if(GGPawn(act) != none && GGPawn(act).mIsRagdoll)
		return GGPawn(act).Mesh.GetPosition();
	else
		return act.Location;
}

function float GetCollisionSize(Actor act)
{
	local float r, h;

	act.GetBoundingCylinder(r, h);
	return r;
}

function EndBeam(bool force)
{
	if(!mIsBeamActive)
		return;

	if(force)
	{
		mKamehamehaAC.Stop();
		gMe.ClearTimer(NameOf(EndBeam), self);
	}

	mBeamRay.SetActive( false );
	mBeamRay.DeactivateSystem();

	mIsBeamActive=false;
	mLockedLocation=vect(0, 0, 0);
	mLockedRotation=rot(0, 0, 0);
}

function vector GetShootLocation()
{
	return gMe.Location + GetShootOffset();
}

function vector GetShootOffset()
{
	return Normal(vector(gMe.Rotation)) * gMe.GetCollisionRadius() * 1.5f;
}

function Tick( float deltaTime )
{
	//Update crosshair
	if(mCrosshairActor == none || mCrosshairActor.bPendingDelete)
	{
		mCrosshairActor = gMe.Spawn(class'GGCrosshairActor');
		mCrosshairActor.SetColor(MakeLinearColor( 135.f/255.f, 206.f/255.f, 235.f/255.f, 1.0f ));
	}
	UpdateCrosshair(GetShootLocation());
	// Don't use abilities when driving
	if(gMe.DrivenVehicle != none
	&&(mIsShooting || mIsCharging || mIsBeamActive))
	{
		StopShooting();
		StopCharging(false);
		EndBeam(true);
	}
	//hover ability
	if(gMe.Physics == PHYS_Falling && mIsHovering && gMe.Velocity.Z<0)
	{
		gMe.Velocity.Z=0;
	}
	//static when shooting beam (unless player ragdolled)
	if(mIsBeamActive && !gMe.mIsRagdoll)
	{
		LockPositionAndRotation();
	}
}

function UpdateCrosshair(vector aimLocation)
{
	local vector			StartTrace, EndTrace, AdjustedAim, camLocation;
	local rotator 			camRotation;
	local Array<ImpactInfo>	ImpactList;
	local ImpactInfo 		RealImpact;
	local float 			Radius;

	if(gMe == none || GGPlayerControllerGame( gMe.Controller ) == none || mCrosshairActor == none)
		return;

	StartTrace = aimLocation;
	if(mIsCharging || mIsBeamActive)
	{
		AdjustedAim=vector(gMe.Rotation);
	}
	else
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
		camRotation.Pitch+=1800.f;
		AdjustedAim = vector(camRotation);
	}

	Radius = mCrosshairActor.SkeletalMeshComponent.SkeletalMesh.Bounds.SphereRadius;
	EndTrace = StartTrace + AdjustedAim * (mBeamLength - Radius);

	RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

	mCrosshairActor.UpdateCrosshair(RealImpact.hitLocation, -AdjustedAim);
}

simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList)
{
	local vector			HitLocation, HitNormal;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local ImpactInfo		CurrentImpact;

	HitActor = CustomTrace(HitLocation, HitNormal, EndTrace, StartTrace, HitInfo);

	if( HitActor == None )
	{
		HitLocation	= EndTrace;
	}

	CurrentImpact.HitActor		= HitActor;
	CurrentImpact.HitLocation	= HitLocation;
	CurrentImpact.HitNormal		= HitNormal;
	CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
	CurrentImpact.StartTrace	= StartTrace;
	CurrentImpact.HitInfo		= HitInfo;

	ImpactList[ImpactList.Length] = CurrentImpact;

	return CurrentImpact;
}

function Actor CustomTrace(out vector HitLocation, out vector HitNormal, vector EndTrace, vector StartTrace, out TraceHitInfo HitInfo)
{
	local Actor hitActor, retActor;

	foreach gMe.TraceActors(class'Actor', hitActor, HitLocation, HitNormal, EndTrace, StartTrace, ,HitInfo)
    {
		if(hitActor != gMe
		&& hitActor.Owner != gMe
		&& hitActor.Base != gMe
		&& hitActor != gMe.mGrabbedItem
		&& !hitActor.bHidden)
		{
			retActor=hitActor;
			break;
		}
    }

    return retActor;
}

function LockPositionAndRotation()
{
	local GGPlayerControllerGame GPC;

	if(VSize(mLockedLocation) == 0)
		return;

	gMe.SetLocation(mLockedLocation);
	gMe.Velocity=vect(0, 0, 0);
	gMe.SetRotation(mLockedRotation);

	GPC = GGPlayerControllerGame( gMe.Controller );
	GPC.mRotationRate = rot(0, 0, 0);
	gMe.mTotalRotation = rot( 0, 0, 0 );
}

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == gMe)
	{
		if(isRagdoll)
		{
			StopShooting();
			StopCharging(false);
			EndBeam(true);
		}
	}
}

defaultproperties
{
	mKiBlastShootSpeed=0.5f
	mKamehamehaChargeTime=4.f
	mBeamTime=3.f
	mBeamLength=10000.f
	mBeamRadius=50.f
	mBeamForce=2000.f
	mBeamDamageFrequency=0.3f

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComp1
		SkeletalMesh=SkeletalMesh'Goat_Zombie.mesh.GoatBeard'
		PhysicsAsset=PhysicsAsset'Goat_Zombie.Mesh.GoatBeard_Physics'
		Rotation=(Pitch=0, Yaw=16384, Roll=32768)//16384 //32768
		Translation=(X=0, Y=15, Z=-5)
		scale=2.f
		Materials(0)=Material'Props_01.Materials.Bicycle_Yellow_Mat'
			bHasPhysicsAssetInstance=true
			bCacheAnimSequenceNodes=false
			AlwaysLoadOnClient=true
			AlwaysLoadOnServer=true
			bOwnerNoSee=false
			CastShadow=true
			BlockRigidBody=true
			CollideActors=true
			bUpdateSkelWhenNotRendered=false
			bIgnoreControllersWhenNotRendered=true
			bUpdateKinematicBonesFromAnimation=true
			bCastDynamicShadow=true
			RBChannel=RBCC_Untitled3
			RBCollideWithChannels=(Untitled1=false,Untitled2=false,Untitled3=true,Vehicle=true)
			bOverrideAttachmentOwnerVisibility=true
			bAcceptsDynamicDecals=false
			TickGroup=TG_PreAsyncWork
			MinDistFactorForKinematicUpdate=0.0
			bChartDistanceFactor=true
			RBDominanceGroup=15
			bSyncActorLocationToRootRigidBody=true
			bNotifyRigidBodyCollision=true
			ScriptRigidBodyCollisionThreshold=1
	        BlockActors=TRUE
			AlwaysCheckCollision=TRUE
	End Object
	mHairMesh=SkeletalMeshComp1

	mKiBlastSound=SoundCue'SaiyanGoat.KiBlastCue'
	mKiBlastMemeSound=SoundCue'SaiyanGoat.PewCue'

	mChargeSound=none//SoundCue'Heist_Audio.Cue.SFX_SlapMan_Stereo_Cue'
	mKamehamehaSound=SoundCue'SaiyanGoat.KamehamehaCue'
	mKamehamehaMemeSound=SoundCue'SaiyanGoat.ShoopDaWhoopCue'

	Begin Object class=ParticleSystemComponent Name=ParticleSystemComponent1
        Template=ParticleSystem'Heist_Effects_01.Effects.Effect_Slap_01'
        Translation=(X=100, Y=0, Z=0)
	End Object
	mChargeParticle=ParticleSystemComponent1

	Begin Object class=ParticleSystemComponent Name=ParticleSystemComponent2
		Template=ParticleSystem'Space_Particles.Particles.GGFPSpaceCraft_Laser'
		Scale3D=(X=4,Y=4,Z=4)
		Translation=(X=100, Y=0, Z=0)
		bAutoActivate=false
	End Object
	mBeamRay=ParticleSystemComponent2
}