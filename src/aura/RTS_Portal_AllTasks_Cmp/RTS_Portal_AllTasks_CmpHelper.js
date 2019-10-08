({
    getTasks: function(component, event, helper) {
        this.sendRequest(component, 'c.getAllTasks')
        .then($A.getCallback(function(tasks) {
            console.log(tasks);
            component.set('v.data', tasks);
            
            
        }))
        .catch(function(errors) {
            console.error('get all tasks error: ' + errors);
            
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