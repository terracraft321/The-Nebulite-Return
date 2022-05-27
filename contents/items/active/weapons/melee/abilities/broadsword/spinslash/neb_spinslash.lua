require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

SpinSlash = WeaponAbility:new()

function SpinSlash:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
  self.weapon:setStance(self.stances.idle)
end

function SpinSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self.fireMode == "alt"
    and shiftHeld == false then
    
    self:setState(self.slash)
  end
end

function SpinSlash:slash()
  local slash = coroutine.create(self.slashAction)
  coroutine.resume(slash, self)

  local movement = function()
    mcontroller.controlModifiers({runningSuppressed = true})

    if self.hover then
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
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation - util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    util.wait(self.stances.windup.duration, function()
      return status.resourceLocked("energy")
    end)

    self.weapon.aimDirection = -self.weapon.aimDirection

    self.weapon:setStance(self.stances.slash)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    armRotationOffset = armRotationOffset + 1
    if armRotationOffset > #self.armRotationOffsets then armRotationOffset = 1 end

    animator.setAnimationState("spinSwoosh", "fire", true)
    animator.playSound("flail")

    util.wait(self.stances.slash.duration, function()
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)
  end

  self.cooldownTimer = self.cooldownTime
end

function SpinSlash:reset()
  animator.setGlobalTag("swooshDirectives", "")
  self.weapon:setStance(self.stances.idle)
end

function SpinSlash:uninit()
  self:reset()
end
