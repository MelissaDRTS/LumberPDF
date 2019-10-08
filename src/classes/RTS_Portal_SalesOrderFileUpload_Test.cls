@isTest
public class RTS_Portal_SalesOrderFileUpload_Test {
    
    @testSetup private static void testSetup() {
        Account testAccount = new Account(
            Name = 'Test Vendor Account'
        );
        
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'User',
            LastName = 'TestClass',
            Email = 'testClassUser@email.com',
            AccountId = testAccount.Id
            
        );
        
        insert testContact;
        
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Installer Community Plus User' LIMIT 1].Id,
            Alias = 'alias',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            FirstName = 'User',
            LastName = 'TestClass',
            Phone = '804-555-2222',
            Email = 'testClassUser@email.com',
            CommunityNickname = 'testClassUser@email.com',
            Username = 'testClassUser@email.com',
            ContactId = testContact.Id
        );
        
        insert testUser;
        
        Service_Request__c testSR = new Service_Request__c(
            Vendor__c = testAccount.Id
        );
        
        insert testSR;
        
        Sales_Order__c testInstallOrder = new Sales_Order__c(
            RecordTypeId = '012220000004ba2AAA',
            Service_Request__c = testSR.Id,
            Subcontractor__c = testContact.Id
        );
        
        insert testInstallOrder;
        
        ContentVersion testFile = new ContentVersion(
            Title = 'Test Doc',
            PathOnClient = 'testDoc23.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        
        insert testFile;
        
        
        
    }
    
    private static ContentDocument getDocument() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        return doc;
    }
    
    private static Sales_Order__c getSalesOrder() {
        Sales_Order__c soId = [SELECT Id, Service_Request__c FROM Sales_Order__c LIMIT 1];
        return soId;
    }
    
    @isTest public static void isSalesOrder_test() {
        Sales_Order__c so = getSalesOrder();
        Boolean isSalesOrder = RTS_Portal_SalesOrderFileUpload.isSalesOrder(so.Id);
        System.assertEquals(true, isSalesOrder);
    }
    
    @isTest public static void getRecordType_test() {
        Sales_Order__c so = getSalesOrder();
        String recType = RTS_Portal_SalesOrderFileUpload.getRecordType(so.Id);
        System.assertEquals('Install_Order', recType);
    }
    
    @isTest public static void getParentServiceRequest_test() {
        Sales_Order__c so = getSalesOrder();
        Id srId = RTS_Portal_SalesOrderFileUpload.getParentServiceRequest(so.Id);
        System.assertEquals(so.Service_Request__c, srId);
    }
    
    @isTest public static void updateCustomerCompleteltionCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('CustomerCompletionForm', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Customer_Completion_Form__c);
    }
    
    @isTest public static void updateChangeAuthCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('InstallChangeAuthorization', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Installation_Change_Authorization__c);
    }
    
    @isTest public static void updateChangeOrderCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('ChangeOrderForm', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Installation_Change_Order__c);
    }
    
    @isTest public static void updateLienWaiverCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('InstallationLienWaiver', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Lien_Waiver__c);
    }
    
    @isTest public static void updateMoistureReadingCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('MoistureReadingForm', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Moisture_Reading__c);
    }
    
    @isTest public static void updateWorkOrderCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('InstallationWorkOrder', so.Id);
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('All_Documents_with_CR', so.Id);
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('All_Documents_without_CR', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Work_Order__c);
    }
    
    @isTest public static void updateAllButCrCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('All_Documents_without_CR', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Work_Order__c);
        System.assertEquals(false, newSo.Installation_Change_Order__c);
    }
    
    @isTest public static void updateProjectAssessmentCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('IPProjectAssessmentForm', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Project_Assessment_Form__c);
        
    }
    
    @isTest public static void updateAllCheckbox_test() {
        Sales_Order__c so = getSalesOrder();
        
        RTS_Portal_SalesOrderFileUpload.updateSalesOrderFileCheckboxes('All_Documents_with_CR', so.Id);
        
        Sales_Order__c newSo = [SELECT Id, Customer_Completion_Form__c, Installation_Change_Authorization__c, Lien_Waiver__c, 
                                Moisture_Reading__c, Installation_Change_Order__c, Project_Assessment_Form__c, Work_Order__c 
                                FROM Sales_Order__c WHERE Id = :so.Id];
        System.assertEquals(true, newSo.Work_Order__c);
        System.assertEquals(true, newSo.Installation_Change_Order__c);
    }
    
    private static RTS_Portal_SalesOrderFileUpload.FileObject newFileObj() {
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument LIMIT 1];
        RTS_Portal_SalesOrderFileUpload.FileObject fileObj = new RTS_Portal_SalesOrderFileUpload.FileObject();
        fileObj.fileType = 'IPProjectAssessmentForm';
        fileObj.newFileName = 'NewFileName';
        fileObj.documentId = doc.Id;
        return fileObj;
    }
    
    @isTest public static void renameFile_test() {
        RTS_Portal_SalesOrderFileUpload.FileObject testDoc = newFileObj();
        String newFileString = JSON.serialize(testDoc);
        RTS_Portal_SalesOrderFileUpload.renameFile(newFileString);
        List<ContentDocument> doc = [SELECT Id, Title FROM ContentDocument WHERE Title = 'NewFileName'];
        System.assertEquals(1, doc.size());
        
    }
    
}