enum IntelType {
    Blueprint = 0,
    Correspondence = 1,
    Specification = 2,
}

Intel <- {}

Intel.TypeLabel <- function(type) {
    // TODO: this needs to use the data service or something to get translated
    //       labels.
    // TODO: in theory i prefer when this said "Correspondence" and "Specifications",
    //       but they were just too long and made the UI look weird.
    if (type==IntelType.Blueprint) return "Blueprints";
    else if (type==IntelType.Correspondence) return "Letters";
    else if (type==IntelType.Specification) return "Specs";
    throw ("Invalid intel type: "+type);
}

Intel.TypeQVar <- function(type) {
    if (type==IntelType.Blueprint) return "IntelBlue";
    else if (type==IntelType.Correspondence) return "IntelCorr";
    else if (type==IntelType.Specification) return "IntelSpec";
    throw ("Invalid intel type: "+type);
}

Intel.ParseType <- function(typeName) {
    typeName = typeName.tolower();
    if (typeName=="blue") return IntelType.Blueprint;
    else if (typeName=="corr") return IntelType.Correspondence;
    else if (typeName=="spec") return IntelType.Specification;
    throw ("Invalid intel type: "+typeName);
}

Intel.GetCount <- function(type) {
    local qvar = Intel.TypeQVar(type);
    if (Quest.Exists(qvar)) {
        return Quest.Get(qvar).tointeger();
    } else {
        return 0;
    }
}

Intel.AddCount <- function(type) {
    local qvar = Intel.TypeQVar(type);
    local count = Intel.GetCount(type);
    count += 1;
    Quest.Set(qvar, count);
}

Intel.TwiddleQVarBit <- function(qvar, bit, set) {
    local value = 0;
    if (Quest.Exists(qvar)) {
        value = Quest.Get(qvar).tointeger();
    }
    if (set) {
        value = value|bit;
    } else {
        value = value&~bit;
    }
    Quest.Set(qvar, value);
    print("Set "+qvar+" = "+value);
}

Intel.SetIDVisible <- function(id, visible) {
    // NOTE: We need two bits for each readable, one that gets cleared (to
    //       reveal the index entry), and one that gets set (to hide the
    //       "not found" placeholder. We allow for up to 64 readable ids; the
    //       reveal-index bit is in BOOK_DECALS_HIDDEN0/1, and the hide-
    //       placholder bit is in BOOK_DECALS_HIDDEN2/3.
    id = id.tointeger();
    if (id<0 || id>=64) {
        throw ("Invalid intel id: "+id);
    }
    local qvarNum = id/32;
    local bit = 1<<(id%32);
    Intel.TwiddleQVarBit("BOOK_DECALS_HIDDEN"+qvarNum, bit, !visible);
    Intel.TwiddleQVarBit("BOOK_DECALS_HIDDEN"+(2+qvarNum), bit, visible);
}

Intel.ShowID <- function(id) {
    Intel.SetIDVisible(id, true);
}

class IsIntel extends SqRootScript {
    function OnFrobWorldEnd() {
        // Ignore attemps to pick us up by anyone other than the player.
        local frobber = message().Frobber;
        if (! Object.InheritsFrom(frobber, "Avatar")) {
            print("ERROR: ("+self+") Only the player is allowed to frob us.");
            return;
        }
        // TODO: figure out some kind of duplicate id detection, preferably
        //       immediately on mission start.
        // Get our parameters, or bail if they are not set.
        local params = ParseTypeAndID();
        if (params==null) {
            print("ERROR: ("+self+") Book: Text must be \"intel_<id>_<type>\".");
            return;
        }
        local type = params[0];
        local id = params[1];
        print("Picked up "+Intel.TypeLabel(type)+" ID "+id+" ("+self+")");
        // Enable the corresponding readable pages.
        Intel.ShowID(id);
        // Increment the appropriate intel type.
        Intel.AddCount(type);
        // Play a nice sound.
        // TODO: make a custom pickup_intel schema that is the paper sound.
        Sound.PlaySchemaAmbient(self, "pickup_loot");
        // Merge with the glory of the fle--er, intelligence.
        Container.Add(self, frobber);
        // Finally, read this book right away, so you don't have to click
        // through a billion pages the first time you read anything. We also
        // remove the Book>Text property so on inventory frobs you read the
        // archetype's Book>Text instead.
        local text = GetProperty("Book");
        local art = GetProperty("BookArt");
        Property.Remove(self, "Book");
        if (text && art) {
            DarkUI.ReadBook(text, art);
        }
    }

    function OnFrobInvEnd() {
        local text = GetProperty("Book");
        local art = GetProperty("BookArt");
        if (text && art) {
            DarkUI.ReadBook(text, art);
        }
    }

    function OnContained() {
        // If we are the first intel picked up, fix our name.
        if (message().event==eContainsEvent.kContainAdd) {
            UpdateName();
        }
    }

    function OnCombine() {
        // Change our shape to that of what was just picked up, like Loot does.
        local intel = message().combiner;
        if (Property.Possessed(intel, "ModelName")) {
            local modelName = Property.Get(intel, "ModelName");
            SetProperty("ModelName", modelName);
        }
        UpdateName();
    }

    function ParseTypeAndID() {
        local text = GetProperty("Book").tostring().tolower();
        if (text.find("intel")!=0) return null;
        local u0 = text.find("_");
        if (u0==null) {
            print("ERROR: ("+self+") Book property must be \"intel_<id>_<type>[_difficulty]\".");
            return null;
        }
        local u1 = text.find("_", u0+1);
        if (u1==null) {
            print("ERROR: ("+self+") Book property must be \"intel_<id>_<type>[_difficulty]\".");
            return null;
        }
        local u2 = text.find("_", u1+1);
        if (u2==null) {
            u2 = text.len();
        }
        local id = text.slice(u0+1,u1).tointeger();
        local type = Intel.ParseType(text.slice(u1+1,u2));
        return [type, id];
    }

    function UpdateName() {
        // Build a name with counts of each intel type, and an overrall total.
        local name = ":\"";
        local label;
        local count;
        local total = 0;
        count = Intel.GetCount(IntelType.Specification);
        label = Intel.TypeLabel(IntelType.Specification);
        name += label+": "+count+"\n";
        total += count;
        count = Intel.GetCount(IntelType.Blueprint);
        label = Intel.TypeLabel(IntelType.Blueprint);
        name += label+": "+count+"\n";
        total += count;
        count = Intel.GetCount(IntelType.Correspondence);
        label = Intel.TypeLabel(IntelType.Correspondence);
        name += label+": "+count+"\n";
        total += count;
        // TODO: this needs to use the data service or something to get translated
        //       labels.
        local totalLabel = "Total";
        name += totalLabel+": "+total;
        name += "\"";
        SetProperty("GameName", name);
    }
}
