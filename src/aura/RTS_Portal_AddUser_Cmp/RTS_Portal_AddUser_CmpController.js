({
	init: function(component, event, helper) {
        console.log('add user init');
        var parsedUrl = new URL(window.location.href);
		var userId = parsedUrl.searchParams.get("userId");
        console.log(userId);
		helper.checkPrivileges(component);
        if(userId) {
            
            component.set('v.userId', userId);
            helper.getSpecialties(component);
            helper.getStores(component);
            helper.getUser(component, userId);
        } else {
            component.set('v.isVisible', false);
        }
        
    },
    
    save: function(component, event, helper) {
        helper.reassignUser(component);
    },
})