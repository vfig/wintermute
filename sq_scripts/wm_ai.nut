enum eFrobObjectFlags {
    kArmsLength = 0x0001,
    kLineOfSight = 0x0002,
    kTurnOn = 0x0004,
    kTurnOff = 0x0008,
}

class FrontDeskPerson extends SqRootScript {
    function OnAlertness() {
        if (message().level>message().oldLevel
        && message().level>=2) {
            // Interrupt any 'GoTo' action we might be doing
            AI.ClearGoals(self);
            // Drop anything in our hands.
            DropAltContained();
        }
    }

    function GetAltContained() {
        foreach (link in Link.GetAll("Contains", self)) {
            local type = LinkTools.LinkGetData(link, "");
            if (type==eDarkContainType.kContainTypeAlt) {
                return LinkDest(link);
            }
        }
    }

    function DropAltContained() {
        local obj = GetAltContained();
        if (obj==0) return;
        print("dropping "+obj);
        Link.DestroyMany("Contains", self, obj);
        Object.RemoveMetaProperty(self, "FrobInert");
        local arch = Object.Archetype(obj);
        if (Property.Possessed(arch, "PhysType")) {
            Property.Add(obj, "PhysType");
        }
    }

    function OnPatrolPoint() {
        local trol = message().patrolObj;
        SendMessage(trol, "PatrolPointReached");
    }

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

    function OnIfRandom_() {
        if (IsBusy()) {
            print("... busy.");
            Reply(false);
            return;
        }
        local chance = message().data
        if (chance==null) {
            chance = 50;
        } else {
            chance = chance.tointeger();
        }
        print("Do I roll < "+chance+"?")
        local roll = Data.RandInt(0, 99);
        if (roll<chance) {
            print("... yes.");
            Reply(true);
            return;
        } else {
            print("... no.");
            Reply(false);
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
        Link.DestroyMany("Contains", 0, obj);
        Object.Teleport(obj, vector(), vector(), self);
        Physics.ControlCurrentPosition(obj);
        Object.RemoveMetaProperty(obj, "FrobInert");
    }
}

class TrigPatrol extends SqRootScript {
    function OnPatrolPointReached() {
        if (Locked.IsLocked(self)) return;
        local msg = "TurnOn";
        if (HasProperty("TrapFlags")) {
            local flags = GetProperty("TrapFlags");
            if (flags&TRAPF_INVERT) {
                msg = "TurnOff";
            }
            if (flags&TRAPF_ONCE) {
                Property.SetSimple(self, "Locked", true);
            }
        }
        Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
    }
}
