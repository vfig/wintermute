/* Put this on a door to have it open when the mission starts. */
class DoorStartsOpen extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            SendMessage(self, "Open");
        }
    }
}

/* Put this on a door to make its joint tweqs run in reverse before
   opening the door, and forward after closing the door.
   (The stock SubDoorJoints script runs tweqs as the door opens)
*/
// BUG: because this blocks StdDoor from seeing the the frob messages,
//      it doesnt know that it is the player frobbing, so plays the AI
//      sounds (i.e. sans "CreatureType Player"). The only way to fix
//      this is to completely redo all the StdDoor functionality in
//      squirrel and then e.g. inherit it for this joints behaviour.
//      But it's not a big enough problem for me to bother.
class DoorJointsFirst extends SqRootScript
{
    function OnFrobWorldEnd() {
        // Keep track of if it was the player for the sake of sound tags.
        local isPlayer = (message().Frobber==Object.Named("Player"));
        if (isPlayer) {
            SetData("PlayerFrob", 1);
        } else {
            ClearData("PlayerFrob");
        }
        local state = Door.GetDoorState(self);
        local flags = Property.Get(self, "StTweqJoints", "AnimS");
        if ((flags&TWEQ_AS_ONOFF)!=0) {
            if ((flags&TWEQ_AS_REVERSE)!=0) {
                TweqJoints(TWEQ_AS_ONOFF);
                PlayJointsSound(false);
            } else {
                TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
                PlayJointsSound(true);
            }
            BlockMessage();
        } else if (state==eDoorStatus.kDoorClosed) {
            TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            PlayJointsSound(true);
            BlockMessage();
        }
        // When the tweqs are not running and the door is
        // not closed, fall through to normal door behaviour.
    }

    function OnOpen() {
        local state = Door.GetDoorState(self);
        if (state==eDoorStatus.kDoorClosed) {
            TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            PlayJointsSound(true);
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
            PlayJointsSound(false);
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
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            ClearData("PlayerFrob");
            if (message().Dir==eTweqDirection.kTweqDirForward) {
                Door.OpenDoor(self);
            }
        }
    }

    function OnDoorClose() {
        TweqJoints(TWEQ_AS_ONOFF);
        // We ought to play the joints closing sound here, but we don't:
        // Because the StdDoor script will halt our schema immediately
        // so as to play the door closed sound; and in any case the loud
        // echoing clang of the pressure door closing pretty much makes
        // our joints-closing sound inaudible anyway.
    }

    function TweqJoints(flags) {
        for(local joint=1; joint<=6; ++joint) {
            local animS = "Joint" + joint + "AnimS";
            Property.Set(self, "StTweqJoints", animS, flags);
        }
        Property.Set(self, "StTweqJoints", "AnimS", flags);
    }

    function PlayJointsSound(opening) {
        local tags = (opening? "Event Activate":"Event Deactivate");
        if (IsDataSet("PlayerFrob")) {
            tags += ", CreatureType Player";
        }
        Sound.HaltSchema(self);
        Sound.PlayEnvSchema(self, tags, self);
    }
}

// Not technically a door, but if we want to toggle hitboxes...
class ToggleRefs extends SqRootScript {
    function OnTurnOn() {
        SetProperty("HasRefs", true);
        SetProperty("CollisionType", 1);
    }

    function OnTurnOff() {
        SetProperty("HasRefs", false);
        SetProperty("CollisionType", 0);
    }
}

// Present as being locked when frobbed from the wrong side.
//
// Make sure this script comes *before* StdDoor (this will
// be true when the parent/archetype has SdtDoor and child/
// concrete has OneSidedDoor), as this needs to block the
// frob messages from the wrong side.
//
// This is really just for the SubPressureDoor models with
// the wheel on only one side (its -Y side).
//
class OneSidedDoor extends SqRootScript {
    function OnFrobWorldEnd() {
        local frobber = message().Frobber;
        // If the door is not closed, let it operate normally.
        local status = Door.GetDoorState(self);
        if (status!=eDoorStatus.kDoorClosed) return;
        // If the frobber is not on the door's +Y side (local space),
        // let it open normally.
        local frobberPos = Object.Position(frobber);
        local relPos = Object.WorldToObject(self, frobberPos);
        if (relPos.y<=0.0) return;
        // Now decide how to react:
        if (frobber==Object.Named("Player")) {
            // To the player, pretend we are locked.
            Sound.PlayEnvSchema(self, "Event Reject, Operation OpenDoor", self);
            BlockMessage();
        } else {
            // To an AI, make them do a little play-acting to get it open.
            // NOTE: The watch pseudoscript needs to run even at high alert,
            //       and should end with sending an Open message to the door
            //       and waiting ~1s for it to open; then the AI can resume
            //       whatever behaviour it was doing prior.
            if (HasProperty("AI_WtchPnt")) {
                if (!Link.AnyExist("AIWatchObj", frobber, self)) {
                    Link.Create("AIWatchObj", frobber, self);
                }
                BlockMessage();
            } else {
                // Let the AI cheat and open the door anyway if there is no
                // Watch Link Defaults property, otherwise they would get stuck
                // and just walk into the door frobbing it forever.
                //
                // So no BlockMessage() here.
            }
        }
    }

    function OnKnock() {
        Sound.PlayEnvSchema(self, "Event Knock", self);
    }
}
