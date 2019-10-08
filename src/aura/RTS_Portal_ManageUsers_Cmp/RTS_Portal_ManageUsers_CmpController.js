({
    
    init: function (component, event, helper) {
        helper.getLoggedInUser(component, event, helper);
        helper.getCurrentUserId(component);
    },
    
    handleEdit: function (component, event, helper) {
        var userId = event.getSource().get("v.value");
        console.log(userId);
        component.set('v.userId', userId);
        
    },
    
    handleRefreshData: function (component, event, helper) {
        helper.getLoggedInUser(component, event, helper);
        helper.getCurrentUserId(component);
        component.set('v.userId', '');
    },
})