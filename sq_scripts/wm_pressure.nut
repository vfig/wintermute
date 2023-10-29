/* PressureGauge monitors the pressure in a pool. When it receives a TurnOn,
   the pressure starts rising; when pressure reaches max, it broadcasts TurnOn
   along CD links. When the gauge receives a TurnOff, it begins falling; when
   pressure leaves max, it broadcasts TurnOff along CD links.

   The min/max pressure values, and time between them are controlled by the
   base archetype, and the M-PressureGaugeRising and M-PressureGaugeMax
   metaproperties, in their Tweq: Joints properties.
*/
class PressureGauge extends SqRootScript {
    function OnTurnOn() {
        if (Object.HasMetaProperty(self, "M-PressureGaugeMax")) {
            // Already on.
        } else {
            if (! Object.HasMetaProperty(self, "M-PressureGaugeRising")) {
                Object.AddMetaProperty(self, "M-PressureGaugeRising");
                local tweq = GetProperty("CfgTweqJoints", "    rate-low-high");
                SetProperty("JointPos", "Joint 1", tweq.y);
            }
            SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
        }
    }

    function OnTurnOff() {
        if (Object.HasMetaProperty(self, "M-PressureGaugeMax")) {
            Object.RemoveMetaProperty(self, "M-PressureGaugeMax");
            Object.AddMetaProperty(self, "M-PressureGaugeRising");
            local tweq = GetProperty("CfgTweqJoints", "    rate-low-high");
            SetProperty("JointPos", "Joint 1", tweq.z);
            Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
        }
        if (Object.HasMetaProperty(self, "M-PressureGaugeRising")) {
            SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
        } else {
            // Already off.
        }
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            Object.RemoveMetaProperty(self, "M-PressureGaugeRising")
            if (message().Dir==eTweqDirection.kTweqDirForward) {
                // Reached max pressure.
                if (! Object.HasMetaProperty(self, "M-PressureGaugeMax")) {
                    Object.AddMetaProperty(self, "M-PressureGaugeMax")
                }
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            } else {
                // Reached normal pressure.
            }
            SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
        }
    }
}

/* OverpressureGauge monitors the overpressure level in a pool. When it
   receives a TurnOn, it starts rising; when overpressure reaches max, it
   broadcasts TurnOn along CD links. When the gauge receives a TurnOff, it
   immediately resets.

   The min/max pressure values, and time between them are controlled by the
   base archetype in its Tweq: Joints properties.
*/
class OverpressureGauge extends SqRootScript {
    function OnTurnOn() {
        SetProperty("StTweqJoints", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnTurnOff() {
        local tweq = GetProperty("CfgTweqJoints", "    rate-low-high");
        SetProperty("JointPos", "Joint 1", tweq.y);
        SetProperty("StTweqJoints", "AnimS", 0);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeJoints
        && message().Op==eTweqOperation.kTweqOpHaltTweq
        && message().Dir==eTweqDirection.kTweqDirForward) {
            // Reached critical overpressure.
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            OnTurnOff();
        }
    }
}

class PressureRegulatorFlicker extends SqRootScript {
    function OnTurnOn() {
        SetProperty("StTweqBlink", "Cur Time", 0);
        SetProperty("StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
        // Send out an immediate particle burst.
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function OnTurnOff() {
        SetProperty("StTweqBlink", "AnimS", 0);
    }
}
