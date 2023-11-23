// Wisper growing
schema wisp_grow
archetype DEVICE_MISC
volume -1500
wisper

// Wisper burst
schema wisp_burst
archetype DEVICE_MISC
volume -1500
wispend

// Camera wisped
schema camera_wisp
archetype DEVICE_MISC
volume -1000
camdown
env_tag (Event Deactivate) (CreatureType Camera)

// Camera unwisped
schema camera_unwisp
archetype DEVICE_MISC
volume -500
cambak
env_tag (Event Activate) (CreatureType Camera)
