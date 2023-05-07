import( gpm.LuaPackageExists( "packages/glua-extensions" ) and "packages/glua-extensions" or "https://github.com/Pika-Software/glua-extensions" )
import( gpm.LuaPackageExists( "packages/ipr-base" ) and "packages/ipr-base" or "https://github.com/Pika-Software/ipr-base" )

local packageName = gpm.Package:GetIdentifier()
local hook = hook

for version, gPackage in pairs( gpm.packages.Get( "ipr-base" ) ) do
	hook.Remove( "PlayerDisconnected", gPackage:GetIdentifier() )
end

local function spawn( ply, ent )
	ply:SetHealth( ply:GetMaxHealth() * ( ent:Health() / ent:GetMaxHealth() ) )
	ply:SetEyeAngles( Angle( 0, ent.PlayerAngles[2], 0 ) )
	ply:SetPos( ent:GetPos() )

	-- Model & skin
	ply:SetModel( ent:GetModel() )
	ply:SetSkin( ent:GetSkin() )

	-- Bodygroups
	for _, bodygroup in ipairs( ent:GetBodyGroups() ) do
		ply:SetBodygroup( bodygroup.id, ent:GetBodygroup( bodygroup.id ) )
	end

	-- Flexes
	ply:SetFlexScale( ent:GetFlexScale() )
	for flex = 1, ply:GetFlexNum() do
		plu:SetFlexWeight( flex, ent:GetFlexWeight( flex ) )
	end

	-- Material
	ply:SetMaterial( ent:GetMaterial() )

	-- Sub-materials
	for index in ipairs( ply:GetMaterials() ) do
		local materialPath = ent:GetSubMaterial( index )
		if materialPath ~= "" then
			ply:SetSubMaterial( index, materialPath )
		end
	end

	-- Color
	ply:SetColor( ent:GetColor() )
	ply:SetPlayerColor( ent:GetPlayerColor() )

	-- Fire transmission
	if ent:IsOnFire() then
		ent:Extinguish()
		ply:Ignite( 16, 32 )
	end

	-- Bone manipulations
	for boneID = 0, ply:GetBoneCount() do
		ply:ManipulateBonePosition( boneID, ent:GetManipulateBonePosition( boneID ) )
		ply:ManipulateBoneAngles( boneID, ent:GetManipulateBoneAngles( boneID ) )
		ply:ManipulateBoneJiggle( boneID, ent:GetManipulateBoneJiggle( boneID ) )
		ply:ManipulateBoneScale( boneID, ent:GetManipulateBoneScale( boneID ) )
	end

	-- Velocity
	local velocity = Vector()
	if ent:IsRagdoll() then
		local count = ent:GetPhysicsObjectCount()
		for physNum = 0, count - 1 do
			local phys = ent:GetPhysicsObjectNum( physNum )
			if not IsValid( phys ) then continue end
			velocity = velocity + phys:GetVelocity()
		end

		velocity = velocity / count
	else
		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then
			velocity = phys:GetVelocity()
		end
	end

	ply:SetVelocity( velocity )
end

hook.Add( "PlayerRagdollCreated", packageName, function( ply, ragdoll )
	ragdoll:SetMaxHealth( ply:GetMaxHealth() )
	ragdoll:SetHealth( ply:Health() )
end )

hook.Add( "PlayerInitialSpawn", packageName, function( ply, transition  )
	if transition or ply:IsBot() then return end
	ply:SetNotSolid( true )
	ply:SetNoDraw( true )
end )

hook.Add( "PlayerInitialized", packageName, function( ply )
	if ply:IsBot() then return end
	ply:SetNotSolid( false )
	ply:SetNoDraw( false )

	local sid64 = ply:SteamID64()
	for _, ent in ipairs( ents.GetAll() ) do
		if not ent:IsPlayerRagdoll() then continue end
		if ent.SteamID64 ~= sid64 then continue end
		if not ply:Alive() then ply:Spawn() end
		spawn( ply, ent )
		ent:Remove()
		break
	end
end )

local removeDelay = CreateConVar( "ipr_remove_delay", 5, FCVAR_ARCHIVE, "Time in minutes to remove player ragdolls.", 0, 300 )

hook.Add( "PlayerDisconnected", packageName, function( ply )
	if ply:IsBot() then return end
	if not ply:Alive() then return end

	local delay = removeDelay:GetInt()
	if delay <= 0 then return end

	local ragdoll = ply:CreateRagdoll()
	if IsValid( ragdoll ) then
		ragdoll.SteamID64 = ply:SteamID64()
		ragdoll.PlayerAngles = ply:EyeAngles()

		timer.Simple( delay * 60, function()
			if not IsValid( ragdoll ) then return end
			ragdoll:Remove()
		end )
	end
end )