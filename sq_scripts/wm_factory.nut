class FacWorker extends SqRootScript {
    function GetConv() {
        local link = Link.GetOne("~AIConversationActor", self);
        if (link==0) return 0;
        return LinkDest(link);
    }

    function OnIsPickUpReady_() {
        print("-----------------------------------------")
        print(message().message);
        if (Link.AnyExist("Route", self)) { print("Already have linked obj."); Reply(false); return; }
        local conv = GetConv();
        local type = "PaganDoll";
        local maxDist = 2.0;
        print("Conv "+conv+" at "+Object.Position(conv));
        local obj = Object.FindClosestObjectNamed(conv, type);
        if (obj==0) { print("Cannot find "+type); Reply(false); return; }
        print("Found "+obj+" at "+Object.Position(obj));
        local dist = (Object.Position(obj) - Object.Position(conv)).Length();
        if (dist>maxDist) { print("Distance "+dist+" exceeds max "+maxDist); Reply(false); return; }
        local link = Link.Create("Route", self, obj);
        Reply(true);
    }

    function OnDoPickUp() {
        print("-----------------------------------------")
        print(message().message);
        local link = Link.GetOne("Route", self);
        if (link==0) { print("No Route link to obj."); Reply(false); return; }
        local obj = LinkDest(link);
        Link.Destroy(link);
        Container.Add(obj, self, eDarkContainType.kContainTypeAlt);
        Reply(true);
    }
}
