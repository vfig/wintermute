/*

Okay, this is kinda working. its a bit weird. issues:

  - the AIWatchLink reaction should happen _before_ the TimeWarp gets applied.
    (also it probably needs to have the rerun delay turned off maybe? or we
    figure out a different way to do the reaction only when the tangle begins?)
    this probably means we have one metaprop for "Tangled state" and one for
    "Tangled slowdown".

  - the M-VineTangled metaprop right now just expires itself after a few
    seconds; instead it should reset its expiry timer whenever the stim comes
    in.

  - also need to explore creating the vine details and giving them scale tweqs
    and detailattaching them to the guard's feet.

  - further work (a separate effect): VineStun (maybe rip choking sounds from
    thief 3?). only for direct hits on a guard from the vine arrow (or perhaps
    if they are in a radius of the vine hit).

*/

class VineTangleable extends SqRootScript {
    // // BUG: why do we need to subscribe to the stimulus when theres
    // //      a receptron with Send to Scripts?
    // function OnBeginScript() {
    //     ActReact.SubscribeToStimulus(self, "VineTangle");
    // }

    // function OnEndScript() {
    //     ActReact.UnsubscribeToStimulus(self, "VineTangle");
    // }

    function OnVineTangleStimulus() {
        print(self+" stim:"+message().message);
        if (! Object.HasMetaProperty(self, "M-VineTangled")) {
            Object.AddMetaProperty(self, "M-VineTangled");
        }
    }

    // Debug which meta props we have (in the case of stim adding/removing them)

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("DumpMetaprops", 1.0);
        }
    }

    function OnTimer() {
        if (message().name=="DumpMetaprops") {
            DumpMetaprops();
            SetOneShotTimer("DumpMetaprops", 1.0);
        }
    }

    function DumpMetaprops() {
        print("MetaProps:");
        local links = Link.GetAll("MetaProp", self);
        foreach (link in links) {
            local metaprop = LinkDest(link);
            local name = Object.GetName(metaprop);
            local flags = LinkTools.LinkGetData(link, "");
            print("  "+name+" flags:"+flags);
        }
    }

    // Debug message

    function OnMessage() {
        print(self+" "+message().message+" from:"+message().from);
    }
}

class VineTangled extends SqRootScript {
    function OnBeginScript() {
        print(self+" BEGIN tangled.");
        SetOneShotTimer("VineTangledExpiry", 3.0);
    }

    function OnEndScript() {
        print(self+" END tangled.");
    }

    function OnTimer() {
        if (message().name=="VineTangledExpiry") {
            Object.RemoveMetaProperty(self, "M-VineTangled");
        }
    }
}

class VineTangler extends SqRootScript {
    // The physics one has problems because we get *two*
    // enter messages for the same object-and-submodel, followed by
    // two exit messages. so tracking "who is in here" reliably is
    // really terrible!
    //
    // So instead we use a radius source, and have the metaprop
    // self-remove with a timer to end things.
    /*
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnEndScript() {
        print(self+" END VineTangler");
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnPhysEnter() {
        print(self+" "+message().message
            +" obj:"+message().transObj
            +" submod:"+message().transSubmod);

        // Just in case we get multiples of this message, we don't
        // want to in any sense have more than one A/R contact...
        ActReact.EndContact(self, message().transObj);
        ActReact.BeginContact(self, message().transObj);
    }

    function OnPhysExit() {
        print(self+" "+message().message
            +" obj:"+message().transObj
            +" submod:"+message().transSubmod);
        ActReact.EndContact(self, message().transObj);
    }
    */
}


// The T1/G WatchMe script doesnt exist in T2! so here is a copy.
class WatchMe extends SqRootScript {
    function OnBeginScript() {
        if(! IsDataSet("Init")) {
            Link.CreateMany("AIWatchObj", "@Human", self);
            SetData("Init", true);
        }
    }
}
