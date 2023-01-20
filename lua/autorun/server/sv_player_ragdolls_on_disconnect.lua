local addonName = 'IPR - Disconnect Ragdolls'

local timer_Simple = timer.Simple
local hook_Add = hook.Add
local IsValid = IsValid

timer_Simple(0, function()
	hook.Remove( 'PlayerDisconnected', 'Improved Player Ragdolls' )
end)

local function getSteamID( ply )
	if ply:IsBot() then
		return 'BOT'
	end

	return ply:SteamID()
end

do

	local removeDelay = CreateConVar( 'ipr_remove_delay', 5, FCVAR_ARCHIVE, 'Time in minutes to remove player ragdolls.', 0, 300 )

	hook_Add('PlayerDisconnected', addonName, function( ply )
		local timeToRemove = removeDelay:GetInt() * 60
		if (timeToRemove > 0) then
			local ragdoll = ply:CreateRagdoll()
			if IsValid( ragdoll ) then
				-- Basic Info
				ragdoll.PlayerAngles = ply:EyeAngles()
				ragdoll.SteamID = getSteamID( ply )
				ragdoll.DisconnectedPlayer = true

				-- Remove Delay
				timer_Simple(timeToRemove, function()
					if IsValid( ragdoll ) then
						ragdoll:Remove()
					end
				end)
			end

			return
		end

		ply:RemoveRagdoll()
	end)

end

do

	local ents_GetAll = ents.GetAll
	local ipairs = ipairs
	local Angle = Angle

	hook_Add('PlayerInitialSpawn', addonName, function( ply )
		local steamID = getSteamID( ply )
		for _, ent in ipairs( ents_GetAll() ) do
			if (ent.IsPlayerRagdoll == nil) then continue end
			if ent:IsPlayerRagdoll() and ent.DisconnectedPlayer and (ent.SteamID == steamID) then
				timer_Simple(0, function()
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
					ply:SetEyeAngles( Angle( 0, ent.PlayerAngles[2], 0 ) )
					ply:SetPos( ent:LocalToWorld( ent:OBBCenter() ) )

					-- Weapons
					ply:StripWeapons()

					for _, class in ipairs( ent.Weapons ) do
						local wep = ply:Give( class )
						if IsValid( wep ) and (class == ent.ActiveWeapon) then
							ply:SetActiveWeapon( wep )
						end
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

					-- Fire Transmission
					if ent:IsOnFire() then
						ply:Ignite( 10, 0 )
					end

					-- Removing
					ent:Remove()
				end)

				break
			end
		end
	end)

end
