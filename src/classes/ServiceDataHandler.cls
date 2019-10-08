/**
 * Created by melissaderricott on 9/23/19.
 */

public without sharing class ServiceDataHandler {
    public List <ServiceRequestTimeframeService.ServiceRequestUpdatedDates> handle(ServiceRequestTimeframeService.ServiceRequestDates timeFrame, List<String> errorLog) {
        List<Service_Request__c> serviceRequestsList;

        try {
            serviceRequestsList = getServiceRequests(timeFrame.startDateTime, timeFrame.endDateTime);
        } catch (Exception e) {
            errorLog.add('Exception: ' + e.getMessage());
        }

        List <ServiceRequestTimeframeService.ServiceRequestUpdatedDates> results = new List<ServiceRequestTimeframeService.ServiceRequestUpdatedDates>();
        if (serviceRequestsList == null) {
            errorLog.add('Failed to retrieve metadata for Service_Request__c');
        } else if (serviceRequestsList.size() == 0) {
            errorLog.add('No results for specified timeframe.');
        } else {
            createResponse(serviceRequestsList, results, errorLog);
        }

        return results;
    }


    private List<Service_Request__c> getServiceRequests(Datetime startDatetime, Datetime endDatetime) {

        Datetime dtStart = startDatetime.addHours(4);
        Datetime dtEnd = endDatetime.addHours(4);


        return [
                SELECT
                        Id,
                        ServiceRequestNumber__c,
                        Measure_Scheduled__c,
                        Installation_Scheduled__c,
                        Estimated_Completion__c,
                        Installation_Completed__c,
                        SystemModStamp
                FROM
                        Service_Request__c
                WHERE
                SystemModstamp >= :dtStart
                AND
                SystemModstamp <= :dtEnd
        ];

    }


    private void createResponse(List<Service_Request__c> serviceRequestsList, List <ServiceRequestTimeframeService.ServiceRequestUpdatedDates> results, List<String> errorLog) {
        for (Service_Request__c sr : serviceRequestsList) {
            try {
                ServiceRequestTimeframeService.ServiceRequestUpdatedDates response = new ServiceRequestTimeframeService.ServiceRequestUpdatedDates();

                response.serviceRequestNumber = sr.ServiceRequestNumber__c;
                response.measureSchedule = sr.Measure_Scheduled__c;
                response.installationScheduled = sr.Installation_Completed__c;
                response.estimationCompleted = sr.Estimated_Completion__c;
                response.installationCompleted = sr.Installation_Completed__c;

                results.add(response);
            } catch (Exception e) {
                errorLog.add('Exception: ' + e.getMessage());
            }

        }
    }
}