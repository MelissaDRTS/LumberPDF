/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial Prototype
 * @updated 9/11/2019 - Hardening of the API and added Error handling. Errors are returned in the response.
 * @updated 9/12/2019 - Added Status handling logic for Vendors.
 *
 * @description Handler for the VendorDataService.  This handler accepts a list of VendorData detail objects and parses
 * them into Account objects for upsert.  No direct validation is performed, instead errors are returned as a list
 * of Strings in the VendorDataResponse objects returned by the handle method.
 */
public with sharing class VendorDataHandler {
    private static final String COMMUNITY_PROFILE = 'Installer Community Plus User';
    private static final String COMMUNITY_PERMISSION_SET = 'Installer_Primary_Admin_Portal_Permissions';
    private static final String USERNAME_SUFFIX = '.SOAPSERV';

    public List<VendorDataService.VendorDataResponse> handle(List<VendorDataService.VendorData> vendorDetails) {


        Map<String, Account> vendorNumberMapping = getVendorMappingByNumber(vendorDetails);
        Map<String, List<String>> errorMapping = generateErrorMapping(vendorNumberMapping.keySet());

        updateOrCreateVendorAccount(vendorDetails, vendorNumberMapping, errorMapping);

        List<Database.UpsertResult> upsertResults = Database.upsert(vendorNumberMapping.values(), false);

        List<Account> retryAccounts = addPlaceholderData(vendorNumberMapping.values(), upsertResults);
        List<Database.UpsertResult> retryResults = Database.upsert(retryAccounts, false);

//        VendorDataHandler.handleCreateCommunityUsers(vendorNumberMapping.keySet());

        List<VendorDataService.VendorDataResponse> responses = createResponseList(vendorNumberMapping.values(), vendorDetails, upsertResults, retryResults);
        for (VendorDataService.VendorDataResponse response : responses) {
            String output = 'VN=<' + response.vendorNumber + '>; SFID=<' + response.salesforceId + '>; errors=' + response.errors.size();

            if (response.errors.size() > 0) {
                output += ' [';
                for (String error : response.errors) {
                    output += '\"' + error + '\",';
                }
                output += ']';
            }

            output += ' exceptions=' + errorMapping.get(response.vendorNumber).size();
            if (errorMapping.get(response.vendorNumber).size() > 0) {
                output += ' [';
                for (String error : errorMapping.get(response.vendorNumber)) {
                    output += '\"' + error + '\",';
                }
                output += ']';
            }

            System.debug(output);
        }
        return responses;
    }

    /**
     * Generate a new Mapping of error messages for this batch of Vendors.
     *
     * @param vendorNumberSet   Batch of vendors
     *
     * @return Mapping of a VendorNumber to a list of strings.
     */
    private Map<String, List<String>> generateErrorMapping(Set<String> vendorNumberSet) {
        Map<String, List<String>> errorMapping = new Map<String, List<String>>();
        for (String vendorNumber : vendorNumberSet) {
            errorMapping.put(vendorNumber, new List<String>());
        }
        return errorMapping;
    }


//    public static void handleCreateCommunityUsers(Set<String> vendorNumbers) {
//        createOrUpdateContacts(vendorNumbers);
//        createOrUpdateUsersForVendors(vendorNumbers);
//    }


    private void updateOrCreateVendorAccount(List<VendorDataService.VendorData> vendorDetails, Map<String, Account> vendorNumberMapping, Map<String, List<String>> errorMapping) {
        for (VendorDataService.VendorData vd : vendorDetails) {
            try {
                Account currentVendor = vendorNumberMapping.get(vd.vendorNumber);

                if (currentVendor == null) {
                    currentVendor = new Account();
                    vendorNumberMapping.put(vd.vendorNumber, currentVendor);
                }

                currentVendor.VendorNumber__c = vd.vendorNumber;
                currentVendor.Name = vd.vendorName;

                currentVendor.Street__c = vd.street;
                currentVendor.City__c = vd.city;
                currentVendor.State__c = vd.state;
                currentVendor.Country__c = vd.country;
                currentVendor.Zip__c = vd.zipCode;

                currentVendor.EmailAddress__c = vd.emailAddress;
                currentVendor.Phone = vd.phoneNumber;

//                if (!String.isBlank(vd.status) && vd.status.equalsIgnoreCase('Inactive')) {
//                    currentVendor.Status__c = 'Inactive';
//                } else {
//                    currentVendor.Status__c = 'Active';
//                }
            } catch (Exception e) {
                errorMapping.get(vd.vendorNumber).add(
                        vd.vendorNumber + ': Could not create corresponding Account. <' + e.getMessage() + '>.'
                );
            }
        }
    }

    private List<VendorDataService.VendorDataResponse> createResponseList(
            List<Account> vendorNumberMapping,
            List<VendorDataService.VendorData> vendorDetails,
            List<Database.upsertResult> upsertResults,
            List<Database.upsertResult> retryResults
    ) {
        List<VendorDataService.VendorDataResponse> responses = new List<VendorDataService.VendorDataResponse>();

        Integer j = 0;
        for (Integer i = 0; i < vendorNumberMapping.size(); i++) {
            Account vendor = vendorNumberMapping.get(i);

            for (VendorDataService.VendorData vd : vendorDetails) {
                if (vd.vendorNumber.equals(vendor.VendorNumber__c)) {
                    VendorDataService.VendorDataResponse response = new VendorDataService.VendorDataResponse(vendor.VendorNumber__c, vendor.Id);
                    Database.upsertResult sr = upsertResults.get(i);

                    if (sr == null) {
                        sr = retryResults.get(j++);
                    }

                    if (!sr.isSuccess()) {
                        for (Database.Error error : sr.getErrors()) {
                            response.addError(error.getStatusCode() + ': ' + error.getMessage());
                        }
                    }

                    responses.add(response);
                    break;
                }
            }
        }
        return responses;
    }

    private Map<String, Account> getVendorMappingByNumber(List<VendorDataService.VendorData> vendorDetails) {
        Map<String, Account> vendorNumberMapping = new Map<String, Account>();
        for (VendorDataService.VendorData vd : vendorDetails) {
            if (vd == null || String.isBlank(vd.vendorNumber)) continue;

            vendorNumberMapping.put(vd.vendorNumber, null);
        }

        List<Account> currentVendors = [
                SELECT Id, VendorNumber__c
                FROM Account
                WHERE VendorNumber__c IN :vendorNumberMapping.keySet()
        ];

        for (Account oldVendor : currentVendors) {
            if (oldVendor == null || String.isBlank(oldVendor.VendorNumber__c)) continue;

            vendorNumberMapping.put(oldVendor.VendorNumber__c, oldVendor);
        }
        return vendorNumberMapping;
    }

    /**
     * Parse a list of upsertResults to find any that failed due to EmailAddress or PhoneNumber errors.
     *
     * @param vendors List of upserted Vendors
     * @param upsertResults List of upsertResults from the first upsert Attempt.
     *
     */
    private List<Account> addPlaceholderData(List<Account> vendors, List<Database.UpsertResult> upsertResults) {
        List<Account> vendorsToRetry = new List<Account>();

        for (Integer i = 0; i < vendors.size(); i++) {
            Account vendor = vendors.get(i);
            Database.UpsertResult upsertResult = upsertResults.get(i);

            if (!upsertResult.isSuccess()) {
                if (emailAddressFailed(upsertResult)) {
                    replaceEmailAddress(vendor);
                }

                if (phoneNumberFailed(upsertResult)) {
                    replacePhoneNumber(vendor);
                }

                vendorsToRetry.add(vendor);
                upsertResults.set(i, null);
            }
        }

        return vendorsToRetry;
    }

    /**
     * Test an Account's upsertResult to see if it failed because of a bad Email Address.
     *
     * @param upsertResult Results of the Account's upsert
     *
     * @return Was there an Email Address validation error?
     */
    private Boolean emailAddressFailed(Database.UpsertResult upsertResult) {
        for (Database.Error error : upsertResult.getErrors()) {
            if (error.statusCode == StatusCode.INVALID_EMAIL_ADDRESS) {
                return true;
            }
        }

        return false;
    }

    /**
     *  Replace the Email Address on a Vendor with a placeholder.
     *
     * @param vendor Account to change.
     */
    private void replaceEmailAddress(Account vendor) {
        vendor.EmailAddress__c = null;
    }

    /**
     * Test an Account's upsertResult to see if it failed because of a bad Phone Number.
     *
     * @param upsertResult Results of the Account's upsert
     *
     * @return Was there a Phone number validation error?
     */
    private Boolean phoneNumberFailed(Database.UpsertResult upsertResult) {
        for (Database.Error error : upsertResult.getErrors()) {
            if (error.statusCode.equals('INVALID_PHONE_NUMBER')) {
                return true;
            }
        }

        return false;
    }

    /**
     * Replace the Phone Number on a Vendor with a placeholder.
     *
     * @param vendor Account to change.
     */
    private void replacePhoneNumber(Account vendor) {
        vendor.Phone = '';
    }
//
//    @Future
//    private static void createOrUpdateContacts(Set<String> vendorNumbers) {
//        List<Account> vendorAccounts = [
//                SELECT Id, Name, VendorNumber__c, Street__c, City__c, State__c, Country__c, Zip__c, Phone, EmailAddress__c, Status__c
//                FROM Account
//                WHERE VendorNumber__c IN :vendorNumbers AND VendorNumber__c != null
//        ];
//
//        List<Contact> existingContacts = [
//                SELECT Id, Vendor_Number__c
//                FROM Contact
//                WHERE Vendor_Number__c IN :vendorNumbers AND Vendor_Number__c != null
//        ];
//
//        List<Contact> vendorContacts = new List<Contact>();
//        for (Account vendor : vendorAccounts) {
//            Contact contact = findOrCreateContact(vendor.VendorNumber__c, existingContacts);
//
//            copyDataToContact(vendor, contact);
//            vendorContacts.add(contact);
//        }
//
//        List<Database.UpsertResult> results = Database.upsert(vendorContacts, false);
//        for (Integer i = 0; i < results.size(); i++) {
//            Database.UpsertResult result = results.get(i);
//            if (!result.isSuccess()) {
//                for (Database.Error error : result.errors) {
//                    System.debug(error.statusCode + ': ' + error.getMessage());
//                }
//            }
//        }
//    }

//
//    private static void copyDataToContact(Account vendorAccount, Contact vendorContact) {
//        vendorContact.AccountId = vendorAccount.Id;
//
//        vendorContact.LastName = vendorAccount.Name;
//        vendorContact.Vendor_Number__c = vendorAccount.VendorNumber__c;
//
//        vendorContact.MailingStreet = vendorAccount.Street__c;
//        vendorContact.MailingCity = vendorAccount.City__c;
//        vendorContact.MailingState = vendorAccount.State__c;
//        vendorContact.MailingCountry = vendorAccount.Country__c;
//        vendorContact.MailingPostalCode = vendorAccount.Zip__c;
//
//        vendorContact.Phone = vendorAccount.Phone;
//        vendorContact.Email = vendorAccount.EmailAddress__c;
//
//        vendorContact.Status__c = vendorAccount.Status__c;
//    }

//
//    /**
//     * Find or create a new contact based on the Vendor's Vendor Number
//     *
//     * @param vendorNumber      Vendor Number to use to find the Contact.
//     * @param existingContacts  List of current Contacts
//     *
//     * @return  Existing or new Contact.
//     */
//    private static Contact findOrCreateContact(String vendorNumber, List<Contact> existingContacts) {
//        if (String.isBlank(vendorNumber)) {
//            throw new DmlException('Vendor Number is blank or null');
//        }
//
//        Contact contact = null;
//        for (Contact existingContact : existingContacts) {
//            if (!String.IsBlank(existingContact.Vendor_Number__c) && existingContact.Vendor_Number__c.equalsIgnoreCase(vendorNumber)) {
//                contact = existingContact;
//                break;
//            }
//        }
//
//        if (contact == null) {
//            contact = new Contact();
//        }
//
//        return contact;
//    }
//
//    /**
//     * Find or create a new User for all Vendor Contacts.
//     *
//     * @param vendorNumber          Vendor Number to use for the matching
//     * @param existingUsers         List of User currently in the system
//     * @param communityProfileId    The ProfileId that should be used for New Users
//     *
//     * @return                      Newly created or Newly updated User, needs to be upserted.
//     */
//    private static User findOrCreateUser(String vendorNumber, List<User> existingUsers, Id communityProfileId) {
//        if (String.isBlank(vendorNumber)) {
//            throw new DmlException('Vendor Number is blank or null');
//        }
//
//        User vendorUser = null;
//
//        for (User user : existingUsers) {
//            if (!String.IsBlank(user.Vendor_Number__c) && user.Vendor_Number__c.equalsIgnoreCase(vendorNumber)) {
//                vendorUser = user;
//                break;
//            }
//        }
//
//        return vendorUser;
//    }
//
//    /**
//     * Create or Update Users based on a Vendor's Contact.  All created users will be assigned the Community ProfileId
//     * and PermissionSet
//     *
//     * @param vendorContacts List of Vendor Contacts that have been created or updated.
//     *
//     * @return List of All Users that have been modified/created.
//     */
//    @Future
//    private static void createOrUpdateUsersForVendors(Set<String> vendorNumbers) {
//        List<Contact> vendorContacts = [
//                SELECT LastName, Email, Id, Vendor_Number__c, Status__c
//                FROM Contact
//                WHERE Vendor_Number__c IN :vendorNumbers AND Vendor_Number__c != null
//        ];
//
//        // Cache the Id for the PermissionSet and Profile for Users
//        Id communityPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :COMMUNITY_PERMISSION_SET LIMIT 1].Id;
//        Id communityProfileId = [SELECT Id FROM Profile WHERE Name = :COMMUNITY_PROFILE LIMIT 1].Id;
//
//        // Grab all Current Users in the system
//        List<User> allUsers = [SELECT Id, Vendor_Number__c FROM User];
//
//        // Create a mapping of Current or New Users to Vendor Number
//        Map<String, User> userMapping = new Map<String, User>();
//        for (Contact vendorContact : vendorContacts) {
//            if (!String.isBlank(vendorContact.Email)) {
//                User vendorUser = findOrCreateUser(vendorContact.Vendor_Number__c, allUsers, communityProfileId);
//
//                if (vendorUser == null) {
//                    vendorUser = createNewUser(vendorContact, communityProfileId);
//                } else {
//                    updateUser(vendorUser, vendorContact);
//                }
//
//                if (vendorContact.Status__c.equalsIgnoreCase('Inactive')) {
//                    vendorUser.IsActive = false;
//                } else {
//                    vendorUser.IsActive = true;
//                }
//
//                userMapping.put(vendorContact.Vendor_Number__c, vendorUser);
//            }
//        }
//
//        List<Database.UpsertResult> results = Database.upsert(userMapping.values(), false);
//        for (Integer i = 0; i < results.size(); i++) {
//            Database.UpsertResult result = results.get(i);
//            if (!result.isSuccess()) {
//                for (Database.Error error : result.errors) {
//                    System.debug(error.statusCode + ': ' + error.getMessage());
//                }
//            }
//        }
//
//
//        // Call an @future method to create the PermissionSetAssignments, will only accept Id's
//        Set<Id> userIds = new Set<Id>();
//        for (User u : userMapping.values()) {
//            userIds.add(u.Id);
//        }
//        createPermissionAssignmentsForVendors(userIds, communityPermissionSetId);
//    }
//
//
//    /**
//     * Create PermissionSetAssignments for new Users if one doesn't currently exist in the system.
//     *
//     * @param newVendorUsers            Set of Id's for all NEW users
//     * @param communityPermissionSetId  The ID of the PermissionSet to be assigned.
//     */
//    public static void createPermissionAssignmentsForVendors(Set<Id> newVendorUsers, Id communityPermissionSetId) {
//        // Fetch all PermissionSetAssignments in the system
//        List<PermissionSetAssignment> permissionSetsAssignments = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment];
//        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
//
//        for (Id newUser : newVendorUsers) {
//            PermissionSetAssignment psa = null;
//
//            // Try to find a matching PermissionSetAssignment
//            for (PermissionSetAssignment current : permissionSetsAssignments) {
//                if (current.AssigneeId == newUser && current.PermissionSetId == communityPermissionSetId) {
//                    psa = current;
//                    break;
//                }
//            }
//
//            // Create a new PermissionSetAssignment if one doesn't exist
//            if (psa == null) {
//                newAssignments.add(new PermissionSetAssignment(
//                        AssigneeId = newUser,
//                        PermissionSetId = communityPermissionSetId
//                ));
//            }
//        }
//
//        // Insert all the newly Created PermissionSetAssignments
//        if (newAssignments.size() > 0) {
//            insert newAssignments;
//        }
//    }
//
//    /**
//     * Create a New User based on data that exists on a Vendor's Contact.
//     *
//     * @param vendorContact         Contact that represents the Vendor.
//     * @param communityProfileId    ID for the Profile to assign to the new User
//     *
//     * @return  The create User, is hasn't been inserted yet.
//     */
//    private static User createNewUser(Contact vendorContact, Id communityProfileId) {
//        String vendorAlias = vendorContact.Email.toLowerCase().substring(0, Math.min(8, vendorContact.Email.lastIndexOf('@')));
//        String vendorUsername = vendorContact.Email;
//
//        return new User(
//                LastName = vendorContact.LastName,
//                Alias = vendorAlias,
//                Email = vendorContact.Email,
//                Username = vendorUsername + USERNAME_SUFFIX,
//                CommunityNickname = vendorContact.Email,
//                LocaleSidKey = 'en_US',
//                TimeZoneSidKey = 'America/New_York',
//                ProfileId = communityProfileId,
//                LanguageLocaleKey = 'en_US',
//                EmailEncodingKey = 'UTF-8',
//                ContactId = vendorContact.Id,
//                Vendor_Number__c = vendorContact.Vendor_Number__c
//        );
//    }
//
//    /**
//     * Update aan Existing User with data from a Vendor Contact.
//     *
//     * @param vendorUser    Existing User that needs to be updated.
//     * @param vendorContact Existing Contact to pull the data from.
//     */
//    private static void updateUser(User vendorUser, Contact vendorContact) {
//        String vendorAlias = vendorContact.Email.toLowerCase().substring(0, Math.min(8, vendorContact.Email.lastIndexOf('@')));
//
//        vendorUser.LastName = vendorContact.LastName;
//        vendorUser.Alias = vendorAlias;
//        vendorUser.Email = vendorContact.Email;
//        vendorUser.ContactId = vendorContact.Id;
//    }
}