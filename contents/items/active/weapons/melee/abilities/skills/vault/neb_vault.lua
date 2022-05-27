require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/neb_weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  self.iFramesTimer = 0
  self.weapon:setStance(self.stances.idle)
  self.primed = false
end

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.iFramesTimer = math.max(0, self.iFramesTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and shiftHeld == true
    and mcontroller.onGround()
    and self.cooldownTimer == 0 then

    self:setState(self.parry)
  end
  
  if mcontroller.onGround() and self.primed then
    self.weapon:setStance(self.stances.idle)
    self.primed = false
  end
  
  if self.iFramesTimer > 0 then
    status.setPersistentEffects("iFrames", {
      {stat = "fallDamageMultiplier", effectiveMultiplier = 0},
      {stat = "invulnerable", amount = 1}
    })
  else
    status.clearPersistentEffects("iFrames")
  end
end

function Parry:parry()
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  
  self.iFramesTimer = self.iFramesTime
  
  mcontroller.setYVelocity(30)
  mcontroller.setXVelocity(38 * mcontroller.facingDirection())
  self.primed = true
  animator.playSound("step")

  self.cooldownTimer = self.cooldownTime
end

function Parry:reset()
end

function Parry:uninit()
  self:reset()
end
