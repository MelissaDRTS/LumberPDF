trigger RTS_MasterServiceRequest_Trigger on Service_Request__c (
    before insert, after insert, 
    before update, after update, 
    before delete, after delete) {
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                
            } 
            if (Trigger.isUpdate) {
                
            }
            if (Trigger.isDelete) {
                
            }
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                
            } 
            if (Trigger.isUpdate) {
                // if vendor is changed, unassign subs in related sales orders
                List <Sales_Order__c> relatedSalesOrders = new List<Sales_Order__c>();
                List<Id> srIds = new List<Id>();
                for(Service_Request__c sr : Trigger.new) {
                    Service_Request__c oldSR = Trigger.oldMap.get(sr.Id);
                    
                    Id oldVendor = oldSR.Vendor__c;
                    Id newVendor = sr.Vendor__c;
                    // if vendor has changed
                    if(oldVendor != newVendor) {
                        srIds.add(sr.Id);
                    }
                    
                }
                // get all related sales orders
                System.debug(srIds);
                relatedSalesOrders = [SELECT Id, Subcontractor__c FROM Sales_Order__c WHERE Service_Request__c IN :srIds];
                for (Sales_Order__c so : relatedSalesOrders) {
                    // unassign subs
                    so.Subcontractor__c = null;
                    System.debug(so);
                    
                }
                update relatedSalesOrders;
                
                
            }
            if (Trigger.isDelete) {
                
            }
        }
    }