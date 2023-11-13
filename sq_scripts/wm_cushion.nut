class CushionStimResponse extends SqRootScript {
    ExpireAfter = 0.1

    function OnBeginScript() {
        if (! IsDataSet("LastStim")) SetData("LastStim", 0.0);
        if (! IsDataSet("ExpiryActive")) SetData("ExpiryActive", 0);
        if (! IsDataSet("Cushioned")) SetData("Cushioned", 0);
    }

    function OnCushionStimStimulus() {
        local now = GetTime();
        local lastStim = GetData("LastStim");
        if (now==lastStim) return;
        SetData("LastStim", now);
        // Add the appropriate metaprop according to velocity.
        local vel = vector();
        Physics.GetVelocity(self, vel);
        local isBig = (vel.z<=-30.0); // Big fall (would normally cause fall damage)
        local cushioned = GetData("Cushioned");
        if (isBig && cushioned!=2) {
            SetData("Cushioned", 2);
            if (! Object.HasMetaProperty(self, "M-CushionedBig")) {
                Object.AddMetaProperty(self, "M-CushionedBig");
            }
            if (Object.HasMetaProperty(self, "M-Cushioned")) {
                Object.RemoveMetaProperty(self, "M-Cushioned");
            }
        } else if (!isBig && cushioned!=1) {
            SetData("Cushioned", 1);
            if (! Object.HasMetaProperty(self, "M-Cushioned")) {
                Object.AddMetaProperty(self, "M-Cushioned");
            }
            if (Object.HasMetaProperty(self, "M-CushionedBig")) {
                Object.RemoveMetaProperty(self, "M-CushionedBig");
            }
        }
        // Start the expiry check (if its not running).
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
            SetData("Cushioned", 0);
            Object.RemoveMetaProperty(self, "M-Cushioned");
            Object.RemoveMetaProperty(self, "M-CushionedBig");
            SetData("ExpiryActive", 0);
        } else {
            PostMessage(self, "CushionExpiry");
        }
    }
}
