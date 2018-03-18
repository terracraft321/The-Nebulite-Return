require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/neb_weapon.lua"

Spin = WeaponAbility:new()

function Spin:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
  self.weapon:setStance(self.stances.idle)
end

function Spin:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and shiftHeld == true
    and not mcontroller.onGround()
    and self.cooldownTimer == 0 then

    self:setState(self.spin)
  end
end

function Spin:spin()
  self.weapon:setStance(self.stances.spin)
  self.weapon:updateAim()
  
  animator.setAnimationState("propelSpin", "spin")
  self.weapon.aimAngle = 0
  activeItem.setOutsideOfHand(true)
  mcontroller.setXVelocity(15 * mcontroller.facingDirection())
  mcontroller.setYVelocity(10)
  
  while self.fireMode == "alt" and not mcontroller.onGround() do
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.spinRate * self.dt)
    mcontroller.controlParameters({gravityEnabled = false, runningSuppressed = true})
    if mcontroller.falling() then
      mcontroller.setYVelocity(mcontroller.yVelocity() + 1)
    end
    if not mcontroller.onGround() and not mcontroller.falling() then
      mcontroller.setYVelocity(mcontroller.yVelocity() - 1)
    end
    
    coroutine.yield()
  end

  self.cooldownTimer = self.cooldownTime
end

function Spin:reset()
  self.weapon:setStance(self.stances.idle)
  mcontroller.controlParameters({gravityEnabled = true, runningSuppressed = false})
  activeItem.setOutsideOfHand(false)
  status.clearPersistentEffects("float")
  animator.setAnimationState("propelSpin", "idle")
end

function Spin:uninit()
  self:reset()
end
