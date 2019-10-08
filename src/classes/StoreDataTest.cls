/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial tests created.
 * @updated 9/12/2019 - Added additional tests for edge cases.
 *
 * @description Unit tests for StoreDataService and StoreDataHandler.
 */

@IsTest
private class StoreDataTest {
    @IsTest
    static void badEmail() {
        List<StoreDataService.StoreData> newStores = new List<StoreDataService.StoreData>();

        StoreDataService.StoreData tvd1 = new StoreDataService.StoreData();
        tvd1.StoreName = 'TEST NAME';
        tvd1.StoreNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newStores.add(tvd1);

        StoreDataService.StoreData tvd2 = new StoreDataService.StoreData();
        tvd2.StoreName = 'TEST NAME';
        tvd2.StoreNumber = '1234';
        tvd2.emailAddress = 'BADEMAIL';
        newStores.add(tvd2);

        StoreDataService.StoreData tvd3 = new StoreDataService.StoreData();
        tvd3.StoreName = 'TEST NAME';
        tvd3.StoreNumber = '1235';
        tvd3.emailAddress = 'goodEmail3@gmail.com';
        newStores.add(tvd3);


        Test.startTest();
        System.debug(StoreDataService.updateStoreData(newStores));
        Test.stopTest();

        Store__c a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd1.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());

        a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd2.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(null, a.Email_Address__c);

        a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd3.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd3.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());
    }


    @IsTest
    static void goodEmail() {
        List<StoreDataService.StoreData> newStores = new List<StoreDataService.StoreData>();

        StoreDataService.StoreData tvd1 = new StoreDataService.StoreData();
        tvd1.StoreName = 'TEST NAME';
        tvd1.StoreNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newStores.add(tvd1);

        StoreDataService.StoreData tvd2 = new StoreDataService.StoreData();
        tvd2.StoreName = 'TEST NAME';
        tvd2.StoreNumber = '1234';
        tvd2.emailAddress = 'goodEmail2@gmail.com';
        newStores.add(tvd2);

        StoreDataService.StoreData tvd3 = new StoreDataService.StoreData();
        tvd3.StoreName = 'TEST NAME';
        tvd3.StoreNumber = '1235';
        tvd3.emailAddress = 'goodEmail3@gmail.com';
        newStores.add(tvd3);


        Test.startTest();
        StoreDataService.updateStoreData(newStores);
        Test.stopTest();

        Store__c a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd1.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());

        a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd2.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd2.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());

        a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd3.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd3.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());
    }

    @IsTest
    static void errorLog() {
        List<StoreDataService.StoreData> newStores = new List<StoreDataService.StoreData>();

        StoreDataService.StoreData tvd1 = new StoreDataService.StoreData();
        tvd1.StoreName = 'TEST NAME';
        tvd1.StoreNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        tvd1.state = 'Virginia';
        newStores.add(tvd1);


        Test.startTest();
        List<StoreDataService.StoreDataResponse> response = StoreDataService.updateStoreData(newStores);
        Test.stopTest();

        List<Store__c> a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd1.StoreNumber];
        System.assertNotEquals(null, a);
        System.assertEquals(0, a.size());

        System.assertEquals(1, response.size());
        System.assertNotEquals(null, response.get(0));
        System.assertNotEquals(null, response.get(0).errors);
        System.assertEquals(1, response.get(0).errors.size());
    }


    @IsTest
    static void testUpdate() {
        List<StoreDataService.StoreData> newStores = new List<StoreDataService.StoreData>();

        StoreDataService.StoreData tvd1 = new StoreDataService.StoreData();
        tvd1.StoreName = 'TEST NAME';
        tvd1.StoreNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newStores.add(tvd1);


        Test.startTest();
        StoreDataService.updateStoreData(newStores);


        Store__c a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd1.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());


        tvd1.emailAddress = 'SOMEOTHER@email.com';
        StoreDataService.updateStoreData(newStores);


        a = [SELECT Id, Email_Address__c FROM Store__c WHERE Store_Number__c = :tvd1.StoreNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.Email_Address__c.toLowerCase());
        Test.stopTest();

    }
}