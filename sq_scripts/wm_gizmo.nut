// Base script for toggling conveyor speed. Use this on ConvTops.
class ToggleConveyorTop extends SqRootScript {
    function OnTurnOn() {
        local meta = Object.Named("M-FastConveyor");
        if (! Object.HasMetaProperty(self, meta)) {
            Object.AddMetaProperty(self, meta);
        }
    }
    function OnTurnOff() {
        local meta = Object.Named("M-FastConveyor");
        if (Object.HasMetaProperty(self, meta)) {
            Object.RemoveMetaProperty(self, meta);
        }
    }
}

// ConveyorBelt that can have its speed changed. Use this on Conveyors.
// Based on Thief 2's ConveyorBelt; but tracks objects on the conveyor with
// Population links, and updates their speed when the belt's speed is changed.
class ToggleConveyorBelt extends ToggleConveyorTop {
    function OnTurnOn() {
        base.OnTurnOn();
        UpdateConveyorSpeed();
    }
    function OnTurnOff() {
        base.OnTurnOff();
        UpdateConveyorSpeed();
    }
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
    }
    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
    }
    function OnPhysContactCreate() {
        local whatTouchedMe = message().contactObj;
        if (Object.Exists(whatTouchedMe)) {
            if (Physics.HasPhysics(whatTouchedMe)) {
                Link.Create("Population", self, whatTouchedMe);
                ApplyConveyorSpeed(whatTouchedMe, true);
            }
        }
    }
    function OnPhysContactDestroy() {
        local whatTouchedMe = message().contactObj;
        if (Object.Exists(whatTouchedMe)) {
            if (Physics.HasPhysics(whatTouchedMe)) {
                local link = Link.GetOne("Population", self, whatTouchedMe);
                if (link!=0) {
                    Link.Destroy(link);
                }
                ApplyConveyorSpeed(whatTouchedMe, false);
            }
        }
    }
    function ApplyConveyorSpeed(whatTouchedMe, enable) {
        const degreesPerRadian = 57.295779513;
        local convVel = vector();
        local convFacing = vector();
        local speed = 0.0;
        if (enable) {
            // when an object contacts us, set their velocity to that of conveyor belt
            convFacing = Object.Facing(self);
            // hack - use the x component of the conveyor belt velocity as the
            //    speed of the belt itself
            if (Property.Possessed(self, "ConveyorVel")) {
                convVel = Property.Get(self, "ConveyorVel");
                speed = convVel.x;
            } else {
                speed = 5.0;  // default conveyor belt speed
            }
            // only pay attention to belt rotation around z axis (for now)
            convVel.x = speed * cos(convFacing.z / degreesPerRadian);
            convVel.y = speed * sin(convFacing.z / degreesPerRadian);
            convVel.z = 0.0;
            if (whatTouchedMe == Object.Named("Player")) {
                // object is an AI, or the player
                Property.SetSimple(whatTouchedMe, "ConveyorVel", convVel);
            } else {
                // inanimate objects
                Physics.ControlVelocity(whatTouchedMe, convVel);
            }
        } else {
            // when an object breaks contact with us, set obj velocity to 0
            if (whatTouchedMe == Object.Named("Player")) {
                // object is an AI, or the player 
                Property.Remove(whatTouchedMe, "ConveyorVel");
            } else {
                // inanimate objects
                Physics.StopControlVelocity(whatTouchedMe);
            }
        }
    }
    function UpdateConveyorSpeed() {
        local links = Link.GetAll("Population", self);
        foreach (link in links) {
            ApplyConveyorSpeed(LinkDest(link), true);
        }
    }
}
