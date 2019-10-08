/**
 * @author  Andrew McGuiness - andrew.mcguiness@rtslabs.com
 *
 * @date    9/10/2019 - Initial tests created.
 * @updated 9/11/2019 - Added additional tests for edge cases.
 *
 * @description Unit tests for VendorDataService and VendorDataHandler.
 */

@IsTest
private class VendorDataTest {

    // User Tests
    // Create a User when email is valid
    // Create a User when an email is invalid
    // Update a User with a valid email
    // Update a User with an invalid email
    // Create Vendor with illegal characters in name
    // Create Vendor with no name
    // Create User with duplicate email


    @IsTest
    static void badEmail() {
        List<VendorDataService.VendorData> newVendors = new List<VendorDataService.VendorData>();

        VendorDataService.VendorData tvd1 = new VendorDataService.VendorData();
        tvd1.vendorName = 'TEST NAME';
        tvd1.vendorNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newVendors.add(tvd1);

        VendorDataService.VendorData tvd2 = new VendorDataService.VendorData();
        tvd2.vendorName = 'TEST NAME';
        tvd2.vendorNumber = '1234';
        tvd2.emailAddress = 'BADEMAIL';
        newVendors.add(tvd2);

        VendorDataService.VendorData tvd3 = new VendorDataService.VendorData();
        tvd3.vendorName = 'TEST NAME';
        tvd3.vendorNumber = '1235';
        tvd3.emailAddress = 'goodEmail3@gmail.com';
        newVendors.add(tvd3);


        Test.startTest();
        VendorDataService.updateVendorData(newVendors);
        Test.stopTest();

        Account a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd1.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());

        a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd2.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(null, a.EmailAddress__c);

        a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd3.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd3.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());
    }


    @IsTest
    static void goodEmail() {
        List<VendorDataService.VendorData> newVendors = new List<VendorDataService.VendorData>();

        VendorDataService.VendorData tvd1 = new VendorDataService.VendorData();
        tvd1.vendorName = 'TEST NAME';
        tvd1.vendorNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newVendors.add(tvd1);

        VendorDataService.VendorData tvd2 = new VendorDataService.VendorData();
        tvd2.vendorName = 'TEST NAME';
        tvd2.vendorNumber = '1234';
        tvd2.emailAddress = 'goodEmail2@gmail.com';
        newVendors.add(tvd2);

        VendorDataService.VendorData tvd3 = new VendorDataService.VendorData();
        tvd3.vendorName = 'TEST NAME';
        tvd3.vendorNumber = '1235';
        tvd3.emailAddress = 'goodEmail3@gmail.com';
        newVendors.add(tvd3);


        Test.startTest();
        VendorDataService.updateVendorData(newVendors);
        Test.stopTest();

        Account a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd1.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());

        a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd2.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd2.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());

        a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd3.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd3.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());
    }

    @IsTest
    static void errorLog() {
        List<VendorDataService.VendorData> newVendors = new List<VendorDataService.VendorData>();

        VendorDataService.VendorData tvd1 = new VendorDataService.VendorData();
        tvd1.vendorName = 'TEST NAME';
        tvd1.vendorNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        tvd1.state = 'Virginia';
        newVendors.add(tvd1);


        Test.startTest();
        List<VendorDataService.VendorDataResponse> response = VendorDataService.updateVendorData(newVendors);
        Test.stopTest();

        List<Account> a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd1.vendorNumber];
        System.assertNotEquals(null, a);
        System.assertEquals(0, a.size());

        System.assertEquals(1, response.size());
        System.assertNotEquals(null, response.get(0));
        System.assertNotEquals(null, response.get(0).errors);
        System.assertEquals(1, response.get(0).errors.size());
    }


    @IsTest
    static void testUpdate() {
        List<VendorDataService.VendorData> newVendors = new List<VendorDataService.VendorData>();

        VendorDataService.VendorData tvd1 = new VendorDataService.VendorData();
        tvd1.vendorName = 'TEST NAME';
        tvd1.vendorNumber = '1233';
        tvd1.emailAddress = 'goodEmail@gmail.com';
        newVendors.add(tvd1);


        Test.startTest();
        VendorDataService.updateVendorData(newVendors);


        Account a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd1.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());


        tvd1.emailAddress = 'SOMEOTHER@email.com';
        VendorDataService.updateVendorData(newVendors);


        a = [SELECT Id, EmailAddress__c FROM Account WHERE VendorNumber__c = :tvd1.vendorNumber LIMIT 1];
        System.assertNotEquals(null, a);
        System.assertEquals(tvd1.emailAddress.toLowerCase(), a.EmailAddress__c.toLowerCase());
        Test.stopTest();

    }
}