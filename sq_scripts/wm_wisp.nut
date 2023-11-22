// BUG: after doing a few of these, hitting weird issues like:
//      - Wisper getting a Destroy message (as seen in monolog) but not
//        actually being destroyed
//      - Wisper particles not being spawned
//
// generally, object weirdness! is my destroying of Owns a problem? or
// is the Stim-destroyed object a problem? idk..., but i am not happy
// about these outcomes AT ALL.

// CAUSES:
//
// Wisper not self-destructing seems to happen when it doesnt hit any lights
// (or maybe when it hits a light that is already wisped??)
//
// Particles not spawning seems to happen when wisping a light a subsequent
// time (only works the first time?)

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
    function OnBeginScript() {
        print("Wisper "+self+" begins.");
        // NOTE: I don't understand why, but if I call SpawnCoreParticles()
        //       here and now, we get a stack overflow? So we defer it for
        //       one frame.
        PostMessage(self, "SpawnParticles");
    }

    function OnEndScript() {
        print("Wisper "+self+" ends.");
    }

    function OnSpawnParticles() {
        // TODO: Really we should spawn a different effect if we did not
        //       find any devices to draw energy from: a small, sad wisp
        //       that fades away fairly rapidly?
        SpawnCoreParticles();
    }

    /* Stims don't actually tell you what object the stim is from (when the
       source is on an archetype). But we need to know in order to set up our
       particle effects. So we have the WispStim-vulnerable objects Poke back
       at the source (the Wisper), using the same stimulus and themselves as
       agent. This results in a 0-intensity Damage message on the Wisper,
       which has the WispStim-vulnerable object as the culprit; so we can get
       the object's location.
    */
    function OnDamage() {
        print("Wisper "+self+" Damage kind:"+message().kind+" damage:"+message().damage+" by:"+message().culprit);
        local stim = Object.Named("WispStim");
        if (stim==0) return;
        if (message().kind!=stim) return;
        local target = message().culprit;
        if (! Link.AnyExist("Population", self, target)) {
            Link.Create("Population", self, target);
            print("Wisper "+self+" hit vulnerable target "+target);
            SpawnParticles(self, target);
        }
    }

    function SpawnCoreParticles() {
        // Core
        local part = Object.BeginCreate("WisperCore");
        if (part==0) { print("Create Particles failed!"); }
        Object.Teleport(part, vector(), vector(), self);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
        // Glow
        part = Object.BeginCreate("WisperGlow");
        if (part==0) { print("Create Particles failed!"); }
        Object.Teleport(part, vector(), vector(), self);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
    }

    function SpawnParticles(fromObj, toObj) {
        local fromPos = Object.Position(fromObj);
        local toPos = Object.Position(toObj);
        local middle = (fromPos+toPos)*0.5;
        if (1) {
            // TEMP: create markers
            local marker = Object.BeginCreate("Marker");
            if (marker==0) { print("Create Marker1 failed!"); }
            Object.Teleport(marker, fromPos, vector(), 0);
            Property.SetSimple(marker, "RenderType", 2);
            Property.SetSimple(marker, "Scale", vector(0.25,0.25,0.25));
            Object.EndCreate(marker);
            Link.Create("Owns", self, marker);
            marker = Object.BeginCreate("Marker");
            if (marker==0) { print("Create Marker2 failed!"); }
            Object.Teleport(marker, toPos, vector(), 0);
            Property.SetSimple(marker, "RenderType", 2);
            Property.SetSimple(marker, "Scale", vector(0.25,0.25,0.25));
            Object.EndCreate(marker);
            Link.Create("Owns", self, marker);
        }
        local delta = (middle-toPos);
        local dist = 2.0*delta.Length();
        local speed = 4.0;
        local vel = delta.GetNormalized()*speed;
        local time = dist/speed;
        local boxMin = -delta - vector(0.1,0.1,0.1);
        local boxMax = -delta + vector(0.1,0.1,0.1);
        // Spawn the particles
        local part = Object.BeginCreate("WispSuckage");
        if (part==0) { print("Create Particles failed!"); }
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

    function CleanupOwned(destroy) {
        local objs = [];
        foreach (link in Link.GetAll("Owns", self)) {
            objs.append(LinkDest(link));
        }
        foreach (obj in objs) {
            if (destroy) {
                Object.Destroy(obj);
            } else {
                Damage.Slay(obj, self);
            }
        }
        Link.DestroyMany("Owns", self, 0);
    }

    function OnSlain() {
        print("Wisper "+self+" is slain. woe!");
        //CleanupOwned(false);
    }

    function OnDestroy() {
        print("Wisper "+self+" is destroyed. woo!");
        CleanupOwned(true);
    }
}

class WisperCore extends SqRootScript {
    function Grow() {
        local t = (GetTime() - GetData("Start"));
        local maxTime = GetData("MaxTime");
        if (t>maxTime) t = maxTime;
        local color;
        local color0 = GetData("Color0");
        local color1 = GetData("Color1");
        local color2 = GetData("Color2");
        local fade = GetData("FadeTime");
        if (t<fade) {
            local k = (t/fade);
            color = color0*(1.0-k)+color1*k;
        } else if (t<(2.0*fade)) {
            local k = ((t-fade)/fade);
            color = color1*(1.0-k)+color2*k;
        } else {
            color = color2;
        }
        local k = t/maxTime;
        local size0 = GetData("Size0");
        local size1 = GetData("Size1");
        local size = size0*(1.0-k)+size1*k;
        local radius0 = GetData("Radius0");
        local radius1 = GetData("Radius1");
        local radius = radius0*(1.0-k)+radius1*k;
        local pulseTime0 = GetData("PulseTime0");
        local pulseTime1 = GetData("PulseTime1");
        local pulseTime = pulseTime0*(1.0-k)+pulseTime1*k;
        SetProperty("ParticleGroup", "size of particle", size);
        SetProperty("ParticleGroup", "fixed-group radius", radius);
        SetProperty("ParticleGroup", "pulse cycle time ms", pulseTime.tointeger());
        SetProperty("ParticleGroup", "bm-disk rgb", ToColorString(color));
        return true;
    }

    function GrowAndRepeat() {
        local ok = Grow();
        if (ok) {
            local timer = SetOneShotTimer("WisperGrow", 0.5);
            SetData("Timer", timer);
        }
    }

    function ParseColorString(s) {
        local color = vector(0,0,0);
        local sep0 = s.find(",");
        if (sep0==null) return color;
        local sep1 = s.find(",", sep0+1);
        if (sep1==null) return color;
        color.x = s.slice(0, sep0).tointeger();
        color.y = s.slice(sep0+1, sep1).tointeger();
        color.z = s.slice(sep1+1).tointeger();
        return color;
    }

    function ToColorString(color) {
        return (""
            +(color.x).tointeger()+","
            +(color.y).tointeger()+","
            +(color.z).tointeger());
    }

    function OnBeginScript() {
        // NOTE: when just spawned, the script property can get initialized
        //       before the particle properties have been inherited. So we
        //       wait one frame before kicking off.
        PostMessage(self, "BeginParticles");
    }

    function OnBeginParticles() {
        SetData("Start", GetTime());
        SetData("Color0", ParseColorString(GetProperty("ParticleGroup", "bm-disk rgb")));
        SetData("Color1", ParseColorString(GetProperty("ParticleGroup", "bm-disk 2nd rgb")));
        SetData("Color2", ParseColorString(GetProperty("ParticleGroup", "bm-disk 3rd rgb")));
        // We abuse the Particle Launch Info property for these other parameters, because
        // as we are not using a Launched particle type, the particle system ignores them.
        local boxMin = GetProperty("PGLaunchInfo", "Box Min");
        local boxMax = GetProperty("PGLaunchInfo", "Box Max");
        SetData("Size0", boxMin.x);
        SetData("Size1", boxMax.x);
        SetData("Radius0", boxMin.y);
        SetData("Radius1", boxMax.y);
        SetData("PulseTime0", boxMin.z);
        SetData("PulseTime1", boxMax.z);
        SetData("MaxTime", GetProperty("PGLaunchInfo", "Max time")/1000.0);
        SetData("FadeTime", GetProperty("ParticleGroup", "particle fade time")/65536.0);
        GrowAndRepeat();
    }

    function OnTimer() {
        GrowAndRepeat();
    }

    function OnEndScript() {
        local timer = GetData("Timer");
        if (timer) KillTimer(timer);
    }
}
