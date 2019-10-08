/**
 * @author Andrew McGuiness - andrew.mcguiness@rtslabs.com
 * @date  9/05/2019
 * @description
 */

public with sharing class ServiceRequestHandler {
    private Validator validator;

    private HeaderHandler headerHandler;
    private NoteHandler noteHandler;
    private MilestoneDatesHandler milestoneDatesHandler;
    private CustomerInfoHandler customerHandler;
    private ShipToAddressHandler shipToAddressHandler;
    private SalesOrderInfoHandler salesOrderInfoHandler;

    public ServiceRequestHandler() {
        validator = new Validator();

        headerHandler = new HeaderHandler();
        noteHandler = new NoteHandler();
        milestoneDatesHandler = new MilestoneDatesHandler();
        customerHandler = new CustomerInfoHandler();
        shipToAddressHandler = new ShipToAddressHandler();
        salesOrderInfoHandler = new SalesOrderInfoHandler();
    }

    public Boolean process(ServiceRequest.Service_Request_Details requestDetails, List<String> log) {
        Boolean success = false;

        if (requestDetails != null && validator.validateServiceRequest(requestDetails, log)) {
            try {
                Id request = buildServiceRequest(requestDetails);
                log.add('Created or Updated Service_Request__c: ' + request);
                success = true;
            } catch (DmlException e) {
                log.add('Failed to create Service_Request__c: ' + e.getMessage());
                success = false;
            }
        } else {
            log.add('Failed to create Service_Request__c');
            success = false;
        }

        return success;
    }


    private Id buildServiceRequest(ServiceRequest.Service_Request_Details requestDetails) {
        // Data stored on the Service Request
        Service_Request__c serviceRequest = findOrCreateServiceRequest(requestDetails);

        headerHandler.handle(requestDetails.Header, serviceRequest);

        if (requestDetails.Milestone_Dates != null) {
            milestoneDatesHandler.handle(requestDetails.Milestone_Dates, serviceRequest);
        }

        // Insert or Update the customer then attach lookup
        serviceRequest.Customer__c = customerHandler.handle(requestDetails.Customer_Info);

        if (requestDetails.Ship_To_Address != null) {
            shipToAddressHandler.handle(requestDetails.Ship_To_Address, serviceRequest);
        }

        upsert serviceRequest;

        // Require Id for the Service Request
        if (requestDetails.Notes != null && requestDetails.Notes.size() > 0) {
            noteHandler.handle(requestDetails.Notes, serviceRequest);
        }

        // Require Id for the Service Request
        if (requestDetails.Sales_Order_Info != null && requestDetails.Sales_Order_Info.size() > 0) {
            salesOrderInfoHandler.handle(requestDetails.Sales_Order_Info, serviceRequest);
        }


        return serviceRequest.Id;
    }

    private Service_Request__c findOrCreateServiceRequest(ServiceRequest.Service_Request_Details requestDetails) {
        Service_Request__c serviceRequest = null;
        List<Service_Request__c> serviceRequests = [
                SELECT Id
                FROM Service_Request__c
                WHERE ServiceRequestNumber__c = :requestDetails.Header.ServiceRequestNumber
        ];

        if (serviceRequests.size() > 0 && serviceRequests[0] != null) {
            serviceRequest = serviceRequests[0];
        } else {
            serviceRequest = new Service_Request__c();
        }
        return serviceRequest;
    }


    private class HeaderHandler {
        private void handle(ServiceRequest.Service_Request_Header header, Service_Request__c serviceRequest) {
            serviceRequest.ServiceRequestNumber__c = header.ServiceRequestNumber;
            serviceRequest.Status__c = header.Status;
            serviceRequest.CreationDate__c = header.CreationDate;

            // Link the ServiceRequest to a Store based on StoreNumber
            if (!String.isBlank(header.StoreNumber)) {
                List<Store__c> stores = [SELECT Id FROM Store__c WHERE Store_Number__c = :header.StoreNumber];
                if (stores.size() > 0 && stores[0] != null) {
                    serviceRequest.Store__c = stores[0].Id;
                }
            }

            // Link the ServiceRequest to a Vendor based on the VendorNumber
            if (!String.isBlank(header.VendorNumber)) {
                List<Account> vendors = [SELECT Id FROM Account WHERE VendorNumber__c = :header.VendorNumber];
                if (vendors.size() > 0 && vendors[0] != null) {
                    serviceRequest.Vendor__c = vendors[0].Id;
                }
            }

            if (header.JobScheduleDate != null) {
                serviceRequest.JobScheduleDate__c = header.JobScheduleDate;
            }
        }
    }

    private class NoteHandler {
        private void handle(List<ServiceRequest.Note> srNotes, Service_Request__c serviceRequest) {
            deleteOldNotes(serviceRequest);
            List<ContentNote> newNotes = insertNewNotes(srNotes);
            insertDocumentLinks(newNotes, serviceRequest);
        }

        private void insertDocumentLinks(List<ContentNote> newNotes, Service_Request__c serviceRequest) {
            List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
            for (ContentNote contentNote : newNotes) {
                documentLinks.add(new ContentDocumentLink(
                        ContentDocumentId = contentNote.Id,
                        LinkedEntityId = serviceRequest.Id,
                        ShareType = 'I',
                        Visibility = 'AllUsers'
                ));
            }
            Database.insert(documentLinks);
        }

        private List<ContentNote> insertNewNotes(List<ServiceRequest.Note> srNotes) {
            List<ContentNote> newNotes = new List<ContentNote>();
            for (ServiceRequest.Note srNote : srNotes) {
                ContentNote newNote = new ContentNote(
                        Title = 'Note: ' + srNote.noteDate + ' : ' + srNote.noteTime,
                        Content = Blob.valueOf(srNote.noteText.escapeHtml4())
                );

                newNotes.add(newNote);
            }
            Database.insert(newNotes);
            return newNotes;
        }

        private void deleteOldNotes(Service_Request__c serviceRequest) {
            List<ContentNote> allNotes = [SELECT Id, Title FROM ContentNote WHERE Id IN :getDocumentIds(serviceRequest)];
            List<ContentNote> oldNotes = new List<ContentNote>();
            for (ContentNote note : allNotes) {
                if (!String.isBlank(note.Title) && note.Title.startsWith('Note: ')) {
                    oldNotes.add(note);
                }
            }
            Database.delete(oldNotes);
        }


        private Set<Id> getDocumentIds(Service_Request__c serviceRequest) {
            List<ContentDocumentLink> currentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :serviceRequest.Id];
            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink cdl : currentDocumentLinks) {
                documentIds.add(cdl.ContentDocumentId);
            }
            return documentIds;
        }
    }

    private class MilestoneDatesHandler {
        private void handle(ServiceRequest.Milestone_Date milestoneDates, Service_Request__c serviceRequest) {
            if (milestoneDates.MeasureRequestReceived != null) {
                serviceRequest.MeasureRequestReceived__c = milestoneDates.MeasureRequestReceived;
            }

            if (milestoneDates.MeasureRequestSent != null) {
                serviceRequest.MeasureRequestSent__c = milestoneDates.MeasureRequestSent;
            }

            if (milestoneDates.MeasureScheduled != null) {
                serviceRequest.Measure_Scheduled__c = milestoneDates.MeasureScheduled;
            }

            if (milestoneDates.MeasurementsReceived != null) {
                serviceRequest.MeasurementsReceived__c = milestoneDates.MeasurementsReceived;
            }

            if (milestoneDates.QuoteBuilt != null) {
                serviceRequest.QuoteBuilt__c = milestoneDates.QuoteBuilt;
            }

            if (milestoneDates.InstallationSold != null) {
                serviceRequest.InstallationSold__c = milestoneDates.InstallationSold;
            }

            if (milestoneDates.ThankYouCall != null) {
                serviceRequest.ThankYouCall__c = milestoneDates.ThankYouCall;
            }

            if (milestoneDates.InstallationPaperworkSent != null) {
                serviceRequest.InstallationPaperworkSent__c = milestoneDates.InstallationPaperworkSent;
            }

            if (milestoneDates.InstallationScheduled != null) {
                serviceRequest.Installation_Scheduled__c = milestoneDates.InstallationScheduled;
            }

            if (milestoneDates.EstimatedCompletion != null) {
                serviceRequest.Estimated_Completion__c = milestoneDates.EstimatedCompletion;
            }

            if (milestoneDates.Pre_CallMade != null) {
                serviceRequest.Pre_CallMade__c = milestoneDates.Pre_CallMade;
            }

            if (milestoneDates.InstallationCompleted != null) {
                serviceRequest.Installation_Completed__c = milestoneDates.InstallationCompleted;
            }

            if (milestoneDates.Post_CallMade != null) {
                serviceRequest.Post_CallMade__c = milestoneDates.Post_CallMade;
            }

            if (milestoneDates.PGI_Invoiced != null) {
                serviceRequest.PGI_Invoiced__c = milestoneDates.PGI_Invoiced;
            }

            if (milestoneDates.Cancellation != null) {
                serviceRequest.Cancellation__c = milestoneDates.Cancellation;
            }
        }
    }

    private class CustomerInfoHandler {
        private Id handle(ServiceRequest.Customer_Info customerInfo) {
            Contact customer = findOrCreateCustomer(customerInfo);
            populateCustomerInfo(customer, customerInfo);

            upsert customer;
            return customer.Id;
        }

        private Contact findOrCreateCustomer(ServiceRequest.Customer_Info customerInfo) {
            List<Contact> customers = [
                    SELECT Id
                    FROM Contact
                    WHERE Customer_Number__c = :customerInfo.CustomerNumber
            ];

            Contact customer = null;
            if (customers.size() > 0 && customers[0] != null) {
                customer = customers[0];
            } else {
                customer = new Contact();
            }
            return customer;
        }

        private void populateCustomerInfo(Contact customer, ServiceRequest.Customer_Info customerInfo) {
            customer.Customer_Number__c = customerInfo.CustomerNumber;
            customer.MailingStreet = customerInfo.Street;
            customer.MailingCity = customerInfo.City;
            customer.MailingState = customerInfo.State;
            customer.MailingCountry = customerInfo.Country;
            customer.MailingPostalCode = customerInfo.ZipCode;
            customer.Phone = customerInfo.Phone;

            // Handle parse the name (Assume that the name is coming as a single field, splits it based on white space)
            List<String> names = customerInfo.CustomerName.split('\\s+');
            if (names.size() == 1) {
                customer.LastName = names[0];
            } else {
                customer.FirstName = names[0];
                customer.LastName = names[names.size() - 1];
            }
        }
    }

    private class ShipToAddressHandler {
        private void handle(ServiceRequest.Ship_To_Address shipToAddress, Service_Request__c serviceRequest) {
            if (!String.isBlank(shipToAddress.ShipToStreet)) {
                serviceRequest.ShipToStreet__c = shipToAddress.ShipToStreet;
            }

            if (!String.isBlank(shipToAddress.ShipToCity)) {
                serviceRequest.ShipToCity__c = shipToAddress.ShipToCity;
            }

            if (!String.isBlank(shipToAddress.ShipToState)) {
                serviceRequest.ShipToState__c = shipToAddress.ShipToState;
            }

            if (!String.isBlank(shipToAddress.ShipToCountry)) {
                serviceRequest.ShipToCountry__c = shipToAddress.ShipToCountry;
            }

            if (!String.isBlank(shipToAddress.ShipToZipCode)) {
                serviceRequest.ShipToZipCode__c = shipToAddress.ShipToZipCode;
            }
        }
    }

    private class SalesOrderInfoHandler {
        private void handle(List<ServiceRequest.Sales_Order_Info> salesOrderInfos, Service_Request__c serviceRequest) {
            Id installOrderRecordId = SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName().get('Install_Order').getRecordTypeId();
            Id measureOrderRecordId = SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName().get('Measure_Order').getRecordTypeId();

            List<Sales_Order__c> salesOrders = [SELECT Id, SalesOrderNumber__c FROM Sales_Order__c WHERE Service_Request__c = :serviceRequest.Id];
            List<Sales_Order__c> updatedAndNewOrders = new List<Sales_Order__c>();

            for (ServiceRequest.Sales_Order_Info srSalesOrderInfo : salesOrderInfos) {
                Sales_Order__c orderInfo = findOrCreateSalesOrder(salesOrders, srSalesOrderInfo.OrderNumber);

                orderInfo.OrderDate__c = srSalesOrderInfo.OrderDate;
                orderInfo.OrderType__c = srSalesOrderInfo.OrderType;
                orderInfo.Service_Request__c = serviceRequest.Id;

                if (srSalesOrderInfo.OrderType.containsIgnoreCase('install')) {
                    orderInfo.RecordTypeId = installOrderRecordId;
                } else if (srSalesOrderInfo.OrderType.containsIgnoreCase('measure')) {
                    orderInfo.RecordTypeId = measureOrderRecordId;
                }


                updatedAndNewOrders.add(orderInfo);
            }

            upsert updatedAndNewOrders;
        }

        private Sales_Order__c findOrCreateSalesOrder(List<Sales_Order__c> salesOrders, String orderNumber) {
            for (Sales_Order__c order : salesOrders) {
                if (order.SalesOrderNumber__c.equals(orderNumber)) {
                    return order;
                }
            }

            return new Sales_Order__c(SalesOrderNumber__c = orderNumber);
        }
    }

    private class Validator {
        private Boolean validateServiceRequest(ServiceRequest.Service_Request_Details requestDetails, List<String> log) {
            Boolean requestValid = true;

            if (requestDetails == null || !requestDetails.Header.isValid()) {
                log.add('Header failed to validate');
                requestValid = false;
            }

            if (requestDetails == null || !requestDetails.Customer_Info.isValid()) {
                log.add('Customer info failed to validate');
                requestValid = false;
            }

            if (!salesOrdersValid(requestDetails.Sales_Order_Info, log)) {
                requestValid = false;
            }


            return requestValid;
        }

        private Boolean salesOrdersValid(List<ServiceRequest.Sales_Order_Info> salesOrderInfos, List<String> log) {
            // Required size of 1 from LL Specs
            Boolean salesOrderInfoValid = salesOrderInfos != null;

            if (salesOrderInfoValid) {
                if (salesOrderInfos.size() < 1) {
                    salesOrderInfoValid = false;
                    log.add('Sales Order Info has a size of 0');
                }


                // Check each Sales Order Info Record is valid
                for (Integer i = 0; i < salesOrderInfos.size(); i++) {
                    if (!salesOrderInfos[i].isValid()) {
                        log.add('Sales Order Info [' + i + '] failed to validate.');
                        salesOrderInfoValid = false;
                    }
                }
            }


            return salesOrderInfoValid;
        }
    }
}