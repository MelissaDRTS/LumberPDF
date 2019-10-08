({
	init : function(component, event, helper) {
		helper.getTasks(component);
	},
    
    handleClick : function(component, event, helper) {
        var recId = event.getSource().get("v.value");
        console.log(recId);
        var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/detail/" + recId
                });
                urlEvent.fire();
    },
})