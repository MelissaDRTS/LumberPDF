@isTest
public class RTS_Portal_AllTasks_Test {

    // create tasks and assign to user
    @testSetup public static void testSetup() {
        
        Account testAccount = new Account(
            Name = 'Test Class Account'
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
        
        Task testTask = new Task(
            Subject = 'Test Class Task',
            OwnerId = [SELECT Id FROM User WHERE LastName = 'TestClass'].Id,
            Priority = 'Normal',
            Status = 'Open',
            IsReminderSet = false
        );
        insert testTask; 
        
    }
    
    @isTest
    public static void getAllTasks_test() {
        User u = [SELECT Id FROM User WHERE LastName = 'TestClass'];
        
        System.runAs(u) {
            List<Task> allTasks = RTS_Portal_AllTasks.getAllTasks();
            System.assertEquals(1, allTasks.size());
        }
    } 
    
}