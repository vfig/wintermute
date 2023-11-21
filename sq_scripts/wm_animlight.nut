// This is a port of the stock AnimLight script to squirrel, so that
// we can subclass it (e.g. for wisp-vulnerable lights). All the remaining
// comments are from the original.
//
// Base script for animating lights: knows how to turn them on and off
// Objects with special effects associated with these events should
// override the TurnOn and TurnOff methods
//
// If the anim light has a TweqFlicker property, then the light will
// respond to TurnOn messages by starting the TweqFlicker and going
// into "flicker between min and max" mode.  When the TweqFlicker
// finishes, _then_ it will turn on.
//
class SqAnimLight extends SqRootScript {

    // METHODS:

    function InitModes()
    {
        local mode, onmode, offmode;

        if(Property.Possessed(self,"AnimLight"))
            mode=Property.Get(self,"AnimLight","Mode");
        else
            return; // Bad, but nothing we can do.

        if(mode==ANIM_LIGHT_MODE_MINIMUM)
            offmode=mode;
        else if(mode==ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN ||
                  mode==ANIM_LIGHT_MODE_SMOOTH_DIM)
            offmode=ANIM_LIGHT_MODE_SMOOTH_DIM;
        else
            offmode=ANIM_LIGHT_MODE_EXTINGUISH;

        if(mode!=offmode)
            onmode=mode;
        else
        {
            if(offmode==ANIM_LIGHT_MODE_SMOOTH_DIM)
                onmode=ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN;
            else
                onmode=ANIM_LIGHT_MODE_MAXIMUM;
        }

        SetData("OnLiteMode",onmode);
        SetData("OffLiteMode",offmode);
    }
        
    // Turn our ambienthack sound (if present) on or off
    function AmbientHack(on)
    {
        if(Property.Possessed(self,"AmbientHacked"))
        {
            local flags=Property.Get(self,"AmbientHacked","Flags");

            if(!on)
                flags=flags|AMBFLG_S_TURNEDOFF;
            else
                flags=flags&(~AMBFLG_S_TURNEDOFF);
            Property.Set(self,"AmbientHacked","Flags",flags);
        }
    }
    function IsLightOn()
    {
        local mode;

        if(Property.Possessed(self,"AnimLight"))
            mode=Property.Get(self,"AnimLight","Mode");
        else
            return false;

        if(!IsDataSet("OnLiteMode"))
            InitModes();

        return mode==GetData("OnLiteMode");
    }
    function ChangeMode(on)
    {
        local newmode;
        local onoffmsg=on?"TurnOn":"TurnOff";
        local modedata=on?"OnLiteMode":"OffLiteMode";

        Link.BroadcastOnAllLinks(self,onoffmsg,"~ParticleAttachement");
        
        if(Property.Possessed(self,"SelfIllum"))
            Property.SetSimple(self,"SelfIllum",on?1.0:0);

        AmbientHack(on);

        Link.BroadcastOnAllLinks(self,onoffmsg,"ControlDevice");

        if(!Property.Possessed(self,"AnimLight"))
            return; // nothing we can do.

        if(!IsDataSet(modedata))
            InitModes();

        newmode=GetData(modedata);
        Light.SetMode(self,newmode);
    }
    function TurnOn()
    {
        ChangeMode(true);
    }
    function TurnOff()
    {
        ChangeMode(false);
    }
    function Toggle()
    {
        local mode;
        if(!Property.Possessed(self,"AnimLight")) return;

        if(!IsDataSet("OnLiteMode") || !IsDataSet("OffLiteMode"))
            InitModes();

        mode=Property.Get(self,"AnimLight","Mode");
        if(mode==GetData("OnLiteMode"))
            TurnOff();
        else if(mode==GetData("OffLiteMode"))
            TurnOn();
    }

    // MESSAGES:

    // Initializations to force particle and self-illum state to be
    // consistent with light "on" state.  Safe for save/load.
    function OnSim()
    {
        if(message().starting)
            InitModes();
    }
    function OnBeginScript()
    {
        // This should just synch particles, tweqs, self illum, and such to
        // the current state of the AnimLight property.
        ChangeMode(IsLightOn());
    }
    function OnTweqComplete()
    {
        if(message().Type==eTweqType.kTweqTypeFlicker)
        {
            TurnOn();
        }
    }
    function OnSlain()
    {
        // Anim Lights need to stick around just long enough to turn off
        // when slain.  So...
        TurnOff();
        SetOneShotTimer(self,"ReallySlay",0.1);
    }
    function OnTimer()
    {
        if(message().name=="ReallySlay")
        {
            // Destruction of anim lights not safe across save/load, apparently
            // Object.Destroy(self);
            Property.SetSimple(self,"HasRefs",FALSE);
        }
    }
    function OnMessage()
    {
        if(MessageIs("TurnOn"))
        {
            if(Property.Possessed(self,"StTweqBlink"))
            {
                ActReact.React("tweq_control",1.0,self,0,eTweqType.kTweqTypeFlicker,eTweqDo.kTweqDoActivate);
                Light.SetMode(self,ANIM_LIGHT_MODE_FLICKER);
            }
            else
                TurnOn();
        }
        else if(MessageIs("TurnOff"))
        {
            if(Property.Possessed(self,"StTweqBlink"))
            {
                ActReact.React("tweq_control",1.0,self,0,eTweqType.kTweqTypeFlicker,eTweqDo.kTweqDoHalt);
                Property.Set(self,"StTweqBlink","Cur Time",0);
            }
            TurnOff();
        }
        else if(MessageIs("Toggle"))
            Toggle();
    }
}
