({
    
    getLoggedInUser : function(component, event, helper){
        var help = this;
        this.sendRequest(component, 'c.canCreateUser')
        .then($A.getCallback(function(canCreateUser) {
            console.log(canCreateUser);
            component.set('v.canCreateUser', canCreateUser);
            if(canCreateUser) {
                help.getSpecialties(component);
        		help.getStores(component);
            }
            
        }))
        .catch(function(errors) {
            console.error('current user error: ' + errors);
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
    
    validateRequiredFields : function(component, data) {
        console.log('validating');
        var userData = data;
        if (!(userData.firstName) || !(userData.lastName) || !(userData.email) || !(userData.confirmationEmail) || !(userData.phoneNumber) ) {
            component.set('v.loading', false);
            component.set("v.errorMessage", "Please fill out all required fields.");
            component.set("v.isValid", true);
            return false;
        } else if (!(userData.email.includes("@")) || !(userData.email.includes("."))) {
            component.set('v.loading', false);
            component.set("v.errorMessage", "Email is not in correct format.");
            component.set("v.isValid", true);
            return false;
        } else if (!(userData.email === userData.confirmationEmail)) {
            component.set('v.loading', false);
            component.set("v.errorMessage", "Emails must match.");
            component.set("v.isValid", true);
            return false;
        } else {
            component.set("v.isValid", false);
            return true;
        }
    },
    
    getUserData : function(component, event, helper) {
        var isInstaller = component.get('v.isInstaller');
        
        console.log('here');
        var firstName = component.find('new-first-name').get('v.value');
        console.log(firstName);
        var lastName = component.find('new-last-name').get('v.value');
        var email = component.find('new-email-address').get('v.value');
        var confirmationEmail = component.find('new-confirmation-email-address').get('v.value');
        var phoneNumber = component.find('new-phone-number').get('v.value');
        if(!isInstaller) {
           var isSecondaryAdmin = false;
        } else {
            isSecondaryAdmin = component.find('new-user-admin').get('v.checked');
        }
        
        
        var assignedStores = component.find('new-user-stores').get('v.value');
        var specialties = component.find('new-user-specialties').get('v.value');
        var isActive = true;
        
        var userObject  = {
            firstName: firstName,
            lastName: lastName,
            email: email,
            confirmationEmail: confirmationEmail,
            phoneNumber: phoneNumber,
            isSecondaryAdmin: isSecondaryAdmin,
            isActive: isActive,
            assignedStores: assignedStores,
            specialties: specialties
            
        };
        console.log(userObject);
        return userObject; 
    },
    
    enterNewUser : function(component, event, helper){
        var userData = this.getUserData(component);
        console.log(userData);
        var jsonUserData = JSON.stringify(userData);
        var isValid = this.validateRequiredFields(component, userData);
        var help = this;
        var fInitial = userData.firstName.slice(0,1);
        var phoneDigits = userData.phoneNumber.slice(-4);
        
        var userName = fInitial + userData.lastName + phoneDigits + '@llportal.com';
        console.log(userName);
        if (isValid) {
            component.set('v.loading', true);
            this.sendRequest(component, 'c.usernameAvailable', {'username' : userName})
            .then($A.getCallback(function(user) {
                console.log(user);
                if(user.includes('contact lumber')) {
                    console.log('active user in system');
                    component.set('v.loading', false);
                    return Promise.reject("ERROR: Username is already registered. Please contact Lumber Liquidators at 1-800-651-1635 for assistance.");
                } else if (user.includes("inactive user")) {
                    console.log('inactive user, reassign button');
                    var index = user.search(':');
                    var userId = user.substring(index + 1);
                    console.log(userId);
                    component.set('v.userId', userId);
                    component.set('v.addUser', true);
                    component.set('v.loading', false);
                    return Promise.reject('User is already registered. Click the button to add them to your account.');
                } else {
                    console.log('new contact to create');
                    return help.sendRequest(component, 'c.provisionNewContact', {'userFormJSON' : jsonUserData});
                }
            }))
            .then($A.getCallback(function(contact) {
                console.log(contact.contactId);
                if(contact.contactId) {
                    var JSONcontact = JSON.stringify(contact);
                    return help.sendRequest(component, 'c.provisionNewUser', {'userForm' : JSONcontact});
                } else {
                    component.set('v.loading', false);
                    return Promise.reject("ERROR: There was a problem while creating the new contact. Please try again or contact an administrator.");
                }
                
            }))
            .then($A.getCallback(function(user) {
                console.log(user);
                if(!user) {
                    component.set('v.loading', false);
                    return Promise.reject("ERROR: There was a problem while creating the new user. Please try again or contact an administrator.");
                } else {
                    component.set('v.loading', false);
                    component.set("v.isOpen", false);
                    var refreshData = $A.get("e.c:RTS_Portal_RefreshManageUsersView_CmpEvt"); 
                	refreshData.fire();

                    
                    
                }
            }))
            .catch(function(errors) {
                component.set('v.loading', false);
                component.set("v.errorMessage", errors);
                component.set("v.isValid", true);
                console.log(errors);
            })
            
            
        } 
    },
    
    reassignUser : function(component, event, helper){
        var userId = component.get('v.userId');
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/add-user?userId=" + userId
        });
        urlEvent.fire();
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