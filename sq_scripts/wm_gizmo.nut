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
    function GetMeta() {
        const key = "ToggleConveyor_MetaProp";
        if (key in userparams()) {
            local name = userparams()[key];
            return Object.Named(name);
        }
        return 0;
    }
    function OnTurnOn() {
        local meta = GetMeta();
        if (meta==0) return;
        if (! Object.HasMetaProperty(self, meta)) {
            Object.AddMetaProperty(self, meta);
        }
    }
    function OnTurnOff() {
        local meta = GetMeta();
        if (meta==0) return;
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
        PostMessage(self, "UpdateConveyorSpeed");
    }
    function OnTurnOff() {
        base.OnTurnOff();
        PostMessage(self, "UpdateConveyorSpeed");
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
                // If another Population link exists, we assume (rightly or
                // wrongly) that another conveyor is gonna be controlling the
                // velocity of the object, so we leave it alone.
                if (! Link.AnyExist("~Population", whatTouchedMe)) {
                    ApplyConveyorSpeed(whatTouchedMe, false);
                }
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
    function OnUpdateConveyorSpeed() {
        local links = Link.GetAll("Population", self);
        foreach (link in links) {
            ApplyConveyorSpeed(LinkDest(link), true);
        }
    }
}

/* Object suited for riding looping conveyors, that detects if it gets
   stuck and tries to unstick itself. */
class ConveyorRider extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetData("LastPosition", Object.Position(self));
            SetOneShotTimer("AmIStuck?", 1.0);
        }
    }

    function OnTimer() {
        if (message().name=="AmIStuck?") {
            local lastPos = GetData("LastPosition");
            local pos = Object.Position(self);
            local moved = (pos-lastPos).Length();
            SetData("LastPosition", pos);
            if (moved <= 1.0) {
                print("ConveyorRider "+self+" got stuck; trying to unstick.");
                Unstick();
            }
            SetOneShotTimer("AmIStuck?", 1.0);
        }
    }

    function Unstick() {
        local pos = Object.Position(self);
        local fac = Object.Facing(self);
        Object.Teleport(self, pos+vector(0,0,0.5), fac);
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

class MirrorMirror extends SqRootScript {
    _reflection = null;
    _reflectionAdjust = vector(0.5,0.0,-1.5);

    function FindReflection() {
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local value = LinkTools.LinkGetData(link, "");
            if (value=="Reflection") {
                _reflection = LinkDest(link);
                break;
            }
        }
    }

    function UpdateReflection() {
        if (_reflection==null) FindReflection();
        if (_reflection==null) {
            print("ERROR: reflection not found.");
            Property.Set(self, "StTweqBlink", "AnimS", 0);
            return;
        }
        local mirrorPos = Object.Position(self);
        local player = Object.Named("Player");
        local playerPos = Object.Position(player);
        local playerFacing = Object.Facing(player);
        local headOffset = vector();
        local ignoreFacing = vector();
        Object.CalcRelTransform(player, player, headOffset, ignoreFacing, 4, 0);
        headOffset = Object.ObjectToWorld(player, headOffset) - playerPos;
        local diffPos = mirrorPos-playerPos;
        local reflectPos = vector();
        // NOTE: this will only work for mirroring across the Y axis:
        reflectPos.x = mirrorPos.x + diffPos.x + headOffset.x + _reflectionAdjust.x;
        reflectPos.y = mirrorPos.y - diffPos.y - headOffset.y + _reflectionAdjust.y;
        reflectPos.z = mirrorPos.z - diffPos.z - headOffset.z + _reflectionAdjust.z;
        local reflectFac = vector();
        reflectFac.x = 0;
        reflectFac.y = 0;
        reflectFac.z = 180-playerFacing.z;
        Object.Teleport(_reflection, reflectPos, reflectFac);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker
        && message().Op==eTweqOperation.kTweqOpFrameEvent) {
            UpdateReflection();
        }
    }
}

class FrobTweqs extends SqRootScript {
    function OnFrobWorldEnd() {
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, eTweqDo.kTweqDoDefault);
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, "Event Activate", self, 0,
            eEnvSoundLoc.kEnvSoundAtObjLoc);
    }

    function OnTweqComplete() {
        Sound.HaltSchema(self);
    }
}

/* Crank used to retract a locking rod. Note that although this uses a Lock
   link to a lockbox (so that unlocking the lockbox will retract the rod),
   the crank itself ignores the lockbox state, and is only locked once the rod
   is fully retracted. */
class LockingMechCrank extends SqRootScript {
    function IsLocked() {
        return GetProperty(self, "Locked");
    }

    function Open() {
        SetData("IsActive", true);
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, eTweqDo.kTweqDoForward);
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, "Event Activate", self, 0,
            eEnvSoundLoc.kEnvSoundAtObjLoc);
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function Close() {
        SetData("IsActive", true);
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, eTweqDo.kTweqDoReverse);
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, "Event Deactivate", self, 0,
            eEnvSoundLoc.kEnvSoundAtObjLoc);
        Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
    }

    function OnFrobWorldBegin() {
        if (IsLocked()) {
            Sound.PlayEnvSchema(self, "Event Reject, Operation FrobLock", self, 0,
                eEnvSoundLoc.kEnvSoundAtObjLoc);
            return;
        }
        Open();
    }

    function OnFrobWorldEnd() {
        if (IsLocked()) {
            return;
        }
        Close();
    }

    function OnWorldDeSelect() {
        if (IsLocked()) {
            return;
        }
        if (GetData("IsActive")) {
            Close();
        }
    }

    function OnNowUnlocked() {
        if (IsLocked()) {
            return;
        }
        Open();
    }

    function OnTweqComplete() {
        if (message().Op==eTweqOperation.kTweqOpHaltTweq) {
            Sound.HaltSchema(self);
            SetData("IsActive", false);
        }

        if (message().Op==eTweqOperation.kTweqOpHaltTweq
        && message().Dir==eTweqDirection.kTweqDirForward) {
            // Lock in the open state.
            SetProperty("Locked", true);
            SetProperty("FrobInfo", "World Action", 0);
            // Ensure all attached pieces are also in the 'open' state,
            // just in case:
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
        }
    }
}

class LockingMechGear extends SqRootScript {
    function OnTurnOn() {
        local flags = GetProperty("TrapFlags");
        local isReversed = ((flags&TRAPF_INVERT)!=0);
        local action = (isReversed? eTweqDo.kTweqDoReverse:eTweqDo.kTweqDoForward);
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, action);
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, "Event ActiveLoop", self, 0,
            eEnvSoundLoc.kEnvSoundAtObjLoc);
    }

    function OnTurnOff() {
        local flags = GetProperty("TrapFlags");
        local isReversed = ((flags&TRAPF_INVERT)!=0);
        local action = (isReversed? eTweqDo.kTweqDoForward:eTweqDo.kTweqDoReverse);
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, action);
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, "Event ActiveLoop", self, 0,
            eEnvSoundLoc.kEnvSoundAtObjLoc);
    }

    function OnTweqComplete() {
        Sound.HaltSchema(self);
    }
}

class DelayedOn extends SqRootScript {
    function OnTurnOn() {
        local delay_ms = 0;
        if (HasProperty("ScriptTiming")) {
            delay_ms = GetProperty("ScriptTiming").tointeger();
        }
        DisableTimer();
        if (delay_ms>0) {
            local timer = SetOneShotTimer("DelayedTurnOn", delay_ms/1000.0);
            SetData("DelayTimer", timer);
        } else {
            ActuallyTurnOn();
        }
    }

    function OnTurnOff() {
        DisableTimer();
        Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
    }

    function OnTimer() {
        if (message().name=="DelayedTurnOn") {
            ClearData("DelayTimer");
            ActuallyTurnOn();
        }
    }

    function DisableTimer() {
        if (IsDataSet("DelayTimer")) {
            local timer = GetData("DelayTimer");
            ClearData("DelayTimer");
            KillTimer(timer);
        }
    }

    function ActuallyTurnOn() {
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }
}
