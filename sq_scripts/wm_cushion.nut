/*
    Stim-based approach doesnt work for small radiuses, because the
    player body will not receive the stim before the feet hit the floor!

    Although radius 4 seems to work okay, and is not too big to attach
    to mudlumps?

    a landing sound gets tags:
        Event Footstep,Landing true

    for temporary i have these tags on M-Cushioned:
        CreatureType Player,Fungus true

    but if we want to have mud (Fungus true tag, because of the prox: fungus stuff)
    separate from plants (SpringGreen arrow fired into earth patches), then
    we want something different on M-Cushioned, so we can have undergrowth
    noises on landing?
*/

class CushionStimResponse extends SqRootScript {
    ExpireAfter = 0.1

    function OnBeginScript() {
        if (! IsDataSet("LastStim")) SetData("LastStim", 0.0);
        if (! IsDataSet("ExpiryActive")) SetData("ExpiryActive", 0);
    }

    function OnCushionStimStimulus() {
        if (! Object.HasMetaProperty(self, "M-Cushioned")) {
            print("++ add cushioned");
            Object.AddMetaProperty(self, "M-Cushioned");
        }
        SetData("LastStim", GetTime());
        local isActive = GetData("ExpiryActive");
        if (! isActive) {
            SetData("ExpiryActive", 1);
            PostMessage(self, "CushionExpiry");
        }
    }

    function OnCushionExpiry() {
        local now = GetTime();
        local lastStim = GetData("LastStim");
        if ((now-lastStim)>=ExpireAfter) {
            print("-- remove cushioned");
            Object.RemoveMetaProperty(self, "M-Cushioned");
            SetData("ExpiryActive", 0);
        } else {
            PostMessage(self, "CushionExpiry");
        }
    }
}
