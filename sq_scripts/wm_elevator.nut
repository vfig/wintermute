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
