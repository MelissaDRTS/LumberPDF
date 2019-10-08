/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial Prototype
 * @updated 9/11/2019 - Hardening of the API and added Error handling. Errors are returned in the response.
 * @updated 9/12/2019 - Added Status handling logic for Stores.
 *
 * @description Handler for the StoreDataService.  This handler accepts a list of StoreData detail objects and parses
 * them into Store__c objects for upsert.  No direct validation is performed, instead errors are returned as a list
 * of Strings in the StoreDataResponse objects returned by the handle method.
 */

public without sharing class StoreDataHandler {
    public List<StoreDataService.StoreDataResponse> handle(List<StoreDataService.StoreData> storeDetails) {
        Map<String, Store__c> storeNumberMapping = getStoreMappingByNumber(storeDetails);
        updateOrCreateStoreData(storeDetails, storeNumberMapping);

        List<Database.UpsertResult> upsertResults = Database.upsert(storeNumberMapping.values(), false);

        List<Store__c> retryStores = addPlaceholderData(storeNumberMapping.values(), upsertResults);
        List<Database.UpsertResult> retryResults = Database.upsert(retryStores, false);

        return createResponseList(storeNumberMapping.values(), storeDetails, upsertResults, retryResults);
    }


    private void updateOrCreateStoreData(List<StoreDataService.StoreData> storeDetails, Map<String, Store__c> storeNumberMapping) {
        for (StoreDataService.StoreData sd : storeDetails) {
            Store__c currentStore = storeNumberMapping.get(sd.storeNumber);

            if (currentStore == null) {
                currentStore = new Store__c();
                storeNumberMapping.put(sd.storeNumber, currentStore);
            }

            currentStore.Store_Number__c = sd.storeNumber;
            currentStore.Name = sd.storeName;

            currentStore.Street__c = sd.street;
            currentStore.City__c = sd.city;
            currentStore.State__c = sd.state;
            currentStore.Country__c = sd.country;
            currentStore.Zip_Code__c = sd.zipCode;

            currentStore.Email_Address__c = sd.emailAddress;
            currentStore.Phone__c = sd.phoneNumber;
            currentStore.Fax__c = sd.faxNumber;

            currentStore.Region__c = sd.region;
            currentStore.Division__c = sd.division;

            // TODO: Convert to a TimeZone.  LL is sending a String in the fomrmat of "America/New_York"
            currentStore.Time_Zone__c = sd.timeZone;

            if (!String.isBlank(sd.status) && sd.status.equalsIgnoreCase('Inactive')) {
                currentStore.Status__c = 'Inactive';
            } else {
                currentStore.Status__c = 'Active';
            }
        }
    }

    private List<StoreDataService.StoreDataResponse> createResponseList(
            List<Store__c> storeNumberMapping,
            List<StoreDataService.StoreData> storeDetails,
            List<Database.UpsertResult> upsertResults,
            List<Database.upsertResult> retryResults
    ) {
        List<StoreDataService.StoreDataResponse> responses = new List<StoreDataService.StoreDataResponse>();

        Integer j = 0;
        for (Integer i = 0; i < storeNumberMapping.size(); i++) {
            Store__c store = storeNumberMapping.get(i);

            for (StoreDataService.StoreData sd : storeDetails) {
                if (sd.storeNumber.equals(store.Store_Number__c)) {
                    StoreDataService.StoreDataResponse response = new StoreDataService.StoreDataResponse(store.Store_Number__c, store.Id);
                    Database.UpsertResult sr = upsertResults.get(i);

                    if(sr == null){
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

    private Map<String, Store__c> getStoreMappingByNumber(List<StoreDataService.StoreData> storeDetails) {
        Map<String, Store__c> storeNumberMapping = new Map<String, Store__c>();
        for (StoreDataService.StoreData sd : storeDetails) {
            if (sd == null || String.isBlank(sd.storeNumber)) continue;

            storeNumberMapping.put(sd.storeNumber, null);
        }

        List<Store__c> currentStores = [
                SELECT Id, Store_Number__c
                FROM Store__c
                WHERE Store_Number__c IN :storeNumberMapping.keySet()
        ];

        for (Store__c oldStore : currentStores) {
            if (oldStore == null || String.isBlank(oldStore.Store_Number__c)) continue;

            storeNumberMapping.put(oldStore.Store_Number__c, oldStore);
        }
        return storeNumberMapping;
    }

    /**
     * Parse a list of upsertResults to find any that failed due to EmailAddress or PhoneNumber errors.
     *
     * @param stores List of upserted Store__c's
     * @param upsertResults List of upsertResults from the first upsert Attempt.
     *
     */
    private List<Store__c> addPlaceholderData(List<Store__c> stores, List<Database.UpsertResult> upsertResults) {
        List<Store__c> storesToRetry = new List<Store__c>();

        for (Integer i = 0; i < stores.size(); i++) {
            Store__c store = stores.get(i);
            Database.UpsertResult upsertResult = upsertResults.get(i);

            if (!upsertResult.isSuccess()) {
                if (emailAddressFailed(upsertResult)) {
                    replaceEmailAddress(store);
                }

                if (phoneNumberFailed(upsertResult)) {
                    replacePhoneNumber(store);
                }

                storesToRetry.add(store);
                upsertResults.set(i, null);
            }
        }

        return storesToRetry;
    }

    /**
     * Test an Store__c's upsertResult to see if it failed because of a bad Email Address.
     *
     * @param upsertResult Results of the Store__c's upsert
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
     *  Replace the Email Address on a Store__c with a placeholder.
     *
     * @param vendor Store__c to change.
     */
    private void replaceEmailAddress(Store__c vendor) {
        vendor.Email_Address__c = null;
    }

    /**
     * Test an Store__c's upsertResult to see if it failed because of a bad Phone Number.
     *
     * @param upsertResult Results of the Store__c's upsert
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
     * Replace the Phone Number on a Store__c with a placeholder.
     *
     * @param vendor Store__c to change.
     */
    private void replacePhoneNumber(Store__c vendor) {
        vendor.Phone__c = '';
    }
}