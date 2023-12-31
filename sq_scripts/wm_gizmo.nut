class StartsOn  extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SendMessage(self, "TurnOn");
        }
    }
}

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
            SetData("StuckCount", 0);
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
                local count = GetData("StuckCount");
                count += 1;
                if (count>10) {
                    print("ConveyorRider "+self+" stuck for too long; destroying.");
                    Object.Destroy(self);
                    return;
                }
                SetData("StuckCount", count);
                Unstick();
            } else {
                SetData("StuckCount", 0);
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

/* Put on an AI (preferably with Idle: Returns to Origin: true). When the
   AI is at its origin point and <= level 1 alert, it will send TurnOn along
   ScriptParams[AtOrigin] links. When it becomes alerted or moves away from
   its origin, it sends TurnOff.
*/
class ActivateAtOrigin extends SqRootScript {
    function IsAtOrigin() {
        // BUG: for some reason, trying to read the AI_IdleOrgn/Original Location
        //      property here gives back an int 0 instead of the vector it should
        //      be! so instead we store it as data on sim and just use that after.
        local origin = GetData("InitialOrigin");
        local pos = Object.Position(self);
        local dist = (origin - pos).Length();
        if (dist<3.0) {
            // At the origin, or close enough.
            return 1;
        }
        return 0;
    }

    function ActivateDevices(on) {
        local msg = (on? "TurnOn":"TurnOff");
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local value = LinkTools.LinkGetData(link, "").tostring().tolower();
            if (value=="atorigin") {
                PostMessage(LinkDest(link), msg);
            }
        }
    }

    function Activate() {
        local atOrigin = IsAtOrigin();
        local alertLevel = AI.GetAlertLevel(self);
        SetData("AtOrigin", atOrigin);
        SetData("AlertLevel", alertLevel);
        local active = atOrigin && (alertLevel<2);
        local mode = GetProperty("AI_Mode");
        if (mode==eAIMode.kAIM_Dead) {
            active = false;
        }
        ActivateDevices(active);
    }

    function ActivateIfChanged() {
        local atOrigin = IsAtOrigin();
        local alertLevel = AI.GetAlertLevel(self);
        local prevAlertLevel = GetData("AlertLevel");
        local prevAtOrigin = GetData("AtOrigin");
        if (prevAlertLevel!=alertLevel
        || prevAtOrigin!=atOrigin) {
            Activate();
        }
    }

    function OnSim() {
        if (message().starting) {
            if (! HasProperty("AI_IdleOrgn")) {
                local pos = Object.Position(self);
                local fac = Object.Facing(self);
                Property.Add(self, "AI_IdleOrgn");
                Property.Set(self, "AI_IdleOrgn", "Original Facing", fac.z);
                Property.Set(self, "AI_IdleOrgn", "Original Location", pos);
                SetData("InitialOrigin", pos);
            } else {
                local pos = Object.Position(self);
                local origin = Property.Get(self, "AI_IdleOrgn", "Original Location");
                SetData("InitialOrigin", origin);
            }
            Activate();
            local timer = SetOneShotTimer("AtOrigin?", 3.0+Data.RandFlt0to1());
            SetData("Timer", timer);
        }
    }

    function OnTimer() {
        if (message().name=="AtOrigin?") {
            ActivateIfChanged();
            local timer = SetOneShotTimer("AtOrigin?", 3.0);
            SetData("Timer", timer);
        }
    }

    function OnAlertness() {
        ActivateIfChanged();
    }

    function OnSlain() {
        local timer = GetData("Timer");
        KillTimer(timer);
        Activate();
    }
}

class DumbwaiterDoor extends SqRootScript {
    function TurnOffLever() {
        Link.BroadcastOnAllLinks(self, "TurnOff", "~ControlDevice");
    }

    function ActivateDevices(on) {
        local msg = (on? "TurnOn":"TurnOff");
        Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
    }

    function StopTimer() {
        if (IsDataSet("Timer")) {
            KillTimer(GetData("Timer"));
            ClearData("Timer");
        }
    }

    function Reset() {
        TurnOffLever();
        ActivateDevices(false);
        SetData("Step", 0);
        StopTimer();
        SendMessage(self, "Open");
    }

    function NextStep() {
        local step = GetData("Step");
        if (step==0) {
            // Close door, wait for it.
            SendMessage(self, "Close");
            SetData("Step", step+1);
        } else if (step==1) {
            // Door closed, start timer.
            StopTimer();
            local timer = SetOneShotTimer("DumbwaiterDone", 5.0);
            SetData("Timer", timer);
            ActivateDevices(true);
            SetData("Step", step+1);
        } else if (step==2) {
            // Timer done, wait a moment before opening.
            StopTimer();
            local timer = SetOneShotTimer("DumbwaiterOpen", 1.0);
            SetData("Timer", timer);
            ActivateDevices(false);
            SetData("Step", step+1);
        } else if (step==3) {
            // Timer done, open door.
            Reset();
        }
    }

    function OnSim() {
        if (message().starting) {
            Reset();
        }
    }

    function OnTurnOn() {
        // Prevent StdDoor from thinking it should open.
        BlockMessage();
        // Ignore if we are already on.
        if (GetData("Step")!=0) return;
        NextStep();
    }

    function OnDoorClose() {
        NextStep();
    }

    function OnTimer() {
        if (message().name=="DumbwaiterDone"
        || message().name=="DumbwaiterOpen") {
            NextStep();
        }
    }

    function OnTurnOff() {
        // Prevent StdDoor from thinking it should close.
        BlockMessage();
        // Ignore if we are already waiting to open the door.
        if (GetData("Step")==3) return;
        local isOpen = (Door.GetDoorState(self)==eDoorStatus.kDoorOpen);
        SetData("Step", (isOpen? 3 : 2));
        NextStep();
    }
}

// On TurnOn, activates tweqs forward; on TurnOff, activates them in reverse.
class TweqToggle extends SqRootScript {
    function OnTurnOn() {
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, eTweqDo.kTweqDoForward);
    }

    function OnTurnOff() {
        ActReact.React("tweq_control", 1.0, self, 0,
            eTweqType.kTweqTypeAll, eTweqDo.kTweqDoReverse);
    }
}

// When frobbed in the world, sends TurnOn to all CD-linked devices. Simpler
// than an in-wall button. Respects Script>Trap Control Flags "Once" and
// "Invert" flags only.
class TrapFrobRelay extends SqRootScript {
    function OnFrobWorldEnd() {
        if (Locked.IsLocked(self)) return;
        local on = true;
        if (HasProperty("TrapFlags")) {
            local flags = GetProperty("TrapFlags");
            if (flags&TRAPF_INVERT) {
                on = !on;
            }
            if (flags&TRAPF_ONCE) {
                Property.SetSimple(self, "Locked", true);
            }
        }
        local msg = on? "TurnOn":"TurnOff"
        Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
    }
}

class Contraption extends SqRootScript {
    function IncrementQVar(qvar) {
        local count = 0;
        if (Quest.Exists(qvar)) {
            count = Quest.Get(qvar);
        }
        count += 1;
        Quest.Set(qvar, count);
        return count;
    }

    function UpdateCounterQVar(category) {
        local roomFrobbed = Quest.Get(category+"Frobbed");
        local roomTotal = Quest.Get(category+"Things");
        local roomRem = (roomTotal-roomFrobbed);
        local missFrobbed = Quest.Get("TotalFrobbed");
        local missTotal = Quest.Get("TotalThings");
        local missRem = (missTotal-missFrobbed);
        local digits = missRem*100+roomRem;
        Quest.Set(category+"Counter", digits);
    }

    function OnObjRoomTransit() {
        // We only care about the initial transit as we enter the first room.
        if (! IsDataSet("Category")) {
            // Get the room's category.
            local room = message().ToObjId;
            local category = "";
            if (room!=0
            && Property.Possessed(room, "SchMsg")) {
                category = Property.Get(room, "SchMsg");
            }
            if (category=="") {
                print("ERROR: Contraption "+self+" in room without Schema:Message category.");
                return null;
            }
            SetData("Category", category);
            // Every contraption needs to count itself for its category
            // and the total.
            IncrementQVar(category+"Things");
            IncrementQVar("TotalThings");
            UpdateCounterQVar(category);
        }
    }

    function OnFrobWorldEnd() {
        if (! IsDataSet("IsFrobbed")) {
            if (! IsDataSet("Category")) {
                // Missing a category; do nothing.
                print("ERROR: Contraption "+self+" in room without Schema:Message category.");
                BlockMessage();
                return;
            }
            SetData("IsFrobbed", 1);
            // Count the frob.
            local category = GetData("Category");
            IncrementQVar(category+"Frobbed");
            IncrementQVar("TotalFrobbed");
            UpdateCounterQVar(category);
        }
    }
}
