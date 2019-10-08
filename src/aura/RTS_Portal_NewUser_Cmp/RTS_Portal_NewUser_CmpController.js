({
    init: function(component, event, helper) {
        console.log('new user init');
        helper.getLoggedInUser(component);
        
    },
    
    addUser : function(component, event, helper) {
        helper.reassignUser(component);
    },
    
    openModel: function(component, event, helper) {
        helper.checkPrivileges(component);
        component.set("v.isOpen", true);
        
    },
    
    closeModel: function(component, event, helper) {
        component.set("v.isValid", false);
        component.set("v.errorMessage", "");
        component.set("v.isOpen", false);
        
    },
    
    save: function(component, event, helper) {
        console.log('saving');
        helper.enterNewUser(component, event, helper);
    },
})