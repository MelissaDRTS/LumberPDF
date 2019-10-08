/**
 * @author Andrew McGuiness - andrew.mcguiness@rtslabs.com
 * @date  9/10/2019
 * @description
 */
public with sharing class DocumentServiceHandler {

    /**
     * Get a List of WorkDocuments that have been updated within the given interval.
     *
     * @param startTime Start of the update interval.
     * @param endTime   End of the update interval.
     *
     * @return  List of WorkDocuments.
     */
    public List<DocumentService.WorkDocument> handleGetDocuments(Datetime startTime, Datetime endTime) {
        List<ContentVersion> contentVersions = getContentVersions(startTime, endTime);
        return getDocuments(contentVersions);
    }

    /**
     * Query Salesforce for all new ContectVersions
     *
     * @param startTime Start time of the query interval.
     * @param endTime   End time of the query interval.
     *
     * @return
     */
    private List<ContentVersion> getContentVersions(Datetime startTime, Datetime endTime) {
        Datetime tzStarTime = startTime.addHours(4);
        Datetime tzEndTime = endTime.addHours(4);


        return [
                SELECT Id, Title, FileType, VersionData
                FROM ContentVersion
                WHERE LastModifiedDate >= :tzStarTime AND LastModifiedDate <= :tzEndTime
        ];
    }


    /**
     * Convert list of ContentVersions into WorkDocument's for SOAP Push.
     *
     * @param contentVersions   ContentVersion of documents in Salesforce to convert.
     *
     * @return  List of WorkDocuments.
     */
    private List<DocumentService.WorkDocument> getDocuments(List<ContentVersion> contentVersions) {
        List<DocumentService.WorkDocument> workDocuments = new List<DocumentService.WorkDocument>();
        for (ContentVersion contentVersion : contentVersions) {
            DocumentService.WorkDocument workDocument = convertContentVersionToWorkDocument(contentVersion);
            if (workDocument != null) {
                workDocuments.add(workDocument);
            }
        }
        return workDocuments;
    }

    /**
     * Convert a single ContentVersion into a WorkDocument.  This assume the Title is in
     * the following format: WD_userEnteredTitle_DocumentType_ServiceRequestNum.extension.
     *
     * @param contentVersion    ContentVersion to be convert.
     *
     * @return  A WorkDocument containing the information from the ContentVersion
     */
    private DocumentService.WorkDocument convertContentVersionToWorkDocument(ContentVersion contentVersion) {
        DocumentService.WorkDocument workDocument = null;

        String documentTitle = contentVersion.Title;
        if (!String.isBlank(documentTitle) && documentTitle.startsWithIgnoreCase('WD_')) {
            workDocument = new DocumentService.WorkDocument();
            workDocument.serviceRequestId = ParsingHelper.parseServiceNumber(documentTitle);
            workDocument.name = contentVersion.Title;
            workDocument.documentType = ParsingHelper.parseDocumentType(documentTitle);
            workDocument.fileType = contentVersion.FileType;
            workDocument.data = contentVersion.VersionData;
        }

        return workDocument;
    }


}