class TronRotaryButton extends SqRootScript {
    function OnFrobWorldEnd() {
        local currentPos = GetData("Position");
        local newPos = Data.RandInt(0, 3);
        DarkUI.TextMessage("Rotating from pos "+currentPos+" to pos "+newPos, 0, 2000);
        RotateToPosition(newPos);
    }

    function OnBeginScript() {
        SetData("Active", false);
        SetPosition(0);
    }

    function SetPosition(pos) {
        SetData("Active", false);
        SetData("Position", pos);
        local targetAngle = 45+90*pos;
        if (targetAngle>=360) {
            targetAngle -= 360;
        }
        TweqStop();
        Property.Set(self, "Position", "Bank", (targetAngle/360.0)*65536);
    }

    function RotateToPosition(pos) {
        local active = GetData("Active");
        if (active) {
            // TODO: play a 'Locked' sound?
            return false;
        }
        SetData("Active", true);
        SetData("Position", pos);
        local currentAngle = Object.Facing(self).x;
        local targetAngle = 45+90*pos;
        if (targetAngle>=360) {
            targetAngle -= 360;
        }
        local speed = 20;
        if (targetAngle>currentAngle) {
            TweqRotate(speed, currentAngle, targetAngle);
        } else {
            SetData("NextPosition", pos);
            TweqRotate(speed, currentAngle, 360);
        }
        return true;
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeRotate
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            SetData("Active", false);
            if (IsDataSet("NextPosition")) {
                local pos = GetData("NextPosition");
                ClearData("NextPosition");
                RotateToPosition(pos);
            } else {
                // TODO: notify somebody that we are done?
            }
        }
    }

    function TweqRotate(speed, from, to) {
        Property.Set(self, "StTweqRotate", "AnimS", 0);
        Property.Set(self, "CfgTweqRotate", "x rate-low-high",
            vector(speed, from, to));
        Property.Set(self, "StTweqRotate", "Axis 1AnimS", 1);
        Property.Set(self, "StTweqRotate", "AnimS", 1);
    }

    function TweqStop() {
        Property.Set(self, "StTweqRotate", "AnimS", 0);
    }
}
