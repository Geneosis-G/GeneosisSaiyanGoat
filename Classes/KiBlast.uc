class KiBlast extends GGKActor;

var vector mTargetLoc;

var float blastForce;
var float blastSpeed;
var float rotationInterpSpeed;

var ParticleSystemComponent mTrailParticle;
var ParticleSystem mTrailEffectTemplate;

var vector oldDirection;
var bool mAimForward;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	//WorldInfo.Game.Broadcast(self, "LaserSwordSpawned=" $ self);
	mTrailParticle = WorldInfo.MyEmitterPool.SpawnEmitter( mTrailEffectTemplate, Location, Rotation, self );
	mTrailParticle.SetScale3D(vect(0.5f, 0.5f, 0.5f));
	mTrailParticle.CustomTimeDilation=3.f;

	StaticMeshComponent.BodyInstance.CustomGravityFactor=0.f;
	CollisionComponent.WakeRigidBody();
	StaticMeshComponent.SetRBLinearVelocity(Normal(vector(Rotation)) * blastSpeed);
	// Dissapear after 10 seconds of flight
	SetTimer(10.f, false, NameOf(HitAndDissapear));
}

function bool shouldIgnoreActor(Actor act)
{
	//WorldInfo.Game.Broadcast(self, "shouldIgnoreActor=" $ act);
	return (
	act == none
	|| Volume(act) != none
	|| act == self
	|| act.Owner == Owner
	|| (GGApexDestructibleActor(act) != none && GGApexDestructibleActor(act).mIsFractured));
}

simulated event TakeDamage( int damage, Controller eventInstigator, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	super.TakeDamage(damage, eventInstigator, hitLocation, momentum, damageType, hitInfo, damageCauser);
	//WorldInfo.Game.Broadcast(self, "TakeDamage");
	if(shouldIgnoreActor(damageCauser))
    {
        return;
    }
	//WorldInfo.Game.Broadcast(self, "TakeDamage=" $ damageCauser);
	HitAndDissapear(damageCauser);
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
    super.Bump(Other, OtherComp, HitNormal);
	//WorldInfo.Game.Broadcast(self, "Bump");
	if(shouldIgnoreActor(other))
    {
        return;
    }
	//WorldInfo.Game.Broadcast(self, "Bump=" $ other);
	HitAndDissapear(other);
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex);
	//WorldInfo.Game.Broadcast(self, "RBCollision");
	if(shouldIgnoreActor(OtherComponent.Owner))
    {
        return;
    }
	//WorldInfo.Game.Broadcast(self, "RBCollision=" $ OtherComponent.Owner);
	HitAndDissapear(OtherComponent!=none?OtherComponent.Owner:none);
}

function HitAndDissapear(optional Actor target=none)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local GGKactor kActor;
	local GGSVehicle vehicle;
	local float mass;
	local vector direction, newVelocity;
	local int damage;
	//WorldInfo.Game.Broadcast(self, "HitAndDissapear(" $ target $ ")");
	direction = Normal(oldDirection);

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
		newVelocity = gpawn.mesh.GetRBLinearVelocity() + (direction * blastForce);
		gpawn.Mesh.SetRBLinearVelocity(newVelocity);
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			damage = int(RandRange(10, 30));
			mmoEnemy.TakeDamageFrom(damage, Owner, class'GGDamageTypeExplosiveActor');
		}
		else
		{
			gpawn.TakeDamage( 0.f, GGGoat(Owner).Controller, gpawn.Location, vect(0, 0, 0), class'GGDamageType',, Owner);
		}
		//Damage zombies
		if(zombieEnemy != none)
		{
			damage = int(RandRange(10, 30));
			zombieEnemy.TakeDamage(damage, GGGoat(Owner).Controller, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode' );
		}
	}
	if(kActor != none)
	{
		mass=kActor.StaticMeshComponent.BodyInstance.GetBodyMass();
		//WorldInfo.Game.Broadcast(self, "Mass : " $ mass);
		kActor.TakeDamage(10000000, none, target.Location, direction * mass * blastForce, class'GGDamageTypeAbility',, Owner);
	}
	else if(vehicle != none)
	{
		mass=vehicle.Mass;
		vehicle.AddForce(direction * mass * blastForce);
	}
	else if(GGApexDestructibleActor(target) != none)
	{
		target.TakeDamage(10000000, GGGoat(Owner).Controller, target.Location, direction * mass * blastForce, class'GGDamageTypeAbility',, Owner);
	}

	if(mTrailParticle.bIsActive)
	{
		mTrailParticle.DeactivateSystem();
	}
	//WorldInfo.Game.Broadcast(self, "LaserSwordDestroyedBy=" $ target);
	ShutDown();
	Destroy();
}

simulated event Tick( float deltaTime )
{
	local GGPawn gpawn;
	local vector targetLoc, newDirection;
	local float oldSpeed;

	// Try to prevent pawns from walking on it
	foreach BasedActors(class'GGPawn', gpawn)
	{
		HitAndDissapear(gpawn);
	}

	super.Tick(deltaTime);

	// Aim at target
	targetLoc=mTargetLoc;
	if(!IsZero(targetLoc))
	{
		oldSpeed = VSize(Velocity);
		if(VSize(Location-targetLoc) < 1.f)
		{
			HitAndDissapear();
		}
		else if(oldSpeed > 0.f)
		{
			// Rotate the blast in the direction of its velocity
			StaticMeshComponent.SetRBRotation(rotator(Normal(Velocity)) + rot(-16384, 0, 0));

			if(mAimForward)
			{
				newDirection=oldDirection;
			}
			else
			{
				newDirection=AimAt(deltaTime, targetLoc);
			}
			//When aligned or passed the target, keep going forward
			if(IsAngleCloseEnough(oldDirection, newDirection) || WentPastTarget())
			{
				mAimForward=true;
				if(VSize(oldDirection) > 0.f)
				{
					newDirection=oldDirection;
				}
			}
			oldDirection = newDirection;
			StaticMeshComponent.SetRBLinearVelocity(newDirection * blastSpeed);
		}
	}
}

function bool WentPastTarget()
{
	local vector A, B, P, Q, distToSelf, distToTarget;

	A=Owner.Location;
	B=mTargetLoc;
	P=Location;
	Q = A + Normal( B - A ) * ((( B - A ) dot ( P - A )) / VSize( A - B ));

	distToSelf=Q-A;
	distToTarget=B-A;

	return (distToSelf dot distToTarget) > 0 && VSize(distToSelf) > VSize(distToTarget);
}

function bool IsAngleCloseEnough(vector A, vector B)
{
	return Acos(Normal(A) dot Normal(B)) < 0.001;
}

function vector AimAt(float deltaTime, vector aimLocation)
{
	local rotator dir, expectedDir;
	local vector newDirection;

	dir=rotator(Normal(StaticMeshComponent.GetRBLinearVelocity()));
	expectedDir=rotator(Normal(aimLocation-Location));

	newDirection=Normal(vector(RInterpTo( dir, expectedDir, deltaTime, rotationInterpSpeed, false )));

	return newDirection;
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
	mBlockCamera=false

	blastForce=1500.f
	blastSpeed=5000.f
	rotationInterpSpeed=10.f

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Props_01.Mesh.Baseball_01'
		Materials(0)=Material'Heist_Effects_01.Effects.PlasmaBall_Mat'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Translation=(X=0, Y=0, Z=0)
	End Object

	mTrailEffectTemplate=ParticleSystem'Space_Particles.Particles.TrailerShip_Trail_PS'

	bCollideActors=true
	bBlockActors=true
	bCollideWorld=true;
}