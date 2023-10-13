class ZeroGStimResponse extends SqRootScript {
    function OnBeginScript() {
        SetData("Expiry", 0.0);
        SetData("ExpiryActive", false);
    }

    function OnZeroGStimStimulus() {
        local intensity = message().intensity;
        local source = LinkDest(message().source)
        local stimRad = 16.0;
        local zeroGRad = 6.0;
        local threshold = 100.0*(1.0-(zeroGRad/stimRad));
        local gravity = 100.0;
        local friction = 1.0;
        if (intensity>=threshold) {
            gravity = 0.0;
            friction = 0.2;
            Property.Set(self, "PhysAttr", "Gravity %", gravity);
            Property.Set(self, "PhysAttr", "Base Friction", friction);
            // Start the expiry timer if it is not running.
            local isTimerActive = GetData("ExpiryActive");
            if (! isTimerActive) {
                SetData("ExpiryActive", true);
                SetOneShotTimer("ZeroGExpiry", 0.3);
            }
            local now = GetTime();
            local expiry = now+0.5;
            SetData("Expiry", expiry);
        }
    }

    function OnTimer() {
        if (message().name=="ZeroGExpiry") {
            local now = GetTime();
            local expiry = GetData("Expiry");
            if (now>=expiry) {
                Property.Set(self, "PhysAttr", "Gravity %", 100.0);
                Property.Set(self, "PhysAttr", "Base Friction", 0.0);
                SetData("ExpiryActive", false);
            } else {            
                SetOneShotTimer("ZeroGExpiry", 0.3);
            }
        }
    }
}
