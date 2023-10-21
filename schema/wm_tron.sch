// Scroll slot
schema wm_scrslot_ok
archetype DEVICE_MISC
volume -1000
lvrotat1
env_tag (Event Activate) (DeviceType ScrollSlot)

schema wm_scrslot_bad
archetype DEVICE_MISC
volume -1000
lvrotat2
env_tag (Event Deactivate) (DeviceType ScrollSlot)

schema wm_scrslot_busy
archetype DEVICE_MISC
volume -1000
locked
env_tag (Event Reject) (DeviceType ScrollSlot)
