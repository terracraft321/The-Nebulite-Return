require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

TravelingSlash = WeaponAbility:new()

function TravelingSlash:init()
  self.cooldownTimer = self.cooldownTime
  self.weapon:setStance(self.stances.idle)
  self.primed = false
end

function TravelingSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and shiftHeld == false then
    if status.overConsumeResource("energy", self.energyUsage) then
      self:setState(self.windup)
    end
  end
  
  if mcontroller.onGround() and self.primed then
    local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
    local params = {
      powerMultiplier = activeItem.ownerPowerMultiplier(),
      power = self:damageAmount()
    }
  
    world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)
    animator.playSound(self:slashSound())
      
    self.primed = false
  end
end

function TravelingSlash:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
  
  mcontroller.setYVelocity(40)
  mcontroller.setXVelocity(10 * mcontroller.facingDirection())

  util.wait(self.stances.windup.duration)

  self:setState(self.fire)
end

function TravelingSlash:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()
  
  self.primed = true
  mcontroller.setYVelocity(-100)
  status.setPersistentEffects("groundSlam", {
    {stat = "fallDamageMultiplier", effectiveMultiplier = 0},
    {stat = "invulnerable", amount = 1}
  })

  util.wait(self.stances.fire.duration)
  self.cooldownTimer = self.cooldownTime
  
  self:setState(self.idle)
end

function TravelingSlash:idle()
  self.weapon:setStance(self.stances.idle)
  status.clearPersistentEffects("groundSlam")
end

function TravelingSlash:slashSound()
  return self.weapon.elementalType.."TravelSlash"
end

function TravelingSlash:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function TravelingSlash:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function TravelingSlash:uninit()
end
