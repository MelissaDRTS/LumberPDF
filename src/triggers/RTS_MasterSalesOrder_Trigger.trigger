trigger RTS_MasterSalesOrder_Trigger on Sales_Order__c (
    before insert, after insert, 
    before update, after update, 
    before delete, after delete) {
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                // Call class logic here!
            } 
            if (Trigger.isUpdate) {
                // Call class logic here!
            }
            if (Trigger.isDelete) {
                // Call class logic here!
            }
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                // Call class logic here!
            } 
            if (Trigger.isUpdate) {
                List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
                
                for (Sales_Order__c so : Trigger.new) {

                    Service_Request__c parentServiceRequest = [SELECT Id, Estimated_Completion__c, Installation_Completed__c, Installation_Scheduled__c, Measure_Scheduled__c FROM Service_Request__c WHERE Id = :so.Service_Request__c];
                    
                    if (so.RecordTypeId == '012220000004ba7AAA' && !(so.MeasureScheduled__c == null)) {
                        parentServiceRequest.Measure_Scheduled__c = date.newInstance(so.MeasureScheduled__c.year(), so.MeasureScheduled__c.month(), so.MeasureScheduled__c.day());
                    } else if (so.RecordTypeId == '012220000004ba7AAA' && so.MeasureScheduled__c == null) {
                        parentServiceRequest.Measure_Scheduled__c = null;
                    } else if (so.RecordTypeId == '012220000004ba2AAA' && !(so.InstallationScheduled__c == null)) {
                        parentServiceRequest.Estimated_Completion__c = so.EstimatedCompletion__c;
                    	parentServiceRequest.Installation_Completed__c = so.InstallationCompleted__c;
                    	parentServiceRequest.Installation_Scheduled__c = date.newInstance(so.InstallationScheduled__c.year(), so.InstallationScheduled__c.month(), so.InstallationScheduled__c.day());
                    } else if (so.RecordTypeId == '012220000004ba2AAA' && so.InstallationScheduled__c == null) {
                        parentServiceRequest.Estimated_Completion__c = so.EstimatedCompletion__c;
                    	parentServiceRequest.Installation_Completed__c = so.InstallationCompleted__c;
                    	parentServiceRequest.Installation_Scheduled__c = null;
                    }
                    
                    
                    serviceRequests.add(parentServiceRequest);
                }
                update serviceRequests;
                
                
                
            }
            if (Trigger.isDelete) {
                // Call class logic here!
            }
        }
    }