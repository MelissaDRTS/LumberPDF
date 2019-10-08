({
    getLoggedInUser : function(component, event, helper){
        var help = this;
        this.sendRequest(component, 'c.canCreateUser')
        .then($A.getCallback(function(isAdmin) {
            console.log(isAdmin);
            if(isAdmin) {
                help.getUsers(component);
            } else {
                help.getUserData(component);
            }
            
        }))
        .catch(function(errors) {
            console.error('current user error: ' + errors);
        });
    },
    
    getCurrentUserId : function(component, event, helper) {
        this.sendRequest(component, 'c.currentUserId')
        .then($A.getCallback(function(userId) {
            console.log('current user id: ' + userId);
            component.set('v.loggedInUserId', userId);
            
       
        }))
        .catch(function(errors) {
            console.error('current user id error: ' + errors);
        });
    },
    
    getUserData : function(component, event, helper) {
        this.sendRequest(component, 'c.getUserData')
        .then($A.getCallback(function(records) {
            console.log(records);
            component.set('v.data', records);
            component.set('v.loading', false);
        }))
        .catch(function(errors) {
            console.error('BUILD SUB USER LIST ERROR: ' + errors);
        });
    },
    
    getUsers : function(component, event, helper) {
        this.sendRequest(component, 'c.getUsersList')
        .then($A.getCallback(function(records) {
            console.log(records);
            component.set('v.data', records);
            component.set('v.loading', false);
        }))
        .catch(function(errors) {
            console.error('BUILD USER LIST ERROR: ' + errors);
        });
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