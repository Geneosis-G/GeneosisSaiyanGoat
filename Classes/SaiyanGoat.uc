class SaiyanGoat extends GGMutator;

var array< SaiyanGoatComponent > mComponents;

function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local SaiyanGoatComponent superSayComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		superSayComp=SaiyanGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'SaiyanGoatComponent', goat.mCachedSlotNr));
		if(superSayComp != none && mComponents.Find(superSayComp) == INDEX_NONE)
		{
			mComponents.AddItem(superSayComp);
		}
	}
}

simulated event Tick( float delta )
{
	local int i;

	for( i = 0; i < mComponents.Length; i++ )
	{
		mComponents[ i ].Tick( delta );
	}
	super.Tick( delta );
}

DefaultProperties
{
	mMutatorComponentClass=class'SaiyanGoatComponent'
}