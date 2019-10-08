({
    checkPrivileges : function(component, event, helper){
        
        this.sendRequest(component, 'c.hasInstallerAdminPermission')
        .then($A.getCallback(function(isInstaller) {
            console.log(isInstaller);
            if(isInstaller) {
                console.log('is installer');
                component.set('v.isInstaller', true);
            } else {
                console.log('is not Installer');
                component.set('v.isInstaller', false);
            }
        }))
        .catch(function(errors) {
            console.error('current installer check error: ' + errors);
        });
    },
    
    getUser : function(component, userId){
        this.sendRequest(component, 'c.getUserToReassign', {'userId' : userId})
        .then($A.getCallback(function(user) {
            console.log(user);
            component.set('v.userToReassign', user);
            component.set('v.isVisible', true);
            
            
        }))
        .catch(function(errors) {
            console.error('get user error: ' + errors);
            component.set('v.isVisible', false);
        });
    },
    
    getSpecialties : function(component, event, helper){
        this.sendRequest(component, 'c.getSpecialtyOptions')
        .then($A.getCallback(function(options) {
            var items = [];
            options.forEach(function(opt) {
                items.push({value: opt, label: opt});
            });
            component.set('v.specialtyOptions', items);
        }))
        .catch(function(errors) {
            console.error('specialty error: ' + errors);
        });
    },
    
    getStores : function(component, event, helper) {
        this.sendRequest(component, 'c.getAssignedStores')
        .then($A.getCallback(function(stores) {
            console.log(stores);
            var options = [];
            stores.forEach(function(store) {
                options.push({value: store.Id, label: store.Name});
            });
            component.set('v.storeOptions', options);
            
            
        }))
        .catch(function(errors) {
            console.error('store option error: ' + errors);
        });
    },
    
    getUserData : function(component, event, helper) {
        console.log('getting data');
        var firstName = component.find('update-first-name').get('v.value');
        var lastName = component.find('update-last-name').get('v.value');
        var email = component.find('update-email-address').get('v.value');
        var phoneNumber = component.find('update-phone-number').get('v.value');
        var isSecondaryAdmin = component.find('update-user-admin').get('v.checked');
        var assignedStores = component.find('update-user-stores').get('v.value');
        var specialties = component.find('update-user-specialties').get('v.value');
        var isActive = true;
        var userId = component.get('v.userId');
        
        var userObject  = {
            firstName: firstName,
            lastName: lastName,
            email: email,
            confirmationEmail: email,
            phoneNumber: phoneNumber,
            isSecondaryAdmin: isSecondaryAdmin,
            isActive: isActive,
            assignedStores: assignedStores,
            specialties: specialties,
            userId: userId
            
        };
        console.log(userObject);
        return userObject; 
    },
    
    validateRequiredFields : function(component, data) {
        console.log('validating');
        var userData = data;
        if (!(userData.firstName) || !(userData.lastName) || !(userData.email) || !(userData.phoneNumber) ) {
            component.set('v.loading', false);
            component.set("v.errorMessage", "Please fill out all required fields.");
            component.set("v.isError", true);
            return false;
        } else if (!(userData.email.includes("@")) || !(userData.email.includes("."))) {
            component.set('v.loading', false);
            component.set("v.errorMessage", "Email is not in correct format.");
            component.set("v.isError", true);
            return false;
        } else {
            component.set("v.isError", false);
            return true;
        }
    },
    
    reassignUser : function(component, event, helper) {
        var userData =  this.getUserData(component);
        var jsonUserData = JSON.stringify(userData);
        var help = this;
        var valid = this.validateRequiredFields(component, userData);
        console.log(valid);
        if(valid) {
            this.sendRequest(component, 'c.updateContact', {'userFormJSON' : jsonUserData})
            .then($A.getCallback(function(contact) {
                if(contact) {
                    
                    return help.sendRequest(component, 'c.updateUser', {'userFormJSON' : jsonUserData});
                } else {
                    return Promise.reject("ERROR: There was a problem updating the contact. Please try again or contact an administrator.");
                }
                
            }))
            .then($A.getCallback(function(user) {
                if(!user) {
                    return Promise.reject("ERROR: There was a problem updating the user. Please try again or contact an administrator.");
                } else {
                    return true;
                }
            }))
            .then($A.getCallback(function(success) {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/manage-users"
                });
                urlEvent.fire();
            }))
            .catch(function(errors) {
                component.set('v.loading', false);
                component.set("v.errorMessage", errors);
                component.set("v.isError", true);
                console.log(errors);
            })
        }
    },
    
    
    
    sendRequest : function(component, methodName, params){
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get(methodName);
            if (params) {
                action.setParams(params);
            }
            
            action.setCallback(self, function(res) {
                var state = res.getState();
                if(state === 'SUCCESS') {
                    resolve(res.getReturnValue());
                } else if(state === 'ERROR') {
                    console.log(res.getReturnValue());
                    reject(action.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
})