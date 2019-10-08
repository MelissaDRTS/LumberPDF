/**
 * @author Andrew McGuiness - andrew.mcguiness@rtslabs.com
 * @date  9/10/2019
 * @description
 */
@IsTest
private class DocumentServiceTest {
    @IsTest
    static void testEmpty() {
        Test.startTest();
        DocumentService.WorkDocumentTimeFrame timeFrame = new DocumentService.WorkDocumentTimeFrame();
        timeFrame.startTime = System.now().addMinutes(-15);
        timeFrame.endTime = System.now();

        List<DocumentService.WorkDocument> serviceDocuments = DocumentService.getNewServiceDocuments(timeFrame);
        Test.stopTest();

        System.assertNotEquals(null, serviceDocuments);
        System.assertEquals(0, serviceDocuments.size());
    }

    @IsTest
    static void testFetch() {
        Account testAccount = new Account(
                Name = 'Test Account'
        );
        insert testAccount;

        // Test Document WITH the proper formatting.
        ContentVersion testVersion = new ContentVersion(
                Title = 'WD_User Named Document_install_1234',
                PathOnClient = 'C:\\TEST_TEST\\THIS IS A TEST.pdf',
                VersionData = Blob.valueOf('Hello World')
        );
        insert testVersion;

        // Test Document without the proper formatting.
        ContentVersion testVersion2 = new ContentVersion(
                Title = 'Test without cool format',
                PathOnClient = 'C:\\TEST_TEST\\THIS IS A TEST.pdf',
                VersionData = Blob.valueOf('Hello World')
        );
        insert testVersion2;

        Test.startTest();
        DocumentService.WorkDocumentTimeFrame timeFrame = new DocumentService.WorkDocumentTimeFrame();
        timeFrame.startTime = System.now().addMinutes(-15);
        timeFrame.endTime = System.now();

        List<DocumentService.WorkDocument> serviceDocuments = DocumentService.getNewServiceDocuments(timeFrame);
        Test.stopTest();


        System.assertNotEquals(null, serviceDocuments);
        System.assertEquals(1, serviceDocuments.size());

        DocumentService.WorkDocument wd = serviceDocuments[0];
        System.debug(wd.name);
        System.debug(wd.fileType);
        System.debug(wd.documentType);
        System.debug(wd.serviceRequestId);
        System.debug(wd.data.toString());
    }
}