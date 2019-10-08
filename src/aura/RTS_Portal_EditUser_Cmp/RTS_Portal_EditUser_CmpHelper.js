({
    getFormData: function(component, event, helper){
        var userId = component.get('v.userId');
        var allUsers = component.get('v.allUsers');
        
        if(userId != '') {
            for (var user of allUsers) {
                if(user.managedUser.Id == userId) {
                    console.log(user);
                    console.log('active?: ' + user.isActive);
                    component.set('v.userContactId', user.managedUser.ContactId);
                    if(user.isActive) {
                        component.set('v.isActive', true);
                  
                    } else {
                        component.set('v.isActive', false);
                        component.set('v.disable', true);
                    }
                    
                    component.set('v.editingInstaller', user.isInstaller);
                    var specialties = user.managedUser.Contact.Specialties__c;
                    var stores = user.assignedStoreIds;
                    if(specialties != undefined) {
                        specialties = specialties.split(';');
                    	component.set('v.selectedSpecialties', specialties);
                    } else {
                        specialties = [''];
                    }
                    
                    component.set('v.selectedStores', stores);
                    component.set('v.userInfo', user);
                    //console.log(user);
                    
                }
            }
            component.set("v.isEditOpen", true);

        }
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
    
    getLoggedInUser : function(component, event, helper){
        this.sendRequest(component, 'c.hasInstallerAdminPermission')
        .then($A.getCallback(function(isInstaller) {
            console.log(isInstaller);
            component.set('v.isInstaller', isInstaller);
            if(!isInstaller) {
                component.set('v.disable', true);
            } 
       
        }))
        .catch(function(errors) {
            console.error('current user error: ' + errors);
        });
    },
    
    getPermissions : function(component, event, helper){
        this.sendRequest(component, 'c.canCreateUser')
        .then($A.getCallback(function(isAdmin) {
            console.log(isAdmin);
            if(isAdmin) {
                component.set('v.disablePicklists', false);
            } else {
                component.set('v.disablePicklists', true);
            }
       
        }))
        .catch(function(errors) {
            console.error('current user error: ' + errors);
        });
    },
    
    
    
    getStores : function(component, event, helper) {
        this.sendRequest(component, 'c.getAssignedStores')
        .then($A.getCallback(function(stores) {
            //console.log(stores);
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
   
    
    validateRequiredFields : function(component, data) {
        var userData = data;
        
        if (!(userData.firstName) || !(userData.lastName) || !(userData.email) || !(userData.phoneNumber)) {
            component.set("v.errorMessage", "Please fill out all required fields.");
            component.set("v.isValid", true);
            component.set('v.loading', false);
            return false;
        } else {
            component.set("v.isValid", false);
            return true;
        }
    },
    
    getUserData : function(component, event, helper) {
        
        var firstName = component.find('edit-first-name').get('v.value');
        var lastName = component.find('edit-last-name').get('v.value');
        var email = component.find('edit-email-address').get('v.value');
        var phoneNumber = component.find('edit-phone-number').get('v.value');
        var editingInstaller = component.get('v.editingInstaller');
        if (editingInstaller) {
            isAdmin = false;
        } else {
            var isAdmin = component.find('edit-admin').get('v.checked');
        }
        
        console.log(isAdmin);
        var userId = component.get('v.userId');
        var loggedInId = component.get('v.loggedInUserId');
        if(userId == loggedInId) {
            var isActive = component.get('v.isActive');
        } else {
            isActive = component.find('edit-active-user').get('v.checked');
        }
        
        var contactId = component.get('v.userContactId');
        
        var specialties = component.find('edit-user-specialities').get('v.value');
        var assignedStores = component.find('edit-user-stores').get('v.value');
        
        
        var userObject  = {
            firstName: firstName,
            lastName: lastName,
            email: email,
            confirmationEmail: email,
            phoneNumber: phoneNumber,
            isSecondaryAdmin: isAdmin,
            isActive: isActive,
            contactId: contactId,
            userId : userId,
            specialties : specialties,
            assignedStores : assignedStores
        };
        
        console.log(userObject);
        return userObject;
    },
    
    updateUser: function(component, userId) {
        console.log(userId);
        var userData = this.getUserData(component);
        var jsonUserData = JSON.stringify(userData);
        var isValid = this.validateRequiredFields(component, userData);
        var fInitial = userData.firstName.slice(0,1);
        var phoneDigits = userData.phoneNumber.slice(-4);
        
        var userName = fInitial + userData.lastName + phoneDigits + '@llportal.com';
        var help = this;
        
        if(isValid) {
            this.sendRequest(component, 'c.existingUsernameAvailable', {'username' : userName, 'userId' : userId })
            .then($A.getCallback(function(username) {
                if(!username) {
                    return Promise.reject("ERROR: Username is already registered to another user. Please contact Lumber Liquidators at 1-800-651-1635 for assistance.");
                } else {
                    return help.sendRequest(component, 'c.updateContact', {'userFormJSON' : jsonUserData});
                }
            }))
            .then($A.getCallback(function(contact) {
                if(contact.contactId) {
                    var JSONcontact = JSON.stringify(contact);
                    return help.sendRequest(component, 'c.updateUser', {'userFormJSON' : JSONcontact});
                } else {
                    return Promise.reject("ERROR: There was a problem updating the contact. Please try again or contact Lumber Liquidators at 1-800-651-1635 for assistance.");
                }
                
            }))
            .then($A.getCallback(function(user) {
                if(!user) {
                    return Promise.reject("ERROR: There was a problem updating the user. Please try again or contact Lumber Liquidators at 1-800-651-1635 for assistance.");
                } else {
                    return true;
                }
            }))
            .then($A.getCallback(function(success) {
                component.set('v.loading', false);
                component.set("v.isEditOpen", false);
                var refreshData = $A.get("e.c:RTS_Portal_RefreshManageUsersView_CmpEvt"); 
                refreshData.fire();
            }))
            .catch(function(errors) {
                component.set('v.loading', false);
                component.set("v.errorMessage", errors);
                component.set("v.isValid", true);
                console.log(errors);
            })
        }
    },
    
    sendRequest : function(component, methodName, params){
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get(methodName);
            if(params) {
                action.setParams(params);
            }
            
            action.setCallback(self, function(res) {
                var state = res.getState();
                if(state === 'SUCCESS') {
                    resolve(res.getReturnValue());
                } else if(state === 'ERROR') {
                    reject(action.getError())
                }
            });
            $A.enqueueAction(action);
        }));
    },
})