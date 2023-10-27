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
    if (typeName=="blueprint") return IntelType.Blueprint;
    else if (typeName=="correspondence") return IntelType.Correspondence;
    else if (typeName=="specification") return IntelType.Specification;
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

class IsIntel extends SqRootScript {
    /* on pickup, should
        - add to intel stats qvars
        - combine with existing intel stack (or fake it)
        - enable corresponding pages (well, set appropriate qvars)
        - 
    */
    function OnFrobWorldEnd() {
        // Ignore attemps to pick us up by anyone other than the player.
        local frobber = message().Frobber;
        if (! Object.InheritsFrom(frobber, "Avatar")) {
            print("ERROR: ("+self+") Only the player is allowed to frob us.");
            return;
        }
        // TODO: enable corresponding pages
        // Increment the appropriate intel type.
        local params = userparams();
        local type = -1;
        if ("IntelType" in params) {
            type = Intel.ParseType(params.IntelType);
        } else {
            print("ERROR: ("+self+") Missing IntelType userparam.");
            return;
        }
        Intel.AddCount(type);
        // Play a nice sound.
        // TODO: make a custom pickup_intel schema that is the paper sound.
        Sound.PlaySchemaAmbient(self, "pickup_loot");
        // Merge with the glory of the fle--er, intelligence.
        Container.Add(self, frobber);
    }

    function OnFrobInvEnd() {
        local text = GetProperty("Book");
        local art = GetProperty("BookArt");
        if (text && art) {
            DarkUI.ReadBook(text, art);
        }
    }

    function OnContained() {
        UpdateName();
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
