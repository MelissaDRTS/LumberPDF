({
    renderForm: function(component, event, helper) {
        console.log('rendering edit form');
        helper.getSpecialties(component);
        helper.getStores(component);
        helper.getFormData(component, event, helper);
        helper.getLoggedInUser(component);
        helper.getPermissions(component);
        
    },
    
    openModal: function(component, event, helper) {
        component.set("v.isEditOpen", true);
        component.set("v.isValid", false);
        
    },
    
    closeModal: function(component, event, helper) {
        component.set("v.userId", '');
        component.set('v.disable', false);
        component.set("v.isValid", false);
        component.set("v.isEditOpen", false);
        
        
    },
    
    handleToggle : function(component, event, helper) {
        var isInstaller = component.get('v.isInstaller');
        if(isInstaller) {
            var isActive = component.find('edit-active-user').get('v.checked');
            var active = component.get('v.isActive');
            console.log('attr: ' + active);
            // is opposite of what is should be, having issues with toggle
            if(isActive) {
                component.set('v.disable', true);
            } else {
                component.set('v.disable', false);
            }
        }
        
        
    },
    
    save: function(component, event, helper) {
        console.log('updating user');
        var userId = component.get('v.userId');
        component.set("v.loading", true);
        helper.updateUser(component, userId);
        
        
    },
})