install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )
install( "packages/ipr-base", "https://github.com/Pika-Software/ipr-base" )

local hook = hook

for _, pkg in ipairs( gpm.Find( "ipr%-base", false, false ) ) do
	_G.hook.Remove( "PlayerDisconnected", pkg:GetIdentifier( "RemoveOnDisconnect" ) )
end

hook.Add( "PlayerInitialized", "PlayerDataSaving", function( ply )
	if ply:IsBot() then return end

	local sid64 = ply:SteamID64()
	for _, ent in ipairs( ents.GetAll() ) do
		if not ent:IsPlayerRagdoll() then continue end
		if ent.SteamID64 ~= sid64 then continue end
		if not ply:Alive() then ply:Spawn() end

		-- Origin & Angles
		ply:SetEyeAngles( Angle( 0, ent.PlayerAngles[2], 0 ) )
		ply:SetPos( ent:GetPos() )

		-- Health & Armor
		ply:SetHealth( ply:GetMaxHealth() * ( ent:Health() / ent:GetMaxHealth() ) )
		ply:SetArmor( ply:GetMaxArmor() * ( ent.Armor / ent.MaxArmor ) )

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
			ply:SetFlexWeight( flex, ent:GetFlexWeight( flex ) )
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

		-- Weapons & Ammo
		local func = ent.PickupWeapons
		if type( func ) == "function" then
			func( ent, ply )
		end

		ent:Remove()
		break
	end
end )

local removeDelay = CreateConVar( "ipr_remove_delay", 5, FCVAR_ARCHIVE, "Time in minutes to remove player ragdolls.", 0, 300 )

hook.Add( "PlayerDisconnected", "PlayerDataLoading", function( ply )
	if ply:IsBot() then return end
	if not ply:Alive() then return end

	local delay = removeDelay:GetInt()
	if delay <= 0 then return end

	local ragdoll = ply:CreateRagdoll()
	if not IsValid( ragdoll ) then return end

	-- SteamID64
	ragdoll.SteamID64 = ply:SteamID64()

	-- Angles
	ragdoll.PlayerAngles = ply:EyeAngles()

	-- Health
	ragdoll:SetMaxHealth( ply:GetMaxHealth() )
	ragdoll:SetHealth( ply:Health() )

	-- Armor
	ragdoll.MaxArmor = ply:GetMaxArmor()
	ragdoll.Armor = ply:Armor()

	timer.Simple( delay * 60, function()
		if not IsValid( ragdoll ) then return end
		ragdoll:Remove()
	end )
end )