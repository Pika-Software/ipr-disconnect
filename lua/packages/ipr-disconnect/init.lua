install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )
install( "packages/ipr-base", "https://github.com/Pika-Software/ipr-base" )

local packageName = _PKG:GetIdentifier()
local OBS_MODE_CHASE = OBS_MODE_CHASE
local timer_Simple = timer.Simple
local ents_GetAll = ents.GetAll
local cvars_Bool = cvars.Bool
local IsValid = IsValid
local ipairs = ipairs
local Vector = Vector
local Angle = Angle
local hook = hook

for _, pkg in ipairs( gpm.Find( "ipr%-base", false, false ) ) do
    _G.hook.Remove( "PlayerDisconnected", pkg:GetIdentifier( "RemoveOnDisconnect" ) )
    _G.hook.Remove( "PlayerSpawn", pkg:GetIdentifier( "RemoveOnSpawn" ) )
end

hook.Add( "PlayerInitialSpawn", "PlayerDataLoading", function( ply, transition )
    if transition then return end
    ply[ packageName ] = true
end )

local removeDelay = CreateConVar( "ipr_remove_delay", 5, FCVAR_ARCHIVE, "Time in minutes to remove player ragdolls.", 0, 300 )

hook.Add( "PlayerDisconnected", "PlayerDataSaving", function( ply )
    if not ply:Alive() then return end

    local delay = removeDelay:GetInt()
    if delay <= 0 then return end

    local entity = ply:CreateRagdoll()
    if not IsValid( entity ) then return end
    entity.Alive = true

    -- Angles
    entity.PlayerAngles = ply:EyeAngles()

    -- Health
    entity:SetMaxHealth( ply:GetMaxHealth() )
    entity:SetHealth( ply:Health() )

    -- Armor
    entity.MaxArmor = ply:GetMaxArmor()
    entity.Armor = ply:Armor()

    timer_Simple( delay * 60, function()
        if not IsValid( entity ) then return end
        entity:Remove()
    end )
end )


local function findRagdoll( ply )
    local uid = ply:UniqueID2()
    for _, entity in ipairs( ents_GetAll() ) do
        if not entity:IsPlayerRagdoll() then continue end
        local ouid = entity:GetNW2Var( "entity-owner" )
        if not ouid or ouid ~= uid then continue end
        return entity
    end
end

hook.Add( "PlayerSpawn", "RemoveOnSpawn", function( ply, _ )
    if ply[ packageName ] then
        ply[ packageName ] = nil

        local entity = findRagdoll( ply )
        if not IsValid( entity ) then return end
        ply:SetNW2Entity( "player-ragdoll", entity )

        if not entity.Alive or entity:Health() < 1 then
            ply:KillSilent()

            if not IsValid( ply:GetObserverTarget() ) then
                ply:SetObserverMode( OBS_MODE_CHASE )
                ply:SpectateEntity( entity )
            end

            return
        end

        if not ply:Alive() then
            ply:Spawn()
        end

        -- Origin & Angles
        ply:SetEyeAngles( Angle( 0, entity.PlayerAngles[ 2 ], 0 ) )
        ply:SetPos( entity:GetPos() )

        -- Health & Armor
        local health, armor = entity:Health() / entity:GetMaxHealth(), entity.Armor / entity.MaxArmor
        timer_Simple( 0.5, function()
            if not IsValid( ply ) or not ply:Alive() then return end
            ply:SetHealth( ply:GetMaxHealth() * health )
            ply:SetArmor( ply:GetMaxArmor() * armor )
        end )

        -- Model & skin
        ply:SetModel( entity:GetModel() )
        ply:SetSkin( entity:GetSkin() )

        -- Bodygroups
        for _, bodygroup in ipairs( entity:GetBodyGroups() ) do
            ply:SetBodygroup( bodygroup.id, entity:GetBodygroup( bodygroup.id ) )
        end

        -- Flexes
        ply:SetFlexScale( entity:GetFlexScale() )
        for flex = 1, ply:GetFlexNum() do
            ply:SetFlexWeight( flex, entity:GetFlexWeight( flex ) )
        end

        -- Material
        ply:SetMaterial( entity:GetMaterial() )

        -- Sub-materials
        for index in ipairs( ply:GetMaterials() ) do
            local materialPath = entity:GetSubMaterial( index )
            if materialPath ~= "" then
                ply:SetSubMaterial( index, materialPath )
            end
        end

        -- Color
        ply:SetColor( entity:GetColor() )
        ply:SetPlayerColor( entity:GetPlayerColor() )

        -- Fire transmission
        if entity:IsOnFire() then
            entity:Extinguish()
            ply:Ignite( 16, 32 )
        end

        -- Bone manipulations
        for boneID = 0, ply:GetBoneCount() do
            ply:ManipulateBonePosition( boneID, entity:GetManipulateBonePosition( boneID ) )
            ply:ManipulateBoneAngles( boneID, entity:GetManipulateBoneAngles( boneID ) )
            ply:ManipulateBoneJiggle( boneID, entity:GetManipulateBoneJiggle( boneID ) )
            ply:ManipulateBoneScale( boneID, entity:GetManipulateBoneScale( boneID ) )
        end

        -- Velocity
        local velocity = Vector()
        if entity:IsRagdoll() then
            local count = entity:GetPhysicsObjectCount()
            for physNum = 0, count - 1 do
                local phys = entity:GetPhysicsObjectNum( physNum )
                if not IsValid( phys ) then continue end
                velocity = velocity + phys:GetVelocity()
            end

            velocity = velocity / count
        else
            local phys = entity:GetPhysicsObject()
            if IsValid( phys ) then
                velocity = phys:GetVelocity()
            end
        end

        ply:SetVelocity( velocity )
        entity:Use( ply )
        entity:Remove()
        return
    end

    if cvars_Bool( "ipr_remove_on_spawn", false ) then
        ply:RemoveRagdoll()
    end

    ply:SpectateEntity( ply )
end )