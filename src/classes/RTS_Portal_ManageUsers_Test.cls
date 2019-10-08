@isTest public class RTS_Portal_ManageUsers_Test {
    
    // user
    // contact
    // account
    // permissions
    // usernames
    // contact specialties
    // assigned stores
    // make contact
    // update contact
    // make user
    // update user
    
    private static String INSTALLER_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Primary_Admin_Portal_Permissions';
    private static String SECONDARY_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Secondary_Admin_Portal_Permissions';
    private static String SUB_PERMISSION_SET_API_NAME = 'Subcontractor_Portal_Permissions';
    
    @testSetup private static void testSetup() {
        
        
        Account testVendorAccount = new Account(
            Name = 'Test Vendor Account'
        );
        
        insert testVendorAccount;
        
        Contact testInstallerContact = new Contact(
            FirstName = 'InstallerUser',
            LastName = 'TestClass',
            Email = 'testClassUser@email.com',
            AccountId = testVendorAccount.Id
            
        );
        
        insert testInstallerContact;
        
        Contact testSubContact = new Contact(
            FirstName = 'SubContractorUser',
            LastName = 'TestSub',
            Email = 'testSubUser@email.com',
            AccountId = testVendorAccount.Id
            
        );
        
        insert testSubContact;
        
        Contact testAdminContact = new Contact(
            FirstName = 'AdminUser',
            LastName = 'TestAdmin',
            Email = 'testAdminUser@email.com',
            AccountId = testVendorAccount.Id
            
        );
        
        insert testAdminContact;
        
        User testInstallerUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Installer Community Plus User' LIMIT 1].Id,
            Alias = 'alias',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            FirstName = 'InstallerUser',
            LastName = 'TestClass',
            Phone = '804-555-2222',
            Email = 'testClassUser@email.com',
            CommunityNickname = 'testClassUser@email.com',
            Username = 'testClassUser@email.com',
            ContactId = testInstallerContact.Id
        );
        
        insert testInstallerUser;
        
        User testSubUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Subcontractor Community Plus User' LIMIT 1].Id,
            Alias = 'sub',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            FirstName = 'SubUser',
            LastName = 'TestSub',
            Phone = '804-555-2222',
            Email = 'testSubUser@email.com',
            CommunityNickname = 'testSubUser@email.com',
            Username = 'testSubUser@email.com',
            ContactId = testSubContact.Id
        );
        
        insert testSubUser;
        
        User testAdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Installer Community Plus User' LIMIT 1].Id,
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            FirstName = 'AdminUser',
            LastName = 'TestAdmin',
            Phone = '804-555-2222',
            Email = 'testAdminUser@email.com',
            CommunityNickname = 'testAdminUser@email.com',
            Username = 'testAdminUser@email.com',
            ContactId = testAdminContact.Id
        );
        
        insert testAdminUser;
        
        
        
        
        
        Service_Request__c testSR = new Service_Request__c(
            Vendor__c = testVendorAccount.Id
        );
        
        insert testSR;
        
        Sales_Order__c testInstallOrder = new Sales_Order__c(
            RecordTypeId = '012220000004ba2AAA',
            Service_Request__c = testSR.Id,
            Subcontractor__c = testInstallerContact.Id
        );
        
        insert testInstallOrder;
        
    }
    
    private static void addTestUserPermissions() {
        User installer = [SELECT Id FROM User WHERE FirstName = 'InstallerUser' LIMIT 1];
        User admin = [SELECT Id FROM User WHERE FirstName = 'AdminUser' LIMIT 1];
        User sub = [SELECT Id FROM User WHERE FirstName = 'SubUser' LIMIT 1];
        RTS_Portal_ManageUsers_Ctlr.addPermissionSet(installer.Id, INSTALLER_ADMIN_PERMISSION_SET_API_NAME);
        RTS_Portal_ManageUsers_Ctlr.addPermissionSet(admin.Id, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
        RTS_Portal_ManageUsers_Ctlr.addPermissionSet(sub.Id, SUB_PERMISSION_SET_API_NAME);
        
        
    }
    
    private static User getInstaller() {
        User installer = [SELECT Id FROM User WHERE FirstName = 'InstallerUser' LIMIT 1];
        return installer;
    }
    
    private static User getAdmin() {
        User admin = [SELECT Id FROM User WHERE FirstName = 'AdminUser' LIMIT 1];
        return admin;
    }
    
    private static User getSub() {
        User sub = [SELECT Id FROM User WHERE FirstName = 'SubUser' LIMIT 1];
        return sub;
    }
    
    @isTest public static void canCreateUser_test() {
        addTestUserPermissions();
        User u = getInstaller();
        
        System.runAs(u) {
            Boolean createUser = RTS_Portal_ManageUsers_Ctlr.canCreateUser();
            System.assertEquals(true, createUser);
        }
        
    }
    
    @isTest public static void hasInstallerAdminPermission_test() {
        addTestUserPermissions();
        User u = getInstaller();
        
        System.runAs(u) {
            Boolean isInstaller = RTS_Portal_ManageUsers_Ctlr.hasInstallerAdminPermission();
            System.assertEquals(true, isInstaller);
        }
    }
    
    @isTest public static void hasSecondaryAdminPermission_test() {
        addTestUserPermissions();
        User u = getAdmin();
        
        System.runAs(u) {
            Boolean isAdmin = RTS_Portal_ManageUsers_Ctlr.hasSecondaryAdminPermission();
            System.assertEquals(true, isAdmin);
        }
    }
    
    @isTest public static void hasSeondaryAdminPermission_test2() {
        addTestUserPermissions();
        User u = getAdmin();
        
        Boolean isAdmin = RTS_Portal_ManageUsers_Ctlr.hasSecondaryAdminPermission(u.Id);
        System.assertEquals(true, isAdmin);
        
    }
    
    @isTest public static void hasSubcontractorPermission_test() {
        addTestUserPermissions();
        User u = getSub();
        
        System.runAs(u) {
            Boolean isSub = RTS_Portal_ManageUsers_Ctlr.hasSubcontractorPermission();
            System.assertEquals(true, isSub);
        }
    }
    
    @isTest public static void usernameAvailable_test() {
        String available = RTS_Portal_ManageUsers_Ctlr.usernameAvailable('testAdminUser@email.com');
        System.assertEquals('contact lumber', available);
    }
    
    @isTest public static void existingUsernameAvailable_test() {
        User u = [SELECT Id, Username FROM User LIMIT 1];
        Boolean available = RTS_Portal_ManageUsers_Ctlr.existingUsernameAvailable(u.Username, u.Id);
        System.assertEquals(true, available);
    }
    
    @isTest public static void getSpecialtyOptions_test() {
        List<String> options = RTS_Portal_ManageUsers_Ctlr.getSpecialtyOptions();
        System.assertEquals(true, options.contains('Tile'));
    }
    
    @isTest public static void getUserToReassign_test() {
        User u = [SELECT Id, FirstName, Username FROM User WHERE Username = 'testAdminUser@email.com' LIMIT 1];
        RTS_Portal_ManageUsers_Ctlr.UserForm userForm = RTS_Portal_ManageUsers_Ctlr.getUserToReassign(u.Id);
        System.assertEquals(u.FirstName, userForm.firstName);
    }
    
    @isTest public static void getAssignedStores_test() {
        addTestUserPermissions();
        User u = getSub();
        
        System.runAs(u) {
            List<Store__c> stores = RTS_Portal_ManageUsers_Ctlr.getAssignedStores();
            System.assertEquals(0, stores.size());
        }
    }
}