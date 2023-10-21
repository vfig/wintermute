class TronRotaryButton extends SqRootScript {
    function OnFrobWorldEnd() {
        if (IsButtonMode()) {
            if (IsButtonPressed()) {
                TweqButton(false);
            } else {
                TweqButton(true);
                Link.BroadcastOnAllLinks(self, "ButtonPressStart", "~ScriptParams");
            }
        }

        // local currentPos = GetData("Position");
        // local newPos = Data.RandInt(0, 3);
        // DarkUI.TextMessage("Rotating from pos "+currentPos+" to pos "+newPos, 0, 2000);
        // RotateToPosition(newPos);
    }

    function OnBeginScript() {
        SetData("IsEnabled", true);
        //SetData("IsRotating", false);
        //SetRotaryPosition(0);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            local wasForward = (message().Dir==eTweqDirection.kTweqDirForward);
            print("BUTTON "+self+" OnTweqComplete: joints forward:"+wasForward);
            if (IsButtonMode()) {
                if (GetData("IsEnabled")) {
                    local msg = (wasForward? "ButtonPressed":"ButtonReleased");
                    Link.BroadcastOnAllLinks(self, msg, "~ScriptParams");
                }
            } else {
                // TODO: we stopped rotating.
            }
        }
    }

    // -- Button Mode activates linear joint 1.

    function IsButtonMode() {
        local joint = GetProperty("CfgTweqJoints", "Primary Joint");
        return (joint==1);
    }

    function SetButtonMode(buttonMode) {
        if (buttonMode) {
            SetProperty("CfgTweqJoints", "Primary Joint", 1);
        } else {
            SetProperty("CfgTweqJoints", "Primary Joint", 2);
        }
    }

    function OnReleaseButton() {
        TweqButton(false);
    }

    function IsButtonMoving() {
        print("BUTTON "+self+" IsButtonMoving?");
        local animS = GetProperty("StTweqJoints", "AnimS");
        print("BUTTON "+self+"   animS:"+animS);
        local joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        print("BUTTON "+self+"   joint1AnimS:"+joint1AnimS);
        local result = ( ((AnimS&1)!=0) && ((joint1AnimS&1)!=0) );
        print("BUTTON "+self+"   => "+result);
        return result;
    }

    function IsButtonPressed() {
        print("BUTTON "+self+" IsButtonPressed?");
        local joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        print("BUTTON "+self+"   joint1AnimS:"+joint1AnimS);
        local result = ( ((joint1AnimS&2)!=0) );
        print("BUTTON "+self+"   => "+result);
        return result;
    }

    function TweqButton(on) {
        if (on) {
            SetProperty("StTweqJoints", "Joint1AnimS", 1);
            SetProperty("StTweqJoints", "AnimS", 1);
        } else {
            SetProperty("StTweqJoints", "Joint1AnimS", 3);
            SetProperty("StTweqJoints", "AnimS", 3);
        }
    }

    function OnDisable() {
        SetData("IsEnabled", false);
        TweqButton(true);
        local frobInert = Object.Named("FrobInert");
        if (! Object.HasMetaProperty(self, frobInert)) {
            Object.AddMetaProperty(self, frobInert);
        }
    }

    function OnEnable() {
        SetData("IsEnabled", true);
        TweqButton(false);
        Object.RemoveMetaProperty(self, "FrobInert");
    }

    // -- Rotary Mode activates rotary joint 2.

    function OnRotate() {
        SetButtonMode(false);
        TweqRotary(true);
    }

    function TweqRotary(on) {
        // ObjProp "CfgTweqJoints"      // type sTweqJointsConfig         , flags 0x0000 , editor name: "Tweq: Joints"
        // {
        //     "Halt" : enum    // enums: "Destroy Obj", "Remove Prop", "Stop Tweq", "Continue", "Slay Obj"
        //     "AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "MiscC" : bitflags    // flags: "Anchor", "Scripts", "Random", "Grav", "ZeroVel", "TellAi", "PushOut", "NegativeLogic", "Relative Velocity", "NoPhysics", "AnchorVhot", "HostOnly", "CreatureScale", "Use Model 5", "LinkRel"
        //     "CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "Primary Joint" : int
        //     "Joint1AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint1CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high" : vector
        //     "Joint2AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint2CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high2" : vector
        //     "Joint3AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint3CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high3" : vector
        //     "Joint4AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint4CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high4" : vector
        //     "Joint5AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint5CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high5" : vector
        //     "Joint6AnimC" : bitflags    // flags: "NoLimit", "Sim", "Wrap", "OneBounce", "SimSmallRad", "SimLargeRad", "OffScreen"
        //     "Joint6CurveC" : bitflags    // flags: "JitterLow", "JitterHi", "Mul", "Pendulum(/BounceHi)", "Bounce"
        //     "    rate-low-high6" : vector
        // }

        // ObjProp "StTweqJoints"       // type sTweqJointsState          , flags 0x0011 , editor name: "Tweq: JointsState"
        // {
        //     "AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "MiscS" : bitflags    // flags: "Null"
        //     "Joint1AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "Joint2AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "Joint3AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "Joint4AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "Joint5AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        //     "Joint6AnimS" : bitflags    // flags: "On", "Reverse", "ReSynch", "GoEdge", "LapOne"
        // }

        if (on) {
            SetProperty("StTweqJoints", "Joint2AnimS", 1);
            SetProperty("StTweqJoints", "AnimS", 1);
        } else {
            SetProperty("StTweqJoints", "Joint2AnimS", 0);
            SetProperty("StTweqJoints", "AnimS", 0);
        }
    }

/*
    function SetRotaryPosition(pos) {
        SetData("IsRotating", false);
        SetData("Position", pos);
        local targetAngle = 45+90*pos;
        if (targetAngle>=360) {
            targetAngle -= 360;
        }
        TweqStop();
        SetProperty("Position", "Bank", (targetAngle/360.0)*65536);
    }

    function RotateToPosition(pos) {
        local active = GetData("IsRotating");
        if (active) {
            // TODO: play a 'Locked' sound?
            return false;
        }
        SetData("IsRotating", true);
        SetData("Position", pos);
        local currentAngle = Object.Facing(self).x;
        local targetAngle = 45+90*pos;
        if (targetAngle>=360) {
            targetAngle -= 360;
        }
        local speed = 20;
        if (targetAngle>currentAngle) {
            TweqRotate(speed, currentAngle, targetAngle);
        } else {
            SetData("NextPosition", pos);
            TweqRotate(speed, currentAngle, 360);
        }
        return true;
    }

        // if (message().Type==eTweqType.kTweqTypeRotate
        // && message().Op==eTweqOperation.kTweqOpHaltTweq) {
        //     SetData("IsRotating", false);
        //     if (IsDataSet("NextPosition")) {
        //         local pos = GetData("NextPosition");
        //         ClearData("NextPosition");
        //         RotateToPosition(pos);
        //     } else {
        //         // TODO: notify somebody that we are done?
        //     }
        // }

    function TweqRotate(speed, from, to) {
        SetProperty("StTweqRotate", "AnimS", 0);
        SetProperty("CfgTweqRotate", "x rate-low-high",
            vector(speed, from, to));
        SetProperty("StTweqRotate", "Axis 1AnimS", 1);
        SetProperty("StTweqRotate", "AnimS", 1);
    }

    function TweqStop() {
        SetProperty("StTweqRotate", "AnimS", 0);
    }
*/
}

class TronInterface extends SqRootScript {
    function OnBeginScript() {
        for (local i=0; i<8; i+=1) {
            SetData("Noun", -1);
            SetData("Verb", -1);
        }
    }

    function OnSim() {
        if (message().starting) {
            local links = Link.GetAll("ScriptParams", self);
            foreach (link in links) {
                local id = LinkTools.LinkGetData(link, "");
                if (id.find("Output")==0) {
                    PostMessage(LinkDest(link), "Disable");
                }
            }
        }
    }

    function OnButtonPressStart() {
        local link = Link.GetOne("ScriptParams", self, message().from);
        if (link==0) return;
        local id = LinkTools.LinkGetData(link, "");
        if (id.find("Noun")==0) {
            local index = id.slice(4).tointeger();
            print("# Noun "+index+" button press start.");
            HandleNounButtonStart(index);
        } else if (id.find("Verb")==0) {
            local index = id.slice(4).tointeger();
            print("# Verb "+index+" button press start.");
            HandleVerbButtonStart(index);
        }
    }

    function OnButtonPressed() {
        local link = Link.GetOne("ScriptParams", self, message().from);
        if (link==0) return;
        local id = LinkTools.LinkGetData(link, "");
        if (id=="Commit") {
            print("# Commit button pressed.");
            HandleCommitButtonPressed();
        } else if (id.find("Noun")==0) {
            local index = id.slice(4).tointeger();
            print("# Noun "+index+" button pressed.");
            HandleNounButtonPressed(index);
        } else if (id.find("Verb")==0) {
            local index = id.slice(4).tointeger();
            print("# Verb "+index+" button pressed.");
            HandleVerbButtonPressed(index);
        } else {
            print("# ERROR: Unknown button '"+id+"' pressed.");
        }
    }

    function OnButtonReleased() {
        local link = Link.GetOne("ScriptParams", self, message().from);
        if (link==0) return;
        local id = LinkTools.LinkGetData(link, "");
        if (id=="Commit") {
            print("# Commit button released.");
        } else if (id.find("Noun")==0) {
            local index = id.slice(4).tointeger();
            print("# Noun "+index+" button released.");
            HandleNounButtonReleased(index);
        } else if (id.find("Verb")==0) {
            local index = id.slice(4).tointeger();
            print("# Verb "+index+" button released.");
            HandleVerbButtonReleased(index);
        } else {
            print("# ERROR: Unknown button '"+id+"' released.");
        }
    }

    function ReleaseButton(id) {
        Link.BroadcastOnAllLinksData(self, "ReleaseButton", "ScriptParams", id);
    }

    function HandleNounButtonStart(index) {
        local noun = GetData("Noun");
        for (local i=0; i<8; i+=1) {
            if (i==index) continue;
            if (i==noun) SetNoun(-1);
            ReleaseButton("Noun"+i);
        }
    }

    function HandleVerbButtonStart(index) {
        local verb = GetData("Verb");
        for (local i=0; i<8; i+=1) {
            if (i==index) continue;
            if (i==verb) SetVerb(-1);
            ReleaseButton("Verb"+i);
        }
    }

    function HandleNounButtonPressed(index) {
        SetNoun(index);
    }

    function HandleNounButtonReleased(index) {
        local noun = GetData("Noun");
        if (noun==index) SetNoun(-1);
    }

    function HandleVerbButtonPressed(index) {
        SetVerb(index);
    }

    function HandleVerbButtonReleased(index) {
        local verb = GetData("Verb");
        if (verb==index) SetVerb(-1);
    }

    function SetNoun(noun) {
        SetData("Noun", noun);
        if (noun!=-1) {
            Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", "NounLight");
        } else {
            Link.BroadcastOnAllLinksData(self, "TurnOff", "ScriptParams", "NounLight");
        }
        CheckCommitReady();
    }

    function SetVerb(verb) {
        SetData("Verb", verb);
        if (verb!=-1) {
            Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", "VerbLight");
        } else {
            Link.BroadcastOnAllLinksData(self, "TurnOff", "ScriptParams", "VerbLight");
        }
        CheckCommitReady();
    }

    function CheckCommitReady() {
        local noun = GetData("Noun");
        local verb = GetData("Verb");
        if (noun!=-1 && verb!=-1) {
            Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", "CommitLight");
        } else {
            Link.BroadcastOnAllLinksData(self, "TurnOff", "ScriptParams", "CommitLight");
        }
    }

    function HandleCommitButtonPressed() {
        ReleaseButton("Commit");
        local noun = GetData("Noun");
        local verb = GetData("Verb");
        if (noun!=-1 && verb!=-1) {
            // Disable all the buttons, and start the outputs rotating.
            PostMessage(message().from, "Disable");
            local links = Link.GetAll("ScriptParams", self);
            foreach (link in links) {
                local id = LinkTools.LinkGetData(link, "");
                if ( (id.find("Noun")==0)
                || (id.find("Verb")==0) ) {
                    PostMessage(LinkDest(link), "Disable");
                } else if (id.find("Output")==0) {
                    PostMessage(LinkDest(link), "Rotate");
                }
            }
            // Turn on the output light and rotate the outputs
            Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", "OutputLight");
        } else {
            // TODO: Buzz angrily!
        }
    }
}

class ScrollSlot extends SqRootScript {
    function Log(msg) {
        print(Object.GetName(self)+" ("+self+"): "+msg);
    }

    function LogMessage() {
        Log(message().message+" from "+Object.GetName(message().from)+" ("+message().from+")");
    }

    function OnWorldSelect() {
        LogMessage();
        MakeToolScrolls(true);
    }

    function OnWorldDeSelect() {
        LogMessage();
        MakeToolScrolls(false);
    }

    function OnEnable() {
        LogMessage();
        SetFrobEnabled(true);
    }

    function OnDisable() {
        LogMessage();
        SetFrobEnabled(false);
    }

    function OnTakeItem() {
        LogMessage();
        local from = message().from;
        local scroll = message().data;
        local target = GetTarget();
        // If the sender already contains the scroll, that means they are asking
        // us to take over and spit it out.
        local isIngest = !Link.AnyExist("Contains", from, scroll);
        // Don't accept if we already have a scroll, or we are locked,
        // or we are currently in motion, or the message data was bogus,
        // or (if ingesting) we don't have a target.
        if (Link.AnyExist("Contains", self)
        || Locked.IsLocked(self)
        || IsActive()
        || (scroll==null || scroll==0)
        || (isIngest && target==0)) {
            Log("Refusing to take item: "+scroll);
            Sound.PlayEnvSchema(self, "Event Reject", self);
            Reply(false);
            return;
        }
        // Take the scroll...
        Container.Add(scroll, self);
        SetActive(true);
        SetFrobEnabled(false);
        if (isIngest) {
            // ...and begin the ingestion animation.
            ResetJoints(1);
            AnimateJoints(1);
            Sound.PlayEnvSchema(self, "Event Activate", self);
        } else {
            // ...and begin the expulsion animation.
            ResetJoints(0);
            AnimateJoints(0);
            Sound.PlayEnvSchema(self, "Event Deactivate", self);
        }
        Reply(true);
    }

    function OnTweqComplete() {
        LogMessage();
        if (message().Type==eTweqType.kTweqTypeJoints) {
            local wasIngesting = (message().Dir==eTweqDirection.kTweqDirReverse);
            local link = Link.GetOne("Contains", self);
            if (! link) {
                // We don't have a scroll?
                Log("Weird. TweqComplete but we don't have a scroll.");
                return;
            }
            local scroll = LinkDest(link);
            local target = GetTarget();
            if (wasIngesting && !target) {
                // We don't have a target?!
                Log("Weird. TweqComplete but we don't have a target.");
                return;
            }
            if (wasIngesting) {
                // Pass the item over to our target, if it is willing.
                local didAccept = SendMessage(target, "TakeItem", scroll);
                // Double check if the item was actually removed from us,
                // as a naive OnTakeItem() method might forget to Reply().
                local stillContains = Link.AnyExist("Contains", self, scroll);
                if (didAccept && stillContains) {
                    didAccept = false;
                } else if (!didAccept && !stillContains) {
                    didAccept = true;
                }
                if (didAccept) {
                    // Ready for more.
                    SetActive(false);
                    SetFrobEnabled(true);
                    ResetJoints(0);
                } else {
                    // Send this scroll back out.
                    ResetJoints(0);
                    AnimateJoints(0);
                    Sound.PlayEnvSchema(self, "Event Deactivate", self);
                }
            } else {
                // Uncontain the scroll again.
                local range = GetProperty("CfgTweqJoints", "    rate-low-high");
                // Hardcoded position/facing tweaks for unrolled scroll:
                local offset = vector(0,-0.125,range.z);
                local facing = vector(90,0,0);
                Object.Teleport(scroll, offset, facing, self);
                Container.Remove(scroll, self);
                SetActive(false);
                SetFrobEnabled(true);
                ResetJoints(0);
            }
        }
    }

    function GetTarget() {
        local link = Link.GetOne("ControlDevice", self);
        return (link? LinkDest(link) : 0);
    }

    function MakeToolScrolls(toolEnable) {
        if (toolEnable) {
            Object.AddMetaPropertyToMany("M-ToolScroll", "@Scroll");
        } else {
            Object.RemoveMetaPropertyFromMany("M-ToolScroll", "@Scroll");
        }
    }

    function SetFrobEnabled(enabled) {
        if (enabled) {
            Object.RemoveMetaProperty(self, "FrobInert");
        } else {
            // NOTE: We won't get the WorldDeSelect message when we become
            //       FrobInert, so we manually disable tool scrolls now.
            MakeToolScrolls(false);
            if (! Object.HasMetaProperty(self, "FrobInert")) {
                Object.AddMetaProperty(self, "FrobInert");
            }
        }
    }

    function IsActive() {
        if (IsDataSet("Active"))
            return GetData("Active");
        else
            return false;
    }

    function SetActive(active) {
        SetData("Active", active);
    }

    function ResetJoints(position) {
        local range = GetProperty("CfgTweqJoints", "    rate-low-high");
        if (position>0) {
            SetProperty("JointPos", "Joint 1", range.z);
        } else {
            SetProperty("JointPos", "Joint 1", range.y);
        }
        SetProperty("StTweqJoints", "AnimS", 0);
    }

    function AnimateJoints(fromPosition) {
        if (fromPosition>0) {
            SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
        } else {
            SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
        }
    }
}

class ToolScroll extends SqRootScript {
    function OnMessage() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" from "+Object.GetName(message().from)+" ("+message().from+")");
    }

    function OnFrobToolBegin() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" Src:"+Object.GetName(message().SrcObjId)+" ("+message().SrcObjId+")"
            +" Dst:"+Object.GetName(message().DstObjId)+" ("+message().DstObjId+")");
    }

    function OnFrobToolEnd() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" Src:"+Object.GetName(message().SrcObjId)+" ("+message().SrcObjId+")"
            +" Dst:"+Object.GetName(message().DstObjId)+" ("+message().DstObjId+")");
        SendMessage(message().DstObjId, "TakeItem", self);
    }
}

