class StartMovingTerrain extends SqRootScript {
    // Summon elevaor to its 'next' TerrPt when the mission starts.
    function OnSim() {
        if (message().starting) {
            local link = Link.GetOne("TPathNext", self);
            if (link!=0) {
                PostMessage(LinkDest(link), "TurnOn");
            } else {
                print("ERROR: Cannot find TPathNext for elevator "+self);
            }
        }
    }
}

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
        if (enable) {
            // when an object contacts us, set their velocity to that of conveyor belt
            local convVel = vector();
            local speed = 0.0;
            // hack - use the x component of the conveyor belt velocity as the
            //    speed of the belt itself
            if (Property.Possessed(self, "ConveyorVel")) {
                convVel = Property.Get(self, "ConveyorVel");
                speed = convVel.x;
            } else {
                speed = 5.0;  // default conveyor belt speed
            }
            // Use the entire direction of the conveyor to calculate velocity.
            local convDir = Object.ObjectToWorld(self, vector(1.0,0.0,0.0))-Object.Position(self);
            convDir.Normalize();
            convVel.x = speed*convDir.x;
            convVel.y = speed*convDir.y;
            convVel.z = speed*convDir.z;
            // HACK: increase velocity to counteract gravity on upward conveyors.
            if (convDir.z>0.0) {
                local hackFactor = 1.0/(1.0-fabs(convDir.z));
                convVel.x = hackFactor*convVel.x;
                convVel.y = hackFactor*convVel.y;
            }
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

/* SameTeamCamera: a camera that, when it seems members of its own
   team within range, will turn on certain devices; and turn them
   back off again, after a delay, if it no longer sees its own team
   members. Devices must be linked from the camera with a ScriptParams
   link, with the value set to "SameTeamDevice".
*/
const kSameTeamCameraInterval = 1.0;
const kSameTeamCameraRequiredLevel = 2;
const kSameTeamCameraTimeout = 5.0;
const kSameTeamCameraRange = 25.0;

class SameTeamCamera extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("LookForSameTeam", kSameTeamCameraInterval);
        }
    }

    function OnTimer() {
        if (message().name=="LookForSameTeam") {
            LookForSameTeam();
            SetOneShotTimer("LookForSameTeam", kSameTeamCameraInterval);
        }
    }

    function LookForSameTeam() {
        local sawSomething = false;
        local myTeam = Property.Get(self, "AI_Team");
        local myPosition = Object.Position(self);
        local links = Link.GetAll("AIAwareness", self);
        foreach (link in links) {
            local target = LinkDest(link);
            local targetTeam = Property.Get(target, "AI_Team");
            if (targetTeam!=myTeam) continue;
            local level = LinkTools.LinkGetData(link, "Level");
            if (level<kSameTeamCameraRequiredLevel) continue;
            local targetPosition = Object.Position(target);
            if ((targetPosition-myPosition).Length()>kSameTeamCameraRange) continue;
            local flags = LinkTools.LinkGetData(link, "Flags");
            local fSeen = ((flags&0x01)!=0);
            local fHaveLOS = ((flags&0x08)!=0);
            local fFirstHand = ((flags&0x80)!=0);
            sawSomething = true;
        }
        local now = GetTime();
        local isActive = IsDataSet("SameTeamCameraLastSeen");
        if (sawSomething) {
            SetData("SameTeamCameraLastSeen", now);
        }
        if (!isActive && sawSomething) {
            ActivateDevices(true);
            Sound.PlaySchema(self, "cambak");
        } else if (isActive && !sawSomething) {
            local lastSeen = GetData("SameTeamCameraLastSeen");
            if ((now-lastSeen)>=kSameTeamCameraTimeout) {
                ClearData("SameTeamCameraLastSeen");
                ActivateDevices(false);
                Sound.PlaySchema(self, "camlos");
            }
        }
    }

    function ActivateDevices(turnOn) {
        local msg = (turnOn? "TurnOn":"TurnOff");
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local value = LinkTools.LinkGetData(link, "");
            if (value=="SameTeamDevice") {
                SendMessage(LinkDest(link), msg);
            }
        }
    }
}
