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

class ScrollSlotIngest extends SqRootScript {
    function IsActive() {
        if (IsDataSet("Active"))
            return GetData("Active");
        else
            return false;
    }

    function SetActive(active) {
        local isActive = IsActive();
        if (active!=isActive) {
            SetData("Active", active);
            local range = GetProperty("CfgTweqJoints", "    rate-low-high");
            if (active) {
                // Turn on.
                print("Turn On");
                SetProperty("JointPos", "Joint 1", range.z);
                SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
                OnDisable();
            } else {
                // Turn off.
                print("Turn Off");
                SetProperty("StTweqJoints", "AnimS", 0);
                SetProperty("JointPos", "Joint 1", range.y);
                OnEnable();
            }
        }
    }

    function MakeToolScrolls(toolEnable) {
        if (toolEnable) {
            Object.AddMetaPropertyToMany("M-ToolScroll", "@Scroll");
        } else {
            Object.RemoveMetaPropertyFromMany("M-ToolScroll", "@Scroll");
        }
    }

    function OnWorldSelect() {
        print(Object.GetName(self)+" ("+self+"): "+message().message);
        MakeToolScrolls(true);
    }

    function OnWorldDeSelect() {
        print(Object.GetName(self)+" ("+self+"): "+message().message);
        MakeToolScrolls(false);
    }

    function OnEnable() {
        print(Object.GetName(self)+" ("+self+"): "+message().message+" at "+GetTime());
        Object.RemoveMetaProperty(self, "FrobInert");
    }

    function OnDisable() {
        print(Object.GetName(self)+" ("+self+"): "+message().message+" at "+GetTime());
        // NOTE: We won't get the WorldDeSelect message when we become
        //       FrobInert, so we manually disable tool scrolls now.
        MakeToolScrolls(false);
        if (! Object.HasMetaProperty(self, "FrobInert")) {
            Object.AddMetaProperty(self, "FrobInert");
        }
    }

    function OnScrollFrob() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" from "+Object.GetName(message().from)+" ("+message().from+")");
        if (! IsActive()) {
            local scroll = message().from;
            Container.Remove(scroll);
            Container.Add(scroll, self);
            SetActive(true);
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints) {
            SetActive(false);
            local link = Link.GetOne("ControlDevice", self);
            if (link) {
                local expulsor = LinkDest(link);
                Container.MoveAllContents(self, expulsor);
                SendMessage(expulsor, "TurnOn");
            }
        }
    }

    function OnMessage() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" from "+Object.GetName(message().from)+" ("+message().from+")");
    }
}

class ScrollSlotExpulse extends SqRootScript {
    function IsActive() {
        if (IsDataSet("Active"))
            return GetData("Active");
        else
            return false;
    }

    function SetActive(active) {
        local isActive = IsActive();
        if (active!=isActive) {
            SetData("Active", active);
            local range = GetProperty("CfgTweqJoints", "    rate-low-high");
            if (active) {
                // Turn on.
                EnableControllers(false);
                SetProperty("JointPos", "Joint 1", range.y);
                SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
                print("EXPULSING");
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            } else {
                // Turn off.
                EnableControllers(true);
                SetProperty("StTweqJoints", "AnimS", 0);
                SetProperty("JointPos", "Joint 1", range.y);
                print("EXPULSE COMPLETE. Should be setting joint 1 to "+range.y);
                Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
            }
        }
    }

    function EnableControllers(enable) {
        local msg = (enable? "Enable" : "Disable");
        local link = Link.GetOne("~ControlDevice", self);
        if (link) {
            local ingestor = LinkDest(link);
            SendMessage(ingestor, msg);
        }
    }

    function OnTurnOn() {
        // TODO: we have a race condition where the player could feed multiple
        //       objects in while we are still pumping one out! those objects
        //       might then get lost?
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" from "+Object.GetName(message().from)+" ("+message().from+")");
        if (! IsActive()) {
            SetActive(true);
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints) {
            SetActive(false);
            // Expulse all objects
            local objects = [];
            foreach (link in Link.GetAll("Contains", self)) {
                objects.append(LinkDest(link));
            }
            local range = GetProperty("CfgTweqJoints", "    rate-low-high");
            local offset = vector(0,-0.125,range.z);
            local facing = vector(90,0,0); // Hardcoded for unrolled scroll.
            foreach (obj in objects) {
                Object.Teleport(obj, offset, facing, self);
                Container.Remove(obj, self);
                SendMessage(obj, "Transmogrify");
            }
        }
    }

    function OnMessage() {
        print(Object.GetName(self)+" ("+self+"): "+message().message
            +" from "+Object.GetName(message().from)+" ("+message().from+")");
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
        SendMessage(message().DstObjId, "ScrollFrob");
    }
}

