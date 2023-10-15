// Fancy Elevator Controller
// -------------------------
//
// Setup:
//
// 1. Add a fnord, and give it the ElevatorController script. This
//    is the controller.
// 1. For each call button, CD link from it to the controller.
// 2. CD link from the controller to each TerrPt.
// 3. CD link from the controller to each door.
// 4. CD link from the controller to the elevator.
// 5. On each call button, door, and TerrPt, add the "Schema: Message"
//    property, with its value being the floor number.
// 6. Put the ElevatorReporter script on the elevator.
//
// Floor numbers can start at 0, or at 1, it is up to you.
//
// Note that the button at a given floor that sends the elevator up
// or down should have "Schema: Message" set to the floor number it
// will send the elevator to, NOT the floor number the button is at.
//
class ElevatorController extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetupReporters();
            SetupInitialFloor();
        }
    }

    function LogError(text) {
        print("ERROR: ElevatorController "+self+": "+text);
    }

    function Log(text) {
        print("# ElevatorController "+self+": "+text);
    }

    function SetupReporters() {
        local metaName = "M-ElevatorReporter";
        local meta = Object.Named(metaName);
        if (meta==0) {
            LogError("Cannot find "+metaName+" metaclass.");
            return;
        }
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (! Object.HasMetaProperty(obj, meta)) {
                if (Object.InheritsFrom(obj, "TerrPt")
                || Object.InheritsFrom(obj, "Lift")) {
                    Object.AddMetaProperty(obj, meta);
                }
            }
        }
    }

    function SetupInitialFloor() {
        local elevator = GetElevator();
        if (elevator==0) {
            LogError("Cannot find elevator.");
            return;
        }
        Log("found elevator "+elevator);
        local link = Link.GetOne("TPathInit", elevator);
        if (link==0) {
            LogError("Cannot find elevator's TPathInit.");
            return;
        }
        local waypt = LinkDest(link);
        local floor = Property.Get(waypt, "SchMsg").tointeger();
        SetData("ElevatorController.Floor", floor);
        Log("starting at floor "+floor);
    }

    function GetElevator() {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (Object.InheritsFrom(obj, "Lift")) {
                return obj;
            }
        }
        return 0;
    }

    function DoDoors(atFloor, open) {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (Object.InheritsFrom(obj, "Door")
            || Property.Possessed(obj, "RotDoor")
            || Property.Possessed(obj, "TransDoor")) {
                local floor = Property.Get(obj, "SchMsg").tointeger();
                if (atFloor==-1 || atFloor==floor) {
                    Log((open? "opening":"closing")+" door "+obj);
                    SendMessage(obj, (open? "Open":"Close"));
                }
            }
        }
    }

    function CallElevator(toFloor) {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (Object.InheritsFrom(obj, "TerrPt")) {
                local floor = Property.Get(obj, "SchMsg").tointeger();
                if (toFloor==floor) {
                    Log("calling elevator to TerrPt "+obj);
                    SendMessage(obj, "TurnOn");
                    return;
                }
            }
        }
    }

    function OnTurnOn() {
        Log(message().message+" from "+message().from);
        // Find out what floor we should go to.
        local button = message().from;
        local floor = Property.Get(button, "SchMsg").tointeger();
        // See if we want to go there.
        local atFloor = GetData("ElevatorController.Floor");
        if (floor==atFloor) {
            Log("already at floor "+floor);
            return;
        }
        // Okay, go there.
        Log("summon to floor "+floor);
        SetData("ElevatorController.Floor", -1);
        CallElevator(floor);
        // And close all the doors.
        DoDoors(-1, false);
    }

    function OnWaypointReached() {
        Log(message().message+" from "+message().from);
        // Find out what floor we arrived at.
        local waypt = message().from;
        local floor = Property.Get(waypt, "SchMsg").tointeger();
        Log("arrived at floor "+floor);
        SetData("ElevatorController.Floor", floor);
        // Open the doors at this floor.
        DoDoors(floor, true);
    }
}

class ElevatorReporter extends SqRootScript {
    function OnWaypointReached() {
        Link.BroadcastOnAllLinks(self, "WaypointReached", "~ControlDevice");
    }
}

class PathPoint extends SqRootScript {
    function OnTurnOn() {
        Log(message().message);
        local elevator = FindElevator();
        if (elevator) {
            SendMessage(elevator, "Call");
        }
    }

    function FindElevator() {
        // Trace alternately forward and backward to find the nearest elevator.
        local forwardPt = self;
        local reversePt = self;
        local link = 0;
        local safety = 0;
        while (forwardPt && reversePt) {
            if (forwardPt) {
                link = Link.GetOne("~TPathNext", forwardPt);
                if (link) break;
                link = Link.GetOne("~TPathInit", forwardPt);
                if (link) break;
                forwardPt = LinkDest(Link.GetOne("TPath", forwardPt));
            }
            if (reversePt) {
                link = Link.GetOne("~TPathNext", reversePt);
                if (link) break;
                link = Link.GetOne("~TPathInit", reversePt);
                if (link) break;
                reversePt = LinkDest(Link.GetOne("~TPath", reversePt));
            }
            safety++;
            if (safety>1000) {
                Log("SAFETY DANCE");
                return 0;
            }
        }
        if (link) {
            local elevator = LinkDest(link);
            Log("found Elevator "+elevator);
            return elevator;
        }
        Log("found no elevator.");
        return 0;
    }

    function Log(message) {
        print("PathPoint "+self+": "+message);
        Debug.Log("PathElevator "+self+": "+message);
    }
}

class Cthelevator extends SqRootScript {
    m_path = null;

    function OnSim() {
        Log(message().message);
        if (message().starting) {
            InitElevator();
        }
    }

    function OnDarkGameModeChange() {
        Log(message().message);
        if (message().resuming) {
            // TODO: do we need to start moving again?
        } else if (message().suspending) {
            // Do nothing
        } else {
            // Neither suspending nor resuming? Do we need to do anything?
        }
    }

    function OnMovingTerrainWaypoint() {
        Log(message().message);
        local waypoint = message().waypoint;
    }

    function OnMessage() {
        Log(message().message);
    }

    // TODO: we are gonna need a custom TerrPt script, that will search both
    //       directions along the TPath links to find the elevator to call.
    function OnCall() {
        Log(message().message);
        local dest = message().from;
        local at = AtPoint();
        Log("at "+at);
        local result = FindPathToPoint(at, dest);
        if (result==null) {
            LogError("Cannot find path to point "+dest)
        } else {
            local forward = result[0];
            local path = result[1];
            Log("path to point "+dest+":")
            for (local i=0; i<path.len(); i++) {
                local pt = path[i];
                Log("  "+pt+" "+Object.Position(pt));
            }
            // TODO: deal with the cases:
            //   1. dest==at, and we are nearby
            //   2. dest==at, but we are some distance from it (might not be forward!)
            //   3. other edge cases?
            SetDestPoint(dest);
            SetForward(forward);
            SetMoving(true);
            UpdateElevator(true);
        }
    }

    function InitElevator() {
        // Find the point we begin at.
        local link = Link.GetOne("TPathInit", self);
        if (! link) {
            LogError("has no TPathInit link and will not run.");
            Object.Destroy(self);
            return;
        }
        local pt = LinkDest(link);
        SetAtPoint(pt);
        SetForward(true);
        SetMoving(false);
    }

    function UpdateElevator(resetNext) {
        local forward = IsForward();
        local at = AtPoint();
        local dest = DestPoint();
        local next = 0;
        if (resetNext) {
            if (forward) {
                next = LinkDest(Link.GetOne("TPath", at));
            } else {
                next = LinkDest(Link.GetOne("~TPath", at));
            }
            local link = Link.GetOne("TPathNext", self);
            if (link) Link.Destroy(link);
            if (next) Link.Create("TPathNext", self, next);
        } else {
            next = LinkDest(Link.GetOne("TPathNext", self));
        }
        // If there is no next point, something has gone wrong, and we
        // should stop.
        if (! next) {
            local zero = vector();
            Physics.ControlVelocity(self, zero);
            Physics.SetVelocity(self, zero);
            SetMoving(false);
            LogError("has no TPathNext link. Stopping.");
            return;
        }
        // Are we at the next point yet?
        local pos = Object.Position(self);
        local nextPos = Object.Position(next);
        local dist = (nextPos-pos).Length();
        // TODO: figure out how far we will move in the next elevator tick
        //       (i am thinking like 1/4 sec) and if we expect to hit the
        //       next point or not. 
        if (dist<0.5) {
            // We are basically here.
            // TODO: handle moving down the chain
            local zero = vector();
            Physics.ControlVelocity(self, zero);
            Physics.SetVelocity(self, zero);
            SetMoving(false);
            Log("TODO: handle moving down the chain");
            return;
        } else {
            local dir = (nextPos-pos).GetNormalized();
            local speed = 5.0; // TODO: handle speed
            local vel = dir*speed;
            Physics.ControlVelocity(self, vel);
            // TODO: face the direction too.
        }
        // TODO: set a timer to update again.
        // UpdateElevator();
    }

    function AtPointLink() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local value = LinkTools.LinkGetData(link, "");
            if (value=="PathElevAt") {
                return link;
            }
        }
    }

    function DestPointLink() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local value = LinkTools.LinkGetData(link, "");
            if (value=="PathElevDest") {
                return link;
            }
        }
    }

    function SetAtPoint(pt) {
        local link = AtPointLink();
        if (link) Link.Destroy(link);
        link = Link.Create("ScriptParams", self, pt);
        LinkTools.LinkSetData(link, "", "PathElevAt");
    }

    function SetDestPoint(pt) {
        local link = DestPointLink();
        if (link) Link.Destroy(link);
        link = Link.Create("ScriptParams", self, pt);
        LinkTools.LinkSetData(link, "", "PathElevDest");
    }

    function AtPoint() {
        return LinkDest(AtPointLink());
    }

    function DestPoint() {
        return LinkDest(DestPointLink());
    }

    function IsMoving() {
        return GetData("Moving");
    }

    function IsForward() {
        return GetData("Forward");
    }

    function SetMoving(moving) {
        SetData("Moving", (moving==true));
    }

    function SetForward(forward) {
        SetData("Forward", (forward==true));
    }


    function FindPathToPoint(start, dest) {
        if (! start || ! dest) return null;
        local path = [];
        // Trace forward from the start to try to find the dest.
        local pt = start;
        local link = 0;
        local found = false;
        while (true) {
            path.append(pt);
            if (pt==dest) {
                found = true;
                break;
            }
            link = Link.GetOne("TPath", pt);
            if (link==0) break;
            if (LinkDest(link)==start) break;
            pt = LinkDest(link);
        }
        if (found) {
            Log("found Forward path from "+start+" to "+dest);
            return [true, path];
        }
        // Not trace backward from the start, maybe the dest is that way.
        path = [];
        pt = start;
        found = false;
        while (true) {
            path.append(pt);
            if (pt==dest) {
                found = true;
                break;
            }
            link = Link.GetOne("~TPath", pt);
            if (link==0) break;
            if (LinkDest(link)==start) break;
            pt = LinkDest(link);
        }
        if (found) {
            Log("found Reverse path from "+start+" to "+dest);
            return [false, path];
        }
        Log("found no path from "+start+" to "+dest);
        return null;
    }

    function Log(message) {
        print("PathElevator "+self+": "+message);
        Debug.Log("PathElevator "+self+": "+message);
    }

    function LogError(message) {
        print("ERROR: PathElevator "+self+": "+message);
        Debug.Log("ERROR: PathElevator "+self+": "+message);
    }
}
