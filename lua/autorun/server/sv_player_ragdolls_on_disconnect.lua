local addonName = 'IPR - Disconnect Ragdolls'

timer.Simple(0, function()
	hook.Remove( 'PlayerDisconnected', 'Improved Player Ragdolls' )
end)

CreateConVar( 'ipr_remove_delay', 5, FCVAR_ARCHIVE, 'Time in minutes to remove player ragdolls.', 0, 300 )

local function getSteamID( ply )
	if ply:IsBot() then
		return 'BOT'
	end

	return ply:SteamID()
end

hook.Add('PlayerDisconnected', addonName, function( ply )
	local timeToRemove = cvars.Number( 'ipr_remove_delay', 5 ) * 60
	if (timeToRemove > 0) then
		local ragdoll = ply:CreateRagdoll()
		if IsValid( ragdoll ) then
			-- Basic Info
			ragdoll.PlayerAngles = ply:EyeAngles()
			ragdoll.SteamID = getSteamID( ply )
			ragdoll.DisconnectedPlayer = true

			-- Remove Delay
			timer.Simple(timeToRemove, function()
				if IsValid( ragdoll ) then
					ragdoll:Remove()
				end
			end)
		end

		return
	end

	ply:RemoveRagdoll()
end)

hook.Add('PlayerInitialSpawn', addonName, function( ply )
	local steamID = getSteamID( ply )
	for _, ent in ipairs( ents.GetAll() ) do
		if ent:IsPlayerRagdoll() and ent.DisconnectedPlayer and (ent.SteamID == steamID) then
			-- Model
			ply:SetModel( ent:GetModel() )

			-- Skin
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

			-- Color & Material
			ply:SetMaterial( ent:GetMaterial() )
			ply:SetColor( ent:GetColor() )

			-- Position & Angles
			local pos = ent:LocalToWorld( ent:OBBCenter() )
			local ang = ent.PlayerAngles

			timer.Simple(0, function()
				if IsValid( ply ) then
					ply:SetEyeAngles( Angle( 0, ang[2], 0 ) )
					ply:SetPos( pos )
				end
			end)

			-- Weapons
			ply:StripWeapons()

			for class, wep in pairs( ent.Weapons ) do
				if not IsValid( wep ) then
					wep = ents.Create( class )
					if IsValid( wep ) then
						wep:SetPos( pos )
						wep:Spawn()
					end
				end

				if IsValid( wep ) then
					wep:SetParent()
					wep:SetNoDraw( false )
					ply:PickupWeapon( wep )
					wep:SetCollisionGroup( COLLISION_GROUP_NONE )
				end
			end

			-- Active Weapon
			local activeWeapon = ent.ActiveWeapon
			if not IsValid( activeWeapon ) then
				local class = ent.ActiveWeaponClass
				if isstring( class ) then
					activeWeapon = ents.Create( class )
					if IsValid( activeWeapon ) then
						activeWeapon:SetPos( pos )
						activeWeapon:Spawn()
						ply:PickupWeapon( activeWeapon )
					end
				end
			end

			if IsValid( activeWeapon ) then
				ply:SetActiveWeapon( activeWeapon )
			end

			-- Bone Manipulations
			for i = 0, ply:GetBoneCount() do
				ply:ManipulateBonePosition( i, ent:GetManipulateBonePosition( i ) )
				ply:ManipulateBoneAngles( i, ent:GetManipulateBoneAngles( i ) )
				ply:ManipulateBoneJiggle( i, ent:GetManipulateBoneJiggle( i ) )
				ply:ManipulateBoneScale( i, ent:GetManipulateBoneScale( i ) )
			end

			-- Velocity
			ply:SetVelocity( ent:GetVelocity() )

			ent:Remove()
			break
		end
	end
end)
