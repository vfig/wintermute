// TODO:
//
// - sad wisp with no devices (+sound)
// - adjust wisp range
// - make lights fade out? in? (more awkward state management if so)
//       though flickering back on would be nice, if i can wrangle it?
// - update all the light archetypes it should work with
// - any other devices it should work with?
//       turrets!
// - LIGHTNING

class WispVulnCamera extends SqRootScript {
    function IsTurnedOn() {
        return (! Object.HasMetaProperty(self, "M-AI-Stasis"));
    }

    function OnWisp() {
        // Increment the stack count.
        local stackCount = 0;
        if (IsDataSet("Wisped")) {
            stackCount = GetData("Wisped");
        }
        stackCount++;
        SetData("Wisped", stackCount);
        // Become wisped when stack count hits one.
        if (stackCount==1) {
            SetData("WispWantsOn", IsTurnedOn());
            SendMessage(self, "TurnOff");
            Sound.PlayEnvSchema(self, "Event Deactivate", self, message().from, eEnvSoundLoc.kEnvSoundOnObj);
        }
    }

    function OnUnwisp() {
        // Decrement the stack count.
        local stackCount = 0;
        if (IsDataSet("Wisped")) {
            stackCount = GetData("Wisped");
        }
        stackCount--;
        SetData("Wisped", stackCount);
        // Become unwisped when stack count hits zero.
        if (stackCount<=0) {
            local wantsOn = GetData("WispWantsOn");
            ClearData("Wisped");
            ClearData("WispWantsOn");
            if (wantsOn) {
                SendMessage(self, "TurnOn");
                Sound.PlayEnvSchema(self, "Event Activate", self, message().from, eEnvSoundLoc.kEnvSoundOnObj);
            }
        }
    }

    function OnTurnOn() {
        if (IsDataSet("Wisped")) {
            SetData("WispWantsOn", true);
            BlockMessage();
        }
    }

    function TurnOff() {
        if (IsDataSet("Wisped")) {
            SetData("WispWantsOn", false);
            BlockMessage();
        }
    }
}

class WispVulnLight extends SqAnimLight {
    function OnWisp() {
        // Increment the stack count.
        local stackCount = 0;
        if (IsDataSet("Wisped")) {
            stackCount = GetData("Wisped");
        }
        stackCount++;
        SetData("Wisped", stackCount);
        // Become wisped when stack count hits one.
        if (stackCount==1) {
            SetData("WispWantsOn", IsLightOn());
            ChangeMode(false);
        }
    }

    function OnUnwisp() {
        // Decrement the stack count.
        local stackCount = 0;
        if (IsDataSet("Wisped")) {
            stackCount = GetData("Wisped");
        }
        stackCount--;
        SetData("Wisped", stackCount);
        // Become unwisped when stack count hits zero.
        if (stackCount<=0) {
            local wantsOn = GetData("WispWantsOn");
            ClearData("Wisped");
            ClearData("WispWantsOn");
            if (wantsOn) {
                TurnOn();
            }
        }
    }

    function TurnOn() {
        if (IsDataSet("Wisped"))
            SetData("WispWantsOn", true);
        else
            base.TurnOn();
    }

    function TurnOff() {
        if (IsDataSet("Wisped"))
            SetData("WispWantsOn", false);
        else
            base.TurnOff();
    }
}

class Wisper extends SqRootScript {
    function OnBeginScript() {
        // NOTE: It is not safe to spawn new objects (such as our core
        //       particles) here; it results in this method being invoked
        //       again, causing a stack overflow. My guess is that a
        //       BeginCreate/EndCreate frame for this object is still open,
        //       and there is some state mixup happening if we try to create
        //       another object within that frame. So we use a PostMessage()
        //       to defer the core particles creation.
        // NOTE: This deferred spawn has a side benefit: the poke-back Damage
        //       happens before our posted message, so by the time we are
        //       ready, we know whether we found any devices to affect.
        PostMessage(self, "WisperReady");
    }

    /* Stims don't actually tell you what object the stim is from (when the
       source is on an archetype). But we need to know in order to set up our
       particle effects. So we have the WispStim-vulnerable objects Poke back
       at the source (the Wisper), using the same stimulus and themselves as
       agent. This results in a 0-intensity Damage message on the Wisper,
       which has the WispStim-vulnerable object as the culprit; so we can get
       the object's location.

       And so we also use this to keep track of this wispable device, so we
       can wisp and (later) unwisp it.
    */
    function OnDamage() {
        local stim = Object.Named("WispStim");
        if (stim==0) return;
        if (message().kind!=stim) return;
        local target = message().culprit;
        if (! Link.AnyExist("Population", self, target)) {
            Link.Create("Population", self, target);
        }
    }

    function OnWisperReady() {
        print("Wisper "+self+" "+message().message+" at "+GetTime());
        if (Link.AnyExist("Population", self)) {
            SpawnCoreParticles();
            Link.BroadcastOnAllLinks(self, "Wisp", "Population");
            foreach (link in Link.GetAll("Population", self)) {
                SpawnSuckParticles(LinkDest(link), self);
            }
        } else {
            print("...but it had nothing to draw power from :(");
            // TODO: Spawn a a small, sad wisp that fades away fairly rapidly?
        }
    }

    function SpawnCoreParticles() {
        local pos = Object.Position(self);
        // Core
        local part = Object.BeginCreate("WisperCore");
        Object.Teleport(part, pos, vector(), 0);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
        // Glow
        part = Object.BeginCreate("WisperGlow");
        Object.Teleport(part, pos, vector(), 0);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
    }

    function SpawnSuckParticles(fromObj, toObj) {
        local fromPos = Object.Position(fromObj);
        local toPos = Object.Position(toObj);
        local middle = (fromPos+toPos)*0.5;
        if (0) {
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
        }
        local delta = (middle-fromPos);
        local dist = 2.0*delta.Length();
        local speed = 8.0;
        local vel = delta.GetNormalized()*speed;
        local time = dist/speed;
        local boxMin = -delta - vector(0.1,0.1,0.1);
        local boxMax = -delta + vector(0.1,0.1,0.1);
        // Spawn the suckage particles
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
        // And the suckage glow particles
        local part = Object.BeginCreate("WispSuckageGlow");
        Object.Teleport(part, middle, vector(), 0);
        Property.Set(part, "PGLaunchInfo", "Box Min", boxMin);
        Property.Set(part, "PGLaunchInfo", "Box Max", boxMax);
        Property.Set(part, "PGLaunchInfo", "Velocity Min", vel);
        Property.Set(part, "PGLaunchInfo", "Velocity Max", vel);
        Property.Set(part, "PGLaunchInfo", "Min time", time);
        Property.Set(part, "PGLaunchInfo", "Max time", time);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
        // And the source particles
        local part = Object.BeginCreate("WispSuckageSource");
        Object.Teleport(part, fromPos, vector(), 0);
        Object.EndCreate(part);
        Link.Create("Owns", self, part);
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
        // NOTE: We are slain only by water, in which case we want our
        //       existing particles to stop immediately: so we Destroy them.
        CleanupOwned(true);
    }

    function OnDestroy() {
        print("Wisper "+self+" is destroyed. woo!");
        Link.BroadcastOnAllLinks(self, "Unwisp", "Population");
        // NOTE: If we were not Slain, then we want our particles to be able
        //       to make corpses: so we Slay them.
        CleanupOwned(false);
    }
}

/* Script for a non-launched particle effect that can change over time.
   This is pretty hard-coded for the needs of the WisperCore and WisperGlow
   particles:

   - applies changes over a duration set by the Particle Launch Info "Max Time" value.
   - fades "bm-disk rgb" color over time to the 2nd and 3rd colors (regardless
     of bm-disk flags), at a rate defined by "particle fade time".
   - scales "size of particle" per the X field of Particle Launch Info "Box Min"/
     "Box Max", starting at the min x and ending at the max x.
   - scales "fixed-group radius" per the Y field of Particle Launch Info "Box Min"/
     "Box Max", starting at the min y and ending at the max y.
   - sets "pulse cycle time ms" per the Z field of Particle Launch Info "Box Min"/
     "Box Max", starting at the min z and ending at the max z.
*/
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
