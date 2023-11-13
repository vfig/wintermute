class CushionStimResponse extends SqRootScript {
    ExpireAfter = 0.1

    function OnBeginScript() {
        if (! IsDataSet("LastStim")) SetData("LastStim", 0.0);
        if (! IsDataSet("ExpiryActive")) SetData("ExpiryActive", 0);
    }

    function OnCushionStimStimulus() {
        local now = GetTime();
        local lastStim = GetData("LastStim");
        if (now==lastStim) return;
        SetData("LastStim", now);
        // Add the appropriate metaprops according to velocity.
        local vel = vector();
        Physics.GetVelocity(self, vel);
        local isBig = (vel.z<=-30.0); // Big fall (would normally cause fall damage)
        // We are always cushioned, ...
        if (! Object.HasMetaProperty(self, "M-Cushioned")) {
            Object.AddMetaProperty(self, "M-Cushioned");
        }
        // ...but at high velocity we want the big landing sound:
        if (isBig) {
            if (! Object.HasMetaProperty(self, "M-CushionedBig")) {
                Object.AddMetaProperty(self, "M-CushionedBig");
            }
        } else {
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
        local other = message().collObj;
        if (other==Object.Named("Player")
        || Object.InheritsFrom(other, "mudcarpet")) {
            // Don't collide.
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

class GreenFingers extends SqRootScript {
    function OnBeginScript() {
        if (! IsDataSet("HasGrown")) SetData("HasGrown", 0);
    }

    function OnBeginGrowthStimStimulus() {
        if (! GetData("HasGrown")) {
            SetData("HasGrown", 1);
            Grow("GrowVinePatch", 0.0);
            GrowRandom();
        }
    }

    function OnGrowthStimStimulus() {
        if (! GetData("HasGrown")) {
            SetData("HasGrown", 1);
            GrowRandom();
        }
    }

    function GrowRandom() {
        local archs = [];
        foreach (link in Link.GetAllInheritedSingle("Transmute", self)) {
            archs.append(LinkDest(link));
        }
        if (archs.len()==0) return;
        local choice = Data.RandInt(0, archs.len()-1);
        Grow(archs[choice], 1.5);
    }

    function Grow(arch, offsetScale) {
        local offset = vector();
        offset.x = offsetScale*Data.RandFltNeg1to1();
        offset.y = offsetScale*Data.RandFltNeg1to1();
        local facing = vector();
        facing.z = 360.0*Data.RandFlt0to1();
        local obj = Object.Create(arch);
        Object.Teleport(obj, offset, facing, self);
    }
}
