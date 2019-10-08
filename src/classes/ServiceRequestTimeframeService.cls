/**
 * Created by melissaderricott on 9/23/19.
 */

global without sharing class ServiceRequestTimeframeService {
    global class ServiceRequestDates {
        webservice Datetime startDateTime;
        webservice Datetime endDateTime;
    }

    global class ServiceRequestUpdatedDates {
        webservice String serviceRequestNumber;
        webservice Date measureSchedule;
        webservice Date installationScheduled;
        webservice Date estimationCompleted;
        webservice Date installationCompleted;
    }

    global class ServiceRequestResponse {
        webservice Integer updatedServiceRequestCount;
        webservice List<ServiceRequestUpdatedDates> updatedServiceRequestDates;
        webservice List<String> errors;
    }


    webservice static ServiceRequestResponse getServiceRequestResponses(ServiceRequestDates timeFrame) {
        ServiceDataHandler handler = new ServiceDataHandler();

        ServiceRequestResponse srr = new ServiceRequestResponse();

        srr.errors = new List<String>();
        srr.updatedServiceRequestDates = handler.handle(timeFrame, srr.errors);

        srr.updatedServiceRequestCount = srr.updatedServiceRequestDates.size();

        return srr;
    }
}