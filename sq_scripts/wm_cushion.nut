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

/* When picked up by the player, swaps itself out for a different object.
   Looks for a Transmute link (from itself or archetypes) to an archetype
   to turn into. Stack Count is preserved. (In other words, like the stock
   Crystal script, except without hardcoded archetypes.)
*/
class InventorySwap extends SqRootScript {
    function GetArchetype() {
        foreach (link in Link.GetAllInheritedSingle("Transmute", self)) {
            return LinkDest(link);
        }
        return 0;
    }

    function Transmogrify(container) {
        local arch = GetArchetype();
        if (! arch) return;
        local obj = Object.Create(arch);
        if (HasProperty("StackCount")) {
            local count = GetProperty("StackCount");
            Property.SetSimple(obj, "StackCount", count);
        }
        Container.Add(obj, container);
    }

    function OnContained() {
        if (message().event!=eContainsEvent.kContainRemove
        && message().container==Object.Named("Player")) {
            Transmogrify(message().container);
            Object.Destroy(self);
        }
    }
}

/* Like MossSpore, only it ignores collisions with the player. */
class MudBall extends SqRootScript {
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        if (message().collObj==Object.Named("Player")) {
            Reply(ePhysMessageResult.kPM_Nothing);
        } else {
            local normal = message().collNormal;
            // Slay if we hit a surface thats within 45 degrees of vertical,
            // facing up; otherwise Destroy.
            if (normal.z<0.707) {
                Property.SetSimple(self, "SlayResult", eSlayResult.kSlayDestroy);
            }
            Reply(ePhysMessageResult.kPM_Slay);
        }
    }
}
