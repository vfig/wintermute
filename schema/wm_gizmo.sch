// Weird desktop contraption
schema wm_contraption
archetype DEVICE_MISC
mono_loop 0 0
volume -2000
gears4
env_tag (Event Activate) (DeviceType Contraption)

// Locking bar "door" moving.
schema wm_lockbar_op
archetype DEVICE_MISC
mono_loop 0 0
volume -1000
elev1lp
env_tag (Event StateChange)  (DoorType LockingBar) (OpenState Opening Closing) (OldOpenState Open Closed Opening Closing)

// Locking bar "door" stopping.
schema wm_lockbar_cl
archetype DEVICE_MISC
volume -1000
elev1st
env_tag (Event StateChange)  (DoorType LockingBar) (OpenState Open Closed) (OldOpenState Opening Closing)

// Locking bar machine gears turning.
schema wm_lockbar_gear
archetype DEVICE_MISC
mono_loop 0 0
volume -1500
gears2
env_tag (Event ActiveLoop) (DeviceType LockingBarGear)

// Locking bar crank - turning
schema wm_lockbarcron
archetype DEVICE_MISC
volume -1000
lvrotat1
env_tag (Event Activate) (DeviceType LockingBarCrank)

// Locking bar crank - returning
schema wm_lockbarcroff
archetype DEVICE_MISC
volume -1000
lvrotat2
env_tag (Event Deactivate) (DeviceType LockingBarCrank)
