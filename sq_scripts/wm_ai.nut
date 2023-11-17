enum eFrobObjectFlags {
    kArmsLength = 0x0001,
    kLineOfSight = 0x0002,
    kTurnOn = 0x0004,
    kTurnOff = 0x0008,
}

class FrontDeskPerson extends SqRootScript {
    // function OnPatrolPoint() {
    //     local trol = message().patrolObj;
    //     // if (Property.Possessed(trol, "AI_WtchPnt")
    //     // && !Link.AnyExist("AIWatchObj", self, trol)) {
    //     //     Link.Create("AIWatchObj", self, trol);
    //     // }
    //     if (Property.Possessed(trol, "AI_Converation")) {
    //         if (!Link.AnyExist("AIConversationActor", trol)) {
    //             print("Created link.");
    //             local link = Link.Create("AIConversationActor", trol, self);
    //             LinkTools.LinkSetData(link, "Actor ID", 1);
    //         }
    //         local ok = AI.StartConversation(trol);
    //         print("Conversation result: "+ok);
    //     }
    // }

    // If we are 'busy', all inquiry messages return false to cancel their
    // pseudoscripts until later. Prevents overlap e.g. immediately returning
    // the broom after picking it up.
    function SetBusy(duration_ms) {
        print("Busy for the next "+duration_ms+"ms");
        local expiry = GetTime()+(duration_ms/1000.0);
        SetData("BusyUntil", expiry);
    }

    function IsBusy() {
        if (! IsDataSet("BusyUntil")) return false;
        local expiry = GetData("BusyUntil");
        return (GetTime()<expiry);
    }

    function OnBusy() {
        local duration = message().data;
        if (duration==null) duration = 5000;
        duration = duration.tointeger();
        SetBusy(duration);
    }

    function OnIfSearching_() {
        if (IsBusy()) {
            print("... busy.");
            Reply(false);
            return;
        }
        print("Am I searching?")
        if (Link.AnyExist("AIInvest", self)) {
            print("... yes.");
            Reply(true);
            return;
        } else {
            print("... no.");
            Reply(false);
            return;
        }
    }

    function OnIfNotSearching_() {
        if (IsBusy()) {
            print("... busy.");
            Reply(false);
            return;
        }
        print("Am I *not* searching?")
        if (Link.AnyExist("AIInvest", self)) {
            print("... no.");
            Reply(false);
            return;
        } else {
            print("... yes.");
            Reply(true);
            return;
        }
    }

    function OnIfIHave_() {
        if (IsBusy()) {
            print("... busy.");
            Reply(false);
            return;
        }
        local obj = Object.Named(message().data)
        print("Do I have "+obj+"?")
        if (obj==0) {
            print("... no.");
            Reply(false);
            return;
        } else if (Link.AnyExist("Contains", self, obj)) {
            print("... yes.");
            Reply(true);
            return;
        } else {
            print("... no.");
            Reply(false);
            return;
        }
    }

    function OnIfIDontHave_() {
        if (IsBusy()) {
            print("... busy.");
            Reply(false);
            return;
        }
        local obj = Object.Named(message().data)
        print("Do I *not* have "+obj+"?")
        if (obj==0) {
            print("... yes.");
            Reply(true);
            return;
        } else if (Link.AnyExist("Contains", self, obj)) {
            print("... no.");
            Reply(false);
            return;
        } else {
            print("... yes.");
            Reply(true);
            return;
        }
    }

    function OnGoTo() {
        local obj = Object.Named(message().data)
        print("GoTo "+obj+"...")
        if (obj==0) {
            print("... invalid.");
            Reply(false);
            return;
        } else {
            local speed = eAIScriptSpeed.kNormalSpeed;
            local speedParam = message().data2
            if (speedParam!=null) {
                speedParam = speedParam.tostring().tolower();
                if (speedParam=="fast"|| speedParam=="very fast") {
                    speed = eAIScriptSpeed.kFast;
                }
            }
            local ok = AI.MakeGotoObjLoc(self, obj, speed, eAIActionPriority.kNormalPriorityAction);
            if (ok) {
                print("... ok.");
                SetBusy(5000);
                Reply(true);
                return;
            } else {
                print("... failed.");
                Reply(false);
                return;
            }
        }
    }

    function ParseFrobObjectFlags(text) {
        if (text==null) return 0;
        local flags = 0;
        local start = 0;
        local at = 0;
        local len = text.len();
        while (at<len) {
            local c = text.slice(at, at+1);
            // Skip whitespace and commas
            if (c==" "||c==",") {
                at += 1;
                continue;
            }
            start = at;
            at += 1;
            while (at<len) {
                // Stop at whitespace and commas
                c = text.slice(at, at+1);
                if (c==" "||c==",") {
                    break;
                }
                at += 1;
            }
            local s = text.slice(start, at);
            s = s.tolower();
            if (s=="armslength") {
                flags = flags|eFrobObjectFlags.kArmsLength;
            } else if (s=="lineofsight") {
                flags = flags|eFrobObjectFlags.kLineOfSight;
            } else if (s=="turnon") {
                flags = flags|eFrobObjectFlags.kTurnOn;
            } else if (s=="turnoff") {
                flags = flags|eFrobObjectFlags.kTurnOff;
            } else {
                print("Warning: "+self+" FrobObject: unknown flag '"+s+"'");
            }
        }
        return flags;
    }

    function OnFrobObject() {
        local obj = Object.Named(message().data)
        print("FrobObject "+obj+"...")
        if (obj==0) {
            print("... invalid.");
            return;
        } else {
            local flags = ParseFrobObjectFlags(message().data2);
            print("... with flags "+flags);
            if (flags&eFrobObjectFlags.kArmsLength) {
                local dist = (Object.Position(self)-Object.Position(obj)).Length();
                if (dist>6.0) {
                    print("... not within arm's length.");
                    return;
                }
            }
            if (flags&eFrobObjectFlags.kLineOfSight) {
                local loc = vector();
                local hit = Engine.PortalRaycast(Object.Position(self), Object.Position(obj), loc);
                if (hit) {
                    print("... no line of sight.");
                    return;
                }
            }
            if (flags&eFrobObjectFlags.kTurnOn) {
                SendMessage(obj, "TurnOn");
            } else if (flags&eFrobObjectFlags.kTurnOff) {
                SendMessage(obj, "TurnOff");
            } else {
                // TODO - does this break the pseudoscript? do we need to instead
                //        fake a frob message??? idk???????
                AI.MakeFrobObj(self, obj);
            }
        }
    }
}

class PickUpBroom extends SqRootScript {
    function OnPickUp() {
        print("PickUpBroom: PickUp");
        if (! Link.AnyExist("~Contains", self)) {
            local actor = message().from;
            Container.Add(self, actor, eDarkContainType.kContainTypeAlt, CTF_NONE);
            Object.AddMetaProperty(self, "FrobInert");
        }
    }
}

class ReturnBroom extends SqRootScript {
    function OnReturn() {
        local obj = Object.Named(message().data)
        print("ReturnBroom: Return "+obj);
        if (obj==0) {
            print("... invalid.");
            return;
        }
        Object.Teleport(obj, vector(), vector(), self);
        Link.DestroyMany("Contains", 0, obj);
        Object.RemoveMetaProperty(self, "FrobInert");
    }
}
