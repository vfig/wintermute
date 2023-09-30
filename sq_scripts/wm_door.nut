/* Put this on a door to make its joint tweqs run in reverse before
   opening the door, and forward after closing the door.
   (The stock SubDoorJoints script runs tweqs as the door opens)
*/
class DoorJointsFirst extends SqRootScript
{
    function OnFrobWorldEnd() {
        local state = Door.GetDoorState(self);
        local flags = Property.Get(self, "StTweqJoints", "AnimS");
        if ((flags&TWEQ_AS_ONOFF)!=0) {
            if ((flags&TWEQ_AS_REVERSE)!=0) {
                TweqJoints(TWEQ_AS_ONOFF);
            } else {
                TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            }
            BlockMessage();
        } else if (state==eDoorStatus.kDoorClosed) {
            TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            BlockMessage();
        }
        // When the tweqs are not running and the door is
        // not closed, fall through to normal door behaviour.
    }

    function OnOpen() {
        local state = Door.GetDoorState(self);
        if (state==eDoorStatus.kDoorClosed) {
            TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            BlockMessage();
        }
        // When the door is not closed, fall through to
        // normal door behaviour.
    }

    function OnClose() {
        local state = Door.GetDoorState(self);
        local flags = Property.Get(self, "StTweqJoints", "AnimS");
        if ((flags&TWEQ_AS_ONOFF)!=0) {
            TweqJoints(TWEQ_AS_ONOFF);
            BlockMessage();
        }
        // When the tweqs are not running, fall through to
        // normal door behaviour.
    }

    function OnTurnOn() {
        OnOpen();
    }

    function OnTurnOff() {
        OnClose();
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints
        && message().Op==eTweqOperation.kTweqOpHaltTweq
        && message().Dir==eTweqDirection.kTweqDirForward) {
            Door.OpenDoor(self);
        }
    }

    function OnDoorClose() {
        TweqJoints(TWEQ_AS_ONOFF);
    }

    function TweqJoints(flags) {
        for(local joint=1; joint<=6; ++joint) {
            local animS = "Joint" + joint + "AnimS";
            Property.Set(self, "StTweqJoints", animS, flags);
        }
        Property.Set(self, "StTweqJoints", "AnimS", flags);
    }
}
