/* Conversation abort conditions do not reliably play if the conversation is
   interrupted by e.g. combat. At least, not immediately. So we need to make
   sure our conversation-related metaprops are all removed when bad stuff
   happens. This is especially important for standing motion tags.
*/
class ConvCleanUp extends SqRootScript {
    function OnAlertness() {
        if (message().level>message().oldLevel
        && message().level>=2) {
            print(self+" ConvCleanUp on alert "+message().level);
            Object.RemoveMetaProperty(self, "M-WaitForConversation");
            Object.RemoveMetaProperty(self, "M-Crouched");
            Object.RemoveMetaProperty(self, "M-ArmsCrossed");
        }
    }
}
