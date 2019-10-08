/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial prototype.
 * @updated 9/11/2019 - Added Errors to the SOAP response.
 * @updated 9/12/2019 - exposed Status field.
 *
 * @description Exposes the StoreData object for a SOAP request.  This is handed off to the StoreDataHandler's handle
 * method and a response is returned from the Service in the form of a List of mappings from SFID to StoreNumber along
 * with a List of Strings which are the errors returned by Salesforce on Upsert.
 */

global without sharing class StoreDataService {
    global class StoreData {
        webservice String storeNumber;
        webservice String storeName;

        webservice String street;
        webservice String city;
        webservice String state;
        webservice String country;
        webservice String zipCode;

        webservice String emailAddress;
        webservice String phoneNumber;
        webservice String faxNumber;

        webservice String region;
        webservice String division;
        webservice String timeZone;

        webservice String status;
    }

    global class StoreDataResponse {
        webservice String storeNumber;
        webservice String salesforceId;
        webservice List<String> errors;

        public StoreDataResponse(String storeNumber, String salesforceId) {
            this.storeNumber = storeNumber;
            this.salesforceId = salesforceId;
            errors = new List<String>();
        }

        public void addError(String error) {
            errors.add(error);
        }
    }

    webservice static List<StoreDataResponse> updateStoreData(List<StoreData> storeDetails) {
        return new StoreDataHandler().handle(storeDetails);
    }
}