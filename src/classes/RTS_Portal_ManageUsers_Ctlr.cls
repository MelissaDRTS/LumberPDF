/*
* Author: Alicia Chafee, RTS Labs.
* Date: 08/2019
* Description: This class is the controller for the RTS_Portal_EditUser_Cmp and the RTS_Portal_NewUser_Cmp. 
* 				It handles the insert and update of new contacts, and new portal users and their associated permission sets.
* 
* 
*/



public without sharing class RTS_Portal_ManageUsers_Ctlr {
    
    @TestVisible private static String INSTALLER_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Primary_Admin_Portal_Permissions';
    @TestVisible private static String SECONDARY_ADMIN_PERMISSION_SET_API_NAME = 'Installer_Secondary_Admin_Portal_Permissions';
    @TestVisible private static String SUB_PERMISSION_SET_API_NAME = 'Subcontractor_Portal_Permissions';
    
    private static final String INSTALLER_COMMUNITY_USER_PROFILE_NAME = 'Installer Community Plus User';
    private static final String SUBCONTRACTOR_COMMUNITY_USER_PROFILE_NAME = 'Subcontractor Community Plus User';
    
    private static Map<String,Id> permissionSetIdsByName;
    private static Map<Id,PermissionSetAssignment> userPermissionSetAssignmentsByPermissionId;
    
    public static void addPermissionSet(Id userId, String permissionName) {
        if (!hasPermissionSet(userId, permissionName) && permissionSetIdsByName.containsKey(permissionName)) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = permissionSetIdsByName.get(permissionName),
                AssigneeId = userId
            );
            insert psa;
        }
    }
    
    public static void addPermissionSet(Map<Id, Set<String>> userIdToPermissionNameMap) {
        System.debug('rts permission set');
        List<PermissionSetAssignment> psasToInsert = new List<PermissionSetAssignment>();
        for(Id userId :userIdToPermissionNameMap.keySet()){
            Set<String> permissionNames = userIdToPermissionNameMap.get(userId);
            for(String permissionName :permissionNames){
                if (!hasPermissionSet(userId, permissionName) && permissionSetIdsByName.containsKey(permissionName)) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(
                        PermissionSetId = permissionSetIdsByName.get(permissionName),
                        AssigneeId = userId
                    );
                    psasToInsert.add(psa);
                }
            }
        }
        if(psasToInsert.size() > 0){
            System.debug(psasToInsert);
            insert psasToInsert;
        }
    }
    
    public static void removePermissionSet(Id userId, String permissionName) {
        if (hasPermissionSet(userId, permissionName) && permissionSetIdsByName.containsKey(permissionName)) {
            Id permissionSetId = permissionSetIdsByName.get(permissionName);
            if (permissionSetId != null) {
                delete userPermissionSetAssignmentsByPermissionId.get(permissionSetId);
            }
        }
    }
    
    
    
    public static Boolean hasPermissionSet(Id userId, String permissionName) {
        Boolean hasPermissionSet = false;
        
        if (permissionSetIdsByName == null || userPermissionSetAssignmentsByPermissionId == null) {
            resetUserPermissionVariables(userId);
        }
        
        Id permissionId = permissionSetIdsByName.get(permissionName);
        if (permissionId != null) {
            hasPermissionSet = userPermissionSetAssignmentsByPermissionId.containsKey(permissionId);
        }
        return hasPermissionSet;
    }
    
    public static void resetUserPermissionVariables(Id userId) {
        setPermissionSetMap();
        setAllUserPermissionAssignments(userId);
    }
    
    private static void setPermissionSetMap() {
        permissionSetIdsByName = new Map<String, Id>();
        
        List<PermissionSet> permissionSets = [
            SELECT Id, Name
            FROM PermissionSet
        ];
        for (PermissionSet ps : permissionSets) {
            permissionSetIdsByName.put(ps.Name, ps.Id);
        }
    }
    
    private static void setAllUserPermissionAssignments(Id userId) {
        userPermissionSetAssignmentsByPermissionId = new Map<Id,PermissionSetAssignment>();
        
        List<PermissionSetAssignment> permissionAssignments  = [
            SELECT PermissionSetId, AssigneeId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
        ];
        for (PermissionSetAssignment psa : permissionAssignments) {
            userPermissionSetAssignmentsByPermissionId.put(psa.PermissionSetId, psa);
        }
    }
    
    public static Id getInstallerPortalUserProfileId() {
        Profile profiles = [
            SELECT Id
            FROM Profile
            WHERE Name = :INSTALLER_COMMUNITY_USER_PROFILE_NAME LIMIT 1
        ];
        
        return profiles.Id;
    }
    
    public static Id getSubcontractorPortalUserProfileId() {
        Profile profiles = [
            SELECT Id
            FROM Profile
            WHERE Name = :SUBCONTRACTOR_COMMUNITY_USER_PROFILE_NAME LIMIT 1
        ];
        
        return profiles.Id;
    }
    
    @AuraEnabled
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
            List<User> users = [
                SELECT Id, Name, Email, ContactId, AccountId, LanguageLocaleKey, Account.OwnerId,
                EmailEncodingKey, LocaleSidKey, TimeZoneSidKey, FirstName, LastName, Phone, MobilePhone
                FROM User
                WHERE Id =: userId
            ];
            
            if(users.size() == 1) {
                u = users[0];
            }
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
    
    @AuraEnabled
    public static Boolean hasSubcontractorPermission() {
        User currentUser = getCurrentUser();
        List<PermissionSetAssignment> psas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUser.Id
        ];
        
        PermissionSet subcontractorPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :SUB_PERMISSION_SET_API_NAME
        ];
        
        List<String> permissionSetIds = new List<String>();
        
        for( PermissionSetAssignment psa : psas ){
            permissionSetIds.add( psa.PermissionSetId );
        }
        
        return permissionSetIds.contains(String.valueOf(subcontractorPermission.Id));
    }
    
    public static List<User> userExists(String username) {
        List<User> users = [
            SELECT Id, IsActive
            FROM User
            WHERE Username = :username
        ];
        
        return users;
    }
    
    
    public static List<User> userExists(String username, String userId) {
        List<User> users = [
            SELECT Id
            FROM User
            WHERE Username = :username
            AND Id != :userId
        ];
        
        return users;
    }
    
    
    @AuraEnabled
    public static String usernameAvailable(String username) {
        List<User> u = userExists(username);
        if (u.size() > 0) {
            if (u.size() > 1) {
                return 'contact lumber';
            } else {
                User comUser = u.get(0);
                if (comUser.IsActive == false) {
                    String userId = comUser.Id;
                    return 'inactive user:' + userId;
                } else {
                    return 'contact lumber';
                }
            }
        } else {
            return 'available';
        }
        
    }
    
    @AuraEnabled
    public static Boolean existingUsernameAvailable(String username, String userId) {
        System.debug('checking username');
        List<User> u = userExists(username, userId);
        if (u.size() > 0) {
            return false;
        } else {
            return true;
        }
        
    }
    
    @AuraEnabled
    public static List<String> getSpecialtyOptions() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Specialties__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug(ple);
        
        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getValue());
        }
        System.debug(options);
        return options;
        
    }
    
    
    
    @AuraEnabled
    public static UserForm getUserToReassign(String userId) {
        User u = [SELECT Id, FirstName, LastName, Email, Phone, ContactId FROM User WHERE Id = :userId LIMIT 1];
        Contact c = [SELECT Id, Specialties__c FROM Contact WHERE Id = :u.ContactId];
        System.debug(u.ContactId);
        List<Assigned_Store__c> stores = [SELECT Id, Store__c, Store__r.Name, Installer_or_Sub__c FROM Assigned_Store__c WHERE Installer_or_Sub__c = :u.ContactId];
        Boolean isAdmin = hasSecondaryAdminPermission(u.Id);
        List<String> assignedStores = new List<String>();
        List<String> specialties = new List<String>();
        if (c.Specialties__c != null) {
            String sp = c.Specialties__c;
        specialties = sp.split(';');
        }
        
        System.debug(specialties);
        System.debug(stores);
        if(stores.size() > 0) {
            for(Assigned_Store__c store : stores) {
                System.debug(store.Store__r.Name);
                assignedStores.add(store.Store__c);
            }
        }
        
        System.debug(assignedStores);
        UserForm userToReassign = new UserForm(u.FirstName, u.LastName, u.Email, u.Phone, isAdmin, specialties, assignedStores);
        return userToReassign;
        
    }
    
    @AuraEnabled
    public static List<Store__c> getAssignedStores() {
        User u = getCurrentUser();
        List<Store__c> stores = new List<Store__c>();
        List<Service_Request__c> sr = [SELECT Id, Name, Store__c FROM Service_Request__c WHERE Vendor__c = :u.AccountId];
        System.debug(sr);
        Set<Id> accIds = new Set<Id>();
        for (Service_Request__c req : sr) {
            accIds.add(req.Store__c);
        }
        
        stores = [SELECT Id, Name FROM Store__c WHERE Id IN :accIds];
        System.debug(stores);
        return stores;
    }
    
    @AuraEnabled
    public static UserForm provisionNewContact(String userFormJSON) {
        System.debug('creating new contact');
        System.debug(userFormJSON);
        UserForm form = (UserForm) JSON.deserialize(userFormJSON, UserForm.class);
        
        if (form.isValid()) {
            try {
                form.createPortalContact();
                System.debug(form.contactId);
            }
            catch (Exception e) {
                throw new AuraHandledException('Error creating new contact. ' + e.getMessage());
            }
            System.debug(form);
            return form;
            
        } else {
            UserForm blankForm = new UserForm();
            return blankForm;
        }
    }
    
    @AuraEnabled
    public static UserForm updateContact(String userFormJSON) {
        UserForm form = (UserForm) JSON.deserialize(userFormJSON, UserForm.class);
        UserForm returnForm;
        System.debug('update contact form');
        System.debug(form);
        if (form.isValid()) {
            try {
                form.updatePortalContact();
                returnForm = form;
            }
            catch(Exception e) {
                System.debug('failed to update contact');
                System.debug(e.getMessage());
                
            }
        }
        return returnForm;
        
        
    }
    
    @AuraEnabled
    public static User provisionNewUser(String userForm) {
        Boolean success = false;
        UserForm form = (UserForm) JSON.deserialize(userForm, UserForm.class);
        User newUser;
        
        if (form.isValid() && form.contactId != null) {
            System.debug('new user form is valid: ' + form.isValid());
            Savepoint sp = Database.setSavepoint();
            
            try {
                newUser = form.createPortalUser();
            }
            catch(Exception e) {
                System.debug(e.getMessage());
                Database.rollback(sp);
            }
            success = newUser != null && newUser.Id != null;
        }
        
        if (!success) {
            delete new Contact(Id = form.contactId);
        }
        System.debug('SUCCESS : ' + success);
        return newUser;
    }
    
    
    @AuraEnabled
    public static Boolean updateUser(String userFormJSON) {
        UserForm form = (UserForm) JSON.deserialize(userFormJSON, UserForm.class);
        System.debug('update user form');
        System.debug(form);
        if (form.isValid()) {
            Savepoint sp = Database.setSavepoint();
            try {
                form.updatePortalUser();
            }
            catch(Exception e) {
                System.debug('failed to update user');
                System.debug(e.getMessage());
                Database.rollback(sp);
                return false;
            }
        }
        
        return true;
    }
    
    public static void deleteAssignedStores(Id contactId)
    {
        List<Assigned_Store__c> deleteStores = [
            SELECT Installer_or_Sub__c 
            FROM Assigned_Store__c
            WHERE Installer_or_Sub__c =: contactId
        ];
        
        if (0 < deleteStores.size())
        {
            try
            {
                delete deleteStores;
            }
            catch(Exception e)
            {
                System.debug('failed to delete assigned stores');
                system.debug('Exception: ' + e.getMessage());
            }
            
        }
        
    }
    
    public static String format(Set<String> values) {
        if (values == null) return null;
        List<String> l = new List<String>(values);
        l.sort();
        return format(l);
    }
    
    public static String format(List<String> values) {
        if (values == null) return null;
        return String.join(values, ';');
    }
    
    public static Id getSubcontractorRecordType() {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Subcontractor').getRecordTypeId();
        return recordTypeId;
    }
    
    
    public class UserForm {
        @AuraEnabled public Id userId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String confirmationEmail { get; set; }
        @AuraEnabled public String phoneNumber { get; set; }
        @AuraEnabled public Boolean isSecondaryAdmin { get; set; }
        @AuraEnabled public Boolean isActive {get;set;}
        @AuraEnabled public List<String> assignedStores { get; set; }
        @AuraEnabled public List<String> specialties {get;set;}
        
        public UserForm() {
            
        }
        
        public UserForm(String firstName, String lastName, String email, String phoneNumber, Boolean isAdmin, List<String> specialties, List<String> assignedStores) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.phoneNumber = phoneNumber;
            this.isSecondaryAdmin = isAdmin;
            this.specialties = specialties;
            this.assignedStores = assignedStores;
            
        }
        
        public Boolean isValid() {
            sanitize();
            
            Boolean valid = true;
            valid = valid && this.firstName != null;
            valid = valid && this.lastName != null;
            valid = valid && this.email != null;
            valid = valid && this.confirmationEmail != null;
            valid = valid && this.phoneNumber != null;
            valid = valid && this.email == this.confirmationEmail;
            
            System.debug('form valid: ' + valid);
            return valid;
        }
        
        public void sanitize() {
            this.firstName = this.firstName.stripHtmlTags();
            this.lastName = this.lastName.stripHtmlTags();
            this.email = this.email.stripHtmlTags();
            this.confirmationEmail = this.confirmationEmail.stripHtmlTags();
            
        }
        
        private String generateAlias() {
            Integer lastLength = (this.lastName.length() > 4 ? 4 : this.lastName.length());
            return this.firstName.substring(0, 1) + this.lastName.substring(0, lastLength);
        }
        
        private String generateUsername() {
            String generatedUsername = this.firstName.left(1) + this.lastName + this.phoneNumber.right(4) + '@llportal.com';
            System.debug(generatedUsername);
            return generatedUsername;
        }
        
        private Contact createPortalContact() {
            User currentUser = getCurrentUser();
            Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Subcontractor').getRecordTypeId();
            
            Contact newContact = new Contact(
                
                FirstName = this.firstName,
                LastName = this.lastName,
                Email = this.email,
                Phone = this.phoneNumber,
                AccountId = currentUser.AccountId,
                OwnerId = currentUser.Account.OwnerId,
                Specialties__c = format(this.specialties),
                RecordTypeId = getSubcontractorRecordType()
                
            );
            
            System.debug(newContact);
            try {
                insert newContact;
            } catch(DmlException  e) {
                System.debug('failed to enter new user');
                System.debug(e.getMessage());
                
            }
            
            
            this.contactId = newContact.Id;
            System.debug(newContact.Id);
            updateAssignedStores(newContact.Id);
            return newContact;
        }
        
        private User createPortalUser() {
            User currentUser = getCurrentUser();
            System.debug(currentUser);
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = true;
            Id profile;
            if(this.isSecondaryAdmin) {
                profile = getInstallerPortalUserProfileId();
            } else {
                profile = getSubcontractorPortalUserProfileId();
            }
            
            User newUser = new User(
                ProfileId = profile,
                Alias = generateAlias(),
                EmailEncodingKey = currentUser.EmailEncodingKey,
                LanguageLocaleKey = currentUser.LanguageLocaleKey,
                LocaleSidKey = currentUser.LocaleSidKey,
                TimeZoneSidKey = currentUser.TimeZoneSidKey,
                ContactId = this.contactId,
                FirstName = this.firstName,
                LastName = this.lastName,
                Phone = this.phoneNumber,
                Email = this.email,
                CommunityNickname = this.email,
                Username = generateUsername()
                
                
            );
            
            
            newUser.setOptions(dmo);
            
            System.debug('trying to enter new user');
            insert newUser;
            
            
            if (newUser.Id != null) {
                if (this.isSecondaryAdmin) {
                    addPermissionSet(newUser.Id, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
                }
                else {
                    addPermissionSet(newUser.Id, SUB_PERMISSION_SET_API_NAME);
                    
                }
            } 
            return newUser;
        }
        
        
        private void updatePortalContact() {
            System.debug('updating contact');
            User currentUser = getCurrentUser();
            User userToUpdate = [SELECT Id, ContactId FROM User WHERE Id = :this.userId LIMIT 1];
            System.debug(userToUpdate);
            
            Contact contactToUpdate = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, Specialties__c, RecordTypeId FROM Contact WHERE Id = :userToUpdate.ContactId LIMIT 1];
            System.debug(contactToUpdate);
            contactToUpdate.AccountId = currentUser.AccountId;
            contactToUpdate.FirstName = this.firstName;
            contactToUpdate.LastName = this.lastName;
            contactToUpdate.Email = this.email;
            contactToUpdate.Phone = this.phoneNumber;
            contactToUpdate.Specialties__c = format(this.specialties);
            contactToUpdate.RecordTypeId = getSubcontractorRecordType();
            
            update contactToUpdate;  
            
            updateAssignedStores(userToUpdate.ContactId);
        }
        
        private void updatePortalUser() {
            User userToUpdate = [SELECT Id, Alias, FirstName, LastName, Phone, Email, CommunityNickname, IsActive FROM User WHERE Id = :this.userId LIMIT 1];
            Boolean alreadyActive = userToUpdate.IsActive;
            userToUpdate.Alias = generateAlias();
            userToUpdate.FirstName = this.firstName;
            userToUpdate.LastName = this.lastName;
            userToUpdate.Phone = this.phoneNumber;
            userToUpdate.Email = this.email;
            userToUpdate.CommunityNickname = this.email;
            userToUpdate.IsActive = this.isActive;
            
            if (alreadyActive) {
                
                if (this.isSecondaryAdmin) {
                    addPermissionSet(this.userId, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
                    removePermissionSet(this.userId, SUB_PERMISSION_SET_API_NAME);
                    userToUpdate.ProfileId = getInstallerPortalUserProfileId();
                }
                else {
                    removePermissionSet(this.userId, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
                    addPermissionSet(this.userId, SUB_PERMISSION_SET_API_NAME);
                    userToUpdate.ProfileId = getSubcontractorPortalUserProfileId();
                }
                update userToUpdate;
            } else {
                System.debug('user is not active');
                System.debug(this.isActive);
                
                update userToUpdate;
                if (this.isSecondaryAdmin) {
                    addPermissionSet(this.userId, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
                    removePermissionSet(this.userId, SUB_PERMISSION_SET_API_NAME);
                    
                }
                else {
                    removePermissionSet(this.userId, SECONDARY_ADMIN_PERMISSION_SET_API_NAME);
                    addPermissionSet(this.userId, SUB_PERMISSION_SET_API_NAME);
                    
                }
            }
            
            
            
            
            
        }
        
        private void updateAssignedStores(Id conId) {
            deleteAssignedStores(conId);
            
            List<Assigned_Store__c> assignStores = new List<Assigned_Store__c>();
            for(String storeId : this.assignedStores) {
                assignStores.add(new Assigned_Store__c(Installer_or_Sub__c = conId, Store__c = storeId));
            }
            insert assignStores;
            
        }
        
        
        
    }   
    
}