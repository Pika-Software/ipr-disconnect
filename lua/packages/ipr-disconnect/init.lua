import( gpm.LuaPackageExists( "packages/glua-extensions" ) and "packages/glua-extensions" or "https://github.com/Pika-Software/glua-extensions" )
import( gpm.LuaPackageExists( "packages/ipr-base" ) and "packages/ipr-base" or "https://github.com/Pika-Software/ipr-base" )

local packageName = gpm.Package:GetIdentifier()
local hook = hook

for version, gPackage in pairs( gpm.packages.Get( "ipr-base" ) ) do
	hook.Remove( "PlayerDisconnected", gPackage:GetIdentifier() )
end

hook.Add( "PlayerInitialized", packageName, function( ply )
	if ply:IsBot() then return end

	local sid64 = ply:SteamID64()
	for _, ent in ipairs( ents.GetAll() ) do
		if not ent:IsPlayerRagdoll() then continue end
		if ent.SteamID ~= sid64 then continue end
		ply:SetPos( ent:GetPos() )
		ent:Remove()
	end
end )

local removeDelay = CreateConVar( "ipr_remove_delay", 5, FCVAR_ARCHIVE, "Time in minutes to remove player ragdolls.", 0, 300 )

hook.Add( "PlayerDisconnected", packageName, function( ply )
	if ply:IsBot() then return end

	local ragdoll = ply:CreateRagdoll()
	if not IsValid( ragdoll ) then return end

	ragdoll.SteamID64 = ply:SteamID64()

end )