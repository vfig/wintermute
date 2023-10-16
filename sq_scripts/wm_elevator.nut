// Fancy Elevator Controller
// -------------------------
//
// Controls an elevator with multiple floors and integrated doors/gates.
//
// Setup:
//
// 1. Add a fnord, and give it the ElevatorController script. This
//    is the controller.
// 2. CD link from the controller to the elevator. Add the "ControlledElevator"
//    script to the elevator.
// 3. CD link each call button to the controller. Add the "Schema>Message"
//    property to the button, with the floor number
//    that it calls the elevator to.
// 4. CD link from the controller to each TerrPt. Add the "Schema>Message"
//    property to the TerrPt, with the floor number that this TerrPt is at.
// 5. CD link from the controller to each door. Add the "Schema>Message"
//    property to the door, with the floor number that this door is at.
//
// Floor numbers can start at 0, or at 1, it is up to you.
//
// Note that the button at a given floor that sends the elevator up
// or down should have "Schema: Message" set to the floor number it
// will send the elevator to, NOT the floor number the button is at.
//
// Note also that you must NOT create CD links to individual TerrPts, as with
// the stock elevators; instead, all the links go to or from the
// ElevatorController, so that it can coordinate all the behaviour.
//
class ElevatorController extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            SetupInitialFloor();
        }
    }

    function LogError(text) {
        print("ERROR: ElevatorController "+self+": "+text);
    }

    function Log(text) {
        print("# ElevatorController "+self+": "+text);
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

    function OnElevatorAtWaypoint() {
        Log(message().message+" from "+message().from);
        // Find out what floor we arrived at.
        local waypt = message().data;
        local floor = Property.Get(waypt, "SchMsg").tointeger();
        Log("arrived at floor "+floor);
        SetData("ElevatorController.Floor", floor);
        // Open the doors at this floor.
        DoDoors(floor, true);
    }
}

// Path Elevator Controller
// -------------------------
//
// Controls a multi-stop variable-speed bidirectional elevator (horizontal
// or vertical).
//
// Setup:
//
// 1. Create the "forward" chain of points, of TerrPt or PathPt objects
//    (see note below). For best results, the points should be pretty evenly
//    spaced along the entire path. Link each point to the next with a TPath
//    link; you do not need to set the Speed or other fields of the link. Add
//    one more dummy point at the end of the chain, in order that the last real
//    point also has an outgoing TPath link. It is important that you do NOT
//    link the points in a loop, as you would for a stock elevator.
//
// 2. On the points where the elevator should stop, add the "Schema>Message"
//    property with the stop number; stops must be numbered starting from
//    1 nearest the start of the forward chain and increasing along the chain.
//
// 3. Create the "reverse" chain of points, by duplicating all the points from
//    the forward chain. Link each point to the one before it with a TPath link,
//    so that the reverse chain links go in the opposite direction from the
//    forward chain links. Add one more dummy point at the end of the chain,
//    in order that the last real point also has an outgoing TPath link.
//
// 4. On the reverse points where the elevator should stop, add the
//    "Schema>Message" property with the NEGATIVE stop number.
//
// 5. Sanity check: you should have points set up similar to this diagram:
//
//    Forward:       o -> o -> o -> o -> o -> o -> o -> o
//    'Message'      1              2              3
//
//    Reverse:  o <- o <- o <- o <- o <- o <- o <- o
//    'Message'     -1             -2             -3
//
// 6. Add a fnord, and give it the PathElevatorController script. This
//    is the controller.
// 7. CD link from the controller to the elevator. Add the "ControlledElevator"
//    script to the elevator.
// 8. CD link each call button to the controller. Add the "Schema>Message"
//    property to the button, with the stop number that it calls the elevator
//    to. This stop number should always be positive.
// 9. CD link from the controller to each point on both the forward and reverse
//    chains where the elevator should stop. These are the same points that you
//    added the "Schema>Message" property to in steps 2 and 4.
// 10. XXXXXXX TODO: CD link from the controller to each door. Add the "Schema>Message"
//    property to the door, with the floor number that this door is at.
//
// Note that while you can use TerrPt for the path points, this script
// does not depend on their StdTerrpoint script. In my mission, I created a
// separate PathPt archetype (child of Marker) with no scripts that I used
// for the path; this script will work with either TerrPt or PathPt objects.
//
// Note also that you must NOT create CD links to individual path points, as
// with the stock elevators; instead, all the links go to or from the
// PathElevatorController, so that it can coordinate all the behaviour.
//

class PathElevatorController extends SqRootScript {
    function OnSim() {
        if (message().starting) {
            Setup();
        }
    }

    function LogError(text) {
        print("ERROR: PathElevatorController "+self+": "+text);
    }

    function Log(text) {
        print("## PathElevatorController "+self+": "+text);
    }

    function Setup() {
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
        local initPt = LinkDest(link);
        local stopPoints = GetStopPoints();
        local atStop = 0;
        foreach (id, pt in stopPoints) {
            if (pt==initPt) {
                atStop = abs(id);
                break;
            }
        }
        if (atStop==0) {
            LogError("Cannot identify elevator's starting stop.");
            return;
        }
        Log("starting at stop "+atStop);
        SetData("PathElevatorController.Stop", atStop);
        SetData("PathElevatorController.Dest", 0);
        DoDoors(0, false);
        DoDoors(atStop, true);
        DoGizmos(0, false);
        DoGizmos(atStop, true);
    }

    function GetElevator() {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (ObjIsElevator(obj)) {
                return obj;
            }
        }
        return 0;
    }

    function GetStopPointId(obj) {
        if (! Property.Possessed(obj, "SchMsg")) return 0;
        return Property.Get(obj, "SchMsg").tointeger();
    }

    function GetStopPoints() {
        local stopPoints = {};
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local pt = LinkDest(link);
            if (ObjIsPathPt(pt)) {
                local id = GetStopPointId(pt);
                if (id==0) continue;
                stopPoints[id] <- pt;
            }
        }
        return stopPoints;
    }

    function ObjIsElevator(obj) {
        return (Object.InheritsFrom(obj, "Lift")
            || Property.Possessed(obj, "MovingTerrain"));
    }

    function ObjIsPathPt(obj) {
        return (Object.InheritsFrom(obj, "TerrPt")
            || Object.InheritsFrom(obj, "PathPt"));
    }

    function ObjIsDoor(obj) {
        return (Object.InheritsFrom(obj, "Door")
            || Property.Possessed(obj, "RotDoor")
            || Property.Possessed(obj, "TransDoor"));
    }

    function ObjIsGizmo(obj) {
        return (! ObjIsElevator(obj)
            && ! ObjIsPathPt(obj)
            && ! ObjIsDoor(obj));
    }

    function DoDoors(atStop, open) {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (ObjIsDoor(obj)) {
                local stop = Property.Get(obj, "SchMsg").tointeger();
                if (atStop==0 || atStop==stop) {
                    Log((open? "opening":"closing")+" door "+obj);
                    SendMessage(obj, (open? "Open":"Close"));
                }
            }
        }
    }

    function DoGizmos(atStop, turnOn) {
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local obj = LinkDest(link);
            if (ObjIsGizmo(obj)) {
                local stop = Property.Get(obj, "SchMsg").tointeger();
                if (atStop==0 || atStop==stop) {
                    Log((turnOn? "turning on":"turning off")+" gizmo "+obj);
                    SendMessage(obj, (turnOn? "TurnOn":"TurnOff"));
                }
            }
        }
    }

    function OnTurnOn() {
        local elevator = GetElevator();
        if (elevator==0) {
            LogError("Cannot find elevator.");
            return;
        }
        // Abort if we are in motion already.
        local isMoving = Property.Get(elevator, "MovingTerrain", "Active");
        if (isMoving) {
            Log("Elevator is in motion; ignoring summons.");
            return;
        }
        // TODO: check the saved "at stop", and abort if it is zero (we may not
        //       be in motion, but we plan to be, waiting for doors or something).
        // TODO: better: abort if we are in motion and have passed one
        //       waypoint already (so the player can "change their mind")
        //       about the button they press?
        Log(message().message+" from "+message().from);
        // Find out what stop we should go to.
        local button = message().from;
        local toStop = Property.Get(button, "SchMsg").tointeger();
        if (toStop<=0) {
            Log("Warning: call button "+button+" has negative stop. You ought to fix this.");
            toStop = abs(toStop);
        }
        // See if we want to go there.
        local atStop = abs(GetData("PathElevatorController.Stop"));
        print("...at "+atStop+" to "+toStop);
        if (toStop==atStop) {
            Log("already at stop "+toStop);
            return;
        }
        // Okay, go there.
        Log("summon to stop "+toStop);
        local stopPoints = GetStopPoints();
        // Check if we need the reverse path.
        if (toStop<atStop) {
            toStop = -toStop;
            atStop = -atStop;
            print("...reverse path: at "+atStop+" to "+toStop);
        }
        local atStopPt = stopPoints[atStop];
        local toStopPt = stopPoints[toStop];
        // Fix up the elevator's path links, so it is on the correct path.
        local link = Link.GetOne("TPath", atStopPt);
        if (link==0) {
            LogError("Stop point "+atStopPt+" has no outgoing TPath");
            return;
        }
        local nextStopPt = LinkDest(link);
        local link = Link.GetOne("TPathNext", elevator);
        if (link) Link.Destroy(link);
        Link.Create("TPathNext", elevator, nextStopPt);
        print("... created TPathNext link to "+nextStopPt);
        // TODO: do we need to finagle the TPathInit links too?
        //       - seems like no? but maybe save/load affects it?
        // link = Link.GetOne("TPathInit", elevator);
        // if (link) Link.Destroy(link);
        // Link.Create("TPathInit", elevator, atStopPt);
        // print("... created TPathInit link to "+atStopPt);

        // Set the speeds of all the links along the path, so we get the
        // acceleration and deceleration that we want.
        local links = [];
        local pt = atStopPt;
        while (pt!=toStopPt) {
            link = Link.GetOne("TPath", pt);
            if (link==0) {
                LogError("Failed to find path from "+atStopPt+" to "+toStopPt);
                return;
            }
            links.append(link);
            pt = LinkDest(link);
        }
        local minSpeed = 3.0;
        local maxSpeed = 20.0;
        local speedIncrement = 2.0;
        local count = links.len();
        local mid = count>>1;
        print("count = "+count+", mid = "+mid);
        local speed = minSpeed;
        for (local i=0; i<=mid; i++) {
            local j = count-i-1;
            speed += speedIncrement;
            if (speed>maxSpeed) speed = maxSpeed;
            if (i==mid && (count&1)==0) break;
            // Set accelerating link
            link = links[i];
            LinkTools.LinkSetData(link, "Speed", speed);
            LinkTools.LinkSetData(link, "Pause (ms)", 0);
            LinkTools.LinkSetData(link, "Path Limit?", false);
            print("**** set link "+i+" speed to "+speed);
            if (i==mid) break;
            // Set decelerating link
            link = links[j];
            LinkTools.LinkSetData(link, "Speed", speed);
            LinkTools.LinkSetData(link, "Pause (ms)", 0);
            LinkTools.LinkSetData(link, "Path Limit?", false);
            print("**** set link "+j+" speed to "+speed);
        }
        // The destination point needs to stop the elevator entirely.
        link = Link.GetOne("TPath", toStopPt);
        if (link==0) {
            LogError("No outgoing TPath link from "+toStopPt);
            return;
        }
        LinkTools.LinkSetData(link, "Speed", 0.0);
        LinkTools.LinkSetData(link, "Pause (ms)", 0);
        LinkTools.LinkSetData(link, "Path Limit?", true);
        // Start going.
        SetData("PathElevatorController.Stop", 0);
        SetData("PathElevatorController.Dest", toStop);
        Property.Set(elevator, "MovingTerrain" ,"Active", true);
        // And close all the doors.
        DoDoors(0, false);
        DoGizmos(0, false);
    }

    function OnElevatorAtWaypoint() {
        Log(message().message+" from "+message().from);
        local elevator = GetElevator();
        if (elevator==0) {
            LogError("Cannot find elevator.");
            return;
        }
        local waypt = message().data;
        // TODO: Set our rotate tweq to turn towards the direction
        // of movement? (FaceWaypoint doesnt work, it can only rotate in one direction)

        // Find out if we arrived at a stop.
        local stop = GetStopPointId(waypt);
        if (stop==0) {
            // Boring intermediate point.
            return;
        }
        // Is this our destination stop?
        local toStop = GetData("PathElevatorController.Dest");
        if (stop==toStop) {
            Log("arrived at stop "+stop);
            SetData("PathElevatorController.Stop", stop);
            SetData("PathElevatorController.Dest", 0);
            Property.Set(elevator, "MovingTerrain", "Active", false);
            // Open the doors at this floor.
            DoDoors(abs(stop), true);
            DoGizmos(abs(stop), true);
        } else {
            Log("passing stop "+stop);
        }
    }
}

// Support script for ElevatorController and PathElevatorController.
class ControlledElevator extends SqRootScript {
    function OnMovingTerrainWaypoint() {
        local waypt = message().waypoint;
        local targets = [];
        local links = Link.GetAll("~ControlDevice", self);
        foreach (link in links) {
            targets.append(LinkDest(link));
        }
        foreach (obj in targets) {
            SendMessage(obj, "ElevatorAtWaypoint", waypt);
        }
    }
}
