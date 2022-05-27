require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

SpinSlash = WeaponAbility:new()

function SpinSlash:init()
  self.cooldownTimer = self.cooldownTime
  self.hoverTimer = self.hoverTime
  self:reset()
  self.weapon:setStance(self.stances.idle)
end

function SpinSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.hoverTimer = math.max(0, self.hoverTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self.fireMode == "alt"
    and shiftHeld == false then
    
    self:setState(self.start)
  end
end

function SpinSlash:start()
  self.hoverTimer = self.hoverTime
  animator.setAnimationState("portal", "open", true)
  animator.setAnimationState("spinSwoosh", "windup", true)
  
  self:setState(self.slash)
end

function SpinSlash:slash()
  local slash = coroutine.create(self.slashAction)
  coroutine.resume(slash, self)

  
  animator.playSound("loop", -1)
  
  local movement = function()
    mcontroller.controlModifiers ({runningSuppressed = true})
    
    if self.hover and self.hoverTimer == 0 then
      mcontroller.controlApproachYVelocity(self.hoverYSpeed, self.hoverForce)
    end
  end

  while util.parallel(slash, movement) do
    coroutine.yield()
  end
end

function SpinSlash:slashAction()
  local armRotationOffset = math.random(1, #self.armRotationOffsets)
  while self.fireMode == "alt" do
    if not status.overConsumeResource("energy", self.energyUsage * (self.stances.windup.duration + self.stances.slash.duration)) then return end

    self.weapon:setStance(self.stances.windup)
    self.weapon:updateAim()

    util.wait(self.stances.windup.duration, function()
      return status.resourceLocked("energy")
    end)

    self.weapon:setStance(self.stances.slash)
    self.weapon:updateAim()

    animator.playSound("flail")
    
    local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
    local params = {
      powerMultiplier = 0,
      power = 0
    }
    world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)

    util.wait(self.stances.slash.duration, function()
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)
  end

  self.cooldownTimer = self.cooldownTime
end

function SpinSlash:reset()
  animator.setGlobalTag("swooshDirectives", "")
  animator.setAnimationState("spinSwoosh", "idle", true)
  animator.stopAllSounds("loop")
  mcontroller.controlParameters({runningSuppressed = false})
  self.weapon:setStance(self.stances.idle)
end

function SpinSlash:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function SpinSlash:uninit()
  self:reset()
  animator.playSound("end")
  animator.setAnimationState("portal", "close", true)
end
