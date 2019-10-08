/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial prototype.
 * @updated 9/11/2019 - Added Errors to the SOAP Response.
 * @updated 9/12/2019 - exposed Status field.
 *
 * @description Exposes the VendorData object for a SOAP request.  This is handed off to the VendorDataHandler's handle
 * method and a response is returned from the Service in the form of a List of mappings from SFID to VendorNumber along
 * with a List of Strings which are the errors returned by Salesforce on Upsert.
 */
global without sharing class VendorDataService {
    global class VendorData {
        webservice String vendorNumber;
        webservice String vendorName;

        webservice String street;
        webservice String city;
        webservice String state;
        webservice String country;
        webservice String zipCode;

        webservice String emailAddress;
        webservice String phoneNumber;
    }

    global class VendorDataResponse {
        webservice String vendorNumber;
        webservice String salesforceId;
        webservice List<String> errors;

        public VendorDataResponse(String vendorNumber, String salesforceId) {
            this.vendorNumber = vendorNumber;
            this.salesforceId = salesforceId;
            errors = new List<String>();
        }

        public void addError(String error) {
            errors.add(error);
        }
    }

    webservice static List<VendorDataResponse> updateVendorData(List<VendorData> vendorDetails) {
        return new VendorDataHandler().handle(vendorDetails);
    }
}