/**
 * @author Andrew McGuiness - andrew.mcguiness@rtslabs.com
 * @date  9/10/2019
 * @description
 */

global without sharing class DocumentService {
    global class WorkDocumentTimeFrame {
        webservice Datetime startTime;
        webService Datetime endTime;
    }

    global class WorkDocument {
        webservice String serviceRequestId;
        webservice String name;
        webservice String documentType;
        webService String fileType;
        webservice Blob data;

    }

    webservice static List<WorkDocument> getNewServiceDocuments(WorkDocumentTimeFrame timeFrame) {
        return new DocumentServiceHandler().handleGetDocuments(timeFrame.startTime, timeFrame.endTime);
    }
}