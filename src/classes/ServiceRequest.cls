/**
 *  @description SOAP Webservice to handle ServiceRequests submitted from LumberLiquidators' SAP.
 *  @author Andrew McGuiness - andrewmcguiness@rtslabs.com
 *  @date 9/6/2019
 */

global without sharing class ServiceRequest {
    global class Service_Request_Details {
        webservice Service_Request_Header Header;
        webservice List<Note> Notes;
        webservice Milestone_Date Milestone_Dates;
        webservice Customer_Info Customer_Info;
        webservice Ship_To_Address Ship_To_Address;
        webservice List<Sales_Order_Info> Sales_Order_Info;
    }

    global class Service_Request_Header {
        webservice String ServiceRequestNumber; // Mandatory
        webservice String Status;               // Mandatory
        webservice Date CreationDate;          // Mandatory

        webservice String StoreNumber;
        webservice String StoreZipCode;
        webservice String VendorNumber;
        webservice Date JobScheduleDate;

        public Boolean isValid() {
            return !String.isBlank(ServiceRequestNumber) &&
                    !String.isBlank(Status) &&
                    CreationDate != null;
        }
    }

    global class Note {
        webservice Date noteDate;
        webservice Time noteTime;
        webservice String noteUser;
        webservice String noteText;

        public Note() {
            this.noteDate = null;
            this.noteTime = null;
            this.noteUser = null;
            this.noteText = null;
        }
    }

    global class Milestone_Date {
        webservice Date MeasureRequestReceived;
        webservice Date MeasureRequestSent;
        webservice Date MeasureScheduled;
        webservice Date MeasurementsReceived;
        webservice Date QuoteBuilt;
        webservice Date InstallationSold;
        webservice Date ThankYouCall;
        webservice Date InstallationPaperworkSent;
        webservice Date InstallationScheduled;
        webservice Date EstimatedCompletion;
        webservice Date Pre_CallMade;
        webservice Date InstallationCompleted;
        webservice Date Post_CallMade;
        webservice Date PGI_Invoiced;
        webservice Date Cancellation;
    }

    global class Customer_Info {
        webservice String CustomerNumber;   // Mandatory
        webservice String CustomerName;     // Mandatory
        webservice String Street;           // Mandatory
        webservice String City;             // Mandatory
        webservice String State;            // Mandatory
        webservice String Country;          // Mandatory
        webservice String ZipCode;          // Mandatory

        webservice String Phone;

        public Boolean isValid() {
            return !String.isBlank(CustomerNumber) &&
                    !String.isBlank(CustomerName) &&
                    !String.isBlank(Street) &&
                    !String.isBlank(City) &&
                    !String.isBlank(State) &&
                    !String.isBlank(Country) &&
                    !String.isBlank(ZipCode);
        }
    }

    global class Ship_To_Address {
        webservice String ShipToStreet;
        webservice String ShipToCity;
        webservice String ShipToState;
        webservice String ShipToCountry;
        webservice String ShipToZipCode;
    }

    global class Sales_Order_Info {
        webservice String OrderNumber;      // Mandatory
        webservice Date OrderDate;        // Mandatory
        webservice String OrderType;        // Mandatory

        public Boolean isValid() {
            return !String.isBlank(OrderNumber) &&
                    OrderDate != null &&
                    !String.isBlank(OrderType);
        }
    }

    webservice static String serviceRequest(Service_Request_Details Service_Request_Detail) {
        String results = '';

        List<String> log = new List<String>();
        ServiceRequestHandler srh = new ServiceRequestHandler();

        if (srh.process(Service_Request_Detail, log)) {
            results = 'Success:\n';
        } else {
            results = 'Error:\n';
        }

        for (String s : log) {
            results += s + '\n';
        }

        return results;
    }
}