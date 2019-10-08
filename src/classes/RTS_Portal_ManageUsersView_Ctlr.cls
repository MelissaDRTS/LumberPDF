public without sharing class RTS_Portal_ManageUsersView_Ctlr {
    
    @TestVisible private static String INSTALLER_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Primary_Admin_Portal_Permissions';
    @TestVisible private static String SECONDARY_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Secondary_Admin_Portal_Permissions';
    @TestVisible private static String SUB_PERMISSION_SET_API_NAME = 'Subcontractor_Portal_Permissions';
    
    
    public static User getCurrentUser() {
        return getUserById(UserInfo.getUserId());
    }
    
    @AuraEnabled 
    public static Id currentUserId() {
        User u = getCurrentUser();
        return u.Id;
    }
    
    public static User getUserById(Id userId) {
        User u;
        
        if(userId != null) {
            u = [
                SELECT Id, Name, Email, ContactId, AccountId, LanguageLocaleKey, Account.OwnerId,
                EmailEncodingKey, LocaleSidKey, TimeZoneSidKey, FirstName, LastName, Phone, MobilePhone, IsActive, Contact.Specialties__c
                FROM User
                WHERE Id =: userId LIMIT 1
            ];
        }
        return u;
    }
    
    
    @AuraEnabled
    public static Boolean canCreateUser() {
        Boolean isInstaller = hasInstallerAdminPermission();
        Boolean isAdmin = hasSecondaryAdminPermission();
        System.debug(isAdmin);
        if(isInstaller || isAdmin) {
            return true;
        } else {
            return false;
        }
    }
    
    
    
    @AuraEnabled
    public static Boolean hasInstallerAdminPermission() {
        User currentUser = getCurrentUser();
        System.debug(currentUser);
        List<PermissionSetAssignment> psas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUser.Id
        ];
        
        System.debug(psas);
        
        PermissionSet installerAdminPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :INSTALLER_ADMIN_PERMISSION_SET_API_NAME LIMIT 1
        ];
        
        System.debug(installerAdminPermission);
        
        List<String> permissionSetIds = new List<String>();
        
        for( PermissionSetAssignment psa : psas ){
            permissionSetIds.add( psa.PermissionSetId );
        }
        
        return permissionSetIds.contains(String.valueOf(installerAdminPermission.Id));
    } 
    
    @AuraEnabled
    public static Boolean hasInstallerAdminPermission(Id userId) {

        List<PermissionSetAssignment> psas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId 
        ];
        
        System.debug(psas);
        
        PermissionSet installerAdminPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :INSTALLER_ADMIN_PERMISSION_SET_API_NAME LIMIT 1
        ];
        
        System.debug(installerAdminPermission);
        
        List<String> permissionSetIds = new List<String>();
        
        for( PermissionSetAssignment psa : psas ){
            permissionSetIds.add( psa.PermissionSetId );
        }
        
        return permissionSetIds.contains(String.valueOf(installerAdminPermission.Id));
    } 
    
    @AuraEnabled
    public static Boolean hasSecondaryAdminPermission() {
        User currentUser = getCurrentUser();
        List<PermissionSetAssignment> psas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUser.Id
        ];
        
        PermissionSet secondaryAdminPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :SECONDARY_ADMIN_PERMISSION_SET_API_NAME LIMIT 1
        ];
        
        System.debug(secondaryAdminPermission);
        
        List<String> permissionSetIds = new List<String>();
        
        for( PermissionSetAssignment psa : psas ){
            permissionSetIds.add( psa.PermissionSetId );
        }
        
        return permissionSetIds.contains(String.valueOf(secondaryAdminPermission.Id));
    }
    
    public static Boolean hasSecondaryAdminPermission(Id userId) {
        
        List<PermissionSetAssignment> psas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
        ];
        
        PermissionSet secondaryAdminPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :SECONDARY_ADMIN_PERMISSION_SET_API_NAME LIMIT 1
        ];
        
        System.debug(secondaryAdminPermission);
        
        List<String> permissionSetIds = new List<String>();
        
        for( PermissionSetAssignment psa : psas ){
            permissionSetIds.add( psa.PermissionSetId );
        }
        
        return permissionSetIds.contains(String.valueOf(secondaryAdminPermission.Id));
    }
    
    
    public static Map<Id,User> getUserMapByAccountId(Id accountId) {
        
        Map<Id,User> usersMap;
        if ( accountId != null ) {
            usersMap = new Map<Id,User>([
                SELECT Id, Name, Email, ContactId, AccountId, IsActive, FirstName, LastName, Phone, Contact.Specialties__c
                FROM User
                WHERE AccountId = :accountId
                ORDER BY Name
            ]);
            
        }
        return usersMap;
    }
    
    public static Map<Id,User> getUserMapByAccountId(Id accountId, Id userId) {
        
        Map<Id,User> usersMap;
        if ( accountId != null ) {
            usersMap = new Map<Id,User>([
                SELECT Id, Name, Email, ContactId, AccountId, IsActive, FirstName, LastName, Phone, Contact.Specialties__c
                FROM User
                WHERE AccountId = :accountId
                AND Id = :userId 
                LIMIT 1
                
            ]);
            
        }
        return usersMap;
    }
    
    public static Map<Id, Set<String>> getUsersAssignedStores(Map<Id, User> users) {
        if ((null == users) || users.size() == 0)
            return null;
        
        Map<Id,Id> userToContactIds = new Map<Id,Id>();
        for(Id usrid : users.keySet())
        {
            User usr = users.get(usrid);
            userToContactIds.put(usrid, usr.ContactId);
        }
        
        Map<Id, Assigned_Store__c> stores = new Map<Id, Assigned_Store__c>
            ([SELECT Id, Installer_or_Sub__r.Id, Store__c, Store__r.Name
              FROM Assigned_Store__c  
              WHERE Installer_or_Sub__c IN: userToContactIds.values()
              Order by Installer_or_Sub__r.Id, Store__r.Name]);
        
        Map<Id, Set<String>> assignedStoreString = new Map<Id, Set<String>>();
        
        for( Assigned_Store__c store : stores.values())
        {
            Set<String> strStore;
            if(assignedStoreString.containsKey(store.Installer_or_Sub__c))
            {
                strStore = assignedStoreString.get(store.Installer_or_Sub__c);
            }
            else
            {
                strStore = new Set<String>();
            }
            strStore.add(store.Store__r.Name);
            assignedStoreString.put(store.Installer_or_Sub__r.id, strStore);   
            
        }
        System.debug(assignedStoreString);
        return(assignedStoreString);
    }
    
    public static Map<Id, Set<String>> getAssignedStoresByUsers(Map<Id, User> users) {
        if ((null == users) || users.size() == 0)
            return null;
        
        Map<Id,Id> userToContactIds = new Map<Id,Id>();
        for(Id usrid : users.keySet())
        {
            User usr = users.get(usrid);
            userToContactIds.put(usrid, usr.ContactId);
        }
        
        Map<Id, Assigned_Store__c> stores = new Map<Id, Assigned_Store__c>
            ([SELECT Id, Installer_or_Sub__r.Id, Store__c, Store__r.Name
              FROM Assigned_Store__c  
              WHERE Installer_or_Sub__c IN: userToContactIds.values()
              Order by Installer_or_Sub__r.Id, Store__r.Name]);
        
        Map<Id, Set<String>> assignedStoreString = new Map<Id, Set<String>>();
        
        for( Assigned_Store__c store : stores.values())
        {
            Set<String> strStore;
            if(assignedStoreString.containsKey(store.Installer_or_Sub__c))
            {
                strStore = assignedStoreString.get(store.Installer_or_Sub__c);
            }
            else
            {
                strStore = new Set<String>();
            }
            strStore.add(store.Store__c);
            assignedStoreString.put(store.Installer_or_Sub__r.id, strStore);   
            
        }
        System.debug(assignedStoreString);
        return(assignedStoreString);
    }
    
    @AuraEnabled
    public static List<manageUserContainer> getUserData() {
        List<manageUserContainer> userData = new List<manageUserContainer>();
        System.debug('getting users information');
        User user = getCurrentUser();
        Map<Id,User> usersForAccount = getUserMapByAccountId(user.accountId, user.Id);
        Map<Id, Set<String>> contactsAssignedStores = getAssignedStoresByUsers(usersForAccount);
        Map<Id, Set<String>> assignedToUser = getUsersAssignedStores(usersForAccount);
        System.debug(usersForAccount);
        System.debug(contactsAssignedStores);
        for( Id userId : usersForAccount.keySet() ){
            Boolean multipleStores = false;
            User u = usersForAccount.get(userId);
            Boolean isAdmin = hasSecondaryAdminPermission(userId);
            Boolean isInstaller = hasInstallerAdminPermission(userId);
            Set<String> assignedStores = contactsAssignedStores.get(u.ContactId);
            System.debug(assignedStores);
            if (assignedStores != null && assignedStores.size() > 1) {
                multipleStores = true;
            }
            Set<String> storeToUser = assignedToUser.get(u.ContactId);
            userData.add(new manageUserContainer(u, u.ContactId, u.AccountId, u.IsActive, isAdmin, isInstaller, assignedStores, storeToUser, multipleStores));
            
        }
        return userData;
    }
    
    
    @AuraEnabled
    public static List<manageUserContainer> getUsersList() {
        List<manageUserContainer> allUsersForVendorAccount = new List<manageUserContainer>();
        System.debug('getting user list');
        User user = getCurrentUser();
        Map<Id,User> usersForAccount = getUserMapByAccountId(user.accountId);
        Map<Id, Set<String>> contactsAssignedStores = getAssignedStoresByUsers(usersForAccount);
        Map<Id, Set<String>> assignedToUser = getUsersAssignedStores(usersForAccount);
        System.debug(usersForAccount);
        System.debug(contactsAssignedStores);
        for( Id userId : usersForAccount.keySet() ){
            Boolean multipleStores = false;
            User u = usersForAccount.get(userId);
            Boolean isAdmin = hasSecondaryAdminPermission(userId);
            Boolean isInstaller = hasInstallerAdminPermission(userId);
            Set<String> assignedStores = contactsAssignedStores.get(u.ContactId);
            System.debug(assignedStores);
            if (assignedStores != null && assignedStores.size() > 1) {
                multipleStores = true;
            }
            Set<String> storeToUser = assignedToUser.get(u.ContactId);
            allUsersForVendorAccount.add(new manageUserContainer(u, u.ContactId, u.AccountId, u.IsActive, isAdmin, isInstaller, assignedStores, storeToUser, multipleStores));
            
        }
        return allUsersForVendorAccount;
    }
    
    public class manageUserContainer {
        @AuraEnabled public User managedUser{get;set;}
        @AuraEnabled public Contact managedContact{get;set;}
        @AuraEnabled public Boolean isAdmin{get;set;}
        @AuraEnabled public Boolean isInstaller{get;set;}
        @AuraEnabled public Boolean isActive{get;set;}
        @AuraEnabled public Id contactId {get;set;}
        @AuraEnabled public Id accountId {get;set;}
        @AuraEnabled public String userJSON { get; set; }
        @AuraEnabled public List<String> assignedStoreIds {get;set;}
        @AuraEnabled public List<String> assignedStores {get;set;}
        @AuraEnabled public String accountFacsJSON {get;set;}
        @AuraEnabled public String assignedStoresJSON {get;set;}
        @AuraEnabled public Boolean multipleStores {get;set;}
        
        
        public manageUserContainer(User aUser, Id contactId, Id accountId, Boolean isActive, Boolean isAdmin, Boolean isInstaller, Set<String> assignedStoreIds, Set<String> assignedStores, Boolean multipleStores ) {
            this.managedUser = aUser;
            this.contactId = contactId;
            this.accountId = accountId;
            this.isActive = isActive;
            this.isAdmin = isAdmin;
            this.isInstaller = isInstaller;
            this.userJSON = JSON.serialize(aUser);
            this.assignedStores = new List<String>(assignedStores);
            this.assignedStoresJSON = JSON.serialize(this.assignedStores);
            this.assignedStoreIds = new List<String>(assignedStoreIds);
            this.multipleStores = multipleStores;
            
            
        }
        
        
        
    }
    
}