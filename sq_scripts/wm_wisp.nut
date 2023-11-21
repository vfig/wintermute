// BUG: after doing a few of these, hitting weird issues like:
//      - Wisper getting a Destroy message (as seen in monolog) but not
//        actually being destroyed
//      - Wisper particles not being spawned
//
// generally, object weirdness! is my destroying of Owns a problem? or
// is the Stim-destroyed object a problem? idk..., but i am not happy
// about these outcomes AT ALL.

class WispVulnLight extends SqAnimLight {
    function OnWispStimStimulus() {
        print(self+" is Wisped for "+message().intensity+" at "+GetTime());
        if (IsWisped()) {
            local timer = GetData("WispedTimer");
            KillTimer(timer);
        } else {
            SetData("Wisped", true);
            SetData("WispWantsOn", IsLightOn());
        }
        // TODO: use stimulus intensity as time??
        local timer = SetOneShotTimer("Unwisp", 1.1);
        SetData("WispedTimer", timer);
        ChangeMode(false);
    }

    function OnTimer() {
        if (message().name=="Unwisp") {
            print(self+" Unwisping at "+GetTime());
            local wantsOn = GetData("WispWantsOn");
            ClearData("WispedTimer");
            ClearData("Wisped");
            ClearData("WispWantsOn");
            if (wantsOn) {
                TurnOn();
            }
        }
        base.OnTimer();
    }

    function IsWisped() {
        if (IsDataSet("Wisped"))
            return GetData("Wisped");
        return false;
    }

    function TurnOn() {
        if (IsWisped())
            SetData("WispWantsOn", true);
        else
            base.TurnOn();
    }

    function TurnOff() {
        if (IsWisped())
            SetData("WispWantsOn", false);
        else
            base.TurnOff();
    }
}

class WispedLight extends SqRootScript {
/*
    function OnBeginScript() {
        print("WispedLight "+self+": "+message().message);
        local mode = Light.GetMode(self);
        local isOn = !(mode==ANIM_LIGHT_MODE_MINIMUM
            || mode==ANIM_LIGHT_MODE_EXTINGUISH
            || mode==ANIM_LIGHT_MODE_SMOOTH_DIM);
        SetData("IsOn", isOn);
        SetData("LightMode", mode);
    }

    function GetOffMode(mode) {
        switch (mode) {
            case ANIM_LIGHT_MODE_MAXIMUM: return ANIM_LIGHT_MODE_MINIMUM;
            case ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN: return ANIM_LIGHT_MODE_SMOOTH_DIM;
            default: return ANIM_LIGHT_MODE_EXTINGUISH;
        }
    }

    function OnWispStimStimulus() {
        print("WispedLight "+self+": "+message().message
            +" intensity:"+message().intensity);
    }

    function OnTurnOn() {
        SetData("IsOn", true);
        BlockMessage();
    }

    function OnTurnOff() {
        SetData("IsOn", false);
        BlockMessage();
    }

    function OnEndScript() {
        print("WispedLight "+self+": "+message().message);

        SetData("LightMode", mode);
    }
*/
}

class Wisper extends SqRootScript {
    /* Stims don't actually tell you what object the stim is from (when the
       source is on an archetype). But we need to know in order to set up our
       particle effects. So we have the WispStim-vulnerable objects Poke back
       at the source (the Wisper), using the same stimulus and themselves as
       agent. This results in a 0-intensity Damage message on the Wisper,
       which has the WispStim-vulnerable object as the culprit; so we can get
       the object's location.
    */
    function OnDamage() {
        local stim = Object.Named("WispStim");
        if (stim==0) return;
        if (message().kind!=stim) return;
        local target = message().culprit;
        if (!Link.AnyExist("Population", self, target)) {
            Link.Create("Population", self, target);
            print("Wisper "+self+" hit vulnerable target "+target);
            SpawnParticles(self, target);
        }
    }

    function SpawnParticles(fromObj, toObj) {
        local fromPos = Object.Position(fromObj);
        local toPos = Object.Position(toObj);
        local middle = (fromPos+toPos)*0.5;
        if (1) {
            // TEMP: create markers
            local marker = Object.BeginCreate("Marker");
            Object.Teleport(marker, fromPos, vector(), 0);
            Property.SetSimple(marker, "RenderType", 2);
            Property.SetSimple(marker, "Scale", vector(0.25,0.25,0.25));
            Object.EndCreate(marker);
            Link.Create("Owns", self, marker);
            marker = Object.BeginCreate("Marker");
            Object.Teleport(marker, toPos, vector(), 0);
            Property.SetSimple(marker, "RenderType", 2);
            Property.SetSimple(marker, "Scale", vector(0.25,0.25,0.25));
            Object.EndCreate(marker);
            Link.Create("Owns", self, marker);
            // marker = Object.BeginCreate("Marker");
            // Object.Teleport(marker, middle, vector(), 0);
            // Property.SetSimple(marker, "RenderType", 2);
            // Property.SetSimple(marker, "Scale", vector(0.25,0.25,0.25));
            // Object.EndCreate(marker);
            // Link.Create("Owns", self, marker);
        }
        local delta = (middle-toPos);
        // delta.x = fabs(delta.x);
        // delta.y = fabs(delta.y);
        // delta.z = fabs(delta.z);
        local dist = 2.0*delta.Length();
        local speed = 4.0;
        local vel = delta.GetNormalized()*speed;
        local time = dist/speed;
        local boxMin = -delta - vector(0.1,0.1,0.1);
        local boxMax = -delta + vector(0.1,0.1,0.1);
        // Spawn the particles
        local part = Object.BeginCreate("WispSuckage");
        Object.Teleport(part, middle, vector(), 0);
        Property.Set(part, "PGLaunchInfo", "Box Min", boxMin);
        Property.Set(part, "PGLaunchInfo", "Box Max", boxMax);
        Property.Set(part, "PGLaunchInfo", "Velocity Min", vel);
        Property.Set(part, "PGLaunchInfo", "Velocity Max", vel);
        Property.Set(part, "PGLaunchInfo", "Min time", time);
        Property.Set(part, "PGLaunchInfo", "Max time", time);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
        return part;
    }

    function OnSlain() {
        print(self+" is slain. woe!");
    }

    function OnDestroy() {
        print(self+" is destroyed. woo!");
        foreach (link in Link.GetAll("Owns", self)) {
            Damage.Slay(LinkDest(link), self);
        }
    }
}
