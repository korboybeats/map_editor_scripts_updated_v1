global function Desertlands_PreMapInit_Common
global function Desertlands_MapInit_Common
global function CodeCallback_PlayerEnterUpdraftTrigger
global function CodeCallback_PlayerLeaveUpdraftTrigger

#if SERVER
global function Desertlands_MU1_MapInit_Common
global function Desertlands_MU1_EntitiesLoaded_Common
global function Desertlands_MU1_UpdraftInit_Common
global function Desertlands_SetTrainEnabled
#endif


#if SERVER
//Copied from _jump_pads. This is being hacked for the geysers.
const float JUMP_PAD_PUSH_RADIUS = 256.0
const float JUMP_PAD_PUSH_PROJECTILE_RADIUS = 32.0//98.0
const float JUMP_PAD_PUSH_VELOCITY = 2000.0
const float JUMP_PAD_VIEW_PUNCH_SOFT = 25.0
const float JUMP_PAD_VIEW_PUNCH_HARD = 4.0
const float JUMP_PAD_VIEW_PUNCH_RAND = 4.0
const float JUMP_PAD_VIEW_PUNCH_SOFT_TITAN = 120.0
const float JUMP_PAD_VIEW_PUNCH_HARD_TITAN = 20.0
const float JUMP_PAD_VIEW_PUNCH_RAND_TITAN = 20.0
const TEAM_JUMPJET_DBL = $"P_team_jump_jet_ON_trails"
const ENEMY_JUMPJET_DBL = $"P_enemy_jump_jet_ON_trails"
const asset JUMP_PAD_MODEL = $"mdl/props/octane_jump_pad/octane_jump_pad.rmdl"

const float JUMP_PAD_ANGLE_LIMIT = 0.70
const float JUMP_PAD_ICON_HEIGHT_OFFSET = 48.0
const float JUMP_PAD_ACTIVATION_TIME = 0.5
const asset JUMP_PAD_LAUNCH_FX = $"P_grndpnd_launch"
const JUMP_PAD_DESTRUCTION = "jump_pad_destruction"

// Loot drones
const int NUM_LOOT_DRONES_TO_SPAWN = 12
const int NUM_LOOT_DRONES_WITH_VAULT_KEYS = 4
#endif

struct
{
	#if SERVER
	bool isTrainEnabled = true
	#endif
} file

void function Desertlands_PreMapInit_Common()
{
	//DesertlandsTrain_PreMapInit()
}

void function Desertlands_MapInit_Common()
{
	printt( "Desertlands_MapInit_Common" )

	MapZones_RegisterDataTable( $"datatable/map_zones/zones_mp_rr_desertlands_64k_x_64k.rpak" )

	FlagInit( "PlayConveyerStartFX", true )

	SetVictorySequencePlatformModel( $"mdl/rocks/desertlands_victory_platform.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )

	#if SERVER
		//%if HAS_LOOT_DRONES && HAS_LOOT_ROLLERS
		InitLootDrones()
		InitLootRollers()
		//%endif

		AddCallback_EntitiesDidLoad( EntitiesDidLoad )

		SURVIVAL_SetPlaneHeight( 15250 )
		SURVIVAL_SetAirburstHeight( 2500 )
		SURVIVAL_SetMapCenter( <0, 0, 0> )
		//Survival_SetMapFloorZ( -8000 )

		//if ( file.isTrainEnabled )
		//	DesertlandsTrain_Precaches()

		AddSpawnCallback_ScriptName( "desertlands_train_mover_0", AddTrainToMinimap )

		SpawnEditorProps()
	#endif

	#if CLIENT
		Freefall_SetPlaneHeight( 15250 )
		Freefall_SetDisplaySeaHeightForLevel( -8961.0 )

		SetVictorySequenceLocation( <11092.6162, -20878.0684, 1561.52222>, <0, 267.894653, 0> )
		SetVictorySequenceSunSkyIntensity( 1.0, 0.5 )
		SetMinimapBackgroundTileImage( $"overviews/mp_rr_canyonlands_bg" )

		// RegisterMinimapPackage( "prop_script", eMinimapObject_prop_script.TRAIN, MINIMAP_OBJECT_RUI, MinimapPackage_Train, FULLMAP_OBJECT_RUI, FullmapPackage_Train )
	#endif
}

#if SERVER
void function EntitiesDidLoad()
{
	#if SERVER && DEV
		test_runmapchecks()
	#endif

	GeyserInit()
	Updrafts_Init()

	InitLootDronePaths()

	string currentPlaylist = GetCurrentPlaylistName()
	// thread SpawnLootDrones( GetPlaylistVarInt( currentPlaylist, "loot_drones_spawn_count", NUM_LOOT_DRONES_TO_SPAWN ) )

	int keyCount = GetPlaylistVarInt( currentPlaylist, "loot_drones_vault_key_count", NUM_LOOT_DRONES_WITH_VAULT_KEYS )
	//if ( keyCount > 0 )
	//	LootRollers_ForceAddLootRefToRandomLootRollers( "data_knife", keyCount )

	if ( file.isTrainEnabled )
		thread DesertlandsTrain_Init()
}
#endif

#if SERVER
void function Desertlands_SetTrainEnabled( bool enabled )
{
	file.isTrainEnabled = enabled
}
#endif

//=================================================================================================
//=================================================================================================
//
//  ##     ## ##     ##    ##       ######   #######  ##     ## ##     ##  #######  ##    ##
//  ###   ### ##     ##  ####      ##    ## ##     ## ###   ### ###   ### ##     ## ###   ##
//  #### #### ##     ##    ##      ##       ##     ## #### #### #### #### ##     ## ####  ##
//  ## ### ## ##     ##    ##      ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ##
//  ##     ## ##     ##    ##      ##       ##     ## ##     ## ##     ## ##     ## ##  ####
//  ##     ## ##     ##    ##      ##    ## ##     ## ##     ## ##     ## ##     ## ##   ###
//  ##     ##  #######   ######     ######   #######  ##     ## ##     ##  #######  ##    ##
//
//=================================================================================================
//=================================================================================================

#if SERVER
void function Desertlands_MU1_MapInit_Common()
{
	AddSpawnCallback_ScriptName( "conveyor_rotator_mover", OnSpawnConveyorRotatorMover )

	Desertlands_MapInit_Common()
	PrecacheParticleSystem( JUMP_PAD_LAUNCH_FX )

	//SURVIVAL_SetDefaultLootZone( "zone_medium" )

	//LaserMesh_Init()
	FlagSet( "DisableDropships" )

	AddDamageCallbackSourceID( eDamageSourceId.burn, OnBurnDamage )

	svGlobal.evacEnabled = false //Need to disable this on a map level if it doesn't support it at all
}


void function OnBurnDamage( entity player, var damageInfo )
{
	if ( !player.IsPlayer() )
		return

	// sky laser shouldn't hurt players in plane
	if ( player.GetPlayerNetBool( "playerInPlane" ) )
	{
		DamageInfo_SetDamage( damageInfo, 0 )
	}
}

///////////////////////
///////////////////////
//// Conveyor


void function OnSpawnConveyorRotatorMover( entity mover )
{
	thread ConveyorRotatorMoverThink( mover )
}


void function ConveyorRotatorMoverThink( entity mover )
{
	mover.EndSignal( "OnDestroy" )

	entity rotator = GetEntByScriptName( "conveyor_rotator" )
	entity startNode
	entity endNode

	array<entity> links = rotator.GetLinkEntArray()
	foreach ( l in links )
	{
		if ( l.GetValueForKey( "script_noteworthy" ) == "end" )
			endNode = l
		if ( l.GetValueForKey( "script_noteworthy" ) == "start" )
			startNode = l
	}


	float angle1 = VectorToAngles( startNode.GetOrigin() - rotator.GetOrigin() ).y
	float angle2 = VectorToAngles( endNode.GetOrigin() - rotator.GetOrigin() ).y

	float angleDiff = angle1 - angle2
	angleDiff = (angleDiff + 180) % 360 - 180

	float rotatorSpeed = float( rotator.GetValueForKey( "rotate_forever_speed" ) )
	float waitTime     = fabs( angleDiff ) / rotatorSpeed

	Assert( IsValid( endNode ) )

	while ( 1 )
	{
		mover.WaitSignal( "ReachedPathEnd" )

		mover.SetParent( rotator, "", true )

		wait waitTime

		mover.ClearParent()
		mover.SetOrigin( endNode.GetOrigin() )
		mover.SetAngles( endNode.GetAngles() )

		thread MoverThink( mover, [ endNode ] )
	}
}


void function Desertlands_MU1_UpdraftInit_Common( entity player )
{
	//ApplyUpdraftModUntilTouchingGround( player )
	thread PlayerSkydiveFromCurrentPosition( player )
	thread BurnPlayerOverTime( player )
}


void function Desertlands_MU1_EntitiesLoaded_Common()
{
	GeyserInit()
	Updrafts_Init()
}


//Geyster stuff
void function GeyserInit()
{
	array<entity> geyserTargets = GetEntArrayByScriptName( "geyser_jump" )
	foreach ( target in geyserTargets )
	{
		thread GeyersJumpTriggerArea( target )
		//target.Destroy()
	}
}


void function GeyersJumpTriggerArea( entity jumpPad )
{
	Assert ( IsNewThread(), "Must be threaded off" )
	jumpPad.EndSignal( "OnDestroy" )

	vector origin = OriginToGround( jumpPad.GetOrigin() )
	vector angles = jumpPad.GetAngles()

	entity trigger = CreateEntity( "trigger_cylinder_heavy" )
	SetTargetName( trigger, "geyser_trigger" )
	trigger.SetOwner( jumpPad )
	trigger.SetRadius( JUMP_PAD_PUSH_RADIUS )
	trigger.SetAboveHeight( 32 )
	trigger.SetBelowHeight( 16 ) //need this because the player or jump pad can sink into the ground a tiny bit and we check player feet not half height
	trigger.SetOrigin( origin )
	trigger.SetAngles( angles )
	trigger.SetTriggerType( TT_JUMP_PAD )
	trigger.SetLaunchScaleValues( JUMP_PAD_PUSH_VELOCITY, 1.25 )
	trigger.SetViewPunchValues( JUMP_PAD_VIEW_PUNCH_SOFT, JUMP_PAD_VIEW_PUNCH_HARD, JUMP_PAD_VIEW_PUNCH_RAND )
	trigger.SetLaunchDir( <0.0, 0.0, 1.0> )
	trigger.UsePointCollision()
	trigger.kv.triggerFilterNonCharacter = "0"
	DispatchSpawn( trigger )
	trigger.SetEnterCallback( Geyser_OnJumpPadAreaEnter )

	// entity traceBlocker = CreateTraceBlockerVolume( trigger.GetOrigin(), 24.0, true, CONTENTS_BLOCK_PING | CONTENTS_NOGRAPPLE, TEAM_MILITIA, GEYSER_PING_SCRIPT_NAME )
	// traceBlocker.SetBox( <-192, -192, -16>, <192, 192, 3000> )

	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, trigger.GetAboveHeight(), 255, 0, 255, true, 9999.9 )
	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, -trigger.GetBelowHeight(), 255, 0, 255, true, 9999.9 )

	OnThreadEnd(
		function() : ( trigger )
		{
			trigger.Destroy()
		} )

	WaitForever()
}


void function Geyser_OnJumpPadAreaEnter( entity trigger, entity ent )
{
	Geyser_JumpPadPushEnt( trigger, ent, trigger.GetOrigin(), trigger.GetAngles() )
}


void function Geyser_JumpPadPushEnt( entity trigger, entity ent, vector origin, vector angles )
{
	if ( Geyser_JumpPad_ShouldPushPlayerOrNPC( ent ) )
	{
		if ( ent.IsPlayer() )
		{
			entity jumpPad = trigger.GetOwner()
			if ( IsValid( jumpPad ) )
			{
				int fxId = GetParticleSystemIndex( JUMP_PAD_LAUNCH_FX )
				StartParticleEffectOnEntity( jumpPad, fxId, FX_PATTACH_ABSORIGIN_FOLLOW, 0 )
			}
			thread Geyser_JumpJetsWhileAirborne( ent )
		}
		else
		{
			EmitSoundOnEntity( ent, "JumpPad_LaunchPlayer_3p" )
			EmitSoundOnEntity( ent, "JumpPad_AirborneMvmt_3p" )
		}
	}
}


void function Geyser_JumpJetsWhileAirborne( entity player )
{
	if ( !IsPilot( player ) )
		return
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.Signal( "JumpPadStart" )
	player.EndSignal( "JumpPadStart" )
	player.EnableSlowMo()
	player.DisableMantle()

	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_LaunchPlayer_3p" )
	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_AirborneMvmt_3p" )

	array<entity> jumpJetFXs
	array<string> attachments = [ "vent_left", "vent_right" ]
	int team                  = player.GetTeam()
	foreach ( attachment in attachments )
	{
		int friendlyID    = GetParticleSystemIndex( TEAM_JUMPJET_DBL )
		entity friendlyFX = StartParticleEffectOnEntity_ReturnEntity( player, friendlyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		friendlyFX.SetOwner( player )
		SetTeam( friendlyFX, team )
		friendlyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_FRIENDLY
		jumpJetFXs.append( friendlyFX )

		int enemyID    = GetParticleSystemIndex( ENEMY_JUMPJET_DBL )
		entity enemyFX = StartParticleEffectOnEntity_ReturnEntity( player, enemyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		SetTeam( enemyFX, team )
		enemyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY
		jumpJetFXs.append( enemyFX )
	}

	OnThreadEnd(
		function() : ( jumpJetFXs, player )
		{
			foreach ( fx in jumpJetFXs )
			{
				if ( IsValid( fx ) )
					fx.Destroy()
			}

			if ( IsValid( player ) )
			{
				player.DisableSlowMo()
				player.EnableMantle()
				StopSoundOnEntity( player, "JumpPad_AirborneMvmt_3p" )
			}
		}
	)

	WaitFrame()

	wait 0.1
	//thread PlayerSkydiveFromCurrentPosition( player )
	while( !player.IsOnGround() )
	{
		WaitFrame()
	}

}


bool function Geyser_JumpPad_ShouldPushPlayerOrNPC( entity target )
{
	if ( target.IsTitan() )
		return false

	if ( IsSuperSpectre( target ) )
		return false

	if ( IsTurret( target ) )
		return false

	if ( IsDropship( target ) )
		return false

	return true
}


///////////////////////
///////////////////////
//// Updrafts

const string UPDRAFT_TRIGGER_SCRIPT_NAME = "skydive_dust_devil"
void function Updrafts_Init()
{
	array<entity> triggers = GetEntArrayByScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
	foreach ( entity trigger in triggers )
	{
		if ( trigger.GetClassName() != "trigger_updraft" )
		{
			entity newTrigger = CreateEntity( "trigger_updraft" )
			newTrigger.SetOrigin( trigger.GetOrigin() )
			newTrigger.SetAngles( trigger.GetAngles() )
			newTrigger.SetModel( trigger.GetModelName() )
			newTrigger.SetScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
			newTrigger.kv.triggerFilterTeamBeast = 1
			newTrigger.kv.triggerFilterTeamNeutral = 1
			newTrigger.kv.triggerFilterTeamOther = 1
			newTrigger.kv.triggerFilterUseNew = 1
			DispatchSpawn( newTrigger )
			trigger.Destroy()
		}
	}
}

void function BurnPlayerOverTime( entity player )
{
	Assert( IsValid( player ) )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "DeathTotem_PreRecallPlayer" )
	for ( int i = 0; i < 8; ++i )
	{
		//if ( !player.Player_IsInsideUpdraftTrigger() )
		//	break

		if ( !player.IsPhaseShifted() )
		{
			player.TakeDamage( 5, null, null, { damageSourceId = eDamageSourceId.burn, damageType = DMG_BURN } )
		}

		wait 0.5
	}
}
#endif

void function CodeCallback_PlayerEnterUpdraftTrigger( entity trigger, entity player )
{
	float entZ = player.GetOrigin().z
	//OnEnterUpdraftTrigger( trigger, player, max( -5750.0, entZ - 400.0 ) )
}


void function CodeCallback_PlayerLeaveUpdraftTrigger( entity trigger, entity player )
{
	//OnLeaveUpdraftTrigger( trigger, player )
}

#if SERVER
void function AddTrainToMinimap( entity mover )
{
	entity minimapObj = CreatePropScript( $"mdl/dev/empty_model.rmdl", mover.GetOrigin() )
	minimapObj.Minimap_SetCustomState( eMinimapObject_prop_script.TRAIN )
	minimapObj.SetParent( mover )
	SetTargetName( minimapObj, "trainIcon" )
	foreach ( player in GetPlayerArray() )
	{
		minimapObj.Minimap_AlwaysShow( 0, player )
	}
}
#endif

#if CLIENT
void function MinimapPackage_Train( entity ent, var rui )
{
	#if DEV
		printt( "Adding 'rui/hud/gametype_icons/sur_train_minimap' icon to minimap" )
	#endif
	RuiSetImage( rui, "defaultIcon", $"rui/hud/gametype_icons/sur_train_minimap" )
	RuiSetImage( rui, "clampedDefaultIcon", $"" )
	RuiSetBool( rui, "useTeamColor", false )
}

void function FullmapPackage_Train( entity ent, var rui )
{
	MinimapPackage_Train( ent, rui )
	RuiSetFloat2( rui, "iconScale", <1.5,1.5,0.0> )
	RuiSetFloat3( rui, "iconColor", <0.5,0.5,0.5> )
}
#endif

#if SERVER
// Creates a prop as a map element
entity function CreateEditorProp(asset a, vector pos, vector ang, bool mantle = false, float fade = 2000, 
int realm = -1)
{
    entity e = CreatePropDynamic(a,pos,ang,SOLID_VPHYSICS,fade)
    e.kv.fadedist = fade
    if(mantle) e.AllowMantle()

    if (realm > -1) {
        e.RemoveFromAllRealms()
        e.AddToRealm(realm)
    }

    string positionSerialized = pos.x.tostring() + "," + pos.y.tostring() + "," + pos.z.tostring()
    string anglesSerialized = ang.x.tostring() + "," + ang.y.tostring() + "," + ang.z.tostring()

    e.SetScriptName("editor_placed_prop")
    e.e.gameModeId = realm
    printl("[editor]" + string(a) + ";" + positionSerialized + ";" + anglesSerialized + ";" + realm)

    return e
}

// Creates a zipline as a map element
void function CreateEditorZipline( vector startPos, vector endPos )
{
	string startpointName = UniqueString( "rope_startpoint" )
	string endpointName = UniqueString( "rope_endpoint" )

	entity rope_start = CreateEntity( "move_rope" )
	SetEditorTargetName( rope_start, startpointName )
	rope_start.kv.NextKey = endpointName
	rope_start.kv.MoveSpeed = 64
	rope_start.kv.Slack = 25
	rope_start.kv.Subdiv = "2"
	rope_start.kv.Width = "3"
	rope_start.kv.Type = "0"
	rope_start.kv.TextureScale = "1"
	rope_start.kv.RopeMaterial = "cable/zipline.vmt"
	rope_start.kv.PositionInterpolator = 2
	rope_start.kv.Zipline = "1"
	rope_start.kv.ZiplineAutoDetachDistance = "150"
	rope_start.kv.ZiplineSagEnable = "0"
	rope_start.kv.ZiplineSagHeight = "50"
	rope_start.SetOrigin( startPos )

	entity rope_end = CreateEntity( "keyframe_rope" )
	SetEditorTargetName( rope_end, endpointName )
	rope_end.kv.MoveSpeed = 64
	rope_end.kv.Slack = 25
	rope_end.kv.Subdiv = "2"
	rope_end.kv.Width = "3"
	rope_end.kv.Type = "0"
	rope_end.kv.TextureScale = "1"
	rope_end.kv.RopeMaterial = "cable/zipline.vmt"
	rope_end.kv.PositionInterpolator = 2
	rope_end.kv.Zipline = "1"
	rope_end.kv.ZiplineAutoDetachDistance = "150"
	rope_end.kv.ZiplineSagEnable = "0"
	rope_end.kv.ZiplineSagHeight = "50"
	rope_end.SetOrigin( endPos )

	DispatchSpawn( rope_start )
	DispatchSpawn( rope_end )

	printl("[zipline][1]" + startPos)
	printl("[zipline][2]" + endPos)
}

void function SetEditorTargetName( entity ent, string name )
{
	ent.SetValueForKey( "targetname", name )
}
#endif

#if SERVER
void function SpawnEditorProps()
{
    // Written by mostly fireproof. Let me know if there are any issues!

    //PROTEUS MAP

        //Spawn area
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7424,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7680,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7936,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7936,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7936,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7680,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7424,38464>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7680,38464>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7424,38464>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032,8064.94,38463.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27776,8064.94,38463.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27520,8064.94,38463.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27391.1,7936.14,38463.7>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27391,7424.07,38463.7>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27519.8,7295.04,38463.8>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27776,7295.07,38463.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032.1,7295.1,38463.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.9,7423.93,38463.5>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.9,7680.01,38463.5>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.9,7936.01,38463.6>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27775.9,7295.23,38719.4>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27519.9,7295.25,38719.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032,7295.3,38719.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.6,7424.01,38719.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.6,7680.02,38719.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28160.6,7936.01,38719.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032.1,8064.7,38719.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27775.9,8064.64,38719.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27520,8064.67,38719.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27391.3,7935.94,38719.3>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27391.2,7423.94,38719.5>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7936,38976>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7936,38976>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7936,38976>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7680,38976>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7680,38976>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7680,38976>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27520,7424,38976>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27776,7424,38976>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7424,38976>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27392.9,7679.97,38720.5>, <0,-90,0>, false, 8000 )
        //Spawn area tunnel
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27264,7680,38784>, <0,-90,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27072,7680,38912>, <0,-90,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26880,7680,39040>, <0,-90,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264.1,7552.97,38463.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264,7807.09,38463.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008,7807.07,38463.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7807.07,38463.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27007.9,7552.97,38463.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7552.98,38463.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27263.8,7552.86,38655.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27007.9,7552.96,38719.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26751.9,7552.64,38719.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7552.58,38847.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27007.7,7552.91,38784.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26752,7680,39104>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264.1,7807.12,38655.5>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008.1,7807.03,38719.8>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008.1,7807.03,38783.8>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7807.04,38719.7>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7807.03,38847.8>, <0,0,0>, false, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27263.9,7552.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008,7552.98,38207.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7552.97,38207.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26752,7807.01,38208.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008,7807.01,38208.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264,7807.01,38208.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27392.9,7679.98,38208.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26751.9,7551.26,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008,7551.26,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264,7551.26,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27392.6,7679.98,37951.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27264,7808.55,37951.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27008,7808.58,37951.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26751.9,7808.63,37951.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27264,7680,37952>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27008,7680,37952>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26752,7680,37952>, <0,90,0>, false, 8000 )

        //Proteus Sign
    CreateEditorProp( $"mdl/desertlands/desertlands_lobby_sign_01.rmdl", <-27403.1,7688.04,38736.5>, <0,90,0>, false, 8000 )

        //Obstacle 1
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7807.02,38143.8>, <0,0,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23935.7,7552.89,38144.4>, <0,180,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24191.7,7552.88,38144.4>, <0,180,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24191.8,7807.04,38143.8>, <0,0,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24447.9,7807.01,38144.1>, <0,0,30>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24447.9,7552.94,38144.3>, <0,180,30>, false, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7552.97,38144.3>, <0,180,30>, false, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680.1,7807.02,38143.9>, <0,0,30>, false, 8000 )

        //Box 1
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.7,7936.07,37951.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,8192.12,37951.5>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,8320.79,37951.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26239.9,8320.84,37951.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25983.9,8320.86,37951.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728.1,8320.87,37951.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25471.9,8320.61,37951.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8320.77,37951.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960.1,8319.26,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704.1,8319.35,37951.2>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448.1,8319.39,37951.2>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8319.33,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8319.26,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8319.25,37951.3>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7424.13,37951.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7167.97,37951.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26495.9,7040.93,37951.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26239.9,7040.94,37951.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25983.9,7040.95,37951.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25727.9,7040.95,37951.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25471.9,7040.97,37951.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,7041,37951.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24959.9,7041,37951.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24703.9,7041,37951.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24447.9,7041,37951.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7041,37951.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7041,37952>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7041,37952>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.1,7041,37952>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.2,8319.08,37951.6>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23423.9,7040.84,38207.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7040.86,38207.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23935.9,7040.8,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7040.76,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24447.8,7040.77,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704.1,7040.78,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7040.79,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25215.6,7040.68,38207.4>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,7040.71,38207.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,7040.69,38207.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,7040.72,38207.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,7040.72,38207.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,7040.64,38207.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7168.01,38208>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7424.06,38208>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7936.05,38208>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,8192.1,38208>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8320.99,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8321,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8321,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8321,38207.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23423.9,7039.02,38463.8>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7039.01,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,7039,38463.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7167.99,38463.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7423.98,38463.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7935.98,38463.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,8191.99,38463.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26495.9,8320.96,38463.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26239.9,8320.96,38463.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,8320.96,38463.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25727.9,8320.98,38463.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8320.99,38463.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24703.9,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8320.99,38463.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.7,7424.08,38719.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.7,7168.01,38719.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,7039.48,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,7039.48,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,7039.52,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,7039.52,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,7039.49,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,7039.53,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7039.51,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,7039.51,38719.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,7039,38719.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7039,38719.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7039,38719.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7039,38719.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,7039,38719.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23423.9,8320.91,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23679.9,8320.9,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8320.91,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24191.9,8320.92,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8320.92,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8320.92,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,8320.93,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,8320.92,38719.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,8192.08,38719.6>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7936.03,38719.6>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7936.04,38975.5>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.8,8192.33,38975.6>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26495.9,8320.88,38975.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26239.9,8320.93,38975.6>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25983.9,8320.95,38975.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25727.9,8320.96,38975.7>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8320.97,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25215.9,8320.97,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24959.9,8320.98,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8320.98,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448.1,8320.99,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8320.99,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8320.99,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8320.99,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8320.99,38975.8>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,7039,38976>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7167.9,38975.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7423.93,38975.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.9,7680.28,39104.4>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7935.98,39231.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,8192.07,39231.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496.1,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25983.9,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25471.9,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8320.99,39231.9>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23679.9,7039.01,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25984,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26240,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26496,7039,39231.9>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7167.8,39231.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26625,7423.94,39231.9>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-26624.6,7680.06,39231.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,8192,39488>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,8192,39488>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,8192,39488>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8192,39488>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8192,39488>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8192,39488>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26496,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-26240,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25984,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8192,37952>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7680,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7424,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7168,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7936,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8192,37952>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.9,8320.65,37951.2>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,8320.76,37951.3>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,8320.88,38207.5>, <0,180,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,8320.91,38207.6>, <0,180,0>, false, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,7039.74,37951>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,7039.73,37951>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,7039.48,38207.1>, <0,0,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,7039.44,38207.2>, <0,0,0>, false, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7168,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7424,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7680,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7936,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8192,39488>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,8191.93,38207.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8191.95,37951.4>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8192.15,38464.6>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,8192.01,38720.8>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,8192.1,38976.4>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,8192.01,39232.8>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,7936,39232.8>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7680.02,39232.8>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7424.02,39232.8>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7168.03,39232.7>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,7168.09,38976.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,7424.09,38976.1>, <0,-90,0>, false, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,7680.07,38976.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,7936.1,38976>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,7936.08,38719.2>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7679.98,38719.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7423.98,38719.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7168,38719.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.3,7168.02,38463>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.4,7424.04,38463.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.5,7680.03,38463.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.5,7936.03,38463.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.1,7936,38207>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7680.03,38207.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7424.02,38207.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,7167.99,38207.3>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.2,7167.97,37951>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.3,7424.05,37951.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.4,7680.02,37951.1>, <0,-90,0>, false, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.5,7936.02,37951.1>, <0,-90,0>, false, 8000 )



    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24703.9,7807.13,38143.5>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24703.7,7552.94,38144.1>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6912,38464>, <0,180,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,6912.05,38463.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,6912.17,38720.2>, <0,-90,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6912,38976>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8448,38464>, <0,0,0>, true, 8000 )
    
    
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8448,38976>, <0,180,0>, true, 8000 )
    
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,6783.13,38463.5>, <0,0,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6783.07,38720.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912.2,8575.08,38463.6>, <0,0,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,8575.2,38720.6>, <0,0,0>, true, 8000 )



    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7807.32,38143.3>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,7552.98,38143.8>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.9,6912.16,37951.6>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.9,6655.99,37951.5>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.9,6399.98,37951.5>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.9,6143.98,37951.5>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.9,5888.09,37951.5>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8448.05,37951.9>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8704.05,37951.9>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8959.98,37951.9>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,9216.01,37951.9>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,9472.01,37951.9>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6912,38464>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8448,38464>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656.3,6783.06,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656.3,6783.04,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22527.1,6911.81,38463.5>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22527.2,6911.77,38720.5>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6912,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656.6,8575.27,38463.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8447.99,38463.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656.3,8575.07,38720.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8447.99,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8448,38976>, <0,-90,0>, true, 8000 )
    
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,8192.03,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,7936.04,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,7680.01,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,7424.01,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22529,7168.01,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7168,38976>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7424,38976>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7680,38976>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7936,38976>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8192,38976>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7424,38464.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7680,38464.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7936,38464.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7936,38720>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7680,38720>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7424,38720>, <0,-90,0>, true, 8000 )
    

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22527.1,7167.99,38463.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22527.1,8192.33,38463.9>, <0,90,0>, true, 8000 )



    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22016.9,7424.06,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22017,7168.03,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22017,6912.03,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22017,7936.04,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22017,8192.04,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22017,8448.04,37951.7>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22016.6,7680.13,37951.2>, <0,-90,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23679.9,8576.68,38463.3>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23935.9,8576.66,38463.3>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8576.66,38463.2>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8576.91,38463.6>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8576.91,38463.6>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8576.92,38463.6>, <0,180,30>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6783.49,38463.1>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6783.47,38463.1>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6783.47,38463.1>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6783.47,38463.2>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6783.47,38463.2>, <0,0,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24959.9,6783.43,38463.2>, <0,0,30>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,7168.01,37696.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,7423.98,37696.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,7680.03,37696.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,7936.04,37696.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8192.04,37696.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8192,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7936,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7680,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7424,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,7168,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7168,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7424,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7680,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7936,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8192,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8448,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8704,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8960,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9216,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9472,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9728,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9728,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9472,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9216,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8960,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8704,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8448,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9728,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9472,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9216,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8960,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8704,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8448,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8192,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7936,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7680,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7424,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7168,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7168,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7424,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7680,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7936,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8192,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8448,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8704,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8960,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9216,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9472,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9728,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6912,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6656,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6400,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6912,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6656,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6400,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6912,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6656,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6400,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6912,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6656,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6400,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6144,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5888,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5632,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5632,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5888,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6144,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6144,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6144,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5888,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5632,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5632,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5888,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6912.09,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6655.93,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6400,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6144.01,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5888,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5632,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,5631.85,37952.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,5887.99,37952.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6144.01,37952.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6400.03,37952.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6656.01,37952.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6912.01,37952.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6911.99,38208.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6399.95,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6143.95,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5887.95,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5631.95,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6399.9,38464.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,6656.01,38720.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,6399.99,38720.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6144,38463.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5887.99,38463.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5631.98,38463.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,5631.92,38720.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,5888.01,38720.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6144.15,38720.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8447.98,37695.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,8704.07,37695.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,8960.04,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,9216.05,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9472.06,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9728.08,37695.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9727.97,37952.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9216,37952.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9472.01,37952.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8960,37952.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8448,37952.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.5,8447.99,38208.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,8960.1,38208.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9216.15,38208.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,9472.03,38208.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,9728.03,38208.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.6,8704.01,37951.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8960.07,38464.2>, <0,-90,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.7,8960,38720.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9216.19,38463.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9472.05,38463.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9728.04,38463.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9471.97,38720.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9728,38720.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9215.98,38720.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9984,37696>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9984,37696>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9984,37696>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.5,9984.11,37695.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,9984.11,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9984.04,38208.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.4,9984.02,38464.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.2,9983.99,38721>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5376,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5376,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5376,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5376,37696>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,5375.96,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,5375.89,37952.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.1,5375.98,38209>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.1,5375.99,38465>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.1,5375.99,38721>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656,5248.93,37695.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22399.9,5248.94,37695.7>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22143.9,5248.95,37695.7>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,5248.91,37695.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22655.8,5248.97,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22400,5247.02,37951.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22144,5247.01,37951.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,5247.01,37951.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888.1,5247.18,38208.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22144.1,5247.18,38208.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22400.1,5247.18,38208.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656.1,5247.18,38208.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656,5247.39,38464.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22400,5247.42,38464.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22144,5247.42,38464.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,5247.42,38464.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,5247.5,38720.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22144,5247.52,38720.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22400,5247.52,38720.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656,5247.52,38720.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22656,10112.7,37695.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22399.9,10112.7,37695.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22143.9,10112.8,37695.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,10112.8,37695.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22655.9,10113,37952>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22399.9,10113,37952>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22143.9,10113,37952>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21887.9,10113,37952>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22655.8,10113,38207.7>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22400,10113,38207.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22143.9,10113,38207.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21887.9,10113,38207.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21887.9,10113,38464.1>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22143.9,10113,38464.1>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22399.9,10113,38464.1>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22655.9,10113,38464.1>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22655.9,10112.9,38720.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22399.9,10112.9,38720.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22144,10112.9,38720.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21888,10112.9,38720.4>, <0,180,0>, true, 8000 )
    

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8192,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8192,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7936,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7936,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7680,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7680,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7424,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,7168,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7168,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,7424,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,8191.95,38975.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7935.97,38975.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7679.96,38975.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7423.92,38975.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7167.93,38975.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,8191.97,39231.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7936.02,39231.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7679.98,39231.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7423.93,39231.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,7167.97,39231.9>, <0,90,0>, true, 8000 )

    

        //Small red lights at entrance
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38479.7>, <0,90,-90>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38524.1>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38568.3>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38620.4>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38672.2>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804.04,38716.2>, <0,90,-90>, true, 8000 )

    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38479.7>, <0,90,-90>, false, 8000 )  
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38524.1>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38568.3>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38620.4>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38672.2>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38716.2>, <0,90,-90>, true, 8000 )

    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804,38499.9>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804,38544.3>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804,38592.1>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804,38644.3>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7804,38692.4>, <0,90,-90>, true, 8000 )

    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38496.5>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38544.4>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38592.6>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38644.6>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27391,7556.57,38692.1>, <0,90,-90>, true, 8000 )

    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7804.14,38724.1>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7556.07,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7688.07,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7716.09,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7744.16,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7772.2,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7660.04,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7632,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7607.97,38724>, <0,90,-90>, true, 8000 )
    CreateEditorProp( $"mdl/lamps/warning_light_ON_red.rmdl", <-27399,7579.92,38724>, <0,90,-90>, true, 8000 )

        //Ceiling lights & sign light
    CreateEditorProp( $"mdl/utilities/halogen_lightbulbs.rmdl", <-27409,7736.09,38836.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/utilities/halogen_lightbulb_case.rmdl", <-27400,7739,38842>, <0,90,180>, true, 8000 )
    CreateEditorProp( $"mdl/utilities/halogen_lightbulb_case.rmdl", <-27412,7635,38842>, <180,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27455.4,7551.92,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27519.5,7551.91,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27583.7,7551.96,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27647.4,7552.05,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27711.4,7552.05,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27775.4,7552.06,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27839.3,7552.05,38976.7>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27903.2,7552.05,38976.5>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27967.2,7552.03,38976.5>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-28032,7552,38977>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-28095.5,7551.54,38976.7>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27455.2,7807.91,38976.6>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27519.4,7807.93,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27583.5,7807.92,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27647.6,7807.95,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27711.3,7807.83,38976.7>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27775.4,7807.95,38976.8>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27839.5,7807.95,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27903.5,7807.92,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-27967.5,7807.94,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-28031.7,7808.03,38976.9>, <0,90,0>, false, 8000 )
    CreateEditorProp( $"mdl/lamps/halogen_light_ceiling.rmdl", <-28095.9,7808.02,38977>, <0,90,0>, false, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21759.4,5375.95,37695.2>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5632.1,37695.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5888.03,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6144.03,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6400.07,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6656.07,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6912.05,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7168.04,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7424.05,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7680.04,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7936.04,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8192.03,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8448.03,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8704.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8960.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9216.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9472.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9728.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9984.02,37695.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9984,37696>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9984.05,37951.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9727.95,37951.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9472.04,37951.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,9216.02,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8960.03,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8704.03,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8448.04,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,8192.04,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7936.04,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7680.03,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7424.03,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,7168.02,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6912.01,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6656.01,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6400.01,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,6144.01,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5888.01,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5632,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5376,37951.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5375.87,38208.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,5632,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,5888.02,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6144.03,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6400.02,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6656.02,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6912.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7168.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7424.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7680.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7936.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8192.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8448.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8704,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8960,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9216,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9472,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9728,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9984.01,38208.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.5,9983.9,38464.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,9727.98,38464.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,9472,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,9216.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,8960.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,8704.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,8448.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,8192.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,7936.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,7680.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,7424.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,7168.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,6912.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,6656.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,6400.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,6144.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,5888.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,5632.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.7,5376.02,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21760.9,5375.9,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,5631.95,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,5888,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6144,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6400,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6656,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,6912,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7168,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7424,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7680,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,7936,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8192,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8448,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8704,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,8960,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9216,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9472,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9728,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-21761,9984,38720.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8704,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,8960,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9216,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9472,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9728,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,9984,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9984,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9984,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9728,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9472,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,9216,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8960,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8704,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8448,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,8192,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7936,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7680,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7424,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,7168,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6912,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6656,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6400,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,6144,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5888,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5632,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22400,5376,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5376,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5632,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,5888,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6144,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6400,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22656,6656,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6656,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6400,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6144,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5888,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5376,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5376,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5632,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,5888,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6144,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6400,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6656,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,6912,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,6912,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7168,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7168,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7424,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7424,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7680,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,7936,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8192,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8448,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8704,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,8960,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9216,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9472,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,9728,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9984,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9728,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9472,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,9216,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8960,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8704,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8448,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,8192,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7936,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-21888,7680,38976>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,9471.98,37695.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.8,9216.11,37695.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.8,8960,37695.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22271,8704.04,37695.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22271,8448.02,37695.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22271,8191.99,37695.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,7936.16,37695.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,7679.98,37695.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,7423.96,37695.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,7167.97,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,6911.98,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,6655.98,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,6399.99,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,6143.99,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,5887.98,37695.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,5888.16,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6143.98,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6400,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6656.05,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6912,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7168,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7424,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7680,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7936.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8192.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8448.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8704.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8960.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,9216.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,9472.03,37951.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,5888.01,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6143.99,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6399.97,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,6399.84,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.7,6143.88,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.7,5887.93,38464.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.3,5887.98,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.3,6143.99,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.3,6399.99,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.4,6656.02,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6912.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7168.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7424.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7680.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7936.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8192.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8448.02,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,8448.12,38464.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8192.03,38464.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,6912.03,38464.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,7168.03,38464.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.4,6912.01,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.5,7168.03,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,7424,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,7680,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,7935.99,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,8191.99,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.6,8447.98,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8960.03,38207.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,9216.03,38207.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,9472.03,38207.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,8960.05,38464.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.5,8704.01,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.5,8960.02,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.8,9216.06,38464.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.5,9216.01,38720.9>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.5,9472.02,38720.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,9471.99,38464.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,6656.13,38208.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8704.06,38208>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22144,5632,38976>, <0,0,0>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,8832.97,38463.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,8831.12,38463.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.1,8831.09,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680.1,8831.08,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8831.07,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8831.07,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8831.07,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8831.07,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8831.07,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8831.03,38463.8>, <0,0,0>, true, 8000 )
    

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,8831.04,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8831.04,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8831.05,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8831.04,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8831.04,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8831.04,38207.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8831.04,38207.7>, <0,0,0>, true, 8000 )



    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,8831,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8831.01,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8831.01,38719.9>, <0,0,0>, true, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8831.01,38719.9>, <0,0,0>, true, 8000 )
    

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,8575.12,38207.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.9,8575.12,38207.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,8447.94,38207.8>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25727.9,8832.71,38975.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8832.77,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8832.99,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8833,38975.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.1,8831,38976.1>, <0,0,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8831,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8704,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8704,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23296.9,8448.18,38975.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23296.9,8704.15,38975.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,8448.06,39232.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,8704.05,39232.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8704,39488>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8448,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.8,8575.15,38463.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295.1,8447.74,38463.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.8,8575.06,38720.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295,8447.9,38720.1>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8448,38976>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6912,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.8,6784.88,38463.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.9,6784.76,38720.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6912,38976>, <0,180,0>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6527.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6527.23,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6527.23,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6527.23,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23679.8,6527.08,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936.1,6527.12,38463.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6527.11,38463.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6527.1,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6527.1,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6527.1,38463.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6527.09,38463.6>, <0,0,0>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6527.41,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6527.38,38719.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6656,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6656,38976>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23296.8,6912.17,38975.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23296.8,6656.04,38975.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,6655.99,39232.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,6911.99,39232.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23423.9,6528.85,38975.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6528.83,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6528.82,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6528.82,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6528.82,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6528.83,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6528.84,38975.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6528.84,38975.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6528.84,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6528.83,38975.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6527.02,39231.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6656,39488>, <0,180,0>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6527.08,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6527.08,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6527.08,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6527.08,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6527.07,37951.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6527.07,37951.6>, <0,0,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6656,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6912,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6656,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6912,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8448,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8704,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8448,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8704,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8448,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8704,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295.1,8447.91,37951.5>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.7,8575.23,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.7,8575.07,37951.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,8832.97,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,8832.98,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,8832.98,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,8832.99,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,8832.99,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,8832.99,37951.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,8832.99,37951.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,8832.99,37951.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,8832.99,37951.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,8832.99,37951.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,8832.99,37951.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,8832.99,37951.9>, <0,180,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295.3,6912.26,37951.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23295.1,6912.34,38207.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.8,6784.59,37951.2>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,6784.78,37951.4>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.9,6784.96,38208.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,6784.96,38208.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8448,37952>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,7552.71,38143.3>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680.3,7807.06,38143.8>, <0,0,30>, true, 8000 )
    
    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,6655.92,37951.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,6911.98,37951.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,6912.01,38207.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,6656,38207.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,6912.01,38463.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,6656.01,38463.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,6655.97,38719.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,6912.01,38719.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,6655.92,38975.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,6911.98,38975.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,6911.95,39231.9>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,6656.01,39231.9>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,8704.02,37951.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,8447.97,37951.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8448,38207.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8704.01,38207.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,8704.02,38464.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.3,8448.02,38464.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,8704.03,38720.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,8448.03,38720.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,8704.09,38976.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,8448.03,38976.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,8703.98,39232.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,8447.98,39232.4>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22273,8704.04,38464>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22272.9,6655.98,38463.6>, <0,-90,0>, true, 8000 )

    
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8704,39488>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8704,39488>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8448,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8448,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.2,9215.66,37951.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8959.96,37951.7>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,8960.02,38208.5>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.1,9215.98,38208.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8959.96,38464.2>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,9215.96,38464.2>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,9215.83,38720.1>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8959.98,38720.1>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,8959.88,38976.2>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855,9216,38976.2>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.5,8959.94,39232.9>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25855.4,9215.89,39232.8>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728.1,9344.88,37951.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9344.92,37951.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9343,37952>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,9343,37952>, <0,0,0>, true, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,8959.88,37952>, <0,-90,0>, true, 8000 )
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23297,9215.93,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.1,9343.03,38208.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680.1,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343.03,38208.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9343.01,38208.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,9343.01,38208.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,9343,38464>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424.1,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,9343.01,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728.1,9343.42,38976.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9343.39,38976.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343.36,38976.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343.35,38976.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343.33,38976.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448.1,9343.04,38976.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24191.9,9343.02,38976.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343.02,38976.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9343.02,38976.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,9343.01,38976.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,9343.03,39232.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,9343.03,39232.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,9343.03,39232.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,9343.03,39232.2>, <0,0,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,9216,39488>, <0,90,0>, true, 8000 )
    

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6912,39488>, <0,-90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6400,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6144,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6400,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6144,39488>, <0,90,0>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,9343.06,38463.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,9343.05,38463.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168.1,9343.02,38720.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,9343.02,38720.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168.1,9343.1,38975.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912.1,9343.11,38975.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,9216.02,38975.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8960.18,38975.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8704.06,38975.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22785,8448.06,38975.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8448.04,39232.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8704.04,39232.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,8960.04,39232.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.8,9216.02,39232.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,9343.04,39231.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,9343.04,39231.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8448,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,9216,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,8960,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8704,39488>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8448,39488>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,8960,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,9216,37952>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,9343.27,37951.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,9343.28,37951.3>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22911.9,9343.03,38208.2>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,9343.02,38208.2>, <0,0,0>, true, 8000 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,9088.92,38463.6>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,9088.92,38463.6>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23935.9,9089,38464>, <0,180,30>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,9089,38463.9>, <0,180,30>, true, 8000 )


    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23680,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23424,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6144,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6400,37952>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6144.02,37951.7>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6400.05,37951.8>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25856.9,6144.02,38208.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25856.9,6400.14,38208.5>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6143.97,38464.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6399.99,38464.1>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6144.05,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6400.1,38720.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6143.98,38976.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25857,6400.14,38976.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25856.9,6144.11,39232.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25856.9,6400.08,39232.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015.23,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6015.21,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6015.2,37951.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6015,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015.01,38207.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015.21,38464.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23167.9,6015.23,38464.6>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015.11,38463.5>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015.17,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015.18,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6015.18,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6015,38720.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015,38720>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015,38720>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015,38720>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015,38720>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015,38719.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015.01,38975.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168.1,6015.02,38975.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015.03,38975.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015.03,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015.04,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015.04,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015.04,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015.04,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015.04,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015.05,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015.05,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728.1,6015.05,38975.7>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25728,6015,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25472,6015,39232>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-25216,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24960,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24704,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24448,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-24192,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23936,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23680,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23424,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-23168,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22912,6015,39231.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22783.2,6143.89,38975.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22783.2,6399.94,38975.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22783.1,6143.94,39232.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22783,6399.95,39232.3>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6655.94,38975.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6912.01,38975.6>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6655.99,39232.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22784.9,6911.97,39232.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23168,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6656,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6912,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-22912,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-23936,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24192,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24448,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24704,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25216,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-24960,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6400,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25472,6144,39488>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-25728,6144,39488>, <0,-90,0>, true, 8000 )



        //Warning signs & arrow signs
    CreateEditorProp( $"mdl/signs/Sign_no_tresspasing.rmdl", <-27400,7535.9,38563>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/signs/Sign_no_tresspasing.rmdl", <-27400,7825,38563>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/signs/street_sign_arrow.rmdl", <-27400,7531.97,38584.6>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/signs/street_sign_arrow.rmdl", <-27400,7828.05,38584.6>, <-180,90,0>, true, 8000 )

        //Right Stairs
    CreateEditorProp( $"mdl/desertlands/research_station_stairs_big_building_01.rmdl", <-27496,7376,38397>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/desertlands/research_station_stairs_big_building_01.rmdl", <-27656.5,7376,38520>, <0,0,0>, true, 8000 )

        //Right stairs platform and walls
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27443,7424,38720>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27904,7424,38720>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28160,7424,38720>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28032,7680,38720>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27775,7424.02,38463.9>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27776.8,7315,38719.4>, <0,-90,0>, true, 8000 )

        //Right stairs platform thin floor
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27690,7535.87,38735>, <90,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27815,7535.87,38735>, <90,-90,0>, true, 8000 )


        //Right fencewall
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27399,7541,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27527.1,7541,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27655.1,7541,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27783.2,7541,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27915,7541,38721>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27915,7541,38721>, <0,0,0>, true, 8000 )

    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27685.1,7445,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27557.1,7445,38721>, <0,90,0>, true, 8000 )

        //Left Stairs
    CreateEditorProp( $"mdl/desertlands/research_station_stairs_big_building_01.rmdl", <-27496,7987,38397>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/desertlands/research_station_stairs_big_building_01.rmdl", <-27656.5,7987,38520>, <0,0,0>, true, 8000 )

        //Left stairs platform and walls
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27443,7936,38720>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-27904,7936,38720>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <-28160,7936,38720>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27775,7935.94,38463.9>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-27777,8033,38719.8>, <0,-90,0>, true, 8000 )

        //Left stairs platform thin floor
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27690,7896.87,38735>, <90,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27815,7896.87,38735>, <90,-90,0>, true, 8000 )

        //Left fencewall
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27399,7807,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27527.1,7807,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27655.1,7807,38721>, <0,90,0>, true, 8000 )

    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27783.2,7807,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27915,7690,38721>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27915.6,7615.25,38721>, <0,0,0>, true, 8000 )
    
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27685.1,7904,38721>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27557.1,7904,38721>, <0,90,0>, true, 8000 )

        //vending machines, bench, props, etc
    CreateEditorProp( $"mdl/angel_city/vending_machine.rmdl", <-27836.5,8044.05,38479.2>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/angel_city/vending_machine.rmdl", <-27920.7,8044.47,38479.4>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/angel_city/vending_machine.rmdl", <-27843.2,7315.61,38479.5>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/angel_city/vending_machine.rmdl", <-27923.3,7315.6,38479.4>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/mendoko/mendoko_handscanner_01_dmg.rmdl", <-27399.1,7543.86,38535>, <0,90,0>, true, 8000 )
    CreateEditorProp( $"mdl/benches/bench_single_modern_dirty.rmdl", <-27768.6,7427.23,38479.8>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/benches/bench_single_modern_dirty.rmdl", <-27768.4,7939.1,38479.7>, <0,0,0>, true, 8000 )

        //Spawn box 
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032.2,7551.2,38463.4>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032.6,7807.25,38463.9>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.4,7808.73,38656.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.4,7680.72,38656.6>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.5,7680.8,38592.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.5,7808.8,38592.3>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28032.3,7551.04,38464.1>, <0,0,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-28031.9,7808.96,38463.7>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.4,7808.42,38656.8>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.2,7680.44,38656.9>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.3,7808.8,38592.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/slum_city/slumcity_fencewall_128x72_dirty.rmdl", <-27904.4,7680.76,38592.5>, <0,180,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.7,7936.26,38463.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22528.7,7679.96,38463.3>, <0,-90,0>, true, 8000 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-22527.1,7423.76,38463.7>, <0,90,0>, true, 8000 )

}
#endif
