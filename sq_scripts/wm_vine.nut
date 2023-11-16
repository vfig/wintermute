/* Based on stock CollisionStick, DeployRope, DeployVine.
   Deploys a vine when it hits a suitable wall or ceiling surface; if not, it
   bounces back. If it hits a floor-ish surface, and there is a MudLump1 or
   PlantLump1 nearby, will deploy an upward rope.
*/
class SpringVine extends SqRootScript {
    // Considering only the type of surface, can I attach?
    // This is the method you'd override to make distinctions
    // between target surface types, as with the vine arrow.
    function CanAttachToSurface(targ) {
        local surf = 0;
        local me = 0;

        if (Property.Possessed(targ, "CanAttach"))
            surf = Property.Get(targ, "CanAttach");
        if (Property.Possessed(self,"CanAttach"))
            me = Property.Get(self, "CanAttach");

        return ((me&surf)!=0);
    }

    function CanAttachTo(targ) {
        if (targ==0) return false;
        if (! CanAttachToSurface(targ)) return false;
        if (Object.InheritsFrom(targ, "Texture"))
            return true;
        // Objects which are not textures ought to be
        // immobile, or we can't attach.
        if (!Property.Possessed(targ,"Immobile")
        || !Property.Get(targ,"Immobile"))
            return false;
        // Even if "immobile", the object might be a door
        // set to "immobile" because we'd like it to block
        // lights.  So, check for doors explicitly.
        if (Property.Possessed(targ, "RotDoor")
        || Property.Possessed(targ, "TransDoor")
        || Property.Possessed(targ, "MovingTerrain"))
            return false;
        return true;
    }

    function CanGrowUpFrom(targ) {
        if (targ==0) return false;
        if (! CanAttachToSurface(targ)) return false;
        if (Object.InheritsFrom(targ, "EarthTex")
        || Object.InheritsFrom(targ, "VegetationTex"))
            return true;
        return false;
    }

    function HasConcreteInRange(archName, maxDistance) {
        local selfPos = Object.Position(self);
        local arch = Object.Named(archName);
        if (arch==0) return false;
        foreach (link in Link.GetAll("~MetaProp", arch)) {
            local obj = LinkDest(link);
            local objPos = Object.Position(obj);
            local dist = (selfPos-objPos).Length();
            if (dist<=maxDistance) {
                return true;
            }
        }
        return false;
    }

    function IsNearEarthLump() {
        if (HasConcreteInRange("MudLump1", 7.5)) return true;
        if (HasConcreteInRange("PlantLump1", 7.5)) return true;
        return false;
    }

    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
        SetData("FirstBounce", 1);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        local WhatIHit = message().collObj;
        local attach = CanAttachTo(WhatIHit);
        local isFloor = (message().collNormal.z>=0.707);
        local isUp = false;
        if (isFloor) {
            if (IsNearEarthLump()) {
                attach = true;
                isUp = true;
            } else {
                isUp = CanGrowUpFrom(WhatIHit);
            }
        }
        if (GetData("FirstBounce")==1) {
            SetData("FirstBounce", 0);
            if (! Object.HasMetaProperty(self, "M-SpringVineBounce")) {
                Object.AddMetaProperty(self, "M-SpringVineBounce");
            }
        } else {
            attach = false;
        }
        if (attach) {
            if (!Property.Possessed(self, "StackCount")) {
                Property.Add(self, "StackCount");
                Property.Set(self, "StackCount", 1);
            }
            local RopeArch = isUp? "VineArrowUpVine":"VineArrowVine";
            local MyRope = Object.BeginCreate(RopeArch);
            Link.Create("Owns", self, MyRope);
            Object.Teleport(MyRope, vector(-1.0,0,0), vector(0,0,0), self);
            Property.Set(MyRope, "SuspObj", "Is Suspicious", true);
            //don't set type. (why not?)
            Property.Set(MyRope, "SuspObj", "Minimum Light Level", 0.15);
            Object.EndCreate(MyRope);
         
            local Joint = Object.BeginCreate("VineClump");
            if (Joint!=0) {
                Link.Create("Owns", self, Joint);
                Object.Teleport(Joint, vector(-0.33,0,0), vector(0,0,0), self);
                Object.EndCreate(Joint);
            }
        }
        Reply(attach? ePhysMessageResult.kPM_NonPhys:ePhysMessageResult.kPM_Bounce);
    }

    function OnFrobWorldEnd() {
        // if rope arrow is picked up, destroy the rope it deployed
        // (also vine clump for vine arrows)
        if (Link.AnyExist("Owns", self)) {
            local ownlinks = Link.GetAll("Owns", self);
            while (ownlinks.AnyLinksLeft()) {
                local attachment = LinkDest(ownlinks.Link());
                Damage.Slay(attachment, self);
                ownlinks.NextLink();
            }
        }
        SetData("FirstBounce", 1);
        if (Object.HasMetaProperty(self, "M-SpringVineBounce")) {
            Object.RemoveMetaProperty(self, "M-SpringVineBounce");
        }
    }
}
