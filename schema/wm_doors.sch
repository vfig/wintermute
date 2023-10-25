//PRESSURE DOOR 1 - JOINTS OPENING - AI
schema d_press_jo_a
archetype AI_DOOR
volume -100
dorwheel1
env_tag (Event Activate) (DoorType Pressure)

//PRESSURE DOOR - JOINTS CLOSING - AI
schema d_press_jc_a
archetype AI_DOOR
volume -100
dorwheel2
env_tag (Event Deactivate) (DoorType Pressure)

//PRESSURE DOOR 1 - JOINTS OPENING - PLAYER
schema d_press_jo_p
archetype PLYR_DOOR
volume -500
dorwheel1
env_tag (Event Activate) (DoorType Pressure) (CreatureType Player)

//PRESSURE DOOR - JOINTS CLOSING - PLAYER
schema d_press_jc_p
archetype PLYR_DOOR
volume -500
dorwheel2
env_tag (Event Deactivate) (DoorType Pressure) (CreatureType Player)

//PRESSURE DOOR - knock
schema d_press_kn
archetype AI_DOOR
volume -500
dorknock2
env_tag (Event Knock) (DoorType Pressure)
