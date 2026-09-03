AddCSLuaFile()

SWEP.PrintName = "Lua Physgun"
SWEP.Author = "GMod Replica"
SWEP.Purpose = "Hold LMB to grab. Release to drop. RMB to freeze."
SWEP.Instructions = "Hold LMB: Grab\nRelease LMB: Drop\nRMB: Freeze\nE + Mouse: Rotate\nE + W/S: Distance\nE + Shift: Snap Rotation"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Base = "weapon_base"
SWEP.IsLuaPhysgun = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.UseHands = true

-- Visuals (File scope -> PascalCase)
local MatBeam = Material("sprites/physbeama")
local MatGlow = Material("sprites/physg_glow1")

-------------------------------------------------------------------------
-- CONVARS / SETTINGS
-------------------------------------------------------------------------
if CLIENT then
    local conVarDefs = {
        -- Physics Movement
        { name = "cl_physgun_timetoarrive",         default = "0.03",   userinfo = true,    min = 0.001,    help = "Time (seconds) for object to reach target position linearly" },
        { name = "cl_physgun_timetoarrive_angular", default = "0.03",   userinfo = true,    min = 0.001,    help = "Time (seconds) for object to reach target angle" },
        { name = "cl_physgun_damping",              default = "0.9",    userinfo = true,                    help = "Linear damping factor" },
        { name = "cl_physgun_damping_angular",      default = "1.2",    userinfo = true,                    help = "Angular damping factor" },

        -- Physics Limits
        { name = "cl_physgun_maxspeed",             default = "5000",   userinfo = true,    help = "Maximum linear speed" },
        { name = "cl_physgun_maxspeed_damping",     default = "10000",  userinfo = true,    help = "Maximum linear damping force" },
        { name = "cl_physgun_maxangular",           default = "5000",   userinfo = true,    help = "Maximum angular force (torque)" },
        { name = "cl_physgun_maxangular_damping",   default = "10000",  userinfo = true,    help = "Maximum angular damping" },

        -- Range & Cooldowns
        { name = "cl_physgun_maxrange",             default = "8192",   userinfo = true,    help = "Maximum grab distance" },
        { name = "cl_physgun_minrange",             default = "35",     userinfo = true,    help = "Minimum hold distance" },
        { name = "cl_physgun_freezecooldown",       default = "0.25",   userinfo = true,    help = "Cooldown (seconds) before you can grab again after freezing something" },

        -- Visuals
        { name = "cl_physgun_beamsegments",         default = "25", userinfo = false,   min = 0,    max = 500,  help = "Detail level of the beam curve" },
        { name = "cl_physgun_drawtip",              default = "1",  userinfo = false,   min = 0,    max = 1,    help = "Draw sprite glow at end of beam (Tip)" },
        { name = "cl_physgun_drawglow",             default = "1",  userinfo = false,   min = 0,    max = 1,    help = "Draw sprite glow at muzzle of gun (Glow)" },
    }

    -- Create ConVars
    for _, cv in ipairs(conVarDefs) do
        CreateClientConVar(cv.name, cv.default, true, cv.userinfo, cv.help, cv.min, cv.max)
    end

    -- Smart Reset Command
    concommand.Add("cl_physgun_reset", function()
        print("---------------------------------------------")
        print("Lua Physgun resetting to defaults...")
        print("---------------------------------------------")
        
        local changes = 0

        for _, cv in ipairs(conVarDefs) do
            local conVarObj = GetConVar(cv.name)
            
            if conVarObj then
                local curVal = conVarObj:GetFloat()
                local defVal = tonumber(cv.default) or 0
                
                -- Compare with small epsilon to handle float precision
                if math.abs(curVal - defVal) > 0.001 then
                    -- Print: Name: Old -> New
                    MsgC(Color(255, 200, 100), cv.name .. ": ")
                    MsgC(Color(255, 100, 100), tostring(curVal))
                    MsgC(Color(255, 255, 255), " -> ")
                    MsgC(Color(100, 255, 100), cv.default .. "\n")
                    
                    RunConsoleCommand(cv.name, cv.default)
                    changes = changes + 1
                end
            end
        end

        print("---------------------------------------------")
        print("Reset " .. changes .. " setting" .. (changes == 1 and "" or "s") .. " to default")
    end)
end

function SWEP:Initialize()
    self:SetHoldType("physgun")
    self.NextGrabTime = 0
    
    self:SetSkin(1)
    
    if CLIENT then
        self.ViewModelFOV = GetConVar("viewmodel_fov"):GetFloat()
    end
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            vm:SetSkin(1)
        end
    end
    
    -- Reset the state monitor cache on deploy
    self.CachedHeldEntity = nil
    
    return true
end

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "HeldEntity")
    self:NetworkVar("Float", 0, "HoldDistance")
    self:NetworkVar("Angle", 0, "TargetAngle")
    self:NetworkVar("Float", 1, "YawOffset")
    self:NetworkVar("Bool", 0, "IsRotating")
    
    self:NetworkVar("Vector", 0, "VisualOffset")
    self:NetworkVar("Vector", 1, "PhysOffset")
    self:NetworkVar("Int", 0, "PhysicsBone")
end

-------------------------------------------------------------------------
-- LOGIC: STATE MONITOR
-------------------------------------------------------------------------
-- This function monitors the HeldEntity DTVar for changes.
-- It ensures that Hooks (Pickup/Drop) fire regardless of how the
-- variable was set (Input, Spawn Menu, Deletion, etc).
function SWEP:CheckHeldState(ply)
    local currentHeld = self:GetHeldEntity()
    local lastHeld = self.CachedHeldEntity

    -- No change in state
    if currentHeld == lastHeld then return end

    -- CASE: DROP (Was holding, now not holding or holding different)
    if IsValid(lastHeld) then
        -- Clean up removal watcher for the old entity
        lastHeld:RemoveCallOnRemove("LuaPhysgun_Tracker_" .. self:EntIndex())
        
        -- Fire Drop Hook (if not already handled by the removal callback)
        if not lastHeld._PhysgunDropHandled then
            hook.Run("PhysgunDrop", ply, lastHeld)
        end
        
        -- Reset Flags
        lastHeld._PhysgunDropHandled = nil

        -- Reset Local Rotation logic
        self.RawRotation = nil
        self.RawPitch = nil
        self.RawYawOffset = nil
    end

    -- CASE: PICKUP (Now holding valid entity)
    if IsValid(currentHeld) then
        -- We do NOT run the permission check here. CheckHeldState runs AFTER variables are set.
        -- Permission checks happen in TryPickup.
        -- We run OnPhysgunPickup logic here if needed, or simply let TryPickup handle the initial hook.
        -- For external pickups (Spawn Menu), this block ensures logic is initialized.
        
        -- Setup Deletion Watcher
        -- This ensures we catch deletions (e.g. Undo) immediately before the entity becomes NULL
        local wepIndex = self:EntIndex()
        currentHeld:CallOnRemove("LuaPhysgun_Tracker_" .. wepIndex, function(ent)
            local wep = Entity(wepIndex)
            if IsValid(wep) and wep.GetHeldEntity and wep:GetHeldEntity() == ent then
                -- Mark flag so the State Monitor loop doesn't double-fire the hook
                ent._PhysgunDropHandled = true
                hook.Run("PhysgunDrop", wep:GetOwner(), ent)
                
                -- Force state to null immediately
                wep:SetHeldEntity(NULL)
            end
        end)

        -- Initialize Local Rotation Variables
        -- (Needed here because client might not have run TryPickup if spawned from menu)
        local entAng = currentHeld:GetAngles()
        local phys = currentHeld:GetPhysicsObjectNum(self:GetPhysicsBone())
        
        if IsValid(phys) and currentHeld:GetClass() == "prop_ragdoll" then
            entAng = phys:GetAngles()
        end
        
        self.RawPitch = entAng.p
        self.RawYawOffset = self:GetYawOffset()
        self.LastShiftDown = false
    end

    -- Update Cache
    self.CachedHeldEntity = currentHeld
end

-------------------------------------------------------------------------
-- LOGIC: PICKUP
-------------------------------------------------------------------------
function SWEP:TryPickup(ply, eyePos, aimVec)
    -- Get User Setting for Range
    local range = ply:GetInfoNum("cl_physgun_maxrange", 8192)

    local tr = util.TraceLine({
        start = eyePos,
        endpos = eyePos + aimVec * range,
        filter = {ply, self}
    })

    if IsValid(tr.Entity) and not tr.Entity:IsPlayer() and not tr.Entity:IsWorld() then
        -- [FIX] Prop Protection Hook
        -- We call this here to PREVENT the pickup if returned false.
        -- This runs on both Client (Prediction) and Server.
        if hook.Run("PhysgunPickup", ply, tr.Entity) == false then return end

        local phys = tr.Entity:GetPhysicsObjectNum(tr.PhysicsBone)
        
        -- Allow client to proceed even if phys obj isn't fully valid locally yet (Prediction)
        if IsValid(phys) or (CLIENT and tr.Entity:GetBoneCount() > 0) then
            local dist = (tr.HitPos - eyePos):Length()
            
            -- If phys isn't valid on client yet, we use default local coords
            local physPos = tr.Entity:WorldToLocal(tr.HitPos)
            if IsValid(phys) then physPos = phys:WorldToLocal(tr.HitPos) end

            self:PickupObject(tr.Entity, tr.PhysicsBone, dist, tr.Entity:WorldToLocal(tr.HitPos), physPos)
        end
    end
end

function SWEP:PickupObject(ent, physBone, dist, visOffset, physOffset)
    if not IsValid(ent) then return end

    -- [PREDICTION] Set NetVars immediately
    self:SetHeldEntity(ent)
    self:SetPhysicsBone(physBone)
    self:SetHoldDistance(dist)
    self:SetVisualOffset(visOffset)
    self:SetPhysOffset(physOffset)
    
    local entAng = ent:GetAngles()
    local phys = ent:GetPhysicsObjectNum(physBone)

    if IsValid(phys) and ent:GetClass() == "prop_ragdoll" then
        entAng = phys:GetAngles()
    end

    self:SetTargetAngle(entAng)
    self:SetYawOffset(self:GetOwner():EyeAngles().y - entAng.y)
    
    -- [SERVER] Authoritative Physics Change
    if SERVER then
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
            phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
            
            self.OriginalMass = phys:GetMass()
            phys:SetMass(45678)
            
            self.OriginalGravity = phys:IsGravityEnabled()
            phys:EnableGravity(false)
        end

        -- [HOOK] OnPhysgunPickup (Server Game Event)
        hook.Run("OnPhysgunPickup", self:GetOwner(), ent)
    end
end

-------------------------------------------------------------------------
-- LOGIC: DROP
-------------------------------------------------------------------------
function SWEP:DropObject()
    local ent = self:GetHeldEntity()
    
    if SERVER and IsValid(ent) then
        local phys = ent:GetPhysicsObjectNum(self:GetPhysicsBone())
        if IsValid(phys) then
            phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
            if self.OriginalMass then
                phys:SetMass(self.OriginalMass)
                self.OriginalMass = nil

                phys:EnableGravity(self.OriginalGravity)
                self.OriginalGravity = nil
            end
        end
    end
    
    -- We simply clear the DT var. CheckHeldState will handle the hooks.
    self:SetHeldEntity(NULL)
    self:SetPhysicsBone(0)
    self:SetIsRotating(false)
end

-------------------------------------------------------------------------
-- INPUT
-------------------------------------------------------------------------
function SWEP:PrimaryAttack()
    if self.NextGrabTime > CurTime() or self:GetOwner():KeyDown(IN_ATTACK2) then return end
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:SecondaryAttack()
    local held = self:GetHeldEntity()
    local didFreeze = false

    if IsValid(held) then
        local phys = held:GetPhysicsObjectNum(self:GetPhysicsBone())
        local canFreeze = true

        if SERVER then
            if IsValid(phys) then
                -- [HOOK] OnPhysgunFreeze (Server)
                if hook.Run("OnPhysgunFreeze", self, phys, held, self:GetOwner()) == false then
                    canFreeze = false
                end
            else
                canFreeze = false
            end
        end

        if canFreeze then
            didFreeze = true
            if SERVER and IsValid(phys) then
                phys:EnableMotion(false)
                phys:Wake()
            end
            -- DropObject handles the logic
            self:DropObject()
        end
    end
    
    if didFreeze then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        
        local freezeTime = self:GetOwner():GetInfoNum("cl_physgun_freezecooldown", 0.25)
        local cd = CurTime() + freezeTime
        
        self:SetNextPrimaryFire(cd)
        self:SetNextSecondaryFire(cd)
        self.NextGrabTime = cd
    end
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    local owner = self:GetOwner()

    if not owner:KeyPressed(IN_RELOAD) then return end
    
    if SERVER then
        if hook.Run("OnPhysgunReload", self, owner) == false then
            owner:PhysgunUnfreeze()
        end
    end
end

function SWEP:HUDShouldDraw(element)
    if IsValid(self:GetHeldEntity()) and element == "CHudWeaponSelection" then
        return false
    end
end

-------------------------------------------------------------------------
-- PHYSICS LOGIC
-------------------------------------------------------------------------
-- Helper for grid snapping
local function SnapToGrid(vec, gridSize)
    if gridSize <= 0 then return vec end
    return Vector(
        math.Round(vec.x / gridSize) * gridSize,
        math.Round(vec.y / gridSize) * gridSize,
        math.Round(vec.z / gridSize) * gridSize
    )
end

-- Helper for angle snapping
local function SnapAngle(val, snapSize)
    if snapSize <= 0 then return math.NormalizeAngle(val) end
    return math.NormalizeAngle(math.Round(val / snapSize) * snapSize)
end

function SWEP:RunPhysics(ply, mv, cmd)
    -- [FIX] Update State Monitor
    -- Checks for changes in HeldEntity and fires Pickup/Drop hooks accordingly.
    self:CheckHeldState(ply)

    -- This function now runs Shared (Client + Server) via SetupMove.
    local dt = engine.TickInterval()
    local eyePos = mv:GetOrigin() + ply:GetCurrentViewOffset() + (mv:GetVelocity() * dt)
    local aimVec = cmd:GetViewAngles():Forward()
    
    local held = self:GetHeldEntity()

    -- TRY PICKUP
    if not IsValid(held) then
        if cmd:KeyDown(IN_ATTACK) and not cmd:KeyDown(IN_ATTACK2) then
            if CurTime() >= (self.NextGrabTime or 0) then
                self:TryPickup(ply, eyePos, aimVec)
                -- Refresh local var after pickup attempt
                held = self:GetHeldEntity()
            end
        end
    end

    -- PHYSICS LOOP
    if IsValid(held) then
        if not cmd:KeyDown(IN_ATTACK) then
            self:DropObject()
            return
        end

        local minR = ply:GetInfoNum("cl_physgun_minrange", 35)
        local maxR = ply:GetInfoNum("cl_physgun_maxrange", 8192)

        -- SCROLL DISTANCE (Shared Prediction)
        local wheel = cmd:GetMouseWheel()
        if wheel ~= 0 then
            local speed = ply:GetInfoNum("physgun_wheelspeed", 10)
            self:SetHoldDistance(math.Clamp(self:GetHoldDistance() + (wheel * speed), minR, maxR))
        end

        -- ROTATION (Shared Prediction)
        if cmd:KeyDown(IN_USE) then
            self:SetIsRotating(true)
            
            -- W/S Distance
            local distSpeed = 100 * dt 
            if cmd:KeyDown(IN_FORWARD) then
                self:SetHoldDistance(math.Clamp(self:GetHoldDistance() + distSpeed, minR, maxR))
            elseif cmd:KeyDown(IN_BACK) then
                self:SetHoldDistance(math.Clamp(self:GetHoldDistance() - distSpeed, minR, maxR))
            end

            -- Mouse Rotation (Relative to Player)
            local sens = ply:GetInfoNum("physgun_rotation_sensitivity", 0.05)
            local mx = cmd:GetMouseX() * sens
            local my = cmd:GetMouseY() * sens 
            
            -- Initialize Raw Rotation accumulator if needed
            if not self.RawRotation then
                local currentAng = self:GetTargetAngle()
                -- FIX: Update the Yaw to match the prop's current visual orientation
                -- (ViewAngle - Offset) before we start applying new rotations.
                currentAng.y = math.NormalizeAngle(cmd:GetViewAngles().y - self:GetYawOffset())
                self.RawRotation = currentAng
            end

            if mx ~= 0 or my ~= 0 then
                local viewAng = cmd:GetViewAngles()

                -- 1. Rotate the Raw Accumulator
                -- Mouse X: Rotate around World Z (Up)
                if mx ~= 0 then
                    self.RawRotation:RotateAroundAxis(Vector(0, 0, 1), mx)
                end
                -- Mouse Y: Rotate around Player Right Vector
                if my ~= 0 then
                    self.RawRotation:RotateAroundAxis(viewAng:Right(), my)
                end
                
                self.RawRotation:Normalize()
            end

            -- 2. Calculate Final Target Angle (Handle Snapping)
            local finalAng = self.RawRotation
            local shiftDown = cmd:KeyDown(IN_SPEED)

            if shiftDown then
                local snapAng = ply:GetInfoNum("gm_snapangles", 45)
                if snapAng > 0 then
                    -- Snap the Euler components of the Raw Rotation
                    local snapped = Angle(
                        SnapAngle(self.RawRotation.p, snapAng),
                        SnapAngle(self.RawRotation.y, snapAng),
                        SnapAngle(self.RawRotation.r, snapAng)
                    )
                    finalAng = snapped
                end
            end

            -- 3. Apply to NetworkVar
            self:SetTargetAngle(finalAng)

            -- 4. Sync YawOffset (Essential for Shadow Control Physics)
            -- The physics calc expects: TargetY = ViewY - YawOffset
            -- So: YawOffset = ViewY - TargetY
            self:SetYawOffset(math.NormalizeAngle(cmd:GetViewAngles().y - finalAng.y))

        else
            self:SetIsRotating(false)
            -- Clear accumulator so we fetch fresh angle on next rotation start
            self.RawRotation = nil
        end

        -- Physics Setup (Server Only Application)
        if SERVER then
            local phys = held:GetPhysicsObjectNum(self:GetPhysicsBone())
            if not IsValid(phys) then self:DropObject() return end

            -- Get Settings
            local cfgTimeArrive = ply:GetInfoNum("cl_physgun_timetoarrive", 0.03)
            local cfgTimeArriveAng = ply:GetInfoNum("cl_physgun_timetoarrive_angular", 0.03)
            local cfgMaxSpeed = ply:GetInfoNum("cl_physgun_maxspeed", 5000)
            local cfgMaxSpeedDamp = ply:GetInfoNum("cl_physgun_maxspeed_damping", 10000)
            local cfgMaxAngular = ply:GetInfoNum("cl_physgun_maxangular", 5000)
            local cfgMaxAngularDamp = ply:GetInfoNum("cl_physgun_maxangular_damping", 10000)
            local cfgDamping = ply:GetInfoNum("cl_physgun_damping", 0.9)
            local cfgRotDamp = ply:GetInfoNum("cl_physgun_damping_angular", 1.2)

            local dist = math.max(self:GetHoldDistance(), minR)
            local currentAng = self:GetTargetAngle()
            local finalAng = Angle(currentAng.p, currentAng.y, currentAng.r)
            finalAng.y = cmd:GetViewAngles().y - self:GetYawOffset()
            
            local crosshairPos = eyePos + (aimVec * dist)
            local rotatedOffset = LocalToWorld(self:GetPhysOffset(), Angle(0,0,0), Vector(0,0,0), finalAng)
            local targetOrigin = crosshairPos - rotatedOffset

            -- Grid Snapping
            local gridSize = ply:GetInfoNum("gm_snapgrid", 0)
            if gridSize > 0 then
                targetOrigin = SnapToGrid(targetOrigin, gridSize)
            end

            phys:Wake()
                
            -- Manual Linear Control
            local physVel = phys:GetVelocity()
            local physPos = phys:GetPos()
            local diff = targetOrigin - physPos
            local distance = diff:Length()
            local mass = 45678

            local dir = diff / distance
            
            local tta = math.max(cfgTimeArrive, 0.001)
            local targetSpeed = distance / tta

            if targetSpeed > cfgMaxSpeed then
                targetSpeed = cfgMaxSpeed
            end
            
            local targetVel = dir * targetSpeed
            local forceDir = targetVel - physVel
            local force = forceDir * mass * cfgDamping

            local forceMag = force:Length()
            local maxForceVal = cfgMaxSpeedDamp * mass
            
            if forceMag > maxForceVal then
                force = force:GetNormalized() * maxForceVal
            end

            phys:ApplyForceCenter(force)

            -- Angular Control
            local shadow = {}
            shadow.delta = dt
            shadow.secondstoarrive = math.max(cfgTimeArriveAng, 0.001)
            shadow.maxspeed = 0
            shadow.maxspeeddamp = 0
            shadow.angle = finalAng
            shadow.maxangular = cfgMaxAngular
            shadow.maxangulardamp = cfgMaxAngularDamp
            shadow.dampfactor = cfgRotDamp
            shadow.teleportdistance = 0
         
            phys:ComputeShadowControl(shadow)
        end
    end
end

-------------------------------------------------------------------------
-- VISUALS
-------------------------------------------------------------------------
function SWEP:AdjustMouseSensitivity()
    return 1
end

function SWEP:DrawWorldModel()
    self:DrawModel()
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local att = self:GetAttachment(1)
    if not att then return end
    
    local colVec = owner:GetWeaponColor():GetNormalized()
    local col = Color(colVec.x * 255, colVec.y * 255, colVec.z * 255, 255)

    local held = self:GetHeldEntity()
    local isHolding = IsValid(held)
    local enabled = isHolding or (owner:KeyDown(IN_ATTACK) and not owner:KeyDown(IN_ATTACK2) and CurTime() >= (self.NextGrabTime or 0))

    -- Calculate Data
    local hitPos, drawPos
    local bone = self:GetPhysicsBone()
    local eyePos = owner:EyePos()
    local eyeDir = owner:EyeAngles():Forward()

    if isHolding then
        drawPos = held:LocalToWorld(self:GetVisualOffset())
        hitPos = drawPos
    else
        local maxR = owner:GetInfoNum("cl_physgun_maxrange", 8192)
        local tr = util.TraceLine({
            start = eyePos,
            endpos = eyePos + eyeDir * maxR,
            filter = {owner, self}
        })
        hitPos = tr.HitPos
        drawPos = tr.HitPos
        bone = 0
        held = NULL
    end

    if hook.Run("DrawPhysgunBeam", owner, self, enabled, held, bone, hitPos) ~= false then
        if enabled then
            -- Calculate Ideal Point (Crosshair depth)
            local beamDist = eyePos:Distance(drawPos)
            if beamDist < 35 then beamDist = 35 end
            local idealPos = eyePos + (eyeDir * beamDist)
            
            -- Tangent points to Ideal (Straight when aligned)
            local tangentDir = (idealPos - att.Pos):GetNormalized()
            
            self:DrawBendyBeam(att.Pos, tangentDir, drawPos, col)
        end
    end
end

-- Legacy helper used in RunPhysics/Visuals in original code
function SWEP:GetBeamTargetPos(ply)
    local held = self:GetHeldEntity()
    local maxR = ply:GetInfoNum("cl_physgun_maxrange", 8192)

    if IsValid(held) then
        return held:LocalToWorld(self:GetVisualOffset())
    elseif ply:KeyDown(IN_ATTACK) then
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:EyeAngles():Forward() * maxR,
            filter = {ply, self}
        })
        return tr.HitPos
    end
    return nil
end

if CLIENT then
    hook.Add("PostDrawOpaqueRenderables", "LuaPhysgun_DrawVisuals", function()
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        
        if not IsValid(wep) or not wep.IsLuaPhysgun then return end

        local vm = ply:GetViewModel()
        if not IsValid(vm) then return end

        if hook.Run("PreDrawViewModel", vm, ply, wep) == true then return end

        if ply:ShouldDrawLocalPlayer() then return end
        
        local attID = vm:LookupAttachment("muzzle")
        if attID == 0 then attID = 1 end
        
        local att = vm:GetAttachment(attID)
        if not att then return end

        local colVec = ply:GetWeaponColor():GetNormalized()
        local col = Color(colVec.x * 255, colVec.y * 255, colVec.z * 255, 255)

        if ply:GetInfoNum("cl_physgun_drawglow", 1) == 1 then
            cam.IgnoreZ(true)
                render.SetMaterial(MatGlow)
                render.DrawSprite(att.Pos, 55, 55, col)
            cam.IgnoreZ(false)
        end

        local held = wep:GetHeldEntity()
        local isHolding = IsValid(held)
        local enabled = isHolding or (ply:KeyDown(IN_ATTACK) and not ply:KeyDown(IN_ATTACK2) and CurTime() >= (wep.NextGrabTime or 0))

        local hitPos, drawPos
        local bone = wep:GetPhysicsBone()
        local eyePos = ply:EyePos()
        local eyeDir = ply:EyeAngles():Forward()

        if isHolding then
            drawPos = held:LocalToWorld(wep:GetVisualOffset())
            hitPos = drawPos
        else
            local maxR = ply:GetInfoNum("cl_physgun_maxrange", 8192)
            local tr = util.TraceLine({
                start = eyePos,
                endpos = eyePos + eyeDir * maxR,
                filter = {ply, wep}
            })
            hitPos = tr.HitPos
            drawPos = tr.HitPos
            bone = 0
            held = NULL
        end

        if hook.Run("DrawPhysgunBeam", ply, wep, enabled, held, bone, hitPos) ~= false then
            if enabled then
                cam.IgnoreZ(true)
                    local beamDist = eyePos:Distance(drawPos)
                    if beamDist < 35 then beamDist = 35 end
                    
                    -- Ideally, the beam points at the crosshair at the correct depth
                    local idealPos = eyePos + (eyeDir * beamDist)
                    local tangentDir = (idealPos - att.Pos):GetNormalized()

                    wep:DrawBendyBeam(att.Pos, tangentDir, drawPos, col)
                cam.IgnoreZ(false)
            end
        end
    end)
end

function SWEP:DrawBendyBeam(startPos, tangentDir, endPos, color)
    local scroll = CurTime() * 0.5
    local isHolding = IsValid(self:GetHeldEntity())
    
    local segments = GetConVar("cl_physgun_beamsegments"):GetInt()
    local drawTip = GetConVar("cl_physgun_drawtip"):GetBool()

    local p0 = startPos
    local p3 = endPos
    
    local curveDist = p0:Distance(p3)
    
    -- [FIX] Reduce Tangent Influence
    -- Previous value was equal to curveDist (1.0), which creates large loops/humps 
    -- when the muzzle sways. 0.33 is standard for tighter, smoother Bezier curves.
    local tangentDist = curveDist * 0.8
    
    local p1 = p0 + (tangentDir * tangentDist)
    local p2 = p3 -- Quadratic-ish feel (P2 at End) vs Cubic. 

    local function drawBeamLayer(mat, width, alpha, speedMult)
        local layerCol = Color(color.r, color.g, color.b, alpha)
        render.SetMaterial(mat)
        render.StartBeam(segments + 1)
        render.AddBeam(startPos, width, scroll * speedMult, layerCol)

        for i = 1, segments do
            local t = i / segments
            local invT = 1 - t
            
            -- Cubic Bezier Formula
            local p = (invT * invT * invT) * p0
                    + (3 * invT * invT * t) * p1
                    + (3 * invT * t * t) * p2
                    + (t * t * t) * p3
            
            local distFrac = (t * curveDist) / 256
            local tex = (scroll * speedMult) + (distFrac * 2)

            render.AddBeam(p, width, tex, layerCol)
        end
        render.EndBeam()
    end
    
    if isHolding then drawBeamLayer(MatBeam, 10, 120, 10) end
    local coreAlpha = isHolding and 255 or 255
    local coreWidth = isHolding and 6 or 2
    drawBeamLayer(MatBeam, coreWidth, coreAlpha, 100)

    if drawTip then
        local tipAlpha = isHolding and 255 or 200
        local size = math.random(5, 16)
        render.SetMaterial(MatGlow)
        render.DrawSprite(endPos, size, size, Color(color.r, color.g, color.b, 255))
    end
end

function SWEP:OnRemove()
    if SERVER then self:DropObject() end
end

function SWEP:Holster()
    if SERVER then self:DropObject() end
    return true
end

-- SHARED HOOK: Lock Input and View while maintaining mouse delta
hook.Add("StartCommand", "LuaPhysgun_InputLock", function(ply, cmd)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.IsLuaPhysgun then
        -- Only lock if holding valid entity AND holding E
        if IsValid(wep:GetHeldEntity()) and cmd:KeyDown(IN_USE) then
            
            -- Lock Movement
            cmd:ClearMovement()
            cmd:RemoveKey(IN_JUMP)
            cmd:RemoveKey(IN_DUCK)
            cmd:RemoveKey(IN_WALK)
            cmd:RemoveKey(IN_RUN)
            
            -- Lock View
            if not wep.LockedViewAngles then
                wep.LockedViewAngles = cmd:GetViewAngles()
            end
            
            -- Apply locked angles
            cmd:SetViewAngles(wep.LockedViewAngles)
        else
            -- Reset lock when E released
            if wep.LockedViewAngles then
                wep.LockedViewAngles = nil
            end
        end
    end
end)

-- SHARED HOOK: Run Physics Logic
-- Allows Client to predict pickup/drop/input, while Server handles forces.
hook.Add("SetupMove", "LuaPhysgun_Physics_Hook", function(ply, mv, cmd)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.IsLuaPhysgun then
        wep:RunPhysics(ply, mv, cmd)
    end
end)