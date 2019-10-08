/**
 *  @description Test class to Unit Test the ServiceRequestTimeframeService class and the getServiceRequestResponses
 *  webservice.
 *  @author Andrew McGuiness - andrewmcguiness@rtslabs.com
 *  @date 9/27/2019
 */

@IsTest
private class ServiceRequestTimeframeTest {
    @TestSetup
    static void setupTestData() {
        ServiceRequest.Service_Request_Details srd = createServiceRequest();
        setupHeader(srd);
        setupNotes(srd, 1);
        setupMilestonesBlank(srd);
        setupCustomerInfo(srd);
        setupShipTo(srd);
        setupSalesOrder(srd);

        ServiceRequest.serviceRequest(srd);
    }


    @IsTest
    static void testEmpty() {
        Test.startTest();
        ServiceRequestTimeframeService.ServiceRequestDates srd = new ServiceRequestTimeframeService.ServiceRequestDates();
        srd.startDateTime = System.now().addMinutes(-60);
        srd.endDateTime = System.now().addMinutes(-55);

        ServiceRequestTimeframeService.ServiceRequestResponse results = ServiceRequestTimeframeService.getServiceRequestResponses(srd);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.updatedServiceRequestCount);
        System.assertEquals(1, results.errors.size());
    }

    @IsTest
    static void testOne() {
        Test.startTest();
        ServiceRequestTimeframeService.ServiceRequestDates srd = new ServiceRequestTimeframeService.ServiceRequestDates();
        srd.startDateTime = System.now().addMinutes(-5);
        srd.endDateTime = System.now().addMinutes(5);

        ServiceRequestTimeframeService.ServiceRequestResponse results = ServiceRequestTimeframeService.getServiceRequestResponses(srd);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.updatedServiceRequestCount);
        System.assertEquals(0, results.errors.size());
        System.assertEquals(results.updatedServiceRequestDates[0].serviceRequestNumber, [SELECT ServiceRequestNumber__c FROM Service_Request__c][0].ServiceRequestNumber__c);
    }


    @IsTest
    static void testMany() {
        {
            ServiceRequest.Service_Request_Details srd = createServiceRequest();
            setupHeader(srd);
            srd.Header.ServiceRequestNumber = '1002';
            setupNotes(srd, 1);
            setupMilestonesBlank(srd);
            setupCustomerInfo(srd);
            setupShipTo(srd);
            setupSalesOrder(srd);

            ServiceRequest.serviceRequest(srd);
        }


        Test.startTest();
        ServiceRequestTimeframeService.ServiceRequestDates srd = new ServiceRequestTimeframeService.ServiceRequestDates();
        srd.startDateTime = System.now().addMinutes(-5);
        srd.endDateTime = System.now().addMinutes(5);

        ServiceRequestTimeframeService.ServiceRequestResponse results = ServiceRequestTimeframeService.getServiceRequestResponses(srd);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(2, results.updatedServiceRequestCount);
        System.assertEquals(0, results.errors.size());
    }

    private static ServiceRequest.Service_Request_Details createServiceRequest() {
        ServiceRequest.Service_Request_Details srd = new ServiceRequest.Service_Request_Details();
        srd.Milestone_Dates = new ServiceRequest.Milestone_Date();
        srd.Ship_To_Address = new ServiceRequest.Ship_To_Address();
        srd.Sales_Order_Info = new List<ServiceRequest.Sales_Order_Info>();
        srd.Customer_Info = new ServiceRequest.Customer_Info();
        srd.Notes = new List<ServiceRequest.Note>();
        srd.Header = new ServiceRequest.Service_Request_Header();

        return srd;
    }

    private static void setupHeader(ServiceRequest.Service_Request_Details srd) {
        ServiceRequest.Service_Request_Header header = srd.Header;
        header.ServiceRequestNumber = '1001';
        header.Status = 'Active';
        header.CreationDate = Date.valueOf('2019-09-26');
        header.StoreNumber = '100';
        header.StoreZipCode = '23233';
        header.VendorNumber = '9999';
        header.JobScheduleDate = Date.valueOf('2019-09-26');
    }

    private static void setupNotes(ServiceRequest.Service_Request_Details srd, Integer count) {
        List<ServiceRequest.Note> nl = srd.Notes;

        for (Integer i = 0; i < count; i++) {
            ServiceRequest.Note sn = new ServiceRequest.Note();
            sn.noteDate = Date.valueOf('2019-09-26');
//            sn.noteTime = '13:45:05';
            sn.noteText = 'Hello, World! Test Note!';
            nl.add(sn);
        }
    }

    private static void setupMilestonesBlank(ServiceRequest.Service_Request_Details srd) {
        ServiceRequest.Milestone_Date md = srd.Milestone_Dates;
    }

    private static void setupMilestonesFilled(ServiceRequest.Service_Request_Details srd) {
        ServiceRequest.Milestone_Date md = srd.Milestone_Dates;

        md.MeasureRequestReceived = Date.valueOf('2019-09-26');
        md.MeasureRequestSent = Date.valueOf('2019-09-26');
        md.MeasureScheduled = Date.valueOf('2019-09-26');
        md.MeasurementsReceived = Date.valueOf('2019-09-26');
        md.QuoteBuilt = Date.valueOf('2019-09-26');
        md.InstallationSold = Date.valueOf('2019-09-26');
        md.ThankYouCall = Date.valueOf('2019-09-26');
        md.InstallationPaperworkSent = Date.valueOf('2019-09-26');
        md.InstallationScheduled = Date.valueOf('2019-09-26');
        md.EstimatedCompletion = Date.valueOf('2019-09-26');
        md.Pre_CallMade = Date.valueOf('2019-09-26');
        md.InstallationCompleted = Date.valueOf('2019-09-26');
        md.Post_CallMade = Date.valueOf('2019-09-26');
        md.PGI_Invoiced = Date.valueOf('2019-09-26');
        md.Cancellation = Date.valueOf('2019-09-26');
    }

    private static void setupCustomerInfo(ServiceRequest.Service_Request_Details srd) {
        ServiceRequest.Customer_Info ci = srd.Customer_Info;
        ci.CustomerNumber = '99';
        ci.CustomerName = 'Test Person';
        ci.Street = '1234 Fake Street';
        ci.City = 'Richmond';
        ci.State = 'VA';
        ci.Country = 'US';
        ci.ZipCode = '23233';
        ci.Phone = '8045555555';
    }

    private static void setupShipTo(ServiceRequest.Service_Request_Details srd) {
        ServiceRequest.Ship_To_Address sa = srd.Ship_To_Address;
        sa.ShipToStreet = '1212 Fake Street';
        sa.ShipToCity = 'Henrico';
        sa.ShipToState = 'VA';
        sa.ShipToCountry = 'US';
        sa.ShipToZipCode = '24060';
    }

    private static void setupSalesOrder(ServiceRequest.Service_Request_Details srd) {
        List<ServiceRequest.Sales_Order_Info> soi = srd.Sales_Order_Info;

        ServiceRequest.Sales_Order_Info so = new ServiceRequest.Sales_Order_Info();
        so.OrderNumber = '2222';
        so.OrderDate = Date.valueOf('2019-09-26');
        so.OrderType = 'Install';

        soi.add(so);
    }
}