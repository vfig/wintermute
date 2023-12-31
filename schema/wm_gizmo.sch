// Weird desktop contraption
schema wm_contraption
archetype DEVICE_MISC
mono_loop 0 0
volume -2000
gears4
env_tag (Event Activate) (DeviceType Contraption)

schema wm_contrapshit
archetype DEVICE_MISC
no_repeat
volume -2000
ft_frog1 ft_frog2
env_tag (Event Activate) (DeviceType Contraption) (Fungus true)

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

// Air puff from fans
schema wm_fanpuff
archetype DEVICE_MISC
volume -2000
gasemit

// Electrified rail
schema wm_elecrail
archetype DEVICE_MISC
mono_loop 0 0
volume -2000
arcs

// Worker train button ignored
schema Button_elev_rej
archetype DEVICE_SWITCH
buzzer
env_tag (Event Reject) (SwitchType BElev)

//WorkerTrain elevator
schema wt_elevloop
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp
env_tag (Event ActiveLoop) (ElevType WorkerTrain)

schema wt_elevloop00
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp00
env_tag (Speed 0 3) (ElevType WorkerTrain)

schema wt_elevloop01
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp01
env_tag (Speed 4 7) (ElevType WorkerTrain)

schema wt_elevloop02
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp02
env_tag (Speed 8 11) (ElevType WorkerTrain)

schema wt_elevloop03
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp03
env_tag (Speed 12 15) (ElevType WorkerTrain)

schema wt_elevloop04
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp04
env_tag (Speed 16 19) (ElevType WorkerTrain)

schema wt_elevloop05
archetype DEVICE_LIFT
mono_loop 0 0
volume -750
elev1lp05
env_tag (Speed 20 99) (ElevType WorkerTrain)

schema wt_elevstop
archetype DEVICE_LIFT
volume -750
elev1st
env_tag (Event Deactivate) (ElevType WorkerTrain)

// Big power room generally
schema wm_powerrm
archetype DEVICE_MISC
mono_loop 0 0
volume -1000
machlg03

// Big pistons in power room
schema wm_pistonlp
archetype DEVICE_MISC
mono_loop 0 0
delay 0
volume -500
machlg08lp

schema wm_pistonlp2
archetype DEVICE_MISC
mono_loop 0 0
delay 500
volume -500
machlg08lp

// Alternating piston things in power room
schema wm_piston1
archetype DEVICE_MISC
mono_loop 0 0
volume -500
machlg07

schema wm_piston2
archetype DEVICE_MISC
mono_loop 0 0
delay 700
volume -500
machlg07
